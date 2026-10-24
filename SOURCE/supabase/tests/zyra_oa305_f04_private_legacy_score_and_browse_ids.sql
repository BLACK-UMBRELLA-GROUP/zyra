-- OA-ZYRA-305 / F04 PREPARATION-ONLY isolated synthetic boundary replay.
-- Not a privacy pass, app integration, immutable paid result, full bank/parser
-- validation, retention, JWT gateway or production activation certificate.
\set ON_ERROR_STOP on
do $guard$
begin
  if pg_catalog.current_database() !~ '^zyra_oa305_f04_[a-z0-9_]+$'
     or pg_catalog.current_setting('zyra.oa305_f04_local_replay', true)
       is distinct from 'prepared_local_replay'
     or pg_catalog.to_regnamespace('zyra_f04_private') is not null then
    raise exception 'F04 replay requires explicitly armed fresh synthetic fixture';
  end if;
end;
$guard$;

create function pg_temp.f04_seed() returns void language plpgsql as $$
begin
  insert into public.profiles(id, role, gender, is_active, profile_complete) values
    ('30500004-0000-4000-8000-000000000001', 'seeker', 'male', true, true),
    ('30500004-0000-4000-8000-000000000002', 'seeker', 'female', true, true),
    ('30500004-0000-4000-8000-000000000003', 'seeker', 'female', true, true),
    ('30500004-0000-4000-8000-000000000004', 'seeker', 'female', true, true),
    ('30500004-0000-4000-8000-000000000005', 'seeker', 'female', true, true),
    ('30500004-0000-4000-8000-000000000006', 'seeker', 'male', true, true),
    ('30500004-0000-4000-8000-000000000007', 'wali', 'female', true, true),
    ('30500004-0000-4000-8000-000000000008', 'seeker', 'female', false, true),
    ('30500004-0000-4000-8000-000000000009', 'seeker', 'female', true, true),
    ('30500004-0000-4000-8000-000000000010', 'seeker', 'female', true, true),
    ('30500004-0000-4000-8000-000000000011', 'seeker', 'female', true, false);
  insert into public.onboarding_answers(user_id, ch3_answers, ch4_preferences, ch4_hard_requirements) values
    ('30500004-0000-4000-8000-000000000001', '{"ch3_q33":"Yes"}',
      '{"ch3_q33":{"Yes":"green","No":"red"}}', '{"ch3_q1":["No"]}'),
    ('30500004-0000-4000-8000-000000000002',
      '{"ch3_q1":"Yes","ch3_q33":"Yes","ch3_q101":"Yes","ch3_q102":"No","bio_sensitive":"private"}',
      '{"ch3_q33":{"Yes":"red","No":"green"}}', '{}'),
    ('30500004-0000-4000-8000-000000000003', '{"ch3_q1":"Yes","ch3_q33":"No"}', '{}', '{}'),
    ('30500004-0000-4000-8000-000000000004', '{}', '{}', '{}'),
    ('30500004-0000-4000-8000-000000000005', '{"ch3_q1":"No","ch3_q33":"Yes"}', '{}', '{}'),
    ('30500004-0000-4000-8000-000000000006', '{"ch3_q1":"Yes","ch3_q33":"Yes"}', '{}', '{}'),
    ('30500004-0000-4000-8000-000000000007', '{"ch3_q1":"Yes","ch3_q33":"Yes"}', '{}', '{}'),
    ('30500004-0000-4000-8000-000000000008', '{"ch3_q1":"Yes","ch3_q33":"Yes"}', '{}', '{}'),
    ('30500004-0000-4000-8000-000000000009', '{"ch3_q1":"Yes","ch3_q33":"Yes"}', '{}', '{}'),
    ('30500004-0000-4000-8000-000000000010', '{"ch3_q1":"Yes","ch3_q33":"Yes"}', '{}', '{}');
  insert into public.profile_blocks values
    ('30500004-0000-4000-8000-000000000009', '30500004-0000-4000-8000-000000000001');
  insert into public.wali_links values
    ('30500004-0000-4000-8000-000000000007', '30500004-0000-4000-8000-000000000001', 'active');
  insert into public.matches(id, seeker_a_id, seeker_b_id, status, journey_stage) values
    ('30500004-0000-4000-8000-000000000101', '30500004-0000-4000-8000-000000000001',
      '30500004-0000-4000-8000-000000000002', 'active', 'compatibility_reveal'),
    ('30500004-0000-4000-8000-000000000102', '30500004-0000-4000-8000-000000000001',
      '30500004-0000-4000-8000-000000000006', 'active', 'compatibility_reveal'),
    ('30500004-0000-4000-8000-000000000103', '30500004-0000-4000-8000-000000000001',
      '30500004-0000-4000-8000-000000000009', 'active', 'compatibility_reveal');
  insert into public.journey_attempts(id, match_id, status, journey_stage) values
    ('30500004-0000-4000-8000-000000000201', '30500004-0000-4000-8000-000000000101',
      'active', 'compatibility_reveal');
