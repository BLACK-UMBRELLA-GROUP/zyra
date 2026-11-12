-- Q109/Q111/Q113 synthetic owner, canonical item and scoring premises.
begin;
\ir fixtures/server0_v2_full_schema_prestate.sql

create function pg_temp.q109_actor(p_label text) returns uuid
language sql stable as $$
  select id from server0_v2_fixture_actors where fixture_label = p_label;
$$;

create function pg_temp.q109_assert(p_ok boolean, p_check text) returns void
language plpgsql as $$
begin
  if p_ok is distinct from true then raise exception 'Q109 FAIL: %', p_check; end if;
  raise notice 'Q109 PASS: %', p_check;
end;
$$;

create function pg_temp.q109_score()
returns table (capture_version text, inputs_hash text, overall numeric, area_bands jsonb, state text)
language sql stable as $$
  select * from public.zyra_score_direction_v1(pg_temp.q109_actor('male1'), pg_temp.q109_actor('fem1'));
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
where p.id = o.user_id and p.id in (pg_temp.q109_actor('male1'), pg_temp.q109_actor('fem1'));

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
where user_id in (pg_temp.q109_actor('male1'), pg_temp.q109_actor('fem1'));


grant select on server0_v2_fixture_actors to authenticated;
grant execute on function pg_temp.q109_actor(text), pg_temp.q109_assert(boolean,text) to authenticated;
create function pg_temp.q109_as(label text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object(
    'sub', pg_temp.q109_actor(label), 'role', 'authenticated')::text, true);
$$;
create function pg_temp.q109_refused(payload jsonb, expected_state text, expected_error text)
returns void language plpgsql as $$
begin
  perform public.zyra_confirm_preference_lights(payload);
  raise exception 'Q109 FAIL: invalid writer admission';
exception when others then
  if sqlstate <> expected_state or sqlerrm <> expected_error then raise; end if;
end;
$$;
grant execute on function pg_temp.q109_as(text), pg_temp.q109_refused(jsonb,text,text) to authenticated;

select pg_temp.q109_assert(
  not has_function_privilege('anon', 'public.zyra_my_lights_needed_for_compatibility()', 'execute')
  and has_function_privilege('authenticated', 'public.zyra_my_lights_needed_for_compatibility()', 'execute')
  and not has_function_privilege('authenticated', 'private.zyra_preference_lights_to_check(boolean)', 'execute')
  and not has_table_privilege('authenticated', 'public.preference_light_confirmations', 'INSERT'),
  'reader RPC and receipts retain the caller-only boundary');

update public.onboarding_answers
set ch3_answers = jsonb_set(ch3_answers - 'ch3_q24', '{ch3_q3}', '"No"'),
    ch4_preferences = jsonb_set(jsonb_set(jsonb_set(ch4_preferences,
      '{ch3_q24,As soon as possible}', '"yellow"'),
      array['ch3_q26', (select options ->> 0 from public.zyra_onboarding_questions
        where qid = 'ch3_q26' and gender_visibility = 'womenOnly')], '"amber"'),
      '{ch3_q39}', jsonb_build_object((select options ->> 0 from public.zyra_onboarding_questions
        where qid = 'ch3_q39' and gender_visibility = 'menOnly'), 'yellow'))
where user_id = pg_temp.q109_actor('male1');
update public.seeker_details set preferences = preferences || '{
  "sect":{"matrix":{"sunni":"yellow","shia":"red","other":"red"},
          "outside_flexibility":"yellow","hard_requirement":["shia","other"]},
  "revert":{"flexibility":"yellow"},
  "location":{"flexibility":"yellow"},
  "nationality":{"preferred":["GB"],"skipped":false,"flexibility":"yellow"},
  "languages":{"preferred":["en"],"skipped":false,"flexibility":"yellow"}
}'::jsonb where user_id = pg_temp.q109_actor('male1');

set local role authenticated;
select pg_temp.q109_as('male1');
select pg_temp.q109_assert(
  (select count(*) = 4 and bool_and(light = 'amber') from public.zyra_my_lights_needing_reconfirmation())
  and (select array_agg(question_id order by question_id) from public.zyra_my_lights_needing_reconfirmation()) =
    array['ch2.revert.flexibility','ch2.sect.matrix','ch2.sect.outside_flexibility','ch3_q26']
  and exists (select 1 from public.zyra_my_lights_needing_reconfirmation()
    where question_id = 'ch2.sect.matrix' and option_value = 'sunni')
  and (select count(*) = 2 and bool_and(option_value = '*')
    from public.zyra_my_lights_needing_reconfirmation() where question_id <> 'ch2.sect.matrix' and question_id like 'ch2.%'),
  'visible reader uses canonical setup IDs and the counterpart q26 variant');
