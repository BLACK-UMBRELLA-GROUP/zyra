-- OA-ZYRA-159 . Stage 4c -- Request New Journey. DR-ZYRA-121 item 8.
--
--   "One person requests; the other decides. Never unilateral, never a
--    resurrection -- a new attempt starts fresh with its own timeline."
--
-- This supersedes restart_journey(), which has refused since OA-ZYRA-154
-- because it reopened an ended Journey on one party's word and deleted six
-- tables of history first.
--
-- THE TWO GUESSES, in one place. DR-121 item 16 records the 6-month cooldown
-- and 14-day expiry as deliberately unanswered -- guesses to be revisited on
-- real usage, not design. They are named constants here so revisiting them is
-- one line, not a search for literals.

CREATE OR REPLACE FUNCTION public.request_new_journey(p_match_id UUID)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  k_expiry CONSTANT INTERVAL := INTERVAL '14 days';   -- DR-121 item 16, a guess
  k_cool   CONSTANT INTERVAL := INTERVAL '24 hours';  -- existing #17 cooling period
  caller UUID := (SELECT auth.uid());
  m      RECORD;
  other  UUID;
  v_id   UUID;
  v_name TEXT;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  -- Identity before existence, so an error never confirms a match the caller
  -- is not part of.
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;
  other := CASE WHEN caller = m.seeker_a_id THEN m.seeker_b_id ELSE m.seeker_a_id END;

  IF m.status <> 'ended' THEN
    RAISE EXCEPTION 'journey_not_ended'
      USING HINT = 'There is nothing to begin again -- this Journey has not ended.';
  END IF;

  IF m.ended_at IS NULL OR NOW() < m.ended_at + k_cool THEN
    RAISE EXCEPTION 'cooling_period_active'
      USING HINT = 'This Journey ended less than 24 hours ago.';
  END IF;

  -- THE ORDER OF THE NEXT THREE MATTERS, and it is the reverse of how they
  -- read. A hold is checked LAST of the three refusals that could reveal
  -- something: blocks and Tier-1 are conditions of the pair, but a hold is a
  -- record of a decision the other person made and did not want disclosed.
  IF zyra_block_exists(other) THEN
    RAISE EXCEPTION 'not_available';
  END IF;

  IF NOT zyra_can_match(caller, other) THEN
    RAISE EXCEPTION 'not_available';
  END IF;

  -- OA-ZYRA-159: "THE REQUESTER IS NEVER TOLD WHICH." A 6-month cooldown, a
  -- permanent "don't ask again" and a 14-day expiry all land here, and all
  -- raise the SAME error as a block and a Tier-1 exclusion. One error name
  -- for every refusal is what makes them indistinguishable -- the moment one
  -- of them gets its own message, the requester can tell them apart.
  IF zyra_hold_blocks(caller, other) THEN
    RAISE EXCEPTION 'not_available';
  END IF;

  -- Asking for something you could not accept wastes the other person's
  -- decision. Checked before the request exists, not at accept time.
  IF EXISTS (SELECT 1 FROM matches x WHERE x.status = 'active'
               AND (x.seeker_a_id = caller OR x.seeker_b_id = caller)) THEN
    RAISE EXCEPTION 'one_active_journey_limit'
      USING HINT = 'You already have an Active Journey. End or pause it first.';
  END IF;

  IF EXISTS (SELECT 1 FROM journey_requests r
              WHERE r.match_id = p_match_id AND r.status = 'pending') THEN
    RAISE EXCEPTION 'request_already_pending';
  END IF;

  INSERT INTO journey_requests (match_id, requested_by, requested_to, expires_at)
  VALUES (p_match_id, caller, other, NOW() + k_expiry)
  RETURNING id INTO v_id;

  SELECT first_name INTO v_name FROM profiles WHERE id = caller;
  PERFORM create_notification(
    other, 'journey_request', 'A new Journey',
    COALESCE(v_name,'Someone') || ' would like to begin a new Journey with you.',
    p_match_id);

  RETURN v_id;
END;
$function$;


