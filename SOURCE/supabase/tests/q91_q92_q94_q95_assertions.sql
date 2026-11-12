-- DOC-ZYRA-0472 V4. Disposable PostgreSQL 17 after the governed replay.
\set ON_ERROR_STOP on

-- Q91: use actual authenticated RPC grants and request JWT claims.
begin;

do $guard$
begin
  if current_database() !~ '^zyra_server0_v2_[a-z0-9_]+$'
     or current_user <> 'postgres' then
    raise exception 'Q91 requires the disposable SERVER 0 replay database';
  end if;
end;
$guard$;

create function pg_temp.q91_actor(p_number integer)
returns uuid language sql immutable security invoker as $$
  select ('91000000-0000-4000-8000-' || lpad(p_number::text, 12, '0'))::uuid;
$$;

create function pg_temp.q91_as(p_number integer)
returns void language plpgsql security invoker as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', pg_temp.q91_actor(p_number), 'role', 'authenticated')::text,
    true);
end;
$$;

create function pg_temp.q91_assert(p_ok boolean, p_label text)
returns void language plpgsql security invoker as $$
begin
  if p_ok is distinct from true then
    raise exception 'Q91 FAIL: %', p_label;
  end if;
  raise notice 'Q91 PASS: %', p_label;
end;
$$;

create function pg_temp.q91_refuse(p_token text, p_reason text)
returns void language plpgsql security invoker as $$
begin
  begin
    perform public.accept_wali_invite(p_token, 'other');
  exception when raise_exception then
    if sqlerrm <> p_reason then raise; end if;
    raise notice 'Q91 PASS refusal %: %', p_token, p_reason;
    return;
  end;
  raise exception 'Q91 FAIL: invitation % accepted; expected %', p_token, p_reason;
end;
$$;

grant execute on function pg_temp.q91_actor(integer), pg_temp.q91_as(integer),
  pg_temp.q91_assert(boolean, text), pg_temp.q91_refuse(text, text) to authenticated;

insert into auth.users (id, aud, role, email, raw_app_meta_data, raw_user_meta_data)
select pg_temp.q91_actor(n), 'authenticated', 'authenticated',
       'q91-assertion-' || n || '@zyra.test',
       '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb
from generate_series(101, 124) as actors(n);

insert into public.profiles (id, role, first_name, date_of_birth, gender)
select pg_temp.q91_actor(n),
       case when n < 110 then 'seeker' else 'wali' end,
       'Fixture ' || n, date '1985-01-01', 'male'
from generate_series(101, 123) as actors(n);

insert into public.subscriptions (user_id, plan_type, status, expires_at)
values (pg_temp.q91_actor(102), 'seeker_premium', 'active', clock_timestamp() + interval '1 day'),
       (pg_temp.q91_actor(110), 'wali_premium', 'active', clock_timestamp() + interval '1 day'),
       (pg_temp.q91_actor(113), 'wali_premium', 'active', clock_timestamp() + interval '1 day');

insert into public.wali_invites (token, inviter_id, inviter_role)
values ('Q91PAID0', pg_temp.q91_actor(101), 'seeker'),
       ('Q91FREE1', pg_temp.q91_actor(101), 'seeker'),
       ('Q91LATER', pg_temp.q91_actor(101), 'seeker'),
       ('Q91LAPSE', pg_temp.q91_actor(101), 'seeker'),
       ('Q91EXPRD', pg_temp.q91_actor(101), 'seeker'),
       ('Q91ONETN', pg_temp.q91_actor(102), 'seeker'),
       ('Q91ONELM', pg_temp.q91_actor(102), 'seeker'),
       ('Q91LEGAC', pg_temp.q91_actor(103), 'seeker'),
       ('Q91REVR1', pg_temp.q91_actor(117), 'wali');

update public.wali_invites
set expires_at = clock_timestamp() - interval '1 minute'
where token = 'Q91EXPRD';

insert into public.wali_links (seeker_id, wali_id, status, relationship)
select pg_temp.q91_actor(102), pg_temp.q91_actor(n), 'active', 'other'
from generate_series(110, 118) as actors(n);

insert into public.wali_links (seeker_id, wali_id, status, relationship)
values (pg_temp.q91_actor(103), pg_temp.q91_actor(115), 'active', 'other');

select pg_temp.q91_assert(
  not has_function_privilege('anon', 'public.preview_wali_invite(text)', 'execute')
  and not has_function_privilege('anon', 'public.accept_wali_invite(text,text)', 'execute')
  and not has_table_privilege('authenticated', 'private.zyra_guardian_invite_accept_guards', 'select')
  and not has_function_privilege('authenticated',
      'private.zyra_guardian_invite_capacity(uuid,uuid,timestamptz)', 'execute'),
  'legacy RPCs require authentication and the capacity internals remain private');

set local role authenticated;
select pg_temp.q91_as(101);
select pg_temp.q91_assert(
  (select invite_status = 'pending' and seeker_plan is null
          and basic_place_free is null and needs_guardian_one is null
   from public.preview_wali_invite('Q91FREE1')),
  'sender keeps old preview and gets no receiver facts');
select pg_temp.q91_as(104);
select pg_temp.q91_assert(
  (select seeker_plan is null and basic_place_free is null and needs_guardian_one is null
   from public.preview_wali_invite('Q91FREE1')),
  'wrong-role bearer gets no Guardian facts');
select pg_temp.q91_as(124);
select pg_temp.q91_assert(
  (select seeker_plan = 'basic' and basic_place_free and not needs_guardian_one
   from public.preview_wali_invite('Q91FREE1')),
  'signed-in code holder can preview before their Guardian profile exists');
select pg_temp.q91_refuse('Q91FREE1', 'Complete your profile before accepting an invite');
select pg_temp.q91_assert(
  not exists (select from public.preview_wali_invite('Q91WRONG')),
  'unknown token returns no rows');

select pg_temp.q91_as(110);
select pg_temp.q91_assert(
  public.accept_wali_invite('Q91PAID0', 'father') is not null,
  'paid Guardian can join first');
select pg_temp.q91_as(112);
select pg_temp.q91_assert(
  (select seeker_plan = 'basic' and basic_place_free and not needs_guardian_one
   from public.preview_wali_invite('Q91LATER')),
  'a paid link leaves the Basic place free');
select pg_temp.q91_as(111);
select pg_temp.q91_assert(
  (select seeker_plan = 'basic' and basic_place_free and not needs_guardian_one
   from public.preview_wali_invite('Q91FREE1')),
  'Basic Guardian can see a free place on their code');
select pg_temp.q91_assert(
  public.accept_wali_invite('Q91FREE1', 'uncle') is not null,
  'Basic Guardian accepts the free place');

select pg_temp.q91_as(112);
select pg_temp.q91_assert(
  (select to_jsonb(preview) = jsonb_build_object(
      'inviter_first_name', 'Fixture 101',
      'inviter_role', 'seeker',
      'invite_status', 'pending',
      'inviter_ward_count', 0,
      'seeker_plan', 'basic',
      'basic_place_free', false,
      'needs_guardian_one', true)
   from public.preview_wali_invite('Q91LATER') preview),
  'occupied-place preview returns exactly seven allowed fields, without a holder');
select pg_temp.q91_refuse('Q91LATER', 'needs_guardian_one');
select pg_temp.q91_assert(
  (select invite_status = 'pending' from public.preview_wali_invite('Q91LATER')),
  'refused acceptance leaves that code pending');
select pg_temp.q91_refuse('Q91EXPRD', 'invite_expired');
select pg_temp.q91_assert(
  (select invite_status = 'expired' and seeker_plan is null
   from public.preview_wali_invite('Q91EXPRD')),
  'existing expired-state response retains no live receiver facts');

select pg_temp.q91_as(113);
select pg_temp.q91_assert(
  (select seeker_plan = 'basic' and not basic_place_free and not needs_guardian_one
   from public.preview_wali_invite('Q91LAPSE')),
  'verified Guardian One can preview a used Basic place');
reset role;

update public.subscriptions set expires_at = clock_timestamp() - interval '1 minute'
where user_id = pg_temp.q91_actor(113);
insert into public.subscriptions (user_id, plan_type, status, expires_at)
values (pg_temp.q91_actor(112), 'wali_premium', 'active', clock_timestamp() + interval '1 day');

set local role authenticated;
select pg_temp.q91_as(113);
select pg_temp.q91_refuse('Q91LAPSE', 'needs_guardian_one');
select pg_temp.q91_as(112);
select pg_temp.q91_assert(
  public.accept_wali_invite('Q91LATER', 'brother') is not null,
  'same invite accepts once its receiver has verified Guardian One');
select pg_temp.q91_refuse('Q91LATER', 'Invite not found or already used');

select pg_temp.q91_as(119);
select pg_temp.q91_assert(
  (select seeker_plan = 'one' and basic_place_free and not needs_guardian_one
   from public.preview_wali_invite('Q91ONETN')),
  'Seeker One shows Basic place free even with nine links');
select pg_temp.q91_assert(
  public.accept_wali_invite('Q91ONETN', 'other') is not null,
  'Seeker One can accept the tenth unpaid Guardian');
select pg_temp.q91_as(120);
select pg_temp.q91_refuse('Q91ONELM', 'guardian_capacity_exceeded');

select pg_temp.q91_as(116);
select pg_temp.q91_assert(
  (select not basic_place_free and needs_guardian_one
   from public.preview_wali_invite('Q91LEGAC')),
  'existing active Basic link occupies the place without new metadata');
