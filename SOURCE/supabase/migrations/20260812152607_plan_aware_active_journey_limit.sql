-- THE ACTIVE CAP IS THE PLAN'S, NOT THE NUMBER ONE ........................
-- Completes part (b) of the work data/zyra_entitlements.dart has carried
-- as "raised, not built" since 2026-08-09: the entitlements matrix says
-- ZYRA Basic holds 1 Active Journey and ZYRA One holds 3, and until today
-- the server enforced exactly one for everyone. Founder made it real by
-- picking the C1 chooser popup (2026-08-12): at the cap, the app now asks
-- WHICH Journey makes room — a question that only exists once the cap can
-- be above one.
--
-- Two helpers carry the rule so seven enforcement points cannot drift:
--   zyra_active_journey_cap(user)    — 3 on an active seeker_premium
--                                      subscription, 1 otherwise; the same
--                                      plan read suspend_journey uses. The
--                                      numbers mirror the matrix
--                                      (data/zyra_entitlements.dart).
--   zyra_active_journey_count(user)  — unsuspended active matches, with an
--                                      optional row to exclude.
-- Both are internal: no client role may call them.
--
-- THE UNIQUE INDEXES BECOME PLAIN INDEXES. matches_seeker_a_active /
-- _b_active enforced cap-one at the storage layer; a per-plan cap cannot
-- live in a unique index. The constraint triggers — which serialise both
-- parties under advisory locks precisely so they are race-proof — are now
-- the sole enforcement, as promote's own comment always described them.
-- The indexes stay (non-unique) because every cap check counts by seeker
-- over exactly their predicate.
--
-- Error names are unchanged ('one_active_journey_limit',
-- 'self_in_active_journey', 'other_party_in_active_journey') — the Dart
-- side maps names, not sentences, so Basic behaviour and old clients are
-- untouched. Hints now speak in "your plan's limit".

-- 1 ── the rule, in one place each
create or replace function public.zyra_active_journey_cap(p_user uuid)
returns int
language sql stable security definer
set search_path to 'public'
as $$
  select case when exists (
    select 1 from subscriptions
    where user_id = p_user and plan_type = 'seeker_premium' and status = 'active'
  ) then 3 else 1 end;
$$;
revoke all on function public.zyra_active_journey_cap(uuid) from public, anon, authenticated;

create or replace function public.zyra_active_journey_count(p_user uuid, p_exclude uuid default null)
returns int
language sql stable security definer
set search_path to 'public'
as $$
  select count(*)::int from matches
  where status = 'active' and suspended_by is null
    and (seeker_a_id = p_user or seeker_b_id = p_user)
    and (p_exclude is null or id <> p_exclude);
$$;
revoke all on function public.zyra_active_journey_count(uuid, uuid) from public, anon, authenticated;

-- 2 ── the storage layer: uniqueness out, lookup support stays
drop index if exists matches_seeker_a_active;
drop index if exists matches_seeker_b_active;
create index matches_seeker_a_active on public.matches
  using btree (seeker_a_id) where (status = 'active' and suspended_by is null);
create index matches_seeker_b_active on public.matches
  using btree (seeker_b_id) where (status = 'active' and suspended_by is null);

-- 3 ── the race-proof check on matches, now per-party and per-plan
CREATE OR REPLACE FUNCTION public.zyra_enforce_one_active_match()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_party uuid;
begin
  -- A paused row (suspended_by set) is not in the Active pool — being
  -- paused, or being updated while paused, needs no cap check.
  if new.status <> 'active' or new.suspended_by is not null then
    return null;
  end if;

  perform pg_advisory_xact_lock(hashtextextended(least(new.seeker_a_id, new.seeker_b_id)::text, 0));
  perform pg_advisory_xact_lock(hashtextextended(greatest(new.seeker_a_id, new.seeker_b_id)::text, 0));

  -- Each party against THEIR OWN plan's cap (Basic 1 / One 3). The count
  -- excludes this row, so entering the pool is refused exactly when the
  -- party already stands at their cap.
  foreach v_party in array array[new.seeker_a_id, new.seeker_b_id] loop
    if zyra_active_journey_count(v_party, new.id) >= zyra_active_journey_cap(v_party) then
      raise exception 'one_active_journey_limit'
        using hint = 'One of you is at their plan''s Active Journey limit. End or pause one first.';
    end if;
  end loop;

  return null;
