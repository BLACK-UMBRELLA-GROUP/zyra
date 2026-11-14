-- Line 110 / Question 142. Exercise retained restart and unlock behavior on
-- the production baseline. Every actor, balance and Journey rolls back.
\set ON_ERROR_STOP on
begin;
\ir fixtures/server0_v2_full_schema_prestate.sql

grant select on server0_v2_fixture_actors to authenticated;
create temporary table held_test_state (name text primary key, id uuid not null);
grant select on held_test_state to authenticated;

create function pg_temp.actor(p_label text) returns uuid
language sql stable security invoker as $$
  select id from server0_v2_fixture_actors where fixture_label = p_label;
$$;
create function pg_temp.entry(p_name text) returns uuid
language sql stable security invoker as $$
  select id from held_test_state where name = p_name;
$$;
create function pg_temp.check_result(p_ok boolean, p_label text) returns void
language plpgsql security invoker as $$
begin
  if p_ok is distinct from true then
    raise exception 'Line 110 held behavior failed: %', p_label;
  end if;
end;
$$;
create function pg_temp.expect_rejection(p_sql text, p_error text) returns void
language plpgsql security invoker as $$
begin
  begin
    execute p_sql;
  exception when others then
    if sqlstate = p_error or sqlerrm = p_error then return; end if;
    raise;
  end;
  raise exception 'Expected rejection % for %', p_error, p_sql;
end;
$$;
create function pg_temp.sign_in(p_label text) returns void
language sql security invoker as $$
  select set_config('request.jwt.claims', json_build_object(
    'sub', pg_temp.actor(p_label), 'role', 'authenticated')::text, true);
$$;
grant execute on function pg_temp.actor(text), pg_temp.entry(text),
  pg_temp.check_result(boolean, text), pg_temp.expect_rejection(text, text),
  pg_temp.sign_in(text) to authenticated;

insert into public.wali_links (seeker_id, wali_id, status, is_main, relationship)
values (pg_temp.actor('fem1'), pg_temp.actor('gb'), 'active', true, 'father');
update public.subscriptions set plan_type = 'seeker_premium' where user_id = pg_temp.actor('male1');

with ended as (
  insert into public.matches (seeker_a_id, seeker_b_id, status, journey_stage, ended_at)
  values (least(pg_temp.actor('male1'), pg_temp.actor('fem1')),
          greatest(pg_temp.actor('male1'), pg_temp.actor('fem1')),
          'ended', 'conversation', now() - interval '23 hours')
  returning id
)
insert into held_test_state select 'match', id from ended;
insert into held_test_state
select 'old_attempt', id from public.journey_attempts where match_id = pg_temp.entry('match');
update public.journey_attempts
set started_at = now() - interval '30 days', ended_at = now() - interval '23 hours',
    ended_by = pg_temp.actor('male1'), end_reason = 'not_compatible'
where id = pg_temp.entry('old_attempt');
insert into public.conversations (match_id, attempt_id, status, closed_at)
values (pg_temp.entry('match'), pg_temp.entry('old_attempt'), 'closed', now() - interval '23 hours');
insert into public.timelines (match_id, attempt_id)
values (pg_temp.entry('match'), pg_temp.entry('old_attempt'));
insert into public.journey_salams (match_id, seeker_id, attempt_id, sent_at)
values (pg_temp.entry('match'), pg_temp.actor('male1'), pg_temp.entry('old_attempt'),
        now() - interval '29 days');

set local role authenticated;
select pg_temp.sign_in('male1');
select pg_temp.check_result(not public.zyra_may_request_new_journey(pg_temp.entry('match')),
  'eligible member must wait 24 hours');
select pg_temp.expect_rejection(
  format('select public.request_new_journey(%L)', pg_temp.entry('match')), '42501');
select pg_temp.expect_rejection(
  'select public.respond_to_journey_request(gen_random_uuid(), ''accept'')', '42501');
select pg_temp.expect_rejection(
  format('select public.restart_journey(%L)', pg_temp.entry('match')),
  'restart_requires_mutual_consent');
select pg_temp.expect_rejection(format(
  'insert into public.journey_requests (match_id, requested_by, requested_to, expires_at)
   values (%L, auth.uid(), %L, now() + interval ''30 days'')',
  pg_temp.entry('match'), pg_temp.actor('fem1')), '42501');
reset role;

update public.matches set ended_at = now() - interval '25 hours' where id = pg_temp.entry('match');
update public.journey_attempts set ended_at = now() - interval '25 hours'
where id = pg_temp.entry('old_attempt');
set local role authenticated;
select pg_temp.sign_in('male1');
select pg_temp.check_result(public.zyra_may_request_new_journey(pg_temp.entry('match')),
  'One member can see availability after 24 hours');
