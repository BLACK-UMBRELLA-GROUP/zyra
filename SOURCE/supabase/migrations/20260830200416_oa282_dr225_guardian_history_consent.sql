-- OA-ZYRA-282 / DR-ZYRA-225 / 051 Phase 0 / 054 N1 revision.
--
-- STAGED ONLY. Do not apply without the separate Founder apply GO after
-- Fable verification and external security review.
--
-- Consent mechanism:
--   * wali_links.main_guardian_authority_id is an opaque assignment epoch.
--   * It exists only while that exact link is the active Main relationship.
--   * It rotates whenever a link becomes Main after not being Main.
--   * The consent row must match both the link id and its current epoch.
--   * wali_links.active_since is the current continuous active-link boundary.
--   * It is fresh on activation/reactivation and survives uninterrupted role
--     switches; wali_links.created_at remains immutable row provenance.
--
-- This is intentionally stronger than binding consent to wali_links.id alone:
-- accept_wali_invite() reuses removed rows, so a row-id-only grant could revive
-- after removal/relinking or after a former Main was promoted again.

-- =====================================================================
-- A. Track each active-link period and each Main assignment epoch.
-- =====================================================================
alter table public.wali_links
  add column main_guardian_authority_id uuid,
  add column active_since timestamptz;

-- Existing dev/test active rows predate active-period tracking. created_at is
-- the dispositioned best provable proxy for their current uninterrupted
-- period and is used only for this one backfill; it is never repurposed or
-- refreshed.
update public.wali_links
set active_since = created_at
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
    elsif old.status is distinct from 'active'
       or old.active_since is null then
      new.active_since := pg_catalog.clock_timestamp();
    else
      -- Main/Additional switches and unrelated updates do not restart a
      -- continuously active relationship period.
      new.active_since := old.active_since;
    end if;
  else
    new.active_since := null;
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
      -- An unrelated update cannot rotate or replace a live assignment id.
      new.main_guardian_authority_id := old.main_guardian_authority_id;
    end if;
  else
    new.main_guardian_authority_id := null;
  end if;

  return new;
end;
$function$;

comment on function public.auto_designate_main_wali() is
  'DR-ZYRA-225. Preserves first-active-link Main designation and maintains '
  'the opaque Main-assignment authority id used to bind full-history consent. '
  'The id is non-null only for the active Main and rotates on every fresh Main '
  'assignment, including removed-then-relinked relationships. Also maintains '
  'active_since as the current continuous active-link period: fresh on every '
  'activation, preserved across uninterrupted role/unrelated updates, and '
  'null while inactive.';

revoke execute on function public.auto_designate_main_wali()
  from public, anon, authenticated;
grant execute on function public.auto_designate_main_wali()
  to service_role;

-- Let the revised trigger issue an epoch for every currently active Main.
-- No existing consent rows exist, so this backfill grants no visibility.
update public.wali_links
set main_guardian_authority_id = pg_catalog.gen_random_uuid()
where status = 'active'
  and is_main is true;

alter table public.wali_links
  add constraint wali_links_main_guardian_authority_state
  check (
    (
      status = 'active'
      and is_main is true
      and main_guardian_authority_id is not null
    )
    or (
      (status <> 'active' or is_main is false)
      and main_guardian_authority_id is null
    )
  ),
  add constraint wali_links_active_since_state
  check (
    (
      status = 'active'
      and active_since is not null
    )
    or (
      status <> 'active'
      and active_since is null
    )
  );

comment on column public.wali_links.main_guardian_authority_id is
  'DR-ZYRA-225: opaque current-Main assignment epoch. Rotates whenever this '
  'link freshly becomes Main; null for every non-current-Main link. It is not '
  'a historical role timestamp and is never displayed.';

comment on column public.wali_links.active_since is
  'DR-ZYRA-225 / 054 N1: server-authoritative start of this link row''s '
  'current continuous active period. Fresh on activation/reactivation, '
  'preserved across uninterrupted Main/Additional switches and unrelated '
  'updates, null while inactive. created_at remains row provenance.';

-- =====================================================================
-- B. Store only the current full-history visibility grant.
-- =====================================================================
create table public.guardian_journey_history_consents (
  wali_link_id uuid primary key
    references public.wali_links(id) on delete cascade,
  main_guardian_authority_id uuid not null,
  granted_at timestamptz not null default pg_catalog.clock_timestamp()
);

