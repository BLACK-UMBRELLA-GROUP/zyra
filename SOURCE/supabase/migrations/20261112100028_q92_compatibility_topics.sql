-- Q92, Q97, Q98, Q100 / DOC-ZYRA-0472 V4 / DR-ZYRA-250.
-- The Dart presentation grouping is the source of area assignment only.
-- Scoring eligibility and applicability remain with the authoritative scorer.

begin;

create table private.zyra_question_area (
  question_id text primary key,
  area smallint not null check (area between 1 and 12)
);

alter table private.zyra_question_area enable row level security;
revoke all on private.zyra_question_area from public, anon, authenticated, service_role;

insert into private.zyra_question_area (question_id, area)
select question_id, area
from (values
  -- deen_practice
  (1, array[
    'ch3_q33', 'ch3_q34', 'ch3_q35', 'ch3_q36', 'ch3_q37', 'ch3_q38', 'ch3_q39', 'ch3_q40',
    'ch3_q41', 'ch3_q42', 'ch3_q43', 'ch3_q44', 'ch3_q45', 'ch3_q46', 'ch3_q49', 'ch3_q50',
    'ch3_q51', 'sect', 'revert'
  ]),
  -- marriage_intentions
  (2, array[
    'ch3_q1', 'ch3_q23', 'ch3_q25', 'ch3_q26', 'ch3_q27', 'ch3_q28', 'ch3_q31', 'ch3_q32'
  ]),
  -- children_parenting
  (3, array[
    'ch3_q2', 'ch3_q3', 'ch3_q24', 'ch3_q29', 'ch3_q48'
  ]),
  -- family_in_laws
  (4, array[
    'ch3_q4', 'ch3_q5', 'ch3_q6', 'ch3_q7', 'ch3_q8', 'ch3_q9', 'ch3_q10'
  ]),
  -- finances_provision
  (5, array[
    'ch3_q12', 'ch3_q13', 'ch3_q14', 'ch3_q15', 'ch3_q19', 'ch3_q20', 'ch3_q21', 'ch3_q22',
    'ch3_q47', 'ch3_q67', 'ch3_q68'
  ]),
  -- education_career
  (6, array[
    'ch3_q11', 'ch3_q16', 'ch3_q17', 'ch3_q18', 'ch3_q63'
  ]),
  -- home_roles
  (7, array[
    'ch3_q64', 'ch3_q65', 'ch3_q66', 'ch3_q69', 'ch3_q70', 'ch3_q71', 'ch3_q72', 'ch3_q73'
  ]),
  -- communication_conflict
  (8, array[
    'ch3_q74', 'ch3_q75', 'ch3_q76', 'ch3_q77', 'ch3_q78', 'ch3_q79', 'ch3_q80', 'ch3_q81',
    'ch3_q82', 'ch3_q83'
  ]),
  -- personality_connection
  (9, array[
    'ch3_q61', 'ch3_q62', 'ch3_q84'
  ]),
  -- lifestyle_wellbeing
  (10, array[
    'ch3_q30', 'ch3_q52', 'ch3_q53', 'ch3_q54', 'ch3_q55', 'ch3_q56', 'ch3_q57', 'ch3_q58',
    'ch3_q59', 'ch3_q60', 'ch3_q94', 'ch3_q95', 'ch3_q96', 'ch3_q97', 'ch3_q98', 'ch3_q99',
    'ch3_q100', 'ch3_q101', 'ch3_q102', 'ch3_q103', 'ch3_q104'
  ]),
  -- digital_boundaries
  (11, array[
    'ch3_q85', 'ch3_q86', 'ch3_q87', 'ch3_q88', 'ch3_q89', 'ch3_q90', 'ch3_q91', 'ch3_q92',
    'ch3_q93'
  ]),
  -- culture_language
  (12, array[
    'country_of_birth', 'nationality', 'ethnicity', 'languages'
  ])
) as areas(area, question_ids)
cross join lateral unnest(areas.question_ids) as questions(question_id);


-- Preserve the source row's capture version. Scoring uses per-light receipts
-- even when a new row starts at v1.
alter table public.onboarding_answers
  add column capture_version text not null default 'v0' check (capture_version in ('v0', 'v1'));
alter table public.onboarding_answers alter column capture_version set default 'v1';

alter table public.seeker_details
  add column capture_version text not null default 'v0' check (capture_version in ('v0', 'v1'));
alter table public.seeker_details alter column capture_version set default 'v1';

create function private.zyra_version_compatibility_capture()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if current_user in ('authenticated', 'anon') then
    if tg_op = 'INSERT' then
      new.capture_version := 'v1';
    else
      new.capture_version := old.capture_version;
    end if;
  end if;
  return new;
end;
$$;
revoke all on function private.zyra_version_compatibility_capture()
  from public, anon, authenticated, service_role;

create trigger zyra_compatibility_capture_version
before insert or update on public.onboarding_answers
for each row execute function private.zyra_version_compatibility_capture();

create trigger zyra_compatibility_capture_version
before insert or update on public.seeker_details
for each row execute function private.zyra_version_compatibility_capture();

create table private.zyra_directional_results (
  viewer uuid not null references public.profiles(id) on delete cascade,
  subject uuid not null references public.profiles(id) on delete cascade,
  capture_version text not null check (capture_version in ('v0', 'v1')),
  inputs_hash text not null check (inputs_hash ~ '^[0-9a-f]{64}$'),
  overall numeric not null check (overall between 0 and 100),
  area_bands jsonb not null check (
    jsonb_typeof(area_bands) = 'array' and jsonb_array_length(area_bands) = 12
    and not jsonb_path_exists(area_bands,
      '$[*] ? (@ != "strong" && @ != "good" && @ != "some_differences" && @ != "not_enough")')
  ),
  state text not null check (state = 'ok'),
  created_at timestamptz not null default now(),
  primary key (viewer, subject),
  check (viewer <> subject)
);
create index zyra_directional_results_subject_idx on private.zyra_directional_results(subject);
alter table private.zyra_directional_results enable row level security;
revoke all on private.zyra_directional_results from public, anon, authenticated, service_role;

