-- SERVER 0 V2 / DOC-ZYRA-0329 / OA-ZYRA-317, OA-ZYRA-319.
-- Inherited Sep24 contract: isolated AFTER-PAYLOAD full-schema regression.
-- All data/DDL is transaction-local and rolls back. No grant, release switch,
-- provider, live database or payment service is changed. Client boundaries use
-- actual authenticated/JWT impersonation. Private preparation bodies that have
-- no client EXECUTE grant are exercised by the trusted synthetic owner only;
-- the preceding impersonation checks prove they remain inaccessible to clients.
\set ON_ERROR_STOP on
begin;
\ir fixtures/server0_v2_full_schema_prestate.sql
grant select on server0_v2_fixture_actors to authenticated,service_role;
create temporary table server0_contract_state(key text primary key,value text);
grant select,insert,update on server0_contract_state to authenticated,service_role;
create function pg_temp.ct_actor(p_label text) returns uuid language sql stable security invoker as $$
  select id from server0_v2_fixture_actors where fixture_label=p_label;
$$;
create function pg_temp.ct_state(p_key text) returns uuid language sql stable security invoker as $$
  select value::uuid from server0_contract_state where key=p_key;
$$;
create function pg_temp.ct_assert(p_ok boolean,p_label text) returns void language plpgsql security invoker as $$
begin
  if p_ok is distinct from true then raise exception 'SERVER0 contract FAIL: %',p_label; end if;
  raise notice 'SERVER0 contract PASS: %',p_label;
end;
$$;
create function pg_temp.ct_reject(p_sql text,p_error text,p_label text) returns void language plpgsql security invoker as $$
declare rejected boolean:=false;
begin
  begin execute p_sql;
  exception when others then
    if sqlstate=p_error or sqlerrm=p_error then rejected:=true;
    else raise exception 'SERVER0 contract wrong refusal %: % / %',p_label,sqlstate,sqlerrm; end if;
  end;
  if not rejected then raise exception 'SERVER0 contract unexpectedly allowed: %',p_label; end if;
  raise notice 'SERVER0 contract PASS refusal: %',p_label;
end;
$$;
grant execute on function pg_temp.ct_actor(text),pg_temp.ct_state(text),pg_temp.ct_assert(boolean,text),pg_temp.ct_reject(text,text,text) to authenticated,service_role;

-- Actual client denials precede trusted constraint/body regressions.
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.ct_actor('male1'),'role','authenticated')::text,true);
select pg_temp.ct_reject('select public.zyra_start_verified_seeker_trial(gen_random_uuid(),gen_random_uuid(),repeat(''a'',64))','42501','client cannot start a verified trial');
select pg_temp.ct_reject('select public.zyra_accept_family_invitation(gen_random_uuid())','42501','Family invitation activation remains held');
select pg_temp.ct_reject('select public.zyra_family_formula_monthly_pence(1,1)','42501','client cannot call service pricing kernel');
select pg_temp.ct_reject('select * from private.verified_people','42501','verified human ledger private');
select pg_temp.ct_reject('select * from private.seeker_trial_ledger','42501','trial ledger private');
select pg_temp.ct_reject('select * from public.family_subscriptions','42501','Family billing private');
select pg_temp.ct_reject('insert into public.family_seat_assignments(family_subscription_id,member_id,role) values(gen_random_uuid(),auth.uid(),''seeker'')','42501','client cannot self-mint Family seat');
select pg_temp.ct_reject('insert into public.family_ownership_transfers(family_subscription_id,current_owner_id,replacement_owner_id,replacement_role) values(gen_random_uuid(),auth.uid(),gen_random_uuid(),''seeker'')','42501','client cannot transfer Family ownership directly');
reset role;