end;
$$;

create function pg_temp.f04_existing_metadata() returns jsonb language sql stable as $$
  select jsonb_build_object(
    'functions', (select jsonb_agg(jsonb_build_object(
      'oid', p.oid, 'owner', p.proowner, 'acl', p.proacl::text,
      'definition', pg_get_functiondef(p.oid),
      'comment', obj_description(p.oid, 'pg_proc')) order by p.oid)
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
      where n.nspname = 'public' and p.prokind = 'f'
        and p.oid <> 'public.score_candidates(uuid[])'::regprocedure
        and p.proname <> 'zyra_browse_ranked_ids'),
    'tables', (select jsonb_agg(jsonb_build_object(
      'oid', c.oid, 'owner', c.relowner, 'acl', c.relacl::text,
      'rls', c.relrowsecurity, 'force', c.relforcerowsecurity,
      'comment', obj_description(c.oid, 'pg_class')) order by c.oid)
      from pg_class c join pg_namespace n on n.oid = c.relnamespace
      where n.nspname = 'public' and c.relkind in ('r', 'i')),
    'policies', (select jsonb_agg(jsonb_build_object(
      'table', p.polrelid, 'name', p.polname, 'roles', p.polroles,
      'using', pg_get_expr(p.polqual, p.polrelid),
      'check', pg_get_expr(p.polwithcheck, p.polrelid)) order by p.oid) from pg_policy p),
    'constraints', (select jsonb_agg(pg_get_constraintdef(c.oid) order by c.oid)
      from pg_constraint c join pg_namespace n on n.oid = c.connamespace
      where n.nspname = 'public')
  );
$$;
create temp table f04_metadata_before as select pg_temp.f04_existing_metadata() as value;
create temp table f04_numeric_before (value jsonb);

begin;
select pg_temp.f04_seed();
do $baseline$
declare v_score numeric;
begin
  perform set_config('request.jwt.claims',
    '{"sub":"30500004-0000-4000-8000-000000000001","role":"authenticated"}', true);
  execute 'set local role authenticated';
  select s.score into v_score from public.score_candidates(
    array['30500004-0000-4000-8000-000000000002'::uuid]) s;
  if v_score <> 100 then raise exception 'F04FAIL captured pre-fix score mismatch'; end if;
  -- A member's forged information-only preference probes a private answer.
  update public.onboarding_answers set ch4_preferences =
    '{"ch3_q101":{"Yes":"red","No":"green"}}'
    where user_id = (select auth.uid());
  select s.score into v_score from public.score_candidates(
    array['30500004-0000-4000-8000-000000000002'::uuid]) s;
  if v_score <> 0 then raise exception 'F04FAIL synthetic pre-fix q101 probe not reproduced'; end if;
  execute 'reset role';
  raise notice 'F04BASELINE direct numeric pre-entitlement and information-only qid probe reproduced';
end;
$baseline$;
rollback;

-- Capture exact canonical legacy outcomes before the cutover; no actors remain
-- when the migration commits. Temp baseline persists across that commit.
begin;
select pg_temp.f04_seed();
select set_config('request.jwt.claims',
  '{"sub":"30500004-0000-4000-8000-000000000001","role":"authenticated"}', true);
select jsonb_agg(to_jsonb(s) order by s.candidate_id) as numeric_expected
from public.score_candidates(array[
  '30500004-0000-4000-8000-000000000002'::uuid,
  '30500004-0000-4000-8000-000000000003'::uuid,
  '30500004-0000-4000-8000-000000000004'::uuid,
  '30500004-0000-4000-8000-000000000005'::uuid,
  '30500004-0000-4000-8000-000000000010'::uuid]) s \gset
rollback;
insert into f04_numeric_before values (:'numeric_expected'::jsonb);

