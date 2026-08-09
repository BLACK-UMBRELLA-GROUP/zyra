-- APPLIED LIVE 2026-08-08, version 20260808135907.
-- OA-ZYRA-156 stage 4e · STEP 3 — the three trigger functions.
-- Authorised by DR-ZYRA-122. No rule changes; only the key changes.
--
-- create_match_on_mutual_like also stops RELYING ON TRIGGER ORDERING: it
-- inserted conversations and timelines with match_id alone and left
-- zyra_set_attempt_from_match() to fill attempt_id, which works only
-- because matches_create_first_attempt is AFTER INSERT and lands before
-- the next statement. True today; the kind of assumption that breaks
-- silently when someone reorders a function. Now explicit.

create or replace function public.create_match_on_mutual_like()
 returns trigger language plpgsql security definer set search_path to 'public'
as $function$
DECLARE
  reciprocal_exists BOOLEAN; a_id UUID; b_id UUID;
  new_match_id UUID; new_attempt_id UUID; new_timeline_id UUID;
  a_name TEXT; b_name TEXT;
BEGIN
  SELECT EXISTS (SELECT 1 FROM likes WHERE liker_id = NEW.liked_id AND liked_id = NEW.liker_id)
    INTO reciprocal_exists;
  IF NOT reciprocal_exists THEN RETURN NEW; END IF;
  IF NOT public.zyra_can_match(NEW.liker_id, NEW.liked_id) THEN RETURN NEW; END IF;
  IF NEW.liker_id < NEW.liked_id THEN a_id := NEW.liker_id; b_id := NEW.liked_id;
  ELSE                                a_id := NEW.liked_id; b_id := NEW.liker_id; END IF;
  IF EXISTS (SELECT 1 FROM matches WHERE seeker_a_id = a_id AND seeker_b_id = b_id) THEN
    RETURN NEW; END IF;

  INSERT INTO matches (seeker_a_id, seeker_b_id, status)
    VALUES (a_id, b_id, 'potential') RETURNING id INTO new_match_id;
  SELECT a.id INTO new_attempt_id FROM journey_attempts a
   WHERE a.match_id = new_match_id ORDER BY a.attempt_number DESC LIMIT 1;
  IF new_attempt_id IS NULL THEN RAISE EXCEPTION 'no_attempt_created_for_match'; END IF;

  INSERT INTO conversations (match_id, attempt_id) VALUES (new_match_id, new_attempt_id);
  INSERT INTO timelines     (match_id, attempt_id) VALUES (new_match_id, new_attempt_id)
    RETURNING id INTO new_timeline_id;
  INSERT INTO timeline_milestones (timeline_id, milestone_type)
    VALUES (new_timeline_id, 'match_created');

  SELECT first_name INTO a_name FROM profiles WHERE id = a_id;
  SELECT first_name INTO b_name FROM profiles WHERE id = b_id;
  PERFORM create_notification(a_id,'new_match','New Match', COALESCE(b_name,'Someone')||' matched with you.', new_match_id);
  PERFORM create_notification(b_id,'new_match','New Match', COALESCE(a_name,'Someone')||' matched with you.', new_match_id);
  RETURN NEW;
END; $function$;

create or replace function public.create_conversation_started_milestone()
 returns trigger language plpgsql security definer set search_path to 'public'
as $function$
DECLARE v_timeline_id UUID; v_already_exists BOOLEAN;
BEGIN
  SELECT t.id INTO v_timeline_id FROM conversations c
   JOIN timelines t ON t.attempt_id = c.attempt_id
   WHERE c.id = NEW.conversation_id;
  IF v_timeline_id IS NULL THEN RETURN NEW; END IF;
  SELECT EXISTS (SELECT 1 FROM timeline_milestones
    WHERE timeline_id = v_timeline_id AND milestone_type = 'conversation_started')
    INTO v_already_exists;
  IF NOT v_already_exists THEN
    INSERT INTO timeline_milestones (timeline_id, milestone_type)
      VALUES (v_timeline_id, 'conversation_started');
  END IF;
  RETURN NEW;
END; $function$;

-- notifications.related_match_id keeps taking the match id — renaming
-- that column is step 7's, and changing what a notification points at is
-- not a key change.
create or replace function public.notify_new_message()
 returns trigger language plpgsql security definer set search_path to 'public'
as $function$
DECLARE v_match_id UUID; v_a UUID; v_b UUID; v_recipient UUID; v_sender_name TEXT;
BEGIN
  SELECT m.id, m.seeker_a_id, m.seeker_b_id INTO v_match_id, v_a, v_b
  FROM conversations c
  JOIN journey_attempts ja ON ja.id = c.attempt_id
  JOIN matches m          ON m.id  = ja.match_id
  WHERE c.id = NEW.conversation_id;
  IF v_match_id IS NULL THEN RETURN NEW; END IF;
  v_recipient := CASE WHEN NEW.sender_id = v_a THEN v_b ELSE v_a END;
  SELECT first_name INTO v_sender_name FROM profiles WHERE id = NEW.sender_id;
  PERFORM create_notification(v_recipient,'new_message', COALESCE(v_sender_name,'New message'),
                              left(NEW.content,140), v_match_id);
  RETURN NEW;
END; $function$;

-- VERIFIED 2026-08-08, 12/12, exercising the REAL path (two mutual likes):
-- one-sided like creates nothing; mutual like creates match + attempt;
-- conversation and timeline both carry attempt_id explicitly;
-- match_created milestone written; both parties notified; a message
-- writes conversation_started via the attempt join; the recipient is
-- notified and the sender is not; a second message does not duplicate
-- the milestone.
