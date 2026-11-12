-- OA-ZYRA-317 / DOC-ZYRA-0473 V4 / Q124, Q127 and Q133 / LOCK 32.
-- Only launch and foreground activity advance the clock after the backfill.
-- Live job scheduling and email delivery are separate.
begin;

alter table public.profiles add column last_active_at timestamptz;

with activity_events as (
  select sender_id as user_id, created_at as used_at from public.messages
  union all
  select sender_id, created_at from public.family_messages where kind = 'message'
  union all
  select requested_by, created_at from public.journey_requests
  union all
  select requested_to, responded_at from public.journey_requests
  where status = 'accepted' or closed_reason = 'declined'
  union all
  select case when source = 'personal_code' then recipient_id else inviter_id end, created_at
  from public.wali_invites
  union all
  select invited_by, created_at from public.family_membership_invitations
  union all
  select user_id, updated_at from public.onboarding_answers
  union all
  select seeker_id, created_at from public.journey_phase_answers
  union all
  select answerer_id, created_at from public.journey_family_answers
  union all
  select wali_id, responded_at from public.journey_family_review_responses
), newest_activity as (
  select user_id, max(used_at) as used_at
  from activity_events
  where user_id is not null
  group by user_id
)
update public.profiles p
set last_active_at = greatest(p.created_at, u.created_at, u.last_sign_in_at, activity.used_at)
from auth.users u left join newest_activity activity on activity.user_id = u.id
where p.id = u.id;

alter table public.profiles alter column last_active_at set default now();
alter table public.profiles alter column last_active_at set not null;
-- The existing column-scoped grants keep last_active_at private. Index the
-- exact UTC calendar anniversary so the job also handles leap-day accounts.
create index profiles_inactivity_anniversary_idx on public.profiles (
  (((last_active_at at time zone 'UTC') + interval '2 years') at time zone 'UTC')
);

create table public.zyra_inactivity_notices (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  warned_at timestamptz not null,
  removal_due_at timestamptz not null,
  cleared_at timestamptz,
  completed_at timestamptz,
  welcome_back_pending boolean not null default false,
  check (cleared_at is null or completed_at is null),
  check (not welcome_back_pending or cleared_at is not null)
);
alter table public.zyra_inactivity_notices enable row level security;
revoke all on public.zyra_inactivity_notices from public, anon, authenticated, service_role;
grant select on public.zyra_inactivity_notices to authenticated, service_role;
create policy inactivity_notices_owner_select on public.zyra_inactivity_notices
for select to authenticated using (user_id = (select auth.uid()));

create table public.email_outbox (
  user_id uuid not null references public.profiles(id) on delete cascade,
  template_key text not null check (template_key in (
    'inactivity_1', 'inactivity_2', 'inactivity_3', 'inactivity_4', 'inactivity_5'
  )),
  variables jsonb not null,
  due_at timestamptz not null,
  sent_at timestamptz,
  cancelled_at timestamptz,
  primary key (user_id, template_key, due_at)
);
alter table public.email_outbox enable row level security;
revoke all on public.email_outbox from public, anon, authenticated, service_role;
grant select on public.email_outbox to service_role;

alter table public.notifications drop constraint notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type in (
    'new_match', 'new_message', 'wali_request', 'journey_ended', 'journey_request',
    'journey_request_accepted', 'journey_request_declined', 'milestone_proposed',
    'milestone_confirmed', 'pause_nudge', 'journey_paused', 'journey_also_paused',
    'journey_continued', 'wali_invite_received', 'wali_invite_declined',
    'wali_invite_expiring', 'wali_invite_expired', 'wali_invite_revoked', 'inactivity_warning',
    'journey_ended_profile_inactive'
  ));

create or replace function public.zyra_notification_category(p_type text)
returns text language plpgsql immutable set search_path = ''
as $$
declare
  v_category text;
begin
  if p_type in ('new_device_signin', 'password_changed', 'account_action', 'inactivity_warning',
    'journey_ended_profile_inactive') then
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
    raise exception 'unknown_notification_type: %', p_type using errcode = '22023';
  end if;
  return v_category;
end;
$$;

