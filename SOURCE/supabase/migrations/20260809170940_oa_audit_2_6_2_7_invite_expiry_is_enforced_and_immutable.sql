-- AUDIT FINDINGS 2.6 AND 2.7 — invite expiry was decorative.
--
-- They are one defect in two halves, which is why they are one migration.
--
-- 2.6 · accept_wali_invite NEVER LOOKED AT expires_at. The only expiry
-- enforcement was in preview_wali_invite, which calls
-- expire_wali_invite_if_due() and flips the row to 'expired'. The client
-- is trusted to call preview first. It does — but the accept RPC is
-- granted to `authenticated` and can be called directly, and then the
-- 7-day deadline means nothing at all.
--
-- 2.7 · THE INVITER COULD REWRITE THE INVITE. Measured 2026-08-09:
-- `authenticated` held UPDATE on EVERY column of wali_invites — status,
-- expires_at, token, inviter_role, accepted_by, all of them — and
-- wali_invites_update carried a USING clause with no WITH CHECK, so
-- USING doubled as the check and the only rule was "it is mine".
--
-- Together: revoke an invite, set status back to 'pending', push
-- expires_at out another year, and it is live again. That is not a stale
-- invite, it is WITHDRAWN ACCESS THAT STILL WORKS — and the access in
-- question is Main Guardian, which reads sect, revert status, ethnicity
-- and nationality (GDPR Article 9).
--
-- The audit named three columns. It is all of them.
--
-- ── THE FIX FOR 2.6. Call the helper that already exists rather than
-- re-testing expires_at inline. expire_wali_invite_if_due() is the one
-- place that decides what "expired" means, it already marks the row, and
-- preview_wali_invite already uses it. One predicate, one place —
-- invariant I3. A second inline `expires_at < NOW()` here would be a
-- second definition that could drift.
--
-- ── THE FIX FOR 2.7. `authenticated` does not need UPDATE on this table
-- AT ALL. Verified before revoking — every write path goes elsewhere:
--   · create   -> plain INSERT (kept)
--   · revoke   -> zyra_revoke_wali_invite(), SECURITY DEFINER
--   · accept   -> accept_wali_invite(), SECURITY DEFINER
--   · expire   -> expire_wali_invite_if_due(), called from inside
--                 SECURITY DEFINER functions, so it runs as the definer
--   · Dart     -> reads only (zyra_wali_link_service.dart:278 SELECT,
--                 :330 INSERT). No .update() on this table anywhere in
--                 109 Dart files.
--
-- So the grant is removed, not narrowed. wali_invites_update is dropped
-- with it: a policy behind a revoked grant is dead code that reads as a
-- live rule, and the next person to grant UPDATE should have to think
-- about the policy rather than inherit one.
--
-- ── NOT IN THIS MIGRATION: finding 2.9. The audit calls
-- zyra_clear_main_guardian a defect for lacking the guard
-- zyra_remove_guardian has. It is not — zyra_wali_link_service.dart
-- documents the no-Main state as deliberate: "demoting can leave a
-- Seeker with Guardians and no Main. That is reachable and the Guardian
-- page handles it." Two positions disagree and the Founder decides which
-- one holds. Raised, not built.

