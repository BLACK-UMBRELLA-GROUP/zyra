-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806103539, applied name
-- 'oa154_restart_journey_safety_fix') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- OA-ZYRA-154 — restart_journey() safety defect.
-- DR-ZYRA-121 item 1. Governing document: ZYRA_JOURNEY_LIFECYCLE_
-- CURRENT_VERSION_V3.md §0. Founder authorised 2026-08-06, first in
-- sequence, independent of the wider architecture.
--
-- ================= WHAT WAS WRONG, VERIFIED IN THE LIVE FUNCTION ==========
--
-- 1. UNILATERAL. It checked only that the caller was A party to the match.
--    It never asked the other person. Someone who ended a Journey because
--    they felt unsafe could be returned to an Active Journey with that
--    person, without consent.
--
-- 2. SIX DELETES. journey_compatibility, journey_salams,
--    journey_phase_answers, journey_phase_ratings, journey_phase_checkpoints
--    and journey_family_answers were all wiped BEFORE the Journey reopened —
--    destroying the record that would justify the ending.
--
-- 3. `ended_at = NULL`. Not named in V3, found while verifying. Worse than
--    the DELETEs in one respect: it erases the fact that the Journey ended
--    AT ALL. After a restart there is no evidence of a prior ending, so a
--    pattern of endings — the exact thing a Guardian or moderator would need
--    to see — becomes invisible.
--
-- 4. `UPDATE conversations SET status = 'closed', closed_at = NULL`.
--    Marks the conversation closed while clearing the timestamp recording
--    when it closed. Restarting should not close a conversation. 'active'
--    was plainly intended.
--
-- 5. ORPHANED FAMILY REVIEWS. Also not named in V3. It deleted
--    journey_family_answers but NOT journey_family_reviews, leaving a review
--    row whose answers no longer exist. Fixed automatically by removing the
--    deletes.
--
-- ================= WHY THIS REFUSES RATHER THAN ASKING ===================
--
-- V3 §16 item 1 says "mutual consent". V3 §9 and OA-ZYRA-159 specify what
-- that consent actually IS: Request New Journey, with Accept / Decline /
-- Decline-and-don't-ask-again, a 6-month cooldown, a 14-day expiry, and a
-- requester who is never told which kind of decline they received. That is
-- step 4 of the approved sequence; this is step 1.
--
-- Building an interim handshake here would mean writing a consent mechanism
-- with different semantics from the approved one, days before the approved
-- one replaces it. The Founder's standing instruction is that duplicate work
-- is to be avoided.
--
-- SO: no restart path exists until OA-159 supplies the real one.
--
-- The evidence that makes this safe rather than merely cheap:
--   matches                     0 rows
--   matches WHERE status='ended' 0 rows
-- Nobody can restart anything today, because nothing has ended. Removing
-- the path costs no user anything and closes the defect completely, now.
--
-- The function is kept (rather than dropped) so the Dart caller and its
-- error handling keep compiling, and so the reason is discoverable at the
-- point someone goes looking for it. OA-159 replaces the body.
--
-- REVERSIBLE IN ONE EDIT if the Founder would rather have an interim
-- handshake: the guarded restart logic is preserved verbatim below the
-- RAISE, commented, minus the destructive parts.

create or replace function public.restart_journey(p_match_id uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
DECLARE
  m RECORD;
  caller UUID := auth.uid();
BEGIN
  -- Identity checks still run first, so the error a caller receives never
  -- confirms the existence of a match they are not part of.
  IF caller IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'match not found';
  END IF;

  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;

  -- OA-ZYRA-154. A Journey may not be reopened by one person.
  RAISE EXCEPTION 'restart_requires_mutual_consent'
    USING HINT = 'Starting again needs both people to agree. This will be '
                 'available as Request New Journey.';

  -- ---------------------------------------------------------------------
  -- Preserved for OA-ZYRA-159, which will run this AFTER the other party
  -- accepts. Deliberately already stripped of every destructive statement,
  -- so nobody reinstating it can reinstate the defect by accident:
  --
  --   • no DELETEs — V3 item 13, all Journey history is preserved
  --   • ended_at is NOT cleared — the prior ending stays on the record
  --   • conversations goes to 'active', not 'closed'
  --
  -- IF m.status <> 'ended' THEN RAISE EXCEPTION 'match is not ended'; END IF;
  -- IF EXISTS (SELECT 1 FROM matches WHERE status = 'active' AND id <> p_match_id
  --            AND (seeker_a_id IN (m.seeker_a_id, m.seeker_b_id)
  --              OR seeker_b_id IN (m.seeker_a_id, m.seeker_b_id)))
  -- THEN RAISE EXCEPTION 'one_active_journey_limit'; END IF;
  --
  -- UPDATE matches SET status = 'active', journey_stage = 'compatibility_reveal'
  --  WHERE id = p_match_id;
  -- UPDATE conversations SET status = 'active', closed_at = NULL
  --  WHERE match_id = p_match_id;
  -- ---------------------------------------------------------------------
END;
$function$;

comment on function public.restart_journey(uuid) is
  'OA-ZYRA-154: refuses. A Journey cannot be reopened by one party. Replaced by Request New Journey (OA-ZYRA-159). Previously deleted six tables of history and cleared ended_at.';

revoke all on function public.restart_journey(uuid) from public, anon;
grant execute on function public.restart_journey(uuid) to authenticated;
