-- Line 110 / Q152. Run on the disposable clean baseline. All rows roll back.
\set ON_ERROR_STOP on
begin;
\ir fixtures/server0_v2_full_schema_prestate.sql

create function pg_temp.actor(p_label text) returns uuid language sql stable as $$
  select id from server0_v2_fixture_actors where fixture_label = p_label;
$$;
create function pg_temp.as_actor(p_label text) returns void language sql as $$
  select set_config('request.jwt.claims', jsonb_build_object(
    'sub', pg_temp.actor(p_label), 'role', 'authenticated')::text, true);
$$;
create function pg_temp.expect(p_ok boolean, p_label text) returns void language plpgsql as $$
begin
  if p_ok is distinct from true then raise exception 'Q152 FAIL: %', p_label; end if;
  raise notice 'Q152 PASS: %', p_label;
end;
$$;
create function pg_temp.expect_denied(p_statement text, p_label text)
returns void language plpgsql as $$
begin
  execute p_statement;
  raise exception 'Q152 FAIL: %', p_label;
exception when insufficient_privilege then
  perform pg_temp.expect(true, p_label);
end;
$$;
grant select on server0_v2_fixture_actors to authenticated;
grant execute on function pg_temp.actor(text), pg_temp.as_actor(text),
  pg_temp.expect(boolean, text), pg_temp.expect_denied(text, text) to authenticated;
grant execute on function pg_temp.expect_denied(text, text) to anon;

do $private_access$
declare
  function_id regprocedure;
  function_owner oid;
  scheduled boolean;
begin
  foreach function_id in array array[
    'private.zyra_can_match_pair(uuid,uuid)'::regprocedure,
    'private.zyra_can_guardian_link_pair(uuid,uuid)'::regprocedure,
    'private.zyra_expire_due_journey_requests_all()'::regprocedure
  ] loop
    select proowner into function_owner from pg_proc where oid = function_id;
    perform pg_temp.expect(
      (select prosecdef and proconfig @> array['search_path=""']
       from pg_proc where oid = function_id)
      and not exists (
        select from pg_proc p, lateral aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) a
        where p.oid = function_id and a.grantee <> function_owner and a.privilege_type = 'EXECUTE'
      )
      and not has_function_privilege('anon', function_id, 'EXECUTE')
      and not has_function_privilege('authenticated', function_id, 'EXECUTE')
      and not has_function_privilege('service_role', function_id, 'EXECUTE'),
      format('%s is owner-only with an empty search path', function_id));
  end loop;
  if to_regclass('cron.job') is not null then
    execute 'select exists (select from cron.job where command ilike $1)'
      into scheduled using '%zyra_expire_due_journey_requests_all%';
    perform pg_temp.expect(not scheduled, 'the global sweep is unscheduled');
  end if;
end;
$private_access$;

select pg_temp.expect(
  private.zyra_can_match_pair(pg_temp.actor('male2'), pg_temp.actor('fem2'))
  and private.zyra_can_guardian_link_pair(pg_temp.actor('male2'), pg_temp.actor('gb')),
  'owner-only predicates find positive cases that will be third-party to the caller');
insert into public.profile_blocks(blocker_id, blocked_id)
values (pg_temp.actor('fem3'), pg_temp.actor('male1'));

set local role authenticated;
select pg_temp.as_actor('male1');
select pg_temp.expect(
  public.zyra_can_match(pg_temp.actor('male1'), pg_temp.actor('fem1'))
  and public.zyra_can_match(pg_temp.actor('fem1'), pg_temp.actor('male1'))
  and public.zyra_can_match(pg_temp.actor('male1'), pg_temp.actor('fem3')) is false,
  'the member can check their own match pair in either order and the block still applies');
select pg_temp.expect(
  public.zyra_can_guardian_link(pg_temp.actor('male1'), pg_temp.actor('gadd'))
  and public.zyra_can_guardian_link(pg_temp.actor('gadd'), pg_temp.actor('male1')),
  'the member can check their own eligible Guardian pair in either order');