select pg_temp.sign_in('fem1');
select pg_temp.check_result(not public.zyra_may_request_new_journey(pg_temp.entry('match')),
  'Basic member cannot initiate a restart');
select pg_temp.sign_in('male2');
select pg_temp.check_result(not public.zyra_may_request_new_journey(pg_temp.entry('match')),
  'outsider cannot see restart availability');
reset role;

-- Owner exercises the held preparation bodies as the fixture actors while
-- the member EXECUTE grants stay revoked.
select pg_temp.sign_in('male1');
select pg_temp.expect_rejection(format(
  'insert into public.journey_requests (match_id, requested_by, requested_to, expires_at)
   values (%L, auth.uid(), %L, now() + interval ''7 days'')',
  pg_temp.entry('match'), pg_temp.actor('fem1')), 'restart_expiry_must_be_thirty_days');
insert into held_test_state
values ('request', public.request_new_journey(pg_temp.entry('match')));
select pg_temp.check_result(exists (
  select from public.journey_requests
  where id = pg_temp.entry('request') and requested_by = pg_temp.actor('male1')
    and requested_to = pg_temp.actor('fem1') and expires_at = now() + interval '30 days'
    and status = 'pending' and attempt_id is null
), 'held preparation creates a caller-bound request with the current deadline');
select pg_temp.check_result(
  public.zyra_active_journey_count(pg_temp.actor('male1')) = 0
  and public.zyra_active_journey_count(pg_temp.actor('fem1')) = 0,
  'pending request consumes no active place');
select pg_temp.sign_in('fem1');
select pg_temp.check_result(
  public.respond_to_journey_request(pg_temp.entry('request'), 'accept') = 'accepted',
  'intended Basic recipient with capacity can accept in the held body');
select pg_temp.check_result(exists (
  select from public.journey_requests r
  join public.journey_attempts a on a.id = r.attempt_id
  where r.id = pg_temp.entry('request') and r.status = 'accepted'
    and a.match_id = pg_temp.entry('match') and a.id <> pg_temp.entry('old_attempt')
    and a.status = 'active' and a.journey_stage = 'salam_exchange' and a.attempt_number = 2
) and exists (
  select from public.journey_attempts a
  join public.journey_salams s on s.attempt_id = a.id
  where a.id = pg_temp.entry('old_attempt') and a.status = 'ended'
    and s.seeker_id = pg_temp.actor('male1')
), 'held acceptance prepares a distinct attempt and retains the ended history');

-- Build a credit balance in this transaction through ordinary ledger rows.
insert into public.unlock_credits (user_id, tier, delta, reason)
values (pg_temp.actor('male2'), 'paid_single', 1, 'adjustment'),
       (pg_temp.actor('male2'), 'paid_plus_single', 1, 'adjustment');
set local role authenticated;
select pg_temp.sign_in('male2');
do $$
declare
  held jsonb;
  purchase jsonb;
  replay jsonb;
begin
  held := public.zyra_unlock_profile(pg_temp.actor('fem2'), 'paid_plus_single');
  perform pg_temp.check_result(held->>'status' = 'plus_unavailable' and held->>'charged' = 'false',
    'held Plus cannot mint an entitlement even with credit');
  purchase := public.zyra_unlock_profile(pg_temp.actor('fem2'), 'paid_single');
  replay := public.zyra_unlock_profile(pg_temp.actor('fem2'), 'paid_single');
  perform pg_temp.check_result(purchase->>'status' = 'unlocked'
    and purchase->>'charged' = 'true' and purchase->>'balance' = '0'
    and purchase->>'operation_id' is not null,
    'Standard purchase spends one credit and produces a receipt');
  perform pg_temp.check_result(replay->>'status' = 'already_unlocked'
    and replay->>'charged' = 'false' and replay->>'operation_id' = purchase->>'operation_id',
    'retry reuses the receipt and does not spend again');
end;
$$;
select pg_temp.sign_in('gmain');
select pg_temp.expect_rejection(format(
  'select public.zyra_unlock_profile(%L, ''paid_single'')', pg_temp.actor('male1')), '42501');
reset role;
select pg_temp.check_result(
  (select count(*) = 1 from public.profile_unlocks where unlocker_id = pg_temp.actor('male2'))
  and (select count(*) = 1 from public.unlock_credits where user_id = pg_temp.actor('male2') and delta = -1)
  and (select count(*) = 1 from private.zyra_unlock_operations where unlocker_id = pg_temp.actor('male2')),
  'only one entitlement, debit and operation survive a retry');
rollback;
