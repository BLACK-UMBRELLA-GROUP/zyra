-- ZYRA line 94 / OA-ZYRA-317 / DOC-ZYRA-0473 V4 / Q126, Q130 and Q134.
-- Runs after the account-deletion migration adds private match retirement.
begin;

-- A hold remains its own audit log after the retired match is purged.
alter table public.protection_holds
  alter column match_id drop not null,
  drop constraint protection_holds_match_id_fkey,
  add constraint protection_holds_match_id_fkey
    foreign key (match_id) references public.matches(id) on delete set null;

-- Older Journey RPCs read a match first and then check the caller. Filter
-- retired rows at the lookup so they have the same result as a purged row.
-- Writers lock the match before checking, so erasure cannot race past it.
do $retired_match_guards$
declare
  v_rpc regprocedure;
  v_definition text;
  v_match_filter text;
  v_match_lookup constant text :=
    '(select \* into m from matches where (matches\.)?id = (p_match_id|att\.match_id))(\s+for update)?';
  v_attestation_lookup constant text :=
    'select \* into att from journey_milestone_attestations where id = p_attestation_id';
begin
  foreach v_rpc in array array[
    'public.end_journey(uuid)'::regprocedure,
    'public.end_journey(uuid,text)'::regprocedure,
    'public.nudge_paused_journey(uuid)'::regprocedure,
    'public.open_family_review(uuid,text,text)'::regprocedure,
    'public.promote_journey_to_active(uuid)'::regprocedure,
    'public.resolve_family_review_if_due(uuid)'::regprocedure,
    'public.restart_journey(uuid)'::regprocedure,
    'public.resume_journey(uuid)'::regprocedure,
    'public.suspend_journey(uuid)'::regprocedure,
    'public.zyra_advance_stage(uuid,text)'::regprocedure,
    'public.zyra_confirm_milestone(uuid)'::regprocedure,
    'public.zyra_dev_counterpart_complete(uuid,text[])'::regprocedure,
    'public.zyra_dev_set_compatibility(uuid,numeric)'::regprocedure,
    'public.zyra_dev_set_counterpart_reveal(uuid,boolean)'::regprocedure,
    'public.zyra_dev_set_journey_stage(uuid,text)'::regprocedure,
    'public.zyra_milestone_attestation_state(uuid)'::regprocedure,
    'public.zyra_propose_milestone(uuid,text,date)'::regprocedure
  ] loop
    v_definition := pg_get_functiondef(v_rpc);
    if (select count(*) from regexp_matches(v_definition, v_match_lookup, 'gi')) <> 1 then
      raise exception 'Journey match lookup changed in %', v_rpc;
    end if;
    v_match_filter := '\1 and seeker_a_id is not null and seeker_b_id is not null';
    if v_rpc <> 'public.zyra_milestone_attestation_state(uuid)'::regprocedure then
      v_match_filter := v_match_filter || ' for update';
    end if;
    v_definition := regexp_replace(v_definition, v_match_lookup, v_match_filter, 'i');
    if v_rpc = 'public.zyra_confirm_milestone(uuid)'::regprocedure then
      if (select count(*) from regexp_matches(v_definition, v_attestation_lookup, 'gi')) <> 1 then
        raise exception 'Journey attestation lookup changed in %', v_rpc;
      end if;
      v_definition := regexp_replace(v_definition, v_attestation_lookup,
        'select a.* into att from journey_milestone_attestations a
         join matches mm on mm.id = a.match_id
         where a.id = p_attestation_id and mm.seeker_a_id is not null and mm.seeker_b_id is not null
         for update of mm',
        'i');
    end if;
    execute v_definition;
  end loop;
end;
$retired_match_guards$;

-- Review responses and reopens must serialize with account deletion. Lock
-- the pair before reading the current attempt and taking the review lock.
create function private.zyra_lock_active_family_review(
  p_review_id uuid, p_expected_status text
) returns public.journey_family_reviews
language plpgsql security invoker set search_path = ''
as $$
declare
  v_review public.journey_family_reviews%rowtype;
  v_match public.matches%rowtype;
  v_caller uuid := (select auth.uid());
begin
  select r.* into v_review from public.journey_family_reviews r
  join public.matches m on m.id = r.match_id
  where r.id = p_review_id and m.seeker_a_id is not null and m.seeker_b_id is not null;
  if not found then raise exception 'review not found'; end if;
  if v_review.attempt_id is null then raise exception 'review_has_no_attempt'; end if;

  select * into v_match from public.matches
  where id = v_review.match_id and seeker_a_id is not null and seeker_b_id is not null
  for update;
  if not found then raise exception 'review not found'; end if;
  if v_caller is null or not exists (
    select 1 from public.wali_links link
    where link.wali_id = v_caller and link.status = 'active' and link.is_main
      and link.seeker_id in (v_match.seeker_a_id, v_match.seeker_b_id)
  ) then raise exception 'not an authorised Wali for this Journey'; end if;

  select * into v_review from public.journey_family_reviews
  where id = p_review_id and match_id = v_match.id for update;
  if not found then raise exception 'review not found'; end if;
  if v_match.status <> 'active' or not exists (
    select 1 from public.journey_attempts attempt
    where attempt.id = v_review.attempt_id and attempt.match_id = v_match.id
      and attempt.status = 'active'
  ) then raise exception 'journey_not_active'; end if;
  if v_review.status <> p_expected_status then
    if p_expected_status = 'paused' then raise exception 'review is not paused'; end if;
    raise exception 'review already resolved';
  end if;
  return v_review;
end;
$$;
revoke all on function private.zyra_lock_active_family_review(uuid,text)
  from public, anon, authenticated, service_role;

create or replace function public.wali_review_decision(p_review_id uuid, p_decision text)
returns void language plpgsql security definer set search_path = ''
as $$
declare
  v_review public.journey_family_reviews%rowtype;
  v_expected_count integer;
  v_continued_count integer;
