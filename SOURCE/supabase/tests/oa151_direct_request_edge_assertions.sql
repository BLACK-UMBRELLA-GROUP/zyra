-- Additional fake-only deny/revalidation edges, after functional and races.
-- Every scenario rolls back; no production adapter, receipt or bridge claim.
\set ON_ERROR_STOP on
do $guard$ begin
  if current_database() !~ '^zyra_oa151_synthetic_[a-z0-9_]+$'
    or current_setting('zyra.oa151_local_replay',true) is distinct from 'enabled'
    or current_user<>'postgres' or session_user<>'postgres' then
    raise exception 'OA151 edge assertions isolation refused';
  end if;
end; $guard$;

begin;
set local statement_timeout='15s';
set local role authenticated;
do $helpers$
declare p record; args text;
begin
  for p in select f.* from pg_proc f join pg_namespace n on n.oid=f.pronamespace
    where n.nspname='oa151_kernel' and f.proname not in
      ('send_request','cancel_request','decline_request','accept_request','mark_ready','inbox','available_to_browse') loop
    select coalesce(string_agg('null::'||format_type(a,null),',' order by ordinal),'')
      into args from unnest(p.proargtypes::oid[]) with ordinality x(a,ordinal);
    perform oa151_synthetic.expect_error(
      format('select oa151_kernel.%I(%s)',p.proname,args),'permission denied');
  end loop;
end; $helpers$;
reset role;
set local role service_role;
do $service$
declare p record; args text; refused boolean;
begin
  for p in select f.* from pg_proc f join pg_namespace n on n.oid=f.pronamespace
    where n.nspname='oa151_kernel' loop
    select coalesce(string_agg('null::'||format_type(a,null),',' order by ordinal),'')
      into args from unnest(p.proargtypes::oid[]) with ordinality x(a,ordinal);
    refused:=false;
    begin
      execute format('select oa151_kernel.%I(%s)',p.proname,args);
    exception when insufficient_privilege then refused:=true;
    end;
    if not refused then raise exception 'OA151 service_role executed %',p.proname; end if;
  end loop;
end; $service$;
reset role;
do $$ begin raise notice 'OA151 PASS: actual private-helper and service_role EXECUTE denials'; end; $$;
rollback;

begin;
update oa151_kernel.policy set request_ttl=interval '1 hour',request_limit=8,
  reservation_ttl=interval '2 hours' where singleton;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a101',true);
select set_config('oa151.test.edge',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a102','00000000-0000-0000-0000-00000000e101')::text,true);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a102',true);
select oa151_synthetic.expect_error(
  $$select oa151_kernel.cancel_request(current_setting('oa151.test.edge')::uuid)$$,'oa151_not_requester');
select oa151_synthetic.assert_true(oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a101','00000000-0000-0000-0000-00000000e102')::text
    =current_setting('oa151.test.edge'),'reverse sender operation has stable own replay');
select oa151_synthetic.expect_error(
  $$select oa151_kernel.send_request('00000000-0000-0000-0000-00000000a103','00000000-0000-0000-0000-00000000e102')$$,
  'oa151_idempotency_target_mismatch');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a108',true);
select oa151_synthetic.expect_error(
  $$select oa151_kernel.decline_request(current_setting('oa151.test.edge')::uuid)$$,'oa151_request_not_found');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a102',true);
select oa151_synthetic.assert_true(oa151_kernel.accept_request(current_setting('oa151.test.edge')::uuid)='accepted',
  'recipient alone accepts');
select oa151_synthetic.assert_true(not oa151_kernel.available_to_browse('00000000-0000-0000-0000-00000000a103'),
  'recipient Basic capacity full');
select oa151_synthetic.assert_true(oa151_kernel.decline_request(current_setting('oa151.test.edge')::uuid)='declined',
  'recipient decline terminates accepted reservation');
