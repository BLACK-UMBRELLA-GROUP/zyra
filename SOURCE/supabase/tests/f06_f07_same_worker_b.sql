-- Root runs true independent sessions; no network/service start here.
\set ON_ERROR_STOP on
\set VERBOSITY verbose
set application_name='zyra_f06_f07_same_B';
do $guard$
begin
 if current_database() not like 'zyra\_f06\_f07\_synthetic\_%' escape '\'
  or current_setting('zyra.synthetic_fixture',true) is distinct from 'f06_f07_unlocks'
  or current_user <> 'postgres' then raise exception 'F06/F07 worker isolation refused'; end if;
end;
$guard$;
begin isolation level read committed;
set local lock_timeout='10s';
set local statement_timeout='15s';
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000f60a',true);
do $start$ begin raise notice 'F06_RC_SAME_B_RPC_START'; end; $start$;
select public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f620','paid_single') as same_target_b;
select pg_sleep(0);
commit;
