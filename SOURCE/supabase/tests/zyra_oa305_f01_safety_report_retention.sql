-- OA-ZYRA-305 / F01 synthetic local replay. Includes the exact new candidate.
-- Requires fixtures/zyra_oa305_f01_prestate.sql in an explicitly armed isolated
-- database. Never run on a production/member database. Final ROLLBACK removes
-- all synthetic actors/data. The migration itself commits in this disposable
-- database. Savepoint restoration is NOT physical backup/recovery evidence.
\set ON_ERROR_STOP on

do $guard$
begin
  if pg_catalog.current_database() !~ '^zyra_oa305_f01_[a-z0-9_]+$'
     or pg_catalog.current_setting('zyra.oa305_f01_local_replay', true)
       is distinct from 'enabled'
     or (select array_agg(attname::text order by attnum)
         from pg_catalog.pg_attribute
         where attrelid = 'auth.users'::regclass
           and attnum > 0 and not attisdropped) <> array['id']::text[] then
    raise exception 'F01 replay requires explicitly armed minimal local fixture';
  end if;
end;
$guard$;

-- Reproduce the exact old failure first, solely against synthetic actors and
-- within a rollback. This does not measure historical production data loss.
begin;
do $baseline_loss$
begin
  insert into auth.users(id) values
    ('30500001-0000-4000-8000-000000000001'),
    ('30500001-0000-4000-8000-000000000002');
  insert into public.profiles(id, role) values
    ('30500001-0000-4000-8000-000000000001', 'seeker'),
    ('30500001-0000-4000-8000-000000000002', 'wali');
  insert into public.profile_reports(reporter_id, reported_id, reason, detail)
  values ('30500001-0000-4000-8000-000000000001',
          '30500001-0000-4000-8000-000000000002', 'other',
          'F01 pre-fix synthetic evidence');
  perform set_config('request.jwt.claims',
    '{"sub":"30500001-0000-4000-8000-000000000001","role":"authenticated"}', true);
  execute 'set local role authenticated';
  perform public.delete_own_account();
  execute 'reset role';
  if exists (select 1 from public.profile_reports)
     or exists (select 1 from auth.users
       where id = '30500001-0000-4000-8000-000000000001')
     or not exists (select 1 from auth.users
       where id = '30500001-0000-4000-8000-000000000002') then
    raise exception 'F01FAIL captured pre-fix cascade loss was not reproduced';
  end if;
  raise notice 'F01BASELINE synthetic account deletion cascades away report evidence';
end;
$baseline_loss$;
rollback;

create function pg_temp.f01_metadata() returns jsonb
language sql stable as $$
  select jsonb_build_object(
    'table', (select jsonb_build_object(
      'owner', relowner, 'acl', relacl::text, 'rls', relrowsecurity,
      'force_rls', relforcerowsecurity,
      'comment', obj_description(oid, 'pg_class'))
      from pg_class where oid = 'public.profile_reports'::regclass),
    'columns', (select jsonb_agg(jsonb_build_object(
      'name', a.attname, 'type', a.atttypid, 'number', a.attnum,
      'notnull', case when a.attname in ('reporter_id', 'reported_id')
        then null else a.attnotnull end,
      'default', pg_get_expr(d.adbin, d.adrelid), 'acl', a.attacl::text,
      'comment', col_description(a.attrelid, a.attnum)) order by a.attnum)
      from pg_attribute a left join pg_attrdef d
        on d.adrelid = a.attrelid and d.adnum = a.attnum
      where a.attrelid = 'public.profile_reports'::regclass
        and a.attnum > 0 and not a.attisdropped),
    'policies', (select jsonb_agg(jsonb_build_object(
      'name', polname, 'cmd', polcmd, 'roles', polroles,
      'permissive', polpermissive, 'using', pg_get_expr(polqual, polrelid),
      'check', case when polname = 'profile_reports_insert' then null
        else pg_get_expr(polwithcheck, polrelid) end) order by polname)
      from pg_policy where polrelid = 'public.profile_reports'::regclass),
    'other_constraints', (select jsonb_agg(jsonb_build_object(
      'name', conname, 'definition', pg_get_constraintdef(oid)) order by conname)
      from pg_constraint where conrelid = 'public.profile_reports'::regclass
        and conname not in ('profile_reports_reporter_id_fkey',
                            'profile_reports_reported_id_fkey')),
    'indexes', (select jsonb_agg(pg_get_indexdef(indexrelid) order by indexrelid)
      from pg_index where indrelid = 'public.profile_reports'::regclass),
    'non_fk_triggers', (select jsonb_agg(pg_get_triggerdef(oid) order by tgname)
      from pg_trigger where tgrelid = 'public.profile_reports'::regclass
        and not tgisinternal),
    'rpcs', (select jsonb_agg(jsonb_build_object(
      'name', proname, 'owner', proowner, 'acl', proacl::text,
      'definition', pg_get_functiondef(oid)) order by proname)
      from pg_proc where oid in (
        'public.delete_own_account()'::regprocedure,
        'public.zyra_my_safety_cases()'::regprocedure))
  );
