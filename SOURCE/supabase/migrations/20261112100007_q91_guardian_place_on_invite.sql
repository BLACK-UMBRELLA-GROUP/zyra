-- Q91 / DOC-ZYRA-0472 / OA-ZYRA-317 / LOCK 19 V11.
-- Throws away no existing link history. Apply only after SERVER 0 and line 85.

begin;

alter table public.wali_links
  add column place_kind text check (place_kind in ('basic_place', 'guardian_one')),
  add column invitation_id uuid references public.wali_invites(id) on delete set null;

create index wali_links_invitation_id
  on public.wali_links(invitation_id) where invitation_id is not null;

comment on column public.wali_links.place_kind is
  'Guardian place at acceptance of a Seeker-sent legacy invitation. '
  'Current eligibility always uses verified entitlements. Legacy links may be null.';
comment on column public.wali_links.invitation_id is
  'Seeker-sent legacy invitation that recorded this place. '
  'Null for links without recorded provenance or when the invitation is removed.';

create table private.zyra_guardian_invite_accept_guards (
  seeker_id uuid primary key references public.profiles(id) on delete cascade,
  revision bigint not null
);

alter table private.zyra_guardian_invite_accept_guards enable row level security;
revoke all on private.zyra_guardian_invite_accept_guards
  from public, anon, authenticated, service_role;

create function private.zyra_guardian_invite_capacity(
  p_seeker uuid,
  p_exclude_guardian uuid,
  p_at timestamptz
)
returns table(active_count integer, basic_place_free boolean)
language sql
stable
set search_path = ''
as $function$
  select count(*)::integer,
         coalesce(bool_and(public.zyra_has_paid_role(wl.wali_id, 'guardian', p_at)), true)
  from public.wali_links wl
  where wl.seeker_id = p_seeker
    and wl.status = 'active'
    and wl.wali_id is distinct from p_exclude_guardian;
$function$;

revoke all on function private.zyra_guardian_invite_capacity(uuid, uuid, timestamptz)
  from public, anon, authenticated, service_role;

drop function public.preview_wali_invite(text);

