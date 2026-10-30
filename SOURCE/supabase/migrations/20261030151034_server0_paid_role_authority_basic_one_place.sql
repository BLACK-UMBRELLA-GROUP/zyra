-- SERVER 0 V2 / DOC-ZYRA-0329 / OA-ZYRA-317 / OA-ZYRA-319.
-- Local proof only; production requires a separate exact-payload Founder GO.

begin;

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
  select case
    when public.zyra_has_paid_role(p_user, 'seeker') then 3
    when exists (
      select 1 from public.subscriptions s
      where s.user_id = p_user and s.plan_type = 'seeker_basic'
        and s.status = 'active'
        and (s.expires_at is null or s.expires_at > now())
    ) then 1
    else 0 end;
$$;
revoke all on function public.zyra_active_journey_cap(uuid)
  from public, anon, authenticated;

commit;
