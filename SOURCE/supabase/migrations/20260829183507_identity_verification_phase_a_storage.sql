-- OA-ZYRA-266 / DR-ZYRA-220 / DR-ZYRA-221 — PHASE A, STAGED ONLY.
--
-- IMPORTANT: this migration has NOT been applied. Founder GO is required.
-- Applying it creates the private state store and narrow RPC boundary; it
-- does not activate the existing-account app gate by itself.
--
-- Data minimisation from 027 §3/§4 is structural here: there is nowhere to
-- store an ID document, selfie, face template, score, extracted PII, duplicate
-- hit, provider reason or raw webhook payload. Phase B must collapse provider
-- data in memory before calling the service-role result function below.

begin;

create schema if not exists private;
revoke all on schema private from public;
revoke all on schema private from anon;
revoke all on schema private from authenticated;
grant usage on schema private to service_role;

create table private.identity_verification_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider_code text not null default 'sumsub'
    check (provider_code in ('sumsub', 'stripe')),
  provider_session_ref text unique
    check (
      provider_session_ref is null
      or char_length(provider_session_ref) between 1 and 255
    ),
  result text not null
    check (result in (
      'pending',
      'verified',
      'retry_required',
      'review_required',
      'failed',
      'expired',
      'cancelled'
    )),
  -- NULL = not_evaluated, FALSE = clear, TRUE = human review required.
  duplicate_review_required boolean,
  -- SHA-256 hex only. Never store the provider event id or raw event body.
  provider_event_ref_hash text unique
    check (
      provider_event_ref_hash is null
      or provider_event_ref_hash ~ '^[0-9a-f]{64}$'
    ),
  consent_granted boolean not null,
  consent_version text not null
    check (consent_version ~ '^[a-z0-9][a-z0-9._-]{0,79}$'),
  consent_recorded_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  decided_at timestamptz,
  -- User-visible deletion removes the attempt from current-state reads while
  -- retaining the minimal consent event needed to evidence the decision.
  member_deleted_at timestamptz,
  constraint identity_verification_verified_not_duplicate check (
    result <> 'verified' or duplicate_review_required is distinct from true
  ),
  constraint identity_verification_duplicate_routes_to_review check (
    duplicate_review_required is distinct from true
    or result = 'review_required'
  ),
  constraint identity_verification_final_has_decision_time check (
    result in ('pending', 'retry_required', 'review_required')
    or decided_at is not null
  )
);

comment on table private.identity_verification_attempts is
  'PRIVATE SERVER-OWNED IDV state. No biometric/document/selfie/PII/raw '
  'provider payload columns are permitted. Ordinary clients use only the '
  'caller-scoped public RPCs in this migration.';
comment on column private.identity_verification_attempts.provider_session_ref is
  'Opaque provider reference only; never email, name, document data or a URL.';
comment on column private.identity_verification_attempts.duplicate_review_required is
  'NULL=not_evaluated, FALSE=clear, TRUE=manual review. Never contains a hit id, score or reason.';
comment on column private.identity_verification_attempts.provider_event_ref_hash is
  'SHA-256 event-reference hash for idempotency; never the raw provider event id.';

create index identity_verification_attempts_user_created
  on private.identity_verification_attempts(user_id, created_at desc);

create unique index identity_verification_attempts_one_open_per_user
  on private.identity_verification_attempts(user_id)
  where member_deleted_at is null
    and result in ('pending', 'retry_required', 'review_required');

create unique index identity_verification_attempts_one_verified_per_user
  on private.identity_verification_attempts(user_id)
  where member_deleted_at is null and result = 'verified';

-- Hash-only receipt ledger. Keeping only the latest hash on the attempt would
-- forget older events and let a delayed replay through after a later event.
create table private.identity_verification_event_receipts (
  provider_event_ref_hash text primary key
    check (provider_event_ref_hash ~ '^[0-9a-f]{64}$'),
  attempt_id uuid not null
    references private.identity_verification_attempts(id) on delete cascade,
  mapped_result text not null
    check (mapped_result in (
      'pending', 'verified', 'retry_required', 'review_required',
      'failed', 'expired', 'cancelled'
    )),
  received_at timestamptz not null default now()
);