select pg_temp.q91_refuse('Q91LEGAC', 'needs_guardian_one');
select pg_temp.q91_as(103);
select pg_temp.q91_assert(
  (select invite_status = 'pending' and seeker_plan is null
          and basic_place_free is null and needs_guardian_one is null
   from public.preview_wali_invite('Q91REVR1')),
  'Guardian-sent legacy preview keeps its existing shape and scope');
select pg_temp.q91_assert(
  public.accept_wali_invite('Q91REVR1') is not null,
  'Guardian-sent legacy acceptance still works');
reset role;

select pg_temp.q91_assert(
  (select count(*) = 3 and bool_and(
     wl.place_kind = case wi.token when 'Q91FREE1' then 'basic_place' else 'guardian_one' end
     and wi.accepted_by = wl.wali_id and wi.status = 'accepted')
   from public.wali_links wl
   join public.wali_invites wi on wi.id = wl.invitation_id
   where wi.token in ('Q91PAID0', 'Q91FREE1', 'Q91LATER')
     and wl.seeker_id = pg_temp.q91_actor(101)),
  'link records the exact accepted invitation and admission place');
select pg_temp.q91_assert(
  (select count(*) = 10 from public.wali_links
   where seeker_id = pg_temp.q91_actor(102) and status = 'active'),
  'refused eleventh invite created no link');
select pg_temp.q91_assert(
  (select count(*) = 2 and bool_and(place_kind is null and invitation_id is null)
   from public.wali_links where seeker_id = pg_temp.q91_actor(103) and status = 'active'),
  'pre-existing and reverse-flow links retain their original metadata');
rollback;

-- Q97: check the bank and the fixed D3 assignment independently.
begin;

do $q92$
declare
  v_digest text;
begin
  if (select count(*) from private.zyra_question_area) <> 110
     or (select count(distinct area) from private.zyra_question_area) <> 12 then
    raise exception 'Q97: all 12 areas and all 110 unique inputs must be mapped';
  end if;
  if exists (
    select 1 from public.zyra_onboarding_questions q
    left join private.zyra_question_area a on a.question_id = q.qid
    where q.ch4_scored and a.question_id is null
  ) then
    raise exception 'Q97: each scored bank control must have an area';
  end if;
  -- Hash of sorted question_id:area pairs from chapter3Categories and
  -- the six locked Chapter 2 assignments, using the C collation.
  select encode(sha256(convert_to(
    string_agg(question_id || ':' || area::text, ',' order by question_id collate "C"), 'UTF8'
  )), 'hex') into v_digest
  from private.zyra_question_area;
  if v_digest is distinct from '6a9831d529e18f8ab6c8ea84d7e171917bd93ff1038371853d266e84512cba57' then
    raise exception 'Q97: an area assignment differs from the locked map';
  end if;
  if has_table_privilege('authenticated', 'private.zyra_question_area', 'SELECT')
     or has_table_privilege('anon', 'private.zyra_question_area', 'SELECT') then
    raise exception 'Q97: the internal map must have no member grant';
  end if;
  raise notice 'Q97 area map assertions passed';
end;
$q92$;

rollback;

-- Q100: actual canonical capture, strict scoring, and immutable save.
begin;
\ir fixtures/server0_v2_full_schema_prestate.sql

create function pg_temp.q100_actor(p_label text) returns uuid
language sql stable as $$
  select id from server0_v2_fixture_actors where fixture_label = p_label;
$$;

create function pg_temp.q100_assert(p_ok boolean, p_check text) returns void
language plpgsql as $$
begin
  if p_ok is distinct from true then raise exception 'Q100 FAIL: %', p_check; end if;
  raise notice 'Q100 PASS: %', p_check;
end;
$$;

create function pg_temp.q100_score()
returns table (capture_version text, inputs_hash text, overall numeric, area_bands jsonb, state text)
language sql stable as $$
  select * from public.zyra_score_direction_v1(pg_temp.q100_actor('male1'), pg_temp.q100_actor('fem1'));
$$;

-- Fill the actual question bank's own and counterpart vocabularies.
update public.onboarding_answers o
set ch3_answers = (
  select jsonb_object_agg(q.qid, case when q.is_multi
    then jsonb_build_array(q.options -> 0) else q.options -> 0 end)
  from public.zyra_onboarding_questions q
  where q.gender_visibility in ('all', case p.gender when 'male' then 'menOnly' else 'womenOnly' end)
),
ch4_preferences = (
  select jsonb_object_agg(q.qid, (
    select jsonb_object_agg(opt, case
      when q.qid in ('ch3_q81','ch3_q87','ch3_q90') then 'red' else 'green' end)
    from jsonb_array_elements_text(q.options) opt
  ))
  from public.zyra_onboarding_questions q
  where q.ch4_scored
    and q.gender_visibility in ('all', case p.gender when 'male' then 'womenOnly' else 'menOnly' end)
),
ch4_hard_requirements = '{}'::jsonb, capture_version = 'v1'
from public.profiles p
where p.id = o.user_id and p.id in (pg_temp.q100_actor('male1'), pg_temp.q100_actor('fem1'));

update public.seeker_details
set sect = 'sunni', revert_status = false, country_of_birth = 'GB',
    nationality = 'GB', ethnicity = 'other', languages = array['en'],
    preferences = '{
      "sect":{"matrix":{"sunni":"green","shia":"green","other":"green"},"hard_requirement":[]},
      "revert":{"flexibility":"green"},
      "country_of_birth":{"skipped":true},
      "nationality":{"preferred":["GB"],"skipped":false,"flexibility":"red"},
      "ethnicity":{"skipped":true},
      "languages":{"preferred":["en"],"skipped":false,"flexibility":"green"}
    }', capture_version = 'v1'
where user_id in (pg_temp.q100_actor('male1'), pg_temp.q100_actor('fem1'));

select pg_temp.q100_assert(
  has_function_privilege('service_role', 'public.zyra_score_direction_v1(uuid,uuid)', 'execute')
  and not has_function_privilege('authenticated', 'public.zyra_score_direction_v1(uuid,uuid)', 'execute')
  and not has_function_privilege('anon', 'public.zyra_score_direction_v1(uuid,uuid)', 'execute')
  and not has_function_privilege('authenticated', 'private.zyra_save_direction_result(uuid,uuid)', 'execute')
  and not has_table_privilege('service_role', 'private.zyra_directional_results', 'SELECT'),
  'strict scoring is service-only and results are private');
select pg_temp.q100_assert(
  (select state = 'ok' and capture_version = 'v1'
    and overall between 90 and 100 and jsonb_array_length(area_bands) = 12
    and area_bands ->> 7 = 'strong' and area_bands ->> 10 = 'good'
    and area_bands ->> 11 = 'not_enough'
    and area_bands::text !~ '[0-9]'
    and inputs_hash ~ '^[0-9a-f]{64}$'
   from pg_temp.q100_score()),
  'one actual scoring pass hits exact 75/50 and fewer-than-three band boundaries');

savepoint q100_bad_answer;
update public.onboarding_answers set ch3_answers = ch3_answers - 'ch3_q1'
where user_id = pg_temp.q100_actor('fem1');
select pg_temp.q100_assert(
  (select state = 'incomplete' and overall is null and area_bands is null from pg_temp.q100_score()),
  'missing applicable answer never yields a score');
rollback to q100_bad_answer;

savepoint q100_bad_light;
update public.onboarding_answers set ch4_preferences =
  ch4_preferences #- array['ch3_q1','Never Married']
where user_id = pg_temp.q100_actor('male1');
select pg_temp.q100_assert(
  (select state = 'incomplete' and overall is null and area_bands is null from pg_temp.q100_score()),
  'missing required light never yields a score');
rollback to q100_bad_light;

savepoint q100_wrong_alias;
update public.onboarding_answers set ch3_answers =
  jsonb_set(ch3_answers, '{ch3_q26}', '"I only wish to have one wife"')
where user_id = pg_temp.q100_actor('fem1');
select pg_temp.q100_assert(
  (select state = 'invalid' and overall is null and area_bands is null from pg_temp.q100_score()),
  'a stale counterpart variant is invalid');
rollback to q100_wrong_alias;

savepoint q100_legacy;
update public.onboarding_answers set capture_version = 'v0',
  ch4_preferences = jsonb_set(ch4_preferences, array['ch3_q1','Never Married'], '"amber"')
where user_id = pg_temp.q100_actor('male1');
select pg_temp.q100_assert(
  (select state = 'needs_reconfirmation' and overall is null and area_bands is null from pg_temp.q100_score()),
  'v0 Amber requires reconfirmation with no score');
select pg_temp.q100_assert(
  (private.zyra_save_direction_result(pg_temp.q100_actor('male1'), pg_temp.q100_actor('fem1'))).state
    = 'needs_reconfirmation'
  and not exists (select 1 from private.zyra_directional_results),
  'unsuccessful scoring is never persisted and can be retried');
rollback to q100_legacy;

create temporary table q100_unmodified_score on commit drop as
select overall from pg_temp.q100_score();
savepoint q100_raw_amber;
update public.onboarding_answers set
  ch4_preferences = jsonb_set(ch4_preferences, array['ch3_q1','Never Married'], '"amber"')
where user_id = pg_temp.q100_actor('male1');
select pg_temp.q100_assert(
  (select state = 'needs_reconfirmation' and overall is null from pg_temp.q100_score()),
  'even a v1 source row cannot turn an unconfirmed Amber into a score');
rollback to q100_raw_amber;

savepoint q100_ch2_light;
update public.seeker_details set preferences = preferences #- '{sect,matrix,other}'
where user_id = pg_temp.q100_actor('male1');
select pg_temp.q100_assert(
  (select state = 'incomplete' and overall is null from pg_temp.q100_score()),
  'a missing required Chapter 2 sect light never yields a score');
rollback to q100_ch2_light;

