-- Founder contract consolidation — 2026-09-24.
--
-- REPOSITORY/STAGING ONLY. Do not apply to production without the separate,
-- exact migration GO recorded in the health-check handover.
--
-- This forward migration supersedes the remaining Basic/free assumptions in
-- Journey capacity, completes the server shape for Guardian per-Journey
-- View/Chat controls, requires every Guardian Circle participant to hold
-- their own paid role entitlement, and creates bounded deletion/report
-- retention controls. It intentionally leaves Ended-return RPC execution
-- revoked while OA-ZYRA-156's attempt-owned ritual audit remains open.

-- =====================================================================
-- 1. Paid role authority, including future Family seats.
-- =====================================================================

alter table public.subscriptions
  add column if not exists billing_grace_started_at timestamptz,
  add column if not exists billing_grace_until timestamptz,
  add column if not exists coverage_ends_at timestamptz;

alter table public.subscriptions
  add constraint subscriptions_paid_only_monthly
  check (billing_period is null or billing_period = 'monthly') not valid;

alter table public.subscriptions
  add constraint subscriptions_billing_grace_maximum
  check (
    (billing_grace_started_at is null and billing_grace_until is null)
    or (
      billing_grace_started_at is not null
      and billing_grace_until is not null
      and billing_grace_until > billing_grace_started_at
      and billing_grace_until <= billing_grace_started_at + interval '16 days'
    )
  ) not valid;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to service_role;

-- One verified human may own separate Seeker and Guardian accounts, while a
-- one-way provider-person hash prevents email/device churn from replaying a
-- Seeker trial. No document, selfie, biometric, name or raw provider id is
-- stored here.
create table if not exists private.verified_people (
  id uuid primary key default gen_random_uuid(),
  provider_code text not null check (provider_code in ('stripe')),
  provider_person_ref_hash text not null unique
    check (provider_person_ref_hash ~ '^[0-9a-f]{64}$'),
  created_at timestamptz not null default now()
);

create table if not exists private.verified_person_accounts (
  verified_person_id uuid not null
    references private.verified_people(id) on delete restrict,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('seeker', 'guardian')),
  verified_at timestamptz not null default now(),
  primary key (user_id, role),
  unique (verified_person_id, role)
);

create table if not exists private.seeker_trial_ledger (
  verified_person_id uuid primary key
    references private.verified_people(id) on delete restrict,
  claimed_by uuid references auth.users(id) on delete set null,
  status text not null check (status in (
    'active', 'cancel_at_end', 'completed', 'family_forfeited'
  )),
  payment_authorisation_ref_hash text unique
    check (
      payment_authorisation_ref_hash is null
      or payment_authorisation_ref_hash ~ '^[0-9a-f]{64}$'
    ),
  started_at timestamptz,
  ends_at timestamptz,
  updated_at timestamptz not null default now(),
  constraint seeker_trial_active_shape check (
    status = 'family_forfeited'
    or (
      claimed_by is not null
      and payment_authorisation_ref_hash is not null
      and started_at is not null
      and ends_at = started_at + interval '14 days'
    )
  )
);

alter table private.verified_people enable row level security;
alter table private.verified_person_accounts enable row level security;
alter table private.seeker_trial_ledger enable row level security;
revoke all on private.verified_people from public, anon, authenticated;
revoke all on private.verified_person_accounts from public, anon, authenticated;
revoke all on private.seeker_trial_ledger from public, anon, authenticated;
grant select, insert, update on private.verified_people to service_role;
grant select, insert, update, delete on private.verified_person_accounts
  to service_role;
grant select, insert, update on private.seeker_trial_ledger to service_role;

create or replace function public.zyra_start_verified_seeker_trial(
  p_user uuid,
  p_verified_person uuid,
  p_payment_authorisation_ref_hash text
)
returns timestamptz
language plpgsql security definer set search_path = ''
as $$
declare
  v_end timestamptz;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'service_role_required';
  end if;
  if not exists (
    select 1
    from private.verified_person_accounts binding
    where binding.verified_person_id = p_verified_person
      and binding.user_id = p_user
      and binding.role = 'seeker'
  ) then raise exception 'verified_seeker_binding_required'; end if;
  insert into private.seeker_trial_ledger (
    verified_person_id, claimed_by, status,
    payment_authorisation_ref_hash, started_at, ends_at
  ) values (
    p_verified_person, p_user, 'active',
    p_payment_authorisation_ref_hash, now(), now() + interval '14 days'
  ) returning ends_at into v_end;
  return v_end;
exception when unique_violation then
  raise exception 'seeker_trial_already_used';
end;
$$;
revoke all on function public.zyra_start_verified_seeker_trial(uuid,uuid,text)
  from public, anon, authenticated;
grant execute on function public.zyra_start_verified_seeker_trial(uuid,uuid,text)
  to service_role;

create table if not exists public.family_subscriptions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete restrict,
  owner_role text not null check (owner_role in ('seeker', 'guardian')),
  status text not null check (status in (
    'pending', 'active', 'billing_grace', 'cancel_at_period_end',
    'expired', 'cancelled', 'refunded', 'chargeback'
  )),
  seeker_places integer not null check (seeker_places between 0 and 10),
  guardian_places integer not null check (guardian_places between 0 and 10),
  billing_period text not null default 'monthly'
    check (billing_period = 'monthly'),
  coverage_ends_at timestamptz,
  billing_grace_started_at timestamptz,
  billing_grace_until timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint family_subscriptions_non_empty
    check (seeker_places + guardian_places > 0),
  constraint family_subscriptions_billing_grace_maximum check (
    (billing_grace_started_at is null and billing_grace_until is null)
    or (
      billing_grace_started_at is not null
      and billing_grace_until is not null
      and billing_grace_until > billing_grace_started_at
      and billing_grace_until <= billing_grace_started_at + interval '16 days'
    )
  )
);

create table if not exists public.family_seat_assignments (
  id uuid primary key default gen_random_uuid(),
  family_subscription_id uuid not null
    references public.family_subscriptions(id) on delete cascade,
  member_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('seeker', 'guardian')),
  assigned_at timestamptz not null default now(),
  removed_at timestamptz,
  funded_until timestamptz,
  constraint family_seat_assignment_time_order
    check (removed_at is null or removed_at >= assigned_at)
);

create table if not exists public.family_membership_invitations (
  id uuid primary key default gen_random_uuid(),
  family_subscription_id uuid not null
    references public.family_subscriptions(id) on delete cascade,
  invited_by uuid not null references public.profiles(id) on delete cascade,
  invited_user_id uuid not null references public.profiles(id) on delete cascade,
  role text not null check (role in ('seeker', 'guardian')),
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined', 'expired', 'cancelled')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '7 days'),
  responded_at timestamptz,
  constraint family_invitation_seven_day_window
    check (expires_at = created_at + interval '7 days'),
  constraint family_invitation_response_shape check (
    (status = 'pending' and responded_at is null)
    or (status <> 'pending' and responded_at is not null)
  )
);

create unique index if not exists family_invitation_one_pending_role
  on public.family_membership_invitations(
    family_subscription_id, invited_user_id, role
  ) where status = 'pending';

