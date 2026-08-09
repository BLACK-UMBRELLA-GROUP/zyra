-- AUDIT FINDING 2.2 — open_family_review accepted ANY stage pair.
--
-- zyra_advance_stage() enforces a fixed successor map and refuses the four
-- gated transitions with a hint naming the safe alternative:
--   'This transition opens a Family Review Period. Call
--    open_family_review() instead.'
-- That alternative validated nothing. It never referenced journey_stage,
-- and there is no CHECK constraint on from_stage or to_stage.
--
-- THE ATTACK, one Seeker acting alone:
--   open_family_review(match, 'compatibility_reveal', 'conversation')
--   wait 48 hours
--   resolve_family_review_if_due(match)
-- and the pair is in Open Conversation with the chat live, having skipped
-- the Salam Exchange, BOTH Guardian gates, all three phases and the Family
-- Compatibility stage. No Guardian voted. The other Seeker never consented.
--
-- ── WHAT IS ADDED TO open_family_review. Parity with zyra_advance_stage,
-- which is the point: two doors into the same state machine should not
-- enforce different rules.
--   1. FOR UPDATE on the match, so two callers cannot race.
--   2. status must be 'active'          -> journey_not_active
--   3. suspended_by must be NULL        -> journey_paused
--   4. journey_stage must equal
--      p_from_stage                     -> stage_moved
--   5. p_from_stage must be one of the
--      FOUR gated stages                -> not_a_gated_transition
--      (with a hint pointing back at zyra_advance_stage — the mirror
--       image of the hint that points here, so the two functions now
--       redirect to each other correctly instead of only one way)
--   6. p_to_stage must be THE successor
--      of p_from_stage                  -> invalid_transition
--
-- The successor map is written out rather than derived, and it is the
-- same one zyra_advance_stage refuses:
--   phase_1 -> phase_2 -> phase_3 -> family_stage -> conversation
--
-- ── WHAT IS ADDED TO resolve_family_review_if_due.
--   · Do not resolve on an ended or paused Journey.
--   · STALENESS GUARD: do not apply a review whose from_stage no longer
--     matches the Journey's current stage. A review is a decision about a
--     specific moment; if the Journey has moved since, the premise is
--     gone. It returns without acting rather than guessing, leaving the
--     row visible to a human. With validation 4 above in place this should
--     now be unreachable except by a direct database write, which is
--     exactly when you want it.
--
-- ── WHAT IS DELIBERATELY NOT CHANGED, so nobody thinks it was missed:
--
--   · ONE SEEKER CAN STILL OPEN A REVIEW AND HAVE IT AUTO-CONTINUE after
--     48 hours with no Guardian input. That is the DESIGN, not the defect
--     — the screen says so in as many words: "Unless you or [X]'s other
--     Guardian raises a concern, the Journey continues automatically in
--     [time]." Silence is consent here. The defect was the SKIP, and the
--     skip is what this migration closes.
--
--   · No check that both Seekers submitted their phase answers, or that a
--     Main Guardian still exists to review. Both are real questions and
--     both are PRODUCT decisions, not bug fixes. The second overlaps
--     OA-ZYRA-173 (removing your last Guardian mid-Journey). Raised, not
--     guessed — CLAUDE.md §3c step 6.
--
-- ── MIGRATION RISK: NONE. Measured immediately before applying — 0 rows
-- in journey_family_reviews, and all four client call sites already pass
-- exactly the four legal pairs (journey_flow_screen.dart:330-336).

