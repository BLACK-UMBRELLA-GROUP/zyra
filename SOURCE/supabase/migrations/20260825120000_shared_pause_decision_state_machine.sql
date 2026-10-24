-- SHARED PAUSE DECISION STATE MACHINE — Founder brief, 2026-08-25
--
-- REPOSITORY MIGRATION ONLY. Do not apply without explicit Founder approval.
-- Supersedes DR-ZYRA-170's asymmetric personal-hold implementation.
--
-- State:
--   none               active and unlocked
--   pause_requested    active-slot counted, locked, other Seeker decides
--   continue_requested active-slot counted, locked, original requester decides
--   paused             mutually settled, paused-slot counted
--   resume_requested   paused-slot counted, locked, other Seeker decides
--
-- The nullable deadline is deliberate. No duration or expiry outcome has
-- been ratified. zyra_pause_decision_window() is the one configurable source;
-- it returns NULL until the Founder decides the duration and expiry behaviour.

alter table public.matches
  add column if not exists pause_state text not null default 'none',
  add column if not exists pause_initiated_by uuid,
  add column if not exists pause_requested_by uuid,
  add column if not exists pause_requested_at timestamptz,
  add column if not exists pause_deadline_at timestamptz,
  add column if not exists pause_version bigint not null default 0,
  add column if not exists pause_attempt_id uuid;

alter table public.journey_attempts
  add column if not exists pause_state text not null default 'none',
  add column if not exists pause_initiated_by uuid,
  add column if not exists pause_requested_by uuid,
  add column if not exists pause_requested_at timestamptz,
  add column if not exists pause_deadline_at timestamptz,
  add column if not exists pause_version bigint not null default 0;

-- Refuse a lossy legacy conversion. Every active personal hold must belong to
-- the active Journey attempt before it can become the shared mutually-Paused
-- state. Repair the named rows first, then re-run this migration.
do $preflight$
declare
  affected_ids text;
begin
  select string_agg(m.id::text, ', ' order by m.id::text)
    into affected_ids
    from public.matches m
    where m.status = 'active'
      and m.suspended_by is not null
      and not exists (
        select 1
        from public.journey_attempts ja
        where ja.match_id = m.id and ja.status = 'active'
      );
  if affected_ids is not null then
    raise exception
      'pause_migration_preflight_failed: active legacy pause has no active Journey attempt: %',
      affected_ids;
  end if;
end;
$preflight$;

alter table public.matches
  drop constraint if exists matches_pause_state_check;
alter table public.matches
  add constraint matches_pause_state_check check (
    pause_state in (
      'none', 'pause_requested', 'continue_requested', 'paused',
      'resume_requested'
    )
  );
alter table public.matches
  drop constraint if exists matches_pause_request_shape;
alter table public.matches
  add constraint matches_pause_request_shape check (
    (pause_state = 'none'
      and pause_initiated_by is null
      and pause_requested_by is null
      and pause_requested_at is null
      and pause_deadline_at is null
      and pause_attempt_id is null)
    or
    (pause_state in ('pause_requested', 'continue_requested', 'resume_requested')
      and pause_initiated_by is not null
      and pause_requested_by is not null
      and pause_requested_at is not null
      and pause_attempt_id is not null)
    or
    (pause_state = 'paused'
      and pause_initiated_by is not null
      and pause_requested_by is null
      and pause_requested_at is null
      and pause_deadline_at is null
      and pause_attempt_id is not null)
  );
alter table public.matches
  drop constraint if exists matches_pause_attempt_fk;
alter table public.matches
  add constraint matches_pause_attempt_fk
  foreign key (pause_attempt_id) references public.journey_attempts(id);

alter table public.journey_attempts
  drop constraint if exists journey_attempts_pause_state_check;
alter table public.journey_attempts
  add constraint journey_attempts_pause_state_check check (
    pause_state in (
      'none', 'pause_requested', 'continue_requested', 'paused',
      'resume_requested'
    )
  );
