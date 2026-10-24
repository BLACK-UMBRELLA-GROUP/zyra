-- OA-ZYRA-305 / F05 synthetic rights/maintenance replay.
-- Armed minimal fixture only. No live data, full bank or gateway JWT proof.
\set ON_ERROR_STOP on
do $guard$
begin
  if pg_catalog.current_database() !~ '^zyra_oa305_f05_[a-z0-9_]+$'
     or pg_catalog.current_setting('zyra.oa305_f05_local_replay', true)
       is distinct from 'enabled'
     or (select array_agg(attname::text order by attnum)
         from pg_catalog.pg_attribute where attrelid = 'auth.users'::regclass
           and attnum > 0 and not attisdropped) <> array['id']::text[] then
    raise exception 'F05 replay requires its explicitly armed minimal fixture';
  end if;
end;
$guard$;

create function pg_temp.f05_seed() returns void language plpgsql as $$
begin
  insert into auth.users(id) values
    ('30500005-0000-4000-8000-000000000001'),
    ('30500005-0000-4000-8000-000000000002'),
    ('30500005-0000-4000-8000-000000000003'),
    ('30500005-0000-4000-8000-000000000004');
  insert into public.profiles(id, role, gender, profile_complete) values
    ('30500005-0000-4000-8000-000000000001', 'seeker', 'male', true),
    ('30500005-0000-4000-8000-000000000002', 'seeker', 'female', true),
    ('30500005-0000-4000-8000-000000000003', 'wali', 'female', true),
    ('30500005-0000-4000-8000-000000000004', 'seeker', 'male', false);
  insert into public.seeker_details(user_id, preferences)
    values ('30500005-0000-4000-8000-000000000001', '{"synthetic":"configured"}');
  insert into public.onboarding_answers(user_id, ch3_answers, ch4_preferences)
    select '30500005-0000-4000-8000-000000000001'::uuid,
      jsonb_object_agg(qid, 'No'),
      jsonb_object_agg(qid, '{"No":"green","Yes":"red"}'::jsonb)
    from (select distinct qid from public.zyra_onboarding_questions) q;
  insert into public.onboarding_answers(user_id, ch3_answers, ch4_preferences)
    values ('30500005-0000-4000-8000-000000000002', '{"ch3_q3":"Yes"}', '{}');
  insert into public.f05_guardian_links values
    ('30500005-0000-4000-8000-000000000001', '30500005-0000-4000-8000-000000000003');
  insert into public.f05_blocks values
    ('30500005-0000-4000-8000-000000000001', '30500005-0000-4000-8000-000000000002');
end;
$$;

