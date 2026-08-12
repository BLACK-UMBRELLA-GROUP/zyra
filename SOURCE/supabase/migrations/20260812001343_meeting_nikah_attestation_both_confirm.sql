-- MEETING + NIKAH — BOTH SEEKERS CONFIRM. Founder approval 2026-08-12
-- ("do number 4"; mechanic as recommended: one proposes, the other
-- confirms, only then does the Timeline gain the milestone). Applied live
-- 2026-08-12 00:13 UTC via MCP; file written back the same session.
--
-- Rules:
--   - Either Seeker proposes (type + the date it happened, never future).
--   - Only the OTHER Seeker can confirm. Confirming writes the Timeline
--     milestone dated at the attested day (noon UTC, so every viewer
--     within ±11h of UTC renders the same calendar date).
--   - One of each per attempt: the FIRST meeting is the milestone;
--     routine later meetings are deliberately not logged.
--   - Paused or non-active Journeys refuse (a paused Journey is frozen).
--   - "Not yet" is a client-side dismissal — the proposal stays pending;
--     the proposer may re-propose (their old pending row is superseded).
--   - No automatic Journey state change on Nikah — what happens to the
--     Journey after Nikah is an OPEN product decision (spec says
--     "progress to completion"; the schema has no 'completed' status).

CREATE TABLE public.journey_milestone_attestations (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id       uuid NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  attempt_id     uuid NOT NULL REFERENCES journey_attempts(id) ON DELETE CASCADE,
  milestone_type text NOT NULL CHECK (milestone_type IN ('meeting','nikah')),
  occurred_on    date NOT NULL,
  proposed_by    uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status         text NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending','confirmed','superseded')),
  confirmed_by   uuid REFERENCES profiles(id) ON DELETE SET NULL,
  confirmed_at   timestamptz,
  created_at     timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX journey_milestone_attestations_one_pending
  ON journey_milestone_attestations (attempt_id, milestone_type)
  WHERE status = 'pending';
CREATE INDEX journey_milestone_attestations_match_idx
  ON journey_milestone_attestations (match_id);

ALTER TABLE public.journey_milestone_attestations ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.journey_milestone_attestations FROM PUBLIC, anon, authenticated;

COMMENT ON TABLE public.journey_milestone_attestations IS
  'Meeting/Nikah proposals awaiting the other Seeker''s confirmation (Founder 2026-08-12). Confirmation writes the timeline_milestones row; user-attested, both-party record.';

DO $$
DECLARE cname text;
BEGIN
  SELECT c.conname INTO cname
    FROM pg_constraint c JOIN pg_class t ON t.oid = c.conrelid
   WHERE t.relname = 'notifications' AND pg_get_constraintdef(c.oid) LIKE '%new_match%';
  IF cname IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.notifications DROP CONSTRAINT %I', cname);
  END IF;
END $$;
ALTER TABLE public.notifications ADD CONSTRAINT notifications_type_check
  CHECK (type = ANY (ARRAY['new_match','new_message','wali_request','journey_ended',
                           'journey_request','journey_request_accepted','journey_request_declined',
                           'milestone_proposed','milestone_confirmed']));

CREATE OR REPLACE FUNCTION public.zyra_propose_milestone(
  p_match_id uuid, p_type text, p_occurred_on date
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  caller UUID := auth.uid();
  m RECORD; v_attempt UUID; v_timeline UUID; v_other UUID;
  v_pending RECORD; v_id UUID; v_name TEXT; v_label TEXT;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  IF p_type NOT IN ('meeting','nikah') THEN RAISE EXCEPTION 'bad_milestone_type'; END IF;
  IF p_occurred_on > current_date THEN
    RAISE EXCEPTION 'milestone_in_future'
      USING HINT = 'A milestone records something that has happened.';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party'; END IF;
  IF m.status <> 'active' THEN RAISE EXCEPTION 'journey_not_active'; END IF;
  IF m.suspended_by IS NOT NULL THEN
    RAISE EXCEPTION 'journey_paused'
      USING HINT = 'A paused Journey is frozen — resume it first.';
  END IF;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status <> 'ended'
   ORDER BY (a.status = 'active') DESC, a.attempt_number DESC LIMIT 1;
  IF v_attempt IS NULL THEN RAISE EXCEPTION 'no_attempt_for_match'; END IF;

  SELECT id INTO v_timeline FROM timelines WHERE attempt_id = v_attempt;
  IF v_timeline IS NOT NULL AND EXISTS (
      SELECT 1 FROM timeline_milestones
       WHERE timeline_id = v_timeline AND milestone_type = p_type) THEN
    RAISE EXCEPTION 'milestone_already_recorded';
  END IF;

  SELECT * INTO v_pending FROM journey_milestone_attestations
   WHERE attempt_id = v_attempt AND milestone_type = p_type AND status = 'pending';
  IF FOUND THEN
    IF v_pending.proposed_by <> caller THEN
      RAISE EXCEPTION 'confirm_theirs_instead'
        USING HINT = 'They have already proposed this milestone — confirm or discuss it.';
    END IF;
    UPDATE journey_milestone_attestations SET status = 'superseded' WHERE id = v_pending.id;
  END IF;

  INSERT INTO journey_milestone_attestations
    (match_id, attempt_id, milestone_type, occurred_on, proposed_by)
  VALUES (p_match_id, v_attempt, p_type, p_occurred_on, caller)
  RETURNING id INTO v_id;

  v_other := CASE WHEN caller = m.seeker_a_id THEN m.seeker_b_id ELSE m.seeker_a_id END;
  SELECT first_name INTO v_name FROM profiles WHERE id = caller;
  v_label := CASE p_type WHEN 'meeting' THEN 'first meeting' ELSE 'Nikah' END;
  PERFORM create_notification(
    v_other, 'milestone_proposed', 'Milestone to confirm',
    COALESCE(v_name,'They')||' says your '||v_label||' was on '
      ||to_char(p_occurred_on,'DD FMMonth YYYY')||'. Confirm it to add it to your Timeline.',
    p_match_id);
  RETURN v_id;
END; $function$;

CREATE OR REPLACE FUNCTION public.zyra_confirm_milestone(p_attestation_id uuid)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  caller UUID := auth.uid();
  att RECORD; m RECORD; v_timeline UUID; v_name TEXT; v_label TEXT;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  SELECT * INTO att FROM journey_milestone_attestations WHERE id = p_attestation_id;
  IF NOT FOUND OR att.status <> 'pending' THEN RAISE EXCEPTION 'attestation_not_pending'; END IF;

  SELECT * INTO m FROM matches WHERE id = att.match_id;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party'; END IF;
  IF caller = att.proposed_by THEN
    RAISE EXCEPTION 'not_yours_to_confirm'
      USING HINT = 'The other Seeker confirms — that is what makes it a shared record.';
  END IF;
  IF m.status <> 'active' THEN RAISE EXCEPTION 'journey_not_active'; END IF;
  IF m.suspended_by IS NOT NULL THEN RAISE EXCEPTION 'journey_paused'; END IF;

  INSERT INTO timelines (match_id, attempt_id) VALUES (att.match_id, att.attempt_id)
  ON CONFLICT (attempt_id) DO NOTHING;
  SELECT id INTO v_timeline FROM timelines WHERE attempt_id = att.attempt_id;

  IF NOT EXISTS (SELECT 1 FROM timeline_milestones
                  WHERE timeline_id = v_timeline AND milestone_type = att.milestone_type) THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type, occurred_at)
    VALUES (v_timeline, att.milestone_type,
            (att.occurred_on::timestamp + interval '12 hours') AT TIME ZONE 'UTC');
  END IF;

  UPDATE journey_milestone_attestations
     SET status = 'confirmed', confirmed_by = caller, confirmed_at = now()
   WHERE id = p_attestation_id;

  SELECT first_name INTO v_name FROM profiles WHERE id = caller;
  v_label := CASE att.milestone_type WHEN 'meeting' THEN 'first meeting' ELSE 'Nikah' END;
  PERFORM create_notification(
    att.proposed_by, 'milestone_confirmed', 'Milestone confirmed',
    COALESCE(v_name,'They')||' confirmed your '||v_label||'. It is now on your Timeline.',
    att.match_id);
END; $function$;

CREATE OR REPLACE FUNCTION public.zyra_milestone_attestation_state(p_match_id uuid)
RETURNS TABLE(id uuid, milestone_type text, occurred_on date, proposed_by uuid)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE caller UUID := auth.uid(); m RECORD; v_attempt UUID;
BEGIN
  IF caller IS NULL THEN RETURN; END IF;
  SELECT * INTO m FROM matches WHERE matches.id = p_match_id;
  IF NOT FOUND OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN RETURN; END IF;
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status <> 'ended'
   ORDER BY (a.status = 'active') DESC, a.attempt_number DESC LIMIT 1;
  IF v_attempt IS NULL THEN RETURN; END IF;
  RETURN QUERY
  SELECT t.id, t.milestone_type, t.occurred_on, t.proposed_by
    FROM journey_milestone_attestations t
   WHERE t.attempt_id = v_attempt AND t.status = 'pending';
END; $function$;

REVOKE ALL ON FUNCTION public.zyra_propose_milestone(uuid, text, date) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.zyra_confirm_milestone(uuid) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.zyra_milestone_attestation_state(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.zyra_propose_milestone(uuid, text, date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_confirm_milestone(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_milestone_attestation_state(uuid) TO authenticated;

COMMENT ON FUNCTION public.zyra_propose_milestone(uuid, text, date) IS
  'Proposes a meeting/nikah milestone (Founder 2026-08-12). Party-only, active un-paused Journeys, never future-dated, one pending per type; the counterpart is notified and must confirm before anything reaches the Timeline.';
COMMENT ON FUNCTION public.zyra_confirm_milestone(uuid) IS
  'Counterpart-only confirmation; writes the timeline_milestones row at noon UTC of the attested date. NOT EXISTS-guarded like every other milestone writer.';
COMMENT ON FUNCTION public.zyra_milestone_attestation_state(uuid) IS
  'Pending attestations for the caller''s match — the Timeline screen''s read path; table itself has no grants.';