select pg_temp.q109_assert(
  (select array_agg(question_id order by question_id) from public.zyra_my_lights_needed_for_compatibility()) =
    array['ch2.nationality.flexibility','ch3_q24']
  and (select bool_and(light = 'amber' and reason = 'hidden_but_applicable')
    from public.zyra_my_lights_needed_for_compatibility()),
  'hidden reader returns only potentially applicable owner lights, omitting location, English only and own-gender controls');
select pg_temp.q109_as('fem1');
select pg_temp.q109_assert(
  not exists (select 1 from public.zyra_my_lights_needing_reconfirmation())
  and not exists (select 1 from public.zyra_my_lights_needed_for_compatibility()),
  'a different account sees none of the first owner items');
select pg_temp.q109_as('male1');
select pg_temp.q109_refused('[{"question_id":"ch2.sect.outside_flexibility","option_value":"*","light":"amber"}]',
  '42501', 'consent_required');
select pg_temp.q109_assert(
  not exists (select 1 from public.preference_light_confirmations)
  and not exists (select 1 from public.consents where user_id = auth.uid()),
  'absence of recorded consent refuses the call without writing');
reset role;
insert into public.consents(user_id, consent_type, granted, policy_version, recorded_at)
values (pg_temp.q109_actor('male1'), 'article9_special_category', true, 'test', '2026-01-01 00:00:00+00'),
       (pg_temp.q109_actor('male1'), 'article9_special_category', false, 'test', '2026-01-02 00:00:00+00');
set local role authenticated;
select pg_temp.q109_as('male1');
select pg_temp.q109_refused('[{"question_id":"ch2.sect.outside_flexibility","option_value":"*","light":"amber"}]',
  '42501', 'consent_required');
select pg_temp.q109_assert((select count(*) = 2 from public.consents where user_id = auth.uid())
  and not exists (select 1 from public.preference_light_confirmations),
  'newest withdrawal blocks an otherwise admitted item without changing the consent log');
reset role;
insert into public.consents(user_id, consent_type, granted, policy_version, recorded_at)
values (pg_temp.q109_actor('male1'), 'article9_special_category', true, 'test', '2026-01-03 00:00:00+00');
set local role authenticated;
select pg_temp.q109_as('male1');
select pg_temp.q109_refused('[{"question_id":"ch2.unknown.flexibility","option_value":"*","light":"amber"}]',
  '22023', 'invalid_preference_lights');
select pg_temp.q109_refused('[{"question_id":"ch2.sect.outside_flexibility","option_value":"*","light":"yellow"}]',
  '22023', 'invalid_preference_lights');
select pg_temp.q109_refused(jsonb_build_array(jsonb_build_object('question_id','ch2.sect.outside_flexibility',
  'option_value','*','light','amber','user_id',pg_temp.q109_actor('fem1'))),
  '22023', 'invalid_preference_lights');
select pg_temp.q109_refused('[{"question_id":"ch2.sect.outside_flexibility","option_value":"flexibility","light":"amber"}]',
  '22023', 'invalid_preference_lights');
select pg_temp.q109_refused(jsonb_build_array(jsonb_build_object('question_id','ch3_q39',
  'option_value',(select jsonb_object_keys(ch4_preferences -> 'ch3_q39')
    from public.onboarding_answers where user_id = auth.uid()),'light','green')),
  '22023', 'invalid_preference_lights');
select pg_temp.q109_refused('[{"question_id":"ch2.sect.outside_flexibility","option_value":"*","light":"green"},
  {"question_id":"unknown","option_value":"*","light":"amber"}]', '22023', 'invalid_preference_lights');
select pg_temp.q109_assert(not exists (select 1 from public.preference_light_confirmations)
  and (select preferences #>> '{sect,outside_flexibility}' = 'yellow'
    from public.seeker_details where user_id = auth.uid()),
  'unknown, wrong-key, invalid light, other-owner, wrong variant and mixed batch are refused atomically');

