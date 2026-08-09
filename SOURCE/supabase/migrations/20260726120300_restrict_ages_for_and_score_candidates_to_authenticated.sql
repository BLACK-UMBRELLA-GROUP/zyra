-- Reconciliation note (2026-07-26): this migration was applied live to
-- Supabase via the management API before this local file was created —
-- written here afterward so the checked-in migrations folder matches
-- the live database. No functional change from what's live; this file
-- is the record of it.
--
-- Gap found via get_advisors / has_function_privilege: REVOKE ALL ...
-- FROM PUBLIC does not revoke Supabase's own bootstrap grants of
-- EXECUTE directly to the `anon` role on new public-schema functions.
-- ages_for() and score_candidates() are SECURITY DEFINER and must only
-- be callable by signed-in users, not anon.

REVOKE EXECUTE ON FUNCTION public.ages_for(UUID[]) FROM anon;
REVOKE EXECUTE ON FUNCTION public.score_candidates(UUID[]) FROM anon;
