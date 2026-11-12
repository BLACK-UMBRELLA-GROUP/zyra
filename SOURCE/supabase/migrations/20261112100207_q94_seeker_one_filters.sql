-- DOC-ZYRA-0472 V3 / Q99 / Q101: Browse filters, hide and home place.
begin;

create table public.profile_hides (
  hider uuid not null references public.profiles(id) on delete cascade,
  hidden uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (hider, hidden),
  check (hider <> hidden)
);

create index profile_hides_hidden on public.profile_hides (hidden, hider);

alter table public.profile_hides enable row level security;
create policy profile_hides_read_own on public.profile_hides for select
to authenticated using (hider = (select auth.uid()));

revoke all on public.profile_hides from public, anon, authenticated, service_role;
grant select on public.profile_hides to authenticated;

create function public.zyra_set_profile_hidden(p_profile uuid, p_hidden boolean)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $hide$
declare
  v_me uuid := (select auth.uid());
begin
  if v_me is null or not exists (
    select 1 from public.profiles p where p.id = v_me and p.role = 'seeker'
  ) then
    raise exception using errcode = '42501', message = 'discovery_not_allowed';
  end if;
  if p_profile is null or p_profile = v_me or p_hidden is null then
    raise exception using errcode = '22023', message = 'invalid_profile_hide';
  end if;

  if p_hidden then
    if not exists (
      select 1
      from public.profiles candidate
      join public.profiles viewer on viewer.id = v_me
      where candidate.id = p_profile and candidate.role = 'seeker'
        and candidate.gender <> viewer.gender
        and public.zyra_can_view_profile(candidate.id)
        and not public.zyra_block_exists(candidate.id)
    ) and not exists (
      select 1 from public.profile_hides h where h.hider = v_me and h.hidden = p_profile
    ) then
      raise exception using errcode = '42501', message = 'profile_unavailable';
    end if;
    insert into public.profile_hides (hider, hidden)
    values (v_me, p_profile)
    on conflict (hider, hidden) do nothing;
  else
    delete from public.profile_hides h
    where h.hider = v_me and h.hidden = p_profile;
  end if;

  return pg_catalog.jsonb_build_object(
    'schema_version', 1, 'viewer_id', v_me, 'profile_id', p_profile, 'hidden', p_hidden
  );
end;
$hide$;

-- Preserve the installed client's JSON key. PostgREST selects the overload
-- from the argument names; both paths use the same owner-scoped writer.
create function public.zyra_set_profile_hidden(p_other text, p_hidden boolean)
returns jsonb
language sql
security invoker
set search_path = ''
as $legacy$
  select public.zyra_set_profile_hidden(p_profile => p_other::uuid, p_hidden => p_hidden);
$legacy$;

create function public.zyra_my_hidden_profile_ids()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $my_hides$
declare
  v_me uuid := (select auth.uid());
begin
  if v_me is null then
    raise exception using errcode = '42501', message = 'not_signed_in';
  end if;

  return pg_catalog.jsonb_build_object(
    'schema_version', 1,
    'viewer_id', v_me,
    'profile_ids', coalesce((
      select pg_catalog.jsonb_agg(h.hidden order by h.hidden)
      from public.profile_hides h where h.hider = v_me
    ), '[]'::jsonb)
  );
end;
$my_hides$;

create table private.seeker_home_places (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  country_code text not null check (country_code ~ '^[A-Z]{2}$'),
  lat numeric(7,2) not null check (lat between -90 and 90),
  lon numeric(7,2) not null check (lon between -180 and 180),
  updated_at timestamptz not null default now()
);

alter table private.seeker_home_places enable row level security;
create policy seeker_home_places_read_own on private.seeker_home_places for select
to authenticated using (user_id = (select auth.uid()));
create policy seeker_home_places_insert_own on private.seeker_home_places for insert
to authenticated with check (user_id = (select auth.uid()));
create policy seeker_home_places_update_own on private.seeker_home_places for update
to authenticated using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

revoke all on private.seeker_home_places from public, anon, authenticated, service_role;

create function public.zyra_set_my_home_place(p_country text, p_lat numeric, p_lon numeric)
returns void
language plpgsql
security definer
set search_path = ''
as $home$
declare
  v_me uuid := (select auth.uid());
begin
  if v_me is null or not exists (
    select 1 from public.profiles p where p.id = v_me and p.role = 'seeker'
  ) then
    raise exception using errcode = '42501', message = 'discovery_not_allowed';
  end if;
  if p_country is null or p_country !~ '^[A-Z]{2}$'
     or p_lat is null or p_lat not between -90 and 90
     or p_lon is null or p_lon not between -180 and 180 then
    raise exception using errcode = '22023', message = 'invalid_home_place';
  end if;

  insert into private.seeker_home_places (user_id, country_code, lat, lon)
  values (v_me, p_country, pg_catalog.round(p_lat, 2), pg_catalog.round(p_lon, 2))
  on conflict (user_id) do update
    set country_code = excluded.country_code, lat = excluded.lat, lon = excluded.lon,
        updated_at = now();
end;
$home$;

revoke all on function
  public.zyra_set_profile_hidden(uuid, boolean),
  public.zyra_set_profile_hidden(text, boolean),
  public.zyra_my_hidden_profile_ids(),
  public.zyra_set_my_home_place(text, numeric, numeric)
from public, anon, authenticated, service_role;

