-- ZYRA line 109 / DOC-ZYRA-0512 / OA-ZYRA-317 / Q154.
-- Run only on a disposable replay with the candidate installed.
\set ON_ERROR_STOP on
begin;

do $test$
begin
  if current_user <> 'postgres' or exists (select from auth.users) then
    raise exception 'Line 109 requires an empty disposable replay owned by postgres';
  end if;
end;
$test$;

create temporary table code_actors (
  name text primary key,
  id uuid not null default gen_random_uuid(),
  profile_role text not null,
  gender text not null,
  code text not null unique
);

insert into code_actors (name, profile_role, gender, code) values
  ('Adam', 'seeker', 'male', 'ZYRA-0000-0000-0000-0000-0001'),
  ('Noor', 'seeker', 'female', 'ZYRA-0000-0000-0000-0000-0002'),
  ('Tariq', 'wali', 'male', 'ZYRA-0000-0000-0000-0000-0003'),
  ('Leena', 'wali', 'female', 'ZYRA-0000-0000-0000-0000-0004'),
  ('Yusuf', 'wali', 'male', 'ZYRA-0000-0000-0000-0000-0005'),
  ('Sara', 'seeker', 'female', 'ZYRA-0000-0000-0000-0000-0006'),
  ('Malik', 'wali', 'male', 'ZYRA-0000-0000-0000-0000-0007');
grant select on code_actors to authenticated;

