-- F02 isolated synthetic catalog bootstrap. NEVER run against a project.
-- Reconstructs only the applied authorization slice needed by F02 tests,
-- not a complete Supabase/gateway/auth/provider or 216-migration replay.
-- Historical SQL fragments below are byte-preserved from OA290/OA291.
-- Root supplies this file over stdin to the isolated PG17 test database.
\set ON_ERROR_STOP on

do $synthetic_only$
begin
  if current_database() not like 'zyra_oa305_f02_%'
     or current_user <> 'postgres'
     or current_setting('server_version_num')::integer not between 170000 and 179999
     or exists (select 1 from pg_catalog.pg_tables where schemaname = 'public')
  then raise exception 'F02 synthetic bootstrap requires empty isolated zyra_oa305_f02_* PG17 database';
  end if;
end;
$synthetic_only$;
set zyra.synthetic_f02 = 'yes';

do $roles$
begin
  if not exists (select 1 from pg_roles where rolname='anon') then create role anon nologin; end if;
  if not exists (select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin; end if;
  if not exists (select 1 from pg_roles where rolname='service_role') then create role service_role nologin bypassrls; end if;
end;
$roles$;
create schema auth;
grant usage on schema auth, public to anon, authenticated, service_role;
create function auth.uid() returns uuid language sql stable as $uid$
  select nullif(current_setting('request.jwt.claims', true)::jsonb ->> 'sub', '')::uuid
$uid$;
grant execute on function auth.uid() to anon, authenticated, service_role;

create table public.profiles (
  id uuid primary key, first_name text, surname_line text, date_of_birth date,
  role text, gender text, mobile_number text
);
create table public.matches (
  id uuid primary key, seeker_a_id uuid not null references public.profiles(id),
  seeker_b_id uuid not null references public.profiles(id),
  status text not null, end_reason text
);
create table public.journey_attempts (
  id uuid primary key, match_id uuid not null references public.matches(id),
  status text not null check (status in ('potential','active','ended')),
  started_at timestamptz, ended_at timestamptz,
  paused_by uuid references public.profiles(id), paused_at timestamptz,
  created_at timestamptz not null default now()
);
create table public.wali_links (
  id uuid primary key, seeker_id uuid not null references public.profiles(id),
  wali_id uuid not null references public.profiles(id),
  status text not null, is_main boolean not null default false,
  created_at timestamptz not null default now(),
  active_since timestamptz, main_guardian_authority_id uuid,
  constraint wali_links_active_since_state check (
    (status='active' and active_since is not null) or
    (status<>'active' and active_since is null)
  ),
  constraint wali_links_main_guardian_authority_state check (
    (status='active' and is_main and main_guardian_authority_id is not null) or
    ((status<>'active' or not is_main) and main_guardian_authority_id is null)
  )
);
create unique index wali_links_one_main_per_seeker on public.wali_links(seeker_id)
  where is_main and status='active';
create table public.guardian_journey_history_consents (
  wali_link_id uuid primary key references public.wali_links(id),
  main_guardian_authority_id uuid not null,
  granted_at timestamptz not null default clock_timestamp()
);
alter table public.guardian_journey_history_consents enable row level security;
revoke all on public.guardian_journey_history_consents from public, anon, authenticated;
grant all on public.guardian_journey_history_consents to service_role;

create table public.conversations (
  id uuid primary key, attempt_id uuid not null references public.journey_attempts(id),
  status text not null default 'active'
);
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id),
  sender_id uuid not null references public.profiles(id),
  content text not null, created_at timestamptz not null default now()
);
create table public.timelines (
  id uuid primary key, attempt_id uuid not null references public.journey_attempts(id)
);
create table public.timeline_milestones (
  id uuid primary key, timeline_id uuid not null references public.timelines(id)
);
create table public.journey_family_answers (
  id uuid primary key, attempt_id uuid not null references public.journey_attempts(id)
);
create table public.profile_blocks (
  blocker_id uuid not null references public.profiles(id),
  blocked_id uuid not null references public.profiles(id)
);
alter table public.profiles enable row level security;
alter table public.matches enable row level security;
alter table public.journey_attempts enable row level security;
alter table public.wali_links enable row level security;
alter table public.profile_blocks enable row level security;
alter table public.conversations enable row level security;
alter table public.messages enable row level security;
alter table public.timelines enable row level security;
alter table public.timeline_milestones enable row level security;
alter table public.journey_family_answers enable row level security;
grant select on public.conversations, public.messages, public.timelines,
  public.timeline_milestones, public.journey_family_answers, public.wali_links to authenticated;
