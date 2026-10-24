-- OA-ZYRA-298 / DR-ZYRA-242 — one shared Guardian Circle per Seeker.
-- Separate from Journey chat. The circle is the Seeker plus every currently
-- linked, unblocked Guardian; there are no one-to-one family threads.

create table public.family_message_threads (
  id uuid primary key default gen_random_uuid(),
  seeker_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  last_message_at timestamptz,
  constraint family_message_threads_one_circle_per_seeker unique (seeker_id)
);

create index family_message_threads_recent
  on public.family_message_threads (last_message_at desc nulls last);

create table public.family_message_memberships (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.family_message_threads(id)
    on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  member_role text not null check (member_role in ('seeker', 'guardian')),
  joined_at timestamptz not null default now(),
  readable_from timestamptz not null default now(),
  left_at timestamptz,
  constraint family_message_memberships_time_order
    check (left_at is null or left_at >= joined_at)
);

create unique index family_message_memberships_one_active_epoch
  on public.family_message_memberships (thread_id, user_id)
  where left_at is null;
create index family_message_memberships_user_active
  on public.family_message_memberships (user_id, thread_id)
  where left_at is null;

create table public.family_messages (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.family_message_threads(id)
    on delete cascade,
  sender_id uuid references public.profiles(id) on delete set null,
  kind text not null default 'message'
    check (kind in ('message', 'lifecycle')),
  body text not null,
  created_at timestamptz not null default now(),
  constraint family_messages_body_length
    check (char_length(btrim(body)) between 1 and 2000),
  constraint family_messages_sender_shape
    check (
      -- Account deletion uses the declared ON DELETE SET NULL above. An
      -- ordinary message may therefore outlive its sender's profile. Client
      -- writes remain RPC-only and the send RPC always requires auth.uid().
      kind = 'message'
      or (kind = 'lifecycle' and sender_id is null)
    )
);

create index family_messages_thread_created
  on public.family_messages (thread_id, created_at desc, id desc);
create index family_messages_sender_rate
  on public.family_messages (sender_id, created_at desc)
  where kind = 'message';

create table public.family_message_participant_state (
  thread_id uuid not null references public.family_message_threads(id)
    on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  last_read_at timestamptz,
  muted_at timestamptz,
  archived_at timestamptz,
  primary key (thread_id, user_id)
);

create table public.family_message_reports (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.family_message_threads(id)
    on delete cascade,
  message_id uuid not null references public.family_messages(id)
    on delete cascade,
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  reported_id uuid not null references public.profiles(id) on delete cascade,
  reason text not null check (reason in (
    'harassment', 'inappropriate_content', 'violence', 'privacy', 'other'
  )),
  created_at timestamptz not null default now(),
  constraint family_message_reports_distinct_people
    check (reporter_id <> reported_id)
);

create index family_message_reports_pending
  on public.family_message_reports (created_at desc);

alter table public.family_message_threads enable row level security;
alter table public.family_message_memberships enable row level security;
alter table public.family_messages enable row level security;
alter table public.family_message_participant_state enable row level security;
alter table public.family_message_reports enable row level security;

revoke all on public.family_message_threads from public, anon, authenticated;
revoke all on public.family_message_memberships from public, anon, authenticated;
revoke all on public.family_messages from public, anon, authenticated;
revoke all on public.family_message_participant_state from public, anon, authenticated;
revoke all on public.family_message_reports from public, anon, authenticated;

grant select on public.family_message_threads to authenticated;
grant select on public.family_messages to authenticated;
grant select on public.family_message_participant_state to authenticated;

-- RLS uses a definer helper so client roles never need direct SELECT on the
-- membership ledger itself. The caller can ask only whether their own current
-- membership epoch covers a thread/message timestamp.
create function public.zyra_family_message_can_read(
  p_thread uuid,
  p_created_at timestamptz default null
) returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.family_message_memberships membership
    where membership.thread_id = p_thread
      and membership.user_id = (select auth.uid())
      and membership.left_at is null
      and (p_created_at is null or p_created_at >= membership.readable_from)
  );
$$;

