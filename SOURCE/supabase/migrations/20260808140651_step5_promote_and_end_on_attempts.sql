-- APPLIED LIVE 2026-08-08, version 20260808140651.
-- OA-ZYRA-156 stage 4e · STEP 5 — promote and end. THE BEHAVIOUR-CHANGING
-- STEP, and the linchpin: steps 4 and 7 both waited on it.
-- Authorised by DR-ZYRA-122 (decision 3 covers the ending reason).
--
-- FOUR CHANGES, each stated so none is discovered later:
--
-- 1. promote_journey_to_active() NOW MAINTAINS journey_attempts. It set
--    matches.status='active' and did not touch the attempt at all, so
--    every promoted Journey left its attempt on 'potential'. That single
--    omission made journey_attempts_one_active_per_person inert and
--    blocked half of step 4.
-- 2. end_journey() CAN RECORD A REASON — added as a separate two-argument
--    function, not a defaulted parameter, so the existing Dart call
--    (p_match_id only) keeps resolving to the one-argument form. Neither
--    has defaults, so PostgREST picks by arguments supplied. Both
--    delegate to the same internal: one path (I3), two doors.
-- 3. 'no_response' IS REFUSED from the user path — matches_no_response_is_system
--    requires ended_by IS NULL and this path always has a caller. Without
--    the check the caller would get a constraint violation, not a reason.
-- 4. zyra_end_match_internal() reaches conversations and timelines through
--    attempt_id. It already wrote the attempt row; only its lookups lagged.
--
-- NOT CHANGED: who may end; the Option B notification rule (Seekers only,
-- both ending kinds identical); Step 0's safety-concern concealment; the
-- Pause entitlement.

create or replace function public.promote_journey_to_active(p_match_id uuid)
 returns void language plpgsql security definer set search_path to 'public'
as $function$
DECLARE m RECORD; caller UUID := auth.uid(); v_attempt UUID;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match'; END IF;
  IF m.status <> 'potential' THEN
    RAISE EXCEPTION 'match is not in potential state (status=%)', m.status; END IF;
  -- UNCHANGED (2026-08-07): re-checked at promotion, not only at creation.
  IF NOT public.zyra_can_match(m.seeker_a_id, m.seeker_b_id) THEN
    RAISE EXCEPTION 'not_eligible_to_match'
      USING HINT='Something has changed since this match was made — a '
                 'Guardian relationship or a block now exists between you.';
  END IF;
  -- UNCHANGED, and kept even though step 6's trigger backstops it: this
  -- gives a clear message before the trigger fires. The trigger is the
  -- race-proof guarantee (audit R7: SELECT INTO takes no row lock).
  IF EXISTS (SELECT 1 FROM matches WHERE status='active'
      AND (seeker_a_id IN (m.seeker_a_id,m.seeker_b_id)
        OR seeker_b_id IN (m.seeker_a_id,m.seeker_b_id))) THEN
    RAISE EXCEPTION 'one_active_journey_limit'
      USING HINT='You already have an Active Journey. End or pause it before starting another.';
  END IF;

  UPDATE matches SET status='active', journey_stage='compatibility_reveal' WHERE id=p_match_id;

  -- NEW. The omission that gated steps 4, 6 and 7.
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id
   ORDER BY (a.status <> 'ended') DESC, a.attempt_number DESC LIMIT 1;
  IF v_attempt IS NULL THEN RAISE EXCEPTION 'no_attempt_for_match'; END IF;
  UPDATE journey_attempts
     SET status='active', journey_stage='compatibility_reveal',
         started_at = COALESCE(started_at, NOW())
   WHERE id = v_attempt;
END; $function$;

create or replace function public.zyra_end_match_internal(p_match_id uuid, p_ended_by uuid, p_reason text)
 returns void language plpgsql security definer set search_path to 'public'
