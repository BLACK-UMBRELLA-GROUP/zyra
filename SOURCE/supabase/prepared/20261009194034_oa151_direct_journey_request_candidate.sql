-- OA-ZYRA-151 / DR-ZYRA-265: SYNTHETIC-ONLY preparation kernel.
-- Founder authorised authoring and isolated fake-record tests, NOT deployment.
-- This is deliberately NOT a production migration. The preflight runs BEFORE
-- DDL, inside the SAME atomic transaction, and refuses every database except
-- a specifically named local synthetic replay with an explicit session arm
-- and postgres operator. A client continuing after rejection cannot persist
-- subsequent DDL: the transaction remains aborted until its final rollback.
-- No existing table, function, grant, lifecycle row or Flutter flow is changed.
-- The four oa151_synthetic adapters are test fixtures, NOT receipt, IDV,
-- moderation or production Journey authority. Their trusted replacements,
-- all legacy admission routes, policy approval and end-to-end wiring remain
-- OA-ZYRA-151/253/303 HOLD. Accepted reservations grant NO profile, Guardian,
-- compatibility, ritual or chat access. A bridge token is bookkeeping only;
-- there is no canonical match/attempt/conversation bridge in this candidate.

begin;

do $synthetic_preflight$
begin
  if pg_catalog.current_database() !~ '^zyra_oa151_synthetic_[a-z0-9_]+$'
     or pg_catalog.current_setting('zyra.oa151_local_replay', true)
          is distinct from 'enabled'
     or current_user <> 'postgres' or session_user <> 'postgres' then
    raise exception 'oa151_synthetic_preflight_refused';
  end if;
  if pg_catalog.to_regnamespace('oa151_kernel') is not null
     or pg_catalog.to_regprocedure('oa151_synthetic.account_admission(uuid)') is null
     or pg_catalog.to_regprocedure('oa151_synthetic.journey_cap(uuid)') is null
     or pg_catalog.to_regprocedure('oa151_synthetic.existing_occupancy(uuid)') is null
     or pg_catalog.to_regprocedure('oa151_synthetic.pair_available(uuid,uuid)') is null
     or pg_catalog.to_regprocedure('auth.uid()') is null then
    raise exception 'oa151_synthetic_fixture_missing_or_candidate_exists';
  end if;
end;
$synthetic_preflight$;

create schema oa151_kernel;
revoke all on schema oa151_kernel from public, anon, authenticated, service_role;

-- NULL is intentionally not a live product decision. Every send/accept/ready
-- transition fails closed until the local fixture explicitly supplies policy.
create table oa151_kernel.policy (
  singleton boolean primary key default true check (singleton),
  request_ttl interval,
  request_limit integer,
  reservation_ttl interval,
  check (request_ttl is null or request_ttl > interval '0'),
  check (request_limit is null or request_limit > 0),
  check (reservation_ttl is null or reservation_ttl > interval '0')
);
insert into oa151_kernel.policy(singleton) values (true);

-- Advisory locks serialize READ COMMITTED operations. A real row revision
-- also makes stale REPEATABLE READ/SERIALIZABLE writers fail with 40001,
-- rather than accepting against a pre-lock snapshot after another commit.
create table oa151_kernel.account_revisions (
  user_id uuid primary key,
  revision bigint not null check (revision > 0)
);

