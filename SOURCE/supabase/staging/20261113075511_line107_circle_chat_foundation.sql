-- Line 107 / DOC-ZYRA-0476 / Q138 / OA-ZYRA-340 / DR-ZYRA-344.
-- Disposable verification only. Journey sends remain fenced pending the
-- alert contract and integration with departure/archive safety sealing.

begin;

create table public.family_message_chats (
  id uuid primary key default gen_random_uuid(),
  thread_id uuid not null references public.family_message_threads(id) on delete cascade,
  kind text not null check (kind in ('main', 'journey')),
  attempt_id uuid,
  created_at timestamptz not null default now(),
  check ((kind = 'main') = (attempt_id is null)),
  unique (thread_id, id),
  unique (thread_id, attempt_id)
);
create unique index family_message_chats_one_main
  on public.family_message_chats (thread_id) where kind = 'main';
create index family_message_chats_attempt
  on public.family_message_chats (attempt_id) where attempt_id is not null;

-- The opaque attempt identity survives a source purge; member admission
-- requires the source row and fails closed. No cascade can erase Circle
-- evidence when a counterpart's Journey disappears.
comment on table public.family_message_chats is
  'Circle-owned discussion identity. Journey attempt ids are joint identifiers; do not expose them as member fields.';
create table public.family_message_chat_state (
  chat_id uuid not null references public.family_message_chats(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  last_read_at timestamptz,
  muted_at timestamptz,
  primary key (chat_id, user_id)
);
comment on table public.family_message_chat_state is
  'Owner-only member preferences and read state for a specific Circle chat.';
create index family_message_chat_state_user on public.family_message_chat_state(user_id);

alter table public.family_message_chats enable row level security;
alter table public.family_message_chat_state enable row level security;
revoke all on public.family_message_chats, public.family_message_chat_state
  from public, anon, authenticated, service_role;

insert into public.family_message_chats(thread_id, kind, created_at)
select id, 'main', created_at from public.family_message_threads;

insert into public.family_message_chats(thread_id, kind, attempt_id, created_at)
select t.id, 'journey', a.id, a.started_at
from public.family_message_threads t
join public.matches m on t.seeker_id in (m.seeker_a_id, m.seeker_b_id)
join public.journey_attempts a on a.match_id = m.id
where a.started_at is not null and a.status in ('active', 'ended')
  and m.seeker_a_id is not null and m.seeker_b_id is not null
  and not exists (
    select 1 from private.zyra_account_deleted_matches d where d.match_id = m.id
  );

alter table public.family_messages add column chat_id uuid;
update public.family_messages message set chat_id = chat.id
from public.family_message_chats chat
where chat.thread_id = message.thread_id and chat.kind = 'main';
alter table public.family_messages
  alter column chat_id set not null,
  add constraint family_messages_chat_thread_fkey
  foreign key (thread_id, chat_id) references public.family_message_chats(thread_id, id);
create index family_messages_chat_created
  on public.family_messages(chat_id, created_at desc, id desc);

create function private.zyra_family_chat_seed_for_thread()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(new.seeker_id::text, 107));
  insert into public.family_message_chats(thread_id, kind, created_at)
  values (new.id, 'main', new.created_at);

  insert into public.family_message_chats(thread_id, kind, attempt_id, created_at)
  select new.id, 'journey', a.id, a.started_at
  from public.matches m
  join public.journey_attempts a on a.match_id = m.id
  where new.seeker_id in (m.seeker_a_id, m.seeker_b_id)
    and m.seeker_a_id is not null and m.seeker_b_id is not null
    and a.started_at is not null and a.status in ('active', 'ended')
    and not exists (
      select 1 from private.zyra_account_deleted_matches d where d.match_id = m.id
    )
  on conflict (thread_id, attempt_id) do nothing;
  return new;
end;
$$;

