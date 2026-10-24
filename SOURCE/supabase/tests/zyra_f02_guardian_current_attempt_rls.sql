-- F02 / OA-ZYRA-290/291/305. Synthetic direct authenticated-role/JWT proof.
-- Run only after the new isolated bootstrap and staged F02 candidate, in the
-- same pinned PG17 disposable database. Fixtures always roll back. This is
-- not a PostgREST/realtime/live-project or naturally-positive member proof.
\set ON_ERROR_STOP on

begin;
do $synthetic_guard$
begin
  if current_database() not like 'zyra_oa305_f02_%'
     or current_setting('zyra.synthetic_f02',true) is distinct from 'yes'
     or current_user <> 'postgres'
  then raise exception 'F02 tests require the isolated synthetic bootstrap'; end if;
end;
$synthetic_guard$;

do $unchanged_boundaries$
declare v_row record; v_actual text;
begin
  for v_row in select * from public.f02_test_snapshots loop
    if v_row.object_key='messages_insert' then
      select pg_get_expr(polwithcheck,polrelid) into v_actual from pg_policy
      where polrelid='public.messages'::regclass and polname='messages_insert';
    elsif v_row.object_key like 'function_acl:%' then
      select coalesce(proacl::text,'<null>') into v_actual from pg_proc
      where oid=substring(v_row.object_key from 14)::regprocedure;
    elsif v_row.object_key like 'acl:%' then
      select coalesce(relacl::text,'<null>') into v_actual from pg_class
      where oid=to_regclass('public.' || substring(v_row.object_key from 5));
    else
      v_actual := pg_get_functiondef(v_row.object_key::regprocedure);
    end if;
    if v_actual is distinct from v_row.definition then
      raise exception 'F02 changed a held/unrelated boundary: %',v_row.object_key;
    end if;
  end loop;
  if (select count(*) from pg_policy where polrelid='public.messages'::regclass)<>2
     or (select count(*) from pg_policy where polrelid='public.conversations'::regclass)<>1
  then raise exception 'F02 policy count changed unexpectedly'; end if;
  raise notice 'F02 PASS unchanged summary/consent/link/block helpers, grants and Seeker INSERT';
end;
$unchanged_boundaries$;

insert into public.profiles(id,first_name,role) values
('00000000-0000-0000-0000-000000000001','Synthetic Seeker A','seeker'),
('00000000-0000-0000-0000-000000000002','Synthetic Seeker B','seeker'),
('00000000-0000-0000-0000-000000000003','Synthetic Stranger','seeker'),
('00000000-0000-0000-0000-000000000004','Synthetic Seeker C','seeker'),
('00000000-0000-0000-0000-000000000005','Synthetic Seeker D','seeker'),
('00000000-0000-0000-0000-000000000006','Synthetic Seeker E','seeker'),
('00000000-0000-0000-0000-000000000010','Synthetic Late Main','guardian'),
('00000000-0000-0000-0000-000000000011','Synthetic Support','guardian'),
('00000000-0000-0000-0000-000000000012','Synthetic Summary Only','guardian'),
('00000000-0000-0000-0000-000000000013','Synthetic Promoted','guardian'),
('00000000-0000-0000-0000-000000000014','Synthetic Other Main','guardian');
insert into public.matches(id,seeker_a_id,seeker_b_id,status) values
('00000000-0000-0000-0000-000000000100','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002','active'),
('00000000-0000-0000-0000-000000000200','00000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000005','active'),
('00000000-0000-0000-0000-000000000300','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000006','ended');
insert into public.journey_attempts(id,match_id,status,started_at,ended_at) values
('00000000-0000-0000-0000-000000000101','00000000-0000-0000-0000-000000000100','ended',now()-interval '40 days',now()-interval '30 days'),
('00000000-0000-0000-0000-000000000102','00000000-0000-0000-0000-000000000100','ended',now()-interval '20 days',now()-interval '10 days'),
('00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000100','active',now()-interval '2 days',null),
('00000000-0000-0000-0000-000000000104','00000000-0000-0000-0000-000000000100','potential',null,null),
('00000000-0000-0000-0000-000000000201','00000000-0000-0000-0000-000000000200','active',now()-interval '1 day',null),
('00000000-0000-0000-0000-000000000301','00000000-0000-0000-0000-000000000300','ended',now()-interval '40 days',now()-interval '30 days');
insert into public.conversations(id,attempt_id,status)
select id, id, case when status='active' then 'active' else 'closed' end from public.journey_attempts;
insert into public.messages(id,conversation_id,sender_id,content)
select a.id,a.id,m.seeker_a_id,'Synthetic F02 fixture only'
from public.journey_attempts a join public.matches m on m.id=a.match_id;
insert into public.timelines(id,attempt_id) select id,id from public.journey_attempts;
insert into public.timeline_milestones(id,timeline_id) select id,id from public.journey_attempts;
insert into public.journey_family_answers(id,attempt_id) select id,id from public.journey_attempts;

