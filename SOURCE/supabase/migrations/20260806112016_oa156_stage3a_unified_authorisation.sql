-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806112016, applied name
-- 'oa156_stage3a_unified_authorisation') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- OA-ZYRA-156 STAGE 3a — the unified authorisation model.
-- Founder-approved 2026-08-06 (ZYRA_AUTHORISATION_MODEL_PROPOSAL V1).
--
-- Behaviour must be IDENTICAL to the baseline. The only thing changing is
-- where the rules live.
--
-- ============ ONE PERFORMANCE DECISION, MADE INSIDE THE APPROVED SHAPE ==
--
-- The approved design is zyra_attempt_participants() as the single source
-- of truth. Implemented naively, "do I share an attempt with this person"
-- becomes a function call PER ATTEMPT — O(attempts) with a set-returning
-- call each time, on a table that only grows.
--
-- The participant RULE is therefore expressed once as a VIEW, and the
-- approved function reads from it. The function's signature and contract
-- are unchanged; it is still the single place a new role is added. But the
-- set-based consumers can now join instead of looping.
--
-- This is an implementation detail inside the approved architecture rather
-- than a change to it — the Founder's requirement was that participation
-- have exactly one definition, and it does. Flagged explicitly because he
-- asked to be told about performance implications.

create or replace view public.zyra_attempt_participant_rows as
  -- THE ONE DEFINITION OF PARTICIPATION. Add new roles HERE.
  select a.id as attempt_id, m.seeker_a_id as user_id, 'seeker'::text as role
    from public.journey_attempts a join public.matches m on m.id = a.match_id
  union
  select a.id, m.seeker_b_id, 'seeker'
    from public.journey_attempts a join public.matches m on m.id = a.match_id
  union
  -- Guardians resolved from wali_links AS IT IS NOW. V3 §10 wants this
  -- recorded per attempt; the join table for that does not exist yet and
  -- inventing per-attempt Guardian history would be fabricating a record
  -- (Founder agreed, 2026-08-06). With 0 attempts, current-Guardian and
  -- Guardian-at-the-time are the same set. Stage 3b item.
  select a.id, w.wali_id, 'guardian'
    from public.journey_attempts a
    join public.matches   m on m.id = a.match_id
    join public.wali_links w on w.status = 'active'
                            and w.seeker_id in (m.seeker_a_id, m.seeker_b_id);

comment on view public.zyra_attempt_participant_rows is
  'SINGLE DEFINITION of Journey attempt participation. zyra_attempt_participants() and every visibility function read from here. Add a new role (Mediator, Family Account, Mosque Representative) to THIS view and nowhere else.';

revoke all on public.zyra_attempt_participant_rows from public, anon, authenticated;

-- The approved function, now a thin read of the view. Same signature.
create or replace function public.zyra_attempt_participants(p_attempt uuid)
returns table (user_id uuid, role text)
language sql stable security definer set search_path to 'public'
as $$
  select r.user_id, r.role
  from public.zyra_attempt_participant_rows r
  where r.attempt_id = p_attempt;
$$;

-- =====================================================================
-- "May I see this attempt?" — reads auth.uid() internally.
--
-- The approved V3 signature was attempt_visible_to(attempt_id, auth.uid()).
-- The Founder approved dropping the second parameter: a SECURITY DEFINER
-- function that accepts the SUBJECT as an argument can be asked about
-- anybody, which is an information leak on its own and an authorisation
-- bypass the moment a client-supplied value reaches it. Same defect class
-- as H-2 and H-3 in the security sprint.
-- =====================================================================
create or replace function public.zyra_can_view_attempt(p_attempt uuid)
returns boolean
language sql stable security definer set search_path to 'public'
as $$
  select exists (
    select 1 from public.zyra_attempt_participant_rows r
    where r.attempt_id = p_attempt
      and r.user_id = (select auth.uid())
  );
$$;

comment on function public.zyra_can_view_attempt(uuid) is
  'May the CALLER see this attempt? Boolean, full access only. The successor-Guardian summary case is deliberately NOT here — see zyra_attempt_summary_for_guardian().';

