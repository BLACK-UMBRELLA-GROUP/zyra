-- OA-ZYRA-291 / DR-ZYRA-233
--
-- Founder ruling, 2026-09-18:
--   * every current Guardian may be granted access to past Journey summaries;
--   * the permission is individual, OFF by default, immediately revocable and
--     bound to the current continuous active link period;
--   * a Main/Additional role switch does not transfer the permission to a
--     different person and does not silently revoke it from the same person;
--   * the existing four-field summary cap remains absolute;
--   * current-Journey Additional access remains governed separately by
--     DR-ZYRA-232 and journey_guardian_assignments;
--   * Guardian comments are NOT message sending and are not built here.
--
-- STAGED ONLY. Do not apply without a separate exact-file Founder GO.

begin;

-- =====================================================================
-- A. Bind the permission to one continuous active Guardian-link period.
--
-- main_guardian_authority_id remains for historical compatibility and Main-
-- assignment invariants. guardian_link_authority_id is role-neutral: it is
-- fresh on activation/reactivation, preserved while the same link remains
-- continuously active, and cleared on removal/inactivity.
-- =====================================================================
alter table public.wali_links
  add column guardian_link_authority_id uuid;

update public.wali_links
set guardian_link_authority_id = case
  when is_main is true and main_guardian_authority_id is not null
    then main_guardian_authority_id
  else pg_catalog.gen_random_uuid()
end
where status = 'active';

create or replace function public.auto_designate_main_wali()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.status = 'active' then
    if tg_op = 'INSERT' then
      new.active_since := pg_catalog.clock_timestamp();
      new.guardian_link_authority_id := pg_catalog.gen_random_uuid();
    elsif old.status is distinct from 'active'
       or old.active_since is null
       or old.guardian_link_authority_id is null then
      new.active_since := pg_catalog.clock_timestamp();
      new.guardian_link_authority_id := pg_catalog.gen_random_uuid();
    else
      -- Role changes and unrelated updates do not restart one continuous
      -- relationship period or rotate its per-person history permission.
      new.active_since := old.active_since;
      new.guardian_link_authority_id := old.guardian_link_authority_id;
    end if;
  else
    new.active_since := null;
    new.guardian_link_authority_id := null;
  end if;

  if new.status = 'active' and not exists (
    select 1
    from public.wali_links w
    where w.seeker_id = new.seeker_id
      and w.is_main is true
      and w.status = 'active'
  ) then
    new.is_main := true;
  end if;

  if new.status = 'active' and new.is_main is true then
    if tg_op = 'INSERT' then
      new.main_guardian_authority_id := pg_catalog.gen_random_uuid();
    elsif old.status is distinct from 'active'
       or old.is_main is distinct from true
       or old.main_guardian_authority_id is null then
      new.main_guardian_authority_id := pg_catalog.gen_random_uuid();
    else
      new.main_guardian_authority_id := old.main_guardian_authority_id;
    end if;
  else
    new.main_guardian_authority_id := null;
  end if;

  return new;
end;
$function$;

comment on function public.auto_designate_main_wali() is
  'DR-ZYRA-225/233. Preserves first-active-link Main designation; maintains '
  'the Main-assignment epoch; and maintains a separate role-neutral active-'
  'link epoch for per-Guardian past-summary permission. The link epoch rotates '
  'on activation/reactivation, survives continuous Main/Additional switches, '
  'and is null while inactive.';

revoke execute on function public.auto_designate_main_wali()
  from public, anon, authenticated;
grant execute on function public.auto_designate_main_wali()
  to service_role;

alter table public.wali_links
  add constraint wali_links_guardian_link_authority_state
  check (
    (status = 'active' and guardian_link_authority_id is not null)
    or
    (status <> 'active' and guardian_link_authority_id is null)
  );

comment on column public.wali_links.guardian_link_authority_id is
  'DR-ZYRA-233 opaque current-active-link epoch for one Seeker/Guardian '
  'relationship. Fresh on activation/reactivation, preserved across '
  'continuous Main/Additional switches, null while inactive, never displayed.';

