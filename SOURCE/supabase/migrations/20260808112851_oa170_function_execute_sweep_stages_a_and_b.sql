-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260808112851, applied name
-- 'oa170_function_execute_sweep_stages_a_and_b') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- OA-ZYRA-170 — function EXECUTE sweep, Stages A and B.
-- Founder-approved 2026-08-08. Stage C (audit of 62 authenticated-executable
-- SECURITY DEFINER functions) is deliberately NOT here — separate OA.
--
-- Stage A: revoke the three remaining anon EXECUTE grants in public.
--          All three are SECURITY INVOKER. Two are trigger functions, where
--          EXECUTE is checked at CREATE TRIGGER and not at fire time, so the
--          grant confers nothing. The third is unused by the client and
--          already inert since OA-168 removed anon's write grants.
-- Stage B: stop new functions inheriting anon EXECUTE. Stage A alone would be
--          cleaned up and then undone by the next function written.
--
-- authenticated EXECUTE is untouched, by decision — removing the default
-- would require an explicit grant on every new RPC. Raise separately if the
-- symmetry with tables is wanted.
--
-- REVOKE ... FROM public is not used: anon holds its own explicit grant, so a
-- revoke from PUBLIC reports success and changes nothing (invariant I4).

-- ---------- Stage A ----------
revoke execute on function public.zyra_enforce_guardian_link_allowed()      from anon;
revoke execute on function public.zyra_normalise_profile_identity()         from anon;
revoke execute on function public.expire_wali_invite_if_due(wali_invites)   from anon;

-- ---------- Stage B ----------
-- Migrations run as postgres, so this is the operative default ACL.
alter default privileges for role postgres in schema public
  revoke execute on functions from anon;

-- supabase_admin also holds a default ACL. Attempted, and skipped cleanly if
-- postgres lacks the privilege — the same known gap recorded in OA-168 §3.
do $$
begin
  execute 'alter default privileges for role supabase_admin in schema public '
          'revoke execute on functions from anon';
  raise notice 'Stage B (supabase_admin) — applied';
exception
  when insufficient_privilege or invalid_grant_operation then
    raise notice 'Stage B (supabase_admin) SKIPPED — postgres cannot alter it. '
                 'Expected; ZYRA migrations run as postgres.';
end $$;