insert into public.wali_links(id,seeker_id,wali_id,status,is_main) values
('00000000-0000-0000-0000-000000000310','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000010','active',true),
('00000000-0000-0000-0000-000000000311','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000011','active',false),
('00000000-0000-0000-0000-000000000312','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000012','active',false),
('00000000-0000-0000-0000-000000000313','00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000013','active',false),
('00000000-0000-0000-0000-000000000314','00000000-0000-0000-0000-000000000004','00000000-0000-0000-0000-000000000014','active',true);

create function pg_temp.f02_expect_counts(label text, expected integer)
returns void language plpgsql security invoker as $expect$
declare n integer;
begin
  select count(*) into n from public.conversations;
  if n<>expected then raise exception 'F02 % conversations: % expected %',label,n,expected; end if;
  select count(*) into n from public.messages;
  if n<>expected then raise exception 'F02 % messages: % expected %',label,n,expected; end if;
  select count(*) into n from public.zyra_my_attempt_participation;
  if n<>expected then raise exception 'F02 % participation: % expected %',label,n,expected; end if;
  select count(*) into n from public.timelines;
  if n<>expected then raise exception 'F02 % timelines: % expected %',label,n,expected; end if;
  select count(*) into n from public.timeline_milestones;
  if n<>expected then raise exception 'F02 % milestones: % expected %',label,n,expected; end if;
  select count(*) into n from public.journey_family_answers;
  if n<>expected then raise exception 'F02 % family answers: % expected %',label,n,expected; end if;
  raise notice 'F02 PASS % (% exact readable attempt)',label,expected;
end;
$expect$;
grant execute on function pg_temp.f02_expect_counts(text,integer) to authenticated;
create function pg_temp.f02_expect_identity(label text, expected integer)
returns void language plpgsql security invoker as $identity$
declare n integer;
begin
  select count(*) into n from public.zyra_counterpart_card('00000000-0000-0000-0000-000000000100');
  if n<>expected then raise exception 'F02 % current counterpart: % expected %',label,n,expected; end if;
  if exists(select 1 from public.zyra_counterpart_card('00000000-0000-0000-0000-000000000300')) then
    raise exception 'F02 % ended-only counterpart leaked',label; end if;
  if exists(select 1 from public.zyra_counterpart_card('00000000-0000-0000-0000-000000000200')) then
    raise exception 'F02 % foreign counterpart leaked',label; end if;
  select count(id) into n from public.matches;
  if n<>expected then raise exception 'F02 % match identity: % expected %',label,n,expected; end if;
  raise notice 'F02 PASS % current match/card: %; ended/foreign identity denied',label,expected;
end;
$identity$;
grant execute on function pg_temp.f02_expect_identity(text,integer) to authenticated;

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000010"}',true);
select pg_temp.f02_expect_counts('new Main: current before-link attempt yes; both ended/potential/foreign no',1);
select pg_temp.f02_expect_identity('new Main',1);
do $guardian_send_denied$
begin
  begin
    insert into public.messages(id,conversation_id,sender_id,content) values
      ('00000000-0000-0000-0000-000000000900','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000010','Synthetic denied Guardian send');
    raise exception 'Guardian send was activated';
  exception when insufficient_privilege then null; end;
  raise notice 'F02 PASS actual Guardian message INSERT denied';