savepoint q100_ch2_preference;
update public.seeker_details set preferences = jsonb_set(preferences, '{nationality,preferred}', '[]')
where user_id = pg_temp.q100_actor('male1');
select pg_temp.q100_assert(
  (select state = 'incomplete' and overall is null from pg_temp.q100_score()),
  'a non-skipped Chapter 2 control must have a selected preference');
rollback to q100_ch2_preference;

-- Q105: append inside the Q100 fixture transaction, before its final rollback.
savepoint q105_preference_confirmation;

grant select on server0_v2_fixture_actors to authenticated;
grant execute on function pg_temp.q100_actor(text) to authenticated;

create function pg_temp.q105_as(p_label text) returns void
language sql volatile as $$
  select set_config('request.jwt.claims',
    jsonb_build_object('sub', pg_temp.q100_actor(p_label), 'role', 'authenticated')::text,
    true);
$$;
create function pg_temp.q105_assert(p_ok boolean, p_check text) returns void
language plpgsql as $$
begin
  if p_ok is distinct from true then raise exception 'Q105 FAIL: %', p_check; end if;
  raise notice 'Q105 PASS: %', p_check;
end;
$$;
grant execute on function pg_temp.q105_as(text), pg_temp.q105_assert(boolean,text)
to authenticated;

create temporary table q105_score_endpoints (light text primary key, overall numeric) on commit drop;
insert into q105_score_endpoints
select 'green', overall from pg_temp.q100_score();

update public.onboarding_answers
set ch4_preferences = jsonb_set(ch4_preferences, '{ch3_q1,Never Married}', '"red"')
where user_id = pg_temp.q100_actor('male1');
insert into q105_score_endpoints
select 'red', overall from pg_temp.q100_score();

-- The fixture rows explicitly carry v1 at row level. Without an item receipt
-- even this stamp cannot turn an unconfirmed v0 light into v1.
update public.onboarding_answers
set capture_version = 'v1',
    ch4_preferences = jsonb_set(
      jsonb_set(ch4_preferences, '{ch3_q1,Never Married}', '"amber"'),
      '{ch3_q1,Separated}', '"yellow"')
where user_id = pg_temp.q100_actor('male1');
update public.onboarding_answers
set ch4_preferences = jsonb_set(ch4_preferences, '{ch3_q2,No}', '"amber"')
where user_id = pg_temp.q100_actor('fem1');

select pg_temp.q105_assert(
  (select state = 'needs_reconfirmation' and overall is null and area_bands is null
   from pg_temp.q100_score()),
  'row stamp cannot convert plain legacy Amber and Yellow into a score'
);
select pg_temp.q105_assert(
  not has_function_privilege('anon', 'public.zyra_confirm_preference_lights(jsonb)', 'execute')
  and not has_function_privilege('anon', 'public.zyra_my_lights_needing_reconfirmation()', 'execute')
  and has_table_privilege('authenticated', 'public.preference_light_confirmations', 'SELECT')
  and not has_table_privilege('authenticated', 'public.preference_light_confirmations', 'INSERT')
  and not has_table_privilege('authenticated', 'public.preference_light_confirmations', 'UPDATE')
  and not has_table_privilege('authenticated', 'public.preference_light_confirmations', 'DELETE'),
  'receipt reads are authenticated and the RPC is the only member writer'
);

set local role authenticated;
select pg_temp.q105_as('fem1');
select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch3_q1","option_value":"Never Married","light":"green"}]'
);
select pg_temp.q105_as('male1');

select pg_temp.q105_assert(
  (select jsonb_agg(to_jsonb(l) order by l.option_value)
   from public.zyra_my_lights_needing_reconfirmation() l) =
  '[{"question_id":"ch3_q1","option_value":"Never Married","light":"amber"},
    {"question_id":"ch3_q1","option_value":"Separated","light":"amber"}]'::jsonb,
  'only caller-affected items are listed, including the app legacy Yellow'
);
select pg_temp.q105_assert(
  not exists (select 1 from public.preference_light_confirmations),
  'caller cannot see another member receipt'
);

select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch3_q1","option_value":"Never Married","light":"amber"},
    {"question_id":"ch3_q1","option_value":"Separated","light":"green"}]'
);

select pg_temp.q105_assert(
  (select count(*) = 2 and bool_and(user_id = auth.uid() and capture_version = 'v1'
                                   and confirmed_at is not null)
   from public.preference_light_confirmations)
  and exists (
    select 1 from public.preference_light_confirmations
    where question_id = 'ch3_q1' and option_value = 'Never Married' and light = 'amber'
  )
  and not exists (select 1 from public.zyra_my_lights_needing_reconfirmation()),
  'reconfirming the same Amber writes a matching caller-owned v1 receipt'
);

do $q105_atomic$
begin
  perform public.zyra_confirm_preference_lights(
    '[{"question_id":"ch3_q1","option_value":"Never Married","light":"red"},
      {"question_id":"not_a_question","option_value":"invalid","light":"amber"}]'
  );
  raise exception 'Q105 FAIL: invalid mixed batch was accepted';
exception
  when invalid_parameter_value then
    if sqlerrm <> 'invalid_preference_lights' then raise; end if;
end
$q105_atomic$;
select pg_temp.q105_assert(
  (select ch4_preferences #>> '{ch3_q1,Never Married}' = 'amber'
   from public.onboarding_answers where user_id = auth.uid())
  and (select count(*) = 2 from public.preference_light_confirmations)
  and exists (
    select 1 from public.preference_light_confirmations
    where question_id = 'ch3_q1' and option_value = 'Never Married' and light = 'amber'
  ),
  'invalid mixed batch rolls back both the earlier JSON write and receipt'
);

reset role;
select pg_temp.q105_assert(
  (select scored.state = 'ok'
     and scored.overall > red.overall and scored.overall < green.overall
     and abs(scored.overall - (green.overall + red.overall) / 2) <= 0.1
   from pg_temp.q100_score() scored
   cross join q105_score_endpoints green cross join q105_score_endpoints red
   where green.light = 'green' and red.light = 'red'),
  'confirmed unchanged Amber lands halfway between Green and Red within stored rounding'
);

set local role authenticated;
select pg_temp.q105_as('male1');
select set_config('zyra.confirm_preference_lights', 'on', true);
update public.onboarding_answers
set ch4_preferences = jsonb_set(ch4_preferences, '{ch3_q1,Never Married}', '"red"')
where user_id = auth.uid();
select pg_temp.q105_assert(
  not exists (
    select 1 from public.preference_light_confirmations
    where question_id = 'ch3_q1' and option_value = 'Never Married'
  )
  and exists (
    select 1 from public.preference_light_confirmations
    where question_id = 'ch3_q1' and option_value = 'Separated' and light = 'green'
  ),
  'even a forged transaction flag cannot preserve a changed receipt'
);

update public.onboarding_answers
set ch4_preferences = jsonb_set(ch4_preferences, '{ch3_q1,Never Married}', '"amber"')
where user_id = auth.uid();
select pg_temp.q105_assert(
  not exists (
    select 1 from public.preference_light_confirmations
    where question_id = 'ch3_q1' and option_value = 'Never Married'
  )
  and (select count(*) = 1 and bool_and(question_id = 'ch3_q1'
       and option_value = 'Never Married' and light = 'amber')
       from public.zyra_my_lights_needing_reconfirmation()),
  'restoring Amber through plain JSON cannot recreate its receipt'
);
reset role;
select pg_temp.q105_assert(
  (select state = 'needs_reconfirmation' and overall is null and area_bands is null
   from pg_temp.q100_score()),
  'an invalidated and restored Amber still has no score'
);
select set_config('zyra.confirm_preference_lights', '', true);

set local role authenticated;
select pg_temp.q105_as('male1');
select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch3_q1","option_value":"Never Married","light":"green"}]'
);
update public.seeker_details
set preferences = jsonb_set(preferences, '{sect,matrix,sunni}', '"yellow"')
where user_id = auth.uid();
select pg_temp.q105_assert(
  (select count(*) = 1 and bool_and(question_id = 'sect' and option_value = 'sunni'
                                   and light = 'amber')
   from public.zyra_my_lights_needing_reconfirmation()),
  'the Chapter 2 sect matrix uses the same affected-item reader'
);
select public.zyra_confirm_preference_lights(
  '[{"question_id":"sect","option_value":"sunni","light":"amber"}]'
);
select pg_temp.q105_assert(
  (select preferences #>> '{sect,matrix,sunni}' = 'amber'
   from public.seeker_details where user_id = auth.uid())
  and exists (
    select 1 from public.preference_light_confirmations
    where question_id = 'sect' and option_value = 'sunni'
      and light = 'amber' and capture_version = 'v1'
  )
  and not exists (select 1 from public.zyra_my_lights_needing_reconfirmation()),
  'Chapter 2 confirmation writes the light and receipt together'
);
reset role;
select pg_temp.q105_assert(
  (select scored.state = 'ok'
     and scored.overall > red.overall and scored.overall < green.overall
     and abs(scored.overall - (green.overall + red.overall) / 2) <= 0.1
   from pg_temp.q100_score() scored
   cross join q105_score_endpoints green cross join q105_score_endpoints red
   where green.light = 'green' and red.light = 'red'),
  'confirmed applicable Chapter 2 Amber also contributes half'
);

delete from public.onboarding_answers where user_id = pg_temp.q100_actor('male1');
select pg_temp.q105_assert(
  not exists (
    select 1 from public.preference_light_confirmations
    where user_id = pg_temp.q100_actor('male1') and question_id = 'ch3_q1'
  )
  and exists (
    select 1 from public.preference_light_confirmations
    where user_id = pg_temp.q100_actor('male1') and question_id = 'sect' and option_value = 'sunni'
  ),
  'deleting a preference row revokes only its chapter receipts'
);
rollback to q105_preference_confirmation;
release savepoint q105_preference_confirmation;