begin
  if p_decision not in ('continue','pause') then raise exception 'invalid decision'; end if;
  v_review := private.zyra_lock_active_family_review(p_review_id, 'pending');
  insert into public.journey_family_review_responses (review_id, wali_id, decision)
  values (p_review_id, (select auth.uid()), p_decision)
  on conflict (review_id, wali_id) do update set decision = excluded.decision, responded_at = now();

  if p_decision = 'pause' then
    update public.journey_family_reviews set status = 'paused', resolved_at = now()
    where id = p_review_id;
    return;
  end if;

  select count(distinct link.wali_id) into v_expected_count
  from public.matches match
  join public.wali_links link on link.seeker_id in (match.seeker_a_id, match.seeker_b_id)
  where match.id = v_review.match_id and link.status = 'active' and link.is_main;

  select count(*) into v_continued_count from public.journey_family_review_responses
  where review_id = p_review_id and decision = 'continue';
  if v_expected_count >= 1 and v_continued_count >= v_expected_count then
    update public.journey_family_reviews set status = 'continued', resolved_at = now()
    where id = p_review_id;
    update public.matches set journey_stage = v_review.to_stage where id = v_review.match_id;
    update public.journey_attempts set journey_stage = v_review.to_stage where id = v_review.attempt_id;
    if v_review.to_stage = 'conversation' then
      update public.conversations set status = 'active' where attempt_id = v_review.attempt_id;
    end if;
  end if;
end;
$$;

create or replace function public.reopen_family_review(p_review_id uuid)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  perform private.zyra_lock_active_family_review(p_review_id, 'paused');
  delete from public.journey_family_review_responses where review_id = p_review_id;
  update public.journey_family_reviews
  set status = 'pending', opened_at = now(), deadline_at = now() + interval '48 hours', resolved_at = null
  where id = p_review_id;
end;
$$;

-- A filed Journey report records the exact attempt when it can be identified.
-- Keep that audit ID after the attempt is purged and the report is closed.
alter table public.profile_reports add column attempt_id uuid;
comment on column public.profile_reports.attempt_id is
  'Exact Journey attempt supplied or resolved at filing. Its ID remains on the safety report after archive purge.';

-- Preserve the existing member report fields without exposing the new safety
-- linkage. The app files reports directly and reads its case status via RPC.
revoke select on public.profile_reports from public, anon, authenticated;
grant select (id, reporter_id, reported_id, reason, detail, source, status, created_at, reviewed_at)
  on public.profile_reports to authenticated;
-- A member-authored description may still identify the departed person.
-- The safety-case status RPC keeps the existing member status read.
create policy line94_detached_profile_report_visibility on public.profile_reports
as restrictive for select to authenticated using (
  reporter_id is not null and reported_id is not null
);

create table private.report_protected_attempts (
  report_id uuid not null references public.profile_reports(id) on delete cascade,
  attempt_id uuid not null references public.journey_attempts(id) on delete cascade,
  primary key (report_id, attempt_id)
);
create index report_protected_attempts_attempt_idx
  on private.report_protected_attempts (attempt_id, report_id);
alter table private.report_protected_attempts enable row level security;
revoke all on private.report_protected_attempts from public, anon, authenticated, service_role;
comment on table private.report_protected_attempts is
  'Internal safety linkage. Open reports protect the linked attempts, including after either participant is detached.';

create index profile_reports_open_legacy_pair_idx
  on public.profile_reports (
    least(reporter_id, reported_id), greatest(reporter_id, reported_id)
  )
  where status in ('pending', 'reviewing') and attempt_id is null;

create function private.zyra_resolve_report_attempt()
returns trigger language plpgsql security definer set search_path = '' as $function$
declare
  v_match_id uuid;
begin
  -- Match deletion already holds the departing profile lock before locking
  -- pairs. Use that same order when filing against the pair.
  perform p.id from public.profiles p
  where p.id in (new.reporter_id, new.reported_id)
  order by p.id for key share;

  select m.id into v_match_id from public.matches m
  where m.seeker_a_id = least(new.reporter_id, new.reported_id)
    and m.seeker_b_id = greatest(new.reporter_id, new.reported_id)
  for update;

  if new.attempt_id is not null then
    if new.source not in ('journey', 'chat') or not exists (
      select 1 from public.journey_attempts a
      where a.id = new.attempt_id and a.match_id = v_match_id and a.status in ('active', 'ended')
    ) then
      raise exception using errcode = '42501', message = 'report_attempt_not_available';
    end if;
  elsif new.source in ('journey', 'chat') then
    -- An older client may report from either the active or an ended card.
    -- Only infer an exact ID when there is one possible attempt; otherwise
    -- link every attempt so an older report cannot lose its evidence.
    select (array_agg(a.id))[1] into new.attempt_id from public.journey_attempts a
    where a.match_id = v_match_id and a.status in ('active', 'ended')
    having count(*) = 1;
  end if;
  return new;
end;
$function$;
revoke all on function private.zyra_resolve_report_attempt() from public, anon, authenticated, service_role;

create trigger zyra_resolve_report_attempt before insert on public.profile_reports
for each row execute function private.zyra_resolve_report_attempt();

create function private.zyra_link_report_attempts()
returns trigger language plpgsql security definer set search_path = '' as $function$
declare
  v_match_id uuid;
begin
  if new.status not in ('pending', 'reviewing') then return new; end if;
  -- INSERT has already locked the pair. Reopening a closed case must also
  -- serialize with its pair's archive purge.
  if tg_op = 'UPDATE' and old.status in ('pending', 'reviewing') then return new; end if;

  if new.attempt_id is not null then
    -- An exact case can reopen while a retired attempt is still held.
    select m.id into v_match_id from public.matches m
    join public.journey_attempts a on a.match_id = m.id
    where a.id = new.attempt_id
    for update of m;
  else
    select m.id into v_match_id from public.matches m
    where m.seeker_a_id = least(new.reporter_id, new.reported_id)
      and m.seeker_b_id = greatest(new.reporter_id, new.reported_id)
    for update;
  end if;

  insert into private.report_protected_attempts (report_id, attempt_id)
  select new.id, a.id from public.journey_attempts a
  where a.match_id = v_match_id and (new.attempt_id is null or a.id = new.attempt_id)
  on conflict do nothing;
  return new;
end;
$function$;
revoke all on function private.zyra_link_report_attempts() from public, anon, authenticated, service_role;

create trigger zyra_link_report_attempts after insert or update of status on public.profile_reports
for each row execute function private.zyra_link_report_attempts();

-- An open legacy case continues to protect a subsequent attempt of its pair.
create function private.zyra_protect_new_report_attempt()
returns trigger language plpgsql security definer set search_path = '' as $function$
begin
  insert into private.report_protected_attempts (report_id, attempt_id)
  select r.id, new.id from public.matches m
  join public.profile_reports r on least(r.reporter_id, r.reported_id) = m.seeker_a_id
    and greatest(r.reporter_id, r.reported_id) = m.seeker_b_id
  where m.id = new.match_id and r.status in ('pending', 'reviewing') and r.attempt_id is null
  on conflict do nothing;
  return new;
end;
$function$;
revoke all on function private.zyra_protect_new_report_attempt() from public, anon, authenticated, service_role;

