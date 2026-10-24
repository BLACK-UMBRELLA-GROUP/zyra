-- Fake-actor SQL/ACL assertions; not REST/Auth/provider or production acceptance.
\set ON_ERROR_STOP on
do $guard$ begin
  if current_database() !~ '^zyra_oa151_synthetic_[a-z0-9_]+$'
    or current_setting('zyra.oa151_local_replay',true) is distinct from 'enabled'
    or current_user<>'postgres' or session_user<>'postgres' then
    raise exception 'OA151 assertions isolation refused';
  end if;
end; $guard$;
begin;
set local statement_timeout='15s';
select oa151_synthetic.assert_true(
  oa151_synthetic.journey_cap('00000000-0000-0000-0000-00000000a101')=1
  and oa151_synthetic.journey_cap('00000000-0000-0000-0000-00000000a103')=3
  and oa151_synthetic.journey_cap('00000000-0000-0000-0000-00000000a105')=3
  and oa151_synthetic.journey_cap('00000000-0000-0000-0000-00000000a106')=0,
  'fake trusted Basic/One/Family proof authority 1/3/3; no proof zero');
select oa151_synthetic.assert_true(
  oa151_synthetic.existing_occupancy('00000000-0000-0000-0000-00000000a111')=1
  and oa151_synthetic.existing_occupancy('00000000-0000-0000-0000-00000000a112')=2
  and oa151_synthetic.existing_occupancy('00000000-0000-0000-0000-00000000a113')=3
  and oa151_synthetic.existing_occupancy('00000000-0000-0000-0000-00000000a114')=1,
  'reconstructed occupancy counts pending pause, excludes settled pause');
do $acl$
declare signature text; t text;
begin
  foreach signature in array array[
    'oa151_kernel.send_request(uuid,uuid)','oa151_kernel.cancel_request(uuid)',
    'oa151_kernel.decline_request(uuid)','oa151_kernel.accept_request(uuid)',
    'oa151_kernel.mark_ready(uuid)','oa151_kernel.inbox()',
    'oa151_kernel.available_to_browse(uuid)'] loop
    perform oa151_synthetic.assert_true(
      has_function_privilege('authenticated',signature,'execute')
      and not has_function_privilege('anon',signature,'execute'), 'API ACL '||signature);
  end loop;
  foreach t in array array['oa151_kernel.requests','oa151_kernel.policy',
    'oa151_kernel.account_revisions','oa151_kernel.send_replays'] loop
    perform oa151_synthetic.assert_true(
      not has_table_privilege('authenticated',t,'select,insert,update,delete')
      and not has_table_privilege('anon',t,'select,insert,update,delete'), 'raw table ACL '||t);
  end loop;
  raise notice 'OA151 PASS: dedicated RPC ACLs; private raw rows inaccessible';
end; $acl$;
-- Bounded PostgreSQL catalog lint ONLY: not Supabase advisors, REST or Gateway.
do $catalog_lint$
declare
  p record; t record; granted_count integer:=0; public_now text;
  allowed oid[]:=array[
    'oa151_kernel.send_request(uuid,uuid)'::regprocedure::oid,
    'oa151_kernel.cancel_request(uuid)'::regprocedure::oid,
    'oa151_kernel.decline_request(uuid)'::regprocedure::oid,
    'oa151_kernel.accept_request(uuid)'::regprocedure::oid,
    'oa151_kernel.mark_ready(uuid)'::regprocedure::oid,
    'oa151_kernel.inbox()'::regprocedure::oid,
    'oa151_kernel.available_to_browse(uuid)'::regprocedure::oid];