create temporary table q100_saved on commit drop as
select s.* from private.zyra_save_direction_result(pg_temp.q100_actor('male1'), pg_temp.q100_actor('fem1')) s;
select pg_temp.q100_assert(
  (select count(*) = 1 from private.zyra_directional_results)
  and (select state = 'ok' from q100_saved),
  'the first valid result is written once');
update public.onboarding_answers
set ch4_preferences = jsonb_set(ch4_preferences, '{ch3_q85}', (
  select jsonb_object_agg(option, 'red')
  from public.zyra_onboarding_questions q
  cross join lateral jsonb_array_elements_text(q.options) option
  where q.qid = 'ch3_q85'
))
where user_id = pg_temp.q100_actor('male1');
select pg_temp.q100_assert(
  (select area_bands ->> 10 = 'some_differences' from pg_temp.q100_score())
  and (select s.inputs_hash = b.inputs_hash and s.overall = b.overall and s.area_bands = b.area_bands
             and s.created_at = b.created_at
       from private.zyra_save_direction_result(pg_temp.q100_actor('male1'), pg_temp.q100_actor('fem1')) s
       cross join q100_saved b)
  and (select count(*) = 1 from private.zyra_directional_results),
  'changed inputs would change the score but cannot refresh the saved result');
rollback;

-- Q100 adapter assertions against the governed throw-away replay.
begin;
\set server0_fixture_case oa283
\ir fixtures/server0_v2_full_schema_prestate.sql

do $adapter$
declare
  v_a constant uuid := 'ac6f5cf7-4695-4332-8cc6-58227ac2f89f';
  v_b constant uuid := 'fd47fa36-99fb-4f11-b891-034a769e42c4';
  v_match constant uuid := '5fde2346-d96f-45dd-869f-64eac717e27f';
  v_row record;
  v_projection public.journey_compatibility%rowtype;
  v_score numeric;
  v_revealed_at timestamptz;
begin
  -- Legacy fixtures never provide authoritative directional values.
  update public.journey_compatibility set seeker_a_score = 11, seeker_b_score = 22
  where match_id = v_match;
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims', jsonb_build_object('sub', v_a, 'role', 'authenticated')::text, true);
  begin
    perform public.zyra_compatibility_for_plus(v_match);
    raise exception 'Q100 Plus unexpectedly available';
  exception when insufficient_privilege then
    if sqlerrm <> 'plus_required' then raise; end if;
  end;
  if public.zyra_unlock_profile(v_b, 'paid_plus_single')->>'status' <> 'plus_unavailable' then
    raise exception 'Q100 new Plus must remain on hold';
  end if;
  select * into strict v_row from public.zyra_reveal_journey_compatibility(v_match);
  if not v_row.mine_revealed or v_row.counterpart_revealed or v_row.my_score is not null then
    raise exception 'Q100 first Reveal leaked a score or altered the counterpart consent';
  end if;
  perform set_config('role', 'postgres', true);
  select * into strict v_projection from public.journey_compatibility where match_id = v_match;
  if v_projection.seeker_a_score is not null or v_projection.seeker_b_score is not null
     or exists (select 1 from private.zyra_directional_results where viewer in (v_a, v_b)) then
    raise exception 'Q100 unavailable synthetic inputs must clear provisional projections without saving';
  end if;

  -- These approved-shape synthetic saved results exercise the adapter without
  -- relying on the separate strict scorer fixture. Seed one pre-hold Plus row.
  insert into private.zyra_directional_results
    (viewer, subject, capture_version, inputs_hash, overall, area_bands, state)
  values
    (v_a, v_b, 'v1', repeat('a', 64), 81,
      to_jsonb(array_fill('strong'::text, array[12])), 'ok'),
    (v_b, v_a, 'v1', repeat('b', 64), 62,
      to_jsonb(array_fill('good'::text, array[12])), 'ok');
  alter table public.profile_unlocks disable trigger zyra_unlock_row_guard;
  insert into public.profile_unlocks (unlocker_id, unlocked_id, unlock_type)
  values (v_a, v_b, 'paid_plus_single');
  alter table public.profile_unlocks enable trigger zyra_unlock_row_guard;

  perform set_config('role', 'authenticated', true);
  select public.zyra_compatibility_for_plus(v_match) into v_score;
  if v_score is distinct from 81::numeric then
    raise exception 'Q100 existing Plus must read the caller direction';
  end if;
  select * into strict v_row from public.zyra_journey_compatibility_state(v_match);
  if not v_row.mine_revealed or v_row.counterpart_revealed or v_row.my_score is not null then
    raise exception 'Q100 Plus changed consent or leaked through the ordinary state';
  end if;

  perform set_config('request.jwt.claims', jsonb_build_object('sub', v_b, 'role', 'authenticated')::text, true);
  select * into strict v_row from public.zyra_reveal_journey_compatibility(v_match);
  if not v_row.mine_revealed or not v_row.counterpart_revealed or v_row.my_score is distinct from 62::numeric then
    raise exception 'Q100 mutual Reveal must return the caller saved direction';
  end if;
  perform set_config('role', 'postgres', true);
  select * into strict v_projection from public.journey_compatibility where match_id = v_match;
  if v_projection.seeker_a_score is distinct from 81::numeric
     or v_projection.seeker_b_score is distinct from 62::numeric
     or v_projection.revealed_at is null then
    raise exception 'Q100 mutual Reveal must project both saved directions';
  end if;
  v_revealed_at := v_projection.revealed_at;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims', jsonb_build_object('sub', v_a, 'role', 'authenticated')::text, true);
  select * into strict v_row from public.zyra_reveal_journey_compatibility(v_match);
  if v_row.my_score is distinct from 81::numeric then
    raise exception 'Q100 the original Reveal side must reuse its saved direction';
  end if;
  perform set_config('role', 'postgres', true);
  if not exists (select 1 from public.journey_compatibility where match_id = v_match and revealed_at = v_revealed_at) then
    raise exception 'Q100 Reveal retry changed the original mutual consent timestamp';
  end if;
  raise notice 'Q100 Journey and Plus adapter assertions passed';
end
$adapter$;

rollback;
\set server0_fixture_case core

-- Q92 reader boundary. Strict scoring and save-once use separate assertions.
begin;
\set server0_fixture_case oa283
\ir fixtures/server0_v2_full_schema_prestate.sql

grant select on server0_v2_fixture_actors to authenticated;

create function pg_temp.q92_actor(p_label text)
returns uuid language sql stable security invoker as $$
  select id from server0_v2_fixture_actors where fixture_label = p_label;
$$;

create function pg_temp.q92_as(p_label text)
returns void language plpgsql security invoker as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', pg_temp.q92_actor(p_label), 'role', 'authenticated')::text, true);
end;
$$;

create function pg_temp.q92_assert(p_ok boolean, p_label text)
returns void language plpgsql security invoker as $$
begin
  if p_ok is distinct from true then raise exception 'Q92 reader FAIL: %', p_label; end if;
  raise notice 'Q92 reader PASS: %', p_label;
end;
$$;

create function pg_temp.q92_match()
returns uuid language sql immutable security invoker as $$
  select '5fde2346-d96f-45dd-869f-64eac717e27f'::uuid;
$$;

create function pg_temp.q92_topics(p_subject text)
returns table(overall numeric, topics_locked boolean, area_no smallint, area_code text, band text, state text)
language sql volatile security invoker as $$
  select * from public.zyra_compatibility_topics(pg_temp.q92_actor(p_subject), pg_temp.q92_match());
$$;

grant execute on function pg_temp.q92_actor(text), pg_temp.q92_as(text),
  pg_temp.q92_assert(boolean, text), pg_temp.q92_match(), pg_temp.q92_topics(text) to authenticated;

select pg_temp.q92_assert(
  has_function_privilege('authenticated', 'public.zyra_compatibility_topics(uuid,uuid)', 'execute')
  and not has_function_privilege('anon', 'public.zyra_compatibility_topics(uuid,uuid)', 'execute')
  and not has_function_privilege('service_role', 'public.zyra_compatibility_topics(uuid,uuid)', 'execute')
  and not has_table_privilege('authenticated', 'private.zyra_directional_results', 'select')
  and not has_function_privilege('authenticated', 'private.zyra_save_direction_result(uuid,uuid)', 'execute'),
  'authenticated-only reader and inaccessible saved rows and saver');

-- Synthetic completed directions have disjoint values so reversed and
-- caller-relative leakage cannot accidentally satisfy the tests.
insert into private.zyra_directional_results
  (viewer, subject, capture_version, inputs_hash, overall, area_bands, state)
values
  (pg_temp.q92_actor('oa283a'), pg_temp.q92_actor('oa283b'), 'v1', repeat('a', 64),
   73, '["strong","good","some_differences","not_enough","strong","good","some_differences","not_enough","strong","good","some_differences","not_enough"]', 'ok'),
  (pg_temp.q92_actor('oa283b'), pg_temp.q92_actor('oa283a'), 'v1', repeat('b', 64),
   19, '["some_differences","some_differences","some_differences","some_differences","some_differences","some_differences","some_differences","some_differences","some_differences","some_differences","some_differences","some_differences"]', 'ok');

set local role authenticated;
select pg_temp.q92_as('oa283a');
select pg_temp.q92_assert(not exists(select from pg_temp.q92_topics('oa283b')),
  'saved row alone cannot bypass reveal consent');