create trigger zyra_protect_new_report_attempt after insert on public.journey_attempts
for each row execute function private.zyra_protect_new_report_attempt();

-- Write links while both original identities are still available. Nullable
-- participant and report FKs can then detach without losing protection.
create function private.zyra_protect_report_attempts_before_departure(p_user_id uuid)
returns void language plpgsql set search_path = '' as $function$
begin
  perform m.id from public.matches m
  where p_user_id in (m.seeker_a_id, m.seeker_b_id)
  order by m.id for update;

  insert into private.report_protected_attempts (report_id, attempt_id)
  select r.id, a.id from public.profile_reports r
  join public.matches m on m.seeker_a_id = least(r.reporter_id, r.reported_id)
    and m.seeker_b_id = greatest(r.reporter_id, r.reported_id)
  join public.journey_attempts a on a.match_id = m.id
    and (r.attempt_id is null or r.attempt_id = a.id)
  where p_user_id in (r.reporter_id, r.reported_id) and r.status in ('pending', 'reviewing')
  on conflict do nothing;
end;
$function$;
revoke all on function private.zyra_protect_report_attempts_before_departure(uuid)
  from public, anon, authenticated, service_role;

-- Older reports have no attempt ID. Existing reports with a departed party
-- cannot be matched to a pair that was already removed by the old CASCADE.
insert into private.report_protected_attempts (report_id, attempt_id)
select r.id, a.id from public.profile_reports r
join public.matches m on m.seeker_a_id = least(r.reporter_id, r.reported_id)
  and m.seeker_b_id = greatest(r.reporter_id, r.reported_id)
join public.journey_attempts a on a.match_id = m.id
where r.status in ('pending', 'reviewing');

-- Keep the match-level restart envelope and hold audit when the newest
-- ended attempt is purged. The legacy projection must never show an older
-- attempt as though it were the one that was erased.
create table private.zyra_purged_ended_match_projections (
  match_id uuid primary key references public.matches(id) on delete cascade
);
alter table private.zyra_purged_ended_match_projections enable row level security;
revoke all on private.zyra_purged_ended_match_projections from public, anon, authenticated, service_role;

-- Only an accepted restart with existing mutual reveal needs a tombstone.
-- This stores the old dates and exact consent dependency without scores or content.
create table private.zyra_journey_reveal_tombstones (
  attempt_id uuid primary key,
  match_id uuid not null references public.matches(id) on delete cascade,
  created_at timestamptz not null,
  started_at timestamptz,
  ended_at timestamptz,
  revealed_at timestamptz,
  consent_for_attempt_id uuid not null references public.journey_attempts(id) on delete cascade
);
create index zyra_journey_reveal_tombstones_consent_idx
  on private.zyra_journey_reveal_tombstones (consent_for_attempt_id);
create index zyra_journey_reveal_tombstones_match_idx
  on private.zyra_journey_reveal_tombstones (match_id);
alter table private.zyra_journey_reveal_tombstones enable row level security;
revoke all on private.zyra_journey_reveal_tombstones from public, anon, authenticated, service_role;

create table private.zyra_ended_journey_removals (
  attempt_id uuid primary key references public.journey_attempts(id) on delete cascade,
  seeker_a_removed_at timestamptz,
  seeker_b_removed_at timestamptz
);
alter table private.zyra_ended_journey_removals enable row level security;
revoke all on private.zyra_ended_journey_removals from public, anon, authenticated, service_role;
comment on table private.zyra_ended_journey_removals is
  'Private, irreversible, attempt-specific joint archive state. Each side controls only its own removal.';

-- Removal is side-specific. The block condition is live and symmetric. An
-- ended attempt's existing safety restrictions are enforced by each reader.
create view private.zyra_ended_journey_visibility as
select a.id as attempt_id, m.id as match_id,
       m.seeker_a_id, m.seeker_b_id,
       m.seeker_a_id is not null and r.seeker_a_removed_at is null and not block.present as seeker_a_visible,
       m.seeker_b_id is not null and r.seeker_b_removed_at is null and not block.present as seeker_b_visible
from public.journey_attempts a
join public.matches m on m.id = a.match_id
left join private.zyra_ended_journey_removals r on r.attempt_id = a.id
cross join lateral (
  select exists (
    select 1 from public.profile_blocks b
    where (b.blocker_id = m.seeker_a_id and b.blocked_id = m.seeker_b_id)
       or (b.blocker_id = m.seeker_b_id and b.blocked_id = m.seeker_a_id)
  ) as present
) block
where a.status = 'ended'
  and not exists (
    select 1 from private.zyra_account_deleted_matches d where d.match_id = m.id
  );
revoke all on private.zyra_ended_journey_visibility from public, anon, authenticated, service_role;

-- Central participation retains the F02 current Guardian rules. Ended
-- Guardian access stays in the independent, four-field summary function.
create or replace view public.zyra_attempt_participant_rows as
select a.id as attempt_id, participant.user_id, 'seeker'::text as role,
       a.match_id, null::boolean as is_main, a.status as attempt_status
from public.journey_attempts a
join public.matches m on m.id = a.match_id
left join private.zyra_ended_journey_visibility v on v.attempt_id = a.id
cross join lateral (values (m.seeker_a_id, v.seeker_a_visible), (m.seeker_b_id, v.seeker_b_visible))
  participant(user_id, archive_visible)
where participant.user_id is not null
  and (a.status <> 'ended' or participant.archive_visible)
  and not exists (
    select 1 from private.zyra_account_deleted_matches d where d.match_id = m.id
  )
union all
select a.id, w.wali_id, 'guardian'::text, a.match_id, w.is_main, a.status
from public.journey_attempts a
join public.matches m on m.id = a.match_id
join public.wali_links w
  on w.status = 'active' and w.seeker_id in (m.seeker_a_id, m.seeker_b_id)
where a.status = 'active'
  and not exists (
    select 1 from private.zyra_account_deleted_matches d where d.match_id = m.id
  )
  and (w.is_main is true or exists (
    select 1 from public.journey_guardian_assignments jga
    where jga.attempt_id = a.id and jga.wali_link_id = w.id
      and jga.seeker_id = w.seeker_id and jga.revoked_at is null
      and jga.granted_at >= w.active_since
  ));
comment on view public.zyra_attempt_participant_rows is
  'F02 and Q126. Exact-attempt participation, with irreversible per-Seeker removal and live pair blocks for archives. Guardian detail remains current-attempt only.';