select public.zyra_confirm_preference_lights((
  select jsonb_agg(case when item.question_id = 'ch3_q26'
    then to_jsonb(item) || '{"light":"green"}'::jsonb else to_jsonb(item) end)
  from public.zyra_my_lights_needing_reconfirmation() item
));
select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch2.nationality.flexibility","option_value":"*","light":"red"}]');
select pg_temp.q109_assert(
  (select count(*) = 5 and bool_and(user_id = auth.uid() and capture_version = 'v1')
    from public.preference_light_confirmations)
  and exists (select 1 from public.preference_light_confirmations
    where question_id = 'ch2.sect.outside_flexibility' and option_value = '*' and light = 'amber')
  and exists (select 1 from public.preference_light_confirmations where question_id = 'ch3_q26' and light = 'green')
  and exists (select 1 from public.preference_light_confirmations where question_id = 'ch2.nationality.flexibility' and light = 'red')
  and (select preferences #>> '{sect,outside_flexibility}' = 'amber'
    and preferences #>> '{revert,flexibility}' = 'amber'
    and preferences #>> '{sect,matrix,sunni}' = 'amber'
    and preferences #> '{sect,hard_requirement}' = '["shia","other"]'::jsonb
    from public.seeker_details where user_id = auth.uid())
  and not exists (select 1 from public.zyra_my_lights_needing_reconfirmation())
  and (select count(*) = 1 and bool_and(question_id = 'ch3_q24') from public.zyra_my_lights_needed_for_compatibility()),
  'legacy Amber may stay Amber or become Green or Red with exact canonical receipts');
reset role;

select pg_temp.q109_assert(
  (select state = 'needs_reconfirmation' and overall is null from pg_temp.q109_score()),
  'the same hidden q24 is still required when the subject answers it');
update public.onboarding_answers
set ch3_answers = jsonb_set(ch3_answers - 'ch3_q24', '{ch3_q3}', '"No"')
where user_id = pg_temp.q109_actor('fem1');
update public.seeker_details set revert_status = true where user_id = pg_temp.q109_actor('fem1');
select pg_temp.q109_assert(
  (select state = 'ok' and overall is not null from pg_temp.q109_score())
  and private.zyra_compatibility_light('"amber"',pg_temp.q109_actor('male1'),'revert','flexibility') = 0.5,
  'a subject whose q3 is No skips q24 and canonical revert Amber retains its D1 half point');

update public.seeker_details set sect = 'shia' where user_id = pg_temp.q109_actor('fem1');
set local role authenticated;
select pg_temp.q109_as('fem1');
select set_config('storage.operation', 'storage.object.upload', true);
insert into storage.objects(bucket_id, name, owner_id)
values ('profile-photos', auth.uid()::text || '/q109-discovery.jpg', auth.uid()::text);
insert into public.profile_photos(user_id, storage_path, is_primary)
values (auth.uid(), auth.uid()::text || '/q109-discovery.jpg', true);
select pg_temp.q109_as('male1');
select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch3_q24","option_value":"As soon as possible","light":"amber"}]');
select pg_temp.q109_refused('[{"question_id":"ch3_q24","option_value":"As soon as possible","light":"green"}]',
  '22023', 'invalid_preference_lights');
select pg_temp.q109_assert(not exists (select 1 from public.zyra_my_lights_needed_for_compatibility())
  and exists (select 1 from public.preference_light_confirmations
    where question_id = 'ch3_q24' and light = 'amber'),
  'hidden q24 is writable only while the separate reader admits that affected option');
select pg_temp.q109_assert(not exists (select 1 from public.zyra_discover_profile_ids()
  where profile_id = pg_temp.q109_actor('fem1')), 'an eligible Shia profile is hidden by a live Red exclusion');
select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch2.sect.matrix","option_value":"shia","light":"red"}]');
select pg_temp.q109_assert((select preferences #> '{sect,hard_requirement}' = '["shia","other"]'::jsonb
  from public.seeker_details where user_id = auth.uid())
  and exists (select 1 from public.preference_light_confirmations
    where question_id = 'ch2.sect.matrix' and option_value = 'shia' and light = 'red'),
  'Red to Red confirms without removing either existing exclusion');