end;
$guardian_send_denied$;
do $private_denials$
begin
  begin perform 1 from public.zyra_attempt_participant_rows; raise exception 'unscoped view exposed';
  exception when insufficient_privilege then null; end;
  begin perform 1 from public.journey_guardian_assignments; raise exception 'assignment ledger exposed';
  exception when insufficient_privilege then null; end;
  begin perform 1 from public.guardian_journey_history_consents; raise exception 'consent ledger exposed';
  exception when insufficient_privilege then null; end;
  raise notice 'F02 PASS private base views/ledgers denied to actual authenticated role';
end;
$private_denials$;

select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000001"}',true);
select pg_temp.f02_expect_counts('Seeker A exact archives unchanged',5);
insert into public.messages(id,conversation_id,sender_id,content) values
  ('00000000-0000-0000-0000-000000000900','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000001','Synthetic positive current Seeker send');
reset role;
delete from public.messages where id='00000000-0000-0000-0000-000000000900';
set local role authenticated;
do $seeker_match_archive$ begin
  if (select count(id) from public.matches)<>2 then raise exception 'Seeker match archives changed'; end if;
  raise notice 'F02 PASS Seeker match identity archives unchanged';
end; $seeker_match_archive$;
select * from public.zyra_guardian_journey_access('00000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000103',true);
select * from public.zyra_guardian_history_consent('00000000-0000-0000-0000-000000000010',true);
select * from public.zyra_guardian_history_consent('00000000-0000-0000-0000-000000000012',true);
do $assignment_denials$
begin
  begin perform * from public.zyra_guardian_journey_access('00000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000101',true);
    raise exception 'ended assignment granted';
  exception when raise_exception then if sqlerrm<>'active_owned_journey_not_found' then raise; end if; end;
  begin perform * from public.zyra_guardian_journey_access('00000000-0000-0000-0000-000000000014','00000000-0000-0000-0000-000000000103',true);
    raise exception 'foreign link granted';
  exception when raise_exception then if sqlerrm<>'active_guardian_link_not_found' then raise; end if; end;
  begin perform * from public.zyra_guardian_journey_access('00000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000201',true);
    raise exception 'foreign attempt granted';
  exception when raise_exception then if sqlerrm<>'active_owned_journey_not_found' then raise; end if; end;
  raise notice 'F02 PASS ended/foreign assignment writes denied';
end;
$assignment_denials$;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000002"}',true);
select pg_temp.f02_expect_counts('Seeker B exact archives unchanged',4);
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000010"}',true);
select pg_temp.f02_expect_counts('Main summary opt-in never grants old chat',1);
select pg_temp.f02_expect_identity('Main summary opt-in',1);
do $summary_only_shape$
begin
  if (select count(*) from public.zyra_attempt_summary_for_guardian('00000000-0000-0000-0000-000000000001'))<>4 then
    raise exception 'Main four-field consent summary regression'; end if;
  if (select count(*) from jsonb_object_keys((select to_jsonb(summary) from public.zyra_attempt_summary_for_guardian('00000000-0000-0000-0000-000000000001') summary limit 1)))<>4 then
    raise exception 'summary widened'; end if;
  raise notice 'F02 PASS existing four-field consent summary preserved';
end;
$summary_only_shape$;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000012"}',true);
select pg_temp.f02_expect_counts('summary-only Additional receives no conversation or rich detail',0);
select pg_temp.f02_expect_identity('summary-only Additional',0);
do $summary_permission$
begin
  if (select count(*) from public.zyra_attempt_summary_for_guardian('00000000-0000-0000-0000-000000000001'))<>4 then
    raise exception 'Additional consent summary regression'; end if;
  raise notice 'F02 PASS summary-only Additional still receives authorized summary';
end;
$summary_permission$;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000011"}',true);
select pg_temp.f02_expect_counts('explicit own Additional assignment current detail',1);
select pg_temp.f02_expect_identity('explicit own Additional',1);
reset role;
insert into public.profile_blocks(blocker_id,blocked_id) values
  ('00000000-0000-0000-0000-000000000001','00000000-0000-0000-0000-000000000002');
set local role authenticated;
do $counterpart_block_denial$
begin
  if exists(select 1 from public.zyra_counterpart_card('00000000-0000-0000-0000-000000000100')) then
    raise exception 'existing counterpart block exclusion regressed'; end if;
  raise notice 'F02 PASS counterpart block exclusion unchanged';
