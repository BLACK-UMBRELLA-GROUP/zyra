-- OA-ZYRA-232 — make the Guardian invite lifecycle observable.
--
-- Expiry remains lazy because pg_cron is unavailable, but it is now a real
-- sweep invoked whenever a Guardian surface loads. Day-5 and day-7 events are
-- one-shot. Preview records the first signed-in bearer who has actually seen
-- the code, which is the only recipient identity the manual share-code model
-- possesses; revocation therefore notifies that person only when known.
--
-- Privacy: wali_invites.label remains the SENDER'S private note. It is used
-- only in notifications sent back to the sender. Recipient-facing received /
-- revoked copy names the inviter from profiles and never exposes the label.

alter table public.wali_invites
  add column if not exists expiring_notified_at timestamptz,
  add column if not exists seen_by uuid references public.profiles(id) on delete set null,
  add column if not exists seen_at timestamptz,
  add column if not exists declined_by uuid references public.profiles(id) on delete set null,
  add column if not exists declined_at timestamptz;

alter table public.wali_invites
  drop constraint if exists wali_invites_status_check;
alter table public.wali_invites
  add constraint wali_invites_status_check
  check (status in ('pending', 'accepted', 'declined', 'revoked', 'expired'));

alter table public.wali_invites
  drop constraint if exists wali_invites_seen_pair;
alter table public.wali_invites
  add constraint wali_invites_seen_pair
  check ((seen_by is null) = (seen_at is null));

alter table public.wali_invites
  drop constraint if exists wali_invites_declined_pair;
alter table public.wali_invites
  add constraint wali_invites_declined_pair
  check ((declined_by is null) = (declined_at is null));

comment on column public.wali_invites.seen_by is
  'First authenticated bearer who previewed this manual invite code. Used '
  'only to send received/revoked lifecycle notifications; not proof that '
  'the sender intended the code for this person.';
comment on column public.wali_invites.expiring_notified_at is
  'One-shot marker for the day-5 Guardian invitation reminder.';

alter table public.notifications drop constraint if exists notifications_type_check;
alter table public.notifications add constraint notifications_type_check
  check (type = any (array[
    'new_match'::text, 'new_message'::text, 'wali_request'::text,
    'journey_ended'::text, 'journey_request'::text,
    'journey_request_accepted'::text, 'journey_request_declined'::text,
    'milestone_proposed'::text, 'milestone_confirmed'::text,
    'pause_nudge'::text, 'journey_paused'::text,
    'journey_also_paused'::text, 'journey_continued'::text,
    'wali_invite_received'::text, 'wali_invite_declined'::text,
    'wali_invite_expiring'::text, 'wali_invite_expired'::text,
    'wali_invite_revoked'::text
  ]));

-- One expiry transition, one notification. This helper is shared by preview
-- and the sweep so the meaning of "expired" cannot drift between them.
create or replace function public.expire_wali_invite_if_due(
  p_invite public.wali_invites
)
returns text
language plpgsql
set search_path to 'public'
as $function$
declare
  v_label text;
  v_status text;
