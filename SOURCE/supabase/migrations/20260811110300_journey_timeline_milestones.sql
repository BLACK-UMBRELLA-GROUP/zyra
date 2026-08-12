-- THE TIMELINE LEARNS THE JOURNEY.
--
-- Founder, 2026-08-11: "lets start making the timeline... create fake
-- scenarios when they liked each other, when they matched and more when
-- journey started and make the timeline update for example when they revealed
-- compatibility etc and continue it as journey continues."
--
-- The Timeline screen has been real since 2026-07-18 and has had exactly ONE
-- thing to draw: 'match_created', written by create_match_on_mutual_like().
-- Eight Journey stages ran past it without leaving a mark, so a couple at
-- Open Conversation and a couple who had just matched had identical Timelines.
--
-- ── WHY A TRIGGER AND NOT A CALL AT EACH SITE.
--
-- journey_stage is moved from five different places today:
-- zyra_advance_stage(), resolve_family_review_if_due(), wali_review_decision(),
-- zyra_dev_set_journey_stage() and zyra_dev_counterpart_complete(). Adding an
-- insert to each is five chances to forget one, and the one you forget is
-- invisible — a Timeline quietly missing a step reads as "nothing happened",
-- not as a bug. The column is the fact; the milestone follows it.
--
-- ── NAMED FOR WHAT HAPPENED, NOT FOR THE STAGE ARRIVED AT.
--
-- The existing two are 'match_created' and 'conversation_started' — past-tense
-- events — so the new ones match. A milestone records the stage just
-- COMPLETED, which is why the map reads from OLD.journey_stage.
--
-- ⚠️ FILE CONTENT vs APPLIED CONTENT. The remote recorded this version with
-- the rewind function bundled in; it was corrected minutes later by
-- 20260811111500. Splitting it here so each file does one thing — replaying
-- this file and then that one produces exactly the live schema, which is what
-- a migration set is for. Nothing is lost: the intermediate rewind body never
-- left this session.

ALTER TABLE timeline_milestones DROP CONSTRAINT timeline_milestones_milestone_type_check;
ALTER TABLE timeline_milestones ADD CONSTRAINT timeline_milestones_milestone_type_check
  CHECK (milestone_type = ANY (ARRAY[
    -- before the Journey
    'liked'::text, 'match_created'::text, 'journey_started'::text,
    -- the eight stages, as they complete
    'compatibility_revealed'::text, 'salam_exchanged'::text, 'guardian_linked'::text,
    'phase_1_complete'::text, 'phase_2_complete'::text, 'phase_3_complete'::text,
    'family_stage'::text, 'conversation_started'::text,
    -- beyond, and the two endings
    'meeting'::text, 'nikah'::text, 'journey_ended'::text, 'journey_restarted'::text
  ]));

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
  -- THE CANONICAL ORDER, and the only copy of it in the database. Kept in one
  -- array so "did the Journey move forward" is a comparison rather than a
  -- second switch that could disagree with the first.
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

  -- A Journey beginning is its own milestone, and it is a status change
  -- rather than a stage change — the Pre-Journey Ritual is what turns a
  -- Potential Journey into an Active one.
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

    -- FORWARD ONLY. A dev rewind sets the stage back to the first one, and a
    -- rewind that wrote "compatibility revealed" on the way past would leave
    -- the Timeline claiming things happened in an order they did not.
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

      -- Arriving at the last stage is an event in its own right, on top of
      -- Family Compatibility having finished.
      IF NEW.journey_stage = 'conversation' AND NOT EXISTS (
        SELECT 1 FROM timeline_milestones
         WHERE timeline_id = v_timeline AND milestone_type = 'conversation_started') THEN
        INSERT INTO timeline_milestones (timeline_id, milestone_type)
        VALUES (v_timeline, 'conversation_started');
      END IF;
    END IF;
  END IF;

  -- Endings, which are not stage moves at all.
  IF NEW.status = 'ended' AND OLD.status IS DISTINCT FROM 'ended' THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type)
    VALUES (v_timeline, 'journey_ended');
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS matches_record_journey_milestone ON matches;
CREATE TRIGGER matches_record_journey_milestone
  AFTER UPDATE ON matches
  FOR EACH ROW
  EXECUTE FUNCTION zyra_record_journey_milestone();

COMMENT ON FUNCTION public.zyra_record_journey_milestone() IS
  'Writes a Timeline milestone whenever a match starts, advances a Journey stage forward, or ends. Forward-only, so a dev rewind leaves no trace. One place, because journey_stage is moved from five.';