begin
  perform oa151_synthetic.assert_true(
    to_regnamespace('oa151_kernel') is not null
      and to_regnamespace('oa151_kernel')<>to_regnamespace('public'),
    'candidate isolated from public API schema');
  for p in select f.* from pg_proc f join pg_namespace n on n.oid=f.pronamespace
    where n.nspname='oa151_kernel' loop
    perform oa151_synthetic.assert_true(p.prosecdef and pg_get_userbyid(p.proowner)='postgres',
      'all candidate functions privileged owner and SECURITY DEFINER '||p.proname);
    perform oa151_synthetic.assert_true((select count(*)=1 from unnest(p.proconfig) config
      where config like 'search_path=%'
        and trim(both '"' from substring(config from length('search_path=')+1))=''),
      'every candidate function has explicitly empty search_path '||p.proname);
    perform oa151_synthetic.assert_true(
      not exists(select 1 from aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
        where a.grantee=0 and a.privilege_type='EXECUTE')
      and not has_function_privilege('anon',p.oid,'execute')
      and not has_function_privilege('service_role',p.oid,'execute'),
      'no PUBLIC/anon/service_role candidate execute '||p.proname);
    perform oa151_synthetic.assert_true(
      has_function_privilege('authenticated',p.oid,'execute')=(p.oid=any(allowed)),
      'authenticated executes exact documented interface, never helpers '||p.proname);
    if has_function_privilege('authenticated',p.oid,'execute') then
      granted_count:=granted_count+1;
    end if;
  end loop;
  perform oa151_synthetic.assert_true(granted_count=7,'exactly seven authenticated candidate APIs');
  perform oa151_synthetic.assert_true((select count(*)=4 from pg_class c
    join pg_namespace n on n.oid=c.relnamespace where n.nspname='oa151_kernel'
      and c.relkind in('r','p')),'exactly four private candidate tables');
  for t in select c.* from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='oa151_kernel' and c.relkind in('r','p') loop
    perform oa151_synthetic.assert_true(t.relrowsecurity
      and not has_table_privilege('authenticated',t.oid,'select,insert,update,delete,truncate,references,trigger')
      and not has_table_privilege('anon',t.oid,'select,insert,update,delete,truncate,references,trigger')
      and not has_table_privilege('service_role',t.oid,'select,insert,update,delete,truncate,references,trigger')
      and not exists(select 1 from aclexplode(coalesce(t.relacl,acldefault('r',t.relowner))) a
        where a.grantee=0), 'RLS and no client raw table privileges '||t.relname);
  end loop;
  select md5(coalesce(jsonb_agg(jsonb_build_object(
    'signature',fn.oid::regprocedure::text,'definition',pg_get_functiondef(fn.oid),
    'acl',fn.proacl::text,'owner',fn.proowner,'config',fn.proconfig)
    order by fn.oid)::text,'[]')) into public_now
    from pg_proc fn join pg_namespace n on n.oid=fn.pronamespace
    where n.nspname='public' and fn.prokind='f';
  perform oa151_synthetic.assert_true(public_now=(select public_functions_fingerprint
    from oa151_synthetic.baseline),'existing public function definitions/ACLs/owners unchanged');
  raise notice 'OA151 PASS: bounded SQL catalog security lint; no Supabase advisor/API claim';
end; $catalog_lint$;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a101',true);
select oa151_synthetic.expect_error(
  $$select oa151_kernel.send_request('00000000-0000-0000-0000-00000000a102','00000000-0000-0000-0000-00000000d101')$$,
  'oa151_policy_unconfigured');
reset role;
-- Explicit test policy, not a selected Founder product policy or live default.
update oa151_kernel.policy set request_ttl=interval '1 hour',request_limit=5,
  reservation_ttl=interval '2 hours' where singleton;
set local role authenticated;
select set_config('request.jwt.claim.sub','',true);
select oa151_synthetic.expect_error(
  $$select oa151_kernel.send_request('00000000-0000-0000-0000-00000000a102','00000000-0000-0000-0000-00000000d101')$$,
  'oa151_not_signed_in');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a101',true);
select oa151_synthetic.expect_error(
  $$select oa151_kernel.send_request('00000000-0000-0000-0000-00000000a101','00000000-0000-0000-0000-00000000d101')$$,
  'oa151_self_request');
select oa151_synthetic.expect_error(
  $$select oa151_kernel.send_request(null,'00000000-0000-0000-0000-00000000d101')$$,'oa151_invalid_request');
select oa151_synthetic.expect_error(
  $$select oa151_kernel.send_request('00000000-0000-0000-0000-00000000a102',null)$$,'oa151_invalid_request');
do $denials$
declare target text;
begin
  foreach target in array array['106','107','109','130','131'] loop
    perform oa151_synthetic.expect_error(format(
      'select oa151_kernel.send_request(%L::uuid,%L::uuid)',
      '00000000-0000-0000-0000-00000000a'||target,
      '00000000-0000-0000-0000-00000000d'||target),'oa151_not_available');
  end loop;
  raise notice 'OA151 PASS: null/self/Guardian/unadmitted/unfunded/pair-denied requests refused';
