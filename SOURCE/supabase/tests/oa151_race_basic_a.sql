\set ON_ERROR_STOP on
\set VERBOSITY verbose
set application_name='OA151_BASIC_A';
do $guard$ begin
  if current_database() !~ '^zyra_oa151_synthetic_[a-z0-9_]+$'
    or current_setting('zyra.oa151_local_replay',true) is distinct from 'enabled'
    or current_user<>'postgres' or session_user<>'postgres' then raise exception 'OA151 worker isolation refused'; end if;
end; $guard$;
begin isolation level read committed;
set local lock_timeout='10s';
set local statement_timeout='15s';
select set_config('oa151.test.request',(select request_id::text from oa151_synthetic.race_requests where name='basic_a'),true);
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a201',true);
select oa151_synthetic.assert_true(oa151_kernel.accept_request(current_setting('oa151.test.request')::uuid)='accepted',
  'race A occupies only Basic place');
do $$ begin raise notice 'OA151_BASIC_A_ACCEPTED_LOCKS_HELD'; end; $$;
select pg_sleep(5);
commit;

