-- #17 — 24-hour cooling period + Restart, per APP/Journey/JOURNEY
-- AVAILABILITY/Summary.md "ENDED JOURNEY — RULES":
--   "24-hour cooling period begins (no actions possible)."
--   "After 24 hours, journey officially disconnects."
--   "Either party may choose to Restart."
--   "RESTART: full fresh start from the beginning. Process begins
--    again from Compatibility Reveal... Old timeline remains visible
--    as historical record."
--
-- Note: this builds the "ended WITHOUT a block" path only. "Ended
-- WITH a block" (both parties disappear entirely, no restart, match
-- removed) is NOT built here — there is no blocking mechanism
-- anywhere in this schema yet (no blocks table, no block flag). That
-- is a separate, larger gap, out of scope for this task.
--
-- Design decision made without a separate question, since the spec
-- text is unambiguous: "Restart = full fresh start from the
-- beginning" is a reset of the RITUAL (Compatibility Reveal / Salam /
-- Phase 1-3 / Family Stage answers), not of the TIMELINE (which the
-- same section explicitly says stays visible as historical record).
-- So restart_journey clears the match-scoped ritual-progress tables
-- (journey_compatibility, journey_salams, journey_phase_answers,
-- journey_phase_ratings, journey_phase_checkpoints,
-- journey_family_answers) but leaves timeline_milestones alone.

-- 1. Track when a Journey's 24h cooling period is up. ended_at already
-- exists on matches; the cooling period is just ended_at + 24h,
-- computed at check-time rather than stored redundantly.

-- 2. Widen the Timeline Milestones vocabulary — "Journey Ended" and
-- "Journey Restarted" weren't tracked events at all before this.
ALTER TABLE timeline_milestones DROP CONSTRAINT timeline_milestones_milestone_type_check;
ALTER TABLE timeline_milestones ADD CONSTRAINT timeline_milestones_milestone_type_check
  CHECK (milestone_type IN (
    'match_created',
    'conversation_started',
    'family_stage',
    'meeting',
    'nikah',
    'journey_ended',
    'journey_restarted'
  ));

-- 3. end_journey now also records a Timeline milestone.
CREATE OR REPLACE FUNCTION public.end_journey(p_match_id UUID)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  m RECORD;
  caller UUID := auth.uid();
  v_timeline_id UUID;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;
  IF m.status = 'ended' THEN RAISE EXCEPTION 'already ended'; END IF;

  UPDATE matches SET status = 'ended', ended_at = NOW(), suspended_by = NULL, suspended_at = NULL WHERE id = p_match_id;
  UPDATE conversations SET status = 'closed', closed_at = NOW() WHERE match_id = p_match_id;

  SELECT id INTO v_timeline_id FROM timelines WHERE match_id = p_match_id;
  IF v_timeline_id IS NOT NULL THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type) VALUES (v_timeline_id, 'journey_ended');
  END IF;
END;
$function$;

-- 4. Restart — only reachable once the 24h cooling period has
-- elapsed. Full fresh start of the ritual; Timeline history preserved.
CREATE OR REPLACE FUNCTION public.restart_journey(p_match_id UUID)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  m RECORD;
  caller UUID := auth.uid();
  v_timeline_id UUID;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;
  IF m.status <> 'ended' THEN
    RAISE EXCEPTION 'match is not ended';
  END IF;
  IF m.ended_at IS NULL OR NOW() < m.ended_at + INTERVAL '24 hours' THEN
    RAISE EXCEPTION 'cooling_period_active' USING HINT = 'This Journey ended less than 24 hours ago — Restart is not available yet.';
  END IF;

  -- One-Active-Journey-at-a-time still applies to a Restart.
  IF EXISTS (
    SELECT 1 FROM matches
    WHERE status = 'active' AND id <> p_match_id
      AND (seeker_a_id IN (m.seeker_a_id, m.seeker_b_id) OR seeker_b_id IN (m.seeker_a_id, m.seeker_b_id))
  ) THEN
    RAISE EXCEPTION 'one_active_journey_limit' USING HINT = 'You already have an Active Journey. End or pause it before restarting this one.';
  END IF;

  -- Full fresh start of the ritual (spec: "Process begins again from
  -- Compatibility Reveal") — clear match-scoped ritual-progress rows.
  -- Timeline milestones are deliberately NOT touched (spec: "Old
  -- timeline remains visible as historical record").
  DELETE FROM journey_compatibility WHERE match_id = p_match_id;
  DELETE FROM journey_salams WHERE match_id = p_match_id;
  DELETE FROM journey_phase_answers WHERE match_id = p_match_id;
  DELETE FROM journey_phase_ratings WHERE match_id = p_match_id;
  DELETE FROM journey_phase_checkpoints WHERE match_id = p_match_id;
  DELETE FROM journey_family_answers WHERE match_id = p_match_id;

  UPDATE matches SET status = 'active', journey_stage = 'compatibility_reveal', ended_at = NULL WHERE id = p_match_id;
  UPDATE conversations SET status = 'closed', closed_at = NULL WHERE match_id = p_match_id;

  SELECT id INTO v_timeline_id FROM timelines WHERE match_id = p_match_id;
  IF v_timeline_id IS NOT NULL THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type) VALUES (v_timeline_id, 'journey_restarted');
  END IF;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.restart_journey(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.restart_journey(UUID) TO authenticated;
