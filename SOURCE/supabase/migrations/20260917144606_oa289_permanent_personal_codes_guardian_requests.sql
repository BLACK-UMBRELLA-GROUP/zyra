-- OA-ZYRA-289 / DR-ZYRA-231 — permanent role-specific ZYRA Codes.
--
-- STAGED ONLY. This migration must not be applied without a separate Founder
-- GO naming this exact file and its SHA-256.
--
-- A ZYRA Code is a reusable discovery handle, not a credential. Knowing one
-- never creates a Guardian relationship. It can only create a recipient-bound
-- request which the code owner must approve. The preview deliberately exposes
-- first name + role only: no photo and no identity-verification claim.
--
-- Legacy seven-day bearer invitations remain readable/acceptable during the
-- transition. New clients stop minting them; this migration does not delete or
-- rewrite any existing row.

begin;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to service_role;

create table private.zyra_personal_codes (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  role_context text not null check (role_context in ('seeker', 'wali')),
  code text not null unique,
  created_at timestamptz not null default clock_timestamp(),
  rotated_at timestamptz,
  unique (owner_id, role_context),
  constraint zyra_personal_codes_format check (
    code ~ '^ZYRA-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}$'
  )
);

create table private.zyra_retired_personal_code_hashes (
  code_sha256 bytea primary key,
  retired_at timestamptz not null default clock_timestamp()
);

create table private.zyra_personal_code_attempts (
  id bigint generated always as identity primary key,
  caller_id uuid not null references public.profiles(id) on delete cascade,
  attempted_at timestamptz not null default clock_timestamp(),
  succeeded boolean not null
);

create index zyra_personal_code_attempts_caller_time
  on private.zyra_personal_code_attempts(caller_id, attempted_at desc);

alter table private.zyra_personal_codes enable row level security;
alter table private.zyra_retired_personal_code_hashes enable row level security;
alter table private.zyra_personal_code_attempts enable row level security;
revoke all on all tables in schema private from public, anon, authenticated;
grant select, insert, update, delete on private.zyra_personal_codes to service_role;
grant select, insert on private.zyra_retired_personal_code_hashes to service_role;
grant select, insert, delete on private.zyra_personal_code_attempts to service_role;
grant usage, select on sequence private.zyra_personal_code_attempts_id_seq
  to service_role;

comment on table private.zyra_personal_codes is
  'Server-owned reusable ZYRA discovery handles. One active code per account '
  'role context; never a credential and never sufficient to create a link.';
comment on table private.zyra_retired_personal_code_hashes is
  'Pseudonymous non-reuse ledger. Only SHA-256 digests survive rotation or '
  'account deletion; no owner identifier is retained.';

create or replace function private.zyra_normalize_personal_code(p_code text)
returns text
language plpgsql
immutable
set search_path = ''
as $function$
declare
  v_compact text := upper(regexp_replace(coalesce(p_code, ''), '[^0-9A-Z]', '', 'g'));
begin
  if length(v_compact) <> 24 or left(v_compact, 4) <> 'ZYRA' then
    return null;
  end if;
  return 'ZYRA-' || substr(v_compact, 5, 4) || '-' ||
         substr(v_compact, 9, 4) || '-' || substr(v_compact, 13, 4) || '-' ||
         substr(v_compact, 17, 4) || '-' || substr(v_compact, 21, 4);
end;
$function$;

create or replace function private.zyra_retire_personal_code()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if tg_op = 'DELETE' then
    insert into private.zyra_retired_personal_code_hashes(code_sha256)
    values (extensions.digest(old.code, 'sha256'))
    on conflict do nothing;
    return old;
  end if;
  if new.code is distinct from old.code then
    insert into private.zyra_retired_personal_code_hashes(code_sha256)
    values (extensions.digest(old.code, 'sha256'))
    on conflict do nothing;
  end if;
  return new;
end;
$function$;

revoke execute on function private.zyra_normalize_personal_code(text)
  from public, anon, authenticated;
revoke execute on function private.zyra_retire_personal_code()
  from public, anon, authenticated;