begin
  if p_invite.status = 'pending' and p_invite.expires_at < clock_timestamp() then
    update public.wali_invites
       set status = 'expired'
     where id = p_invite.id
       and status = 'pending'
       and expires_at < clock_timestamp()
     returning label into v_label;

    if found then
      perform public.create_notification(
        p_invite.inviter_id,
        'wali_invite_expired',
        'Guardian invitation expired',
        case when v_label is null
          then 'A Guardian invitation expired.'
          else v_label || '''s Guardian invitation expired.'
        end,
        null
      );
      return 'expired';
    end if;

    -- Another transaction may have accepted/revoked/declined the row after
    -- the caller read it. Report the state that actually won, not expiry.
    select wi.status into v_status
      from public.wali_invites wi where wi.id = p_invite.id;
    return coalesce(v_status, p_invite.status);
  end if;
  return p_invite.status;
end;
$function$;

revoke all on function public.expire_wali_invite_if_due(public.wali_invites)
  from public, anon, authenticated;
grant execute on function public.expire_wali_invite_if_due(public.wali_invites)
  to service_role;

create or replace function public.zyra_expire_due_wali_invites()
returns table(expiring_count integer, expired_count integer)
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_me uuid := auth.uid();
  v_invite public.wali_invites%rowtype;
  v_expiring integer := 0;
  v_expired integer := 0;
  v_label text;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;

  for v_invite in
    select wi.*
      from public.wali_invites wi
     where wi.inviter_id = v_me
       and wi.status = 'pending'
     order by wi.expires_at
  loop
    if v_invite.expires_at < clock_timestamp() then
      if public.expire_wali_invite_if_due(v_invite) = 'expired' then
        v_expired := v_expired + 1;
      end if;
    elsif v_invite.created_at <= clock_timestamp() - interval '5 days'
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

revoke execute on function public.zyra_expire_due_wali_invites()
  from public, anon;
grant execute on function public.zyra_expire_due_wali_invites()
  to authenticated, service_role;

-- Preview is the moment a manual bearer code first "arrives" anywhere ZYRA
-- can observe. Record the first authenticated viewer and emit received once.
drop function if exists public.preview_wali_invite(text);
create function public.preview_wali_invite(p_token text)
returns table(
  inviter_first_name text,
  inviter_role text,
  invite_status text,
  inviter_ward_count integer
)
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_invite public.wali_invites%rowtype;
  v_status text;
  v_viewer uuid := auth.uid();
  v_inviter_name text;
begin
  select * into v_invite
    from public.wali_invites wi
   where wi.token = upper(trim(p_token));
  if not found then return; end if;

  v_status := public.expire_wali_invite_if_due(v_invite);
  select p.first_name into v_inviter_name
    from public.profiles p where p.id = v_invite.inviter_id;

  if v_status = 'pending'
     and v_viewer is not null
     and v_viewer <> v_invite.inviter_id then
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

  return query
  select v_inviter_name,
         v_invite.inviter_role,
         v_status,
         (select count(distinct wl.seeker_id)::integer
            from public.wali_links wl
           where wl.wali_id = v_invite.inviter_id
             and wl.status = 'active');
end;
$function$;

revoke execute on function public.preview_wali_invite(text)
  from public, anon;
grant execute on function public.preview_wali_invite(text)
  to authenticated, service_role;

create or replace function public.zyra_decline_wali_invite(p_token text)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_me uuid := auth.uid();
  v_invite public.wali_invites%rowtype;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;

  select * into v_invite
    from public.wali_invites wi
   where wi.token = upper(trim(p_token));
  if not found then raise exception 'invite_not_found'; end if;
  if v_invite.inviter_id = v_me then raise exception 'cannot_decline_own_invite'; end if;

  if v_invite.status = 'declined' and v_invite.declined_by = v_me then
    return true;
  end if;
  if public.expire_wali_invite_if_due(v_invite) = 'expired' then
    raise exception 'invite_expired';
  end if;
  if v_invite.status <> 'pending' then raise exception 'invite_not_pending'; end if;

  update public.wali_invites
     set status = 'declined',
         declined_by = v_me,
         declined_at = clock_timestamp(),
         seen_by = coalesce(seen_by, v_me),
         seen_at = coalesce(seen_at, clock_timestamp())
   where id = v_invite.id and status = 'pending';
  if not found then raise exception 'invite_not_pending'; end if;

  perform public.create_notification(
    v_invite.inviter_id,
    'wali_invite_declined',
    'Guardian invitation declined',
    case when v_invite.label is null
      then 'Your Guardian invitation was declined.'
      else v_invite.label || ' declined your Guardian invitation.'
    end,
    null
  );
  return true;
end;
$function$;

revoke execute on function public.zyra_decline_wali_invite(text)
  from public, anon;
grant execute on function public.zyra_decline_wali_invite(text)
  to authenticated, service_role;

create or replace function public.zyra_revoke_wali_invite(p_token text)
returns boolean
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_me uuid := auth.uid();
  v_invite public.wali_invites%rowtype;
  v_inviter_name text;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;

  select * into v_invite
    from public.wali_invites wi
   where wi.token = upper(trim(p_token))
     and wi.inviter_id = v_me;
  if not found or v_invite.status <> 'pending' then return false; end if;

  update public.wali_invites
     set status = 'revoked'
   where id = v_invite.id and status = 'pending';
  if not found then return false; end if;

  if v_invite.seen_by is not null then
    select p.first_name into v_inviter_name
      from public.profiles p where p.id = v_me;
    perform public.create_notification(
      v_invite.seen_by,
      'wali_invite_revoked',
      'Guardian invitation withdrawn',
      coalesce(v_inviter_name, 'The sender') || ' withdrew the Guardian invitation.',
      null
    );
  end if;
  return true;
end;
$function$;

revoke execute on function public.zyra_revoke_wali_invite(text)
  from public, anon;
grant execute on function public.zyra_revoke_wali_invite(text)
  to authenticated, service_role;
