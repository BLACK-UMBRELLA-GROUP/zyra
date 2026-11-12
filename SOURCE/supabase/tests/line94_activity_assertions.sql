-- OA-ZYRA-317 / DOC-ZYRA-0473 V4 / Q124, Q127 and Q133: disposable inactivity regression.
\set ON_ERROR_STOP on
begin;

do $$
begin
  if current_user <> 'postgres'
     or current_database() !~ '^zyra_(server0_v2_line94|line94v3_)[a-z0-9_]*$'
     or exists (select from auth.users) then
    raise exception 'Line 94 activity assertions require an empty disposable replay owned by postgres';
  end if;
end;
$$;

create temporary table activity_actor (name text primary key, id uuid not null default gen_random_uuid());
insert into activity_actor (name) values ('inactive'), ('returns'), ('active'), ('recent'), ('no_history'), ('removed'), ('leap'), ('late'), ('active_partner');
create temporary table activity_pair (
  name text primary key,
  match_id uuid not null default gen_random_uuid(),
  attempt_id uuid,
  first_actor text not null,
  second_actor text not null
);
insert into activity_pair (name, first_actor, second_actor) values
  ('remove', 'inactive', 'active'), ('keep', 'returns', 'active'),
  ('too_recent', 'recent', 'active'), ('already_removed', 'removed', 'active'),
  ('leap_archive', 'leap', 'active'), ('still_active', 'inactive', 'active_partner');
grant select on activity_actor, activity_pair to authenticated;

create function pg_temp.activity_user(p_name text) returns uuid language sql stable as $$
  select id from activity_actor where name = p_name;
$$;
create function pg_temp.activity_attempt(p_name text) returns uuid language sql stable as $$
  select attempt_id from activity_pair where name = p_name;
$$;
create function pg_temp.activity_sign_in(p_name text) returns text language sql as $$
  select set_config('request.jwt.claims',
    json_build_object('sub', pg_temp.activity_user(p_name), 'role', 'authenticated')::text,
    true);
$$;
create function pg_temp.activity_assert(p_ok boolean, p_label text) returns void language plpgsql as $$
begin
  if p_ok is distinct from true then raise exception 'Line 94 activity FAIL: %', p_label; end if;
  raise notice 'Line 94 activity PASS: %', p_label;
end;
$$;
create function pg_temp.activity_deny(p_sql text, p_label text) returns void language plpgsql as $$
begin
  begin
    execute p_sql;
  exception when insufficient_privilege then
    raise notice 'Line 94 activity PASS: %', p_label;
    return;
  end;
  raise exception 'Line 94 activity unexpectedly allowed: %', p_label;
end;
$$;
grant execute on function pg_temp.activity_user(text), pg_temp.activity_attempt(text),
  pg_temp.activity_sign_in(text), pg_temp.activity_assert(boolean, text),
  pg_temp.activity_deny(text, text) to authenticated;
grant execute on function pg_temp.activity_deny(text, text) to anon;

create function pg_temp.activity_anniversary()
returns timestamptz language sql immutable as $$
  select timestamptz '2026-11-12 12:00:00+00';
$$;