-- =====================================================================
-- The successor-Guardian exception, kept narrow and visible.
--
-- V3 §10: a NEW Guardian sees THAT a previous Journey existed and how it
-- ended — never its contents, and never the previous Guardian's notes.
--
-- Founder: "I would rather have one obvious exception than quietly
-- increase the complexity of the core authorisation layer." So this is a
-- separate function returning three facts, not a role in the participant
-- set. It cannot be mistaken for full access because it cannot return
-- anything else.
-- =====================================================================
create or replace function public.zyra_attempt_summary_for_guardian(p_seeker uuid)
returns table (attempt_id uuid, started_at timestamptz, ended_at timestamptz, ended boolean)
language sql stable security definer set search_path to 'public'
as $$
  select a.id, a.started_at, a.ended_at, (a.status = 'ended')
  from public.journey_attempts a
  join public.matches m on m.id = a.match_id
  where p_seeker in (m.seeker_a_id, m.seeker_b_id)
    -- caller must be an ACTIVE Guardian of that Seeker
    and exists (
      select 1 from public.wali_links w
      where w.seeker_id = p_seeker
        and w.wali_id   = (select auth.uid())
        and w.status    = 'active'
    );
$$;

comment on function public.zyra_attempt_summary_for_guardian(uuid) is
  'V3 §10. THREE FACTS ONLY — that a Journey existed, when, and whether it ended. No stage, no reason, no notes, no other party. A Guardian who was not there must never inherit the previous Guardian''s observations.';

-- =====================================================================
-- zyra_can_view_profile — refactored onto the shared participant set.
--
-- Clauses 3 and 4 previously inlined match-participation SQL that
-- zyra_can_view_attempt would have restated. They now ask the same view.
-- Adding a Mediator to that view grants them the attempt AND the profiles
-- of the people in it, together, in one edit — which is what the Founder's
-- "one authoritative place" requirement actually demands.
--
-- BEHAVIOUR IS UNCHANGED. matches -> attempts is 1:1 via the stage-2
-- trigger, so "shares an attempt" and "shares a match" are the same set.
-- =====================================================================
create or replace function public.zyra_can_view_profile(p_target uuid)
returns boolean
language sql stable security definer set search_path to 'public'
as $$
  select
    -- yourself
    p_target = (select auth.uid())

    -- your Guardian, or your Seeker. Either direction, any gender.
    -- NOT from the participant view: this link exists with or without a
    -- Journey, so it is a fact about the pair of people, not an attempt.
    or exists (
      select 1 from public.wali_links w
      where w.status = 'active'
        and (   (w.seeker_id = p_target and w.wali_id   = (select auth.uid()))
             or (w.wali_id   = p_target and w.seeker_id = (select auth.uid())) )
    )

    -- WAS clauses 3 and 4, inline match SQL. Now one question asked of the
    -- participant set: does an attempt exist that we are both party to?
    -- This covers "my match partner" AND "my Seeker's match partner"
    -- without stating either separately, because a Guardian is already a
    -- participant of their Seeker's attempts.
    or exists (
      select 1
      from public.zyra_attempt_participant_rows me
      join public.zyra_attempt_participant_rows them
        on them.attempt_id = me.attempt_id
      where me.user_id = (select auth.uid())
        and them.user_id = p_target
    )

    -- BROWSING. Active, published, not blocked, opposite gender.
    or exists (
      select 1
      from public.profiles p
      cross join lateral (
        select pv.role, pv.gender from public.profiles pv where pv.id = (select auth.uid())
      ) viewer
      where p.id = p_target
        and p.is_active = true
        and p.profile_complete = true
        and not public.zyra_block_exists(p_target)
        and viewer.role = 'seeker'
        and viewer.gender is not null
        and p.gender is not null
        and p.gender <> viewer.gender
    );
$$;

comment on function public.zyra_can_view_profile(uuid) is
  'May the CALLER see this profile? self · Guardian link · shares an attempt (via zyra_attempt_participant_rows) · opposite-gender browsing. Participation logic is NOT duplicated here — it is read from the one view.';

revoke all on function public.zyra_can_view_attempt(uuid)              from public, anon;
revoke all on function public.zyra_attempt_summary_for_guardian(uuid)  from public, anon;
grant execute on function public.zyra_can_view_attempt(uuid)             to authenticated;
grant execute on function public.zyra_attempt_summary_for_guardian(uuid) to authenticated;