select pg_temp.q92_assert(not exists(select from public.zyra_compatibility_topics(pg_temp.q92_actor('oa283b'))),
  'Profiles entry requires owned Unlock');
select pg_temp.q92_as('gb');
select pg_temp.q92_assert(not exists(select from pg_temp.q92_topics('oa283b')),
  'Main Guardian cannot see pre-reveal result');
reset role;

update public.journey_compatibility
set seeker_a_revealed = true, seeker_b_revealed = true, revealed_at = now()
where match_id = pg_temp.q92_match();

insert into public.profile_unlocks (unlocker_id, unlocked_id, unlock_type)
values (pg_temp.q92_actor('oa283a'), pg_temp.q92_actor('fem1'), 'paid_single'),
       (pg_temp.q92_actor('oa283b'), pg_temp.q92_actor('oa283a'), 'automatic_match');

set local role authenticated;
select pg_temp.q92_as('oa283a');
select pg_temp.q92_assert(
  (select count(*) = 12 and bool_and(overall = 73 and topics_locked and band is null and state = 'ok')
   and array_agg(area_code order by area_no) =
     array['deen','marriage','children','family','finances','work','home','communication','personality','lifestyle','digital','culture']
   from pg_temp.q92_topics('oa283b')),
  'Basic shows ordered area names and own Overall, and another subject Unlock does not open bands');
select pg_temp.q92_assert(not exists(select from pg_temp.q92_topics('fem1')),
  'owned Unlock on another person cannot be paired with this match');
select pg_temp.q92_as('oa283b');
select pg_temp.q92_assert(
  (select count(*) = 12 and bool_and(overall = 19 and topics_locked and band is null)
   from pg_temp.q92_topics('oa283a')),
  'reverse direction has its own Overall and an automatic match grant opens no bands');
select pg_temp.q92_as('male1');
select pg_temp.q92_assert(not exists(select from pg_temp.q92_topics('oa283b')),
  'stranger with exact match and subject IDs gets no result');
reset role;

update public.subscriptions set plan_type = 'seeker_premium'
where user_id = pg_temp.q92_actor('oa283a');
set local role authenticated;
select pg_temp.q92_as('oa283a');
select pg_temp.q92_assert(
  (select count(*) = 12 and bool_and(overall = 73 and not topics_locked and band is not null)
   from pg_temp.q92_topics('oa283b')),
  'Seeker One opens bands without an exact paid Unlock after mutual reveal');
reset role;
update public.subscriptions set plan_type = 'seeker_basic'
where user_id = pg_temp.q92_actor('oa283a');

insert into public.profile_unlocks (unlocker_id, unlocked_id, unlock_type)
values (pg_temp.q92_actor('oa283a'), pg_temp.q92_actor('oa283b'), 'paid_single');

set local role authenticated;
select pg_temp.q92_as('oa283a');
select pg_temp.q92_assert(
  (select count(*) = 12 and bool_and(overall = 73 and not topics_locked and band is not null)
   from public.zyra_compatibility_topics(pg_temp.q92_actor('oa283b'))),
  'same-person paid Unlock opens the persisted direction from Profiles');
select pg_temp.q92_assert(
  (select to_jsonb(t) = jsonb_build_object(
    'overall',73,'topics_locked',false,'area_no',1,'area_code','deen','band','strong','state','ok')
   from pg_temp.q92_topics('oa283b') t where area_no = 1),
  'open projection exposes only the approved fields and a band code');
select pg_temp.q92_as('gb');
select pg_temp.q92_assert(
  (select count(*) = 12 and bool_and(overall = 73 and topics_locked and band is null)
   from pg_temp.q92_topics('oa283b')),
  'Guardian Basic stays locked even when linked Seeker owns the Unlock');
select pg_temp.q92_assert(not exists(select from pg_temp.q92_topics('oa283a')),
  'Guardian cannot reverse the requested direction');
select pg_temp.q92_assert(not exists(select from public.zyra_compatibility_topics(pg_temp.q92_actor('oa283b'))),
  'Guardian requires exact Journey context');
reset role;

update public.subscriptions set plan_type = 'wali_premium'
where user_id = pg_temp.q92_actor('gb');
insert into public.wali_links (seeker_id, wali_id, status)
values (pg_temp.q92_actor('oa283a'), pg_temp.q92_actor('gadd'), 'active');

set local role authenticated;
select pg_temp.q92_as('gb');
select pg_temp.q92_assert(
  (select count(*) = 12 and bool_and(overall = 73 and not topics_locked and band is not null)
   from pg_temp.q92_topics('oa283b')),
  'Guardian One receives bands from their own linked Seeker direction');
select pg_temp.q92_as('gadd');
select pg_temp.q92_assert(not exists(select from pg_temp.q92_topics('oa283b')),
  'active Additional Guardian still needs exact-attempt View permission');
reset role;

insert into public.journey_guardian_assignments (attempt_id, wali_link_id, seeker_id, granted_by, granted_at)
select attempt.id, link.id, link.seeker_id, link.seeker_id, clock_timestamp()
from public.journey_attempts attempt
join public.wali_links link on link.seeker_id = pg_temp.q92_actor('oa283a')
  and link.wali_id = pg_temp.q92_actor('gadd')
where attempt.match_id = pg_temp.q92_match() and attempt.status = 'active';

set local role authenticated;
select pg_temp.q92_as('gadd');
select pg_temp.q92_assert(
  (select count(*) = 12 and bool_and(topics_locked and band is null) from pg_temp.q92_topics('oa283b')),
  'included Additional Guardian receives the Basic locked projection');
select pg_temp.q92_as('oa283a');
select public.end_journey(pg_temp.q92_match());
reset role;
-- The fixture link clock advances after the outer transaction's now().
update public.journey_attempts set ended_at = clock_timestamp()
where match_id = pg_temp.q92_match() and status = 'ended';
update public.matches set ended_at = clock_timestamp()
where id = pg_temp.q92_match();

set local role authenticated;
select pg_temp.q92_as('gb');
select pg_temp.q92_assert(
  (select count(*) = 12 and bool_and(overall = 73 and not topics_locked and band is not null)
   from pg_temp.q92_topics('oa283b')),
  'Guardian One can read their direction in the exact readable ended attempt');
reset role;

savepoint q92_restart;
with next_attempt as (
  insert into public.journey_attempts (match_id, attempt_number, status, journey_stage, started_at)
  values (pg_temp.q92_match(), 2, 'active', 'salam_exchange', clock_timestamp())
  returning id
)
insert into public.journey_requests
  (match_id, requested_by, requested_to, status, expires_at, responded_at, attempt_id, closed_reason)
select pg_temp.q92_match(), pg_temp.q92_actor('oa283a'), pg_temp.q92_actor('oa283b'),
       'accepted', now() + interval '7 days', clock_timestamp(), id, 'accepted'
from next_attempt;
update public.matches
set status = 'active', journey_stage = 'salam_exchange',
    ended_at = null, ended_by = null, end_reason = null, end_note = null
where id = pg_temp.q92_match();
set local role authenticated;
select pg_temp.q92_as('gb');
select pg_temp.q92_assert(
  (select count(*) = 12 and bool_and(overall = 73 and not topics_locked and band is not null)
   from pg_temp.q92_topics('oa283b')),
  'an accepted restart reuses the saved direction under current Main Guardian access');
select pg_temp.q92_as('gadd');
select pg_temp.q92_assert(not exists(select from pg_temp.q92_topics('oa283b')),
  'an earlier Additional Guardian assignment does not transfer to the restarted attempt');
reset role;
rollback to q92_restart;

update public.journey_attempts set ended_at = now() - interval '3 months 1 day'
where match_id = pg_temp.q92_match() and status = 'ended';
update public.matches set ended_at = now() - interval '3 months 1 day'
where id = pg_temp.q92_match();

set local role authenticated;
select pg_temp.q92_as('gb');
select pg_temp.q92_assert(not exists(select from pg_temp.q92_topics('oa283b')),
  'Guardian archive older than three months returns no rows');
select pg_temp.q92_as('oa283a');
select pg_temp.q92_assert(not exists(select from pg_temp.q92_topics('oa283b')),
  'Seeker archive older than three months returns no rows');
select pg_temp.q92_assert(
  (select count(*) = 12 and bool_and(overall = 73 and not topics_locked and band is not null)
   from public.zyra_compatibility_topics(pg_temp.q92_actor('oa283b'))),
  'owned Profiles Unlock survives ordinary Journey archive expiry');
reset role;
update public.matches set end_reason = 'safety_concern' where id = pg_temp.q92_match();
set local role authenticated;
select pg_temp.q92_as('oa283a');
select pg_temp.q92_assert(
  not exists(select from public.zyra_compatibility_topics(pg_temp.q92_actor('oa283b'))),
  'safety ending withholds disclosure even through a permanent Profiles Unlock');
rollback;
\set server0_fixture_case core

-- Q94/Q99/Q101: discovery, personal hide and home place on the governed replay.
begin;

do $q94_guard$
begin
  if current_database() !~ '^zyra_server0_v2_[a-z0-9_]+$'
     or current_user <> 'postgres' then
    raise exception 'Q94 requires a disposable SERVER0 replay and postgres';
  end if;
end
$q94_guard$;

create function pg_temp.q94_id(n int)
returns uuid language sql immutable as $$
  select ('94000000-0000-4000-8000-' || lpad(n::text, 12, '0'))::uuid
$$;

create function pg_temp.q94_as(n int)
returns void language sql volatile as $$
  select set_config('request.jwt.claims',
    jsonb_build_object('sub', pg_temp.q94_id(n), 'role', 'authenticated')::text, true)
$$;