grant insert on public.messages to authenticated;
-- The captured catalog denies full-table profile/match/attempt SELECT.
-- Only columns needed by the unchanged safe INSERT are granted here.
grant select(id,seeker_a_id,seeker_b_id) on public.matches to authenticated;
create policy wali_links_fixture_read on public.wali_links for select
  using (seeker_id=auth.uid() or wali_id=auth.uid());

create function public.zyra_block_exists(other_id uuid) returns boolean
language sql stable security definer set search_path='' as $block$
  select exists(select 1 from public.profile_blocks b
    where (b.blocker_id=(select auth.uid()) and b.blocked_id=other_id)
       or (b.blocked_id=(select auth.uid()) and b.blocker_id=other_id))
$block$;
revoke execute on function public.zyra_block_exists(uuid) from public, anon;
grant execute on function public.zyra_block_exists(uuid) to authenticated, service_role;

-- Exact applied OA290 authorization slice; counterpart RPC intentionally outside F02.
begin;

create table public.journey_guardian_assignments (
  id uuid primary key default gen_random_uuid(),
  attempt_id uuid not null references public.journey_attempts(id) on delete cascade,
  wali_link_id uuid not null references public.wali_links(id) on delete cascade,
  seeker_id uuid not null references public.profiles(id) on delete cascade,
  granted_by uuid not null references public.profiles(id),
  granted_at timestamptz not null default pg_catalog.clock_timestamp(),
  revoked_by uuid references public.profiles(id),
  revoked_at timestamptz,
  constraint journey_guardian_assignments_revocation_pair check (
    (revoked_at is null and revoked_by is null)
    or (revoked_at is not null and revoked_by is not null)
  )
);

create unique index journey_guardian_assignments_one_live
  on public.journey_guardian_assignments (attempt_id, wali_link_id)
  where revoked_at is null;

create index journey_guardian_assignments_link_history
  on public.journey_guardian_assignments (wali_link_id, granted_at desc);

alter table public.journey_guardian_assignments enable row level security;
revoke all on table public.journey_guardian_assignments
  from public, anon, authenticated;
grant all on table public.journey_guardian_assignments to service_role;

comment on table public.journey_guardian_assignments is
  'Audited per-attempt access grants for Additional Guardians. Live rows have '
  'revoked_at NULL. Main Guardians are never stored here because their active '
  'role is the non-optional Journey authority.';

-- One participation source remains authoritative. A current Main Guardian is
-- always present. An Additional Guardian is present only for an active attempt
-- with an unrevoked assignment belonging to their own Seeker link.
create or replace view public.zyra_attempt_participant_rows as
select a.id as attempt_id,
       m.seeker_a_id as user_id,
       'seeker'::text as role,
       a.match_id,
       null::boolean as is_main,
       a.status as attempt_status
from public.journey_attempts a
join public.matches m on m.id = a.match_id
union all
select a.id,
       m.seeker_b_id,
       'seeker'::text,
       a.match_id,
       null::boolean,
       a.status
from public.journey_attempts a
join public.matches m on m.id = a.match_id
union all
select a.id,
       w.wali_id,
       'guardian'::text,
       a.match_id,
       w.is_main,
       a.status