create or replace function public.zyra_attempt_summary_for_guardian(p_seeker uuid)
returns table(attempt_id uuid, started_at timestamptz, ended_at timestamptz, ended boolean)
language sql stable security definer set search_path = '' as $function$
  with current_guardian_link as materialized (
    select w.id, w.active_since, w.guardian_link_authority_id
    from public.wali_links w
    where w.seeker_id = p_seeker and w.wali_id = (select auth.uid()) and w.status = 'active'
  )
  select a.id, a.started_at, a.ended_at, a.status = 'ended'
  from public.journey_attempts a
  join public.matches m on m.id = a.match_id
  cross join current_guardian_link w
  left join private.zyra_ended_journey_visibility v on v.attempt_id = a.id
  where p_seeker in (m.seeker_a_id, m.seeker_b_id)
    and not exists (
      select 1 from private.zyra_account_deleted_matches d where d.match_id = m.id
    )
    and (a.status = 'active' or (
      a.status = 'ended'
      and ((p_seeker = v.seeker_a_id and v.seeker_a_visible)
        or (p_seeker = v.seeker_b_id and v.seeker_b_visible))
      and (a.ended_at >= w.active_since or exists (
        select 1 from public.guardian_journey_history_consents c
        where c.wali_link_id = w.id and c.guardian_link_authority_id = w.guardian_link_authority_id
      ))
    ));
$function$;

-- A Seeker's visible archive grants their own Bio access. The counterpart's
-- removal hides only that counterpart's archive, even outside Browse.
do $archive_bio$
declare
  v_definition text := pg_get_functiondef('public.zyra_can_view_profile(uuid)'::regprocedure);
  v_counterpart_join constant text := $old$
      join public.zyra_attempt_participant_rows them
        on them.attempt_id = me.attempt_id
$old$;
  v_counterpart_scope constant text := $old$
        and them.user_id = p_target
        and me.role   = 'seeker'
        and them.role = 'seeker'
$old$;
begin
  if strpos(v_definition, v_counterpart_join) = 0
     or strpos(v_definition, v_counterpart_scope) = 0 then
    raise exception 'Journey Bio visibility definition changed';
  end if;
  v_definition := replace(v_definition, v_counterpart_join, E'\n');
  execute replace(v_definition, v_counterpart_scope, $new$
        and me.role = 'seeker'
        and p_target <> me.user_id
        and p_target in (mm.seeker_a_id, mm.seeker_b_id)
$new$);
end;
$archive_bio$;

-- Match-keyed legacy reads can only show the newest attempt's status. They
-- must never expose that attempt when only an older card remains visible.
create function public.zyra_can_read_ended_match(p_match_id uuid)
returns boolean language sql stable security definer set search_path = '' as $function$
  select coalesce((
    select (v.seeker_a_id = (select auth.uid()) and v.seeker_a_visible)
        or (v.seeker_b_id = (select auth.uid()) and v.seeker_b_visible)
    from private.zyra_ended_journey_visibility v
    join public.journey_attempts a on a.id = v.attempt_id
    where v.match_id = p_match_id
      and not exists (
        select 1 from private.zyra_purged_ended_match_projections p where p.match_id = p_match_id
      )
    order by a.attempt_number desc
    limit 1
  ), false);
$function$;
revoke all on function public.zyra_can_read_ended_match(uuid) from public, anon, authenticated, service_role;
grant execute on function public.zyra_can_read_ended_match(uuid) to authenticated;

alter policy matches_select on public.matches using (
  seeker_a_id is not null and seeker_b_id is not null
  and (
    (status = 'ended' and public.zyra_can_read_ended_match(id))
    or (status <> 'ended' and (
      seeker_a_id = (select auth.uid()) or seeker_b_id = (select auth.uid())
      or exists (
        select 1 from public.zyra_my_attempt_participation r
        where r.match_id = matches.id and r.role = 'guardian' and r.attempt_status = 'active'
      )
    ))
  )
);

create or replace function public.zyra_match_ending(p_match_id uuid)
returns table(ended_by uuid, end_reason text, end_note text, ended_at timestamptz)
language sql stable security definer set search_path = '' as $function$
  select m.ended_by,
         case when m.end_reason = 'safety_concern' and m.ended_by is distinct from (select auth.uid())
           then 'prefer_not_to_say' else m.end_reason end,
         case when m.end_reason = 'safety_concern' and m.ended_by is distinct from (select auth.uid())
           then null else m.end_note end,
         m.ended_at
  from public.matches m
  where m.id = p_match_id
    and (m.status = 'ended' and public.zyra_can_read_ended_match(m.id)
      or m.status <> 'ended' and exists (
        select 1 from public.zyra_my_attempt_participation p where p.match_id = m.id
      ));
$function$;

-- The definer RPCs apply the same archive scope as their underlying reads.
create or replace function public.zyra_guardian_activity()
returns table(
  wali_id       uuid,
  activity_type text,
  occurred_at   timestamptz,
  detail        text
)
language sql
stable
security definer
set search_path = ''
as $function$
  with my_guardians as (
    select w.wali_id, w.created_at, coalesce(w.is_main, false) as is_main
    from public.wali_links w
    where w.seeker_id = (select auth.uid())
      and w.status = 'active'
  )

  -- They accepted, and the link began.
  select g.wali_id, 'linked'::text, g.created_at, null::text
  from my_guardians g

  union all

  -- They put someone forward. The only type with real data today.
  select s.wali_id, 'suggested', s.created_at, p.first_name
  from public.wali_suggestions s
  join my_guardians g on g.wali_id = s.wali_id
  join public.profiles p on p.id = s.suggested_id
  where s.seeker_id = (select auth.uid())

  union all

  -- They answered a Family Review on one of my Journeys.
  select r.wali_id, 'review_answered', r.responded_at, r.decision
  from public.journey_family_review_responses r
  join my_guardians g on g.wali_id = r.wali_id
  join public.journey_family_reviews rev on rev.id = r.review_id
  join public.zyra_my_attempt_participation p on p.attempt_id = rev.attempt_id and p.role = 'seeker'

  union all

  -- A review is open and the Main Guardian has not answered it.
  -- Scoped to Main because only the Main Guardian is asked to act — the
  -- same rule the page already states in its own copy.
  select g.wali_id, 'review_waiting', rev.opened_at, null
  from public.journey_family_reviews rev
  join public.zyra_my_attempt_participation p on p.attempt_id = rev.attempt_id and p.role = 'seeker'
  join my_guardians g on g.is_main
  where rev.status = 'open'
    and not exists (
      select 1 from public.journey_family_review_responses rr
      where rr.review_id = rev.id and rr.wali_id = g.wali_id
    )

  order by 3 desc nulls last;
$function$;

