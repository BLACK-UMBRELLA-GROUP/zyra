-- DEV ONLY — stage jumper. Founder request 2026-08-10: "a new toggle when in
-- active journey which allows me to skip stages to test sections".
--
-- ⚠️ THIS FUNCTION SKIPS EVERY GATE IN THE PRODUCT. The Pre-Journey Ritual,
-- the Guardian Gate and the 48-hour Family Review Period are the three things
-- that make ZYRA a marriage process rather than a chat app. A caller of this
-- function walks past all of them. It exists so the Founder can reach a screen
-- without spending two days getting there, and for no other reason.
--
-- ⚠️ MUST BE DROPPED BEFORE PUBLIC LAUNCH. Add it to the same list as
-- mock_purchase_wali_premium() and mock_set_wali_plan() (engineering audit
-- item #20). A dev tool left in a shipped build is not a dev tool.
--
-- ⚠️ IT RESTS ON THE @zyra.test GUARD, WHICH IS OA-ZYRA-171 AND OPEN. That OA
-- records that the guard has never been confirmed against a real signup flow —
-- if a member could ever register an @zyra.test address, this function is
-- reachable by them. Adding a third consumer does not make the guard weaker,
-- but it does raise what it costs to be wrong. Do not close OA-171 without
-- re-reading this.
--
-- The guard is SERVER-SIDE and reads auth.users directly. Hiding the button in
-- Dart is not a control — contradiction-audit finding 3.1 is an entire section
-- about this project trusting client-side gates.

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
  IF caller IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

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

  -- Identity before existence, so the error never confirms a match the caller
  -- is not part of.
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;
  IF m.status <> 'active' THEN
    RAISE EXCEPTION 'journey_not_active'
      USING HINT = 'Only an Active Journey has stages to jump between.';
  END IF;

  -- BOTH tables, in step. matches is still authoritative until OA-ZYRA-156
  -- step 7, and journey_attempts mirrors it — zyra_end_match_internal
  -- maintains both and so must this. A jumper that moved one and not the
  -- other would leave the pair disagreeing about where they are, which is
  -- precisely the drift the canonical stage map (DR-ZYRA-129) exists to stop.
  UPDATE matches SET journey_stage = p_stage WHERE id = p_match_id;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status = 'active'
   ORDER BY a.attempt_number DESC LIMIT 1;

  IF v_attempt IS NOT NULL THEN
    UPDATE journey_attempts SET journey_stage = p_stage WHERE id = v_attempt;
  END IF;

  -- Landing on 'conversation' with no conversation row is a dead screen — the
  -- Dart pushes ChatScreen and finds nothing. In the real flow the conversation
  -- is created on the way in; a jump has no way in. Created here so every
  -- destination is actually usable, which is the entire point of the tool.
  INSERT INTO conversations (match_id, attempt_id, status)
  VALUES (p_match_id, v_attempt, 'active')
  ON CONFLICT (match_id) DO UPDATE SET status = 'active', closed_at = NULL;

  INSERT INTO timelines (match_id, attempt_id)
  VALUES (p_match_id, v_attempt)
  ON CONFLICT (match_id) DO NOTHING;

  RETURN p_stage;
END;
$function$;

REVOKE ALL ON FUNCTION public.zyra_dev_set_journey_stage(UUID, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.zyra_dev_set_journey_stage(UUID, TEXT) FROM anon;
GRANT EXECUTE ON FUNCTION public.zyra_dev_set_journey_stage(UUID, TEXT) TO authenticated;

COMMENT ON FUNCTION public.zyra_dev_set_journey_stage(UUID, TEXT) IS
  'DEV ONLY. Jumps an Active Journey to any stage, skipping the Pre-Journey '
  'Ritual, Guardian Gate and Family Review. Guarded server-side on @zyra.test '
  '(OA-ZYRA-171). DROP BEFORE PUBLIC LAUNCH — audit item #20.';
