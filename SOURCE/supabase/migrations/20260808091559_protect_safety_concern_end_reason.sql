-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260808091559, applied name
-- 'protect_safety_concern_end_reason') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- STEP 0: make safety_concern unreachable before the feature that writes it
-- exists. Founder approved 2026-08-08.
--
-- ── THE RULE, already in governance and already unenforced.
-- zyra_data_ownership on matches.end_reason:
--   "per-value. joint for the five stated reasons. safety_concern is
--    row-scoped(ended_by) and MUST NEVER reach the other party by export
--    or any indirect route."
--
-- matches_select returns the whole row, so end_reason reached the other
-- Seeker AND both families' Guardians, with ended_by naming who raised it.
-- Proven by test, rolled back.
--
-- ── NOBODY IS EXPOSED TODAY, and that is the point of doing it now.
-- end_journey() writes status and ended_at only. No function in the schema
-- writes end_reason, ended_by or end_note — the ending-reason feature is
-- designed and unbuilt. The value used in the test was inserted by hand.
--
-- So this is not an incident fix. It is hardening the foundation before the
-- feature lands on it, which is also why it is free: no reader, no writer,
-- nothing to break. All 13 references to these names in lib/ are to
-- `suspended_by`, a different column.
--
-- A useful side effect: whoever builds the write path will hit "cannot read
-- end_reason" and have to come and find out why. The revoke is the forcing
-- function.
--
-- ── WHY RLS CANNOT DO THIS. The register describes PER-VALUE ownership —
-- one column, joint for five values and private for a sixth. A policy
-- decides whether you get a row, not which values within it. Column grants
-- plus an accessor are the only way to express it, and profiles.date_of_birth
-- already set that precedent.

-- ── 1. Column grants ──────────────────────────────────────────────────
--
-- REVOKING A COLUMN IS NOT ENOUGH ON ITS OWN. A table-level SELECT grant
-- covers every column, and `REVOKE SELECT (col)` does not carve a hole in
-- it. The table grant has to go first, then the permitted columns are
-- granted back — which is exactly the shape `profiles` is already in.
revoke select on public.matches from anon, authenticated;

grant select (
  id, seeker_a_id, seeker_b_id, status, ended_at, created_at,
  journey_stage, suspended_by, suspended_at,
  -- ended_by STAYS READABLE, deliberately. The register calls it joint:
  -- "who ended it is knowable to both". Knowing WHO without knowing WHY is
  -- precisely what prefer_not_to_say already means, so leaving it visible
  -- is part of what makes the substitution believable rather than a second
  -- side channel.
  ended_by
) on public.matches to authenticated;

comment on column public.matches.end_reason is
  'OWNERSHIP: per-value. Joint for the five stated reasons (V3 §8 — a '
  'stated reason is kinder than silence). safety_concern is '
  'row-scoped(ended_by) and MUST NEVER reach the other party or either '
  'family. NOT CLIENT-READABLE since 2026-08-08: RLS decides rows, not '
  'values, so the rule cannot be a policy. Read via zyra_match_ending(), '
  'which substitutes prefer_not_to_say for anyone not entitled. '
  'DO NOT RE-GRANT.';

comment on column public.matches.end_note is
  'OWNERSHIP: joint — written TO the other person. Revoked alongside '
  'end_reason 2026-08-08: a note being present or absent is itself a '
  'signal about the reason, so it has to travel through the same accessor.';

-- ── 2. The accessor ───────────────────────────────────────────────────
--
-- Written now, before the write path exists, so the feature cannot be
-- built around it.
--
-- STRICT — Founder decision 2026-08-08: "A safety concern belongs to the
-- person who raised it unless they explicitly choose to share it. Being
-- someone's Main Guardian should not automatically grant access to
-- sensitive disclosures made by that person."
--
-- So NO Guardian sees safety_concern, including the reporter's own Main
-- Guardian. There are real situations where someone trusts ZYRA with this
-- and is not ready to tell their family. If a Guardian should know later,
-- that must be the reporter choosing to involve them — never the system
-- assuming.
--
-- Narrowest position, and the easy direction to widen from.

create or replace function public.zyra_match_ending(p_match_id uuid)
 returns table(ended_by uuid, end_reason text, end_note text, ended_at timestamptz)
 language sql
 stable
 security definer
 set search_path to 'public'
as $function$
  select
    m.ended_by,
    case
      -- Only the person who raised it sees what they raised.
      when m.ended_by = (select auth.uid()) then m.end_reason
      -- Everyone else: the five joint reasons pass through untouched;
      -- safety_concern becomes a reason that already exists, is already
      -- common, and carries no signal.
      when m.end_reason = 'safety_concern' then 'prefer_not_to_say'
      else m.end_reason
    end,
    case
      when m.ended_by = (select auth.uid()) then m.end_note
      when m.end_reason = 'safety_concern' then null
      else m.end_note
    end,
    m.ended_at
  from public.matches m
  where m.id = p_match_id
    -- MIRRORS matches_select EXACTLY, so the accessor can never be more
    -- permissive than the row policy. Written out rather than delegating to
    -- zyra_can_view_attempt(), which takes an ATTEMPT id — passing a match
    -- id to it would have silently returned false for everyone.
    and (
      m.seeker_a_id = (select auth.uid())
      or m.seeker_b_id = (select auth.uid())
      or (m.status <> 'potential' and exists (
            select 1 from public.wali_links wl
            where wl.wali_id = (select auth.uid())
              and wl.status = 'active'
              and wl.seeker_id = any (array[m.seeker_a_id, m.seeker_b_id])
         ))
    );
$function$;

comment on function public.zyra_match_ending(uuid) is
  'THE only route to how a Journey ended. Substitutes prefer_not_to_say for '
  'safety_concern for everyone except the person who raised it — including '
  'their own Guardian (Founder, strict, 2026-08-08). '
  'GOVERNANCE RULE FOR CALLERS: prefer_not_to_say must render identically '
  'whether genuine or substituted. One string, one layout, one behaviour. '
  'A different tone, an extra sentence or a separate code path would make '
  'the rendering the disclosure.';

revoke execute on function public.zyra_match_ending(uuid) from public, anon;
grant  execute on function public.zyra_match_ending(uuid) to authenticated;
