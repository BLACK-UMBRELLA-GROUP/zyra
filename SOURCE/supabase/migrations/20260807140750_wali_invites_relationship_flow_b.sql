-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260807140750, applied name
-- 'wali_invites_relationship_flow_b') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Flow B: the Guardian states their relationship when CREATING the invite.
--
-- THE RULE (Founder, 2026-08-07): "The relationship is a statement about the
-- Guardian, so the Guardian makes it — once per link, at the point they
-- create that link."
--
-- Flow A already satisfies this: the Guardian accepts, and is asked there.
-- Flow B could not, because in that direction the Guardian is gone by the
-- time the link exists — the Seeker's acceptance is what creates the row. So
-- the answer has to travel WITH the invite and be transferred on acceptance.
--
-- Distinct from wali_invites.label, which is the sender's private note about
-- WHO the code is for. This is a claim about the SENDER, and unlike the
-- label it does leave the invite: it becomes wali_links.relationship.

alter table public.wali_invites add column if not exists relationship text;

alter table public.wali_invites
  drop constraint if exists wali_invites_relationship_check;
alter table public.wali_invites
  add constraint wali_invites_relationship_check
  check (relationship is null or relationship in (
    'father', 'brother', 'grandfather', 'uncle',
    'legal_guardian', 'family_representative', 'other'));

-- Only meaningful when a GUARDIAN is inviting. A Seeker inviting a Guardian
-- has nothing to state about themselves — the Guardian answers at acceptance.
alter table public.wali_invites
  drop constraint if exists wali_invites_relationship_only_from_wali;
alter table public.wali_invites
  add constraint wali_invites_relationship_only_from_wali
  check (relationship is null or inviter_role = 'wali');

comment on column public.wali_invites.relationship is
  'OWNERSHIP: row-scoped(inviter_id) — the inviting Guardian''s statement '
  'about themselves ("I am her father"), carried onto wali_links.relationship '
  'when the Seeker accepts. Null for Seeker-sent invites, where the Guardian '
  'is asked at acceptance instead. Per LINK, not per account.';

-- accept_wali_invite: take the invite's relationship when the caller did not
-- supply one. Flow A passes p_relationship (Guardian accepting); Flow B
-- passes null and inherits what the Guardian stated when sending.
create or replace function public.accept_wali_invite(
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
  v_relationship TEXT;
BEGIN
  IF v_accepter_id IS NULL THEN
    RAISE EXCEPTION 'Not signed in';
  END IF;

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

  -- The caller's answer wins where there is one — that is the Guardian
  -- answering live in Flow A. Otherwise inherit what the Guardian stated
  -- when they sent it, which is Flow B. Either way the value came from the
  -- Guardian and never from the Seeker.
  v_relationship := COALESCE(p_relationship, v_invite.relationship);

  SELECT id INTO v_link_id FROM wali_links WHERE seeker_id = v_seeker_id AND wali_id = v_wali_id;
  IF v_link_id IS NULL THEN
    INSERT INTO wali_links (seeker_id, wali_id, status, relationship)
      VALUES (v_seeker_id, v_wali_id, 'active', v_relationship)
      RETURNING id INTO v_link_id;
  ELSE
    UPDATE wali_links
       SET status = 'active',
           relationship = COALESCE(v_relationship, relationship)
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
