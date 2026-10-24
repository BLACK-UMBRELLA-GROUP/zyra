-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260811102840, applied name
-- 'journey_timeline_milestones_and_rewind_all') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- ═══════════════════════════════════════════════════════════════════════
-- PART 1 — THE TIMELINE LEARNS THE JOURNEY
-- ═══════════════════════════════════════════════════════════════════════
--
-- Founder, 2026-08-11: "lets start making the timeline... create fake
-- scenarios when they liked each other, when they matched and more when
-- journey started and make the timeline update for example when they revealed
-- compatibility etc and continue it as journey continues."
--
-- The Timeline screen has been real since 2026-07-18 and has had exactly ONE
-- thing to draw: 'match_created', written by create_match_on_mutual_like().
-- Eight Journey stages have run past it without leaving a mark, so the
-- Timeline showed a single dot no matter how far a couple had come.
--
-- ── WHY A TRIGGER AND NOT A CALL AT EACH SITE.
--
-- journey_stage is moved from five different places today:
-- zyra_advance_stage(), resolve_family_review_if_due(), wali_review_decision(),
-- zyra_dev_set_journey_stage() and zyra_dev_counterpart_complete(). Adding an
-- insert to each is five chances to forget one, and the one you forget is
-- invisible — a Timeline that is quietly missing a step reads as "nothing
-- happened", not as a bug. The column is the fact; the milestone follows it.
--
-- ── NAMED FOR WHAT HAPPENED, NOT FOR THE STAGE ARRIVED AT.
--
-- The existing two are 'match_created' and 'conversation_started' — past-tense
-- events — so the new ones match. A milestone records the stage just
-- COMPLETED, which is why the map below reads from OLD.journey_stage.

ALTER TABLE timeline_milestones DROP CONSTRAINT timeline_milestones_milestone_type_check;
ALTER TABLE timeline_milestones ADD CONSTRAINT timeline_milestones_milestone_type_check
  CHECK (milestone_type = ANY (ARRAY[
    -- before the Journey
    'liked'::text, 'match_created'::text, 'journey_started'::text,
    -- the eight stages, as they complete
    'compatibility_revealed'::text, 'salam_exchanged'::text, 'guardian_linked'::text,
    'phase_1_complete'::text, 'phase_2_complete'::text, 'phase_3_complete'::text,
    'family_stage'::text, 'conversation_started'::text,
    -- beyond, and the two endings
    'meeting'::text, 'nikah'::text, 'journey_ended'::text, 'journey_restarted'::text
  ]));

CREATE OR REPLACE FUNCTION public.zyra_record_journey_milestone()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_timeline UUID;
  v_attempt  UUID;
  v_type     TEXT;
  v_old_ord  INT;
  v_new_ord  INT;
  -- THE CANONICAL ORDER, and the only copy of it in the database. Kept in one
  -- array so "did the Journey move forward" is a comparison rather than a
  -- second switch that could disagree with the first.
  v_order    TEXT[] := ARRAY['compatibility_reveal','salam_exchange','wali_gate',
                             'phase_1','phase_2','phase_3','family_stage','conversation'];
BEGIN
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = NEW.id
   ORDER BY (a.status = 'active') DESC, a.attempt_number DESC LIMIT 1;
  IF v_attempt IS NULL THEN RETURN NEW; END IF;

  INSERT INTO timelines (match_id, attempt_id) VALUES (NEW.id, v_attempt)
  ON CONFLICT (attempt_id) DO NOTHING;
  SELECT id INTO v_timeline FROM timelines WHERE attempt_id = v_attempt;
  IF v_timeline IS NULL THEN RETURN NEW; END IF;

  -- A Journey beginning is its own milestone, and it is a status change
  -- rather than a stage change — the Pre-Journey Ritual is what turns a
  -- Potential Journey into an Active one.
  IF NEW.status = 'active' AND OLD.status IS DISTINCT FROM 'active' THEN
    IF NOT EXISTS (SELECT 1 FROM timeline_milestones
                    WHERE timeline_id = v_timeline AND milestone_type = 'journey_started') THEN
      INSERT INTO timeline_milestones (timeline_id, milestone_type)
      VALUES (v_timeline, 'journey_started');
    END IF;
  END IF;

  IF NEW.journey_stage IS DISTINCT FROM OLD.journey_stage
     AND OLD.journey_stage IS NOT NULL THEN

    v_old_ord := array_position(v_order, OLD.journey_stage);
    v_new_ord := array_position(v_order, NEW.journey_stage);

    -- FORWARD ONLY. A dev rewind sets the stage back to the first one, and a
    -- rewind that wrote "compatibility revealed" on the way past would leave
    -- the Timeline claiming things happened in an order they did not.
    IF v_old_ord IS NOT NULL AND v_new_ord IS NOT NULL AND v_new_ord > v_old_ord THEN

      v_type := CASE OLD.journey_stage
                  WHEN 'compatibility_reveal' THEN 'compatibility_revealed'
                  WHEN 'salam_exchange'       THEN 'salam_exchanged'
                  WHEN 'wali_gate'            THEN 'guardian_linked'
                  WHEN 'phase_1'              THEN 'phase_1_complete'
                  WHEN 'phase_2'              THEN 'phase_2_complete'
                  WHEN 'phase_3'              THEN 'phase_3_complete'
                  WHEN 'family_stage'         THEN 'family_stage'
                END;

      IF v_type IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM timeline_milestones
         WHERE timeline_id = v_timeline AND milestone_type = v_type) THEN
        INSERT INTO timeline_milestones (timeline_id, milestone_type) VALUES (v_timeline, v_type);
      END IF;

      -- Arriving at the last stage is an event in its own right, on top of
      -- Family Compatibility having finished.
      IF NEW.journey_stage = 'conversation' AND NOT EXISTS (
        SELECT 1 FROM timeline_milestones
         WHERE timeline_id = v_timeline AND milestone_type = 'conversation_started') THEN
        INSERT INTO timeline_milestones (timeline_id, milestone_type)
        VALUES (v_timeline, 'conversation_started');
      END IF;
    END IF;
  END IF;

  -- Endings, which are not stage moves at all.
  IF NEW.status = 'ended' AND OLD.status IS DISTINCT FROM 'ended' THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type)
    VALUES (v_timeline, 'journey_ended');
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS matches_record_journey_milestone ON matches;
CREATE TRIGGER matches_record_journey_milestone
  AFTER UPDATE ON matches
  FOR EACH ROW
  EXECUTE FUNCTION zyra_record_journey_milestone();

