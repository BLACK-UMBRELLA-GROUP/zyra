-- SERVER 0 V2 / DOC-ZYRA-0329 / OA-ZYRA-317, OA-ZYRA-319.
-- Held ended-return PREPARATION bodies, isolated full after-schema only.
-- The exact client EXECUTE/direct-table denials are tested first. The owner
-- then invokes existing bodies with synthetic member JWT claims, without any
-- grant, release switch, altered guard or fake GUC. This proves local body
-- behavior only, never a feature activation. Every write rolls back.
\set ON_ERROR_STOP on
begin;
\ir fixtures/server0_v2_full_schema_prestate.sql
grant select on server0_v2_fixture_actors to authenticated;
create temporary table server0_restart_state(key text primary key,value text);
grant select,insert,update on server0_restart_state to authenticated;
create function pg_temp.rt_actor(p_label text) returns uuid language sql stable security invoker as $$
  select id from server0_v2_fixture_actors where fixture_label=p_label;
$$;
create function pg_temp.rt_state(p_key text) returns uuid language sql stable security invoker as $$
  select value::uuid from server0_restart_state where key=p_key;
$$;
create function pg_temp.rt_assert(p_ok boolean,p_label text) returns void language plpgsql security invoker as $$
begin
  if p_ok is distinct from true then raise exception 'SERVER0 restart FAIL: %',p_label; end if;
  raise notice 'SERVER0 restart PASS: %',p_label;
end;
$$;
create function pg_temp.rt_reject(p_sql text,p_error text,p_label text) returns void language plpgsql security invoker as $$
declare rejected boolean:=false;
begin
  begin execute p_sql;
  exception when others then
    if sqlstate=p_error or sqlerrm=p_error then rejected:=true;
    else raise exception 'SERVER0 restart wrong refusal %: % / %',p_label,sqlstate,sqlerrm; end if;
  end;
  if not rejected then raise exception 'SERVER0 restart unexpectedly allowed: %',p_label; end if;
  raise notice 'SERVER0 restart PASS refusal: %',p_label;
end;
$$;
grant execute on function pg_temp.rt_actor(text),pg_temp.rt_state(text),pg_temp.rt_assert(boolean,text),pg_temp.rt_reject(text,text,text) to authenticated;
update public.subscriptions set plan_type='seeker_premium' where user_id=pg_temp.rt_actor('male1');
insert into public.wali_links(seeker_id,wali_id,status,is_main,relationship)
values(pg_temp.rt_actor('fem1'),pg_temp.rt_actor('gb'),'active',true,'father');
insert into public.matches(id,seeker_a_id,seeker_b_id,status,journey_stage,ended_at)
values('33000000-0000-0000-0000-000000000401',least(pg_temp.rt_actor('male1'),pg_temp.rt_actor('fem1')),greatest(pg_temp.rt_actor('male1'),pg_temp.rt_actor('fem1')),'ended','conversation',now()-interval '25 hours');
insert into server0_restart_state values('match','33000000-0000-0000-0000-000000000401');
insert into server0_restart_state select 'old_attempt',id::text from public.journey_attempts where match_id=pg_temp.rt_state('match');
update public.journey_attempts set started_at=now()-interval '30 days',ended_at=now()-interval '25 hours',ended_by=pg_temp.rt_actor('male1'),end_reason='not_compatible'
where id=pg_temp.rt_state('old_attempt');
insert into public.conversations(match_id,attempt_id,status,closed_at) values(pg_temp.rt_state('match'),pg_temp.rt_state('old_attempt'),'closed',now()-interval '25 hours');
insert into public.timelines(match_id,attempt_id) values(pg_temp.rt_state('match'),pg_temp.rt_state('old_attempt'));
insert into public.journey_salams(match_id,seeker_id,attempt_id,sent_at)
values(pg_temp.rt_state('match'),pg_temp.rt_actor('male1'),pg_temp.rt_state('old_attempt'),now()-interval '29 days');
insert into server0_restart_state select 'old_hash',md5(row_to_json(a)::text) from public.journey_attempts a where id=pg_temp.rt_state('old_attempt');
insert into server0_restart_state select 'old_salam_hash',md5(row_to_json(s)::text) from public.journey_salams s where match_id=pg_temp.rt_state('match');