create trigger zyra_retire_personal_code_before_change
before update of code or delete on private.zyra_personal_codes
for each row execute function private.zyra_retire_personal_code();

alter table public.wali_invites
  add column if not exists source text not null default 'legacy_code',
  add column if not exists personal_code_id uuid
    references private.zyra_personal_codes(id) on delete cascade,
  add column if not exists recipient_id uuid
    references public.profiles(id) on delete cascade,
  add column if not exists request_expires_at timestamptz,
  add column if not exists cancelled_at timestamptz;

-- New rows are server-owned. Existing pending legacy rows remain readable and
-- acceptable, but an old or modified client may no longer mint a fresh bearer
-- token by inserting directly.
revoke insert on table public.wali_invites from public, anon, authenticated;

alter table public.wali_invites
  drop constraint if exists wali_invites_status_check;
alter table public.wali_invites
  add constraint wali_invites_status_check check (
    status in ('pending', 'accepted', 'declined', 'revoked', 'expired', 'cancelled')
  );

alter table public.wali_invites
  add constraint wali_invites_source_check
  check (source in ('legacy_code', 'personal_code')) not valid;
alter table public.wali_invites validate constraint wali_invites_source_check;

-- Legacy rows carry the Guardian's relationship only when the Guardian was
-- the inviter. In the new addressed flow the Guardian may instead be the
-- recipient/requester entering a Seeker's code, so source-aware server RPCs
-- own the role check and the old inviter-only shape must not reject the row.
alter table public.wali_invites
  drop constraint if exists wali_invites_relationship_only_from_wali;
alter table public.wali_invites
  add constraint wali_invites_relationship_owner_check check (
    relationship is null
    or (source = 'legacy_code' and inviter_role = 'wali')
    or source = 'personal_code'
  ) not valid;
alter table public.wali_invites
  validate constraint wali_invites_relationship_owner_check;

alter table public.wali_invites
  add constraint wali_invites_personal_request_shape check (
    source <> 'personal_code' or
    (personal_code_id is not null and recipient_id is not null and
     request_expires_at is not null and token is not null)
  ) not valid;
alter table public.wali_invites validate constraint wali_invites_personal_request_shape;

create index wali_invites_personal_incoming
  on public.wali_invites(inviter_id, status, created_at desc)
  where source = 'personal_code';
create index wali_invites_personal_outgoing
  on public.wali_invites(recipient_id, status, created_at desc)
  where source = 'personal_code';
create unique index wali_invites_one_pending_personal_request
  on public.wali_invites(personal_code_id, recipient_id)
  where source = 'personal_code' and status = 'pending';

comment on column public.wali_invites.recipient_id is
  'For source=personal_code, the authenticated requester. The code owner is '
  'inviter_id. A link is never created until the owner accepts.';
comment on column public.wali_invites.request_expires_at is
  'Thirty-day request clock for addressed personal-code requests. The legacy '
  'seven-day bearer-code expires_at contract is unchanged.';

create or replace function private.zyra_enforce_personal_request_owner_acceptance()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.source = 'personal_code'
     and new.status = 'accepted'
     and old.status is distinct from 'accepted'
     and new.accepted_by is distinct from new.inviter_id then
    raise exception 'personal_request_requires_owner_acceptance';
  end if;
  return new;
end;
$function$;

revoke execute on function private.zyra_enforce_personal_request_owner_acceptance()
  from public, anon, authenticated;

create trigger wali_invites_personal_request_owner_acceptance
before update of status on public.wali_invites
for each row execute function private.zyra_enforce_personal_request_owner_acceptance();

create or replace function private.zyra_generate_personal_code()
returns text
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
  v_hex text;
  v_code text;
