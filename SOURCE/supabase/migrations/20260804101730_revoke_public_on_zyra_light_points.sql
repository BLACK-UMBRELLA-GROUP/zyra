-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804101730, applied name
-- 'revoke_public_on_zyra_light_points') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- `revoke execute ... from anon` did not remove anon's access to
-- zyra_light_points, because the grant it inherits is the PUBLIC one that
-- Postgres applies to every newly created function — and PUBLIC and a
-- named role are separate grants.
--
-- This is the exact mirror of the earlier miss on
-- seeker_details_for_unlocked, where `revoke ... from public` left anon's
-- own explicit grant intact. Both directions have now bitten once. The
-- rule: revoke from PUBLIC first, then grant only the roles that need it.
--
-- score_candidates was unaffected because it already existed and carried
-- explicit role grants rather than the PUBLIC default — which is why the
-- same statement worked there and silently did nothing here. Caught by
-- checking the actual privilege rather than trusting the earlier statement
-- to have done what it looked like it did.
--
-- zyra_light_points is a pure text->int lookup with no data access, so this
-- is tidiness rather than an exposure. Left correct anyway: a helper that
-- anon can call is a helper someone will one day wire to something that
-- matters.

revoke all on function public.zyra_light_points(text) from public;
revoke all on function public.zyra_light_points(text) from anon;
grant execute on function public.zyra_light_points(text) to authenticated;

revoke all on function public.zyra_all_iso639_1(text[]) from public;
revoke all on function public.zyra_all_iso639_1(text[]) from anon;

revoke all on function public.has_article9_consent() from public;
revoke all on function public.has_article9_consent() from anon;
grant execute on function public.has_article9_consent() to authenticated;
