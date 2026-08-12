-- PAUSE BELONGS TO BOTH PLANS, CAPPED — 2026-08-11.
--
-- Founder, on seeing the "Pause needs ZYRA One" dialog: "why does it say
-- zyra one lets you pause a journey when in zyra basic you can also pause
-- a journey its just how much you pause is different with zyra basic and
-- zyra one" — and, asked to pick the canon explicitly: BOTH plans pause,
-- caps 5/10.
--
-- This SUPERSEDES the DR-ZYRA-121 Founder amendment ("Pause stays a ZYRA
-- One capability"), resolving its conflict with the newer Founder-approved
-- entitlements matrix of 2026-08-09 (data/zyra_entitlements.dart):
--
--            ZYRA Basic   ZYRA One
--   Paused        5           10
--
-- The cap counts pauses the CALLER initiated (suspended_by = caller) —
-- "how much YOU pause" — so Journeys the other party paused never eat
-- this allowance, matching how the Paused section already distinguishes
-- "Paused by you" from "Paused by them".
--
-- Error code changes with the rule: suspension_requires_one is RETIRED
-- (nothing raises it after this migration); paused_limit_reached is
-- raised at the cap. The client maps it to a cap dialog that offers the
-- upgrade only where an upgrade would actually change the number.
--
-- ⚠️ THE 5 AND 10 MIRROR data/zyra_entitlements.dart. That file is the
-- specification; if the matrix changes, change BOTH in one commit. (A
-- server-side entitlements function is still the raised-not-built work
-- the dart file's header describes; when it lands, these literals move
-- into it.)

create or replace function public.suspend_journey(p_match_id uuid)
 returns void language plpgsql security definer set search_path to 'public'
as $function$
DECLARE
  m RECORD; caller UUID := auth.uid(); caller_plan TEXT; v_attempt UUID;
  v_cap INT; v_paused INT;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match'; END IF;
  IF m.status <> 'active' THEN RAISE EXCEPTION 'match is not active'; END IF;

  -- CHANGED 2026-08-11: the One-only gate becomes a per-plan cap.
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
  UPDATE matches SET suspended_by=caller, suspended_at=NOW() WHERE id=p_match_id;
  UPDATE journey_attempts SET paused_by=caller, paused_at=NOW()
   WHERE v_attempt IS NOT NULL AND id=v_attempt;
  UPDATE conversations SET status='paused'
   WHERE v_attempt IS NOT NULL AND attempt_id=v_attempt;
END; $function$;

comment on function public.suspend_journey(uuid) is
  'Pause recorded on BOTH matches.suspended_by and journey_attempts.paused_by. '
  'Since 2026-08-11 both plans may pause: cap 5 (Basic) / 10 (ZYRA One) counted '
  'over pauses the caller initiated; raises paused_limit_reached at the cap. '
  'suspension_requires_one is retired.';
