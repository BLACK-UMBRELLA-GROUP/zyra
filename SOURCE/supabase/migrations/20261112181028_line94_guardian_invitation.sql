-- ZYRA line 94 / DOC-ZYRA-0473 V2 / Q120, Q125 / OA-ZYRA-317.

begin;

alter table public.wali_invites
  add column issued_by_guardian_invitation_rpc boolean not null default false,
  add constraint wali_invites_guardian_invitation_duration check (
    not issued_by_guardian_invitation_rpc
    or (
      source = 'legacy_code'
      and inviter_role = 'seeker'
      and expires_at = created_at + interval '14 days'
    )
  );

create function public.zyra_create_guardian_invitation()
returns table(token text, expires_at timestamptz)
language plpgsql security definer set search_path = ''
as $$
declare
  v_seeker uuid := (select auth.uid());
  v_due public.wali_invites%rowtype;
  v_created_at timestamptz;
  v_active_count integer;
  v_pending_count integer;
  v_token text;
begin
  if v_seeker is null then raise exception 'not_signed_in'; end if;
  if not exists (
    select 1 from public.profiles p where p.id = v_seeker and p.role = 'seeker'
  ) then
    raise exception 'seeker_required';
  end if;

  -- Resolve old invitations in the same lock order as acceptance: invite
  -- rows before the Seeker guard. The stored deadline determines expiry.
  for v_due in
    select wi.* from public.wali_invites wi
    where wi.inviter_id = v_seeker and wi.source = 'legacy_code'
      and wi.status = 'pending' and wi.expires_at <= clock_timestamp()
    order by coalesce(wi.request_expires_at, wi.expires_at), wi.id
  loop
    perform public.expire_wali_invite_if_due(v_due);
  end loop;

  insert into private.zyra_guardian_invite_accept_guards as guard (seeker_id, revision)
  values (v_seeker, 1)
  on conflict (seeker_id) do update set revision = guard.revision + 1;

  v_created_at := clock_timestamp();
  select capacity.active_count into v_active_count
  from private.zyra_guardian_invite_capacity(v_seeker, null, v_created_at) capacity;
  select count(*) into v_pending_count from public.wali_invites wi
  where wi.inviter_id = v_seeker and wi.source = 'legacy_code'
    and wi.status = 'pending' and wi.expires_at > v_created_at;
  if v_active_count + v_pending_count >= 10 then
    raise exception 'guardian_limit';
  end if;

  loop
    v_token := private.zyra_generate_personal_code();
    insert into public.wali_invites as wi (
      token, inviter_id, inviter_role, created_at, expires_at,
      issued_by_guardian_invitation_rpc
    )
    values (
      v_token, v_seeker, 'seeker', v_created_at,
      v_created_at + interval '14 days', true
    )
    on conflict on constraint wali_invites_token_key do nothing
    returning wi.token, wi.expires_at into token, expires_at;
    exit when found;
  end loop;

  return next;
end;
$$;

revoke all on function public.zyra_create_guardian_invitation()
  from public, anon, authenticated, service_role;
grant execute on function public.zyra_create_guardian_invitation() to authenticated;

create or replace function public.zyra_expire_due_wali_invites()
returns table(expiring_count integer, expired_count integer)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := auth.uid();
  v_invite public.wali_invites%rowtype;
  v_deadline timestamptz;
  v_expiring integer := 0;
  v_expired integer := 0;
  v_label text;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;

  for v_invite in
    select wi.*
      from public.wali_invites wi
     where wi.inviter_id = v_me
       and wi.status = 'pending'
     order by coalesce(wi.request_expires_at, wi.expires_at), wi.id
  loop
    v_deadline := coalesce(v_invite.request_expires_at, v_invite.expires_at);
    if v_deadline < clock_timestamp() then
      if public.expire_wali_invite_if_due(v_invite) = 'expired' then
        v_expired := v_expired + 1;
      end if;
    elsif v_deadline <= clock_timestamp() + interval '2 days'
       and v_invite.expiring_notified_at is null then
      update public.wali_invites
         set expiring_notified_at = clock_timestamp()
       where id = v_invite.id
         and status = 'pending'
         and expiring_notified_at is null
       returning label into v_label;

      if found then
        v_expiring := v_expiring + 1;
        perform public.create_notification(
          v_me,
          'wali_invite_expiring',
          'Guardian invitation expiring',
          case when v_label is null
            then 'A Guardian invitation expires in two days.'
            else v_label || '''s Guardian invitation expires in two days.'
          end,
          null
        );
      end if;
    end if;
  end loop;

  return query select v_expiring, v_expired;
end;
$function$;

drop function public.preview_wali_invite(text);

create function public.preview_wali_invite(p_token text)
returns table(
  inviter_first_name text,
  inviter_role text,
  invite_status text,
  inviter_ward_count integer,
  seeker_plan text,
  basic_place_free boolean,
  needs_guardian_one boolean,
  expires_at timestamptz
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
         v_needs_one,
         v_invite.expires_at;
end;
$function$;

revoke execute on function public.preview_wali_invite(text) from public, anon;
grant execute on function public.preview_wali_invite(text) to authenticated, service_role;

commit;
