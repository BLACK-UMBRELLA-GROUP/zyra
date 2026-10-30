-- SERVER 0 V2 / OA-ZYRA-317, OA-ZYRA-319, OA-ZYRA-198.
-- Synthetic actor DATA only, after a governed full-schema replay. Never live.
-- Fresh database per suite: zyra_server0_v2_<unique_suffix>.
-- psql -v ON_ERROR_STOP=1 -v server0_fixture_case=core -f <this file>
-- core: guard, Journey, OA228, OA229, OA231, OA232 and OA282.
-- oa283: the same actors plus OA283's exact compatibility fixture.
-- Onboarding bank, OA289 and OA291 do not need this fixture.
-- Does not create/replace functions, grants, policies or migration history.
-- Keep fixture + suite in an outer rollback, or stop the disposable database
-- after the suite. This file intentionally has no COMMIT/ROLLBACK of its own.
\set ON_ERROR_STOP on
\if :{?server0_fixture_case}
\else
  \set server0_fixture_case core
\endif

do $guard$
begin
  if pg_catalog.current_database() !~ '^zyra_server0_v2_[a-z0-9_]+$'
     or current_user <> 'postgres' then
    raise exception 'SERVER0 fixture requires isolated zyra_server0_v2_* database and postgres owner';
  end if;
  if exists (select 1 from auth.users)
     or exists (select 1 from public.profiles)
     or exists (select 1 from public.matches) then
    raise exception 'SERVER0 fixture refuses nonempty actor/match tables';
  end if;
  if not exists (select 1 from public.zyra_onboarding_questions) then
    raise exception 'SERVER0 fixture requires the replayed question bank';
  end if;
end;
$guard$;

create temporary table server0_v2_fixture_selection (case_name text not null);
insert into server0_v2_fixture_selection values (:'server0_fixture_case');
do $selection$
begin
  if (select case_name from server0_v2_fixture_selection) not in ('core', 'oa283') then
    raise exception 'SERVER0 fixture case must be core or oa283';
  end if;
end;
$selection$;

create temporary table server0_v2_fixture_actors (
  id uuid primary key,
  role_name text not null,
  first_name text not null,
  gender text not null,
  fixture_label text not null unique
);
insert into server0_v2_fixture_actors values
  ('9805470a-d9e6-4e7f-aff1-933031e4aaed', 'seeker', 'Adam', 'male', 'male1'),
  ('12421707-fe06-4604-94bb-771ccd8ae30a', 'seeker', 'Yusuf', 'male', 'male2'),
  ('2e1bcfed-b1f5-4e91-a6a1-c81ab8bf6802', 'seeker', 'Maryam', 'female', 'fem1'),
  ('6c84767c-64df-4d24-b17d-c3239848d68e', 'seeker', 'Aisha', 'female', 'fem2'),
  ('01c7caa4-56c1-481b-8557-de901d3e7d99', 'seeker', 'Rahma', 'female', 'fem3'),
  ('03752c3d-0396-4f38-b234-84d93b724b00', 'seeker', 'Khadija', 'female', 'fem4'),
  ('058050b9-f8d4-4449-920e-8abf7a4a0325', 'wali', 'Ibrahim', 'male', 'gmain'),
  ('6493a6e6-6fc7-4d7a-b1b5-58b637c08647', 'wali', 'Ismail', 'male', 'gadd'),
  ('565a0208-f968-4680-8d68-f1d1165c2679', 'wali', 'Musa', 'male', 'gb'),
  ('cda84c79-cb3e-4c9e-8572-399a1b5ee640', 'wali', 'Harun', 'male', 'gb2'),
  ('257d6ebc-ccd0-4c16-a878-3c416ad7b530', 'wali', 'Hamza', 'male', 'gmain2');

-- OA283's fixed pair is separate from the guard/Journey actors. Adding it in
-- core mode would change those suites' starting match counts and capacity.
insert into server0_v2_fixture_actors
select actor.*
from (values
  ('ac6f5cf7-4695-4332-8cc6-58227ac2f89f'::uuid, 'seeker', 'Omar', 'male', 'oa283a'),
  ('fd47fa36-99fb-4f11-b891-034a769e42c4'::uuid, 'seeker', 'Sara', 'female', 'oa283b')
) actor(id, role_name, first_name, gender, fixture_label)
where (select case_name from server0_v2_fixture_selection) = 'oa283';

-- Shared auth.users columns only: the cached runtime's platform schema is
-- older than current hosted Auth. No confirmation or gateway claim is made.
-- These isolated SQL identities have synthetic addresses and no credential.
insert into auth.users (
  id, aud, role, email, raw_app_meta_data, raw_user_meta_data,
  created_at, updated_at
)
select
  actor.id, 'authenticated', 'authenticated',
  'server0-v2-' || actor.fixture_label || '@zyra.test',
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{}'::jsonb, pg_catalog.clock_timestamp(), pg_catalog.clock_timestamp()
from server0_v2_fixture_actors actor;

insert into public.profiles (
  id, role, first_name, date_of_birth, gender,
  location_text, bio, is_active, profile_complete
)
select actor.id, actor.role_name, actor.first_name,
  case when actor.role_name = 'wali' then date '1960-01-01' else date '1990-01-01' end,
  actor.gender, 'Test', 'SERVER0 V2 isolated synthetic regression actor.', true, true
