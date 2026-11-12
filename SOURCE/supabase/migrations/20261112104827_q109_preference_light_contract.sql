-- Line 92 / LOCK 30 / Q109, Q111 and Q113 / OA-ZYRA-193 / DR-ZYRA-250.
-- Does not change subject applicability or saved compatibility calculations.
begin;

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
  from unnest(array['sunni', 'shia',
    case when p_sect is null or p_sect in ('sunni', 'shia') then 'other' else p_sect end
  ]) sect_code
  union all
  select 'ch2.sect.outside_flexibility', '*', 2, array['sect', 'outside_flexibility']
  union all
  select 'ch2.' || group_id || '.flexibility', '*', 2, array[group_id, 'flexibility']
  from unnest(array['revert', 'location', 'country_of_birth', 'nationality', 'ethnicity', 'languages']) group_id;
$function$;

create or replace function private.zyra_preference_receipt_path(
  p_chapter integer, p_question text, p_option text
)
returns text[]
language sql immutable set search_path = ''
as $function$
  select case
    when p_chapter = 4 then array[p_question, p_option]
    when p_question in ('sect', 'ch2.sect.matrix') then array['sect', 'matrix', p_option]
    when p_option = '*' and p_question like 'ch2.%' then (string_to_array(p_question, '.'))[2:3]
    else array[p_question, 'flexibility'] end;
$function$;