revoke execute on function public.zyra_family_message_can_read(uuid, timestamptz)
  from public, anon;
grant execute on function public.zyra_family_message_can_read(uuid, timestamptz)
  to authenticated;

create policy family_message_threads_active_member_read
  on public.family_message_threads for select to authenticated
  using (public.zyra_family_message_can_read(id));

create policy family_messages_active_epoch_read
  on public.family_messages for select to authenticated
  using (public.zyra_family_message_can_read(thread_id, created_at));

create policy family_message_participant_state_self_read
  on public.family_message_participant_state for select to authenticated
  using (
    user_id = (select auth.uid())
    and public.zyra_family_message_can_read(thread_id)
  );

-- One current ZYRA One held by the Seeker, or Guardian One held by any
-- currently active Circle Guardian, covers the shared circle.
create function public.zyra_family_message_circle_can_send(p_seeker uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select
    p_seeker is not null
    and exists (
      select 1 from public.wali_links link
      where link.seeker_id = p_seeker and link.status = 'active'
        and not exists (
          select 1 from public.profile_blocks block
          where (block.blocker_id = p_seeker and block.blocked_id = link.wali_id)
             or (block.blocker_id = link.wali_id and block.blocked_id = p_seeker)
        )
    )
    and exists (
      select 1 from public.subscriptions subscription
      where subscription.status = 'active'
        and (
          (subscription.user_id = p_seeker
            and subscription.plan_type = 'seeker_premium')
          or
          (subscription.plan_type = 'wali_premium' and exists (
            select 1 from public.wali_links link
            where link.seeker_id = p_seeker
              and link.wali_id = subscription.user_id
              and link.status = 'active'
              and not exists (
                select 1 from public.profile_blocks block
                where (block.blocker_id = p_seeker and block.blocked_id = link.wali_id)
                   or (block.blocker_id = link.wali_id and block.blocked_id = p_seeker)
              )
          ))
        )
    );
$$;

revoke execute on function public.zyra_family_message_circle_can_send(uuid)
  from public, anon, authenticated;

-- Re-linking creates a fresh membership epoch beginning now, so a newly
-- linked Guardian never inherits messages written before joining.
create function public.zyra_sync_family_message_circle_members(p_seeker uuid)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_thread uuid;
  v_now timestamptz := pg_catalog.clock_timestamp();
begin
  select thread.id into v_thread
  from public.family_message_threads thread
  where thread.seeker_id = p_seeker;
  if v_thread is null then return null; end if;

  insert into public.family_message_memberships (
    thread_id, user_id, member_role, joined_at, readable_from
  ) values (
    v_thread, p_seeker, 'seeker', v_now,
    (select thread.created_at from public.family_message_threads thread
     where thread.id = v_thread)
  )
  on conflict (thread_id, user_id) where left_at is null do nothing;

  update public.family_message_memberships membership
  set left_at = v_now
  where membership.thread_id = v_thread
    and membership.member_role = 'guardian'
    and membership.left_at is null
    and not exists (
      select 1 from public.wali_links link
      where link.seeker_id = p_seeker
        and link.wali_id = membership.user_id
        and link.status = 'active'
        and not exists (
          select 1 from public.profile_blocks block
          where (block.blocker_id = p_seeker and block.blocked_id = link.wali_id)
             or (block.blocker_id = link.wali_id and block.blocked_id = p_seeker)
        )
    );

  insert into public.family_message_memberships (
    thread_id, user_id, member_role, joined_at, readable_from
  )
  select v_thread, link.wali_id, 'guardian', v_now, v_now
  from public.wali_links link
  where link.seeker_id = p_seeker and link.status = 'active'
    and not exists (
      select 1 from public.profile_blocks block
      where (block.blocker_id = p_seeker and block.blocked_id = link.wali_id)
         or (block.blocker_id = link.wali_id and block.blocked_id = p_seeker)
    )
    and not exists (
      select 1 from public.family_message_memberships membership
      where membership.thread_id = v_thread
        and membership.user_id = link.wali_id
        and membership.left_at is null
    );

  insert into public.family_message_participant_state (thread_id, user_id)
  select membership.thread_id, membership.user_id
  from public.family_message_memberships membership
  where membership.thread_id = v_thread and membership.left_at is null
  on conflict (thread_id, user_id) do nothing;

  return v_thread;
end;
$$;

revoke execute on function public.zyra_sync_family_message_circle_members(uuid)
  from public, anon, authenticated;

create function public.zyra_open_family_message_circle(p_seeker uuid)
returns table (
  thread_id uuid,
  seeker_id uuid,
  seeker_first_name text,
  participant_count bigint,
  can_send boolean,
  access_reason text,
  muted boolean
)
language plpgsql security definer set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_thread uuid;
  v_can_send boolean;
  v_has_guardian boolean;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if p_seeker is null then raise exception 'invalid_seeker'; end if;
  if v_me <> p_seeker and not exists (
    select 1 from public.wali_links link
    where link.seeker_id = p_seeker and link.wali_id = v_me
      and link.status = 'active'
      and not exists (
        select 1 from public.profile_blocks block
        where (block.blocker_id = p_seeker and block.blocked_id = v_me)
           or (block.blocker_id = v_me and block.blocked_id = p_seeker)
      )
  ) then raise exception 'no_guardian_circle_access'; end if;

  insert into public.family_message_threads as circle (seeker_id)
  values (p_seeker)
  -- The RETURNS TABLE output also has a seeker_id variable. Naming the
  -- constraint avoids PL/pgSQL's ambiguous-column error on first execution.
  on conflict on constraint family_message_threads_one_circle_per_seeker
  do update set seeker_id = excluded.seeker_id
  returning circle.id into v_thread;
  perform public.zyra_sync_family_message_circle_members(p_seeker);

  if not exists (
    select 1 from public.family_message_memberships membership
    where membership.thread_id = v_thread and membership.user_id = v_me
      and membership.left_at is null
  ) then raise exception 'no_guardian_circle_access'; end if;

  v_can_send := public.zyra_family_message_circle_can_send(p_seeker);
  select exists (
    select 1 from public.family_message_memberships membership
    where membership.thread_id = v_thread
      and membership.member_role = 'guardian'
      and membership.left_at is null
  ) into v_has_guardian;

  return query
  select v_thread, profile.id, profile.first_name,
    (select count(*) from public.family_message_memberships membership
     where membership.thread_id = v_thread and membership.left_at is null),
    v_can_send,
    case when not v_has_guardian then 'link_inactive'
         when v_can_send then 'ready'
         else 'membership_required' end,
    coalesce(state.muted_at is not null, false)
  from public.profiles profile
  left join public.family_message_participant_state state
    on state.thread_id = v_thread and state.user_id = v_me
  where profile.id = p_seeker;
end;
$$;

create function public.zyra_family_message_circles()
returns table (
  thread_id uuid,
  seeker_id uuid,
  seeker_first_name text,
  participant_count bigint,
  last_message text,
  last_message_at timestamptz,
  unread_count bigint,
  can_send boolean,
  access_reason text,
  muted boolean
)
language sql stable security definer set search_path = ''
as $$
  select thread.id, thread.seeker_id, profile.first_name,
    (select count(*) from public.family_message_memberships member_count
     where member_count.thread_id = thread.id and member_count.left_at is null),
    latest.body, thread.last_message_at,
    count(unread.id) filter (where unread.id is not null),
    public.zyra_family_message_circle_can_send(thread.seeker_id),
    case when not exists (
      select 1 from public.family_message_memberships guardian
      where guardian.thread_id = thread.id
        and guardian.member_role = 'guardian' and guardian.left_at is null
    ) then 'link_inactive'
    when public.zyra_family_message_circle_can_send(thread.seeker_id)
      then 'ready' else 'membership_required' end,
    coalesce(state.muted_at is not null, false)
  from public.family_message_threads thread
  join public.profiles profile on profile.id = thread.seeker_id
  join public.family_message_memberships me
    on me.thread_id = thread.id and me.user_id = (select auth.uid())
   and me.left_at is null
  left join lateral (
    select message.body from public.family_messages message
    where message.thread_id = thread.id
      and message.created_at >= me.readable_from
    order by message.created_at desc, message.id desc limit 1
  ) latest on true
  left join public.family_message_participant_state state
    on state.thread_id = thread.id and state.user_id = (select auth.uid())
  left join public.family_messages unread
    on unread.thread_id = thread.id
   and unread.sender_id is distinct from (select auth.uid())
   and unread.kind = 'message'
   and unread.created_at >= me.readable_from
   and unread.created_at > coalesce(state.last_read_at, '-infinity'::timestamptz)
  group by thread.id, profile.first_name, latest.body, state.muted_at,
    me.readable_from
  order by thread.last_message_at desc nulls last, thread.created_at desc;
$$;

create function public.zyra_family_messages(
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
  select message.id, message.sender_id, sender.first_name, message.kind,
    message.body, message.created_at
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

create function public.zyra_send_family_message(p_thread uuid, p_body text)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_seeker uuid;
  v_body text := btrim(coalesce(p_body, ''));
  v_id uuid;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if char_length(v_body) < 1 or char_length(v_body) > 2000 then
    raise exception 'invalid_message_length';
  end if;
  -- The budget is per sender, not per Circle. A Guardian can belong to more
  -- than one Circle, so thread row locks alone permit concurrent requests to
  -- pass the same rate-count check. Always take the sender lock first.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_me::text, 298)
  );
  select thread.seeker_id into v_seeker
  from public.family_message_threads thread
  where thread.id = p_thread for update;
  if v_seeker is null then raise exception 'circle_not_found'; end if;
  perform public.zyra_sync_family_message_circle_members(v_seeker);
  if not exists (
    select 1 from public.family_message_memberships membership
    where membership.thread_id = p_thread and membership.user_id = v_me
      and membership.left_at is null
  ) then raise exception 'circle_not_found'; end if;
  if not public.zyra_family_message_circle_can_send(v_seeker) then
    raise exception 'family_message_read_only';
  end if;
  if (select count(*) from public.family_messages message
      where message.sender_id = v_me and message.kind = 'message'
        and message.created_at > now() - interval '1 minute') >= 10 then
    raise exception 'family_message_rate_minute';
  end if;
  if (select count(*) from public.family_messages message
      where message.sender_id = v_me and message.kind = 'message'
        and message.created_at > now() - interval '1 hour') >= 60 then
    raise exception 'family_message_rate_hour';
  end if;
  insert into public.family_messages (thread_id, sender_id, body)
  values (p_thread, v_me, v_body) returning id into v_id;
  update public.family_message_threads set last_message_at = now()
  where id = p_thread;
  insert into public.family_message_participant_state
    (thread_id, user_id, last_read_at)
  values (p_thread, v_me, now())
  on conflict (thread_id, user_id) do update
    set last_read_at = excluded.last_read_at;
  return v_id;