COMMENT ON FUNCTION public.zyra_record_journey_milestone() IS
  'Writes a Timeline milestone whenever a match starts, advances a Journey stage forward, or ends. Forward-only, so a dev rewind leaves no trace. One place, because journey_stage is moved from five.';

-- ═══════════════════════════════════════════════════════════════════════
-- PART 2 — REWIND, NOW ACCOUNT-WIDE AND TIMELINE-AWARE
-- ═══════════════════════════════════════════════════════════════════════
--
-- Founder: "when i pressed reset it started with send salam not started with
-- start journey again... main thing is to fix reset toggle."
--
-- Two changes:
--   p_match_id is now OPTIONAL. NULL means every Journey this account is in,
--   so the panel's Reset — which has no match in front of it — can call it.
--
--   The Timeline is pruned back to the pre-Journey facts. 'liked' and
--   'match_created' SURVIVE: those happened before the Journey and are still
--   true after a rewind. Everything the Journey itself wrote goes.
DROP FUNCTION IF EXISTS public.zyra_dev_rewind_journey(uuid);

CREATE OR REPLACE FUNCTION public.zyra_dev_rewind_journey(p_match_id uuid DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  caller    UUID := (SELECT auth.uid());
  v_email   TEXT;
  v_ids     UUID[];
  v_id      UUID;
  v_conv    UUID;
  n         INT;
  total     INT := 0;
  journeys  INT := 0;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Rewinding a Journey is limited to seeded @zyra.test accounts.';
  END IF;

  IF p_match_id IS NULL THEN
    SELECT array_agg(id) INTO v_ids FROM matches
     WHERE seeker_a_id = caller OR seeker_b_id = caller;
  ELSE
    SELECT array_agg(id) INTO v_ids FROM matches
     WHERE id = p_match_id AND (seeker_a_id = caller OR seeker_b_id = caller);
    IF v_ids IS NULL THEN RAISE EXCEPTION 'not_a_party'; END IF;
  END IF;

  IF v_ids IS NULL THEN RETURN 'No Journeys on this account — nothing to rewind.'; END IF;

  FOREACH v_id IN ARRAY v_ids LOOP
    journeys := journeys + 1;

    DELETE FROM journey_phase_ratings     WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_phase_answers     WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_phase_checkpoints WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_family_answers    WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_stage_checkpoints WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_salams            WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_compatibility     WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_requests          WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

    DELETE FROM journey_family_review_responses
     WHERE review_id IN (SELECT id FROM journey_family_reviews WHERE match_id = v_id);
    GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_family_reviews WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

    SELECT id INTO v_conv FROM conversations WHERE match_id = v_id LIMIT 1;
    IF v_conv IS NOT NULL THEN
      DELETE FROM messages WHERE conversation_id = v_conv; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
      UPDATE conversations SET status = 'closed', closed_at = NULL WHERE id = v_conv;
    END IF;

    -- The Journey's own marks only. How you met each other survives.
    DELETE FROM timeline_milestones
     WHERE timeline_id IN (SELECT id FROM timelines WHERE match_id = v_id)
       AND milestone_type NOT IN ('liked', 'match_created');
    GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

    DELETE FROM notifications WHERE related_match_id = v_id;
    GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

    UPDATE matches
       SET journey_stage = 'compatibility_reveal',
           status        = 'active',
           suspended_by  = NULL, suspended_at = NULL,
           ended_at      = NULL, ended_by     = NULL,
           end_reason    = NULL, end_note     = NULL
     WHERE id = v_id;

    UPDATE journey_attempts
       SET journey_stage = 'compatibility_reveal', status = 'active'
     WHERE match_id = v_id;
  END LOOP;

  RETURN format('%s Journey(s) back at Compatibility Reveal. %s row(s) cleared.',
                journeys, total);
END;
$function$;

REVOKE ALL ON FUNCTION public.zyra_dev_rewind_journey(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.zyra_dev_rewind_journey(uuid) TO authenticated;

COMMENT ON FUNCTION public.zyra_dev_rewind_journey(uuid) IS
  'DEV ONLY (@zyra.test). Destructive: wipes a Journey back to stage one, keeping the match, the Guardian link and how you met. NULL match id rewinds every Journey on the account. Not a product feature — see restart_journey(). Drop before public launch — OA-ZYRA-184.';