set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.rt_actor('male1'),'role','authenticated')::text,true);
select pg_temp.rt_reject('select public.request_new_journey('''||pg_temp.rt_state('match')||''')','42501','member request activation remains revoked');
select pg_temp.rt_reject('select public.respond_to_journey_request(gen_random_uuid(),''accept'')','42501','member response activation remains revoked');
select pg_temp.rt_reject('select public.withdraw_journey_request(gen_random_uuid())','42501','member withdrawal activation remains revoked');
select pg_temp.rt_reject('select public.zyra_may_request_new_journey('''||pg_temp.rt_state('match')||''')','42501','member internal may-request RPC remains revoked');
select pg_temp.rt_reject('select public.zyra_may_request_new_journey_ids()','42501','member internal may-request IDs RPC remains revoked');
select pg_temp.rt_reject('insert into public.journey_requests(match_id,requested_by,requested_to,expires_at) values('''||pg_temp.rt_state('match')||''',auth.uid(),'''||pg_temp.rt_actor('fem1')||''',now()+interval ''7 days'')','42501','member cannot bypass held RPC with direct request INSERT');
select pg_temp.rt_reject('update public.matches set status=''active'' where id='''||pg_temp.rt_state('match')||'''','42501','member cannot directly reactivate ended match');
select pg_temp.rt_reject('update public.journey_attempts set status=''active'' where id='''||pg_temp.rt_state('old_attempt')||'''','42501','member cannot directly reactivate ended attempt');
select pg_temp.rt_reject('select public.restart_journey('''||pg_temp.rt_state('match')||''')','restart_requires_mutual_consent','legacy restart refuses participant unilaterally');
select pg_temp.rt_reject('select public.promote_journey_to_active('''||pg_temp.rt_state('match')||''')','match is not in potential state (status=ended)','promotion RPC cannot reactivate ended match');
select pg_temp.rt_reject('select public.zyra_close_unavailable_journey_requests()','42501','unavailable request closure is service-only');
select pg_temp.rt_assert(public.zyra_journey_return_available(pg_temp.rt_state('match')),'One recent ended pair has read-only availability marker');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.rt_actor('male2'),'role','authenticated')::text,true);
select pg_temp.rt_reject('select public.restart_journey('''||pg_temp.rt_state('match')||''')','not a party to this match','legacy restart checks outsider identity before consent refusal');
select set_config('request.jwt.claims','{"role":"authenticated"}',true);
select pg_temp.rt_reject('select public.restart_journey('''||pg_temp.rt_state('match')||''')','not_signed_in','legacy restart rejects missing subject');
reset role;

do $member_acl_catalog$
declare expected record; member_role text; operation text; overloads integer;
begin
  for expected in select * from (values
    ('request_new_journey','public.request_new_journey(uuid)'),
    ('respond_to_journey_request','public.respond_to_journey_request(uuid,text)'),
    ('zyra_may_request_new_journey','public.zyra_may_request_new_journey(uuid)'),
    ('zyra_may_request_new_journey_ids','public.zyra_may_request_new_journey_ids()'),
    ('withdraw_journey_request','public.withdraw_journey_request(uuid)'),
    ('restart_journey','public.restart_journey(uuid)'),
    ('promote_journey_to_active','public.promote_journey_to_active(uuid)'),
    ('zyra_expire_due_journey_requests','public.zyra_expire_due_journey_requests(uuid)'),
    ('zyra_close_unavailable_journey_requests','public.zyra_close_unavailable_journey_requests()'),
    ('zyra_journey_return_available','public.zyra_journey_return_available(uuid)'),
    ('zyra_available_journey_return_ids','public.zyra_available_journey_return_ids()'),
    ('zyra_dev_seed_journey','public.zyra_dev_seed_journey()'),
    ('zyra_dev_rewind_journey','public.zyra_dev_rewind_journey(uuid)')
  ) signatures(function_name,signature)
  loop
    select count(*) into overloads from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname=expected.function_name;
    if overloads<>1 or to_regprocedure(expected.signature) is null then
      raise exception 'SERVER0 restart unexpected function overload/signature: % (%)',expected.function_name,overloads;
    end if;
  end loop;
  foreach member_role in array array['anon','authenticated'] loop
    foreach operation in array array['INSERT','UPDATE','DELETE','TRUNCATE'] loop
      if has_table_privilege(member_role,'public.journey_requests',operation) then
        raise exception 'SERVER0 restart direct table privilege exists: % %',member_role,operation;
      end if;
    end loop;
    if has_any_column_privilege(member_role,'public.journey_requests','INSERT')
       or has_any_column_privilege(member_role,'public.journey_requests','UPDATE') then
      raise exception 'SERVER0 restart direct request column write privilege exists: %',member_role;
    end if;
    for expected in select * from (values
      ('public.request_new_journey(uuid)'),('public.respond_to_journey_request(uuid,text)'),
      ('public.zyra_may_request_new_journey(uuid)'),('public.zyra_may_request_new_journey_ids()'),
      ('public.withdraw_journey_request(uuid)'),('public.zyra_close_unavailable_journey_requests()'),
      ('public.zyra_guard_ended_restart_initiation()')
    ) held(signature) loop
      if has_function_privilege(member_role,expected.signature,'EXECUTE') then
        raise exception 'SERVER0 restart held function executable by %: %',member_role,expected.signature;
      end if;
    end loop;
  end loop;
  if not has_function_privilege('authenticated','public.zyra_expire_due_journey_requests(uuid)','EXECUTE')
     or not has_function_privilege('service_role','public.zyra_close_unavailable_journey_requests()','EXECUTE')
     or not (select relrowsecurity from pg_class where oid='public.journey_requests'::regclass)
     or exists(select 1 from pg_policy where polrelid='public.journey_requests'::regclass and polcmd in('a','w','d','*'))
  then raise exception 'SERVER0 restart cleanup grant or request RLS boundary drifted'; end if;
  raise notice 'SERVER0 restart PASS: exact overloads; all member request table/column write ACLs denied; request RLS has no write policy; due-only cleanup and service closure retain their intended grants';
end;
$member_acl_catalog$;

savepoint ordinary_developer_identity;
update auth.users set email='server0-restart-ordinary@example.invalid' where id=pg_temp.rt_actor('male2');
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.rt_actor('male2'),'role','authenticated')::text,true);
select pg_temp.rt_reject('select public.zyra_dev_seed_journey()','dev_only','ordinary reserved-address member cannot seed Journey');
select pg_temp.rt_reject('select public.zyra_dev_rewind_journey('''||pg_temp.rt_state('match')||''')','dev_only','ordinary reserved-address member cannot rewind Journey');
reset role;
rollback to savepoint ordinary_developer_identity;
do $$ begin
  raise notice 'SERVER0 restart EXCEPTION: existing developer seed/rewind RPCs remain test-account-only for @zyra.test identities; ordinary reserved-address identity received dev_only. This suite does not claim those approved developer identities are locked out.';
end; $$;

-- These are owner-invoked preparation-body regressions from this point.
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.rt_actor('fem1'),'role','authenticated')::text,true);
select pg_temp.rt_reject('select public.request_new_journey('''||pg_temp.rt_state('match')||''')','return_membership_required','Basic requester refused by held body');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.rt_actor('male2'),'role','authenticated')::text,true);
select pg_temp.rt_reject('select public.request_new_journey('''||pg_temp.rt_state('match')||''')','not_a_party','outsider refused by held body');
select set_config('request.jwt.claims','{}',true);
select pg_temp.rt_reject('select public.request_new_journey('''||pg_temp.rt_state('match')||''')','not_signed_in','unsigned request body refused');

savepoint cooling;
update public.matches set ended_at=now()-interval '23 hours' where id=pg_temp.rt_state('match');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.rt_actor('male1'),'role','authenticated')::text,true);
select pg_temp.rt_reject('select public.request_new_journey('''||pg_temp.rt_state('match')||''')','cooling_period_active','full 24-hour cooling required');
rollback to savepoint cooling;

savepoint last_five;
-- Two additional historical counterpart identities make six valid opposite-
-- gender pair envelopes. Their onboarding is deliberately irrelevant to this
-- ranking check; no request to a filler actor is claimed eligible.
insert into auth.users(instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at,confirmation_token,recovery_token,email_change,email_change_token_new,email_change_token_current)
values('00000000-0000-0000-0000-000000000000','33000000-0000-0000-0000-000000000491','authenticated','authenticated','server0-restart-history-a@zyra.test',null,now(),'{}','{}',now(),now(),'','','','',''),
      ('00000000-0000-0000-0000-000000000000','33000000-0000-0000-0000-000000000492','authenticated','authenticated','server0-restart-history-b@zyra.test',null,now(),'{}','{}',now(),now(),'','','','','');
insert into public.profiles(id,role,first_name,date_of_birth,gender,is_active,profile_complete)
values('33000000-0000-0000-0000-000000000491','seeker','History A',date '1990-01-01','female',true,false),
      ('33000000-0000-0000-0000-000000000492','seeker','History B',date '1990-01-01','female',true,false);
insert into public.matches(seeker_a_id,seeker_b_id,status,journey_stage,ended_at)
select least(pg_temp.rt_actor('male1'),counterpart),greatest(pg_temp.rt_actor('male1'),counterpart),'ended','conversation',now()-interval '24 hours 30 minutes'
from (values(pg_temp.rt_actor('fem2')),(pg_temp.rt_actor('fem3')),(pg_temp.rt_actor('fem4')),('33000000-0000-0000-0000-000000000491'::uuid),('33000000-0000-0000-0000-000000000492'::uuid)) histories(counterpart);
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.rt_actor('male1'),'role','authenticated')::text,true);
select pg_temp.rt_reject('select public.request_new_journey('''||pg_temp.rt_state('match')||''')','return_window_exceeded','only five most recent ended pairs are eligible');
select pg_temp.rt_assert(not public.zyra_journey_return_available(pg_temp.rt_state('match')),'old sixth pair marker is false');
rollback to savepoint last_five;

savepoint capacity;
select set_config('request.jwt.claims','{}',true);
insert into public.matches(seeker_a_id,seeker_b_id,status,journey_stage)
values(least(pg_temp.rt_actor('male2'),pg_temp.rt_actor('fem1')),greatest(pg_temp.rt_actor('male2'),pg_temp.rt_actor('fem1')),'active','salam_exchange');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.rt_actor('male1'),'role','authenticated')::text,true);
select pg_temp.rt_reject('select public.request_new_journey('''||pg_temp.rt_state('match')||''')','journey_capacity_unavailable','Basic recipient full one-place capacity refused');
rollback to savepoint capacity;

savepoint blocked;
select set_config('request.jwt.claims','{}',true);
insert into public.profile_blocks(blocker_id,blocked_id) values(pg_temp.rt_actor('fem1'),pg_temp.rt_actor('male1'));
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.rt_actor('male1'),'role','authenticated')::text,true);
select pg_temp.rt_reject('select public.request_new_journey('''||pg_temp.rt_state('match')||''')','not_available','block refuses restart without disclosing cause');
rollback to savepoint blocked;
savepoint held;
select set_config('request.jwt.claims','{}',true);
insert into public.protection_holds(match_id,restricted_id,protected_id,hold_type,appealable,expires_at)
values(pg_temp.rt_state('match'),pg_temp.rt_actor('male1'),pg_temp.rt_actor('fem1'),'decline_cooldown',true,now()+interval '30 days');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.rt_actor('male1'),'role','authenticated')::text,true);
select pg_temp.rt_reject('select public.request_new_journey('''||pg_temp.rt_state('match')||''')','not_available','protection hold refuses restart neutrally');
rollback to savepoint held;

select set_config('request.jwt.claims',json_build_object('sub',pg_temp.rt_actor('male1'),'role','authenticated')::text,true);
select pg_temp.rt_reject('insert into public.journey_requests(match_id,requested_by,requested_to,expires_at) values('''||pg_temp.rt_state('match')||''','''||pg_temp.rt_actor('male1')||''','''||pg_temp.rt_actor('fem1')||''',now()+interval ''8 days'')','restart_expiry_must_be_seven_days','trigger enforces exact seven-day expiry');
select pg_temp.rt_reject('insert into public.journey_requests(match_id,requested_by,requested_to,expires_at) values('''||pg_temp.rt_state('match')||''','''||pg_temp.rt_actor('fem1')||''','''||pg_temp.rt_actor('male1')||''',now()+interval ''7 days'')','restart_not_available','trigger binds requesting caller');
insert into server0_restart_state select 'request',public.request_new_journey(pg_temp.rt_state('match'))::text;
select pg_temp.rt_assert((select requested_by=pg_temp.rt_actor('male1') and requested_to=pg_temp.rt_actor('fem1') and expires_at=now()+interval '7 days' and status='pending' from public.journey_requests where id=pg_temp.rt_state('request')),'held body creates caller-bound seven-day pending request');
set local role authenticated;
select pg_temp.rt_reject('insert into public.journey_requests(match_id,requested_by,requested_to,expires_at) values('''||pg_temp.rt_state('match')||''',auth.uid(),'''||pg_temp.rt_actor('fem1')||''',now()+interval ''7 days'')','42501','member INSERT remains denied with real pending row present');
select pg_temp.rt_reject('update public.journey_requests set status=''accepted'',attempt_id='''||pg_temp.rt_state('old_attempt')||''',responded_at=now() where id='''||pg_temp.rt_state('request')||'''','42501','member cannot accept real pending row by direct UPDATE');
select pg_temp.rt_reject('update public.journey_requests set expires_at=now()+interval ''30 days'' where id='''||pg_temp.rt_state('request')||'''','42501','member cannot extend real request expiry by direct column UPDATE');
select pg_temp.rt_reject('delete from public.journey_requests where id='''||pg_temp.rt_state('request')||'''','42501','member cannot delete real pending request');
select pg_temp.rt_reject('truncate table public.journey_requests','42501','member cannot truncate request table with real pending row');
select pg_temp.rt_assert(public.zyra_expire_due_journey_requests(pg_temp.rt_state('match'))=0,'authenticated expiry cleanup cannot close not-due request');
reset role;
select pg_temp.rt_assert((select status='pending' and attempt_id is null from public.journey_requests where id=pg_temp.rt_state('request')) and (select status='ended' from public.matches where id=pg_temp.rt_state('match')) and (select count(*)=1 from public.journey_attempts where match_id=pg_temp.rt_state('match')),'denied member writes and early cleanup leave pending request/ended pair/attempt count unchanged');
select pg_temp.rt_reject('select public.request_new_journey('''||pg_temp.rt_state('match')||''')','request_already_pending','duplicate pending pair refused');
select pg_temp.rt_assert(public.zyra_active_journey_count(pg_temp.rt_actor('male1'))=0 and public.zyra_active_journey_count(pg_temp.rt_actor('fem1'))=0,'pending request consumes no Journey place');

select set_config('request.jwt.claims',json_build_object('sub',pg_temp.rt_actor('male2'),'role','authenticated')::text,true);
select pg_temp.rt_reject('select public.respond_to_journey_request('''||pg_temp.rt_state('request')||''',''accept'')','not_yours_to_answer','only intended recipient can answer');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.rt_actor('fem1'),'role','authenticated')::text,true);
select pg_temp.rt_reject('select public.respond_to_journey_request('''||pg_temp.rt_state('request')||''',''unknown'')','unknown_decision','unsupported response rejected');
savepoint expired;
update public.journey_requests set expires_at=now()-interval '1 second' where id=pg_temp.rt_state('request');
select pg_temp.rt_reject('select public.respond_to_journey_request('''||pg_temp.rt_state('request')||''',''accept'')','request_expired','expired request cannot be accepted');
set local role authenticated;
select pg_temp.rt_assert(public.zyra_expire_due_journey_requests(pg_temp.rt_state('match'))=1,'expiry sweep closes due pending request');
reset role;
select pg_temp.rt_assert((select status='declined' and closed_reason='expired' and attempt_id is null from public.journey_requests where id=pg_temp.rt_state('request')) and (select status='ended' from public.matches where id=pg_temp.rt_state('match')) and (select count(*)=1 from public.journey_attempts where match_id=pg_temp.rt_state('match')),'authenticated due-only expiry never accepts request or opens attempt');
select pg_temp.rt_assert(not exists(select 1 from public.protection_holds),'expiry creates no decline cooldown');
rollback to savepoint expired;
savepoint decline;
select pg_temp.rt_assert(public.respond_to_journey_request(pg_temp.rt_state('request'),'decline')='declined','Basic recipient may decline without paid role');
select pg_temp.rt_assert((select hold_type='decline_cooldown' and expires_at=now()+interval '30 days' and appealable from public.protection_holds where match_id=pg_temp.rt_state('match')),'ordinary decline creates appealable thirty-day hold');
rollback to savepoint decline;
savepoint never;
select pg_temp.rt_assert(public.respond_to_journey_request(pg_temp.rt_state('request'),'decline_never')='declined','Basic recipient may refuse further requests');
select pg_temp.rt_assert((select hold_type='decline_permanent' and expires_at is null and appealable from public.protection_holds where match_id=pg_temp.rt_state('match')),'never decline creates permanent appealable hold');
rollback to savepoint never;
savepoint unavailable;
update public.subscriptions set status='cancelled' where user_id=pg_temp.rt_actor('fem1');
select pg_temp.rt_assert(public.respond_to_journey_request(pg_temp.rt_state('request'),'accept')='recipient_unavailable','no-capacity recipient closes request neutrally');
select pg_temp.rt_assert((select closed_reason='recipient_unavailable' from public.journey_requests where id=pg_temp.rt_state('request')),'unavailable closure does not store billing reason');
rollback to savepoint unavailable;
savepoint requester_unpaid;
update public.subscriptions set plan_type='seeker_basic' where user_id=pg_temp.rt_actor('male1');
select pg_temp.rt_reject('select public.respond_to_journey_request('''||pg_temp.rt_state('request')||''',''accept'')','not_available','accept rechecks requester paid entitlement');
rollback to savepoint requester_unpaid;

select pg_temp.rt_assert(public.respond_to_journey_request(pg_temp.rt_state('request'),'accept')='accepted','Basic recipient accepts held preparation request');
insert into server0_restart_state select 'new_attempt',attempt_id::text from public.journey_requests where id=pg_temp.rt_state('request');
select pg_temp.rt_assert(pg_temp.rt_state('new_attempt')<>pg_temp.rt_state('old_attempt'),'acceptance creates a distinct new attempt');
select pg_temp.rt_assert((select status='active' and journey_stage='salam_exchange' and attempt_number=2 from public.journey_attempts where id=pg_temp.rt_state('new_attempt')),'new attempt starts at Salam');
select pg_temp.rt_assert((select md5(row_to_json(a)::text)=(select value from server0_restart_state where key='old_hash') from public.journey_attempts a where id=pg_temp.rt_state('old_attempt')),'prior ended attempt is byte-equivalent');
select pg_temp.rt_assert((select md5(row_to_json(s)::text)=(select value from server0_restart_state where key='old_salam_hash') from public.journey_salams s where match_id=pg_temp.rt_state('match')),'prior ritual row stays with old attempt');
select pg_temp.rt_assert((select count(*)=2 from public.conversations where match_id=pg_temp.rt_state('match')) and (select count(*)=2 from public.timelines where match_id=pg_temp.rt_state('match')),'new attempt receives distinct conversation and timeline');
select pg_temp.rt_assert(public.zyra_active_journey_count(pg_temp.rt_actor('male1'))=1 and public.zyra_active_journey_count(pg_temp.rt_actor('fem1'))=1,'new active attempt consumes one place each');
select pg_temp.rt_reject('select public.respond_to_journey_request('''||pg_temp.rt_state('request')||''',''accept'')','already_answered','accepted request cannot be replayed');

-- Known release blocker: original ritual ownership still keys Salam by the
-- pair. Prove it explicitly; do not delete historic ritual rows or bypass the
-- collision to make the release appear ready. The held client ACL is required.
set local role authenticated;
do $held_ritual_limit$
declare rejected boolean:=false;
begin
  begin
    insert into public.journey_salams(match_id,seeker_id,attempt_id)
    values(pg_temp.rt_state('match'),pg_temp.rt_actor('fem1'),pg_temp.rt_state('new_attempt'));
  exception when unique_violation then rejected:=true;
  end;
  -- This actor has no prior Salam; its write verifies current attempt binding.
  if rejected then raise exception 'new recipient Salam unexpectedly collided'; end if;
end;
$held_ritual_limit$;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.rt_actor('male1'),'role','authenticated')::text,true);
do $known_preparation_blocker$
declare collision boolean:=false; violated_constraint text;
begin
  begin
    insert into public.journey_salams(match_id,seeker_id,attempt_id)
    values(pg_temp.rt_state('match'),pg_temp.rt_actor('male1'),pg_temp.rt_state('new_attempt'));
  exception when unique_violation then
    get stacked diagnostics violated_constraint = CONSTRAINT_NAME;
    if violated_constraint is distinct from 'journey_salams_pkey' then
      raise exception 'unexpected Salam uniqueness constraint: %',violated_constraint;
    end if;
    collision:=true;
  end;
  if not collision then raise exception 'expected historical pair-owned Salam release blocker changed; review gate'; end if;
  raise notice 'SERVER0 restart EXPECTED DEFECT (journey_salams_pkey): prior pair-owned Salam collides with restarted attempt; public restart execution remains revoked pending its own reviewed ownership cutover';
end;
$known_preparation_blocker$;
reset role;
select pg_temp.rt_assert(not has_function_privilege('authenticated','public.request_new_journey(uuid)','execute') and not has_function_privilege('authenticated','public.respond_to_journey_request(uuid,text)','execute'),'release remains held after preparation-only tests');
rollback;
