-- Current Guardian Circle members only. The function is deliberately scoped
-- by the caller's own active membership before it returns any names; knowing a
-- thread UUID is not enough to enumerate its people.
create function public.zyra_family_message_participants(p_thread uuid)
returns table (
  user_id uuid,
  first_name text,
  member_role text,
  is_main_guardian boolean,
  is_current_user boolean
)
language sql stable security definer set search_path = ''
as $$
  select
    member.user_id,
    profile.first_name,
    member.member_role,
    coalesce(link.is_main, false),
    member.user_id = (select auth.uid())
  from public.family_message_memberships member
  join public.family_message_threads thread
    on thread.id = member.thread_id
  join public.profiles profile
    on profile.id = member.user_id
  join public.family_message_memberships caller
    on caller.thread_id = member.thread_id
   and caller.user_id = (select auth.uid())
   and caller.left_at is null
  left join public.wali_links link
    on member.member_role = 'guardian'
   and link.seeker_id = thread.seeker_id
   and link.wali_id = member.user_id
   and link.status = 'active'
  where member.thread_id = p_thread
    and member.left_at is null
  order by
    case member.member_role when 'seeker' then 0 else 1 end,
    coalesce(link.is_main, false) desc,
    member.joined_at,
    member.user_id;
$$;

revoke all on function public.zyra_family_message_participants(uuid)
  from public, anon;
grant execute on function public.zyra_family_message_participants(uuid)
  to authenticated;

comment on function public.zyra_family_message_participants(uuid) is
  'Names and roles of current members, visible only to another current member of the same Guardian Circle.';