end; $denials$;
do $caller_denials$
declare actor text;
begin
  foreach actor in array array['106','107','109'] loop
    perform set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a'||actor,true);
    perform oa151_synthetic.expect_error(
      $$select oa151_kernel.send_request('00000000-0000-0000-0000-00000000a103','00000000-0000-0000-0000-00000000d195')$$,
      'oa151_not_available');
  end loop;
  perform set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a101',true);
  raise notice 'OA151 PASS: caller admission/role/funding rechecked, null target/key refused';
end; $caller_denials$;
select set_config('oa151.test.request',
  oa151_kernel.send_request('00000000-0000-0000-0000-00000000a102',
    '00000000-0000-0000-0000-00000000d101')::text,true);
select oa151_synthetic.assert_true(
  oa151_kernel.send_request('00000000-0000-0000-0000-00000000a102',
    '00000000-0000-0000-0000-00000000d101')::text=current_setting('oa151.test.request'),
  'lost-ack exact replay returns same request');
select oa151_synthetic.expect_error(
  $$select oa151_kernel.send_request('00000000-0000-0000-0000-00000000a104','00000000-0000-0000-0000-00000000d101')$$,
  'oa151_idempotency_target_mismatch');
select oa151_synthetic.assert_true((select count(*)=1 from oa151_kernel.inbox()),'sender inbox exactly one pending');
select oa151_synthetic.expect_error(
  $$select oa151_kernel.accept_request(current_setting('oa151.test.request')::uuid)$$,'oa151_not_recipient');
select oa151_synthetic.expect_error(
  $$select oa151_kernel.decline_request(current_setting('oa151.test.request')::uuid)$$,'oa151_not_recipient');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a108',true);
select oa151_synthetic.assert_true((select count(*)=0 from oa151_kernel.inbox()),'stranger inbox empty');
select oa151_synthetic.expect_error(
  $$select oa151_kernel.accept_request(current_setting('oa151.test.request')::uuid)$$,'oa151_request_not_found');
select oa151_synthetic.expect_error(
  $$select oa151_kernel.cancel_request(current_setting('oa151.test.request')::uuid)$$,'oa151_request_not_found');
select oa151_synthetic.expect_error(
  $$select oa151_kernel.mark_ready(current_setting('oa151.test.request')::uuid)$$,'oa151_request_not_found');
select oa151_synthetic.expect_error($$select * from oa151_kernel.requests$$,'permission denied');
select oa151_synthetic.expect_error($$update oa151_kernel.policy set request_limit=999$$,'permission denied');
select oa151_synthetic.expect_error($$delete from public.matches$$,'permission denied');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a102',true);
select oa151_synthetic.assert_true(oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a101','00000000-0000-0000-0000-00000000d192')::text
  =current_setting('oa151.test.request'),'reverse send resolves same pair, not acceptance');
reset role;
select oa151_synthetic.assert_true((select status='pending' from oa151_kernel.requests
  where id=current_setting('oa151.test.request')::uuid),'reverse send remains pending');
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a101',true);
select oa151_kernel.cancel_request(current_setting('oa151.test.request')::uuid);
reset role;
select oa151_synthetic.assert_true((select status='cancelled' from oa151_kernel.requests
  where id=current_setting('oa151.test.request')::uuid),'sender cancel terminal');
do $$ begin raise notice 'OA151 PASS: request ownership, caller inbox, idempotency and private-write denial'; end; $$;
rollback;

-- All policies below are test-only choices, rolled back at completion.
begin;
update oa151_kernel.policy set request_ttl=interval '1 hour',request_limit=5,
  reservation_ttl=interval '2 hours' where singleton;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a103',true);
select set_config('oa151.test.request',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a104','00000000-0000-0000-0000-00000000d103')::text,true);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a104',true);
select oa151_kernel.decline_request(current_setting('oa151.test.request')::uuid);
reset role;
select oa151_synthetic.assert_true((select status='declined' from oa151_kernel.requests
  where id=current_setting('oa151.test.request')::uuid),'recipient decline terminal');