-- =====================================================================
-- B. Generalise the existing private consent row without losing any current
-- Main permission. Historical/inert rows receive a non-matching opaque value
-- rather than being deleted; only a match to the live link epoch grants data.
-- =====================================================================
alter table public.guardian_journey_history_consents
  add column guardian_link_authority_id uuid;

update public.guardian_journey_history_consents c
set guardian_link_authority_id = coalesce(
  (
    select w.guardian_link_authority_id
    from public.wali_links w
    where w.id = c.wali_link_id
      and w.status = 'active'
      and w.main_guardian_authority_id = c.main_guardian_authority_id
  ),
  pg_catalog.gen_random_uuid()
);

alter table public.guardian_journey_history_consents
  alter column guardian_link_authority_id set not null,
  alter column main_guardian_authority_id drop not null;

comment on table public.guardian_journey_history_consents is
  'DR-ZYRA-225/233 current-state permission for past Journey summaries. A row '
  'grants only when wali_link_id and guardian_link_authority_id match one '
  'current active link. Absent or mismatched means OFF. No direct client '
  'access; use zyra_guardian_history_consent(uuid, boolean).';

comment on column
  public.guardian_journey_history_consents.guardian_link_authority_id is
  'Snapshot of wali_links.guardian_link_authority_id at grant time. A '
  'mismatch invalidates permission after removal/reactivation without relying '
  'on client cleanup.';

comment on column
  public.guardian_journey_history_consents.main_guardian_authority_id is
  'Legacy DR-ZYRA-225 Main-assignment snapshot retained for compatibility and '
  'audit provenance. New authority uses guardian_link_authority_id.';

-- =====================================================================
-- C. One Seeker-owned RPC reads or changes one linked Guardian's permission.
-- p_enabled NULL reads; TRUE grants; FALSE revokes. The response is the only
-- state the client may render as confirmed.
-- =====================================================================
create or replace function public.zyra_guardian_history_consent(
  p_guardian uuid,
  p_enabled boolean default null
)
returns table (
  enabled boolean,
  active_guardian_link_id uuid,
  guardian_id uuid,
  guardian_is_main boolean
)
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
  v_caller uuid := (select auth.uid());
  v_link_id uuid;
  v_link_authority_id uuid;
  v_main_authority_id uuid;
  v_is_main boolean;
begin
  if v_caller is null then
    raise exception 'not_signed_in';
  end if;
  if p_guardian is null then
    raise exception 'guardian_required';
  end if;

  select
    w.id,
    w.guardian_link_authority_id,
    w.main_guardian_authority_id,
    w.is_main
  into
    v_link_id,
    v_link_authority_id,
    v_main_authority_id,
    v_is_main
  from public.wali_links w
  where w.seeker_id = v_caller
    and w.wali_id = p_guardian
    and w.status = 'active';

  if not found then
    if p_enabled is true then
      raise exception 'active_guardian_required_for_history_consent';
    end if;
    return query
    select false, null::uuid, null::uuid, null::boolean;
    return;
  end if;

  if p_enabled is true then
    insert into public.guardian_journey_history_consents (
      wali_link_id,
      main_guardian_authority_id,
      guardian_link_authority_id,
      granted_at
    ) values (
      v_link_id,
      v_main_authority_id,
      v_link_authority_id,
      pg_catalog.clock_timestamp()
    )
    on conflict (wali_link_id) do update
      set main_guardian_authority_id = excluded.main_guardian_authority_id,
          guardian_link_authority_id = excluded.guardian_link_authority_id,
          granted_at = excluded.granted_at;
  elsif p_enabled is false then
    delete from public.guardian_journey_history_consents c
    where c.wali_link_id = v_link_id;
  end if;

  return query
  select
    exists (
      select 1
      from public.guardian_journey_history_consents c
      where c.wali_link_id = v_link_id
        and c.guardian_link_authority_id = v_link_authority_id
    ),
    v_link_id,
    p_guardian,
    v_is_main;
end;
$function$;

