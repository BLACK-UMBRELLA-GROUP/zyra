-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260811103056, applied name
-- 'rewind_keeps_journey_started_milestone') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- The keep-list was ('liked','match_created') and lost 'journey_started' on
-- every rewind — permanently, because the trigger only writes that one on a
-- status change INTO 'active', and a rewind of an already-active Journey is
-- not one. So the first reset silently deleted the moment the Journey began
-- and nothing would ever put it back.
--
-- A rewind is the same Journey wound back, not a different Journey. It began
-- when it began.
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

    DELETE FROM journey_family_review_responses
     WHERE review_id IN (SELECT id FROM journey_family_reviews WHERE match_id = v_id);
    GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
    DELETE FROM journey_family_reviews WHERE match_id = v_id; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

    SELECT id INTO v_conv FROM conversations WHERE match_id = v_id LIMIT 1;
    IF v_conv IS NOT NULL THEN
      DELETE FROM messages WHERE conversation_id = v_conv; GET DIAGNOSTICS n = ROW_COUNT; total := total + n;
      UPDATE conversations SET status = 'closed', closed_at = NULL WHERE id = v_conv;
    END IF;

    -- How you met, and that this Journey began, both survive. Everything the
    -- Journey itself recorded from Compatibility Reveal onwards goes.
    DELETE FROM timeline_milestones
     WHERE timeline_id IN (SELECT id FROM timelines WHERE match_id = v_id)
       AND milestone_type NOT IN ('liked', 'match_created', 'journey_started');
    GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

    DELETE FROM notifications WHERE related_match_id = v_id;
    GET DIAGNOSTICS n = ROW_COUNT; total := total + n;

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