CREATE OR REPLACE FUNCTION public.zyra_journey_busy_flags(p_match_ids uuid[])
RETURNS TABLE(match_id uuid, in_another_journey boolean)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $function$
  SELECT
    requested.id AS match_id,
    EXISTS (
      SELECT 1
      FROM public.matches AS other_match
      WHERE other_match.id <> requested.id
        AND other_match.status = 'active'
        AND other_match.suspended_by IS NULL
        AND other_match.also_paused_by IS NULL
        AND (
          other_match.seeker_a_id = CASE
            WHEN requested.seeker_a_id = auth.uid()
              THEN requested.seeker_b_id
            ELSE requested.seeker_a_id
          END
          OR other_match.seeker_b_id = CASE
            WHEN requested.seeker_a_id = auth.uid()
              THEN requested.seeker_b_id
            ELSE requested.seeker_a_id
          END
        )
        AND auth.uid() NOT IN (
          other_match.seeker_a_id,
          other_match.seeker_b_id
        )
    ) AS in_another_journey
  FROM public.matches AS requested
  WHERE requested.id = ANY(COALESCE(p_match_ids, '{}'::uuid[]))
    AND auth.uid() IN (requested.seeker_a_id, requested.seeker_b_id)
    AND (requested.status <> 'ended' OR public.zyra_can_read_ended_match(requested.id));
$function$;

create or replace function public.zyra_journey_main_guardian_gate(
  p_match_id uuid
)
returns table (
  self_has_main boolean,
  other_has_main boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_me uuid := (select auth.uid());
  v_a uuid;
  v_b uuid;
  v_status text;
  v_other uuid;
begin
  if v_me is null then
    raise exception 'not_signed_in';
  end if;

  select m.seeker_a_id, m.seeker_b_id, m.status
    into v_a, v_b, v_status
  from public.matches m
  where m.id = p_match_id and m.seeker_a_id is not null and m.seeker_b_id is not null;

  if not found or (v_me is distinct from v_a and v_me is distinct from v_b)
      or (v_status = 'ended' and not public.zyra_can_read_ended_match(p_match_id)) then
    raise exception 'journey_not_available';
  end if;

  v_other := case when v_me = v_a then v_b else v_a end;

  return query
  select
    exists (
      select 1
      from public.wali_links w
      where w.seeker_id = v_me
        and w.status = 'active'
        and w.is_main is true
    ),
    exists (
      select 1
      from public.wali_links w
      where w.seeker_id = v_other
        and w.status = 'active'
        and w.is_main is true
    );
end;
$function$;

create or replace function public.zyra_mark_journey_messages_read(
  p_conversation uuid
) returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_caller uuid := (select auth.uid());
  v_now timestamptz := clock_timestamp();
begin
  if v_caller is null then
    raise exception 'authentication_required';
  end if;

  if not exists (
    select 1
    from public.conversations conversation
    join public.zyra_my_attempt_participation p on p.attempt_id = conversation.attempt_id
    where conversation.id = p_conversation and p.role = 'seeker'
  ) then
    raise exception 'conversation_not_available';
  end if;

  update public.messages message
  set read_at = coalesce(message.read_at, v_now)
  where message.conversation_id = p_conversation
    and message.sender_id <> v_caller
    and message.read_at is null;

  return v_now;
end;
$$;

-- Family answer writes used only an author check. A held Journey still
-- has valid foreign keys, so require membership of the exact attempt.
alter policy journey_family_answers_write on public.journey_family_answers with check (
  answerer_id = (select auth.uid()) and exists (
    select 1 from public.zyra_my_attempt_participation p
    where p.attempt_id = journey_family_answers.attempt_id
      and p.match_id = journey_family_answers.match_id
  )
);

-- Phase ratings have an independent owner policy. Require visibility of
-- their attempt as well, or a visible match for a legacy match-only rating.
create policy line94_phase_ratings_archive_visibility on public.journey_phase_ratings
as restrictive for all to authenticated using (
  (attempt_id is null and exists (
    select 1 from public.matches m where m.id = journey_phase_ratings.match_id
  )) or exists (
    select 1 from public.zyra_my_attempt_participation p
    where p.attempt_id = journey_phase_ratings.attempt_id and p.role = 'seeker'
  )
);

create function public.zyra_my_ended_journeys()
returns table(attempt_id uuid, match_id uuid, started_at timestamptz, ended_at timestamptz, journey_stage text,
              end_reason text, end_note text, display_name text)
language sql stable security definer set search_path = '' as $function$
  select a.id, a.match_id, a.started_at, a.ended_at, a.journey_stage,
         case when a.end_reason = 'safety_concern' and a.ended_by is distinct from caller.id
           then 'prefer_not_to_say' else a.end_reason end,
         case when a.end_reason = 'safety_concern' and a.ended_by is distinct from caller.id
           then null else a.end_note end,
         case when a.end_reason is distinct from 'safety_concern'
           and public.zyra_can_view_profile(other.id) then profile.first_name end
  from private.zyra_ended_journey_visibility v
  join public.journey_attempts a on a.id = v.attempt_id
  cross join (select (select auth.uid()) as id) caller
  cross join lateral (
    select case when caller.id = v.seeker_a_id then v.seeker_b_id else v.seeker_a_id end as id
  ) other
  left join public.profiles profile on profile.id = other.id
  where (v.seeker_a_visible and v.seeker_a_id = caller.id)
     or (v.seeker_b_visible and v.seeker_b_id = caller.id)
  order by a.ended_at desc nulls last, a.id;
$function$;
revoke all on function public.zyra_my_ended_journeys() from public, anon, authenticated, service_role;
grant execute on function public.zyra_my_ended_journeys() to authenticated;

create or replace function public.zyra_record_journey_milestone()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  v_timeline UUID;
  v_attempt  UUID;
  v_type     TEXT;
  v_old_ord  INT;
  v_new_ord  INT;
  -- SALAM FIRST (DR-ZYRA-183): this array decides forward vs backward,
  -- so it must mirror zyra_advance_stage's map exactly.
  v_order    TEXT[] := ARRAY['salam_exchange','compatibility_reveal','wali_gate',
                             'phase_1','phase_2','phase_3','family_stage','conversation'];
BEGIN
  -- Account erasure may close a held match without creating new Timeline data.
  IF EXISTS (
    SELECT 1 FROM private.zyra_account_deleted_matches d WHERE d.match_id = NEW.id
  ) THEN RETURN NEW; END IF;

  -- A purged match projection must never write legacy events to an older
  -- surviving attempt. A new active attempt starts a new projection.
  IF NEW.status = 'ended' AND EXISTS (
    SELECT 1 FROM private.zyra_purged_ended_match_projections p WHERE p.match_id = NEW.id
  ) THEN RETURN NEW; END IF;
  IF NEW.status = 'active' AND OLD.status IS DISTINCT FROM 'active' THEN
    DELETE FROM private.zyra_purged_ended_match_projections WHERE match_id = NEW.id;
  END IF;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = NEW.id
   ORDER BY (a.status = 'active') DESC, a.attempt_number DESC LIMIT 1;
  IF v_attempt IS NULL THEN RETURN NEW; END IF;

  INSERT INTO timelines (match_id, attempt_id) VALUES (NEW.id, v_attempt)
  ON CONFLICT (attempt_id) DO NOTHING;
  SELECT id INTO v_timeline FROM timelines WHERE attempt_id = v_attempt;
  IF v_timeline IS NULL THEN RETURN NEW; END IF;

  IF NEW.status = 'active' AND OLD.status IS DISTINCT FROM 'active' THEN
    IF NOT EXISTS (SELECT 1 FROM timeline_milestones
                    WHERE timeline_id = v_timeline AND milestone_type = 'journey_started') THEN
      INSERT INTO timeline_milestones (timeline_id, milestone_type)
      VALUES (v_timeline, 'journey_started');
    END IF;
  END IF;

  -- Pauses and resumes — DR-ZYRA-142 (2026-08-12): the Timeline records
  -- the PAIR, dated, nameless and reasonless. Deliberately NOT deduped:
  -- a couple may pause many times, and each "paused … continued" pair is
  -- part of the story, quiet by styling rather than by omission. Who
  -- paused is never written — the Timeline is the keepsake, not a ledger
  -- of responsibility (Main Guardians can read it, which is exactly why).
  IF NEW.suspended_by IS NOT NULL AND OLD.suspended_by IS NULL THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type)
    VALUES (v_timeline, 'journey_paused');
  END IF;
  -- An end-while-paused writes no "continued": journey_ended below
  -- already closes the chapter.
  IF NEW.suspended_by IS NULL AND OLD.suspended_by IS NOT NULL
     AND NEW.status = 'active' THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type)
    VALUES (v_timeline, 'journey_continued');
  END IF;

  IF NEW.journey_stage IS DISTINCT FROM OLD.journey_stage
     AND OLD.journey_stage IS NOT NULL THEN

    v_old_ord := array_position(v_order, OLD.journey_stage);
    v_new_ord := array_position(v_order, NEW.journey_stage);

    IF v_old_ord IS NOT NULL AND v_new_ord IS NOT NULL AND v_new_ord > v_old_ord THEN

      v_type := CASE OLD.journey_stage
                  WHEN 'compatibility_reveal' THEN 'compatibility_revealed'
                  WHEN 'salam_exchange'       THEN 'salam_exchanged'
                  WHEN 'wali_gate'            THEN 'guardian_linked'
                  WHEN 'phase_1'              THEN 'phase_1_complete'
                  WHEN 'phase_2'              THEN 'phase_2_complete'
                  WHEN 'phase_3'              THEN 'phase_3_complete'
                  WHEN 'family_stage'         THEN 'family_stage'
                END;

      IF v_type IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM timeline_milestones
         WHERE timeline_id = v_timeline AND milestone_type = v_type) THEN
        INSERT INTO timeline_milestones (timeline_id, milestone_type) VALUES (v_timeline, v_type);
      END IF;

      IF NEW.journey_stage = 'conversation' AND NOT EXISTS (
        SELECT 1 FROM timeline_milestones
         WHERE timeline_id = v_timeline AND milestone_type = 'conversation_started') THEN
        INSERT INTO timeline_milestones (timeline_id, milestone_type)
        VALUES (v_timeline, 'conversation_started');
      END IF;
    END IF;
  END IF;

  -- Endings — NOW GUARDED (2026-08-12): zyra_end_match_internal writes the
  -- same milestone after this trigger has fired.
  IF NEW.status = 'ended' AND OLD.status IS DISTINCT FROM 'ended' THEN
    IF NOT EXISTS (SELECT 1 FROM timeline_milestones
                    WHERE timeline_id = v_timeline AND milestone_type = 'journey_ended') THEN
      INSERT INTO timeline_milestones (timeline_id, milestone_type)
      VALUES (v_timeline, 'journey_ended');
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