begin
  loop
    v_hex := upper(encode(extensions.gen_random_bytes(10), 'hex'));
    v_code := 'ZYRA-' || substr(v_hex, 1, 4) || '-' ||
              substr(v_hex, 5, 4) || '-' || substr(v_hex, 9, 4) || '-' ||
              substr(v_hex, 13, 4) || '-' || substr(v_hex, 17, 4);
    exit when not exists (
      select 1 from private.zyra_personal_codes c where c.code = v_code
    ) and not exists (
      select 1 from private.zyra_retired_personal_code_hashes r
      where r.code_sha256 = extensions.digest(v_code, 'sha256')
    );
  end loop;
  return v_code;
end;
$function$;

revoke execute on function private.zyra_generate_personal_code()
  from public, anon, authenticated;

create or replace function private.zyra_identity_verification_allows_user(
  p_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select coalesce((
    select attempt.result = 'verified'
    from private.identity_verification_attempts attempt
    where attempt.user_id = p_user_id
      and attempt.member_deleted_at is null
    order by (attempt.result = 'verified') desc, attempt.created_at desc
    limit 1
  ), false);
$function$;

revoke execute on function private.zyra_identity_verification_allows_user(uuid)
  from public, anon, authenticated;

create or replace function public.zyra_my_personal_code(p_role_context text default null)
returns table(code text, role_context text)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := auth.uid();
  v_role text;
  v_requested_role text;
  v_code text;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;
  select p.role into v_role from public.profiles p where p.id = v_me;
  if v_role not in ('seeker', 'wali') then raise exception 'profile_role_unavailable'; end if;
  v_requested_role := coalesce(p_role_context, v_role);
  if v_requested_role <> v_role then raise exception 'role_context_not_authorised'; end if;

  select c.code into v_code
  from private.zyra_personal_codes c
  where c.owner_id = v_me and c.role_context = v_requested_role;

  if v_code is null then
    loop
      begin
        insert into private.zyra_personal_codes as inserted
          (owner_id, role_context, code)
        values (v_me, v_requested_role, private.zyra_generate_personal_code())
        returning inserted.code into v_code;
        exit;
      exception when unique_violation then
        select c.code into v_code
        from private.zyra_personal_codes c
        where c.owner_id = v_me and c.role_context = v_requested_role;
        if v_code is not null then exit; end if;
      end;
    end loop;
  end if;

  return query select v_code, v_requested_role;
end;
$function$;

create or replace function public.zyra_rotate_my_personal_code(p_role_context text default null)
returns table(code text, role_context text)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := auth.uid();
  v_role text;
  v_requested_role text;
  v_code text;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;
  select p.role into v_role from public.profiles p where p.id = v_me;
  if v_role not in ('seeker', 'wali') then raise exception 'profile_role_unavailable'; end if;
  v_requested_role := coalesce(p_role_context, v_role);
  if v_requested_role <> v_role then raise exception 'role_context_not_authorised'; end if;

  perform public.zyra_my_personal_code(v_requested_role);
  update private.zyra_personal_codes c
     set code = private.zyra_generate_personal_code(),
         rotated_at = clock_timestamp()
   where c.owner_id = v_me and c.role_context = v_requested_role
   returning c.code into v_code;

  return query select v_code, v_requested_role;
end;
$function$;

create or replace function public.zyra_preview_personal_code(p_code text)
returns table(owner_first_name text, owner_role text)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := auth.uid();
  v_code text := private.zyra_normalize_personal_code(p_code);
  v_owner uuid;
  v_owner_role text;
  v_my_role text;
  v_first_name text;
  v_allowed boolean := false;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(v_me::text, 231));

  delete from private.zyra_personal_code_attempts a
   where a.caller_id = v_me
     and a.attempted_at < clock_timestamp() - interval '7 days';
  if (select count(*) from private.zyra_personal_code_attempts a
      where a.caller_id = v_me and a.attempted_at >= clock_timestamp() - interval '1 hour') >= 10
     or
     (select count(*) from private.zyra_personal_code_attempts a
      where a.caller_id = v_me and a.attempted_at >= clock_timestamp() - interval '1 day') >= 30 then
    return;
  end if;

  select c.owner_id, c.role_context, p.first_name
    into v_owner, v_owner_role, v_first_name
  from private.zyra_personal_codes c
  join public.profiles p on p.id = c.owner_id and p.role = c.role_context
  where c.code = v_code;
  select p.role into v_my_role from public.profiles p where p.id = v_me;

  v_allowed := coalesce(v_owner is not null
    and v_owner <> v_me
    and private.zyra_identity_verification_allows_user(v_owner)
    and v_my_role in ('seeker', 'wali')
    and v_owner_role <> v_my_role
    and not public.zyra_block_exists(v_owner)
    and public.zyra_can_guardian_link(v_me, v_owner)
    and not exists (
      select 1 from public.wali_links wl
      where ((wl.seeker_id = v_me and wl.wali_id = v_owner)
          or (wl.seeker_id = v_owner and wl.wali_id = v_me))
        and wl.status = 'active'
    ), false);

  insert into private.zyra_personal_code_attempts(caller_id, succeeded)
  values (v_me, v_allowed);
  if not v_allowed then return; end if;

  return query select v_first_name, v_owner_role;