select pg_temp.expect(
  public.zyra_can_match(pg_temp.actor('male2'), pg_temp.actor('fem2')) is false
  and public.zyra_can_guardian_link(pg_temp.actor('male2'), pg_temp.actor('gb')) is false,
  'both callable predicates refuse an otherwise eligible third-party pair');
select pg_temp.expect(
  public.zyra_can_match(null, pg_temp.actor('fem1')) is false
  and public.zyra_can_match(pg_temp.actor('male1'), null) is false
  and public.zyra_can_match(null, null) is false
  and public.zyra_can_guardian_link(null, pg_temp.actor('gadd')) is false
  and public.zyra_can_guardian_link(pg_temp.actor('male1'), null) is false
  and public.zyra_can_guardian_link(null, null) is false,
  'missing endpoints yield false for both predicates');
do $intent_policies$
declare
  path record;
  inserted_id uuid;
  statement text;
begin
  for path in select * from (values
    ('likes', 'liker_id', 'liked_id'), ('saves', 'saver_id', 'saved_id'),
    ('passes', 'passer_id', 'passed_id')
  ) as write_path(table_name, actor_column, target_column)
  loop
    statement := format('insert into public.%I(%I, %I) values ($1, $2) returning id',
      path.table_name, path.actor_column, path.target_column);
    execute statement into inserted_id using auth.uid(), pg_temp.actor('fem1');
    perform pg_temp.expect(inserted_id is not null, path.table_name || ' accepts the eligible caller pair');
    perform pg_temp.expect_denied(format(
      'insert into public.%I(%I, %I) values (%L, %L)',
      path.table_name, path.actor_column, path.target_column, auth.uid(), pg_temp.actor('fem3')),
      path.table_name || ' refuses the blocked caller pair');
    perform pg_temp.expect_denied(format(
      'insert into public.%I(%I, %I) values (%L, %L)',
      path.table_name, path.actor_column, path.target_column, pg_temp.actor('male2'), pg_temp.actor('fem2')),
      path.table_name || ' refuses a third-party write');
  end loop;
end;
$intent_policies$;
reset role;

create temp table q152_invite (token text not null);
grant select, insert on q152_invite to authenticated;
set local role authenticated;
select pg_temp.as_actor('male2');
insert into q152_invite select token from public.zyra_create_guardian_invitation();
select pg_temp.as_actor('gb');
select pg_temp.expect(
  (select count(*) = 1 and bool_and(preview.invite_status = 'pending')
   from q152_invite cross join lateral public.preview_wali_invite(q152_invite.token) preview),
  'a Guardian can preview the valid invitation the Seeker created');
select pg_temp.expect(
  (select public.accept_wali_invite(token, 'father') is not null from q152_invite),
  'a Guardian can accept the invitation under the existing checks');
reset role;
select pg_temp.expect(exists (
  select from public.wali_links where seeker_id = pg_temp.actor('male2')
    and wali_id = pg_temp.actor('gb') and status = 'active'
), 'acceptance persists the governed Guardian link');

create temp table q152_requests (
  label text primary key, match_id uuid not null default gen_random_uuid(),
  sender uuid not null, recipient uuid not null, due boolean not null
);
insert into q152_requests(label, sender, recipient, due) values
  ('scoped', pg_temp.actor('male1'), pg_temp.actor('fem1'), true),
  ('other_sent', pg_temp.actor('male1'), pg_temp.actor('fem2'), true),
  ('other_received', pg_temp.actor('fem3'), pg_temp.actor('male1'), true),
  ('future', pg_temp.actor('male1'), pg_temp.actor('fem4'), false),
  ('foreign', pg_temp.actor('male2'), pg_temp.actor('fem2'), true);
grant select on q152_requests to authenticated;
create function pg_temp.q152_match(p_label text) returns uuid language sql stable as $$
  select match_id from q152_requests where label = p_label;
$$;
grant execute on function pg_temp.q152_match(text) to authenticated;