comment on table private.identity_verification_event_receipts is
  'Hash-only webhook idempotency ledger. No provider event id, body, header, '
  'reason, PII, biometric data or duplicate-hit detail.';

alter table private.identity_verification_attempts enable row level security;
revoke all on table private.identity_verification_attempts from public;
revoke all on table private.identity_verification_attempts from anon;
revoke all on table private.identity_verification_attempts from authenticated;
grant select, insert, update on table private.identity_verification_attempts
  to service_role;
alter table private.identity_verification_event_receipts enable row level security;
revoke all on table private.identity_verification_event_receipts from public;
revoke all on table private.identity_verification_event_receipts from anon;
revoke all on table private.identity_verification_event_receipts from authenticated;
grant select, insert on table private.identity_verification_event_receipts
  to service_role;

create or replace function private.zyra_touch_identity_verification_attempt()
returns trigger
language plpgsql
set search_path = pg_catalog, private
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke execute on function private.zyra_touch_identity_verification_attempt()
  from public;

create trigger identity_verification_attempts_updated_at
before update on private.identity_verification_attempts
for each row execute function private.zyra_touch_identity_verification_attempt();

create or replace function public.zyra_my_identity_verification_state()
returns jsonb
language plpgsql
stable
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_me uuid := auth.uid();
  v_attempt private.identity_verification_attempts%rowtype;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;

  select * into v_attempt
  from private.identity_verification_attempts
  where user_id = v_me and member_deleted_at is null
  order by
    (result = 'verified') desc,
    created_at desc
  limit 1;

  if not found then return null; end if;

  return jsonb_build_object(
    'result', v_attempt.result,
    'duplicate_review_required', v_attempt.duplicate_review_required,
    'consent_granted', v_attempt.consent_granted,
    'consent_version', v_attempt.consent_version,
    'consent_recorded_at', v_attempt.consent_recorded_at,
    'updated_at', v_attempt.updated_at,
    'decided_at', v_attempt.decided_at
  );
end;
$$;

revoke execute on function public.zyra_my_identity_verification_state()
  from public;
revoke execute on function public.zyra_my_identity_verification_state()
  from anon;
grant execute on function public.zyra_my_identity_verification_state()
  to authenticated;