create table if not exists public.family_ownership_transfers (
  id uuid primary key default gen_random_uuid(),
  family_subscription_id uuid not null
    references public.family_subscriptions(id) on delete cascade,
  current_owner_id uuid not null references public.profiles(id) on delete restrict,
  replacement_owner_id uuid not null references public.profiles(id) on delete restrict,
  replacement_role text not null check (replacement_role in ('seeker', 'guardian')),
  status text not null default 'pending_acceptance' check (status in (
    'pending_acceptance', 'pending_purchase', 'scheduled',
    'completed', 'declined', 'cancelled'
  )),
  requested_at timestamptz not null default now(),
  accepted_at timestamptz,
  replacement_purchase_confirmed_at timestamptz,
  effective_at timestamptz,
  completed_at timestamptz,
  constraint family_ownership_distinct_people
    check (current_owner_id <> replacement_owner_id),
  constraint family_ownership_schedule_shape check (
    status not in ('scheduled', 'completed')
    or (
      accepted_at is not null
      and replacement_purchase_confirmed_at is not null
      and effective_at is not null
    )
  )
);

create unique index if not exists family_seats_one_live_role_per_member
  on public.family_seat_assignments(member_id, role)
  where removed_at is null;
create index if not exists family_seats_subscription_live
  on public.family_seat_assignments(family_subscription_id, role)
  where removed_at is null;

alter table public.family_subscriptions enable row level security;
alter table public.family_seat_assignments enable row level security;
alter table public.family_membership_invitations enable row level security;
alter table public.family_ownership_transfers enable row level security;
revoke all on public.family_subscriptions from public, anon, authenticated;
revoke all on public.family_seat_assignments from public, anon, authenticated;
revoke all on public.family_membership_invitations
  from public, anon, authenticated;
revoke all on public.family_ownership_transfers
  from public, anon, authenticated;

create or replace function public.zyra_family_formula_monthly_pence(
  p_seekers integer,
  p_guardians integer
)
returns integer
language plpgsql immutable set search_path = ''
as $$
declare
  v_members integer;
  v_discount integer;
  v_gross integer;
begin
  if p_seekers not between 0 and 10
     or p_guardians not between 0 and 10
     or p_seekers + p_guardians = 0 then
    raise exception 'invalid_family_place_count';
  end if;
  v_members := p_seekers + p_guardians;
  v_discount := least(40, greatest(0, (v_members - 2) * 5));
  v_gross := p_seekers * 2999 + p_guardians * 1999;
  return (v_gross * (100 - v_discount) + 50) / 100;
end;
$$;
revoke all on function public.zyra_family_formula_monthly_pence(integer,integer)
  from public, anon, authenticated;
grant execute on function public.zyra_family_formula_monthly_pence(
  integer,integer
) to service_role;

create or replace function public.zyra_enforce_family_seat_capacity()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_family uuid;
  v_seekers integer;
  v_guardians integer;
begin
  v_family := case when tg_op = 'DELETE'
    then old.family_subscription_id
    else new.family_subscription_id
  end;
  perform pg_advisory_xact_lock(hashtextextended(v_family::text, 0));
  select family.seeker_places, family.guardian_places
  into v_seekers, v_guardians
  from public.family_subscriptions family
  where family.id = v_family
  for update;

  if (
    select count(*)
    from public.family_seat_assignments seat
    where seat.family_subscription_id = v_family
      and seat.role = 'seeker'
      and (seat.removed_at is null or seat.funded_until > now())
  ) > v_seekers then
    raise exception 'family_seeker_capacity_exceeded';
  end if;
  if (
    select count(*)
    from public.family_seat_assignments seat
    where seat.family_subscription_id = v_family
      and seat.role = 'guardian'
      and (seat.removed_at is null or seat.funded_until > now())
  ) > v_guardians then
    raise exception 'family_guardian_capacity_exceeded';
  end if;
  return null;
end;
$$;
revoke all on function public.zyra_enforce_family_seat_capacity()
  from public, anon, authenticated;

drop trigger if exists family_seat_capacity_guard
  on public.family_seat_assignments;
create constraint trigger family_seat_capacity_guard
after insert or update or delete on public.family_seat_assignments
deferrable initially immediate
for each row execute function public.zyra_enforce_family_seat_capacity();

create or replace function public.zyra_require_verified_family_seat()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if not exists (
    select 1
    from private.verified_person_accounts binding
    where binding.user_id = new.member_id
      and binding.role = new.role
  ) then
    raise exception 'verified_family_member_required';
  end if;
  return new;
end;
$$;
revoke all on function public.zyra_require_verified_family_seat()
  from public, anon, authenticated;

drop trigger if exists family_seat_verified_role_guard
  on public.family_seat_assignments;
create trigger family_seat_verified_role_guard
before insert or update of member_id, role
on public.family_seat_assignments
for each row execute function public.zyra_require_verified_family_seat();

create or replace function public.zyra_guard_family_place_reduction()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_funded_seekers integer;
  v_funded_guardians integer;
begin
  if new.seeker_places >= old.seeker_places
     and new.guardian_places >= old.guardian_places then
    return new;
  end if;

  perform pg_advisory_xact_lock(hashtextextended(new.id::text, 0));

  select
    count(*) filter (where seat.role = 'seeker'),
    count(*) filter (where seat.role = 'guardian')
  into v_funded_seekers, v_funded_guardians
  from public.family_seat_assignments seat
  where seat.family_subscription_id = new.id
    and (seat.removed_at is null or seat.funded_until > now());

  if new.seeker_places < v_funded_seekers then
    raise exception 'family_seeker_places_still_funded';
  end if;
  if new.guardian_places < v_funded_guardians then
    raise exception 'family_guardian_places_still_funded';
  end if;
  return new;
end;
$$;
revoke all on function public.zyra_guard_family_place_reduction()
  from public, anon, authenticated;

drop trigger if exists family_place_reduction_guard
  on public.family_subscriptions;
create trigger family_place_reduction_guard
before update of seeker_places, guardian_places on public.family_subscriptions
for each row execute function public.zyra_guard_family_place_reduction();

