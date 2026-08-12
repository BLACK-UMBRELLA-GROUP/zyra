-- FIX: DUPLICATE journey_ended TIMELINE MILESTONES — 2026-08-12 stewardship
-- pass (applied live 2026-08-11 23:37 UTC via MCP; file written back the
-- same night).
--
-- Since 20260811110300, ending a Journey wrote TWO 'journey_ended' rows:
-- zyra_end_match_internal() UPDATEs matches.status (firing the new
-- matches_record_journey_milestone trigger, which inserts one) and then
-- inserts its own, unguarded. The trigger's ending branch was also the only
-- insert in that function without a NOT EXISTS guard — its three siblings
-- all have one. Verified live: one timeline already held journey_ended x2.
-- Verified after: duplicate groups = 0.
--
-- NOT EXISTS guards on BOTH writers (idempotent whichever fires first, and
-- resilient if either is ever disabled), plus a one-time dedupe keeping the
-- earliest row per timeline.

CREATE OR REPLACE FUNCTION public.zyra_record_journey_milestone()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_timeline UUID;
  v_attempt  UUID;
  v_type     TEXT;
  v_old_ord  INT;
  v_new_ord  INT;
  v_order    TEXT[] := ARRAY['compatibility_reveal','salam_exchange','wali_gate',
                             'phase_1','phase_2','phase_3','family_stage','conversation'];
BEGIN
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = NEW.id
   ORDER BY (a.status = 'active') DESC, a.attempt_number DESC LIMIT 1;
  IF v_attempt IS NULL THEN RETURN NEW; END IF;

  INSERT INTO timelines (match_id, attempt_id) VALUES (NEW.id, v_attempt)
  ON CONFLICT (attempt_id) DO NOTHING;
  SELECT id INTO v_timeline FROM timelines WHERE attempt_id = v_attempt;
  IF v_timeline IS NULL THEN RETURN NEW; END IF;

  IF NEW.status = 'active' AND OLD.status IS DISTINCT FROM 'active' THEN
    IF NOT EXISTS (SELECT 1 FROM timeline_milestones
                    WHERE timeline_id = v_timeline AND milestone_type = 'journey_started') THEN
      INSERT INTO timeline_milestones (timeline_id, milestone_type)
      VALUES (v_timeline, 'journey_started');
    END IF;
  END IF;

  IF NEW.journey_stage IS DISTINCT FROM OLD.journey_stage
     AND OLD.journey_stage IS NOT NULL THEN

    v_old_ord := array_position(v_order, OLD.journey_stage);
    v_new_ord := array_position(v_order, NEW.journey_stage);

    IF v_old_ord IS NOT NULL AND v_new_ord IS NOT NULL AND v_new_ord > v_old_ord THEN

      v_type := CASE OLD.journey_stage
                  WHEN 'compatibility_reveal' THEN 'compatibility_revealed'
                  WHEN 'salam_exchange'       THEN 'salam_exchanged'
                  WHEN 'wali_gate'            THEN 'guardian_linked'
                  WHEN 'phase_1'              THEN 'phase_1_complete'
                  WHEN 'phase_2'              THEN 'phase_2_complete'
                  WHEN 'phase_3'              THEN 'phase_3_complete'
                  WHEN 'family_stage'         THEN 'family_stage'
                END;

      IF v_type IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM timeline_milestones
         WHERE timeline_id = v_timeline AND milestone_type = v_type) THEN
        INSERT INTO timeline_milestones (timeline_id, milestone_type) VALUES (v_timeline, v_type);
      END IF;

      IF NEW.journey_stage = 'conversation' AND NOT EXISTS (
        SELECT 1 FROM timeline_milestones
         WHERE timeline_id = v_timeline AND milestone_type = 'conversation_started') THEN
        INSERT INTO timeline_milestones (timeline_id, milestone_type)
        VALUES (v_timeline, 'conversation_started');
      END IF;
    END IF;
  END IF;

  -- Endings — NOW GUARDED (2026-08-12): zyra_end_match_internal writes the
  -- same milestone after this trigger has fired.
  IF NEW.status = 'ended' AND OLD.status IS DISTINCT FROM 'ended' THEN
    IF NOT EXISTS (SELECT 1 FROM timeline_milestones
                    WHERE timeline_id = v_timeline AND milestone_type = 'journey_ended') THEN
      INSERT INTO timeline_milestones (timeline_id, milestone_type)
      VALUES (v_timeline, 'journey_ended');
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.zyra_end_match_internal(p_match_id uuid, p_ended_by uuid, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE m RECORD; v_attempt UUID; v_timeline_id UUID; v_other UUID; v_ender_name TEXT;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND OR m.status = 'ended' THEN RETURN; END IF;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status <> 'ended'
   ORDER BY a.attempt_number DESC LIMIT 1;

  UPDATE matches
     SET status='ended', ended_at=NOW(), ended_by=p_ended_by,
         end_reason=p_reason, suspended_by=NULL, suspended_at=NULL
   WHERE id = p_match_id;

  UPDATE journey_attempts
     SET status='ended', ended_at=NOW(), ended_by=p_ended_by,
         end_reason=p_reason, paused_by=NULL, paused_at=NULL
   WHERE match_id = p_match_id AND status <> 'ended';

  -- Re-pointed onto the attempt.
  UPDATE conversations SET status='closed', closed_at=NOW()
   WHERE (v_attempt IS NOT NULL AND attempt_id = v_attempt) AND status <> 'closed';

  SELECT id INTO v_timeline_id FROM timelines
   WHERE (v_attempt IS NOT NULL AND attempt_id = v_attempt);
  -- GUARDED 2026-08-12: the matches UPDATE above fires
  -- matches_record_journey_milestone, which usually writes this milestone
  -- first. Both writers now check, so exactly one row lands either way.
  IF v_timeline_id IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM timeline_milestones
       WHERE timeline_id = v_timeline_id AND milestone_type = 'journey_ended') THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type)
    VALUES (v_timeline_id, 'journey_ended');
  END IF;

  -- UNCHANGED — OPTION B. The person who ended it is not told; they know.
  -- SEEKERS ONLY: the body carries the counterpart's name, and after
  -- Step 1 a Guardian may not be entitled to it. Notifying them would
  -- push a name through a channel the visibility rules do not govern.
  IF p_ended_by IS NOT NULL THEN
    v_other := CASE WHEN m.seeker_a_id = p_ended_by THEN m.seeker_b_id ELSE m.seeker_a_id END;
    SELECT first_name INTO v_ender_name FROM profiles WHERE id = p_ended_by;
    PERFORM create_notification(
      v_other, 'journey_ended', 'Journey ended',
      'Your Journey with ' || COALESCE(v_ender_name,'someone') || ' has ended.',
      p_match_id);
  END IF;
END; $function$;

-- One-time dedupe: keep the earliest journey_ended per timeline.
DELETE FROM timeline_milestones a
 USING timeline_milestones b
 WHERE a.milestone_type = 'journey_ended'
   AND b.milestone_type = 'journey_ended'
   AND a.timeline_id = b.timeline_id
   AND (b.occurred_at < a.occurred_at
        OR (b.occurred_at = a.occurred_at AND b.id < a.id));
