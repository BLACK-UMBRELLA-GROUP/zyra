-- Wali account linking (Paths 1/2/3, WALI_ARCHITECTURE_CURRENT_
-- VERSION_V5.md). Not in ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md
-- — that doc only defines wali_links (the resulting relationship),
-- never the linking MECHANISM. V5 specifies "Internal invitation
-- token (generated per invite)" as the linking method but doesn't
-- define its schema. This is a genuine gap, filled here.
--
-- Deliberately scoped to LINKING only, not the Extended Wali
-- capability/entitlement resolution engine (Primary Wali, capability
-- grants from Path A/B) — that's a separate, larger piece of
-- unbuilt architecture with no schema representation anywhere yet
-- (subscriptions.plan_type has no per-relationship entitlement
-- concept). Also no SMS/email delivery — no such backend exists:
-- an invite is a shareable 8-character code, copy/share manually.
--
-- Symmetric design: either a Seeker or a Wali can generate an
-- invite (inviter_role records which), and the other party accepts
-- it via the same function regardless of direction — this covers
-- Path 1/2 (Seeker invites) and Path 3 (Wali invites) with one
-- mechanism instead of two.
--
-- [AMENDED 2026-07-19 by 20260719080735_security_hardening_wali_and_
-- invites.sql: token default switched to gen_random_bytes; anon
-- EXECUTE revoked on both functions.]

CREATE TABLE wali_invites (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  token         TEXT NOT NULL UNIQUE DEFAULT upper(substr(md5(random()::text || clock_timestamp()::text), 1, 8)),
  inviter_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  inviter_role  TEXT NOT NULL CHECK (inviter_role IN ('seeker', 'wali')),
  status        TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'revoked')),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  accepted_at   TIMESTAMPTZ,
  accepted_by   UUID REFERENCES profiles(id)
);

ALTER TABLE wali_invites ENABLE ROW LEVEL SECURITY;

-- Inviter can see/manage their own invites (show pending state, allow
-- revoke later). Not broadly readable — acceptance/preview go through
-- the SECURITY DEFINER functions below instead, so an invitee never
-- needs direct table access before they're party to the invite.
CREATE POLICY wali_invites_select ON wali_invites
  FOR SELECT USING (inviter_id = (select auth.uid()));

CREATE POLICY wali_invites_insert ON wali_invites
  FOR INSERT WITH CHECK (inviter_id = (select auth.uid()));

CREATE POLICY wali_invites_update ON wali_invites
  FOR UPDATE USING (inviter_id = (select auth.uid()));

-- Lets an invitee see who invited them and for what role before
-- accepting, without needing a direct SELECT grant on wali_invites.
CREATE OR REPLACE FUNCTION preview_wali_invite(p_token TEXT)
RETURNS TABLE(inviter_first_name TEXT, inviter_role TEXT, invite_status TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT p.first_name, wi.inviter_role, wi.status
  FROM wali_invites wi
  JOIN profiles p ON p.id = wi.inviter_id
  WHERE wi.token = p_token;
END;
$$;

REVOKE EXECUTE ON FUNCTION preview_wali_invite(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION preview_wali_invite(TEXT) TO authenticated, anon;

-- Accepts an invite and creates (or reactivates) the wali_links row.
-- Runs as SECURITY DEFINER because the accepting user is, by
-- definition, not the inviter — wali_links_insert's direct
-- WITH CHECK (seeker_id = auth.uid()) can't cover a Wali-initiated
-- invite (Path 3) where the Seeker didn't create the invite row.
-- This function is the sole path for a Wali-initiated link to be
-- created, rather than loosening wali_links_insert's client policy.
CREATE OR REPLACE FUNCTION accept_wali_invite(p_token TEXT)
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

  RETURN v_link_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION accept_wali_invite(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION accept_wali_invite(TEXT) TO authenticated;
