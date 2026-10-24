-- OA-ZYRA-295 — Find a known Seeker by their permanent ZYRA Code.
--
-- STAGED ONLY. Do not apply without a separate Founder production Apply GO.
--
-- This is deliberately separate from zyra_preview_personal_code() and
-- zyra_request_guardian_link(). Those APIs resolve only opposite-role
-- Guardian relationships. Widening them would mix two different authorities
-- and could make a romantic Seeker code appear in the Guardian-link flow.
--
-- A code is a bearer-held discovery handle, not authority to bypass ZYRA's
-- rules. Both functions below require authenticated, identity-verified
-- Seekers and preserve zyra_can_view_profile() + zyra_can_match(). Entering a
-- code creates one Consider only; a Match still requires reciprocal Consider.

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
    return;
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

create or replace function public.zyra_consider_match_code(p_code text)
returns text
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := auth.uid();
  v_code text := private.zyra_normalize_personal_code(p_code);
  v_owner uuid;
  v_preview_name text;
  v_match_exists boolean := false;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;

  -- Re-run the complete preview boundary at mutation time. A prior preview is
  -- never authority: the code, block state, verification or eligibility may
  -- have changed before the member presses Consider.
  select preview.owner_first_name
    into v_preview_name
  from public.zyra_preview_match_code(p_code) preview;
  if v_preview_name is null then return null; end if;

  select c.owner_id into v_owner
  from private.zyra_personal_codes c
  join public.profiles p
    on p.id = c.owner_id
   and p.role = c.role_context
  where c.code = v_code
    and c.role_context = 'seeker';

  if v_owner is null
     or v_owner = v_me
     or not private.zyra_identity_verification_allows_user(v_owner)
     or not public.zyra_can_view_profile(v_owner)
     or not public.zyra_can_match(v_me, v_owner) then
    return null;
  end if;

  insert into public.likes(liker_id, liked_id)
  values (v_me, v_owner)
  on conflict (liker_id, liked_id) do nothing;

  select exists (
    select 1
    from public.matches m
    where (m.seeker_a_id = least(v_me, v_owner)
       and m.seeker_b_id = greatest(v_me, v_owner))
  ) into v_match_exists;

  return case when v_match_exists then 'matched' else 'considered' end;
end;
$function$;

revoke execute on function public.zyra_preview_match_code(text)
  from public, anon;
revoke execute on function public.zyra_consider_match_code(text)
  from public, anon;

grant execute on function public.zyra_preview_match_code(text)
  to authenticated, service_role;
grant execute on function public.zyra_consider_match_code(text)
  to authenticated, service_role;

comment on function public.zyra_preview_match_code(text) is
  'Bearer-code lookup for a known romantic candidate. Returns only Browse-level '
  'identity after authentication, both users identity-verified, Seeker-only '
  'role, visibility, block, onboarding, gender and Guardian-exclusion checks. '
  'Uses the shared personal-code attempt budget; an empty rowset is deliberately '
  'indistinguishable across unknown, ineligible and disallowed targets.';

comment on function public.zyra_consider_match_code(text) is
  'Creates the caller''s ordinary Consider for an eligible Seeker resolved by '
  'permanent ZYRA Code. Rechecks the full preview boundary at mutation time and '
  'does not create a Match without an existing reciprocal Consider.';
