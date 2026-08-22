-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806193028, applied name
-- 'harden_revoke_truncate_from_anon_authenticated') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- SECURITY HARDENING — defence in depth. Deliberately a standalone
-- migration, bundled with no feature work.
--
-- WHAT THIS IS NOT: this is not the fix for a live vulnerability. The
-- TRUNCATE privilege was NOT reachable by any user through the product.
-- PostgREST has no TRUNCATE verb, and the anon/authenticated roles are not
-- directly connectable — they are roles PostgREST SETs into. Nobody could
-- have emptied a table, and nothing suggests anybody tried.
--
-- WHAT IT IS: the removal of a privilege that no part of the system uses,
-- and that RLS cannot constrain. Every other destructive verb on these
-- tables is filtered by row-level policies. TRUNCATE is not — it is a
-- table-level operation, so a policy saying "only your own rows" has no
-- opportunity to apply. It was granted by Supabase's default GRANT ALL,
-- not by any decision here.
--
-- The gap it closes is conditional: IF a SQL-injectable RPC ever shipped,
-- or IF a future component connected as one of these roles, TRUNCATE would
-- turn a row-scoped bug into total data loss with no recovery short of a
-- backup restore. Removing an unused privilege costs nothing and removes
-- that entire branch.
--
-- VERIFIED BEFORE APPLYING — nothing relies on TRUNCATE:
--   * 0 database functions contain the keyword
--   * 0 TRUNCATE-event triggers exist
--   * 0 client-side uses in Dart
--   * dev account reset runs through zyra_dev_reset_account(), which is
--     SECURITY DEFINER and executes as owner, so role grants do not apply
--   * neither role holds CREATE on schema public, so the adjacent TRIGGER
--     grant is not an escalation path either (noted, not changed here —
--     this migration does one thing)

do $$
declare r record;
begin
  for r in
    select quote_ident(schemaname)||'.'||quote_ident(tablename) as t
    from pg_tables where schemaname = 'public'
  loop
    execute format('revoke truncate on table %s from anon', r.t);
    execute format('revoke truncate on table %s from authenticated', r.t);
    -- PUBLIC is a third, independent grant. Revoking from anon and
    -- authenticated has never removed it, and that exact trap has bitten
    -- this project three times in one day.
    execute format('revoke truncate on table %s from public', r.t);
  end loop;
end $$;

-- Without this, the next table created inherits Supabase's default GRANT
-- ALL and quietly puts TRUNCATE back. Surgical: removes only TRUNCATE from
-- the default, leaving SELECT/INSERT/UPDATE/DELETE for RLS to govern.
alter default privileges in schema public revoke truncate on tables from anon;
alter default privileges in schema public revoke truncate on tables from authenticated;
