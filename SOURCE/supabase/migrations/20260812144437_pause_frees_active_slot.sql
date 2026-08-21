-- PAUSE FREES THE ACTIVE SLOT .............................................
-- Ratified before it was built: the 2026-08-09 state matrix and
-- SUSPENSION V2 §5 both say a paused Journey does not consume an Active
-- slot — but every enforcement point counted status='active' alone, and a
-- paused row keeps status='active' with only suspended_by set. So a pause
-- HELD the slot: promote refused, request refused, and the takeover dialog
-- could honestly offer only End. Today the dialog gains "Pause with <name>
-- & begin" (Founder, 2026-08-12), which made the gap user-visible.
--
-- One decision, every enforcement point, one migration:
--   1  matches_seeker_a_active / _b_active — index only unsuspended rows.
--      Strictly narrower predicate, so existing data cannot violate it.
--   2  matches_one_active_per_person — also fire on suspended_by changes,
--      so a RESUME re-enters the race-proof advisory-lock check. It only
--      fired on status, and a resume never touches status.
--   3  zyra_enforce_one_active_match() — ignore paused rows in the clash;
--      a row being paused needs no check at all (it is LEAVING the pool).
--   4  promote_journey_to_active() — the good-message pre-check ignores
--      paused rows. This is the check that refused pause-then-begin.
--   5  resume_journey() — NEW self-guard 'self_in_active_journey':
--      resuming while YOU hold another unsuspended Active Journey is now a
--      reachable state, because pause-then-begin is legal. The other-party
--      guard likewise ignores paused rows.
--   6  request_new_journey() / zyra_may_request_new_journey() — a paused
--      Journey no longer blocks asking an ended one to begin again; the
--      accept path it feeds (promote) agrees, per 4.
--   7  restart_journey() — dormant (raises unconditionally), but its
--      preserved reinstatement comment carried the old predicate; amended
--      so OA-ZYRA-159 cannot copy the stale check back in.
-- suspend_journey() is deliberately untouched: its paused-count cap reads
-- status='active' AND suspended_by = caller, which is still exactly what
-- a paused row looks like.

-- 1 ── the partial unique indexes
drop index if exists matches_seeker_a_active;
drop index if exists matches_seeker_b_active;
create unique index matches_seeker_a_active on public.matches
  using btree (seeker_a_id) where (status = 'active' and suspended_by is null);
create unique index matches_seeker_b_active on public.matches
  using btree (seeker_b_id) where (status = 'active' and suspended_by is null);

-- 2 ── the constraint trigger re-armed for resumes
drop trigger if exists matches_one_active_per_person on public.matches;
create constraint trigger matches_one_active_per_person
  after insert or update of status, suspended_by on public.matches
  not deferrable initially immediate
  for each row execute function zyra_enforce_one_active_match();

-- 3 ── the race-proof check itself
CREATE OR REPLACE FUNCTION public.zyra_enforce_one_active_match()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_clash uuid;
begin
  -- A paused row (suspended_by set) is not in the Active pool — being
  -- paused, or being updated while paused, needs no clash check.
  if new.status <> 'active' or new.suspended_by is not null then
    return null;
  end if;

  perform pg_advisory_xact_lock(hashtextextended(least(new.seeker_a_id, new.seeker_b_id)::text, 0));
  perform pg_advisory_xact_lock(hashtextextended(greatest(new.seeker_a_id, new.seeker_b_id)::text, 0));

  select m.id into v_clash
  from public.matches m
  where m.status = 'active'
    and m.suspended_by is null
    and m.id <> new.id
    and (   m.seeker_a_id in (new.seeker_a_id, new.seeker_b_id)
         or m.seeker_b_id in (new.seeker_a_id, new.seeker_b_id) )
  limit 1;

  if v_clash is not null then
    raise exception 'one_active_journey_limit'
      using hint = 'One of you already has an Active Journey. End or pause it first.';
  end if;

  return null;
end $function$;