$$;
create temp table f01_metadata_before as select pg_temp.f01_metadata() as value;

\ir ../migrations/20261005113808_oa305_f01_safety_report_retention.sql

begin;
do $metadata$
begin
  if (select value from f01_metadata_before)
       is distinct from pg_temp.f01_metadata() then
    raise exception 'F01FAIL unrelated columns/defaults/comments/indexes/RLS/ACL/RPC changed';
  end if;
  if (select count(*) from pg_constraint
      where conrelid = 'public.profile_reports'::regclass and contype = 'f'
        and confdeltype = 'n') <> 2
     or exists (select 1 from pg_attribute
       where attrelid = 'public.profile_reports'::regclass
         and attname in ('reporter_id', 'reported_id') and attnotnull) then
    raise exception 'F01FAIL exact nullable SET NULL poststate missing';
  end if;
  if (select regexp_replace(pg_get_expr(polwithcheck, polrelid), '\s+', '', 'g')
      from pg_policy where polrelid = 'public.profile_reports'::regclass
        and polname = 'profile_reports_insert') is distinct from
      '((reporter_id=(SELECTauth.uid()ASuid))AND(reported_idISNOTNULL))' then
    raise exception 'F01FAIL required target INSERT predicate differs from exact correction';
  end if;
  raise notice 'F01PASS metadata/ACL/SELECT/RPC unchanged; nullable SET NULL FKs and exact required-target INSERT';
end;
$metadata$;

-- Four report cases: reporter-only deletion, reported-only deletion, both
-- parties deleted, and unaffected. Cover all existing case statuses and both
-- account roles. These fixed UUIDs exist only in this guarded local fixture.
insert into auth.users (id) values
  ('30500001-0000-4000-8000-000000000001'),
  ('30500001-0000-4000-8000-000000000002'),
  ('30500001-0000-4000-8000-000000000003'),
  ('30500001-0000-4000-8000-000000000004'),
  ('30500001-0000-4000-8000-000000000005'),
  ('30500001-0000-4000-8000-000000000006'),
  ('30500001-0000-4000-8000-000000000007'),
  ('30500001-0000-4000-8000-000000000008'),
  ('30500001-0000-4000-8000-000000000009');
insert into public.profiles(id, role)
  select id, case when right(id::text, 1) in ('1', '5') then 'wali' else 'seeker' end
  from auth.users;
insert into public.profile_reports (
  id, reporter_id, reported_id, reason, detail, source, status, created_at, reviewed_at
) values
  ('30500001-0000-4000-8000-000000000101',
   '30500001-0000-4000-8000-000000000001', '30500001-0000-4000-8000-000000000002',
   'harassment', 'F01 synthetic case A context', 'guardian', 'pending',
   '2026-10-01 10:00:00+00', null),
  ('30500001-0000-4000-8000-000000000102',
   '30500001-0000-4000-8000-000000000003', '30500001-0000-4000-8000-000000000004',
   'privacy', 'F01 synthetic case B context', 'profile', 'actioned',
   '2026-10-01 11:00:00+00', '2026-10-02 11:00:00+00'),
  ('30500001-0000-4000-8000-000000000103',
   '30500001-0000-4000-8000-000000000005', '30500001-0000-4000-8000-000000000006',
   'other', 'F01 synthetic case C context', 'journey', 'reviewing',
   '2026-10-01 12:00:00+00', null),
  ('30500001-0000-4000-8000-000000000104',
   '30500001-0000-4000-8000-000000000007', '30500001-0000-4000-8000-000000000008',
   'fake_profile', 'F01 synthetic case D context', 'browse', 'dismissed',
   '2026-10-01 13:00:00+00', '2026-10-02 13:00:00+00');
insert into storage.objects(bucket_id, name) values
  ('profile-photos', '30500001-0000-4000-8000-000000000001/own.jpg'),
  ('profile-photos', '30500001-0000-4000-8000-000000000004/own.jpg'),
  ('profile-photos', '30500001-0000-4000-8000-000000000005/own.jpg'),
  ('profile-photos', '30500001-0000-4000-8000-000000000006/own.jpg'),
  ('profile-photos', '30500001-0000-4000-8000-000000000003/survives.jpg'),
  ('unrelated-bucket', '30500001-0000-4000-8000-000000000001/not-owned-cleanup.jpg');
