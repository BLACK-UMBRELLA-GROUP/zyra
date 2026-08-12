-- ELEVENTH DEV-ONLY FUNCTION. Drop with the other ten before public launch
-- (OA-ZYRA-184). Refuses for anything that is not a seeded @zyra.test account.
--
-- WHY: the Journey is built end to end and none of it could be walked alone.
-- Every stage from the Salam onwards is a MUTUAL act by design — that is the
-- product, not a defect — so a solo tester reaches "Waiting for their
-- answers" at stage two and stops. Six of the eight stages had therefore
-- never been seen running, only read.
--
-- This does the OTHER party's half of whatever stage the Journey is standing
-- on, and nothing else. It does not skip a stage, does not advance the
-- Journey, and does not touch the caller's own half: the tester still presses
-- their own buttons and still sees their own waiting states. What ends is the
-- wait for a person who is never going to open the app.
--
-- The Family Review is resolved by pulling its deadline back and calling
-- resolve_family_review_if_due() — the REAL resolution path, not a second
-- copy of it. A dev tool that advanced the stage itself would be testing
-- itself rather than the product.
--
-- File name kept as the "fix" because that is the version recorded remotely;
-- see 20260811094513 for what it corrected.
CREATE OR REPLACE FUNCTION public.zyra_dev_counterpart_complete(
  p_match_id     uuid,
  p_question_ids text[] DEFAULT '{}'::text[]
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  caller     UUID := (SELECT auth.uid());
  v_email    TEXT;
  m          RECORD;
  v_other    UUID;
  v_attempt  UUID;
  v_phase    INT;
  v_guardian UUID;
  v_answerer UUID;
  v_qid      TEXT;
  v_seeker   UUID;
  n          INT := 0;
  did        TEXT;
  -- Plausible answers, so the simultaneous-reveal screen shows something a
  -- person could have written. A column of "test test test" would render the
  -- reveal correctly and tell you nothing about whether it reads well.
  v_samples  TEXT[] := ARRAY[
    'I keep my five prayers at the centre of the day and try to build everything else around them.',
    'Honestly, some weeks are stronger than others — but I have never let it slip entirely, and I would want a home where we hold each other to it gently.',
    'I am looking for someone to build a settled life with, not to date indefinitely. I would want to move at a considered pace but with a clear intention.',
    'Kindness first, then honesty. If someone is unkind when they are tired or under pressure, everything else is decoration.',
    'I would want us to live near enough to family to be present, but with our own front door.',
    'Two or three, God willing, and I would rather not wait many years — though I know that is not entirely ours to decide.',
    'I would want us both to be able to speak plainly when something is wrong, rather than letting it sit for a week.',
    'My work matters to me and I would not want to give it up, but I do not want it to be the loudest thing in the house.',
    'I would rather we decide money together and neither of us feels they are asking permission.',
    'I go quiet when I am upset, which I know is not always fair. It is the thing I am working on most.'
  ];
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Simulating the other party is limited to seeded @zyra.test accounts.';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;
  IF m.status <> 'active' THEN
    RAISE EXCEPTION 'journey_not_active'
      USING HINT = 'Only an Active Journey has a stage to complete.';
  END IF;

  v_other := CASE WHEN caller = m.seeker_a_id THEN m.seeker_b_id ELSE m.seeker_a_id END;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id
   ORDER BY (a.status = 'active') DESC, a.attempt_number DESC LIMIT 1;
  IF v_attempt IS NULL THEN RAISE EXCEPTION 'no_attempt_for_match'; END IF;

  -- The conversation and timeline rows are normally created by
  -- create_match_on_mutual_like(). A match seeded straight into the table has
  -- neither, so Open Conversation opens onto nothing at the end of an
  -- otherwise perfect walk-through. Created here, idempotently, at whatever
  -- stage this is first called: 'closed' until the Journey earns 'active',
  -- which resolve_family_review_if_due() sets on the real path.
  INSERT INTO conversations (match_id, attempt_id, status)
  VALUES (p_match_id, v_attempt,
          CASE WHEN m.journey_stage = 'conversation' THEN 'active' ELSE 'closed' END)
  ON CONFLICT (attempt_id) DO NOTHING;

  INSERT INTO timelines (match_id, attempt_id)
  VALUES (p_match_id, v_attempt)
  ON CONFLICT (attempt_id) DO NOTHING;

  IF m.journey_stage = 'compatibility_reveal' THEN

    INSERT INTO journey_compatibility (match_id) VALUES (p_match_id)
    ON CONFLICT (match_id) DO NOTHING;

    IF v_other = m.seeker_a_id THEN
      UPDATE journey_compatibility SET seeker_a_revealed = TRUE WHERE match_id = p_match_id;
    ELSE
      UPDATE journey_compatibility SET seeker_b_revealed = TRUE WHERE match_id = p_match_id;
    END IF;

    -- zyra_advance_stage() needs BOTH a reveal and a Continue from each side.
    INSERT INTO journey_stage_checkpoints (match_id, stage, seeker_id)
    VALUES (p_match_id, 'compatibility_reveal', v_other)
    ON CONFLICT DO NOTHING;

    did := 'They revealed their compatibility and chose to continue.';

  ELSIF m.journey_stage = 'salam_exchange' THEN

    INSERT INTO journey_salams (match_id, seeker_id) VALUES (p_match_id, v_other)
    ON CONFLICT DO NOTHING;
    did := 'They sent their Salam.';

  ELSIF m.journey_stage = 'wali_gate' THEN

    -- Not a "half" — the Guardian Gate is a precondition on BOTH Seekers
    -- (zyra_advance_stage returns guardian_required_self /
    -- guardian_required_other), so both are satisfied here or the gate is
    -- still shut and this button would appear to do nothing.
    SELECT id INTO v_guardian FROM auth.users WHERE email = 'dev.guardian.a@zyra.test';
    IF v_guardian IS NULL THEN
      RAISE EXCEPTION 'no_dev_guardian'
        USING HINT = 'Seed dev.guardian.a@zyra.test before using the Guardian Gate.';
    END IF;

    FOREACH v_seeker IN ARRAY ARRAY[m.seeker_a_id, m.seeker_b_id] LOOP
      IF NOT EXISTS (SELECT 1 FROM wali_links wl
                      WHERE wl.seeker_id = v_seeker AND wl.is_main AND wl.status = 'active') THEN
        INSERT INTO wali_links (seeker_id, wali_id, status, is_main, relationship)
        VALUES (v_seeker, v_guardian, 'active', TRUE, 'father')
        ON CONFLICT (seeker_id, wali_id)
        DO UPDATE SET status = 'active', is_main = TRUE;
        n := n + 1;
      END IF;
    END LOOP;

    did := CASE WHEN n = 0
      THEN 'Both of you already have a linked Guardian — the gate is open.'
      ELSE format('Linked a Main Guardian for %s of you.', n) END;

  ELSIF m.journey_stage IN ('phase_1', 'phase_2', 'phase_3') THEN

    v_phase := substring(m.journey_stage from 7)::INT;

    FOREACH v_qid IN ARRAY p_question_ids LOOP
      INSERT INTO journey_phase_answers (match_id, phase, seeker_id, question_id, answer_text)
      VALUES (p_match_id, v_phase, v_other, v_qid,
              v_samples[1 + (n % array_length(v_samples, 1))])
      ON CONFLICT (match_id, phase, seeker_id, question_id) DO NOTHING;
      n := n + 1;
    END LOOP;

    -- Their Continue at the phase checkpoint. Harmless before the reveal:
    -- the client only reads checkpoints once both sides have submitted.
    INSERT INTO journey_phase_checkpoints (match_id, phase, seeker_id, decision)
    VALUES (p_match_id, v_phase, v_other, 'continue')
    ON CONFLICT (match_id, phase, seeker_id) DO NOTHING;

    did := format('They answered %s question(s) and chose to continue.', n);

  ELSIF m.journey_stage = 'family_stage' THEN

    -- The Seeker answers 'wali_to_seeker'; the screen then waits on
    -- 'seeker_to_wali', which is the GUARDIAN's side and has no Guardian-app
    -- screen behind it yet. The answerer is the caller's own Main Guardian
    -- where one exists, so the row is attributed to a real person.
    SELECT wl.wali_id INTO v_answerer FROM wali_links wl
     WHERE wl.seeker_id = caller AND wl.is_main AND wl.status = 'active' LIMIT 1;
    IF v_answerer IS NULL THEN
      SELECT id INTO v_answerer FROM auth.users WHERE email = 'dev.guardian.a@zyra.test';
    END IF;
    IF v_answerer IS NULL THEN RAISE EXCEPTION 'no_dev_guardian'; END IF;

    FOREACH v_qid IN ARRAY p_question_ids LOOP
      INSERT INTO journey_family_answers (match_id, direction, question_id, answerer_id, answer_text)
      VALUES (p_match_id, 'seeker_to_wali', v_qid, v_answerer,
              v_samples[1 + (n % array_length(v_samples, 1))])
      ON CONFLICT (match_id, direction, question_id, answerer_id) DO NOTHING;
      n := n + 1;
    END LOOP;

    did := format('Their Guardian answered %s question(s).', n);

  ELSIF m.journey_stage = 'conversation' THEN
    UPDATE conversations SET status = 'active', closed_at = NULL WHERE attempt_id = v_attempt;
    did := 'Already at Open Conversation — nothing left to wait for.';
  ELSE
    did := format('Nothing to do at %s.', coalesce(m.journey_stage, 'no stage'));
  END IF;

  -- A pending Family Review is the other thing that stalls a solo walk: it
  -- opens on four transitions and clears itself after 48 hours. Bring the
  -- deadline forward and let the REAL resolver run, so what is being tested
  -- is resolve_family_review_if_due() and not this function.
  IF EXISTS (SELECT 1 FROM journey_family_reviews
              WHERE attempt_id = v_attempt AND status = 'pending') THEN
    UPDATE journey_family_reviews
       SET deadline_at = NOW() - INTERVAL '1 minute'
     WHERE attempt_id = v_attempt AND status = 'pending';
    PERFORM resolve_family_review_if_due(p_match_id);
    did := did || ' The Family Review period closed and the Journey moved on.';
  END IF;

  RETURN did;
END;
$function$;

REVOKE ALL ON FUNCTION public.zyra_dev_counterpart_complete(uuid, text[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.zyra_dev_counterpart_complete(uuid, text[]) TO authenticated;

COMMENT ON FUNCTION public.zyra_dev_counterpart_complete(uuid, text[]) IS
  'DEV ONLY (@zyra.test). Completes the other party''s half of the current Journey stage so the flow can be walked alone. Drop before public launch — OA-ZYRA-184.';
