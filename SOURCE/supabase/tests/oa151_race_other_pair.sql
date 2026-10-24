\set ON_ERROR_STOP on
set application_name='OA151_OTHER_PAIR';
do $guard$ begin
  if current_database() !~ '^zyra_oa151_synthetic_[a-z0-9_]+$'
    or current_setting('zyra.oa151_local_replay',true) is distinct from 'enabled'
    or current_user<>'postgres' or session_user<>'postgres' then raise exception 'OA151 worker isolation refused'; end if;
end; $guard$;
begin isolation level read committed;
set local lock_timeout='2s';
set local statement_timeout='3s';
select set_config('oa151.test.request',(select request_id::text from oa151_synthetic.race_requests where name='other'),true);
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a230',true);
select oa151_synthetic.assert_true(oa151_kernel.accept_request(current_setting('oa151.test.request')::uuid)='accepted',
  'unrelated pair acceptance succeeds');
reset role;
select pg_stat_clear_snapshot();
insert into oa151_synthetic.race_outcomes
select 'other_completed_while_a_held',count(*)=1 from pg_stat_activity
  where datname=current_database() and application_name='OA151_BASIC_A'
    and xact_start is not null and state='active';
select oa151_synthetic.assert_true((select proved from oa151_synthetic.race_outcomes
  where name='other_completed_while_a_held'),'unrelated pair completes while A transaction still held');
do $$ begin raise notice 'OA151_OTHER_PAIR_COMPLETED_WHILE_A_HELD'; end; $$;
commit;