end;
$function$;

create or replace function public.zyra_request_guardian_link(
  p_code text,
  p_relationship text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := auth.uid();
  v_code text := private.zyra_normalize_personal_code(p_code);
  v_my_role text;
  v_owner uuid;
  v_owner_role text;
  v_code_id uuid;
  v_request_id uuid;
  v_my_name text;
  v_preview_role text;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;
  if p_relationship is not null and p_relationship not in (
    'father','brother','grandfather','uncle','legal_guardian',
    'family_representative','other'
  ) then raise exception 'unknown_relationship'; end if;

  -- The mutation cannot bypass preview's authentication, neutral filtering or
  -- rate limit by calling this RPC directly.
  select preview.owner_role into v_preview_role
  from public.zyra_preview_personal_code(p_code) preview;
  if v_preview_role is null then return null; end if;

  select p.role, p.first_name into v_my_role, v_my_name
  from public.profiles p where p.id = v_me;
  select c.id, c.owner_id, c.role_context
    into v_code_id, v_owner, v_owner_role
  from private.zyra_personal_codes c
  join public.profiles owner_profile
    on owner_profile.id = c.owner_id and owner_profile.role = c.role_context
  where c.code = v_code;

  if v_owner is null or v_owner = v_me or v_my_role not in ('seeker','wali')
     or v_owner_role = v_my_role
     or public.zyra_block_exists(v_owner)
     or not public.zyra_can_guardian_link(v_me, v_owner) then
    raise exception 'code_unavailable';
  end if;
  if v_my_role = 'wali' and p_relationship is null then
    raise exception 'relationship_required';
  end if;
  if v_my_role = 'seeker' and p_relationship is not null then
    raise exception 'relationship_owned_by_guardian';
  end if;
  if exists (
    select 1 from public.wali_links wl
    where ((wl.seeker_id = v_me and wl.wali_id = v_owner)
        or (wl.seeker_id = v_owner and wl.wali_id = v_me))
      and wl.status = 'active'
  ) then raise exception 'already_linked'; end if;

  update public.wali_invites wi
     set status = 'expired'
   where wi.source = 'personal_code'
     and wi.personal_code_id = v_code_id
     and wi.recipient_id = v_me
     and wi.status = 'pending'
     and wi.request_expires_at <= clock_timestamp();

  insert into public.wali_invites(
    token, inviter_id, inviter_role, status, relationship, source,
    personal_code_id, recipient_id, expires_at, request_expires_at
  ) values (
    'REQ-' || upper(encode(extensions.gen_random_bytes(12), 'hex')),
    v_owner, v_owner_role, 'pending',
    case when v_my_role = 'wali' then p_relationship else null end,
    'personal_code', v_code_id, v_me,
    clock_timestamp() + interval '30 days',
    clock_timestamp() + interval '30 days'
  )
  returning id into v_request_id;

  perform public.create_notification(
    v_owner, 'wali_request', 'Guardian request',
    coalesce(v_my_name, 'Someone') || ' sent you a Guardian request.', null
  );
  return v_request_id;
exception
  when unique_violation then raise exception 'request_already_pending';
end;
$function$;

create or replace function public.zyra_my_guardian_requests()
returns table(
  request_id uuid,
  direction text,
  other_first_name text,
  other_role text,
  status text,
  relationship text,
  created_at timestamptz,
  expires_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;

  return query
  select wi.id,
         case when wi.inviter_id = v_me then 'incoming' else 'outgoing' end,
         other_profile.first_name,
         other_profile.role,
         case when wi.status = 'pending' and wi.request_expires_at <= now()
              then 'expired' else wi.status end,
         wi.relationship,
         wi.created_at,
         wi.request_expires_at
  from public.wali_invites wi
  join public.profiles other_profile
    on other_profile.id = case when wi.inviter_id = v_me
                               then wi.recipient_id else wi.inviter_id end
  where wi.source = 'personal_code'
    and (wi.inviter_id = v_me or wi.recipient_id = v_me)
  order by wi.created_at desc;
end;
$function$;

create or replace function public.zyra_accept_guardian_request(
  p_request_id uuid,
  p_relationship text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := auth.uid();
  v_request public.wali_invites%rowtype;
  v_requester_role text;
  v_owner_role text;
  v_seeker uuid;
  v_wali uuid;
  v_relationship text;
  v_link_id uuid;
  v_owner_name text;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;
  if p_relationship is not null and p_relationship not in (
    'father','brother','grandfather','uncle','legal_guardian',
    'family_representative','other'
  ) then raise exception 'unknown_relationship'; end if;

  select * into v_request from public.wali_invites wi
  where wi.id = p_request_id and wi.source = 'personal_code'
  for update;
  if not found or v_request.inviter_id <> v_me then raise exception 'request_unavailable'; end if;
  if v_request.status <> 'pending' then raise exception 'request_not_pending'; end if;
  if v_request.request_expires_at <= clock_timestamp() then
    raise exception 'request_expired';
  end if;

  select p.role, p.first_name into v_owner_role, v_owner_name
  from public.profiles p where p.id = v_me;
  select p.role into v_requester_role
  from public.profiles p where p.id = v_request.recipient_id;
  if v_owner_role is distinct from v_request.inviter_role
     or v_requester_role = v_owner_role
     or v_requester_role not in ('seeker','wali') then
    raise exception 'role_context_changed';
  end if;
  if public.zyra_block_exists(v_request.recipient_id)
     or not public.zyra_can_guardian_link(v_me, v_request.recipient_id) then
    raise exception 'request_unavailable';
  end if;
  if not private.zyra_identity_verification_allows_user(v_request.recipient_id) then
    raise exception 'request_unavailable';
  end if;

  if v_owner_role = 'seeker' then
    v_seeker := v_me; v_wali := v_request.recipient_id;
    v_relationship := v_request.relationship;
    if p_relationship is not null then raise exception 'relationship_owned_by_guardian'; end if;
    if v_relationship is null then raise exception 'relationship_required'; end if;
  else
    v_seeker := v_request.recipient_id; v_wali := v_me;
    v_relationship := p_relationship;
    if v_relationship is null then raise exception 'relationship_required'; end if;
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(
      'zyra-wali-link:' || v_seeker::text || ':' || v_wali::text,
      231
    )
  );
  if exists (
    select 1 from public.wali_links wl
    where wl.seeker_id = v_seeker
      and wl.wali_id = v_wali
      and wl.status = 'active'
  ) then
    raise exception 'already_linked';
  end if;

  insert into public.wali_links as existing
    (seeker_id, wali_id, status, relationship)
  values (v_seeker, v_wali, 'active', v_relationship)
  on conflict (seeker_id, wali_id) do update
    set status = 'active',
        relationship = coalesce(excluded.relationship, existing.relationship)
  returning id into v_link_id;

  delete from public.likes
   where (liker_id = v_seeker and liked_id = v_wali)
      or (liker_id = v_wali and liked_id = v_seeker);
  delete from public.saves
   where (saver_id = v_seeker and saved_id = v_wali)
      or (saver_id = v_wali and saved_id = v_seeker);
  delete from public.passes
   where (passer_id = v_seeker and passed_id = v_wali)
      or (passer_id = v_wali and passed_id = v_seeker);

  update public.wali_invites
     set status = 'accepted', accepted_at = clock_timestamp(), accepted_by = v_me
   where id = v_request.id;
  perform public.create_notification(
    v_request.recipient_id, 'wali_request', 'Guardian request accepted',
    coalesce(v_owner_name, 'They') || ' accepted your Guardian request.', null
  );
  return v_link_id;
end;
$function$;

create or replace function public.zyra_decline_guardian_request(p_request_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := auth.uid();
  v_requester uuid;
  v_name text;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;
  update public.wali_invites wi
     set status = 'declined', declined_by = v_me, declined_at = clock_timestamp()
   where wi.id = p_request_id and wi.source = 'personal_code'
     and wi.inviter_id = v_me and wi.status = 'pending'
     and wi.request_expires_at > clock_timestamp()
  returning wi.recipient_id into v_requester;
  if v_requester is null then return false; end if;
  select p.first_name into v_name from public.profiles p where p.id = v_me;
  perform public.create_notification(
    v_requester, 'wali_request', 'Guardian request declined',
    coalesce(v_name, 'They') || ' declined your Guardian request.', null
  );
  return true;
end;
$function$;

create or replace function public.zyra_cancel_guardian_request(p_request_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not private.zyra_identity_verification_allows_user(v_me) then
    raise exception 'identity_verification_required';
  end if;
  update public.wali_invites wi
     set status = 'cancelled', cancelled_at = clock_timestamp()
   where wi.id = p_request_id and wi.source = 'personal_code'
     and wi.recipient_id = v_me and wi.status = 'pending'
     and wi.request_expires_at > clock_timestamp();
  return found;
end;
$function$;

-- Drive both seven-day legacy invitations and thirty-day personal requests
-- from their actual deadline. The previous created_at+5-days heuristic sent a
-- false "two days" warning for the new thirty-day request class.
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
     order by coalesce(wi.request_expires_at, wi.expires_at)
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

revoke execute on function public.zyra_my_personal_code(text) from public, anon;
revoke execute on function public.zyra_rotate_my_personal_code(text) from public, anon;
revoke execute on function public.zyra_preview_personal_code(text) from public, anon;
revoke execute on function public.zyra_request_guardian_link(text, text) from public, anon;
revoke execute on function public.zyra_my_guardian_requests() from public, anon;
revoke execute on function public.zyra_accept_guardian_request(uuid, text) from public, anon;
revoke execute on function public.zyra_decline_guardian_request(uuid) from public, anon;
revoke execute on function public.zyra_cancel_guardian_request(uuid) from public, anon;
revoke execute on function public.zyra_expire_due_wali_invites() from public, anon;

grant execute on function public.zyra_my_personal_code(text) to authenticated, service_role;
grant execute on function public.zyra_rotate_my_personal_code(text) to authenticated, service_role;
grant execute on function public.zyra_preview_personal_code(text) to authenticated, service_role;
grant execute on function public.zyra_request_guardian_link(text, text) to authenticated, service_role;
grant execute on function public.zyra_my_guardian_requests() to authenticated, service_role;
grant execute on function public.zyra_accept_guardian_request(uuid, text) to authenticated, service_role;
grant execute on function public.zyra_decline_guardian_request(uuid) to authenticated, service_role;
grant execute on function public.zyra_cancel_guardian_request(uuid) to authenticated, service_role;
grant execute on function public.zyra_expire_due_wali_invites() to authenticated, service_role;

comment on function public.zyra_preview_personal_code(text) is
  'Authenticated, rate-limited and neutral-on-failure preview. Returns first '
  'name and role only; no photo and no identity-verification claim.';
comment on function public.zyra_request_guardian_link(text, text) is
  'Creates a 30-day two-sided request against a permanent ZYRA Code. Never '
  'creates or reactivates wali_links; owner acceptance is mandatory.';

commit;