-- Internal exceptions map validation outcomes to the four typed states.
create function private.zyra_compatibility_input(p_value jsonb, p_type text)
returns jsonb language plpgsql immutable set search_path = ''
as $$
begin
  if p_value is null or p_value = 'null'::jsonb then
    raise exception using errcode = 'P8910', message = 'compatibility_input_missing';
  end if;
  if jsonb_typeof(p_value) is distinct from p_type then
    raise exception using errcode = 'P8911', message = 'compatibility_input_invalid';
  end if;
  return p_value;
end;
$$;

create function private.zyra_compatibility_light(
  p_value jsonb, p_viewer uuid, p_question text, p_option text
)
returns numeric language plpgsql stable set search_path = ''
as $$
declare
  v_light text := private.zyra_compatibility_input(p_value, 'string') #>> '{}';
begin
  case v_light
    when 'green' then return 1;
    when 'red' then return 0;
    when 'amber' then
      if exists (
        select 1 from public.preference_light_confirmations c
        where c.user_id = p_viewer and c.question_id = p_question
          and c.option_value = p_option and c.capture_version = 'v1' and c.light = v_light
      ) then return 0.5; end if;
    when 'yellow' then null;
    else
      raise exception using errcode = 'P8911', message = 'compatibility_light_invalid';
  end case;
  raise exception using errcode = 'P8912', message = 'compatibility_light_needs_reconfirmation';
end;
$$;

create function private.zyra_compatibility_answer(
  p_value jsonb, p_question text, p_options jsonb, p_multi boolean
)
returns jsonb language plpgsql immutable set search_path = ''
as $$
declare
  v_selected jsonb;
  v_choice jsonb;
