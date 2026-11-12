-- Q116 / OA-ZYRA-193 / DR-ZYRA-250. Run only after the isolated full replay.
begin;
\ir fixtures/server0_v2_full_schema_prestate.sql

create function pg_temp.q116_actor(p_label text) returns uuid
language sql stable as $$
  select id from server0_v2_fixture_actors where fixture_label = p_label;
$$;

create function pg_temp.q116_as(p_label text) returns void language sql as $$
  select set_config('request.jwt.claims', json_build_object(
    'sub', pg_temp.q116_actor(p_label), 'role', 'authenticated')::text, true);
$$;

create function pg_temp.q116_assert(p_ok boolean, p_label text) returns void
language plpgsql as $$
begin
  if p_ok is distinct from true then raise exception 'Q116 FAIL: %', p_label; end if;
  raise notice 'Q116 PASS: %', p_label;
end;
$$;

create function pg_temp.q116_score(p_subject text)
returns table(capture_version text, inputs_hash text, overall numeric, area_bands jsonb, state text)
language sql as $$
  select * from public.zyra_score_direction_v1(pg_temp.q116_actor('male1'), pg_temp.q116_actor(p_subject));
$$;

create function pg_temp.q116_refuse_retired() returns void language plpgsql as $$
begin
  perform public.zyra_confirm_preference_lights(
    '[{"question_id":"ch2.sect.matrix","option_value":"retired-fellowship","light":"amber"}]');
  raise exception 'Q116 FAIL: writer accepted a retired key';
exception when invalid_parameter_value then
  if sqlerrm <> 'invalid_preference_lights' then raise; end if;
end;
$$;

create function pg_temp.q116_topics(p_subject text)
returns table(overall numeric, topics_locked boolean, area_no smallint, area_code text, band text, state text)
language sql as $$
  select * from public.zyra_compatibility_topics(pg_temp.q116_actor(p_subject));
$$;

create function pg_temp.q116_assert_profile_state(p_subject text, p_state text, p_label text)
returns void language sql as $$
  select pg_temp.q116_assert(count(*) = 12 and bool_and(state = p_state and not topics_locked
    and overall is null and band is null), p_label)
  from pg_temp.q116_topics(p_subject);
$$;

grant select on server0_v2_fixture_actors to authenticated;
grant execute on function pg_temp.q116_actor(text), pg_temp.q116_as(text),
  pg_temp.q116_assert(boolean,text), pg_temp.q116_refuse_retired(), pg_temp.q116_topics(text),
  pg_temp.q116_assert_profile_state(text,text,text) to authenticated;

-- Use the actual per-gender vocabularies and counterpart preference banks.
update public.onboarding_answers o
set ch3_answers = (
  select jsonb_object_agg(q.qid, case when q.is_multi
    then jsonb_build_array(q.options -> 0) else q.options -> 0 end)
  from public.zyra_onboarding_questions q
  where q.gender_visibility in ('all', case p.gender when 'male' then 'menOnly' else 'womenOnly' end)
),
ch4_preferences = (
  select jsonb_object_agg(q.qid, (
    select jsonb_object_agg(opt, 'green'::text) from jsonb_array_elements_text(q.options) opt
  ) order by q.gender_visibility = case p.gender when 'male' then 'womenOnly' else 'menOnly' end)
  from public.zyra_onboarding_questions q
  where q.ch4_scored
),
ch4_hard_requirements = '{}'::jsonb
from public.profiles p
where p.id = o.user_id;

update public.onboarding_answers
set ch3_answers = jsonb_set(ch3_answers - 'ch3_q24', '{ch3_q3}', '"No"');
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
    }', capture_version = 'v0';

create temporary table q116_baseline as select * from pg_temp.q116_score('fem1');
select pg_temp.q116_assert((select state = 'ok' and overall is not null from q116_baseline),
  'valid real-bank baseline produces a score');

-- Direct helper coverage for display truncation and the older sentinel. The
-- full-bank tests below separately exercise typed unavailable and its audit.
select pg_temp.q116_assert(
  private.zyra_current_sect_third_key(repeat('a', 60) || '-full-slot', repeat('a', 60)) =
    repeat('a', 60) || '-full-slot',
  'a capped ASCII display label cannot replace the full canonical matrix key');