create function public.preview_wali_invite(p_token text)
returns table(
  inviter_first_name text,
  inviter_role text,
  invite_status text,
  inviter_ward_count integer,
  seeker_plan text,
  basic_place_free boolean,
  needs_guardian_one boolean
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_invite public.wali_invites%rowtype;
  v_status text;
  v_viewer uuid := auth.uid();
  v_viewer_role text;
  v_inviter_name text;
  v_inviter_role text;
  v_is_seeker_one boolean;
  v_place_free boolean;
  v_needs_one boolean;
  v_at timestamptz := clock_timestamp();
begin
  select wi.* into v_invite
  from public.wali_invites wi
  where wi.token = upper(trim(p_token))
    and wi.source = 'legacy_code';
  if not found then return; end if;

  v_status := public.expire_wali_invite_if_due(v_invite);
  select p.first_name, p.role into v_inviter_name, v_inviter_role
  from public.profiles p
  where p.id = v_invite.inviter_id;

  if v_status = 'pending'
     and v_viewer is not null
     and v_viewer <> v_invite.inviter_id then
    select p.role into v_viewer_role
    from public.profiles p
    where p.id = v_viewer;

    -- A new bearer can preview before a profile exists. The notification
    -- marker refers to a profile, so record it only when that row exists.
    if found then
      update public.wali_invites
         set seen_by = v_viewer,
             seen_at = clock_timestamp()
       where id = v_invite.id
         and status = 'pending'
         and seen_by is null;

      if found then
        perform public.create_notification(
          v_viewer,
          'wali_invite_received',
          'Guardian invitation received',
          coalesce(v_inviter_name, 'Someone') || ' sent you a Guardian invitation.',
          null
        );
      end if;
    end if;

    if v_invite.inviter_role = 'seeker' and v_inviter_role = 'seeker'
       and (v_viewer_role is null or v_viewer_role = 'wali') then
      v_is_seeker_one := public.zyra_has_paid_role(v_invite.inviter_id, 'seeker', v_at);
      if v_is_seeker_one then
        v_place_free := true;
      else
        select capacity.basic_place_free into v_place_free
        from private.zyra_guardian_invite_capacity(v_invite.inviter_id, null, v_at) capacity;
      end if;
      v_needs_one := not v_place_free
        and not public.zyra_has_paid_role(v_viewer, 'guardian', v_at);
    end if;
  end if;

  return query
  select v_inviter_name,
         v_invite.inviter_role,
         v_status,
         (select count(distinct wl.seeker_id)::integer
          from public.wali_links wl
          where wl.wali_id = v_invite.inviter_id and wl.status = 'active'),
         case v_is_seeker_one when true then 'one' when false then 'basic' end,
         v_place_free,
         v_needs_one;
end;
$function$;

revoke execute on function public.preview_wali_invite(text) from public, anon;
grant execute on function public.preview_wali_invite(text) to authenticated, service_role;

create or replace function public.accept_wali_invite(
  p_token text,
  p_relationship text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_invite public.wali_invites%rowtype;
  v_accepter_id uuid := auth.uid();
  v_accepter_role text;
  v_inviter_role text;
  v_accepter_name text;
  v_seeker_id uuid;
  v_wali_id uuid;
  v_link_id uuid;
  v_relationship text;
  v_active_count integer;
  v_place_free boolean;
  v_place_kind text;
  v_guardian_one boolean;
  v_invitation_id uuid;
  v_at timestamptz;
begin
  if v_accepter_id is null then
    raise exception 'Not signed in';
  end if;

  if p_relationship is not null
     and p_relationship not in ('father','brother','grandfather','uncle',
                                'legal_guardian','family_representative','other') then
    raise exception 'Unknown relationship: %', p_relationship;
  end if;

  select wi.* into v_invite
  from public.wali_invites wi
  where wi.token = p_token and wi.status = 'pending' and wi.source = 'legacy_code'
  for update;
  if not found then
    raise exception 'Invite not found or already used';
  end if;

  -- This helper is the shared expiry predicate. On refusal its update rolls
  -- back with the exception. The preview and expiry sweep persist expiry.
  if public.expire_wali_invite_if_due(v_invite) <> 'pending' then
    raise exception 'invite_expired'
      using hint = 'This invite has expired. Ask for a new code.';
  end if;

  if v_invite.inviter_id = v_accepter_id then
    raise exception 'Cannot accept your own invite';
  end if;

  select p.role, p.first_name into v_accepter_role, v_accepter_name
  from public.profiles p where p.id = v_accepter_id;
  if v_accepter_role is null then
    raise exception 'Complete your profile before accepting an invite';
  end if;

  select p.role into v_inviter_role
  from public.profiles p where p.id = v_invite.inviter_id;
  if v_inviter_role is null then
    raise exception 'Invite is no longer valid';
  end if;
  if v_inviter_role is distinct from v_invite.inviter_role then
    raise exception 'invite_role_mismatch'
      using hint = 'This invite does not match the account that sent it. Ask them to send a new one.';
  end if;

  if v_inviter_role = 'seeker' then
    if v_accepter_role <> 'wali' then
      raise exception 'This invite is for a Wali account';
    end if;
    v_seeker_id := v_invite.inviter_id;
    v_wali_id := v_accepter_id;
  elsif v_inviter_role = 'wali' then
    if v_accepter_role <> 'seeker' then
      raise exception 'This invite is for a Seeker account';
    end if;
    v_seeker_id := v_accepter_id;
    v_wali_id := v_invite.inviter_id;
  else
    raise exception 'Invalid invite';
  end if;

  -- Serialize even when there are no link rows to lock. A write conflict
  -- also forces a stale repeatable-read transaction to retry.
  insert into private.zyra_guardian_invite_accept_guards as guard (seeker_id, revision)
  values (v_seeker_id, 1)
  on conflict (seeker_id) do update set revision = guard.revision + 1;

  perform wl.id
  from public.wali_links wl
  where wl.seeker_id = v_seeker_id and (wl.status = 'active' or wl.wali_id = v_wali_id)
  order by wl.id
  for update;

  if public.expire_wali_invite_if_due(v_invite) <> 'pending' then
    raise exception 'invite_expired'
      using hint = 'This invite has expired. Ask for a new code.';
  end if;

  if not public.zyra_can_guardian_link(v_seeker_id, v_wali_id) then
    raise exception 'romantic_edge_exists'
      using hint = 'These two people have a Journey together. A Guardian '
                   'relationship cannot be created over one. End the Journey '
                   'first if that is really what you both want.';
  end if;

  if v_inviter_role = 'seeker' then
    v_at := clock_timestamp();
    -- Re-accepting a code for the same pair reuses its link and consumes
    -- neither another total place nor another Basic place.
    select capacity.active_count, capacity.basic_place_free into v_active_count, v_place_free
    from private.zyra_guardian_invite_capacity(v_seeker_id, v_wali_id, v_at) capacity;

    if v_active_count >= 10 then
      raise exception 'guardian_capacity_exceeded';
    end if;
    v_guardian_one := public.zyra_has_paid_role(v_wali_id, 'guardian', v_at);
    if not v_guardian_one and not v_place_free
       and not public.zyra_has_paid_role(v_seeker_id, 'seeker', v_at) then
      raise exception 'needs_guardian_one';
    end if;
    v_place_kind := case when v_guardian_one then 'guardian_one' else 'basic_place' end;
    v_invitation_id := v_invite.id;
  end if;

  v_relationship := coalesce(p_relationship, v_invite.relationship);

  insert into public.wali_links as existing (
    seeker_id, wali_id, status, relationship, place_kind, invitation_id
  ) values (
    v_seeker_id, v_wali_id, 'active', v_relationship, v_place_kind, v_invitation_id
  )
  on conflict (seeker_id, wali_id) do update
    set status = 'active',
        relationship = coalesce(excluded.relationship, existing.relationship),
        place_kind = coalesce(excluded.place_kind, existing.place_kind),
        invitation_id = coalesce(excluded.invitation_id, existing.invitation_id)
  returning id into v_link_id;

  -- Linking extinguishes one-sided intent silently in both directions.
  delete from public.likes
   where (liker_id = v_seeker_id and liked_id = v_wali_id)
      or (liker_id = v_wali_id and liked_id = v_seeker_id);
  delete from public.saves
   where (saver_id = v_seeker_id and saved_id = v_wali_id)
      or (saver_id = v_wali_id and saved_id = v_seeker_id);
  delete from public.passes
   where (passer_id = v_seeker_id and passed_id = v_wali_id)
      or (passer_id = v_wali_id and passed_id = v_seeker_id);

  update public.wali_invites
     set status = 'accepted', accepted_at = now(), accepted_by = v_accepter_id
   where id = v_invite.id;

  perform public.create_notification(
    v_invite.inviter_id, 'wali_request', 'Wali Link Accepted',
    coalesce(v_accepter_name, 'Someone') || ' accepted your Wali link invite.', null
  );
  return v_link_id;
end;
$function$;

revoke execute on function public.accept_wali_invite(text, text) from public, anon;
grant execute on function public.accept_wali_invite(text, text) to authenticated, service_role;

commit;