create function pg_temp.q94_assert(ok boolean, label text)
returns void language plpgsql as $$
begin
  if ok is distinct from true then
    raise exception 'Q94 FAIL: %', label;
  end if;
  raise notice 'Q94 PASS: %', label;
end
$$;

grant execute on function pg_temp.q94_id(int), pg_temp.q94_as(int),
  pg_temp.q94_assert(boolean, text) to authenticated;

insert into auth.users (id, aud, role, email, raw_app_meta_data, raw_user_meta_data,
                        created_at, updated_at)
select pg_temp.q94_id(n), 'authenticated', 'authenticated',
  'q94-' || n::text || '@example.invalid',
  '{"provider":"email","providers":["email"]}', '{}', now(), now()
from generate_series(1, 73) as member(n);

insert into public.profiles (id, role, first_name, date_of_birth, gender,
                             location_text, is_active, profile_complete)
select pg_temp.q94_id(n),
  case when n = 10 then 'wali' else 'seeker' end,
  'Fixture', (current_date - make_interval(years => case when n > 16 then 60 else 30 end))::date,
  case when n in (1, 7) then 'male' else 'female' end,
  'Fixture Town', n <> 9, n <> 8
from generate_series(1, 73) as member(n);

insert into public.seeker_details (user_id, nationality, ethnicity, sect, preferences)
values
  (pg_temp.q94_id(1), null, null, null,
    '{"nationality":{"preferred":["FR"],"flexibility":"red"},"sect":{"hard_requirement":["shia"]}}'),
  (pg_temp.q94_id(2), 'GB', 'white_british', 'sunni', '{}'),
  (pg_temp.q94_id(3), 'FR', 'white_other', 'sunni', '{}'),
  (pg_temp.q94_id(4), null, null, 'sunni', '{}'),
  (pg_temp.q94_id(14), 'GB', 'white_british', 'shia', '{}'),
  (pg_temp.q94_id(15), 'GB', 'white_other', 'sunni', '{}');

-- Meet the real browsing visibility gate. The viewer's legacy empty
-- Chapter 3 light maps make the ranking fixture depend on Chapter 2.
insert into public.seeker_details (user_id, preferences)
select p.id, '{"sect":{"matrix":{"sunni":"green"},"hard_requirement":[]}}'
from public.profiles p
where p.id in (select pg_temp.q94_id(n) from generate_series(1, 73) member(n))
  and p.role = 'seeker'
on conflict (user_id) do update
set preferences = excluded.preferences
where public.seeker_details.preferences = '{}'::jsonb;

insert into public.onboarding_answers (user_id, ch3_answers, ch4_preferences,
                                      ch4_hard_requirements, is_synthetic)
select p.id,
  jsonb_object_agg(q.qid, case when q.is_multi
    then jsonb_build_array(q.options -> 0)
    else coalesce(q.options -> 0, '"fixture"'::jsonb) end),
  jsonb_object_agg(q.qid, '{}'::jsonb), '{}'::jsonb, true
from public.profiles p
join public.zyra_onboarding_questions q
  on q.gender_visibility = 'all'
  or q.gender_visibility = case p.gender when 'male' then 'menOnly' else 'womenOnly' end
where p.id in (select pg_temp.q94_id(n) from generate_series(1, 73) member(n))
  and p.role = 'seeker'
group by p.id;

-- Owner-bound display media. Each SQL insert presents the true owner claim.
do $photos$
declare
  member_id uuid;
  object_path text;
  n int;
begin
  for n in 2..73 loop
    continue when n = 11;
    member_id := pg_temp.q94_id(n);
    object_path := member_id::text || '/94000000-0000-4000-8000-000000009401.jpg';
    perform pg_temp.q94_as(n);
    insert into storage.objects (bucket_id, name, owner_id)
    values ('profile-photos', object_path, member_id::text);
    insert into public.profile_photos (user_id, storage_path)
    values (member_id, object_path);
  end loop;
end
$photos$;

insert into public.profile_blocks (blocker_id, blocked_id) values
  (pg_temp.q94_id(5), pg_temp.q94_id(1)),
  (pg_temp.q94_id(1), pg_temp.q94_id(12));

insert into public.subscriptions (user_id, plan_type, status)
values (pg_temp.q94_id(1), 'seeker_basic', 'active');

insert into public.wali_links (seeker_id, wali_id, status, is_main, relationship)
values (pg_temp.q94_id(1), pg_temp.q94_id(10), 'active', true, 'other');

select pg_temp.q94_assert(
  not has_function_privilege('anon',
    'public.zyra_discover_profile_ids(int,int,text,int,text,text[],text[],int,uuid)', 'execute')
  and has_function_privilege('authenticated',
    'public.zyra_discover_profile_ids(int,int,text,int,text,text[],text[],int,uuid)', 'execute')
  and not has_table_privilege('authenticated', 'private.seeker_home_places', 'SELECT')
  and not has_table_privilege('authenticated', 'private.seeker_home_places', 'UPDATE')
  and not has_table_privilege('authenticated', 'private.seeker_home_places', 'INSERT'),
  'member-only discovery and no direct home-place privileges'
);

set local role authenticated;
select pg_temp.q94_as(1);
select public.zyra_set_my_home_place('GB', 51.40, -0.10);
select public.zyra_set_my_home_place('GB', 51.5072, -0.1276);
select pg_temp.q94_as(2);
select public.zyra_set_my_home_place('GB', 51.5100, -0.1200);
select pg_temp.q94_as(3);
select public.zyra_set_my_home_place('FR', 48.8566, 2.3522);
select pg_temp.q94_as(14);
select public.zyra_set_my_home_place('GB', 51.5072, -0.1276);
select pg_temp.q94_as(15);
select public.zyra_set_my_home_place('GB', 51.5100, -0.1200);

select pg_temp.q94_as(16);
select pg_temp.q94_assert(
  public.zyra_set_profile_hidden(p_profile => pg_temp.q94_id(1), p_hidden => true)
    = jsonb_build_object('schema_version', 1, 'viewer_id', pg_temp.q94_id(16),
                         'profile_id', pg_temp.q94_id(1), 'hidden', true),
  'canonical named hide call returns the exact caller-owned acknowledgement'
);

select pg_temp.q94_as(1);
select pg_temp.q94_assert(
  public.zyra_set_profile_hidden(p_other => pg_temp.q94_id(6)::text, p_hidden => true)
    = jsonb_build_object('schema_version', 1, 'viewer_id', pg_temp.q94_id(1),
                         'profile_id', pg_temp.q94_id(6), 'hidden', true),
  'legacy app named hide call preserves its acknowledgement'
);
select pg_temp.q94_assert(
  public.zyra_my_hidden_profile_ids()
    = jsonb_build_object('schema_version', 1, 'viewer_id', pg_temp.q94_id(1),
                         'profile_ids', jsonb_build_array(pg_temp.q94_id(6)))
  and (select count(*) = 1 from public.profile_hides)
  and not exists (select 1 from public.profile_hides h where h.hider = pg_temp.q94_id(16)),
  'only caller-owned hide rows are readable and incoming hides stay private'
);
select pg_temp.q94_assert(
  (select count(*) = 1 from (select * from public.seeker_details where user_id = auth.uid()) own_row),
  'owner wildcard seeker_details read remains available'
);
do $home_privacy$
begin
  perform 1 from private.seeker_home_places where user_id = pg_temp.q94_id(2);
  raise exception 'Q94 member could read a different home place';
exception when insufficient_privilege then
  perform pg_temp.q94_assert(true, 'another Seeker cannot read a home place');
end
$home_privacy$;
reset role;

select pg_temp.q94_assert(
  (select country_code = 'GB' and lat = 51.51 and lon = -0.13
   from private.seeker_home_places where user_id = pg_temp.q94_id(1)),
  'home-place update applies only to the authenticated owner and rounds to two decimals'
);

set local role authenticated;
select pg_temp.q94_as(10);
select pg_temp.q94_assert(
  (select count(*) = 1 from (
    select * from public.seeker_details where user_id = pg_temp.q94_id(1)
  ) linked),
  'linked Guardian keeps legacy seeker_details read'
);
do $guardian_privacy$
begin
  perform 1 from private.seeker_home_places where user_id = pg_temp.q94_id(1);
  raise exception 'Q94 Guardian could read linked home place';
exception when insufficient_privilege then
  perform pg_temp.q94_assert(true, 'linked Guardian cannot read a home place');
end
$guardian_privacy$;
do $guardian_writer$
begin
  perform public.zyra_set_my_home_place('GB', 0, 0);
  raise exception 'Q94 Guardian could write a Seeker home place';
exception when insufficient_privilege then
  perform pg_temp.q94_assert(true, 'Guardian cannot use the Seeker home writer');
end
$guardian_writer$;

select pg_temp.q94_as(1);

select pg_temp.q94_assert(
  (select array_agg(profile_id) =
    array[pg_temp.q94_id(3), pg_temp.q94_id(2), pg_temp.q94_id(15), pg_temp.q94_id(4), pg_temp.q94_id(13)]
    and bool_and(not one_filters_applied and not location_applied)
   from public.zyra_discover_profile_ids(
     p_age_min => 25, p_age_max => 35,
     p_nationalities => array['FR'], p_ethnicities => array['white_other'])),
  'Basic ignores both lists, admits worldwide without a home place, retains rank and hide/block/hard checks'
);

select pg_temp.q94_assert(
  (select array_agg(profile_id) = array[pg_temp.q94_id(2), pg_temp.q94_id(15)]
       and bool_and(location_applied)
   from public.zyra_discover_profile_ids(p_age_max => 40, p_location => 'near', p_distance_km => 5)),
  'Near uses actual kilometres and omits candidates without a home place'
);