end;
$counterpart_block_denial$;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000001"}',true);
do $blocked_send_denied$
begin
  begin insert into public.messages(id,conversation_id,sender_id,content) values
    ('00000000-0000-0000-0000-000000000900','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000001','Synthetic denied blocked send');
    raise exception 'blocked Seeker send permitted';
  exception when insufficient_privilege then null; end;
  raise notice 'F02 PASS unchanged blocked Seeker INSERT denied';
end;
$blocked_send_denied$;
reset role;
delete from public.profile_blocks;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000003"}',true);
select pg_temp.f02_expect_counts('authenticated stranger denied',0);
select pg_temp.f02_expect_identity('authenticated stranger',0);
select set_config('request.jwt.claims','{}',true);
select pg_temp.f02_expect_counts('authenticated null-principal denied',0);
select pg_temp.f02_expect_identity('null principal',0);
do $null_write$
begin
  begin perform * from public.zyra_guardian_journey_access('00000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000103',true);
    raise exception 'null principal wrote';
  exception when raise_exception then if sqlerrm<>'not_signed_in' then raise; end if; end;
end;
$null_write$;

reset role;
update public.journey_attempts set paused_by='00000000-0000-0000-0000-000000000001',paused_at=now()
where id='00000000-0000-0000-0000-000000000103';
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000010"}',true);
select pg_temp.f02_expect_counts('paused current Main support retained',1);
select pg_temp.f02_expect_identity('paused Main',1);
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000011"}',true);
select pg_temp.f02_expect_counts('paused current assigned support retained',1);
select pg_temp.f02_expect_identity('paused assigned support',1);

-- Both Main-role switches and re-links are exercised against the real link
-- trigger. New Main does not inherit ended chat; current support still works.
reset role;
update public.wali_links set is_main=false where id='00000000-0000-0000-0000-000000000310';
update public.wali_links set is_main=true where id='00000000-0000-0000-0000-000000000313';
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000010"}',true);
select pg_temp.f02_expect_counts('former Main without assignment loses current detail',0);
select pg_temp.f02_expect_identity('former Main without assignment',0);
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000013"}',true);
select pg_temp.f02_expect_counts('promoted Main current yes; ended no',1);
select pg_temp.f02_expect_identity('promoted Main',1);
reset role;
update public.wali_links set status='removed' where id='00000000-0000-0000-0000-000000000313';
set local role authenticated;
select pg_temp.f02_expect_counts('removed Main loses current detail immediately',0);
select pg_temp.f02_expect_identity('removed Main',0);
reset role;
update public.wali_links set status='active' where id='00000000-0000-0000-0000-000000000313';
set local role authenticated;
select pg_temp.f02_expect_counts('relinked current Main yes; old history no',1);
select pg_temp.f02_expect_identity('relinked Main',1);

select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000001"}',true);
select * from public.zyra_guardian_journey_access('00000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000103',false);
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000011"}',true);
select pg_temp.f02_expect_counts('Additional revoke removes rich detail immediately',0);
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000001"}',true);
select * from public.zyra_guardian_journey_access('00000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000103',true);
reset role;
update public.wali_links set status='removed' where id='00000000-0000-0000-0000-000000000311';
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000011"}',true);
select pg_temp.f02_expect_counts('removed assigned Guardian denied',0);
reset role;
update public.wali_links set status='active' where id='00000000-0000-0000-0000-000000000311';
set local role authenticated;
select pg_temp.f02_expect_counts('relinked Additional does not revive stale assignment',0);
select pg_temp.f02_expect_identity('relinked stale Additional',0);
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000001"}',true);
do $fresh_regrant$
begin
  if exists(select 1 from public.zyra_guardian_journey_access('00000000-0000-0000-0000-000000000011',null,null) where included) then
    raise exception 'stale grant rendered ON'; end if;
  if not exists(select 1 from public.zyra_guardian_journey_access('00000000-0000-0000-0000-000000000011','00000000-0000-0000-0000-000000000103',true) where included) then
    raise exception 'explicit fresh grant failed'; end if;
  raise notice 'F02 PASS stale read OFF and explicit relink regrant ON';
