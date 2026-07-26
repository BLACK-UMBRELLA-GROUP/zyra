-- Progresses the Timeline beyond its permanent 'match_created' state.
-- match creation already auto-creates a timeline + 'match_created'
-- milestone (see match_creation_on_mutual_like.sql); this adds the
-- next naturally-detectable milestone — the first real message sent
-- in a match's conversation — using the same SECURITY DEFINER
-- trigger pattern.
--
-- Deliberately NOT built here: 'family_stage', 'meeting', 'nikah'
-- milestones. Those are real-world events a Seeker/Wali would need
-- to actively mark (there's no automatic signal for them in the
-- data), which is really the "Family Review Period" workflow —
-- unbuilt product surface, out of scope for this pass.

CREATE OR REPLACE FUNCTION create_conversation_started_milestone()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_timeline_id UUID;
  v_already_exists BOOLEAN;
BEGIN
  SELECT t.id INTO v_timeline_id
  FROM conversations c
  JOIN timelines t ON t.match_id = c.match_id
  WHERE c.id = NEW.conversation_id;

  IF v_timeline_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM timeline_milestones WHERE timeline_id = v_timeline_id AND milestone_type = 'conversation_started'
  ) INTO v_already_exists;

  IF NOT v_already_exists THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type) VALUES (v_timeline_id, 'conversation_started');
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER messages_create_conversation_started_milestone
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION create_conversation_started_milestone();

REVOKE EXECUTE ON FUNCTION create_conversation_started_milestone() FROM PUBLIC;
