-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260808093501, applied name
-- 'block_revocation_is_permanent') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- FIX to the migration applied minutes earlier. Caught by its own
-- verification, which is the only reason it is not now in production
-- behaviour.
--
-- ── THE BUG. Step 1b keyed clause 3's revocation on "does a block row
-- exist between the two Seekers". That row is DELETED by
-- zyra_unblock_user(). So unblocking restored visibility:
--
--   after unblock, match status ......... ended   (correct)
--   after unblock, blocked -> blocker ... TRUE    (WRONG)
--
-- Which is a straight violation of the invariant recorded in that same
-- migration: "Nothing may automatically recreate or restore any
-- relationship, VISIBILITY, conversation or Journey that existed before
-- the block."
--
-- ── WHY IT HAPPENED. I attached a permanent consequence to a transient
-- fact. The block row is a live state that the user can clear; the
-- terminal boundary is created by the ENDING, which is permanent and
-- recorded on the match itself.
--
-- ── THE FIX. Clause 3 now refuses on EITHER:
--   (a) a live block between the two Seekers — covers a pair blocked with
--       no Journey to end, and a pair whose Journey ended normally before
--       the block, and
--   (b) the match having been ended for safety — durable, survives
--       unblocking, and is the actual boundary.
--
-- (b) alone is nearly sufficient, since zyra_block_user() ends every live
-- Journey with safety_concern. (a) is kept for the case where the Journey
-- was already ended for an ordinary reason when the block arrived: that
-- pair should not see each other either, and no safety_concern exists to
-- catch it.
--
-- ── WHAT IS STILL PERMITTED, deliberately. After unblocking, the two may
-- form a NEW Journey — zyra_can_match() allows it once no block stands.
-- Founder: "If both people ever wish to reconnect, it must start from a
-- completely new Journey." The OLD attempt confers nothing, forever; a new
-- one starts clean. Those are different questions and only the first is
-- closed here.

create or replace function public.zyra_can_view_profile(p_target uuid)
 returns boolean
 language sql
 stable
 security definer
 set search_path to 'public'
as $function$
  select
    p_target = (select auth.uid())

    or exists (
      select 1 from public.wali_links w
      where w.status = 'active'
        and (   (w.seeker_id = p_target and w.wali_id   = (select auth.uid()))
             or (w.wali_id   = p_target and w.seeker_id = (select auth.uid())) )
    )

    -- PARTICIPANTS OF A SHARED ATTEMPT.
    --   status guard 2026-08-08 (Step 1)  — families do not meet at 'potential'
    --   block  guard 2026-08-08 (Step 1b) — attempt-level, not viewer-level:
    --     zyra_block_exists() compares auth.uid() to the target, which
    --     catches the two Seekers and misses all four Guardians.
    --   PERMANENCE FIX 2026-08-08 — the guard also keys on the match having
    --     been ended for safety, so unblocking does not restore sight.
    or exists (
      select 1
      from public.zyra_attempt_participant_rows me
      join public.zyra_attempt_participant_rows them
        on them.attempt_id = me.attempt_id
      join public.matches mm on mm.id = me.match_id
      where me.user_id = (select auth.uid())
        and them.user_id = p_target
        and (
              (me.role = 'seeker' and them.role = 'seeker')
           or me.attempt_status <> 'potential'
        )
        -- (b) durable: a safety ending is terminal, block row or not
        and mm.end_reason is distinct from 'safety_concern'
        -- (a) live: a standing block, for pairs with nothing to end
        and not exists (
          select 1 from public.profile_blocks b
          where (b.blocker_id = mm.seeker_a_id and b.blocked_id = mm.seeker_b_id)
             or (b.blocker_id = mm.seeker_b_id and b.blocked_id = mm.seeker_a_id)
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