CREATE OR REPLACE FUNCTION public.accept_wali_invite(p_token text, p_relationship text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_invite wali_invites%ROWTYPE;
  v_accepter_id UUID := auth.uid();
  v_accepter_role TEXT;
  v_inviter_role TEXT;
  v_accepter_name TEXT;
  v_seeker_id UUID;
  v_wali_id UUID;
  v_link_id UUID;
  v_relationship TEXT;
  v_live_status TEXT;
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

  -- ── EXPIRY, 2026-08-09, audit finding 2.6. Was enforced ONLY in
  -- preview_wali_invite, which the client was trusted to call first.
  -- Reuses that same helper so there is one definition of expired, and
  -- so the row is marked on the way past rather than left pending.
  v_live_status := expire_wali_invite_if_due(v_invite);
  IF v_live_status <> 'pending' THEN
    RAISE EXCEPTION 'invite_expired'
      USING HINT = 'This invite has expired. Ask for a new code.';
  END IF;

  IF v_invite.inviter_id = v_accepter_id THEN
    RAISE EXCEPTION 'Cannot accept your own invite';
  END IF;

  SELECT role INTO v_accepter_role FROM profiles WHERE id = v_accepter_id;
  IF v_accepter_role IS NULL THEN
    RAISE EXCEPTION 'Complete your profile before accepting an invite';
  END IF;

  -- ── SECURITY 2026-08-09, audit finding 2.1. The inviter's role comes
  -- from profiles, NOT from wali_invites.inviter_role, which the client
  -- writes and can therefore lie about.
  SELECT role INTO v_inviter_role FROM profiles WHERE id = v_invite.inviter_id;
  IF v_inviter_role IS NULL THEN
    RAISE EXCEPTION 'Invite is no longer valid';
  END IF;
  IF v_inviter_role IS DISTINCT FROM v_invite.inviter_role THEN
    RAISE EXCEPTION 'invite_role_mismatch'
      USING HINT = 'This invite does not match the account that sent it. '
                   'Ask them to send a new one.';
  END IF;

  -- WHO may be a Guardian. Still role-based, still gated on the outstanding
  -- gender governance review. Distinct from the romantic-conflict question
  -- below, which is now zyra_can_guardian_link()'s job.
  IF v_inviter_role = 'seeker' THEN
    IF v_accepter_role <> 'wali' THEN
      RAISE EXCEPTION 'This invite is for a Wali account';
    END IF;
    v_seeker_id := v_invite.inviter_id;
    v_wali_id := v_accepter_id;
  ELSIF v_inviter_role = 'wali' THEN
    IF v_accepter_role <> 'seeker' THEN
      RAISE EXCEPTION 'This invite is for a Seeker account';
    END IF;
    v_seeker_id := v_accepter_id;
    v_wali_id := v_invite.inviter_id;
  ELSE
    RAISE EXCEPTION 'Invalid invite';
  END IF;

  -- One predicate, one place. Was an inline EXISTS here until 2026-08-07.
  IF NOT public.zyra_can_guardian_link(v_seeker_id, v_wali_id) THEN
    RAISE EXCEPTION 'romantic_edge_exists'
      USING HINT = 'These two people have a Journey together. A Guardian '
                   'relationship cannot be created over one. End the Journey '
                   'first if that is really what you both want.';
  END IF;

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

  -- ── ARCHITECTURAL RULE, not housekeeping. Founder-ratified 2026-08-07.
  --
  --   "Forming a Guardian bond extinguishes any one-sided romantic intent
  --    between the two people, in both directions, silently and
  --    permanently."
  --
  -- WHY CLEARED RATHER THAN REFUSED. Refusing a Guardian link because a
  -- Like exists would let anyone veto a Guardian relationship they are not
  -- part of, simply by Liking one of the parties — one denial-of-service
  -- traded for another. A MATCH is different: mutual, stateful, and
  -- refused above.
  --
  -- WHY SILENTLY. Telling Alice "your Save of Bob was removed" discloses
  -- that she had saved him, to a screen her new Guardian may be looking at.
  -- The disclosure is worse than the surprise.
  --
  -- WHY PERMANENTLY. Removing the Guardian link later does not restore
  -- them. Interest is a present-tense act; resurrecting a year-old Like
  -- would be inventing intent nobody expressed.
  --
  -- A future developer wondering why a Save vanished on its own should find
  -- this comment, ZYRA_GUARDIAN_ROMANTIC_RULES_CURRENT_VERSION_V1.md, or
  -- both.
  DELETE FROM likes  WHERE (liker_id  = v_seeker_id AND liked_id  = v_wali_id)
                        OR (liker_id  = v_wali_id   AND liked_id  = v_seeker_id);
  DELETE FROM saves  WHERE (saver_id  = v_seeker_id AND saved_id  = v_wali_id)
                        OR (saver_id  = v_wali_id   AND saved_id  = v_seeker_id);
  DELETE FROM passes WHERE (passer_id = v_seeker_id AND passed_id = v_wali_id)
                        OR (passer_id = v_wali_id   AND passed_id = v_seeker_id);

  UPDATE wali_invites SET status = 'accepted', accepted_at = NOW(), accepted_by = v_accepter_id WHERE id = v_invite.id;

  SELECT first_name INTO v_accepter_name FROM profiles WHERE id = v_accepter_id;
  PERFORM create_notification(
    v_invite.inviter_id, 'wali_request', 'Wali Link Accepted',
    COALESCE(v_accepter_name, 'Someone') || ' accepted your Wali link invite.', NULL
  );

  RETURN v_link_id;
END;
$function$;


-- ── 2.7. No client-side UPDATE on this table. See the header for the
-- audit of every write path that proves nothing needs it.
REVOKE UPDATE ON public.wali_invites FROM authenticated;
DROP POLICY IF EXISTS wali_invites_update ON public.wali_invites;
