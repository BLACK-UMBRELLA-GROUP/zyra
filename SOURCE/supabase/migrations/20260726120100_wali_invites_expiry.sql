-- wali_invites expiry (Founder-flagged gap, 2026-07-26 — see
-- ZYRA_FABLE_BUILD_REVIEW_2026-07-19_V1.md §Open Decisions item 6:
-- "wali_invites never expire").
--
-- 20260718193640_wali_invites_and_linking.sql created wali_invites
-- with no expiry concept at all — a generated 8-character code stays
--'pending' and acceptable forever unless manually revoked. This adds
-- a 7-day expiry window (matches the "share this code" flow's
-- implicit one-time, near-term use per link_wali_screen.dart's own
-- copy — nothing about the UX suggests a code should still work
-- months later), auto-expiry evaluated at accept time (no cron/pg_cron
-- dependency needed), and a status value so an attempted-but-expired
-- invite is distinguishable from a never-existed one.

ALTER TABLE wali_invites
  ADD COLUMN expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days');

ALTER TABLE wali_invites
  DROP CONSTRAINT wali_invites_status_check;
ALTER TABLE wali_invites
  ADD CONSTRAINT wali_invites_status_check
  CHECK (status IN ('pending', 'accepted', 'revoked', 'expired'));

-- Lazily flips a still-'pending' row to 'expired' once past expires_at.
-- Called at the two read/accept entry points below rather than via a
-- scheduled job — there's no pg_cron/Edge Function scheduler wired up
-- in this build, and correctness only matters at the moment someone
-- actually tries to use the code.
CREATE OR REPLACE FUNCTION public.expire_wali_invite_if_due(p_invite wali_invites)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_invite.status = 'pending' AND p_invite.expires_at < NOW() THEN
    UPDATE wali_invites SET status = 'expired' WHERE id = p_invite.id;
    RETURN 'expired';
  END IF;
  RETURN p_invite.status;
END;
$$;

CREATE OR REPLACE FUNCTION public.preview_wali_invite(p_token TEXT)
RETURNS TABLE(inviter_first_name TEXT, inviter_role TEXT, invite_status TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invite wali_invites%ROWTYPE;
  v_status TEXT;
BEGIN
  SELECT * INTO v_invite FROM wali_invites wi WHERE wi.token = p_token;
  IF NOT FOUND THEN
    RETURN;
  END IF;
  v_status := expire_wali_invite_if_due(v_invite);

  RETURN QUERY
  SELECT p.first_name, v_invite.inviter_role, v_status
  FROM profiles p
  WHERE p.id = v_invite.inviter_id;
END;
$$;

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
  v_seeker_id UUID;
  v_wali_id UUID;
  v_link_id UUID;
BEGIN
  IF v_accepter_id IS NULL THEN
    RAISE EXCEPTION 'Not signed in';
  END IF;

  SELECT * INTO v_invite FROM wali_invites WHERE token = p_token;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invite not found or already used';
  END IF;

  IF expire_wali_invite_if_due(v_invite) = 'expired' THEN
    RAISE EXCEPTION 'This invite code has expired. Ask them to generate a new one.';
  END IF;

  IF v_invite.status <> 'pending' THEN
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

  RETURN v_link_id;
END;
$$;

REVOKE ALL ON FUNCTION public.expire_wali_invite_if_due(wali_invites) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.preview_wali_invite(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.preview_wali_invite(TEXT) TO authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.accept_wali_invite(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.accept_wali_invite(TEXT) TO authenticated;
