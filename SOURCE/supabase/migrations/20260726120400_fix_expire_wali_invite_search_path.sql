-- Reconciliation note (2026-07-26): this migration was applied live to
-- Supabase via the management API before this local file was created —
-- written here afterward so the checked-in migrations folder matches
-- the live database. No functional change from what's live; this file
-- is the record of it.
--
-- Fixes the function_search_path_mutable lint: expire_wali_invite_if_due
-- was missing SET search_path = public.

CREATE OR REPLACE FUNCTION public.expire_wali_invite_if_due(p_invite wali_invites)
RETURNS TEXT
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF p_invite.status = 'pending' AND p_invite.expires_at < NOW() THEN
    UPDATE wali_invites SET status = 'expired' WHERE id = p_invite.id;
    RETURN 'expired';
  END IF;
  RETURN p_invite.status;
END;
$$;
