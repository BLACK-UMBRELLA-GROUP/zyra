-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260807222532, applied name
-- 'revoke_anon_execute_on_my_two_functions') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Second attempt at the same fix, and the reason is worth recording.
--
-- The previous migration did `REVOKE EXECUTE ... FROM public`, which is
-- what you do when a function leaked to everyone via the CREATE FUNCTION
-- default. It changed nothing: both functions still reported
-- anon_can_run = true.
--
-- The ACL shows why:
--
--   zyra_reset_profile  {postgres=X, anon=X, authenticated=X, service_role=X}
--   zyra_unlock_profile {postgres=X,         authenticated=X, service_role=X}
--
-- `anon` holds its OWN explicit grant, from Supabase's ALTER DEFAULT
-- PRIVILEGES, not an inherited PUBLIC one. Revoking PUBLIC leaves it
-- untouched.
--
-- This is the third time this project has been bitten by the same fact —
-- PUBLIC, anon and authenticated are three independent grants — and the
-- second time TODAY, once creating these functions and once trying to fix
-- them. Recorded rather than quietly corrected, because the lesson keeps
-- not sticking: after any grant change, VERIFY with
-- has_function_privilege(), never assume the statement did what it reads
-- like it did.
--
-- zyra_unlock_profile above is the shape every other function in this
-- schema already has, and is what these two now match.

revoke execute on function public.zyra_reset_profile() from anon;
revoke execute on function public.zyra_submit_feedback(text,text,text,text,text) from anon;