from server0_v2_fixture_actors actor;

-- Real bank values supply every applicable question; no completeness flag is
-- forced and no trigger is disabled. Extra conditional answers are harmless.
insert into public.onboarding_answers (
  user_id, ch3_answers, ch4_preferences, ch4_hard_requirements, is_synthetic
)
select actor.id,
  pg_catalog.jsonb_object_agg(question.qid,
    case when question.is_multi
      then pg_catalog.jsonb_build_array(question.options -> 0)
      else coalesce(question.options -> 0, '"fixture"'::jsonb) end),
  pg_catalog.jsonb_object_agg(question.qid, coalesce((
    select pg_catalog.jsonb_object_agg(option.value, 'green')
    from pg_catalog.jsonb_array_elements_text(question.options) option(value)
  ), '{}'::jsonb)), '{}'::jsonb, true
from server0_v2_fixture_actors actor
join public.zyra_onboarding_questions question
  on question.gender_visibility = 'all'
  or question.gender_visibility = case actor.gender
    when 'male' then 'menOnly' else 'womenOnly' end
where actor.role_name = 'seeker'
group by actor.id;

insert into public.seeker_details (user_id, sect, preferences, is_synthetic)
select actor.id, 'sunni',
  '{"sect":{"matrix":{"sunni":"green"},"hard_requirement":[]}}'::jsonb, true
from server0_v2_fixture_actors actor where actor.role_name = 'seeker';

-- Explicit paid Basic capacity premises: one place for each Seeker. Guardian
-- Basic does not imply Chat; these suites exercise visibility and lifecycle.
insert into public.subscriptions (user_id, plan_type, status)
select actor.id,
  case actor.role_name when 'seeker' then 'seeker_basic' else 'wali_basic' end,
  'active'
from server0_v2_fixture_actors actor;

insert into private.identity_verification_attempts (
  user_id, provider_code, provider_session_ref, result,
  duplicate_review_required, provider_event_ref_hash,
  consent_granted, consent_version, decided_at
)
select actor.id, 'stripe', 'server0-v2-synthetic-' || actor.id::text, 'verified',
  false, pg_catalog.md5(actor.id::text) || pg_catalog.md5(actor.id::text),
  true, 'server0_v2_fixture', pg_catalog.clock_timestamp()
from server0_v2_fixture_actors actor;

-- Both guard and Journey suites expect only male1's Main at entry. They
-- create their own Additional and counterpart links and check the teardown.
insert into public.wali_links (seeker_id, wali_id, status, is_main, relationship)
values ('9805470a-d9e6-4e7f-aff1-933031e4aaed',
        '058050b9-f8d4-4449-920e-8abf7a4a0325', 'active', true, 'father');

do $premises$
declare
  actor record;
  fixture_attempt uuid;
begin
  for actor in select * from server0_v2_fixture_actors where role_name = 'seeker' loop
    if not public.zyra_onboarding_complete(actor.id)
       or not (select profile.onboarding_complete from public.profiles profile where profile.id = actor.id) then
      raise exception 'SERVER0 fixture actor % has incomplete real onboarding data', actor.fixture_label;
    end if;
  end loop;
  if not public.zyra_can_match('9805470a-d9e6-4e7f-aff1-933031e4aaed',
                             '2e1bcfed-b1f5-4e91-a6a1-c81ab8bf6802') then
    raise exception 'SERVER0 fixture core pair is not matchable';
  end if;
  if (select case_name from server0_v2_fixture_selection) = 'oa283' then
    -- The activation/reveal hold requires a Main for both Seekers. Use two
    -- distinct Guardians so the pair has no shared-Guardian exclusion.
    insert into public.wali_links (seeker_id, wali_id, status, is_main) values
      ('ac6f5cf7-4695-4332-8cc6-58227ac2f89f',
       '565a0208-f968-4680-8d68-f1d1165c2679', 'active', true),
      ('fd47fa36-99fb-4f11-b891-034a769e42c4',
       'cda84c79-cb3e-4c9e-8572-399a1b5ee640', 'active', true);
    insert into public.matches (id, seeker_a_id, seeker_b_id, status, journey_stage)
    values ('5fde2346-d96f-45dd-869f-64eac717e27f',
            'ac6f5cf7-4695-4332-8cc6-58227ac2f89f',
            'fd47fa36-99fb-4f11-b891-034a769e42c4',
            'active', 'compatibility_reveal');
    select attempt.id into strict fixture_attempt
    from public.journey_attempts attempt
    where attempt.match_id = '5fde2346-d96f-45dd-869f-64eac717e27f'
      and attempt.status = 'active';
    update public.journey_attempts set journey_stage = 'compatibility_reveal'
    where id = fixture_attempt;
    insert into public.journey_compatibility (match_id, attempt_id)
    values ('5fde2346-d96f-45dd-869f-64eac717e27f', fixture_attempt);
  end if;
  raise notice 'SERVER0 V2 full-schema synthetic actor premises ready: %',
    (select case_name from server0_v2_fixture_selection);
end;
$premises$;
