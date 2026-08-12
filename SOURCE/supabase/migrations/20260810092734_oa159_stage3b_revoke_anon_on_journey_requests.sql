-- OA-ZYRA-159 · correction to stage 3, found by its own verification run.
--
-- Stage 3 revoked INSERT, UPDATE and DELETE from anon but not SELECT, and
-- Supabase's default privileges grant SELECT on a new public table to anon.
-- So `anon` held a table-level SELECT on journey_requests.
--
-- NO ROWS WERE EXPOSED: RLS is enabled and journey_requests_select is
-- TO authenticated, so an anonymous PostgREST call matches no policy and
-- returns an empty set. The leak is the table's existence and shape, not its
-- contents.
--
-- Fixed anyway, for two reasons. On 2026-08-08 this project found four of its
-- own tables sitting in `public` readable by anon, and the lesson recorded
-- then was that `public` is PostgREST-exposed and a grant you did not intend
-- is a grant you will not remember. And "no rows today" is a property of one
-- policy: the day someone adds a policy TO public, the grant decides what
-- happens, and nobody will re-read this migration first.
--
-- REVOKE ALL, not REVOKE SELECT — the same reason protection_holds used it.
-- An enumerated revoke is a list somebody has to keep correct.

REVOKE ALL ON public.journey_requests FROM anon;

-- Restated so this file is complete on its own: the intended end state is
-- SELECT for authenticated and nothing else for anyone.
REVOKE INSERT, UPDATE, DELETE ON public.journey_requests FROM authenticated;
GRANT SELECT ON public.journey_requests TO authenticated;
