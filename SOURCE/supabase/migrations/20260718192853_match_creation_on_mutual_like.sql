-- Match creation — fills the gap flagged in the original schema
-- migration's comments: `matches` deliberately has no client-facing
-- INSERT policy ("Application service role only" per ZYRA_DATABASE_
-- SCHEMA_CURRENT_VERSION_V1.md §5), so something server-side has to
-- create matches. Implemented as a SECURITY DEFINER trigger on
-- `likes` rather than an RPC the app must remember to call — this
-- way a match is created the instant a mutual Like exists regardless
-- of which of the two Likes lands second, with no app-side race
-- condition to get wrong.
--
-- Also auto-creates the conversation + timeline + first milestone for
-- the new match, per schema doc: "One conversation per match,
-- auto-created on match creation" / "One timeline per match,
-- auto-created on match creation".

CREATE OR REPLACE FUNCTION create_match_on_mutual_like()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  reciprocal_exists BOOLEAN;
  a_id UUID;
  b_id UUID;
  new_match_id UUID;
  new_timeline_id UUID;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM likes WHERE liker_id = NEW.liked_id AND liked_id = NEW.liker_id
  ) INTO reciprocal_exists;

  IF NOT reciprocal_exists THEN
    RETURN NEW;
  END IF;

  -- Ordered pair per matches.CHECK (seeker_a_id < seeker_b_id).
  IF NEW.liker_id < NEW.liked_id THEN
    a_id := NEW.liker_id; b_id := NEW.liked_id;
  ELSE
    a_id := NEW.liked_id; b_id := NEW.liker_id;
  END IF;

  -- Schema enforces one ACTIVE match per seeker via partial unique
  -- indexes. If either party already has one, skip silently rather
  -- than raising — a Like must never fail just because a match can't
  -- be created right now. (Not retried automatically; a known v1
  -- limitation — one-active-match-per-Seeker means a second mutual
  -- Like simply doesn't become a Journey while the first is active.)
  IF EXISTS (
    SELECT 1 FROM matches
    WHERE status = 'active'
      AND (seeker_a_id IN (a_id, b_id) OR seeker_b_id IN (a_id, b_id))
  ) THEN
    RETURN NEW;
  END IF;

  -- Already matched as this exact pair (any status) — avoid a
  -- duplicate row if this fires again after an unlike/re-like cycle.
  IF EXISTS (SELECT 1 FROM matches WHERE seeker_a_id = a_id AND seeker_b_id = b_id) THEN
    RETURN NEW;
  END IF;

  INSERT INTO matches (seeker_a_id, seeker_b_id) VALUES (a_id, b_id) RETURNING id INTO new_match_id;
  INSERT INTO conversations (match_id) VALUES (new_match_id);
  INSERT INTO timelines (match_id) VALUES (new_match_id) RETURNING id INTO new_timeline_id;
  INSERT INTO timeline_milestones (timeline_id, milestone_type) VALUES (new_timeline_id, 'match_created');

  RETURN NEW;
END;
$$;

CREATE TRIGGER likes_create_match
  AFTER INSERT ON likes
  FOR EACH ROW EXECUTE FUNCTION create_match_on_mutual_like();