create temp table f01_evidence_before as
  select jsonb_agg(to_jsonb(r) - 'reporter_id' - 'reported_id' order by r.id) as value,
         jsonb_agg(to_jsonb(r) order by r.id) as original
  from public.profile_reports r;
create temp table f01_users_before as select id from auth.users;
create temp table f01_storage_before as select * from storage.objects;

savepoint f01_delete_replay;

do $delete_cases$
declare
  v_actor uuid;
begin
  foreach v_actor in array array[
    '30500001-0000-4000-8000-000000000001'::uuid,
    '30500001-0000-4000-8000-000000000004'::uuid,
    '30500001-0000-4000-8000-000000000005'::uuid,
    '30500001-0000-4000-8000-000000000006'::uuid
  ] loop
    perform set_config('request.jwt.claims',
      jsonb_build_object('sub', v_actor, 'role', 'authenticated')::text, true);
    execute 'set local role authenticated';
    perform public.delete_own_account();
    -- Retained/stale JWT retry of already-deleted caller is still caller-pinned.
    perform public.delete_own_account();
    execute 'reset role';
    if exists (select 1 from auth.users where id = v_actor)
       or exists (select 1 from public.profiles where id = v_actor)
       or exists (select 1 from storage.objects
         where bucket_id = 'profile-photos' and name like v_actor::text || '/%') then
      raise exception 'F01FAIL account/profile/owned-folder deletion rights blocked';
    end if;
  end loop;

  if (select value from f01_evidence_before) is distinct from (
    select jsonb_agg(to_jsonb(r) - 'reporter_id' - 'reported_id' order by r.id)
    from public.profile_reports r
  ) then
    raise exception 'F01FAIL case IDs/evidence/source/status/dates changed or lost';
  end if;
  if not exists (select 1 from public.profile_reports
      where id = '30500001-0000-4000-8000-000000000101'
        and reporter_id is null
        and reported_id = '30500001-0000-4000-8000-000000000002')
     or not exists (select 1 from public.profile_reports
      where id = '30500001-0000-4000-8000-000000000102'
        and reporter_id = '30500001-0000-4000-8000-000000000003'
        and reported_id is null)
     or not exists (select 1 from public.profile_reports
      where id = '30500001-0000-4000-8000-000000000103'
        and reporter_id is null and reported_id is null)
     or not exists (select 1 from public.profile_reports
      where id = '30500001-0000-4000-8000-000000000104'
        and reporter_id = '30500001-0000-4000-8000-000000000007'
        and reported_id = '30500001-0000-4000-8000-000000000008') then
    raise exception 'F01FAIL reporter/reported/both/unaffected detachment boundary';
  end if;
  if (select count(*) from auth.users) <> 5
     or (select count(*) from public.profiles) <> 5
     or (select count(*) from storage.objects) <> 2 then
    raise exception 'F01FAIL deletion/retry touched unrelated account/object rows';
  end if;
  raise notice 'F01PASS four case states, both roles, repeat deletion; evidence preserved';
end;
$delete_cases$;

do $surviving_reporter$
declare
  v_case record;
  v_count bigint;
  v_changed bigint;
