-- ZYRA line 94 / DOC-ZYRA-0473 V4 / OA-ZYRA-317 / Q123, Q130, Q134.
begin;

-- Only safety-retained matches lose their participant keys. There is no
-- member-facing record for a deleted account.
alter table public.matches
  alter column seeker_a_id drop not null,
  alter column seeker_b_id drop not null,
  add constraint matches_deleted_pair_shape check (
    (seeker_a_id is not null and seeker_b_id is not null)
    or (seeker_a_id is null and seeker_b_id is null and status = 'ended')
  );

create table private.zyra_account_deleted_matches (
  match_id uuid primary key references public.matches(id) on delete cascade
);
alter table private.zyra_account_deleted_matches enable row level security;
revoke all on private.zyra_account_deleted_matches from public, anon, authenticated, service_role;

alter table public.messages
  alter column sender_id drop not null,
  drop constraint messages_sender_id_fkey,
  add constraint messages_sender_id_fkey
    foreign key (sender_id) references public.profiles(id) on delete set null;

-- Guardian assignments whose link belongs to a remaining account can still
-- carry the deleted actor. Keep the timestamps for safety audit.
alter table public.journey_guardian_assignments
  alter column granted_by drop not null,
  drop constraint journey_guardian_assignments_granted_by_fkey,
  drop constraint journey_guardian_assignments_revoked_by_fkey,
  drop constraint journey_guardian_assignments_revocation_pair,
  add constraint journey_guardian_assignments_granted_by_fkey
    foreign key (granted_by) references public.profiles(id) on delete set null,
  add constraint journey_guardian_assignments_revoked_by_fkey
    foreign key (revoked_by) references public.profiles(id) on delete set null,
  add constraint journey_guardian_assignments_revocation_pair
    check (revoked_by is null or revoked_at is not null);

alter table public.notifications
  add column payload jsonb not null default '{}'::jsonb,
  add constraint notifications_inactive_notice_anonymous check (
    type <> 'journey_ended_profile_inactive'
    or (payload = '{}'::jsonb and related_match_id is null)
  );

-- Source IDs identify evidence without FK cascades from deleted accounts or chat.
create table private.safety_sealed_messages (
  id uuid primary key default gen_random_uuid(),
  source text not null check (source in ('journey', 'guardian_circle')),
  source_message_id uuid not null,
  thread_id uuid not null,
  sender_id uuid,
  body text not null,
  sent_at timestamptz not null,
  sealed_at timestamptz not null,
  purge_at timestamptz not null,
  unique (source, source_message_id),
  check (purge_at = sealed_at + interval '8760 hours')
);
create index safety_sealed_messages_purge_idx on private.safety_sealed_messages(purge_at);
alter table private.safety_sealed_messages enable row level security;
revoke all on private.safety_sealed_messages from public, anon, authenticated, service_role;
grant select, delete on private.safety_sealed_messages to service_role;

create function public.zyra_purge_expired_safety_messages()
returns bigint
language plpgsql security invoker set search_path = ''
as $$
declare
  v_count bigint;
begin
  delete from private.safety_sealed_messages where purge_at <= now();
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
revoke all on function public.zyra_purge_expired_safety_messages()
  from public, anon, authenticated, service_role;
grant execute on function public.zyra_purge_expired_safety_messages() to service_role;

-- Profile reports already detach both users. Circle reports also have an exact message link.
alter table public.family_message_reports
  alter column thread_id drop not null,
  alter column message_id drop not null,
  alter column reporter_id drop not null,
  alter column reported_id drop not null,
  drop constraint family_message_reports_thread_id_fkey,
  drop constraint family_message_reports_message_id_fkey,
  drop constraint family_message_reports_reporter_id_fkey,
  drop constraint family_message_reports_reported_id_fkey,
  add constraint family_message_reports_thread_id_fkey
    foreign key (thread_id) references public.family_message_threads(id) on delete set null,
  add constraint family_message_reports_message_id_fkey
    foreign key (message_id) references public.family_messages(id) on delete set null,
  add constraint family_message_reports_reporter_id_fkey
    foreign key (reporter_id) references public.profiles(id) on delete set null,
  add constraint family_message_reports_reported_id_fkey
    foreign key (reported_id) references public.profiles(id) on delete set null,
  add column sealed_message_id uuid
    references private.safety_sealed_messages(id) on delete set null;
