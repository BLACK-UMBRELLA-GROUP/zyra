-- REWIND, NOW ACCOUNT-WIDE AND TIMELINE-AWARE. Replaces the single-match
-- version added earlier the same day (20260811104500).
--
-- Founder, 2026-08-11: "the reset account isn't quite right, why cos when i
-- pressed reset it started with send salam not started with start journey
-- again... main thing is to fix reset toggle."
--
-- My first answer was to leave both Reset buttons alone and add a third
-- control inside the Journey. That was wrong, and this is the correction: he
-- pressed RESET, and a button called Reset that leaves you halfway through a
-- Journey has not reset anything he can see. The panel's Reset runs from
-- HomeShell with no Journey in front of it, so:
--
--   p_match_id is now OPTIONAL. NULL means every Journey this account is in.
--
-- The old objection — recorded in dev_scenario_panel.dart, that destroying
-- matches would make the button too dangerous to press — still stands and is
-- still respected. The match, the attempt, the Guardian link and how the two
-- of them met all survive. What goes is what they DID.
--
--   KEPT     'liked', 'match_created', 'journey_started'
--   CLEARED  every milestone the Journey itself wrote, and all of its
--            answers, ratings, Salams, reveals, reviews and messages
--
-- 'journey_started' is in the keep-list for a reason worth stating: the
-- trigger only writes it on a status change INTO 'active', and rewinding an
-- already-active Journey is not one. Leaving it out deleted the moment the
-- Journey began, permanently, on the first reset — with nothing that would
-- ever put it back. A rewind is the same Journey wound back, not a new one.
-- It began when it began.
--
-- ⚠️ DESTRUCTIVE, AND NOT A PRODUCT FEATURE. Starting a Journey again for
-- real requires mutual consent and preserves all history (OA-ZYRA-154 /
-- OA-ZYRA-159 — restart_journey() raises rather than doing any of this, and
-- was stripped of its DELETEs on purpose so nobody could reinstate the defect
-- by accident). Nothing here may ever be reached from a member-facing screen.
--
-- TWELFTH DEV-ONLY FUNCTION. Drop with the rest before public launch
-- (OA-ZYRA-184).
DROP FUNCTION IF EXISTS public.zyra_dev_rewind_journey(uuid);

CREATE OR REPLACE FUNCTION public.zyra_dev_rewind_journey(p_match_id uuid DEFAULT NULL)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  caller    UUID := (SELECT auth.uid());
  v_email   TEXT;
  v_ids     UUID[];
  v_id      UUID;
  v_conv    UUID;
  n         INT;
  total     INT := 0;
  journeys  INT := 0;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Rewinding a Journey is limited to seeded @zyra.test accounts.';
  END IF;

  IF p_match_id IS NULL THEN
    SELECT array_agg(id) INTO v_ids FROM matches
     WHERE seeker_a_id = caller OR seeker_b_id = caller;
  ELSE
    SELECT array_agg(id) INTO v_ids FROM matches
     WHERE id = p_match_id AND (seeker_a_id = caller OR seeker_b_id = caller);
    IF v_ids IS NULL THEN RAISE EXCEPTION 'not_a_party'; END IF;
  END IF;

  IF v_ids IS NULL THEN RETURN 'No Journeys on this account — nothing to rewind.'; END IF;

  FOREACH v_id IN ARRAY v_ids LOOP
    journeys := journeys + 1;

    DELETE FROM journey_phase_ratings     WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_phase_answers     WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_phase_checkpoints WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_family_answers    WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_stage_checkpoints WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_salams            WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_compatibility     WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_requests          WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

    -- Review responses first: journey_family_review_responses references the
    -- review, and there is no ON DELETE CASCADE on that side to rely on.
    DELETE FROM journey_family_review_responses
     WHERE review_id IN (SELECT id FROM journey_family_reviews WHERE match_id = v_id);
    GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_family_reviews WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

    -- The conversation ROW survives and goes back to 'closed'. Deleting it
    -- would put the Journey back in the state that made Open Conversation
    -- open onto nothing, which an earlier change today fixed.
    SELECT id INTO v_conv FROM conversations WHERE match_id = v_id LIMIT 1;
    IF v_conv IS NOT NULL THEN
      DELETE FROM messages WHERE conversation_id = v_conv; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
      UPDATE conversations SET status = 'closed', closed_at = NULL WHERE id = v_conv;
    END IF;

    DELETE FROM timeline_milestones
     WHERE timeline_id IN (SELECT id FROM timelines WHERE match_id = v_id)
       AND milestone_type NOT IN ('liked', 'match_created', 'journey_started');
    GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

    DELETE FROM notifications WHERE related_match_id = v_id;
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
     WHERE id = v_id;

    UPDATE journey_attempts
       SET journey_stage = 'compatibility_reveal', status = 'active'
     WHERE match_id = v_id;
  END LOOP;

  RETURN format('%s Journey(s) back at Compatibility Reveal. %s row(s) cleared.',
                journeys, total);
END;
$function$;

REVOKE ALL ON FUNCTION public.zyra_dev_rewind_journey(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.zyra_dev_rewind_journey(uuid) TO authenticated;

COMMENT ON FUNCTION public.zyra_dev_rewind_journey(uuid) IS
  'DEV ONLY (@zyra.test). Destructive: wipes a Journey back to stage one, keeping the match, the Guardian link and how you met. NULL match id rewinds every Journey on the account. Not a product feature — see restart_journey(). Drop before public launch — OA-ZYRA-184.';
