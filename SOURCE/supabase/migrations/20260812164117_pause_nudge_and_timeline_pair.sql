-- THE PAUSE PACKAGE — DR-ZYRA-142 ........................................
-- Product model settled with ChatGPT and ratified by the Founder,
-- 2026-08-12 evening. Three parts; the first two live here, the third
-- (time-honesty on the rows) is client-only. The pauser keeps sole
-- ownership of the lift (V3 §7, unchanged); what the waiting person
-- gains is a VOICE, exactly once:
--
--   1  THE ONE-SHOT NUDGE. The non-pauser may send "I'm ready when you
--      are" ONCE PER PAUSE EPISODE: one notification to the pauser,
--      no badge, no delivery/read/response state, Guardian-silent.
--      matches.pause_nudged_at is the episode flag — suspend_journey
--      clears it (a new pause is a new episode), resume_journey clears
--      it (meaningless when active). No accept/decline machinery: the
--      pauser resumes when they resume.
--   2  THE TIMELINE PAIR. journey_paused / journey_continued milestones,
--      dated, NAMELESS and reasonless — the Timeline is the keepsake,
--      not a ledger of responsibility. Recorded by the existing
--      milestone trigger (a pause IS a matches update), never deduped:
--      a couple may pause many times, and each pair is part of the
--      story. An end-while-paused writes no "continued" — journey_ended
--      already closes the chapter.
--
-- Also part of the ratification, deliberately NOT built here: the
-- system never auto-ends a pause of any age (DR-ZYRA-121 item 12
-- stands), and the 30/90-day gentle reminders to the pauser need a
-- scheduler — raised as OA-ZYRA-203 rather than half-built.

-- 1 ── the episode flag
alter table public.matches add column if not exists pause_nudged_at timestamptz;

-- 2 ── the two vocabularies grow by one word each
alter table public.notifications drop constraint notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type = any (array['new_match'::text, 'new_message'::text,
    'wali_request'::text, 'journey_ended'::text, 'journey_request'::text,
    'journey_request_accepted'::text, 'journey_request_declined'::text,
    'milestone_proposed'::text, 'milestone_confirmed'::text,
    'pause_nudge'::text]));

alter table public.timeline_milestones drop constraint timeline_milestones_milestone_type_check;
alter table public.timeline_milestones add constraint timeline_milestones_milestone_type_check
  check (milestone_type = any (array['liked'::text, 'match_created'::text,
    'journey_started'::text, 'compatibility_revealed'::text,
    'salam_exchanged'::text, 'guardian_linked'::text,
    'phase_1_complete'::text, 'phase_2_complete'::text,
    'phase_3_complete'::text, 'family_stage'::text,
    'conversation_started'::text, 'meeting'::text, 'nikah'::text,
    'journey_ended'::text, 'journey_restarted'::text,
    'journey_paused'::text, 'journey_continued'::text]));

-- 3 ── the nudge itself
create or replace function public.nudge_paused_journey(p_match_id uuid)
returns void
language plpgsql security definer
set search_path to 'public'
as $function$
declare m record; caller uuid := auth.uid(); v_name text;
begin
  if caller is null then raise exception 'not_signed_in'; end if;
  select * into m from matches where id = p_match_id;
  if not found then raise exception 'match not found'; end if;
  if caller <> m.seeker_a_id and caller <> m.seeker_b_id then
    raise exception 'not a party to this match';
  end if;
  if m.status <> 'active' or m.suspended_by is null then
    raise exception 'journey_not_paused';
  end if;
  -- The pauser has no use for a nudge — their button is Resume.
  if caller = m.suspended_by then
    raise exception 'pauser_cannot_nudge';
  end if;
  -- ONE per episode. The client greys its button from the same flag, so
  -- reaching this is a race or a stale screen, not a normal path.
  if m.pause_nudged_at is not null then
    raise exception 'already_nudged'
      using hint = 'One nudge per pause — they already know you are ready.';
  end if;

  update matches set pause_nudged_at = now() where id = p_match_id;

  -- One notification to the PAUSER alone. No wali copy — Guardian-silent
  -- is part of the decision: a whisper, not a family event.
  select first_name into v_name from profiles where id = caller;
  perform create_notification(
    m.suspended_by, 'pause_nudge', 'Whenever you are ready',
    coalesce(v_name, 'They') || ' is ready to continue, whenever you are.',
    p_match_id);
end $function$;

revoke all on function public.nudge_paused_journey(uuid) from public, anon;
grant execute on function public.nudge_paused_journey(uuid) to authenticated;