select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch2.sect.matrix","option_value":"shia","light":"amber"}]');
select pg_temp.q109_assert((select preferences #> '{sect,hard_requirement}' = '["other"]'::jsonb
  from public.seeker_details where user_id = auth.uid())
  and exists (select 1 from public.preference_light_confirmations
    where question_id = 'ch2.sect.matrix' and option_value = 'shia' and light = 'amber'),
  'Red to Amber confirms and removes only its own exclusion');
select pg_temp.q109_assert(exists (select 1 from public.zyra_discover_profile_ids()
  where profile_id = pg_temp.q109_actor('fem1')), 'the Shia profile becomes discoverable immediately when the live exclusion is removed');
update public.seeker_details set preferences = jsonb_set(preferences, '{sect,hard_requirement}', '["sunni","shia","other"]')
where user_id = auth.uid();
select pg_temp.q109_assert((select preferences #> '{sect,hard_requirement}' = '["other"]'::jsonb
  from public.seeker_details where user_id = auth.uid()), 'direct JSON cannot add a hard requirement to a non-Red sect');
update public.onboarding_answers set
  ch4_preferences = jsonb_set(jsonb_set(ch4_preferences, '{ch3_q1,Never Married}', '"red"'), '{ch3_q1,Separated}', '"red"'),
  ch4_hard_requirements = '{"ch3_q1":["Never Married","Separated"]}'
where user_id = auth.uid();
select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch3_q1","option_value":"Separated","light":"green"}]');
select pg_temp.q109_assert((select ch4_hard_requirements -> 'ch3_q1' = '["Never Married"]'::jsonb
  from public.onboarding_answers where user_id = auth.uid())
  and exists (select 1 from public.preference_light_confirmations
    where question_id = 'ch3_q1' and option_value = 'Separated' and light = 'green'),
  'Red to Green confirms and Chapter 4 removes only the selected exclusion');
do $invalid_exclusions$
declare
  invalid jsonb;
begin
  foreach invalid in array array['true'::jsonb, '["other",true]'::jsonb] loop
    begin
      update public.seeker_details set preferences =
        jsonb_set(preferences, '{sect,hard_requirement}', invalid)
      where user_id = auth.uid();
      raise exception 'Q109 FAIL: malformed sect exclusions were accepted';
    exception when check_violation or invalid_parameter_value then null;
    end;
  end loop;
  foreach invalid in array array['{"ch3_q1":true}'::jsonb, '{"ch3_q1":["Never Married",true]}'::jsonb] loop
    begin
      update public.onboarding_answers set ch4_hard_requirements = invalid where user_id = auth.uid();
      raise exception 'Q109 FAIL: malformed Chapter 4 exclusions were accepted';
    exception when check_violation or invalid_parameter_value then null;
    end;
  end loop;
end;
$invalid_exclusions$;
select pg_temp.q109_assert(
  (select preferences #> '{sect,hard_requirement}' = '["other"]'
    from public.seeker_details where user_id = auth.uid())
  and (select ch4_hard_requirements -> 'ch3_q1' = '["Never Married"]'
    from public.onboarding_answers where user_id = auth.uid()),
  'legacy boolean and mixed hard requirement payloads are rejected without changing stored exclusions');
select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch3_q1","option_value":"Separated","light":"amber"}]');
select pg_temp.q109_assert(exists (select 1 from public.preference_light_confirmations
  where question_id = 'ch3_q1' and option_value = 'Separated' and light = 'amber'),
  'Green to Amber confirms without adding a hard requirement');
select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch3_q1","option_value":"Separated","light":"red"}]');
select pg_temp.q109_assert((select ch4_hard_requirements -> 'ch3_q1' = '["Never Married"]'::jsonb
  from public.onboarding_answers where user_id = auth.uid()), 'confirming Red does not add an exclusion');
update public.onboarding_answers set ch4_preferences = ch4_preferences #- '{ch3_q1,Separated}'
where user_id = auth.uid();
update public.seeker_details set preferences = preferences - 'location' where user_id = auth.uid();
select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch3_q1","option_value":"Separated","light":"green"},
    {"question_id":"ch2.location.flexibility","option_value":"*","light":"green"}]');
select pg_temp.q109_assert((select count(*) = 2 and bool_and(light = 'green' and capture_version = 'v1')
  from public.preference_light_confirmations where (question_id,option_value) in
    (('ch3_q1','Separated'),('ch2.location.flexibility','*'))),
  'fresh displayed and setup controls record v1 immediately');
