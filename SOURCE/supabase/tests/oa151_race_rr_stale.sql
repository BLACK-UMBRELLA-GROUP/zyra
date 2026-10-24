-- EXPECTED psql exit3, SQLSTATE40001. Root waits for barrier before writer.
\set ON_ERROR_STOP on
\set VERBOSITY verbose
set application_name='OA151_RR_STALE';
do $guard$ begin
  if current_database() !~ '^zyra_oa151_synthetic_[a-z0-9_]+$'
    or current_setting('zyra.oa151_local_replay',true) is distinct from 'enabled'
    or current_user<>'postgres' or session_user<>'postgres' then raise exception 'OA151 worker isolation refused'; end if;
end; $guard$;
begin isolation level repeatable read;
set local lock_timeout='10s';
set local statement_timeout='15s';
select set_config('oa151.test.request',(select request_id::text from oa151_synthetic.race_requests where name='rr_stale'),true);
select count(*) from oa151_kernel.account_revisions; -- Deliberately pin snapshot.
do $$ begin raise notice 'OA151_RR_SNAPSHOT_PINNED'; end; $$;
-- Writer takes both account locks while this snapshot remains pinned; the
-- acceptance then waits behind it and must fail 40001 after writer COMMIT.
select pg_sleep(1);
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a221',true);
select oa151_kernel.accept_request(current_setting('oa151.test.request')::uuid);
-- Reaching COMMIT is a test failure, even if the stale snapshot had capacity.
do $$ begin raise exception 'OA151 stale RR unexpectedly proceeded'; end; $$;
commit;
