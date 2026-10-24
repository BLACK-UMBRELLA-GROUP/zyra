-- Run only after the three coordinated independent-session races.
-- Expected: two different-target sessions exit0; two same-target exit0;
-- RR writer exit0; stale RR worker alone exits3 with SQLSTATE40001.
\set ON_ERROR_STOP on
do $guard$
begin
 if current_database() not like 'zyra\_f06\_f07\_synthetic\_%' escape '\'
  or current_setting('zyra.synthetic_fixture',true) is distinct from 'f06_f07_unlocks'
  or current_user<>'postgres' then raise exception 'F06/F07 race assertion isolation refused'; end if;
end;
$guard$;
do $races$
declare actor uuid;
begin
 foreach actor in array array['00000000-0000-0000-0000-00000000f609'::uuid,
  '00000000-0000-0000-0000-00000000f60a'::uuid,'00000000-0000-0000-0000-00000000f60b'::uuid] loop
  if (select count(*) from public.profile_unlocks where unlocker_id=actor)<>1
   or (select count(*) from public.unlock_credits where user_id=actor and reason='spend')<>1
   or (select sum(delta) from public.unlock_credits where user_id=actor and tier='paid_single')<>0
   or (select count(*) from private.zyra_unlock_operations where unlocker_id=actor)<>1 then
   raise exception 'F06/F07 FAIL: one credit must yield one bound operation for %',actor;
  end if;
  if not exists(select 1 from private.zyra_unlock_operations o
   join public.profile_unlocks u on u.id=o.unlock_id
   join public.unlock_credits c on c.id=o.debit_id
   where o.unlocker_id=actor and u.unlocker_id=actor and u.unlocked_id=o.unlocked_id
    and c.user_id=actor and c.delta=-1 and c.related_unlock_id=u.id) then
   raise exception 'F06/F07 FAIL: race receipt/unlock/debit binding %',actor;
  end if;
  raise notice 'F06/F07 PASS: concurrent last-credit operation conserved for %',actor;
 end loop;
 if exists(select 1 from public.profile_unlocks where unlocker_id='00000000-0000-0000-0000-00000000f60b'
   and unlocked_id='00000000-0000-0000-0000-00000000f620')
  or not exists(select 1 from public.profile_unlocks where unlocker_id='00000000-0000-0000-0000-00000000f60b'
   and unlocked_id='00000000-0000-0000-0000-00000000f621') then
  raise exception 'F06/F07 FAIL: stale RR snapshot minted an operation';
 end if;
 raise notice 'F06/F07 PASS: stale REPEATABLE READ worker created no paid state';
end;
$races$;

-- Lost ACK after the concurrent commit: no extra debit, stable receipt identity.
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000f609',true);
do $retry$
declare target uuid; result jsonb;
begin
 select unlocked_id into target from public.profile_unlocks
 where unlocker_id=(select auth.uid());
 result:=public.zyra_unlock_profile(target,'paid_single');
 if result->>'status'<>'already_unlocked' or result->>'charged'<>'false'
  or result->>'operation_id' is null then raise exception 'F06/F07 FAIL: race lost-ACK retry'; end if;
 raise notice 'F06/F07 PASS: committed race lost-ACK retry is no-charge';
end;
$retry$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000f60b',true);
do $retry_rr$
declare result jsonb;
begin
 result:=public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f620','paid_single');
 if result->>'status'<>'insufficient_credits' or result->>'charged'<>'false'
  or result->>'balance'<>'0' then raise exception 'F06/F07 FAIL: fresh RR loser retry'; end if;
 raise notice 'F06/F07 PASS: complete READ COMMITTED retry sees the committed zero balance';
end;
$retry_rr$;
commit;
do $final$
begin
 if (select count(*) from private.zyra_unlock_operations
  where unlocker_id in ('00000000-0000-0000-0000-00000000f609','00000000-0000-0000-0000-00000000f60a',
   '00000000-0000-0000-0000-00000000f60b'))<>3
  or (select count(*) from public.unlock_credits where reason='spend'
   and user_id in ('00000000-0000-0000-0000-00000000f609','00000000-0000-0000-0000-00000000f60a',
    '00000000-0000-0000-0000-00000000f60b'))<>3 then
  raise exception 'F06/F07 FAIL: race retry generated duplicate paid state';
 end if;
 raise notice 'F06/F07 PASS: concurrency retries created no extra operation/debit';
end;
$final$;