from public.journey_attempts a
join public.matches m on m.id = a.match_id
join public.wali_links w
  on w.status = 'active'
 and w.seeker_id in (m.seeker_a_id, m.seeker_b_id)
where w.is_main is true
   or (
     a.status = 'active'
     and exists (
       select 1
       from public.journey_guardian_assignments jga
       where jga.attempt_id = a.id
         and jga.wali_link_id = w.id
         and jga.seeker_id = w.seeker_id
         and jga.revoked_at is null
     )
   );

comment on view public.zyra_attempt_participant_rows is
  'Canonical unscoped Journey participation: both Seekers; every current Main '
  'Guardian; and per-attempt Seeker-authorised Additional Guardians while the '
  'attempt remains active. Granted to nobody; clients use the caller-scoped '
  'zyra_my_attempt_participation view.';

revoke all on public.zyra_attempt_participant_rows
  from public, anon, authenticated;

create or replace view public.zyra_my_attempt_participation as
select attempt_id, role, match_id, is_main, attempt_status
from public.zyra_attempt_participant_rows
where user_id = (select auth.uid());

comment on view public.zyra_my_attempt_participation is
  'Caller-scoped projection of canonical Journey participation. Additional '
  'Guardians appear only while explicitly included in that active Journey.';

revoke all on public.zyra_my_attempt_participation from public, anon;
grant select on public.zyra_my_attempt_participation to authenticated;