create table oa151_kernel.requests (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  requester_id uuid not null,
  recipient_id uuid not null,
  pair_a uuid generated always as (least(requester_id, recipient_id)) stored,
  pair_b uuid generated always as (greatest(requester_id, recipient_id)) stored,
  status text not null default 'pending' check (status in (
    'pending', 'accepted', 'cancelled', 'declined',
    'request_expired', 'reservation_expired'
  )),
  created_at timestamptz not null,
  request_expires_at timestamptz not null,
  accepted_at timestamptz,
  reservation_expires_at timestamptz,
  closed_at timestamptz,
  requester_ready_at timestamptz,
  recipient_ready_at timestamptz,
  bridge_token uuid,
  check (requester_id <> recipient_id),
  check (request_expires_at > created_at),
  check ((status in ('pending', 'accepted')) = (closed_at is null)),
  check (status <> 'pending' or (
    accepted_at is null and reservation_expires_at is null
    and requester_ready_at is null and recipient_ready_at is null
    and bridge_token is null
  )),
  check (status <> 'accepted' or (
    accepted_at is not null and reservation_expires_at is not null
    and reservation_expires_at > accepted_at
  )),
  check (bridge_token is null or (
    status = 'accepted' and requester_ready_at is not null
    and recipient_ready_at is not null
  ))
);
create unique index requests_one_live_per_pair
  on oa151_kernel.requests(pair_a, pair_b)
  where status in ('pending', 'accepted');
create index requests_outgoing_pending
  on oa151_kernel.requests(requester_id, request_expires_at)
  where status = 'pending';
create index requests_recipient on oa151_kernel.requests(recipient_id, created_at);
create index requests_requester on oa151_kernel.requests(requester_id, created_at);
create index requests_reserved_a
  on oa151_kernel.requests(pair_a, reservation_expires_at)
  where status = 'accepted';
create index requests_reserved_b
  on oa151_kernel.requests(pair_b, reservation_expires_at)
  where status = 'accepted';

-- Keeps every caller-provided operation key immutable even when a reverse
-- request resolves to the other participant's existing in-flight request.
create table oa151_kernel.send_replays (
  actor_id uuid not null,
  idempotency_key uuid not null,
  target_id uuid not null,
  request_id uuid not null references oa151_kernel.requests(id),
  primary key (actor_id, idempotency_key),
  check (actor_id <> target_id)
);
create index send_replays_request on oa151_kernel.send_replays(request_id);

alter table oa151_kernel.policy enable row level security;
alter table oa151_kernel.account_revisions enable row level security;
alter table oa151_kernel.requests enable row level security;
alter table oa151_kernel.send_replays enable row level security;
revoke all on all tables in schema oa151_kernel
  from public, anon, authenticated, service_role;

comment on schema oa151_kernel is
  'SYNTHETIC-ONLY OA151 kernel. No production adapters, canonical bridge or activation.';
comment on table oa151_kernel.policy is
  'OWNER: internal operator. NULL policy fails closed; fixture values are not Founder policy.';
comment on table oa151_kernel.requests is
  'OWNER: joint requester/recipient interaction metadata. Accepted reservation is bookkeeping, not a canonical relationship or access grant.';
comment on table oa151_kernel.account_revisions is
  'OWNER: internal concurrency metadata. No client read/write access.';
comment on table oa151_kernel.send_replays is
  'OWNER: originating actor operation metadata. No client read/write access.';

create function oa151_kernel.assert_local()
returns void language plpgsql stable security definer set search_path = ''
as $local$
begin
  if pg_catalog.current_database() !~ '^zyra_oa151_synthetic_[a-z0-9_]+$'
     or pg_catalog.current_setting('zyra.oa151_local_replay', true)
          is distinct from 'enabled' then
    raise exception 'oa151_local_only';
  end if;
end;
$local$;

create function oa151_kernel.actor()
returns uuid language plpgsql stable security definer set search_path = ''
as $actor$
declare v_actor uuid;
begin
  perform oa151_kernel.assert_local();
  v_actor := auth.uid();
  if v_actor is null then raise exception 'oa151_not_signed_in'; end if;
  return v_actor;
end;
$actor$;

create function oa151_kernel.require_policy()
returns oa151_kernel.policy
language plpgsql stable security definer set search_path = ''
as $policy$
declare v_policy oa151_kernel.policy%rowtype;
begin
  select * into v_policy from oa151_kernel.policy where singleton;
  if not found or v_policy.request_ttl is null
     or v_policy.request_limit is null or v_policy.reservation_ttl is null then
    raise exception 'oa151_policy_unconfigured';
  end if;
  return v_policy;
end;
$policy$;