begin
  perform set_config('request.jwt.claims',
    '{"sub":"30500001-0000-4000-8000-000000000003","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select count(*) into v_count from public.profile_reports;
  if v_count <> 1 then raise exception 'F01FAIL surviving reporter lost/is overgranted read'; end if;
  select * into strict v_case from public.zyra_my_safety_cases();
  if v_case.case_id <> '30500001-0000-4000-8000-000000000102'::uuid
     or v_case.case_type <> 'profile' or v_case.status <> 'actioned'
     or v_case.updated_at <> '2026-10-02 11:00:00+00'::timestamptz then
    raise exception 'F01FAIL surviving reporter status projection changed';
  end if;
  update public.profile_reports set status = 'dismissed';
  get diagnostics v_changed = row_count;
  if v_changed <> 0 then raise exception 'F01FAIL member can change evidence status'; end if;
  delete from public.profile_reports;
  get diagnostics v_changed = row_count;
  if v_changed <> 0 then raise exception 'F01FAIL member can retract safety evidence'; end if;
  execute 'reset role';
  raise notice 'F01PASS surviving reporter status/access; member UPDATE/DELETE denied';
end;
$surviving_reporter$;

do $nonparticipants$
declare
  v_actor uuid;
begin
  foreach v_actor in array array[
    '30500001-0000-4000-8000-000000000002'::uuid, -- reported-only survivor
    '30500001-0000-4000-8000-000000000008'::uuid, -- live reported target
    '30500001-0000-4000-8000-000000000009'::uuid, -- unrelated account
    '30500001-0000-4000-8000-000000000001'::uuid  -- deleted reporter/stale JWT
  ] loop
    perform set_config('request.jwt.claims',
      jsonb_build_object('sub', v_actor, 'role', 'authenticated')::text, true);
    execute 'set local role authenticated';
    if exists (select 1 from public.profile_reports)
       or exists (select 1 from public.zyra_my_safety_cases()) then
      raise exception 'F01FAIL target/stranger/deleted-caller can read retained evidence';
    end if;
    execute 'reset role';
  end loop;
  raise notice 'F01PASS reported targets, stranger and stale deleted reporter denied';
end;
$nonparticipants$;

do $null_principal$
begin
  perform set_config('request.jwt.claims', '{"role":"authenticated"}', true);
  execute 'set local role authenticated';
  if exists (select 1 from public.profile_reports) then
    raise exception 'F01FAIL NULL principal matches retained NULL reporter';
  end if;
  begin
    perform public.delete_own_account();
    raise exception 'F01FAIL NULL principal deletion admitted';
  exception when raise_exception then
    if sqlerrm <> 'Not signed in' then raise; end if;
  end;
  begin
    perform public.zyra_my_safety_cases();
    raise exception 'F01FAIL NULL principal status RPC admitted';
  exception when raise_exception then
    if sqlerrm <> 'not_signed_in' then raise; end if;
  end;
  begin
    insert into public.profile_reports(reporter_id, reported_id, reason)
    values (null, '30500001-0000-4000-8000-000000000008', 'other');
    raise exception 'F01FAIL NULL reporter insert admitted after nullable change';
  exception when insufficient_privilege then null;
  end;
  execute 'reset role';
  raise notice 'F01PASS NULL principal read/insert/deletion/status refused';
end;
$null_principal$;

do $anonymous$
begin
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  execute 'set local role anon';
  begin
    perform 1 from public.profile_reports;
    raise exception 'F01FAIL anonymous report SELECT admitted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.delete_own_account();
    raise exception 'F01FAIL anonymous deletion admitted';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.zyra_my_safety_cases();
    raise exception 'F01FAIL anonymous status RPC admitted';
  exception when insufficient_privilege then null;
  end;
  execute 'reset role';
  raise notice 'F01PASS anonymous table/deletion/status ACLs refused';
end;
$anonymous$;

do $new_report$
begin
  perform set_config('request.jwt.claims',
    '{"sub":"30500001-0000-4000-8000-000000000007","role":"authenticated"}', true);
  execute 'set local role authenticated';
  insert into public.profile_reports(id, reporter_id, reported_id, reason, detail)
  values ('30500001-0000-4000-8000-000000000105',
    '30500001-0000-4000-8000-000000000007',
    '30500001-0000-4000-8000-000000000008', 'other', 'F01 new synthetic report');
  begin
    insert into public.profile_reports(reporter_id, reported_id, reason)
    values ('30500001-0000-4000-8000-000000000003',
      '30500001-0000-4000-8000-000000000008', 'other');
    raise exception 'F01FAIL forged reporter admitted';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.profile_reports(reporter_id, reported_id, reason)
    values (null, '30500001-0000-4000-8000-000000000008', 'other');
    raise exception 'F01FAIL signed-in user can forge NULL reporter';
  exception when insufficient_privilege then null;
  end;
  execute 'reset role';
  raise notice 'F01PASS legitimate new reporting works; forged/NULL reporter refused';
end;
$new_report$;

do $existing_privileged_review$
begin
  execute 'set local role service_role';
  if (select count(*) from public.profile_reports) <> 5 then
    raise exception 'F01FAIL existing privileged review lost retained cases';
  end if;
  execute 'reset role';
  if (select value from f01_metadata_before)
       is distinct from pg_temp.f01_metadata() then
    raise exception 'F01FAIL role tests altered existing authority metadata';
  end if;
  raise notice 'F01PASS existing privileged review retained; no new review/hold authority';
end;
$existing_privileged_review$;

rollback to savepoint f01_delete_replay;
do $transaction_restore$
begin
  if (select original from f01_evidence_before) is distinct from (
       select jsonb_agg(to_jsonb(r) order by r.id) from public.profile_reports r)
     or exists ((select id from auth.users) except (select id from f01_users_before))
     or exists ((select id from f01_users_before) except (select id from auth.users))
     or exists ((select * from storage.objects) except (select * from f01_storage_before))
     or exists ((select * from f01_storage_before) except (select * from storage.objects))
     or (select count(*) from public.profiles) <> 9 then
    raise exception 'F01FAIL transaction restore changed evidence/accounts/object fixture';
  end if;
  raise notice 'F01PASS transaction/savepoint restoration exact; not physical backup proof';
end;
$transaction_restore$;

rollback;
