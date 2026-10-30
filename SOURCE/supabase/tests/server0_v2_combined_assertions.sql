-- SERVER 0 V2 / DOC-ZYRA-0329 / OA-ZYRA-317, OA-ZYRA-319, OA-ZYRA-324.
-- AFTER-PAYLOAD, isolated full-schema replay only. This is a synthetic SQL
-- impersonation proof, not a live clone, gateway, app or payment-provider test.
-- Run standalone on a fresh replay: the fixture creates actors inside this
-- transaction; every setup/test write rolls back. No candidate guard is changed.
\set ON_ERROR_STOP on
begin;
\ir fixtures/server0_v2_full_schema_prestate.sql

grant select on server0_v2_fixture_actors to authenticated;
create temporary table server0_combined_state(key text primary key, value text);
grant select, insert, update on server0_combined_state to authenticated;
create function pg_temp.actor(p_label text) returns uuid
language sql stable security invoker as $$
  select id from server0_v2_fixture_actors where fixture_label=p_label;
$$;
create function pg_temp.state(p_key text) returns uuid
language sql stable security invoker as $$
  select value::uuid from server0_combined_state where key=p_key;
$$;
create function pg_temp.assert(p_ok boolean, p_label text) returns void
language plpgsql security invoker as $$
begin
  if p_ok is distinct from true then raise exception 'SERVER0 combined FAIL: %',p_label; end if;
  raise notice 'SERVER0 combined PASS: %',p_label;
end;
$$;
create function pg_temp.reject(p_sql text,p_error text,p_label text) returns void
language plpgsql security invoker as $$
declare v_rejected boolean:=false;
begin
  begin execute p_sql;
  exception when others then
    if sqlstate=p_error or sqlerrm=p_error then v_rejected:=true;
    else raise exception 'SERVER0 combined wrong refusal %: % / %',p_label,sqlstate,sqlerrm; end if;
  end;
  if not v_rejected then raise exception 'SERVER0 combined unexpectedly allowed: %',p_label; end if;
  raise notice 'SERVER0 combined PASS refusal: %',p_label;
end;
$$;
grant execute on function pg_temp.actor(text),pg_temp.state(text),
  pg_temp.assert(boolean,text),pg_temp.reject(text,text,text) to authenticated;

-- The BEFORE UPDATE hold must see the proposed active state, rather than
-- returning early after reading the old potential pair row.
savepoint activation_hold;
insert into public.matches(id,seeker_a_id,seeker_b_id,status,journey_stage)
values('33000000-0000-0000-0000-000000000005',
  least(pg_temp.actor('male1'),pg_temp.actor('fem1')),
  greatest(pg_temp.actor('male1'),pg_temp.actor('fem1')),'potential','salam_exchange');
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male1'),'role','authenticated')::text,true);
select pg_temp.reject('select public.promote_journey_to_active(''33000000-0000-0000-0000-000000000005'')',
 'main_guardian_required_for_journey','activation cannot bypass missing Main hold');
reset role;
rollback to savepoint activation_hold;

