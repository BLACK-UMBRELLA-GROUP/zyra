-- Isolated DB proof only: fake balances/claims, no payment/JWT/API acceptance.
\set ON_ERROR_STOP on
do $guard$
begin
 if current_database() not like 'zyra\_f06\_f07\_synthetic\_%' escape '\'
  or current_setting('zyra.synthetic_fixture',true) is distinct from 'f06_f07_unlocks'
  or current_user <> 'postgres' then raise exception 'F06/F07 assertion isolation refused'; end if;
 if (select count(*) from public.profiles) <> 16 then
  raise exception 'F06/F07 exact synthetic fixture required'; end if;
end;
$guard$;
begin;
create schema f06_test;
grant usage on schema f06_test to authenticated,anon,service_role;
create function f06_test.ok(p_name text,p_ok boolean) returns void language plpgsql as $f$
begin
 if p_ok is distinct from true then raise exception 'F06/F07 FAIL: %',p_name; end if;
 raise notice 'F06/F07 PASS: %',p_name;
end;
$f$;
create function f06_test.reject(p_name text,p_sql text,p_state text) returns void language plpgsql as $f$
declare rejected boolean:=false; state text;
begin
 begin execute p_sql;
 exception when others then
  get stacked diagnostics state=returned_sqlstate;
  if state<>p_state then raise exception 'F06/F07 wrong SQLSTATE % expected % for %',state,p_state,p_name; end if;
  rejected:=true;
 end;
 perform f06_test.ok(p_name,rejected);
end;
$f$;
grant execute on all functions in schema f06_test to authenticated,anon,service_role;

select f06_test.ok('private gate default OFF, RLS forced, no ordinary/service writes',
 not private.zyra_plus_spend_available()
 and not has_table_privilege('authenticated','private.zyra_unlock_release_gate','SELECT,INSERT,UPDATE,DELETE')
 and not has_table_privilege('service_role','private.zyra_unlock_release_gate','SELECT,INSERT,UPDATE,DELETE')
 and (select count(*)=3 and bool_and(relrowsecurity and relforcerowsecurity)
  from pg_class where oid in ('private.zyra_unlock_release_gate'::regclass,
   'private.zyra_unlock_account_guards'::regclass,'private.zyra_unlock_operations'::regclass)));
select f06_test.reject('flag flip cannot substitute for future release contract',
 'update private.zyra_unlock_release_gate set plus_spend_enabled=true','23514');
select f06_test.ok('no migration backfill/grant/debit/entitlement',
 (select count(*)=4 from public.profile_unlocks)
 and (select count(*)=10 from public.unlock_credits)
 and (select count(*)=0 from private.zyra_unlock_operations));
select f06_test.ok('included-credit and debug-grant definitions unchanged',
 md5(pg_get_functiondef('public.grant_zyra_one_credits()'::regprocedure))='6a85b2417d5b067df1f18233c3b6217e'
 and md5(pg_get_functiondef('public.zyra_debug_grant_credits(text,integer)'::regprocedure))='6b67563c333ce5f841cfcea82da3af2b');
select f06_test.ok('profile visibility byte-identical',
 md5(pg_get_functiondef('public.zyra_can_view_profile(uuid)'::regprocedure))='10bebeecc1fb937cc257816711baf99b');
select f06_test.ok('new private helper execution not granted to ordinary callers',
 not has_function_privilege('authenticated','private.zyra_lock_unlock_account(uuid)','execute')
 and not has_function_privilege('service_role','private.zyra_plus_spend_available()','execute'));

set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000f601',true);
do $legacy$
declare result jsonb; target uuid;
begin
 foreach target in array array['00000000-0000-0000-0000-00000000f602'::uuid,
  '00000000-0000-0000-0000-00000000f603'::uuid,'00000000-0000-0000-0000-00000000f604'::uuid,
  '00000000-0000-0000-0000-00000000f605'::uuid] loop
  result:=public.zyra_unlock_profile(target,'paid_single');
  perform f06_test.ok('legacy Plus/bundle/automatic Standard superset no charge '||target::text,
   result->>'status'='already_unlocked' and result->>'charged'='false');
 end loop;
 result:=public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f603','paid_plus_single');
 perform f06_test.ok('held legacy Plus bundle still recognized',
  result->>'status'='already_unlocked' and result->>'charged'='false');
 result:=public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f605','paid_plus_single');
 perform f06_test.ok('automatic_match is not promoted into Plus',
  result->>'status'='plus_unavailable' and result->>'charged'='false');
 result:=public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f606','paid_plus_single');
 perform f06_test.ok('ordinary new Plus is truthfully unavailable without debit',
  result->>'status'='plus_unavailable' and result->>'charged'='false');
end;
$legacy$;
select f06_test.ok('held Plus leaves its balance and existing entitlement unchanged',
 (select coalesce(sum(delta),0)=3 from public.unlock_credits where tier='paid_plus_single')
 and (select count(*)=0 from public.profile_unlocks where unlocked_id='00000000-0000-0000-0000-00000000f606'));