begin
  if p_multi then
    v_selected := private.zyra_compatibility_input(p_value, 'array');
  else
    v_selected := jsonb_build_array(private.zyra_compatibility_input(p_value, 'string'));
  end if;
  if jsonb_array_length(v_selected) = 0 then
    raise exception using errcode = 'P8910', message = 'compatibility_selection_missing';
  end if;
  for v_choice in select value from jsonb_array_elements(v_selected) loop
    perform private.zyra_compatibility_input(v_choice, 'string');
    if not (p_options ? (v_choice #>> '{}')) then
      raise exception using errcode = 'P8911', message = 'compatibility_answer_outside_bank';
    end if;
  end loop;
  if jsonb_array_length(v_selected) <> (select count(distinct value) from jsonb_array_elements(v_selected))
     or (p_question in ('ch3_q37','ch3_q97') and v_selected ? 'None' and jsonb_array_length(v_selected) > 1) then
    raise exception using errcode = 'P8911', message = 'compatibility_selection_invalid';
  end if;
  return v_selected;
end;
$$;

revoke all on function private.zyra_compatibility_input(jsonb, text),
  private.zyra_compatibility_light(jsonb, uuid, text, text),
  private.zyra_compatibility_answer(jsonb, text, jsonb, boolean)
  from public, anon, authenticated, service_role;

create function public.zyra_score_direction_v1(p_viewer uuid, p_subject uuid)
returns table(capture_version text, inputs_hash text, overall numeric, area_bands jsonb, state text)
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_actor record;
  v_question record;
  v_option text;
  v_code_pattern text;
  v_selected jsonb;
  v_lights jsonb;
  v_hard_options jsonb;
  v_items jsonb := '{}'::jsonb;
  v_points numeric;
  v_ch4_version text;
  v_ch2_version text;
  v_prefs jsonb;
  v_hards jsonb;
  v_ch2_prefs jsonb;
  v_viewer_answers jsonb;
  v_subject_answers jsonb;
  v_viewer_details public.seeker_details%rowtype;
  v_subject_details public.seeker_details%rowtype;
  v_target_gender text;
  v_block jsonb;
  v_preferred jsonb;
  v_actual jsonb;
  v_matching boolean;
begin
  state := 'incomplete';
  if p_viewer is null or p_subject is null or p_viewer = p_subject then
    state := 'invalid';
    return next;
    return;
  end if;

  for v_actor in
    select p.id, p.gender, o.ch3_answers, o.ch4_preferences, o.ch4_hard_requirements,
           o.capture_version as ch4_version
    from public.profiles p
    left join public.onboarding_answers o on o.user_id = p.id
    where p.id in (p_viewer, p_subject) and p.role = 'seeker'
  loop
    if v_actor.gender is null then
      raise exception using errcode = 'P8910', message = 'compatibility_gender_missing';
    end if;
    perform private.zyra_compatibility_input(v_actor.ch3_answers, 'object');
    -- Match each account's own answer vocabulary and each conditional parent.
    for v_question in
      select q.qid, q.options, q.is_multi
      from public.zyra_onboarding_questions q
      where q.gender_visibility in ('all', case v_actor.gender when 'male' then 'menOnly' else 'womenOnly' end)
        and (q.show_if_qid is null or not coalesce(
          q.show_if_not_any_of ? (v_actor.ch3_answers ->> q.show_if_qid), false))
    loop
      perform private.zyra_compatibility_answer(
        v_actor.ch3_answers -> v_question.qid, v_question.qid, v_question.options, v_question.is_multi);
    end loop;

    if v_actor.id = p_viewer then
      v_viewer_answers := v_actor.ch3_answers;
      v_prefs := v_actor.ch4_preferences;
      v_hards := v_actor.ch4_hard_requirements;
      v_ch4_version := v_actor.ch4_version;
    else
      v_subject_answers := v_actor.ch3_answers;
      v_target_gender := v_actor.gender;
    end if;
  end loop;
  if v_viewer_answers is null or v_subject_answers is null then
    return next;
    return;
  end if;
  if v_target_gender = (select gender from public.profiles where id = p_viewer) then
    raise exception using errcode = 'P8911', message = 'compatibility_direction_invalid';
  end if;
  perform private.zyra_compatibility_input(v_prefs, 'object');
  perform private.zyra_compatibility_input(v_hards, 'object');

  -- Use the subject's applicable scored items and the viewer's full option
  -- matrices. Each multi-select contributes the mean of all selected lights.
  for v_question in
    select q.qid, q.options, q.is_multi
    from public.zyra_onboarding_questions q
    where q.ch4_scored
      and q.gender_visibility in ('all', case v_target_gender when 'male' then 'menOnly' else 'womenOnly' end)
      and (q.show_if_qid is null or not coalesce(
        q.show_if_not_any_of ? (v_subject_answers ->> q.show_if_qid), false))
    order by q.qid
  loop
    v_lights := private.zyra_compatibility_input(v_prefs -> v_question.qid, 'object');
    v_hard_options := coalesce(v_hards -> v_question.qid, '[]'::jsonb);
    perform private.zyra_compatibility_input(v_hard_options, 'array');
    if exists (select 1 from jsonb_object_keys(v_lights) k where not (v_question.options ? k))
       or exists (select 1 from jsonb_array_elements(v_hard_options) h
                  where jsonb_typeof(h) <> 'string' or not (v_question.options ? (h #>> '{}'))) then
      raise exception using errcode = 'P8911', message = 'compatibility_preference_outside_bank';
    end if;
    for v_option in select jsonb_array_elements_text(v_question.options) loop
      perform private.zyra_compatibility_light(v_lights -> v_option, p_viewer, v_question.qid, v_option);
    end loop;
    v_selected := private.zyra_compatibility_answer(
      v_subject_answers -> v_question.qid, v_question.qid, v_question.options, v_question.is_multi);
    if exists (select 1 from jsonb_array_elements_text(v_selected) s where v_hard_options ? s) then
      raise exception using errcode = 'P8911', message = 'compatibility_hard_exclusion';
    end if;
    select avg(private.zyra_compatibility_light(v_lights -> option, p_viewer, v_question.qid, option))
      into v_points
      from jsonb_array_elements_text(v_selected) as selected(option);
    v_items := v_items || jsonb_build_object(v_question.qid, v_points);
  end loop;

  select d.* into v_viewer_details from public.seeker_details d where d.user_id = p_viewer;
  select d.* into v_subject_details from public.seeker_details d where d.user_id = p_subject;
  v_ch2_version := v_viewer_details.capture_version;
  v_ch2_prefs := private.zyra_compatibility_input(v_viewer_details.preferences, 'object');
  if v_viewer_details.sect is null or v_subject_details.sect is null
     or v_viewer_details.revert_status is null or v_subject_details.revert_status is null
     or v_viewer_details.country_of_birth is null or v_subject_details.country_of_birth is null
     or v_viewer_details.nationality is null or v_subject_details.nationality is null
     or v_viewer_details.ethnicity is null or v_subject_details.ethnicity is null
     or cardinality(v_viewer_details.languages) = 0 or cardinality(v_subject_details.languages) = 0 then
    raise exception using errcode = 'P8910', message = 'compatibility_chapter_two_missing';
  end if;

  v_block := private.zyra_compatibility_input(v_ch2_prefs -> 'sect', 'object');
  v_lights := private.zyra_compatibility_input(v_block -> 'matrix', 'object');
  v_hard_options := coalesce(v_block -> 'hard_requirement', '[]'::jsonb);
  perform private.zyra_compatibility_input(v_hard_options, 'array');
  if exists (select 1 from jsonb_array_elements(v_hard_options) h
             where jsonb_typeof(h) <> 'string' or not (v_lights ? (h #>> '{}'))) then
    raise exception using errcode = 'P8911', message = 'compatibility_sect_hard_invalid';
  end if;
  foreach v_option in array array['sunni', 'shia',
    case when v_viewer_details.sect in ('sunni', 'shia') then 'other' else v_viewer_details.sect end]
  loop
    perform private.zyra_compatibility_light(v_lights -> v_option, p_viewer, 'sect', v_option);
  end loop;
  for v_option in select jsonb_object_keys(v_lights) loop
    perform private.zyra_compatibility_light(v_lights -> v_option, p_viewer, 'sect', v_option);
  end loop;
  if v_hard_options ? v_subject_details.sect then
    raise exception using errcode = 'P8911', message = 'compatibility_hard_exclusion';
  end if;
  v_points := private.zyra_compatibility_light(v_lights -> v_subject_details.sect, p_viewer, 'sect', v_subject_details.sect);
  v_items := v_items || jsonb_build_object('sect', v_points);

  if v_subject_details.revert_status then
    v_points := private.zyra_compatibility_light(
      v_ch2_prefs -> 'revert' -> 'flexibility', p_viewer, 'revert', 'flexibility');
    v_items := v_items || jsonb_build_object('revert', v_points);
  end if;

  for v_question in
    select * from (values
      ('country_of_birth', to_jsonb(v_subject_details.country_of_birth), '^[A-Z]{2}$'),
      ('nationality', to_jsonb(v_subject_details.nationality), '^[A-Z]{2}$'),
      ('ethnicity', to_jsonb(v_subject_details.ethnicity), '^[a-z][a-z_]*$'),
      ('languages', to_jsonb(v_subject_details.languages), '^[a-z]{2}$')
    ) as c(item, actual, code_pattern)
  loop
    v_block := private.zyra_compatibility_input(v_ch2_prefs -> v_question.item, 'object');
    if (private.zyra_compatibility_input(v_block -> 'skipped', 'boolean') #>> '{}')::boolean then
      continue;
    end if;
    v_preferred := private.zyra_compatibility_input(v_block -> 'preferred', 'array');
    v_code_pattern := v_question.code_pattern;
    if jsonb_array_length(v_preferred) = 0 then
      raise exception using errcode = 'P8910', message = 'compatibility_preference_missing';
    end if;
    if exists (select 1 from jsonb_array_elements(v_preferred) p
               where jsonb_typeof(p) <> 'string' or (p #>> '{}') !~ v_code_pattern)
       or jsonb_array_length(v_preferred) <> (select count(distinct value) from jsonb_array_elements(v_preferred)) then
      raise exception using errcode = 'P8911', message = 'compatibility_preference_code_invalid';
    end if;
    if v_question.item = 'languages' then
      v_preferred := v_preferred - 'en';
    end if;
    if jsonb_array_length(v_preferred) = 0 then
      continue;
    end if;

    v_points := private.zyra_compatibility_light(v_block -> 'flexibility', p_viewer, v_question.item, 'flexibility');
    if v_question.item = 'languages' then
      v_actual := private.zyra_compatibility_input(v_question.actual, 'array');
      if jsonb_array_length(v_actual) = 0 then
        raise exception using errcode = 'P8910', message = 'compatibility_languages_missing';
      end if;
      if exists (select 1 from jsonb_array_elements(v_actual) a
                 where jsonb_typeof(a) <> 'string' or (a #>> '{}') !~ v_code_pattern) then
        raise exception using errcode = 'P8911', message = 'compatibility_language_code_invalid';
      end if;
      v_matching := exists (select 1 from jsonb_array_elements_text(v_actual) a where v_preferred ? a);
    else
      v_actual := private.zyra_compatibility_input(v_question.actual, 'string');
      v_matching := v_preferred ? (v_actual #>> '{}');
    end if;
    v_items := v_items || jsonb_build_object(v_question.item, case when v_matching then 1 else v_points end);
  end loop;

  if exists (select 1 from jsonb_object_keys(v_items) item
             where not exists (select 1 from private.zyra_question_area m where m.question_id = item)) then
    raise exception using errcode = 'P8911', message = 'compatibility_area_missing';
  end if;
  with counts as (
    select a.area, count(*) as items, sum(i.value::numeric) as points
    from jsonb_each_text(v_items) i
    join private.zyra_question_area a on a.question_id = i.key
    group by a.area
  )
  select round(100 * sum(c.points) / nullif(sum(c.items), 0), 1),
         jsonb_agg(case
           when coalesce(c.items, 0) < 3 then 'not_enough'
           when c.points * 4 >= c.items * 3 then 'strong'
           when c.points * 2 >= c.items then 'good'
           else 'some_differences' end order by a.area)
  into overall, area_bands
  from generate_series(1, 12) a(area) left join counts c on c.area = a.area;

  if overall is null then
    area_bands := null;
    return next;
    return;
  end if;
  capture_version := case when v_ch4_version = 'v1' and v_ch2_version = 'v1' then 'v1' else 'v0' end;
  inputs_hash := encode(sha256(convert_to(jsonb_build_array(
    p_viewer, p_subject, v_target_gender, v_viewer_answers, v_subject_answers,
    v_prefs, v_hards, v_ch2_version, v_ch4_version, v_ch2_prefs,
    (select jsonb_agg(jsonb_build_array(c.question_id, c.option_value, c.light)
                      order by c.question_id collate "C", c.option_value collate "C")
       from public.preference_light_confirmations c
      where c.user_id = p_viewer and c.light = 'amber' and c.capture_version = 'v1'),
    v_viewer_details.sect, v_viewer_details.revert_status,
    v_subject_details.sect, v_subject_details.revert_status, v_subject_details.country_of_birth,
    v_subject_details.nationality, v_subject_details.ethnicity, v_subject_details.languages
  )::text, 'UTF8')), 'hex');
  state := 'ok';
  return next;
exception
  when sqlstate 'P8910' or sqlstate 'P8911' or sqlstate 'P8912' then
    state := case sqlstate when 'P8910' then 'incomplete' when 'P8911' then 'invalid'
                 else 'needs_reconfirmation' end;
    capture_version := null;
    inputs_hash := null;
    overall := null;
    area_bands := null;
    return next;
end;
$$;
revoke all on function public.zyra_score_direction_v1(uuid,uuid)
  from public, anon, authenticated, service_role;
grant execute on function public.zyra_score_direction_v1(uuid,uuid) to service_role;

create function private.zyra_save_direction_result(p_viewer uuid, p_subject uuid)
returns private.zyra_directional_results
language plpgsql volatile set search_path = ''
as $$
declare
  v_result private.zyra_directional_results%rowtype;
begin
  perform pg_advisory_xact_lock(hashtextextended(
    'zyra-compatibility-direction:' || p_viewer::text || ':' || p_subject::text, 0));
  select r.* into v_result from private.zyra_directional_results r
  where r.viewer = p_viewer and r.subject = p_subject;
  if found then
    return v_result;
  end if;
  -- A first save uses one coherent capture. Preference updates and
  -- confirmation writes lock these same rows, in chapter order.
  perform o.user_id from public.onboarding_answers o
  where o.user_id in (p_viewer, p_subject)
  order by o.user_id for share;
  perform d.user_id from public.seeker_details d
  where d.user_id in (p_viewer, p_subject)
  order by d.user_id for share;

  select p_viewer, p_subject, s.capture_version, s.inputs_hash, s.overall, s.area_bands, s.state, now()
    into v_result
    from public.zyra_score_direction_v1(p_viewer, p_subject) s;
  if v_result.state = 'ok' then
    insert into private.zyra_directional_results
    select v_result.*
    on conflict (viewer, subject) do nothing
    returning * into v_result;
    if not found then
      select r.* into strict v_result from private.zyra_directional_results r
      where r.viewer = p_viewer and r.subject = p_subject;
    end if;
  end if;
  return v_result;
end;
$$;
revoke all on function private.zyra_save_direction_result(uuid,uuid)
  from public, anon, authenticated, service_role;

-- DOC-ZYRA-0472 V4 / Q105. An explicit owner call confirms a single light.
create table public.preference_light_confirmations (
  user_id uuid not null references public.profiles(id) on delete cascade,
  question_id text not null,
  option_value text not null,
  light text not null check (light in ('green', 'amber', 'red')),
  capture_version text not null default 'v1' check (capture_version = 'v1'),
  confirmed_at timestamptz not null default statement_timestamp(),
  primary key (user_id, question_id, option_value)
);

alter table public.preference_light_confirmations enable row level security;
revoke all on public.preference_light_confirmations
  from public, anon, authenticated, service_role;
grant select on public.preference_light_confirmations to authenticated;
create policy preference_light_confirmations_read_own
  on public.preference_light_confirmations for select to authenticated
  using (user_id = (select auth.uid()));

-- Use the scored Chapter 4 bank and the existing Chapter 2 storage keys.
create function private.zyra_preference_light_controls(p_gender text, p_sect text)
returns table (question_id text, option_value text, chapter integer, path text[])
language sql stable set search_path = ''
as $function$
  select q.qid, o.option_value, 4, array[q.qid, o.option_value]
  from public.zyra_onboarding_questions q
  cross join lateral jsonb_array_elements_text(q.options) o(option_value)
  where q.ch4_scored
    and q.gender_visibility in ('all',
      case p_gender when 'male' then 'womenOnly' when 'female' then 'menOnly' end)
  union all
  select 'sect', sect_code, 2, array['sect', 'matrix', sect_code]
  from unnest(array['sunni', 'shia',
    case when p_sect is null or p_sect in ('sunni', 'shia') then 'other' else p_sect end
  ]) sect_code
  union all
  select qid, 'flexibility', 2, array[qid, 'flexibility']
  from unnest(array['revert', 'country_of_birth', 'nationality', 'ethnicity', 'languages']) qid;
$function$;
revoke all on function private.zyra_preference_light_controls(text, text)
  from public, anon, authenticated, service_role;

-- This path helper intentionally covers obsolete controls too. An old JSON
-- writer may remove a bank option or move a member between vocabularies.
create function private.zyra_preference_receipt_path(
  p_chapter integer, p_question text, p_option text
)
returns text[]
language sql immutable set search_path = ''
as $function$
  select case
    when p_chapter = 4 then array[p_question, p_option]
    when p_question = 'sect' then array['sect', 'matrix', p_option]
    else array[p_question, 'flexibility'] end;
$function$;
revoke all on function private.zyra_preference_receipt_path(integer, text, text)
  from public, anon, authenticated, service_role;

create function private.zyra_invalidate_preference_light_confirmations()
returns trigger
language plpgsql security definer set search_path = ''
as $function$
declare
  v_chapter integer := tg_argv[0]::integer;
  v_old jsonb := to_jsonb(old) -> tg_argv[1];
  v_new jsonb;
  v_confirm_call boolean := current_setting('zyra.confirm_preference_lights', true) = 'on';
begin
  if tg_op = 'UPDATE' and new.user_id is not distinct from old.user_id then
    v_new := to_jsonb(new) -> tg_argv[1];
  end if;
  if v_new is null then
    delete from public.preference_light_confirmations c
    where c.user_id = old.user_id
      and (v_chapter = 2) = (c.question_id in (
        'sect', 'revert', 'country_of_birth', 'nationality', 'ethnicity', 'languages'));
    return null;
  end if;

  if v_new is not distinct from v_old then return null; end if;

  delete from public.preference_light_confirmations c
  where c.user_id = old.user_id
    and (v_chapter = 2) = (c.question_id in (
      'sect', 'revert', 'country_of_birth', 'nationality', 'ethnicity', 'languages'))
    and (v_old #> private.zyra_preference_receipt_path(v_chapter, c.question_id, c.option_value))
      is distinct from (v_new #> private.zyra_preference_receipt_path(v_chapter, c.question_id, c.option_value))
    -- A caller can set a GUC. Keeping a changed receipt also requires a
    -- matching row written in this statement by the protected RPC.
    and not coalesce(v_confirm_call and c.confirmed_at = statement_timestamp()
      and to_jsonb(c.light) =
        (v_new #> private.zyra_preference_receipt_path(v_chapter, c.question_id, c.option_value)), false);
  return null;
end;
$function$;
revoke all on function private.zyra_invalidate_preference_light_confirmations()
  from public, anon, authenticated, service_role;

create trigger zyra_invalidate_ch4_preference_light_confirmations
after update or delete on public.onboarding_answers
for each row execute function private.zyra_invalidate_preference_light_confirmations('4', 'ch4_preferences');

create trigger zyra_invalidate_ch2_preference_light_confirmations
after update or delete on public.seeker_details
for each row execute function private.zyra_invalidate_preference_light_confirmations('2', 'preferences');

create function public.zyra_confirm_preference_lights(p_items jsonb)
returns void
language plpgsql security definer set search_path = ''
as $function$
declare
  v_me uuid := (select auth.uid());
  v_gender text;
  v_sect text;
  v_ch4 jsonb;
  v_ch2 jsonb;
  v_item jsonb;
  v_control record;
  v_light text;
  v_block jsonb;
  v_matrix jsonb;
  v_ch4_changed boolean := false;
  v_ch2_changed boolean := false;
  v_previous_flag text := current_setting('zyra.confirm_preference_lights', true);
begin
  if v_me is null then
    raise exception using errcode = '42501', message = 'not_signed_in';
  end if;
  select p.gender into v_gender
  from public.profiles p where p.id = v_me and p.role = 'seeker';
  if not found then
    raise exception using errcode = '42501', message = 'seeker_required';
  end if;
  if jsonb_typeof(p_items) is distinct from 'array' then
    raise exception using errcode = '22023', message = 'invalid_preference_lights';
  end if;
  if jsonb_array_length(p_items) = 0 then
    raise exception using errcode = '22023', message = 'invalid_preference_lights';
  end if;

  for v_item in select value from jsonb_array_elements(p_items) loop
    if jsonb_typeof(v_item) is distinct from 'object' then
      raise exception using errcode = '22023', message = 'invalid_preference_lights';
    end if;
    if v_item - array['question_id', 'option_value', 'light'] <> '{}'::jsonb
       or jsonb_typeof(v_item -> 'question_id') is distinct from 'string'
       or jsonb_typeof(v_item -> 'option_value') is distinct from 'string'
       or jsonb_typeof(v_item -> 'light') is distinct from 'string'
       or v_item ->> 'light' not in ('green', 'amber', 'red') then
      raise exception using errcode = '22023', message = 'invalid_preference_lights';
    end if;
  end loop;
  if exists (
    select 1 from jsonb_to_recordset(p_items) i(question_id text, option_value text)
    group by i.question_id, i.option_value having count(*) > 1
  ) then
    raise exception using errcode = '22023', message = 'invalid_preference_lights';
  end if;

  -- Use the same row-before-receipt order as ordinary preference writers.
  select o.ch4_preferences into v_ch4 from public.onboarding_answers o
  where o.user_id = v_me for update;
  select d.preferences, d.sect into v_ch2, v_sect from public.seeker_details d
  where d.user_id = v_me for update;

  for v_control in
    select i.question_id, i.option_value, i.light, c.chapter
    from jsonb_to_recordset(p_items) i(question_id text, option_value text, light text)
    left join private.zyra_preference_light_controls(v_gender, v_sect) c
      on c.question_id = i.question_id and c.option_value = i.option_value
  loop
    if v_control.chapter is null then
      raise exception using errcode = '22023', message = 'invalid_preference_lights';
    end if;
    v_light := v_control.light;
    if v_control.chapter = 4 then
      if jsonb_typeof(v_ch4) is distinct from 'object' then
        raise exception using errcode = '22023', message = 'invalid_preference_lights';
      end if;
      v_block := coalesce(v_ch4 -> v_control.question_id, '{}'::jsonb);
      if jsonb_typeof(v_block) <> 'object' then
        raise exception using errcode = '22023', message = 'invalid_preference_lights';
      end if;
      v_block := v_block || jsonb_build_object(v_control.option_value, v_light);
      v_ch4 := jsonb_set(v_ch4, array[v_control.question_id], v_block);
      v_ch4_changed := true;
    else
      if jsonb_typeof(v_ch2) is distinct from 'object' then
        raise exception using errcode = '22023', message = 'invalid_preference_lights';
      end if;
      v_block := coalesce(v_ch2 -> v_control.question_id, '{}'::jsonb);
      if jsonb_typeof(v_block) <> 'object' then
        raise exception using errcode = '22023', message = 'invalid_preference_lights';
      end if;
      if v_control.question_id = 'sect' then
        v_matrix := coalesce(v_block -> 'matrix', '{}'::jsonb);
        if jsonb_typeof(v_matrix) <> 'object' then
          raise exception using errcode = '22023', message = 'invalid_preference_lights';
        end if;
        v_block := jsonb_set(v_block, array['matrix'],
          v_matrix || jsonb_build_object(v_control.option_value, v_light));
      else
        v_block := v_block || jsonb_build_object('flexibility', v_light);
      end if;
      v_ch2 := jsonb_set(v_ch2, array[v_control.question_id], v_block);
      v_ch2_changed := true;
    end if;
  end loop;

  perform set_config('zyra.confirm_preference_lights', 'on', true);
  insert into public.preference_light_confirmations (user_id, question_id, option_value, light, confirmed_at)
  select v_me, i.question_id, i.option_value, i.light, statement_timestamp()
  from jsonb_to_recordset(p_items) i(question_id text, option_value text, light text)
  on conflict (user_id, question_id, option_value) do update
  set light = excluded.light, confirmed_at = excluded.confirmed_at;

  if v_ch4_changed then
    update public.onboarding_answers set ch4_preferences = v_ch4 where user_id = v_me;
  end if;
  if v_ch2_changed then
    update public.seeker_details set preferences = v_ch2 where user_id = v_me;
  end if;
  perform set_config('zyra.confirm_preference_lights', coalesce(v_previous_flag, ''), true);
end;
$function$;
revoke all on function public.zyra_confirm_preference_lights(jsonb)
  from public, anon, authenticated, service_role;
grant execute on function public.zyra_confirm_preference_lights(jsonb) to authenticated;

create function public.zyra_my_lights_needing_reconfirmation()
returns table (question_id text, option_value text, light text)
language sql stable security definer set search_path = ''
as $function$
  select c.question_id, c.option_value, 'amber'::text
  from public.profiles p
  left join public.onboarding_answers o on o.user_id = p.id
  left join public.seeker_details d on d.user_id = p.id
  cross join lateral private.zyra_preference_light_controls(p.gender, d.sect) c
  cross join lateral (
    select case c.chapter
      when 4 then o.ch4_preferences #>> c.path
      else d.preferences #>> c.path end as light
  ) current_light
  where p.id = (select auth.uid()) and p.role = 'seeker'
    and current_light.light in ('amber', 'yellow')
    and (c.chapter = 4 or c.question_id in ('sect', 'revert')
      or (d.preferences -> c.question_id -> 'skipped') is distinct from 'true'::jsonb)
    and (c.question_id <> 'languages'
      or (d.preferences -> 'languages' -> 'preferred') is distinct from '["en"]'::jsonb)
    and not exists (
      select 1 from public.preference_light_confirmations r
      where r.user_id = p.id and r.question_id = c.question_id
        and r.option_value = c.option_value and r.light = current_light.light
    )
  order by c.question_id, c.option_value;
$function$;
revoke all on function public.zyra_my_lights_needing_reconfirmation()
  from public, anon, authenticated, service_role;
grant execute on function public.zyra_my_lights_needing_reconfirmation() to authenticated;

-- DOC-ZYRA-0472 Q100. Keep the OA-ZYRA-283 member RPC names and envelopes.
create or replace function public.zyra_reveal_journey_compatibility(
  p_match_id uuid
)
returns table(
  mine_revealed boolean,
  counterpart_revealed boolean,
  my_score numeric
)
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
  v_caller uuid := (select auth.uid());
  v_match record;
  v_attempt record;
  v_compat public.journey_compatibility%rowtype;
  v_is_a boolean;
  v_a_result private.zyra_directional_results;
  v_b_result private.zyra_directional_results;
begin
  if v_caller is null then
    raise exception using errcode = '42501', message = 'not_signed_in';
  end if;

  -- All mutating doorways lock in the same order: match, active attempt,
  -- compatibility row. This serialises simultaneous A/B reveals without a
  -- lost update or duplicate-row race.
  select m.seeker_a_id, m.seeker_b_id, m.status, m.journey_stage,
         m.suspended_by, m.also_paused_by,
         coalesce(pg_catalog.to_jsonb(m) ->> 'pause_state', 'none')
           as shared_pause_state
    into v_match
    from public.matches as m
   where m.id = p_match_id
     and v_caller in (m.seeker_a_id, m.seeker_b_id)
   for update;

  if not found then
    raise exception using errcode = '42501', message = 'not_a_party';
  end if;

  if v_match.status is distinct from 'active'
     or v_match.journey_stage is distinct from 'compatibility_reveal'
     or v_match.suspended_by is not null
     or v_match.also_paused_by is not null
     or v_match.shared_pause_state is distinct from 'none' then
    raise exception using errcode = '55000', message = 'journey_not_available';
  end if;

  select a.id, a.journey_stage, a.paused_by, a.also_paused_by,
         coalesce(pg_catalog.to_jsonb(a) ->> 'pause_state', 'none')
           as shared_pause_state
    into v_attempt
    from public.journey_attempts as a
   where a.match_id = p_match_id
     and a.status = 'active'
   for update;

  if not found
     or v_attempt.journey_stage is distinct from 'compatibility_reveal'
     or v_attempt.paused_by is not null
     or v_attempt.also_paused_by is not null
     or v_attempt.shared_pause_state is distinct from 'none' then
    raise exception using errcode = '55000', message = 'journey_not_available';
  end if;

  v_is_a := v_caller = v_match.seeker_a_id;
  insert into public.journey_compatibility (match_id, attempt_id)
  values (p_match_id, v_attempt.id)
  on conflict (match_id) do nothing;

  select jc.*
    into v_compat
    from public.journey_compatibility as jc
   where jc.match_id = p_match_id
   for update;

  if v_compat.attempt_id is distinct from v_attempt.id then
    raise exception using
      errcode = '55000',
      message = 'compatibility_attempt_mismatch';
  end if;

  -- Every Journey uses the same pair of saved directions. Lock them in
  -- UUID order even if a later match represents the pair with sides reversed.
  if v_match.seeker_a_id < v_match.seeker_b_id then
    v_a_result := private.zyra_save_direction_result(v_match.seeker_a_id, v_match.seeker_b_id);
    v_b_result := private.zyra_save_direction_result(v_match.seeker_b_id, v_match.seeker_a_id);
  else
    v_b_result := private.zyra_save_direction_result(v_match.seeker_b_id, v_match.seeker_a_id);
    v_a_result := private.zyra_save_direction_result(v_match.seeker_a_id, v_match.seeker_b_id);
  end if;

  update public.journey_compatibility as jc
     set seeker_a_revealed = jc.seeker_a_revealed or v_is_a,
         seeker_b_revealed = jc.seeker_b_revealed or not v_is_a,
         seeker_a_score = case when v_a_result.state = 'ok' then v_a_result.overall end,
         seeker_b_score = case when v_b_result.state = 'ok' then v_b_result.overall end,
         revealed_at = case
           when (jc.seeker_a_revealed or v_is_a) and (jc.seeker_b_revealed or not v_is_a)
             then coalesce(jc.revealed_at, pg_catalog.statement_timestamp())
           else null
         end
   where jc.match_id = p_match_id
   returning jc.* into v_compat;

  mine_revealed := case
    when v_is_a then v_compat.seeker_a_revealed
    else v_compat.seeker_b_revealed
  end;
  counterpart_revealed := case
    when v_is_a then v_compat.seeker_b_revealed
    else v_compat.seeker_a_revealed
  end;
  my_score := case when v_compat.seeker_a_revealed and v_compat.seeker_b_revealed then
    case when v_is_a then v_compat.seeker_a_score else v_compat.seeker_b_score end
  end;

  return next;
end;
$function$;

create or replace function public.zyra_compatibility_for_plus(
  p_match_id uuid
)
returns numeric
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
  v_caller uuid := (select auth.uid());
  v_match record;
  v_attempt record;
  v_compat public.journey_compatibility%rowtype;
  v_is_a boolean;
  v_counterpart uuid;
  v_result private.zyra_directional_results;
begin
  if v_caller is null then
    raise exception using errcode = '42501', message = 'not_signed_in';
  end if;

  select m.seeker_a_id, m.seeker_b_id, m.status, m.journey_stage,
         m.suspended_by, m.also_paused_by,
         coalesce(pg_catalog.to_jsonb(m) ->> 'pause_state', 'none')
           as shared_pause_state
    into v_match
    from public.matches as m
   where m.id = p_match_id
     and v_caller in (m.seeker_a_id, m.seeker_b_id)
   for update;

  if not found then
    raise exception using errcode = '42501', message = 'not_a_party';
  end if;

  if v_match.status is distinct from 'active'
     or v_match.journey_stage is distinct from 'compatibility_reveal'
     or v_match.suspended_by is not null
     or v_match.also_paused_by is not null
     or v_match.shared_pause_state is distinct from 'none' then
    raise exception using errcode = '55000', message = 'journey_not_available';
  end if;

  select a.id, a.journey_stage, a.paused_by, a.also_paused_by,
         coalesce(pg_catalog.to_jsonb(a) ->> 'pause_state', 'none')
           as shared_pause_state
    into v_attempt
    from public.journey_attempts as a
   where a.match_id = p_match_id
     and a.status = 'active'
   for update;

  if not found
     or v_attempt.journey_stage is distinct from 'compatibility_reveal'
     or v_attempt.paused_by is not null
     or v_attempt.also_paused_by is not null
     or v_attempt.shared_pause_state is distinct from 'none' then
    raise exception using errcode = '55000', message = 'journey_not_available';
  end if;

  v_is_a := v_caller = v_match.seeker_a_id;
  v_counterpart := case
    when v_is_a then v_match.seeker_b_id
    else v_match.seeker_a_id
  end;

  if not exists (
    select 1
      from public.profile_unlocks as unlocks
     where unlocks.unlocker_id = v_caller
       and unlocks.unlocked_id = v_counterpart
       and unlocks.unlock_type in ('paid_plus_single', 'paid_plus_bundle')
  ) then
    raise exception using errcode = '42501', message = 'plus_required';
  end if;

  insert into public.journey_compatibility (match_id, attempt_id)
  values (p_match_id, v_attempt.id)
  on conflict (match_id) do nothing;

  select jc.*
    into v_compat
    from public.journey_compatibility as jc
   where jc.match_id = p_match_id
   for update;

  if v_compat.attempt_id is distinct from v_attempt.id then
    raise exception using
      errcode = '55000',
      message = 'compatibility_attempt_mismatch';
  end if;

  v_result := private.zyra_save_direction_result(v_caller, v_counterpart);
  if v_result.state is distinct from 'ok' then
    return null;
  end if;

  -- Retain the legacy score-only projection and the Main Guardian write
  -- gate on changes to that projection. Plus never changes reveal consent.
  update public.journey_compatibility as jc
     set seeker_a_score = case when v_is_a then v_result.overall else jc.seeker_a_score end,
         seeker_b_score = case when v_is_a then jc.seeker_b_score else v_result.overall end
   where jc.match_id = p_match_id
     and (case when v_is_a then jc.seeker_a_score else jc.seeker_b_score end)
         is distinct from v_result.overall;
  return v_result.overall;
end;
$function$;

comment on function public.zyra_reveal_journey_compatibility(uuid) is
  'OA-ZYRA-283 / DOC-ZYRA-0472. Records the authenticated Seeker consent, projects both saved directions, and returns only the caller-owned Overall after mutual reveal.';
comment on function public.zyra_compatibility_for_plus(uuid) is
  'DR-ZYRA-135 / DOC-ZYRA-0472. Existing Plus entitlements can read the caller-owned saved Overall without changing either reveal flag.';

-- Q92/Q97/Q98/Q100: caller-relative disclosure from one saved directional result.
create function public.zyra_compatibility_topics(
  p_subject uuid,
  p_match_id uuid default null
)
returns table(
  overall numeric,
  topics_locked boolean,
  area_no smallint,
  area_code text,
  band text,
  state text
)
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
  v_caller uuid := (select auth.uid());
  v_role text;
  v_viewer uuid;
  v_match public.matches%rowtype;
  v_attempt_id uuid;
  v_attempt_number integer;
  v_mutual boolean := false;
  v_unlocked boolean := false;
  v_open boolean;
  v_result private.zyra_directional_results%rowtype;
begin
  if v_caller is null or p_subject is null or v_caller = p_subject then return; end if;
  select p.role into v_role from public.profiles p where p.id = v_caller;
  if v_role is null or v_role not in ('seeker', 'wali') then return; end if;
  if not exists (select 1 from public.profiles p where p.id = p_subject and p.role = 'seeker')
     or public.zyra_block_exists(p_subject) then return; end if;

  if v_role = 'seeker' then
    select exists (
      select 1 from public.profile_unlocks u
      where u.unlocker_id = v_caller and u.unlocked_id = p_subject
        and u.unlock_type in ('paid_single', 'paid_bundle', 'paid_plus_single', 'paid_plus_bundle')
    ) into v_unlocked;
  end if;

  if p_match_id is null then
    if v_role <> 'seeker' or not v_unlocked
       or not public.zyra_can_view_profile(p_subject) then return; end if;
    v_viewer := v_caller;
  else
    select m.* into v_match
    from public.matches m
    where m.id = p_match_id and p_subject in (m.seeker_a_id, m.seeker_b_id)
      and m.status in ('active', 'ended')
      and m.end_reason is distinct from 'safety_concern';
    if not found then return; end if;
    v_viewer := case when p_subject = v_match.seeker_a_id then v_match.seeker_b_id
                     else v_match.seeker_a_id end;
    if v_role = 'seeker' and v_viewer <> v_caller then return; end if;

    select a.id, a.attempt_number, jc.seeker_a_revealed and jc.seeker_b_revealed
      into v_attempt_id, v_attempt_number, v_mutual
    from public.journey_attempts a
    left join public.journey_compatibility jc on jc.match_id = a.match_id and jc.attempt_id = a.id
    where a.match_id = v_match.id and a.status = v_match.status
      and (a.status = 'active' or
        (a.end_reason is distinct from 'safety_concern'
         and a.ended_at > now() - interval '3 months'))
    order by a.attempt_number desc
    limit 1;
    if not found then return; end if;

    -- Accepted restarts resume at Salam exchange and leave the prior
    -- match-keyed reveal row on its original attempt. Carry that mutual
    -- consent within this match; check access against the selected attempt.
    if v_mutual is not true then
      select exists (
        select 1 from public.journey_requests r
        join public.journey_compatibility jc on jc.match_id = r.match_id
        join public.journey_attempts prior on prior.id = jc.attempt_id
          and prior.match_id = r.match_id
        where r.match_id = v_match.id and r.attempt_id = v_attempt_id and r.status = 'accepted'
          and prior.status = 'ended' and prior.attempt_number < v_attempt_number
          and prior.end_reason is distinct from 'safety_concern'
          and jc.seeker_a_revealed and jc.seeker_b_revealed
      ) into v_mutual;
    end if;

    if v_role = 'wali' then
      if v_mutual is not true or public.zyra_block_exists(v_viewer) then return; end if;
      if v_match.status = 'active' then
        -- F02's exact-attempt and continuous-link checks, scoped to the
        -- one linked Seeker whose direction this request would disclose.
        if not exists (
          select 1 from public.wali_links w
          where w.seeker_id = v_viewer and w.wali_id = v_caller and w.status = 'active'
            and (w.is_main or exists (
              select 1 from public.journey_guardian_assignments a
              where a.attempt_id = v_attempt_id and a.wali_link_id = w.id
                and a.seeker_id = v_viewer and a.revoked_at is null
                and a.granted_at >= w.active_since
            ))
        ) then return; end if;
      elsif not exists (
        select 1 from public.zyra_attempt_summary_for_guardian(v_viewer) archive
        where archive.attempt_id = v_attempt_id and archive.ended
      ) then return;
      end if;
    elsif v_mutual is not true and not v_unlocked then
      return;
    end if;
  end if;

  -- Safety endings remain private after the live block is removed, including
  -- when the same pair is addressed through an old paid Profile Unlock.
  if exists (
    select 1 from public.matches m
    where ((m.seeker_a_id = v_viewer and m.seeker_b_id = p_subject)
        or (m.seeker_b_id = v_viewer and m.seeker_a_id = p_subject))
      and m.end_reason = 'safety_concern'
  ) or exists (
    select 1 from public.profile_blocks b
    where (b.blocker_id = v_viewer and b.blocked_id = p_subject)
       or (b.blocker_id = p_subject and b.blocked_id = v_viewer)
  ) then return; end if;

  select d.* into v_result
  from private.zyra_directional_results d
  where d.viewer = v_viewer and d.subject = p_subject;
  if not found and v_role = 'seeker' and (v_unlocked or v_mutual is true) then
    v_result := private.zyra_save_direction_result(v_viewer, p_subject);
  end if;

  v_open := case v_role
    when 'seeker' then public.zyra_has_paid_role(v_caller, 'seeker') or v_unlocked
    else public.zyra_has_paid_role(v_caller, 'guardian')
  end;
  return query
    select case when v_result.state = 'ok' then v_result.overall end,
           not v_open,
           a.area_no::smallint,
           a.area_code,
           case when v_open and v_result.state = 'ok'
                then v_result.area_bands ->> (a.area_no - 1) end,
           coalesce(v_result.state, 'incomplete')
    from (values
      (1, 'deen'), (2, 'marriage'), (3, 'children'), (4, 'family'),
      (5, 'finances'), (6, 'work'), (7, 'home'), (8, 'communication'),
      (9, 'personality'), (10, 'lifestyle'), (11, 'digital'), (12, 'culture')
    ) a(area_no, area_code)
    order by a.area_no;
end;
$function$;

revoke all on function public.zyra_compatibility_topics(uuid, uuid)
  from public, anon, authenticated, service_role;
grant execute on function public.zyra_compatibility_topics(uuid, uuid) to authenticated;

commit;
