-- COMMENT CORRECTION to 20260809170940 (findings 2.6/2.7). Behaviour is
-- IDENTICAL — this replaces one wrong comment inside accept_wali_invite.
--
-- The previous version said the expiry check marks the row "on the way
-- past rather than left pending". It does not. expire_wali_invite_if_due()
-- performs an UPDATE, but the RAISE immediately after it aborts the
-- function and Postgres rolls that UPDATE back with everything else.
-- Proven 2026-08-09: after a refused accept, status was still 'pending'.
--
-- The security property is unaffected — the accept is refused either way —
-- but a comment that describes a side effect which never happens is the
-- same class of problem as the code this whole audit is cleaning up. If
-- someone later builds a cleanup report on the belief that accept marks
-- expired invites, they would be wrong.
--
-- The call is kept, not replaced with an inline expires_at test, because
-- it keeps ONE definition of "expired" (invariant I3). It is simply a
-- predicate here; the marking is done by preview_wali_invite.

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
  -- preview_wali_invite, which the client was trusted to call first, so a
  -- direct call to this RPC ignored the 7-day deadline entirely.
  --
  -- expire_wali_invite_if_due() is used as a PREDICATE, to keep one
  -- definition of "expired" (I3). Its UPDATE does not survive: the RAISE
  -- below aborts this function and rolls it back. Marking the row is
  -- preview_wali_invite's job, not this one.
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