-- 4 ── promote: the good message before the race-proof trigger
CREATE OR REPLACE FUNCTION public.promote_journey_to_active(p_match_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE m RECORD; caller UUID := auth.uid(); v_attempt UUID;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;
  IF m.status <> 'potential' THEN
    RAISE EXCEPTION 'match is not in potential state (status=%)', m.status;
  END IF;

  -- UNCHANGED (2026-08-07): re-checked at promotion, not merely at
  -- creation — a Guardian link or a block may have appeared in between.
  IF NOT public.zyra_can_match(m.seeker_a_id, m.seeker_b_id) THEN
    RAISE EXCEPTION 'not_eligible_to_match'
      USING HINT = 'Something has changed since this match was made — a '
                   'Guardian relationship or a block now exists between you.';
  END IF;

  -- UNCHANGED, and kept deliberately even though step 6's constraint
  -- trigger now backstops it: this produces a clear, actionable error
  -- before the trigger fires. The trigger is the race-proof guarantee
  -- (audit R7: SELECT INTO takes no row lock); this is the good message.
  -- 2026-08-12: paused rows no longer count — pause frees the slot.
  IF EXISTS (
    SELECT 1 FROM matches
    WHERE status = 'active'
      AND suspended_by IS NULL
      AND (seeker_a_id IN (m.seeker_a_id, m.seeker_b_id)
           OR seeker_b_id IN (m.seeker_a_id, m.seeker_b_id))
  ) THEN
    RAISE EXCEPTION 'one_active_journey_limit'
      USING HINT = 'You already have an Active Journey. End or pause it before starting another.';
  END IF;

  UPDATE matches SET status = 'active', journey_stage = 'compatibility_reveal'
   WHERE id = p_match_id;

  -- NEW. The omission that gated steps 4, 6 and 7.
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id
   ORDER BY (a.status <> 'ended') DESC, a.attempt_number DESC LIMIT 1;
  IF v_attempt IS NULL THEN RAISE EXCEPTION 'no_attempt_for_match'; END IF;

  UPDATE journey_attempts
     SET status        = 'active',
         journey_stage = 'compatibility_reveal',
         started_at    = COALESCE(started_at, NOW())
   WHERE id = v_attempt;
END; $function$;

-- 5 ── resume: the self-guard, newly reachable
CREATE OR REPLACE FUNCTION public.resume_journey(p_match_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE m RECORD; caller UUID := auth.uid(); other_id UUID; v_attempt UUID;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  -- UNCHANGED: V3 section 7 "Only the person who placed a pause may lift it."
  IF caller <> m.suspended_by THEN
    RAISE EXCEPTION 'only the suspending Seeker may resume'; END IF;
  -- CHANGED 2026-08-08 (OA-ZYRA-174): was zyra_can_match(), which pulled in
  -- Tier-1 and trapped the Journey permanently over a third party's action.
  -- Now blocks and Tier-0 only — both of which the two parties can see and,
  -- if they choose, undo. The hint names something the Seeker can act on.
  IF NOT public.zyra_can_continue_journey(m.seeker_a_id, m.seeker_b_id) THEN
    RAISE EXCEPTION 'not_eligible_to_continue'
      USING HINT='This Journey cannot resume: one of you has blocked the '
                 'other, or one of you is now the other''s Guardian.';
  END IF;
  -- NEW 2026-08-12 (pause frees the slot): pause-then-begin is legal now,
  -- so a resumer can hold another Active Journey — a state that could not
  -- previously arise. Your own state first: it is the one you can act on.
  -- The re-armed constraint trigger backstops the race.
  IF EXISTS (SELECT 1 FROM matches WHERE status='active' AND suspended_by IS NULL
               AND id <> p_match_id
               AND (seeker_a_id = caller OR seeker_b_id = caller)) THEN
    RAISE EXCEPTION 'self_in_active_journey'
      USING HINT='You are in an Active Journey. Pause or end it first — '
                 'then resume this one.';
  END IF;
  other_id := CASE WHEN m.seeker_a_id = caller THEN m.seeker_b_id ELSE m.seeker_a_id END;
  -- UNCHANGED, still from `matches` — authoritative until step 7.
  -- 2026-08-12: their PAUSED Journeys no longer block yours resuming.
  IF EXISTS (SELECT 1 FROM matches WHERE status='active' AND suspended_by IS NULL
               AND id <> p_match_id
               AND (seeker_a_id = other_id OR seeker_b_id = other_id)) THEN
    RAISE EXCEPTION 'other_party_in_active_journey'
      USING HINT='This Journey stays paused for now. You can wait, or end it '
                 'yourself if you would rather.';
  END IF;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status <> 'ended'
   ORDER BY (a.status='active') DESC, a.attempt_number DESC LIMIT 1;

  UPDATE matches SET suspended_by = NULL, suspended_at = NULL WHERE id = p_match_id;
  UPDATE journey_attempts SET paused_by = NULL, paused_at = NULL
   WHERE v_attempt IS NOT NULL AND id = v_attempt;
  UPDATE conversations SET status='active'
   WHERE v_attempt IS NOT NULL AND attempt_id = v_attempt AND status='paused';
END; $function$;

-- 6a ── requesting a new Journey: a paused one no longer blocks the ask
CREATE OR REPLACE FUNCTION public.request_new_journey(p_match_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  k_expiry CONSTANT INTERVAL := INTERVAL '14 days';   -- DR-121 item 16, a guess
  k_cool   CONSTANT INTERVAL := INTERVAL '24 hours';  -- existing #17 cooling period
  caller UUID := (SELECT auth.uid());
  m      RECORD;
  other  UUID;
  v_id   UUID;
  v_name TEXT;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  -- Identity before existence, so an error never confirms a match the caller
  -- is not part of.
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;
  other := CASE WHEN caller = m.seeker_a_id THEN m.seeker_b_id ELSE m.seeker_a_id END;

  IF m.status <> 'ended' THEN
    RAISE EXCEPTION 'journey_not_ended'
      USING HINT = 'There is nothing to begin again — this Journey has not ended.';
  END IF;

  IF m.ended_at IS NULL OR NOW() < m.ended_at + k_cool THEN
    RAISE EXCEPTION 'cooling_period_active'
      USING HINT = 'This Journey ended less than 24 hours ago.';
  END IF;

  -- THE ORDER OF THE NEXT THREE MATTERS, and it is the reverse of how they
  -- read. A hold is checked LAST of the three refusals that could reveal
  -- something: blocks and Tier-1 are conditions of the pair, but a hold is a
  -- record of a decision the other person made and did not want disclosed.
  IF zyra_block_exists(other) THEN
    RAISE EXCEPTION 'not_available';
  END IF;

  IF NOT zyra_can_match(caller, other) THEN
    RAISE EXCEPTION 'not_available';
  END IF;

  -- OA-ZYRA-159: "THE REQUESTER IS NEVER TOLD WHICH." A 6-month cooldown, a
  -- permanent "don't ask again" and a 14-day expiry all land here, and all
  -- raise the SAME error as a block and a Tier-1 exclusion. One error name
  -- for every refusal is what makes them indistinguishable — the moment one
  -- of them gets its own message, the requester can tell them apart.
  IF zyra_hold_blocks(caller, other) THEN
    RAISE EXCEPTION 'not_available';
  END IF;

  -- Asking for something you could not accept wastes the other person's
  -- decision. Checked before the request exists, not at accept time.
  -- 2026-08-12: a paused Journey no longer counts — pause frees the slot.
  IF EXISTS (SELECT 1 FROM matches x WHERE x.status = 'active'
               AND x.suspended_by IS NULL
               AND (x.seeker_a_id = caller OR x.seeker_b_id = caller)) THEN
    RAISE EXCEPTION 'one_active_journey_limit'
      USING HINT = 'You already have an Active Journey. End or pause it first.';
  END IF;

  IF EXISTS (SELECT 1 FROM journey_requests r
              WHERE r.match_id = p_match_id AND r.status = 'pending') THEN
    RAISE EXCEPTION 'request_already_pending';
  END IF;

  INSERT INTO journey_requests (match_id, requested_by, requested_to, expires_at)
  VALUES (p_match_id, caller, other, NOW() + k_expiry)
  RETURNING id INTO v_id;

  SELECT first_name INTO v_name FROM profiles WHERE id = caller;
  PERFORM create_notification(
    other, 'journey_request', 'A new Journey',
    COALESCE(v_name,'Someone') || ' would like to begin a new Journey with you.',
    p_match_id);

  RETURN v_id;
END;
$function$;

-- 6b ── and the read-side predicate the button is drawn from, kept in step
CREATE OR REPLACE FUNCTION public.zyra_may_request_new_journey(p_match_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  caller UUID := (SELECT auth.uid());
  m RECORD; other UUID;
BEGIN
  IF caller IS NULL THEN RETURN FALSE; END IF;
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RETURN FALSE; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN RETURN FALSE; END IF;
  other := CASE WHEN caller = m.seeker_a_id THEN m.seeker_b_id ELSE m.seeker_a_id END;

  IF m.status <> 'ended' THEN RETURN FALSE; END IF;
  IF m.ended_at IS NULL OR NOW() < m.ended_at + INTERVAL '24 hours' THEN RETURN FALSE; END IF;
  IF zyra_block_exists(other) THEN RETURN FALSE; END IF;
  IF NOT zyra_can_match(caller, other) THEN RETURN FALSE; END IF;
  IF zyra_hold_blocks(caller, other) THEN RETURN FALSE; END IF;
  -- 2026-08-12: a paused Journey no longer counts — pause frees the slot.
  IF EXISTS (SELECT 1 FROM matches x WHERE x.status='active'
               AND x.suspended_by IS NULL
               AND (x.seeker_a_id = caller OR x.seeker_b_id = caller)) THEN RETURN FALSE; END IF;
  IF EXISTS (SELECT 1 FROM journey_requests r
              WHERE r.match_id = p_match_id AND r.status='pending') THEN RETURN FALSE; END IF;
  RETURN TRUE;
END;
$function$;

-- 7 ── restart_journey: dormant, but its reinstatement recipe is amended so
--      OA-ZYRA-159 cannot copy the stale predicate back in. Behaviour
--      unchanged: it still refuses unconditionally.
CREATE OR REPLACE FUNCTION public.restart_journey(p_match_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  m RECORD;
  caller UUID := auth.uid();
BEGIN
  -- Identity checks still run first, so the error a caller receives never
  -- confirms the existence of a match they are not part of.
  IF caller IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'match not found';
  END IF;

  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;

  -- OA-ZYRA-154. A Journey may not be reopened by one person.
  RAISE EXCEPTION 'restart_requires_mutual_consent'
    USING HINT = 'Starting again needs both people to agree. This will be '
                 'available as Request New Journey.';

  -- ---------------------------------------------------------------------
  -- Preserved for OA-ZYRA-159, which will run this AFTER the other party
  -- accepts. Deliberately already stripped of every destructive statement,
  -- so nobody reinstating it can reinstate the defect by accident:
  --
  --   • no DELETEs — V3 item 13, all Journey history is preserved
  --   • ended_at is NOT cleared — the prior ending stays on the record
  --   • conversations goes to 'active', not 'closed'
  --   • 2026-08-12: the slot check below already carries suspended_by IS
  --     NULL — pause frees the slot; do not reinstate it without that.
  --
  -- IF m.status <> 'ended' THEN RAISE EXCEPTION 'match is not ended'; END IF;
  -- IF EXISTS (SELECT 1 FROM matches WHERE status = 'active' AND suspended_by IS NULL
  --            AND id <> p_match_id
  --            AND (seeker_a_id IN (m.seeker_a_id, m.seeker_b_id)
  --              OR seeker_b_id IN (m.seeker_a_id, m.seeker_b_id)))
  -- THEN RAISE EXCEPTION 'one_active_journey_limit'; END IF;
  --
  -- UPDATE matches SET status = 'active', journey_stage = 'compatibility_reveal'
  --  WHERE id = p_match_id;
  -- UPDATE conversations SET status = 'active', closed_at = NULL
  --  WHERE match_id = p_match_id;
  -- ---------------------------------------------------------------------
END;
$function$;
