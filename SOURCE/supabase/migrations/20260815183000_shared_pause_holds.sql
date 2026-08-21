-- ═══════════════════════════════════════════════════════════════════════
-- SHARED PAUSE HOLDS — DR-ZYRA-170, 2026-08-15
--
-- Founder brief (verbatim intent): "I want the pause to feel like a
-- shared Journey state, not one person having power over the other."
--
-- THE MODEL: a pause is a PERSONAL HOLD.
--   · Either party may hold (suspend_journey now mirrors when the other
--     side already holds).
--   · The Journey rests while ANY hold exists.
--   · resume_journey lifts only YOUR OWN hold — nobody resumes anybody
--     else, nobody requests anything.
--   · Lifting yours while theirs stands IS your standing "I'm ready"
--     (pause_nudged_at is set for you; the pause_nudge notification
--     carries it — DR-ZYRA-142's one-shot survives only for the person
--     who never held).
--
-- STATE COLUMNS: matches.suspended_by stays the PRIMARY hold;
-- matches.also_paused_by is the second. When the primary lifts while a
-- second stands, the second is PROMOTED into suspended_by — so the
-- journey_paused / journey_continued Timeline trigger
-- (zyra_record_journey_milestone) stays correct WITHOUT modification:
-- it fires only on NULL↔set transitions of suspended_by, and promotion
-- never touches NULL. Verified against the live trigger body before
-- writing this.
--
-- NOTIFICATIONS: three new types. journey_paused finally tells the
-- other person a pause happened at all (they used to find out by
-- opening the app); journey_also_paused tells the first pauser the
-- other now rests too; journey_continued ends the silent-reactivation
-- problem (resume used to flip the Journey active for both with no
-- word to the non-pauser). Voice matches pause_nudge's existing warmth.
-- Guardian-silent throughout, deliberately — a pause is a whisper, not
-- a family event.
--
-- CAPS: the 5/10 paused cap now counts HOLDS YOU CURRENTLY HOLD
-- (either column). A mirror is your hold and counts against your plan;
-- the existing paused_limit_reached refusal covers the edge.
-- ═══════════════════════════════════════════════════════════════════════

-- ── columns (same shape as suspended_by: bare uuid, no FK — matching) ──
alter table matches
  add column if not exists also_paused_by uuid,
  add column if not exists also_paused_at timestamptz;

alter table journey_attempts
  add column if not exists also_paused_by uuid,
  add column if not exists also_paused_at timestamptz;

-- A second hold cannot exist without a first, and never the same hand.
alter table matches drop constraint if exists matches_also_pause_requires_primary;
alter table matches add constraint matches_also_pause_requires_primary
  check (also_paused_by is null or suspended_by is not null);
alter table matches drop constraint if exists matches_holds_distinct;
alter table matches add constraint matches_holds_distinct
  check (also_paused_by is null or also_paused_by <> suspended_by);

-- ── notification types: 10 → 13 ──
alter table notifications drop constraint if exists notifications_type_check;
alter table notifications add constraint notifications_type_check
  check (type = any (array[
    'new_match'::text, 'new_message'::text, 'wali_request'::text,
    'journey_ended'::text, 'journey_request'::text,
    'journey_request_accepted'::text, 'journey_request_declined'::text,
    'milestone_proposed'::text, 'milestone_confirmed'::text,
    'pause_nudge'::text,
    'journey_paused'::text, 'journey_also_paused'::text,
    'journey_continued'::text]));