CREATE OR REPLACE FUNCTION public.respond_to_journey_request(
  p_request_id UUID,
  p_decision   TEXT           -- 'accept' | 'decline' | 'decline_never'
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  k_cooldown CONSTANT INTERVAL := INTERVAL '6 months';  -- DR-121 item 16, a guess
  caller  UUID := (SELECT auth.uid());
  r       RECORD;
  m       RECORD;
  v_att   UUID;
  v_n     INT;
  v_name  TEXT;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  IF p_decision NOT IN ('accept','decline','decline_never') THEN
    RAISE EXCEPTION 'unknown_decision';
  END IF;

  SELECT * INTO r FROM journey_requests WHERE id = p_request_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'request_not_found'; END IF;
  IF r.requested_to <> caller THEN RAISE EXCEPTION 'not_yours_to_answer'; END IF;
  IF r.status <> 'pending' THEN RAISE EXCEPTION 'already_answered'; END IF;
  IF r.expires_at <= NOW() THEN RAISE EXCEPTION 'request_expired'; END IF;

  SELECT * INTO m FROM matches WHERE id = r.match_id FOR UPDATE;

  -- DECLINE. Both kinds write the SAME request row. The difference lives only
  -- in protection_holds, which the requester cannot read, so no future SELECT
  -- on this table can leak which one happened.
  IF p_decision IN ('decline','decline_never') THEN
    UPDATE journey_requests
       SET status = 'declined', responded_at = NOW()
     WHERE id = p_request_id;

    INSERT INTO protection_holds
      (match_id, restricted_id, protected_id, hold_type, appealable, expires_at)
    VALUES (
      r.match_id, r.requested_by, caller,
      CASE WHEN p_decision = 'decline_never' THEN 'decline_permanent' ELSE 'decline_cooldown' END,
      TRUE,
      CASE WHEN p_decision = 'decline_never' THEN NULL ELSE NOW() + k_cooldown END);

    -- OA-ZYRA-159: a decline DOES notify -- "hiding it behind the expiry would
    -- mean fourteen days of hope for something already answered." Identical
    -- wording for both kinds, and for an expiry sweep, by design.
    PERFORM create_notification(
      r.requested_by, 'journey_request_declined', 'Journey request',
      'Your request to begin a new Journey was not taken up.', r.match_id);

    RETURN 'declined';
  END IF;

  -- ACCEPT. Re-checked at accept time, not trusted from request time. Days may
  -- have passed; a block, a Guardian change or another Journey can have
  -- happened in between.
  IF zyra_block_exists(r.requested_by) THEN RAISE EXCEPTION 'not_available'; END IF;
  IF NOT zyra_can_match(caller, r.requested_by) THEN RAISE EXCEPTION 'not_available'; END IF;

  IF EXISTS (SELECT 1 FROM matches x WHERE x.status = 'active'
               AND (x.seeker_a_id IN (m.seeker_a_id, m.seeker_b_id)
                 OR x.seeker_b_id IN (m.seeker_a_id, m.seeker_b_id))) THEN
    RAISE EXCEPTION 'one_active_journey_limit'
      USING HINT = 'One of you already has an Active Journey.';
  END IF;

  -- A FRESH ATTEMPT. Nothing is deleted and ended_at is NOT cleared -- the
  -- prior ending stays on the record (DR-121 item 3). The old attempt row
  -- keeps its own ended_by / ended_at / end_reason, which is where the
  -- history actually lives now.
  SELECT COALESCE(MAX(attempt_number), 0) + 1 INTO v_n
    FROM journey_attempts WHERE match_id = r.match_id;

  INSERT INTO journey_attempts
    (match_id, attempt_number, status, journey_stage, started_at)
  VALUES (r.match_id, v_n, 'active', 'compatibility_reveal', NOW())
  RETURNING id INTO v_att;

  -- matches_end_fields_need_ended_status FORCES ended_by/end_reason/end_note
  -- to null once status leaves 'ended'. ended_at is not in that constraint,
  -- which is exactly why the preserved comment in restart_journey said to
  -- keep it: it is the one part of the ending the pair row can still carry.
  UPDATE matches
     SET status = 'active',
         journey_stage = 'compatibility_reveal',
         ended_by = NULL, end_reason = NULL, end_note = NULL,
         suspended_by = NULL, suspended_at = NULL
   WHERE id = r.match_id;

  -- Its own conversation and its own timeline -- possible only since stage 4a
  -- moved both tables from UNIQUE(match_id) to UNIQUE(attempt_id). The old
  -- attempt's messages stay with the old conversation, so a fresh start is
  -- genuinely fresh without erasing anything.
  INSERT INTO conversations (match_id, attempt_id, status)
  VALUES (r.match_id, v_att, 'active');

  INSERT INTO timelines (match_id, attempt_id) VALUES (r.match_id, v_att);

  UPDATE journey_requests
     SET status = 'accepted', responded_at = NOW(), attempt_id = v_att
   WHERE id = p_request_id;

  SELECT first_name INTO v_name FROM profiles WHERE id = caller;
  PERFORM create_notification(
    r.requested_by, 'journey_request_accepted', 'A new Journey',
    COALESCE(v_name,'They') || ' accepted. Your new Journey has begun.',
    r.match_id);

  RETURN 'accepted';
END;
$function$;


-- The question the Ended row asks before deciding whether to draw the button.
-- BOOLEAN ONLY. A caller learns whether they may ask, and nothing about why
-- not -- which is the whole of OA-ZYRA-159's asymmetry rule.
CREATE OR REPLACE FUNCTION public.zyra_may_request_new_journey(p_match_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  caller UUID := (SELECT auth.uid());
  m RECORD; other UUID;
BEGIN
  IF caller IS NULL THEN RETURN FALSE; END IF;
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RETURN FALSE; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN RETURN FALSE; END IF;
  other := CASE WHEN caller = m.seeker_a_id THEN m.seeker_b_id ELSE m.seeker_a_id END;

  IF m.status <> 'ended' THEN RETURN FALSE; END IF;
  IF m.ended_at IS NULL OR NOW() < m.ended_at + INTERVAL '24 hours' THEN RETURN FALSE; END IF;
  IF zyra_block_exists(other) THEN RETURN FALSE; END IF;
  IF NOT zyra_can_match(caller, other) THEN RETURN FALSE; END IF;
  IF zyra_hold_blocks(caller, other) THEN RETURN FALSE; END IF;
  IF EXISTS (SELECT 1 FROM matches x WHERE x.status='active'
               AND (x.seeker_a_id = caller OR x.seeker_b_id = caller)) THEN RETURN FALSE; END IF;
  IF EXISTS (SELECT 1 FROM journey_requests r
              WHERE r.match_id = p_match_id AND r.status='pending') THEN RETURN FALSE; END IF;
  RETURN TRUE;
END;
$function$;

REVOKE ALL ON FUNCTION public.request_new_journey(UUID) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.respond_to_journey_request(UUID, TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.zyra_may_request_new_journey(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.request_new_journey(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.respond_to_journey_request(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.zyra_may_request_new_journey(UUID) TO authenticated;
