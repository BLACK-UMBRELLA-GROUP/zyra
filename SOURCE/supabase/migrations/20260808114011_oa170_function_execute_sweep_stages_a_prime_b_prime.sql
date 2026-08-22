-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260808114011, applied name
-- 'oa170_function_execute_sweep_stages_a_prime_b_prime') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- OA-ZYRA-170 — Stages A' and B'. Founder-approved 2026-08-08.
--
-- Completes the sweep. Stages A and B revoked anon's EXPLICIT grant and
-- removed anon from the default ACL, both of which worked — and neither of
-- which mattered, because these functions also grant EXECUTE to PUBLIC and
-- anon is a member of PUBLIC.
--
-- Effective privilege is the UNION of a role's own grant, PUBLIC's grant, and
-- anything it inherits. Revoking one path leaves the others standing. This is
-- the fourth time this project has been caught by that relationship and the
-- first in this direction.
--
-- Blast radius, checked before proposing: authenticated, service_role and
-- postgres each hold their own explicit =X entry from Supabase's default ACL,
-- so revoking PUBLIC costs them nothing. anon is the only role that loses
-- anything, which is the objective.

-- ---------- Stage A' : the PUBLIC grant on the two remaining functions ----------
revoke execute on function public.zyra_enforce_guardian_link_allowed() from public;
revoke execute on function public.zyra_normalise_profile_identity()    from public;

-- ---------- Stage B' : PostgreSQL's built-in PUBLIC default ----------
-- Independent of Supabase's pg_default_acl entries: the language grants
-- EXECUTE to PUBLIC on every function at creation unless this says otherwise.
alter default privileges for role postgres in schema public
  revoke execute on functions from public;

do $$
begin
  execute 'alter default privileges for role supabase_admin in schema public '
          'revoke execute on functions from public';
  raise notice 'Stage B'' (supabase_admin) — applied';
exception
  when insufficient_privilege or invalid_grant_operation then
    raise notice 'Stage B'' (supabase_admin) SKIPPED — postgres cannot alter '
                 'it. Same known gap as OA-168 section 3.';
end $$;