\ir ../migrations/20261005120711_oa305_f04_private_legacy_score_and_browse_ids.sql

begin;
select pg_temp.f04_seed();
do $metadata$
begin
  if (select value from f04_metadata_before) is distinct from pg_temp.f04_existing_metadata() then
    raise exception 'F04FAIL existing Journey/visibility/RLS/entitlement metadata changed';
  end if;
  if pg_catalog.pg_get_function_result('public.zyra_browse_ranked_ids(uuid[])'::regprocedure)
       <> 'TABLE(candidate_id uuid)'
     or pg_catalog.has_function_privilege('authenticated', 'public.score_candidates(uuid[])', 'execute')
     or pg_catalog.has_function_privilege('anon', 'public.score_candidates(uuid[])', 'execute')
     or pg_catalog.has_schema_privilege('authenticated', 'zyra_f04_private', 'usage')
     or pg_catalog.has_schema_privilege('anon', 'zyra_f04_private', 'usage')
     or pg_catalog.has_function_privilege('authenticated',
       'zyra_f04_private.score_candidates_legacy(uuid[])', 'execute')
     or not pg_catalog.has_function_privilege('service_role', 'public.score_candidates(uuid[])', 'execute') then
    raise exception 'F04FAIL private/ID-only catalog rights';
  end if;
  raise notice 'F04PASS private/ID-only rights and unrelated Journey/visibility/RLS metadata preserved';
end;
$metadata$;

do $canonical$
declare v_actual jsonb;
begin
  perform set_config('request.jwt.claims',
    '{"sub":"30500004-0000-4000-8000-000000000001","role":"authenticated"}', true);
  select jsonb_agg(to_jsonb(s) order by s.candidate_id) into v_actual
  from public.score_candidates(array[
    '30500004-0000-4000-8000-000000000002'::uuid,
    '30500004-0000-4000-8000-000000000003'::uuid,
    '30500004-0000-4000-8000-000000000004'::uuid,
    '30500004-0000-4000-8000-000000000005'::uuid,
    '30500004-0000-4000-8000-000000000010'::uuid]) s;
  if v_actual is distinct from (select value from f04_numeric_before) then
    raise exception 'F04FAIL canonical legacy score/exclusion/null output changed';
  end if;
  raise notice 'F04PASS fixed canonical legacy arithmetic/exclusion/null output matches prestate';
end;
$canonical$;

do $browse$
declare v_ids uuid[]; v_row jsonb;
begin
  execute 'set local role authenticated';
  select array_agg(b.candidate_id) into v_ids from public.zyra_browse_ranked_ids(array[
    '30500004-0000-4000-8000-000000000004'::uuid, -- null score, last
    '30500004-0000-4000-8000-000000000003'::uuid, -- zero score, before null
    '30500004-0000-4000-8000-000000000010'::uuid, -- tied first in input
    '30500004-0000-4000-8000-000000000002'::uuid,
    '30500004-0000-4000-8000-000000000002'::uuid, -- duplicate cannot duplicate output
    '30500004-0000-4000-8000-000000000005'::uuid, -- hard excluded
    '30500004-0000-4000-8000-000000000006'::uuid, -- same-gender match exception
    '30500004-0000-4000-8000-000000000007'::uuid, -- linked Guardian
    '30500004-0000-4000-8000-000000000008'::uuid, -- inactive
    '30500004-0000-4000-8000-000000000009'::uuid, -- blocked despite match exception
    '30500004-0000-4000-8000-000000000011'::uuid, -- incomplete
    '30500004-0000-4000-8000-000000009999'::uuid, null::uuid]) b;
  if v_ids is distinct from array[
    '30500004-0000-4000-8000-000000000010'::uuid,
    '30500004-0000-4000-8000-000000000002'::uuid,
    '30500004-0000-4000-8000-000000000003'::uuid,
    '30500004-0000-4000-8000-000000000004'::uuid] then
    raise exception 'F04FAIL ID-only Browse order/tie/exclusion/purpose boundary: %', v_ids;
  end if;
  select to_jsonb(b) into strict v_row from public.zyra_browse_ranked_ids(
    array['30500004-0000-4000-8000-000000000002'::uuid]) b;
  -- One OUT UUID is represented by PostgreSQL as a scalar UUID, not a
  -- composite JSON object. Test that actual ID-only SQL transcript. Gateway
  -- JSON serialization and the future Flutter ID-list mapper remain unproved.
  if v_row is distinct from to_jsonb('30500004-0000-4000-8000-000000000002'::uuid) then
    raise exception 'F04FAIL Browse leaked score/category/answer/count/diagnostic';
  end if;
  if exists (select 1 from public.zyra_browse_ranked_ids(null))
     or exists (select 1 from public.zyra_browse_ranked_ids('{}'::uuid[])) then
    raise exception 'F04FAIL empty input was not empty';
  end if;
  execute 'reset role';
  raise notice 'F04PASS ID-only rank, stable ties, hard/null handling and Browse-purpose actor filtering';