create function private.zyra_family_chat_seed_for_attempt()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare v_seeker uuid;
begin
  if new.status <> 'active' or new.started_at is null then return new; end if;
  if tg_op = 'UPDATE' and old.status = 'active' and old.started_at is not null then
    return new;
  end if;
  -- Take the same lock as Circle creation. UUID order is stable for both sides.
  for v_seeker in
    select p.id from public.matches m
    cross join lateral (values (m.seeker_a_id), (m.seeker_b_id)) p(id)
    where m.id = new.match_id
      and m.seeker_a_id is not null and m.seeker_b_id is not null
      and not exists (
        select 1 from private.zyra_account_deleted_matches d where d.match_id = m.id
      )
    order by p.id
  loop
    perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(v_seeker::text, 107));
    insert into public.family_message_chats(thread_id, kind, attempt_id, created_at)
    select t.id, 'journey', new.id, new.started_at
    from public.family_message_threads t where t.seeker_id = v_seeker
    on conflict (thread_id, attempt_id) do nothing;
  end loop;
  return new;
end;
$$;

create function private.zyra_family_message_default_main()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if new.chat_id is null then
    select c.id into new.chat_id from public.family_message_chats c
    where c.thread_id = new.thread_id and c.kind = 'main';
  end if;
  return new;
end;
$$;

create trigger family_message_chats_seed_thread after insert on public.family_message_threads
for each row execute function private.zyra_family_chat_seed_for_thread();
create trigger family_message_chats_seed_attempt
after insert or update of status, started_at on public.journey_attempts
for each row execute function private.zyra_family_chat_seed_for_attempt();
create trigger family_messages_default_main before insert on public.family_messages
for each row execute function private.zyra_family_message_default_main();

-- Only current Circle membership can reach this branch. A Guardian's active
-- authority must belong to this Circle's Seeker, never just the counterpart.
create function private.zyra_family_chat_admission(p_chat uuid)
returns table (
  thread_id uuid, kind text, state text, other_first_name text,
  ended_at timestamptz, readable_from timestamptz
)
language sql stable security definer set search_path = ''
as $$
  select c.thread_id, c.kind,
    case when a.status = 'ended' then 'past' else 'current' end,
    case when a.end_reason is distinct from 'safety_concern'
      and (a.status <> 'ended' or member.member_role = 'guardian'
        or public.zyra_can_view_profile(other.id)) then other.first_name end,
    a.ended_at, member.readable_from
  from public.family_message_chats c
  join public.family_message_threads t on t.id = c.thread_id
  join public.family_message_memberships member
    on member.thread_id = t.id and member.user_id = (select auth.uid()) and member.left_at is null
  left join public.wali_links link
    on link.seeker_id = t.seeker_id and link.wali_id = member.user_id and link.status = 'active'
  left join public.journey_attempts a on a.id = c.attempt_id
  left join public.matches m on m.id = a.match_id
  left join public.profiles other on other.id =
    case when t.seeker_id = m.seeker_a_id then m.seeker_b_id else m.seeker_a_id end
  left join private.zyra_ended_journey_visibility ended on ended.attempt_id = a.id
  where c.id = p_chat
    and (c.kind = 'main' or (
      a.started_at is not null
      and t.seeker_id in (m.seeker_a_id, m.seeker_b_id)
      and other.id is not null
      and not exists (
        select 1 from private.zyra_account_deleted_matches d where d.match_id = m.id
      )
      and not exists (
        select 1 from public.profile_blocks b
        where (b.blocker_id = t.seeker_id and b.blocked_id = other.id)
           or (b.blocker_id = other.id and b.blocked_id = t.seeker_id)
           or (b.blocker_id = member.user_id and b.blocked_id in (t.seeker_id, other.id))
           or (b.blocked_id = member.user_id and b.blocker_id in (t.seeker_id, other.id))
      )
      and (
        (a.status = 'active' and (
          member.user_id = t.seeker_id or link.is_main is true or exists (
            select 1 from public.journey_guardian_assignments assignment
            where assignment.attempt_id = a.id and assignment.seeker_id = t.seeker_id
              and assignment.wali_link_id = link.id and assignment.revoked_at is null
              and assignment.granted_at >= link.active_since
          )
        )) or (
          a.status = 'ended'
          and ((t.seeker_id = ended.seeker_a_id and ended.seeker_a_visible)
            or (t.seeker_id = ended.seeker_b_id and ended.seeker_b_visible))
          and (a.end_reason is distinct from 'safety_concern' or a.ended_by = member.user_id)
          and (member.user_id = t.seeker_id or exists (
            select 1 from public.guardian_journey_history_consents consent
            where consent.wali_link_id = link.id
              and consent.guardian_link_authority_id = link.guardian_link_authority_id
          ))
        )
      )
    ));
