-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804110133, applied name
-- 'revoke_authenticated_on_trigger_functions') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Trigger functions should be callable by nobody. They are invoked by the
-- trigger machinery, which does not consult EXECUTE grants at all.
--
-- THIRD TIME TODAY the same trap has bitten, in its third permutation:
--
--   morning     revoke FROM PUBLIC   left anon's explicit grant
--   afternoon   revoke FROM anon     left the PUBLIC grant
--   now         revoke FROM public+anon   left the AUTHENTICATED grant
--
-- PUBLIC, anon and authenticated are three independent grants and revoking
-- any one says nothing about the other two. The only reliable idiom is
-- REVOKE ALL FROM PUBLIC, anon, authenticated and then grant back exactly
-- what is needed — which is what this does, granting nothing back.
--
-- Not exploitable as it stood: Postgres refuses to execute a function
-- returning `trigger` outside a trigger context. Fixed because the
-- Supabase advisor flags it, and an advisor with known-ignorable warnings
-- is an advisor nobody reads.

do $$
declare f record;
begin
  for f in
    select p.oid::regprocedure::text as sig
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prorettype = 'trigger'::regtype
  loop
    execute format('revoke all on function %s from public, anon, authenticated', f.sig);
  end loop;
end $$;