end;
$browse$;

do $ordinary_denial$
declare v_actor uuid; v_sql text;
begin
  foreach v_actor in array array[
    '30500004-0000-4000-8000-000000000001'::uuid,
    '30500004-0000-4000-8000-000000000007'::uuid, null::uuid
  ] loop
    perform set_config('request.jwt.claims', jsonb_build_object(
      'sub', v_actor, 'role', 'authenticated')::text, true);
    execute 'set local role authenticated';
    foreach v_sql in array array[
      'select * from public.score_candidates(array[''30500004-0000-4000-8000-000000000002''::uuid])',
      'select * from zyra_f04_private.score_candidates_legacy(array[''30500004-0000-4000-8000-000000000002''::uuid])'
    ] loop
      begin
        execute v_sql;
        raise exception 'F04FAIL ordinary numeric/private scorer reachable';
      exception when insufficient_privilege then null;
      end;
    end loop;
    if v_actor is distinct from '30500004-0000-4000-8000-000000000001'::uuid
       and exists (select 1 from public.zyra_browse_ranked_ids(
         array['30500004-0000-4000-8000-000000000002'::uuid])) then
      raise exception 'F04FAIL Guardian/null principal gained Browse';
    end if;
    execute 'reset role';
  end loop;
  execute 'set local role anon';
  begin
    perform * from public.zyra_browse_ranked_ids(null);
    raise exception 'F04FAIL anonymous Browse allowed';
  exception when insufficient_privilege then null;
  end;
  execute 'reset role';
  raise notice 'F04PASS ordinary/Guardian/null private and numeric denials; anonymous Browse denied';
end;
$ordinary_denial$;

do $whitelist$
declare v_key text; v_score numeric; v_count bigint;
begin
  perform set_config('request.jwt.claims',
    '{"sub":"30500004-0000-4000-8000-000000000001","role":"authenticated"}', true);
  foreach v_key in array array['ch3_q101', 'ch3_q102', 'bio_sensitive', 'ch3_q999', 'ch3_q33_extra'] loop
    update public.onboarding_answers set ch4_preferences = jsonb_build_object(
      v_key, '{"Yes":"red","No":"green","private":"red"}'::jsonb),
      ch4_hard_requirements = jsonb_build_object(v_key, '["Yes","No","private"]'::jsonb)
      where user_id = (select auth.uid());
    select count(*), max(s.score) into v_count, v_score from public.score_candidates(
      array['30500004-0000-4000-8000-000000000002'::uuid]) s;
    if v_count <> 1 or v_score is not null then
      raise exception 'F04FAIL unknown/information-only qid became score or exclusion: %', v_key;
    end if;
    update public.onboarding_answers set ch4_preferences = ch4_preferences ||
      '{"ch3_q33":{"Yes":"green","No":"red"}}'
      where user_id = (select auth.uid());
    select count(*), max(s.score) into v_count, v_score from public.score_candidates(
      array['30500004-0000-4000-8000-000000000002'::uuid]) s;
    if v_count <> 1 or v_score <> 100 then
      raise exception 'F04FAIL unknown qid altered a valid canonical score/exclusion: %', v_key;
    end if;
  end loop;
  update public.onboarding_answers set ch4_preferences =
    '{"ch3_q33":{"Yes":"green","No":"red"}}', ch4_hard_requirements = '{"ch3_q1":["No"]}'
    where user_id = (select auth.uid());
  raise notice 'F04PASS q101/q102/Bio/unknown/alias preferences and hards cannot query those answers';
end;
$whitelist$;

