-- ZYRA line 106 / DOC-ZYRA-0475 / OA-ZYRA-317 / Q137.
-- Throw-away database verification only. Production requires a separate Founder GO.

begin;

-- Keep the existing lookup and eligibility rules. Both write paths that
-- already call these previews inherit the limit error from their preview.
create or replace function public.zyra_preview_personal_code(p_code text)
returns table(owner_first_name text, owner_role text)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := auth.uid();
  v_code text := private.zyra_normalize_personal_code(p_code);
  v_owner uuid;
  v_owner_role text;
  v_my_role text;
  v_first_name text;
  v_allowed boolean := false;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(v_me::text, 231));

  delete from private.zyra_personal_code_attempts a
   where a.caller_id = v_me
     and a.attempted_at < clock_timestamp() - interval '7 days';
  if (select count(*) from private.zyra_personal_code_attempts a
      where a.caller_id = v_me and a.attempted_at >= clock_timestamp() - interval '1 hour') >= 10
     or
     (select count(*) from private.zyra_personal_code_attempts a
      where a.caller_id = v_me and a.attempted_at >= clock_timestamp() - interval '1 day') >= 30 then
    raise exception 'too_many_code_checks';
  end if;

  select c.owner_id, c.role_context, p.first_name
    into v_owner, v_owner_role, v_first_name
  from private.zyra_personal_codes c
  join public.profiles p on p.id = c.owner_id and p.role = c.role_context
  where c.code = v_code;
  select p.role into v_my_role from public.profiles p where p.id = v_me;

  v_allowed := coalesce(v_owner is not null
    and v_owner <> v_me
    and private.zyra_identity_verification_allows_user(v_owner)
    and v_my_role in ('seeker', 'wali')
    and v_owner_role <> v_my_role
    and not public.zyra_block_exists(v_owner)
    and public.zyra_can_guardian_link(v_me, v_owner)
    and not exists (
      select 1 from public.wali_links wl
      where ((wl.seeker_id = v_me and wl.wali_id = v_owner)
          or (wl.seeker_id = v_owner and wl.wali_id = v_me))
        and wl.status = 'active'
    ), false);

  insert into private.zyra_personal_code_attempts(caller_id, succeeded)
  values (v_me, v_allowed);
  if not v_allowed then return; end if;

  return query select v_first_name, v_owner_role;
end;
$function$;

create or replace function public.zyra_preview_match_code(p_code text)
returns table(
  owner_first_name text,
  owner_age integer,
  owner_location text
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := auth.uid();
  v_code text := private.zyra_normalize_personal_code(p_code);
  v_owner uuid;
  v_my_role text;
  v_first_name text;
  v_age integer;
  v_location text;
  v_allowed boolean := false;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;

  -- The Guardian-link preview already uses this shared, caller-scoped budget.
  -- Sharing it means switching lookup surfaces cannot multiply enumeration.
  perform pg_advisory_xact_lock(hashtextextended(v_me::text, 231));
  delete from private.zyra_personal_code_attempts a
   where a.caller_id = v_me
     and a.attempted_at < clock_timestamp() - interval '7 days';
  if (select count(*) from private.zyra_personal_code_attempts a
      where a.caller_id = v_me
        and a.attempted_at >= clock_timestamp() - interval '1 hour') >= 10
     or
     (select count(*) from private.zyra_personal_code_attempts a
      where a.caller_id = v_me
        and a.attempted_at >= clock_timestamp() - interval '1 day') >= 30 then
    raise exception 'too_many_code_checks';
  end if;

  select c.owner_id,
         p.first_name,
         date_part('year', age(p.date_of_birth))::integer,
         p.location_text
    into v_owner, v_first_name, v_age, v_location
  from private.zyra_personal_codes c
  join public.profiles p
    on p.id = c.owner_id
   and p.role = c.role_context
  where c.code = v_code
    and c.role_context = 'seeker';

  select p.role into v_my_role
  from public.profiles p
  where p.id = v_me;

  v_allowed := coalesce(
    v_owner is not null
    and v_owner <> v_me
    and v_my_role = 'seeker'
    and private.zyra_identity_verification_allows_user(v_owner)
    and public.zyra_can_view_profile(v_owner)
    and public.zyra_can_match(v_me, v_owner),
    false
  );

  insert into private.zyra_personal_code_attempts(caller_id, succeeded)
  values (v_me, v_allowed);

  if not v_allowed then return; end if;
  return query select v_first_name, v_age, v_location;
end;
$function$;

create or replace function public.zyra_my_code_check_budget()
returns table(
  checks_left_this_hour integer,
  checks_left_today integer,
  next_check_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := auth.uid();
  v_now timestamptz := clock_timestamp();
  v_hour_count integer;
  v_day_count integer;
  v_attempts timestamptz[];
begin
  if v_me is null then raise exception 'not_signed_in'; end if;

  select count(*) filter (where a.attempted_at >= v_now - interval '1 hour'),
         count(*),
         array_agg(a.attempted_at order by a.attempted_at desc)
    into v_hour_count, v_day_count, v_attempts
  from private.zyra_personal_code_attempts a
  where a.caller_id = v_me
    and a.attempted_at >= v_now - interval '1 day';

  -- The existing windows include their lower bound. Use the first instant
  -- after it and wait for both windows when both have reached their cap.
  return query select
    greatest(10 - v_hour_count, 0),
    greatest(30 - v_day_count, 0),
    greatest(
      case when v_hour_count >= 10
        then v_attempts[10] + interval '1 hour 1 microsecond' end,
      case when v_day_count >= 30
        then v_attempts[30] + interval '1 day 1 microsecond' end
    );
end;
$function$;

revoke execute on function public.zyra_my_code_check_budget()
  from public, anon, service_role;
grant execute on function public.zyra_my_code_check_budget()
  to authenticated;

comment on function public.zyra_my_code_check_budget() is
  'Remaining rolling code checks for the signed-in account, and the next '
  'allowed check time when either limit has been reached.';

commit;