CREATE OR REPLACE FUNCTION public.open_family_review(p_match_id uuid, p_from_stage text, p_to_stage text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  m RECORD;
  caller UUID := auth.uid();
  v_attempt UUID;
  v_expected_to TEXT;
  existing_id UUID;
  new_id UUID;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;

  -- ── LIFECYCLE, 2026-08-09 (audit 2.2). Same three tests zyra_advance_stage
  -- applies before it will move anything.
  IF m.status <> 'active' THEN
    RAISE EXCEPTION 'journey_not_active';
  END IF;
  IF m.suspended_by IS NOT NULL THEN
    RAISE EXCEPTION 'journey_paused';
  END IF;
  IF m.journey_stage IS DISTINCT FROM p_from_stage THEN
    RAISE EXCEPTION 'stage_moved'
      USING HINT = 'This Journey is no longer at that stage. Reload before continuing.';
  END IF;

  -- ── THE TRANSITION MUST BE ONE OF THE FOUR GATED ONES, and p_to_stage
  -- must be its real successor. Previously both were accepted verbatim.
  IF p_from_stage NOT IN ('phase_1','phase_2','phase_3','family_stage') THEN
    RAISE EXCEPTION 'not_a_gated_transition'
      USING HINT = 'This transition does not open a Family Review Period. '
                   'Call zyra_advance_stage() instead.';
  END IF;

  v_expected_to := CASE p_from_stage
                     WHEN 'phase_1'      THEN 'phase_2'
                     WHEN 'phase_2'      THEN 'phase_3'
                     WHEN 'phase_3'      THEN 'family_stage'
                     WHEN 'family_stage' THEN 'conversation'
                   END;

  IF p_to_stage IS DISTINCT FROM v_expected_to THEN
    RAISE EXCEPTION 'invalid_transition'
      USING HINT = format('A Family Review from %s can only lead to %s.',
                          p_from_stage, v_expected_to);
  END IF;

  -- Resolve the attempt this review belongs to. Same selection rule as
  -- zyra_set_attempt_from_match(), stated here because this function now
  -- writes attempt_id explicitly rather than leaving it to the trigger.
  SELECT a.id INTO v_attempt
  FROM journey_attempts a
  WHERE a.match_id = p_match_id
  ORDER BY (a.status = 'active') DESC, a.attempt_number DESC
  LIMIT 1;
  IF v_attempt IS NULL THEN RAISE EXCEPTION 'no_attempt_for_match'; END IF;

  -- Idempotency now keyed on the ATTEMPT, not the match. Identical today
  -- (one attempt per match); correct once a pair can have several.
  SELECT id INTO existing_id FROM journey_family_reviews
    WHERE attempt_id = v_attempt AND status = 'pending';
  IF existing_id IS NOT NULL THEN
    RETURN existing_id;
  END IF;

  INSERT INTO journey_family_reviews (match_id, attempt_id, from_stage, to_stage, deadline_at)
    VALUES (p_match_id, v_attempt, p_from_stage, p_to_stage, NOW() + INTERVAL '48 hours')
    RETURNING id INTO new_id;
  RETURN new_id;
END;
$function$;


CREATE OR REPLACE FUNCTION public.resolve_family_review_if_due(p_match_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  r RECORD;
  caller UUID := auth.uid();
  m RECORD;
  v_attempt UUID;
  is_party BOOLEAN;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id FOR UPDATE;
  IF NOT FOUND THEN RETURN; END IF;

  -- UNCHANGED authorisation: a party, or a Main Guardian of either side.
  is_party := caller IS NOT NULL AND (caller = m.seeker_a_id OR caller = m.seeker_b_id);
  IF NOT is_party AND NOT EXISTS (
    SELECT 1 FROM wali_links WHERE wali_id = caller AND status = 'active' AND is_main = TRUE
      AND seeker_id IN (m.seeker_a_id, m.seeker_b_id)
  ) THEN
    RETURN;
  END IF;

  -- ── LIFECYCLE, 2026-08-09 (audit 2.2). A timer must not carry an ended
  -- or paused Journey forward. Paused simply defers: the next call after
  -- a resume will resolve it.
  IF m.status <> 'active' OR m.suspended_by IS NOT NULL THEN RETURN; END IF;

  SELECT a.id INTO v_attempt
  FROM journey_attempts a
  WHERE a.match_id = p_match_id
  ORDER BY (a.status = 'active') DESC, a.attempt_number DESC
  LIMIT 1;
  IF v_attempt IS NULL THEN RETURN; END IF;

  SELECT * INTO r FROM journey_family_reviews
    WHERE attempt_id = v_attempt AND status = 'pending' AND deadline_at <= NOW();
  IF NOT FOUND THEN RETURN; END IF;

  -- ── STALENESS GUARD, 2026-08-09 (audit 2.2). A review is a decision
  -- about one specific moment in the Journey. If the stage has moved since
  -- it was opened, the premise is gone — do nothing and leave the row for
  -- a human, rather than teleporting the Journey to a stale destination.
  IF m.journey_stage IS DISTINCT FROM r.from_stage THEN RETURN; END IF;

  UPDATE journey_family_reviews SET status = 'continued', resolved_at = NOW() WHERE id = r.id;
  UPDATE matches          SET journey_stage = r.to_stage WHERE id = p_match_id;
  UPDATE journey_attempts SET journey_stage = r.to_stage WHERE id = v_attempt;
  IF r.to_stage = 'conversation' THEN
    UPDATE conversations SET status = 'active' WHERE attempt_id = v_attempt;
  END IF;
END;
$function$;