insert into auth.users (id, aud, role, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
select id, 'authenticated', 'authenticated', 'line94-activity-' || name || '@zyra.test',
       '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()
from activity_actor;
insert into public.profiles (
  id, role, first_name, date_of_birth, gender, location_text, is_active, profile_complete, last_active_at
)
select id, 'seeker', initcap(replace(name, '_', ' ')), date '1980-01-01',
  case when name in ('active', 'active_partner') then 'female' else 'male' end,
  'Test', true, false,
  case name
    when 'active' then pg_temp.activity_anniversary() - interval '1 day'
    when 'active_partner' then pg_temp.activity_anniversary() - interval '1 day'
    when 'recent' then pg_temp.activity_anniversary() - interval '2 years' + interval '1 microsecond'
    when 'leap' then timestamptz '2024-02-29 12:00:00+00'
    when 'late' then pg_temp.activity_anniversary() - interval '3 years'
    else pg_temp.activity_anniversary() - interval '2 years'
  end
from activity_actor;

insert into public.subscriptions (user_id, plan_type, status)
select id, 'seeker_basic', 'active' from activity_actor where name in ('inactive', 'active_partner');

insert into public.matches (id, seeker_a_id, seeker_b_id, status, journey_stage, ended_at)
select match_id,
  least(pg_temp.activity_user(first_actor), pg_temp.activity_user(second_actor)),
  greatest(pg_temp.activity_user(first_actor), pg_temp.activity_user(second_actor)),
  case when name = 'still_active' then 'active' else 'ended' end,
  'conversation',
  case when name <> 'still_active' then pg_temp.activity_anniversary() - interval '2 years' end
from activity_pair;
update activity_pair pair set attempt_id = a.id
from public.journey_attempts a where a.match_id = pair.match_id;
update public.journey_attempts set started_at = pg_temp.activity_anniversary() - interval '3 years',
  ended_at = pg_temp.activity_anniversary() - interval '2 years', end_reason = 'not_compatible'
where id in (select attempt_id from activity_pair where name <> 'still_active');
insert into public.timelines (match_id, attempt_id)
select match_id, attempt_id from activity_pair on conflict do nothing;
set local role authenticated;
select pg_temp.activity_sign_in('removed');
select public.zyra_remove_ended_journey(pg_temp.activity_attempt('already_removed'));
reset role;
insert into public.profile_blocks (blocker_id, blocked_id)
values (pg_temp.activity_user('active'), pg_temp.activity_user('inactive'));

set local role anon;
select pg_temp.activity_deny('select public.zyra_touch_activity()', 'anonymous touch denied');
select pg_temp.activity_deny('select public.zyra_my_inactivity_notice()', 'anonymous notice read denied');
select pg_temp.activity_deny('select public.zyra_my_welcome_back()', 'anonymous Welcome back read denied');
select pg_temp.activity_deny('select * from public.email_outbox', 'anonymous outbox read denied');
reset role;
set local role authenticated;
select pg_temp.activity_sign_in('active');
select pg_temp.activity_deny('select public.zyra_run_inactivity_job()', 'members cannot run the job');
select pg_temp.activity_deny('select last_active_at from public.profiles', 'activity column is private');
select pg_temp.activity_deny(
  'update public.profiles set last_active_at = now() where id = auth.uid()',
  'members cannot write their activity column directly');
select pg_temp.activity_deny(
  'insert into public.zyra_inactivity_notices (user_id, warned_at, removal_due_at) values (auth.uid(), now(), now())',
  'members cannot manufacture a notice');
select pg_temp.activity_deny('select * from public.email_outbox', 'members cannot read queued email variables');
select set_config('request.jwt.claims', '{"role":"authenticated"}', true);
select pg_temp.activity_deny('select public.zyra_touch_activity()', 'touch requires a signed-in subject');
reset role;
set local role service_role;
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
select pg_temp.activity_deny(
  'select private.zyra_run_inactivity_job_at(now())',
  'service role cannot choose the production job clock');
select pg_temp.activity_assert((select count(*) = 0 from public.email_outbox), 'service role can read the outbox');
reset role;

select private.zyra_run_inactivity_job_at(timestamptz '2026-02-14 11:59:59.999999+00');
select pg_temp.activity_assert(not exists (select from public.zyra_inactivity_notices),
  'a leap-day account does not warn before its exact calendar boundary');
set local timezone = 'America/New_York';
select private.zyra_run_inactivity_job_at(timestamptz '2026-02-14 12:00:00+00');
select pg_temp.activity_assert((
  select warned_at = timestamptz '2026-02-14 12:00:00+00'
     and removal_due_at = timestamptz '2026-03-14 12:00:00+00'
  from public.zyra_inactivity_notices where user_id = pg_temp.activity_user('leap')
), 'leap day uses the February 28 anniversary and fixed UTC offsets across DST');
set local timezone = 'UTC';

select private.zyra_run_inactivity_job_at(pg_temp.activity_anniversary() - interval '14 days 0.000001 seconds');
select pg_temp.activity_assert(not exists (
  select from public.zyra_inactivity_notices
  where user_id <> pg_temp.activity_user('leap')
), 'notice is closed one microsecond before the opening boundary');

select private.zyra_run_inactivity_job_at(pg_temp.activity_anniversary() - interval '14 days');
select private.zyra_run_inactivity_job_at(pg_temp.activity_anniversary() - interval '14 days');
select pg_temp.activity_assert((
  select count(*) = 2 and bool_and(
    warned_at = pg_temp.activity_anniversary() - interval '14 days'
    and removal_due_at = pg_temp.activity_anniversary() + interval '14 days'
  )
  from public.zyra_inactivity_notices
  where user_id in (pg_temp.activity_user('inactive'), pg_temp.activity_user('returns'))
), 'eligible accounts warn exactly at two years minus 14 days');
select pg_temp.activity_assert(not exists (
  select from public.zyra_inactivity_notices
  where user_id in (
    pg_temp.activity_user('active'), pg_temp.activity_user('recent'), pg_temp.activity_user('no_history'),
    pg_temp.activity_user('removed'), pg_temp.activity_user('late')
  )
), 'recent activity, no ended attempts, and own archived copies already removed do not warn');
select pg_temp.activity_assert((
  select count(*) = 2 and count(distinct user_id) = 2 from public.notifications
  where type = 'inactivity_warning'
), 'running the job again creates no duplicate warning items');
select pg_temp.activity_assert((
  select array_agg(due_at order by template_key) = array[
    pg_temp.activity_anniversary() - interval '14 days',
    pg_temp.activity_anniversary() - interval '7 days',
    pg_temp.activity_anniversary(),
    pg_temp.activity_anniversary() + interval '7 days'
  ] and bool_and(sent_at is null and cancelled_at is null)
  from public.email_outbox where user_id = pg_temp.activity_user('inactive')
), 'four unsent reminders carry exact -14, -7, 0 and +7 days before completion is available');
select pg_temp.activity_assert((
  select count(*) = 4 and bool_and(variables =
    '{"first_name":"Inactive","ended_journeys":1,"removal_date":"2026-11-26"}'::jsonb)
  from public.email_outbox where user_id = pg_temp.activity_user('inactive')
), 'only first name, ended count and removal date are stored in email variables');
select pg_temp.activity_assert(not exists (
  select from public.email_outbox where user_id in (
    pg_temp.activity_user('no_history'), pg_temp.activity_user('removed')
  )
), 'accounts without a remaining ended copy get no outbox rows');

set local role authenticated;
select pg_temp.activity_sign_in('inactive');
select pg_temp.activity_assert((
  select ended_journeys = 1 and removal_due_at = pg_temp.activity_anniversary() + interval '14 days'
  from public.zyra_my_inactivity_notice()
), 'owner gets deadline and remaining ended count even during a transient block');
select pg_temp.activity_assert((select count(*) = 1 from public.zyra_inactivity_notices),
  'direct notice reads are owner scoped');
select pg_temp.activity_assert(not public.zyra_my_welcome_back(), 'an open notice has no Welcome back flag');
select pg_temp.activity_sign_in('active');
select pg_temp.activity_assert(not exists (select from public.zyra_my_inactivity_notice()),
  'an active member cannot read another notice');
select pg_temp.activity_assert(not exists (
  select from public.notifications where type = 'inactivity_warning'
), 'warning notification is visible only to its owner');
reset role;

update public.email_outbox set sent_at = due_at
where user_id = pg_temp.activity_user('returns') and template_key = 'inactivity_1';
set local role authenticated;
select pg_temp.activity_sign_in('returns');
select public.zyra_touch_activity();
select pg_temp.activity_assert(not exists (select from public.zyra_my_inactivity_notice()),
  'returning before removal clears the open notice');
select pg_temp.activity_assert(not exists (
  select from public.notifications where type = 'inactivity_warning'
), 'returning clears the old warning signal');
select pg_temp.activity_assert(public.zyra_my_welcome_back(), 'a return opens the Welcome back flag');
select pg_temp.activity_assert(not public.zyra_my_welcome_back(), 'reading the flag consumes it once');
select public.zyra_touch_activity();
select pg_temp.activity_assert(not public.zyra_my_welcome_back(), 'repeated activity does not rearm Welcome back');
reset role;
select pg_temp.activity_assert((
  select count(*) filter (where sent_at is not null and cancelled_at is null) = 1
     and count(*) filter (where sent_at is null and cancelled_at is not null) = 3
  from public.email_outbox where user_id = pg_temp.activity_user('returns')
), 'return cancels unsent reminders and leaves the sent reminder untouched');
select pg_temp.activity_assert((
  select last_active_at = now() from public.profiles where id = pg_temp.activity_user('returns')
), 'touch records the returning member activity');
select pg_temp.activity_assert((
  select last_active_at = pg_temp.activity_anniversary() - interval '2 years'
  from public.profiles where id = pg_temp.activity_user('inactive')
), 'touch leaves another member clock unchanged');
update public.profiles set last_active_at = date_trunc('day', now(), 'UTC')
where id = pg_temp.activity_user('returns');
set local role authenticated;
select pg_temp.activity_sign_in('returns');
select public.zyra_touch_activity();
reset role;
select pg_temp.activity_assert((
  select last_active_at = date_trunc('day', now(), 'UTC')
  from public.profiles where id = pg_temp.activity_user('returns')
), 'second touch on the UTC calendar day does not rewrite activity');

select private.zyra_run_inactivity_job_at(pg_temp.activity_anniversary() + interval '13 days 23:59:59.999999');
select pg_temp.activity_assert(not exists (
  select from private.zyra_ended_journey_removals where attempt_id = pg_temp.activity_attempt('remove')
), 'no attempt is removed one microsecond before the deadline');
select pg_temp.activity_assert(not exists (
  select from public.email_outbox where user_id = pg_temp.activity_user('inactive') and template_key = 'inactivity_5'
), 'no completion email is available before removal');

-- This account acquires an ended copy after its notice window already lapsed.
insert into public.matches (seeker_a_id, seeker_b_id, status, journey_stage, ended_at)
values (
  least(pg_temp.activity_user('active'), pg_temp.activity_user('late')),
  greatest(pg_temp.activity_user('active'), pg_temp.activity_user('late')),
  'ended', 'conversation', pg_temp.activity_anniversary()
);
select private.zyra_run_inactivity_job_at(pg_temp.activity_anniversary() + interval '14 days');
select private.zyra_run_inactivity_job_at(pg_temp.activity_anniversary() + interval '14 days');
select pg_temp.activity_assert((
  select case when m.seeker_a_id = pg_temp.activity_user('inactive')
    then r.seeker_a_removed_at is not null and r.seeker_b_removed_at is null
    else r.seeker_b_removed_at is not null and r.seeker_a_removed_at is null end
  from private.zyra_ended_journey_removals r
  join public.journey_attempts a on a.id = r.attempt_id
  join public.matches m on m.id = a.match_id
  where r.attempt_id = pg_temp.activity_attempt('remove')
), 'at two years plus 14 days only the inactive participant archive copy is removed');
select pg_temp.activity_assert(exists (
  select from public.timelines where attempt_id = pg_temp.activity_attempt('remove')
), 'the counterpart still retains their copy and Timeline');
select pg_temp.activity_assert(exists (
  select from public.journey_attempts where id = pg_temp.activity_attempt('still_active') and status = 'active'
), 'the same inactive participant active Journey is untouched');
select pg_temp.activity_assert((
  select count(*) = 1 and bool_and(due_at = pg_temp.activity_anniversary() + interval '14 days'
    and sent_at is null and cancelled_at is null and (variables->>'ended_journeys')::integer = 1)
  from public.email_outbox where user_id = pg_temp.activity_user('inactive') and template_key = 'inactivity_5'
), 'removal makes one fifth email available with the correct due date and actual removal count');
select pg_temp.activity_assert((
  select count(*) filter (where cancelled_at is not null and template_key <> 'inactivity_5') = 4
     and count(*) filter (where template_key = 'inactivity_5' and cancelled_at is null
          and due_at = pg_temp.activity_anniversary() - interval '1 year' + interval '14 days') = 1
  from public.email_outbox where user_id = pg_temp.activity_user('late')
), 'late discovery keeps planned dates and cancels superseded unsent reminders');
select pg_temp.activity_assert(not exists (
  select from public.notifications where user_id = pg_temp.activity_user('late') and type = 'inactivity_warning'
), 'late removal does not create a stale My ZYRA notice');
select pg_temp.activity_assert(not exists (
  select from private.zyra_ended_journey_removals where attempt_id = pg_temp.activity_attempt('keep')
), 'the returned member keeps their ended attempt');
select pg_temp.activity_assert(not exists (
  select from public.email_outbox where user_id = pg_temp.activity_user('returns') and template_key = 'inactivity_5'
), 'a return prevents the fifth email from being queued');
select pg_temp.activity_assert(not exists (
  select from private.zyra_ended_journey_removals where attempt_id = pg_temp.activity_attempt('too_recent')
), 'one microsecond shy of the later deadline is still too soon');

set local role authenticated;
select pg_temp.activity_sign_in('inactive');
select pg_temp.activity_assert(not exists (select from public.zyra_my_inactivity_notice()),
  'completed removal closes the notice');
select public.zyra_touch_activity();
select pg_temp.activity_assert(not public.zyra_my_welcome_back(), 'return after removal does not show Welcome back');
select pg_temp.activity_sign_in('active');
select public.zyra_remove_ended_journey(pg_temp.activity_attempt('remove'));
reset role;
select pg_temp.activity_assert(not exists (
  select from public.timelines where attempt_id = pg_temp.activity_attempt('remove')
), 'the counterpart removal still purges the shared Timeline data');
select pg_temp.activity_assert(exists (
  select from public.timelines where attempt_id = pg_temp.activity_attempt('keep')
), 'the separate ended attempt remains intact');

set local role service_role;
select public.zyra_run_inactivity_job();
reset role;
select pg_temp.activity_assert(true, 'service role can invoke the production wrapper with the server clock');

rollback;