comment on function public.zyra_guardian_history_consent(uuid, boolean) is
  'DR-ZYRA-233 Seeker-owned, caller-derived permission for one current active '
  'Guardian to see all past four-field Journey summaries. NULL reads; TRUE '
  'grants; FALSE revokes. No counterpart identity, stage, messages, answers, '
  'reasons, notes or safety information is returned or authorised.';

revoke execute on function public.zyra_guardian_history_consent(uuid, boolean)
  from public, anon;
grant execute on function public.zyra_guardian_history_consent(uuid, boolean)
  to authenticated, service_role;

-- Preserve the public Main-only RPC contract for older clients while routing
-- its authority through the same role-neutral link-bound store.
create or replace function public.zyra_main_guardian_history_consent(
  p_enabled boolean default null
)
returns table (
  enabled boolean,
  active_main_link_id uuid,
  main_guardian_id uuid
)
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
  v_caller uuid := (select auth.uid());
  v_guardian uuid;
begin
  if v_caller is null then
    raise exception 'not_signed_in';
  end if;

  select w.wali_id
  into v_guardian
  from public.wali_links w
  where w.seeker_id = v_caller
    and w.status = 'active'
    and w.is_main is true;

  if not found then
    if p_enabled is true then
      raise exception 'main_guardian_required_for_history_consent';
    end if;
    return query select false, null::uuid, null::uuid;
    return;
  end if;

  return query
  select
    state.enabled,
    state.active_guardian_link_id,
    state.guardian_id
  from public.zyra_guardian_history_consent(v_guardian, p_enabled) state;
end;
$function$;

comment on function public.zyra_main_guardian_history_consent(boolean) is
  'Compatibility wrapper for DR-ZYRA-225 clients. Reads or changes the '
  'current Main Guardian through zyra_guardian_history_consent(uuid, boolean).';

revoke execute on function public.zyra_main_guardian_history_consent(boolean)
  from public, anon;
grant execute on function public.zyra_main_guardian_history_consent(boolean)
  to authenticated, service_role;

-- =====================================================================
-- D. Every active Guardian keeps the DR-ZYRA-230 default summary. A valid
-- per-link permission widens ended summaries for that same Guardian only.
-- =====================================================================
create or replace function public.zyra_attempt_summary_for_guardian(
  p_seeker uuid
)
returns table (
  attempt_id uuid,
  started_at timestamptz,
  ended_at timestamptz,
  ended boolean
)
language sql
stable
security definer
set search_path = ''
as $function$
  with caller as materialized (
    select (select auth.uid()) as user_id
  ),
  current_guardian_link as materialized (
    select
      w.id,
      w.active_since,
      w.guardian_link_authority_id
    from public.wali_links w
    cross join caller c
    where c.user_id is not null
      and w.seeker_id = p_seeker
      and w.wali_id = c.user_id
      and w.status = 'active'
  )
  select
    a.id,
    a.started_at,
    a.ended_at,
    (a.status = 'ended')
  from public.journey_attempts a
  join public.matches m on m.id = a.match_id
  cross join current_guardian_link w
  where p_seeker in (m.seeker_a_id, m.seeker_b_id)
    and (
      a.status = 'active'
      or (
        a.status = 'ended'
        and (
          a.ended_at >= w.active_since
          or exists (
            select 1
            from public.guardian_journey_history_consents c
            where c.wali_link_id = w.id
              and c.guardian_link_authority_id =
                w.guardian_link_authority_id
          )
        )
      )
    );
$function$;

comment on function public.zyra_attempt_summary_for_guardian(uuid) is
  'DR-ZYRA-230/233. CALLER-BOUND ACTIVE GUARDIANS. Every active Guardian sees '
  'the current active/paused attempt plus ended attempts from the current '
  'continuous link period. A valid per-link Seeker permission widens to all '
  'ended summaries for that same Guardian. Positive active/ended allowlist '
  'fails future statuses closed. Four fields only; never counterpart, stage, '
  'messages, answers, reasons, notes or safety data.';

revoke execute on function public.zyra_attempt_summary_for_guardian(uuid)
  from public, anon;
grant execute on function public.zyra_attempt_summary_for_guardian(uuid)
  to authenticated, service_role;

commit;
