-- Line 92 / Q116 / OA-ZYRA-193 / DR-ZYRA-250 D2, D5, D6.
begin;

-- The canonical code was stored from the full label. A display prefix
-- can be shorter because the client caps that separate field at 60 UTF-16 units.
create function private.zyra_current_sect_third_key(p_sect text, p_words text)
returns text
language sql immutable set search_path = ''
as $function$
  select case
    when p_sect is null or p_sect in ('sunni', 'shia') then 'other'
    when p_sect !~ '^[a-z0-9]+(-[a-z0-9]+)*$' then null
    when p_words is null or p_sect = code then p_sect
    when p_sect = 'other' then case when code not in ('sunni', 'shia') then code end
    when length(p_words) + (
      select count(*) from regexp_split_to_table(p_words, '') letter
      where octet_length(letter) = 4
    ) = 60 and (
      lower(p_words) collate "C" !~ '[a-z0-9]' or starts_with(p_sect, code)
    ) then p_sect
    else null
  end
  from (select public.zyra_sect_code(p_words) as code) words;
$function$;
revoke all on function private.zyra_current_sect_third_key(text,text)
  from public, anon, authenticated, service_role;

create function private.zyra_compatibility_sect_key(p_subject_sect text, p_third_key text)
returns text
language sql immutable set search_path = ''
as $function$
  select case
    when p_subject_sect is null or p_subject_sect in ('sunni', 'shia') then p_subject_sect
    else p_third_key
  end;
$function$;
revoke all on function private.zyra_compatibility_sect_key(text,text)
  from public, anon, authenticated, service_role;