select f06_test.reject('member direct entitlement insert remains denied', $sql$
 insert into public.profile_unlocks(unlocker_id,unlocked_id,unlock_type)
 values('00000000-0000-0000-0000-00000000f601','00000000-0000-0000-0000-00000000f620','paid_single')
$sql$,'42501');
select f06_test.reject('member direct ledger insert remains denied', $sql$
 insert into public.unlock_credits(user_id,tier,delta,reason)
 values('00000000-0000-0000-0000-00000000f601','paid_single',10,'purchase')
$sql$,'42501');
select f06_test.reject('member cannot flip release table',
 'update private.zyra_unlock_release_gate set plus_spend_enabled=true','42501');
select set_config('zyra.plus_spend_enabled','true',true);
do $guc$
begin
 perform f06_test.ok('client GUC cannot enable Plus',
  public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f606','paid_plus_single')->>'status'='plus_unavailable');
end;
$guc$;
select f06_test.reject('NULL tier rejected instead of guessed',
 $$select public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f606',null)$$,'P0001');
select f06_test.reject('unsupported tier rejected instead of normalized as a purchase',
 $$select public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f606','automatic_match')$$,'P0001');

do $spend$
declare first_result jsonb; retry_result jsonb;
begin
 first_result:=public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f606','paid_single');
 perform f06_test.ok('Standard atomically charges one and returns durable operation identity',
  first_result->>'status'='unlocked' and first_result->>'charged'='true'
  and first_result->>'balance'='1' and first_result->>'operation_id' is not null);
 retry_result:=public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f606','paid_single');
 perform f06_test.ok('lost-ACK/revisit is no-charge with same server operation identity',
  retry_result->>'status'='already_unlocked' and retry_result->>'charged'='false'
  and retry_result->>'operation_id'=first_result->>'operation_id');
end;
$spend$;
reset role;
select f06_test.ok('one bound receipt, entitlement and debit committed in one transaction',
 (select count(*)=1 from private.zyra_unlock_operations o join public.profile_unlocks u on u.id=o.unlock_id
  join public.unlock_credits c on c.id=o.debit_id
  where o.unlocker_id='00000000-0000-0000-0000-00000000f601'
   and o.unlocked_id='00000000-0000-0000-0000-00000000f606'
   and c.user_id=o.unlocker_id and c.related_unlock_id=u.id and c.delta=-1));
select f06_test.reject('table-level duplicate debit rejected independently of RPC', $sql$
 insert into public.unlock_credits(user_id,tier,delta,reason,related_unlock_id)
 select unlocker_id,'paid_single',-1,'spend',unlock_id from private.zyra_unlock_operations
 where unlocked_id='00000000-0000-0000-0000-00000000f606'
$sql$,'55000');
select f06_test.reject('old Plus entitlement cannot be moved to a new target', $sql$
 update public.profile_unlocks set unlocked_id='00000000-0000-0000-0000-00000000f622'
 where id='00000000-0000-0000-0000-00000000f631'
$sql$,'55000');
select f06_test.reject('old negative Plus debit cannot be increased',
 $$update public.unlock_credits set delta=-2 where id='00000000-0000-0000-0000-00000000f641'$$,'55000');
update public.profile_unlocks set created_at=created_at where id='00000000-0000-0000-0000-00000000f631';
update public.unlock_credits set note='synthetic nonfinancial metadata',created_at=created_at
where id='00000000-0000-0000-0000-00000000f641';
select f06_test.ok('unchanged held legacy Plus metadata updates remain allowed',
 (select delta=-1 and note='synthetic nonfinancial metadata' from public.unlock_credits
  where id='00000000-0000-0000-0000-00000000f641'));
select f06_test.reject('all negative Plus ledger reasons held, not just RPC spend', $sql$
 insert into public.unlock_credits(user_id,tier,delta,reason)
 values('00000000-0000-0000-0000-00000000f601','paid_plus_single',-1,'adjustment')
$sql$,'55000');

-- Equivalent to a future automatic grant inside a larger local transaction:
-- both Plus types suppress the grant without aborting the surrounding action.
do $automatic$
declare tier text; written integer;
begin
 foreach tier in array array['paid_plus_single','paid_plus_bundle'] loop
  insert into public.profile_unlocks(unlocker_id,unlocked_id,unlock_type)
  values('00000000-0000-0000-0000-00000000f601','00000000-0000-0000-0000-00000000f622',tier);
  get diagnostics written=row_count;
  perform f06_test.ok('new held '||tier||' table INSERT is zero-row without enclosing failure',written=0);
 end loop;
end;
$automatic$;
delete from public.profile_unlocks where unlocker_id='00000000-0000-0000-0000-00000000f601'
and unlocked_id='00000000-0000-0000-0000-00000000f606';
set local role authenticated;
do $recovery$
declare result jsonb;
begin
 result:=public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f606','paid_single');
 perform f06_test.ok('missing entitlement beside receipt returns recovery, never another charge',
  result->>'status'='recovery_required' and result->>'charged'='false'
  and result->>'operation_id' is not null);
end;
$recovery$;
reset role;
select f06_test.ok('recovery does not repeat debit or invent a replacement entitlement',
 (select count(*)=1 from private.zyra_unlock_operations)
 and (select count(*)=1 from public.unlock_credits where user_id='00000000-0000-0000-0000-00000000f601' and tier='paid_single' and reason='spend'));

-- No credits are necessary to revisit an already-held tier or its superset.
delete from public.unlock_credits where user_id='00000000-0000-0000-0000-00000000f601' and tier='paid_single';
set local role authenticated;
do $zero$
begin
 perform f06_test.ok('legacy Plus still opens Standard with zero Standard balance',
  public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f602','paid_single')->>'status'='already_unlocked'
  and (select coalesce(sum(delta),0)=0 from public.unlock_credits where tier='paid_single'));
end;
$zero$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000f609',true);
select f06_test.ok('existing dev guard cannot mint a new held Plus; false is truthful',
 not public.zyra_dev_set_plus_unlock('00000000-0000-0000-0000-00000000f620',true));
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000f607',true);
select f06_test.reject('Guardian cannot spend even with own credit and linked visibility',
 $$select public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f601','paid_single')$$,'42501');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000f608',true);
select f06_test.reject('incomplete Seeker cannot pay around current visibility',
 $$select public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f606','paid_single')$$,'P0001');
select set_config('request.jwt.claim.sub','',true);
select f06_test.reject('no JWT subject cannot call spend',
 $$select public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f606','paid_single')$$,'P0001');
reset role;
set local role anon;
select f06_test.reject('anonymous spend execute remains denied',
 $$select public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f606','paid_single')$$,'42501');
reset role;

-- Positive included credits are unchanged and never activate held spending.
insert into public.subscriptions values('00000000-0000-0000-0000-00000000f60d','seeker_premium','active');
update public.subscriptions set status=status where user_id='00000000-0000-0000-0000-00000000f60d';
select f06_test.ok('existing included-credit trigger still grants exactly once in synthetic setup',
 (select count(*)=1 and sum(delta)=3 from public.unlock_credits
  where user_id='00000000-0000-0000-0000-00000000f60d' and reason='zyra_one_included'));

-- A single statement must see its preceding trigger-processed rows: one
-- credit cannot fund two negative adjustments even inside an INSERT batch.
do $batch$
declare before_revision bigint;
begin
 select revision into before_revision from private.zyra_unlock_account_guards
 where user_id='00000000-0000-0000-0000-00000000f60d';
 perform f06_test.reject('one-credit two-negative Standard batch rejects whole statement', $sql$
  insert into public.unlock_credits(user_id,tier,delta,reason,note) values
   ('00000000-0000-0000-0000-00000000f60d','paid_single',-1,'adjustment','synthetic batch first'),
   ('00000000-0000-0000-0000-00000000f60d','paid_single',-1,'adjustment','synthetic batch second')
 $sql$,'55000');
 perform f06_test.ok('rejected batch retains one credit/no negative balance/no partial rows',
  (select coalesce(sum(delta),0)=1 from public.unlock_credits
   where user_id='00000000-0000-0000-0000-00000000f60d' and tier='paid_single')
  and (select count(*)=0 from public.unlock_credits
   where user_id='00000000-0000-0000-0000-00000000f60d' and reason='adjustment')
  and (select revision=before_revision from private.zyra_unlock_account_guards
   where user_id='00000000-0000-0000-0000-00000000f60d'));
end;
$batch$;

create function f06_test.inject_partial_failure() returns trigger language plpgsql as $f$
begin
 if new.user_id='00000000-0000-0000-0000-00000000f60c' and new.reason='spend' then
  raise exception 'synthetic_partial_failure';
 end if;
 return new;
end;
$f$;
create trigger zz_f06_test_partial_failure before insert on public.unlock_credits
for each row execute function f06_test.inject_partial_failure();
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000f60c',true);
select f06_test.reject('injected post-entitlement debit failure aborts whole operation',
 $$select public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f620','paid_single')$$,'P0001');
reset role;
select f06_test.ok('failed partial transaction leaves no entitlement/debit/receipt/guard',
 (select count(*)=0 from public.profile_unlocks where unlocker_id='00000000-0000-0000-0000-00000000f60c')
 and (select count(*)=0 from private.zyra_unlock_operations where unlocker_id='00000000-0000-0000-0000-00000000f60c')
 and (select count(*)=0 from private.zyra_unlock_account_guards where user_id='00000000-0000-0000-0000-00000000f60c')
 and (select sum(delta)=1 from public.unlock_credits where user_id='00000000-0000-0000-0000-00000000f60c'));
rollback;
do $post$
begin
 if (select count(*) from public.profile_unlocks)<>4 or (select count(*) from public.unlock_credits)<>10
  or (select count(*) from private.zyra_unlock_operations)<>0
  or to_regnamespace('f06_test') is not null then raise exception 'F06/F07 assertion rollback failed'; end if;
 raise notice 'F06/F07 PASS: functional assertion transaction fully rolled back';
end;
$post$;