create function private.zyra_match_has_active_hold(p_match_id uuid)
returns boolean language sql stable set search_path = '' as $function$
  select exists (
    select 1 from public.protection_holds h
    where h.match_id = p_match_id and h.released_at is null
      and (h.expires_at is null or h.expires_at > pg_catalog.now())
  );
$function$;
revoke all on function private.zyra_match_has_active_hold(uuid)
  from public, anon, authenticated, service_role;

create function private.zyra_attempt_has_open_report(p_attempt_id uuid)
returns boolean language sql stable set search_path = '' as $function$
  select exists (
    select 1 from private.report_protected_attempts p
    join public.profile_reports r on r.id = p.report_id
    where p.attempt_id = p_attempt_id and r.status in ('pending', 'reviewing')
  );
$function$;
revoke all on function private.zyra_attempt_has_open_report(uuid)
  from public, anon, authenticated, service_role;

create function private.zyra_match_has_protected_data(p_match_id uuid)
returns boolean language sql stable set search_path = '' as $function$
  select private.zyra_match_has_active_hold(p_match_id) or exists (
    select 1 from public.journey_attempts a
    where a.match_id = p_match_id and private.zyra_attempt_has_open_report(a.id)
  );
$function$;
revoke all on function private.zyra_match_has_protected_data(uuid)
  from public, anon, authenticated, service_role;

-- Only an account-deleted match can enter this purge. A match-wide hold
-- protects all attempts. A Journey report protects its linked attempts.
create function private.zyra_purge_account_deleted_match(p_match_id uuid)
returns void language plpgsql set search_path = '' as $function$
begin
  perform m.id
  from public.matches m
  join private.zyra_account_deleted_matches d on d.match_id = m.id
  where m.id = p_match_id
  for update of m;
  if not found then return; end if;

  if not private.zyra_match_has_protected_data(p_match_id) then
    delete from public.matches where id = p_match_id;
  elsif not private.zyra_match_has_active_hold(p_match_id) then
    delete from public.journey_attempts a
    where a.match_id = p_match_id and not private.zyra_attempt_has_open_report(a.id);
  end if;
end;
$function$;
revoke all on function private.zyra_purge_account_deleted_match(uuid)
  from public, anon, authenticated, service_role;

create function private.zyra_purge_account_deleted_matches()
returns void language plpgsql set search_path = '' as $function$
declare
  v_match_id uuid;