-- C: Basic is one place; One is three. Only the caller-bound wrapper exposes
-- paid status. The privileged arbitrary-user helper stays private.
select pg_temp.assert(public.zyra_active_journey_cap(pg_temp.actor('male1'))=1,'Basic capacity is one');
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male1'),'role','authenticated')::text,true);
select pg_temp.assert(not public.zyra_my_paid_access('seeker'),'Basic has no paid role');
select pg_temp.reject('select public.zyra_has_paid_role('''||pg_temp.actor('fem1')||''',''seeker'')','42501','arbitrary-user paid helper denied');
select pg_temp.reject('select public.zyra_active_journey_cap('''||pg_temp.actor('fem1')||''')','42501','arbitrary-user capacity helper denied');
select pg_temp.reject('select public.mock_purchase_wali_premium()','42501','legacy premium mint denied');
select pg_temp.reject('select public.mock_set_wali_plan(''wali_premium'')','42501','legacy plan setter denied');
reset role;
update public.subscriptions set plan_type='seeker_premium' where user_id=pg_temp.actor('male1');
update public.subscriptions set plan_type='wali_premium' where user_id in(pg_temp.actor('gmain'),pg_temp.actor('gadd'),pg_temp.actor('gb'));
select pg_temp.assert(public.zyra_active_journey_cap(pg_temp.actor('male1'))=3,'One capacity is three');
select pg_temp.assert(public.zyra_active_journey_cap(pg_temp.actor('fem1'))=1,'counterpart Basic remains one');
set local role authenticated;
select pg_temp.assert(public.zyra_my_paid_access('seeker'),'One caller-bound paid access');
select pg_temp.assert(not public.zyra_my_paid_access('guardian'),'paid role cannot cross Seeker/Guardian');
reset role;

-- Known code: full verification + visibility rechecked at mutation time.
-- Use fem2 so code Consider cannot accidentally create the chat fixture pair.
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('fem2'),'role','authenticated')::text,true);
insert into server0_combined_state select 'code',code from public.zyra_my_personal_code('seeker');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male2'),'role','authenticated')::text,true);
select pg_temp.assert((select count(*)=1 from public.zyra_preview_match_code((select value from server0_combined_state where key='code'))),'verified eligible known code preview');
select pg_temp.assert(public.zyra_consider_match_code((select value from server0_combined_state where key='code'))='considered','known code creates Consider only');
reset role;
select pg_temp.assert(not exists(select 1 from public.matches),'one-way code Consider creates no Match');
insert into public.profile_blocks(blocker_id,blocked_id) values(pg_temp.actor('fem2'),pg_temp.actor('male2'));
set local role authenticated;
select pg_temp.assert(not exists(select 1 from public.zyra_preview_match_code((select value from server0_combined_state where key='code'))),'blocked known code is neutral');
select pg_temp.assert(public.zyra_consider_match_code((select value from server0_combined_state where key='code')) is null,'Consider rechecks changed block state');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('gmain'),'role','authenticated')::text,true);
select pg_temp.assert(not exists(select 1 from public.zyra_preview_match_code((select value from server0_combined_state where key='code'))),'Guardian cannot discover romantic code');
reset role;
update public.profiles set is_active=false where id=pg_temp.actor('fem2');
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male1'),'role','authenticated')::text,true);
select pg_temp.assert(not exists(select 1 from public.zyra_preview_match_code((select value from server0_combined_state where key='code'))),'hidden known-code target stays undiscoverable');
reset role;
update public.profiles set is_active=true where id=pg_temp.actor('fem2');
update private.identity_verification_attempts set result='failed' where user_id=pg_temp.actor('fem2');
set local role authenticated;
select pg_temp.assert(not exists(select 1 from public.zyra_preview_match_code((select value from server0_combined_state where key='code'))),'unverified known-code target stays undiscoverable');
reset role;
update private.identity_verification_attempts set result='failed' where user_id=pg_temp.actor('male2');
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male2'),'role','authenticated')::text,true);
select pg_temp.reject('select * from public.zyra_preview_match_code(''ZYRA-0000-0000-0000-0000-0000'')','identity_verification_required','unverified code caller denied');
reset role;

-- Telemetry is allowlisted, identifier-free and raw/summary/prune access is
-- service-only. No app feature switch is enabled by this SQL test.
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male1'),'role','authenticated')::text,true);
select public.zyra_record_product_event('journey','opened','pageView','seeker','ios','1.0','1');
select pg_temp.reject('select public.zyra_record_product_event(''journey'',''opened'',''untrusted-text'',''seeker'',''ios'',''1.0'',''1'')','22023','telemetry rejects free action');
select pg_temp.reject('select * from private.zyra_product_events','42501','telemetry raw data denied');
select pg_temp.reject('select * from public.zyra_product_event_summary(now()-interval ''1 day'',now())','42501','telemetry summary denied');
select pg_temp.reject('select public.zyra_prune_product_events()','42501','telemetry pruning denied');
reset role;
select pg_temp.assert((select count(*)=1 from private.zyra_product_events),'one valid telemetry row only');
select pg_temp.assert(not exists(select 1 from information_schema.columns where table_schema='private' and table_name='zyra_product_events' and column_name in('user_id','device_id','session_id','attributes')),'telemetry has no identity/arbitrary attributes');

-- Actual full-schema active pair and current conversation; trusted fixture
-- setup does not disable triggers or alter any policy/function.
insert into public.wali_links(seeker_id,wali_id,status,is_main,relationship) values
  (pg_temp.actor('fem1'),pg_temp.actor('gb'),'active',true,'father'),
  (pg_temp.actor('male1'),pg_temp.actor('gadd'),'active',false,'uncle');
insert into public.matches(id,seeker_a_id,seeker_b_id,status,journey_stage)
values('33000000-0000-0000-0000-000000000001',least(pg_temp.actor('male1'),pg_temp.actor('fem1')),greatest(pg_temp.actor('male1'),pg_temp.actor('fem1')),'active','conversation');
insert into server0_combined_state values('match','33000000-0000-0000-0000-000000000001');
insert into server0_combined_state select 'attempt',id::text from public.journey_attempts where match_id=pg_temp.state('match') and status='active';
update public.journey_attempts set journey_stage='conversation' where id=pg_temp.state('attempt');
insert into public.conversations(match_id,attempt_id,status)
select pg_temp.state('match'),pg_temp.state('attempt'),'active'
where not exists(select 1 from public.conversations where attempt_id=pg_temp.state('attempt'));
insert into server0_combined_state select 'conversation',id::text from public.conversations where attempt_id=pg_temp.state('attempt');
insert into server0_combined_state select 'additional_link',id::text from public.wali_links where seeker_id=pg_temp.actor('male1') and wali_id=pg_temp.actor('gadd') and status='active';

-- Ordinary Seeker sends remain free within an active stage-8 Journey. Sender
-- spoof, stage/lifecycle/block failures and Guardians' paid+Chat gates are
-- tested as real INSERTs, not merely helper booleans.
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('fem1'),'role','authenticated')::text,true);
insert into public.messages(conversation_id,sender_id,content) values(pg_temp.state('conversation'),pg_temp.actor('fem1'),'Basic Seeker stage-8 message');
select pg_temp.reject('insert into public.messages(conversation_id,sender_id,content) values('''||pg_temp.state('conversation')||''','''||pg_temp.actor('male1')||''',''spoof'')','42501','message sender spoof denied');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('gadd'),'role','authenticated')::text,true);
select pg_temp.reject('insert into public.messages(conversation_id,sender_id,content) values('''||pg_temp.state('conversation')||''','''||pg_temp.actor('gadd')||''',''unassigned'')','42501','paid Additional needs own current assignment');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male1'),'role','authenticated')::text,true);
select * from public.zyra_guardian_journey_chat_access(pg_temp.actor('gadd'),pg_temp.state('attempt'),true,true);
select pg_temp.reject('select public.zyra_set_guardian_journey_permission('''||(select id from public.wali_links where wali_id=pg_temp.actor('gmain') and seeker_id=pg_temp.actor('male1'))||''','''||pg_temp.state('match')||''',false,false)','main_guardian_access_required','Main view/chat cannot be disabled');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('gadd'),'role','authenticated')::text,true);
insert into public.messages(conversation_id,sender_id,content) values(pg_temp.state('conversation'),pg_temp.actor('gadd'),'Paid included Additional Chat');
select pg_temp.reject('select public.zyra_set_guardian_journey_permission('''||pg_temp.state('additional_link')||''','''||pg_temp.state('match')||''',true,true)','guardian_link_not_available','Guardian cannot self-grant Chat');
select pg_temp.reject('select public.zyra_mark_journey_messages_read('''||pg_temp.state('conversation')||''')','conversation_not_available','Guardian cannot write Seeker read receipt');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male1'),'role','authenticated')::text,true);
select public.zyra_set_guardian_journey_permission(pg_temp.state('additional_link'),pg_temp.state('match'),true,false);
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('gadd'),'role','authenticated')::text,true);
select pg_temp.reject('insert into public.messages(conversation_id,sender_id,content) values('''||pg_temp.state('conversation')||''','''||pg_temp.actor('gadd')||''',''Chat off'')','42501','included paid Additional with Chat off denied');
reset role;
update public.subscriptions set plan_type='wali_basic' where user_id=pg_temp.actor('gmain');
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('gmain'),'role','authenticated')::text,true);
select pg_temp.reject('insert into public.messages(conversation_id,sender_id,content) values('''||pg_temp.state('conversation')||''','''||pg_temp.actor('gmain')||''',''unpaid Main'')','42501','Main role alone gives no paid Guardian send');
reset role;
update public.subscriptions set plan_type='wali_premium' where user_id=pg_temp.actor('gmain');
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('gmain'),'role','authenticated')::text,true);
insert into public.messages(conversation_id,sender_id,content) values(pg_temp.state('conversation'),pg_temp.actor('gmain'),'Paid Main Chat');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male1'),'role','authenticated')::text,true);
insert into public.messages(conversation_id,sender_id,content) values(pg_temp.state('conversation'),pg_temp.actor('male1'),'Own message receipt stays unread');
select public.zyra_mark_journey_messages_read(pg_temp.state('conversation'));
reset role;
select pg_temp.assert((select bool_and(read_at is not null) from public.messages where conversation_id=pg_temp.state('conversation') and sender_id=pg_temp.actor('fem1')),'Seeker marks counterpart message read');
select pg_temp.assert((select bool_and(read_at is null) from public.messages where conversation_id=pg_temp.state('conversation') and sender_id=pg_temp.actor('male1')),'Seeker cannot mark own message as counterpart read');
savepoint guardian_block;
insert into public.profile_blocks(blocker_id,blocked_id) values(pg_temp.actor('gmain'),pg_temp.actor('fem1'));
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('gmain'),'role','authenticated')::text,true);
select pg_temp.reject('insert into public.messages(conversation_id,sender_id,content) values('''||pg_temp.state('conversation')||''','''||pg_temp.actor('gmain')||''',''blocked Guardian'')','42501','Guardian/counterpart block independently closes paid send');
reset role;
rollback to savepoint guardian_block;
update public.journey_attempts set journey_stage='family_stage' where id=pg_temp.state('attempt');
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male1'),'role','authenticated')::text,true);
select pg_temp.reject('insert into public.messages(conversation_id,sender_id,content) values('''||pg_temp.state('conversation')||''','''||pg_temp.actor('male1')||''',''early'')','42501','stage before Open Conversation denied');
reset role;
update public.journey_attempts set journey_stage='conversation' where id=pg_temp.state('attempt');
update public.conversations set status='closed' where id=pg_temp.state('conversation');
set local role authenticated;
select pg_temp.reject('insert into public.messages(conversation_id,sender_id,content) values('''||pg_temp.state('conversation')||''','''||pg_temp.actor('male1')||''',''closed'')','42501','closed conversation denied');
reset role;
update public.conversations set status='active' where id=pg_temp.state('conversation');
savepoint inactive_attempt;
update public.journey_attempts set status='ended',ended_at=now() where id=pg_temp.state('attempt');
set local role authenticated;
select pg_temp.reject('insert into public.messages(conversation_id,sender_id,content) values('''||pg_temp.state('conversation')||''','''||pg_temp.actor('male1')||''',''inactive attempt'')','42501','inactive attempt denied despite active conversation');
reset role;
rollback to savepoint inactive_attempt;

-- H: only participants see the two booleans. Clearing Main keeps the link,
-- ordinary Journey writes stop, and the authenticated End path still works.
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male2'),'role','authenticated')::text,true);
select pg_temp.reject('select * from public.zyra_journey_main_guardian_gate('''||pg_temp.state('match')||''')','journey_not_available','outsider Main status hidden');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male1'),'role','authenticated')::text,true);
select pg_temp.assert((select self_has_main and other_has_main from public.zyra_journey_main_guardian_gate(pg_temp.state('match'))),'both Main booleans visible to Seeker');
select public.zyra_clear_main_guardian(pg_temp.actor('gmain'));
select pg_temp.assert((select not self_has_main and other_has_main from public.zyra_journey_main_guardian_gate(pg_temp.state('match'))),'deliberate no-Main state visible');
select pg_temp.reject('insert into public.messages(conversation_id,sender_id,content) values('''||pg_temp.state('conversation')||''','''||pg_temp.actor('male1')||''',''held'')','main_guardian_required_for_journey','no-Main blocks ordinary Seeker message');
select public.end_journey(pg_temp.state('match'));
reset role;
select pg_temp.assert((select status='ended' from public.matches where id=pg_temp.state('match')),'End remains available under no-Main hold');
select pg_temp.assert((select status='active' and not is_main from public.wali_links where seeker_id=pg_temp.actor('male1') and wali_id=pg_temp.actor('gmain')),'clear Main demotes without unlinking');
-- Restore only the synthetic Main before testing the separate ended-return
-- preparation read marker; member mutation RPCs remain revoked.
update public.wali_links set is_main=true where seeker_id=pg_temp.actor('male1') and wali_id=pg_temp.actor('gmain');
update public.matches set ended_at=now()-interval '25 hours' where id=pg_temp.state('match');
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male1'),'role','authenticated')::text,true);
select pg_temp.assert(public.zyra_journey_return_available(pg_temp.state('match')),'paid recent ended Journey is available after 24h');
select pg_temp.reject('select public.request_new_journey('''||pg_temp.state('match')||''')','42501','restart mutation remains held preparation');
select pg_temp.reject('select public.respond_to_journey_request(gen_random_uuid(),''accept'')','42501','restart response remains held preparation');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('fem1'),'role','authenticated')::text,true);
select pg_temp.assert(not public.zyra_journey_return_available(pg_temp.state('match')),'Basic cannot initiate restart');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male2'),'role','authenticated')::text,true);
select pg_temp.assert(not public.zyra_journey_return_available(pg_temp.state('match')),'outsider restart marker is false');
reset role;
update public.matches set ended_at=now()-interval '23 hours' where id=pg_temp.state('match');
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male1'),'role','authenticated')::text,true);
select pg_temp.assert(not public.zyra_journey_return_available(pg_temp.state('match')),'restart cooling period enforced');
reset role;

-- Circle paid participants, caller privacy, sender labels, epoch boundary,
-- receipts and moderation ACLs. A new epoch never regains old messages.
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male1'),'role','authenticated')::text,true);
insert into server0_combined_state select 'thread',thread_id::text from public.zyra_open_family_message_circle(pg_temp.actor('male1'));
reset role;
-- The RPC uses wall-clock membership epochs and transaction timestamps for
-- messages. Model an already-open first epoch explicitly so this single
-- rollback transaction represents later send/read API transactions honestly.
-- Relink below still uses its real new wall-clock epoch without adjustment.
update public.family_message_memberships set joined_at=now()-interval '1 minute',readable_from=now()-interval '1 minute'
where thread_id=pg_temp.state('thread');
set local role authenticated;
select pg_temp.assert((select can_send from public.zyra_open_family_message_circle(pg_temp.actor('male1'))),'Circle send requires all current roles paid');
insert into server0_combined_state select 'circle_msg',public.zyra_send_family_message(pg_temp.state('thread'),'Circle first epoch')::text;
select pg_temp.assert((select count(*)=3 from public.zyra_family_message_participants(pg_temp.state('thread'))),'Circle current participant count');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male2'),'role','authenticated')::text,true);
select pg_temp.assert(not exists(select 1 from public.zyra_family_message_participants(pg_temp.state('thread'))),'outsider cannot enumerate Circle people');
select pg_temp.assert(not exists(select 1 from public.zyra_family_messages_v2(pg_temp.state('thread'))),'outsider cannot read sender identities');
select pg_temp.reject('select public.zyra_send_family_message('''||pg_temp.state('thread')||''',''outsider'')','circle_not_found','outsider Circle send hidden');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('gadd'),'role','authenticated')::text,true);
select public.zyra_mark_family_messages_read(pg_temp.state('thread'));
select pg_temp.assert((select read_by='[]'::jsonb from public.zyra_family_messages_v3(pg_temp.state('thread')) where message_id=pg_temp.state('circle_msg')),'Circle recipients cannot inspect sender read list');
insert into server0_combined_state select 'guardian_circle_msg',public.zyra_send_family_message(pg_temp.state('thread'),'Additional first epoch')::text;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male1'),'role','authenticated')::text,true);
select pg_temp.assert((select jsonb_array_length(read_by)=1 from public.zyra_family_messages_v3(pg_temp.state('thread')) where message_id=pg_temp.state('circle_msg')),'Circle sender sees actual reader only');
select pg_temp.assert((select sender_role_label='Additional Guardian' from public.zyra_family_messages_v2(pg_temp.state('thread')) where message_id=pg_temp.state('guardian_circle_msg')),'sender identity is actual Additional role');
select public.zyra_remove_guardian(pg_temp.actor('gadd'));
select pg_temp.assert((select sender_first_name='Former Guardian' from public.zyra_family_messages_v2(pg_temp.state('thread')) where message_id=pg_temp.state('guardian_circle_msg')),'left sender honestly labelled Former Guardian');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('gadd'),'role','authenticated')::text,true);
select pg_temp.assert(not exists(select 1 from public.zyra_family_messages_v3(pg_temp.state('thread'))),'removed Guardian loses whole Circle read');
reset role;
update public.wali_links set status='active' where id=pg_temp.state('additional_link');
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('gadd'),'role','authenticated')::text,true);
select * from public.zyra_open_family_message_circle(pg_temp.actor('male1'));
select pg_temp.assert(not exists(select 1 from public.zyra_family_messages_v3(pg_temp.state('thread')) where message_id in(pg_temp.state('circle_msg'),pg_temp.state('guardian_circle_msg'))),'relinked Guardian cannot read prior epoch');
reset role;
update public.subscriptions set plan_type='wali_basic' where user_id=pg_temp.actor('gadd');
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.actor('male1'),'role','authenticated')::text,true);
select pg_temp.assert(not (select can_send from public.zyra_open_family_message_circle(pg_temp.actor('male1'))),'one unpaid linked Guardian makes Circle read-only');
select pg_temp.reject('select public.zyra_send_family_message('''||pg_temp.state('thread')||''',''unpaid participant'')','family_message_read_only','Circle paid send boundary');
select pg_temp.reject('select * from public.family_message_report_evidence','42501','Circle moderation evidence private');
select pg_temp.reject('select public.zyra_close_family_message_report(gen_random_uuid(),false)','42501','Circle report closure service-only');
select pg_temp.reject('select public.zyra_purge_expired_family_message_data()','42501','Circle purge service-only');
reset role;

-- F01/F03/F05/F06/F07 have separate real fixtures and concurrency schedules.
-- Here verify their private authorities remain closed in the combined schema;
-- F04 remains excluded and must be tested only in its guarded local fixture.
set local role authenticated;
select pg_temp.reject('select * from public.journey_guardian_assignments','42501','F02 assignment ledger stays private');
select pg_temp.reject('select * from public.zyra_attempt_participant_rows','42501','F02 canonical participant view stays private');
reset role;
do $f02_shape$
begin
  if (select count(*) from pg_attribute where attrelid='public.zyra_attempt_participant_rows'::regclass and attnum>0 and not attisdropped)<>6 then
    raise exception 'SERVER0 combined F02 canonical six-column shape drifted';
  end if;
  raise notice 'SERVER0 combined PASS: F02 canonical six-column shape retained';
end;
$f02_shape$;
do $$ begin
  raise notice 'SERVER0 combined limitations: F01/F03/F05/F06/F07 functional and two-worker proofs are separate required suites; F04 is local-only and excluded';
end; $$;
rollback;