set local role authenticated;
select oa151_synthetic.assert_true(oa151_kernel.accept_request(current_setting('oa151.test.request')::uuid)='declined',
  'declined replay does not resurrect');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a101',true);
select set_config('oa151.test.request',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a102','00000000-0000-0000-0000-00000000d102')::text,true);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a102',true);
select oa151_kernel.accept_request(current_setting('oa151.test.request')::uuid);
reset role;
select set_config('oa151.test.deadline',(select reservation_expires_at::text from oa151_kernel.requests
  where id=current_setting('oa151.test.request')::uuid),true);
set local role authenticated;
select oa151_synthetic.assert_true(oa151_kernel.accept_request(current_setting('oa151.test.request')::uuid)='accepted',
  'accepted replay returns accepted');
reset role;
select oa151_synthetic.assert_true((select reservation_expires_at::text=current_setting('oa151.test.deadline')
  from oa151_kernel.requests where id=current_setting('oa151.test.request')::uuid),
  'accepted replay does not extend reservation');
set local role authenticated;
select oa151_synthetic.assert_true(not oa151_kernel.available_to_browse(
  '00000000-0000-0000-0000-00000000a103'),'full Basic viewer unavailable to Browse');
select oa151_synthetic.assert_true((select not ready_to_bridge and bridge_token is null
  from oa151_kernel.mark_ready(current_setting('oa151.test.request')::uuid)),
  'recipient readiness alone grants no bridge');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a101',true);
select oa151_synthetic.assert_true((select ready_to_bridge and bridge_token is not null
  from oa151_kernel.mark_ready(current_setting('oa151.test.request')::uuid)),
  'both independent readiness produces only bridge token');
select set_config('oa151.test.bridge',(select bridge_token::text
  from oa151_kernel.mark_ready(current_setting('oa151.test.request')::uuid)),true);
select oa151_synthetic.assert_true((select bridge_token::text=current_setting('oa151.test.bridge')
  from oa151_kernel.mark_ready(current_setting('oa151.test.request')::uuid)),
  'readiness replay token stable');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a108',true);
select oa151_synthetic.assert_true(not oa151_kernel.available_to_browse(
  '00000000-0000-0000-0000-00000000a102'),'full Basic target unavailable to Browse');
select oa151_synthetic.assert_true(oa151_kernel.available_to_browse(
  '00000000-0000-0000-0000-00000000a104'),'available admitted opposite-gender target browsable');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a110',true);
select oa151_synthetic.assert_true(not oa151_kernel.available_to_browse(
  '00000000-0000-0000-0000-00000000a113'),'full One target unavailable to Browse');
select oa151_synthetic.assert_true(oa151_kernel.available_to_browse(
  '00000000-0000-0000-0000-00000000a112'),'monthly target with only two occupied places stays browsable');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a111',true);
select oa151_synthetic.assert_true((select count(*)=1 from public.matches),'existing full Basic match remains readable');
select oa151_synthetic.assert_true((select count(*)=1 from public.wali_links),'existing full Basic Guardian link remains readable');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a107',true);
select oa151_synthetic.assert_true((select count(*)=2 from public.wali_links),'linked Guardian read unaffected');
reset role;
select oa151_synthetic.assert_true((select count(*)=1 from oa151_kernel.requests where status='accepted'),
  'accepted reservation not duplicated');
select oa151_synthetic.assert_true(oa151_synthetic.canonical_fingerprint()=(select fingerprint from oa151_synthetic.baseline),
  'readiness cannot create/change match, attempt, Guardian, chat or timeline');
update public.profiles set admission_ready=false where id='00000000-0000-0000-0000-00000000a101';
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a101',true);
select oa151_synthetic.expect_error(
  $$select oa151_kernel.mark_ready(current_setting('oa151.test.request')::uuid)$$,'oa151_not_available');
select oa151_synthetic.assert_true(oa151_kernel.cancel_request(current_setting('oa151.test.request')::uuid)='cancelled',
  'admission loss cannot trap accepted sender cleanup');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a108',true);
select oa151_synthetic.assert_true(oa151_kernel.available_to_browse(
  '00000000-0000-0000-0000-00000000a102'),'accepted cancellation releases recipient Basic place');
reset role;
select oa151_synthetic.assert_true((select requester_ready_at is null and recipient_ready_at is null and bridge_token is null
  from oa151_kernel.requests where id=current_setting('oa151.test.request')::uuid),
  'cancel clears both readiness and bridge bookkeeping');
