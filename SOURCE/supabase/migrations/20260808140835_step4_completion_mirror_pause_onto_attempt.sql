-- APPLIED LIVE 2026-08-08, version 20260808140835.
-- OA-ZYRA-156 stage 4e · STEP 4, COMPLETED. Unblocked by step 5.
--
-- Step 4 shipped without mirroring pause onto journey_attempts because
-- attempts_pause_needs_active rejected it — an attempt promoted the normal
-- way was still 'potential'. Step 5 made promote maintain the attempt's
-- status (verified 20/20), so the CHECK accepts it. Finished rather than
-- left as a known gap behind a resolved blocker.

create or replace function public.suspend_journey(p_match_id uuid)
 returns void language plpgsql security definer set search_path to 'public'
as $function$
DECLARE m RECORD; caller UUID := auth.uid(); caller_plan TEXT; v_attempt UUID;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match'; END IF;
  IF m.status <> 'active' THEN RAISE EXCEPTION 'match is not active'; END IF;
  -- UNCHANGED: Pause is ZYRA One (DR-ZYRA-121 item 12, Founder amendment).
  SELECT plan_type INTO caller_plan FROM subscriptions WHERE user_id=caller AND status='active';
  IF caller_plan IS DISTINCT FROM 'seeker_premium' THEN
    RAISE EXCEPTION 'suspension_requires_one' USING HINT='Journey Suspension requires ZYRA One.';
  END IF;
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status <> 'ended'
   ORDER BY (a.status='active') DESC, a.attempt_number DESC LIMIT 1;
  UPDATE matches SET suspended_by=caller, suspended_at=NOW() WHERE id=p_match_id;
  UPDATE journey_attempts SET paused_by=caller, paused_at=NOW()
   WHERE v_attempt IS NOT NULL AND id=v_attempt;
  UPDATE conversations SET status='paused'
   WHERE v_attempt IS NOT NULL AND attempt_id=v_attempt;
END; $function$;

create or replace function public.resume_journey(p_match_id uuid)
 returns void language plpgsql security definer set search_path to 'public'
as $function$
DECLARE m RECORD; caller UUID := auth.uid(); other_id UUID; v_attempt UUID;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller <> m.suspended_by THEN
    RAISE EXCEPTION 'only the suspending Seeker may resume'; END IF;
  IF NOT public.zyra_can_match(m.seeker_a_id, m.seeker_b_id) THEN
    RAISE EXCEPTION 'not_eligible_to_match'
      USING HINT='Something has changed while this was paused — a Guardian '
                 'relationship or a block now exists between you.';
  END IF;
  other_id := CASE WHEN m.seeker_a_id = caller THEN m.seeker_b_id ELSE m.seeker_a_id END;
  IF EXISTS (SELECT 1 FROM matches WHERE status='active' AND id <> p_match_id
               AND (seeker_a_id=other_id OR seeker_b_id=other_id)) THEN
    RAISE EXCEPTION 'other_party_in_active_journey'
      USING HINT='This Journey stays paused for now. You can wait, or end it '
                 'yourself if you would rather.';
  END IF;
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status <> 'ended'
   ORDER BY (a.status='active') DESC, a.attempt_number DESC LIMIT 1;
  UPDATE matches SET suspended_by=NULL, suspended_at=NULL WHERE id=p_match_id;
  UPDATE journey_attempts SET paused_by=NULL, paused_at=NULL
   WHERE v_attempt IS NOT NULL AND id=v_attempt;
  UPDATE conversations SET status='active'
   WHERE v_attempt IS NOT NULL AND attempt_id=v_attempt AND status='paused';
END; $function$;

comment on function public.suspend_journey(uuid) is
  'Pause recorded on BOTH matches.suspended_by and journey_attempts.paused_by '
  'as of 2026-08-08. matches stays authoritative until step 7.';
comment on function public.resume_journey(uuid) is
  'Clears the pause on both rows. Still reads Active-Journey state from '
  'matches, authoritative until step 7.';
comment on function public.zyra_enforce_one_active_attempt() is
  'LIVE as of 2026-08-08 step 5 — promote now sets an attempt to active, so '
  'this fires. Runs alongside zyra_enforce_one_active_match() on matches; '
  'both raise one_active_journey_limit. The matches one retires at step 7.';

-- VERIFIED 2026-08-08, 9/9: pause written to both rows and cleared from
-- both; conversation paused and resumed; ending a paused Journey clears
-- the attempt pause and sets the attempt to ended.
