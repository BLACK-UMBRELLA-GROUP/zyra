-- In-app notifications (#16, first half — Bell icon + feed). Push
-- (FCM/APNs) is deliberately out of scope here, tracked separately
-- (needs Firebase project + APNs key from the Founder before it can
-- be built) — see APP/Notifications/SUMMARY.md.
--
-- Three event types, matching the three preference toggles already
-- built in notification_settings_screen.dart/AppState
-- (notifyNewMatches/notifyNewMessages/notifyWaliRequests):
--   new_match     - a mutual Like creates a match (even a Potential one)
--   new_message   - a message arrives in a Journey's conversation
--   wali_request  - a Wali-link invite is accepted (either direction)
--
-- Journey-stage-advancement notifications are deliberately NOT
-- included — there's no existing preference toggle for that category,
-- and adding a 4th type/toggle is new scope beyond what Settings
-- already promised. Can be a follow-up.
--
-- Delivery model: every write path here is server-side (a SECURITY
-- DEFINER function or trigger already owned by these migrations), not
-- a direct client INSERT — so `notifications` has no INSERT policy
-- for `authenticated` at all. Client can only SELECT its own rows and
-- UPDATE read_at on its own rows.

CREATE TABLE notifications (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type              TEXT NOT NULL CHECK (type IN ('new_match', 'new_message', 'wali_request')),
  title             TEXT NOT NULL,
  body              TEXT,
  related_match_id  UUID REFERENCES matches(id) ON DELETE CASCADE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  read_at           TIMESTAMPTZ
);

CREATE INDEX notifications_user_created ON notifications(user_id, created_at DESC);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY notifications_select ON notifications FOR SELECT
  USING (user_id = auth.uid());

-- Only read_at is ever client-writable; enforced by WITH CHECK
-- requiring the row stay owned by the same user (there's nothing else
-- for a client to legitimately change here).
CREATE POLICY notifications_update ON notifications FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- No notifications_insert / notifications_delete policy: rows are
-- only ever created by the SECURITY DEFINER functions/triggers below.


-- ============================================================
-- Internal helper — not exposed to authenticated/anon directly.
-- ============================================================
CREATE OR REPLACE FUNCTION public.create_notification(
  p_user_id UUID,
  p_type TEXT,
  p_title TEXT,
  p_body TEXT,
  p_related_match_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO notifications (user_id, type, title, body, related_match_id)
  VALUES (p_user_id, p_type, p_title, p_body, p_related_match_id);
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_notification(UUID, TEXT, TEXT, TEXT, UUID) FROM PUBLIC;


-- ============================================================
-- new_match — extend the existing mutual-like trigger function.
-- ============================================================
CREATE OR REPLACE FUNCTION public.create_match_on_mutual_like()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  reciprocal_exists BOOLEAN;
  a_id UUID;
  b_id UUID;
  new_match_id UUID;
  new_timeline_id UUID;
  a_name TEXT;
  b_name TEXT;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM likes WHERE liker_id = NEW.liked_id AND liked_id = NEW.liker_id
  ) INTO reciprocal_exists;

  IF NOT reciprocal_exists THEN
    RETURN NEW;
  END IF;

  IF NEW.liker_id < NEW.liked_id THEN
    a_id := NEW.liker_id; b_id := NEW.liked_id;
  ELSE
    a_id := NEW.liked_id; b_id := NEW.liker_id;
  END IF;

  IF EXISTS (SELECT 1 FROM matches WHERE seeker_a_id = a_id AND seeker_b_id = b_id) THEN
    RETURN NEW;
  END IF;

  INSERT INTO matches (seeker_a_id, seeker_b_id, status) VALUES (a_id, b_id, 'potential') RETURNING id INTO new_match_id;
  INSERT INTO conversations (match_id) VALUES (new_match_id);
  INSERT INTO timelines (match_id) VALUES (new_match_id) RETURNING id INTO new_timeline_id;
  INSERT INTO timeline_milestones (timeline_id, milestone_type) VALUES (new_timeline_id, 'match_created');

  -- 2026-07-26 (#16): notify both parties of the new match.
  SELECT first_name INTO a_name FROM profiles WHERE id = a_id;
  SELECT first_name INTO b_name FROM profiles WHERE id = b_id;
  PERFORM create_notification(a_id, 'new_match', 'New Match', COALESCE(b_name, 'Someone') || ' matched with you.', new_match_id);
  PERFORM create_notification(b_id, 'new_match', 'New Match', COALESCE(a_name, 'Someone') || ' matched with you.', new_match_id);

  RETURN NEW;
END;
$function$;


-- ============================================================
-- new_message — genuine new trigger, messages has no wrapping
-- function today (client inserts directly under messages_insert).
-- ============================================================
CREATE OR REPLACE FUNCTION public.notify_new_message()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_match_id UUID;
  v_a UUID;
  v_b UUID;
  v_recipient UUID;
  v_sender_name TEXT;
BEGIN
  SELECT m.id, m.seeker_a_id, m.seeker_b_id INTO v_match_id, v_a, v_b
  FROM conversations c
  JOIN matches m ON m.id = c.match_id
  WHERE c.id = NEW.conversation_id;

  IF v_match_id IS NULL THEN
    RETURN NEW;
  END IF;

  v_recipient := CASE WHEN NEW.sender_id = v_a THEN v_b ELSE v_a END;
  SELECT first_name INTO v_sender_name FROM profiles WHERE id = NEW.sender_id;

  PERFORM create_notification(
    v_recipient, 'new_message', COALESCE(v_sender_name, 'New message'),
    left(NEW.content, 140), v_match_id
  );

  RETURN NEW;
END;
$$;

CREATE TRIGGER messages_notify_recipient
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION public.notify_new_message();


-- ============================================================
-- wali_request — extend accept_wali_invite to notify the inviter
-- once their invite is accepted.
-- ============================================================
CREATE OR REPLACE FUNCTION public.accept_wali_invite(p_token TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invite wali_invites%ROWTYPE;
  v_accepter_id UUID := auth.uid();
  v_accepter_role TEXT;
  v_accepter_name TEXT;
  v_seeker_id UUID;
  v_wali_id UUID;
  v_link_id UUID;
BEGIN
  IF v_accepter_id IS NULL THEN
    RAISE EXCEPTION 'Not signed in';
  END IF;

  SELECT * INTO v_invite FROM wali_invites WHERE token = p_token AND status = 'pending';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invite not found or already used';
  END IF;

  IF v_invite.inviter_id = v_accepter_id THEN
    RAISE EXCEPTION 'Cannot accept your own invite';
  END IF;

  SELECT role INTO v_accepter_role FROM profiles WHERE id = v_accepter_id;
  IF v_accepter_role IS NULL THEN
    RAISE EXCEPTION 'Complete your profile before accepting an invite';
  END IF;

  IF v_invite.inviter_role = 'seeker' THEN
    IF v_accepter_role <> 'wali' THEN
      RAISE EXCEPTION 'This invite is for a Wali account';
    END IF;
    v_seeker_id := v_invite.inviter_id;
    v_wali_id := v_accepter_id;
  ELSIF v_invite.inviter_role = 'wali' THEN
    IF v_accepter_role <> 'seeker' THEN
      RAISE EXCEPTION 'This invite is for a Seeker account';
    END IF;
    v_seeker_id := v_accepter_id;
    v_wali_id := v_invite.inviter_id;
  ELSE
    RAISE EXCEPTION 'Invalid invite';
  END IF;

  SELECT id INTO v_link_id FROM wali_links WHERE seeker_id = v_seeker_id AND wali_id = v_wali_id;
  IF v_link_id IS NULL THEN
    INSERT INTO wali_links (seeker_id, wali_id, status) VALUES (v_seeker_id, v_wali_id, 'active')
      RETURNING id INTO v_link_id;
  ELSE
    UPDATE wali_links SET status = 'active' WHERE id = v_link_id;
  END IF;

  UPDATE wali_invites SET status = 'accepted', accepted_at = NOW(), accepted_by = v_accepter_id WHERE id = v_invite.id;

  -- 2026-07-26 (#16): notify the inviter that their Wali-link invite
  -- was accepted. related_match_id left NULL — this isn't Journey-
  -- scoped.
  SELECT first_name INTO v_accepter_name FROM profiles WHERE id = v_accepter_id;
  PERFORM create_notification(
    v_invite.inviter_id, 'wali_request', 'Wali Link Accepted',
    COALESCE(v_accepter_name, 'Someone') || ' accepted your Wali link invite.', NULL
  );

  RETURN v_link_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION accept_wali_invite(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION accept_wali_invite(TEXT) TO authenticated;
