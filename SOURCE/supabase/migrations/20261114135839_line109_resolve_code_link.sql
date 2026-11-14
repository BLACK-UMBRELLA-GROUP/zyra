-- ZYRA line 109 / DOC-ZYRA-0512 / OA-ZYRA-317 / Q154.
-- Production requires a separate Founder GO.

begin;

create function private.zyra_begin_personal_code_check()
returns uuid
language plpgsql
set search_path = ''
as $function$
declare
  v_me uuid := auth.uid();
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
      where a.caller_id = v_me
        and a.attempted_at >= clock_timestamp() - interval '1 hour') >= 10
     or
     (select count(*) from private.zyra_personal_code_attempts a
      where a.caller_id = v_me
        and a.attempted_at >= clock_timestamp() - interval '1 day') >= 30 then
    raise exception 'too_many_code_checks';
  end if;

  return v_me;
end;
$function$;

create function private.zyra_personal_code_guardian_eligible(
  p_caller uuid, p_caller_role text, p_owner uuid, p_owner_role text
)
returns boolean
language sql
stable
set search_path = ''
as $function$
  select coalesce(p_owner is not null
    and p_owner <> p_caller
    and private.zyra_identity_verification_allows_user(p_owner)
    and p_caller_role in ('seeker', 'wali')
    and p_owner_role <> p_caller_role
    and not public.zyra_block_exists(p_owner)
    and public.zyra_can_guardian_link(p_caller, p_owner)
    and not exists (
      select 1 from public.wali_links wl
      where ((wl.seeker_id = p_caller and wl.wali_id = p_owner)
          or (wl.seeker_id = p_owner and wl.wali_id = p_caller))
        and wl.status = 'active'
    ), false);
$function$;

create function private.zyra_personal_code_match_eligible(
  p_caller uuid, p_caller_role text, p_owner uuid
)
returns boolean
language sql
stable
set search_path = ''
as $function$
  select coalesce(p_owner is not null
    and p_owner <> p_caller
    and p_caller_role = 'seeker'
    and private.zyra_identity_verification_allows_user(p_owner)
    and public.zyra_can_view_profile(p_owner)
    and public.zyra_can_match(p_caller, p_owner), false);
$function$;

revoke all on function private.zyra_begin_personal_code_check(),
  private.zyra_personal_code_guardian_eligible(uuid, text, uuid, text),
  private.zyra_personal_code_match_eligible(uuid, text, uuid)
  from public, anon, authenticated, service_role;

create or replace function public.zyra_preview_personal_code(p_code text)
returns table(owner_first_name text, owner_role text)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := private.zyra_begin_personal_code_check();
  v_code text := private.zyra_normalize_personal_code(p_code);
  v_owner uuid;
  v_owner_role text;
  v_my_role text;
  v_first_name text;
  v_allowed boolean;
begin
  select c.owner_id, c.role_context, p.first_name
    into v_owner, v_owner_role, v_first_name
  from private.zyra_personal_codes c
  join public.profiles p on p.id = c.owner_id and p.role = c.role_context
  where c.code = v_code;

  select p.role into v_my_role from public.profiles p where p.id = v_me;
  v_allowed := private.zyra_personal_code_guardian_eligible(
    v_me, v_my_role, v_owner, v_owner_role
  );
  insert into private.zyra_personal_code_attempts(caller_id, succeeded)
  values (v_me, v_allowed);
  if not v_allowed then return; end if;

  return query select v_first_name, v_owner_role;
end;
$function$;

create or replace function public.zyra_preview_match_code(p_code text)
returns table(owner_first_name text, owner_age integer, owner_location text)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := private.zyra_begin_personal_code_check();
  v_code text := private.zyra_normalize_personal_code(p_code);
  v_owner uuid;
  v_my_role text;
  v_first_name text;
  v_age integer;
  v_location text;
  v_allowed boolean;
begin
  select c.owner_id,
         p.first_name,
         date_part('year', age(p.date_of_birth))::integer,
         p.location_text
    into v_owner, v_first_name, v_age, v_location
  from private.zyra_personal_codes c
  join public.profiles p on p.id = c.owner_id and p.role = c.role_context
  where c.code = v_code and c.role_context = 'seeker';

  select p.role into v_my_role from public.profiles p where p.id = v_me;
  v_allowed := private.zyra_personal_code_match_eligible(v_me, v_my_role, v_owner);
  insert into private.zyra_personal_code_attempts(caller_id, succeeded)
  values (v_me, v_allowed);
  if not v_allowed then return; end if;

  return query select v_first_name, v_age, v_location;
end;
$function$;

create function public.zyra_resolve_code_link(p_code text)
returns table(
  outcome text,
  owner_first_name text,
  owner_role text,
  owner_age integer,
  owner_location text
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := private.zyra_begin_personal_code_check();
  v_code text := private.zyra_normalize_personal_code(p_code);
  v_owner uuid;
  v_code_role text;
  v_owner_role text;
  v_my_role text;
  v_first_name text;
  v_age integer;
  v_location text;
begin
  select c.owner_id, c.role_context, p.role, p.first_name,
         date_part('year', age(p.date_of_birth))::integer, p.location_text
    into v_owner, v_code_role, v_owner_role, v_first_name, v_age, v_location
  from private.zyra_personal_codes c
  join public.profiles p on p.id = c.owner_id
  where c.code = v_code;

  select p.role into v_my_role from public.profiles p where p.id = v_me;

  outcome := 'unavailable';
  if v_owner = v_me then
    outcome := 'own_code';
  elsif v_owner_role = v_code_role then
    if private.zyra_personal_code_guardian_eligible(v_me, v_my_role, v_owner, v_code_role) then
      outcome := case when v_my_role = 'seeker' then 'add_guardian' else 'add_seeker' end;
      owner_first_name := v_first_name;
      owner_role := v_code_role;
    elsif v_code_role = 'seeker'
      and private.zyra_personal_code_match_eligible(v_me, v_my_role, v_owner) then
      outcome := 'scan';
      owner_first_name := v_first_name;
      owner_age := v_age;
      owner_location := v_location;
    end if;
  end if;

  insert into private.zyra_personal_code_attempts(caller_id, succeeded)
  values (v_me, outcome in ('add_guardian', 'add_seeker', 'scan'));

  return next;
end;
$function$;

revoke all on function public.zyra_resolve_code_link(text)
  from public, anon, service_role;
grant execute on function public.zyra_resolve_code_link(text) to authenticated;

comment on function public.zyra_resolve_code_link(text) is
  'Resolve a shared ZYRA Code using one caller-scoped check across both role routes. '
  'Successful results only disclose the fields already returned by the corresponding preview.';

commit;
