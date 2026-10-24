-- OA-ZYRA-305 / F05: close arbitrary-account raw progress helper RPCs.
-- LOCAL CANDIDATE ONLY; no live apply is authorised by preparing this file.
-- The app already calls caller-pinned zyra_my_onboarding_progress(). Keep its
-- body/ACL and all definer-trigger/server maintenance paths unchanged.
-- No linked Guardian, visible profile or paid tier gains private progress.
--
-- Companion: zyra_refresh_onboarding_complete(uuid) is an arbitrary-account
-- mutation helper, not a client entry point. Revoke its ordinary EXECUTE too;
-- definer triggers and existing trusted server callers retain the same body.
-- Prestate: dated audit SHA256
-- a3f02c512d31bdc1a3ae7b8e860c4f188e1b5d903bae98a6671a5ead3db9c4fb
-- confirms signatures, SD/search_path and ordinary EXECUTE. Body sentinels
-- derive from retained statements; root independently confirmed all four raw
-- helper and wrapper body pins in fresh 2026-10-05 metadata-only catalog evidence
-- (oa305FreshProgressCatalog). The exact fresh receipt belongs in the GO packet;
-- source matching is not itself production permission. Fail closed on drift.
-- MD5 values are drift sentinels, not cryptographic security claims.
-- Rollback: revoke-only is transactionally reversible before commit. Never
-- reopen the arbitrary-user oracle as a routine rollback; fix the caller or
-- server path under separate exact approval while retaining this denial.

begin;
set local lock_timeout = '5s';
set local statement_timeout = '30s';

do $f05$
declare
  v_sig text;
  v_expected text;
  v_volatility "char";
  v_proc record;
  v_wrapper_acl text;
  v_wrapper_body text;
  v_service boolean;
begin
  if pg_catalog.to_regprocedure('public.zyra_my_onboarding_progress()') is null
     or pg_catalog.to_regprocedure('public.zyra_profiles_set_onboarding_complete()') is null
     or pg_catalog.to_regprocedure('public.zyra_answers_refresh_onboarding_complete()') is null
     or pg_catalog.to_regprocedure('public.zyra_refresh_onboarding_complete(uuid)') is null then
    raise exception 'F05 precondition: caller/maintenance paths missing';
  end if;
  select p.proacl::text, pg_catalog.md5(p.prosrc)
    into v_wrapper_acl, v_wrapper_body
  from pg_catalog.pg_proc p
  where p.oid = 'public.zyra_my_onboarding_progress()'::regprocedure
    and p.prosecdef and p.provolatile = 's'
    and pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
    and p.proconfig = array['search_path=public'];
  if v_wrapper_body is distinct from '7215c628ed5a334a59ed54b8db9e783a'
     or not pg_catalog.has_function_privilege(
       'authenticated', 'public.zyra_my_onboarding_progress()', 'execute')
     or pg_catalog.has_function_privilege(
       'anon', 'public.zyra_my_onboarding_progress()', 'execute') then
    raise exception 'F05 precondition: caller-pinned progress wrapper drifted';
  end if;

  for v_sig, v_expected, v_volatility in select * from (values
    ('public.zyra_onboarding_missing(uuid)', 'dbfb80f610c3af4c411e8bb2f6935ad2', 's'::"char"),
    ('public.zyra_onboarding_complete(uuid)', '4e6c7b38429028e0740ba69aa6c7183b', 's'::"char"),
    ('public.zyra_onboarding_data_complete(uuid,text)', '2e227193321ff532b39605807d194790', 's'::"char"),
    ('public.zyra_refresh_onboarding_complete(uuid)', '5459c5009b237eac0031ddd4786ee2d8', 'v'::"char")
  ) pins(signature, body_md5, volatility) loop
    select p.* into v_proc from pg_catalog.pg_proc p
      where p.oid = pg_catalog.to_regprocedure(v_sig);
    if not found or not v_proc.prosecdef or v_proc.provolatile <> v_volatility
       or v_proc.proconfig is distinct from array['search_path=public']
       or pg_catalog.pg_get_userbyid(v_proc.proowner) <> 'postgres'
       or pg_catalog.md5(v_proc.prosrc) <> v_expected
       or not pg_catalog.has_function_privilege('authenticated', v_sig, 'execute')
       or pg_catalog.has_function_privilege('anon', v_sig, 'execute') then
      raise exception 'F05 precondition: captured raw helper drifted: %', v_sig;
    end if;
    -- No unknown client role can remain reachable through a retained grant.
    -- Existing server/owner privileges are not invented or widened.
    if exists (select 1 from pg_catalog.aclexplode(coalesce(v_proc.proacl,
        pg_catalog.acldefault('f', v_proc.proowner))) a
        where a.privilege_type = 'EXECUTE' and a.grantee not in (
          0, (select oid from pg_catalog.pg_roles where rolname = 'anon'),
          (select oid from pg_catalog.pg_roles where rolname = 'authenticated'),
          (select oid from pg_catalog.pg_roles where rolname = 'service_role'),
          v_proc.proowner)) then
      raise exception 'F05 precondition: unexpected helper grantee: %', v_sig;
    end if;
    v_service := pg_catalog.has_function_privilege('service_role', v_sig, 'execute');
    execute pg_catalog.format('revoke execute on function %s from public, anon, authenticated', v_sig);
    if pg_catalog.has_function_privilege('anon', v_sig, 'execute')
       or pg_catalog.has_function_privilege('authenticated', v_sig, 'execute')
       or pg_catalog.has_function_privilege('service_role', v_sig, 'execute')
          is distinct from v_service
       or not pg_catalog.has_function_privilege('postgres', v_sig, 'execute')
       or (select pg_catalog.md5(p.prosrc) from pg_catalog.pg_proc p
           where p.oid = pg_catalog.to_regprocedure(v_sig)) <> v_expected then
      raise exception 'F05 postcondition: helper denial/internal rights changed: %', v_sig;
    end if;
  end loop;
  if (select p.proacl::text from pg_catalog.pg_proc p
      where p.oid = 'public.zyra_my_onboarding_progress()'::regprocedure)
       is distinct from v_wrapper_acl
     or (select pg_catalog.md5(p.prosrc) from pg_catalog.pg_proc p
         where p.oid = 'public.zyra_my_onboarding_progress()'::regprocedure)
       is distinct from v_wrapper_body then
    raise exception 'F05 postcondition: caller wrapper altered';
  end if;
end;
$f05$;

commit;
