-- TWELFTH DEV-ONLY FUNCTION. Drop with the rest before public launch
-- (OA-ZYRA-184). @zyra.test accounts only, and only on a Journey you are in.
--
-- Founder, 2026-08-11: "the reset button in toggle doesn't reset the journey
-- stage.. say if i wanna start again."
--
-- It doesn't, and that was correct of it. Neither existing Reset was ever
-- going to do this:
--
--   Reset (beside SCENARIOS)  clears the panel's own toggles. Client-side
--                             only; it has never touched the server.
--   Reset this account (red)  clears Saves, Considers, Passes, unlocks and
--                             credits, and DELIBERATELY leaves matches alone
--                             — dev_scenario_panel.dart's own note says a
--                             reset that destroyed them "would make the
--                             button too dangerous to press".
--
-- So this is a third thing, named for what it does: rewind ONE Journey to its
-- first stage. The match survives, the attempt survives, the pair survives —
-- what goes is everything the two of them did inside it.
--
-- ⚠️ DESTRUCTIVE, AND NOT A PRODUCT FEATURE. Starting a Journey again for
-- real requires mutual consent and preserves all history (OA-ZYRA-154 /
-- OA-ZYRA-159 — restart_journey() raises rather than doing any of this, and
-- was stripped of its DELETEs on purpose so nobody could reinstate the defect
-- by accident). Nothing here may ever be reached from a member-facing screen.
CREATE OR REPLACE FUNCTION public.zyra_dev_rewind_journey(p_match_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  caller    UUID := (SELECT auth.uid());
  v_email   TEXT;
  m         RECORD;
  v_attempt UUID;
  v_conv    UUID;
  n         INT;
  total     INT := 0;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Rewinding a Journey is limited to seeded @zyra.test accounts.';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id
   ORDER BY (a.status = 'active') DESC, a.attempt_number DESC LIMIT 1;

  -- Scoped by match_id throughout, NOT by attempt. A rewind is "this pair
  -- starts over", and a row left behind from an earlier attempt would come
  -- back on the second walk-through as somebody else's answer.
  DELETE FROM journey_phase_ratings     WHERE match_id = p_match_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
  DELETE FROM journey_phase_answers     WHERE match_id = p_match_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
  DELETE FROM journey_phase_checkpoints WHERE match_id = p_match_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
  DELETE FROM journey_family_answers    WHERE match_id = p_match_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
  DELETE FROM journey_stage_checkpoints WHERE match_id = p_match_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
  DELETE FROM journey_salams            WHERE match_id = p_match_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
  DELETE FROM journey_compatibility     WHERE match_id = p_match_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
  DELETE FROM journey_requests          WHERE match_id = p_match_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

  -- Review responses first: journey_family_review_responses references the
  -- review, and there is no ON DELETE CASCADE on that side to rely on.
  DELETE FROM journey_family_review_responses
   WHERE review_id IN (SELECT id FROM journey_family_reviews WHERE match_id = p_match_id);
  GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
  DELETE FROM journey_family_reviews WHERE match_id = p_match_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

  -- The conversation ROW survives and goes back to 'closed'. Deleting it
  -- would put the Journey back in the state that made Open Conversation open
  -- onto nothing, which is the bug the last change fixed.
  SELECT id INTO v_conv FROM conversations WHERE match_id = p_match_id LIMIT 1;
  IF v_conv IS NOT NULL THEN
    DELETE FROM messages WHERE conversation_id = v_conv; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    UPDATE conversations SET status = 'closed', closed_at = NULL WHERE id = v_conv;
  END IF;

  DELETE FROM timeline_milestones
   WHERE timeline_id IN (SELECT id FROM timelines WHERE match_id = p_match_id);
  GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

  DELETE FROM notifications WHERE related_match_id = p_match_id;
  GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

  -- Back to the top, and un-paused / un-ended, because "start again" from a
  -- Journey you paused or ended should land you somewhere you can press
  -- things — not on the paused screen with an empty Journey behind it.
  UPDATE matches
     SET journey_stage = 'compatibility_reveal',
         status        = 'active',
         suspended_by  = NULL, suspended_at = NULL,
         ended_at      = NULL, ended_by     = NULL,
         end_reason    = NULL, end_note     = NULL
   WHERE id = p_match_id;

  IF v_attempt IS NOT NULL THEN
    UPDATE journey_attempts
       SET journey_stage = 'compatibility_reveal', status = 'active'
     WHERE id = v_attempt;
  END IF;

  RETURN format('Journey rewound to Compatibility Reveal. %s row(s) cleared.', total);
END;
$function$;

REVOKE ALL ON FUNCTION public.zyra_dev_rewind_journey(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.zyra_dev_rewind_journey(uuid) TO authenticated;

COMMENT ON FUNCTION public.zyra_dev_rewind_journey(uuid) IS
  'DEV ONLY (@zyra.test). Destructive: wipes one Journey''s answers, ratings, salams, reveals, reviews, messages and milestones and sets it back to stage one. Not a product feature — see restart_journey(). Drop before public launch — OA-ZYRA-184.';