create index family_message_reports_sealed_idx on public.family_message_reports(sealed_message_id)
  where sealed_message_id is not null;

alter table public.family_subscriptions
  alter column owner_id drop not null,
  drop constraint family_subscriptions_owner_id_fkey,
  add constraint family_subscriptions_owner_id_fkey
    foreign key (owner_id) references public.profiles(id) on delete set null,
  add constraint family_subscriptions_live_owner_required check (
    owner_id is not null or status in ('expired', 'cancelled', 'refunded', 'chargeback')
  );

alter table public.family_ownership_transfers
  alter column current_owner_id drop not null,
  alter column replacement_owner_id drop not null,
  drop constraint family_ownership_transfers_current_owner_id_fkey,
  drop constraint family_ownership_transfers_replacement_owner_id_fkey,
  add constraint family_ownership_transfers_current_owner_id_fkey
    foreign key (current_owner_id) references public.profiles(id) on delete set null,
  add constraint family_ownership_transfers_replacement_owner_id_fkey
    foreign key (replacement_owner_id) references public.profiles(id) on delete set null,
  add constraint family_ownership_transfers_live_parties_required check (
    (current_owner_id is not null and replacement_owner_id is not null)
    or status in ('completed', 'declined', 'cancelled')
  );

-- Closed plans with a deleted owner no longer need a verified seat for that owner.
create or replace function public.zyra_assert_family_owner_seat(p_family uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_family public.family_subscriptions%rowtype;
begin
  select * into v_family
  from public.family_subscriptions family
  where family.id = p_family;
  if not found or v_family.owner_id is null then return; end if;

  if not exists (
    select 1
    from private.verified_person_accounts binding
    where binding.user_id = v_family.owner_id
      and binding.role = v_family.owner_role
  ) then raise exception 'verified_family_owner_required'; end if;

  if (v_family.owner_role = 'seeker' and v_family.seeker_places < 1)
     or (v_family.owner_role = 'guardian' and v_family.guardian_places < 1) then
    raise exception 'family_owner_place_required';
  end if;

  if not exists (
    select 1
    from public.family_seat_assignments seat
    where seat.family_subscription_id = p_family
      and seat.member_id = v_family.owner_id
      and seat.role = v_family.owner_role
      and (seat.removed_at is null or seat.funded_until > now())
  ) then raise exception 'family_owner_seat_required'; end if;
end;
$$;

create or replace function public.zyra_validate_family_ownership_transfer()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_family public.family_subscriptions%rowtype;
begin
  if tg_op = 'UPDATE' then
    if new.status = 'cancelled'
       and new.current_owner_id is not distinct from old.current_owner_id
       and new.replacement_owner_id is not distinct from old.replacement_owner_id
       and new.family_subscription_id = old.family_subscription_id then
      return new;
    end if;
    if old.status in ('completed', 'declined', 'cancelled')
       and new.status = old.status and new.family_subscription_id = old.family_subscription_id
       and (new.current_owner_id is null or new.current_owner_id is not distinct from old.current_owner_id)
       and (new.replacement_owner_id is null or new.replacement_owner_id is not distinct from old.replacement_owner_id)
       and (new.current_owner_id is null or new.replacement_owner_id is null) then
      return new;
    end if;
  end if;
  if new.current_owner_id is null or new.replacement_owner_id is null then
    raise exception 'family_transfer_existing_member_required';
  end if;

  select * into v_family
  from public.family_subscriptions family
  where family.id = new.family_subscription_id;
  if not found or v_family.owner_id is distinct from new.current_owner_id then
    raise exception 'family_transfer_owner_mismatch';
  end if;
  if not exists (
    select 1
    from public.family_seat_assignments seat
    where seat.family_subscription_id = new.family_subscription_id
      and seat.member_id = new.replacement_owner_id
      and seat.role = new.replacement_role
      and seat.removed_at is null
  ) then raise exception 'family_transfer_existing_member_required'; end if;
  if not exists (
    select 1
    from private.verified_person_accounts binding
    where binding.user_id = new.replacement_owner_id
      and binding.role = new.replacement_role
  ) then raise exception 'family_transfer_verified_member_required'; end if;
  if new.status in ('scheduled', 'completed')
     and new.effective_at is distinct from v_family.coverage_ends_at then
    raise exception 'family_transfer_must_start_at_renewal';
  end if;
  return new;
end;
$$;

alter table private.seeker_trial_ledger
  alter column updated_at drop not null,
  drop constraint seeker_trial_active_shape,
  add constraint seeker_trial_active_shape check (
    claimed_by is null and status = 'completed'
      and payment_authorisation_ref_hash is null and started_at is null
      and ends_at is null and updated_at is null
    or status = 'family_forfeited'
    or claimed_by is not null and payment_authorisation_ref_hash is not null
      and started_at is not null and ends_at = started_at + interval '14 days'
  );

-- A hold and its release audit survive either party's account deletion.
alter table public.protection_holds
  alter column restricted_id drop not null,
  alter column protected_id drop not null,
  drop constraint protection_holds_restricted_id_fkey,
  drop constraint protection_holds_protected_id_fkey,
  add constraint protection_holds_restricted_id_fkey
    foreign key (restricted_id) references public.profiles(id) on delete set null,
  add constraint protection_holds_protected_id_fkey
    foreign key (protected_id) references public.profiles(id) on delete set null,
  add column released_by_departed boolean not null default false,
  drop constraint holds_release_is_complete,
  add constraint holds_release_is_complete check (
    (released_at is null and released_by is null and release_reason is null and not released_by_departed)
    or (
      released_at is not null and release_reason is not null
      and ((released_by is null) = released_by_departed)
    )
  );
comment on constraint holds_release_is_complete on public.protection_holds is
  'A release records a date, reason and actor until that actor deletes their account.';

create table private.zyra_report_sealed_messages (
  report_id uuid references public.profile_reports(id) on delete cascade,
  sealed_message_id uuid references private.safety_sealed_messages(id) on delete cascade,
  primary key (report_id, sealed_message_id)
);
create index zyra_report_sealed_messages_seal_idx on private.zyra_report_sealed_messages(sealed_message_id);
alter table private.zyra_report_sealed_messages enable row level security;
revoke all on private.zyra_report_sealed_messages from public, anon, authenticated, service_role;
grant select on private.zyra_report_sealed_messages to service_role;

-- Keep Guardian notification sources private. The application still reads the
-- same notification shape and cannot read a request's bearer token from it.
create table private.zyra_guardian_notification_sources (
  notification_id uuid primary key references public.notifications(id) on delete cascade,
  actor_id uuid references public.profiles(id) on delete set null,
  invite_id uuid references public.wali_invites(id) on delete set null,
  link_id uuid references public.wali_links(id) on delete set null
);
alter table private.zyra_guardian_notification_sources enable row level security;
revoke all on private.zyra_guardian_notification_sources from public, anon, authenticated, service_role;
create index zyra_guardian_notification_actor_idx on private.zyra_guardian_notification_sources(actor_id);
create index zyra_guardian_notification_invite_idx on private.zyra_guardian_notification_sources(invite_id);
create index zyra_guardian_notification_link_idx on private.zyra_guardian_notification_sources(link_id);

create function private.zyra_create_notification(
  p_user_id uuid, p_type text, p_title text, p_body text, p_related_match_id uuid,
  p_actor_id uuid default null, p_invite_id uuid default null, p_link_id uuid default null
)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_category text := public.zyra_notification_category(p_type);
  v_enabled boolean;
  v_notification_id uuid;
  v_has_departed boolean;
begin
  if v_category is not null then
    select p.enabled into v_enabled
    from public.notification_preferences p
    where p.user_id = p_user_id and p.category = v_category
    order by p.seq desc limit 1;

    if not coalesce(v_enabled, v_category not in ('marketing_emails', 'product_updates')) then
      return;
    end if;
  end if;

  -- A notification written after account erasure must not recreate a preview
  -- for that departed participant. Taking the match lock serializes the check
  -- with the erasure transaction.
  if p_related_match_id is not null then
    select (m.seeker_a_id is null or m.seeker_b_id is null) into v_has_departed
    from public.matches m where m.id = p_related_match_id for share;
    if not found or v_has_departed then return; end if;
  end if;

  insert into public.notifications(user_id, type, title, body, related_match_id)
  values (p_user_id, p_type, p_title, p_body, p_related_match_id)
  returning id into v_notification_id;

  if p_actor_id is not null or p_invite_id is not null or p_link_id is not null then
    insert into private.zyra_guardian_notification_sources(notification_id, actor_id, invite_id, link_id)
    values (v_notification_id, p_actor_id, p_invite_id, p_link_id);
  end if;
end;
$$;
revoke all on function private.zyra_create_notification(uuid,text,text,text,uuid,uuid,uuid,uuid)
  from public, anon, authenticated, service_role;
grant execute on function private.zyra_create_notification(uuid,text,text,text,uuid,uuid,uuid,uuid)
  to service_role;

create or replace function public.create_notification(
  p_user_id uuid, p_type text, p_title text, p_body text, p_related_match_id uuid
)
returns void
language sql security definer set search_path = ''
as $$
  select private.zyra_create_notification(p_user_id, p_type, p_title, p_body, p_related_match_id);
$$;

-- Preserve the existing writers, checks and copy. Each writer has exactly one
-- notification call in the replay. Attach its already-authorized source IDs.
do $guardian_notification_writers$
declare
  v_writer record;
  v_definition text;
  v_call constant text := 'perform public[.]create_notification[(]([^;]*),[[:space:]]*null[[:space:]]*[)][;]';
begin
  for v_writer in
    select * from (values
      ('public.accept_wali_invite(text,text)'::regprocedure, 'v_accepter_id, v_invite.id, v_link_id'),
      ('public.expire_wali_invite_if_due(public.wali_invites)'::regprocedure, 'null, p_invite.id, null'),
      ('public.preview_wali_invite(text)'::regprocedure, 'v_invite.inviter_id, v_invite.id, null'),
      ('public.zyra_accept_guardian_request(uuid,text)'::regprocedure, 'v_me, v_request.id, v_link_id'),
      ('public.zyra_decline_guardian_request(uuid)'::regprocedure, 'v_me, p_request_id, null'),
      ('public.zyra_decline_wali_invite(text)'::regprocedure, 'v_me, v_invite.id, null'),
      ('public.zyra_expire_due_wali_invites()'::regprocedure, 'null, v_invite.id, null'),
      ('public.zyra_request_guardian_link(text,text)'::regprocedure, 'v_me, v_request_id, null'),
      ('public.zyra_revoke_wali_invite(text)'::regprocedure, 'v_me, v_invite.id, null')
    ) as writers(rpc, source_ids)
  loop
    v_definition := pg_get_functiondef(v_writer.rpc);
    if (select count(*) from regexp_matches(v_definition, v_call, 'gi')) <> 1 then
      raise exception 'Guardian notification call changed in %', v_writer.rpc;
    end if;
    execute regexp_replace(v_definition, v_call,
      'perform private.zyra_create_notification(\1, null, ' || v_writer.source_ids || ');', 'i');
  end loop;
end;
$guardian_notification_writers$;

-- Legacy rows carry no source ID. Recover only a unique, exact recipient and
-- persisted event-time match. A name or a nearby timestamp is insufficient.
with candidates as (
  select n.id as notification_id, invite.id as invite_id,
    case
      when n.title in ('Guardian request', 'Guardian invitation declined') then
        case n.type when 'wali_request' then invite.recipient_id else invite.declined_by end
      when n.title = 'Wali Link Accepted' then invite.accepted_by
      else invite.inviter_id
    end as actor_id,
    count(*) over (partition by n.id) as candidates
  from public.notifications n
  join public.wali_invites invite on (
    (n.type = 'wali_request' and n.title = 'Guardian request' and invite.source = 'personal_code'
      and n.user_id = invite.inviter_id and n.created_at = invite.created_at)
    or (n.type = 'wali_request' and n.title = 'Guardian request accepted' and invite.source = 'personal_code'
      and n.user_id = invite.recipient_id and n.created_at = invite.accepted_at)
    or (n.type = 'wali_request' and n.title = 'Guardian request declined' and invite.source = 'personal_code'
      and n.user_id = invite.recipient_id and n.created_at = invite.declined_at)
    or (n.type = 'wali_request' and n.title = 'Wali Link Accepted' and invite.source = 'legacy_code'
      and n.user_id = invite.inviter_id and n.created_at = invite.accepted_at)
    or (n.type = 'wali_invite_received' and n.user_id = invite.seen_by and n.created_at = invite.seen_at)
    or (n.type = 'wali_invite_declined' and n.user_id = invite.inviter_id and n.created_at = invite.declined_at)
    or (n.type = 'wali_invite_expiring' and n.user_id = invite.inviter_id
      and n.created_at = invite.expiring_notified_at)
  )
  where n.related_match_id is null
)
insert into private.zyra_guardian_notification_sources(notification_id, actor_id, invite_id)
select notification_id, actor_id, invite_id from candidates where candidates = 1;

-- For retained Journey evidence, preserve the authored rows that would
-- otherwise cascade with the deleted profile. The original attempt governs
-- the lifetime of this service-only snapshot.
create table private.zyra_deleted_attempt_evidence (
  attempt_id uuid primary key references public.journey_attempts(id) on delete cascade,
  records jsonb not null
);
alter table private.zyra_deleted_attempt_evidence enable row level security;
revoke all on private.zyra_deleted_attempt_evidence from public, anon, authenticated, service_role;
grant select on private.zyra_deleted_attempt_evidence to service_role;

-- Circle report evidence is independently retained under the existing
-- moderation rules. Keep the full sealed Circle context while its case is
-- open or under legal hold.
create table private.zyra_circle_seal_protections (
  sealed_message_id uuid references private.safety_sealed_messages(id) on delete cascade,
  report_id uuid references public.family_message_reports(id) on delete cascade,
  primary key (sealed_message_id, report_id)
);
alter table private.zyra_circle_seal_protections enable row level security;
revoke all on private.zyra_circle_seal_protections from public, anon, authenticated, service_role;

create or replace function public.zyra_purge_expired_safety_messages()
returns bigint
language plpgsql security definer set search_path = ''
as $$
declare
  v_count bigint;
begin
  delete from private.safety_sealed_messages sealed
  where sealed.purge_at <= now() and not exists (
    select 1 from private.zyra_circle_seal_protections protection
    join public.family_message_reports report on report.id = protection.report_id
    left join public.family_message_report_evidence evidence on evidence.report_id = report.id
    where protection.sealed_message_id = sealed.id
      and (report.status in ('pending', 'reviewing') or evidence.legal_hold)
  );
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- A message INSERT can outlive its original RLS snapshot while waiting on
-- deletion. Lock the match first and recheck its current state before writing.
create function private.zyra_lock_message_match()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare
  v_has_departed boolean;
begin
  select m.seeker_a_id is null into v_has_departed
  from public.matches m
  join public.conversations c on c.match_id = m.id
  where c.id = new.conversation_id for share of m;
  if not found or v_has_departed then
    raise exception using errcode = '42501', message = 'journey_not_available';
  end if;
  return new;
end;
$$;
revoke all on function private.zyra_lock_message_match()
  from public, anon, authenticated, service_role;
create trigger messages_lock_match before insert on public.messages
for each row execute function private.zyra_lock_message_match();

create function private.zyra_erase_departing_notification_previews(p_user_id uuid)
returns void
language sql set search_path = ''
as $$
  with departing_references(id) as (
    select p_user_id
    union all
    select m.id from public.matches m where p_user_id in (m.seeker_a_id, m.seeker_b_id)
    union all
    select r.id from public.journey_requests r where p_user_id in (r.requested_by, r.requested_to)
    union all
    select i.id from public.wali_invites i
    where p_user_id in (i.inviter_id, i.recipient_id, i.seen_by, i.accepted_by, i.declined_by)
    union all
    select l.id from public.wali_links l where p_user_id in (l.seeker_id, l.wali_id)
  ), affected as (
    select source.notification_id
    from private.zyra_guardian_notification_sources source
    left join public.wali_invites invite on invite.id = source.invite_id
    left join public.wali_links link on link.id = source.link_id
    where p_user_id in (source.actor_id, invite.inviter_id, invite.recipient_id, invite.seen_by,
      invite.accepted_by, invite.declined_by, link.seeker_id, link.wali_id)
    union
    select n.id from public.notifications n
    where n.payload <> '{}'::jsonb and exists (
      select 1
      from jsonb_path_query(n.payload, '$.** ? (@.type() == "string")') field(value)
      join departing_references ref on lower(field.value #>> '{}') = ref.id::text
    )
  )
  update public.notifications n
  set title = 'This profile is no longer active', body = null, payload = '{}'::jsonb
  from affected where n.id = affected.notification_id;

  -- A legacy Guardian preview can outlive its invite and contain a name
  -- without an ID. Erase the preview rather than matching on a name alone.
  update public.notifications n
  set title = '', body = null, payload = '{}'::jsonb
  where n.related_match_id is null
    and n.type in ('wali_request','wali_invite_received','wali_invite_declined',
      'wali_invite_expiring','wali_invite_expired','wali_invite_revoked')
    and (n.title <> '' or n.body is not null)
    and not exists (
      select 1 from private.zyra_guardian_notification_sources source
      where source.notification_id = n.id
        and (source.actor_id is not null or source.invite_id is not null or source.link_id is not null)
    );
$$;
revoke all on function private.zyra_erase_departing_notification_previews(uuid)
  from public, anon, authenticated, service_role;

-- The profile trigger also covers Auth-driven erasure. Its caller and all
-- cascades share one transaction, including the notice and safety copy.
create function private.zyra_remove_departing_profile()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_deleted_at timestamptz := clock_timestamp();
  v_purge_at timestamptz := v_deleted_at + interval '8760 hours';
  v_match_ids uuid[];
  v_match_id uuid;
begin
  -- The profile row lock also excludes a new owner reference. Lock existing
  -- owner rows before deciding whether any plan still has coverage.
  perform 1 from public.family_subscriptions family
  where family.owner_id = old.id order by family.id for update;
  if exists (
    select 1 from public.family_subscriptions family
    where family.owner_id = old.id
      and family.status in ('active', 'billing_grace', 'cancel_at_period_end')
  ) then raise exception 'family_owner_must_transfer'; end if;

  update public.family_ownership_transfers transfer
  set status = 'cancelled'
  where old.id in (transfer.current_owner_id, transfer.replacement_owner_id)
    and transfer.status in ('pending_acceptance', 'pending_purchase', 'scheduled');

  update public.family_subscriptions family
  set status = 'cancelled'
  where family.owner_id = old.id and family.status = 'pending';

  update private.seeker_trial_ledger trial
  set claimed_by = null, status = 'completed', payment_authorisation_ref_hash = null,
      started_at = null, ends_at = null, updated_at = null
  where trial.claimed_by = old.id;

  -- Preserve report links before detaching either participant. This also
  -- locks the matches in a deterministic order.
  perform private.zyra_protect_report_attempts_before_departure(old.id);
  perform private.zyra_erase_departing_notification_previews(old.id);

  update public.protection_holds
  set released_by = null, released_by_departed = true
  where released_by = old.id;

  -- Both invite actor FKs null on profile deletion. Their paired checks also
  -- require clearing the corresponding time in the same statement.
  update public.wali_invites invite
  set seen_at = case when invite.seen_by = old.id then null else invite.seen_at end,
      seen_by = case when invite.seen_by = old.id then null else invite.seen_by end,
      declined_at = case when invite.declined_by = old.id then null else invite.declined_at end,
      declined_by = case when invite.declined_by = old.id then null else invite.declined_by end,
      label = null
  where old.id in (invite.seen_by, invite.declined_by, invite.accepted_by);


  select coalesce(array_agg(m.id order by m.id), '{}'::uuid[]) into v_match_ids
  from public.matches m where old.id in (m.seeker_a_id, m.seeker_b_id);

  perform t.id from public.family_message_threads t
  where t.seeker_id = old.id
     or exists (select 1 from public.family_messages msg
                where msg.thread_id = t.id and msg.sender_id = old.id)
  order by t.id for update;

  insert into private.safety_sealed_messages
    (source, source_message_id, thread_id, sender_id, body, sent_at, sealed_at, purge_at)
  select 'journey', msg.id, msg.conversation_id, msg.sender_id,
    msg.content, msg.created_at, v_deleted_at, v_purge_at
  from public.messages msg
  join public.conversations conversation on conversation.id = msg.conversation_id
  where conversation.match_id = any(v_match_ids)
  union all
  select 'guardian_circle', msg.id, msg.thread_id, msg.sender_id,
    msg.body, msg.created_at, v_deleted_at, v_purge_at
  from public.family_messages msg
  join public.family_message_threads thread on thread.id = msg.thread_id
  where msg.kind = 'message' and (thread.seeker_id = old.id or msg.sender_id = old.id)
  on conflict (source, source_message_id) do nothing;

  insert into private.zyra_report_sealed_messages(report_id, sealed_message_id)
  select protection.report_id, sealed.id
  from private.report_protected_attempts protection
  join public.conversations conversation on conversation.attempt_id = protection.attempt_id
  join private.safety_sealed_messages sealed on sealed.thread_id = conversation.id
    and sealed.source = 'journey'
  where conversation.match_id = any(v_match_ids)
  on conflict do nothing;

  insert into private.zyra_circle_seal_protections(sealed_message_id, report_id)
  select sealed.id, report.id
  from public.family_message_reports report
  join public.family_message_threads thread on thread.id = report.thread_id
  join private.safety_sealed_messages sealed
    on sealed.source = 'guardian_circle' and sealed.thread_id = report.thread_id
  where thread.seeker_id = old.id
    or (sealed.source_message_id = report.message_id and sealed.sender_id = old.id)
  on conflict do nothing;

  update public.family_message_reports report
  set sealed_message_id = protection.sealed_message_id
  from private.zyra_circle_seal_protections protection
  join private.safety_sealed_messages sealed on sealed.id = protection.sealed_message_id
  where report.id = protection.report_id and report.message_id = sealed.source_message_id;

  -- A Circle is currently keyed by its owning Seeker. That owner's entire
  -- Circle disappears. In another Seeker's Circle, remove the deleted
  -- account's own contributions and let its membership FK cascade.
  delete from public.family_message_threads where seeker_id = old.id;
  with removed as (
    delete from public.family_messages where sender_id = old.id returning thread_id
  )
  update public.family_message_threads thread
  set last_message_at = (
    select max(msg.created_at) from public.family_messages msg
    where msg.thread_id = thread.id and msg.sender_id is distinct from old.id
  )
  where thread.id in (select thread_id from removed);

  -- Recipient identity is needed only for this insert. DISTINCT covers
  -- pairs with multiple attempts and an existing Journey plus requests.
  insert into public.notifications(user_id, type, title, body, payload)
  select distinct survivor.id, 'journey_ended_profile_inactive',
    'One of your Journeys has ended',
    'This profile is no longer active. Your place is free for a new Journey.', '{}'::jsonb
  from public.matches m
  join public.profiles survivor on survivor.id =
    case when m.seeker_a_id = old.id then m.seeker_b_id else m.seeker_a_id end
  where m.id = any(v_match_ids) and survivor.role = 'seeker'
    and (m.status in ('active', 'ended') or exists (
      select 1 from public.journey_attempts a
      where a.match_id = m.id and a.status in ('active', 'ended')
    ));

  delete from public.notifications where related_match_id = any(v_match_ids);
  delete from public.journey_requests
  where match_id = any(v_match_ids) or old.id in (requested_by, requested_to);
  delete from public.wali_suggestions where old.id in (wali_id, seeker_id, suggested_id);

  insert into private.zyra_account_deleted_matches(match_id)
  select unnest(v_match_ids);

  -- Preserve the records whose author FK would otherwise erase content
  -- even when its parent attempt is protected. Unprotected attempts and
  -- their temporary snapshots are purged together below.
  insert into private.zyra_deleted_attempt_evidence(attempt_id, records)
  select a.id, jsonb_build_object(
    'message_senders', (select jsonb_agg(jsonb_build_object('id', msg.id, 'sender_id', msg.sender_id))
      from public.messages msg join public.conversations c on c.id = msg.conversation_id
      where c.attempt_id = a.id and msg.sender_id = old.id),
    'family_answers', (select jsonb_agg(to_jsonb(r)) from public.journey_family_answers r
      where r.attempt_id = a.id and r.answerer_id = old.id),
    'guardian_assignments', (select jsonb_agg(to_jsonb(r))
      from public.journey_guardian_assignments r
      join public.wali_links link on link.id = r.wali_link_id
      where r.attempt_id = a.id
        and old.id in (r.seeker_id, r.granted_by, r.revoked_by, link.wali_id)),
    'milestone_attestations', (select jsonb_agg(to_jsonb(r)) from public.journey_milestone_attestations r
      where r.attempt_id = a.id and old.id in (r.proposed_by, r.confirmed_by)),
    'phase_answers', (select jsonb_agg(to_jsonb(r)) from public.journey_phase_answers r
      where r.attempt_id = a.id and r.seeker_id = old.id),
    'phase_checkpoints', (select jsonb_agg(to_jsonb(r)) from public.journey_phase_checkpoints r
      where r.attempt_id = a.id and r.seeker_id = old.id),
    'phase_ratings', (select jsonb_agg(to_jsonb(r)) from public.journey_phase_ratings r
      where r.attempt_id = a.id and r.rater_id = old.id),
    'salams', (select jsonb_agg(to_jsonb(r)) from public.journey_salams r
      where r.attempt_id = a.id and r.seeker_id = old.id),
    'stage_checkpoints', (select jsonb_agg(to_jsonb(r)) from public.journey_stage_checkpoints r
      where r.attempt_id = a.id and r.seeker_id = old.id)
  )
  from public.journey_attempts a where a.match_id = any(v_match_ids)
    and (private.zyra_attempt_has_open_report(a.id)
      or private.zyra_match_has_active_hold(a.match_id));

  -- Clear both participant keys before later FK cascades. Null keys and the
  -- private marker give retained records no membership or restart route.
  update public.matches
  set seeker_a_id = null, seeker_b_id = null,
      status = 'ended', ended_at = coalesce(ended_at, v_deleted_at),
      suspended_by = null, suspended_at = null, also_paused_by = null, also_paused_at = null
  where id = any(v_match_ids);

  update public.journey_attempts
  set status = 'ended', ended_at = coalesce(ended_at, v_deleted_at),
      paused_by = null, paused_at = null, also_paused_by = null, also_paused_at = null
  where match_id = any(v_match_ids);

  update public.conversations
  set status = 'closed', closed_at = coalesce(closed_at, v_deleted_at)
  where match_id = any(v_match_ids);

  foreach v_match_id in array v_match_ids loop
    perform private.zyra_purge_account_deleted_match(v_match_id);
  end loop;
  return old;
end;
$$;
revoke all on function private.zyra_remove_departing_profile()
  from public, anon, authenticated, service_role;

drop trigger profiles_mark_family_message_sender_deleted on public.profiles;
create trigger profiles_remove_departing_profile
before delete on public.profiles
for each row execute function private.zyra_remove_departing_profile();

insert into private.safety_sealed_messages
  (source, source_message_id, thread_id, sender_id, body, sent_at, sealed_at, purge_at)
select 'guardian_circle', message.id, message.thread_id, null, message.body,
  message.created_at, message.sender_deleted_at, message.sender_deleted_at + interval '8760 hours'
from public.family_messages message
where message.sender_id is null and message.kind = 'message'
  and message.sender_deleted_at + interval '8760 hours' > now();

update public.family_message_reports report
set sealed_message_id = sealed.id
from private.safety_sealed_messages sealed
where sealed.source = 'guardian_circle' and sealed.source_message_id = report.message_id;

delete from public.family_messages where sender_id is null and kind = 'message';

alter table public.family_messages
  drop constraint family_messages_sender_shape,
  add constraint family_messages_sender_shape check (
    (kind = 'message' and sender_id is not null)
    or (kind = 'lifecycle' and sender_id is null)
  );

commit;