select pg_temp.q116_assert(
  private.zyra_current_sect_third_key(
    repeat('a', 50) || '-full-slot', repeat('a', 50) || repeat(U&'\+01F642', 5)) =
    repeat('a', 50) || '-full-slot'
  and private.zyra_current_sect_third_key('full-slot', repeat(U&'\+01F642', 30)) = 'full-slot',
  'count the UTF-16 cap with supplementary characters, including an all-non-ASCII prefix');
select pg_temp.q116_assert(
  private.zyra_current_sect_third_key('other', 'Legacy Fellowship') = 'legacy-fellowship'
  and private.zyra_current_sect_third_key('other', null) = 'other'
  and private.zyra_current_sect_third_key('other', 'Sunni') is null
  and private.zyra_current_sect_third_key('current-fellowship', 'Different Own Words') is null
  and private.zyra_current_sect_third_key('Invalid Code', 'Invalid Code') is null,
  'retain legacy Other recovery and refuse malformed or contradictory current keys');

-- Seed historical storage without applying the new ordinary-write policy.
alter table public.seeker_details disable trigger zyra_keep_red_ch2_hard_requirements;
update public.seeker_details
set preferences = jsonb_set(preferences, '{sect,matrix,retired-fellowship}', '"yellow"')
where user_id = pg_temp.q116_actor('male1');
alter table public.seeker_details enable trigger zyra_keep_red_ch2_hard_requirements;
select pg_temp.q116_assert(
  (select s.state = 'ok' and s.overall = b.overall and s.inputs_hash = b.inputs_hash
   from pg_temp.q116_score('fem1') s cross join q116_baseline b),
  'unrelated retained Amber leaves the score and hash unchanged');

update public.seeker_details set sect = 'retired-fellowship', sect_other = 'Retired Fellowship'
where user_id = pg_temp.q116_actor('fem1');
update public.seeker_details set sect = 'shia' where user_id = pg_temp.q116_actor('fem4');
create temporary table q116_custom_green as select * from pg_temp.q116_score('fem1');
update public.seeker_details set sect = 'different-fellowship', sect_other = 'Different Fellowship'
where user_id = pg_temp.q116_actor('fem1');
select pg_temp.q116_assert(
  (select a.state = 'ok' and b.state = 'ok' and a.overall = b.overall and a.inputs_hash = b.inputs_hash
   from pg_temp.q116_score('fem1') a cross join q116_custom_green b),
  'exact retired and unrelated counterpart custom codes have identical scoring inputs');

update public.seeker_details set sect = 'other', sect_other = null
where user_id = pg_temp.q116_actor('fem1');
select pg_temp.q116_assert(
  (select s.state = 'ok' and s.inputs_hash = b.inputs_hash
   from pg_temp.q116_score('fem1') s cross join q116_custom_green b),
  'the generic Other counterpart uses the same third key');
update public.seeker_details set sect = 'retired-fellowship', sect_other = 'Retired Fellowship'
where user_id = pg_temp.q116_actor('fem1');
update public.seeker_details set sect = 'other', sect_other = null
where user_id = pg_temp.q116_actor('fem2');

alter table public.seeker_details disable trigger zyra_keep_red_ch2_hard_requirements;
update public.seeker_details
set sect = 'current-fellowship', sect_other = 'Current Fellowship',
    preferences = jsonb_set(preferences, '{sect}', '{
      "matrix":{"sunni":"green","shia":"green","current-fellowship":"red",
                "retired-fellowship":"red","unknown-legacy":"unexpected","other":"yellow"},
      "hard_requirement":["retired-fellowship"]
    }'::jsonb)
where user_id = pg_temp.q116_actor('male1');
alter table public.seeker_details enable trigger zyra_keep_red_ch2_hard_requirements;
select pg_temp.q116_assert(
  (select s.state = 'ok' and t.state = 'ok' and s.overall = t.overall and s.overall < b.overall
   from pg_temp.q116_score('fem1') s cross join pg_temp.q116_score('fem2') t
   cross join q116_custom_green b),
  'current custom Red applies to all Other counterparts and retired hard and malformed lights do not apply');
select pg_temp.q116_assert(
  (select s.state = 'ok' and h.state = 'ok' and s.overall = b.overall and h.overall = b.overall
   from pg_temp.q116_score('fem3') s cross join pg_temp.q116_score('fem4') h cross join q116_baseline b),
  'Sunni and Shia use their own lights');