create function oa151_kernel.lock_accounts(p_a uuid, p_b uuid)
returns void language plpgsql volatile security definer set search_path = ''
as $lock$
declare v_low uuid := least(p_a, p_b); v_high uuid := greatest(p_a, p_b);
begin
  if p_a is null or p_b is null or p_a = p_b then
    raise exception 'oa151_invalid_pair';
  end if;
  -- Exact existing Journey advisory-key contract, in a single global order.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_low::text, 0));
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_high::text, 0));
  insert into oa151_kernel.account_revisions(user_id, revision)
  values (v_low, 1)
  on conflict (user_id) do update
    set revision = oa151_kernel.account_revisions.revision + 1;
  insert into oa151_kernel.account_revisions(user_id, revision)
  values (v_high, 1)
  on conflict (user_id) do update
    set revision = oa151_kernel.account_revisions.revision + 1;
end;
$lock$;

create function oa151_kernel.expire_pair(p_a uuid, p_b uuid, p_at timestamptz)
returns void language plpgsql volatile security definer set search_path = ''
as $expiry$
begin
  -- Invoked only after both account locks. Reads/counts also treat expired
  -- timers as terminal, so unrelated rows never need an eager global sweep.
  update oa151_kernel.requests
  set status = case when status = 'pending' then 'request_expired'
                    else 'reservation_expired' end,
      closed_at = p_at,
      requester_ready_at = null, recipient_ready_at = null, bridge_token = null
  where pair_a = least(p_a, p_b) and pair_b = greatest(p_a, p_b)
    and ((status = 'pending' and request_expires_at <= p_at)
      or (status = 'accepted' and reservation_expires_at <= p_at));
end;
$expiry$;

create function oa151_kernel.occupancy(p_user uuid, p_at timestamptz)
returns integer language plpgsql volatile security definer set search_path = ''
as $occupancy$
declare v_existing integer; v_reserved integer;
begin
  v_existing := oa151_synthetic.existing_occupancy(p_user);
  if v_existing is null or v_existing < 0 then
    raise exception 'oa151_fixture_occupancy_invalid';
  end if;
  select count(*)::integer into v_reserved
  from oa151_kernel.requests
  where status = 'accepted' and reservation_expires_at > p_at
    and p_user in (requester_id, recipient_id);
  return v_existing + v_reserved;
end;
$occupancy$;

create function oa151_kernel.require_available_pair(
  p_a uuid, p_b uuid, p_at timestamptz
)
returns void language plpgsql volatile security definer set search_path = ''
as $available$
declare v_a_cap integer; v_b_cap integer;
begin
  if oa151_synthetic.account_admission(p_a) is distinct from true
     or oa151_synthetic.account_admission(p_b) is distinct from true
     or oa151_synthetic.pair_available(p_a, p_b) is distinct from true then
    raise exception 'oa151_not_available';
  end if;
  v_a_cap := oa151_synthetic.journey_cap(p_a);
  v_b_cap := oa151_synthetic.journey_cap(p_b);
  if v_a_cap is null or v_b_cap is null or v_a_cap <= 0 or v_b_cap <= 0 then
    raise exception 'oa151_not_available';
  end if;
  if oa151_kernel.occupancy(p_a, p_at) >= v_a_cap
     or oa151_kernel.occupancy(p_b, p_at) >= v_b_cap then
    raise exception 'oa151_capacity_unavailable';
  end if;
end;
$available$;

create function oa151_kernel.owned_request(p_id uuid, p_actor uuid)
returns oa151_kernel.requests
language plpgsql volatile security definer set search_path = ''
as $owned$
declare v_request oa151_kernel.requests%rowtype;
begin
  select * into v_request from oa151_kernel.requests
  where id = p_id and p_actor in (requester_id, recipient_id);
  if not found then raise exception 'oa151_request_not_found'; end if;
  return v_request;
end;
$owned$;

