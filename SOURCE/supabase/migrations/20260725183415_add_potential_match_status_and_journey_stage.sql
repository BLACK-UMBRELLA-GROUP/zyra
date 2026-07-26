-- DR-ZYRA-101 audit finding: matches had no 'potential' status, so a
-- second mutual Like while the first match was still 'active' was
-- SILENTLY DROPPED by create_match_on_mutual_like (see that function's
-- own prior comment). This directly contradicted JOURNEY AVAILABILITY/
-- Summary.md's "Many Potential Journeys, One Active Journey" rule.
-- Fix: add 'potential' as the default status for new matches (never
-- dropped), add journey_stage to track Ritual progress once promoted
-- to 'active', and add an explicit promotion RPC that enforces the
-- one-Active-Journey rule at the correct point (promotion time, not
-- match-creation time).

-- 1. Widen the status check to include 'potential', and make it the default.
ALTER TABLE matches DROP CONSTRAINT matches_status_check;
ALTER TABLE matches ADD CONSTRAINT matches_status_check
  CHECK (status IN ('potential', 'active', 'paused', 'ended'));
ALTER TABLE matches ALTER COLUMN status SET DEFAULT 'potential';

-- 2. journey_stage — meaningful once status <> 'potential'. Null while
-- potential. Enum matches PRE-JOURNEY RITUAL/Summary.md's stage list.
ALTER TABLE matches ADD COLUMN journey_stage TEXT
  CHECK (journey_stage IN (
    'compatibility_reveal', 'salam_exchange', 'wali_gate',
    'phase_1', 'phase_2', 'phase_3', 'family_stage', 'conversation'
  ));

-- 3. Conversations should not be open until the Ritual reaches the
-- 'conversation' stage. New conversations now start 'closed'; the
-- promotion-to-conversation step (a later migration/RPC, once the
-- Ritual flow is built) will flip this to 'active'.
ALTER TABLE conversations ALTER COLUMN status SET DEFAULT 'closed';

-- 4. Fix the trigger: always create the match (as 'potential'), never
-- silently drop a mutual Like. The one-active-match rule is enforced
-- later, at promotion time, not here.
CREATE OR REPLACE FUNCTION public.create_match_on_mutual_like()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  reciprocal_exists BOOLEAN;
  a_id UUID;
  b_id UUID;
  new_match_id UUID;
  new_timeline_id UUID;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM likes WHERE liker_id = NEW.liked_id AND liked_id = NEW.liker_id
  ) INTO reciprocal_exists;

  IF NOT reciprocal_exists THEN
    RETURN NEW;
  END IF;

  IF NEW.liker_id < NEW.liked_id THEN
    a_id := NEW.liker_id; b_id := NEW.liked_id;
  ELSE
    a_id := NEW.liked_id; b_id := NEW.liker_id;
  END IF;

  -- Already matched as this exact pair (any status) — avoid a
  -- duplicate row if this fires again after an unlike/re-like cycle.
  IF EXISTS (SELECT 1 FROM matches WHERE seeker_a_id = a_id AND seeker_b_id = b_id) THEN
    RETURN NEW;
  END IF;

  -- 2026-07-25 fix (DR-ZYRA-101): always create the match as
  -- 'potential' — a mutual Like must never be silently dropped just
  -- because one party already has an Active Journey. Many Potential
  -- Journeys may coexist; only promotion to 'active' is limited to one.
  INSERT INTO matches (seeker_a_id, seeker_b_id, status) VALUES (a_id, b_id, 'potential') RETURNING id INTO new_match_id;
  INSERT INTO conversations (match_id) VALUES (new_match_id);
  INSERT INTO timelines (match_id) VALUES (new_match_id) RETURNING id INTO new_timeline_id;
  INSERT INTO timeline_milestones (timeline_id, milestone_type) VALUES (new_timeline_id, 'match_created');

  RETURN NEW;
END;
$function$;

-- 5. Promotion RPC: Potential Journey -> Active Journey. This is what
-- "Start Journey" now calls. Enforces one-Active-Journey-at-a-time
-- properly (at the moment it matters), using the existing partial
-- unique indexes as the hard backstop against races.
CREATE OR REPLACE FUNCTION public.promote_journey_to_active(p_match_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  m RECORD;
  caller UUID := auth.uid();
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'match not found';
  END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;
  IF m.status <> 'potential' THEN
    RAISE EXCEPTION 'match is not in potential state (status=%)', m.status;
  END IF;

  -- One-Active-Journey-at-a-time (JOURNEY AVAILABILITY/Summary.md
  -- CORE PRINCIPLE). Checked explicitly here for a clear error message;
  -- the partial unique indexes on matches(seeker_a_id)/matches(seeker_b_id)
  -- WHERE status='active' are the hard backstop against race conditions.
  IF EXISTS (
    SELECT 1 FROM matches
    WHERE status = 'active'
      AND (seeker_a_id IN (m.seeker_a_id, m.seeker_b_id) OR seeker_b_id IN (m.seeker_a_id, m.seeker_b_id))
  ) THEN
    RAISE EXCEPTION 'one_active_journey_limit' USING HINT = 'You already have an Active Journey. End or pause it before starting another.';
  END IF;

  UPDATE matches SET status = 'active', journey_stage = 'compatibility_reveal' WHERE id = p_match_id;
END;
$function$;