grant execute on function
  public.zyra_set_profile_hidden(uuid, boolean),
  public.zyra_set_profile_hidden(text, boolean),
  public.zyra_my_hidden_profile_ids(),
  public.zyra_set_my_home_place(text, numeric, numeric)
to authenticated;

create function public.zyra_discover_profile_ids(
  p_age_min int default 18,
  p_age_max int default null,
  p_location text default 'worldwide',
  p_distance_km int default null,
  p_country text default null,
  p_nationalities text[] default '{}',
  p_ethnicities text[] default '{}',
  p_limit int default 50,
  p_after uuid default null
)
returns table(profile_id uuid, one_filters_applied boolean, location_applied boolean)
language plpgsql
stable
security definer
set search_path = ''
as $discovery$
declare
  v_one boolean := public.zyra_has_paid_role((select auth.uid()), 'seeker');
  v_caller uuid := (select auth.uid());
  v_gender text;
  v_home_lat double precision;
  v_home_lon double precision;
  v_country text;
  v_location text := coalesce(p_location, 'worldwide');
  v_location_applied boolean;
  v_nationalities text[] := coalesce(p_nationalities, '{}');
  v_ethnicities text[] := coalesce(p_ethnicities, '{}');
  v_one_filters_applied boolean;
begin
  select viewer.gender, home.lat, home.lon,
         coalesce(p_country, home.country_code)
  into v_gender, v_home_lat, v_home_lon, v_country
  from public.profiles viewer
  left join private.seeker_home_places home on home.user_id = viewer.id
  where viewer.id = v_caller and viewer.role = 'seeker' and viewer.is_active;
  if not found then
    return;
  end if;

  if v_location not in ('near', 'country', 'worldwide') then
    raise exception using errcode = '22023', message = 'invalid_discovery_location';
  end if;
  v_location_applied := v_location = 'country' or
    (v_location = 'near' and v_home_lat is not null and v_home_lon is not null);
  if v_location = 'near' and v_location_applied
     and (p_distance_km is null or p_distance_km not between 5 and 500) then
    raise exception using errcode = '22023', message = 'invalid_discovery_distance';
  end if;
  v_one_filters_applied := v_one and (
    pg_catalog.cardinality(v_nationalities) > 0 or pg_catalog.cardinality(v_ethnicities) > 0
  );

  return query
  with eligible as materialized (
    select candidate.id
    from public.profiles candidate
    left join public.seeker_details details on details.user_id = candidate.id
    left join private.seeker_home_places home on home.user_id = candidate.id
    cross join lateral (
      select extract(year from pg_catalog.age(current_date, candidate.date_of_birth))::int as years
    ) age
    where candidate.id <> v_caller
      and candidate.role = 'seeker'
      and candidate.gender <> v_gender
      and candidate.is_active
      and candidate.profile_complete
      and not exists (
        select 1 from public.profile_hides hide
        where (hide.hider = v_caller and hide.hidden = candidate.id)
           or (hide.hider = candidate.id and hide.hidden = v_caller)
      )
      and not public.zyra_block_exists(candidate.id)
      and public.zyra_can_view_profile(candidate.id)
      and exists (
        select 1 from public.profile_photos photo
        where photo.user_id = candidate.id
          and public.zyra_can_read_photo_object(photo.storage_path)
      )
      and age.years >= greatest(coalesce(p_age_min, 18), 18)
      and (p_age_max is null or age.years <= p_age_max)
      and (not v_one or pg_catalog.cardinality(v_nationalities) = 0
           or details.nationality = any(v_nationalities))
      and (not v_one or pg_catalog.cardinality(v_ethnicities) = 0
           or details.ethnicity = any(v_ethnicities))
      and case
        when not v_location_applied then true
        when v_location = 'country' then home.country_code = v_country
        when home.lat is null or home.lon is null then false
        else
          2.0 * 6371.0 * pg_catalog.asin(pg_catalog.sqrt(least(1.0,
            pg_catalog.power(pg_catalog.sin(pg_catalog.radians(home.lat - v_home_lat) / 2.0), 2)
            + pg_catalog.cos(pg_catalog.radians(v_home_lat))
              * pg_catalog.cos(pg_catalog.radians(home.lat))
              * pg_catalog.power(pg_catalog.sin(pg_catalog.radians(home.lon - v_home_lon) / 2.0), 2)
          ))) <= p_distance_km
      end
  ), ranked as materialized (
    -- The existing Browse scorer suppresses hard-requirement failures and
    -- ranks scored candidates above unscored candidates. Keep scores internal.
    -- A UUID tie-break makes the formerly unordered source ties pageable.
    select scored.candidate_id as id, -coalesce(scored.score, -1) as sort_score
    from public.score_candidates(array(select e.id from eligible e)) scored
  ), cursor_row as (
    select r.id, r.sort_score from ranked r where r.id = p_after
  )
  select r.id, v_one_filters_applied, v_location_applied
  from ranked r
  where p_after is null or exists (
    select 1 from cursor_row c where (r.sort_score, r.id) > (c.sort_score, c.id)
  )
  order by r.sort_score, r.id
  limit least(greatest(coalesce(p_limit, 50), 0), 50);
end;
$discovery$;

revoke all on function public.zyra_discover_profile_ids(
  int, int, text, int, text, text[], text[], int, uuid
) from public, anon, authenticated, service_role;
grant execute on function public.zyra_discover_profile_ids(
  int, int, text, int, text, text[], text[], int, uuid
) to authenticated;

commit;