begin
  for v_match_id in
    select d.match_id
    from private.zyra_account_deleted_matches d
    order by d.match_id
  loop
    perform private.zyra_purge_account_deleted_match(v_match_id);
  end loop;
end;
$function$;
revoke all on function private.zyra_purge_account_deleted_matches()
  from public, anon, authenticated, service_role;

-- The pair lock serializes archive removal with account deletion and report
-- filing. Lock the exact attempt as well before deleting its dependent rows.
create function private.zyra_purge_ended_journey(p_attempt_id uuid)
returns void language plpgsql set search_path = '' as $function$
declare
  v_match public.matches%rowtype;
  v_removal private.zyra_ended_journey_removals%rowtype;
  v_attempt public.journey_attempts%rowtype;
begin
  select m.* into v_match
  from public.matches m join public.journey_attempts a on a.match_id = m.id
  where a.id = p_attempt_id and a.status = 'ended'
  for update of m;
  if not found then return; end if;

  select * into v_attempt from public.journey_attempts a
  where a.id = p_attempt_id and a.status = 'ended' for update;
  if not found then return; end if;

  select * into v_removal from private.zyra_ended_journey_removals r
  where r.attempt_id = p_attempt_id;
  if not found
      or v_removal.seeker_a_removed_at is null
      or v_removal.seeker_b_removed_at is null then
    return;
  end if;

  if private.zyra_match_has_active_hold(v_match.id)
     or private.zyra_attempt_has_open_report(p_attempt_id) then
    return;
  end if;

  if v_match.status = 'ended' and not exists (
    select 1 from public.journey_attempts newer
    where newer.match_id = v_match.id and newer.attempt_number > v_attempt.attempt_number
  ) then
    insert into private.zyra_purged_ended_match_projections(match_id)
    values (v_match.id) on conflict do nothing;
    update public.matches
    set journey_stage = null, ended_by = null, end_note = null
    where id = v_match.id;
  end if;

  -- Q92/Q98's active restart can use this mutual consent. Preserve its
  -- dependency without the former attempt's scores, answers or lifecycle text.
  insert into private.zyra_journey_reveal_tombstones (
    attempt_id, match_id, created_at, started_at, ended_at, revealed_at, consent_for_attempt_id
  )
  select v_attempt.id, v_match.id, v_attempt.created_at, v_attempt.started_at, v_attempt.ended_at,
         jc.revealed_at, active.id
  from public.journey_compatibility jc
  join public.journey_attempts active on active.match_id = jc.match_id and active.status = 'active'
  where jc.match_id = v_match.id and jc.attempt_id = p_attempt_id
    and jc.seeker_a_revealed and jc.seeker_b_revealed
    and v_attempt.end_reason is distinct from 'safety_concern'
    and v_attempt.attempt_number < active.attempt_number
    and exists (
      select 1 from public.journey_requests r
      where r.match_id = v_match.id and r.attempt_id = active.id and r.status = 'accepted'
    );

  -- The exact attempt's FKs cascade all shared content and archive state.
  -- Accepted restart requests that produced it cannot survive with a null
  -- attempt, so erase those rows explicitly first. Other attempts stay intact.
  delete from public.journey_requests where attempt_id = p_attempt_id;
  delete from public.journey_attempts where id = p_attempt_id;
end;
$function$;
revoke all on function private.zyra_purge_ended_journey(uuid) from public, anon, authenticated, service_role;

create function private.zyra_remove_ended_journey_for(p_attempt_id uuid, p_seeker_id uuid)
returns void language plpgsql set search_path = '' as $function$
declare
  v_match public.matches%rowtype;
  v_removed_at timestamptz := pg_catalog.clock_timestamp();
begin
  select m.* into v_match
  from public.matches m join public.journey_attempts a on a.match_id = m.id
  where a.id = p_attempt_id and a.status = 'ended'
    and p_seeker_id in (m.seeker_a_id, m.seeker_b_id)
  for update of m;
  if not found then
    raise exception using errcode = '42501', message = 'ended_journey_not_available';
  end if;

  insert into private.zyra_ended_journey_removals as r (
    attempt_id, seeker_a_removed_at, seeker_b_removed_at
  ) values (
    p_attempt_id,
    case when p_seeker_id = v_match.seeker_a_id then v_removed_at end,
    case when p_seeker_id = v_match.seeker_b_id then v_removed_at end
  ) on conflict (attempt_id) do update
  set seeker_a_removed_at = coalesce(r.seeker_a_removed_at, excluded.seeker_a_removed_at),
      seeker_b_removed_at = coalesce(r.seeker_b_removed_at, excluded.seeker_b_removed_at);

  perform private.zyra_purge_ended_journey(p_attempt_id);
end;
$function$;
revoke all on function private.zyra_remove_ended_journey_for(uuid, uuid) from public, anon, authenticated, service_role;

create function public.zyra_remove_ended_journey(p_attempt_id uuid)
returns void language sql volatile security definer set search_path = '' as $function$
  select private.zyra_remove_ended_journey_for(p_attempt_id, (select auth.uid()));
$function$;
revoke all on function public.zyra_remove_ended_journey(uuid) from public, anon, authenticated, service_role;
grant execute on function public.zyra_remove_ended_journey(uuid) to authenticated;

-- Recheck pending archive deletions from the trusted daily job, so an
-- expired hold or closed report does not require either Seeker to act again.
create function private.zyra_purge_closed_ended_journeys()
returns void language plpgsql set search_path = '' as $function$
declare
  v_attempt_id uuid;
begin
  for v_attempt_id in
    select r.attempt_id
    from private.zyra_ended_journey_removals r
    join public.journey_attempts a on a.id = r.attempt_id
    join public.matches m on m.id = a.match_id
    where a.status = 'ended'
      and r.seeker_a_removed_at is not null and r.seeker_b_removed_at is not null
      and not exists (
        select 1 from private.zyra_account_deleted_matches d where d.match_id = m.id
      )
    order by m.id, a.attempt_number
  loop
    perform private.zyra_purge_ended_journey(v_attempt_id);
  end loop;
  perform private.zyra_purge_account_deleted_matches();
end;
$function$;
revoke all on function private.zyra_purge_closed_ended_journeys() from public, anon, authenticated, service_role;

