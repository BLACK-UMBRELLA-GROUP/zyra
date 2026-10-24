\set ON_ERROR_STOP on
do $guard$ begin
  if current_database() !~ '^zyra_oa151_synthetic_[a-z0-9_]+$'
    or current_setting('zyra.oa151_local_replay',true) is distinct from 'enabled'
    or current_user<>'postgres' or session_user<>'postgres' then raise exception 'OA151 race assertions isolation refused'; end if;
end; $guard$;
select oa151_synthetic.assert_true((select count(*)=1 from oa151_kernel.requests
  where recipient_id='00000000-0000-0000-0000-00000000a201' and status='accepted'),
  'Basic racing accepts exactly one reservation');
select oa151_synthetic.assert_true((select r.status='pending' from oa151_kernel.requests r
  join oa151_synthetic.race_requests x on x.request_id=r.id where x.name='basic_b'),
  'Basic refused request remains pending, no orphan acceptance');
select oa151_synthetic.assert_true((select count(*)=3 and bool_and(proved) from oa151_synthetic.race_outcomes
  where name in('basic_b_refused','actual_basic_lock_wait','other_completed_while_a_held')),
  'actual independent-session wait, denial and unrelated throughput observed');
begin;
select set_config('oa151.test.request',(select request_id::text from oa151_synthetic.race_requests where name='basic_a'),true);
select set_config('oa151.test.deadline',(select reservation_expires_at::text from oa151_kernel.requests
  where id=current_setting('oa151.test.request')::uuid),true);
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a202',true);
select oa151_synthetic.assert_true(oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a201','00000000-0000-0000-0000-00000000d201')::text
  =current_setting('oa151.test.request'),'lost acknowledgement replay after committed race acceptance');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a201',true);
select oa151_synthetic.assert_true(oa151_kernel.accept_request(current_setting('oa151.test.request')::uuid)='accepted',
  'committed acceptance replay stays accepted');
reset role;
select oa151_synthetic.assert_true((select reservation_expires_at::text=current_setting('oa151.test.deadline')
  from oa151_kernel.requests where id=current_setting('oa151.test.request')::uuid),'committed replay cannot extend deadline');
commit;
select oa151_synthetic.assert_true(oa151_synthetic.canonical_fingerprint()=(select fingerprint from oa151_synthetic.baseline),
  'true acceptance race preserves canonical fixtures');
do $$ begin raise notice 'OA151 PASS: true Basic race final count and committed idempotent replay'; end; $$;

