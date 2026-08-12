-- OA-ZYRA-159 . Stage 4a. The change that unblocks Request New Journey.
--
-- DR-ZYRA-121 item 2: "each attempt carries its own status, stage, timeline
-- and conversation." It could not, because conversations and timelines both
-- held UNIQUE (match_id) -- one per PAIR, forever. A second attempt had
-- nowhere to put its conversation.
--
-- Approved by the Founder on 2026-08-10 as part of the Journey Timeline
-- specification: "storing per Journey Attempt while presenting one
-- relationship story."
--
-- WHY THIS IS SAFE TODAY AND WOULD NOT BE IN A MONTH. Measured at the time:
-- conversations 0 rows, timelines 0 rows, messages 0, timeline_milestones 0.
-- Nothing to backfill and nothing to break. Every day of real usage adds rows
-- to a change whose cost right now is a constraint swap.
--
-- WHAT THIS DOES NOT DO: match_id stays on both tables. OA-ZYRA-156 step 7
-- drops it across thirteen tables and that is its job, not this one. This
-- moves the UNIQUENESS only -- the narrowest change that lets attempt #2 exist.
--
-- DEPENDENCY TRACE, run before writing this:
--   * create_match_on_mutual_like already supplies attempt_id on BOTH inserts
--     -- verified in its body, not assumed. No change needed.
--   * zyra_end_match_internal already reads conversations BY attempt_id.
--   * zyra_dev_set_journey_stage used ON CONFLICT (match_id) -- that conflict
--     target ceases to exist below, so it is rewritten in the same migration.
--     A migration that invalidates a function and leaves it is how you get a
--     defect nobody connects to the change that caused it.
--   * Four Dart call sites read these tables BY match_id with .limit(1).
--     Correct while one attempt exists, silently wrong once two do -- no
--     error, just the wrong conversation. Fixed in stage 4b, same sitting.
--   * MISSED ON THE FIRST PASS and found by the verification run: a BEFORE
--     INSERT trigger, zyra_set_attempt_from_match, fills attempt_id from
--     match_id when null. Layer 4 of the six-layer rule is triggers, and it
--     was read for matches and journey_attempts but not for the two tables
--     actually being changed. It turns out to help -- see the note at the
--     foot of this file.

-- conversations
ALTER TABLE public.conversations ALTER COLUMN attempt_id SET NOT NULL;
ALTER TABLE public.conversations DROP CONSTRAINT IF EXISTS conversations_match_id_key;
ALTER TABLE public.conversations ADD CONSTRAINT conversations_attempt_id_key UNIQUE (attempt_id);

COMMENT ON COLUMN public.conversations.attempt_id IS
  'OA-ZYRA-159 stage 4a. THE conversation belongs to an ATTEMPT, not a pair. '
  'A new attempt gets a new conversation, so a fresh start is genuinely fresh '
  'and the previous attempt''s messages stay with the previous attempt '
  '(messages hang off conversation_id). match_id remains until OA-ZYRA-156 '
  'step 7 -- do not read this table by it.';

-- timelines
ALTER TABLE public.timelines ALTER COLUMN attempt_id SET NOT NULL;
ALTER TABLE public.timelines DROP CONSTRAINT IF EXISTS timelines_match_id_key;
ALTER TABLE public.timelines ADD CONSTRAINT timelines_attempt_id_key UNIQUE (attempt_id);

COMMENT ON COLUMN public.timelines.attempt_id IS
  'OA-ZYRA-159 stage 4a, and the Journey Timeline specification V3 D2. One '
  'timeline per attempt; the SCREEN presents every attempt for a pair as '
  'chapters of one relationship. Storage per attempt, presentation per '
  'relationship -- that is what makes a restart fresh without erasing history.';

-- The function this migration would otherwise have broken.
CREATE OR REPLACE FUNCTION public.zyra_dev_set_journey_stage(
  p_match_id UUID,
  p_stage    TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  caller  UUID := (SELECT auth.uid());
  v_email TEXT;
  m       RECORD;
  v_attempt UUID;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Stage jumping is limited to seeded @zyra.test accounts.';
  END IF;

  IF p_stage NOT IN ('compatibility_reveal','salam_exchange','wali_gate',
                     'phase_1','phase_2','phase_3','family_stage','conversation') THEN
    RAISE EXCEPTION 'unknown_stage'
      USING HINT = 'Stage must be one of the eight in zyra_journey_stages.dart.';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;
  IF m.status <> 'active' THEN
    RAISE EXCEPTION 'journey_not_active'
      USING HINT = 'Only an Active Journey has stages to jump between.';
  END IF;

  UPDATE matches SET journey_stage = p_stage WHERE id = p_match_id;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status = 'active'
   ORDER BY a.attempt_number DESC LIMIT 1;

  IF v_attempt IS NULL THEN
    RAISE EXCEPTION 'no_active_attempt'
      USING HINT = 'The Journey is active but has no active attempt row.';
  END IF;

  UPDATE journey_attempts SET journey_stage = p_stage WHERE id = v_attempt;

  -- CHANGED IN STAGE 4a: conflict target is now attempt_id, and attempt_id is
  -- NOT NULL, so v_attempt is required rather than optional. Previously this
  -- inserted with a possibly-NULL attempt_id and conflicted on match_id --
  -- both of which stopped being legal in the statements above.
  INSERT INTO conversations (match_id, attempt_id, status)
  VALUES (p_match_id, v_attempt, 'active')
  ON CONFLICT (attempt_id) DO UPDATE SET status = 'active', closed_at = NULL;

  INSERT INTO timelines (match_id, attempt_id)
  VALUES (p_match_id, v_attempt)
  ON CONFLICT (attempt_id) DO NOTHING;

  RETURN p_stage;
END;
$function$;

-- THE TRIGGER NOTE, recorded because it is now load-bearing.
--
-- zyra_set_attempt_from_match (BEFORE INSERT on both tables) fills attempt_id
-- from match_id when null, resolving to the ACTIVE attempt else the newest.
-- With UNIQUE(attempt_id) in force this is a GOOD thing: a legacy caller that
-- inserts by match_id alone no longer attaches quietly to the wrong
-- conversation -- it collides with the existing row and THROWS. Verified as
-- check 6 of the stage-4a test run. Do not "fix" that trigger into something
-- forgiving; the loud failure is the feature.
