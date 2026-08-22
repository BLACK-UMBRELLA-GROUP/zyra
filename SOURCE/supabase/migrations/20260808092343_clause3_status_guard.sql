-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260808092343, applied name
-- 'clause3_status_guard') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- STEP 1: stop a mutual Like exposing both families to each other.
-- Founder approved 2026-08-08. Only clause 3 changes.
--
-- ── WHAT WAS WRONG. Clause 3 asked one question — "are we both party to an
-- attempt?" — with no regard for what stage that attempt had reached. Any
-- participant therefore saw any other participant from the moment
-- create_match_on_mutual_like() fired. Measured at 'potential', with a
-- mutual Like and nothing else:
--
--   Seeker A -> Seeker B .................. true
--   Seeker A -> B's GUARDIAN .............. true   <- Unlock+ sells this
--   Guardian A -> Seeker B ................ true
--   Guardian A -> Guardian B .............. true
--
-- Two Seekers liking each other is consent to be CONSIDERED. It was being
-- read as consent for both families to MEET.
--
-- ── NOT A GUARDIAN PROBLEM, which is how it was first described. The
-- clause does not look at roles, so a SEEKER also got the counterpart's
-- Guardian roster free. The Unlock+ bypass was never Guardian-specific.
--
-- ── WHY SEEKER <-> SEEKER IS EXEMPT, and it is not a softening.
-- Found by testing rather than reading: when a matched counterpart pauses
-- their profile, clause 4 stops applying (it requires is_active) and THIS
-- clause is the only thing still making them visible. A blanket guard would
-- delete a paused match from the other person's Potential Journeys.
--
-- ── THIS IS A DELAY, NOT THE PRIVACY MODEL. From the moment a Journey goes
-- active, a Seeker and their Guardians still see the counterpart's whole
-- Guardian roster for nothing. Closing that needs the gate-level matrix
-- (wali_gate), which is Step 4/5. Nobody should read this migration as
-- having solved Guardian visibility.
--
-- ── STILL MISSING FROM THIS CLAUSE: a block check. Clause 4 has one, both
-- paid accessors have one, clause 3 does not — so a blocked person and
-- their Guardians can still see the blocker. Deliberately NOT fixed here:
-- the Founder has decided blocking should END an active Journey, and the
-- check ships with that change as Step 1b rather than leaving two people in
-- a live Journey who cannot see each other.

create or replace function public.zyra_can_view_profile(p_target uuid)
 returns boolean
 language sql
 stable
 security definer
 set search_path to 'public'
as $function$
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

    -- PARTICIPANTS OF A SHARED ATTEMPT. Covers "my match partner" and "my
    -- Seeker's match partner" in one question, because a Guardian is
    -- already a participant of their Seeker's attempts.
    --
    -- GUARDED ON STATUS 2026-08-08 — see the header. Anything involving a
    -- Guardian now waits for the Journey to actually start. Seeker to
    -- Seeker is exempt so a paused counterpart does not disappear.
    --
    -- matches_select has carried `status <> 'potential'` for Guardians
    -- since 2026-07-26. This brings profile visibility into line with the
    -- row visibility that was already correct.
    or exists (
      select 1
      from public.zyra_attempt_participant_rows me
      join public.zyra_attempt_participant_rows them
        on them.attempt_id = me.attempt_id
      where me.user_id = (select auth.uid())
        and them.user_id = p_target
        and (
              (me.role = 'seeker' and them.role = 'seeker')
           or me.attempt_status <> 'potential'
        )
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
$function$;