end;
$fresh_regrant$;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000011"}',true);
select pg_temp.f02_expect_counts('explicit regrant after relink restores current detail only',1);
select pg_temp.f02_expect_identity('freshly regranted Additional',1);

-- Current Journey ending removes both Main and Additional detail, including
-- when an old assignment is still present and past-summary consent exists.
reset role;
update public.journey_attempts set status='ended',ended_at=now(),paused_by=null,paused_at=null
where id='00000000-0000-0000-0000-000000000103';
update public.conversations set status='closed' where id='00000000-0000-0000-0000-000000000103';
set local role authenticated;
select pg_temp.f02_expect_counts('ended assigned Guardian rich detail removed',0);
select pg_temp.f02_expect_identity('ended assigned Guardian',0);
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000013"}',true);
select pg_temp.f02_expect_counts('ended Main rich detail removed',0);
select pg_temp.f02_expect_identity('ended Main',0);
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000012"}',true);
select pg_temp.f02_expect_counts('all-ended summary opt-in still never chat',0);
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000001"}',true);
select pg_temp.f02_expect_counts('Seeker archives retained after ending',5);
do $ended_send_denied$
begin
  begin insert into public.messages(id,conversation_id,sender_id,content) values
    ('00000000-0000-0000-0000-000000000900','00000000-0000-0000-0000-000000000103','00000000-0000-0000-0000-000000000001','Synthetic denied ended send');
    raise exception 'ended Seeker send permitted';
  exception when insufficient_privilege then null; end;
  raise notice 'F02 PASS unchanged ended Seeker INSERT denied';
end;
$ended_send_denied$;

-- A synthetic new attempt tests exact-attempt isolation only; the held
-- production Journey-return RPC is never invoked or activated by this suite.
reset role;
insert into public.journey_attempts(id,match_id,status,started_at) values
  ('00000000-0000-0000-0000-000000000105','00000000-0000-0000-0000-000000000100','active',now());
insert into public.conversations(id,attempt_id,status) values
  ('00000000-0000-0000-0000-000000000105','00000000-0000-0000-0000-000000000105','active');
insert into public.messages(id,conversation_id,sender_id,content) values
  ('00000000-0000-0000-0000-000000000105','00000000-0000-0000-0000-000000000105','00000000-0000-0000-0000-000000000001','Synthetic fresh attempt only');
insert into public.timelines(id,attempt_id) values
  ('00000000-0000-0000-0000-000000000105','00000000-0000-0000-0000-000000000105');
insert into public.timeline_milestones(id,timeline_id) values
  ('00000000-0000-0000-0000-000000000105','00000000-0000-0000-0000-000000000105');
insert into public.journey_family_answers(id,attempt_id) values
  ('00000000-0000-0000-0000-000000000105','00000000-0000-0000-0000-000000000105');
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000013"}',true);
select pg_temp.f02_expect_counts('new attempt Main support cannot read ended previous attempts',1);
select pg_temp.f02_expect_identity('new attempt current Main',1);
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000011"}',true);
select pg_temp.f02_expect_counts('previous Additional assignment never transfers to new attempt',0);
select pg_temp.f02_expect_identity('previous attempt assigned Additional',0);
select set_config('request.jwt.claims','{"sub":"00000000-0000-0000-0000-000000000001"}',true);
select pg_temp.f02_expect_counts('Seeker keeps old plus new attempt archives',6);

reset role;
set local role anon;
do $anonymous_denials$
begin
  begin perform 1 from public.conversations; raise exception 'anon conversation grant';
  exception when insufficient_privilege then null; end;
  begin perform 1 from public.messages; raise exception 'anon message grant';
  exception when insufficient_privilege then null; end;
  begin perform 1 from public.zyra_my_attempt_participation; raise exception 'anon participant grant';
  exception when insufficient_privilege then null; end;
  raise notice 'F02 PASS actual anon-role relation privileges denied';
end;
$anonymous_denials$;
reset role;
do $result$ begin raise notice 'F02 SYNTHETIC DIRECT-ROLE/JWT POSITIVE AND DENIAL MATRIX PASS'; end; $result$;
rollback;
