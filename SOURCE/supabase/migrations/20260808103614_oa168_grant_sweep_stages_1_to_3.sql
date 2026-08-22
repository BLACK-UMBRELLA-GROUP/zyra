-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260808103614, applied name
-- 'oa168_grant_sweep_stages_1_to_3') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- OA-ZYRA-168 — grant sweep, Stages 1-3. Founder-approved 2026-08-08.
--
-- Stage 1: revoke ALL write privileges from 'anon'. Unauthenticated writes
--          are not part of the ZYRA product model.
-- Stage 2: revoke 'authenticated' write privileges that have NO matching RLS
--          policy. Matched grants are retained untouched.
-- Stage 3: change the default privileges so future tables arrive WITHOUT
--          write grants. Stages 1-2 treat instances; Stage 3 treats the class.
--
-- Not used anywhere below: REVOKE ... FROM public. 'anon' and 'authenticated'
-- hold their own explicit grants, so a revoke from PUBLIC reports success and
-- changes nothing. Three prior incidents on this project — invariant I4.
--
-- SECURITY DEFINER functions run as their owner and are unaffected. The one
-- SECURITY INVOKER writer, expire_wali_invite_if_due(), updates wali_invites,
-- whose UPDATE grant is matched by a policy and therefore retained.

do $$
declare
  r record;
  n int := 0;
begin
  -- ---------- Stage 1 : anon, all write privileges ----------
  for r in
    select g.table_name, g.privilege_type
      from information_schema.role_table_grants g
     where g.table_schema = 'public'
       and g.grantee      = 'anon'
       and g.privilege_type in ('INSERT','UPDATE','DELETE','TRUNCATE')
  loop
    execute format('revoke %s on public.%I from anon',
                   r.privilege_type, r.table_name);
    n := n + 1;
  end loop;
  raise notice 'Stage 1 — revoked % anon write grant(s)', n;

  -- ---------- Stage 2 : authenticated, unmatched only ----------
  n := 0;
  for r in
    select g.table_name, g.privilege_type
      from information_schema.role_table_grants g
     where g.table_schema = 'public'
       and g.grantee      = 'authenticated'
       and g.privilege_type in ('INSERT','UPDATE','DELETE','TRUNCATE')
       and not exists (
             select 1
               from pg_policies p
              where p.schemaname = 'public'
                and p.tablename  = g.table_name
                and p.cmd in (g.privilege_type, 'ALL'))
  loop
    execute format('revoke %s on public.%I from authenticated',
                   r.privilege_type, r.table_name);
    n := n + 1;
  end loop;
  raise notice 'Stage 2 — revoked % unmatched authenticated write grant(s)', n;
end $$;

-- ---------- Stage 3 : the durable fix ----------
-- Migrations run as 'postgres', so this is the operative default ACL.
do $$
begin
  execute 'alter default privileges for role postgres in schema public '
          'revoke insert, update, delete, truncate on tables from anon';
  execute 'alter default privileges for role postgres in schema public '
          'revoke insert, update, delete, truncate on tables from authenticated';
  raise notice 'Stage 3a — postgres default ACL updated';
end $$;

-- supabase_admin also holds a default ACL. Objects created by supabase_admin
-- are not part of the ZYRA migration workflow, and postgres may lack the
-- privilege to alter it. Attempted, and skipped cleanly if refused.
do $$
begin
  execute 'alter default privileges for role supabase_admin in schema public '
          'revoke insert, update, delete, truncate on tables from anon';
  execute 'alter default privileges for role supabase_admin in schema public '
          'revoke insert, update, delete, truncate on tables from authenticated';
  raise notice 'Stage 3b — supabase_admin default ACL updated';
exception
  when insufficient_privilege or invalid_grant_operation then
    raise notice 'Stage 3b SKIPPED — cannot alter supabase_admin default ACL. '
                 'Expected: ZYRA migrations run as postgres, so Stage 3a is '
                 'the operative change.';
end $$;
