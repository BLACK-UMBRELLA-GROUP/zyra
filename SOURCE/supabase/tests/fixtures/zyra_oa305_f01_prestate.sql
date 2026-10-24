-- F01-only ISOLATED, EMPTY, SYNTHETIC PostgreSQL fixture; never a live bootstrap.
-- Set zyra.oa305_f01_local_replay=enabled on a database named
-- zyra_oa305_f01_<suffix>. Root owns runtime/target verification and cleanup.
-- No provider, gateway, legal hold, moderation service or actual object API is
-- simulated as production proof. These are the captured table/FK/RLS shapes.
\set ON_ERROR_STOP on

do $guard$
begin
  if pg_catalog.current_database() !~ '^zyra_oa305_f01_[a-z0-9_]+$'
     or pg_catalog.current_setting('zyra.oa305_f01_local_replay', true)
       is distinct from 'enabled'
     or pg_catalog.to_regclass('auth.users') is not null
     or pg_catalog.to_regclass('public.profiles') is not null
     or pg_catalog.to_regclass('public.profile_reports') is not null
     or pg_catalog.to_regclass('storage.objects') is not null then
    raise exception 'F01 fixture requires explicitly armed empty isolated database';
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
create schema storage;
grant usage on schema public, auth to anon, authenticated, service_role;

create table auth.users (id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub',
    ''
  )::uuid;
$$;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('seeker', 'wali'))
);
create table storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text not null,
  name text not null
);
create table public.profile_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null check (reason in (
    'fake_profile', 'inappropriate_content', 'harassment', 'underage',
    'violence', 'privacy', 'other'
  )),
  detail text,
  source text not null default 'browse' check (source in (
    'browse', 'chat', 'journey', 'connections', 'profile', 'guardian'
  )),
  status text not null default 'pending' check (status in (
    'pending', 'reviewing', 'actioned', 'dismissed'
  )),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz
);
create index profile_reports_reported
  on public.profile_reports(reported_id, created_at desc);
create index profile_reports_reporter_idx on public.profile_reports(reporter_id);
create index profile_reports_pending
  on public.profile_reports(created_at desc) where status = 'pending';
alter table public.profile_reports enable row level security;
create policy profile_reports_insert on public.profile_reports for insert
  with check (reporter_id = (select auth.uid()));
create policy profile_reports_select on public.profile_reports for select
  using (reporter_id = (select auth.uid()));
-- UPDATE/DELETE table grants intentionally exercise RLS refusal, not merely
-- missing-privilege refusal. Candidate does not change any of these grants.
grant select, insert, update, delete on public.profile_reports to authenticated;
grant all on public.profile_reports to service_role;
comment on table public.profile_reports is
  'F01 synthetic existing safety evidence; never visible to the reported person.';
comment on column public.profile_reports.detail is 'F01 synthetic submitted context.';

-- Use the unchanged repository RPCs, so pg_get_functiondef drift hashes match
-- the dated captured catalog rather than a hand-written approximation.
\ir ../../migrations/20260726170000_delete_own_account.sql
\ir ../../migrations/20260925202027_restore_safety_case_status_rpc.sql
