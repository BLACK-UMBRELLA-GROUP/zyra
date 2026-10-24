-- OA-ZYRA-305 / F01 exact second-application refusal preparation.
-- LOCAL SYNTHETIC FIXTURE ONLY. Run after the F01 replay in a fresh psql
-- session with ON_ERROR_STOP on, then run the exact canonical migration in a
-- separate session. That run MUST exit nonzero with the known message:
--   F01 precondition: account/reference columns drifted
-- A syntax/permission/connection/crash failure is NOT the expected refusal.
-- Finally run zyra_oa305_f01_refusal_postcheck.sql in another fresh session.
-- The deliberately persistent fixture snapshot crosses these sessions. It is
-- not a production table, physical backup, or an idempotent migration claim.
\set ON_ERROR_STOP on

do $guard$
begin
  if pg_catalog.current_database() !~ '^zyra_oa305_f01_[a-z0-9_]+$'
     or pg_catalog.current_setting('zyra.oa305_f01_local_replay', true)
       is distinct from 'enabled'
     or (select array_agg(attname::text order by attnum)
         from pg_catalog.pg_attribute
         where attrelid = 'auth.users'::regclass
           and attnum > 0 and not attisdropped) <> array['id']::text[]
     or pg_catalog.to_regnamespace('zyra_f01_refusal_fixture') is not null then
    raise exception 'F01 refusal requires a fresh explicitly armed local fixture';
  end if;
  if exists (select 1 from public.profile_reports)
     or exists (select 1 from public.profiles)
     or exists (select 1 from auth.users)
     or exists (select 1 from storage.objects)
     or (select count(*) from pg_catalog.pg_constraint
         where conrelid = 'public.profile_reports'::regclass
           and contype = 'f' and confdeltype = 'n') <> 2
     or exists (select 1 from pg_catalog.pg_attribute
         where attrelid = 'public.profile_reports'::regclass
           and attname in ('reporter_id', 'reported_id') and attnotnull) then
    raise exception 'F01 refusal requires empty synthetic F01 poststate';
  end if;
end;
$guard$;

begin;
create schema zyra_f01_refusal_fixture;
revoke all on schema zyra_f01_refusal_fixture from public, anon, authenticated;
create function zyra_f01_refusal_fixture.metadata() returns jsonb
language sql stable set search_path = pg_catalog as $$
  select jsonb_build_object(
    'tables', (select jsonb_agg(jsonb_build_object(
      'oid', c.oid, 'name', c.oid::regclass::text, 'owner', c.relowner,
      'acl', c.relacl::text, 'rls', c.relrowsecurity,
      'force_rls', c.relforcerowsecurity,
      'comment', obj_description(c.oid, 'pg_class')) order by c.oid)
      from pg_class c where c.oid in ('public.profile_reports'::regclass,
        'public.profiles'::regclass, 'auth.users'::regclass,
        'storage.objects'::regclass)),
    'columns', (select jsonb_agg(jsonb_build_object(
      'table', a.attrelid, 'name', a.attname, 'type', a.atttypid,
      'number', a.attnum, 'notnull', a.attnotnull,
      'default', pg_get_expr(d.adbin, d.adrelid), 'acl', a.attacl::text,
      'comment', col_description(a.attrelid, a.attnum))
      order by a.attrelid, a.attnum)
      from pg_attribute a left join pg_attrdef d
        on d.adrelid = a.attrelid and d.adnum = a.attnum
      where a.attrelid in ('public.profile_reports'::regclass,
        'public.profiles'::regclass, 'auth.users'::regclass,
        'storage.objects'::regclass) and a.attnum > 0 and not a.attisdropped),
    'constraints', (select jsonb_agg(jsonb_build_object(
      'oid', c.oid, 'table', c.conrelid, 'name', c.conname,
      'definition', pg_get_constraintdef(c.oid),
      'comment', obj_description(c.oid, 'pg_constraint')) order by c.oid)
      from pg_constraint c where c.conrelid in (
        'public.profile_reports'::regclass, 'public.profiles'::regclass,
        'auth.users'::regclass, 'storage.objects'::regclass)),
    'policies', (select jsonb_agg(jsonb_build_object(
      'table', p.polrelid, 'name', p.polname, 'cmd', p.polcmd,
      'roles', p.polroles, 'permissive', p.polpermissive,
      'using', pg_get_expr(p.polqual, p.polrelid),
      'check', pg_get_expr(p.polwithcheck, p.polrelid))
      order by p.polrelid, p.polname)
      from pg_policy p where p.polrelid in (
        'public.profile_reports'::regclass, 'public.profiles'::regclass,
        'auth.users'::regclass, 'storage.objects'::regclass)),
    'indexes', (select jsonb_agg(pg_get_indexdef(i.indexrelid)
      order by i.indexrelid) from pg_index i where i.indrelid in (
        'public.profile_reports'::regclass, 'public.profiles'::regclass,
        'auth.users'::regclass, 'storage.objects'::regclass)),
    'triggers', (select jsonb_agg(jsonb_build_object(
      'oid', t.oid, 'definition', pg_get_triggerdef(t.oid)) order by t.oid)
      from pg_trigger t where t.tgrelid in (
        'public.profile_reports'::regclass, 'public.profiles'::regclass,
        'auth.users'::regclass, 'storage.objects'::regclass)),
    'rpcs', (select jsonb_agg(jsonb_build_object(
      'oid', p.oid, 'owner', p.proowner, 'acl', p.proacl::text,
      'definition', pg_get_functiondef(p.oid)) order by p.oid)
      from pg_proc p where p.oid in (
        'public.delete_own_account()'::regprocedure,
        'public.zyra_my_safety_cases()'::regprocedure))
  );
$$;
revoke all on function zyra_f01_refusal_fixture.metadata()
  from public, anon, authenticated;
create table zyra_f01_refusal_fixture.before (
  singleton boolean primary key check (singleton), value jsonb not null
);
revoke all on zyra_f01_refusal_fixture.before from public, anon, authenticated;
insert into zyra_f01_refusal_fixture.before
  values (true, zyra_f01_refusal_fixture.metadata());
commit;
\echo F01REFUSAL_READY exact second candidate must fail at the known precondition
