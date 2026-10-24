-- F04-only isolated synthetic prestate, NOT production schema/visibility parity.
-- Real retained scorer and Journey RPC definitions are loaded below. The small
-- relation/visibility fixtures exercise purpose guards without member contents,
-- live Storage, a provider, production grants or an approved shared snapshot.
\set ON_ERROR_STOP on
do $guard$
begin
  if pg_catalog.current_database() !~ '^zyra_oa305_f04_[a-z0-9_]+$'
     or pg_catalog.current_setting('zyra.oa305_f04_local_replay', true)
       is distinct from 'prepared_local_replay'
     or pg_catalog.to_regclass('public.profiles') is not null
     or pg_catalog.to_regnamespace('zyra_f04_private') is not null then
    raise exception 'F04 fixture requires explicitly armed empty isolated database';
  end if;
end;
$guard$;
do $roles$
begin
  if not exists (select 1 from pg_catalog.pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
  if not exists (select 1 from pg_catalog.pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
  if not exists (select 1 from pg_catalog.pg_roles where rolname = 'service_role') then
    create role service_role nologin bypassrls;
  end if;
end;
$roles$;
create schema auth;
grant usage on schema public, auth to anon, authenticated, service_role;
create function auth.uid() returns uuid language sql stable as $$
  select nullif(nullif(current_setting('request.jwt.claims', true), '')::jsonb
    ->> 'sub', '')::uuid;
$$;
create table public.profiles (
  id uuid primary key, role text not null, gender text,
  is_active boolean not null default true,
  profile_complete boolean not null default true
);
create table public.onboarding_answers (
  user_id uuid primary key references public.profiles(id),
  ch3_answers jsonb, ch4_preferences jsonb, ch4_hard_requirements jsonb
);
create table public.seeker_details (
  user_id uuid primary key references public.profiles(id), preferences jsonb,
  sect text, sect_other text, revert_status boolean,
  country_of_birth text, nationality text, ethnicity text, languages text[]
);
create table public.profile_blocks (blocker_id uuid, blocked_id uuid);
create table public.wali_links (wali_id uuid, seeker_id uuid, status text);
create table public.matches (
  id uuid primary key, seeker_a_id uuid, seeker_b_id uuid, status text,
  journey_stage text, suspended_by uuid, also_paused_by uuid
);
create table public.journey_attempts (
  id uuid primary key, match_id uuid, status text, journey_stage text,
  paused_by uuid, also_paused_by uuid
);
create table public.journey_compatibility (
  match_id uuid primary key, attempt_id uuid,
  seeker_a_revealed boolean not null default false,
  seeker_b_revealed boolean not null default false,
  seeker_a_score numeric, seeker_b_score numeric, revealed_at timestamptz
);
create table public.profile_unlocks (
  unlocker_id uuid, unlocked_id uuid, unlock_type text
);
create function public.zyra_block_exists(p_target uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profile_blocks b
    where (b.blocker_id = (select auth.uid()) and b.blocked_id = p_target)
       or (b.blocked_id = (select auth.uid()) and b.blocker_id = p_target));
$$;
-- Simplified declared relationship visibility, NOT captured production policy.
-- Matching and linked-Guardian exceptions deliberately allow same-gender reads
-- so the narrower Browse projection must independently reject those purposes.
create function public.zyra_can_view_profile(p_target uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.profiles p
    join public.profiles v on v.id = (select auth.uid())
    where p.id = p_target and (
      p.id = v.id
      or exists (select 1 from public.wali_links w where w.status = 'active'
        and ((w.wali_id = v.id and w.seeker_id = p.id)
          or (w.seeker_id = v.id and w.wali_id = p.id)))
      or exists (select 1 from public.matches m
        where v.id in (m.seeker_a_id, m.seeker_b_id)
          and p.id in (m.seeker_a_id, m.seeker_b_id))
      or (v.role = 'seeker' and p.role = 'seeker'
        and v.gender <> p.gender and p.is_active and p.profile_complete
        and not public.zyra_block_exists(p.id))));
$$;
create function public.zyra_light_weight(p_light text) returns numeric
language sql immutable set search_path = public as $$
  select case p_light when 'green' then 1.0 when 'yellow' then 0.5
    when 'red' then 0.0 else 0.0 end::numeric;
$$;

-- Exact retained scorer + its two later surgical fixes: canonical sect codes
-- and one averaged denominator unit per multiselect question.
\ir ../../migrations/20260811152809_score_candidates_null_array_guard.sql
\ir ../../migrations/20260821120000_oa229_canonical_sect_codes.sql
\ir ../../migrations/20260821122000_oa228_multiselect_one_question_unit.sql
revoke execute on function public.score_candidates(uuid[]) from public, anon;
grant execute on function public.score_candidates(uuid[]) to authenticated, service_role;

-- Exact retained member Journey boundary. Caller-pinned mutual/Plus state is
-- tested below, but this fixture is not complete live lifecycle/concurrency.
\ir ../../migrations/20260910184252_oa283_journey_compatibility_rpc_boundary.sql

alter table public.onboarding_answers enable row level security;
alter table public.seeker_details enable row level security;
create policy f04_answers_own on public.onboarding_answers
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy f04_details_own on public.seeker_details
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
grant select, insert, update, delete on public.onboarding_answers,
  public.seeker_details to authenticated;
grant all on public.profiles, public.onboarding_answers, public.seeker_details,
  public.profile_blocks, public.wali_links, public.matches, public.journey_attempts,
  public.profile_unlocks to service_role;
