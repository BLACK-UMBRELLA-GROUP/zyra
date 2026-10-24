\set ON_ERROR_STOP on
do $guard$ begin
  if current_database() !~ '^zyra_oa151_synthetic_[a-z0-9_]+$'
    or current_setting('zyra.oa151_local_replay',true) is distinct from 'enabled'
    or current_user<>'postgres' or session_user<>'postgres' then raise exception 'OA151 RR assertions isolation refused'; end if;
end; $guard$;
select oa151_synthetic.assert_true((select count(*)=1 from oa151_kernel.requests
  where recipient_id='00000000-0000-0000-0000-00000000a221' and status='accepted'),
  'stale RR rollback cannot overbook Basic');
select oa151_synthetic.assert_true((select r.status='pending' from oa151_kernel.requests r
  join oa151_synthetic.race_requests x on x.request_id=r.id where x.name='rr_stale'),
  '40001 leaves stale request pending');
select oa151_synthetic.assert_true((select proved from oa151_synthetic.race_outcomes
  where name='rr_writer_while_stale_open'),'writer committed while stale snapshot remained open');
select oa151_synthetic.assert_true((select proved from oa151_synthetic.race_outcomes
  where name='rr_actual_lock_wait'),'actual stale RR worker waited behind writer account lock');
select oa151_synthetic.assert_true(oa151_synthetic.canonical_fingerprint()=(select fingerprint from oa151_synthetic.baseline),
  'RR stale denial leaves canonical fixtures unchanged');
-- Explicitly retire the fixture policy after measured races, no live default.
update oa151_kernel.policy set request_ttl=null,request_limit=null,reservation_ttl=null where singleton;
select oa151_synthetic.assert_true((select request_ttl is null and request_limit is null and reservation_ttl is null
  from oa151_kernel.policy where singleton),'fixture policy retired to unselected fail-closed state');
do $$ begin raise notice 'OA151 PASS: deliberately stale RR fails safely, exact preservation and policy HOLD'; end; $$;