alter table public.journey_attempts
  drop constraint if exists journey_attempts_pause_request_shape;
alter table public.journey_attempts
  add constraint journey_attempts_pause_request_shape check (
    (pause_state = 'none'
      and pause_initiated_by is null
      and pause_requested_by is null
      and pause_requested_at is null
      and pause_deadline_at is null)
    or
    (pause_state in ('pause_requested', 'continue_requested', 'resume_requested')
      and pause_initiated_by is not null
      and pause_requested_by is not null
      and pause_requested_at is not null)
    or
    (pause_state = 'paused'
      and pause_initiated_by is not null
      and pause_requested_by is null
      and pause_requested_at is null
      and pause_deadline_at is null)
  );

-- Existing old-model pauses become neutral, mutually Paused Journeys. The
-- original actor is retained only as internal audit metadata; UI never uses it.
update public.matches m
set pause_state = 'paused',
    pause_initiated_by = m.suspended_by,
    pause_requested_by = null,
    pause_requested_at = null,
    pause_deadline_at = null,
    pause_version = greatest(m.pause_version, 1),
    pause_attempt_id = (
      select ja.id
      from public.journey_attempts ja
      where ja.match_id = m.id and ja.status = 'active'
      order by ja.attempt_number desc
      limit 1
    ),
    also_paused_by = null,
    also_paused_at = null,
    pause_nudged_at = null
where m.status = 'active' and m.suspended_by is not null;

update public.journey_attempts a
set pause_state = m.pause_state,
    pause_initiated_by = m.pause_initiated_by,
    pause_requested_by = m.pause_requested_by,
    pause_requested_at = m.pause_requested_at,
    pause_deadline_at = m.pause_deadline_at,
    pause_version = m.pause_version,
    also_paused_by = null,
    also_paused_at = null
from public.matches m
where a.id = m.pause_attempt_id;

create or replace function public.zyra_pause_decision_window()
returns interval
language sql
stable
set search_path = ''
as $function$
  select null::interval;
$function$;

comment on function public.zyra_pause_decision_window() is
  'Single configurable Pause response window. NULL until Founder ratifies duration and expiry behaviour.';
revoke all on function public.zyra_pause_decision_window()
  from public, anon, authenticated;

create or replace function public.zyra_paused_journey_cap(p_user uuid)
returns integer
language sql
stable
security definer
set search_path = 'public'
as $function$
  select case when exists (
    select 1 from public.subscriptions
    where user_id = p_user
      and plan_type = 'seeker_premium'
      and status = 'active'
  ) then 10 else 5 end;
$function$;

create or replace function public.zyra_paused_journey_count(
  p_user uuid,
  p_exclude uuid default null
)
returns integer
language sql
stable
security definer
set search_path = 'public'
as $function$
  select count(*)::integer
  from public.matches
  where status = 'active'
    and pause_state in ('paused', 'resume_requested')
    and (seeker_a_id = p_user or seeker_b_id = p_user)
    and (p_exclude is null or id <> p_exclude);
$function$;