create function oa151_kernel.send_request(p_target uuid, p_idempotency uuid)
returns uuid language plpgsql volatile security definer set search_path = ''
as $send$
declare
  v_actor uuid := oa151_kernel.actor();
  v_policy oa151_kernel.policy%rowtype;
  v_replay oa151_kernel.send_replays%rowtype;
  v_request uuid;
  v_at timestamptz;
  v_pending integer;
begin
  if p_target = v_actor then raise exception 'oa151_self_request'; end if;
  if p_target is null or p_idempotency is null then
    raise exception 'oa151_invalid_request';
  end if;
  v_policy := oa151_kernel.require_policy();
  perform oa151_kernel.lock_accounts(v_actor, p_target);
  v_at := pg_catalog.clock_timestamp();
  select * into v_replay from oa151_kernel.send_replays
  where actor_id = v_actor and idempotency_key = p_idempotency;
  if found then
    if v_replay.target_id <> p_target then
      raise exception 'oa151_idempotency_target_mismatch';
    end if;
    return v_replay.request_id;
  end if;
  perform oa151_kernel.expire_pair(v_actor, p_target, v_at);
  select id into v_request from oa151_kernel.requests
  where pair_a = least(v_actor, p_target) and pair_b = greatest(v_actor, p_target)
    and status in ('pending', 'accepted');
  if v_request is null then
    perform oa151_kernel.require_available_pair(v_actor, p_target, v_at);
    select count(*)::integer into v_pending from oa151_kernel.requests
    where requester_id = v_actor and status = 'pending' and request_expires_at > v_at;
    if v_pending >= v_policy.request_limit then
      raise exception 'oa151_request_limit';
    end if;
    insert into oa151_kernel.requests(
      requester_id, recipient_id, created_at, request_expires_at
    ) values (v_actor, p_target, v_at, v_at + v_policy.request_ttl)
    returning id into v_request;
  end if;
  insert into oa151_kernel.send_replays(actor_id, idempotency_key, target_id, request_id)
  values (v_actor, p_idempotency, p_target, v_request);
  return v_request;
end;
$send$;

create function oa151_kernel.cancel_request(p_request uuid)
returns text language plpgsql volatile security definer set search_path = ''
as $cancel$
declare
  v_actor uuid := oa151_kernel.actor();
  v_request oa151_kernel.requests%rowtype;
  v_at timestamptz;
begin
  v_request := oa151_kernel.owned_request(p_request, v_actor);
  if v_request.requester_id <> v_actor then raise exception 'oa151_not_requester'; end if;
  perform oa151_kernel.lock_accounts(v_request.requester_id, v_request.recipient_id);
  v_at := pg_catalog.clock_timestamp();
  perform oa151_kernel.expire_pair(v_request.requester_id, v_request.recipient_id, v_at);
  select * into v_request from oa151_kernel.requests where id = p_request for update;
  if v_request.status in ('pending', 'accepted') then
    update oa151_kernel.requests set status = 'cancelled', closed_at = v_at,
      requester_ready_at = null, recipient_ready_at = null, bridge_token = null
    where id = p_request;
    return 'cancelled';
  end if;
  return v_request.status;
end;
$cancel$;

create function oa151_kernel.decline_request(p_request uuid)
returns text language plpgsql volatile security definer set search_path = ''
as $decline$
declare
  v_actor uuid := oa151_kernel.actor();
  v_request oa151_kernel.requests%rowtype;
  v_at timestamptz;
begin
  v_request := oa151_kernel.owned_request(p_request, v_actor);
  if v_request.recipient_id <> v_actor then raise exception 'oa151_not_recipient'; end if;
  perform oa151_kernel.lock_accounts(v_request.requester_id, v_request.recipient_id);
  v_at := pg_catalog.clock_timestamp();
  perform oa151_kernel.expire_pair(v_request.requester_id, v_request.recipient_id, v_at);
  select * into v_request from oa151_kernel.requests where id = p_request for update;
  if v_request.status in ('pending', 'accepted') then
    update oa151_kernel.requests set status = 'declined', closed_at = v_at,
      requester_ready_at = null, recipient_ready_at = null, bridge_token = null
    where id = p_request;
    return 'declined';
  end if;
  return v_request.status;
