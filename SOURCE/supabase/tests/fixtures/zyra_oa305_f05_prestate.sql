-- F05-only empty synthetic fixture. Not the full migration replay, question
-- bank provenance, gateway/JWT proof or a Supabase production bootstrap.
\set ON_ERROR_STOP on
do $guard$
begin
  if pg_catalog.current_database() !~ '^zyra_oa305_f05_[a-z0-9_]+$'
     or pg_catalog.current_setting('zyra.oa305_f05_local_replay', true)
       is distinct from 'enabled'
     or pg_catalog.to_regclass('public.profiles') is not null
     or pg_catalog.to_regclass('auth.users') is not null then
    raise exception 'F05 fixture requires explicitly armed empty isolated database';
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
create table auth.users (id uuid primary key);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(nullif(current_setting('request.jwt.claims', true), '')::jsonb
    ->> 'sub', '')::uuid;
$$;
create table public.profiles (
  id uuid primary key references auth.users(id), role text not null,
  gender text, profile_complete boolean not null default false
);
create table public.onboarding_answers (
  user_id uuid primary key references public.profiles(id),
  ch3_answers jsonb, ch4_preferences jsonb
);
create table public.seeker_details (
  user_id uuid primary key references public.profiles(id), preferences jsonb
);
create table public.zyra_onboarding_questions (
  qid text not null, gender_visibility text not null, is_multi boolean not null,
  options jsonb not null, primary key(qid, gender_visibility)
);
-- Deliberately small scored-bank fixture plus real unscored rows introduced
-- by the retained 173212 migration. Conditional and dual-gender paths covered.
insert into public.zyra_onboarding_questions values
  ('ch3_q3', 'all', false, '["No", "Yes"]'),
  ('ch3_q24', 'all', false, '["Soon", "Later"]'),
  ('ch3_q26', 'menOnly', false, '["No", "Yes"]'),
  ('ch3_q26', 'womenOnly', false, '["No", "Yes"]');

\ir ../../migrations/20260811153416_oa193c_onboarding_question_bank_and_completeness.sql
\ir ../../migrations/20260811153547_oa193c_materialise_onboarding_complete.sql
\ir ../../migrations/20260811172021_fix_question_is_due_multi_variant_qid.sql
\ir ../../migrations/20260811173212_oa193c_bank_holds_all_104_chapter3_questions.sql

-- Model the captured effective EXECUTE matrix without loading unrelated
-- historical probe/notification SQL. No production default ACL is changed.
revoke execute on function public.zyra_onboarding_missing(uuid),
  public.zyra_onboarding_complete(uuid),
  public.zyra_onboarding_data_complete(uuid,text),
  public.zyra_my_onboarding_progress(),
  public.zyra_refresh_onboarding_complete(uuid),
  public.zyra_profiles_set_onboarding_complete(),
  public.zyra_answers_refresh_onboarding_complete() from public, anon;
grant execute on function public.zyra_onboarding_missing(uuid),
  public.zyra_onboarding_complete(uuid),
  public.zyra_onboarding_data_complete(uuid,text),
  public.zyra_my_onboarding_progress(),
  public.zyra_refresh_onboarding_complete(uuid),
  public.zyra_profiles_set_onboarding_complete(),
  public.zyra_answers_refresh_onboarding_complete() to authenticated, service_role;

alter table public.profiles enable row level security;
alter table public.onboarding_answers enable row level security;
alter table public.seeker_details enable row level security;
create policy f05_profiles_own on public.profiles
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy f05_answers_own on public.onboarding_answers
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy f05_details_own on public.seeker_details
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
grant select, insert, update, delete on public.profiles,
  public.onboarding_answers, public.seeker_details to authenticated;
grant all on public.profiles, public.onboarding_answers,
  public.seeker_details, public.zyra_onboarding_questions to service_role;
-- Synthetic relationship/safety facts are intentionally incapable of
-- authorising a raw progress RPC. They are not production policy substitutes.
create table public.f05_guardian_links (seeker uuid, guardian uuid);
create table public.f05_blocks (blocker uuid, blocked uuid);
