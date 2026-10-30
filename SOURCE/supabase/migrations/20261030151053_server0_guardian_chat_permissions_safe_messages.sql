-- SERVER 0 V2 / DOC-ZYRA-0329 / OA-ZYRA-317 / OA-ZYRA-319.
-- Local proof only; production requires a separate exact-payload Founder GO.

begin;

create table if not exists public.guardian_journey_permissions (
  wali_link_id uuid not null references public.wali_links(id) on delete cascade,
  match_id uuid not null references public.matches(id) on delete cascade,
  can_view boolean not null default true,
  can_chat boolean not null default true,
  updated_by uuid not null references public.profiles(id) on delete cascade,
  updated_at timestamptz not null default now(),
  primary key (wali_link_id, match_id),
  constraint guardian_journey_chat_requires_view
    check (can_view or not can_chat)
);

alter table public.guardian_journey_permissions enable row level security;
revoke all on public.guardian_journey_permissions
  from public, anon, authenticated;

create or replace function public.zyra_set_guardian_journey_permission(
  p_wali_link_id uuid,
  p_match_id uuid,
  p_can_view boolean,
  p_can_chat boolean
)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_caller uuid := (select auth.uid());
  v_link public.wali_links%rowtype;
begin
  select * into v_link
  from public.wali_links link
  where link.id = p_wali_link_id
  for update;
  if not found or v_link.seeker_id <> v_caller or v_link.status <> 'active' then
    raise exception 'guardian_link_not_available';
  end if;
  if v_link.is_main then raise exception 'main_guardian_access_required'; end if;
  if p_can_chat and not p_can_view then
    raise exception 'guardian_chat_requires_view';
  end if;
  if not exists (
    select 1 from public.matches match
    where match.id = p_match_id
      and match.status = 'active'
      and v_caller in (match.seeker_a_id, match.seeker_b_id)
  ) then
    raise exception 'active_journey_not_available';
  end if;

  perform * from public.zyra_guardian_journey_access(v_link.wali_id,
    (select a.id from public.journey_attempts a where a.match_id = p_match_id
     order by a.attempt_number desc limit 1), p_can_view);

  insert into public.guardian_journey_permissions (
    wali_link_id, match_id, can_view, can_chat, updated_by, updated_at
  ) values (
    p_wali_link_id, p_match_id, p_can_view, p_can_chat, v_caller, now()
  )
  on conflict (wali_link_id, match_id) do update
    set can_view = excluded.can_view,
        can_chat = excluded.can_chat,
        updated_by = excluded.updated_by,
        updated_at = excluded.updated_at;
end;
$$;

revoke all on function public.zyra_set_guardian_journey_permission(
  uuid,uuid,boolean,boolean
) from public, anon;
grant execute on function public.zyra_set_guardian_journey_permission(
  uuid,uuid,boolean,boolean
) to authenticated;

create or replace function public.zyra_guardian_journey_permissions(
  p_wali_link_id uuid
)
returns table(match_id uuid, can_view boolean, can_chat boolean)
language sql stable security definer set search_path = ''
as $$
  select
    match.id,
    case when link.is_main then true else coalesce(permission.can_view, true) end,
    case when link.is_main then true else coalesce(permission.can_chat, true) end
  from public.wali_links link
  join public.matches match
    on link.seeker_id in (match.seeker_a_id, match.seeker_b_id)
   and match.status = 'active'
  left join public.guardian_journey_permissions permission
    on permission.wali_link_id = link.id and permission.match_id = match.id
  where link.id = p_wali_link_id
    and link.status = 'active'
    and (link.seeker_id = (select auth.uid())
      or link.wali_id = (select auth.uid()));
$$;

revoke all on function public.zyra_guardian_journey_permissions(uuid)
  from public, anon;
grant execute on function public.zyra_guardian_journey_permissions(uuid)
  to authenticated;

create or replace function public.zyra_guardian_journey_chat_access(
  p_guardian uuid,
  p_attempt uuid default null,
  p_enabled boolean default null,
  p_chat_enabled boolean default null
)
returns table (
  attempt_id uuid,
  match_id uuid,
  counterpart_first_name text,
  included boolean,
  can_change boolean,
  guardian_is_main boolean,
  chat_available boolean,
  chat_enabled boolean
)
language plpgsql security definer set search_path = ''
as $$
declare
  v_caller uuid := (select auth.uid());
  v_link_id uuid;
  v_is_main boolean;
  v_match_id uuid;