insert into auth.users (id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
select id, 'authenticated', 'authenticated', 'line109-' || name || '@example.com',
       '{}'::jsonb, '{}'::jsonb, now(), now()
from code_actors;
insert into public.profiles (
  id, role, first_name, date_of_birth, gender, location_text, bio, is_active, profile_complete
)
select id, profile_role, name, date '1990-01-01', gender, 'Test Location',
       'Synthetic code-link actor.', true, true
from code_actors;
update public.profiles set onboarding_complete = true
where id in (select id from code_actors where profile_role = 'seeker');

insert into private.identity_verification_attempts (
  user_id, provider_code, provider_session_ref, result, duplicate_review_required,
  provider_event_ref_hash, consent_granted, consent_version, decided_at
)
select id, 'stripe', 'line109-' || name, 'verified', false,
       md5(id::text) || md5(id::text), true, 'line109_fixture', now()
from code_actors where name <> 'Malik';
insert into private.zyra_personal_codes (owner_id, role_context, code)
select id, profile_role, code from code_actors;

insert into public.profile_blocks (blocker_id, blocked_id)
select blocker.id, blocked.id
from code_actors blocker cross join code_actors blocked
where (blocker.name = 'Yusuf' and blocked.name = 'Adam')
   or (blocker.name = 'Adam' and blocked.name = 'Sara');

-- Exercise the real retirement trigger. Resolving the old address must
-- disclose exactly the same information as a completely unknown code.
update private.zyra_personal_codes
set code = 'ZYRA-0000-0000-0000-0000-0044', rotated_at = now()
where owner_id = (select id from code_actors where name = 'Leena');

create function pg_temp.assert_true(p_ok boolean, p_label text)
returns void language plpgsql as $test$
begin
  if p_ok is distinct from true then raise exception 'Line 109 FAIL: %', p_label; end if;
  raise notice 'Line 109 PASS: %', p_label;
end;
$test$;

create function pg_temp.sign_in(p_name text)
returns text language sql as $test$
  select set_config('request.jwt.claims',
    json_build_object('sub', id, 'role', 'authenticated')::text, true)
  from code_actors where name = p_name;
$test$;

create function pg_temp.assert_error(p_sql text, p_message text)
returns void language plpgsql as $test$
begin
  begin
    execute p_sql;
  exception
    when others then
      if sqlerrm = p_message then return; end if;
      raise;
  end;
  raise exception 'Line 109 expected %', p_message;
end;
$test$;

create function pg_temp.assert_link(
  p_code text, p_outcome text, p_name text default null, p_role text default null,
  p_age integer default null, p_location text default null
)
returns void language plpgsql as $test$
declare
  v_reply record;
  v_before integer;
  v_after integer;
begin
  select checks_left_today into v_before from public.zyra_my_code_check_budget();
  select * into strict v_reply from public.zyra_resolve_code_link(p_code);
  select checks_left_today into v_after from public.zyra_my_code_check_budget();
  perform pg_temp.assert_true(v_before - v_after = 1, 'one attempt for ' || p_outcome);
  perform pg_temp.assert_true(
    v_reply.outcome is not distinct from p_outcome
    and v_reply.owner_first_name is not distinct from p_name
    and v_reply.owner_role is not distinct from p_role
    and v_reply.owner_age is not distinct from p_age
    and v_reply.owner_location is not distinct from p_location,
    'exact permitted payload for ' || p_outcome
  );
end;
$test$;

select pg_temp.assert_true(
  has_function_privilege('authenticated', 'public.zyra_resolve_code_link(text)', 'EXECUTE')
  and not has_function_privilege('anon', 'public.zyra_resolve_code_link(text)', 'EXECUTE')
  and not has_function_privilege('service_role', 'public.zyra_resolve_code_link(text)', 'EXECUTE')
  and exists (
    select from pg_proc p
    where p.oid = 'public.zyra_resolve_code_link(text)'::regprocedure
      and p.prosecdef and p.proconfig = array['search_path=""']
  ),
  'only authenticated callers may execute the resolver, with owner rights and an empty search path'
);
select pg_temp.assert_true(
  not exists (
    select from pg_proc p
    where p.oid in (
      'private.zyra_begin_personal_code_check()'::regprocedure,
      'private.zyra_personal_code_guardian_eligible(uuid,text,uuid,text)'::regprocedure,
      'private.zyra_personal_code_match_eligible(uuid,text,uuid)'::regprocedure
    ) and (
      has_function_privilege('anon', p.oid, 'EXECUTE')
      or has_function_privilege('authenticated', p.oid, 'EXECUTE')
      or has_function_privilege('service_role', p.oid, 'EXECUTE')
    )
  ),
  'the budget and eligibility helpers remain private'
);

set local role anon;
select pg_temp.assert_error(
  $$select from public.zyra_resolve_code_link('ZYRA-0000-0000-0000-0000-0003')$$,
  'permission denied for function zyra_resolve_code_link'
);

set local role authenticated;
select pg_temp.assert_error(
  $$select from public.zyra_resolve_code_link('ZYRA-0000-0000-0000-0000-0003')$$,
  'not_signed_in'
);
select pg_temp.sign_in('Malik');
select pg_temp.assert_error(
  $$select from public.zyra_resolve_code_link('ZYRA-0000-0000-0000-0000-0001')$$,
  'identity_verification_required'
);

select pg_temp.sign_in('Adam');
select pg_temp.assert_link('ZYRA-0000-0000-0000-0000-0003', 'add_guardian', 'Tariq', 'wali');
select pg_temp.assert_link('ZYRA-0000-0000-0000-0000-0002', 'scan', 'Noor', null,
  date_part('year', age(date '1990-01-01'))::integer, 'Test Location');
select pg_temp.assert_link('ZYRA-0000-0000-0000-0000-0001', 'own_code');
select pg_temp.assert_link('ZYRA-0000-0000-0000-0000-0099', 'unavailable');
select pg_temp.assert_link('ZYRA-0000-0000-0000-0000-0004', 'unavailable');
select pg_temp.assert_link('ZYRA-0000-0000-0000-0000-0005', 'unavailable');
select pg_temp.assert_link('ZYRA-0000-0000-0000-0000-0006', 'unavailable');
select pg_temp.assert_link('ZYRA-0000-0000-0000-0000-0007', 'unavailable');

select pg_temp.assert_true((
  select owner_first_name = 'Tariq' and owner_role = 'wali'
  from public.zyra_preview_personal_code('ZYRA-0000-0000-0000-0000-0003')
), 'existing Guardian preview returns its existing payload');
select pg_temp.assert_true((
  select owner_first_name = 'Noor'
     and owner_age = date_part('year', age(date '1990-01-01'))::integer
     and owner_location = 'Test Location'
  from public.zyra_preview_match_code('ZYRA-0000-0000-0000-0000-0002')
), 'existing match preview returns its existing payload');
select pg_temp.assert_true((
  select checks_left_this_hour = 0 and checks_left_today = 20
  from public.zyra_my_code_check_budget()
), 'link resolver and both previews share the hourly budget');
select pg_temp.assert_error(
  $$select from public.zyra_resolve_code_link('ZYRA-0000-0000-0000-0000-0003')$$,
  'too_many_code_checks'
);
select pg_temp.assert_error(
  $$select from public.zyra_preview_personal_code('ZYRA-0000-0000-0000-0000-0003')$$,
  'too_many_code_checks'
);
select pg_temp.assert_error(
  $$select from public.zyra_preview_match_code('ZYRA-0000-0000-0000-0000-0002')$$,
  'too_many_code_checks'
);

select pg_temp.sign_in('Tariq');
select pg_temp.assert_link('ZYRA-0000-0000-0000-0000-0001', 'add_seeker', 'Adam', 'seeker');
select pg_temp.assert_link('ZYRA-0000-0000-0000-0000-0044', 'unavailable');

reset role;
select pg_temp.assert_true(
  count(*) = 10 and count(*) filter (where succeeded) = 4,
  'Seeker outcomes and both existing previews record only eligible matches as successful'
)
from private.zyra_personal_code_attempts
where caller_id = (select id from code_actors where name = 'Adam');
select pg_temp.assert_true(
  count(*) = 2 and count(*) filter (where succeeded) = 1,
  'Guardian outcomes only record the eligible Seeker lookup as successful'
)
from private.zyra_personal_code_attempts
where caller_id = (select id from code_actors where name = 'Tariq');
select pg_temp.assert_true(
  not exists (
    select from private.zyra_personal_code_attempts
    where caller_id = (select id from code_actors where name = 'Malik')
  )
  and not exists (select from public.wali_invites)
  and not exists (select from public.wali_links)
  and not exists (select from public.likes),
  'verification failures do not charge and resolving a link creates no request, link or interest'
);

update private.zyra_personal_code_attempts set attempted_at = now() - interval '20 hours'
where caller_id = (select id from code_actors where name = 'Adam');
insert into private.zyra_personal_code_attempts (caller_id, attempted_at, succeeded)
select id, now() - interval '2 hours', false
from code_actors cross join generate_series(1, 19) where name = 'Adam';
set local role authenticated;
select pg_temp.sign_in('Adam');
select pg_temp.assert_link('ZYRA-0000-0000-0000-0000-0099', 'unavailable');
select pg_temp.assert_true((
  select checks_left_this_hour = 9 and checks_left_today = 0
  from public.zyra_my_code_check_budget()
), 'resolver charges the last daily slot');
select pg_temp.assert_error(
  $$select from public.zyra_resolve_code_link('ZYRA-0000-0000-0000-0000-0099')$$,
  'too_many_code_checks'
);
reset role;
select pg_temp.assert_true(count(*) = 30, 'daily limit rejected without writing an attempt')
from private.zyra_personal_code_attempts
where caller_id = (select id from code_actors where name = 'Adam');

rollback;
