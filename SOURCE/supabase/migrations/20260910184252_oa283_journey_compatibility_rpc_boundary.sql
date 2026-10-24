-- OA-ZYRA-283 — caller-scoped Compatibility Reveal boundary.
--
-- STAGED ONLY on 2026-09-10. Do not apply without the Founder's separate,
-- hash-specific production GO. The existing client held a whole-row RLS grant
-- on a row containing both Seekers' private scores and consent flags. RLS can
-- authorise rows, not different columns for each participant, so this
-- migration replaces direct client table access with two caller-relative
-- RPCs. It also hardens the existing Plus doorway because that function reads
-- and writes the same protected row.
--
-- Deliberately NOT included: the broader score_candidates Browse boundary,
-- the OA-ZYRA-156 destructive per-attempt key conversion, or OA-ZYRA-284's
-- typed client failure state. Those are separately governed work.

create or replace function public.zyra_journey_compatibility_state(
  p_match_id uuid
)
returns table(
  mine_revealed boolean,
  counterpart_revealed boolean,
  my_score numeric
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_caller uuid := (select auth.uid());
  v_match record;
  v_attempt record;
  v_compat public.journey_compatibility%rowtype;
  v_is_a boolean;
begin
  if v_caller is null then
    raise exception using errcode = '42501', message = 'not_signed_in';
  end if;

  -- Match absence and non-participation deliberately have one observable
  -- result. A caller cannot use this function to enumerate match ids.
  select m.seeker_a_id, m.seeker_b_id, m.status, m.journey_stage,
         m.suspended_by, m.also_paused_by,
         coalesce(pg_catalog.to_jsonb(m) ->> 'pause_state', 'none')
           as shared_pause_state
    into v_match
    from public.matches as m
   where m.id = p_match_id
     and v_caller in (m.seeker_a_id, m.seeker_b_id);

  if not found then
    raise exception using errcode = '42501', message = 'not_a_party';
  end if;

  if v_match.status is distinct from 'active'
     or v_match.journey_stage is distinct from 'compatibility_reveal'
     or v_match.suspended_by is not null
     or v_match.also_paused_by is not null
     or v_match.shared_pause_state is distinct from 'none' then
    raise exception using errcode = '55000', message = 'journey_not_available';
  end if;

  select a.id, a.journey_stage, a.paused_by, a.also_paused_by,
         coalesce(pg_catalog.to_jsonb(a) ->> 'pause_state', 'none')
           as shared_pause_state
    into v_attempt
    from public.journey_attempts as a
   where a.match_id = p_match_id
     and a.status = 'active';

  if not found
     or v_attempt.journey_stage is distinct from 'compatibility_reveal'
     or v_attempt.paused_by is not null
     or v_attempt.also_paused_by is not null
     or v_attempt.shared_pause_state is distinct from 'none' then
    raise exception using errcode = '55000', message = 'journey_not_available';
  end if;

  v_is_a := v_caller = v_match.seeker_a_id;

  select jc.*
    into v_compat
    from public.journey_compatibility as jc
   where jc.match_id = p_match_id;

  if not found then
    mine_revealed := false;
    counterpart_revealed := false;
    my_score := null;
    return next;
    return;
  end if;

  -- The table is still keyed by match_id until OA-ZYRA-156 finishes. Never
  -- reinterpret a prior-attempt row as the current Journey.
  if v_compat.attempt_id is distinct from v_attempt.id then
    raise exception using
      errcode = '55000',
      message = 'compatibility_attempt_mismatch';
  end if;

  mine_revealed := case
    when v_is_a then v_compat.seeker_a_revealed
    else v_compat.seeker_b_revealed
  end;
  counterpart_revealed := case
    when v_is_a then v_compat.seeker_b_revealed
    else v_compat.seeker_a_revealed
  end;

  -- Ordinary Reveal remains mutual: the caller's own precomputed Plus score
  -- is not returned through the ordinary state RPC until both consent flags
  -- are true.
  my_score := case
    when v_compat.seeker_a_revealed and v_compat.seeker_b_revealed then
      case
        when v_is_a then v_compat.seeker_a_score
        else v_compat.seeker_b_score
      end
    else null
  end;

  return next;
end;
$function$;

create or replace function public.zyra_reveal_journey_compatibility(
  p_match_id uuid
)
returns table(
  mine_revealed boolean,
  counterpart_revealed boolean,
  my_score numeric
)
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
  v_caller uuid := (select auth.uid());
  v_match record;
  v_attempt record;
  v_compat public.journey_compatibility%rowtype;
  v_is_a boolean;
  v_counterpart uuid;
  v_computed_score numeric;
begin
  if v_caller is null then
    raise exception using errcode = '42501', message = 'not_signed_in';
  end if;

  -- All mutating doorways lock in the same order: match, active attempt,
  -- compatibility row. This serialises simultaneous A/B reveals without a
  -- lost update or duplicate-row race.
  select m.seeker_a_id, m.seeker_b_id, m.status, m.journey_stage,
         m.suspended_by, m.also_paused_by,
         coalesce(pg_catalog.to_jsonb(m) ->> 'pause_state', 'none')
           as shared_pause_state
    into v_match
    from public.matches as m
   where m.id = p_match_id
     and v_caller in (m.seeker_a_id, m.seeker_b_id)
   for update;

  if not found then
    raise exception using errcode = '42501', message = 'not_a_party';
  end if;

  if v_match.status is distinct from 'active'
     or v_match.journey_stage is distinct from 'compatibility_reveal'
     or v_match.suspended_by is not null
     or v_match.also_paused_by is not null
     or v_match.shared_pause_state is distinct from 'none' then
    raise exception using errcode = '55000', message = 'journey_not_available';
  end if;

  select a.id, a.journey_stage, a.paused_by, a.also_paused_by,
         coalesce(pg_catalog.to_jsonb(a) ->> 'pause_state', 'none')
           as shared_pause_state
    into v_attempt
    from public.journey_attempts as a
   where a.match_id = p_match_id
     and a.status = 'active'
   for update;

  if not found
     or v_attempt.journey_stage is distinct from 'compatibility_reveal'
     or v_attempt.paused_by is not null
     or v_attempt.also_paused_by is not null
     or v_attempt.shared_pause_state is distinct from 'none' then
    raise exception using errcode = '55000', message = 'journey_not_available';
  end if;

  v_is_a := v_caller = v_match.seeker_a_id;
  v_counterpart := case
    when v_is_a then v_match.seeker_b_id
    else v_match.seeker_a_id
  end;

  insert into public.journey_compatibility (match_id, attempt_id)
  values (p_match_id, v_attempt.id)
  on conflict (match_id) do nothing;

  select jc.*
    into v_compat
    from public.journey_compatibility as jc
   where jc.match_id = p_match_id
   for update;

  if v_compat.attempt_id is distinct from v_attempt.id then
    raise exception using
      errcode = '55000',
      message = 'compatibility_attempt_mismatch';
  end if;

  -- Compute only the caller's figure, and never overwrite a stored one.
  if (v_is_a and v_compat.seeker_a_score is null)
     or (not v_is_a and v_compat.seeker_b_score is null) then
    select scored.score
      into v_computed_score
      from public.score_candidates(array[v_counterpart]) as scored
     where scored.candidate_id = v_counterpart
     limit 1;
  end if;

  if v_is_a then
    update public.journey_compatibility as jc
       set seeker_a_revealed = true,
           seeker_a_score = coalesce(jc.seeker_a_score, v_computed_score),
           revealed_at = case
             when jc.seeker_b_revealed and not jc.seeker_a_revealed
               then pg_catalog.statement_timestamp()
             when jc.seeker_a_revealed and jc.seeker_b_revealed
               then coalesce(jc.revealed_at, pg_catalog.statement_timestamp())
             else null
           end
     where jc.match_id = p_match_id;
  else
    update public.journey_compatibility as jc
       set seeker_b_revealed = true,
           seeker_b_score = coalesce(jc.seeker_b_score, v_computed_score),
           revealed_at = case
             when jc.seeker_a_revealed and not jc.seeker_b_revealed
               then pg_catalog.statement_timestamp()
             when jc.seeker_a_revealed and jc.seeker_b_revealed
               then coalesce(jc.revealed_at, pg_catalog.statement_timestamp())
             else null
           end
     where jc.match_id = p_match_id;
  end if;

  select jc.*
    into v_compat
    from public.journey_compatibility as jc
   where jc.match_id = p_match_id;

  mine_revealed := case
    when v_is_a then v_compat.seeker_a_revealed
    else v_compat.seeker_b_revealed
  end;
  counterpart_revealed := case
    when v_is_a then v_compat.seeker_b_revealed
    else v_compat.seeker_a_revealed
  end;
  my_score := case
    when v_compat.seeker_a_revealed and v_compat.seeker_b_revealed then
      case
        when v_is_a then v_compat.seeker_a_score
        else v_compat.seeker_b_score
      end
    else null
  end;

  return next;
end;
$function$;

-- Existing paid early-sight doorway, restated against the same current-state
-- and current-attempt boundary. It remains score-only: no reveal flag, joint
-- timestamp, notification or stage transition is written.
create or replace function public.zyra_compatibility_for_plus(
  p_match_id uuid
)
returns numeric
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
  v_caller uuid := (select auth.uid());
  v_match record;
  v_attempt record;
  v_compat public.journey_compatibility%rowtype;
  v_is_a boolean;
  v_counterpart uuid;
  v_score numeric;
begin
  if v_caller is null then
    raise exception using errcode = '42501', message = 'not_signed_in';
  end if;

  select m.seeker_a_id, m.seeker_b_id, m.status, m.journey_stage,
         m.suspended_by, m.also_paused_by,
         coalesce(pg_catalog.to_jsonb(m) ->> 'pause_state', 'none')
           as shared_pause_state
    into v_match
    from public.matches as m
   where m.id = p_match_id
     and v_caller in (m.seeker_a_id, m.seeker_b_id)
   for update;

  if not found then
    raise exception using errcode = '42501', message = 'not_a_party';
  end if;

  if v_match.status is distinct from 'active'
     or v_match.journey_stage is distinct from 'compatibility_reveal'
     or v_match.suspended_by is not null
     or v_match.also_paused_by is not null
     or v_match.shared_pause_state is distinct from 'none' then
    raise exception using errcode = '55000', message = 'journey_not_available';
  end if;

  select a.id, a.journey_stage, a.paused_by, a.also_paused_by,
         coalesce(pg_catalog.to_jsonb(a) ->> 'pause_state', 'none')
           as shared_pause_state
    into v_attempt
    from public.journey_attempts as a
   where a.match_id = p_match_id
     and a.status = 'active'
   for update;

  if not found
     or v_attempt.journey_stage is distinct from 'compatibility_reveal'
     or v_attempt.paused_by is not null
     or v_attempt.also_paused_by is not null
     or v_attempt.shared_pause_state is distinct from 'none' then
    raise exception using errcode = '55000', message = 'journey_not_available';
  end if;

  v_is_a := v_caller = v_match.seeker_a_id;
  v_counterpart := case
    when v_is_a then v_match.seeker_b_id
    else v_match.seeker_a_id
  end;

  if not exists (
    select 1
      from public.profile_unlocks as unlocks
     where unlocks.unlocker_id = v_caller
       and unlocks.unlocked_id = v_counterpart
       and unlocks.unlock_type in ('paid_plus_single', 'paid_plus_bundle')
  ) then
    raise exception using errcode = '42501', message = 'plus_required';
  end if;

  insert into public.journey_compatibility (match_id, attempt_id)
  values (p_match_id, v_attempt.id)
  on conflict (match_id) do nothing;

  select jc.*
    into v_compat
    from public.journey_compatibility as jc
   where jc.match_id = p_match_id
   for update;

  if v_compat.attempt_id is distinct from v_attempt.id then
    raise exception using
      errcode = '55000',
      message = 'compatibility_attempt_mismatch';
  end if;

  v_score := case
    when v_is_a then v_compat.seeker_a_score
    else v_compat.seeker_b_score
  end;

  if v_score is null then
    select scored.score
      into v_score
      from public.score_candidates(array[v_counterpart]) as scored
     where scored.candidate_id = v_counterpart
     limit 1;

    if v_score is not null then
      if v_is_a then
        update public.journey_compatibility as jc
           set seeker_a_score = v_score
         where jc.match_id = p_match_id;
      else
        update public.journey_compatibility as jc
           set seeker_b_score = v_score
         where jc.match_id = p_match_id;
      end if;
    end if;
  end if;

  return v_score;
end;
$function$;

revoke all on function public.zyra_journey_compatibility_state(uuid)
  from public, anon, authenticated, service_role;
revoke all on function public.zyra_reveal_journey_compatibility(uuid)
  from public, anon, authenticated, service_role;
revoke all on function public.zyra_compatibility_for_plus(uuid)
  from public, anon, authenticated, service_role;

grant execute on function public.zyra_journey_compatibility_state(uuid)
  to authenticated;
grant execute on function public.zyra_reveal_journey_compatibility(uuid)
  to authenticated;
grant execute on function public.zyra_compatibility_for_plus(uuid)
  to authenticated;

comment on function public.zyra_journey_compatibility_state(uuid) is
  'OA-ZYRA-283. Current active Journey compatibility state, caller-relative. '
  'Returns mutual flags and only the caller-owned score after mutual reveal.';
comment on function public.zyra_reveal_journey_compatibility(uuid) is
  'OA-ZYRA-283. Reveals and scores only the authenticated Seeker side for the '
  'current active, unpaused Compatibility Reveal attempt.';
comment on function public.zyra_compatibility_for_plus(uuid) is
  'DR-ZYRA-135 / OA-ZYRA-283. Entitled early sight of only the caller-owned '
  'score; does not alter either reveal flag, timestamp, stage or notification.';

-- RPC-only table. Dropping the old permissive policies is deliberate defence
-- in depth: a later accidental table grant must not silently resurrect the
-- whole-row participant boundary.
revoke all privileges on table public.journey_compatibility
  from public, anon, authenticated;

drop policy if exists journey_compatibility_read
  on public.journey_compatibility;
drop policy if exists journey_compatibility_insert
  on public.journey_compatibility;
drop policy if exists journey_compatibility_update
  on public.journey_compatibility;

alter table public.journey_compatibility enable row level security;

comment on table public.journey_compatibility is
  'RPC-only Compatibility Reveal state. Client roles have no direct table '
  'privileges; caller-relative access is enforced by OA-ZYRA-283 functions.';