select pg_temp.q94_assert(
  (select array_agg(profile_id) = array[pg_temp.q94_id(2), pg_temp.q94_id(15)]
       and bool_and(location_applied)
   from public.zyra_discover_profile_ids(p_age_max => 40, p_location => 'country')),
  'Country defaults to the caller home country'
);

select pg_temp.q94_assert(
  (select array_agg(profile_id) = array[pg_temp.q94_id(3)]
       and bool_and(location_applied)
   from public.zyra_discover_profile_ids(p_location => 'country', p_country => 'FR')),
  'explicit Country and stored home country match'
);

select pg_temp.q94_assert(
  (select array_agg(profile_id) = array[pg_temp.q94_id(3), pg_temp.q94_id(2)]
   from public.zyra_discover_profile_ids(p_age_max => 40, p_limit => 2))
  and (select array_agg(profile_id) = array[pg_temp.q94_id(15), pg_temp.q94_id(4)]
   from public.zyra_discover_profile_ids(p_age_max => 40, p_limit => 2, p_after => pg_temp.q94_id(2)))
  and (select array_agg(profile_id) = array[pg_temp.q94_id(13)]
   from public.zyra_discover_profile_ids(p_age_max => 40, p_limit => 2, p_after => pg_temp.q94_id(4))),
  'rank/UUID keyset has stable pages and no repeat across numeric and null scores'
);

select pg_temp.q94_assert(
  (select count(*) = 50 from public.zyra_discover_profile_ids(p_limit => 100))
  and not exists (select 1 from public.zyra_discover_profile_ids(p_after => pg_temp.q94_id(6))),
  'hard page cap and hidden cursor cannot access a different window'
);

select pg_temp.q94_assert(
  (select to_jsonb(row) =
     jsonb_build_object('profile_id', pg_temp.q94_id(3),
                        'one_filters_applied', false, 'location_applied', false)
   from public.zyra_discover_profile_ids(p_limit => 1) as row),
  'exact result shape carries only ID and two flags'
);

select pg_temp.q94_assert(
  not exists (select 1 from public.zyra_discover_profile_ids(p_age_min => 31, p_age_max => 59)),
  'inclusive age range only admits candidates within the range'
);

select pg_temp.q94_assert(
  public.zyra_set_profile_hidden(p_profile => pg_temp.q94_id(6), p_hidden => false)
    = jsonb_build_object('schema_version', 1, 'viewer_id', pg_temp.q94_id(1),
                         'profile_id', pg_temp.q94_id(6), 'hidden', false),
  'unhide acknowledges the caller-owned direction'
);
select pg_temp.q94_assert(
  public.zyra_my_hidden_profile_ids()->'profile_ids' = '[]'::jsonb
  and exists (select 1 from public.zyra_discover_profile_ids(p_age_max => 40) where profile_id = pg_temp.q94_id(6))
  and not exists (select 1 from public.zyra_discover_profile_ids(p_age_max => 40) where profile_id = pg_temp.q94_id(16)),
  'unhide restores only the outgoing candidate; incoming hide remains excluded'
);
select public.zyra_set_profile_hidden(p_profile => pg_temp.q94_id(6), p_hidden => true);
reset role;

update public.subscriptions set plan_type = 'seeker_premium'
where user_id = pg_temp.q94_id(1);
set local role authenticated;
select pg_temp.q94_as(1);
select pg_temp.q94_assert(
  (select array_agg(profile_id) = array[pg_temp.q94_id(3), pg_temp.q94_id(15)]
       and bool_and(one_filters_applied)
   from public.zyra_discover_profile_ids(p_nationalities => array['GB','FR'],
                                        p_ethnicities => array['white_other'])),
  'One applies multi-value lists with both chosen fields required'
);
reset role;

update public.subscriptions set plan_type = 'seeker_basic'
where user_id = pg_temp.q94_id(1);
delete from private.seeker_home_places where user_id = pg_temp.q94_id(1);
set local role authenticated;
select pg_temp.q94_as(1);
select pg_temp.q94_assert(
  (select array_agg(profile_id) =
    array[pg_temp.q94_id(3), pg_temp.q94_id(2), pg_temp.q94_id(15), pg_temp.q94_id(4), pg_temp.q94_id(13)]
    and bool_and(not one_filters_applied and not location_applied)
   from public.zyra_discover_profile_ids(
     p_age_max => 40, p_location => 'near', p_distance_km => 5,
     p_nationalities => array['FR'], p_ethnicities => array['white_other'])),
  'downgrade ignores saved selections and Near without caller home falls back to Worldwide'
);
select pg_temp.q94_as(10);
select pg_temp.q94_assert(
  not exists (select 1 from public.zyra_discover_profile_ids()), 'Guardian has no discovery'
);
select set_config('request.jwt.claims', '{}', true);
select pg_temp.q94_assert(
  not exists (select 1 from public.zyra_discover_profile_ids()), 'caller without a claim has no discovery'
);
reset role;

rollback;

-- Q95: owner-only sources, legacy rows and durable removal.
begin;
\ir fixtures/server0_v2_full_schema_prestate.sql

grant select on server0_v2_fixture_actors to authenticated, service_role;

create function pg_temp.q95_actor(p_label text) returns uuid
language sql stable as $$
  select id from server0_v2_fixture_actors where fixture_label = p_label;
$$;

create function pg_temp.q95_as(p_label text) returns void language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', pg_temp.q95_actor(p_label), 'role', 'authenticated')::text, true);
$$;

create function pg_temp.q95_photo(p_slot integer) returns uuid language sql immutable as $$
  select ('95000000-0000-4000-8000-' || lpad(p_slot::text, 12, '0'))::uuid;
$$;

create function pg_temp.q95_display(p_label text, p_slot integer) returns text language sql stable as $$
  select pg_temp.q95_actor(p_label)::text || '/display-' || p_slot::text || '.jpg';
$$;

create function pg_temp.q95_source(p_label text, p_slot integer) returns text language sql stable as $$
  select pg_temp.q95_actor(p_label)::text || '/' || pg_temp.q95_photo(p_slot)::text || '.jpg';
$$;

create function pg_temp.q95_assert(p_ok boolean, p_label text) returns void language plpgsql as $$
begin
  if p_ok is distinct from true then raise exception 'Q95 FAIL: %', p_label; end if;
  raise notice 'Q95 PASS: %', p_label;
end;
$$;

create function pg_temp.q95_refused(p_sql text, p_state text, p_message text default null)
returns void language plpgsql as $$
begin
  execute p_sql;
  raise exception 'Q95 expected refusal %', p_sql;
exception when others then
  if sqlstate <> p_state or (p_message is not null and sqlerrm <> p_message) then raise; end if;
end;
$$;

grant execute on function
  pg_temp.q95_actor(text), pg_temp.q95_as(text), pg_temp.q95_photo(integer),
  pg_temp.q95_display(text,integer), pg_temp.q95_source(text,integer),
  pg_temp.q95_assert(boolean,text), pg_temp.q95_refused(text,text,text)
  to authenticated, service_role;

select pg_temp.q95_assert(
  (select not public and file_size_limit = 8388608 and allowed_mime_types = array['image/jpeg']
   from storage.buckets where id = 'profile-photo-sources'),
  'private JPEG source bucket has the 8 MiB limit'
);
select pg_temp.q95_assert(
  not has_function_privilege('anon', 'public.zyra_my_photo_sources()', 'execute')
  and not has_function_privilege('authenticated', 'public.zyra_claim_photo_object_deletions()', 'execute')
  and not has_function_privilege('authenticated', 'public.zyra_finish_photo_object_deletion(text,text,integer,text)', 'execute')
  and not has_table_privilege('authenticated', 'public.photo_object_deletions', 'select'),
  'source RPC requires a member and cleanup is service-only'
);

set local role authenticated;
select pg_temp.q95_as('male1');
select set_config('storage.operation', 'storage.object.upload', true);

insert into storage.objects(bucket_id, name, owner_id)
select 'profile-photos', pg_temp.q95_display('male1', slot), auth.uid()::text
from generate_series(1, 4) slot;
insert into storage.objects(bucket_id, name, owner_id)
select 'profile-photo-sources', pg_temp.q95_source('male1', slot), auth.uid()::text
from generate_series(1, 4) slot;

select pg_temp.q95_refused($sql$
  insert into storage.objects(bucket_id, name, owner_id)
  values ('profile-photo-sources', pg_temp.q95_source('fem1', 6), auth.uid()::text)
$sql$, '42501');
select pg_temp.q95_refused($sql$
  insert into storage.objects(bucket_id, name, owner_id)
  values ('profile-photo-sources', auth.uid()::text || '/nested/abc.jpg', auth.uid()::text)
$sql$, '42501');

