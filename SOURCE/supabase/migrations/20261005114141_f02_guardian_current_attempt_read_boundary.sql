-- F02 / OA-ZYRA-290 / OA-ZYRA-291 / OA-ZYRA-305
-- DR-ZYRA-225/232/233: current Main support is non-optional; past summaries
-- never grant conversation/message detail. A pause retains attempt 'active'.
--
-- STAGED LOCAL CANDIDATE ONLY. No production authority is implied. Applying
-- requires current catalog reconciliation, exact-file Founder GO and separate
-- direct-role/JWT post-verification. Do not apply the held Sep24 bundle.
--
-- Exact prestate is reconstructed from the applied OA290/OA291 files and the
-- Oct3 captured catalog. Unknown drift fails closed before durable changes.
-- No identity/IDV, billing, message INSERT, send, read-receipt, block, return,
-- Guardian Circle or past-summary authority is activated or widened here.

begin;
set local lock_timeout = '5s';
set local statement_timeout = '30s';

-- Let this PostgreSQL version deparse the exact applied definitions, rather
-- than relying on whitespace/alias guesses in a textual view digest.
create temporary view f02_expected_participants as
select a.id as attempt_id, m.seeker_a_id as user_id,
       'seeker'::text as role, a.match_id, null::boolean as is_main,
       a.status as attempt_status
from public.journey_attempts a join public.matches m on m.id = a.match_id
union all
select a.id, m.seeker_b_id, 'seeker'::text, a.match_id, null::boolean, a.status
from public.journey_attempts a join public.matches m on m.id = a.match_id
union all
select a.id, w.wali_id, 'guardian'::text, a.match_id, w.is_main, a.status
from public.journey_attempts a
join public.matches m on m.id = a.match_id
join public.wali_links w
  on w.status = 'active' and w.seeker_id in (m.seeker_a_id, m.seeker_b_id)
where w.is_main is true
   or (a.status = 'active' and exists (
     select 1 from public.journey_guardian_assignments jga
     where jga.attempt_id = a.id and jga.wali_link_id = w.id
       and jga.seeker_id = w.seeker_id and jga.revoked_at is null
   ));

create temporary view f02_expected_caller as
select attempt_id, role, match_id, is_main, attempt_status
from public.zyra_attempt_participant_rows
where user_id = (select auth.uid());

-- Identical unqualified table names make pg_get_expr comparable while these
-- empty, private temporary relations cannot expose or alter application data.
create temporary table conversations (attempt_id uuid) on commit drop;
create policy f02_expected_conversations on pg_temp.conversations for select
using (exists (
  select 1 from public.zyra_my_attempt_participation r
  where r.attempt_id = conversations.attempt_id
    and (r.role = 'seeker'
      or (r.role = 'guardian' and r.attempt_status <> 'potential'))
));
create temporary table messages (conversation_id uuid) on commit drop;
create policy f02_expected_messages on pg_temp.messages for select
using (exists (
  select 1 from public.conversations c
  join public.zyra_my_attempt_participation r on r.attempt_id = c.attempt_id
  where c.id = messages.conversation_id
    and (r.role = 'seeker'
      or (r.role = 'guardian' and r.attempt_status <> 'potential'))
));
create temporary table matches (id uuid, seeker_a_id uuid, seeker_b_id uuid) on commit drop;
create policy f02_expected_matches on pg_temp.matches for select using (
  seeker_a_id = (select auth.uid()) or seeker_b_id = (select auth.uid())
  or exists (
    select 1 from public.journey_attempts a
    join public.wali_links w
      on w.wali_id = (select auth.uid()) and w.status = 'active'
     and w.seeker_id in (matches.seeker_a_id, matches.seeker_b_id)
    where a.match_id = matches.id and a.status <> 'potential'
      and (w.is_main is true or (a.status = 'active' and exists (
        select 1 from public.journey_guardian_assignments jga
        where jga.attempt_id = a.id and jga.wali_link_id = w.id
          and jga.seeker_id = w.seeker_id and jga.revoked_at is null
      )))
  )
);
create temporary table f02_expected_link_epoch (
  status text, active_since timestamptz, guardian_link_authority_id uuid,
  constraint wali_links_active_since_state check (
    (status = 'active' and active_since is not null)
    or (status <> 'active' and active_since is null)
  ),
  constraint wali_links_guardian_link_authority_state check (
    (status = 'active' and guardian_link_authority_id is not null)
    or (status <> 'active' and guardian_link_authority_id is null)
  )
) on commit drop;

