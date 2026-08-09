-- APPLIED LIVE 2026-08-08. Version 20260808101938.
-- Founder-approved 2026-08-08. Supersedes 20260808101800.
--
-- Fixes the release blocker recorded in GUARDIAN & ROMANTIC RULES
-- section 7 (Founder-classified 2026-08-07).
--
-- WHAT WAS BROKEN
-- ZyraJourneyService.advanceStage() wrote matches.journey_stage from the
-- client. matches has a SELECT policy and no UPDATE policy, so RLS
-- discarded the write: 0 rows, no error, inside catch (_) {}. Because
-- the three transitions it served are the FIRST three, a Journey could
-- never leave compatibility_reveal — phase_1 onward, which do work via
-- the Family Review path, were unreachable. Verified live 2026-08-08.
--
-- WHAT THIS DOES NOT DO
-- The four gated transitions (phase_1->2, ->3, ->family_stage,
-- ->conversation) stay with open_family_review()/wali_review_decision().
-- This function REFUSES them. Accepting them would make it a way to skip
-- the 48-hour Family Review Period, which is the one thing the Guardian
-- side of the ritual is built on.
--
-- SIGNATURE — from_stage, not to_stage
-- The caller says which stage it believes it has completed; the server
-- decides what comes next from a fixed map. A client cannot name a
-- destination, so there is no skip-ahead to validate. It also doubles as
-- a compare-and-swap token: a stale screen advancing from a stage the
-- Journey has already left gets 'stage_moved', not a rewind.
--
-- GATES — all three provable from existing tables (Founder 2026-08-08)
--   compatibility_reveal -> salam_exchange
--       both revealed AND both pressed Continue.
--       "Neither of you sees the result until you both choose to reveal"
--       plus the Continue Journey checkpoint action.
--   salam_exchange -> wali_gate
--       both Salams sent. "Neither moves forward until both have acted."
--   wali_gate -> phase_1
--       BOTH Seekers hold an active Main Guardian. Founder-decided
--       2026-08-08. Previously the client checked only the acting
--       Seeker's own Guardian and then advanced the SHARED stage, so one
--       party dragged the pair past the gate and the other never saw it.
--       The Family Review Period expects a Main Guardian on both sides
--       to function at all.
--
-- ES-03: these are religious-propriety and consent rules. They are now
-- enforced server-side; the client checks are UX only.

create or replace function public.zyra_advance_stage(
  p_match_id   uuid,
  p_from_stage text
)
returns table (advanced boolean, stage text, reason text)
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  caller     uuid := (select auth.uid());
  m          record;
  next_stage text;
  a_ok       boolean;
  b_ok       boolean;