$$;

create function private.zyra_family_chat_message_visible(p_chat uuid, p_created_at timestamptz)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from private.zyra_family_chat_admission(p_chat) admitted
    where p_created_at >= admitted.readable_from
  );
$$;

revoke all on function private.zyra_family_chat_seed_for_thread(),
  private.zyra_family_chat_seed_for_attempt(), private.zyra_family_message_default_main(),
  private.zyra_family_chat_admission(uuid), private.zyra_family_chat_message_visible(uuid,timestamptz)
  from public, anon, authenticated, service_role;
grant execute on function private.zyra_family_chat_message_visible(uuid,timestamptz) to authenticated;

alter policy family_messages_active_epoch_read on public.family_messages
using (private.zyra_family_chat_message_visible(chat_id, created_at));

create function public.zyra_family_message_chats(p_thread_id uuid)
returns table (
  chat_id uuid, kind text, state text, other_first_name text,
  last_message_at timestamptz, ended_at timestamptz, unread_count bigint,
  muted boolean, circle_muted boolean, counts_toward_total boolean
)
language sql stable security definer set search_path = ''
as $$
  select c.id, admitted.kind, admitted.state, admitted.other_first_name,
    messages.last_message_at, admitted.ended_at, messages.unread_count,
    local.muted_at is not null, circle.muted_at is not null,
    local.muted_at is null and circle.muted_at is null
  from public.family_message_chats c
  cross join lateral private.zyra_family_chat_admission(c.id) admitted
  left join public.family_message_chat_state local
    on local.chat_id = c.id and local.user_id = (select auth.uid())
  left join public.family_message_participant_state circle
    on circle.thread_id = c.thread_id and circle.user_id = (select auth.uid())
  cross join lateral (
    select max(msg.created_at) as last_message_at,
      count(*) filter (
        where msg.sender_id is distinct from (select auth.uid())
          and msg.created_at > coalesce(greatest(local.last_read_at, circle.last_read_at), '-infinity'::timestamptz)
      ) as unread_count
    from public.family_messages msg
    where msg.chat_id = c.id and msg.kind = 'message' and msg.created_at >= admitted.readable_from
  ) messages
  where c.thread_id = p_thread_id;
$$;

comment on function public.zyra_family_message_chats(uuid) is
  'Raw counts include muted arrivals. counts_toward_total is current attention eligibility, not delivery history; visible Circle totals exclude individually muted chats.';

create function public.zyra_mark_family_chat_read(p_chat_id uuid)
returns void language plpgsql security definer set search_path = ''
as $$
declare v_me uuid := (select auth.uid());
begin
  if not exists (select 1 from private.zyra_family_chat_admission(p_chat_id)) then
    raise exception 'family_chat_not_found';
  end if;
  insert into public.family_message_chat_state as chat_state (chat_id, user_id, last_read_at)
  values (p_chat_id, v_me, clock_timestamp())
  on conflict (chat_id, user_id) do update
    set last_read_at = greatest(chat_state.last_read_at, excluded.last_read_at);
end;
$$;

create function public.zyra_set_family_chat_muted(p_chat_id uuid, p_muted boolean)
returns void language plpgsql security definer set search_path = ''
as $$
declare v_me uuid := (select auth.uid());
begin
  if not exists (select 1 from private.zyra_family_chat_admission(p_chat_id)) then
    raise exception 'family_chat_not_found';
  end if;
  insert into public.family_message_chat_state (chat_id, user_id, muted_at)
  values (p_chat_id, v_me, case when p_muted then clock_timestamp() end)
  on conflict (chat_id, user_id) do update set muted_at = excluded.muted_at;
end;
$$;

revoke all on function public.zyra_family_message_chats(uuid),
  public.zyra_mark_family_chat_read(uuid), public.zyra_set_family_chat_muted(uuid,boolean)
  from public, anon;
grant execute on function public.zyra_family_message_chats(uuid),
  public.zyra_mark_family_chat_read(uuid), public.zyra_set_family_chat_muted(uuid,boolean)
  to authenticated, service_role;


-- Old transcript RPCs have no chat argument. Keep them on Main and preserve
-- their result shape, caller scope and grants. The exact transcript can be
-- read by chat_id via the same authenticated table SELECT, under chat RLS.


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
  join public.family_message_chats chat on chat.id = message.chat_id and chat.kind = 'main'
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