create function pg_temp.f05_metadata() returns jsonb language sql stable as $$
  select jsonb_build_object(
    'functions', (select jsonb_agg(jsonb_build_object(
      'oid', p.oid, 'owner', p.proowner, 'definition', pg_get_functiondef(p.oid),
      'acl', case when p.oid in (
        'public.zyra_onboarding_missing(uuid)'::regprocedure,
        'public.zyra_onboarding_complete(uuid)'::regprocedure,
        'public.zyra_onboarding_data_complete(uuid,text)'::regprocedure,
        'public.zyra_refresh_onboarding_complete(uuid)'::regprocedure)
        then null else p.proacl::text end,
      'comment', obj_description(p.oid, 'pg_proc')) order by p.oid)
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public' and p.prokind = 'f'),
    'relations', (select jsonb_agg(jsonb_build_object(
      'oid', c.oid, 'owner', c.relowner, 'acl', c.relacl::text,
      'rls', c.relrowsecurity, 'force_rls', c.relforcerowsecurity,
      'comment', obj_description(c.oid, 'pg_class')) order by c.oid)
      from pg_class c join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relkind in ('r', 'i')),
    'columns', (select jsonb_agg(jsonb_build_object(
      'table', a.attrelid, 'name', a.attname, 'notnull', a.attnotnull,
      'acl', a.attacl::text, 'default', pg_get_expr(d.adbin, d.adrelid))
      order by a.attrelid, a.attnum)
      from pg_attribute a join pg_class c on c.oid = a.attrelid
      join pg_namespace n on n.oid = c.relnamespace
      left join pg_attrdef d on d.adrelid = a.attrelid and d.adnum = a.attnum
      where n.nspname = 'public' and a.attnum > 0 and not a.attisdropped),
    'policies', (select jsonb_agg(jsonb_build_object(
      'table', p.polrelid, 'name', p.polname, 'cmd', p.polcmd,
      'roles', p.polroles, 'using', pg_get_expr(p.polqual, p.polrelid),
      'check', pg_get_expr(p.polwithcheck, p.polrelid)) order by p.oid)
      from pg_policy p),
    'triggers', (select jsonb_agg(pg_get_triggerdef(t.oid) order by t.oid)
      from pg_trigger t join pg_class c on c.oid = t.tgrelid
      join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public'),
    'constraints', (select jsonb_agg(pg_get_constraintdef(c.oid) order by c.oid)
      from pg_constraint c join pg_namespace n on n.oid = c.connamespace
      where n.nspname = 'public')
  );
$$;
create temp table f05_metadata_before as select pg_temp.f05_metadata() as value;

-- Prove the captured pre-fix oracle, then restore all synthetic actors.
begin;
select pg_temp.f05_seed();
do $baseline$
declare v_a boolean; v_b boolean; v_missing bigint;
begin
  perform set_config('request.jwt.claims',
    '{"sub":"30500005-0000-4000-8000-000000000004","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select public.zyra_onboarding_complete('30500005-0000-4000-8000-000000000001') into v_a;
  select public.zyra_onboarding_data_complete('30500005-0000-4000-8000-000000000002', 'female') into v_b;
  select count(*) into v_missing from public.zyra_onboarding_missing(
    '30500005-0000-4000-8000-000000000002');
  execute 'reset role';
  if v_a is distinct from true or v_b is distinct from false or v_missing = 0 then
    raise exception 'F05FAIL synthetic pre-fix arbitrary-account oracle not reproduced';
  end if;
  raise notice 'F05BASELINE unrelated member reads private completion/conditional missing state';
end;
$baseline$;
rollback;

\ir ../migrations/20261005120004_oa305_f05_private_progress_helpers.sql

begin;
select pg_temp.f05_seed();
do $metadata$
declare v_sig text;
begin
  if (select value from f05_metadata_before) is distinct from pg_temp.f05_metadata() then
    raise exception 'F05FAIL helper bodies/caller wrapper/maintenance/RLS/table metadata altered';
  end if;
  foreach v_sig in array array[
    'public.zyra_onboarding_missing(uuid)', 'public.zyra_onboarding_complete(uuid)',
    'public.zyra_onboarding_data_complete(uuid,text)',
    'public.zyra_refresh_onboarding_complete(uuid)'
  ] loop
    if pg_catalog.has_function_privilege('authenticated', v_sig, 'execute')
       or pg_catalog.has_function_privilege('anon', v_sig, 'execute')
       or not pg_catalog.has_function_privilege('postgres', v_sig, 'execute')
       or not pg_catalog.has_function_privilege('service_role', v_sig, 'execute') then
      raise exception 'F05FAIL exact ordinary denial/server retention: %', v_sig;
    end if;
  end loop;
  raise notice 'F05PASS only four ordinary helper EXECUTE rights removed; metadata unchanged';
end;
$metadata$;

do $denials$
declare v_actor uuid; v_target uuid; v_sig text;
begin
  foreach v_actor in array array[
    '30500005-0000-4000-8000-000000000001'::uuid, -- self
    '30500005-0000-4000-8000-000000000002'::uuid, -- opposite sex and blocked
    '30500005-0000-4000-8000-000000000003'::uuid, -- linked Guardian
    '30500005-0000-4000-8000-000000000004'::uuid, -- unrelated Seeker
    null::uuid
  ] loop
    perform set_config('request.jwt.claims', jsonb_build_object(
      'sub', v_actor, 'role', 'authenticated')::text, true);
    execute 'set local role authenticated';
    foreach v_target in array array[
      '30500005-0000-4000-8000-000000000001'::uuid,
      '30500005-0000-4000-8000-000000000002'::uuid,
      '30500005-0000-4000-8000-000000009999'::uuid, null::uuid
    ] loop
      foreach v_sig in array array[
        'select * from public.zyra_onboarding_missing($1)',
        'select public.zyra_onboarding_complete($1)',
        'select public.zyra_onboarding_data_complete($1, ''female'')',
        'select public.zyra_refresh_onboarding_complete($1)'
      ] loop
        begin
          execute v_sig using v_target;
          raise exception 'F05FAIL direct arbitrary-user helper was permitted';
        exception when insufficient_privilege then null;
        end;
      end loop;
    end loop;
    execute 'reset role';
  end loop;
  raise notice 'F05PASS self/stranger/blocked/Guardian/null direct helper denials for existing/missing/null IDs';
end;
$denials$;

do $owner_wrapper$
declare v_progress record; v_count bigint;
begin
  perform set_config('request.jwt.claims',
    '{"sub":"30500005-0000-4000-8000-000000000001","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select * into strict v_progress from public.zyra_my_onboarding_progress();
  if not v_progress.complete or v_progress.questions_missing <> 0
     or not v_progress.has_chapter_2 or not v_progress.basic_profile then
    raise exception 'F05FAIL own completed caller wrapper changed';
  end if;
  perform set_config('request.jwt.claims',
    '{"sub":"30500005-0000-4000-8000-000000000002","role":"authenticated"}', true);
  select * into strict v_progress from public.zyra_my_onboarding_progress();
  if v_progress.complete or v_progress.questions_missing = 0
     or v_progress.has_chapter_2 or not v_progress.basic_profile then
    raise exception 'F05FAIL own incomplete caller wrapper changed';
  end if;
  perform set_config('request.jwt.claims', '{"role":"authenticated"}', true);
  select count(*) into v_count from public.zyra_my_onboarding_progress();
  if v_count <> 0 then raise exception 'F05FAIL null caller gained progress'; end if;
  execute 'reset role';
  raise notice 'F05PASS caller-pinned progress complete/incomplete/null states preserved';
end;
$owner_wrapper$;

do $anonymous$
declare v_sql text;
begin
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  execute 'set local role anon';
  foreach v_sql in array array[
    'select * from public.zyra_onboarding_missing(null)',
    'select public.zyra_onboarding_complete(null)',
    'select public.zyra_onboarding_data_complete(null, null)',
    'select public.zyra_refresh_onboarding_complete(null)',
    'select * from public.zyra_my_onboarding_progress()'
  ] loop
    begin
      execute v_sql;
      raise exception 'F05FAIL anonymous helper/wrapper allowed';
    exception when insufficient_privilege then null;
    end;
  end loop;
  execute 'reset role';
  raise notice 'F05PASS anonymous helpers and own wrapper remain denied';
end;
$anonymous$;

do $maintenance$
declare v_user uuid := '30500005-0000-4000-8000-000000000001';
begin
  perform set_config('request.jwt.claims', jsonb_build_object(
    'sub', v_user, 'role', 'authenticated')::text, true);
  execute 'set local role authenticated';
  update public.onboarding_answers set ch3_answers = ch3_answers - 'ch3_q101'
    where user_id = v_user;
  if (select onboarding_complete from public.profiles where id = v_user) then
    raise exception 'F05FAIL answer AFTER trigger stopped after ordinary revoke';
  end if;
  update public.onboarding_answers
    set ch3_answers = ch3_answers || '{"ch3_q101":"No"}' where user_id = v_user;
  if not (select onboarding_complete from public.profiles where id = v_user) then
    raise exception 'F05FAIL answer restoration trigger stopped';
  end if;
  update public.seeker_details set preferences = '{}' where user_id = v_user;
  if (select onboarding_complete from public.profiles where id = v_user) then
    raise exception 'F05FAIL details AFTER trigger stopped';
  end if;
  update public.seeker_details set preferences = '{"synthetic":"configured"}' where user_id = v_user;
  update public.profiles set profile_complete = false where id = v_user;
  if (select onboarding_complete from public.profiles where id = v_user) then
    raise exception 'F05FAIL profile BEFORE trigger stopped';
  end if;
  update public.profiles set profile_complete = true where id = v_user;
  if not (select onboarding_complete from public.profiles where id = v_user) then
    raise exception 'F05FAIL profile restoration trigger stopped';
  end if;
  delete from public.onboarding_answers where user_id = v_user;
  if (select onboarding_complete from public.profiles where id = v_user) then
    raise exception 'F05FAIL delete AFTER trigger stopped';
  end if;
  execute 'reset role';
  raise notice 'F05PASS member-save profile/answers/details/delete internal maintenance unchanged';
end;
$maintenance$;

do $server$
declare v_missing bigint;
begin
  execute 'set local role service_role';
  select count(*) into v_missing from public.zyra_onboarding_missing(
    '30500005-0000-4000-8000-000000000002');
  if v_missing = 0 or public.zyra_onboarding_complete(
    '30500005-0000-4000-8000-000000000002')
     or public.zyra_onboarding_data_complete(
       '30500005-0000-4000-8000-000000000002', 'female') then
    raise exception 'F05FAIL retained trusted server helper paths changed';
  end if;
  perform public.zyra_refresh_onboarding_complete(
    '30500005-0000-4000-8000-000000000002');
  execute 'reset role';
  raise notice 'F05PASS existing trusted server completion/maintenance paths retained';
end;
$server$;
rollback;
