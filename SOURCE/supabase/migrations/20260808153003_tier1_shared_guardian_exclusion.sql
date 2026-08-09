-- APPLIED LIVE 2026-08-08, version 20260808153003.
-- TIER-1 · two Seekers who share a Guardian may not match.
-- Founder-approved 2026-08-08, universally, with the institutional
-- exception deliberately deferred until a real user hits it.
--
-- THE DEFECT THIS CLOSES, measured before the change:
--   zyra_can_match(brother, sister), their father guarding both,
--   returned TRUE. A mutual Like would have created a real Journey
--   between siblings.
--
-- Tier-1's ONLY job is opposite-gender co-wards. Same-gender co-wards are
-- already refused by segregation; a Guardian and their own ward by
-- Tier-0. So in practice this rule is "siblings", and its most likely
-- instance is a father with a son and a daughter both using ZYRA.
--
-- WHY UNIVERSAL RATHER THAN FAMILY-ONLY: the sympathetic institutional
-- case — someone guarding women with no male relatives — has all-female
-- wards, so opposite-gender pairs never arise and this costs them
-- nothing. Measured on the seed set: 0 Guardians hold wards of both
-- genders, so Tier-1 blocks 0 of 5,184 opposite-gender pairs today. The
-- only genuine false positive is a mixed-gender community organisation,
-- hypothetical at zero real users and arguably several Guardians rather
-- than one. An exception is easy to add later; siblings matching in the
-- meantime is not undoable.
--
-- ONE CHOICE MADE INSIDE THE APPROVAL, FLAGGED FOR REVIEW:
-- "shared Guardian" counts links that are 'active' OR 'removed', not
-- active alone. Active-only would be I1-vulnerable — two siblings who
-- each moved to a different Guardian would become matchable, and the
-- anchor would be a row the user can retire, which is exactly the "can
-- the user clear the thing this depends on?" failure. It also matches
-- zyra_can_guardian_link(), which counts a `matches` row of ANY status
-- for the mirror-image reason. 'pending' is excluded: an invitation never
-- accepted is not a bond.
--   COST: two people who each briefly linked the same community Guardian
--   and removed them stay permanently unmatchable, silently. Narrow it to
--   active-only on request.

create or replace function public.zyra_can_match(p_a uuid, p_b uuid)
 returns boolean language sql stable security definer set search_path to 'public'
as $function$
  select exists (
    select 1
    from public.profiles a, public.profiles b
    where a.id = p_a and b.id = p_b and a.id <> b.id
      -- A Guardian is not a romantic candidate. Neither is an admin.
      and a.role = 'seeker' and b.role = 'seeker'
      -- The segregation rule. NOT NULL on the column, checked anyway
      -- because a future nullable column would otherwise open it silently.
      and a.gender is not null and b.gender is not null
      and a.gender <> b.gender
      and not exists (
        select 1 from public.profile_blocks x
        where (x.blocker_id = p_a and x.blocked_id = p_b)
           or (x.blocker_id = p_b and x.blocked_id = p_a))
      -- TIER-0 — one of them guards the other.
      and not exists (
        select 1 from public.wali_links w
        where w.status = 'active'
          and (   (w.seeker_id = p_a and w.wali_id = p_b)
               or (w.seeker_id = p_b and w.wali_id = p_a)))
      -- TIER-1 — they share a Guardian. Added 2026-08-08.
      and not exists (
        select 1
        from public.wali_links wa
        join public.wali_links wb on wb.wali_id = wa.wali_id
        where wa.seeker_id = p_a and wb.seeker_id = p_b
          and wa.status in ('active','removed')
          and wb.status in ('active','removed'))
  );
$function$;

comment on function public.zyra_can_match(uuid, uuid) is
  'Romantic eligibility. Tier-0: neither guards the other. Tier-1 (added '
  '2026-08-08): they do not share a Guardian — in practice, siblings, '
  'since same-gender co-wards are already refused by segregation. Keyed '
  'on links active OR removed, so the rule cannot be cleared by retiring '
  'a Guardian (I1). Enforced in the RLS WITH CHECK on likes/saves/passes '
  'and re-checked by promote and resume, per GUARDIAN & ROMANTIC RULES '
  'sections 5 and 6.';

-- VERIFIED 2026-08-08:
--   siblings sharing a Guardian cannot match, both directions .. refused
--   retiring the shared Guardian does NOT unlock them (I1) ...... refused
--   a pending, never-accepted invite does not block ............. allowed
--   independent pair with no shared Guardian .................... allowed
--   Guardian and own ward (Tier-0) .............................. refused
--   the RLS WITH CHECK refuses the Like itself, not just the predicate
--   blast radius on the seed set: 0 of 5,184 opposite-gender pairs