-- A block only hides an archive temporarily. Count and remove the caller's
-- remaining copies, including copies temporarily hidden by a block.
create function private.zyra_inactivity_ended_attempts(p_user uuid)
returns table(attempt_id uuid, match_id uuid)
language sql stable set search_path = ''
as $$
  select a.id, m.id
  from public.matches m
  join public.journey_attempts a on a.match_id = m.id and a.status = 'ended'
  left join private.zyra_ended_journey_removals r on r.attempt_id = a.id
  where (m.seeker_a_id = p_user and r.seeker_a_removed_at is null)
     or (m.seeker_b_id = p_user and r.seeker_b_removed_at is null);
$$;
revoke all on function private.zyra_inactivity_ended_attempts(uuid)
  from public, anon, authenticated, service_role;

create function public.zyra_touch_activity()
returns void language plpgsql security definer set search_path = '' set timezone = 'UTC'
as $$
declare
  v_user uuid := (select auth.uid());
  v_now timestamptz := now();
  v_last_active_at timestamptz;
  v_due_at timestamptz;
begin
  if v_user is null then raise exception using errcode = '42501', message = 'not_signed_in'; end if;

  -- The worker takes the same lock before it can remove any copies.
  select p.last_active_at into v_last_active_at
  from public.profiles p where p.id = v_user for no key update;
  if not found then return; end if;

  if v_last_active_at::date < v_now::date then
    update public.profiles set last_active_at = v_now where id = v_user;
  end if;

  update public.zyra_inactivity_notices set cleared_at = v_now, welcome_back_pending = true
  where user_id = v_user and cleared_at is null and completed_at is null
  returning removal_due_at into v_due_at;
  if found then
    update public.email_outbox set cancelled_at = v_now
    where user_id = v_user and due_at >= v_due_at - interval '28 days' and due_at < v_due_at
      and sent_at is null and cancelled_at is null;
    delete from public.notifications where user_id = v_user and type = 'inactivity_warning';
  end if;
end;
$$;
revoke all on function public.zyra_touch_activity() from public, anon, authenticated, service_role;
grant execute on function public.zyra_touch_activity() to authenticated;

create function public.zyra_my_inactivity_notice()
returns table(removal_due_at timestamptz, ended_journeys integer)
language sql stable security definer set search_path = ''
as $$
  select n.removal_due_at, archive.total
  from public.zyra_inactivity_notices n
  cross join lateral (
    select count(*)::integer as total from private.zyra_inactivity_ended_attempts(n.user_id)
  ) archive
  where n.user_id = (select auth.uid()) and n.cleared_at is null and n.completed_at is null
    and archive.total > 0;
$$;
revoke all on function public.zyra_my_inactivity_notice() from public, anon, authenticated, service_role;
grant execute on function public.zyra_my_inactivity_notice() to authenticated;

create function public.zyra_my_welcome_back()
returns boolean language plpgsql security definer set search_path = ''
as $$
begin
  update public.zyra_inactivity_notices set welcome_back_pending = false
  where user_id = (select auth.uid()) and welcome_back_pending;
  return found;
end;
$$;
revoke all on function public.zyra_my_welcome_back() from public, anon, authenticated, service_role;
grant execute on function public.zyra_my_welcome_back() to authenticated;

-- The clock is injectable only inside the database for disposable replay.
create function private.zyra_run_inactivity_job_at(p_now timestamptz)
returns void language plpgsql set search_path = '' set timezone = 'UTC'
as $$
declare
  v_account record;
  v_notice public.zyra_inactivity_notices%rowtype;
  v_due_at timestamptz;
  v_count integer;
  v_attempt record;
  v_variables jsonb;