create or replace function public.zyra_assert_family_owner_seat(p_family uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_family public.family_subscriptions%rowtype;
begin
  select * into v_family
  from public.family_subscriptions family
  where family.id = p_family;
  if not found then return; end if;

  if not exists (
    select 1
    from private.verified_person_accounts binding
    where binding.user_id = v_family.owner_id
      and binding.role = v_family.owner_role
  ) then raise exception 'verified_family_owner_required'; end if;

  if (v_family.owner_role = 'seeker' and v_family.seeker_places < 1)
     or (v_family.owner_role = 'guardian' and v_family.guardian_places < 1) then
    raise exception 'family_owner_place_required';
  end if;

  if not exists (
    select 1
    from public.family_seat_assignments seat
    where seat.family_subscription_id = p_family
      and seat.member_id = v_family.owner_id
      and seat.role = v_family.owner_role
      and (seat.removed_at is null or seat.funded_until > now())
  ) then raise exception 'family_owner_seat_required'; end if;
end;
$$;
revoke all on function public.zyra_assert_family_owner_seat(uuid)
  from public, anon, authenticated;

create or replace function public.zyra_family_owner_row_guard()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  perform public.zyra_assert_family_owner_seat(new.id);
  return null;
end;
$$;
revoke all on function public.zyra_family_owner_row_guard()
  from public, anon, authenticated;

drop trigger if exists family_owner_row_guard on public.family_subscriptions;
create constraint trigger family_owner_row_guard
after insert or update of owner_id, owner_role, seeker_places, guardian_places
on public.family_subscriptions
deferrable initially deferred
for each row execute function public.zyra_family_owner_row_guard();

create or replace function public.zyra_family_owner_seat_guard()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  perform public.zyra_assert_family_owner_seat(
    case when tg_op = 'DELETE'
      then old.family_subscription_id
      else new.family_subscription_id
    end
  );
  return null;
end;
$$;
revoke all on function public.zyra_family_owner_seat_guard()
  from public, anon, authenticated;

drop trigger if exists family_owner_seat_guard
  on public.family_seat_assignments;
create constraint trigger family_owner_seat_guard
after insert or update or delete on public.family_seat_assignments
deferrable initially deferred
for each row execute function public.zyra_family_owner_seat_guard();

create or replace function public.zyra_forfeit_seeker_trial_on_family_seat()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_person uuid;
begin
  if new.role <> 'seeker'
     or not (new.removed_at is null or new.funded_until > now()) then
    return new;
  end if;
  select binding.verified_person_id into v_person
  from private.verified_person_accounts binding
  where binding.user_id = new.member_id and binding.role = 'seeker';
  if v_person is null then raise exception 'verified_family_member_required'; end if;

  insert into private.seeker_trial_ledger (
    verified_person_id, claimed_by, status, updated_at
  ) values (
    v_person, new.member_id, 'family_forfeited', now()
  ) on conflict (verified_person_id) do update
    set status = 'family_forfeited',
        ends_at = least(
          coalesce(private.seeker_trial_ledger.ends_at, now()),
          now()
        ),
        updated_at = now();
  return new;
end;
$$;
revoke all on function public.zyra_forfeit_seeker_trial_on_family_seat()
  from public, anon, authenticated;

drop trigger if exists family_seat_forfeits_seeker_trial
  on public.family_seat_assignments;
create trigger family_seat_forfeits_seeker_trial
after insert or update
on public.family_seat_assignments
for each row execute function public.zyra_forfeit_seeker_trial_on_family_seat();

create or replace function public.zyra_accept_family_invitation(
  p_invitation uuid
)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_caller uuid := (select auth.uid());
  v_invitation public.family_membership_invitations%rowtype;
  v_seat uuid;
begin
  select * into v_invitation
  from public.family_membership_invitations invitation
  where invitation.id = p_invitation
  for update;
  if not found or v_invitation.invited_user_id <> v_caller then
    raise exception 'family_invitation_not_found';
  end if;
  if v_invitation.status <> 'pending' then
    raise exception 'family_invitation_not_pending';
  end if;
  if v_invitation.expires_at <= now() then
    update public.family_membership_invitations
    set status = 'expired', responded_at = now()
    where id = p_invitation;
    raise exception 'family_invitation_expired';
  end if;
  if not exists (
    select 1
    from private.verified_person_accounts binding
    where binding.user_id = v_caller
      and binding.role = v_invitation.role
  ) then raise exception 'family_invitation_role_mismatch'; end if;

  insert into public.family_seat_assignments (
    family_subscription_id, member_id, role, funded_until
  )
  select family.id, v_caller, v_invitation.role, family.coverage_ends_at
  from public.family_subscriptions family
  where family.id = v_invitation.family_subscription_id
    and family.status = 'active'
    and coalesce(family.coverage_ends_at, 'infinity'::timestamptz) > now()
  returning id into v_seat;
  if v_seat is null then raise exception 'family_not_available'; end if;

  update public.family_membership_invitations
  set status = 'accepted', responded_at = now()
  where id = p_invitation;
  return v_seat;
end;
$$;
revoke all on function public.zyra_accept_family_invitation(uuid)
  from public, anon, authenticated;

create or replace function public.zyra_validate_family_ownership_transfer()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_family public.family_subscriptions%rowtype;
begin
  select * into v_family
  from public.family_subscriptions family
  where family.id = new.family_subscription_id;
  if not found or v_family.owner_id <> new.current_owner_id then
    raise exception 'family_transfer_owner_mismatch';
  end if;
  if not exists (
    select 1
    from public.family_seat_assignments seat
    where seat.family_subscription_id = new.family_subscription_id
      and seat.member_id = new.replacement_owner_id
      and seat.role = new.replacement_role
      and seat.removed_at is null
  ) then raise exception 'family_transfer_existing_member_required'; end if;
  if not exists (
    select 1
    from private.verified_person_accounts binding
    where binding.user_id = new.replacement_owner_id
      and binding.role = new.replacement_role
  ) then raise exception 'family_transfer_verified_member_required'; end if;
  if new.status in ('scheduled', 'completed')
     and new.effective_at is distinct from v_family.coverage_ends_at then
    raise exception 'family_transfer_must_start_at_renewal';
  end if;
  return new;
end;
$$;
revoke all on function public.zyra_validate_family_ownership_transfer()
  from public, anon, authenticated;

drop trigger if exists family_ownership_transfer_guard
  on public.family_ownership_transfers;
create trigger family_ownership_transfer_guard
before insert or update on public.family_ownership_transfers
for each row execute function public.zyra_validate_family_ownership_transfer();

create or replace function public.zyra_has_paid_role(
  p_user uuid,
  p_role text,
  p_at timestamptz default now()
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    p_user is not null
    and p_role in ('seeker', 'guardian')
    and (
      exists (
        select 1
        from public.subscriptions subscription
        where subscription.user_id = p_user
          and subscription.plan_type = case p_role
            when 'seeker' then 'seeker_premium'
            else 'wali_premium'
          end
          and (
            (
              subscription.status = 'active'
              and (
                subscription.expires_at is null
                or subscription.expires_at > p_at
                or subscription.billing_grace_until > p_at
              )
            )
            or (
              subscription.status = 'cancelled'
              and subscription.coverage_ends_at > p_at
            )
          )
      )
      or exists (
        select 1
        from public.family_seat_assignments seat
        join public.family_subscriptions family
          on family.id = seat.family_subscription_id
        where seat.member_id = p_user
          and seat.role = p_role
          and coalesce(seat.funded_until, 'infinity'::timestamptz) > p_at
          and (
            seat.removed_at is null
            or coalesce(seat.funded_until, seat.removed_at) > p_at
          )
          and (
            (
              family.status in ('active', 'cancel_at_period_end')
              and coalesce(
                family.coverage_ends_at,
                'infinity'::timestamptz
              ) > p_at
            )
            or (
              family.status = 'billing_grace'
              and family.billing_grace_until > p_at
            )
          )
      )
    );
$$;

revoke all on function public.zyra_has_paid_role(uuid,text,timestamptz)
  from public, anon, authenticated;
grant execute on function public.zyra_has_paid_role(uuid,text,timestamptz)
  to service_role;

comment on function public.zyra_has_paid_role(uuid,text,timestamptz) is
  'Single server authority for paid Seeker/Guardian role access. Covers a '
  'direct One entitlement or a currently funded Family role seat; no Basic '
  'or free fallback exists.';

create or replace function public.zyra_my_paid_access(p_role text)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select public.zyra_has_paid_role((select auth.uid()), p_role);
$$;
revoke all on function public.zyra_my_paid_access(text) from public, anon;
grant execute on function public.zyra_my_paid_access(text) to authenticated;

create or replace function public.zyra_active_journey_cap(p_user uuid)
returns integer
language sql stable security definer set search_path = ''
as $$
  select case when public.zyra_has_paid_role(p_user, 'seeker') then 3 else 0 end;
$$;
revoke all on function public.zyra_active_journey_cap(uuid)
  from public, anon, authenticated;

create or replace function public.zyra_paused_journey_cap(p_user uuid)
returns integer
language sql stable security definer set search_path = ''
as $$
  select case when public.zyra_has_paid_role(p_user, 'seeker') then 10 else 0 end;
$$;
revoke all on function public.zyra_paused_journey_cap(uuid)
  from public, anon, authenticated;

-- =====================================================================
-- 2. Paused return initiation: paid requester, latest five, both below cap.
-- =====================================================================

create or replace function public.zyra_guard_paused_return_initiation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_caller uuid := (select auth.uid());
begin
  if old.pause_state <> 'paused' or new.pause_state <> 'resume_requested' then
    return new;
  end if;
  if v_caller is null then return new; end if;
  if v_caller not in (new.seeker_a_id, new.seeker_b_id) then
    raise exception 'not_a_party';
  end if;
  if not public.zyra_has_paid_role(v_caller, 'seeker') then
    raise exception 'return_membership_required';
  end if;
  if not exists (
    select 1
    from (
      select match.id
      from public.matches match
      where match.status = 'active'
        and match.pause_state in ('paused', 'resume_requested')
        and v_caller in (match.seeker_a_id, match.seeker_b_id)
      order by match.suspended_at desc nulls last, match.id desc
      limit 5
    ) recent
    where recent.id = new.id
  ) then
    raise exception 'return_window_exceeded';
  end if;
  if public.zyra_active_journey_count(new.seeker_a_id, new.id)
       >= public.zyra_active_journey_cap(new.seeker_a_id)
     or public.zyra_active_journey_count(new.seeker_b_id, new.id)
       >= public.zyra_active_journey_cap(new.seeker_b_id) then
    raise exception 'journey_capacity_unavailable';
  end if;
  return new;
end;
$$;

revoke all on function public.zyra_guard_paused_return_initiation()
  from public, anon, authenticated;

-- A privacy-preserving status marker. False deliberately carries no reason.
create or replace function public.zyra_journey_return_available(p_match_id uuid)
returns boolean
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_match public.matches%rowtype;
  v_caller uuid := (select auth.uid());
begin
  if v_caller is null then return false; end if;
  select * into v_match from public.matches where id = p_match_id;
  if not found or v_caller not in (v_match.seeker_a_id, v_match.seeker_b_id) then
    return false;
  end if;
  return public.zyra_has_paid_role(v_caller, 'seeker')
    and public.zyra_active_journey_count(v_match.seeker_a_id, v_match.id)
      < public.zyra_active_journey_cap(v_match.seeker_a_id)
    and public.zyra_active_journey_count(v_match.seeker_b_id, v_match.id)
      < public.zyra_active_journey_cap(v_match.seeker_b_id);
end;
$$;
revoke all on function public.zyra_journey_return_available(uuid)
  from public, anon;
grant execute on function public.zyra_journey_return_available(uuid)
  to authenticated;

create or replace function public.zyra_available_journey_return_ids()
returns setof uuid
language sql stable security definer set search_path = ''
as $$
  with caller as (select (select auth.uid()) as user_id),
  paused_recent as (
    select match.id
    from public.matches match, caller
    where caller.user_id in (match.seeker_a_id, match.seeker_b_id)
      and match.status = 'active'
      and match.pause_state in ('paused', 'resume_requested')
    order by match.suspended_at desc nulls last, match.id desc
    limit 5
  ),
  ended_recent as (
    select match.id
    from public.matches match, caller
    where caller.user_id in (match.seeker_a_id, match.seeker_b_id)
      and match.status = 'ended'
    order by match.ended_at desc nulls last, match.id desc
    limit 5
  )
  select candidate.id
  from (
    select id from paused_recent
    union
    select id from ended_recent
  ) candidate
  where public.zyra_journey_return_available(candidate.id);
$$;
revoke all on function public.zyra_available_journey_return_ids()
  from public, anon;
grant execute on function public.zyra_available_journey_return_ids()
  to authenticated;

-- =====================================================================
-- 3. Ended-return contract. Definitions are repaired but app execution
--    remains revoked until the separate OA-ZYRA-156 release GO.
-- =====================================================================

alter table public.journey_requests
  add column if not exists withdrawn_at timestamptz,
  add column if not exists closed_reason text;

alter table public.journey_requests
  drop constraint if exists requests_status_known;
alter table public.journey_requests
  add constraint requests_status_known check (status in (
    'pending', 'accepted', 'declined', 'withdrawn', 'recipient_unavailable'
  ));

alter table public.journey_requests
  drop constraint if exists requests_response_matches_status;
alter table public.journey_requests
  add constraint requests_response_matches_status check (
    (status = 'pending' and responded_at is null and withdrawn_at is null)
    or (status = 'withdrawn' and responded_at is null and withdrawn_at is not null)
    or (status in ('accepted','declined','recipient_unavailable')
        and responded_at is not null and withdrawn_at is null)
  );

create or replace function public.zyra_expire_due_journey_requests(
  p_match_id uuid default null
)
returns integer
language plpgsql security definer set search_path = ''
as $$
declare
  request_row record;
  v_count integer := 0;
begin
  for request_row in
    select *
    from public.journey_requests request
    where request.status = 'pending'
      and request.expires_at <= now()
      and (p_match_id is null or request.match_id = p_match_id)
    for update skip locked
  loop
    update public.journey_requests
    set status = 'declined', responded_at = now(), closed_reason = 'expired'
    where id = request_row.id;

    if not public.zyra_hold_blocks(
      request_row.requested_by,
      request_row.requested_to
    ) then
      insert into public.protection_holds (
        match_id, restricted_id, protected_id, hold_type, appealable, expires_at
      ) values (
        request_row.match_id,
        request_row.requested_by,
        request_row.requested_to,
        'decline_cooldown',
        true,
        now() + interval '30 days'
      );
    end if;

    perform public.create_notification(
      request_row.requested_by,
      'journey_request_declined',
      'Journey request',
      'Your request to begin a new Journey was not taken up.',
      request_row.match_id
    );
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;
revoke all on function public.zyra_expire_due_journey_requests(uuid)
  from public, anon;
grant execute on function public.zyra_expire_due_journey_requests(uuid)
  to authenticated;

create or replace function public.withdraw_journey_request(p_request_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_caller uuid := (select auth.uid());
begin
  update public.journey_requests request
  set status = 'withdrawn', withdrawn_at = now(), closed_reason = 'sender_withdrew'
  where request.id = p_request_id
    and request.requested_by = v_caller
    and request.status = 'pending';
  if not found then raise exception 'request_not_withdrawable'; end if;
end;
$$;
revoke all on function public.withdraw_journey_request(uuid)
  from public, anon, authenticated;

-- Close requests without describing the recipient's billing state.
create or replace function public.zyra_close_unavailable_journey_requests()
returns integer
language plpgsql security definer set search_path = ''
as $$
declare
  v_count integer;
begin
  with unavailable as (
    update public.journey_requests request
    set status = 'recipient_unavailable',
        responded_at = now(),
        closed_reason = 'recipient_unavailable'
    where request.status = 'pending'
      and not public.zyra_has_paid_role(request.requested_to, 'seeker')
    returning request.requested_by, request.match_id
  ), notified as (
    select public.create_notification(
      unavailable.requested_by,
      'journey_request_declined',
      'Journey request',
      'This person is not available to reconnect right now.',
      unavailable.match_id
    )
    from unavailable
  )
  select count(*)::integer into v_count from notified;
  return coalesce(v_count, 0);
end;
$$;
revoke all on function public.zyra_close_unavailable_journey_requests()
  from public, anon, authenticated;
grant execute on function public.zyra_close_unavailable_journey_requests()
  to service_role;

create or replace function public.request_new_journey(p_match_id uuid)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_caller uuid := (select auth.uid());
  v_match public.matches%rowtype;
  v_other uuid;
  v_request uuid;
  v_name text;
begin
  if v_caller is null then raise exception 'not_signed_in'; end if;
  select * into v_match from public.matches where id = p_match_id for update;
  if not found then raise exception 'match_not_found'; end if;
  if v_caller not in (v_match.seeker_a_id, v_match.seeker_b_id) then
    raise exception 'not_a_party';
  end if;
  v_other := case when v_caller = v_match.seeker_a_id
    then v_match.seeker_b_id else v_match.seeker_a_id end;

  if v_match.status <> 'ended' then raise exception 'journey_not_ended'; end if;
  if v_match.ended_at is null
     or now() < v_match.ended_at + interval '24 hours' then
    raise exception 'cooling_period_active';
  end if;
  if not public.zyra_has_paid_role(v_caller, 'seeker') then
    raise exception 'return_membership_required';
  end if;
  if not public.zyra_has_paid_role(v_other, 'seeker') then
    raise exception 'not_available';
  end if;
  if not exists (
    select 1 from (
      select match.id
      from public.matches match
      where match.status = 'ended'
        and v_caller in (match.seeker_a_id, match.seeker_b_id)
      order by match.ended_at desc nulls last, match.id desc
      limit 5
    ) recent where recent.id = p_match_id
  ) then
    raise exception 'return_window_exceeded';
  end if;
  if public.zyra_block_exists(v_other)
     or not public.zyra_can_match(v_caller, v_other)
     or public.zyra_hold_blocks(v_caller, v_other) then
    raise exception 'not_available';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(least(v_match.seeker_a_id, v_match.seeker_b_id)::text, 0)
  );
  perform pg_advisory_xact_lock(
    hashtextextended(greatest(v_match.seeker_a_id, v_match.seeker_b_id)::text, 0)
  );
  if public.zyra_active_journey_count(v_match.seeker_a_id, v_match.id)
       >= public.zyra_active_journey_cap(v_match.seeker_a_id)
     or public.zyra_active_journey_count(v_match.seeker_b_id, v_match.id)
       >= public.zyra_active_journey_cap(v_match.seeker_b_id) then
    raise exception 'journey_capacity_unavailable';
  end if;
  if exists (
    select 1 from public.journey_requests request
    where request.match_id = p_match_id and request.status = 'pending'
  ) then
    raise exception 'request_already_pending';
  end if;

  insert into public.journey_requests (
    match_id, requested_by, requested_to, expires_at
  ) values (
    p_match_id, v_caller, v_other, now() + interval '30 days'
  ) returning id into v_request;

  select profile.first_name into v_name
  from public.profiles profile where profile.id = v_caller;
  perform public.create_notification(
    v_other,
    'journey_request',
    'A new Journey',
    coalesce(v_name, 'Someone') ||
      ' would like to begin a new Journey with you.',
    p_match_id
  );
  return v_request;
end;
$$;

create or replace function public.respond_to_journey_request(
  p_request_id uuid,
  p_decision text
)
returns text
language plpgsql security definer set search_path = ''
as $$
declare
  v_caller uuid := (select auth.uid());
  v_request public.journey_requests%rowtype;
  v_match public.matches%rowtype;
  v_attempt uuid;
  v_attempt_number integer;
  v_name text;
begin
  if v_caller is null then raise exception 'not_signed_in'; end if;
  if p_decision not in ('accept', 'decline', 'decline_never') then
    raise exception 'unknown_decision';
  end if;
  select * into v_request
  from public.journey_requests request
  where request.id = p_request_id
  for update;
  if not found then raise exception 'request_not_found'; end if;
  if v_request.requested_to <> v_caller then
    raise exception 'not_yours_to_answer';
  end if;
  if v_request.status <> 'pending' then raise exception 'already_answered'; end if;
  if v_request.expires_at <= now() then raise exception 'request_expired'; end if;

  if not public.zyra_has_paid_role(v_caller, 'seeker') then
    update public.journey_requests
    set status = 'recipient_unavailable',
        responded_at = now(),
        closed_reason = 'recipient_unavailable'
    where id = p_request_id;
    perform public.create_notification(
      v_request.requested_by,
      'journey_request_declined',
      'Journey request',
      'This person is not available to reconnect right now.',
      v_request.match_id
    );
    return 'recipient_unavailable';
  end if;

  select * into v_match
  from public.matches match
  where match.id = v_request.match_id
  for update;

  if p_decision in ('decline', 'decline_never') then
    update public.journey_requests
    set status = 'declined', responded_at = now(), closed_reason = 'declined'
    where id = p_request_id;
    insert into public.protection_holds (
      match_id, restricted_id, protected_id, hold_type, appealable, expires_at
    ) values (
      v_request.match_id,
      v_request.requested_by,
      v_caller,
      case when p_decision = 'decline_never'
        then 'decline_permanent' else 'decline_cooldown' end,
      true,
      case when p_decision = 'decline_never'
        then null else now() + interval '30 days' end
    );
    perform public.create_notification(
      v_request.requested_by,
      'journey_request_declined',
      'Journey request',
      'Your request to begin a new Journey was not taken up.',
      v_request.match_id
    );
    return 'declined';
  end if;

  if not public.zyra_has_paid_role(v_request.requested_by, 'seeker')
     or public.zyra_block_exists(v_request.requested_by)
     or not public.zyra_can_match(v_caller, v_request.requested_by) then
    raise exception 'not_available';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(least(v_match.seeker_a_id, v_match.seeker_b_id)::text, 0)
  );
  perform pg_advisory_xact_lock(
    hashtextextended(greatest(v_match.seeker_a_id, v_match.seeker_b_id)::text, 0)
  );
  if public.zyra_active_journey_count(v_match.seeker_a_id, v_match.id)
       >= public.zyra_active_journey_cap(v_match.seeker_a_id)
     or public.zyra_active_journey_count(v_match.seeker_b_id, v_match.id)
       >= public.zyra_active_journey_cap(v_match.seeker_b_id) then
    raise exception 'journey_capacity_unavailable';
  end if;

  select coalesce(max(attempt.attempt_number), 0) + 1
  into v_attempt_number
  from public.journey_attempts attempt
  where attempt.match_id = v_request.match_id;

  insert into public.journey_attempts (
    match_id, attempt_number, status, journey_stage, started_at
  ) values (
    v_request.match_id,
    v_attempt_number,
    'active',
    'compatibility_reveal',
    now()
  ) returning id into v_attempt;

  -- matches is the permanent pair envelope. The prior Journey remains an
  -- immutable ended journey_attempt; this update projects only the new current
  -- attempt so legacy list code can find it.
  update public.matches
  set status = 'active',
      journey_stage = 'compatibility_reveal',
      ended_by = null,
      end_reason = null,
      end_note = null,
      suspended_by = null,
      suspended_at = null,
      pause_state = 'none',
      pause_initiated_by = null,
      pause_requested_by = null,
      pause_requested_at = null,
      pause_deadline_at = null,
      pause_attempt_id = null
  where id = v_request.match_id;

  insert into public.conversations(match_id, attempt_id, status)
  values (v_request.match_id, v_attempt, 'active');
  insert into public.timelines(match_id, attempt_id)
  values (v_request.match_id, v_attempt);

  update public.journey_requests
  set status = 'accepted', responded_at = now(), attempt_id = v_attempt,
      closed_reason = 'accepted'
  where id = p_request_id;

  select profile.first_name into v_name
  from public.profiles profile where profile.id = v_caller;
  perform public.create_notification(
    v_request.requested_by,
    'journey_request_accepted',
    'A new Journey',
    coalesce(v_name, 'They') || ' accepted. Your new Journey has begun.',
    v_request.match_id
  );
  return 'accepted';
end;
$$;

create or replace function public.zyra_may_request_new_journey(p_match_id uuid)
returns boolean
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_caller uuid := (select auth.uid());
  v_match public.matches%rowtype;
  v_other uuid;
begin
  if v_caller is null then return false; end if;
  select * into v_match from public.matches where id = p_match_id;
  if not found or v_caller not in (v_match.seeker_a_id, v_match.seeker_b_id) then
    return false;
  end if;
  v_other := case when v_caller = v_match.seeker_a_id
    then v_match.seeker_b_id else v_match.seeker_a_id end;
  return v_match.status = 'ended'
    and v_match.ended_at is not null
    and now() >= v_match.ended_at + interval '24 hours'
    and public.zyra_has_paid_role(v_caller, 'seeker')
    and public.zyra_has_paid_role(v_other, 'seeker')
    and not public.zyra_block_exists(v_other)
    and public.zyra_can_match(v_caller, v_other)
    and not public.zyra_hold_blocks(v_caller, v_other)
    and not exists (
      select 1 from public.journey_requests request
      where request.match_id = p_match_id and request.status = 'pending'
    )
    and exists (
      select 1 from (
        select match.id
        from public.matches match
        where match.status = 'ended'
          and v_caller in (match.seeker_a_id, match.seeker_b_id)
        order by match.ended_at desc nulls last, match.id desc
        limit 5
      ) recent where recent.id = p_match_id
    )
    and public.zyra_journey_return_available(p_match_id);
end;
$$;

create or replace function public.zyra_may_request_new_journey_ids()
returns setof uuid
language sql stable security definer set search_path = ''
as $$
  select match.id
  from public.matches match
  where (select auth.uid()) in (match.seeker_a_id, match.seeker_b_id)
    and public.zyra_may_request_new_journey(match.id);
$$;

-- Keep every ended-return entry point held. A later exact migration may grant
-- these only after ritual rows are proven attempt-owned and all new function
-- bodies have passed impersonation tests.
revoke execute on function public.request_new_journey(uuid)
  from public, anon, authenticated;
revoke execute on function public.respond_to_journey_request(uuid,text)
  from public, anon, authenticated;
revoke execute on function public.zyra_may_request_new_journey(uuid)
  from public, anon, authenticated;
revoke execute on function public.zyra_may_request_new_journey_ids()
  from public, anon, authenticated;
revoke execute on function public.withdraw_journey_request(uuid)
  from public, anon, authenticated;

-- =====================================================================
-- 4. Per-Guardian, per-active-Journey View and Chat authority.
-- =====================================================================

create table if not exists public.guardian_journey_permissions (
  wali_link_id uuid not null references public.wali_links(id) on delete cascade,
  match_id uuid not null references public.matches(id) on delete cascade,
  can_view boolean not null default true,
  can_chat boolean not null default true,
  updated_by uuid not null references public.profiles(id) on delete cascade,
  updated_at timestamptz not null default now(),
  primary key (wali_link_id, match_id),
  constraint guardian_journey_chat_requires_view
    check (can_view or not can_chat)
);

alter table public.guardian_journey_permissions enable row level security;
revoke all on public.guardian_journey_permissions
  from public, anon, authenticated;

create or replace function public.zyra_set_guardian_journey_permission(
  p_wali_link_id uuid,
  p_match_id uuid,
  p_can_view boolean,
  p_can_chat boolean
)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_caller uuid := (select auth.uid());
  v_link public.wali_links%rowtype;
begin
  select * into v_link
  from public.wali_links link
  where link.id = p_wali_link_id
  for update;
  if not found or v_link.seeker_id <> v_caller or v_link.status <> 'active' then
    raise exception 'guardian_link_not_available';
  end if;
  if v_link.is_main then raise exception 'main_guardian_access_required'; end if;
  if p_can_chat and not p_can_view then
    raise exception 'guardian_chat_requires_view';
  end if;
  if not exists (
    select 1 from public.matches match
    where match.id = p_match_id
      and match.status = 'active'
      and v_caller in (match.seeker_a_id, match.seeker_b_id)
  ) then
    raise exception 'active_journey_not_available';
  end if;

  insert into public.guardian_journey_permissions (
    wali_link_id, match_id, can_view, can_chat, updated_by, updated_at
  ) values (
    p_wali_link_id, p_match_id, p_can_view, p_can_chat, v_caller, now()
  )
  on conflict (wali_link_id, match_id) do update
    set can_view = excluded.can_view,
        can_chat = excluded.can_chat,
        updated_by = excluded.updated_by,
        updated_at = excluded.updated_at;
end;
$$;

revoke all on function public.zyra_set_guardian_journey_permission(
  uuid,uuid,boolean,boolean
) from public, anon;
grant execute on function public.zyra_set_guardian_journey_permission(
  uuid,uuid,boolean,boolean
) to authenticated;

create or replace function public.zyra_guardian_journey_permissions(
  p_wali_link_id uuid
)
returns table(match_id uuid, can_view boolean, can_chat boolean)
language sql stable security definer set search_path = ''
as $$
  select
    match.id,
    case when link.is_main then true else coalesce(permission.can_view, true) end,
    case when link.is_main then true else coalesce(permission.can_chat, true) end
  from public.wali_links link
  join public.matches match
    on link.seeker_id in (match.seeker_a_id, match.seeker_b_id)
   and match.status = 'active'
  left join public.guardian_journey_permissions permission
    on permission.wali_link_id = link.id and permission.match_id = match.id
  where link.id = p_wali_link_id
    and link.status = 'active'
    and (link.seeker_id = (select auth.uid())
      or link.wali_id = (select auth.uid()));
$$;

revoke all on function public.zyra_guardian_journey_permissions(uuid)
  from public, anon;
grant execute on function public.zyra_guardian_journey_permissions(uuid)
  to authenticated;

-- Current clients address a Guardian by profile id. The fourth argument lets
-- View and Chat be changed independently while retaining a three-argument
-- compatibility wrapper for already-installed internal builds.
create or replace function public.zyra_guardian_journey_access(
  p_guardian uuid,
  p_attempt uuid default null,
  p_enabled boolean default null,
  p_chat_enabled boolean default null
)
returns table (
  attempt_id uuid,
  match_id uuid,
  counterpart_first_name text,
  included boolean,
  can_change boolean,
  guardian_is_main boolean,
  chat_available boolean,
  chat_enabled boolean
)
language plpgsql security definer set search_path = ''
as $$
declare
  v_caller uuid := (select auth.uid());
  v_link_id uuid;
  v_is_main boolean;
  v_match_id uuid;
begin
  if v_caller is null then raise exception 'not_signed_in'; end if;
  if p_guardian is null then raise exception 'guardian_required'; end if;
  if p_attempt is null and (p_enabled is not null or p_chat_enabled is not null) then
    raise exception 'attempt_required_for_change';
  end if;

  select link.id, link.is_main into v_link_id, v_is_main
  from public.wali_links link
  where link.seeker_id = v_caller
    and link.wali_id = p_guardian
    and link.status = 'active';
  if not found then raise exception 'active_guardian_link_not_found'; end if;

  if p_attempt is not null then
    select attempt.match_id into v_match_id
    from public.journey_attempts attempt
    join public.matches match on match.id = attempt.match_id
    where attempt.id = p_attempt
      and attempt.status = 'active'
      and v_caller in (match.seeker_a_id, match.seeker_b_id);
    if v_match_id is null then raise exception 'active_owned_journey_not_found'; end if;
    if v_is_main and (p_enabled is not null or p_chat_enabled is not null) then
      raise exception 'main_guardian_access_required';
    end if;

    insert into public.guardian_journey_permissions (
      wali_link_id, match_id, can_view, can_chat, updated_by, updated_at
    ) values (
      v_link_id,
      v_match_id,
      coalesce(p_enabled, true),
      case
        when p_enabled is false then false
        else coalesce(p_chat_enabled, true)
      end,
      v_caller,
      now()
    )
    on conflict (wali_link_id, match_id) do update
      set can_view = coalesce(p_enabled, guardian_journey_permissions.can_view),
          can_chat = case
            when coalesce(p_enabled, guardian_journey_permissions.can_view) is false
              then false
            else coalesce(
              p_chat_enabled,
              guardian_journey_permissions.can_chat
            )
          end,
          updated_by = v_caller,
          updated_at = now();
  end if;

  return query
  select
    attempt.id,
    attempt.match_id,
    counterpart.first_name,
    case when v_is_main then true else coalesce(permission.can_view, true) end,
    not v_is_main,
    v_is_main,
    true,
    case when v_is_main then true else coalesce(permission.can_chat, true) end
  from public.journey_attempts attempt
  join public.matches match on match.id = attempt.match_id
  join public.profiles counterpart on counterpart.id = case
    when match.seeker_a_id = v_caller then match.seeker_b_id
    else match.seeker_a_id
  end
  left join public.guardian_journey_permissions permission
    on permission.wali_link_id = v_link_id
   and permission.match_id = attempt.match_id
  where attempt.status = 'active'
    and v_caller in (match.seeker_a_id, match.seeker_b_id)
  order by attempt.started_at desc nulls last, attempt.created_at desc, attempt.id;
end;
$$;

revoke all on function public.zyra_guardian_journey_access(
  uuid,uuid,boolean,boolean
) from public, anon;
grant execute on function public.zyra_guardian_journey_access(
  uuid,uuid,boolean,boolean
) to authenticated;

create or replace function public.zyra_guardian_journey_access(
  p_guardian uuid,
  p_attempt uuid default null,
  p_enabled boolean default null
)
returns table (
  attempt_id uuid,
  match_id uuid,
  counterpart_first_name text,
  included boolean,
  can_change boolean,
  guardian_is_main boolean,
  chat_available boolean,
  chat_enabled boolean
)
language sql security definer set search_path = ''
as $$
  select * from public.zyra_guardian_journey_access(
    p_guardian, p_attempt, p_enabled, null::boolean
  );
$$;
revoke all on function public.zyra_guardian_journey_access(uuid,uuid,boolean)
  from public, anon;
grant execute on function public.zyra_guardian_journey_access(uuid,uuid,boolean)
  to authenticated;

-- Append can_chat to the canonical participant rows. Additional Guardians
-- with View off cease to be attempt participants. Main remains always on.
create or replace view public.zyra_attempt_participant_rows as
  select attempt.id as attempt_id, match.seeker_a_id as user_id,
         'seeker'::text as role, attempt.match_id,
         null::boolean as is_main, attempt.status as attempt_status,
         true::boolean as can_chat
  from public.journey_attempts attempt
  join public.matches match on match.id = attempt.match_id
  union all
  select attempt.id, match.seeker_b_id, 'seeker', attempt.match_id,
         null::boolean, attempt.status, true::boolean
  from public.journey_attempts attempt
  join public.matches match on match.id = attempt.match_id
  union all
  select attempt.id, link.wali_id, 'guardian', attempt.match_id,
         link.is_main, attempt.status,
         case when link.is_main then true else coalesce(permission.can_chat, true) end
  from public.journey_attempts attempt
  join public.matches match on match.id = attempt.match_id
  join public.wali_links link
    on link.status = 'active'
   and link.seeker_id in (match.seeker_a_id, match.seeker_b_id)
  left join public.guardian_journey_permissions permission
    on permission.wali_link_id = link.id
   and permission.match_id = attempt.match_id
  where link.is_main
     or coalesce(permission.can_view, true);

revoke all on public.zyra_attempt_participant_rows
  from public, anon, authenticated;

drop policy if exists messages_insert on public.messages;
create policy messages_insert on public.messages for insert to authenticated
with check (
  sender_id = (select auth.uid())
  and exists (
    select 1
    from public.conversations conversation
    join public.zyra_attempt_participant_rows participant
      on participant.match_id = conversation.match_id
    where conversation.id = messages.conversation_id
      and participant.user_id = (select auth.uid())
      and (
        participant.role = 'seeker'
        or (participant.role = 'guardian' and participant.can_chat)
      )
      and participant.attempt_status <> 'potential'
  )
);

-- =====================================================================
-- 5. Guardian Circle: every current participant holds their own paid role.
-- =====================================================================

create or replace function public.zyra_family_message_circle_can_send(
  p_seeker uuid
)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select
    p_seeker is not null
    and public.zyra_has_paid_role(p_seeker, 'seeker')
    and exists (
      select 1 from public.wali_links link
      where link.seeker_id = p_seeker
        and link.status = 'active'
        and not exists (
          select 1 from public.profile_blocks block
          where (block.blocker_id = p_seeker and block.blocked_id = link.wali_id)
             or (block.blocker_id = link.wali_id and block.blocked_id = p_seeker)
        )
    )
    and not exists (
      select 1 from public.wali_links link
      where link.seeker_id = p_seeker
        and link.status = 'active'
        and not exists (
          select 1 from public.profile_blocks block
          where (block.blocker_id = p_seeker and block.blocked_id = link.wali_id)
             or (block.blocker_id = link.wali_id and block.blocked_id = p_seeker)
        )
        and not public.zyra_has_paid_role(link.wali_id, 'guardian')
    );
$$;
revoke all on function public.zyra_family_message_circle_can_send(uuid)
  from public, anon, authenticated;

-- =====================================================================
-- 6. Account deletion and safety evidence retention.
-- =====================================================================

alter table public.family_messages
  add column if not exists sender_deleted_at timestamptz;

alter table public.family_message_reports
  add column if not exists status text not null default 'pending'
    check (status in ('pending', 'reviewing', 'actioned', 'dismissed')),
  add column if not exists reviewed_at timestamptz;

-- Preserve honest authorship labels without restoring access to a removed
-- Guardian's old membership epoch. Deleted profiles are intentionally
-- anonymous; a linked Guardian who has left the Circle is shown by role,
-- not as though they were still a current participant.
create or replace function public.zyra_family_messages(
  p_thread uuid,
  p_before timestamptz default null,
  p_limit integer default 50
) returns table (
  message_id uuid,
  sender_id uuid,
  sender_first_name text,
  kind text,
  body text,
  created_at timestamptz
)
language sql stable security definer set search_path = ''
as $$
  select
    message.id,
    message.sender_id,
    case
      when message.sender_id is null then 'Deleted member'
      when exists (
        select 1
        from public.family_message_memberships former
        where former.thread_id = message.thread_id
          and former.user_id = message.sender_id
          and former.member_role = 'guardian'
          and former.left_at is not null
      ) and not exists (
        select 1
        from public.family_message_memberships current_member
        where current_member.thread_id = message.thread_id
          and current_member.user_id = message.sender_id
          and current_member.left_at is null
      ) then 'Former Guardian'
      else sender.first_name
    end,
    message.kind,
    message.body,
    message.created_at
  from public.family_messages message
  join public.family_message_memberships membership
    on membership.thread_id = message.thread_id
   and membership.user_id = (select auth.uid())
   and membership.left_at is null
  left join public.profiles sender on sender.id = message.sender_id
  where message.thread_id = p_thread
    and message.created_at >= membership.readable_from
    and (p_before is null or message.created_at < p_before)
  order by message.created_at desc, message.id desc
  limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;
revoke execute on function public.zyra_family_messages(uuid,timestamptz,integer)
  from public, anon;
grant execute on function public.zyra_family_messages(uuid,timestamptz,integer)
  to authenticated;

create table if not exists public.family_message_report_evidence (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null unique,
  thread_id uuid not null,
  message_id uuid not null,
  reported_sender_id uuid,
  reason text not null,
  reported_body text not null,
  immediate_context jsonb not null default '[]'::jsonb,
  reported_at timestamptz not null,
  closed_at timestamptz,
  retain_until timestamptz,
  legal_hold boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.family_message_report_evidence enable row level security;
revoke all on public.family_message_report_evidence
  from public, anon, authenticated;
grant select, insert, update, delete on public.family_message_report_evidence
  to service_role;

create or replace function public.zyra_capture_family_message_report_evidence()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.family_message_report_evidence (
    report_id, thread_id, message_id, reported_sender_id, reason,
    reported_body, immediate_context, reported_at
  )
  select
    new.id,
    new.thread_id,
    new.message_id,
    message.sender_id,
    new.reason,
    message.body,
    coalesce((
      select jsonb_agg(jsonb_build_object(
        'message_id', context_message.id,
        'sender_id', context_message.sender_id,
        'body', context_message.body,
        'created_at', context_message.created_at
      ) order by context_message.created_at, context_message.id)
      from (
        select candidate.*
        from public.family_messages candidate
        where candidate.thread_id = new.thread_id
          and candidate.created_at between
            message.created_at - interval '10 minutes'
            and message.created_at + interval '10 minutes'
        order by abs(extract(epoch from (candidate.created_at - message.created_at))),
                 candidate.id
        limit 11
      ) context_message
    ), '[]'::jsonb),
    new.created_at
  from public.family_messages message
  where message.id = new.message_id;
  return new;
end;
$$;

revoke all on function public.zyra_capture_family_message_report_evidence()
  from public, anon, authenticated;

drop trigger if exists family_message_report_capture_evidence
  on public.family_message_reports;
create trigger family_message_report_capture_evidence
after insert on public.family_message_reports
for each row execute function public.zyra_capture_family_message_report_evidence();

create or replace function public.zyra_mark_family_message_sender_deleted()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  update public.family_messages
  set sender_deleted_at = coalesce(sender_deleted_at, now())
  where sender_id = old.id;
  return old;
end;
$$;
revoke all on function public.zyra_mark_family_message_sender_deleted()
  from public, anon, authenticated;

drop trigger if exists profiles_mark_family_message_sender_deleted
  on public.profiles;
create trigger profiles_mark_family_message_sender_deleted
before delete on public.profiles
for each row execute function public.zyra_mark_family_message_sender_deleted();

create or replace function public.zyra_close_family_message_report(
  p_report_id uuid,
  p_legal_hold boolean default false
)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'moderation_authority_required';
  end if;
  update public.family_message_report_evidence evidence
  set closed_at = now(),
      legal_hold = p_legal_hold,
      retain_until = case when p_legal_hold then null
        else now() + interval '24 months' end
  where evidence.report_id = p_report_id;
  if not found then raise exception 'report_evidence_not_found'; end if;
  update public.family_message_reports report
  set status = 'actioned', reviewed_at = now()
  where report.id = p_report_id;
end;
$$;
revoke all on function public.zyra_close_family_message_report(uuid,boolean)
  from public, anon, authenticated;
grant execute on function public.zyra_close_family_message_report(uuid,boolean)
  to service_role;

create or replace function public.zyra_purge_expired_family_message_data()
returns table(deleted_messages bigint, deleted_evidence bigint)
language plpgsql security definer set search_path = ''
as $$
declare
  v_messages bigint;
  v_evidence bigint;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'service_role_required';
  end if;
  delete from public.family_messages message
  where message.sender_id is null
    and message.sender_deleted_at <= now() - interval '12 months'
    and not exists (
      select 1 from public.family_message_report_evidence evidence
      where evidence.message_id = message.id
        and (evidence.legal_hold or evidence.retain_until > now())
    );
  get diagnostics v_messages = row_count;

  delete from public.family_message_report_evidence evidence
  where not evidence.legal_hold
    and evidence.closed_at is not null
    and evidence.retain_until <= now();
  get diagnostics v_evidence = row_count;

  return query select v_messages, v_evidence;
end;
$$;
revoke all on function public.zyra_purge_expired_family_message_data()
  from public, anon, authenticated;
grant execute on function public.zyra_purge_expired_family_message_data()
  to service_role;

-- Membership expiry never hides a person's own safety-case status. This
-- projection is caller-scoped, contains no reported-person identity, and is
-- intentionally independent of zyra_has_paid_role().
create or replace function public.zyra_my_safety_cases()
returns table (
  case_id uuid,
  case_type text,
  status text,
  created_at timestamptz,
  updated_at timestamptz
)
language sql stable security definer set search_path = ''
as $$
  select report.id, 'profile'::text, report.status,
         report.created_at, report.reviewed_at
  from public.profile_reports report
  where report.reporter_id = (select auth.uid())
  union all
  select report.id, 'guardian_circle'::text, report.status,
         report.created_at, report.reviewed_at
  from public.family_message_reports report
  where report.reporter_id = (select auth.uid())
  order by created_at desc, case_id desc;
$$;
revoke all on function public.zyra_my_safety_cases()
  from public, anon;
grant execute on function public.zyra_my_safety_cases()
  to authenticated;

comment on table public.family_message_report_evidence is
  'Protected moderation evidence: reported message plus bounded immediate '
  'context. Service-role only. Retained 24 months after case closure unless '
  'an active legal/safety hold requires longer.';