insert into public.consents(user_id, consent_type, granted, policy_version, recorded_at)
values (pg_temp.q116_actor('male1'), 'article9_special_category', true, 'test', now());
set local role authenticated;
select pg_temp.q116_as('male1');
select pg_temp.q116_assert(
  not exists (select from public.zyra_my_lights_needing_reconfirmation(p_include_missing => true))
  and not exists (select from public.zyra_my_lights_needed_for_compatibility()),
  'neither owner list exposes retired keys after the third light is set');
select pg_temp.q116_refuse_retired();
select pg_temp.q116_assert(
  not exists (select from public.preference_light_confirmations where option_value = 'retired-fellowship'),
  'the refused retired write creates no receipt');
select pg_temp.q116_assert(
  (select count(*) = 2 and count(distinct score) = 1 from public.score_candidates(
    array[pg_temp.q116_actor('fem1'),pg_temp.q116_actor('fem2')])),
  'discovery keeps both Other counterparts and applies the same current light');
reset role;

update public.seeker_details
set preferences = jsonb_set(preferences, '{sect,hard_requirement}',
    '["retired-fellowship","current-fellowship"]')
where user_id = pg_temp.q116_actor('male1');
-- Simulate historical retired hard flags that predate the Red-only trigger.
-- Keep every normal trigger and constraint active for the tested write.
alter table public.seeker_details disable trigger zyra_keep_red_ch2_hard_requirements;
update public.seeker_details
set preferences = jsonb_set(preferences, '{sect,hard_requirement}',
    '["retired-fellowship","other","orphan-hard-key","current-fellowship"]')
where user_id = pg_temp.q116_actor('male1');
alter table public.seeker_details enable trigger zyra_keep_red_ch2_hard_requirements;
select pg_temp.q116_assert(
  (select s.state = 'invalid' and t.state = 'invalid' and u.state = 'ok' and h.state = 'ok'
   from pg_temp.q116_score('fem1') s cross join pg_temp.q116_score('fem2') t
   cross join pg_temp.q116_score('fem3') u cross join pg_temp.q116_score('fem4') h),
  'the current third hard requirement applies to Other and leaves Sunni and Shia eligible');
set local role authenticated;
select pg_temp.q116_as('male1');
select pg_temp.q116_assert(
  (select count(*) = 2 and bool_and(candidate_id in (pg_temp.q116_actor('fem3'),pg_temp.q116_actor('fem4')))
   from public.score_candidates(
    array[pg_temp.q116_actor('fem1'),pg_temp.q116_actor('fem2'),
          pg_temp.q116_actor('fem3'),pg_temp.q116_actor('fem4')])),
  'discovery excludes all Other counterparts only when the current hard requirement applies');
select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch2.sect.matrix","option_value":"current-fellowship","light":"green"}]');
reset role;
select pg_temp.q116_assert(
  (select preferences #> '{sect,hard_requirement}' =
       '["retired-fellowship","other","orphan-hard-key"]'::jsonb
     and preferences #>> '{sect,matrix,retired-fellowship}' = 'red'
     and preferences #>> '{sect,matrix,unknown-legacy}' = 'unexpected'
     and preferences #>> '{sect,matrix,other}' = 'yellow'
   from public.seeker_details where user_id = pg_temp.q116_actor('male1')),
  'editing the current light clears its own hard flag and preserves retired lights and exclusion');

-- A normal setup save can replace the whole section payload. Preserve each
-- previously retired entry and discard attempts to add new retired entries.
set local role authenticated;
select pg_temp.q116_as('male1');
update public.seeker_details
set preferences = jsonb_set(preferences, '{sect}', '{
  "matrix":{"sunni":"green","shia":"red","current-fellowship":"green",
            "retired-fellowship":"green","attempted-legacy":"red"},
  "hard_requirement":["attempted-legacy","shia"]
}'::jsonb)
where user_id = auth.uid();
reset role;
select pg_temp.q116_assert(
  (select preferences #> '{sect,matrix}' =
     '{"sunni":"green","shia":"red","current-fellowship":"green",
       "retired-fellowship":"red","unknown-legacy":"unexpected","other":"yellow"}'::jsonb
   and (preferences #> '{sect,hard_requirement}') ?& array[
     'retired-fellowship','other','orphan-hard-key','shia']
   and jsonb_array_length(preferences #> '{sect,hard_requirement}') = 4
   from public.seeker_details where user_id = pg_temp.q116_actor('male1')),
  'ordinary setup saves preserve exact retired storage and write current entries only');

