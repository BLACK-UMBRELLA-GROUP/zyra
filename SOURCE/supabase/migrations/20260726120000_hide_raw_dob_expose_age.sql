-- Server-computed age instead of raw DOB exposure (Founder decision,
-- 2026-07-26 — see REPORTS/CURRENT/ZYRA_FABLE_BUILD_REVIEW_2026-07-19_V1.md
-- §Open Decisions item 2).
--
-- Problem: profiles_select (20260718192519_optimize_rls_auth_uid_
-- initplan.sql) makes any active+complete profile row visible to any
-- signed-in user — required for Browse/Matches/Journey to work at
-- all. But that row includes `date_of_birth`, so every other Seeker's
-- exact birthdate is readable by any signed-in user, not just their
-- age. Nothing in the Flutter app re-reads a user's OWN date_of_birth
-- from the database (AppState.dob is populated client-side once,
-- during Chapter 1 onboarding, and never re-fetched) — the only
-- reads of this column are the four call sites below, all of which
-- want an age, not a birthdate.
--
-- Fix: column-level REVOKE so `date_of_birth` cannot be selected by
-- the client at all (own row or anyone else's), plus a SECURITY
-- DEFINER function that returns only the derived `age` for a batch of
-- profile ids. This keeps the existing profiles_select row-visibility
-- policy untouched (Browse still needs to see the row), while the one
-- sensitive column is no longer readable by PostgREST regardless of
-- row visibility. The function runs as its owner (bypasses the column
-- revoke, same mechanism already used by preview_wali_invite/
-- accept_wali_invite), so it's the only path back to date_of_birth
-- from the client.
--
-- Call sites updated in this batch: zyra_discovery_service.dart,
-- zyra_match_service.dart, zyra_journey_service.dart (x2).

REVOKE SELECT (date_of_birth) ON public.profiles FROM authenticated, anon;

CREATE OR REPLACE FUNCTION public.ages_for(p_ids UUID[])
RETURNS TABLE(id UUID, age INT)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p.id, EXTRACT(YEAR FROM age(current_date, p.date_of_birth))::int
  FROM public.profiles p
  WHERE p.id = ANY(p_ids);
$$;

REVOKE ALL ON FUNCTION public.ages_for(UUID[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.ages_for(UUID[]) TO authenticated;