-- Missing controls can be set through the owner writer when the enclosing
-- data is absent or has the expected object shape.
create function private.zyra_sect_light_missing(p_preferences jsonb, p_option text)
returns boolean
language sql immutable set search_path = ''
as $function$
  select jsonb_typeof(p_preferences) = 'object'
    and coalesce(jsonb_typeof(p_preferences -> 'sect'), 'null') in ('object', 'null')
    and coalesce(jsonb_typeof(p_preferences #> '{sect,matrix}'), 'null') in ('object', 'null')
    and p_preferences #>> array['sect', 'matrix', p_option] is null;
$function$;
revoke all on function private.zyra_sect_light_missing(jsonb,text)
  from public, anon, authenticated, service_role;

-- One repair record per viewer, with no counterpart or raw answer fields.
create table private.zyra_compatibility_sect_repairs (
  viewer uuid primary key references public.profiles(id) on delete cascade,
  first_seen_at timestamptz not null default statement_timestamp()
);
alter table private.zyra_compatibility_sect_repairs enable row level security;
revoke all on private.zyra_compatibility_sect_repairs
  from public, anon, authenticated, service_role;

-- Keep the existing directional scorer and disclosures. Only first saves
-- evaluate current preferences; the existing save function owns D5 and D6.
create or replace function public.zyra_score_direction_v1(p_viewer uuid, p_subject uuid)
returns table(capture_version text, inputs_hash text, overall numeric, area_bands jsonb, state text)
language plpgsql volatile security definer set search_path = ''
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
  v_third_sect_key text;
  v_subject_sect_key text;
  v_current_sect_keys text[];
  v_scoring_sect jsonb;
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

  select d.* into v_viewer_details from public.seeker_details d where d.user_id = p_viewer;
  v_third_sect_key := private.zyra_current_sect_third_key(
    v_viewer_details.sect, v_viewer_details.sect_other);
  if v_third_sect_key is null then
    insert into private.zyra_compatibility_sect_repairs(viewer)
    values (p_viewer)
    on conflict (viewer) do nothing;
    state := 'unavailable';
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
  v_current_sect_keys := array['sunni', 'shia', v_third_sect_key];
  if exists (
    select 1 from unnest(v_current_sect_keys) current_key(key)
    where private.zyra_sect_light_missing(v_viewer_details.preferences, key)
  ) then
    raise exception using errcode = 'P8910', message = 'compatibility_input_missing';
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
  v_subject_sect_key := private.zyra_compatibility_sect_key(
    v_subject_details.sect, v_third_sect_key);
  v_hard_options := coalesce(v_block -> 'hard_requirement', '[]'::jsonb);
  perform private.zyra_compatibility_input(v_hard_options, 'array');

  foreach v_option in array v_current_sect_keys loop
    perform private.zyra_compatibility_light(v_lights -> v_option, p_viewer, 'sect', v_option);
  end loop;
  if v_hard_options ? v_subject_sect_key then
    raise exception using errcode = 'P8911', message = 'compatibility_hard_exclusion';
  end if;
  v_points := private.zyra_compatibility_light(
    v_lights -> v_subject_sect_key, p_viewer, 'sect', v_subject_sect_key);
  v_items := v_items || jsonb_build_object('sect', v_points);
  v_scoring_sect := jsonb_build_object(
    'matrix', (select jsonb_object_agg(key, v_lights -> key)
               from unnest(v_current_sect_keys) current_key(key)),
    'hard_requirement', array(select key from unnest(v_current_sect_keys) current_key(key)
                              where v_hard_options ? key)
  );

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
    v_prefs, v_hards, v_ch2_version, v_ch4_version,
    jsonb_set(v_ch2_prefs, '{sect}', v_scoring_sect),
    (select jsonb_agg(jsonb_build_array(c.question_id, c.option_value, c.light)
                      order by c.question_id collate "C", c.option_value collate "C")
       from public.preference_light_confirmations c
      where c.user_id = p_viewer and c.light = 'amber' and c.capture_version = 'v1'
        and (c.question_id not in ('sect', 'ch2.sect.matrix')
          or c.option_value = any(v_current_sect_keys))),
    v_third_sect_key, v_viewer_details.revert_status,
    v_subject_sect_key, v_subject_details.revert_status, v_subject_details.country_of_birth,
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

-- p_sect is the resolved third key for the current owner.
create or replace function private.zyra_preference_light_controls(p_gender text, p_sect text)
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
  select 'ch2.sect.matrix', sect_code, 2, array['sect', 'matrix', sect_code]
  from unnest(array['sunni', 'shia', p_sect]) sect_code
  where sect_code is not null
  union all
  select 'ch2.sect.outside_flexibility', '*', 2, array['sect', 'outside_flexibility']
  union all
  select 'ch2.' || group_id || '.flexibility', '*', 2, array[group_id, 'flexibility']
  from unnest(array['revert', 'location', 'country_of_birth', 'nationality', 'ethnicity', 'languages']) group_id;
$function$;

create or replace function private.zyra_preference_lights_to_check(p_hidden boolean)
returns table (question_id text, option_value text, light text)
language sql stable set search_path = ''
as $function$
  select c.question_id, c.option_value, 'amber'::text
  from public.profiles p
  left join public.onboarding_answers o on o.user_id = p.id
  left join public.seeker_details d on d.user_id = p.id
  cross join lateral private.zyra_preference_light_controls(
    p.gender, private.zyra_current_sect_third_key(d.sect, d.sect_other)) c
  cross join lateral (
    select case c.chapter when 4 then o.ch4_preferences #>> c.path
      else d.preferences #>> c.path end as light,
      private.zyra_preference_control_visible(p.gender, o.ch3_answers,
        c.chapter, c.question_id, c.option_value) as visible
  ) current_control
  where p.id = (select auth.uid()) and p.role = 'seeker'
    and current_control.light in ('amber', 'yellow')
    and (case when p_hidden then not current_control.visible and (
        c.chapter = 4 or private.zyra_hidden_ch2_light_applicable(c.path[1], d.preferences -> c.path[1])
      ) else current_control.visible end)
    and not exists (
      select 1 from public.preference_light_confirmations r
      where r.user_id = p.id and r.light = current_control.light
        and (c.chapter = 2) = (r.question_id like 'ch2.%' or r.question_id in (
          'sect', 'revert', 'country_of_birth', 'nationality', 'ethnicity', 'languages'))
        and private.zyra_preference_receipt_path(c.chapter, r.question_id, r.option_value) = c.path
    )
  order by c.question_id, c.option_value;
$function$;
revoke all on function private.zyra_preference_lights_to_check(boolean)
  from public, anon, authenticated, service_role;

-- Keep the no-argument visible reader's three-field Amber shape for
-- existing clients. The explicit overload adds the owner-only missing rows.
create function public.zyra_my_lights_needing_reconfirmation(p_include_missing boolean)
returns table (question_id text, option_value text, light text, reason text)
language sql stable security definer set search_path = ''
as $function$
  select c.*, null::text as reason
  from private.zyra_preference_lights_to_check(false) c
  union all
  select 'ch2.sect.matrix', k.sect_key, null::text, 'missing'
  from public.profiles p
  join public.seeker_details d on d.user_id = p.id
  cross join lateral unnest(array['sunni', 'shia',
    private.zyra_current_sect_third_key(d.sect, d.sect_other)
  ]) k(sect_key)
  where p_include_missing
    and p.id = (select auth.uid()) and p.role = 'seeker'
    and k.sect_key is not null
    and private.zyra_sect_light_missing(d.preferences, k.sect_key)
  order by question_id, option_value;
$function$;
revoke all on function public.zyra_my_lights_needing_reconfirmation(boolean)
  from public, anon, authenticated, service_role;
grant execute on function public.zyra_my_lights_needing_reconfirmation(boolean) to authenticated;

-- Keep existing retired entries across both partial edits and whole setup
-- saves. Apply Q111's Red rule to the current keys only.
create or replace function private.zyra_keep_red_ch2_hard_requirements()
returns trigger language plpgsql security definer set search_path = ''
as $function$
declare
  v_current_keys text[] := array_remove(array['sunni', 'shia',
    private.zyra_current_sect_third_key(new.sect, new.sect_other)], null);
  v_sect jsonb := new.preferences -> 'sect';
  v_matrix jsonb := v_sect -> 'matrix';
  v_incoming_hard jsonb := v_sect -> 'hard_requirement';
  v_old_matrix jsonb;
  v_old_hard jsonb;
  v_retired_matrix jsonb := '{}'::jsonb;
  v_retired_hard jsonb := '[]'::jsonb;
  v_current_matrix jsonb;
  v_hard jsonb;
  v_keep_hard_order boolean;
begin
  if tg_op = 'UPDATE' then
    v_old_matrix := old.preferences #> '{sect,matrix}';
    v_old_hard := old.preferences #> '{sect,hard_requirement}';
    if jsonb_typeof(v_old_matrix) = 'object' then
      v_retired_matrix := v_old_matrix - v_current_keys;
    end if;
    if jsonb_typeof(v_old_hard) = 'array' then
      select coalesce(jsonb_agg(item.value order by item.ordinal), '[]'::jsonb)
      into v_retired_hard
      from jsonb_array_elements_text(v_old_hard) with ordinality as item(value, ordinal)
      where not (item.value = any(v_current_keys));
    end if;
  end if;

  -- Leave hard-list shape validation to its existing CHECK. Do not let a
  -- malformed replacement erase retired data that cannot be merged.
  if not public.zyra_ch2_sect_hard_shape_ok(new.preferences) then
    return new;
  end if;
  if ((v_retired_matrix <> '{}'::jsonb or v_retired_hard <> '[]'::jsonb)
      and (jsonb_typeof(new.preferences) is distinct from 'object'
        or coalesce(jsonb_typeof(v_sect), 'null') not in ('object', 'null')))
     or (v_retired_matrix <> '{}'::jsonb
         and coalesce(jsonb_typeof(v_matrix), 'null') not in ('object', 'null')) then
    raise exception using errcode = '22023', message = 'invalid_sect_preferences';
  end if;

  if jsonb_typeof(v_matrix) = 'object' or v_retired_matrix <> '{}'::jsonb then
    select coalesce(jsonb_object_agg(key, v_matrix -> key), '{}'::jsonb)
    into v_current_matrix
    from unnest(v_current_keys) current_key(key)
    where v_matrix ? key;
    v_sect := jsonb_set(coalesce(nullif(v_sect, 'null'::jsonb), '{}'::jsonb),
      '{matrix}', v_retired_matrix || v_current_matrix);
  end if;

  if v_incoming_hard is not null or v_retired_hard <> '[]'::jsonb then
    -- A confirmation preserves the submitted list's order while clearing
    -- current flags whose lights changed. A replacement restores old retired
    -- flags in their original order after the new current flags.
    v_keep_hard_order := v_incoming_hard is not distinct from v_old_hard;
    select coalesce(jsonb_agg(item.value order by item.ordinal), '[]'::jsonb)
    into v_hard
    from jsonb_array_elements_text(coalesce(v_incoming_hard, '[]'::jsonb))
      with ordinality as item(value, ordinal)
    where case when item.value = any(v_current_keys) then v_matrix ->> item.value = 'red'
               else v_keep_hard_order end;
    if not v_keep_hard_order then
      v_hard := v_hard || v_retired_hard;
    end if;
    v_sect := jsonb_set(coalesce(nullif(v_sect, 'null'::jsonb), '{}'::jsonb),
      '{hard_requirement}', v_hard);
  end if;
  if v_sect is distinct from new.preferences -> 'sect' then
    new.preferences := jsonb_set(new.preferences, '{sect}', v_sect);
  end if;
  return new;
end;
$function$;
create or replace function public.zyra_confirm_preference_lights(p_items jsonb)
returns void
language plpgsql security definer set search_path = ''
as $function$
declare
  v_me uuid := (select auth.uid());
  v_gender text;
  v_third_sect_key text;
  v_answers jsonb;
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
  if not public.has_article9_consent() then
    raise exception using errcode = '42501', message = 'consent_required';
  end if;
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
  select o.ch3_answers, o.ch4_preferences into v_answers, v_ch4 from public.onboarding_answers o
  where o.user_id = v_me for update;
  select d.preferences, private.zyra_current_sect_third_key(d.sect, d.sect_other)
    into v_ch2, v_third_sect_key
  from public.seeker_details d
  where d.user_id = v_me for update;

  -- Q113 admits any current state of a displayed or setup control. A
  -- hidden Chapter 4 option must be in the caller's separate affected list.
  for v_control in
    select i.question_id, i.option_value, i.light, c.chapter, c.path
    from jsonb_to_recordset(p_items) i(question_id text, option_value text, light text)
    left join private.zyra_preference_light_controls(v_gender, v_third_sect_key) c
      on c.question_id = i.question_id and c.option_value = i.option_value
  loop
    if v_control.chapter is null or (v_control.chapter = 4
       and not private.zyra_preference_control_visible(v_gender, v_answers,
         v_control.chapter, v_control.question_id, v_control.option_value)
       and not exists (
         select 1 from public.zyra_my_lights_needed_for_compatibility() h
         where h.question_id = v_control.question_id and h.option_value = v_control.option_value
       )) then
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
      v_block := coalesce(v_ch2 -> v_control.path[1], '{}'::jsonb);
      if v_control.question_id = 'ch2.sect.matrix' and v_block = 'null'::jsonb then
        v_block := '{}'::jsonb;
      end if;
      if jsonb_typeof(v_block) <> 'object' then
        raise exception using errcode = '22023', message = 'invalid_preference_lights';
      end if;
      if cardinality(v_control.path) = 3 then
        v_matrix := coalesce(nullif(v_block -> 'matrix', 'null'::jsonb), '{}'::jsonb);
        if jsonb_typeof(v_matrix) <> 'object' then
          raise exception using errcode = '22023', message = 'invalid_preference_lights';
        end if;
        v_block := jsonb_set(v_block, array['matrix'],
          v_matrix || jsonb_build_object(v_control.path[3], v_light));
      else
        v_block := v_block || jsonb_build_object(v_control.path[2], v_light);
      end if;
      v_ch2 := jsonb_set(v_ch2, array[v_control.path[1]], v_block);
      v_ch2_changed := true;
    end if;
  end loop;

  perform set_config('zyra.confirm_preference_lights', 'on', true);
  insert into public.preference_light_confirmations (user_id, question_id, option_value, light, confirmed_at)
  -- Refresh a matching legacy setup receipt in place. Its identity forms
  -- part of the existing score hash, which a same-value save must preserve.
  select v_me, coalesce(prior.question_id, i.question_id),
    coalesce(prior.option_value, i.option_value), i.light, statement_timestamp()
  from jsonb_to_recordset(p_items) i(question_id text, option_value text, light text)
  left join public.preference_light_confirmations prior
    on prior.user_id = v_me and prior.light = i.light and (
      (i.question_id = 'ch2.sect.matrix' and prior.question_id = 'sect'
        and prior.option_value = i.option_value)
      or (i.option_value = '*' and prior.option_value = 'flexibility'
        and prior.question_id in ('revert', 'country_of_birth', 'nationality', 'ethnicity', 'languages')
        and i.question_id = 'ch2.' || prior.question_id || '.flexibility')
    )
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

-- Discovery uses the earlier lenient scorer for ranking and live exclusion.
-- Apply the same mapping there while retaining its other scoring rules and
-- the authorization and multi-select amendments made by prior migrations.
do $migration$
declare
  v_definition text := pg_get_functiondef('public.score_candidates(uuid[])'::regprocedure);
  v_old_declaration text := 'v_my_ch2 JSONB; v_cand RECORD; v_block JSONB; v_pref_arr JSONB;';
  v_old_read text :=
    'SELECT sd.preferences INTO v_my_ch2 FROM seeker_details sd WHERE sd.user_id = v_me;';
  v_old_sect text := $old$
        IF v_block IS NOT NULL AND v_cand.sect IS NOT NULL THEN
          IF (v_block -> 'hard_requirement') ? v_cand.sect THEN
            v_excluded := TRUE;
          ELSE
            v_light := v_block -> 'matrix' ->> v_cand.sect;
$old$;
  v_new_sect text := $new$
        v_sect_key := private.zyra_compatibility_sect_key(v_cand.sect, v_third_sect_key);
        IF v_block IS NOT NULL AND v_sect_key IS NOT NULL THEN
          IF (v_block -> 'hard_requirement') ? v_sect_key THEN
            v_excluded := TRUE;
          ELSE
            v_light := v_block -> 'matrix' ->> v_sect_key;
            -- Keep the existing Browse half-weight for a confirmed current Amber.
            IF v_light = 'amber' AND EXISTS (
              SELECT 1 FROM public.preference_light_confirmations c
              WHERE c.user_id = v_me
                AND c.question_id IN ('sect', 'ch2.sect.matrix')
                AND c.option_value = v_sect_key
                AND c.light = 'amber' AND c.capture_version = 'v1'
            ) THEN
              v_light := 'yellow';
            END IF;
$new$;
begin
  if cardinality(string_to_array(v_definition, v_old_declaration)) <> 2
     or cardinality(string_to_array(v_definition, v_old_read)) <> 2
     or cardinality(string_to_array(v_definition, v_old_sect)) <> 2 then
    raise exception 'Q116 expected the established discovery scorer declarations and sect lookup';
  end if;
  v_definition := replace(v_definition, v_old_declaration, v_old_declaration || chr(10)
    || '  v_third_sect_key text; v_sect_key text;');
  v_definition := replace(v_definition, v_old_read,
    'SELECT sd.preferences, private.zyra_current_sect_third_key(sd.sect, sd.sect_other)'
    || chr(10) || '    INTO v_my_ch2, v_third_sect_key'
    || chr(10) || '    FROM seeker_details sd WHERE sd.user_id = v_me;');
  execute replace(v_definition, v_old_sect, v_new_sect);
end;
$migration$;

commit;
