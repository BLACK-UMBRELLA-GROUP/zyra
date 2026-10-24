-- OA-ZYRA-305 / F01: narrow account-deletion cascade-loss repair.
-- LOCAL CANDIDATE ONLY. Production requires a separate exact Founder GO.
--
-- Preserve the existing report (case ID, submitted evidence, source, status
-- and dates), but detach either deleted account. Do not copy account identity,
-- chat/context, create a new moderator/legal-hold capability, or define expiry.
-- DR-ZYRA-248's reported Guardian Circle message retention is not silently
-- extended to all profile reports. Lawful expiry/hold operations remain a
-- separately governed dependency before production acceptance.
--
-- Catalog prestate: ZYRA_FULL_APP_AUDIT_2026-10-03_EVIDENCE.json, SHA256
-- a3f02c512d31bdc1a3ae7b8e860c4f188e1b5d903bae98a6671a5ead3db9c4fb.
-- pg_get_functiondef MD5 values below are exact drift sentinels, not security
-- hashes. The full artifact and catalog SHA256 pins belong in the GO packet.
-- The caller-pinned deletion RPC, Storage cleanup, SELECT policy, grants,
-- safety-case RPC and other account cascades are deliberately unchanged.
-- INSERT additionally requires a non-NULL target, preserving the pre-repair
-- submission requirement while historical FK detachment remains permitted.
--
-- Rollback: before commit, PostgreSQL rolls back the entire change. After
-- deleted-party NULLs exist, never restore NOT NULL/CASCADE or erase evidence
-- to force a rollback. Keep this privacy-preserving shape and forward-repair;
-- an exact restore/retention plan and separate approval are required.

begin;
set local lock_timeout = '5s';
set local statement_timeout = '30s';

do $f01$
declare
  v_reporter smallint;
  v_reported smallint;
  v_profile_id smallint;
  v_auth_id smallint;
  v_columns text[];
  v_policy record;
  v_predicate text;