-- Direct entitlement states, including cancellation coverage, expiry, bounded
-- grace and wrong-role denial. Caller-scoped wrapper is the public surface.
update public.subscriptions set plan_type='seeker_premium',expires_at=now()+interval '1 day'
where user_id=pg_temp.ct_actor('male1');
set local role authenticated;
select pg_temp.ct_assert(public.zyra_my_paid_access('seeker'),'active direct One paid access');
select pg_temp.ct_assert(not public.zyra_my_paid_access('guardian'),'direct entitlement is role-specific');
select pg_temp.ct_assert(not public.zyra_my_paid_access('unsupported'),'unsupported paid role is false');
reset role;
update public.subscriptions set expires_at=now()-interval '1 day' where user_id=pg_temp.ct_actor('male1');
set local role authenticated;
select pg_temp.ct_assert(not public.zyra_my_paid_access('seeker'),'expired direct One has no access');
reset role;
update public.subscriptions set billing_grace_started_at=now()-interval '1 day',billing_grace_until=now()+interval '1 day'
where user_id=pg_temp.ct_actor('male1');
set local role authenticated;
select pg_temp.ct_assert(public.zyra_my_paid_access('seeker'),'active billing grace retains access');
reset role;
select pg_temp.ct_reject('update public.subscriptions set billing_grace_until=now()+interval ''17 days'' where user_id='''||pg_temp.ct_actor('male1')||'''','23514','billing grace cannot exceed 16 days');
select pg_temp.ct_reject('update public.subscriptions set billing_period=''yearly'' where user_id='''||pg_temp.ct_actor('male1')||'''','23514','new direct billing is monthly only');
update public.subscriptions set status='cancelled',coverage_ends_at=now()+interval '1 day',billing_grace_started_at=null,billing_grace_until=null
where user_id=pg_temp.ct_actor('male1');
set local role authenticated;
select pg_temp.ct_assert(public.zyra_my_paid_access('seeker'),'cancelled direct plan retains funded period');
reset role;
update public.subscriptions set coverage_ends_at=now()-interval '1 day' where user_id=pg_temp.ct_actor('male1');
set local role authenticated;
select pg_temp.ct_assert(not public.zyra_my_paid_access('seeker'),'cancelled direct coverage expires');
reset role;

-- Verified-person bindings use synthetic opaque hashes only. One real human
-- may have distinct Seeker/Guardian roles, never duplicate accounts per role.
insert into private.verified_people(id,provider_code,provider_person_ref_hash)
values('33000000-0000-0000-0000-000000000101','stripe',repeat('1',64)),
      ('33000000-0000-0000-0000-000000000102','stripe',repeat('2',64)),
      ('33000000-0000-0000-0000-000000000103','stripe',repeat('3',64)),
      ('33000000-0000-0000-0000-000000000104','stripe',repeat('4',64));
insert into private.verified_person_accounts(verified_person_id,user_id,role) values
('33000000-0000-0000-0000-000000000101',pg_temp.ct_actor('male1'),'seeker'),
('33000000-0000-0000-0000-000000000102',pg_temp.ct_actor('male2'),'seeker'),
('33000000-0000-0000-0000-000000000103',pg_temp.ct_actor('fem1'),'seeker'),
('33000000-0000-0000-0000-000000000101',pg_temp.ct_actor('gmain'),'guardian'),
('33000000-0000-0000-0000-000000000104',pg_temp.ct_actor('gadd'),'guardian');
select pg_temp.ct_reject('insert into private.verified_person_accounts(verified_person_id,user_id,role) values(''33000000-0000-0000-0000-000000000101'','''||pg_temp.ct_actor('fem2')||''',''seeker'')','23505','one verified person cannot bind a second Seeker account');
select pg_temp.ct_reject('insert into private.verified_people(provider_code,provider_person_ref_hash) values(''stripe'',repeat(''1'',64))','23505','provider human hash cannot be replayed');
set local role service_role;
select set_config('request.jwt.claims','{"role":"service_role"}',true);
select pg_temp.ct_assert(public.zyra_family_formula_monthly_pence(1,1)=4998,'Family two-place gross has no discount');
select pg_temp.ct_assert(public.zyra_family_formula_monthly_pence(1,2)=6647,'Family third place receives five-percent discount');
select pg_temp.ct_assert(public.zyra_family_formula_monthly_pence(10,10)=29988,'Family discount caps at forty percent');
select pg_temp.ct_reject('select public.zyra_family_formula_monthly_pence(0,0)','invalid_family_place_count','empty Family rejected');
select pg_temp.ct_reject('select public.zyra_family_formula_monthly_pence(11,0)','invalid_family_place_count','Family place maximum enforced');
select pg_temp.ct_reject('select public.zyra_start_verified_seeker_trial('''||pg_temp.ct_actor('fem2')||''',''33000000-0000-0000-0000-000000000101'',repeat(''a'',64))','verified_seeker_binding_required','trial requires matching verified account');
select public.zyra_start_verified_seeker_trial(pg_temp.ct_actor('male2'),'33000000-0000-0000-0000-000000000102',repeat('a',64));
select pg_temp.ct_reject('select public.zyra_start_verified_seeker_trial('''||pg_temp.ct_actor('male2')||''',''33000000-0000-0000-0000-000000000102'',repeat(''b'',64))','seeker_trial_already_used','same verified human cannot repeat trial');
reset role;
select pg_temp.ct_assert((select status='active' and ends_at=started_at+interval '14 days' from private.seeker_trial_ledger where claimed_by=pg_temp.ct_actor('male2')),'verified trial is exactly fourteen days');

-- Family rows and seats remain preparation-only. Owner setup checks the
-- actual deferred constraint, not a replacement or a fake owner check.
select set_config('request.jwt.claims','{}',true);
insert into public.family_subscriptions(id,owner_id,owner_role,status,seeker_places,guardian_places,coverage_ends_at)
values('33000000-0000-0000-0000-000000000201',pg_temp.ct_actor('male1'),'seeker','active',2,1,now()+interval '30 days');
insert into public.family_seat_assignments(id,family_subscription_id,member_id,role,funded_until) values
('33000000-0000-0000-0000-000000000211','33000000-0000-0000-0000-000000000201',pg_temp.ct_actor('male1'),'seeker',now()+interval '30 days'),
('33000000-0000-0000-0000-000000000212','33000000-0000-0000-0000-000000000201',pg_temp.ct_actor('gmain'),'guardian',now()+interval '30 days');
set constraints family_owner_row_guard,family_owner_seat_guard immediate;
set constraints family_owner_row_guard,family_owner_seat_guard deferred;
select pg_temp.ct_assert((select status='family_forfeited' from private.seeker_trial_ledger where claimed_by=pg_temp.ct_actor('male1')),'Family Seeker seat forfeits future trial');
select pg_temp.ct_reject('insert into public.family_seat_assignments(family_subscription_id,member_id,role) values(''33000000-0000-0000-0000-000000000201'','''||pg_temp.ct_actor('fem2')||''',''seeker'')','verified_family_member_required','unverified Family member rejected');
select pg_temp.ct_reject('insert into public.family_seat_assignments(family_subscription_id,member_id,role) values(''33000000-0000-0000-0000-000000000201'','''||pg_temp.ct_actor('gadd')||''',''guardian'')','family_guardian_capacity_exceeded','Guardian seat capacity enforced');
select pg_temp.ct_reject('update public.family_subscriptions set seeker_places=0 where id=''33000000-0000-0000-0000-000000000201''','family_seeker_places_still_funded','cannot cut funded Seeker places');
select pg_temp.ct_reject('update public.family_subscriptions set guardian_places=0 where id=''33000000-0000-0000-0000-000000000201''','family_guardian_places_still_funded','cannot cut funded Guardian places');
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.ct_actor('male1'),'role','authenticated')::text,true);
select pg_temp.ct_assert(public.zyra_my_paid_access('seeker'),'funded Family Seeker seat provides paid access without direct One');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.ct_actor('gmain'),'role','authenticated')::text,true);
select pg_temp.ct_assert(public.zyra_my_paid_access('guardian'),'funded Family Guardian seat provides Guardian access');
select pg_temp.ct_assert(not public.zyra_my_paid_access('seeker'),'Family Guardian seat cannot cross roles');
reset role;
update public.family_subscriptions set status='cancel_at_period_end' where id='33000000-0000-0000-0000-000000000201';
set local role authenticated;
select pg_temp.ct_assert(public.zyra_my_paid_access('guardian'),'Family cancellation preserves funded coverage');
reset role;
update public.family_subscriptions set status='billing_grace',billing_grace_started_at=now()-interval '1 day',billing_grace_until=now()+interval '1 day' where id='33000000-0000-0000-0000-000000000201';
set local role authenticated;
select pg_temp.ct_assert(public.zyra_my_paid_access('guardian'),'Family billing grace preserves access');
reset role;
update public.family_subscriptions set billing_grace_until=now()-interval '1 hour' where id='33000000-0000-0000-0000-000000000201';
set local role authenticated;
select pg_temp.ct_assert(not public.zyra_my_paid_access('guardian'),'expired Family grace has no access');
reset role;
update public.family_subscriptions set status='active',billing_grace_started_at=null,billing_grace_until=null where id='33000000-0000-0000-0000-000000000201';
update public.family_seat_assignments set removed_at=now() where id='33000000-0000-0000-0000-000000000212';
set local role authenticated;
select pg_temp.ct_assert(public.zyra_my_paid_access('guardian'),'removed seat retains already funded coverage');
reset role;
update public.family_seat_assignments set funded_until=now()-interval '1 hour' where id='33000000-0000-0000-0000-000000000212';
set local role authenticated;
select pg_temp.ct_assert(not public.zyra_my_paid_access('guardian'),'removed seat coverage eventually expires');
reset role;
update public.family_seat_assignments set removed_at=null,funded_until=now()+interval '30 days' where id='33000000-0000-0000-0000-000000000212';

