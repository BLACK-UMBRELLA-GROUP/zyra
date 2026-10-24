-- Root runs true independent sessions; no network/service start here.
\set ON_ERROR_STOP on
\set VERBOSITY verbose
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
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000f60b',true);
select public.zyra_unlock_profile('00000000-0000-0000-0000-00000000f621','paid_single') as repeatable_read_concurrent_writer;
select pg_sleep(0);
commit;