begin
  if not pg_try_advisory_xact_lock(hashtextextended('zyra-inactivity-job', 0)) then return; end if;

  for v_account in
    select p.id, p.first_name, p.last_active_at, calendar.anniversary
    from public.profiles p
    cross join lateral (
      select ((p.last_active_at at time zone 'UTC') + interval '2 years') at time zone 'UTC' as anniversary
    ) calendar
    left join public.zyra_inactivity_notices n on n.user_id = p.id
    where calendar.anniversary <= p_now + interval '14 days'
      and (
        n.user_id is null
        or ((n.cleared_at is not null or n.completed_at is not null) and p.last_active_at > n.warned_at)
        or (n.cleared_at is null and n.completed_at is null and n.removal_due_at <= p_now)
      )
    order by p.id
    for no key update of p skip locked
  loop
    -- Recheck the notice after taking the profile lock. It may have been
    -- cleared while the initial query was reading its snapshot.
    select * into v_notice from public.zyra_inactivity_notices n where n.user_id = v_account.id;

    if v_notice.user_id is null or (
      (v_notice.cleared_at is not null or v_notice.completed_at is not null)
      and v_account.last_active_at > v_notice.warned_at
    ) then
      select count(*)::integer into v_count from private.zyra_inactivity_ended_attempts(v_account.id);
      if v_count = 0 then continue; end if;
      v_due_at := v_account.anniversary + interval '14 days';

      insert into public.zyra_inactivity_notices (user_id, warned_at, removal_due_at)
      values (v_account.id, p_now, v_due_at)
      on conflict (user_id) do update
      set warned_at = excluded.warned_at, removal_due_at = excluded.removal_due_at,
          cleared_at = null, completed_at = null, welcome_back_pending = false
      returning * into v_notice;

      v_variables := jsonb_build_object(
        'first_name', v_account.first_name, 'ended_journeys', v_count, 'removal_date', v_due_at::date
      );
      insert into public.email_outbox (user_id, template_key, variables, due_at)
      select v_account.id, email.template_key, v_variables, v_account.anniversary + email.offset_days
      from (values
        ('inactivity_1', interval '-14 days'),
        ('inactivity_2', interval '-7 days'),
        ('inactivity_3', interval '0 days'),
        ('inactivity_4', interval '7 days')
      ) email(template_key, offset_days);

      -- Q124 keeps this signal for My ZYRA. Email is the only outbound
      -- inactivity communication in LOCK 32.
      if p_now < v_due_at then
        perform public.create_notification(v_account.id, 'inactivity_warning', '', null, null);
      end if;
    end if;

    if v_notice.cleared_at is not null or v_notice.completed_at is not null
       or v_notice.removal_due_at > p_now then
      continue;
    end if;

    v_count := 0;
    for v_attempt in
      select eligible.attempt_id, eligible.match_id
      from private.zyra_inactivity_ended_attempts(v_account.id) eligible
      order by eligible.match_id, eligible.attempt_id
    loop
      -- Manual removal, report filing and account deletion lock the pair
      -- first. Under that lock, recheck in case this copy was already removed.
      perform 1 from public.matches m where m.id = v_attempt.match_id for update;
      if not found then continue; end if;
      if not exists (
        select 1 from private.zyra_inactivity_ended_attempts(v_account.id) eligible
        where eligible.attempt_id = v_attempt.attempt_id
      ) then continue; end if;

      perform private.zyra_remove_ended_journey_for(v_attempt.attempt_id, v_account.id);
      v_count := v_count + 1;
    end loop;

    delete from public.notifications where user_id = v_account.id and type = 'inactivity_warning';
    -- A delayed job keeps the planned dates for the audit trail. Superseded
    -- reminders must not go out after the archive was removed.
    update public.email_outbox set cancelled_at = p_now
    where user_id = v_account.id and due_at >= v_notice.removal_due_at - interval '28 days'
      and due_at < v_notice.removal_due_at and sent_at is null and cancelled_at is null;
    if v_count = 0 then
      update public.zyra_inactivity_notices set cleared_at = p_now where user_id = v_account.id;
    else
      update public.zyra_inactivity_notices set completed_at = p_now where user_id = v_account.id;
      -- The completion email is inserted only with the removal itself. Its
      -- date stays anchored to the inactivity anniversary if the job ran late.
      insert into public.email_outbox (user_id, template_key, variables, due_at)
      values (v_account.id, 'inactivity_5', jsonb_build_object(
        'first_name', v_account.first_name, 'ended_journeys', v_count,
        'removal_date', v_notice.removal_due_at::date
      ), v_notice.removal_due_at);
    end if;
  end loop;

  perform private.zyra_purge_closed_ended_journeys();
end;
$$;
revoke all on function private.zyra_run_inactivity_job_at(timestamptz)
  from public, anon, authenticated, service_role;

create function public.zyra_run_inactivity_job()
returns void language sql security definer set search_path = ''
as $$
  select private.zyra_run_inactivity_job_at(now());
$$;
revoke all on function public.zyra_run_inactivity_job() from public, anon, authenticated, service_role;
grant execute on function public.zyra_run_inactivity_job() to service_role;

commit;
