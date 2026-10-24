-- Root executes after functional assertions, before independent workers.
\set ON_ERROR_STOP on
do $guard$ begin
  if current_database() !~ '^zyra_oa151_synthetic_[a-z0-9_]+$'
    or current_setting('zyra.oa151_local_replay',true) is distinct from 'enabled'
    or current_user<>'postgres' or session_user<>'postgres' then
    raise exception 'OA151 race setup isolation refused';
  end if;
end; $guard$;
begin;
update oa151_kernel.policy set request_ttl=interval '1 hour',request_limit=8,
  reservation_ttl=interval '2 hours' where singleton;
create table oa151_synthetic.race_requests(name text primary key,request_id uuid not null);
create table oa151_synthetic.race_outcomes(name text primary key,proved boolean not null);
revoke all on oa151_synthetic.race_requests,oa151_synthetic.race_outcomes from public,anon,authenticated,service_role;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a202',true);
select set_config('oa151.test.race_a',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a201','00000000-0000-0000-0000-00000000d201')::text,true);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a203',true);
select set_config('oa151.test.race_b',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a201','00000000-0000-0000-0000-00000000d203')::text,true);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a231',true);
select set_config('oa151.test.race_other',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a230','00000000-0000-0000-0000-00000000d230')::text,true);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a222',true);
select set_config('oa151.test.rr_writer',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a221','00000000-0000-0000-0000-00000000d221')::text,true);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-00000000a223',true);
select set_config('oa151.test.rr_stale',oa151_kernel.send_request(
  '00000000-0000-0000-0000-00000000a221','00000000-0000-0000-0000-00000000d223')::text,true);
reset role;
insert into oa151_synthetic.race_requests values
  ('basic_a',current_setting('oa151.test.race_a')::uuid),
  ('basic_b',current_setting('oa151.test.race_b')::uuid),
  ('other',current_setting('oa151.test.race_other')::uuid),
  ('rr_writer',current_setting('oa151.test.rr_writer')::uuid),
  ('rr_stale',current_setting('oa151.test.rr_stale')::uuid);
select oa151_synthetic.assert_true((select count(*)=5 from oa151_kernel.requests where status='pending'),
  'five independently addressed race requests seeded');
commit;

