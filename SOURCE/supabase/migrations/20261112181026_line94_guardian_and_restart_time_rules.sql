-- ZYRA line 94 / DOC-ZYRA-0473 / OA-ZYRA-317.
-- Local replay candidate. Production requires a separate Founder GO.

begin;

-- Stored deadlines are authoritative for invitations already created.
alter table public.wali_invites
  alter column expires_at set default (now() + interval '14 days');

comment on column public.wali_invites.request_expires_at is
  'Stored deadline for an addressed personal-code request. New code requests use 14 days.';
comment on function public.zyra_expire_due_wali_invites() is
  'Expire invitations and personal-code requests using each stored deadline; warn within two days.';

create or replace function public.zyra_request_guardian_link(
  p_code text,
  p_relationship text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := auth.uid();
  v_code text := private.zyra_normalize_personal_code(p_code);
  v_my_role text;
  v_owner uuid;
  v_owner_role text;
  v_code_id uuid;
  v_request_id uuid;
  v_my_name text;
  v_preview_role text;
  v_created_at timestamptz;
  v_deadline timestamptz;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;
  if p_relationship is not null and p_relationship not in (
    'father','brother','grandfather','uncle','legal_guardian',
    'family_representative','other'
  ) then raise exception 'unknown_relationship'; end if;

  -- The mutation cannot bypass preview's authentication, neutral filtering or
  -- rate limit by calling this RPC directly.
  select preview.owner_role into v_preview_role
  from public.zyra_preview_personal_code(p_code) preview;
  if v_preview_role is null then return null; end if;

  select p.role, p.first_name into v_my_role, v_my_name
  from public.profiles p where p.id = v_me;
  select c.id, c.owner_id, c.role_context
    into v_code_id, v_owner, v_owner_role
  from private.zyra_personal_codes c
  join public.profiles owner_profile
    on owner_profile.id = c.owner_id and owner_profile.role = c.role_context
  where c.code = v_code;

  if v_owner is null or v_owner = v_me or v_my_role not in ('seeker','wali')
     or v_owner_role = v_my_role
     or public.zyra_block_exists(v_owner)
     or not public.zyra_can_guardian_link(v_me, v_owner) then
    raise exception 'code_unavailable';
  end if;
  if v_my_role = 'wali' and p_relationship is null then
    raise exception 'relationship_required';
  end if;
  if v_my_role = 'seeker' and p_relationship is not null then
    raise exception 'relationship_owned_by_guardian';
  end if;
  if exists (
    select 1 from public.wali_links wl
    where ((wl.seeker_id = v_me and wl.wali_id = v_owner)
        or (wl.seeker_id = v_owner and wl.wali_id = v_me))
      and wl.status = 'active'
  ) then raise exception 'already_linked'; end if;

  update public.wali_invites wi
     set status = 'expired'
   where wi.source = 'personal_code'
     and wi.personal_code_id = v_code_id
     and wi.recipient_id = v_me
     and wi.status = 'pending'
     and wi.request_expires_at <= clock_timestamp();

  v_created_at := clock_timestamp();
  v_deadline := v_created_at + interval '14 days';
  insert into public.wali_invites(
    token, inviter_id, inviter_role, status, relationship, source,
    personal_code_id, recipient_id, created_at, expires_at, request_expires_at
  ) values (
    'REQ-' || upper(encode(extensions.gen_random_bytes(12), 'hex')),
    v_owner, v_owner_role, 'pending',
    case when v_my_role = 'wali' then p_relationship else null end,
    'personal_code', v_code_id, v_me,
    v_created_at, v_deadline, v_deadline
  )
  returning id into v_request_id;

  perform public.create_notification(
    v_owner, 'wali_request', 'Guardian request',
    coalesce(v_my_name, 'Someone') || ' sent you a Guardian request.', null
  );
  return v_request_id;
exception
  when unique_violation then raise exception 'request_already_pending';
end;
$function$;

comment on function public.zyra_request_guardian_link(text, text) is
  'Creates a 14-day two-sided request against a permanent ZYRA Code. Owner acceptance is mandatory.';

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
  select * into v_match from public.matches
  where id = p_match_id and seeker_a_id is not null and seeker_b_id is not null
  for update;
  if not found then raise exception 'match_not_found'; end if;
  if v_caller is distinct from v_match.seeker_a_id
     and v_caller is distinct from v_match.seeker_b_id then
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
  if public.zyra_active_journey_cap(v_other) = 0 then
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
  if not found or v_match.seeker_a_id is null or v_match.seeker_b_id is null
     or v_caller not in (v_match.seeker_a_id, v_match.seeker_b_id) then
    return false;
  end if;
  v_other := case when v_caller = v_match.seeker_a_id
    then v_match.seeker_b_id else v_match.seeker_a_id end;
  return v_match.status = 'ended'
    and v_match.ended_at is not null
    and now() >= v_match.ended_at + interval '24 hours'
    and public.zyra_has_paid_role(v_caller, 'seeker')
    and public.zyra_active_journey_cap(v_other) > 0
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
    and public.zyra_active_journey_count(v_match.seeker_a_id, v_match.id)
      < public.zyra_active_journey_cap(v_match.seeker_a_id)
    and public.zyra_active_journey_count(v_match.seeker_b_id, v_match.id)
      < public.zyra_active_journey_cap(v_match.seeker_b_id);
end;
$$;

-- Q120 exposes the existing caller-scoped availability check. Restart
-- mutations and the internal batch entry point keep their existing ACLs.
grant execute on function public.zyra_may_request_new_journey(uuid) to authenticated;

create or replace function public.zyra_guard_ended_restart_initiation()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_caller uuid := (select auth.uid());
begin
  if v_caller is null then return new; end if;
  if new.requested_by is distinct from v_caller
     or not public.zyra_may_request_new_journey(new.match_id)
     or not exists (select 1 from public.matches m where m.id = new.match_id
       and new.requested_to = case when m.seeker_a_id=v_caller then m.seeker_b_id else m.seeker_a_id end)
  then raise exception 'restart_not_available'; end if;
  if new.expires_at is distinct from now() + interval '30 days' then
    raise exception 'restart_expiry_must_be_thirty_days';
  end if;
  return new;
end;
$$;

update public.subscriptions
set billing_grace_until = billing_grace_started_at + interval '3 days'
where billing_grace_until > billing_grace_started_at + interval '3 days';

alter table public.subscriptions
  drop constraint subscriptions_billing_grace_maximum,
  add constraint subscriptions_billing_grace_maximum check (
    (billing_grace_started_at is null and billing_grace_until is null)
    or (
      billing_grace_started_at is not null
      and billing_grace_until is not null
      and billing_grace_until > billing_grace_started_at
      and billing_grace_until <= billing_grace_started_at + interval '3 days'
    )
  );

update public.family_subscriptions
set billing_grace_until = billing_grace_started_at + interval '3 days'
where billing_grace_until > billing_grace_started_at + interval '3 days';

alter table public.family_subscriptions
  drop constraint family_subscriptions_billing_grace_maximum,
  add constraint family_subscriptions_billing_grace_maximum check (
    (billing_grace_started_at is null and billing_grace_until is null)
    or (
      billing_grace_started_at is not null
      and billing_grace_until is not null
      and billing_grace_until > billing_grace_started_at
      and billing_grace_until <= billing_grace_started_at + interval '3 days'
    )
  );

-- The person remains in the ledger after the claiming account is removed.
create table private.guardian_trial_ledger (
  verified_person_id uuid primary key
    references private.verified_people(id) on delete restrict,
  claimed_by uuid references auth.users(id) on delete set null,
  started_at timestamptz,
  ends_at timestamptz,
  constraint guardian_trial_duration check (
    (claimed_by is null and started_at is null and ends_at is null)
    or (claimed_by is not null and started_at is not null and ends_at is not null and ends_at = started_at + interval '14 days')
  )
);

create function private.zyra_clear_deleted_guardian_trial()
returns trigger language plpgsql set search_path = ''
as $$
begin
  if new.claimed_by is null then
    new.started_at := null;
    new.ends_at := null;
  end if;
  return new;
end;
$$;
revoke all on function private.zyra_clear_deleted_guardian_trial()
  from public, anon, authenticated, service_role;
create trigger guardian_trial_clear_deleted_account
before update of claimed_by on private.guardian_trial_ledger
for each row execute function private.zyra_clear_deleted_guardian_trial();

alter table private.guardian_trial_ledger enable row level security;
revoke all on private.guardian_trial_ledger from public, anon, authenticated, service_role;
grant select, insert on private.guardian_trial_ledger to service_role;

create function public.zyra_start_verified_guardian_trial(
  p_user uuid,
  p_verified_person uuid
)
returns timestamptz
language plpgsql security invoker set search_path = ''
as $$
declare
  v_started_at timestamptz := now();
  v_ends_at timestamptz;
begin
  if not exists (
    select 1
    from private.verified_person_accounts binding
    join public.profiles profile on profile.id = binding.user_id
    where binding.verified_person_id = p_verified_person
      and binding.user_id = p_user
      and binding.role = 'guardian'
      and profile.role = 'wali'
  ) then
    raise exception 'verified_guardian_binding_required';
  end if;

  insert into private.guardian_trial_ledger (
    verified_person_id, claimed_by, started_at, ends_at
  )
  values (p_verified_person, p_user, v_started_at, v_started_at + interval '14 days')
  on conflict (verified_person_id) do nothing
  returning ends_at into v_ends_at;

  if not found then
    raise exception 'guardian_trial_already_used';
  end if;
  return v_ends_at;
end;
$$;

revoke all on function public.zyra_start_verified_guardian_trial(uuid, uuid)
  from public, anon, authenticated, service_role;
grant execute on function public.zyra_start_verified_guardian_trial(uuid, uuid)
  to service_role;

commit;