insert into public.profile_photos (user_id, storage_path, is_primary)
values (auth.uid(), pg_temp.q95_display('male1', 1), true);
select pg_temp.q95_assert(
  (select source_path is null and revision = 1 and crop is null
   from public.zyra_my_photo_sources()),
  'legacy display remains available with a null source'
);
select pg_temp.q95_refused($sql$
  update public.profile_photos set source_path = pg_temp.q95_source('male1', 1)
  where user_id = auth.uid()
$sql$, '42501');
select pg_temp.q95_refused($sql$
  select public.zyra_save_profile_photo(pg_temp.q95_photo(1), pg_temp.q95_display('male1', 1),
    pg_temp.q95_source('male1', 1), '{"x":0.9,"y":0,"w":0.2,"h":1}', 0, 0)
$sql$, '22023', 'invalid_crop');
select pg_temp.q95_assert(
  public.zyra_save_profile_photo(pg_temp.q95_photo(1), pg_temp.q95_display('male1', 1),
    pg_temp.q95_source('male1', 1), '{"x":0.1,"y":0,"w":0.5,"h":1}', 90, 0)
    = '{"revision":1}',
  'save adds a new source-backed photo at revision one'
);
select pg_temp.q95_assert(
  public.zyra_save_profile_photo(pg_temp.q95_photo(1), pg_temp.q95_display('male1', 2),
    pg_temp.q95_source('male1', 1), '{"x":0,"y":0,"w":0.6,"h":1}', 180, 1)
    = '{"revision":2}',
  'adjust atomically replaces the display and advances the revision'
);
select pg_temp.q95_refused($sql$
  select public.zyra_save_profile_photo(pg_temp.q95_photo(1), pg_temp.q95_display('male1', 3),
    pg_temp.q95_source('male1', 1), '{"x":0,"y":0,"w":0.5,"h":1}', 0, 1)
$sql$, '40001', 'stale');
select pg_temp.q95_refused($sql$
  select public.zyra_remove_profile_photo(pg_temp.q95_photo(1), 1)
$sql$, '40001', 'stale');

select set_config('storage.operation', 'storage.object.get_authenticated', true);
select pg_temp.q95_assert(
  exists (select 1 from public.zyra_my_photo_sources() where photo = pg_temp.q95_photo(1)
    and source_path = pg_temp.q95_source('male1', 1) and rotation = 180
    and crop = '{"x":0,"y":0,"w":0.6,"h":1}'::jsonb and revision = 2)
  and exists (select 1 from storage.objects where name = pg_temp.q95_source('male1', 1)),
  'the owner can retrieve the source and saved framing'
);
select set_config('storage.operation', 'storage.object.sign', true);
select pg_temp.q95_assert(
  not exists (select 1 from storage.objects where name = pg_temp.q95_source('male1', 1)),
  'source Storage cannot mint an anonymously usable signed URL'
);
select set_config('storage.operation', 'storage.object.delete', true);
with deleted as (
  delete from storage.objects where name = pg_temp.q95_source('male1', 1) returning id
)
select pg_temp.q95_assert(not exists (select 1 from deleted), 'a live source cannot be directly deleted');

select pg_temp.q95_as('fem1');
select set_config('storage.operation', 'storage.object.get_authenticated', true);
select pg_temp.q95_assert(
  exists (select 1 from public.profile_photos where storage_path = pg_temp.q95_display('male1', 2))
  and exists (select 1 from storage.objects where name = pg_temp.q95_display('male1', 2))
  and not exists (select 1 from public.zyra_my_photo_sources())
  and not exists (select 1 from storage.objects where name = pg_temp.q95_source('male1', 1)),
  'an eligible viewer sees the display but not the source, crop or lookup'
);
select pg_temp.q95_refused($sql$select crop from public.profile_photos$sql$, '42501');
select pg_temp.q95_refused($sql$select public.zyra_remove_profile_photo(pg_temp.q95_photo(1), 2)$sql$,
  '40001', 'stale');

select pg_temp.q95_as('male1');
select pg_temp.q95_assert(
  public.zyra_remove_profile_photo(pg_temp.q95_photo(1), 2) = '{"revision":3}',
  'paired remove advances the revision'
);
select pg_temp.q95_assert(
  not exists (select 1 from public.zyra_my_photo_sources() where photo = pg_temp.q95_photo(1)),
  'removed photo drops from the owner gallery'
);
select pg_temp.q95_as('fem1');
select pg_temp.q95_assert(
  not exists (select 1 from public.profile_photos where storage_path = pg_temp.q95_display('male1', 2))
  and not exists (select 1 from storage.objects where name = pg_temp.q95_display('male1', 2)),
  'viewer cannot read removed gallery metadata or display Storage'
);

reset role;
set local role service_role;
select pg_temp.q95_assert(
  (select count(*) = 3 from public.photo_object_deletions),
  'replacement and removal queue the previous display and both current objects'
);
create temp table q95_claims as select * from public.zyra_claim_photo_object_deletions();
select pg_temp.q95_assert(
  (select count(*) = 2 from q95_claims)
  and not exists (select 1 from q95_claims where path = pg_temp.q95_display('male1', 1))
  and not exists (select 1 from public.zyra_claim_photo_object_deletions()),
  'cleanup skips a still-referenced display and an active claim'
);
select public.zyra_finish_photo_object_deletion(bucket, path, attempts, null)
from q95_claims where bucket = 'profile-photos';
select public.zyra_finish_photo_object_deletion(bucket, path, attempts, 'test_retry')
from q95_claims where bucket = 'profile-photo-sources';
select pg_temp.q95_assert(
  (select done_at is not null and last_error is null from public.photo_object_deletions
   where path = pg_temp.q95_display('male1', 2))
  and (select done_at is null and last_error = 'test_retry' from public.photo_object_deletions
       where path = pg_temp.q95_source('male1', 1)),
  'worker records completion and preserves a recoverable failure'
);
do $retry$
declare
  v_claim record;
begin
  for i in 2..10 loop
    select * into strict v_claim from public.zyra_claim_photo_object_deletions();
    if v_claim.attempts <> i then raise exception 'unexpected attempt %', v_claim.attempts; end if;
    perform public.zyra_finish_photo_object_deletion(v_claim.bucket, v_claim.path, i, 'test_retry');
  end loop;
end
$retry$;
select pg_temp.q95_assert(
  not exists (select 1 from public.zyra_claim_photo_object_deletions())
  and exists (select 1 from public.photo_object_deletions
      where path = pg_temp.q95_source('male1', 1) and attempts = 10
      and done_at is null and last_error = 'test_retry'),
  'after ten attempts the failed object stays listed and is no longer retried'
);

reset role;
set local role authenticated;
select pg_temp.q95_as('male1');
select pg_temp.q95_refused($sql$
  insert into public.profile_photos (user_id, storage_path)
  values (auth.uid(), pg_temp.q95_display('male1', 2))
$sql$, '22023', 'photo_path_retired');
select set_config('storage.operation', 'storage.object.upload', true);
select pg_temp.q95_refused($sql$
  update storage.objects set name = name
  where bucket_id = 'profile-photos' and name = pg_temp.q95_display('male1', 2)
$sql$, '42501');

select public.zyra_save_profile_photo(pg_temp.q95_photo(3), pg_temp.q95_display('male1', 3),
  pg_temp.q95_source('male1', 3), '{"x":0,"y":0,"w":0.5,"h":1}', 0, 0);
delete from public.profile_photos where user_id = auth.uid();
select pg_temp.q95_assert(
  (public.zyra_set_profile_complete(true)->>'missing') = 'photos',
  'publication does not count a removed photo'
);
insert into public.profile_photos (user_id, storage_path, is_primary)
values (auth.uid(), pg_temp.q95_display('male1', 1), true);
select pg_temp.q95_assert(
  exists (select 1 from public.zyra_my_photo_sources()
    where display_path = pg_temp.q95_display('male1', 1) and source_path is null),
  'legacy delete-and-insert can reorder/re-add a display path'
);

select public.zyra_save_profile_photo(pg_temp.q95_photo(4), pg_temp.q95_display('male1', 4),
  pg_temp.q95_source('male1', 4), '{"x":0,"y":0,"w":0.5,"h":1}', 0, 0);
select pg_temp.q95_assert(
  (public.zyra_reset_profile()->>'status') = 'reset',
  'existing reset succeeds with both legacy and modern photos'
);
reset role;
select pg_temp.q95_assert(
  not exists (select 1 from public.profile_photos where user_id = pg_temp.q95_actor('male1'))
  and (select count(*) = 4 from public.photo_object_deletions
       where path in (pg_temp.q95_display('male1', 1), pg_temp.q95_display('male1', 4),
                      pg_temp.q95_source('male1', 3), pg_temp.q95_source('male1', 4)))
  and (select count(*) = 4 from storage.objects
       where name in (pg_temp.q95_display('male1', 1), pg_temp.q95_display('male1', 4),
                      pg_temp.q95_source('male1', 3), pg_temp.q95_source('male1', 4))),
  'reset queues legacy and modern paths and leaves physical deletion to Storage cleanup'
);

set local role authenticated;
select pg_temp.q95_as('fem1');
insert into storage.objects(bucket_id, name, owner_id)
values ('profile-photos', pg_temp.q95_display('fem1', 5), auth.uid()::text),
       ('profile-photos', pg_temp.q95_display('fem1', 6), auth.uid()::text),
       ('profile-photo-sources', pg_temp.q95_source('fem1', 6), auth.uid()::text);
insert into public.profile_photos (user_id, storage_path, is_primary)
values (auth.uid(), pg_temp.q95_display('fem1', 5), true);
select public.zyra_save_profile_photo(pg_temp.q95_photo(6), pg_temp.q95_display('fem1', 6),
  pg_temp.q95_source('fem1', 6), '{"x":0,"y":0,"w":0.5,"h":1}', 270, 0);
select public.delete_own_account();
reset role;
select pg_temp.q95_assert(
  not exists (select 1 from auth.users where id = pg_temp.q95_actor('fem1'))
  and not exists (select 1 from public.profile_photos where user_id = pg_temp.q95_actor('fem1'))
  and (select count(*) = 3 from public.photo_object_deletions
       where path in (pg_temp.q95_display('fem1', 5), pg_temp.q95_display('fem1', 6),
                      pg_temp.q95_source('fem1', 6)))
  and (select count(*) = 3 from storage.objects
       where name in (pg_temp.q95_display('fem1', 5), pg_temp.q95_display('fem1', 6),
                      pg_temp.q95_source('fem1', 6))),
  'account deletion queues legacy and modern paths before the Auth cascade'
);
rollback;
