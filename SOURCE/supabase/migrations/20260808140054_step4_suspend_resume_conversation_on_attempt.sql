-- APPLIED LIVE 2026-08-08, version 20260808140054.
-- OA-ZYRA-156 stage 4e · STEP 4 — suspend/resume. PARTIAL, DELIBERATELY.
-- Authorised by DR-ZYRA-122. See also 20260808140244, which corrects an
-- overstatement in this header that this step's own test caught.
--
-- ⚠️ THE HALF NOT BUILT, AND WHY. Raised, not worked around.
--
-- The plan says "rewrite suspend/resume onto the attempt", and
-- journey_attempts carries paused_by/paused_at for exactly that. Writing
-- them fails on a real Journey:
--
--   attempts_pause_needs_active: CHECK (paused_by IS NULL OR status='active')
--
-- promote_journey_to_active() sets matches.status='active' and DOES NOT
-- TOUCH journey_attempts at all, so an attempt promoted the normal way is
-- still 'potential' and the CHECK rejects the write. Measured 6/6 on the
-- real path 2026-08-08.
--
-- SECOND CONSEQUENCE, worse: the constraint trigger
-- journey_attempts_one_active_per_person fires only AFTER UPDATE OF
-- status to 'active', so on the real path it CANNOT FIRE. The per-person
-- enforcement that looked like scaffolding when DR-ZYRA-122 was approved
-- is inert. Step 6 puts the invariant on `matches` instead.
--
-- Both belong to STEP 5 (rewrite promote and end), which the plan already
-- flags as the behaviour-changing step needing its own review. Making
-- promote maintain attempt status here would be step 5 arriving early
-- inside a step approved as mechanical.
--
-- BUILT: conversation writes key on attempt_id. Pause state stays on
-- `matches`, where it is authoritative and correct.

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
  SELECT plan_type INTO caller_plan FROM subscriptions WHERE user_id = caller AND status='active';
  IF caller_plan IS DISTINCT FROM 'seeker_premium' THEN
    RAISE EXCEPTION 'suspension_requires_one' USING HINT='Journey Suspension requires ZYRA One.';
  END IF;
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id ORDER BY (a.status='active') DESC, a.attempt_number DESC LIMIT 1;
  UPDATE matches SET suspended_by = caller, suspended_at = NOW() WHERE id = p_match_id;
  -- journey_attempts.paused_by intentionally NOT written — see header.
  UPDATE conversations SET status='paused'
   WHERE (v_attempt IS NOT NULL AND attempt_id = v_attempt);
END; $function$;

create or replace function public.resume_journey(p_match_id uuid)
 returns void language plpgsql security definer set search_path to 'public'
as $function$
DECLARE m RECORD; caller UUID := auth.uid(); other_id UUID; v_attempt UUID;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  -- UNCHANGED: V3 section 7 "Only the person who placed a pause may lift it."
  IF caller <> m.suspended_by THEN
    RAISE EXCEPTION 'only the suspending Seeker may resume'; END IF;
  -- UNCHANGED (2026-08-07): a pause is exactly the window in which a
  -- Guardian link or a block is likely to appear.
  IF NOT public.zyra_can_match(m.seeker_a_id, m.seeker_b_id) THEN
    RAISE EXCEPTION 'not_eligible_to_match'
      USING HINT='Something has changed while this was paused — a Guardian '
                 'relationship or a block now exists between you.';
  END IF;
  other_id := CASE WHEN m.seeker_a_id = caller THEN m.seeker_b_id ELSE m.seeker_a_id END;
  -- UNCHANGED, and still read from `matches`: that is where an Active
  -- Journey is recorded. The attempt copy would return nothing (header).
  IF EXISTS (SELECT 1 FROM matches WHERE status='active' AND id <> p_match_id
               AND (seeker_a_id = other_id OR seeker_b_id = other_id)) THEN
    RAISE EXCEPTION 'other_party_in_active_journey'
      USING HINT='This Journey stays paused for now. You can wait, or end it '
                 'yourself if you would rather.';
  END IF;
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id ORDER BY (a.status='active') DESC, a.attempt_number DESC LIMIT 1;
  UPDATE matches SET suspended_by = NULL, suspended_at = NULL WHERE id = p_match_id;
  UPDATE conversations SET status='active'
   WHERE (v_attempt IS NOT NULL AND attempt_id = v_attempt) AND status='paused';
END; $function$;

-- VERIFIED 2026-08-08: pause recorded on matches; conversation paused and
-- resumed via attempt_id; the other party cannot resume; and on the real
-- path a mirrored attempt pause is rejected by attempts_pause_needs_active,
-- which is the finding above rather than a bug in this migration.