end;
$decline$;

create function oa151_kernel.accept_request(p_request uuid)
returns text language plpgsql volatile security definer set search_path = ''
as $accept$
declare
  v_actor uuid := oa151_kernel.actor();
  v_request oa151_kernel.requests%rowtype;
  v_policy oa151_kernel.policy%rowtype;
  v_at timestamptz;
begin
  v_request := oa151_kernel.owned_request(p_request, v_actor);
  if v_request.recipient_id <> v_actor then raise exception 'oa151_not_recipient'; end if;
  v_policy := oa151_kernel.require_policy();
  perform oa151_kernel.lock_accounts(v_request.requester_id, v_request.recipient_id);
  v_at := pg_catalog.clock_timestamp();
  perform oa151_kernel.expire_pair(v_request.requester_id, v_request.recipient_id, v_at);
  select * into v_request from oa151_kernel.requests where id = p_request for update;
  if v_request.status = 'accepted' then return 'accepted'; end if;
  if v_request.status <> 'pending' then return v_request.status; end if;
  perform oa151_kernel.require_available_pair(v_request.requester_id, v_request.recipient_id, v_at);
  update oa151_kernel.requests set status = 'accepted', accepted_at = v_at,
    reservation_expires_at = v_at + v_policy.reservation_ttl
  where id = p_request;
  return 'accepted';
end;
$accept$;

create function oa151_kernel.mark_ready(p_request uuid)
returns table(request_id uuid, ready_to_bridge boolean, bridge_token uuid)
language plpgsql volatile security definer set search_path = ''
as $ready$
declare
  v_actor uuid := oa151_kernel.actor();
  v_request oa151_kernel.requests%rowtype;
  v_policy oa151_kernel.policy%rowtype;
  v_at timestamptz;
  v_a_cap integer;
  v_b_cap integer;
begin
  v_request := oa151_kernel.owned_request(p_request, v_actor);
  v_policy := oa151_kernel.require_policy();
  perform oa151_kernel.lock_accounts(v_request.requester_id, v_request.recipient_id);
  v_at := pg_catalog.clock_timestamp();
  perform oa151_kernel.expire_pair(v_request.requester_id, v_request.recipient_id, v_at);
  select * into v_request from oa151_kernel.requests r where r.id = p_request for update;
  if v_request.status <> 'accepted' then
    return query select p_request, false, null::uuid;
    return;
  end if;
  -- Count includes THIS live reservation: both parties must remain at or
  -- below, not strictly below, their independently trusted current cap.
  if oa151_synthetic.account_admission(v_request.requester_id) is distinct from true
     or oa151_synthetic.account_admission(v_request.recipient_id) is distinct from true
     or oa151_synthetic.pair_available(v_request.requester_id, v_request.recipient_id)
          is distinct from true then
    raise exception 'oa151_not_available';
  end if;
  v_a_cap := oa151_synthetic.journey_cap(v_request.requester_id);
  v_b_cap := oa151_synthetic.journey_cap(v_request.recipient_id);
  if v_a_cap is null or v_b_cap is null or v_a_cap <= 0 or v_b_cap <= 0 then
    raise exception 'oa151_not_available';
  end if;
  if oa151_kernel.occupancy(v_request.requester_id, v_at) > v_a_cap
     or oa151_kernel.occupancy(v_request.recipient_id, v_at) > v_b_cap then
    raise exception 'oa151_capacity_unavailable';
  end if;
  update oa151_kernel.requests r
  set requester_ready_at = case when v_actor = r.requester_id
          then coalesce(r.requester_ready_at, v_at) else r.requester_ready_at end,
      recipient_ready_at = case when v_actor = r.recipient_id
          then coalesce(r.recipient_ready_at, v_at) else r.recipient_ready_at end
  where r.id = p_request;
  update oa151_kernel.requests r
  set bridge_token = coalesce(r.bridge_token, pg_catalog.gen_random_uuid())
  where r.id = p_request and r.requester_ready_at is not null
    and r.recipient_ready_at is not null;
  return query select r.id, r.bridge_token is not null, r.bridge_token
  from oa151_kernel.requests r where r.id = p_request;