reset role;
update public.preference_light_confirmations set confirmed_at = '2026-01-01 00:00:00+00'
where user_id = pg_temp.q109_actor('male1') and question_id = 'ch3_q1' and option_value = 'Separated';
set local role authenticated;
select pg_temp.q109_as('male1');
select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch3_q1","option_value":"Separated","light":"green"}]');
select pg_temp.q109_assert((select confirmed_at > '2026-01-01 00:00:00+00'
  from public.preference_light_confirmations where question_id = 'ch3_q1' and option_value = 'Separated'),
  'same-value Green re-save refreshes confirmed_at');
select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch3_q1","option_value":"Separated","light":"red"}]');
select pg_temp.q109_assert((select ch4_preferences #>> '{ch3_q1,Separated}' = 'red'
  and ch4_hard_requirements -> 'ch3_q1' = '["Never Married"]'::jsonb
  from public.onboarding_answers where user_id = auth.uid())
  and exists (select 1 from public.preference_light_confirmations
    where question_id = 'ch3_q1' and option_value = 'Separated' and light = 'red' and capture_version = 'v1'),
  'Green to Red confirms without adding a hard requirement');
update public.seeker_details set preferences = jsonb_set(preferences, '{sect,outside_flexibility}', '"green"')
where user_id = auth.uid();
select pg_temp.q109_assert(not exists (select 1 from public.preference_light_confirmations
  where question_id = 'ch2.sect.outside_flexibility'), 'ordinary JSON update invalidates the canonical receipt');
reset role;
-- Return to the earlier scorable pair after the hard-exclusion checks.
update public.onboarding_answers set ch4_hard_requirements = '{}'
where user_id = pg_temp.q109_actor('male1');
update public.seeker_details set sect = 'sunni' where user_id = pg_temp.q109_actor('fem1');
delete from public.preference_light_confirmations
where user_id = pg_temp.q109_actor('male1') and
  ((question_id = 'ch2.sect.matrix' and option_value = 'sunni') or question_id = 'ch2.revert.flexibility');
insert into public.preference_light_confirmations(user_id, question_id, option_value, light, confirmed_at)
values (pg_temp.q109_actor('male1'), 'sect', 'sunni', 'amber', '2026-01-01 00:00:00+00'),
       (pg_temp.q109_actor('male1'), 'revert', 'flexibility', 'amber', '2026-01-01 00:00:00+00');
select pg_temp.q109_assert(private.zyra_compatibility_light('"amber"',pg_temp.q109_actor('male1'),'sect','sunni') = 0.5,
  'an existing Q105 sect receipt still scores its exact same Amber');
create temp table q109_before_legacy_resave as select inputs_hash from pg_temp.q109_score() where state = 'ok';
set local role authenticated;
select pg_temp.q109_as('male1');
select pg_temp.q109_assert(not exists (select 1 from public.zyra_my_lights_needing_reconfirmation()
  where question_id = 'ch2.sect.matrix' and option_value = 'sunni'), 'a historic matching receipt does not reappear under the canonical key');
select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch2.sect.matrix","option_value":"sunni","light":"amber"},
    {"question_id":"ch2.revert.flexibility","option_value":"*","light":"amber"}]');
select pg_temp.q109_assert(
  (select count(*) = 2 and bool_and(confirmed_at > '2026-01-01 00:00:00+00')
    from public.preference_light_confirmations where question_id in ('sect','revert'))
  and not exists (select 1 from public.preference_light_confirmations
    where (question_id, option_value) in (('ch2.sect.matrix','sunni'),('ch2.revert.flexibility','*'))),
  'same-value canonical resave refreshes legacy receipts without duplicating them');
reset role;
select pg_temp.q109_assert(
  (select state = 'ok' and inputs_hash = (select inputs_hash from q109_before_legacy_resave)
    from pg_temp.q109_score()),
  'legacy same-value resave preserves the score inputs hash');
set local role authenticated;
select pg_temp.q109_as('male1');
select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch2.revert.flexibility","option_value":"*","light":"green"}]');
select pg_temp.q109_assert(
  not exists (select 1 from public.preference_light_confirmations where question_id = 'revert')
  and exists (select 1 from public.preference_light_confirmations
    where question_id = 'ch2.revert.flexibility' and option_value = '*' and light = 'green'),
  'a changed legacy light records the canonical receipt and invalidates the old alias');
reset role;
rollback;
