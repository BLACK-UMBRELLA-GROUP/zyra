-- SERVER 0 V2 / DOC-ZYRA-0329 / OA-ZYRA-317 / OA-ZYRA-319.
-- Local proof only; production requires a separate exact-payload Founder GO.

begin;

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

    -- Expiry is not a decline: no decline cooldown is created.

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
      and public.zyra_active_journey_cap(request.requested_to) = 0
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
    p_match_id, v_caller, v_other, now() + interval '7 days'
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

  if public.zyra_active_journey_cap(v_caller) = 0 then
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
  if not found or v_match.status <> 'ended' then
    raise exception 'journey_not_ended';
  end if;

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
     or not public.zyra_can_match(v_caller, v_request.requested_by)
     or public.zyra_hold_blocks(v_caller, v_request.requested_by) then
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
    'salam_exchange',
    now()
  ) returning id into v_attempt;

  -- matches is the permanent pair envelope. The prior Journey remains an
  -- immutable ended journey_attempt; this update projects only the new current
  -- attempt so legacy list code can find it.
  update public.matches
  set status = 'active',
      journey_stage = 'salam_exchange',
      ended_at = null,
      ended_by = null,
      end_reason = null,
      end_note = null
  where id = v_request.match_id;

  insert into public.conversations(match_id, attempt_id, status)
  values (v_request.match_id, v_attempt, 'active');
  insert into public.timelines(match_id, attempt_id)
  values (v_request.match_id, v_attempt)
  on conflict (attempt_id) do nothing;

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


-- Public availability is only a privacy-preserving marker. Writes remain revoked.
create or replace function public.zyra_journey_return_available(p_match_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select public.zyra_may_request_new_journey(p_match_id);
$$;
revoke all on function public.zyra_journey_return_available(uuid) from public, anon;
grant execute on function public.zyra_journey_return_available(uuid) to authenticated;
create or replace function public.zyra_available_journey_return_ids()
returns setof uuid language sql stable security definer set search_path = '' as $$
  select * from public.zyra_may_request_new_journey_ids();
$$;
revoke all on function public.zyra_available_journey_return_ids() from public, anon;
grant execute on function public.zyra_available_journey_return_ids() to authenticated;

create function public.zyra_guard_ended_restart_initiation()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_caller uuid := (select auth.uid());
begin
  if v_caller is null then return new; end if;
  if new.requested_by is distinct from v_caller
     or not public.zyra_may_request_new_journey(new.match_id)
     or not exists (select 1 from public.matches m where m.id = new.match_id
       and new.requested_to = case when m.seeker_a_id=v_caller then m.seeker_b_id else m.seeker_a_id end)
  then raise exception 'restart_not_available'; end if;
  if new.expires_at is distinct from now() + interval '7 days' then
    raise exception 'restart_expiry_must_be_seven_days';
  end if;
  return new;
end;
$$;
revoke all on function public.zyra_guard_ended_restart_initiation() from public, anon, authenticated;
create trigger journey_requests_ended_restart_gate before insert on public.journey_requests
for each row when (new.status = 'pending') execute function public.zyra_guard_ended_restart_initiation();

commit;
