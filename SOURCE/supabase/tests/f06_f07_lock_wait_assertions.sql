-- Synthetic-only observation; execute once during EACH A-first RC schedule.
-- Start A, await its *_A_LOCK_HELD notice, start B, await *_B_RPC_START,
-- then execute this file before A's 3s hold expires. Total poll <=1 second.
-- No query text/member data is returned; exact synthetic names/database only.
\set ON_ERROR_STOP on
set statement_timeout='3s';
do $guard$
begin
 if current_database() not like 'zyra\_f06\_f07\_synthetic\_%' escape '\'
  or current_setting('zyra.synthetic_fixture',true) is distinct from 'f06_f07_unlocks'
  or current_user<>'postgres' then raise exception 'F06/F07 lock observation isolation refused'; end if;
end;
$guard$;
do $observe$
declare
 deadline timestamptz:=clock_timestamp()+interval '1 second';
 pair text;
 a_pid integer;
 b_pid integer;
 b_wait text;
 active_named integer;
begin
 loop
  perform pg_stat_clear_snapshot();
  select count(*) into active_named from pg_stat_activity
  where datname=current_database() and application_name in
   ('zyra_f06_f07_different_A','zyra_f06_f07_different_B',
    'zyra_f06_f07_same_A','zyra_f06_f07_same_B');
  foreach pair in array array['different','same'] loop
   select pid into a_pid from pg_stat_activity
   where datname=current_database() and application_name='zyra_f06_f07_'||pair||'_A';
   select pid,wait_event_type into b_pid,b_wait from pg_stat_activity
   where datname=current_database() and application_name='zyra_f06_f07_'||pair||'_B';
   if active_named=2 and a_pid is not null and b_pid is not null
    and b_wait='Lock' and a_pid=any(pg_blocking_pids(b_pid)) then
    raise notice 'F06/F07 PASS: observed exact % B waiting on A account serialization lock',pair;
    return;
   end if;
  end loop;
  if clock_timestamp()>=deadline then
   raise exception 'F06/F07 FAIL: deterministic RC lock contention not observed within 1 second';
  end if;
  perform pg_sleep(0.05);
 end loop;
end;
$observe$;