-- 4 ── suspend/resume clear the episode flag (bodies otherwise verbatim
--      from pause_both_plans_capped / plan_aware_active_journey_limit)
CREATE OR REPLACE FUNCTION public.suspend_journey(p_match_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  m RECORD; caller UUID := auth.uid(); caller_plan TEXT; v_attempt UUID;
  v_cap INT; v_paused INT;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match'; END IF;
  IF m.status <> 'active' THEN RAISE EXCEPTION 'match is not active'; END IF;

  SELECT plan_type INTO caller_plan FROM subscriptions WHERE user_id=caller AND status='active';
  v_cap := CASE WHEN caller_plan = 'seeker_premium' THEN 10 ELSE 5 END;
  SELECT COUNT(*) INTO v_paused FROM matches
   WHERE status = 'active' AND suspended_by = caller AND id <> p_match_id;
  IF v_paused >= v_cap THEN
    RAISE EXCEPTION 'paused_limit_reached'
      USING HINT = 'Your plan holds up to ' || v_cap || ' paused Journeys.';
  END IF;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status <> 'ended'
   ORDER BY (a.status='active') DESC, a.attempt_number DESC LIMIT 1;
  -- pause_nudged_at cleared: a NEW pause is a NEW episode (DR-ZYRA-142),
  -- so the other person's one nudge comes back.
  UPDATE matches SET suspended_by=caller, suspended_at=NOW(),
                     pause_nudged_at=NULL WHERE id=p_match_id;
  UPDATE journey_attempts SET paused_by=caller, paused_at=NOW()
   WHERE v_attempt IS NOT NULL AND id=v_attempt;
  UPDATE conversations SET status='paused'
   WHERE v_attempt IS NOT NULL AND attempt_id=v_attempt;
END; $function$;

CREATE OR REPLACE FUNCTION public.resume_journey(p_match_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE m RECORD; caller UUID := auth.uid(); other_id UUID; v_attempt UUID;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  -- UNCHANGED: V3 section 7 "Only the person who placed a pause may lift it."
  IF caller <> m.suspended_by THEN
    RAISE EXCEPTION 'only the suspending Seeker may resume'; END IF;
  -- CHANGED 2026-08-08 (OA-ZYRA-174): was zyra_can_match(), which pulled in
  -- Tier-1 and trapped the Journey permanently over a third party's action.
  -- Now blocks and Tier-0 only — both of which the two parties can see and,
  -- if they choose, undo. The hint names something the Seeker can act on.
  IF NOT public.zyra_can_continue_journey(m.seeker_a_id, m.seeker_b_id) THEN
    RAISE EXCEPTION 'not_eligible_to_continue'
      USING HINT='This Journey cannot resume: one of you has blocked the '
                 'other, or one of you is now the other''s Guardian.';
  END IF;
  -- NEW 2026-08-12 (pause frees the slot), plan-aware the same day: your
  -- own state first — it is the one you can act on. The constraint
  -- trigger backstops the race.
  IF zyra_active_journey_count(caller, p_match_id) >= zyra_active_journey_cap(caller) THEN
    RAISE EXCEPTION 'self_in_active_journey'
      USING HINT='You are at your plan''s Active Journey limit. Pause or '
                 'end one first — then resume this one.';
  END IF;
  other_id := CASE WHEN m.seeker_a_id = caller THEN m.seeker_b_id ELSE m.seeker_a_id END;
  -- UNCHANGED in role, still from `matches` — authoritative until step 7.
  IF zyra_active_journey_count(other_id, p_match_id) >= zyra_active_journey_cap(other_id) THEN
    RAISE EXCEPTION 'other_party_in_active_journey'
      USING HINT='This Journey stays paused for now. You can wait, or end it '
                 'yourself if you would rather.';
  END IF;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status <> 'ended'
   ORDER BY (a.status='active') DESC, a.attempt_number DESC LIMIT 1;

  -- pause_nudged_at cleared: the flag is per-episode and the episode is
  -- over (DR-ZYRA-142).
  UPDATE matches SET suspended_by = NULL, suspended_at = NULL,
                     pause_nudged_at = NULL WHERE id = p_match_id;
  UPDATE journey_attempts SET paused_by = NULL, paused_at = NULL
   WHERE v_attempt IS NOT NULL AND id = v_attempt;
  UPDATE conversations SET status='active'
   WHERE v_attempt IS NOT NULL AND attempt_id = v_attempt AND status='paused';
END; $function$;

-- 5 ── the milestone trigger learns the pair
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

  IF NEW.status = 'active' AND OLD.status IS DISTINCT FROM 'active' THEN
    IF NOT EXISTS (SELECT 1 FROM timeline_milestones
                    WHERE timeline_id = v_timeline AND milestone_type = 'journey_started') THEN
      INSERT INTO timeline_milestones (timeline_id, milestone_type)
      VALUES (v_timeline, 'journey_started');
    END IF;
  END IF;

  -- Pauses and resumes — DR-ZYRA-142 (2026-08-12): the Timeline records
  -- the PAIR, dated, nameless and reasonless. Deliberately NOT deduped:
  -- a couple may pause many times, and each "paused … continued" pair is
  -- part of the story, quiet by styling rather than by omission. Who
  -- paused is never written — the Timeline is the keepsake, not a ledger
  -- of responsibility (Main Guardians can read it, which is exactly why).
  IF NEW.suspended_by IS NOT NULL AND OLD.suspended_by IS NULL THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type)
    VALUES (v_timeline, 'journey_paused');
  END IF;
  -- An end-while-paused writes no "continued": journey_ended below
  -- already closes the chapter.
  IF NEW.suspended_by IS NULL AND OLD.suspended_by IS NOT NULL
     AND NEW.status = 'active' THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type)
    VALUES (v_timeline, 'journey_continued');
  END IF;

  IF NEW.journey_stage IS DISTINCT FROM OLD.journey_stage
     AND OLD.journey_stage IS NOT NULL THEN

    v_old_ord := array_position(v_order, OLD.journey_stage);
    v_new_ord := array_position(v_order, NEW.journey_stage);

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

      IF NEW.journey_stage = 'conversation' AND NOT EXISTS (
        SELECT 1 FROM timeline_milestones
         WHERE timeline_id = v_timeline AND milestone_type = 'conversation_started') THEN
        INSERT INTO timeline_milestones (timeline_id, milestone_type)
        VALUES (v_timeline, 'conversation_started');
      END IF;
    END IF;
  END IF;

  -- Endings — NOW GUARDED (2026-08-12): zyra_end_match_internal writes the
  -- same milestone after this trigger has fired.
  IF NEW.status = 'ended' AND OLD.status IS DISTINCT FROM 'ended' THEN
    IF NOT EXISTS (SELECT 1 FROM timeline_milestones
                    WHERE timeline_id = v_timeline AND milestone_type = 'journey_ended') THEN
      INSERT INTO timeline_milestones (timeline_id, milestone_type)
      VALUES (v_timeline, 'journey_ended');
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;
