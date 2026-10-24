-- Give Guardian Circle messages enough identity context to distinguish the
-- Seeker, Main Guardian and Additional Guardians without exposing any profile
-- fields beyond what every current Circle member already knows through the
-- active Guardian relationship.
--
-- This is a versioned read RPC so already-shipped clients can continue using
-- zyra_family_messages unchanged.
create function public.zyra_family_messages_v2(
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

revoke all on function public.zyra_family_messages_v2(
  uuid, timestamptz, integer
) from public, anon;
grant execute on function public.zyra_family_messages_v2(
  uuid, timestamptz, integer
) to authenticated;

comment on function public.zyra_family_messages_v2(
  uuid, timestamptz, integer
) is
  'Current Circle members can read message sender name, Guardian relationship '
  'code and current Circle role. Caller membership and readable_from remain '
  'the authority boundary.';
