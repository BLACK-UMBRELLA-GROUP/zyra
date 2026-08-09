-- ═══════════════════════════════════════════════════════════════════════
-- OA-ZYRA-174 — resolved: GRANDFATHER.
--
-- Founder decision 2026-08-08. Tier-1 (DR-ZYRA-123) is a rule about who
-- may be MATCHED. It is not a dissolution rule. A Journey that already
-- exists predates the shared-Guardian bond and is not undone by it.
--
-- THE DEFECT THIS CLOSES
-- zyra_can_match() is consulted at four gates: the likes/passes/saves RLS
-- insert policies, create_match_on_mutual_like(), promote_journey_to_
-- active(), and resume_journey(). An active, UNPAUSED Journey is not one
-- of them. So when Tier-1 went into zyra_can_match() this morning it
-- silently acquired a fifth meaning nobody decided: a pair who acquired a
-- shared Guardian mid-Journey carried on untouched if they never paused,
-- and became permanently un-resumable if they paused once. Enforcement
-- depended on whether they happened to press a button. I3 (one path) and
-- I4 (enforce at the unskippable layer).
--
-- Found by running zyra_journey_suite.sql end to end for the first time;
-- it threw at assertion 29. No live exposure at the time (zero matches in
-- status potential or active, measured 2026-08-08).
--
-- THE LINE THIS DRAWS
-- resume_journey() now checks only what two parties did to each other
-- deliberately:
--   · a BLOCK       — an explicit act by one of them; terminal (I2)
--   · TIER-0        — one now guards the other; an explicit act by both
--                     (invite plus accept)
-- and no longer checks:
--   · TIER-1        — an inference from a THIRD party's action. Neither
--                     Seeker did anything. Grandfathered.
--
-- Deliberately NOT re-checked at resume: role and gender. Those cannot
-- have changed without the Journey having been illegitimate at creation,
-- and re-checking role would rebuild exactly this trap once the dual-role
-- work deletes profiles.role. A check that can only fail through data
-- corruption adds a trap, not a guard.
--
-- zyra_can_match() itself is UNCHANGED. Tier-1 still blocks new Likes,
-- new matches and promotion. Only continuation is grandfathered.
--
-- NOTE, measured after applying: Tier-0 cannot actually ARISE mid-Journey
-- either — zyra_enforce_guardian_link_allowed() refuses a Guardian link
-- over a live Journey with 'romantic_edge_exists'. The Tier-0 branch below
-- is therefore defence in depth against a direct write or a future path,
-- not the primary guard. Covered by suite assertions 63 and 64.
-- ═══════════════════════════════════════════════════════════════════════

create or replace function public.zyra_can_continue_journey(p_a uuid, p_b uuid)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select not exists (
           select 1 from public.profile_blocks x
           where (x.blocker_id = p_a and x.blocked_id = p_b)
              or (x.blocker_id = p_b and x.blocked_id = p_a))
     and not exists (
           select 1 from public.wali_links w
           where w.status = 'active'
             and (   (w.seeker_id = p_a and w.wali_id = p_b)
                  or (w.seeker_id = p_b and w.wali_id = p_a)));
$$;

comment on function public.zyra_can_continue_journey(uuid, uuid) is
  'OA-ZYRA-174. May an EXISTING Journey continue? Blocks and Tier-0 only. '
  'Not zyra_can_match: Tier-1 is a matching rule, grandfathered for '
  'Journeys already under way. Internal predicate — not client-callable.';

-- Internal predicate. resume_journey() is SECURITY DEFINER and runs as the
-- owner, so no client needs EXECUTE. Revoking explicitly because the
-- default grant to PUBLIC is exactly how zyra_enforce_one_active_match()
-- was left open earlier today.
revoke all on function public.zyra_can_continue_journey(uuid, uuid) from public;
revoke all on function public.zyra_can_continue_journey(uuid, uuid) from anon;
revoke all on function public.zyra_can_continue_journey(uuid, uuid) from authenticated;

create or replace function public.resume_journey(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
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
  other_id := CASE WHEN m.seeker_a_id = caller THEN m.seeker_b_id ELSE m.seeker_a_id END;
  -- UNCHANGED, still from `matches` — authoritative until step 7.
  IF EXISTS (SELECT 1 FROM matches WHERE status='active' AND id <> p_match_id
               AND (seeker_a_id = other_id OR seeker_b_id = other_id)) THEN
    RAISE EXCEPTION 'other_party_in_active_journey'
      USING HINT='This Journey stays paused for now. You can wait, or end it '
                 'yourself if you would rather.';
  END IF;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status <> 'ended'
   ORDER BY (a.status='active') DESC, a.attempt_number DESC LIMIT 1;

  UPDATE matches SET suspended_by = NULL, suspended_at = NULL WHERE id = p_match_id;
  UPDATE journey_attempts SET paused_by = NULL, paused_at = NULL
   WHERE v_attempt IS NOT NULL AND id = v_attempt;
  UPDATE conversations SET status='active'
   WHERE v_attempt IS NOT NULL AND attempt_id = v_attempt AND status='paused';
END; $function$;

-- ─── CLIENT COUNTERPART ────────────────────────────────────────────────
-- The raised error code changed from 'not_eligible_to_match' to
-- 'not_eligible_to_continue'. Checked: the Dart matched only on
-- 'other_party_in_active_journey', so nothing broke — but resumeJourney()
-- would have rethrown the new code raw. SOURCE/lib/services/
-- zyra_journey_service.dart now catches it as
-- NotEligibleToContinueException, alongside the existing named exceptions.