begin
  if v_caller is null then raise exception 'not_signed_in'; end if;
  if p_guardian is null then raise exception 'guardian_required'; end if;
  if p_attempt is null and (p_enabled is not null or p_chat_enabled is not null) then
    raise exception 'attempt_required_for_change';
  end if;

  select link.id, link.is_main into v_link_id, v_is_main
  from public.wali_links link
  where link.seeker_id = v_caller
    and link.wali_id = p_guardian
    and link.status = 'active';
  if not found then raise exception 'active_guardian_link_not_found'; end if;

  if p_attempt is not null then
    select attempt.match_id into v_match_id
    from public.journey_attempts attempt
    join public.matches match on match.id = attempt.match_id
    where attempt.id = p_attempt
      and attempt.status = 'active'
      and v_caller in (match.seeker_a_id, match.seeker_b_id);
    if v_match_id is null then raise exception 'active_owned_journey_not_found'; end if;
    if v_is_main and (p_enabled is not null or p_chat_enabled is not null) then
      raise exception 'main_guardian_access_required';
    end if;

    perform * from public.zyra_guardian_journey_access(p_guardian, p_attempt, p_enabled);

    insert into public.guardian_journey_permissions (
      wali_link_id, match_id, can_view, can_chat, updated_by, updated_at
    ) values (
      v_link_id,
      v_match_id,
      coalesce(p_enabled, true),
      case
        when p_enabled is false then false
        else coalesce(p_chat_enabled, true)
      end,
      v_caller,
      now()
    )
    on conflict on constraint guardian_journey_permissions_pkey do update
      set can_view = coalesce(p_enabled, guardian_journey_permissions.can_view),
          can_chat = case
            when coalesce(p_enabled, guardian_journey_permissions.can_view) is false
              then false
            else coalesce(
              p_chat_enabled,
              guardian_journey_permissions.can_chat
            )
          end,
          updated_by = v_caller,
          updated_at = now();
  end if;

  return query
  select
    attempt.id,
    attempt.match_id,
    counterpart.first_name,
    case when v_is_main then true else coalesce(permission.can_view, true) end,
    not v_is_main,
    v_is_main,
    true,
    case when v_is_main then true else coalesce(permission.can_chat, true) end
  from public.journey_attempts attempt
  join public.matches match on match.id = attempt.match_id
  join public.profiles counterpart on counterpart.id = case
    when match.seeker_a_id = v_caller then match.seeker_b_id
    else match.seeker_a_id
  end
  left join public.guardian_journey_permissions permission
    on permission.wali_link_id = v_link_id
   and permission.match_id = attempt.match_id
  where attempt.status = 'active'
    and v_caller in (match.seeker_a_id, match.seeker_b_id)
  order by attempt.started_at desc nulls last, attempt.created_at desc, attempt.id;
end;
$$;

revoke all on function public.zyra_guardian_journey_chat_access(
  uuid,uuid,boolean,boolean
) from public, anon;
grant execute on function public.zyra_guardian_journey_chat_access(
  uuid,uuid,boolean,boolean
) to authenticated;

-- Keep the six-column participation views and the three-argument access RPC
-- unchanged for F02. A caller-bound helper reads lifecycle/stage behind RLS;
-- it never grants access to a different attempt through the pair envelope.
create function public.zyra_may_send_journey_message(p_conversation uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1
    from public.conversations c
    join public.journey_attempts a on a.id = c.attempt_id
    join public.matches m on m.id = a.match_id and m.id = c.match_id
    join public.zyra_attempt_participant_rows r
      on r.attempt_id = a.id and r.match_id = m.id
     and r.user_id = (select auth.uid())
    where c.id = p_conversation
      and c.status = 'active' and a.status = 'active'
      and m.status = 'active' and a.journey_stage = 'conversation'
      and not exists (select 1 from public.journey_attempts newer
                      where newer.match_id = m.id
                        and newer.attempt_number > a.attempt_number)
      and not exists (
        select 1 from public.profile_blocks b
        where (b.blocker_id = m.seeker_a_id and b.blocked_id = m.seeker_b_id)
           or (b.blocker_id = m.seeker_b_id and b.blocked_id = m.seeker_a_id)
           or (b.blocker_id = (select auth.uid())
               and b.blocked_id in (m.seeker_a_id, m.seeker_b_id))
           or (b.blocked_id = (select auth.uid())
               and b.blocker_id in (m.seeker_a_id, m.seeker_b_id))
      )
      and (
        r.role = 'seeker'
        or (
          r.role = 'guardian'
          and public.zyra_has_paid_role((select auth.uid()), 'guardian')
          and exists (
            select 1 from public.wali_links w
            left join public.guardian_journey_permissions permission
              on permission.wali_link_id = w.id and permission.match_id = m.id
            where w.wali_id = (select auth.uid()) and w.status = 'active'
              and w.seeker_id in (m.seeker_a_id, m.seeker_b_id)
              and (w.is_main or (coalesce(permission.can_view, true)
                                 and coalesce(permission.can_chat, true)))
              and (w.is_main or exists (
                select 1 from public.journey_guardian_assignments assignment
                where assignment.attempt_id = a.id and assignment.wali_link_id = w.id
                  and assignment.seeker_id = w.seeker_id
                  and assignment.revoked_at is null
                  and assignment.granted_at >= w.active_since
              ))
          )
        )
      )
  );
$$;
revoke all on function public.zyra_may_send_journey_message(uuid) from public, anon;
grant execute on function public.zyra_may_send_journey_message(uuid) to authenticated;

drop policy messages_insert on public.messages;
create policy messages_insert on public.messages for insert to authenticated
with check (
  sender_id = (select auth.uid())
  and public.zyra_may_send_journey_message(conversation_id)
);

commit;
