-- THE 'liked' MILESTONE GETS ITS WRITER — Founder approval 2026-08-12
-- ("do number 3" on the stewardship report's decision list).
--
-- The 20260811110300 CHECK constraint allowed 'liked' and the rewind
-- preserve-list expected it, but nothing wrote it — the one dead value
-- with Founder intent behind it ("create fake scenarios when they liked
-- each other, when they matched and more"). Now written at MATCH time,
-- dated at the FIRST like of the pair, so a Timeline reads
--   You liked each other   <first-like date>
--   Match                  <mutual date>
-- One-sided likes still leave no trace anywhere user-visible until they
-- become mutual — writing at match time is what makes that safe.

CREATE OR REPLACE FUNCTION public.create_match_on_mutual_like()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  reciprocal_exists BOOLEAN;
  a_id UUID; b_id UUID;
  new_match_id UUID; new_attempt_id UUID; new_timeline_id UUID;
  a_name TEXT; b_name TEXT;
  first_like TIMESTAMPTZ;
BEGIN
  SELECT EXISTS (SELECT 1 FROM likes WHERE liker_id = NEW.liked_id AND liked_id = NEW.liker_id)
    INTO reciprocal_exists;
  IF NOT reciprocal_exists THEN RETURN NEW; END IF;

  -- UNCHANGED (2026-08-07): mutual interest is necessary, not sufficient.
  IF NOT public.zyra_can_match(NEW.liker_id, NEW.liked_id) THEN RETURN NEW; END IF;

  IF NEW.liker_id < NEW.liked_id THEN a_id := NEW.liker_id; b_id := NEW.liked_id;
  ELSE                                a_id := NEW.liked_id; b_id := NEW.liker_id; END IF;

  IF EXISTS (SELECT 1 FROM matches WHERE seeker_a_id = a_id AND seeker_b_id = b_id) THEN
    RETURN NEW;
  END IF;

  INSERT INTO matches (seeker_a_id, seeker_b_id, status)
    VALUES (a_id, b_id, 'potential') RETURNING id INTO new_match_id;

  -- Created by matches_create_first_attempt (AFTER INSERT). Read it back
  -- rather than assuming the downstream BEFORE triggers will find it.
  SELECT a.id INTO new_attempt_id FROM journey_attempts a
   WHERE a.match_id = new_match_id ORDER BY a.attempt_number DESC LIMIT 1;
  IF new_attempt_id IS NULL THEN RAISE EXCEPTION 'no_attempt_created_for_match'; END IF;

  INSERT INTO conversations (match_id, attempt_id) VALUES (new_match_id, new_attempt_id);
  INSERT INTO timelines     (match_id, attempt_id) VALUES (new_match_id, new_attempt_id)
    RETURNING id INTO new_timeline_id;

  -- ADDED 2026-08-12: the origin of the story. The reciprocal like's
  -- created_at is by definition earlier than NEW's (it existed first).
  SELECT l.created_at INTO first_like FROM likes l
   WHERE l.liker_id = NEW.liked_id AND l.liked_id = NEW.liker_id
   ORDER BY l.created_at ASC LIMIT 1;
  INSERT INTO timeline_milestones (timeline_id, milestone_type, occurred_at)
    VALUES (new_timeline_id, 'liked', COALESCE(LEAST(first_like, NEW.created_at), NOW()));

  INSERT INTO timeline_milestones (timeline_id, milestone_type)
    VALUES (new_timeline_id, 'match_created');

  SELECT first_name INTO a_name FROM profiles WHERE id = a_id;
  SELECT first_name INTO b_name FROM profiles WHERE id = b_id;
  PERFORM create_notification(a_id,'new_match','New Match', COALESCE(b_name,'Someone')||' matched with you.', new_match_id);
  PERFORM create_notification(b_id,'new_match','New Match', COALESCE(a_name,'Someone')||' matched with you.', new_match_id);
  RETURN NEW;
END; $function$;

-- Backfill: existing timelines whose pair has like rows gain their origin,
-- dated correctly; guarded, idempotent, forward-only (no invented dates —
-- pairs seeded straight into matches without like rows get nothing).
INSERT INTO timeline_milestones (timeline_id, milestone_type, occurred_at)
SELECT t.id, 'liked',
       (SELECT MIN(l.created_at) FROM likes l
         WHERE (l.liker_id = m.seeker_a_id AND l.liked_id = m.seeker_b_id)
            OR (l.liker_id = m.seeker_b_id AND l.liked_id = m.seeker_a_id))
  FROM timelines t
  JOIN matches m ON m.id = t.match_id
 WHERE NOT EXISTS (SELECT 1 FROM timeline_milestones x
                    WHERE x.timeline_id = t.id AND x.milestone_type = 'liked')
   AND EXISTS (SELECT 1 FROM likes l
                WHERE (l.liker_id = m.seeker_a_id AND l.liked_id = m.seeker_b_id)
                   OR (l.liker_id = m.seeker_b_id AND l.liked_id = m.seeker_a_id));