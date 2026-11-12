-- OA-ZYRA-317 / DOC-ZYRA-0473 / queue line 94, focused timer assertions.
-- Run on a fresh disposable full replay. Optionally pass
-- -v line94_migration=/absolute/path/to/migration.sql on a fresh pre-line-94
-- replay to commit synthetic old rows before applying the candidate once.
\set ON_ERROR_STOP on
begin;

do $$
begin
  if current_user <> 'postgres' or exists (select from auth.users) then
    raise exception 'Line 94 tests require an empty disposable replay owned by postgres';
  end if;
end;
$$;

create temporary table line94_actors (
  name text primary key,
  id uuid not null default gen_random_uuid(),
  profile_role text not null
);
insert into line94_actors (name, profile_role) values
  ('seeker_old', 'seeker'), ('seeker_new', 'seeker'), ('code_owner', 'wali'),
  ('trial_original', 'wali'), ('trial_replacement', 'wali');
create temporary table line94_state (
  name text primary key,
  id uuid,
  expires_at timestamptz,
  request_expires_at timestamptz,
  code text
);
grant select on line94_actors, line94_state to authenticated, service_role;
grant insert, update on line94_state to authenticated, service_role;

create function pg_temp.line94_actor(p_name text) returns uuid
language sql stable security invoker as $$
  select id from line94_actors where name = p_name;
$$;
create function pg_temp.line94_id(p_name text) returns uuid
language sql stable security invoker as $$
  select id from line94_state where name = p_name;
$$;
create function pg_temp.line94_assert(p_ok boolean, p_label text) returns void
language plpgsql security invoker as $$
begin
  if p_ok is distinct from true then raise exception 'Line 94 FAIL: %', p_label; end if;
  raise notice 'Line 94 PASS: %', p_label;
end;
$$;
create function pg_temp.line94_reject(p_sql text, p_error text, p_label text) returns void
language plpgsql security invoker as $$
begin
  begin
    execute p_sql;
  exception when others then
    if sqlstate <> p_error and sqlerrm <> p_error then
      raise exception 'Line 94 wrong rejection for %: % / %', p_label, sqlstate, sqlerrm;
    end if;
    raise notice 'Line 94 PASS: %', p_label;
    return;
  end;
  raise exception 'Line 94 unexpectedly allowed: %', p_label;
end;
$$;
create function pg_temp.line94_sign_in(p_name text) returns text
language sql security invoker as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', pg_temp.line94_actor(p_name), 'role', 'authenticated')::text,
    true);
$$;
grant execute on function pg_temp.line94_actor(text), pg_temp.line94_id(text),
  pg_temp.line94_sign_in(text), pg_temp.line94_assert(boolean, text),
  pg_temp.line94_reject(text, text, text) to authenticated, service_role;
grant execute on function pg_temp.line94_reject(text, text, text) to anon;