do $legacy_arithmetic$
declare v_score numeric;
begin
  update public.onboarding_answers set ch4_preferences =
    '{"ch3_q33":{"Yes":"green","No":"red"},"ch3_q37":{"Yes":"green","No":"red"}}'
    where user_id = '30500004-0000-4000-8000-000000000001';
  update public.onboarding_answers set ch3_answers = ch3_answers || '{"ch3_q37":["Yes","No"]}'
    where user_id = '30500004-0000-4000-8000-000000000002';
  select s.score into v_score from public.score_candidates(
    array['30500004-0000-4000-8000-000000000002'::uuid]) s;
  if v_score <> 75 then raise exception 'F04FAIL OA228 one-question multiselect unit changed'; end if;
  update public.onboarding_answers set ch4_preferences =
    '{"ch3_q33":{"Yes":"green","No":"red"}}'
    where user_id = '30500004-0000-4000-8000-000000000001';
  insert into public.seeker_details(user_id, preferences, sect) values
    ('30500004-0000-4000-8000-000000000001', '{"sect":{"matrix":{"sunni":"red"},"hard_requirement":[]}}', null),
    ('30500004-0000-4000-8000-000000000002', '{}', 'sunni');
  select s.score into v_score from public.score_candidates(
    array['30500004-0000-4000-8000-000000000002'::uuid]) s;
  if v_score <> 50 then raise exception 'F04FAIL canonical sect/legacy Chapter2 weight changed'; end if;
  delete from public.seeker_details;
  raise notice 'F04PASS legacy one-unit multiselect/canonical sect Chapter2 arithmetic preserved';
end;
$legacy_arithmetic$;

do $journey$
declare v_a record; v_b record; v_score numeric;
begin
  execute 'set local role authenticated';
  select * into strict v_a from public.zyra_reveal_journey_compatibility(
    '30500004-0000-4000-8000-000000000101');
  if not v_a.mine_revealed or v_a.counterpart_revealed or v_a.my_score is not null then
    raise exception 'F04FAIL first Journey reveal lost mutual withholding';
  end if;
  perform set_config('request.jwt.claims',
    '{"sub":"30500004-0000-4000-8000-000000000002","role":"authenticated"}', true);
  select * into strict v_b from public.zyra_reveal_journey_compatibility(
    '30500004-0000-4000-8000-000000000101');
  if not v_b.mine_revealed or not v_b.counterpart_revealed or v_b.my_score <> 0 then
    raise exception 'F04FAIL B-side own asymmetric Journey score changed';
  end if;
  perform set_config('request.jwt.claims',
    '{"sub":"30500004-0000-4000-8000-000000000001","role":"authenticated"}', true);
  select * into strict v_a from public.zyra_journey_compatibility_state(
    '30500004-0000-4000-8000-000000000101');
  if v_a.my_score <> 100 then raise exception 'F04FAIL A-side own Journey score unavailable'; end if;
  begin
    v_score := public.zyra_compatibility_for_plus('30500004-0000-4000-8000-000000000101');
    raise exception 'F04FAIL existing Plus gate bypassed';
  exception when insufficient_privilege then
    if sqlerrm <> 'plus_required' then raise; end if;
  end;
  execute 'reset role';
  -- Existing entitlement fixture only: no paid spending/ledger/tier rule.
  insert into public.profile_unlocks values
    ('30500004-0000-4000-8000-000000000001', '30500004-0000-4000-8000-000000000002', 'paid_plus_single');
  execute 'set local role authenticated';
  v_score := public.zyra_compatibility_for_plus('30500004-0000-4000-8000-000000000101');
  if v_score <> 100 then raise exception 'F04FAIL retained Plus own-score path changed'; end if;
  -- Even an existing entitlement never reopens the raw numeric doorway.
  begin
    perform * from public.score_candidates(array['30500004-0000-4000-8000-000000000002'::uuid]);
    raise exception 'F04FAIL paid entitlement reopened raw numeric scorer';
  exception when insufficient_privilege then null;
  end;
  execute 'reset role';
  raise notice 'F04PASS real retained Journey definer calls preserve mutual/asymmetric/Plus gates';
end;
$journey$;

do $server$
declare v_score numeric;
begin
  execute 'set local role service_role';
  select s.score into v_score from public.score_candidates(
    array['30500004-0000-4000-8000-000000000002'::uuid]) s;
  if v_score <> 100 then raise exception 'F04FAIL trusted server adapter unavailable'; end if;
  execute 'reset role';
  raise notice 'F04PASS trusted server old-signature numeric adapter preserved';
end;
$server$;
rollback;