-- ── suspend_journey: first hold OR mirror ──
CREATE OR REPLACE FUNCTION public.suspend_journey(p_match_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  m RECORD; caller UUID := auth.uid(); caller_plan TEXT; v_attempt UUID;
  v_cap INT; v_held INT; v_other UUID; v_name TEXT;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match'; END IF;
  IF m.status <> 'active' THEN RAISE EXCEPTION 'match is not active'; END IF;

  -- Idempotent for a hand already holding — a stale screen's second tap
  -- is not an error.
  IF caller IS NOT DISTINCT FROM m.suspended_by
     OR caller IS NOT DISTINCT FROM m.also_paused_by THEN
    RETURN;
  END IF;

  -- DR-ZYRA-170: the cap counts holds you currently HOLD, either column.
  SELECT plan_type INTO caller_plan FROM subscriptions WHERE user_id=caller AND status='active';
  v_cap := CASE WHEN caller_plan = 'seeker_premium' THEN 10 ELSE 5 END;
  SELECT COUNT(*) INTO v_held FROM matches
   WHERE status = 'active' AND (suspended_by = caller OR also_paused_by = caller)
     AND id <> p_match_id;
  IF v_held >= v_cap THEN
    RAISE EXCEPTION 'paused_limit_reached'
      USING HINT = 'Your plan holds up to ' || v_cap || ' paused Journeys.';
  END IF;

  v_other := CASE WHEN m.seeker_a_id = caller THEN m.seeker_b_id ELSE m.seeker_a_id END;
  SELECT first_name INTO v_name FROM profiles WHERE id = caller;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status <> 'ended'
   ORDER BY (a.status='active') DESC, a.attempt_number DESC LIMIT 1;

  IF m.suspended_by IS NULL THEN
    -- FIRST HOLD — the pre-existing behaviour, plus the notification the
    -- other person never used to get. pause_nudged_at cleared: a NEW
    -- pause is a NEW episode (DR-ZYRA-142).
    UPDATE matches SET suspended_by=caller, suspended_at=NOW(),
                       pause_nudged_at=NULL WHERE id=p_match_id;
    UPDATE journey_attempts SET paused_by=caller, paused_at=NOW()
     WHERE v_attempt IS NOT NULL AND id=v_attempt;
    UPDATE conversations SET status='paused'
     WHERE v_attempt IS NOT NULL AND attempt_id=v_attempt;
    PERFORM create_notification(
      v_other, 'journey_paused', 'A pause, not an ending',
      coalesce(v_name, 'They') || ' has paused your Journey. Everything you built together is kept.',
      p_match_id);
  ELSE
    -- MIRROR — the other party rests too. Journey-level state is
    -- unchanged (still paused), so the milestone trigger correctly
    -- writes nothing: the Timeline pair stays one 'paused', nameless.
    UPDATE matches SET also_paused_by=caller, also_paused_at=NOW()
     WHERE id=p_match_id;
    UPDATE journey_attempts SET also_paused_by=caller, also_paused_at=NOW()
     WHERE v_attempt IS NOT NULL AND id=v_attempt;
    PERFORM create_notification(
      v_other, 'journey_also_paused', 'Resting together',
      coalesce(v_name, 'They') || ' has also paused. Your Journey rests until you both continue.',
      p_match_id);
  END IF;
END; $function$;

-- ── resume_journey: lift your own hold; promote; final lift activates ──
CREATE OR REPLACE FUNCTION public.resume_journey(p_match_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE m RECORD; caller UUID := auth.uid(); other_id UUID; v_attempt UUID; v_name TEXT;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not a party to this match'; END IF;
  IF m.status <> 'active' THEN RAISE EXCEPTION 'match is not active'; END IF;
  IF m.suspended_by IS NULL THEN RAISE EXCEPTION 'journey_not_paused'; END IF;

  -- DR-ZYRA-170: you lift only YOUR OWN hold. This replaces "only the
  -- suspending Seeker may resume" — under shared holds nobody resumes
  -- anybody else, and nobody asks.
  IF caller IS DISTINCT FROM m.suspended_by
     AND caller IS DISTINCT FROM m.also_paused_by THEN
    RAISE EXCEPTION 'no_hold_to_lift'
      USING HINT = 'Only your own pause is yours to lift.';
  END IF;

  other_id := CASE WHEN m.seeker_a_id = caller THEN m.seeker_b_id ELSE m.seeker_a_id END;
  SELECT first_name INTO v_name FROM profiles WHERE id = caller;
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status <> 'ended'
   ORDER BY (a.status='active') DESC, a.attempt_number DESC LIMIT 1;

  -- SECONDARY LIFT — the Journey stays paused on the primary hold. Your
  -- lift IS your standing "I'm ready": pause_nudged_at is set (only one
  -- non-holder can exist, so the flag is unambiguous) and the existing
  -- pause_nudge notification carries the word. No Timeline event — the
  -- Journey's own state never moved.
  IF caller IS NOT DISTINCT FROM m.also_paused_by THEN
    UPDATE matches SET also_paused_by=NULL, also_paused_at=NULL,
                       pause_nudged_at=NOW() WHERE id=p_match_id;
    UPDATE journey_attempts SET also_paused_by=NULL, also_paused_at=NULL
     WHERE v_attempt IS NOT NULL AND id=v_attempt;
    PERFORM create_notification(
      m.suspended_by, 'pause_nudge', 'Whenever you are ready',
      coalesce(v_name, 'They') || ' is ready to continue, whenever you are.',
      p_match_id);
    RETURN;
  END IF;

  -- caller holds the PRIMARY from here.
  IF m.also_paused_by IS NOT NULL THEN
    -- PROMOTION — their hold becomes the (only) hold, keeping THEIR
    -- original hold time; the Journey stays paused. suspended_by never
    -- touches NULL, so the milestone trigger stays silent — verified
    -- against its live body. The lifter's ready signal stands the same
    -- way a secondary lift's does.
    UPDATE matches SET suspended_by = m.also_paused_by,
                       suspended_at = coalesce(m.also_paused_at, NOW()),
                       also_paused_by = NULL, also_paused_at = NULL,
                       pause_nudged_at = NOW()
     WHERE id = p_match_id;
    UPDATE journey_attempts SET paused_by = m.also_paused_by,
                       paused_at = coalesce(m.also_paused_at, NOW()),
                       also_paused_by = NULL, also_paused_at = NULL
     WHERE v_attempt IS NOT NULL AND id = v_attempt;
    PERFORM create_notification(
      m.also_paused_by, 'pause_nudge', 'Whenever you are ready',
      coalesce(v_name, 'They') || ' is ready to continue, whenever you are.',
      p_match_id);
    RETURN;
  END IF;

  -- FINAL LIFT — the Journey goes active. Eligibility and slot checks
  -- unchanged from the 2026-08-08/12 rulings (OA-ZYRA-174; pause frees
  -- the slot, plan-aware caps).
  IF NOT public.zyra_can_continue_journey(m.seeker_a_id, m.seeker_b_id) THEN
    RAISE EXCEPTION 'not_eligible_to_continue'
      USING HINT='This Journey cannot resume: one of you has blocked the '
                 'other, or one of you is now the other''s Guardian.';
  END IF;
  IF zyra_active_journey_count(caller, p_match_id) >= zyra_active_journey_cap(caller) THEN
    RAISE EXCEPTION 'self_in_active_journey'
      USING HINT='You are at your plan''s Active Journey limit. Pause or '
                 'end one first — then resume this one.';
  END IF;
  IF zyra_active_journey_count(other_id, p_match_id) >= zyra_active_journey_cap(other_id) THEN
    RAISE EXCEPTION 'other_party_in_active_journey'
      USING HINT='This Journey stays paused for now. You can wait, or end it '
                 'yourself if you would rather.';
  END IF;

  -- pause_nudged_at cleared: the flag is per-episode and the episode is
  -- over (DR-ZYRA-142).
  UPDATE matches SET suspended_by = NULL, suspended_at = NULL,
                     pause_nudged_at = NULL WHERE id = p_match_id;
  UPDATE journey_attempts SET paused_by = NULL, paused_at = NULL
   WHERE v_attempt IS NOT NULL AND id = v_attempt;
  UPDATE conversations SET status='active'
   WHERE v_attempt IS NOT NULL AND attempt_id = v_attempt AND status='paused';

  -- The silent re-activation ends here: the other person is TOLD the
  -- Journey is active again (they used to just find it moved).
  PERFORM create_notification(
    other_id, 'journey_continued', 'Your Journey continues',
    coalesce(v_name, 'They') || ' has lifted their pause — your Journey together is active again.',
    p_match_id);
END; $function$;

-- ── nudge: defence-in-depth for the second holder ──
CREATE OR REPLACE FUNCTION public.nudge_paused_journey(p_match_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare m record; caller uuid := auth.uid(); v_name text;
begin
  if caller is null then raise exception 'not_signed_in'; end if;
  select * into m from matches where id = p_match_id;
  if not found then raise exception 'match not found'; end if;
  if caller <> m.seeker_a_id and caller <> m.seeker_b_id then
    raise exception 'not a party to this match';
  end if;
  if m.status <> 'active' or m.suspended_by is null then
    raise exception 'journey_not_paused';
  end if;
  -- A holder has no use for a nudge — their button is Resume. EXTENDED
  -- 2026-08-15 (DR-ZYRA-170) to cover the second hold: with both hands
  -- holding there is nobody left to nudge.
  if caller is not distinct from m.suspended_by
     or caller is not distinct from m.also_paused_by then
    raise exception 'pauser_cannot_nudge';
  end if;
  -- ONE per episode. The client greys its button from the same flag, so
  -- reaching this is a race or a stale screen, not a normal path.
  if m.pause_nudged_at is not null then
    raise exception 'already_nudged'
      using hint = 'One nudge per pause — they already know you are ready.';
  end if;

  update matches set pause_nudged_at = now() where id = p_match_id;

  -- One notification to the PAUSER alone. No wali copy — Guardian-silent
  -- is part of the decision: a whisper, not a family event.
  select first_name into v_name from profiles where id = caller;
  perform create_notification(
    m.suspended_by, 'pause_nudge', 'Whenever you are ready',
    coalesce(v_name, 'They') || ' is ready to continue, whenever you are.',
    p_match_id);
end $function$;
