-- ZYRA line 106 / DOC-ZYRA-0475 / OA-ZYRA-317 / Q137.
-- Run only on a disposable replay with the candidate installed.
\set ON_ERROR_STOP on
begin;
set local timezone = 'UTC';

do $$
begin
  if current_user <> 'postgres' or exists (select from auth.users) then
    raise exception 'Line 106 requires an empty disposable replay owned by postgres';
  end if;
end;
$$;

create temporary table actors (
  name text primary key,
  id uuid not null default gen_random_uuid(),
  profile_role text not null
);
insert into actors (name, profile_role)
values ('caller', 'seeker'), ('other', 'seeker'), ('target', 'wali');
grant select on actors to authenticated;

insert into auth.users (id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
select id, 'authenticated', 'authenticated', 'line106-' || name || '@zyra.test',
       '{}'::jsonb, '{}'::jsonb, now(), now()
from actors;
insert into public.profiles (
  id, role, first_name, date_of_birth, gender, location_text, bio, is_active, profile_complete
)
select id, profile_role, 'Fixture', date '1985-01-01', 'male', 'Test',
       'Synthetic code-check actor.', true, false
from actors;
insert into private.identity_verification_attempts (
  user_id, provider_code, provider_session_ref, result, duplicate_review_required,
  provider_event_ref_hash, consent_granted, consent_version, decided_at
)
select id, 'stripe', 'line106-' || name, 'verified', false,
       md5(id::text) || md5(id::text), true, 'line106_fixture', now()
from actors;
insert into private.zyra_personal_codes (owner_id, role_context, code)
select id, profile_role, case name
    when 'target' then 'ZYRA-0000-0000-0000-0000-0001'
    else 'ZYRA-0000-0000-0000-0000-0002' end
from actors where name in ('target', 'other');

create function pg_temp.assert_true(p_ok boolean, p_label text) returns void
language plpgsql as $$
begin
  if p_ok is distinct from true then raise exception 'Line 106 FAIL: %', p_label; end if;
  raise notice 'Line 106 PASS: %', p_label;
end;
$$;

create function pg_temp.sign_in(p_name text) returns text
language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', id, 'role', 'authenticated')::text, true)
  from actors where name = p_name;
$$;

create function pg_temp.assert_limit(p_statement text) returns void
language plpgsql as $$
begin
  begin
    execute p_statement;
  exception when raise_exception then
    if sqlerrm = 'too_many_code_checks' then return; end if;
    raise;
  end;
  raise exception 'Expected too_many_code_checks';
end;
$$;

select pg_temp.assert_true(
  has_function_privilege('authenticated', 'public.zyra_my_code_check_budget()', 'EXECUTE')
  and not has_function_privilege('anon', 'public.zyra_my_code_check_budget()', 'EXECUTE')
  and not has_function_privilege('service_role', 'public.zyra_my_code_check_budget()', 'EXECUTE')
  and not has_table_privilege('authenticated', 'private.zyra_personal_code_attempts', 'SELECT'),
  'only authenticated callers have the budget RPC; attempt rows remain private'
);

set local role authenticated;
do $$
begin
  begin
    perform public.zyra_my_code_check_budget();
    raise exception 'missing JWT accepted';
  exception when raise_exception then
    if sqlerrm <> 'not_signed_in' then raise; end if;
  end;
end;
$$;
select pg_temp.sign_in('caller');
select pg_temp.assert_true((
  select checks_left_this_hour = 10 and checks_left_today = 30 and next_check_at is null
  from public.zyra_my_code_check_budget()
), 'fresh caller has the full budget');

do $$
declare
  unknown_code constant text := 'ZYRA-0000-0000-0000-0000-0099';
begin
  for i in 1..4 loop
    perform pg_temp.assert_true(
      not exists (select from public.zyra_preview_personal_code(unknown_code)),
      'unknown personal code is empty below the limit'
    );
  end loop;
  for i in 1..3 loop
    perform pg_temp.assert_true(
      not exists (select from public.zyra_preview_match_code(unknown_code)),
      'unknown match code is empty below the limit'
    );
    perform pg_temp.assert_true(
      public.zyra_consider_match_code(unknown_code) is null,
      'unknown Consider code is empty below the limit'
    );
  end loop;
end;
$$;

select pg_temp.assert_true((
  select checks_left_this_hour = 0 and checks_left_today = 20 and next_check_at is not null
  from public.zyra_my_code_check_budget()
), 'all three routes share one hourly budget');
do $$
declare
  code text;
begin
  foreach code in array array[
    'ZYRA-0000-0000-0000-0000-0001', 'ZYRA-0000-0000-0000-0000-0002',
    'ZYRA-0000-0000-0000-0000-0099', 'malformed'
  ] loop
    perform pg_temp.assert_limit(format('select from public.zyra_preview_personal_code(%L)', code));
    perform pg_temp.assert_limit(format('select from public.zyra_preview_match_code(%L)', code));
    perform pg_temp.assert_limit(format('select public.zyra_consider_match_code(%L)', code));
    perform pg_temp.assert_limit(format('select public.zyra_request_guardian_link(%L)', code));
  end loop;
  raise notice 'Line 106 PASS: 11th hourly check and retries give the same error for all code inputs and routes';
end;
$$;

reset role;
select pg_temp.assert_true((
  select next_check_at =
    (select min(attempted_at) from private.zyra_personal_code_attempts
     where caller_id = (select id from actors where name = 'caller'))
    + interval '1 hour 1 microsecond'
  from public.zyra_my_code_check_budget()
), 'hourly retry time matches the first attempt');
select pg_temp.assert_true(
  count(*) = 10 and bool_and(not succeeded),
  'hourly rejections did not store attempts'
) from private.zyra_personal_code_attempts where caller_id = (select id from actors where name = 'caller');
set local role authenticated;
select pg_temp.sign_in('other');
select pg_temp.assert_true((
  select checks_left_this_hour = 10 and checks_left_today = 30 and next_check_at is null
  from public.zyra_my_code_check_budget()
), 'another account has its own full budget while the caller is blocked');
select pg_temp.assert_true(
  not exists (select from public.zyra_preview_personal_code('invalid')),
  'another account can still check a wrong code'
);

reset role;
-- Age the caller's first ten attempts, and seed 19 more from earlier hours.
-- Keep the new final slot free so the RPC itself records the 30th attempt.
update private.zyra_personal_code_attempts
set attempted_at = now() - interval '20 hours'
where caller_id = (select id from actors where name = 'caller');
insert into private.zyra_personal_code_attempts (caller_id, attempted_at, succeeded)
select id, now() - interval '2 hours', false from actors cross join generate_series(1, 19)
where name = 'caller';

set local role authenticated;
select pg_temp.sign_in('caller');
select pg_temp.assert_true((
  select checks_left_this_hour = 10 and checks_left_today = 1 and next_check_at is null
  from public.zyra_my_code_check_budget()
), 'one daily check remains after hourly window reopens');
select pg_temp.assert_true(
  not exists (select from public.zyra_preview_match_code('ZYRA-0000-0000-0000-0000-0099')),
  'the 30th daily check is still accepted'
);
select pg_temp.assert_true((
  select checks_left_this_hour = 9 and checks_left_today = 0
    and next_check_at = now() + interval '4 hours 1 microsecond'
  from public.zyra_my_code_check_budget()
), 'daily cap supplies exact next time even though hourly checks remain');
select pg_temp.assert_limit($sql$select public.zyra_consider_match_code('ZYRA-0000-0000-0000-0000-0002')$sql$);
select pg_temp.assert_limit($sql$select public.zyra_consider_match_code('ZYRA-0000-0000-0000-0000-0099')$sql$);
select pg_temp.assert_true(true, '31st daily check raises the same error for known and unknown codes');

reset role;
select pg_temp.assert_true(
  count(*) = 30, 'daily rejections did not store attempts'
) from private.zyra_personal_code_attempts where caller_id = (select id from actors where name = 'caller');

-- Both caps reached, with the hourly cap the later one to release.
with ranked as (
  select id, row_number() over (order by id) as n
  from private.zyra_personal_code_attempts where caller_id = (select id from actors where name = 'caller')
)
update private.zyra_personal_code_attempts a
set attempted_at = now() - case
  when ranked.n <= 10 then interval '5 minutes'
  else interval '23 hours 55 minutes' end
from ranked where a.id = ranked.id;
set local role authenticated;
select pg_temp.sign_in('caller');
select pg_temp.assert_true((
  select checks_left_this_hour = 0 and checks_left_today = 0
    and next_check_at = now() + interval '55 minutes 1 microsecond'
  from public.zyra_my_code_check_budget()
), 'when both limits are reached the later release time wins');
select pg_temp.sign_in('other');
select pg_temp.assert_true((
  select checks_left_this_hour = 9 and checks_left_today = 29 and next_check_at is null
  from public.zyra_my_code_check_budget()
), 'the second account is charged only for its own check');
rollback;