select oa151_synthetic.assert_true(oa151_kernel.available_to_browse('00000000-0000-0000-0000-00000000a101'),
  'accepted decline frees both Basic capacities');
reset role;
select oa151_synthetic.assert_true((select bridge_token is null and requester_ready_at is null
  and recipient_ready_at is null from oa151_kernel.requests
  where id=current_setting('oa151.test.edge')::uuid),'decline clears readiness/token');
do $$ begin raise notice 'OA151 PASS: recipient/stranger ownership, reverse replay binding and accepted decline cleanup'; end; $$;
rollback;

begin;
update oa151_kernel.policy set request_ttl=interval '1 hour',request_limit=8,
  reservation_ttl=interval '2 hours' where singleton;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a101',true);
select set_config('oa151.test.edge',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a102','00000000-0000-0000-0000-00000000e111')::text,true);
reset role;
update oa151_kernel.policy set request_ttl=null where singleton;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a102',true);
select oa151_synthetic.expect_error(
  $$select oa151_kernel.accept_request(current_setting('oa151.test.edge')::uuid)$$,'oa151_policy_unconfigured');
reset role;
update oa151_kernel.policy set request_ttl=interval '1 hour' where singleton;
set local role authenticated;
select oa151_kernel.accept_request(current_setting('oa151.test.edge')::uuid);
reset role;
update oa151_kernel.policy set reservation_ttl=null where singleton;
set local role authenticated;
select oa151_synthetic.expect_error(
  $$select oa151_kernel.accept_request(current_setting('oa151.test.edge')::uuid)$$,'oa151_policy_unconfigured');
select oa151_synthetic.expect_error(
  $$select oa151_kernel.mark_ready(current_setting('oa151.test.edge')::uuid)$$,'oa151_policy_unconfigured');
select oa151_synthetic.assert_true(not oa151_kernel.available_to_browse('00000000-0000-0000-0000-00000000a103'),
  'NULL policy cannot advertise sendable availability');
select oa151_synthetic.assert_true((select count(*)=1 from oa151_kernel.inbox()),
  'NULL policy still permits participant inbox');
select oa151_synthetic.assert_true(oa151_kernel.decline_request(current_setting('oa151.test.edge')::uuid)='declined',
  'NULL policy still permits recipient cleanup');
reset role;
do $$ begin raise notice 'OA151 PASS: missing policy holds accept/ready/browse, not inbox/cleanup'; end; $$;
rollback;

begin;
update oa151_kernel.policy set request_ttl=interval '1 hour',request_limit=8,
  reservation_ttl=interval '2 hours' where singleton;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a103',true);
select set_config('oa151.test.edge',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a104','00000000-0000-0000-0000-00000000e121')::text,true);
select set_config('oa151.test.edge2',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a110','00000000-0000-0000-0000-00000000e122')::text,true);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a104',true);
select oa151_kernel.accept_request(current_setting('oa151.test.edge')::uuid);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a110',true);
select oa151_kernel.accept_request(current_setting('oa151.test.edge2')::uuid);
reset role;
update oa151_synthetic.funded_receipts set membership='basic'
  where user_id='00000000-0000-0000-0000-00000000a103';
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a104',true);
select oa151_synthetic.expect_error(
  $$select oa151_kernel.mark_ready(current_setting('oa151.test.edge')::uuid)$$,'oa151_capacity_unavailable');
select oa151_synthetic.assert_true(oa151_kernel.decline_request(current_setting('oa151.test.edge')::uuid)='declined',
  'downgraded capacity allows recipient cleanup');
reset role;
update oa151_synthetic.funded_receipts set trusted_fake_proof=false
  where user_id='00000000-0000-0000-0000-00000000a103';
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a110',true);
select oa151_synthetic.expect_error(
  $$select oa151_kernel.mark_ready(current_setting('oa151.test.edge2')::uuid)$$,'oa151_not_available');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a103',true);
select oa151_synthetic.assert_true(oa151_kernel.cancel_request(current_setting('oa151.test.edge2')::uuid)='cancelled',
  'lost proof allows sender cleanup');
reset role;
do $$ begin raise notice 'OA151 PASS: accepted cap downgrade and receipt loss deny ready; cleanup remains possible'; end; $$;
rollback;

begin;
update oa151_kernel.policy set request_ttl=interval '1 hour',request_limit=8,
  reservation_ttl=interval '2 hours' where singleton;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a101',true);
select set_config('oa151.test.edge',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a102','00000000-0000-0000-0000-00000000e131')::text,true);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a102',true);
select oa151_kernel.accept_request(current_setting('oa151.test.edge')::uuid);
reset role;
insert into oa151_synthetic.pair_denials values(
  '00000000-0000-0000-0000-00000000a101','00000000-0000-0000-0000-00000000a102','synthetic_new_block');
set local role authenticated;
select oa151_synthetic.expect_error(
  $$select oa151_kernel.mark_ready(current_setting('oa151.test.edge')::uuid)$$,'oa151_not_available');
select oa151_synthetic.assert_true(oa151_kernel.decline_request(current_setting('oa151.test.edge')::uuid)='declined',
  'blocked accepted reservation still permits recipient cleanup');
reset role;
do $$ begin raise notice 'OA151 PASS: new pair block after acceptance denies ready without trapping cleanup'; end; $$;
rollback;

begin;
update oa151_kernel.policy set request_ttl=interval '1 hour',request_limit=8,
  reservation_ttl=interval '2 hours' where singleton;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a101',true);
select set_config('oa151.test.edge',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a102','00000000-0000-0000-0000-00000000e141')::text,true);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a102',true);
select oa151_kernel.accept_request(current_setting('oa151.test.edge')::uuid);
select oa151_kernel.mark_ready(current_setting('oa151.test.edge')::uuid);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a101',true);
select oa151_synthetic.assert_true((select ready_to_bridge and bridge_token is not null
  from oa151_kernel.mark_ready(current_setting('oa151.test.edge')::uuid)),
  'both independently ready issue a synthetic stable token');
reset role;
update oa151_kernel.requests set accepted_at=clock_timestamp()-interval '2 hours',
  reservation_expires_at=clock_timestamp()-interval '1 second'
  where id=current_setting('oa151.test.edge')::uuid;
set local role authenticated;
select oa151_synthetic.assert_true((select status='reservation_expired'
  and bridge_token is null and not self_ready and not other_ready from oa151_kernel.inbox()
  where request_id=current_setting('oa151.test.edge')::uuid),
  'expired inbox hides previously issued token and readiness');
select oa151_synthetic.assert_true((select not ready_to_bridge and bridge_token is null
  from oa151_kernel.mark_ready(current_setting('oa151.test.edge')::uuid)),
  'expired ready cannot reissue token');
reset role;
select oa151_synthetic.assert_true((select status='reservation_expired' and bridge_token is null
  and requester_ready_at is null and recipient_ready_at is null from oa151_kernel.requests
  where id=current_setting('oa151.test.edge')::uuid),'expiry persists token/readiness deletion');
select oa151_synthetic.assert_true(oa151_synthetic.canonical_fingerprint()=(select fingerprint
  from oa151_synthetic.baseline),'no canonical chat/attempt/profile/Guardian mutation from readiness/expiry');
do $$ begin raise notice 'OA151 PASS: expiry hides and clears formerly issued token; no canonical bridge writes'; end; $$;
rollback;
select oa151_synthetic.assert_true((select request_ttl is null and request_limit is null
  and reservation_ttl is null from oa151_kernel.policy where singleton),
  'edge test rollback leaves all product policy unselected');
select oa151_synthetic.assert_true(oa151_synthetic.canonical_fingerprint()=(select fingerprint
  from oa151_synthetic.baseline),'all edge fixtures rolled back and canonical baseline unchanged');