as $function$
DECLARE m RECORD; v_attempt UUID; v_timeline_id UUID; v_other UUID; v_ender_name TEXT;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND OR m.status = 'ended' THEN RETURN; END IF;
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status <> 'ended'
   ORDER BY a.attempt_number DESC LIMIT 1;

  UPDATE matches SET status='ended', ended_at=NOW(), ended_by=p_ended_by,
         end_reason=p_reason, suspended_by=NULL, suspended_at=NULL
   WHERE id = p_match_id;
  UPDATE journey_attempts SET status='ended', ended_at=NOW(), ended_by=p_ended_by,
         end_reason=p_reason, paused_by=NULL, paused_at=NULL
   WHERE match_id = p_match_id AND status <> 'ended';
  UPDATE conversations SET status='closed', closed_at=NOW()
   WHERE (v_attempt IS NOT NULL AND attempt_id = v_attempt) AND status <> 'closed';
  SELECT id INTO v_timeline_id FROM timelines
   WHERE (v_attempt IS NOT NULL AND attempt_id = v_attempt);
  IF v_timeline_id IS NOT NULL THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type)
      VALUES (v_timeline_id, 'journey_ended');
  END IF;

  -- UNCHANGED — OPTION B. SEEKERS ONLY: the body carries the counterpart's
  -- name, and after Step 1 a Guardian may not be entitled to it.
  IF p_ended_by IS NOT NULL THEN
    v_other := CASE WHEN m.seeker_a_id = p_ended_by THEN m.seeker_b_id ELSE m.seeker_a_id END;
    SELECT first_name INTO v_ender_name FROM profiles WHERE id = p_ended_by;
    PERFORM create_notification(v_other,'journey_ended','Journey ended',
      'Your Journey with '||COALESCE(v_ender_name,'someone')||' has ended.', p_match_id);
  END IF;
END; $function$;

create or replace function public.end_journey(p_match_id uuid)
 returns void language plpgsql security definer set search_path to 'public'
as $function$
DECLARE m RECORD; caller UUID := auth.uid();
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match'; END IF;
  IF m.status = 'ended' THEN RAISE EXCEPTION 'already ended'; END IF;
  PERFORM public.zyra_end_match_internal(p_match_id, caller, NULL);
END; $function$;

create or replace function public.end_journey(p_match_id uuid, p_reason text)
 returns void language plpgsql security definer set search_path to 'public'
as $function$
DECLARE m RECORD; caller UUID := auth.uid();
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match'; END IF;
  IF m.status = 'ended' THEN RAISE EXCEPTION 'already ended'; END IF;
  IF p_reason = 'no_response' THEN
    RAISE EXCEPTION 'reason_is_system_only'
      USING HINT='no_response is recorded by the system, not chosen by a person.';
  END IF;
  IF p_reason IS NOT NULL AND p_reason NOT IN
     ('not_compatible','circumstances_changed','marrying_elsewhere',
      'family_decision','safety_concern','prefer_not_to_say') THEN
    RAISE EXCEPTION 'unknown_end_reason: %', p_reason;
  END IF;
  -- safety_concern permitted: someone may feel unsafe without wanting to
  -- block. Step 0 conceals it from everyone but the person who raised it,
  -- and matches_no_note_on_safety_ending forbids a note. No new disclosure.
  PERFORM public.zyra_end_match_internal(p_match_id, caller, p_reason);
END; $function$;

revoke execute on function public.end_journey(uuid)      from public, anon;
revoke execute on function public.end_journey(uuid,text) from public, anon;
grant  execute on function public.end_journey(uuid)      to authenticated;
grant  execute on function public.end_journey(uuid,text) to authenticated;

-- VERIFIED 2026-08-08, 20/20: attempt goes active with stage and
-- started_at; the attempt pause CHECK now accepts a write (step 4
-- unblocked); a second Active Journey still refused; end sets both rows,
-- records ended_by, closes the conversation and writes the milestone via
-- attempt_id, notifies the other party and not the ender; end with a
-- reason records it on both rows; no_response and unknown reasons
-- refused; safety_concern permitted and still read back as
-- prefer_not_to_say by the other party.