-- Represent stored requests from earlier transactions, before their deadlines.
select set_config('request.jwt.claims', '{}', true);
insert into public.matches(id, seeker_a_id, seeker_b_id, status, journey_stage, ended_at)
select match_id, least(sender, recipient), greatest(sender, recipient),
  'ended', 'conversation', now() - interval '40 days'
from q152_requests;
insert into public.journey_requests(match_id, requested_by, requested_to, created_at, expires_at)
select match_id, sender, recipient,
  case when due then now() - interval '31 days' else now() - interval '2 days' end,
  case when due then now() - interval '1 day' else now() + interval '28 days' end
from q152_requests;

set local role authenticated;
select pg_temp.as_actor('male1');
select pg_temp.expect(
  public.zyra_can_guardian_link(pg_temp.actor('male1'), pg_temp.actor('fem1')) is false,
  'the caller-owned Guardian predicate still rejects an existing Journey pair');
select pg_temp.expect(
  public.zyra_expire_due_journey_requests(p_match_id => pg_temp.q152_match('foreign')) = 0,
  'explicitly requesting a third-party sweep reports zero');
select pg_temp.expect(
  public.zyra_expire_due_journey_requests(p_match_id => pg_temp.q152_match('future')) = 0,
  'a member cannot expire their own request before its deadline');
select pg_temp.expect(
  public.zyra_expire_due_journey_requests(p_match_id => pg_temp.q152_match('scoped')) = 1,
  'the existing named argument expires only the specified due member request');
reset role;
select pg_temp.expect(
  (select bool_and((r.status = 'declined') = (f.label = 'scoped'))
   from public.journey_requests r join q152_requests f using (match_id)),
  'scoped expiry leaves other due requests pending');

set local role authenticated;
select pg_temp.as_actor('male1');
select pg_temp.expect(
  public.zyra_expire_due_journey_requests() = 2,
  'the app call without an argument expires both sent and received due requests for this member');
select pg_temp.expect(
  public.zyra_expire_due_journey_requests() = 0, 'retry is idempotent');
select set_config('request.jwt.claims', '{"role":"authenticated"}', true);
select pg_temp.expect(
  public.zyra_expire_due_journey_requests() = 0, 'missing member identity cannot sweep requests');
reset role;
select pg_temp.expect(
  (select count(*) = 3 and bool_and(r.closed_reason = 'expired' and r.responded_at is not null)
   from public.journey_requests r join q152_requests f using (match_id)
   where f.label in ('scoped', 'other_sent', 'other_received') and r.status = 'declined')
  and (select count(*) = 2 from public.journey_requests r join q152_requests f using (match_id)
       where f.label in ('future', 'foreign') and r.status = 'pending'),
  'member expiry produces the ordinary expiry result and leaves future and third-party rows pending');

set local role anon;
select set_config('request.jwt.claims', '{"role":"anon"}', true);
select pg_temp.expect_denied('select public.zyra_can_match(null,null)', 'anon cannot call the match predicate');
select pg_temp.expect_denied('select public.zyra_can_guardian_link(null,null)', 'anon cannot call the Guardian predicate');
select pg_temp.expect_denied('select public.zyra_expire_due_journey_requests()', 'anon cannot call member expiry');
reset role;

select set_config('request.jwt.claims', '{}', true);
select pg_temp.expect(
  private.zyra_expire_due_journey_requests_all() = 1,
  'trusted owner sweeps the remaining due request across member boundaries');
select pg_temp.expect(
  (select r.status = 'declined' and r.closed_reason = 'expired'
   from public.journey_requests r where r.match_id = pg_temp.q152_match('foreign'))
  and (select r.status = 'pending'
       from public.journey_requests r where r.match_id = pg_temp.q152_match('future'))
  and (select count(*) = 4 from public.notifications
       where type = 'journey_request_declined' and related_match_id in (select match_id from q152_requests)),
  'trusted/member expiry preserves one notification per expired request and leaves the future request pending');
rollback;