create or replace function public.zyra_record_identity_verification_consent(
  p_consent_version text,
  p_granted boolean
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_me uuid := auth.uid();
  v_attempt private.identity_verification_attempts%rowtype;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;
  if p_consent_version is distinct from
     'idv_sumsub_biometric_v1_2026-08-29' then
    raise exception 'unsupported_consent_version';
  end if;

  -- Verified is terminal. A public client cannot create a fresh pending row
  -- over it or use consent replay to move itself backwards/forwards.
  select * into v_attempt
  from private.identity_verification_attempts
  where user_id = v_me
    and member_deleted_at is null
    and result = 'verified'
  limit 1;

  if not found then
    -- Close unfinished unbound attempts before recording a new explicit
    -- decision. A provider-bound attempt is left untouched and must be
    -- resolved through the Phase B webhook adapter.
    update private.identity_verification_attempts
       set result = 'cancelled',
           decided_at = coalesce(decided_at, now())
     where user_id = v_me
       and member_deleted_at is null
       and provider_session_ref is null
       and result in ('pending', 'retry_required', 'review_required');

    insert into private.identity_verification_attempts (
      user_id,
      result,
      consent_granted,
      consent_version,
      decided_at
    ) values (
      v_me,
      case when p_granted then 'pending' else 'cancelled' end,
      p_granted,
      p_consent_version,
      case when p_granted then null else now() end
    )
    returning * into v_attempt;
  end if;

  return jsonb_build_object(
    'result', v_attempt.result,
    'duplicate_review_required', v_attempt.duplicate_review_required,
    'consent_granted', v_attempt.consent_granted,
    'consent_version', v_attempt.consent_version,
    'consent_recorded_at', v_attempt.consent_recorded_at,
    'updated_at', v_attempt.updated_at,
    'decided_at', v_attempt.decided_at
  );
end;
$$;

revoke execute on function public.zyra_record_identity_verification_consent(text, boolean)
  from public;
revoke execute on function public.zyra_record_identity_verification_consent(text, boolean)
  from anon;
grant execute on function public.zyra_record_identity_verification_consent(text, boolean)
  to authenticated;

create or replace function public.zyra_delete_my_unstarted_identity_verification_attempt()
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_me uuid := auth.uid();
  v_id uuid;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;

  select id into v_id
  from private.identity_verification_attempts
  where user_id = v_me
    and member_deleted_at is null
    and provider_session_ref is null
    and result in ('pending', 'retry_required', 'failed', 'expired', 'cancelled')
  order by created_at desc
  limit 1
  for update;

  if v_id is null then return false; end if;

  update private.identity_verification_attempts
     set member_deleted_at = now(),
         result = 'cancelled',
         decided_at = coalesce(decided_at, now())
   where id = v_id;
  return true;
end;
$$;

revoke execute on function public.zyra_delete_my_unstarted_identity_verification_attempt()
  from public;
revoke execute on function public.zyra_delete_my_unstarted_identity_verification_attempt()
  from anon;
grant execute on function public.zyra_delete_my_unstarted_identity_verification_attempt()
  to authenticated;

-- Phase B Edge Function A calls this with service_role after creating or
-- reusing the provider session. The client never receives the opaque session
-- reference from this table.
create or replace function public.zyra_attach_identity_verification_provider_session(
  p_user_id uuid,
  p_provider_code text,
  p_provider_session_ref text
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_id uuid;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'service_role_required';
  end if;
  if p_provider_code not in ('sumsub', 'stripe') then
    raise exception 'unsupported_provider';
  end if;
  if p_provider_session_ref is null
     or char_length(p_provider_session_ref) not between 1 and 255 then
    raise exception 'invalid_provider_session_ref';
  end if;

  select id into v_id
  from private.identity_verification_attempts
  where user_id = p_user_id
    and member_deleted_at is null
    and consent_granted
    and result in ('pending', 'retry_required')
    and (provider_session_ref is null
         or provider_session_ref = p_provider_session_ref)
  order by created_at desc
  limit 1
  for update;

  if v_id is null then raise exception 'no_eligible_attempt'; end if;

  update private.identity_verification_attempts
     set provider_code = p_provider_code,
         provider_session_ref = p_provider_session_ref,
         result = 'pending'
   where id = v_id;
  return true;
end;
$$;

revoke execute on function public.zyra_attach_identity_verification_provider_session(uuid, text, text)
  from public;
revoke execute on function public.zyra_attach_identity_verification_provider_session(uuid, text, text)
  from anon;
revoke execute on function public.zyra_attach_identity_verification_provider_session(uuid, text, text)
  from authenticated;
grant execute on function public.zyra_attach_identity_verification_provider_session(uuid, text, text)
  to service_role;

-- Phase B Edge Function B supplies only already-collapsed values. The raw
-- signed payload is verified and discarded before this function is called.
create or replace function public.zyra_record_identity_verification_provider_result(
  p_provider_code text,
  p_provider_session_ref text,
  p_result text,
  p_duplicate_review_required boolean,
  p_provider_event_ref_hash text
)
returns boolean
language plpgsql
security definer
set search_path = pg_catalog, public, private
as $$
declare
  v_attempt private.identity_verification_attempts%rowtype;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'service_role_required';
  end if;
  if p_result not in (
    'pending', 'verified', 'retry_required', 'review_required',
    'failed', 'expired', 'cancelled'
  ) then
    raise exception 'invalid_coarse_result';
  end if;
  if p_provider_event_ref_hash is null
     or p_provider_event_ref_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid_event_reference_hash';
  end if;
  if p_duplicate_review_required is true and p_result <> 'review_required' then
    raise exception 'duplicate_requires_review';
  end if;
  if p_result = 'verified' and p_duplicate_review_required is true then
    raise exception 'verified_cannot_require_duplicate_review';
  end if;

  -- Idempotency: a replay of an already-durable event is a success.
  if exists (
    select 1 from private.identity_verification_event_receipts
    where provider_event_ref_hash = p_provider_event_ref_hash
  ) then
    return true;
  end if;

  select * into v_attempt
  from private.identity_verification_attempts
  where provider_code = p_provider_code
    and provider_session_ref = p_provider_session_ref
    and member_deleted_at is null
  limit 1
  for update;

  if not found then raise exception 'unknown_provider_session'; end if;

  -- Allowlisted monotonic state machine. Final states never reopen, and a
  -- review can resolve only to another review, verified or failed.
  if not (
    (v_attempt.result in ('pending', 'retry_required') and p_result in (
      'pending', 'retry_required', 'review_required', 'verified',
      'failed', 'expired', 'cancelled'
    ))
    or (v_attempt.result = 'review_required'
        and p_result in ('review_required', 'verified', 'failed'))
    or v_attempt.result = p_result
  ) then
    raise exception 'invalid_identity_verification_transition';
  end if;

  update private.identity_verification_attempts
     set result = p_result,
         duplicate_review_required = p_duplicate_review_required,
         provider_event_ref_hash = p_provider_event_ref_hash,
         decided_at = case
           when p_result in ('verified', 'failed', 'expired', 'cancelled')
             then coalesce(decided_at, now())
           else decided_at
         end
   where id = v_attempt.id;

  insert into private.identity_verification_event_receipts (
    provider_event_ref_hash,
    attempt_id,
    mapped_result
  ) values (
    p_provider_event_ref_hash,
    v_attempt.id,
    p_result
  );
  return true;
end;
$$;

revoke execute on function public.zyra_record_identity_verification_provider_result(text, text, text, boolean, text)
  from public;
revoke execute on function public.zyra_record_identity_verification_provider_result(text, text, text, boolean, text)
  from anon;
revoke execute on function public.zyra_record_identity_verification_provider_result(text, text, text, boolean, text)
  from authenticated;
grant execute on function public.zyra_record_identity_verification_provider_result(text, text, text, boolean, text)
  to service_role;

-- Current-user predicates for the app shell and Active Journey boundary.
-- They intentionally accept no user id, so an authenticated caller cannot
-- probe another member's verification state.
create or replace function public.zyra_my_identity_verification_allows_app()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select coalesce((
    select result = 'verified'
    from private.identity_verification_attempts
    where user_id = auth.uid() and member_deleted_at is null
    order by (result = 'verified') desc, created_at desc
    limit 1
  ), false);
$$;

create or replace function public.zyra_my_identity_verification_allows_active_journey()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, private
as $$
  select coalesce((
    select result = 'verified' and duplicate_review_required is false
    from private.identity_verification_attempts
    where user_id = auth.uid() and member_deleted_at is null
    order by (result = 'verified') desc, created_at desc
    limit 1
  ), false);
$$;

revoke execute on function public.zyra_my_identity_verification_allows_app()
  from public;
revoke execute on function public.zyra_my_identity_verification_allows_app()
  from anon;
grant execute on function public.zyra_my_identity_verification_allows_app()
  to authenticated;

revoke execute on function public.zyra_my_identity_verification_allows_active_journey()
  from public;
revoke execute on function public.zyra_my_identity_verification_allows_active_journey()
  from anon;
grant execute on function public.zyra_my_identity_verification_allows_active_journey()
  to authenticated;

commit;