-- Q120/Q126 replace the three-month Compatibility cutoff with archive access.
create or replace function public.zyra_compatibility_topics(
  p_subject uuid,
  p_match_id uuid default null
)
returns table(
  overall numeric,
  topics_locked boolean,
  area_no smallint,
  area_code text,
  band text,
  state text
)
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
  v_caller uuid := (select auth.uid());
  v_role text;
  v_viewer uuid;
  v_match public.matches%rowtype;
  v_attempt_id uuid;
  v_attempt_number integer;
  v_mutual boolean := false;
  v_unlocked boolean := false;
  v_open boolean;
  v_result private.zyra_directional_results%rowtype;
begin
  if v_caller is null or p_subject is null or v_caller = p_subject then return; end if;
  select p.role into v_role from public.profiles p where p.id = v_caller;
  if v_role is null or v_role not in ('seeker', 'wali') then return; end if;
  if not exists (select 1 from public.profiles p where p.id = p_subject and p.role = 'seeker')
     or public.zyra_block_exists(p_subject) then return; end if;

  if v_role = 'seeker' then
    select exists (
      select 1 from public.profile_unlocks u
      where u.unlocker_id = v_caller and u.unlocked_id = p_subject
        and u.unlock_type in ('paid_single', 'paid_bundle', 'paid_plus_single', 'paid_plus_bundle')
    ) into v_unlocked;
  end if;

  if p_match_id is null then
    if v_role <> 'seeker' or not v_unlocked
       or not public.zyra_can_view_profile(p_subject) then return; end if;
    v_viewer := v_caller;
  else
    select m.* into v_match
    from public.matches m
    where m.id = p_match_id and p_subject in (m.seeker_a_id, m.seeker_b_id)
      and m.status in ('active', 'ended')
      and m.seeker_a_id is not null and m.seeker_b_id is not null
      and m.end_reason is distinct from 'safety_concern'
      and not exists (
        select 1 from private.zyra_purged_ended_match_projections p where p.match_id = m.id
      );
    if not found then return; end if;
    v_viewer := case when p_subject = v_match.seeker_a_id then v_match.seeker_b_id
                     else v_match.seeker_a_id end;
    if v_role = 'seeker' and v_viewer <> v_caller then return; end if;

    select a.id, a.attempt_number, jc.seeker_a_revealed and jc.seeker_b_revealed
      into v_attempt_id, v_attempt_number, v_mutual
    from public.journey_attempts a
    left join public.journey_compatibility jc on jc.match_id = a.match_id and jc.attempt_id = a.id
    where a.match_id = v_match.id and a.status = v_match.status
      and (a.status = 'active' or a.end_reason is distinct from 'safety_concern')
    order by a.attempt_number desc
    limit 1;
    if not found then return; end if;
    if v_match.status = 'ended' and not exists (
      select 1 from private.zyra_ended_journey_visibility v
      where v.attempt_id = v_attempt_id and ((v.seeker_a_id = v_viewer and v.seeker_a_visible)
        or (v.seeker_b_id = v_viewer and v.seeker_b_visible))
    ) then return; end if;

    -- Accepted restarts resume at Salam exchange and leave the prior
    -- match-keyed reveal row on its original attempt. Carry that mutual
    -- consent within this match; check access against the selected attempt.
    if v_mutual is not true then
      select exists (
        select 1 from public.journey_requests r
        where r.match_id = v_match.id and r.attempt_id = v_attempt_id and r.status = 'accepted'
          and (
            exists (
              select 1 from public.journey_compatibility jc
              join public.journey_attempts prior on prior.id = jc.attempt_id
                and prior.match_id = jc.match_id
              where jc.match_id = r.match_id and prior.status = 'ended'
                and prior.attempt_number < v_attempt_number
                and prior.end_reason is distinct from 'safety_concern'
                and jc.seeker_a_revealed and jc.seeker_b_revealed
            ) or exists (
              select 1 from private.zyra_journey_reveal_tombstones t
              where t.match_id = r.match_id and t.consent_for_attempt_id = r.attempt_id
            )
          )
      ) into v_mutual;
    end if;

    if v_role = 'wali' then
      if v_mutual is not true or public.zyra_block_exists(v_viewer) then return; end if;
      if v_match.status = 'active' then
        -- F02's exact-attempt and continuous-link checks, scoped to the
        -- one linked Seeker whose direction this request would disclose.
        if not exists (
          select 1 from public.wali_links w
          where w.seeker_id = v_viewer and w.wali_id = v_caller and w.status = 'active'
            and (w.is_main or exists (
              select 1 from public.journey_guardian_assignments a
              where a.attempt_id = v_attempt_id and a.wali_link_id = w.id
                and a.seeker_id = v_viewer and a.revoked_at is null
                and a.granted_at >= w.active_since
            ))
        ) then return; end if;
      elsif not exists (
        select 1 from public.zyra_attempt_summary_for_guardian(v_viewer) archive
        where archive.attempt_id = v_attempt_id and archive.ended
      ) then return;
      end if;
    elsif v_mutual is not true and not v_unlocked then
      return;
    end if;
  end if;

  -- Safety endings remain private after the live block is removed, including
  -- when the same pair is addressed through an old paid Profile Unlock.
  if exists (
    select 1 from public.matches m
    where ((m.seeker_a_id = v_viewer and m.seeker_b_id = p_subject)
        or (m.seeker_b_id = v_viewer and m.seeker_a_id = p_subject))
      and m.end_reason = 'safety_concern'
  ) or exists (
    select 1 from public.profile_blocks b
    where (b.blocker_id = v_viewer and b.blocked_id = p_subject)
       or (b.blocker_id = p_subject and b.blocked_id = v_viewer)
  ) then return; end if;

  select d.* into v_result
  from private.zyra_directional_results d
  where d.viewer = v_viewer and d.subject = p_subject;
  if not found and v_role = 'seeker' and (v_unlocked or v_mutual is true) then
    v_result := private.zyra_save_direction_result(v_viewer, p_subject);
  end if;

  v_open := case v_role
    when 'seeker' then public.zyra_has_paid_role(v_caller, 'seeker') or v_unlocked
    else public.zyra_has_paid_role(v_caller, 'guardian')
  end;
  return query
    select case when v_result.state = 'ok' then v_result.overall end,
           not v_open,
           a.area_no::smallint,
           a.area_code,
           case when v_open and v_result.state = 'ok'
                then v_result.area_bands ->> (a.area_no - 1) end,
           coalesce(v_result.state, 'incomplete')
    from (values
      (1, 'deen'), (2, 'marriage'), (3, 'children'), (4, 'family'),
      (5, 'finances'), (6, 'work'), (7, 'home'), (8, 'communication'),
      (9, 'personality'), (10, 'lifestyle'), (11, 'digital'), (12, 'culture')
    ) a(area_no, area_code)
    order by a.area_no;
end;
$function$;

commit;