create or replace function public.zyra_family_messages_v2(
  p_thread uuid,
  p_before timestamptz default null,
  p_limit integer default 50
) returns table (
  message_id uuid,
  sender_id uuid,
  sender_first_name text,
  sender_relationship text,
  sender_role_label text,
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
      when sender_membership.member_role = 'guardian'
        and sender_membership.left_at is not null
        and not exists (
          select 1
          from public.family_message_memberships current_member
          where current_member.thread_id = message.thread_id
            and current_member.user_id = message.sender_id
            and current_member.left_at is null
        ) then 'Former Guardian'
      else sender.first_name
    end,
    case
      when sender_membership.member_role = 'guardian'
        then sender_link.relationship
      else null
    end,
    case
      when message.sender_id is null then null
      when sender_membership.member_role = 'seeker' then 'Seeker'
      when sender_membership.member_role = 'guardian'
        and sender_membership.left_at is not null
        and not exists (
          select 1
          from public.family_message_memberships current_member
          where current_member.thread_id = message.thread_id
            and current_member.user_id = message.sender_id
            and current_member.left_at is null
        ) then 'Former Guardian'
      when sender_membership.member_role = 'guardian'
        and coalesce(sender_link.is_main, false) then 'Main Guardian'
      when sender_membership.member_role = 'guardian'
        then 'Additional Guardian'
      else null
    end,
    message.kind,
    message.body,
    message.created_at
  from public.family_messages message
  join public.family_message_chats chat on chat.id = message.chat_id and chat.kind = 'main'
  join public.family_message_threads thread
    on thread.id = message.thread_id
  join public.family_message_memberships membership
    on membership.thread_id = message.thread_id
   and membership.user_id = (select auth.uid())
   and membership.left_at is null
  left join public.profiles sender
    on sender.id = message.sender_id
  left join lateral (
    select sender_epoch.member_role, sender_epoch.left_at
    from public.family_message_memberships sender_epoch
    where sender_epoch.thread_id = message.thread_id
      and sender_epoch.user_id = message.sender_id
    order by (sender_epoch.left_at is null) desc, sender_epoch.joined_at desc
    limit 1
  ) sender_membership on true
  left join lateral (
    select link.relationship, link.is_main
    from public.wali_links link
    where link.seeker_id = thread.seeker_id
      and link.wali_id = message.sender_id
    order by (link.status = 'active') desc,
      link.active_since desc nulls last
    limit 1
  ) sender_link on true
  where message.thread_id = p_thread
    and message.created_at >= membership.readable_from
    and (p_before is null or message.created_at < p_before)
  order by message.created_at desc, message.id desc
  limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;

create or replace function public.zyra_family_messages_v3(
  p_thread uuid,
  p_before timestamptz default null,
  p_limit integer default 50
) returns table (
  message_id uuid,
  sender_id uuid,
  sender_first_name text,
  sender_relationship text,
  sender_role_label text,
  kind text,
  body text,
  created_at timestamptz,
  read_by jsonb,
  unread_for_me boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    message.id,
    message.sender_id,
    case
      when message.sender_id is null then 'Deleted member'
      when sender_membership.member_role = 'guardian'
        and sender_membership.left_at is not null
        and not exists (
          select 1
          from public.family_message_memberships current_member
          where current_member.thread_id = message.thread_id
            and current_member.user_id = message.sender_id
            and current_member.left_at is null
        ) then 'Former Guardian'
      else sender.first_name
    end,
    case
      when sender_membership.member_role = 'guardian'
        then sender_link.relationship
      else null
    end,
    case
      when message.sender_id is null then null
      when sender_membership.member_role = 'seeker' then 'Seeker'
      when sender_membership.member_role = 'guardian'
        and sender_membership.left_at is not null
        and not exists (
          select 1
          from public.family_message_memberships current_member
          where current_member.thread_id = message.thread_id
            and current_member.user_id = message.sender_id
            and current_member.left_at is null
        ) then 'Former Guardian'
      when sender_membership.member_role = 'guardian'
        and coalesce(sender_link.is_main, false) then 'Main Guardian'
      when sender_membership.member_role = 'guardian'
        then 'Additional Guardian'
      else null
    end,
    message.kind,
    message.body,
    message.created_at,
    case
      when message.sender_id = (select auth.uid()) then coalesce((
        select jsonb_agg(
          jsonb_build_object(
            'user_id', reader.user_id,
            'first_name', reader_profile.first_name,
            'role_label', case
              when reader.member_role = 'seeker' then 'Seeker'
              when coalesce(reader_link.is_main, false) then 'Main Guardian'
              else 'Additional Guardian'
            end,
            'read_at', greatest(reader_state.last_read_at, reader_chat.last_read_at)
          ) order by greatest(reader_state.last_read_at, reader_chat.last_read_at), reader.user_id
        )
        from public.family_message_memberships reader
        left join public.family_message_participant_state reader_state
          on reader_state.thread_id = reader.thread_id
         and reader_state.user_id = reader.user_id
        left join public.family_message_chat_state reader_chat
          on reader_chat.chat_id = message.chat_id and reader_chat.user_id = reader.user_id
        join public.profiles reader_profile on reader_profile.id = reader.user_id
        left join public.wali_links reader_link
          on reader_link.seeker_id = thread.seeker_id
         and reader_link.wali_id = reader.user_id
         and reader_link.status = 'active'
        where reader.thread_id = message.thread_id
          and reader.left_at is null
          and reader.user_id <> message.sender_id
          and message.created_at >= reader.readable_from
          and greatest(reader_state.last_read_at, reader_chat.last_read_at) >= message.created_at
      ), '[]'::jsonb)
      else '[]'::jsonb
    end,
    message.kind = 'message' and message.sender_id is distinct from (select auth.uid())
      and message.created_at > coalesce(
        greatest(caller_state.last_read_at, caller_chat.last_read_at),
        '-infinity'::timestamptz
      )
  from public.family_messages message
  join public.family_message_chats chat on chat.id = message.chat_id and chat.kind = 'main'
  join public.family_message_threads thread
    on thread.id = message.thread_id
  join public.family_message_memberships membership
    on membership.thread_id = message.thread_id
   and membership.user_id = (select auth.uid())
   and membership.left_at is null
  left join public.family_message_participant_state caller_state
    on caller_state.thread_id = message.thread_id
   and caller_state.user_id = (select auth.uid())
  left join public.family_message_chat_state caller_chat
    on caller_chat.chat_id = message.chat_id and caller_chat.user_id = (select auth.uid())
  left join public.profiles sender on sender.id = message.sender_id
  left join lateral (
    select sender_epoch.member_role, sender_epoch.left_at
    from public.family_message_memberships sender_epoch
    where sender_epoch.thread_id = message.thread_id
      and sender_epoch.user_id = message.sender_id
    order by (sender_epoch.left_at is null) desc, sender_epoch.joined_at desc
    limit 1
  ) sender_membership on true
  left join lateral (
    select link.relationship, link.is_main
    from public.wali_links link
    where link.seeker_id = thread.seeker_id
      and link.wali_id = message.sender_id
    order by (link.status = 'active') desc,
      link.active_since desc nulls last
    limit 1
  ) sender_link on true
  where message.thread_id = p_thread
    and message.created_at >= membership.readable_from
    and (p_before is null or message.created_at < p_before)
  order by message.created_at desc, message.id desc
  limit least(greatest(coalesce(p_limit, 50), 1), 100);
$$;

create or replace function public.zyra_family_message_circles()
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
    latest.body, latest.created_at,
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
  join public.family_message_chats chat on chat.thread_id = thread.id and chat.kind = 'main'
  left join lateral (
    select message.body, message.created_at from public.family_messages message
    where message.chat_id = chat.id
      and message.created_at >= me.readable_from
    order by message.created_at desc, message.id desc limit 1
  ) latest on true
  left join public.family_message_participant_state state
    on state.thread_id = thread.id and state.user_id = (select auth.uid())
  left join public.family_message_chat_state chat_state
    on chat_state.chat_id = chat.id and chat_state.user_id = (select auth.uid())
  left join public.family_messages unread
    on unread.chat_id = chat.id
   and unread.sender_id is distinct from (select auth.uid())
   and unread.kind = 'message'
   and unread.created_at >= me.readable_from
   and unread.created_at > coalesce(greatest(state.last_read_at, chat_state.last_read_at), '-infinity'::timestamptz)
  group by thread.id, profile.first_name, latest.body, latest.created_at, state.muted_at,
    me.readable_from
  order by latest.created_at desc nulls last, thread.created_at desc;
$$;

create or replace function public.zyra_report_family_message(
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
    and message.created_at >= membership.readable_from
    and private.zyra_family_chat_message_visible(message.chat_id, message.created_at);
  if v_reported is null then raise exception 'message_not_reportable'; end if;
  insert into public.family_message_reports
    (thread_id, message_id, reporter_id, reported_id, reason)
  values (p_thread, p_message, v_me, v_reported, p_reason)
  returning id into v_id;
  return v_id;
end;
$$;

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
        where candidate.chat_id = message.chat_id
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

create or replace function public.zyra_mark_family_messages_read(p_thread uuid)
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
  insert into public.family_message_participant_state as circle_state
    (thread_id, user_id, last_read_at)
  values (p_thread, v_me, clock_timestamp())
  on conflict (thread_id, user_id) do update
    set last_read_at = greatest(circle_state.last_read_at, excluded.last_read_at);
end;
$$;

create or replace function public.zyra_send_family_message(p_thread uuid, p_body text, p_chat_id uuid)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_seeker uuid;
  v_body text := btrim(coalesce(p_body, ''));
  v_id uuid;
  v_chat uuid;
  v_kind text;
  v_now timestamptz;
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
  select chat.id, admitted.kind into v_chat, v_kind
  from public.family_message_chats chat
  cross join lateral private.zyra_family_chat_admission(chat.id) admitted
  where chat.thread_id = p_thread
    and ((p_chat_id is null and chat.kind = 'main') or chat.id = p_chat_id);
  if v_chat is null then raise exception 'family_chat_not_found'; end if;
  if v_kind <> 'main' then raise exception 'family_journey_send_unavailable'; end if;
  if not public.zyra_family_message_circle_can_send(v_seeker) then
    raise exception 'family_message_read_only';
  end if;
  v_now := clock_timestamp();
  if (select count(*) from public.family_messages message
      where message.sender_id = v_me and message.kind = 'message'
        and message.created_at > v_now - interval '1 minute') >= 10 then
    raise exception 'family_message_rate_minute';
  end if;
  if (select count(*) from public.family_messages message
      where message.sender_id = v_me and message.kind = 'message'
        and message.created_at > v_now - interval '1 hour') >= 60 then
    raise exception 'family_message_rate_hour';
  end if;
  insert into public.family_messages (thread_id, chat_id, sender_id, body, created_at)
  values (p_thread, v_chat, v_me, v_body, v_now) returning id into v_id;
  update public.family_message_threads set last_message_at = v_now where id = p_thread;
  insert into public.family_message_chat_state as chat_state (chat_id, user_id, last_read_at)
  values (v_chat, v_me, v_now)
  on conflict (chat_id, user_id) do update
    set last_read_at = greatest(chat_state.last_read_at, excluded.last_read_at);
  return v_id;
end;
$$;

-- Keep both named signatures resolvable without a competing default.
create or replace function public.zyra_send_family_message(p_thread uuid, p_body text)
returns uuid language sql security definer set search_path = ''
as $$
  select public.zyra_send_family_message(p_thread, p_body, null::uuid);
$$;

revoke all on function public.zyra_send_family_message(uuid,text,uuid) from public, anon;
grant execute on function public.zyra_send_family_message(uuid,text,uuid)
  to authenticated, service_role;

-- Account deletion recomputes the thread timestamp for the legacy Main
-- surface. Keep that recalculation from using a private Journey timestamp.
do $scope_deleted_sender$
declare
  definition text := pg_get_functiondef(
    'private.zyra_remove_departing_profile()'::regprocedure
  );
  original constant text := 'where msg.thread_id = thread.id and msg.sender_id is distinct from old.id';
  scoped constant text := original || '
      and exists (select 1 from public.family_message_chats c
                  where c.id = msg.chat_id and c.kind = ''main'')';
begin
  if length(definition) - length(replace(definition, original, '')) <> length(original) then
    raise exception 'Circle timestamp recalculation changed; review Main scoping';
  end if;
  execute replace(definition, original, scoped);
end;
$scope_deleted_sender$;

commit;
