-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806152928, applied name
-- 'guardian_relationship_accept_wali_invite') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Guardian Relationship, step 2a: accept_wali_invite writes the relationship.
--
-- DROP then CREATE, not CREATE OR REPLACE: adding a parameter makes a new
-- function rather than replacing the old one, and leaving both in place makes
-- accept_wali_invite('token') ambiguous at call time.
--
-- DROP also discards the function's grants. The prior ACL was
-- {authenticated, service_role} with no PUBLIC and no anon, and is restored
-- explicitly at the bottom. Revoking from PUBLIC and anon separately because
-- they are independent grants — revoking one has never removed the other.

drop function if exists public.accept_wali_invite(text);

create function public.accept_wali_invite(
  p_token text,
  p_relationship text default null
)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
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

  -- Fail loudly on an unknown code rather than letting the CHECK constraint
  -- surface as a raw violation. Null stays allowed: the Seeker-accepting
  -- direction has no relationship to state about themselves.
  IF p_relationship IS NOT NULL
     AND p_relationship NOT IN ('father','brother','grandfather','uncle',
                                'legal_guardian','family_representative','other') THEN
    RAISE EXCEPTION 'Unknown relationship: %', p_relationship;
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
    INSERT INTO wali_links (seeker_id, wali_id, status, relationship)
      VALUES (v_seeker_id, v_wali_id, 'active', p_relationship)
      RETURNING id INTO v_link_id;
  ELSE
    -- Re-accepting an existing link must not blank a relationship already
    -- recorded, so a null argument leaves the stored value alone.
    UPDATE wali_links
       SET status = 'active',
           relationship = COALESCE(p_relationship, relationship)
     WHERE id = v_link_id;
  END IF;

  UPDATE wali_invites SET status = 'accepted', accepted_at = NOW(), accepted_by = v_accepter_id WHERE id = v_invite.id;

  SELECT first_name INTO v_accepter_name FROM profiles WHERE id = v_accepter_id;
  PERFORM create_notification(
    v_invite.inviter_id, 'wali_request', 'Wali Link Accepted',
    COALESCE(v_accepter_name, 'Someone') || ' accepted your Wali link invite.', NULL
  );

  RETURN v_link_id;
END;
$function$;

revoke execute on function public.accept_wali_invite(text, text) from public;
revoke execute on function public.accept_wali_invite(text, text) from anon;
grant  execute on function public.accept_wali_invite(text, text) to authenticated;
grant  execute on function public.accept_wali_invite(text, text) to service_role;
