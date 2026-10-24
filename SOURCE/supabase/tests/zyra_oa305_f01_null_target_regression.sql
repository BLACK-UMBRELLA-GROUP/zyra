-- OA-ZYRA-305 F01 / new October7 NULL-target and populated-table regression.
-- Only the explicitly armed, minimal, isolated fake database is allowed.
\set ON_ERROR_STOP on
do $guard$
begin
  if current_database() !~ '^zyra_oa305_f01_[a-z0-9_]+$'
     or current_setting('zyra.oa305_f01_local_replay',true) is distinct from 'enabled'
     or (select array_agg(attname::text order by attnum) from pg_attribute
         where attrelid='auth.users'::regclass and attnum>0 and not attisdropped)
        is distinct from array['id']::text[] then
    raise exception 'F01 new regression requires isolated minimal fake fixture';
  end if;
end;
$guard$;

-- Committed fake cases predate the ALTER. Four statuses and complete payloads
-- are compared before any synthetic deletion, not merely counted.
insert into auth.users(id) values
 ('30500007-0000-4000-8000-000000000001'),
 ('30500007-0000-4000-8000-000000000002');
insert into public.profiles(id,role) values
 ('30500007-0000-4000-8000-000000000001','seeker'),
 ('30500007-0000-4000-8000-000000000002','wali');
insert into public.profile_reports(id,reporter_id,reported_id,reason,detail,source,status,created_at,reviewed_at)
select ('30500007-0000-4000-8000-00000000010' || ordinal)::uuid,
 '30500007-0000-4000-8000-000000000001'::uuid,
 '30500007-0000-4000-8000-000000000002'::uuid,
 'privacy','October7 fake pre-existing evidence ' || ordinal,'guardian',status,
 '2026-10-01 10:00:00+00'::timestamptz,
 case when ordinal>2 then '2026-10-02 11:00:00+00'::timestamptz else null end
from (values (1,'pending'),(2,'reviewing'),(3,'actioned'),(4,'dismissed')) cases(ordinal,status);
create temp table f01_oct7_before as
 select jsonb_agg(to_jsonb(r) order by id) as rows from public.profile_reports r;

\ir ../migrations/20261005113808_oa305_f01_safety_report_retention.sql

begin;
do $existing_cases$
begin
  if (select rows from f01_oct7_before) is distinct from
     (select jsonb_agg(to_jsonb(r) order by id) from public.profile_reports r) then
    raise exception 'F01FAIL populated ALTER changed exact existing case payloads';
  end if;
  raise notice 'F01_NEW_PASS pre-existing four statuses and complete payloads preserved across ALTER';
end;
$existing_cases$;

do $new_targets$
declare
  n bigint;
begin
  perform set_config('request.jwt.claims',
    '{"sub":"30500007-0000-4000-8000-000000000001","role":"authenticated"}',true);
  execute 'set local role authenticated';
  begin
    insert into public.profile_reports(reporter_id,reported_id,reason)
    values ('30500007-0000-4000-8000-000000000001',null,'other');
    raise exception 'F01FAIL fresh NULL-target report admitted';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.profile_reports(reporter_id,reason)
    values ('30500007-0000-4000-8000-000000000001','other');
    raise exception 'F01FAIL fresh omitted-target report admitted';
  exception when insufficient_privilege then null;
  end;
  select count(*) into n from public.profile_reports;
  if n<>4 then raise exception 'F01FAIL denied target submissions changed cases'; end if;
  insert into public.profile_reports(id,reporter_id,reported_id,reason,detail)
  values ('30500007-0000-4000-8000-000000000105',
   '30500007-0000-4000-8000-000000000001',
   '30500007-0000-4000-8000-000000000002','other','October7 valid fresh fake case');
  if (select count(*) from public.profile_reports)<>5 then
    raise exception 'F01FAIL valid target submission lost'; end if;
  execute 'reset role';
  raise notice 'F01_NEW_PASS explicit NULL and omitted target denied with 42501; valid new report accepted';
end;
$new_targets$;

do $historical_detach$
declare
  actor uuid;
begin
  perform set_config('request.jwt.claims',
   '{"sub":"30500007-0000-4000-8000-000000000002","role":"authenticated"}',true);
  execute 'set local role authenticated';
  perform public.delete_own_account();
  execute 'reset role';
  if (select count(*) from public.profile_reports where reported_id is null)<>5
     or exists(select 1 from public.profiles where id='30500007-0000-4000-8000-000000000002') then
    raise exception 'F01FAIL target deletion blocked or retained cases lost'; end if;
  if (select rows from f01_oct7_before) is distinct from (
    select jsonb_agg(jsonb_set(to_jsonb(r),'{reported_id}',
      '"30500007-0000-4000-8000-000000000002"'::jsonb) order by id)
    from public.profile_reports r where id<>'30500007-0000-4000-8000-000000000105') then
    raise exception 'F01FAIL historic payload changed beyond reference detach'; end if;
  perform set_config('request.jwt.claims',
   '{"sub":"30500007-0000-4000-8000-000000000001","role":"authenticated"}',true);
  execute 'set local role authenticated';
  if (select count(*) from public.profile_reports)<>5
     or (select count(*) from public.zyra_my_safety_cases())<>5 then
    raise exception 'F01FAIL surviving reporter lost retained table/status access'; end if;
  execute 'reset role';
  raise notice 'F01_NEW_PASS historical target detach and surviving reporter access preserved';
end;
$historical_detach$;
rollback;
