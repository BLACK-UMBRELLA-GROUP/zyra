-- EXPECTED psql exit 3 / SQLSTATE 40001, solely this stale-snapshot case.
-- Root starts this worker first, waits for F06_RR_SNAPSHOT_PINNED notice,
-- then starts f06_f07_rr_writer.sql before this three-second barrier expires.
\set ON_ERROR_STOP on
\set VERBOSITY verbose
do $guard$
begin
 if current_database() not like 'zyra\_f06\_f07\_synthetic\_%' escape '\'
  or current_setting('zyra.synthetic_fixture',true) is distinct from 'f06_f07_unlocks'
  or current_user <> 'postgres' then raise exception 'F06/F07 worker isolation refused'; end if;
end;
$guard$;
begin isolation level repeatable read;
set local lock_timeout='10s';
set local statement_timeout='15s';
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000f60b',true);
do $pin$
declare available integer;
begin
 select coalesce(sum(delta),0) into available from public.unlock_credits where tier='paid_single';
 if available<>1 then raise exception 'F06_RR expected initial one synthetic credit'; end if;
 raise notice 'F06_RR_SNAPSHOT_PINNED';
end;
$pin$;
select pg_sleep(3);
select public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f620','paid_single') as stale_rr_must_not_spend;
commit;