create or replace function private.zyra_invalidate_preference_light_confirmations()
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
      and (v_chapter = 2) = (c.question_id like 'ch2.%' or c.question_id in (
        'sect', 'revert', 'country_of_birth', 'nationality', 'ethnicity', 'languages'));
    return null;
  end if;

  if v_new is not distinct from v_old then return null; end if;

  delete from public.preference_light_confirmations c
  where c.user_id = old.user_id
    and (v_chapter = 2) = (c.question_id like 'ch2.%' or c.question_id in (
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

create or replace function private.zyra_compatibility_light(
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
        where c.user_id = p_viewer and c.capture_version = 'v1' and c.light = v_light
          and ((c.question_id = p_question and c.option_value = p_option)
            or (p_question = 'sect' and c.question_id = 'ch2.sect.matrix'
              and c.option_value = p_option)
            or (p_option = 'flexibility' and c.option_value = '*'
              and c.question_id = 'ch2.' || p_question || '.flexibility'))
      ) then return 0.5; end if;
    when 'yellow' then null;
    else
      raise exception using errcode = 'P8911', message = 'compatibility_light_invalid';
  end case;
  raise exception using errcode = 'P8912', message = 'compatibility_light_needs_reconfirmation';
end;
$$;

-- Share the displayed counterpart bank rule between Quick check and writes.
create function private.zyra_preference_control_visible(
  p_gender text, p_answers jsonb, p_chapter integer, p_question text, p_option text
) returns boolean
language sql stable set search_path = ''
as $function$
  select case when p_chapter = 2 then
    p_question in ('ch2.sect.matrix', 'ch2.sect.outside_flexibility', 'ch2.revert.flexibility')
  else exists (
    select 1 from public.zyra_onboarding_questions q
    where q.qid = p_question and q.ch4_scored and q.options ? p_option
      and q.gender_visibility in ('all',
        case p_gender when 'male' then 'womenOnly' when 'female' then 'menOnly' end)
      and (q.show_if_qid is null or not coalesce(
        q.show_if_not_any_of ? (p_answers ->> q.show_if_qid), false))
  ) end;
$function$;
revoke all on function private.zyra_preference_control_visible(text,jsonb,integer,text,text)
  from public, anon, authenticated, service_role;

-- Only the Chapter 2 choices scored by D2 can appear in the hidden reader.
create function private.zyra_hidden_ch2_light_applicable(p_group text, p_preference jsonb)
returns boolean language sql immutable set search_path = ''
as $function$
  select case when p_group in ('country_of_birth', 'nationality', 'ethnicity', 'languages')
    and p_preference -> 'skipped' = 'false'::jsonb
    and jsonb_typeof(p_preference -> 'preferred') = 'array'
  then (
    select count(*) = count(distinct item.value)
      and bool_and(jsonb_typeof(item.value) = 'string' and (item.value #>> '{}') ~
        case p_group when 'ethnicity' then '^[a-z][a-z_]*$'
          when 'languages' then '^[a-z]{2}$' else '^[A-Z]{2}$' end)
      and bool_or(p_group <> 'languages' or item.value <> '"en"'::jsonb)
    from jsonb_array_elements(p_preference -> 'preferred') item(value)
  ) else false end;
$function$;
revoke all on function private.zyra_hidden_ch2_light_applicable(text,jsonb)
  from public, anon, authenticated, service_role;

-- A single owner-only projection classifies each affected item once. The
-- hidden list has no subject or match input. Location never enters D2 scoring.
create function private.zyra_preference_lights_to_check(p_hidden boolean)
returns table (question_id text, option_value text, light text)
language sql stable set search_path = ''
as $function$
  select c.question_id, c.option_value, 'amber'::text
  from public.profiles p
  left join public.onboarding_answers o on o.user_id = p.id
  left join public.seeker_details d on d.user_id = p.id
  cross join lateral private.zyra_preference_light_controls(p.gender, d.sect) c
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

create or replace function public.zyra_my_lights_needing_reconfirmation()
returns table (question_id text, option_value text, light text)
language sql stable security definer set search_path = ''
as $function$
  select * from private.zyra_preference_lights_to_check(false);
$function$;

create function public.zyra_my_lights_needed_for_compatibility()
returns table (question_id text, option_value text, light text, reason text)
language sql stable security definer set search_path = ''
as $function$
  select c.*, 'hidden_but_applicable'::text
  from private.zyra_preference_lights_to_check(true) c;
$function$;
revoke all on function public.zyra_my_lights_needed_for_compatibility()
  from public, anon, authenticated, service_role;
grant execute on function public.zyra_my_lights_needed_for_compatibility() to authenticated;

-- Q111. Keep only existing Red exclusions; no write path adds one here.
create function private.zyra_red_hard_requirements(p_lights jsonb, p_requirements jsonb)
returns jsonb language sql immutable set search_path = ''
as $function$
  select coalesce(jsonb_agg(item.value order by item.ordinal), '[]'::jsonb)
  from jsonb_array_elements_text(p_requirements) with ordinality as item(value, ordinal)
  where p_lights ->> item.value = 'red';
$function$;
revoke all on function private.zyra_red_hard_requirements(jsonb,jsonb)
  from public, anon, authenticated, service_role;

create function private.zyra_keep_red_ch2_hard_requirements()
returns trigger language plpgsql security definer set search_path = ''
as $function$
begin
  -- Leave malformed input to the existing CHECK instead of clearing exclusions.
  if new.preferences -> 'sect' ? 'hard_requirement'
     and public.zyra_ch2_sect_hard_shape_ok(new.preferences) then
    new.preferences := jsonb_set(new.preferences, '{sect,hard_requirement}',
      private.zyra_red_hard_requirements(new.preferences #> '{sect,matrix}',
        new.preferences #> '{sect,hard_requirement}'), false);
  end if;
  return new;
end;
$function$;
revoke all on function private.zyra_keep_red_ch2_hard_requirements()
  from public, anon, authenticated, service_role;
create trigger zyra_keep_red_ch2_hard_requirements
before insert or update on public.seeker_details
for each row execute function private.zyra_keep_red_ch2_hard_requirements();

create function private.zyra_keep_red_ch4_hard_requirements()
returns trigger language plpgsql security definer set search_path = ''
as $function$
begin
  if new.ch4_hard_requirements is not null
     and public.zyra_ch4_hard_shape_ok(new.ch4_hard_requirements) then
    select coalesce(jsonb_object_agg(q.key,
      private.zyra_red_hard_requirements(new.ch4_preferences -> q.key, q.value)), '{}'::jsonb)
    into new.ch4_hard_requirements from jsonb_each(new.ch4_hard_requirements) q;
  end if;
  return new;
end;
$function$;
revoke all on function private.zyra_keep_red_ch4_hard_requirements()
  from public, anon, authenticated, service_role;
create trigger zyra_keep_red_ch4_hard_requirements
before insert or update on public.onboarding_answers
for each row execute function private.zyra_keep_red_ch4_hard_requirements();

create or replace function public.zyra_confirm_preference_lights(p_items jsonb)
returns void
language plpgsql security definer set search_path = ''
as $function$
declare
  v_me uuid := (select auth.uid());
  v_gender text;
  v_sect text;
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
  select d.preferences, d.sect into v_ch2, v_sect from public.seeker_details d
  where d.user_id = v_me for update;

  -- Q113 admits any current state of a displayed or setup control. A
  -- hidden Chapter 4 option must be in the caller's separate affected list.
  for v_control in
    select i.question_id, i.option_value, i.light, c.chapter, c.path
    from jsonb_to_recordset(p_items) i(question_id text, option_value text, light text)
    left join private.zyra_preference_light_controls(v_gender, v_sect) c
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
      if jsonb_typeof(v_block) <> 'object' then
        raise exception using errcode = '22023', message = 'invalid_preference_lights';
      end if;
      if cardinality(v_control.path) = 3 then
        v_matrix := coalesce(v_block -> 'matrix', '{}'::jsonb);
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

commit;