create or replace function public.zyra_pause_capacity_status(p_match_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = 'public'
as $function$
declare
  m public.matches%rowtype;
  caller uuid := (select auth.uid());
begin
  if caller is null then raise exception 'not_signed_in'; end if;
  select * into m from public.matches where id = p_match_id;
  if not found or caller not in (m.seeker_a_id, m.seeker_b_id) then
    raise exception 'not_a_party';
  end if;
  return jsonb_build_object(
    'can_pause',
      public.zyra_paused_journey_count(m.seeker_a_id, m.id)
        < public.zyra_paused_journey_cap(m.seeker_a_id)
      and
      public.zyra_paused_journey_count(m.seeker_b_id, m.id)
        < public.zyra_paused_journey_cap(m.seeker_b_id)
  );
end;
$function$;

-- Seeker-only detail projection. Guardian match visibility remains neutral:
-- pause_state is selectable, but the actor ids never leave this party check.
create or replace function public.zyra_my_pause_states(p_match_ids uuid[])
returns table (
  match_id uuid,
  pause_state text,
  pause_initiated_by uuid,
  pause_requested_by uuid,
  pause_requested_at timestamptz,
  pause_deadline_at timestamptz,
  pause_version bigint
)
language sql
stable
security definer
set search_path='public'
as $function$
  select m.id, m.pause_state, m.pause_initiated_by, m.pause_requested_by,
         m.pause_requested_at, m.pause_deadline_at, m.pause_version
  from public.matches m
  where m.id = any(p_match_ids)
    and (m.seeker_a_id = (select auth.uid())
      or m.seeker_b_id = (select auth.uid()));
$function$;

-- One neutral notification asks for a decision; one reports an answer. The
-- lock-screen copy does not expose a counterpart, stage or private reason.
alter table public.notifications
  drop constraint if exists notifications_type_check;
alter table public.notifications
  add constraint notifications_type_check check (type = any (array[
    'new_match'::text, 'new_message'::text, 'wali_request'::text,
    'journey_ended'::text, 'journey_request'::text,
    'journey_request_accepted'::text, 'journey_request_declined'::text,
    'milestone_proposed'::text, 'milestone_confirmed'::text,
    'pause_nudge'::text, 'journey_paused'::text,
    'journey_also_paused'::text, 'journey_continued'::text,
    'wali_invite_received'::text, 'wali_invite_declined'::text,
    'wali_invite_expiring'::text, 'wali_invite_expired'::text,
    'wali_invite_revoked'::text,
    'journey_decision_needed'::text, 'journey_decision_answered'::text
  ]));

update public.notifications
set title = 'Journey update',
    body = 'Your Journey status has changed. Open ZYRA for details.'
where read_at is null
  and type in ('pause_nudge', 'journey_paused', 'journey_also_paused');

-- Keep the single notification-consent gate complete. Unknown types fail
-- closed in create_notification(), so the two new decision types must be
-- assigned to the existing Matches & Journeys preference here.
create or replace function public.zyra_notification_category(p_type text)
returns text
language plpgsql
immutable
set search_path to 'public'
as $function$
declare
  v_category text;
begin
  if p_type in ('new_device_signin', 'password_changed', 'account_action') then
    return null;
  end if;

  v_category := case p_type
    when 'new_match' then 'matches_journeys'
    when 'new_message' then 'matches_journeys'
    when 'journey_ended' then 'matches_journeys'
    when 'journey_request' then 'matches_journeys'
    when 'journey_request_accepted' then 'matches_journeys'
    when 'journey_request_declined' then 'matches_journeys'
    when 'milestone_proposed' then 'matches_journeys'
    when 'milestone_confirmed' then 'matches_journeys'
    when 'pause_nudge' then 'matches_journeys'
    when 'journey_paused' then 'matches_journeys'
    when 'journey_also_paused' then 'matches_journeys'
    when 'journey_continued' then 'matches_journeys'
    when 'journey_decision_needed' then 'matches_journeys'
    when 'journey_decision_answered' then 'matches_journeys'

    when 'wali_request' then 'guardian_activity'
    when 'wali_invite_received' then 'guardian_activity'
    when 'wali_invite_declined' then 'guardian_activity'
    when 'wali_invite_expiring' then 'guardian_activity'
    when 'wali_invite_expired' then 'guardian_activity'
    when 'wali_invite_revoked' then 'guardian_activity'
    when 'family_review_opened' then 'guardian_activity'
    when 'family_review_due' then 'guardian_activity'
    when 'guardian_digest' then 'guardian_activity'

    when 'introduction_received' then 'introductions'
    when 'introduction_answered' then 'introductions'
    when 'entitlement_changed' then 'product_updates'
    when 'credits_low' then 'product_updates'
    else null
  end;

  if v_category is null then
    raise exception 'unknown_notification_type: %', p_type
      using errcode = '22023';
  end if;
  return v_category;
end;
$function$;

-- Every decision is a compare-and-swap under one locked match row and one
-- locked active-attempt row. The function is the only writer of pause_state.
create or replace function public.transition_journey_pause(
  p_match_id uuid,
  p_action text,
  p_expected_version bigint
)
returns jsonb
language plpgsql
security definer
set search_path = 'public'
as $function$
declare
  m public.matches%rowtype;
  a public.journey_attempts%rowtype;
  caller uuid := (select auth.uid());
  other_id uuid;
  window_length interval;
  next_deadline timestamptz;
begin
  if caller is null then raise exception 'not_signed_in'; end if;
  if p_action not in (
    'request_pause', 'agree_pause', 'request_continue', 'continue_journey',
    'confirm_pause', 'request_resume', 'agree_resume', 'keep_paused'
  ) then
    raise exception 'unknown_pause_action';
  end if;

  select * into m
  from public.matches
  where id = p_match_id
  for update;
  if not found then raise exception 'match_not_found'; end if;
  if caller not in (m.seeker_a_id, m.seeker_b_id) then
    raise exception 'not_a_party';
  end if;
  if m.status <> 'active' then raise exception 'journey_not_active'; end if;
  if m.pause_version <> p_expected_version then
    raise exception 'stale_pause_decision';
  end if;

  other_id := case when caller = m.seeker_a_id
    then m.seeker_b_id else m.seeker_a_id end;

  -- Match-row locking serialises competing answers on this Journey. These
  -- participant locks additionally serialise capacity changes across two
  -- different Journeys involving either account, preventing two concurrent
  -- confirmations from both observing the final Paused slot as available.
  -- The keys and stable order match the existing Active-cap triggers.
  perform pg_advisory_xact_lock(
    hashtextextended(least(m.seeker_a_id, m.seeker_b_id)::text, 0)
  );
  perform pg_advisory_xact_lock(
    hashtextextended(greatest(m.seeker_a_id, m.seeker_b_id)::text, 0)
  );

  select * into a
  from public.journey_attempts
  where match_id = p_match_id and status = 'active'
  order by attempt_number desc
  limit 1
  for update;
  if not found then raise exception 'active_attempt_not_found'; end if;
  if m.pause_attempt_id is not null and m.pause_attempt_id <> a.id then
    raise exception 'stale_pause_attempt';
  end if;

  -- Every transition rechecks eligibility and account availability. Ending is
  -- deliberately outside this RPC and remains available through end_journey.
  if not public.zyra_can_continue_journey(m.seeker_a_id, m.seeker_b_id) then
    raise exception 'not_eligible_to_continue';
  end if;
  if not coalesce((select is_active from public.profiles where id=m.seeker_a_id), false)
     or not coalesce((select is_active from public.profiles where id=m.seeker_b_id), false) then
    raise exception 'journey_party_unavailable';
  end if;

  window_length := public.zyra_pause_decision_window();
  next_deadline := case when window_length is null
    then null else now() + window_length end;
  if p_action = 'request_pause' then
    if m.pause_state <> 'none' then raise exception 'pause_transition_not_allowed'; end if;
    update public.matches set
      pause_state='pause_requested', pause_initiated_by=caller,
      pause_requested_by=caller, pause_requested_at=now(),
      pause_deadline_at=next_deadline, pause_version=pause_version+1,
      pause_attempt_id=a.id
    where id=p_match_id;
    update public.journey_attempts set
      pause_state='pause_requested', pause_initiated_by=caller,
      pause_requested_by=caller, pause_requested_at=now(),
      pause_deadline_at=next_deadline, pause_version=pause_version+1
    where id=a.id;
    update public.conversations set status='paused'
      where attempt_id=a.id and status='active';
    perform public.create_notification(
      other_id, 'journey_decision_needed', 'A Journey needs your decision',
      'Open ZYRA when you are ready to respond.', p_match_id);

  elsif p_action in ('agree_pause','request_continue') then
    if m.pause_state <> 'pause_requested' or m.pause_requested_by <> other_id then
      raise exception 'pause_transition_not_allowed';
    end if;
    if p_action = 'agree_pause' then
      if public.zyra_paused_journey_count(m.seeker_a_id, m.id)
           >= public.zyra_paused_journey_cap(m.seeker_a_id)
         or public.zyra_paused_journey_count(m.seeker_b_id, m.id)
           >= public.zyra_paused_journey_cap(m.seeker_b_id) then
        raise exception 'paused_capacity_conflict';
      end if;
      update public.matches set
        pause_state='paused', pause_requested_by=null,
        pause_requested_at=null, pause_deadline_at=null,
        pause_version=pause_version+1,
        suspended_by=pause_initiated_by, suspended_at=now(),
        also_paused_by=null, also_paused_at=null, pause_nudged_at=null
      where id=p_match_id;
      update public.journey_attempts set
        pause_state='paused', pause_requested_by=null,
        pause_requested_at=null, pause_deadline_at=null,
        pause_version=pause_version+1,
        paused_by=pause_initiated_by, paused_at=now(),
        also_paused_by=null, also_paused_at=null
      where id=a.id;
      perform public.create_notification(
        other_id, 'journey_decision_answered',
        'Your pause request has been answered',
        'Open ZYRA to see the current Journey state.', p_match_id);
    else
      update public.matches set
        pause_state='continue_requested', pause_requested_by=caller,
        pause_requested_at=now(), pause_deadline_at=next_deadline,
        pause_version=pause_version+1
      where id=p_match_id;
      update public.journey_attempts set
        pause_state='continue_requested', pause_requested_by=caller,
        pause_requested_at=now(), pause_deadline_at=next_deadline,
        pause_version=pause_version+1
      where id=a.id;
      perform public.create_notification(
        other_id, 'journey_decision_needed', 'A Journey needs your decision',
        'Open ZYRA when you are ready to respond.', p_match_id);
    end if;

  elsif p_action in ('continue_journey','confirm_pause') then
    if m.pause_state <> 'continue_requested' or m.pause_requested_by <> other_id
       or caller <> m.pause_initiated_by then
      raise exception 'pause_transition_not_allowed';
    end if;
    if p_action = 'confirm_pause' then
      if public.zyra_paused_journey_count(m.seeker_a_id, m.id)
           >= public.zyra_paused_journey_cap(m.seeker_a_id)
         or public.zyra_paused_journey_count(m.seeker_b_id, m.id)
           >= public.zyra_paused_journey_cap(m.seeker_b_id) then
        raise exception 'paused_capacity_conflict';
      end if;
      update public.matches set
        pause_state='paused', pause_requested_by=null,
        pause_requested_at=null, pause_deadline_at=null,
        pause_version=pause_version+1,
        suspended_by=pause_initiated_by, suspended_at=now(),
        also_paused_by=null, also_paused_at=null, pause_nudged_at=null
      where id=p_match_id;
      update public.journey_attempts set
        pause_state='paused', pause_requested_by=null,
        pause_requested_at=null, pause_deadline_at=null,
        pause_version=pause_version+1,
        paused_by=pause_initiated_by, paused_at=now(),
        also_paused_by=null, also_paused_at=null
      where id=a.id;
    else
      update public.matches set
        pause_state='none', pause_initiated_by=null,
        pause_requested_by=null, pause_requested_at=null,
        pause_deadline_at=null, pause_version=pause_version+1,
        pause_attempt_id=null
      where id=p_match_id;
      update public.journey_attempts set
        pause_state='none', pause_initiated_by=null,
        pause_requested_by=null, pause_requested_at=null,
        pause_deadline_at=null, pause_version=pause_version+1
      where id=a.id;
      update public.conversations set status='active'
        where attempt_id=a.id and status='paused';
    end if;
    perform public.create_notification(
      other_id, 'journey_decision_answered',
      'Your continuation request has been answered',
      'Open ZYRA to see the current Journey state.', p_match_id);

  elsif p_action = 'request_resume' then
    if m.pause_state <> 'paused' then raise exception 'pause_transition_not_allowed'; end if;
    update public.matches set
      pause_state='resume_requested', pause_requested_by=caller,
      pause_requested_at=now(), pause_deadline_at=next_deadline,
      pause_version=pause_version+1
    where id=p_match_id;
    update public.journey_attempts set
      pause_state='resume_requested', pause_requested_by=caller,
      pause_requested_at=now(), pause_deadline_at=next_deadline,
      pause_version=pause_version+1
    where id=a.id;
    perform public.create_notification(
      other_id, 'journey_decision_needed', 'A Journey needs your decision',
      'Open ZYRA when you are ready to respond.', p_match_id);

  elsif p_action in ('agree_resume','keep_paused') then
    if m.pause_state <> 'resume_requested' or m.pause_requested_by <> other_id then
      raise exception 'pause_transition_not_allowed';
    end if;
    if p_action = 'agree_resume' then
      if public.zyra_active_journey_count(m.seeker_a_id, m.id)
           >= public.zyra_active_journey_cap(m.seeker_a_id) then
        raise exception 'self_in_active_journey';
      end if;
      if public.zyra_active_journey_count(m.seeker_b_id, m.id)
           >= public.zyra_active_journey_cap(m.seeker_b_id) then
        raise exception 'other_party_in_active_journey';
      end if;
      update public.matches set
        pause_state='none', pause_initiated_by=null,
        pause_requested_by=null, pause_requested_at=null,
        pause_deadline_at=null, pause_version=pause_version+1,
        pause_attempt_id=null,
        suspended_by=null, suspended_at=null,
        also_paused_by=null, also_paused_at=null, pause_nudged_at=null
      where id=p_match_id;
      update public.journey_attempts set
        pause_state='none', pause_initiated_by=null,
        pause_requested_by=null, pause_requested_at=null,
        pause_deadline_at=null, pause_version=pause_version+1,
        paused_by=null, paused_at=null,
        also_paused_by=null, also_paused_at=null
      where id=a.id;
      update public.conversations set status='active'
        where attempt_id=a.id and status='paused';
    else
      update public.matches set
        pause_state='paused', pause_requested_by=null,
        pause_requested_at=null, pause_deadline_at=null,
        pause_version=pause_version+1
      where id=p_match_id;
      update public.journey_attempts set
        pause_state='paused', pause_requested_by=null,
        pause_requested_at=null, pause_deadline_at=null,
        pause_version=pause_version+1
      where id=a.id;
    end if;
    perform public.create_notification(
      other_id, 'journey_decision_answered',
      'Your resume request has been answered',
      'Open ZYRA to see the current Journey state.', p_match_id);
  end if;

  select * into m from public.matches where id=p_match_id;
  return jsonb_build_object(
    'pause_state', m.pause_state,
    'pause_initiated_by', m.pause_initiated_by,
    'pause_requested_by', m.pause_requested_by,
    'pause_requested_at', m.pause_requested_at,
    'pause_deadline_at', m.pause_deadline_at,
    'pause_version', m.pause_version
  );
end;
$function$;

revoke all on function public.transition_journey_pause(uuid,text,bigint)
  from public, anon;
grant execute on function public.transition_journey_pause(uuid,text,bigint)
  to authenticated;
revoke all on function public.zyra_pause_capacity_status(uuid)
  from public, anon;
grant execute on function public.zyra_pause_capacity_status(uuid)
  to authenticated;
revoke all on function public.zyra_my_pause_states(uuid[])
  from public, anon;
grant execute on function public.zyra_my_pause_states(uuid[])
  to authenticated;
revoke all on function public.zyra_paused_journey_cap(uuid)
  from public, anon;
revoke all on function public.zyra_paused_journey_count(uuid,uuid)
  from public, anon;

-- Direct writes stay closed by the existing table-level revokes. Repeat them
-- here so this migration remains self-defending if an intervening migration
-- widened a grant: only the SECURITY DEFINER transition/end functions write.
revoke insert, update, delete on public.matches from anon, authenticated;
revoke all on public.journey_attempts from anon, authenticated;

-- Stale clients cannot invoke the retired personal-hold behaviour.
create or replace function public.suspend_journey(p_match_id uuid)
returns void language plpgsql security definer set search_path='public'
as $function$ begin raise exception 'pause_flow_superseded'; end; $function$;
create or replace function public.resume_journey(p_match_id uuid)
returns void language plpgsql security definer set search_path='public'
as $function$ begin raise exception 'pause_flow_superseded'; end; $function$;
create or replace function public.nudge_paused_journey(p_match_id uuid)
returns void language plpgsql security definer set search_path='public'
as $function$ begin raise exception 'pause_flow_superseded'; end; $function$;
revoke all on function public.suspend_journey(uuid) from public, anon;
revoke all on function public.resume_journey(uuid) from public, anon;
revoke all on function public.nudge_paused_journey(uuid) from public, anon;
grant execute on function public.suspend_journey(uuid) to authenticated;
grant execute on function public.resume_journey(uuid) to authenticated;
grant execute on function public.nudge_paused_journey(uuid) to authenticated;

-- Defence in depth: stale screens and direct writes cannot advance stages,
-- submit answers, reveal compatibility or send messages while any Pause
-- decision or mutual Pause locks the Journey.
create or replace function public.zyra_reject_locked_match_progress()
returns trigger language plpgsql security definer set search_path='public'
as $function$
begin
  if (old.pause_state <> 'none' or new.pause_state <> 'none')
     and new.journey_stage is distinct from old.journey_stage then
    raise exception 'journey_pause_locked';
  end if;
  return new;
end;
$function$;

drop trigger if exists matches_reject_locked_progress on public.matches;
create trigger matches_reject_locked_progress
before update of journey_stage on public.matches
for each row execute function public.zyra_reject_locked_match_progress();

create or replace function public.zyra_reject_locked_attempt_progress()
returns trigger language plpgsql security definer set search_path='public'
as $function$
begin
  if new.journey_stage is distinct from old.journey_stage
     and exists (
       select 1 from public.matches m
       where m.id=new.match_id and m.pause_state <> 'none'
     ) then
    raise exception 'journey_pause_locked';
  end if;
  return new;
end;
$function$;

drop trigger if exists attempts_reject_locked_progress
on public.journey_attempts;
create trigger attempts_reject_locked_progress
before update of journey_stage on public.journey_attempts
for each row execute function public.zyra_reject_locked_attempt_progress();

create or replace function public.zyra_reject_locked_journey_write()
returns trigger language plpgsql security definer set search_path='public'
as $function$
declare v_match uuid;
begin
  if tg_argv[0] = 'message' then
    select c.match_id into v_match
    from public.conversations c
    where c.id = case when tg_op = 'DELETE'
      then old.conversation_id else new.conversation_id end;
  elsif tg_argv[0] = 'review_response' then
    select r.match_id into v_match
    from public.journey_family_reviews r
    where r.id = case when tg_op = 'DELETE'
      then old.review_id else new.review_id end;
  else
    v_match := case when tg_op = 'DELETE'
      then old.match_id else new.match_id end;
  end if;
  if exists (
    select 1 from public.matches m
    where m.id=v_match and m.pause_state <> 'none'
  ) then
    raise exception 'journey_pause_locked';
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end;
$function$;

drop trigger if exists journey_salams_pause_lock on public.journey_salams;
create trigger journey_salams_pause_lock before insert or update or delete
on public.journey_salams for each row
execute function public.zyra_reject_locked_journey_write('match');
drop trigger if exists journey_compatibility_pause_lock on public.journey_compatibility;
create trigger journey_compatibility_pause_lock before insert or update or delete
on public.journey_compatibility for each row
execute function public.zyra_reject_locked_journey_write('match');
drop trigger if exists journey_phase_answers_pause_lock on public.journey_phase_answers;
create trigger journey_phase_answers_pause_lock before insert or update or delete
on public.journey_phase_answers for each row
execute function public.zyra_reject_locked_journey_write('match');
drop trigger if exists journey_phase_ratings_pause_lock on public.journey_phase_ratings;
create trigger journey_phase_ratings_pause_lock before insert or update or delete
on public.journey_phase_ratings for each row
execute function public.zyra_reject_locked_journey_write('match');
drop trigger if exists journey_phase_checkpoints_pause_lock on public.journey_phase_checkpoints;
create trigger journey_phase_checkpoints_pause_lock before insert or update or delete
on public.journey_phase_checkpoints for each row
execute function public.zyra_reject_locked_journey_write('match');
drop trigger if exists journey_stage_checkpoints_pause_lock on public.journey_stage_checkpoints;
create trigger journey_stage_checkpoints_pause_lock before insert or update or delete
on public.journey_stage_checkpoints for each row
execute function public.zyra_reject_locked_journey_write('match');
drop trigger if exists journey_family_answers_pause_lock on public.journey_family_answers;
create trigger journey_family_answers_pause_lock before insert or update or delete
on public.journey_family_answers for each row
execute function public.zyra_reject_locked_journey_write('match');
drop trigger if exists journey_family_reviews_pause_lock on public.journey_family_reviews;
create trigger journey_family_reviews_pause_lock before insert or update or delete
on public.journey_family_reviews for each row
execute function public.zyra_reject_locked_journey_write('match');
drop trigger if exists journey_family_review_responses_pause_lock
on public.journey_family_review_responses;
create trigger journey_family_review_responses_pause_lock before insert or update or delete
on public.journey_family_review_responses for each row
execute function public.zyra_reject_locked_journey_write('review_response');
drop trigger if exists journey_milestone_attestations_pause_lock
on public.journey_milestone_attestations;
create trigger journey_milestone_attestations_pause_lock before insert or update or delete
on public.journey_milestone_attestations for each row
execute function public.zyra_reject_locked_journey_write('match');
drop trigger if exists messages_pause_lock on public.messages;
create trigger messages_pause_lock before insert or update or delete
on public.messages for each row
execute function public.zyra_reject_locked_journey_write('message');

-- Every ending path clears the new state and the retired compatibility
-- columns. This includes block/safety/system endings that bypass end_journey.
create or replace function public.zyra_clear_pause_on_terminal()
returns trigger language plpgsql security definer set search_path='public'
as $function$
begin
  if new.status = 'ended' then
    new.pause_state := 'none';
    new.pause_initiated_by := null;
    new.pause_requested_by := null;
    new.pause_requested_at := null;
    new.pause_deadline_at := null;
    new.pause_version := old.pause_version + 1;
    if tg_table_name = 'matches' then
      new.pause_attempt_id := null;
      new.suspended_by := null;
      new.suspended_at := null;
      new.also_paused_by := null;
      new.also_paused_at := null;
      new.pause_nudged_at := null;
    else
      new.paused_by := null;
      new.paused_at := null;
      new.also_paused_by := null;
      new.also_paused_at := null;
    end if;
  end if;
  return new;
end;
$function$;

drop trigger if exists matches_clear_pause_on_terminal on public.matches;
create trigger matches_clear_pause_on_terminal
before update of status on public.matches for each row
execute function public.zyra_clear_pause_on_terminal();
drop trigger if exists attempts_clear_pause_on_terminal on public.journey_attempts;
create trigger attempts_clear_pause_on_terminal
before update of status on public.journey_attempts for each row
execute function public.zyra_clear_pause_on_terminal();

grant select (
  pause_state
) on public.matches to authenticated;

comment on function public.transition_journey_pause(uuid,text,bigint) is
  'Atomic shared Pause decision state machine; locks match/attempt, enforces CAS, eligibility, slot and paused capacity rules.';
