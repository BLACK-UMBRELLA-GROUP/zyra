-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260807223439, applied name
-- 'zyra_can_guardian_link_predicate') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Founder, 2026-08-07: "I'd also like to explicitly state that a Guardian
-- relationship cannot be created over any existing romantic relationship
-- state that would create a conflict... The rule should exist once, with
-- every path enforcing it."
--
-- Correct, and the previous migration got it wrong in exactly the way this
-- whole review cycle has been about. It put the rule INSIDE
-- accept_wali_invite() as an inline EXISTS. That works for today's only
-- write path and is invisible to tomorrow's.
--
-- ── THE PAIR IS NOW SYMMETRIC:
--
--   zyra_can_match(a, b)          may these two pursue each other?
--   zyra_can_guardian_link(a, b)  may these two form a Guardian bond?
--
-- They are mutually exclusive by construction: a Guardian edge makes
-- can_match false, and a romantic edge makes can_guardian_link false.
-- Neither can be satisfied while the other holds, which is the invariant
-- Fable asked for, expressed as two functions instead of prose.
--
-- ── ENFORCED BY A TRIGGER, not only by the caller.
-- accept_wali_invite() is the only write path today because the client
-- INSERT grant was revoked. But "the only path today" is a fact with a
-- shelf life: the Identity Correction process will want admin tooling, and
-- dual-context will want new acceptance flows. A BEFORE trigger on
-- wali_links catches every one of them, including SECURITY DEFINER
-- functions, which is where the next write path will live.
--
-- ── SYMMETRIC ARGUMENTS. A romantic conflict does not care which of the
-- two is the Seeker, so neither does this. Called as (seeker, wali) by
-- convention; correct either way round.
--
-- ── WHAT IT DELIBERATELY DOES NOT CHECK: who is ALLOWED to be a Guardian.
-- Role, gender and the male-Guardian model are a separate question, still
-- gated on the outstanding governance review, and they live in
-- accept_wali_invite() until that concludes. This function answers one
-- question only — is there a romantic conflict between these two people.

create or replace function public.zyra_can_guardian_link(p_a uuid, p_b uuid)
 returns boolean
 language sql
 stable
 security definer
 set search_path to 'public'
as $function$
  select
        p_a is not null
    and p_b is not null
    -- Nobody is their own Guardian. Also a table CHECK
    -- (wali_links_no_self_link); stated here so the predicate is complete
    -- on its own rather than relying on a constraint one layer down.
    and p_a <> p_b
    -- ANY status, including 'ended'. An ended Journey can be revived by
    -- restart_journey(), so a Guardian link over one would create a pair
    -- the system can resurrect into a state zyra_can_match() forbids.
    -- "Absolute" was the Founder's word, and a past romance between a
    -- Guardian and their Seeker is the conflict of interest the Guardian
    -- role exists to prevent.
    and not exists (
      select 1 from public.matches m
      where (m.seeker_a_id = p_a and m.seeker_b_id = p_b)
         or (m.seeker_a_id = p_b and m.seeker_b_id = p_a)
    );
$function$;

comment on function public.zyra_can_guardian_link(uuid, uuid) is
  'THE canonical Guardian-eligibility predicate: may these two people form '
  'a Guardian bond? Symmetric and stateless. Refuses over ANY matches row '
  'in any status, including ended. Enforced by the '
  'zyra_wali_links_guardian_link_allowed trigger on wali_links, so every '
  'write path is covered including future ones. Deliberately silent on WHO '
  'may be a Guardian (role, gender) — that is the outstanding governance '
  'review and lives in accept_wali_invite(). Mirror of zyra_can_match(): '
  'the two are mutually exclusive by construction.';

revoke execute on function public.zyra_can_guardian_link(uuid, uuid) from public, anon;
grant  execute on function public.zyra_can_guardian_link(uuid, uuid) to authenticated;

-- ── The trigger: every path, not just the caller ──────────────────────

create or replace function public.zyra_enforce_guardian_link_allowed()
 returns trigger
 language plpgsql
 set search_path to 'public'
as $function$
BEGIN
  -- A link being retired is always permitted. The rule guards the creation
  -- of a bond, not its ending — and blocking removal would strand people.
  IF NEW.status = 'removed' THEN
    RETURN NEW;
  END IF;

  IF NOT public.zyra_can_guardian_link(NEW.seeker_id, NEW.wali_id) THEN
    RAISE EXCEPTION 'romantic_edge_exists'
      USING HINT = 'These two people have a Journey together. A Guardian '
                   'relationship cannot be created over one. End the Journey '
                   'first if that is really what you both want.';
  END IF;

  RETURN NEW;
END;
$function$;

drop trigger if exists zyra_wali_links_guardian_link_allowed on public.wali_links;
create trigger zyra_wali_links_guardian_link_allowed
  before insert or update of seeker_id, wali_id, status on public.wali_links
  for each row execute function public.zyra_enforce_guardian_link_allowed();

-- ── accept_wali_invite() now calls the predicate instead of restating it ──
-- Behaviour is identical; the rule simply no longer lives in two places
-- with a chance to drift. The trigger above would catch it regardless, but
-- checking here still earns its place: it produces the named error before
-- any of the invite bookkeeping runs, rather than aborting mid-way.

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

  -- WHO may be a Guardian. Still role-based, still gated on the outstanding
  -- gender governance review. Distinct from the romantic-conflict question
  -- below, which is now zyra_can_guardian_link()'s job.
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