-- The same live Browse direction should retain its half point when a
-- current legacy Yellow is explicitly accepted as v1 Amber.
savepoint q116_browse_amber;
create temporary table q116_browse_sect_before as
select (preferences #> '{sect,matrix}') - 'current-fellowship' as retained_lights,
       preferences #> '{sect,hard_requirement}' as retained_hard
from public.seeker_details where user_id = pg_temp.q116_actor('male1');
grant select on q116_browse_sect_before to authenticated;

update public.seeker_details
set preferences = jsonb_set(preferences, '{sect,matrix,current-fellowship}', '"yellow"')
where user_id = pg_temp.q116_actor('male1');
set local role authenticated;
select pg_temp.q116_as('male1');
create temporary table q116_browse_yellow as
select * from public.score_candidates(array[pg_temp.q116_actor('fem1')]);
reset role;

update public.seeker_details
set preferences = jsonb_set(preferences, '{sect,matrix,current-fellowship}', '"amber"')
where user_id = pg_temp.q116_actor('male1');
set local role authenticated;
select pg_temp.q116_as('male1');
select pg_temp.q116_assert(
  (select s.score < y.score
   from public.score_candidates(array[pg_temp.q116_actor('fem1')]) s
   join q116_browse_yellow y using (candidate_id)),
  'an unconfirmed raw Amber does not gain a new Browse half point');

select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch2.sect.matrix","option_value":"current-fellowship","light":"amber"}]');
select pg_temp.q116_assert(
  (select s.score = y.score
   from public.score_candidates(array[pg_temp.q116_actor('fem1')]) s
   join q116_browse_yellow y using (candidate_id)),
  'confirmed current sect Amber keeps the existing Browse Yellow half point');
select pg_temp.q116_assert(
  (select (d.preferences #> '{sect,matrix}') - 'current-fellowship' = b.retained_lights
     and d.preferences #> '{sect,hard_requirement}' = b.retained_hard
   from public.seeker_details d cross join q116_browse_sect_before b
   where d.user_id = auth.uid()),
  'confirming the current Browse light preserves every retired light and hard flag');
reset role;
delete from public.preference_light_confirmations
where user_id = pg_temp.q116_actor('male1')
  and question_id = 'ch2.sect.matrix' and option_value = 'current-fellowship';
insert into public.preference_light_confirmations(user_id, question_id, option_value, light)
values (pg_temp.q116_actor('male1'), 'sect', 'current-fellowship', 'amber');
set local role authenticated;
select pg_temp.q116_as('male1');
select pg_temp.q116_assert(
  (select s.score = y.score
   from public.score_candidates(array[pg_temp.q116_actor('fem1')]) s
   join q116_browse_yellow y using (candidate_id)),
  'a matching historical receipt also retains its current Browse half point');
reset role;
rollback to savepoint q116_browse_amber;
release savepoint q116_browse_amber;

-- Acquire one real synthetic entitlement before any result is saved.
insert into public.unlock_credits(user_id,tier,delta,reason)
values (pg_temp.q116_actor('male1'), 'paid_single', 2, 'debug_grant');
set local role authenticated;
select pg_temp.q116_as('male1');
select pg_temp.q116_assert(
  public.zyra_unlock_profile(pg_temp.q116_actor('fem1'), 'paid_single') @>
    '{"status":"unlocked","charged":true,"balance":1}'::jsonb,
  'the fixture owns a paid Unlock with a real debit and one credit left');
reset role;
create temporary table q116_paid_snapshot as
select (select jsonb_agg(to_jsonb(c) order by c.id) from public.unlock_credits c) as ledger,
       (select jsonb_agg(to_jsonb(u) order by u.id) from public.profile_unlocks u) as unlocks,
       (select jsonb_agg(to_jsonb(o) order by o.id) from private.zyra_unlock_operations o) as operations;

-- A missing current key is actionable even for a counterpart with an exact
-- retired key. The reason carries no option light and the hidden list is empty.
update public.seeker_details
set preferences = preferences #- '{sect,matrix,current-fellowship}'
where user_id = pg_temp.q116_actor('male1');
set local role authenticated;
select pg_temp.q116_as('male1');
select pg_temp.q116_assert_profile_state('fem1','incomplete',
  'paid result with a missing current third light is incomplete and contains no score or bands');
select pg_temp.q116_assert(
  (select count(*) = 1 and bool_and(question_id = 'ch2.sect.matrix'
    and option_value = 'current-fellowship' and light is null and reason = 'missing')
   from public.zyra_my_lights_needing_reconfirmation(p_include_missing => true))
  and not exists (select from public.zyra_my_lights_needed_for_compatibility()),
  'the visible list identifies the owner missing choice without fabricating a light');
select pg_temp.q116_assert(
  not exists (select from public.zyra_my_lights_needing_reconfirmation()),
  'the original visible reader preserves its Amber-only response');
select pg_temp.q116_as('fem1');
select pg_temp.q116_assert(
  (select count(*) = 1 and bool_and(option_value = 'retired-fellowship' and reason = 'missing')
   from public.zyra_my_lights_needing_reconfirmation(p_include_missing => true))
  and not exists (select from public.zyra_my_lights_needed_for_compatibility()),
  'a different account sees only its own missing option');
reset role;

update public.seeker_details
set preferences = jsonb_set(preferences, '{sect,matrix,current-fellowship}', '"yellow"')
where user_id = pg_temp.q116_actor('male1');
set local role authenticated;
select pg_temp.q116_as('male1');
select pg_temp.q116_assert_profile_state('fem1','needs_reconfirmation',
  'current v0 Amber requires confirmation even when the counterpart matches a retired sect');
select pg_temp.q116_assert(
  (select count(*) = 1 and bool_and(question_id = 'ch2.sect.matrix'
    and option_value = 'current-fellowship' and light = 'amber' and reason is null)
   from public.zyra_my_lights_needing_reconfirmation(p_include_missing => true))
  and not exists (select from public.zyra_my_lights_needed_for_compatibility()),
  'existing Amber stays visible only with its existing light and no missing reason');
select pg_temp.q116_assert(
  (select count(*) = 1 and bool_and(to_jsonb(r) = jsonb_build_object(
     'question_id', 'ch2.sect.matrix', 'option_value', 'current-fellowship', 'light', 'amber'))
   from public.zyra_my_lights_needing_reconfirmation() r),
  'the original reader keeps the exact three-field Amber contract');
reset role;

update public.seeker_details set sect_other = 'Different Own Words'
where user_id = pg_temp.q116_actor('male1');
set local role authenticated;
select pg_temp.q116_as('male1');
select pg_temp.q116_assert(not exists (select from pg_temp.q116_topics('fem2')),
  'a paid Unlock for a different profile cannot disclose any result state');
reset role;
select pg_temp.q116_assert(not exists (select from private.zyra_compatibility_sect_repairs),
  'a refused result never reaches the repair audit');
set local role authenticated;
select pg_temp.q116_as('male1');
select pg_temp.q116_assert_profile_state('fem1','unavailable',
  'malformed current third identity yields typed unavailable with no score or bands');
select pg_temp.q116_assert_profile_state('fem1','unavailable',
  'retrying unavailable remains scoreless');
reset role;
select pg_temp.q116_assert(
  not has_table_privilege('authenticated', 'private.zyra_compatibility_sect_repairs', 'select')
  and not has_table_privilege('anon', 'private.zyra_compatibility_sect_repairs', 'select')
  and not has_table_privilege('service_role', 'private.zyra_compatibility_sect_repairs', 'select'),
  'no RPC caller role can read the private repair audit table directly');
select pg_temp.q116_assert(
  (select count(*) = 1 and bool_and(viewer = pg_temp.q116_actor('male1')
     and to_jsonb(r) - array['viewer','first_seen_at'] = '{}'::jsonb)
   from private.zyra_compatibility_sect_repairs r),
  'repeated data faults retain one owner repair row without counterpart data');
select pg_temp.q116_assert(
  not exists (select from private.zyra_directional_results)
  and (select ledger = (select jsonb_agg(to_jsonb(c) order by c.id) from public.unlock_credits c)
     and unlocks = (select jsonb_agg(to_jsonb(u) order by u.id) from public.profile_unlocks u)
     and operations = (select jsonb_agg(to_jsonb(o) order by o.id) from private.zyra_unlock_operations o)
   from q116_paid_snapshot),
  'the non-ok reads save no result and leave every entitlement and ledger row unchanged');

update public.seeker_details
set sect_other = 'Current Fellowship',
    preferences = preferences #- '{sect,matrix,current-fellowship}'
where user_id = pg_temp.q116_actor('male1');
set local role authenticated;
select pg_temp.q116_as('male1');
select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch2.sect.matrix","option_value":"current-fellowship","light":"amber"}]');
select pg_temp.q116_assert(
  not exists (select from public.zyra_my_lights_needing_reconfirmation())
  and (select count(*) = 1 and bool_and(light = 'amber' and capture_version = 'v1')
       from public.preference_light_confirmations
       where question_id = 'ch2.sect.matrix' and option_value = 'current-fellowship'),
  'an intentional Amber tap fills the missing key and confirms its matching receipt');
select pg_temp.q116_assert(
  (select count(*) = 12 and bool_and(state = 'ok' and overall is not null and band is not null)
   from pg_temp.q116_topics('fem1')),
  'the same paid Unlock opens its first ok result without another purchase');
reset role;
create temporary table q116_saved_snapshot as
select to_jsonb(r) as result, r.overall from private.zyra_directional_results r;
grant select on q116_saved_snapshot to authenticated;

update public.seeker_details
set sect_other = 'Another Fault',
    preferences = jsonb_set(preferences, '{sect,matrix,current-fellowship}', '"red"')
where user_id = pg_temp.q116_actor('male1');
set local role authenticated;
select pg_temp.q116_as('male1');
select pg_temp.q116_assert(
  (select count(*) = 12 and bool_and(t.state = 'ok' and t.overall = s.overall and t.band is not null)
   from pg_temp.q116_topics('fem1') t cross join q116_saved_snapshot s),
  'an existing saved result still opens after preference changes and a new owner data fault');
reset role;
select pg_temp.q116_assert(
  (select count(*) = 1 and bool_and(to_jsonb(r) = s.result)
   from private.zyra_directional_results r cross join q116_saved_snapshot s)
  and (select ledger = (select jsonb_agg(to_jsonb(c) order by c.id) from public.unlock_credits c)
     and unlocks = (select jsonb_agg(to_jsonb(u) order by u.id) from public.profile_unlocks u)
     and operations = (select jsonb_agg(to_jsonb(o) order by o.id) from private.zyra_unlock_operations o)
   from q116_paid_snapshot),
  'D5 preserves the saved row exactly and D6 never duplicates the existing debit');

-- A missing whole matrix can be repaired by choosing the visible options
-- individually, even when there is no Unlock and ordinary Quick check is used.
update public.seeker_details
set preferences = jsonb_set(preferences, '{sect,matrix}', 'null')
where user_id = pg_temp.q116_actor('male2');
update public.onboarding_answers
set ch4_preferences = jsonb_set(ch4_preferences, '{ch3_q1,Never Married}', '"yellow"')
where user_id = pg_temp.q116_actor('male2');
insert into public.consents(user_id, consent_type, granted, policy_version, recorded_at)
values (pg_temp.q116_actor('male2'), 'article9_special_category', true, 'test', now());
select pg_temp.q116_assert(
  (select state = 'incomplete' and overall is null and area_bands is null
   from public.zyra_score_direction_v1(pg_temp.q116_actor('male2'), pg_temp.q116_actor('fem1'))),
  'an absent matrix is incomplete even when Chapter 4 also needs reconfirmation');
set local role authenticated;
select pg_temp.q116_as('male2');
select pg_temp.q116_assert(
  (select array_agg(option_value order by option_value) = array['other','shia','sunni']
     and bool_and(question_id = 'ch2.sect.matrix' and reason = 'missing' and light is null)
   from public.zyra_my_lights_needing_reconfirmation(p_include_missing => true)
   where question_id = 'ch2.sect.matrix'),
  'ordinary visible Quick check lists the three unset displayed choices');
select public.zyra_confirm_preference_lights(
  '[{"question_id":"ch2.sect.matrix","option_value":"shia","light":"red"}]');
select pg_temp.q116_assert(
  (select array_agg(option_value order by option_value) = array['other','sunni']
     and bool_and(reason = 'missing')
   from public.zyra_my_lights_needing_reconfirmation(p_include_missing => true)
   where question_id = 'ch2.sect.matrix')
  and (select count(*) = 1 and bool_and(option_value = 'shia' and light = 'red')
       from public.preference_light_confirmations),
  'one explicit tap writes just that light and leaves the other choices missing');
reset role;
rollback;