end;
$ready$;

create function oa151_kernel.inbox()
returns table(
  request_id uuid, requester_id uuid, recipient_id uuid, status text,
  created_at timestamptz, request_expires_at timestamptz,
  reservation_expires_at timestamptz, self_ready boolean,
  other_ready boolean, bridge_token uuid
)
language plpgsql volatile security definer set search_path = ''
as $inbox$
declare v_actor uuid := oa151_kernel.actor(); v_at timestamptz := pg_catalog.clock_timestamp();
begin
  return query select r.id, r.requester_id, r.recipient_id,
    case when r.status = 'pending' and r.request_expires_at <= v_at then 'request_expired'
         when r.status = 'accepted' and r.reservation_expires_at <= v_at then 'reservation_expired'
         else r.status end,
    r.created_at, r.request_expires_at, r.reservation_expires_at,
    (r.status = 'accepted' and r.reservation_expires_at > v_at and
      case when v_actor = r.requester_id then r.requester_ready_at is not null
           else r.recipient_ready_at is not null end),
    (r.status = 'accepted' and r.reservation_expires_at > v_at and
      case when v_actor = r.requester_id then r.recipient_ready_at is not null
           else r.requester_ready_at is not null end),
    case when r.status = 'accepted' and r.reservation_expires_at > v_at
         then r.bridge_token else null end
  from oa151_kernel.requests r
  where v_actor in (r.requester_id, r.recipient_id)
  order by r.created_at desc, r.id;
end;
$inbox$;

create function oa151_kernel.available_to_browse(p_target uuid)
returns boolean language plpgsql volatile security definer set search_path = ''
as $browse$
declare
  v_actor uuid := oa151_kernel.actor(); v_at timestamptz := pg_catalog.clock_timestamp();
  v_actor_cap integer; v_target_cap integer;
begin
  -- This is an availability-only synthetic projection. It does not change
  -- zyra_can_view_profile, photos, participant/Guardian reads or any history.
  if not exists (
       select 1 from oa151_kernel.policy p where p.singleton
         and p.request_ttl is not null and p.request_limit is not null
         and p.reservation_ttl is not null
     ) or p_target is null or p_target = v_actor
     or oa151_synthetic.account_admission(v_actor) is distinct from true
     or oa151_synthetic.account_admission(p_target) is distinct from true
     or oa151_synthetic.pair_available(v_actor, p_target) is distinct from true then
    return false;
  end if;
  v_actor_cap := oa151_synthetic.journey_cap(v_actor);
  v_target_cap := oa151_synthetic.journey_cap(p_target);
  if v_actor_cap is null or v_target_cap is null or v_actor_cap <= 0 or v_target_cap <= 0 then
    return false;
  end if;
  return oa151_kernel.occupancy(v_actor, v_at) < v_actor_cap
    and oa151_kernel.occupancy(p_target, v_at) < v_target_cap
    and not exists (
      select 1 from oa151_kernel.requests r
      where r.pair_a = least(v_actor, p_target) and r.pair_b = greatest(v_actor, p_target)
        and ((r.status = 'pending' and r.request_expires_at > v_at)
          or (r.status = 'accepted' and r.reservation_expires_at > v_at))
    );
end;
$browse$;

-- Explicit least-privilege matrix. No exposed public RPC, raw row access,
-- configuration endpoint or service-role/provider authority is created.
revoke all on all functions in schema oa151_kernel
  from public, anon, authenticated, service_role;
grant usage on schema oa151_kernel to authenticated;
grant execute on function oa151_kernel.send_request(uuid, uuid),
  oa151_kernel.cancel_request(uuid), oa151_kernel.decline_request(uuid),
  oa151_kernel.accept_request(uuid), oa151_kernel.mark_ready(uuid),
  oa151_kernel.inbox(), oa151_kernel.available_to_browse(uuid)
  to authenticated;

commit;