do $$ begin raise notice 'OA151 PASS: independent readiness, stable token, both Basic availability and canonical preservation'; end; $$;
rollback;

begin;
update oa151_kernel.policy set request_ttl=interval '1 hour',request_limit=5,
  reservation_ttl=interval '2 hours' where singleton;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a212',true);
select set_config('oa151.test.requester_late',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a211','00000000-0000-0000-0000-00000000d181')::text,true);
select set_config('oa151.test.requester_first',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a230','00000000-0000-0000-0000-00000000d182')::text,true);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a230',true);
select oa151_kernel.accept_request(current_setting('oa151.test.requester_first')::uuid);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a211',true);
select oa151_synthetic.expect_error(
  $$select oa151_kernel.accept_request(current_setting('oa151.test.requester_late')::uuid)$$,'oa151_capacity_unavailable');
select oa151_synthetic.assert_true(oa151_kernel.decline_request(current_setting('oa151.test.requester_late')::uuid)='declined',
  'recipient cleanup available even when requester full');
reset role;
select oa151_synthetic.assert_true((select count(*)=1 from oa151_kernel.requests where status='accepted'),
  'requester last-place recheck prevents second acceptance');
select oa151_synthetic.assert_true(oa151_synthetic.canonical_fingerprint()=(select fingerprint from oa151_synthetic.baseline),
  'requester cap recheck cannot mutate canonical flow');
do $$ begin raise notice 'OA151 PASS: requester cap rechecked after pending request; recipient cleanup remains available'; end; $$;
rollback;

begin;
update oa151_kernel.policy set request_ttl=interval '1 hour',request_limit=5,
  reservation_ttl=interval '2 hours' where singleton;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a112',true);
select set_config('oa151.test.request',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a104','00000000-0000-0000-0000-00000000d112')::text,true);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a104',true);
select oa151_kernel.accept_request(current_setting('oa151.test.request')::uuid);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a112',true);
select oa151_synthetic.assert_true(not oa151_kernel.available_to_browse(
  '00000000-0000-0000-0000-00000000a110'),'existing occupancy two plus reservation fills monthly third place');
select oa151_synthetic.expect_error(
  $$select oa151_kernel.send_request('00000000-0000-0000-0000-00000000a110','00000000-0000-0000-0000-00000000d113')$$,
  'oa151_capacity_unavailable');
reset role;
select oa151_synthetic.assert_true(oa151_synthetic.canonical_fingerprint()=(select fingerprint from oa151_synthetic.baseline),
  'active/pending-pause/settled-pause legacy records preserved');
do $$ begin raise notice 'OA151 PASS: monthly third-place reservation combines existing occupancy without legacy mutation'; end; $$;
rollback;

begin;
update oa151_kernel.policy set request_ttl=interval '1 hour',request_limit=5,
  reservation_ttl=interval '2 hours' where singleton;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a105',true);
select set_config('oa151.test.family1',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a104','00000000-0000-0000-0000-00000000d151')::text,true);
select set_config('oa151.test.family2',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a110','00000000-0000-0000-0000-00000000d152')::text,true);
select set_config('oa151.test.family3',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a119','00000000-0000-0000-0000-00000000d153')::text,true);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a104',true);
select oa151_kernel.accept_request(current_setting('oa151.test.family1')::uuid);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a110',true);
select oa151_kernel.accept_request(current_setting('oa151.test.family2')::uuid);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a119',true);
select oa151_kernel.accept_request(current_setting('oa151.test.family3')::uuid);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a105',true);
select oa151_synthetic.expect_error(
  $$select oa151_kernel.send_request('00000000-0000-0000-0000-00000000a102','00000000-0000-0000-0000-00000000d154')$$,
  'oa151_capacity_unavailable');
reset role;
select oa151_synthetic.assert_true((select count(*)=3 from oa151_kernel.requests where status='accepted'),
  'funded Family Seeker receives exactly three reservations');
do $$ begin raise notice 'OA151 PASS: fake funded Family three-place cap; no unlimited reservations'; end; $$;
rollback;

begin;
update oa151_kernel.policy set request_ttl=interval '1 hour',request_limit=5,
  reservation_ttl=interval '2 hours' where singleton;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a101',true);
select set_config('oa151.test.request',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a102','00000000-0000-0000-0000-00000000d161')::text,true);
reset role;
update oa151_kernel.requests set created_at=now()-interval '2 hours',request_expires_at=now()-interval '1 second'
  where id=current_setting('oa151.test.request')::uuid;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a102',true);
select oa151_synthetic.assert_true((select status='request_expired' from oa151_kernel.inbox()
  where request_id=current_setting('oa151.test.request')::uuid),'inbox projects expiry without leaking stale pending');
select oa151_synthetic.assert_true(oa151_kernel.accept_request(current_setting('oa151.test.request')::uuid)='request_expired',
  'expired request acceptance returns terminal expiry');
reset role;
select oa151_synthetic.assert_true((select status='request_expired' from oa151_kernel.requests
  where id=current_setting('oa151.test.request')::uuid),'pending expiry terminal');
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a103',true);
select set_config('oa151.test.request',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a104','00000000-0000-0000-0000-00000000d162')::text,true);
reset role;
update oa151_synthetic.funded_receipts set trusted_fake_proof=false
  where user_id='00000000-0000-0000-0000-00000000a103';
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a104',true);
select oa151_synthetic.expect_error(
  $$select oa151_kernel.accept_request(current_setting('oa151.test.request')::uuid)$$,'oa151_not_available');
reset role;
update oa151_synthetic.funded_receipts set trusted_fake_proof=true
  where user_id='00000000-0000-0000-0000-00000000a103';
set local role authenticated;
select oa151_kernel.accept_request(current_setting('oa151.test.request')::uuid);
reset role;
update oa151_kernel.requests set accepted_at=now()-interval '2 hours',reservation_expires_at=now()-interval '1 second'
  where id=current_setting('oa151.test.request')::uuid;
set local role authenticated;
select oa151_kernel.inbox();
select oa151_synthetic.assert_true((select not ready_to_bridge and bridge_token is null
  from oa151_kernel.mark_ready(current_setting('oa151.test.request')::uuid)),
  'expired reservation readiness returns no bridge');
reset role;
select oa151_synthetic.assert_true((select status='reservation_expired' and bridge_token is null
  from oa151_kernel.requests where id=current_setting('oa151.test.request')::uuid),'reservation expiry frees capacity/no bridge');
do $$ begin raise notice 'OA151 PASS: request/reservation expiry and acceptance entitlement recheck'; end; $$;
rollback;

begin;
update oa151_kernel.policy set request_ttl=interval '1 hour',request_limit=1,
  reservation_ttl=interval '2 hours' where singleton;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a103',true);
select oa151_kernel.send_request('00000000-0000-0000-0000-00000000a104','00000000-0000-0000-0000-00000000d171');
select oa151_synthetic.expect_error(
  $$select oa151_kernel.send_request('00000000-0000-0000-0000-00000000a110','00000000-0000-0000-0000-00000000d172')$$,
  'oa151_request_limit');
reset role;
do $$ begin raise notice 'OA151 PASS: test-only configured outstanding request limit'; end; $$;
rollback;

-- Ordinary/anonymous cannot select policy, forge receipts or access raw inbox.
begin;
set local role anon;
do $$ begin
  begin perform oa151_kernel.inbox(); raise exception 'OA151 anonymous API unexpectedly allowed';
  exception when insufficient_privilege then null; end;
  begin perform 1 from oa151_kernel.requests; raise exception 'OA151 anonymous raw row unexpectedly allowed';
  exception when insufficient_privilege then null; end;
end; $$;
reset role;
select oa151_synthetic.assert_true((select request_ttl is null and request_limit is null and reservation_ttl is null
  from oa151_kernel.policy where singleton),'all functional test policies rolled back; product choices still held');
select oa151_synthetic.assert_true((select count(*)=0 from oa151_kernel.requests),'functional tests leave no request rows');
select oa151_synthetic.assert_true(oa151_synthetic.canonical_fingerprint()=(select fingerprint from oa151_synthetic.baseline),
  'all canonical fixtures unchanged after denial/readiness/expiry tests');
do $$ begin raise notice 'OA151 PASS: anonymous denials, held product policy and exact canonical fingerprints'; end; $$;
rollback;
