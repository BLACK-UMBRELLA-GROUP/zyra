-- DR-ZYRA-135, Founder-approved 2026-08-10. Closes OA-ZYRA-152, open since
-- 2026-08-01 and marked "not to be built until resolved".
--
-- THE CONFLICT IT RECORDED WAS REAL. The Compatibility Reveal is built as a
-- consent gate -- "neither of you sees the result until you both choose to
-- reveal" -- and Profile Unlock+ sells that same number to one person. Both
-- could not be true. The Founder chose the purchase over the symmetry.
--
-- THE READING THAT MAKES IT COHERENT, and the line this function must not
-- cross: THE RESULT IS BOUGHT, THE RELATIONSHIP IS NOT. Unlock+ buys sight of
-- a number. It does not advance the Journey, does not tell the other person
-- anything, and does not skip a stage. The other Seeker's reveal is still
-- required for the pair to move on -- which is why this function returns a
-- score and touches NOTHING else. Asserted as checks 4-6 of the DR-135 run.
--
-- IT DOES NOT BREACH THE SCORING-ENGINE HOLD. Scoring work is paused pending
-- the onboarding redesign, because that would change the shape of
-- ch4_preferences which score_candidates() reads. This CALLS score_candidates
-- unchanged; it does not alter it. Calling a frozen function is not changing
-- it.
--
-- A CONSEQUENCE THE FOUNDER SHOULD KNOW IS LIVE, recorded in DR-135 item 3:
-- the purchase becomes visible to the other party by inference. If one Seeker
-- continues instantly on reaching Compatibility Reveal, the other may
-- reasonably conclude they had already seen the number. Not a leak in the
-- data -- a leak in the behaviour, and no code fixes it.

CREATE OR REPLACE FUNCTION public.zyra_compatibility_for_plus(p_match_id UUID)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  caller UUID := (SELECT auth.uid());
  m      RECORD;
  other  UUID;
  v_score NUMERIC;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;
  other := CASE WHEN caller = m.seeker_a_id THEN m.seeker_b_id ELSE m.seeker_a_id END;

  -- THE ENTITLEMENT, CHECKED SERVER-SIDE. Contradiction-audit 3.1 is a whole
  -- section on this project gating entitlements in Dart and believing it.
  -- 'paid_plus_single' and 'paid_plus_bundle' are the two Plus rows;
  -- 'paid_single' and 'paid_bundle' are the cheaper unlock and do NOT buy
  -- early sight.
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

  SELECT overall_score INTO v_score FROM journey_compatibility WHERE match_id = p_match_id;

  -- Compute once, store on the SHARED row. Deliberate: the score is the
  -- score. When the other Seeker later reveals, revealCompatibility's guard
  -- is `overall_score IS NULL`, so it finds this value and does not
  -- recompute -- both people see the same number, which is the only
  -- defensible outcome. A per-viewer score would mean the pair disagreeing
  -- about their own compatibility.
  IF v_score IS NULL THEN
    SELECT s.score INTO v_score FROM score_candidates(ARRAY[other]) s LIMIT 1;
    IF v_score IS NOT NULL THEN
      UPDATE journey_compatibility SET overall_score = v_score WHERE match_id = p_match_id;
    END IF;
  END IF;

  -- NOTE WHAT IS ABSENT. No reveal flag is set, no stage advances, no
  -- notification fires. The other Seeker's screen is unchanged and they are
  -- told nothing. That is the whole of "the result is bought, the
  -- relationship is not".
  RETURN v_score;
END;
$function$;

REVOKE ALL ON FUNCTION public.zyra_compatibility_for_plus(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.zyra_compatibility_for_plus(UUID) TO authenticated;


-- DEV ONLY -- grant or remove a Plus unlock, so the state above can be tested.
-- NINTH function on the @zyra.test guard. OA-ZYRA-184 lists them all.
CREATE OR REPLACE FUNCTION public.zyra_dev_set_plus_unlock(
  p_other_id UUID,
  p_has      BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  caller  UUID := (SELECT auth.uid());
  v_email TEXT;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Plus simulation is limited to seeded @zyra.test accounts.';
  END IF;
  IF p_other_id = caller THEN RAISE EXCEPTION 'not_a_party'; END IF;

  IF p_has THEN
    INSERT INTO profile_unlocks (unlocker_id, unlocked_id, unlock_type)
    VALUES (caller, p_other_id, 'paid_plus_single')
    ON CONFLICT DO NOTHING;
  ELSE
    -- Removes ONLY the simulated Plus row, never a real purchase of another
    -- type. A dev tool that deleted a paid_single would be destroying a
    -- record of money.
    DELETE FROM profile_unlocks
     WHERE unlocker_id = caller AND unlocked_id = p_other_id
       AND unlock_type = 'paid_plus_single';
  END IF;
  RETURN p_has;
END;
$function$;

REVOKE ALL ON FUNCTION public.zyra_dev_set_plus_unlock(UUID, BOOLEAN) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.zyra_dev_set_plus_unlock(UUID, BOOLEAN) TO authenticated;

COMMENT ON FUNCTION public.zyra_dev_set_plus_unlock(UUID, BOOLEAN) IS
  'DEV ONLY. Simulates a Compatibility Unlock+ purchase. Guarded server-side '
  'on @zyra.test. DROP BEFORE PUBLIC LAUNCH -- OA-ZYRA-184, now NINE functions.';
