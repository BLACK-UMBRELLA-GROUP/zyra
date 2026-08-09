-- AUDIT FINDING 2.1 — any Seeker could make themselves another Seeker's
-- MAIN GUARDIAN. Verified by exploit against this database 2026-08-09
-- (rolled back): attacker inserted a wali_invites row claiming
-- inviter_role='wali', victim accepted through the ordinary flow, and the
-- attacker landed as is_main=true, status=active.
--
-- ROOT CAUSE. accept_wali_invite read the ACCEPTER's role from profiles —
-- correctly — but took the INVITER's role from wali_invites.inviter_role,
-- a column the client writes. The only policy on that table is
-- with_check (inviter_id = auth.uid()), which an attacker satisfies
-- honestly. zyra_can_guardian_link() does not save it: its whole body is
-- both ids non-null, not equal, and no matches row between them. No role
-- check, no gender check.
--
-- WHAT IT BOUGHT THE ATTACKER. Main Guardian is the top trust tier —
-- seeker_details_select_guardian (sect, revert status, ethnicity,
-- nationality: GDPR Article 9 special-category data),
-- zyra_can_view_profile clause 2, zyra_counterpart_card, a Family Review
-- vote, and the is_main branch of messages_select.
--
-- THE FIX. Read the inviter's role from profiles, the same source already
-- trusted for the accepter. profiles.role is NOT client-writable —
-- verified 2026-08-09, 'authenticated' holds SELECT and REFERENCES on that
-- column and nothing else — so it is a sound source of truth.
--
-- A mismatch is REFUSED rather than silently reinterpreted. Branching on
-- the true role alone would already be safe (it either produces the
-- correct relationship or fails the accepter-role check), but a silent
-- reinterpretation hides an attack and confuses the honest edge case where
-- someone's role legitimately changed after they sent the invite. Both
-- should re-send.
--
-- Everything else in this function is unchanged from the version live
-- before this migration.

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

  -- ── SECURITY 2026-08-09, audit finding 2.1. The inviter's role comes
  -- from profiles, NOT from wali_invites.inviter_role, which the client
  -- writes and can therefore lie about. See this migration's header.
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