begin
  if caller is null then
    raise exception 'not_authenticated';
  end if;

  -- FOR UPDATE, not a bare SELECT. Audit R7 was a TOCTOU race created by
  -- exactly this omission; two clients polling this function
  -- concurrently is the normal case, not the edge case.
  select * into m from matches where id = p_match_id for update;
  if not found then
    raise exception 'match_not_found';
  end if;
  if caller <> m.seeker_a_id and caller <> m.seeker_b_id then
    raise exception 'not_a_party';
  end if;

  -- Returned, not raised: these are ordinary states a screen can be
  -- sitting in, not programming errors.
  if m.status <> 'active' then
    return query select false, m.journey_stage, 'journey_not_active'; return;
  end if;
  if m.suspended_by is not null then
    return query select false, m.journey_stage, 'journey_paused'; return;
  end if;
  if m.journey_stage is distinct from p_from_stage then
    return query select false, m.journey_stage, 'stage_moved'; return;
  end if;

  next_stage := case p_from_stage
                  when 'compatibility_reveal' then 'salam_exchange'
                  when 'salam_exchange'       then 'wali_gate'
                  when 'wali_gate'            then 'phase_1'
                end;

  if next_stage is null then
    if p_from_stage in ('phase_1','phase_2','phase_3','family_stage') then
      raise exception 'gated_transition'
        using hint = 'This transition opens a Family Review Period. '
                     'Call open_family_review() instead.';
    end if;
    if p_from_stage = 'conversation' then
      return query select false, m.journey_stage, 'terminal_stage'; return;
    end if;
    raise exception 'unknown_stage: %', p_from_stage;
  end if;

  -- Record the caller's own act where the stage asks for one. Idempotent.
  -- Written here rather than by the client because there is no INSERT
  -- grant on the table — a checkpoint cannot be forged, nor written on
  -- the other person's behalf.
  if p_from_stage = 'compatibility_reveal' then
    insert into journey_stage_checkpoints as jsc (match_id, stage, seeker_id)
    values (p_match_id, p_from_stage, caller)
    on conflict do nothing;
  end if;

  if p_from_stage = 'compatibility_reveal' then

    select coalesce(jc.seeker_a_revealed, false) and coalesce(jc.seeker_b_revealed, false)
      into a_ok
      from journey_compatibility jc where jc.match_id = p_match_id;
    if not coalesce(a_ok, false) then
      return query select false, p_from_stage, 'waiting_for_reveal'; return;
    end if;

    -- ALIAS-QUALIFIED: jsc.stage, not stage. The unqualified form
    -- collided with the OUT parameter and raised 42702. See the header
    -- of 20260808101800.
    select count(distinct jsc.seeker_id) = 2 into b_ok
      from journey_stage_checkpoints jsc
     where jsc.match_id  = p_match_id
       and jsc.stage     = p_from_stage
       and jsc.seeker_id in (m.seeker_a_id, m.seeker_b_id);
    if not coalesce(b_ok, false) then
      return query select false, p_from_stage, 'waiting_for_continue'; return;
    end if;

  elsif p_from_stage = 'salam_exchange' then

    select count(distinct js.seeker_id) = 2 into a_ok
      from journey_salams js
     where js.match_id  = p_match_id
       and js.seeker_id in (m.seeker_a_id, m.seeker_b_id);
    if not coalesce(a_ok, false) then
      return query select false, p_from_stage, 'waiting_for_salam'; return;
    end if;

  elsif p_from_stage = 'wali_gate' then

    -- Reported separately so the screen can say "link a Guardian" to the
    -- person who must act and "waiting for them" to the one who cannot.
    -- Neither message names the Guardian or reveals anything beyond
    -- whether the gate is met, which both parties learn anyway by being
    -- held at it.
    select exists (select 1 from wali_links wl
                    where wl.seeker_id = caller and wl.is_main and wl.status = 'active')
      into a_ok;
    if not a_ok then
      return query select false, p_from_stage, 'guardian_required_self'; return;
    end if;

    select exists (select 1 from wali_links wl
                    where wl.seeker_id = case when caller = m.seeker_a_id
                                              then m.seeker_b_id else m.seeker_a_id end
                      and wl.is_main and wl.status = 'active')
      into b_ok;
    if not b_ok then
      return query select false, p_from_stage, 'guardian_required_other'; return;
    end if;

  end if;

  -- Compare-and-swap on journey_stage: if another session advanced
  -- between the lock and here, this affects 0 rows and we report the
  -- truth rather than claiming a move we did not make.
  update matches
     set journey_stage = next_stage
   where id = p_match_id and journey_stage = p_from_stage;

  if not found then
    select m2.journey_stage into next_stage from matches m2 where m2.id = p_match_id;
    return query select false, next_stage, 'stage_moved'; return;
  end if;

  -- Keep the attempt row in step (Founder-approved 2026-08-08).
  -- promote_journey_to_active(), resolve_family_review_if_due() and
  -- wali_review_decision() all still write matches only, so the attempt
  -- copy drifts through those paths. Raised as an open item rather than
  -- silently fixed here — this function owns its own writes, not theirs.
  update journey_attempts ja
     set journey_stage = next_stage
   where ja.match_id = p_match_id and ja.status <> 'ended';

  return query select true, next_stage, 'advanced';
end;
$function$;

revoke execute on function public.zyra_advance_stage(uuid, text) from public, anon;
grant  execute on function public.zyra_advance_stage(uuid, text) to authenticated;

comment on function public.zyra_advance_stage(uuid, text) is
  'Advances the three ungated Pre-Journey Ritual transitions and REFUSES '
  'the four Family-Review-gated ones. Replaces the client-side UPDATE that '
  'RLS silently discarded (release blocker, Founder 2026-08-07). Returns '
  '(advanced, stage, reason) — callers must surface the reason, never '
  'swallow it. See PRE-JOURNEY RITUAL and GUARDIAN & ROMANTIC RULES (current versions).';

-- VERIFIED EMPIRICALLY 2026-08-08 against two real seeded Seekers, a real
-- match, then torn down. 17/17 PASS:
--    1 no reveals yet                    waiting_for_reveal
--    2 one Continue only                 waiting_for_continue
--    3 both Continue                     advanced -> salam_exchange
--    4 attempt row kept in step          salam_exchange
--    5 checkpoint attempt_id backfilled  ok (trigger fired)
--    6 stale from_stage                  stage_moved
--    7 one Salam only                    waiting_for_salam
--    8 both Salams                       advanced -> wali_gate
--    9 male has Guardian, female none    guardian_required_other
--   10 female asked                      guardian_required_self
--   11 both Guardians                    advanced -> phase_1
--   12 gated transition                  refused: gated_transition
--   13 non-party caller                  refused: not_a_party
--   14 paused Journey                    journey_paused
--   15 ended Journey                     journey_not_active
--   16 teardown: matches left behind     0
--   17 teardown: checkpoints left behind 0
-- Grants: anon false, PUBLIC false, authenticated true.
