-- APPLIED LIVE 2026-08-08, version 20260808115254.
-- Item 1 of the autonomous set authorised by the Founder via Fable.
-- STRICT REDUCTION. Rationale and the measured before/after:
-- GUARDIAN & ROMANTIC RULES, section 7d.
--
-- Clause 3 becomes Seeker <-> Seeker ONLY. Guardians derive nothing from
-- being attached to an attempt; clause 2 (own ward) is untouched and is
-- the whole legitimate basis of Guardian visibility.
-- Photos and ages follow automatically — both delegate here.

create or replace function public.zyra_can_view_profile(p_target uuid)
 returns boolean language sql stable security definer set search_path to 'public'
as $function$
  select
    p_target = (select auth.uid())
    -- CLAUSE 2 — own ward / own Guardian. UNCHANGED.
    or exists (
      select 1 from public.wali_links w
      where w.status = 'active'
        and (   (w.seeker_id = p_target and w.wali_id   = (select auth.uid()))
             or (w.wali_id   = p_target and w.seeker_id = (select auth.uid())) )
    )
    -- CLAUSE 3 — the two Seekers of a shared attempt. SEEKERS ONLY.
    -- Guardians removed 2026-08-08. The old status guard went with them:
    -- it existed to stop families meeting at 'potential', and
    -- Seeker<->Seeker was always exempt anyway (clause 4 requires
    -- is_active, so this clause is the only thing keeping a PAUSED
    -- counterpart visible). Block guards retained verbatim.
    or exists (
      select 1
      from public.zyra_attempt_participant_rows me
      join public.zyra_attempt_participant_rows them on them.attempt_id = me.attempt_id
      join public.matches mm on mm.id = me.match_id
      where me.user_id = (select auth.uid())
        and them.user_id = p_target
        and me.role = 'seeker' and them.role = 'seeker'
        and mm.end_reason is distinct from 'safety_concern'
        and not exists (
          select 1 from public.profile_blocks b
          where (b.blocker_id = mm.seeker_a_id and b.blocked_id = mm.seeker_b_id)
             or (b.blocker_id = mm.seeker_b_id and b.blocked_id = mm.seeker_a_id)
        )
    )
    -- CLAUSE 4 — browsing. UNCHANGED.
    or exists (
      select 1 from public.profiles p
      cross join lateral (
        select pv.role, pv.gender from public.profiles pv where pv.id = (select auth.uid())
      ) viewer
      where p.id = p_target
        and p.is_active = true and p.profile_complete = true
        and not public.zyra_block_exists(p_target)
        and viewer.role = 'seeker'
        and viewer.gender is not null and p.gender is not null
        and p.gender <> viewer.gender
    );
$function$;

-- Second surface, found while mapping clause 3: zyra_attempt_participants
-- is SECURITY DEFINER with NO CALLER CHECK — any signed-in user holding
-- any attempt id received that attempt's full participant roster,
-- bypassing clause 3 entirely. Zero Dart callers; revoking breaks nothing.
revoke execute on function public.zyra_attempt_participants(uuid) from public, anon, authenticated;

comment on function public.zyra_attempt_participants(uuid) is
  'NOT CLIENT-CALLABLE as of 2026-08-08. Has no caller check. Do not '
  're-grant without adding a zyra_can_view_attempt() guard.';

-- VERIFIED 2026-08-08, 18/18. All 7 measured disclosure rows -> false;
-- ages_for and photo access follow; clause 2 and clause 3 Seeker paths
-- intact; paused-counterpart regression holds; both block guards hold.
