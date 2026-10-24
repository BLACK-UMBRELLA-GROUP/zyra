-- ⟲ APPLIED-IN-REMOTE RECORD — 2026-08-12 stewardship pass.
--
-- This migration was applied straight to the live database via MCP on
-- 2026-08-11 and existed in no repo file. This record file preserves the
-- version slot and WHAT IT DID. On 2026-09-10, under the Founder's
-- OA-ZYRA-198 governed history-recovery authority, the one retained live
-- statement was restored below from
-- supabase_migrations.schema_migrations version 20260811152255.
-- House precedent for a record-not-body file: 20260811094513.
-- Live statement identity at recovery: 5,435 characters;
-- SHA-256 884de52af3e96ef92ce5427a9a8c69b7a0b4cb6257309e43f8a2140031cbc2ed.
-- The bytes between the BEGIN/END markers are exactly statements[1];
-- neither marker is part of the retained statement.
--
-- WHAT IT DID:
-- zyra_compatibility_for_plus() re-pointed at the caller's own per-person score column (overturns the documented shared-number position, recorded in-file); zyra_dev_set_compatibility() rewritten for the two-score shape, sets both sides + categories + revealed flags
-- BEGIN VERBATIM LIVE STATEMENT 20260811152255
-- The two functions that wrote the retired single overall_score.
--
-- ⚠️ THIS OVERTURNS A DOCUMENTED POSITION, so it is recorded rather than
-- quietly flipped. zyra_compatibility_for_plus carried this comment:
--
--   "Compute once, store on the SHARED row. Deliberate: the score is the
--    score... both people see the same number, which is the only
--    defensible outcome. A per-viewer score would mean the pair
--    disagreeing about their own compatibility."
--
-- That was a reasonable position and it is now superseded by OA-ZYRA-193
-- (a2), Founder 2026-08-11. What it missed is that the pair ALREADY
-- disagree — score_candidates asks each of them a different question, and
-- has since it was written. The single shared number did not create
-- agreement, it picked a winner and hid that it had: whoever revealed
-- second decided what both people saw.

CREATE OR REPLACE FUNCTION public.zyra_compatibility_for_plus(p_match_id uuid)
RETURNS numeric
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  caller  UUID := (SELECT auth.uid());
  m       RECORD;
  other   UUID;
  v_is_a  BOOLEAN;
  v_score NUMERIC;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;
  v_is_a := (caller = m.seeker_a_id);
  other  := CASE WHEN v_is_a THEN m.seeker_b_id ELSE m.seeker_a_id END;

  -- THE ENTITLEMENT, CHECKED SERVER-SIDE. Contradiction-audit §3.1 is a whole
  -- section on this project gating entitlements in Dart and believing it.
  IF NOT EXISTS (
    SELECT 1 FROM profile_unlocks u
     WHERE u.unlocker_id = caller
       AND u.unlocked_id = other
       AND u.unlock_type IN ('paid_plus_single','paid_plus_bundle')
  ) THEN
    RAISE EXCEPTION 'plus_required'
      USING HINT = 'Compatibility Unlock+ is needed to see this before they reveal.';
  END IF;

  INSERT INTO journey_compatibility (match_id) VALUES (p_match_id)
  ON CONFLICT (match_id) DO NOTHING;

  -- The caller's OWN column, computed from the caller's OWN preferences.
  -- Buying Unlock+ buys early sight of YOUR figure; it cannot buy theirs,
  -- which is a per-person fact about what they said they were looking for.
  IF v_is_a THEN
    SELECT seeker_a_score INTO v_score FROM journey_compatibility WHERE match_id = p_match_id;
  ELSE
    SELECT seeker_b_score INTO v_score FROM journey_compatibility WHERE match_id = p_match_id;
  END IF;

  IF v_score IS NULL THEN
    SELECT s.score INTO v_score FROM score_candidates(ARRAY[other]) s LIMIT 1;
    IF v_score IS NOT NULL THEN
      IF v_is_a THEN
        UPDATE journey_compatibility SET seeker_a_score = v_score WHERE match_id = p_match_id;
      ELSE
        UPDATE journey_compatibility SET seeker_b_score = v_score WHERE match_id = p_match_id;
      END IF;
    END IF;
  END IF;

  -- NOTE WHAT IS ABSENT. No reveal flag is set, no stage advances, no
  -- notification fires. The other Seeker's screen is unchanged and they are
  -- told nothing. That is the whole of "the result is bought, the
  -- relationship is not".
  RETURN v_score;
END;
$function$;

-- ── The dev override, on the new shape ─────────────────────────────────
CREATE OR REPLACE FUNCTION public.zyra_dev_set_compatibility(p_match_id uuid, p_score numeric)
RETURNS numeric
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  caller  UUID := (SELECT auth.uid());
  v_email TEXT;
  m       RECORD;
  v_cats  JSONB;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Forcing a compatibility score is limited to seeded @zyra.test accounts.';
  END IF;

  IF p_score < 0 OR p_score > 100 THEN
    RAISE EXCEPTION 'score_out_of_range' USING HINT = '0 to 100.';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;

  v_cats := jsonb_build_object(
    'Deen',                least(100, greatest(0, p_score + 7)),
    'Marriage Goals',      least(100, greatest(0, p_score + 3)),
    'Communication',       least(100, greatest(0, p_score - 4)),
    'Lifestyle',           least(100, greatest(0, p_score - 9)),
    'Family Expectations', least(100, greatest(0, p_score + 1))
  );

  INSERT INTO journey_compatibility (match_id) VALUES (p_match_id)
  ON CONFLICT (match_id) DO NOTHING;

  -- BOTH sides set to the same figure, deliberately. This is a dev fixture
  -- for looking at a screen, not a simulation of the engine — and setting
  -- only the caller's would leave the other account showing nothing when
  -- the Founder switches to it to check the other half.
  UPDATE journey_compatibility
     SET seeker_a_score      = p_score,
         seeker_b_score      = p_score,
         seeker_a_categories = v_cats,
         seeker_b_categories = v_cats,
         seeker_a_revealed   = TRUE,
         seeker_b_revealed   = TRUE,
         revealed_at         = now()
   WHERE match_id = p_match_id;

  RETURN p_score;
END;
$function$;
-- END VERBATIM LIVE STATEMENT 20260811152255