begin
  if pg_catalog.to_regclass('public.profile_reports') is null
     or pg_catalog.to_regclass('public.profiles') is null
     or pg_catalog.to_regclass('auth.users') is null
     or pg_catalog.to_regprocedure('public.delete_own_account()') is null
     or pg_catalog.to_regprocedure('public.zyra_my_safety_cases()') is null then
    raise exception 'F01 precondition: required captured objects missing';
  end if;

  -- Parent-first lock order matches the account-deletion cascade. Stop on
  -- contention, rather than waiting indefinitely while account rights stall.
  lock table public.profiles in share row exclusive mode;
  lock table public.profile_reports in access exclusive mode;

  select array_agg(a.attname::text order by a.attnum)
    into v_columns
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.profile_reports'::regclass
    and a.attnum > 0 and not a.attisdropped;
  if v_columns is distinct from array[
    'id', 'reporter_id', 'reported_id', 'reason', 'detail', 'source',
    'status', 'created_at', 'reviewed_at'
  ]::text[] then
    raise exception 'F01 precondition: profile report shape drifted';
  end if;

  select a.attnum into v_reporter
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.profile_reports'::regclass
    and a.attname = 'reporter_id' and a.attnotnull
    and a.atttypid = 'uuid'::regtype and not a.attisdropped;
  select a.attnum into v_reported
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.profile_reports'::regclass
    and a.attname = 'reported_id' and a.attnotnull
    and a.atttypid = 'uuid'::regtype and not a.attisdropped;
  select a.attnum into v_profile_id
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.profiles'::regclass and a.attname = 'id'
    and a.atttypid = 'uuid'::regtype and not a.attisdropped;
  select a.attnum into v_auth_id
  from pg_catalog.pg_attribute a
  where a.attrelid = 'auth.users'::regclass and a.attname = 'id'
    and a.atttypid = 'uuid'::regtype and not a.attisdropped;
  if v_reporter is null or v_reported is null
     or v_profile_id is null or v_auth_id is null then
    raise exception 'F01 precondition: account/reference columns drifted';
  end if;

  if (select count(*) from pg_catalog.pg_constraint c
      where c.conrelid = 'public.profile_reports'::regclass
        and c.contype = 'f') <> 2
     or (select count(*) from pg_catalog.pg_constraint c
         where c.conrelid = 'public.profile_reports'::regclass
           and c.contype = 'f'
           and c.confrelid = 'public.profiles'::regclass
           and c.confkey = array[v_profile_id]
           and c.confdeltype = 'c' and c.confupdtype = 'a'
           and c.confmatchtype = 's' and c.convalidated
           and not c.condeferrable and not c.condeferred
           and pg_catalog.obj_description(c.oid, 'pg_constraint') is null
           and ((c.conname = 'profile_reports_reporter_id_fkey'
                 and c.conkey = array[v_reporter])
             or (c.conname = 'profile_reports_reported_id_fkey'
                 and c.conkey = array[v_reported]))) <> 2
     or not exists (
       select 1 from pg_catalog.pg_constraint c
       where c.conrelid = 'public.profiles'::regclass
         and c.conname = 'profiles_id_fkey' and c.contype = 'f'
         and c.confrelid = 'auth.users'::regclass
         and c.conkey = array[v_profile_id] and c.confkey = array[v_auth_id]
         and c.confdeltype = 'c' and c.confupdtype = 'a'
         and c.convalidated and not c.condeferrable
     ) then
    raise exception 'F01 precondition: captured cascade constraints drifted';
  end if;

  if not exists (
    select 1 from pg_catalog.pg_class c
    where c.oid = 'public.profile_reports'::regclass and c.relkind = 'r'
      and c.relrowsecurity and not c.relforcerowsecurity
      and pg_catalog.pg_get_userbyid(c.relowner) = 'postgres'
  ) or (select count(*) from pg_catalog.pg_policy p
        where p.polrelid = 'public.profile_reports'::regclass) <> 2 then
    raise exception 'F01 precondition: report RLS/owner/policy count drifted';
  end if;
  for v_policy in
    select p.*, pg_catalog.pg_get_expr(p.polqual, p.polrelid) as using_expr,
           pg_catalog.pg_get_expr(p.polwithcheck, p.polrelid) as check_expr
    from pg_catalog.pg_policy p
    where p.polrelid = 'public.profile_reports'::regclass
  loop
    if not v_policy.polpermissive or v_policy.polroles <> array[0::oid] then
      raise exception 'F01 precondition: report policy roles drifted';
    end if;
    if v_policy.polname = 'profile_reports_select'
       and v_policy.polcmd = 'r' and v_policy.check_expr is null then
      v_predicate := v_policy.using_expr;
    elsif v_policy.polname = 'profile_reports_insert'
          and v_policy.polcmd = 'a' and v_policy.using_expr is null then
      v_predicate := v_policy.check_expr;
    else
      raise exception 'F01 precondition: report policy operation drifted';
    end if;
    if pg_catalog.regexp_replace(v_predicate, '\s+', '', 'g')
       is distinct from '(reporter_id=(SELECTauth.uid()ASuid))' then
      raise exception 'F01 precondition: caller-scoped report predicate drifted';
    end if;
  end loop;

  if pg_catalog.md5(pg_catalog.pg_get_functiondef(
       'public.delete_own_account()'::regprocedure))
       <> '2efb8da2eeff442900f58afd25d67c0b'
     or pg_catalog.md5(pg_catalog.pg_get_functiondef(
       'public.zyra_my_safety_cases()'::regprocedure))
       <> 'bcb1ad68f65df7d109b6c409450acfb5'
     or pg_catalog.has_function_privilege(
       'anon', 'public.delete_own_account()', 'execute')
     or not pg_catalog.has_function_privilege(
       'authenticated', 'public.delete_own_account()', 'execute')
     or pg_catalog.has_function_privilege(
       'anon', 'public.zyra_my_safety_cases()', 'execute')
     or not pg_catalog.has_function_privilege(
       'authenticated', 'public.zyra_my_safety_cases()', 'execute')
     or pg_catalog.has_table_privilege('anon', 'public.profile_reports', 'select')
     or not pg_catalog.has_table_privilege(
       'authenticated', 'public.profile_reports', 'select')
     or not pg_catalog.has_table_privilege(
       'authenticated', 'public.profile_reports', 'insert') then
    raise exception 'F01 precondition: deletion/status/report authority drifted';
  end if;

  alter table public.profile_reports
    alter column reporter_id drop not null,
    alter column reported_id drop not null,
    drop constraint profile_reports_reporter_id_fkey,
    drop constraint profile_reports_reported_id_fkey,
    add constraint profile_reports_reporter_id_fkey
      foreign key (reporter_id) references public.profiles(id) on delete set null,
    add constraint profile_reports_reported_id_fkey
      foreign key (reported_id) references public.profiles(id) on delete set null;

  -- The old NOT NULL column enforced this at submission. Its removal is for
  -- historical FK detachment only, not anonymous/untargeted new evidence.
  alter policy profile_reports_insert on public.profile_reports
    with check (reporter_id = (select auth.uid()) and reported_id is not null);

  if (select count(*) from pg_catalog.pg_constraint c
      where c.conrelid = 'public.profile_reports'::regclass
        and c.contype = 'f' and c.confdeltype = 'n'
        and c.conname in ('profile_reports_reporter_id_fkey',
                          'profile_reports_reported_id_fkey')) <> 2
     or exists (
       select 1 from pg_catalog.pg_attribute a
       where a.attrelid = 'public.profile_reports'::regclass
         and a.attname in ('reporter_id', 'reported_id') and a.attnotnull
     ) then
    raise exception 'F01 postcondition: detach-without-cascade repair incomplete';
  end if;
end;
$f01$;

commit;