end;
$$;

create function public.zyra_mark_family_messages_read(p_thread uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare v_me uuid := auth.uid();
begin
  if v_me is null or not exists (
    select 1 from public.family_message_memberships membership
    where membership.thread_id = p_thread and membership.user_id = v_me
      and membership.left_at is null
  ) then raise exception 'circle_not_found'; end if;
  insert into public.family_message_participant_state
    (thread_id, user_id, last_read_at)
  values (p_thread, v_me, now())
  on conflict (thread_id, user_id) do update
    set last_read_at = excluded.last_read_at;
end;
$$;

create function public.zyra_set_family_message_muted(
  p_thread uuid, p_muted boolean
) returns void
language plpgsql security definer set search_path = ''
as $$
declare v_me uuid := auth.uid();
begin
  if v_me is null or not exists (
    select 1 from public.family_message_memberships membership
    where membership.thread_id = p_thread and membership.user_id = v_me
      and membership.left_at is null
  ) then raise exception 'circle_not_found'; end if;
  insert into public.family_message_participant_state
    (thread_id, user_id, muted_at)
  values (p_thread, v_me, case when p_muted then now() else null end)
  on conflict (thread_id, user_id) do update set muted_at = excluded.muted_at;
end;
$$;

create function public.zyra_report_family_message(
  p_thread uuid, p_message uuid, p_reason text
) returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_reported uuid;
  v_id uuid;
begin
  if p_reason not in (
    'harassment', 'inappropriate_content', 'violence', 'privacy', 'other'
  ) then raise exception 'invalid_report_reason'; end if;
  select message.sender_id into v_reported
  from public.family_messages message
  join public.family_message_memberships membership
    on membership.thread_id = message.thread_id
   and membership.user_id = v_me and membership.left_at is null
  where message.id = p_message and message.thread_id = p_thread
    and message.kind = 'message' and message.sender_id is distinct from v_me
    and message.created_at >= membership.readable_from;
  if v_reported is null then raise exception 'message_not_reportable'; end if;
  insert into public.family_message_reports
    (thread_id, message_id, reporter_id, reported_id, reason)
  values (p_thread, p_message, v_me, v_reported, p_reason)
  returning id into v_id;
  return v_id;
end;
$$;

create function public.zyra_sync_family_message_link_lifecycle()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare v_seeker uuid;
begin
  v_seeker := case when tg_op = 'DELETE' then old.seeker_id else new.seeker_id end;
  perform public.zyra_sync_family_message_circle_members(v_seeker);
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

create trigger wali_links_family_message_lifecycle
after insert or update of status or delete on public.wali_links
for each row execute function public.zyra_sync_family_message_link_lifecycle();

create function public.zyra_sync_family_message_block_lifecycle()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_first uuid;
  v_second uuid;
  v_seeker uuid;
begin
  if tg_op = 'DELETE' then
    v_first := old.blocker_id;
    v_second := old.blocked_id;
  else
    v_first := new.blocker_id;
    v_second := new.blocked_id;
  end if;
  select link.seeker_id into v_seeker from public.wali_links link
  where (link.seeker_id = v_first and link.wali_id = v_second)
     or (link.seeker_id = v_second and link.wali_id = v_first)
  limit 1;
  if v_seeker is not null then
    perform public.zyra_sync_family_message_circle_members(v_seeker);
  end if;
  if tg_op = 'DELETE' then return old; end if;
  return new;
end;
$$;

create trigger profile_blocks_family_message_lifecycle
after insert or delete on public.profile_blocks
for each row execute function public.zyra_sync_family_message_block_lifecycle();

revoke execute on function public.zyra_open_family_message_circle(uuid)
  from public, anon;
revoke execute on function public.zyra_family_message_circles()
  from public, anon;
revoke execute on function public.zyra_family_messages(uuid, timestamptz, integer)
  from public, anon;
revoke execute on function public.zyra_send_family_message(uuid, text)
  from public, anon;
revoke execute on function public.zyra_mark_family_messages_read(uuid)
  from public, anon;
revoke execute on function public.zyra_set_family_message_muted(uuid, boolean)
  from public, anon;
revoke execute on function public.zyra_report_family_message(uuid, uuid, text)
  from public, anon;
revoke execute on function public.zyra_sync_family_message_link_lifecycle()
  from public, anon, authenticated;
revoke execute on function public.zyra_sync_family_message_block_lifecycle()
  from public, anon, authenticated;

grant execute on function public.zyra_open_family_message_circle(uuid)
  to authenticated;
grant execute on function public.zyra_family_message_circles()
  to authenticated;
grant execute on function public.zyra_family_messages(uuid, timestamptz, integer)
  to authenticated;
grant execute on function public.zyra_send_family_message(uuid, text)
  to authenticated;
grant execute on function public.zyra_mark_family_messages_read(uuid)
  to authenticated;
grant execute on function public.zyra_set_family_message_muted(uuid, boolean)
  to authenticated;
grant execute on function public.zyra_report_family_message(uuid, uuid, text)
  to authenticated;

comment on table public.family_message_threads is
  'One canonical shared Guardian Circle per Seeker. Never a Journey chat.';
comment on table public.family_message_memberships is
  'Epoch-scoped Guardian Circle membership; no pre-join history is exposed.';
comment on function public.zyra_family_message_circle_can_send(uuid) is
  'Authoritative circle-scoped family-message entitlement resolver.';
