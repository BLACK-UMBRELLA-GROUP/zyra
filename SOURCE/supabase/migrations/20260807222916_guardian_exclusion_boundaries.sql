-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260807222916, applied name
-- 'guardian_exclusion_boundaries') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- STEP 3: the exclusion boundaries, shipped WITH the predicate rather than
-- after it. Founder authorised 2026-08-07.
--
-- zyra_can_match() stops a Guardian and their Seeker forming a NEW romantic
-- edge. That leaves two directions it does not cover, both found by the
-- adversarial sweep:
--
--   (a) A Guardian link created ON TOP of an existing romantic edge.
--   (b) An EXISTING romantic edge revived after a Guardian link appears.
--
-- ── (a) IS ALSO A DENIAL-OF-SERVICE VECTOR, which is why it cannot wait.
-- The moment "Guardian edge ⇒ never match" exists, a Guardian edge becomes
-- a way to make two people permanently unmatchable. Creating one is no
-- longer unilateral — the INSERT grant was revoked in the previous
-- migration and accept_wali_invite() needs a real invite and a real accept
-- — but two consenting people could still use it to void a Journey the
-- rest of the system believes is live.
--
-- The answer is to refuse the LINK, not to void the Journey. The Journey
-- has state behind it: a conversation, a timeline, milestones, and another
-- family's expectations. A settings action must not silently delete that.
--
-- ── WHY MATCHES REFUSE BUT LIKES DO NOT.
-- A match is mutual and stateful, so a Guardian link over one is refused.
-- A like or a save is one-sided, so refusing on those would let anyone
-- block a Guardian relationship they were not part of simply by Liking one
-- of the parties — trading one denial-of-service for another. Instead the
-- inert edges are cleared: once the link exists they can never lead
-- anywhere, and leaving them means every future feature has to reason
-- about pairs that look interested and are not eligible.

create or replace function public.accept_wali_invite(p_token text, p_relationship text DEFAULT NULL::text)
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

  -- ADDED 2026-08-07 — exclusion boundary (a).
  --
  -- ANY status, including 'ended'. An ended Journey can be revived by
  -- restart_journey(), so allowing a Guardian link over one would create a
  -- pair the system can resurrect into a state zyra_can_match() forbids.
  -- "Absolute" was the Founder's word for this rule; a historical romance
  -- between a Guardian and their Seeker is also the conflict of interest
  -- the Guardian role exists to prevent.
  IF EXISTS (
    SELECT 1 FROM matches
    WHERE (seeker_a_id = v_seeker_id AND seeker_b_id = v_wali_id)
       OR (seeker_a_id = v_wali_id   AND seeker_b_id = v_seeker_id)
  ) THEN
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

  -- Inert edges, cleared rather than refused. See the header.
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

-- ── (b) State transitions that REVIVE a romantic edge ─────────────────
--
-- Found by the adversarial sweep. zyra_can_match() is consulted when an
-- edge is CREATED. Neither of these creates one — they change the status
-- of an edge that already exists — so both slipped past it entirely:
--
--   potential match sits idle -> Guardian link forms legitimately
--     -> promote_journey_to_active() makes it ACTIVE
--   paused Journey            -> Guardian link forms legitimately
--     -> resume_journey() makes it live again
--
-- Either produces exactly the state the exclusion rule forbids, without
-- ever inserting a like. This is the "unexpected state transition" case.

create or replace function public.promote_journey_to_active(p_match_id uuid)
 returns void
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  m RECORD;
  caller UUID := auth.uid();
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'match not found';
  END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;
  IF m.status <> 'potential' THEN
    RAISE EXCEPTION 'match is not in potential state (status=%)', m.status;
  END IF;

  -- ADDED 2026-08-07. Re-checked at promotion, not merely at creation:
  -- a Guardian link or a block may have appeared in between.
  IF NOT public.zyra_can_match(m.seeker_a_id, m.seeker_b_id) THEN
    RAISE EXCEPTION 'not_eligible_to_match'
      USING HINT = 'Something has changed since this match was made — a '
                   'Guardian relationship or a block now exists between you.';
  END IF;

  -- One-Active-Journey-at-a-time (JOURNEY AVAILABILITY/Summary.md
  -- CORE PRINCIPLE). Checked explicitly here for a clear error message;
  -- the partial unique indexes on matches(seeker_a_id)/matches(seeker_b_id)
  -- WHERE status='active' are the hard backstop against race conditions.
  IF EXISTS (
    SELECT 1 FROM matches
    WHERE status = 'active'
      AND (seeker_a_id IN (m.seeker_a_id, m.seeker_b_id) OR seeker_b_id IN (m.seeker_a_id, m.seeker_b_id))
  ) THEN
    RAISE EXCEPTION 'one_active_journey_limit' USING HINT = 'You already have an Active Journey. End or pause it before starting another.';
  END IF;

  UPDATE matches SET status = 'active', journey_stage = 'compatibility_reveal' WHERE id = p_match_id;
END;
$function$;

create or replace function public.resume_journey(p_match_id uuid)
 returns void
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  m RECORD;
  caller UUID := auth.uid();
  other_id UUID;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;

  -- V3 §7: "Only the person who placed a pause may lift it."
  IF caller <> m.suspended_by THEN
    RAISE EXCEPTION 'only the suspending Seeker may resume';
  END IF;

  -- ADDED 2026-08-07, same reasoning as promote_journey_to_active(): a
  -- pause is exactly the window in which a Guardian link or a block is
  -- likely to appear.
  IF NOT public.zyra_can_match(m.seeker_a_id, m.seeker_b_id) THEN
    RAISE EXCEPTION 'not_eligible_to_match'
      USING HINT = 'Something has changed while this was paused — a Guardian '
                   'relationship or a block now exists between you.';
  END IF;

  other_id := CASE WHEN m.seeker_a_id = caller THEN m.seeker_b_id ELSE m.seeker_a_id END;

  IF EXISTS (
    SELECT 1 FROM matches
    WHERE status = 'active' AND id <> p_match_id
      AND (seeker_a_id = other_id OR seeker_b_id = other_id)
  ) THEN
    -- Refuses. Does NOT end anything. The row is untouched.
    RAISE EXCEPTION 'other_party_in_active_journey'
      USING HINT = 'This Journey stays paused for now. You can wait, or end it '
                   'yourself if you would rather.';
  END IF;

  UPDATE matches SET suspended_by = NULL, suspended_at = NULL WHERE id = p_match_id;
  UPDATE conversations SET status = 'active' WHERE match_id = p_match_id AND status = 'paused';
END;
$function$;