do $f02_preflight$
declare
  v_name text;
  v_role text;
  v_expected text;
  v_actual text;
  v_proc record;
begin
  if current_user <> 'postgres' then
    raise exception 'F02 preflight: expected postgres migration owner';
  end if;

  if pg_catalog.pg_get_viewdef('public.zyra_attempt_participant_rows'::regclass)
       is distinct from pg_catalog.pg_get_viewdef('pg_temp.f02_expected_participants'::regclass)
     or pg_catalog.pg_get_viewdef('public.zyra_my_attempt_participation'::regclass)
       is distinct from pg_catalog.pg_get_viewdef('pg_temp.f02_expected_caller'::regclass)
  then
    raise exception 'F02 preflight: canonical/caller view drift';
  end if;

  foreach v_name in array array['zyra_attempt_participant_rows', 'zyra_my_attempt_participation'] loop
    if not exists (
      select 1 from pg_catalog.pg_class c
      where c.oid = pg_catalog.to_regclass('public.' || v_name)
        and c.relkind = 'v' and c.reloptions is null
        and pg_catalog.pg_get_userbyid(c.relowner) = 'postgres'
    ) then
      raise exception 'F02 preflight: view owner/options drift: %', v_name;
    end if;
  end loop;
  if pg_catalog.has_table_privilege('authenticated', 'public.zyra_attempt_participant_rows', 'SELECT')
     or pg_catalog.has_table_privilege('anon', 'public.zyra_attempt_participant_rows', 'SELECT')
     or pg_catalog.has_any_column_privilege('authenticated', 'public.zyra_attempt_participant_rows', 'SELECT')
     or pg_catalog.has_any_column_privilege('anon', 'public.zyra_attempt_participant_rows', 'SELECT')
     or pg_catalog.has_table_privilege('anon', 'public.zyra_my_attempt_participation', 'SELECT')
     or not pg_catalog.has_table_privilege('authenticated', 'public.zyra_my_attempt_participation', 'SELECT')
  then
    raise exception 'F02 preflight: view SELECT grant drift';
  end if;

  foreach v_name in array array['conversations', 'messages', 'matches'] loop
    if not exists (
      select 1 from pg_catalog.pg_class c
      where c.oid = pg_catalog.to_regclass('public.' || v_name)
        and c.relkind = 'r' and c.relrowsecurity and not c.relforcerowsecurity
        and pg_catalog.pg_get_userbyid(c.relowner) = 'postgres'
    ) or pg_catalog.has_table_privilege('authenticated', 'public.' || v_name, 'SELECT')
           is distinct from (v_name <> 'matches')
      or pg_catalog.has_table_privilege('anon', 'public.' || v_name, 'SELECT')
    then
      raise exception 'F02 preflight: table/RLS/grant drift: %', v_name;
    end if;
    -- Another SELECT/ALL policy can OR a denial away; do not silently retain it.
    if (select count(*) from pg_catalog.pg_policy p
        where p.polrelid = pg_catalog.to_regclass('public.' || v_name)
          and p.polcmd in ('r', '*')) <> 1 then
      raise exception 'F02 preflight: unexpected SELECT/ALL policy: %', v_name;
    end if;
    select pg_catalog.pg_get_expr(p.polqual, p.polrelid) into v_actual
    from pg_catalog.pg_policy p
    where p.polrelid = pg_catalog.to_regclass('public.' || v_name)
      and p.polname = v_name || '_select' and p.polcmd = 'r'
      and p.polpermissive and p.polroles = array[0::oid]
      and p.polwithcheck is null;
    select pg_catalog.pg_get_expr(p.polqual, p.polrelid) into v_expected
    from pg_catalog.pg_policy p
    where p.polrelid = pg_catalog.to_regclass('pg_temp.' || v_name)
      and p.polname = 'f02_expected_' || v_name;
    if v_actual is null or v_actual is distinct from v_expected then
      raise exception 'F02 preflight: SELECT policy expression drift: %', v_name;
    end if;
  end loop;

  -- The existing continuous-link epoch is authoritative. Do not guess an
  -- activation time or introduce a Main-history timestamp/backfill.
  foreach v_name in array array['wali_links_active_since_state', 'wali_links_guardian_link_authority_state'] loop
    select pg_catalog.pg_get_constraintdef(c.oid) into v_actual
    from pg_catalog.pg_constraint c
    where c.conrelid = 'public.wali_links'::regclass and c.conname = v_name
      and c.contype = 'c' and c.convalidated and not c.condeferrable;
    select pg_catalog.pg_get_constraintdef(c.oid) into v_expected
    from pg_catalog.pg_constraint c
    where c.conrelid = 'pg_temp.f02_expected_link_epoch'::regclass and c.conname = v_name;
    if v_actual is null or v_actual is distinct from v_expected then
      raise exception 'F02 preflight: continuous-link epoch constraint drift: %', v_name;
    end if;
  end loop;
  if not exists (
    select 1 from pg_catalog.pg_index i join pg_catalog.pg_class c on c.oid = i.indexrelid
    where i.indrelid = 'public.journey_guardian_assignments'::regclass
      and c.relname = 'journey_guardian_assignments_one_live'
      and i.indisunique and i.indisvalid and i.indisready and i.indimmediate
      and i.indnkeyatts = 2 and i.indnatts = 2 and i.indexprs is null
      and pg_catalog.pg_get_expr(i.indpred, i.indrelid) = '(revoked_at IS NULL)'
      and (select pg_catalog.string_agg(a.attname, ',' order by k.ordinality)
           from unnest(i.indkey) with ordinality k(attnum, ordinality)
           join pg_catalog.pg_attribute a on a.attrelid = i.indrelid and a.attnum = k.attnum)
          = 'attempt_id,wali_link_id'
  ) then
    raise exception 'F02 preflight: live-assignment uniqueness/index drift';
  end if;
  if not exists (
    select 1 from pg_catalog.pg_trigger t
    where t.tgrelid = 'public.wali_links'::regclass
      and t.tgname = 'wali_links_auto_main' and not t.tgisinternal
      and t.tgenabled = 'O' and t.tgtype = 23
      and t.tgfoid = 'public.auto_designate_main_wali()'::regprocedure
  ) then
    raise exception 'F02 preflight: active-link trigger drift';
  end if;

  for v_proc in select * from (values
    ('public.auto_designate_main_wali()', 'e96f1160ede0df3ab73d3d382a90bcbc', false),
    ('public.zyra_guardian_journey_access(uuid,uuid,boolean)', '4cef353cd1e5a6ed55b39d6c7241c3f2', true),
    ('public.zyra_counterpart_card(uuid)', 'df67d8fd5f9558f802cdd5cadf816856', true),
    ('public.zyra_attempt_summary_for_guardian(uuid)', '350a38ae4b4358b9065b248f78b6b3bf', true)
  ) as expected(signature, digest, member_execute) loop
    if not exists (
      select 1 from pg_catalog.pg_proc p
      where p.oid = pg_catalog.to_regprocedure(v_proc.signature)
        and p.prosecdef and p.proconfig = array['search_path=""']::text[]
        and pg_catalog.pg_get_userbyid(p.proowner) = 'postgres'
        and pg_catalog.md5(p.prosrc) = v_proc.digest
    ) or pg_catalog.has_function_privilege('anon', v_proc.signature, 'EXECUTE')
      or pg_catalog.has_function_privilege('authenticated', v_proc.signature, 'EXECUTE')
         is distinct from v_proc.member_execute
    then
      raise exception 'F02 preflight: helper/function grant drift: %', v_proc.signature;
    end if;
  end loop;
  foreach v_name in array array['journey_guardian_assignments', 'guardian_journey_history_consents'] loop
    if not exists (select 1 from pg_catalog.pg_class c
                   where c.oid = pg_catalog.to_regclass('public.' || v_name)
                     and c.relrowsecurity)
       or exists (select 1 from pg_catalog.pg_policy p
                  where p.polrelid = pg_catalog.to_regclass('public.' || v_name)) then
      raise exception 'F02 preflight: private assignment/consent RLS drift: %', v_name;
    end if;
    foreach v_role in array array['anon', 'authenticated'] loop
      if pg_catalog.has_table_privilege(v_role, 'public.' || v_name, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE,REFERENCES,TRIGGER')
         or pg_catalog.has_any_column_privilege(v_role, 'public.' || v_name, 'SELECT,INSERT,UPDATE,REFERENCES') then
        raise exception 'F02 preflight: private assignment/consent grant drift: %/%', v_name, v_role;
      end if;
    end loop;
  end loop;
end;
$f02_preflight$;

drop view pg_temp.f02_expected_caller;
drop view pg_temp.f02_expected_participants;
drop table pg_temp.messages;
drop table pg_temp.conversations;
drop table pg_temp.matches;
drop table pg_temp.f02_expected_link_epoch;

-- Seekers retain every exact-attempt archive row. Guardians receive rich
-- detail only for current active (including suspended/paused) attempts. Main
-- sees that current attempt even when it began before the Main was linked.
create or replace view public.zyra_attempt_participant_rows as
select a.id as attempt_id, m.seeker_a_id as user_id,
       'seeker'::text as role, a.match_id, null::boolean as is_main,
       a.status as attempt_status
from public.journey_attempts a join public.matches m on m.id = a.match_id
union all
select a.id, m.seeker_b_id, 'seeker'::text, a.match_id, null::boolean, a.status
from public.journey_attempts a join public.matches m on m.id = a.match_id
union all
select a.id, w.wali_id, 'guardian'::text, a.match_id, w.is_main, a.status
from public.journey_attempts a
join public.matches m on m.id = a.match_id
join public.wali_links w
  on w.status = 'active' and w.seeker_id in (m.seeker_a_id, m.seeker_b_id)
where a.status = 'active'
  and (w.is_main is true or exists (
    select 1 from public.journey_guardian_assignments jga
    where jga.attempt_id = a.id and jga.wali_link_id = w.id
      and jga.seeker_id = w.seeker_id and jga.revoked_at is null
      and jga.granted_at >= w.active_since
  ));

comment on view public.zyra_attempt_participant_rows is
  'DR225/232/233 F02: exact-attempt Seeker archives unchanged; current Main '
  'and explicitly included current-link Additional Guardians receive active '
  '(including paused) Journey detail only. Ended/potential attempts and '
  'past-summary consent never grant Guardian detail. No client direct grant.';

-- Explicit positive allowlists remain at both conversation and message RLS
-- boundaries; future statuses do not accidentally become Guardian readable.
drop policy conversations_select on public.conversations;
create policy conversations_select on public.conversations for select using (
  exists (select 1 from public.zyra_my_attempt_participation r
    where r.attempt_id = conversations.attempt_id
      and (r.role = 'seeker'
        or (r.role = 'guardian' and r.attempt_status = 'active')))
);
drop policy messages_select on public.messages;
create policy messages_select on public.messages for select using (
  exists (select 1 from public.conversations c
    join public.zyra_my_attempt_participation r on r.attempt_id = c.attempt_id
    where c.id = messages.conversation_id
      and (r.role = 'seeker'
        or (r.role = 'guardian' and r.attempt_status = 'active')))
);

-- Independent match and restricted-counterpart identity routes must follow
-- the same current-Journey boundary, not resurrect ended rich detail.
drop policy matches_select on public.matches;
create policy matches_select on public.matches for select using (
  seeker_a_id = (select auth.uid()) or seeker_b_id = (select auth.uid())
  or exists (
    select 1 from public.zyra_my_attempt_participation r
    where r.match_id = matches.id and r.role = 'guardian'
      and r.attempt_status = 'active'
  )
);

create or replace function public.zyra_counterpart_card(p_match_id uuid)
returns table (
  counterpart_first_name text, counterpart_age integer,
  guardian_first_name text, guardian_surname_line text, guardian_contact text
)
language sql stable security definer set search_path = ''
as $function$
  with m as (
    select mm.* from public.matches mm
    where mm.id = p_match_id and mm.status <> 'potential'
      and mm.end_reason is distinct from 'safety_concern'
      and not exists (
        select 1 from public.profile_blocks b
        where (b.blocker_id = mm.seeker_a_id and b.blocked_id = mm.seeker_b_id)
           or (b.blocker_id = mm.seeker_b_id and b.blocked_id = mm.seeker_a_id)
      )
  ), mine as (
    select w.seeker_id as my_ward
    from m join public.wali_links w
      on w.wali_id = (select auth.uid()) and w.status = 'active'
     and w.seeker_id in (m.seeker_a_id, m.seeker_b_id)
    where exists (
      select 1 from public.journey_attempts a
      where a.match_id = m.id and a.status = 'active'
        and (w.is_main is true or exists (
          select 1 from public.journey_guardian_assignments jga
          where jga.attempt_id = a.id and jga.wali_link_id = w.id
            and jga.seeker_id = w.seeker_id and jga.revoked_at is null
            and jga.granted_at >= w.active_since
        ))
    )
    limit 1
  ), other as (
    select case when mine.my_ward = m.seeker_a_id then m.seeker_b_id
                else m.seeker_a_id end as other_seeker
    from m, mine
  )
  select p.first_name, date_part('year', age(p.date_of_birth))::int,
         g.first_name, g.surname_line, null::text
  from other join public.profiles p on p.id = other.other_seeker
  left join public.wali_links ow
    on ow.seeker_id = other.other_seeker and ow.status = 'active' and ow.is_main is true
  left join public.profiles g on g.id = ow.wali_id;
$function$;

-- Re-linking a reused wali_links row cannot revive a previous assignment.
-- Explicitly enabling access retires that stale grant before making a fresh
-- auditable grant. Continuous role changes retain their existing link period.
create or replace function public.zyra_guardian_journey_access(
  p_guardian uuid, p_attempt uuid default null, p_enabled boolean default null
)
returns table (
  attempt_id uuid, match_id uuid, counterpart_first_name text,
  included boolean, can_change boolean, guardian_is_main boolean
)
language plpgsql security definer set search_path = ''
as $function$
#variable_conflict use_column
declare
  v_caller uuid := (select auth.uid());
  v_link_id uuid;
  v_is_main boolean;
  v_active_since timestamptz;
begin
  if v_caller is null then raise exception 'not_signed_in'; end if;
  if p_guardian is null then raise exception 'guardian_required'; end if;
  if (p_attempt is null) <> (p_enabled is null) then
    raise exception 'attempt_and_enabled_must_be_supplied_together';
  end if;
  select w.id, w.is_main, w.active_since
  into v_link_id, v_is_main, v_active_since
  from public.wali_links w
  where w.seeker_id = v_caller and w.wali_id = p_guardian and w.status = 'active'
  for update;
  if not found then raise exception 'active_guardian_link_not_found'; end if;

  if p_attempt is not null then
    if v_is_main then raise exception 'main_guardian_always_included'; end if;
    if not exists (
      select 1 from public.journey_attempts a
      join public.matches m on m.id = a.match_id
      where a.id = p_attempt and a.status = 'active'
        and v_caller in (m.seeker_a_id, m.seeker_b_id)
    ) then raise exception 'active_owned_journey_not_found'; end if;
    if p_enabled then
      update public.journey_guardian_assignments jga
      set revoked_by = v_caller, revoked_at = pg_catalog.clock_timestamp()
      where jga.attempt_id = p_attempt and jga.wali_link_id = v_link_id
        and jga.seeker_id = v_caller and jga.revoked_at is null
        and jga.granted_at < v_active_since;
      insert into public.journey_guardian_assignments (
        attempt_id, wali_link_id, seeker_id, granted_by
      ) values (p_attempt, v_link_id, v_caller, v_caller)
      on conflict (attempt_id, wali_link_id) where revoked_at is null do nothing;
    else
      update public.journey_guardian_assignments jga
      set revoked_by = v_caller, revoked_at = pg_catalog.clock_timestamp()
      where jga.attempt_id = p_attempt and jga.wali_link_id = v_link_id
        and jga.seeker_id = v_caller and jga.revoked_at is null;
    end if;
  end if;

  return query
  select a.id, a.match_id, other_profile.first_name,
    (v_is_main or exists (
      select 1 from public.journey_guardian_assignments jga
      where jga.attempt_id = a.id and jga.wali_link_id = v_link_id
        and jga.seeker_id = v_caller and jga.revoked_at is null
        and jga.granted_at >= v_active_since
    )), not v_is_main, v_is_main
  from public.journey_attempts a
  join public.matches m on m.id = a.match_id
  join public.profiles other_profile on other_profile.id = case
    when m.seeker_a_id = v_caller then m.seeker_b_id else m.seeker_a_id end
  where a.status = 'active' and v_caller in (m.seeker_a_id, m.seeker_b_id)
  order by a.started_at desc nulls last, a.created_at desc, a.id;
end;
$function$;

-- CREATE OR REPLACE preserves every existing ACL; no new helper/grant exists.
-- The four-field summary function, consent store and message INSERT policy
-- intentionally remain byte-for-byte unchanged.
commit;