comment on table public.guardian_journey_history_consents is
  'DR-ZYRA-225 current-state visibility consent. A row is valid only when its '
  'wali_link_id and opaque authority id match the caller''s current active Main '
  'link. Absent or mismatched means OFF. Client writes are forbidden; use '
  'zyra_main_guardian_history_consent(boolean).';

comment on column
  public.guardian_journey_history_consents.main_guardian_authority_id is
  'Snapshot of wali_links.main_guardian_authority_id at grant time. A mismatch '
  'invalidates consent structurally after reassignment, removal or relinking.';

alter table public.guardian_journey_history_consents enable row level security;

-- No policies by design: neither authenticated nor anon can read or write the
-- table directly. Both state reads and changes go through the caller-bound RPC.
revoke all on table public.guardian_journey_history_consents
  from public, anon, authenticated;
grant select, insert, update, delete
  on table public.guardian_journey_history_consents
  to service_role;

-- =====================================================================
-- C. One Seeker-only RPC reads or sets the current consent state.
--
-- p_enabled = null  -> read confirmed server state
-- p_enabled = true  -> grant against the current Main assignment
-- p_enabled = false -> revoke immediately
-- =====================================================================
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
  v_link_id uuid;
  v_guardian_id uuid;
  v_authority_id uuid;
begin
  if v_caller is null then
    raise exception 'not_signed_in';
  end if;

  -- No caller-supplied Seeker id exists. Ownership is always the signed-in
  -- person's own seeker_id side of the current active Main link.
  select
    w.id,
    w.wali_id,
    w.main_guardian_authority_id
  into v_link_id, v_guardian_id, v_authority_id
  from public.wali_links w
  where w.seeker_id = v_caller
    and w.status = 'active'
    and w.is_main is true;

  if not found then
    if p_enabled is true then
      raise exception 'main_guardian_required_for_history_consent';
    end if;

    return query
    select false, null::uuid, null::uuid;
    return;
  end if;

  if p_enabled is true then
    insert into public.guardian_journey_history_consents (
      wali_link_id,
      main_guardian_authority_id,
      granted_at
    ) values (
      v_link_id,
      v_authority_id,
      pg_catalog.clock_timestamp()
    )
    on conflict (wali_link_id) do update
      set main_guardian_authority_id = excluded.main_guardian_authority_id,
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
        and c.main_guardian_authority_id = v_authority_id
    ),
    v_link_id,
    v_guardian_id;
end;
$function$;

comment on function public.zyra_main_guardian_history_consent(boolean) is
  'DR-ZYRA-225 / 051 Phase 0. Seeker-only, caller-derived control for the '
  'current Main Guardian full-Journey-history grant. NULL reads server state; '
  'TRUE grants; FALSE revokes. The returned state is authoritative. No Main '
  'plus TRUE raises main_guardian_required_for_history_consent.';

revoke execute on function public.zyra_main_guardian_history_consent(boolean)
  from public, anon;
grant execute on function public.zyra_main_guardian_history_consent(boolean)
  to authenticated, service_role;

-- =====================================================================
-- D. Replace the summary predicate with the DR-ZYRA-225 positive allowlist.
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
  current_main_link as materialized (
    select
      w.id,
      w.active_since,
      w.main_guardian_authority_id
    from public.wali_links w
    cross join caller c
    where c.user_id is not null
      and w.seeker_id = p_seeker
      and w.wali_id = c.user_id
      and w.status = 'active'
      and w.is_main is true
  )
  select
    a.id,
    a.started_at,
    a.ended_at,
    (a.status = 'ended')
  from public.journey_attempts a
  join public.matches m on m.id = a.match_id
  cross join current_main_link w
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
              and c.main_guardian_authority_id =
                w.main_guardian_authority_id
          )
        )
      )
    );
$function$;

comment on function public.zyra_attempt_summary_for_guardian(uuid) is
  'DR-ZYRA-225 / 051 Phase 0 / 054 N1. CALLER-BOUND ACTIVE MAIN ONLY. '
  'Always returns '
  'the current active/paused attempt; returns ended attempts only when ended '
  'on/after the current continuous active-link period began or a valid '
  'link-and-assignment-bound '
  'full-history grant exists. Positive active/ended allowlist fails future '
  'statuses closed. Four fields only; never counterpart, stage, messages, '
  'answers, reason, notes or safety information.';

revoke execute on function public.zyra_attempt_summary_for_guardian(uuid)
  from public, anon;
grant execute on function public.zyra_attempt_summary_for_guardian(uuid)
  to authenticated, service_role;