-- Shared Auth fixture columns work with the cached local runtime.
insert into auth.users (id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
select id, 'authenticated', 'authenticated', 'line94-' || name || '@zyra.test',
       '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()
from line94_actors;
insert into public.profiles (id, role, first_name, date_of_birth, gender, location_text, bio, is_active, profile_complete)
select id, profile_role, 'Fixture', date '1980-01-01', 'male', 'Test',
       'Synthetic line 94 timer fixture.', true, false
from line94_actors;
insert into private.identity_verification_attempts (
  user_id, provider_code, provider_session_ref, result, duplicate_review_required,
  provider_event_ref_hash, consent_granted, consent_version, decided_at
)
select id, 'stripe', 'line94-' || name, 'verified', false, md5(id::text) || md5(id::text),
       true, 'line94_fixture', now()
from line94_actors;

with people as (
  insert into private.verified_people (provider_code, provider_person_ref_hash)
  values ('stripe', repeat('1', 64)), ('stripe', repeat('2', 64))
  returning id, provider_person_ref_hash
)
insert into line94_state (name, id)
select case when provider_person_ref_hash = repeat('1', 64) then 'owner_person'
            else 'trial_person' end, id
from people;
insert into private.verified_person_accounts (verified_person_id, user_id, role) values
  (pg_temp.line94_id('owner_person'), pg_temp.line94_actor('seeker_old'), 'seeker'),
  (pg_temp.line94_id('trial_person'), pg_temp.line94_actor('trial_original'), 'guardian');

insert into public.subscriptions (user_id, plan_type, status)
values (pg_temp.line94_actor('seeker_old'), 'seeker_premium', 'active');
with new_family as (
  insert into public.family_subscriptions (owner_id, owner_role, status, seeker_places, guardian_places)
  values (pg_temp.line94_actor('seeker_old'), 'seeker', 'active', 1, 1)
  returning id
)
insert into line94_state (name, id) select 'family', id from new_family;
insert into public.family_seat_assignments (family_subscription_id, member_id, role)
values (pg_temp.line94_id('family'), pg_temp.line94_actor('seeker_old'), 'seeker');

-- A seven-day invitation is one day from expiry. A new row gets its new
-- default below. The sweep must continue to use this row's stored deadline.
with old_invite as (
  insert into public.wali_invites (inviter_id, inviter_role, created_at, expires_at)
  values (pg_temp.line94_actor('code_owner'), 'wali', now() - interval '6 days',
          now() + interval '1 day')
  returning id, expires_at
)
insert into line94_state (name, id, expires_at)
select 'old_invite', id, expires_at from old_invite;

set local role authenticated;
select pg_temp.line94_sign_in('code_owner');
insert into line94_state (name, code)
select 'personal_code', code from public.zyra_my_personal_code('wali');
reset role;

\if :{?line94_migration}
  -- Exercise the actual 30-day writer on the old schema. Keep both stored
  -- deadlines, which the historical function computed independently.
  set local role authenticated;
  select pg_temp.line94_sign_in('seeker_old');
  insert into line94_state (name, id)
  select 'old_code_request', public.zyra_request_guardian_link(code)
  from line94_state where name = 'personal_code';
  reset role;
  update line94_state expected
  set expires_at = wi.expires_at, request_expires_at = wi.request_expires_at
  from public.wali_invites wi
  where expected.name = 'old_code_request' and wi.id = expected.id;
  select pg_temp.line94_assert((
    select request_expires_at between now() + interval '30 days'
      and clock_timestamp() + interval '30 days'
    from line94_state where name = 'old_code_request'
  ), 'old code-request writer gives 30 days before migration');

  update public.subscriptions set billing_grace_started_at = now(),
    billing_grace_until = now() + interval '16 days'
  where user_id = pg_temp.line94_actor('seeker_old');
  update public.family_subscriptions set status = 'billing_grace',
    billing_grace_started_at = now(), billing_grace_until = now() + interval '16 days'
  where id = pg_temp.line94_id('family');
  commit;

  \i :line94_migration
  begin;
  select pg_temp.line94_assert((
    select s.billing_grace_until = s.billing_grace_started_at + interval '3 days'
    from public.subscriptions s where s.user_id = pg_temp.line94_actor('seeker_old')
  ), 'migration caps existing direct grace at three days');
  select pg_temp.line94_assert((
    select f.billing_grace_until = f.billing_grace_started_at + interval '3 days'
    from public.family_subscriptions f where f.id = pg_temp.line94_id('family')
  ), 'migration caps existing Family grace at three days');
  select pg_temp.line94_assert((
    select wi.expires_at = expected.expires_at
       and wi.request_expires_at = expected.request_expires_at
    from public.wali_invites wi
    join line94_state expected on wi.id = expected.id
    where expected.name = 'old_code_request'
  ), 'migration preserves both stored 30-day code-request deadlines');
\endif

select pg_temp.line94_assert((
  select wi.expires_at = expected.expires_at
     and wi.expires_at = wi.created_at + interval '7 days'
  from public.wali_invites wi join line94_state expected on wi.id = expected.id
  where expected.name = 'old_invite'
), 'legacy invitation keeps its stored seven-day deadline');

with new_invite as (
  insert into public.wali_invites (inviter_id, inviter_role)
  values (pg_temp.line94_actor('code_owner'), 'wali')
  returning id
)
insert into line94_state (name, id) select 'new_invite', id from new_invite;
select pg_temp.line94_assert((
  select expires_at = created_at + interval '14 days'
  from public.wali_invites where id = pg_temp.line94_id('new_invite')
), 'new Guardian invitation defaults to 14 days');

set local role authenticated;
select pg_temp.line94_sign_in('seeker_new');
select pg_temp.line94_reject(
  'insert into public.wali_invites (inviter_id, inviter_role) values (auth.uid(), ''seeker'')',
  '42501', 'authenticated direct invitation insert remains held');
insert into line94_state (name, id)
select 'new_code_request', public.zyra_request_guardian_link(code)
from line94_state where name = 'personal_code';
reset role;
select pg_temp.line94_assert((
  select expires_at = request_expires_at
     and expires_at = created_at + interval '14 days'
     and request_expires_at between now() + interval '14 days'
       and clock_timestamp() + interval '14 days'
  from public.wali_invites where id = pg_temp.line94_id('new_code_request')
), 'new code link request writes one common 14-day deadline');

-- Age the row independently of its recorded deadline to catch a sweep that
-- computes expiry from creation time instead of reading the stored clock.
update public.wali_invites set created_at = now() - interval '15 days'
where id = pg_temp.line94_id('new_code_request');
set local role authenticated;
select pg_temp.line94_sign_in('code_owner');
select pg_temp.line94_assert((
  select expiring_count = 1 and expired_count = 0 from public.zyra_expire_due_wali_invites()
), 'sweep warns using the legacy stored deadline and leaves the new code request pending');
reset role;
select pg_temp.line94_assert((
  select expiring_notified_at is not null from public.wali_invites
  where id = pg_temp.line94_id('old_invite')
), 'two-day warning belongs to the legacy invitation');
select pg_temp.line94_assert((
  select status = 'pending' and expiring_notified_at is null from public.wali_invites
  where id = pg_temp.line94_id('new_code_request')
), 'backdated creation does not override the stored code-request deadline');
update public.wali_invites set expires_at = now() - interval '1 second',
  request_expires_at = now() - interval '1 second'
where id = pg_temp.line94_id('new_code_request');
set local role authenticated;
select pg_temp.line94_sign_in('code_owner');
select pg_temp.line94_assert((
  select expiring_count = 0 and expired_count = 1 from public.zyra_expire_due_wali_invites()
), 'sweep expires a code request once the stored deadline has passed');
reset role;

update public.subscriptions set billing_grace_started_at = now(),
  billing_grace_until = now() + interval '3 days'
where user_id = pg_temp.line94_actor('seeker_old');
update public.family_subscriptions set status = 'billing_grace', billing_grace_started_at = now(),
  billing_grace_until = now() + interval '3 days'
where id = pg_temp.line94_id('family');
select pg_temp.line94_assert((
  select billing_grace_until = billing_grace_started_at + interval '3 days'
  from public.subscriptions where user_id = pg_temp.line94_actor('seeker_old')
), 'direct grace permits exactly three days');
select pg_temp.line94_assert((
  select billing_grace_until = billing_grace_started_at + interval '3 days'
  from public.family_subscriptions where id = pg_temp.line94_id('family')
), 'Family grace permits exactly three days');
select pg_temp.line94_reject($statement$
  update public.subscriptions set billing_grace_until = billing_grace_until + interval '1 microsecond'
  where user_id = pg_temp.line94_actor('seeker_old')
$statement$, '23514', 'direct grace rejects more than three days');
select pg_temp.line94_reject($statement$
  update public.family_subscriptions set billing_grace_until = billing_grace_until + interval '1 microsecond'
  where id = pg_temp.line94_id('family')
$statement$, '23514', 'Family grace rejects more than three days');

set local role anon;
select pg_temp.line94_reject(
  'select public.zyra_start_verified_guardian_trial(gen_random_uuid(), gen_random_uuid())',
  '42501', 'anonymous caller cannot start the Guardian trial');
reset role;
set local role authenticated;
select pg_temp.line94_sign_in('trial_original');
select pg_temp.line94_reject(
  'select public.zyra_start_verified_guardian_trial(auth.uid(), gen_random_uuid())',
  '42501', 'Guardian client cannot start the trial');
select pg_temp.line94_reject('select from private.guardian_trial_ledger',
  '42501', 'Guardian client cannot read the trial ledger');
reset role;

-- A bad role binding on an otherwise valid Seeker still cannot start a
-- Guardian trial. The actual account role has to agree with the binding.
insert into private.verified_person_accounts (verified_person_id, user_id, role)
values (pg_temp.line94_id('owner_person'), pg_temp.line94_actor('seeker_old'), 'guardian');
set local role service_role;
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
select pg_temp.line94_reject($statement$
  select public.zyra_start_verified_guardian_trial(
    pg_temp.line94_actor('seeker_old'), pg_temp.line94_id('owner_person'))
$statement$, 'verified_guardian_binding_required', 'Seeker with a Guardian binding cannot start the Guardian trial');
select pg_temp.line94_reject($statement$
  select public.zyra_start_verified_guardian_trial(
    pg_temp.line94_actor('trial_replacement'), pg_temp.line94_id('trial_person'))
$statement$, 'verified_guardian_binding_required', 'verified Guardian without matching person binding cannot start the trial');
insert into line94_state (name, expires_at)
values ('trial_result', public.zyra_start_verified_guardian_trial(
  pg_temp.line94_actor('trial_original'), pg_temp.line94_id('trial_person')));
select pg_temp.line94_reject($statement$
  select public.zyra_start_verified_guardian_trial(
    pg_temp.line94_actor('trial_original'), pg_temp.line94_id('trial_person'))
$statement$, 'guardian_trial_already_used', 'same Guardian account cannot repeat the trial');
reset role;
select pg_temp.line94_assert((
  select l.claimed_by = pg_temp.line94_actor('trial_original')
     and l.ends_at = l.started_at + interval '14 days'
     and l.ends_at = r.expires_at
  from private.guardian_trial_ledger l cross join line94_state r
  where l.verified_person_id = pg_temp.line94_id('trial_person') and r.name = 'trial_result'
), 'Guardian trial lasts exactly 14 days and returns its end time');

select set_config('request.jwt.claims', '{}', true);
delete from auth.users where id = pg_temp.line94_actor('trial_original');
insert into private.verified_person_accounts (verified_person_id, user_id, role)
values (pg_temp.line94_id('trial_person'), pg_temp.line94_actor('trial_replacement'), 'guardian');
set local role service_role;
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
select pg_temp.line94_reject($statement$
  select public.zyra_start_verified_guardian_trial(
    pg_temp.line94_actor('trial_replacement'), pg_temp.line94_id('trial_person'))
$statement$, 'guardian_trial_already_used', 'replacement account cannot repeat the same verified person trial');
reset role;
select pg_temp.line94_assert((
  select claimed_by is null and started_at is null and ends_at is null
  from private.guardian_trial_ledger where verified_person_id = pg_temp.line94_id('trial_person')
), 'account removal clears the account link and preserves the verified-person claim');

rollback;
