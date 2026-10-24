-- ⟲ APPLIED-IN-REMOTE RECORD — 2026-08-12 stewardship pass.
--
-- This migration was applied straight to the live database via MCP on
-- 2026-08-11 and existed in no repo file. This record file preserves the
-- version slot and WHAT IT DID; the verbatim statements live in
-- supabase_migrations.schema_migrations version 20260811153643 and can be
-- regenerated with tools/export_missing_migrations.sql (OA-ZYRA-198).
-- House precedent for a record-not-body file: 20260811094513.
--
-- WHAT IT DID:
-- OA-ZYRA-193(c) part 3 — zyra_can_view_profile() clause 4 now requires BOTH viewer and target onboarding_complete (clauses 1-3 untouched, deliberately); zyra_can_match() requires both parties onboarding_complete. Measured before enforcing: 144/144 seeded pass
-- OA-ZYRA-198 RECOVERY — 2026-09-10:
-- The record-only placeholder was replaced in place under the Founder's
-- governed history-recovery authority using the one retained production
-- migration-history statement for version 20260811153643.
-- Retained identity: 6,754 characters; 7,170 UTF-8 bytes;
-- SHA-256 cc919cc511b71d3061dac6036687ad353cdb43fa39f33e6b9d6e3f4bfd2ac4cc.
-- The bytes between the BEGIN/END markers are exactly statements[1];
-- neither marker is part of the retained statement.
--
-- BEGIN VERBATIM LIVE STATEMENT 20260811153643
-- ═══════════════════════════════════════════════════════════════════════
-- OA-ZYRA-193(c) — PART 3: THE GATE ENFORCED
-- ═══════════════════════════════════════════════════════════════════════
--
-- "Finish onboarding or you are not in the pool" — Founder, 2026-08-11.
--
-- BOTH DIRECTIONS, because the harm runs both ways. An incomplete Seeker
-- cannot be SEEN (nobody can score them properly, so nobody should be shown
-- them), and cannot SEE (their own preferences are partial, so every number
-- they would be given is misleading). One-sided would have been the easier
-- change and the wrong one.
--
-- ⚠️ ONLY CLAUSE 4. Clauses 1-3 are untouched, deliberately:
--   1  yourself — you must always be able to see your own profile, and
--      especially while incomplete, since that is when you are fixing it
--   2  your Guardian, or your ward — a family relationship does not lapse
--      because someone has three questions left
--   3  the other Seeker in a shared attempt — an Active Journey must never
--      break because a profile changed underneath it. If the data can go
--      backwards (it can — an answer can be edited), a running Journey
--      would otherwise half-disappear for one party and not the other.
--
-- Measured before enforcing: 144 of 144 seeded Seekers pass, all six dev
-- accounts pass, nobody is locked out by this change.

