-- Truthful read receipts for both messaging surfaces.
--
-- Journey chat is a two-Seeker conversation, so the existing messages.read_at
-- column can represent the other Seeker's read. Guardian Circle is a group,
-- so its existing per-participant last_read_at state is projected as a list.

create or replace function public.zyra_mark_journey_messages_read(
  p_conversation uuid
) returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_caller uuid := (select auth.uid());
  v_now timestamptz := clock_timestamp();
begin
  if v_caller is null then
    raise exception 'authentication_required';
  end if;

  if not exists (
    select 1
    from public.conversations conversation
    join public.matches match on match.id = conversation.match_id
    where conversation.id = p_conversation
      and v_caller in (match.seeker_a_id, match.seeker_b_id)
  ) then
    raise exception 'conversation_not_available';
  end if;

  update public.messages message
  set read_at = coalesce(message.read_at, v_now)
  where message.conversation_id = p_conversation
    and message.sender_id <> v_caller
    and message.read_at is null;

  return v_now;
end;
$$;

revoke all on function public.zyra_mark_journey_messages_read(uuid)
  from public, anon;
grant execute on function public.zyra_mark_journey_messages_read(uuid)
  to authenticated;

comment on function public.zyra_mark_journey_messages_read(uuid) is
  'Marks only the other Seeker''s messages read after proving the caller is '
  'one of the two Seekers in the conversation. Guardians cannot write a '
  'Seeker read receipt.';

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
            'read_at', reader_state.last_read_at
          ) order by reader_state.last_read_at, reader.user_id
        )
        from public.family_message_memberships reader
        join public.family_message_participant_state reader_state
          on reader_state.thread_id = reader.thread_id
         and reader_state.user_id = reader.user_id
        join public.profiles reader_profile on reader_profile.id = reader.user_id
        left join public.wali_links reader_link
          on reader_link.seeker_id = thread.seeker_id
         and reader_link.wali_id = reader.user_id
         and reader_link.status = 'active'
        where reader.thread_id = message.thread_id
          and reader.left_at is null
          and reader.user_id <> message.sender_id
          and reader_state.last_read_at >= message.created_at
      ), '[]'::jsonb)
      else '[]'::jsonb
    end,
    message.sender_id is distinct from (select auth.uid())
      and message.created_at > coalesce(
        caller_state.last_read_at,
        '-infinity'::timestamptz
      )
  from public.family_messages message
  join public.family_message_threads thread
    on thread.id = message.thread_id
  join public.family_message_memberships membership
    on membership.thread_id = message.thread_id
   and membership.user_id = (select auth.uid())
   and membership.left_at is null
  left join public.family_message_participant_state caller_state
    on caller_state.thread_id = message.thread_id
   and caller_state.user_id = (select auth.uid())
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

revoke all on function public.zyra_family_messages_v3(
  uuid, timestamptz, integer
) from public, anon;
grant execute on function public.zyra_family_messages_v3(
  uuid, timestamptz, integer
) to authenticated;

comment on function public.zyra_family_messages_v3(
  uuid, timestamptz, integer
) is
  'Versioned Guardian Circle history with sender identity, caller-unread '
  'state and read receipts visible only on messages sent by the caller. '
  'Current membership and readable_from remain the authority boundary.';