end $function$;

-- 4 ── the mirror on journey_attempts, same shape
CREATE OR REPLACE FUNCTION public.zyra_enforce_one_active_attempt()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_a uuid;
  v_b uuid;
  v_party uuid;
begin
  -- A paused attempt (paused_by set) is not in the Active pool.
  if new.status <> 'active' or new.paused_by is not null then
    return null;
  end if;

  select m.seeker_a_id, m.seeker_b_id into v_a, v_b
  from public.matches m where m.id = new.match_id;

  -- Serialise on the participants, in a stable order so two transactions
  -- touching the same pair can never deadlock against each other.
  perform pg_advisory_xact_lock(hashtextextended(least(v_a,v_b)::text, 0));
  perform pg_advisory_xact_lock(hashtextextended(greatest(v_a,v_b)::text, 0));

  foreach v_party in array array[v_a, v_b] loop
    if (select count(*) from public.journey_attempts a
          join public.matches m on m.id = a.match_id
        where a.status = 'active'
          and a.paused_by is null
          and a.id <> new.id
          and (m.seeker_a_id = v_party or m.seeker_b_id = v_party)
       ) >= zyra_active_journey_cap(v_party) then
      raise exception 'one_active_journey_limit'
        using hint = 'One of you is at their plan''s Active Journey limit. End or pause one first.';
    end if;
  end loop;

  return null;
end $function$;

-- 5 ── promote: the good message before the race-proof trigger
CREATE OR REPLACE FUNCTION public.promote_journey_to_active(p_match_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE m RECORD; caller UUID := auth.uid(); v_attempt UUID; v_party UUID;
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

  -- UNCHANGED in role, and kept deliberately even though the constraint
  -- trigger backstops it: this produces a clear, actionable error before
  -- the trigger fires. The trigger is the race-proof guarantee (audit R7:
  -- SELECT INTO takes no row lock); this is the good message.
  -- 2026-08-12 (later the same day as pause-frees-slot): per-party,
  -- per-plan — Basic 1 / One 3, and paused rows never count.
  FOREACH v_party IN ARRAY ARRAY[m.seeker_a_id, m.seeker_b_id] LOOP
    IF zyra_active_journey_count(v_party, p_match_id) >= zyra_active_journey_cap(v_party) THEN
      RAISE EXCEPTION 'one_active_journey_limit'
        USING HINT = CASE WHEN v_party = caller
          THEN 'You are at your plan''s Active Journey limit. End or pause one before starting another.'
          ELSE 'The other person is at their Active Journey limit right now.'
        END;
    END IF;
  END LOOP;

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

-- 6 ── resume: both guards move from "one" to "the plan's cap"
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
  -- NEW 2026-08-12 (pause frees the slot), plan-aware the same day: your
  -- own state first — it is the one you can act on. The constraint
  -- trigger backstops the race.
  IF zyra_active_journey_count(caller, p_match_id) >= zyra_active_journey_cap(caller) THEN
    RAISE EXCEPTION 'self_in_active_journey'
      USING HINT='You are at your plan''s Active Journey limit. Pause or '
                 'end one first — then resume this one.';
  END IF;
  other_id := CASE WHEN m.seeker_a_id = caller THEN m.seeker_b_id ELSE m.seeker_a_id END;
  -- UNCHANGED in role, still from `matches` — authoritative until step 7.
  IF zyra_active_journey_count(other_id, p_match_id) >= zyra_active_journey_cap(other_id) THEN
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

-- 7a ── requesting a new Journey: refused only at the caller's cap
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
  -- 2026-08-12: per the caller's plan cap; paused Journeys never count.
  IF zyra_active_journey_count(caller) >= zyra_active_journey_cap(caller) THEN
    RAISE EXCEPTION 'one_active_journey_limit'
      USING HINT = 'You are at your plan''s Active Journey limit. End or pause one first.';
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

-- 7b ── and the read-side predicate the button is drawn from, kept in step
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
  -- 2026-08-12: per the caller's plan cap; paused Journeys never count.
  IF zyra_active_journey_count(caller) >= zyra_active_journey_cap(caller) THEN RETURN FALSE; END IF;
  IF EXISTS (SELECT 1 FROM journey_requests r
              WHERE r.match_id = p_match_id AND r.status='pending') THEN RETURN FALSE; END IF;
  RETURN TRUE;
END;
$function$;