CREATE OR REPLACE FUNCTION public.zyra_can_view_profile(p_target uuid)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  select
    p_target = (select auth.uid())

    -- CLAUSE 2 — your own ward, or your own Guardian. UNCHANGED.
    -- This is the entire legitimate basis of Guardian visibility.
    or exists (
      select 1 from public.wali_links w
      where w.status = 'active'
        and (   (w.seeker_id = p_target and w.wali_id   = (select auth.uid()))
             or (w.wali_id   = p_target and w.seeker_id = (select auth.uid())) )
    )

    -- CLAUSE 3 — the two Seekers of a shared attempt. SEEKERS ONLY.
    --   2026-08-08 (item 1): Guardians removed entirely. Previously any
    --     participant could see any participant, which handed every
    --     Guardian a gender-blind view of the other family.
    --   The old status guard (Step 1) is gone with them — it existed to
    --     stop families meeting at 'potential', and Seeker<->Seeker was
    --     always exempt from it anyway, because clause 4 requires
    --     is_active and this clause is the only thing keeping a PAUSED
    --     counterpart visible in Potential Journeys.
    --   Block guards (Step 1b) retained verbatim, both halves.
    --   2026-08-11: NOT gated on onboarding completeness, on purpose —
    --     see the header. A live Journey outranks a tidy pool.
    or exists (
      select 1
      from public.zyra_attempt_participant_rows me
      join public.zyra_attempt_participant_rows them
        on them.attempt_id = me.attempt_id
      join public.matches mm on mm.id = me.match_id
      where me.user_id   = (select auth.uid())
        and them.user_id = p_target
        and me.role   = 'seeker'
        and them.role = 'seeker'
        -- (b) durable: a safety ending is terminal, block row or not
        and mm.end_reason is distinct from 'safety_concern'
        -- (a) live: a standing block, for pairs with nothing to end
        and not exists (
          select 1 from public.profile_blocks b
          where (b.blocker_id = mm.seeker_a_id and b.blocked_id = mm.seeker_b_id)
             or (b.blocker_id = mm.seeker_b_id and b.blocked_id = mm.seeker_a_id)
        )
    )

    -- CLAUSE 4 — browsing.
    --
    -- 2026-08-11, OA-ZYRA-193(c): both parties must have finished
    -- onboarding. Reads the materialised profiles.onboarding_complete
    -- rather than recomputing — this function is the USING clause of
    -- profiles_select and runs per row on every profile read in the app.
    or exists (
      select 1
      from public.profiles p
      cross join lateral (
        select pv.role, pv.gender, pv.onboarding_complete
          from public.profiles pv where pv.id = (select auth.uid())
      ) viewer
      where p.id = p_target
        and p.is_active = true
        and p.profile_complete = true
        and p.onboarding_complete = true          -- they finished
        and viewer.onboarding_complete = true     -- and so did you
        and not public.zyra_block_exists(p_target)
        and viewer.role = 'seeker'
        and viewer.gender is not null
        and p.gender is not null
        and p.gender <> viewer.gender
    );
$function$;

-- ── AND THE MATCH ITSELF ───────────────────────────────────────────────
--
-- Belt and braces, and not redundant: a like is created through a policy
-- path, and create_match_on_mutual_like() calls zyra_can_match() as the
-- final word on whether a pair may become a match. Mutual interest is
-- necessary, not sufficient — and neither is being able to see each other,
-- since clause 3 lets an in-Journey pair see each other regardless.
CREATE OR REPLACE FUNCTION public.zyra_can_match(p_a uuid, p_b uuid)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  select exists (
    select 1
    from public.profiles a, public.profiles b
    where a.id = p_a
      and b.id = p_b
      and a.id <> b.id
      -- A Guardian is not a romantic candidate. Neither is an admin.
      and a.role = 'seeker'
      and b.role = 'seeker'
      -- OA-ZYRA-193(c), 2026-08-11. No question is optional, so a pair
      -- cannot become a match on half an answer sheet.
      and a.onboarding_complete
      and b.onboarding_complete
      -- The segregation rule. NOT NULL on the column, checked anyway
      -- because a future nullable column would otherwise open it silently.
      and a.gender is not null
      and b.gender is not null
      and a.gender <> b.gender
      and not exists (
        select 1 from public.profile_blocks x
        where (x.blocker_id = p_a and x.blocked_id = p_b)
           or (x.blocker_id = p_b and x.blocked_id = p_a)
      )
      -- TIER-0 — one of them guards the other.
      and not exists (
        select 1 from public.wali_links w
        where w.status = 'active'
          and (   (w.seeker_id = p_a and w.wali_id = p_b)
               or (w.seeker_id = p_b and w.wali_id = p_a) )
      )
      -- TIER-1 — they share a Guardian. Added 2026-08-08.
      and not exists (
        select 1
        from public.wali_links wa
        join public.wali_links wb on wb.wali_id = wa.wali_id
        where wa.seeker_id = p_a
          and wb.seeker_id = p_b
          and wa.status in ('active','removed')
          and wb.status in ('active','removed')
      )
  );
$function$;
-- END VERBATIM LIVE STATEMENT 20260811153643