-- The Seeker reads and changes only an active Guardian link that they own.
-- Supplying NULL/NULL is a read. Supplying an attempt and boolean is a write.
create or replace function public.zyra_guardian_journey_access(
  p_guardian uuid,
  p_attempt uuid default null,
  p_enabled boolean default null
)
returns table (
  attempt_id uuid,
  match_id uuid,
  counterpart_first_name text,
  included boolean,
  can_change boolean,
  guardian_is_main boolean
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_caller uuid := (select auth.uid());
  v_link_id uuid;
  v_is_main boolean;
begin
  if v_caller is null then
    raise exception 'not_signed_in';
  end if;
  if p_guardian is null then
    raise exception 'guardian_required';
  end if;
  if (p_attempt is null) <> (p_enabled is null) then
    raise exception 'attempt_and_enabled_must_be_supplied_together';
  end if;

  select w.id, w.is_main
  into v_link_id, v_is_main
  from public.wali_links w
  where w.seeker_id = v_caller
    and w.wali_id = p_guardian
    and w.status = 'active';

  if not found then
    raise exception 'active_guardian_link_not_found';
  end if;

  if p_attempt is not null then
    if v_is_main then
      raise exception 'main_guardian_always_included';
    end if;
    if not exists (
      select 1
      from public.journey_attempts a
      join public.matches m on m.id = a.match_id
      where a.id = p_attempt
        and a.status = 'active'
        and v_caller in (m.seeker_a_id, m.seeker_b_id)
    ) then
      raise exception 'active_owned_journey_not_found';
    end if;

    if p_enabled then
      insert into public.journey_guardian_assignments (
        attempt_id, wali_link_id, seeker_id, granted_by
      ) values (
        p_attempt, v_link_id, v_caller, v_caller
      )
      on conflict (attempt_id, wali_link_id) where revoked_at is null
      do nothing;
    else
      update public.journey_guardian_assignments jga
      set revoked_by = v_caller,
          revoked_at = pg_catalog.clock_timestamp()
      where jga.attempt_id = p_attempt
        and jga.wali_link_id = v_link_id
        and jga.seeker_id = v_caller
        and jga.revoked_at is null;
    end if;
  end if;

  return query
  select a.id,
         a.match_id,
         other_profile.first_name,
         (
           v_is_main
           or exists (
             select 1
             from public.journey_guardian_assignments jga
             where jga.attempt_id = a.id
               and jga.wali_link_id = v_link_id
               and jga.seeker_id = v_caller
               and jga.revoked_at is null
           )
         ),
         not v_is_main,
         v_is_main
  from public.journey_attempts a
  join public.matches m on m.id = a.match_id
  join public.profiles other_profile
    on other_profile.id = case
      when m.seeker_a_id = v_caller then m.seeker_b_id
      else m.seeker_a_id
    end
  where a.status = 'active'
    and v_caller in (m.seeker_a_id, m.seeker_b_id)
  order by a.started_at desc nulls last, a.created_at desc, a.id;
end;
$function$;

revoke execute on function public.zyra_guardian_journey_access(uuid, uuid, boolean)
  from public, anon;
grant execute on function public.zyra_guardian_journey_access(uuid, uuid, boolean)
  to authenticated, service_role;

comment on function public.zyra_guardian_journey_access(uuid, uuid, boolean) is
  'Reads or changes one Seeker-owned Guardian link across the caller''s active '
  'Journeys. Main is immutable ON. Additional changes are server-confirmed, '
  'per attempt and audited; no caller may act for the other Seeker.';

-- Full Journey reads now follow canonical participation. Main-only decision
-- tables/RPCs are intentionally untouched.
drop policy if exists conversations_select on public.conversations;
create policy conversations_select on public.conversations
for select using (
  exists (
    select 1 from public.zyra_my_attempt_participation r
    where r.attempt_id = conversations.attempt_id
      and (
        r.role = 'seeker'
        or (r.role = 'guardian' and r.attempt_status <> 'potential')
      )
  )
);

drop policy if exists messages_select on public.messages;
create policy messages_select on public.messages
for select using (
  exists (
    select 1
    from public.conversations c
    join public.zyra_my_attempt_participation r
      on r.attempt_id = c.attempt_id
    where c.id = messages.conversation_id
      and (
        r.role = 'seeker'
        or (r.role = 'guardian' and r.attempt_status <> 'potential')
      )
  )
);

drop policy if exists timelines_select on public.timelines;
create policy timelines_select on public.timelines
for select using (
  exists (
    select 1 from public.zyra_my_attempt_participation r
    where r.attempt_id = timelines.attempt_id
      and (
        r.role = 'seeker'
        or (r.role = 'guardian' and r.attempt_status <> 'potential')
      )
  )
);

drop policy if exists timeline_milestones_select on public.timeline_milestones;
create policy timeline_milestones_select on public.timeline_milestones
for select using (
  exists (
    select 1
    from public.timelines t
    join public.zyra_my_attempt_participation r
      on r.attempt_id = t.attempt_id
    where t.id = timeline_milestones.timeline_id
      and (
        r.role = 'seeker'
        or (r.role = 'guardian' and r.attempt_status <> 'potential')
      )
  )
);

drop policy if exists journey_family_answers_read on public.journey_family_answers;
create policy journey_family_answers_read on public.journey_family_answers
for select using (
  exists (
    select 1 from public.zyra_my_attempt_participation r
    where r.attempt_id = journey_family_answers.attempt_id
      and r.role in ('seeker', 'guardian')
  )
);

drop policy if exists matches_select on public.matches;
create policy matches_select on public.matches
for select using (
  seeker_a_id = (select auth.uid())
  or seeker_b_id = (select auth.uid())
  or exists (
    select 1
    from public.journey_attempts a
    join public.wali_links w
      on w.wali_id = (select auth.uid())
     and w.status = 'active'
     and w.seeker_id in (matches.seeker_a_id, matches.seeker_b_id)
    where a.match_id = matches.id
      and a.status <> 'potential'
      and (
        w.is_main is true
        or (
          a.status = 'active'
          and exists (
            select 1
            from public.journey_guardian_assignments jga
            where jga.attempt_id = a.id
              and jga.wali_link_id = w.id
              and jga.seeker_id = w.seeker_id
              and jga.revoked_at is null
          )
        )
      )
  )
);


commit;

-- Exact applied OA291 source (unchanged).
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

-- Exact applied safe Seeker INSERT source (unchanged).
-- AUDIT FINDING 2.4 — a block did not close the blocked person's channel.
--
-- messages_insert checked two things: you are the sender, and you are a
-- seeker participant in the attempt. It did NOT check profile_blocks,
-- conversations.status or the attempt's lifecycle. So after blocking
-- someone, their messages still arrived, and notify_new_message still
-- pushed their name and the first 140 characters of the message to the
-- blocked-by party's phone.
--
-- This is the other half of the 2026-08-09 blocking fix (finding 1.2).
-- That one made the block record and end the Journey; without this one
-- the word "blocked" was still not true.
--
-- ── WHAT IS ADDED
--   1. NOT zyra_block_exists(counterpart) — in EITHER direction, because
--      blocking is mutual invisibility, not a one-way mute.
--   2. r.attempt_status = 'active' — no messaging into an ended Journey.
--   3. c.status = 'active' — no messaging into a closed conversation.
--
-- ── WHY zyra_block_exists AND NOT AN INLINE EXISTS. profile_blocks RLS
-- deliberately prevents anyone from seeing who blocked them. An inline
-- EXISTS in this policy is evaluated as the SENDER, so the blocked party
-- would read zero rows and the check would pass for exactly the person it
-- is meant to stop. zyra_block_exists is SECURITY DEFINER, already exists,
-- already checks both directions, and is already granted. One predicate,
-- one place — invariant I3.
--
-- ── WHY notify_new_message IS UNCHANGED. It is an AFTER INSERT trigger.
-- A refused insert never fires it, so the push is closed by the same
-- change. Adding a second block check inside the trigger would be a
-- second copy of the same rule.
--
-- ── WHY journey_attempts IS NOT JOINED HERE, though it holds the
-- lifecycle. journey_attempts has RLS ENABLED WITH ZERO POLICIES, so
-- every row is invisible to `authenticated`. Joining it inside a policy
-- would make this EXISTS false for everyone and silently break ALL
-- messaging. The lifecycle is read through
-- zyra_my_attempt_participation, which is SECURITY DEFINER and already
-- exposes attempt_status. Recorded because it is a live trap for the
-- next policy anyone writes against that table.
--
-- ── WHAT IS DELIBERATELY NOT ADDED, and raised rather than guessed:
--   · journey_stage = 'conversation'. Free messaging is defined to begin
--     only at Open Conversation and ChatScreen is gated on it client
--     side, but the participation view does not expose journey_stage, and
--     journey_attempts cannot be joined (above). Extending that view
--     also changes what messages_select and conversations_select read.
--     Out of scope for a safety fix.
--   · paused. Same reason — paused is paused_by IS NOT NULL on
--     journey_attempts, not a status, and the view does not expose it.
--     c.status = 'active' is the intended guard and nothing currently
--     maintains that column, so today it is dormant but correct.
--
-- ── MIGRATION RISK: NONE. Measured 2026-08-09 immediately before
-- applying — the database holds 0 messages, 0 conversations, 0 attempts
-- and 0 matches. Nothing existing can be invalidated by tightening this.

DROP POLICY IF EXISTS messages_insert ON public.messages;

CREATE POLICY messages_insert ON public.messages
FOR INSERT
WITH CHECK (
  sender_id = (SELECT auth.uid())
  AND EXISTS (
    SELECT 1
    FROM conversations c
    JOIN zyra_my_attempt_participation r ON r.attempt_id = c.attempt_id
    JOIN matches mt ON mt.id = r.match_id
    WHERE c.id = messages.conversation_id
      AND r.role = 'seeker'
      AND r.attempt_status = 'active'
      AND c.status = 'active'
      AND NOT public.zyra_block_exists(
            CASE WHEN mt.seeker_a_id = (SELECT auth.uid())
                 THEN mt.seeker_b_id
                 ELSE mt.seeker_a_id END)
  )
);

create or replace function public.zyra_counterpart_card(p_match_id uuid)
returns table (
  counterpart_first_name text,
  counterpart_age integer,
  guardian_first_name text,
  guardian_surname_line text,
  guardian_contact text
)
language sql
stable
security definer
set search_path = ''
as $function$
  with m as (
    select mm.*
    from public.matches mm
    where mm.id = p_match_id
      and mm.status <> 'potential'
      and mm.end_reason is distinct from 'safety_concern'
      and not exists (
        select 1 from public.profile_blocks b
        where (b.blocker_id = mm.seeker_a_id and b.blocked_id = mm.seeker_b_id)
           or (b.blocker_id = mm.seeker_b_id and b.blocked_id = mm.seeker_a_id)
      )
  ),
  mine as (
    select w.seeker_id as my_ward
    from m
    join public.wali_links w
      on w.wali_id = (select auth.uid())
     and w.status = 'active'
     and w.seeker_id in (m.seeker_a_id, m.seeker_b_id)
    where w.is_main is true
       or exists (
         select 1
         from public.journey_attempts a
         join public.journey_guardian_assignments jga
           on jga.attempt_id = a.id
          and jga.wali_link_id = w.id
          and jga.seeker_id = w.seeker_id
          and jga.revoked_at is null
         where a.match_id = m.id
           and a.status = 'active'
       )
    limit 1
  ),
  other as (
    select case when mine.my_ward = m.seeker_a_id then m.seeker_b_id
                else m.seeker_a_id end as other_seeker
    from m, mine
  )
  select p.first_name,
         date_part('year', age(p.date_of_birth))::int,
         g.first_name,
         g.surname_line,
         null::text
  from other
  join public.profiles p on p.id = other.other_seeker
  left join public.wali_links ow
    on ow.seeker_id = other.other_seeker
   and ow.status = 'active'
   and ow.is_main is true
  left join public.profiles g on g.id = ow.wali_id;
$function$;

revoke execute on function public.zyra_counterpart_card(uuid)
  from public, anon;
grant execute on function public.zyra_counterpart_card(uuid)
  to authenticated;

comment on function public.zyra_counterpart_card(uuid) is
  'Restricted counterpart identity card for an authorised Guardian Journey '
  'participant. Main participates by role; Additional participates only while '
  'the owning Seeker includes them in that active Journey.';

create trigger wali_links_auto_main before insert or update on public.wali_links
  for each row execute function public.auto_designate_main_wali();

-- Synthetic-only unchanged-boundary snapshots for post-candidate comparison.
create table public.f02_test_snapshots (object_key text primary key, definition text not null);
revoke all on public.f02_test_snapshots from public, anon, authenticated;
insert into public.f02_test_snapshots
select 'messages_insert', pg_get_expr(polwithcheck, polrelid)
from pg_policy where polrelid='public.messages'::regclass and polname='messages_insert'
union all
select signature, pg_get_functiondef(signature::regprocedure)
from (values ('public.zyra_attempt_summary_for_guardian(uuid)'),
             ('public.zyra_guardian_history_consent(uuid,boolean)'),
             ('public.zyra_main_guardian_history_consent(boolean)'),
             ('public.auto_designate_main_wali()'),
             ('public.zyra_block_exists(uuid)')) functions(signature)
union all
select 'acl:' || name, coalesce(relacl::text,'<null>')
from (values ('zyra_attempt_participant_rows'), ('zyra_my_attempt_participation'),
             ('messages'), ('conversations'), ('journey_guardian_assignments'),
             ('guardian_journey_history_consents')) objects(name)
join pg_class on oid=to_regclass('public.' || name);
insert into public.f02_test_snapshots
select 'function_acl:' || signature, coalesce(proacl::text,'<null>')
from (values ('public.zyra_counterpart_card(uuid)'),
             ('public.zyra_guardian_journey_access(uuid,uuid,boolean)')) functions(signature)
join pg_proc on oid=signature::regprocedure;