-- Trusted owner exercises held invitation body without adding any EXECUTE
-- grant. Role/recipient/expiry/billing/capacity checks remain the real ones.
insert into public.family_membership_invitations(id,family_subscription_id,invited_by,invited_user_id,role)
values('33000000-0000-0000-0000-000000000301','33000000-0000-0000-0000-000000000201',pg_temp.ct_actor('male1'),pg_temp.ct_actor('male2'),'seeker');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.ct_actor('fem1'),'role','authenticated')::text,true);
select pg_temp.ct_reject('select public.zyra_accept_family_invitation(''33000000-0000-0000-0000-000000000301'')','family_invitation_not_found','invitation cannot be accepted by another user');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.ct_actor('male2'),'role','authenticated')::text,true);
select public.zyra_accept_family_invitation('33000000-0000-0000-0000-000000000301');
select pg_temp.ct_assert((select status='accepted' and responded_at is not null from public.family_membership_invitations where id='33000000-0000-0000-0000-000000000301'),'held invitation preparation accepts intended verified member');
select pg_temp.ct_assert((select status='family_forfeited' and ends_at<=now() from private.seeker_trial_ledger where claimed_by=pg_temp.ct_actor('male2')),'Family joining stops existing Seeker trial');
select pg_temp.ct_reject('select public.zyra_accept_family_invitation(''33000000-0000-0000-0000-000000000301'')','family_invitation_not_pending','invitation cannot be replayed');
select pg_temp.ct_reject('insert into public.family_seat_assignments(family_subscription_id,member_id,role) values(''33000000-0000-0000-0000-000000000201'','''||pg_temp.ct_actor('fem1')||''',''seeker'')','family_seeker_capacity_exceeded','Seeker seat capacity enforced');
insert into public.family_membership_invitations(id,family_subscription_id,invited_by,invited_user_id,role,created_at,expires_at)
values('33000000-0000-0000-0000-000000000302','33000000-0000-0000-0000-000000000201',pg_temp.ct_actor('male1'),pg_temp.ct_actor('gadd'),'guardian',now()-interval '8 days',now()-interval '1 day');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.ct_actor('gadd'),'role','authenticated')::text,true);
select pg_temp.ct_reject('select public.zyra_accept_family_invitation(''33000000-0000-0000-0000-000000000302'')','family_invitation_expired','seven-day expired invitation refuses acceptance');
insert into public.family_membership_invitations(id,family_subscription_id,invited_by,invited_user_id,role)
values('33000000-0000-0000-0000-000000000303','33000000-0000-0000-0000-000000000201',pg_temp.ct_actor('male1'),pg_temp.ct_actor('fem1'),'guardian');
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.ct_actor('fem1'),'role','authenticated')::text,true);
select pg_temp.ct_reject('select public.zyra_accept_family_invitation(''33000000-0000-0000-0000-000000000303'')','family_invitation_role_mismatch','verified Seeker cannot accept Guardian seat');
update public.family_membership_invitations set created_at=now(),expires_at=now()+interval '7 days' where id='33000000-0000-0000-0000-000000000302';
update public.family_subscriptions set status='expired' where id='33000000-0000-0000-0000-000000000201';
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.ct_actor('gadd'),'role','authenticated')::text,true);
select pg_temp.ct_reject('select public.zyra_accept_family_invitation(''33000000-0000-0000-0000-000000000302'')','family_not_available','expired Family cannot accept new seat');
update public.family_subscriptions set status='active' where id='33000000-0000-0000-0000-000000000201';
select pg_temp.ct_reject('insert into public.family_membership_invitations(family_subscription_id,invited_by,invited_user_id,role,expires_at) values(''33000000-0000-0000-0000-000000000201'','''||pg_temp.ct_actor('male1')||''','''||pg_temp.ct_actor('fem1')||''',''seeker'',now()+interval ''8 days'')','23514','invitation window is exactly seven days');

-- Owner integrity and transfer renewal boundary use the actual deferred
-- checks. Each refusal rolls back only its own attempted mutation.
select set_config('request.jwt.claims','{}',true);
select pg_temp.ct_reject('update public.family_subscriptions set owner_id='''||pg_temp.ct_actor('fem2')||''' where id=''33000000-0000-0000-0000-000000000201''; set constraints family_owner_row_guard immediate','verified_family_owner_required','Family owner must be verified');
select pg_temp.ct_reject('update public.family_subscriptions set owner_id='''||pg_temp.ct_actor('fem1')||''' where id=''33000000-0000-0000-0000-000000000201''; set constraints family_owner_row_guard immediate','family_owner_seat_required','Family owner must retain a funded seat');
select pg_temp.ct_reject('insert into public.family_subscriptions(id,owner_id,owner_role,status,seeker_places,guardian_places) values(''33000000-0000-0000-0000-000000000202'','''||pg_temp.ct_actor('gmain')||''',''guardian'',''pending'',1,0); set constraints family_owner_row_guard immediate','family_owner_place_required','Family owner role must have a purchased place');
select pg_temp.ct_reject('update public.family_seat_assignments set removed_at=now(),funded_until=now() where id=''33000000-0000-0000-0000-000000000211''; set constraints family_owner_seat_guard immediate','family_owner_seat_required','funded owner seat cannot be removed');
select pg_temp.ct_reject('insert into public.family_ownership_transfers(family_subscription_id,current_owner_id,replacement_owner_id,replacement_role) values(''33000000-0000-0000-0000-000000000201'','''||pg_temp.ct_actor('fem1')||''','''||pg_temp.ct_actor('male2')||''',''seeker'')','family_transfer_owner_mismatch','transfer requires actual current owner');
select pg_temp.ct_reject('insert into public.family_ownership_transfers(family_subscription_id,current_owner_id,replacement_owner_id,replacement_role) values(''33000000-0000-0000-0000-000000000201'','''||pg_temp.ct_actor('male1')||''','''||pg_temp.ct_actor('fem1')||''',''seeker'')','family_transfer_existing_member_required','replacement must already be a Family member');
select pg_temp.ct_reject('insert into public.family_ownership_transfers(family_subscription_id,current_owner_id,replacement_owner_id,replacement_role,status,accepted_at,replacement_purchase_confirmed_at,effective_at) values(''33000000-0000-0000-0000-000000000201'','''||pg_temp.ct_actor('male1')||''','''||pg_temp.ct_actor('male2')||''',''seeker'',''scheduled'',now(),now(),now()+interval ''29 days'')','family_transfer_must_start_at_renewal','ownership changes only at funded renewal');
savepoint missing_transfer_binding;
delete from private.verified_person_accounts where user_id=pg_temp.ct_actor('male2') and role='seeker';
select pg_temp.ct_reject('insert into public.family_ownership_transfers(family_subscription_id,current_owner_id,replacement_owner_id,replacement_role) values(''33000000-0000-0000-0000-000000000201'','''||pg_temp.ct_actor('male1')||''','''||pg_temp.ct_actor('male2')||''',''seeker'')','family_transfer_verified_member_required','replacement verification is rechecked at transfer');
rollback to savepoint missing_transfer_binding;
insert into public.family_ownership_transfers(family_subscription_id,current_owner_id,replacement_owner_id,replacement_role,status,accepted_at,replacement_purchase_confirmed_at,effective_at)
values('33000000-0000-0000-0000-000000000201',pg_temp.ct_actor('male1'),pg_temp.ct_actor('male2'),'seeker','scheduled',now(),now(),now()+interval '30 days');
select pg_temp.ct_assert((select count(*)=1 from public.family_ownership_transfers),'valid renewal transfer scheduled without activation');
set constraints family_owner_row_guard,family_owner_seat_guard immediate;

-- Circle safety: report snapshot is bounded and protected, survives sender
-- profile deletion, closes only for the service role, and respects retention
-- and legal hold. Deleted-member labels do not resurrect membership epochs.
update public.subscriptions set plan_type='seeker_premium',status='active',expires_at=null,coverage_ends_at=null where user_id=pg_temp.ct_actor('fem1');
update public.subscriptions set plan_type='wali_premium' where user_id=pg_temp.ct_actor('gb2');
insert into public.wali_links(seeker_id,wali_id,status,is_main,relationship)
values(pg_temp.ct_actor('fem1'),pg_temp.ct_actor('gb2'),'active',true,'father');
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.ct_actor('fem1'),'role','authenticated')::text,true);
insert into server0_contract_state select 'thread',thread_id::text from public.zyra_open_family_message_circle(pg_temp.ct_actor('fem1'));
reset role;
update public.family_message_memberships set joined_at=now()-interval '1 minute',readable_from=now()-interval '1 minute' where thread_id=pg_temp.ct_state('thread');
set local role authenticated;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.ct_actor('gb2'),'role','authenticated')::text,true);
insert into server0_contract_state select 'reported_message',public.zyra_send_family_message(pg_temp.ct_state('thread'),'Reported synthetic Circle content')::text;
select set_config('request.jwt.claims',json_build_object('sub',pg_temp.ct_actor('fem1'),'role','authenticated')::text,true);
insert into server0_contract_state select 'report',public.zyra_report_family_message(pg_temp.ct_state('thread'),pg_temp.ct_state('reported_message'),'harassment')::text;
select pg_temp.ct_reject('select * from public.family_message_report_evidence','42501','report evidence hidden from reporter');
select pg_temp.ct_reject('select public.zyra_close_family_message_report('''||pg_temp.ct_state('report')||''',false)','42501','reporter cannot close own case');
reset role;
select pg_temp.ct_assert((select reported_body='Reported synthetic Circle content' and jsonb_array_length(immediate_context) between 1 and 11 from public.family_message_report_evidence where report_id=pg_temp.ct_state('report')),'report snapshot captures message and bounded context');
delete from public.profiles where id=pg_temp.ct_actor('gb2');
select pg_temp.ct_assert((select sender_id is null and sender_deleted_at is not null from public.family_messages where id=pg_temp.ct_state('reported_message')),'sender deletion anonymises retained message and records date');
select pg_temp.ct_assert(exists(select 1 from public.family_message_report_evidence where report_id=pg_temp.ct_state('report')),'protected evidence survives profile/report cascade');
set local role authenticated;
select pg_temp.ct_assert((select sender_first_name='Deleted member' from public.zyra_family_messages(pg_temp.ct_state('thread')) where message_id=pg_temp.ct_state('reported_message')),'deleted sender is honestly labelled');
reset role;
set local role service_role;
select set_config('request.jwt.claims','{"role":"service_role"}',true);
select public.zyra_close_family_message_report(pg_temp.ct_state('report'),false);
reset role;
select pg_temp.ct_assert((select closed_at=now() and retain_until=now()+interval '24 months' and not legal_hold from public.family_message_report_evidence where report_id=pg_temp.ct_state('report')),'case closure sets twenty-four-month evidence retention');
update public.family_messages set sender_deleted_at=now()-interval '13 months' where id=pg_temp.ct_state('reported_message');
set local role service_role;
select * from public.zyra_purge_expired_family_message_data();
reset role;
select pg_temp.ct_assert(exists(select 1 from public.family_messages where id=pg_temp.ct_state('reported_message')),'active evidence retention protects old anonymous message');
set local role service_role;
select public.zyra_close_family_message_report(pg_temp.ct_state('report'),true);
reset role;
select pg_temp.ct_assert((select legal_hold and retain_until is null from public.family_message_report_evidence where report_id=pg_temp.ct_state('report')),'service closure can require indefinite legal hold');
update public.family_message_report_evidence set retain_until=now()-interval '1 day',legal_hold=true where report_id=pg_temp.ct_state('report');
set local role service_role;
select * from public.zyra_purge_expired_family_message_data();
reset role;
select pg_temp.ct_assert(exists(select 1 from public.family_message_report_evidence where report_id=pg_temp.ct_state('report')) and exists(select 1 from public.family_messages where id=pg_temp.ct_state('reported_message')),'legal hold overrides expired retention');
update public.family_message_report_evidence set legal_hold=false where report_id=pg_temp.ct_state('report');
set local role service_role;
select * from public.zyra_purge_expired_family_message_data();
reset role;
select pg_temp.ct_assert(not exists(select 1 from public.family_messages where id=pg_temp.ct_state('reported_message')) and not exists(select 1 from public.family_message_report_evidence where report_id=pg_temp.ct_state('report')),'expired closed evidence and twelve-month deleted-sender message purge');
rollback;
