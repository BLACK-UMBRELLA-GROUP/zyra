-- OA-ZYRA-200: extend the both-parties @zyra.test guard (pattern from
-- 20260811233914, which fixed the destructive pair) to the three
-- shared-row dev setters. They already guard the CALLER and party
-- membership; this adds the assertion that the OTHER party is seeded too,
-- so a test account can never mutate a match involving a real account.
-- Stricter form than the sibling pattern: count(*) < 2 also treats a
-- missing auth.users row as unseeded rather than silently passing.
--
-- Applied to the live project 2026-08-20 as version 20260820200633
-- (supabase_migrations.schema_migrations). This repo file is the
-- OA-ZYRA-198-discipline copy of exactly what was applied.

CREATE OR REPLACE FUNCTION public.zyra_dev_set_compatibility(p_match_id uuid, p_score numeric)
 RETURNS numeric
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  caller  UUID := (SELECT auth.uid());
  v_email TEXT;
  m       RECORD;
  v_cats  JSONB;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Forcing a compatibility score is limited to seeded @zyra.test accounts.';
  END IF;

  IF p_score < 0 OR p_score > 100 THEN
    RAISE EXCEPTION 'score_out_of_range' USING HINT = '0 to 100.';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;

  -- GUARD BOTH PARTIES (2026-08-20, OA-ZYRA-200): this writes the shared
  -- journey_compatibility row for BOTH sides, so both parties must be
  -- seeded accounts, not just the caller.
  IF (SELECT count(*) FROM auth.users u
       WHERE u.id IN (m.seeker_a_id, m.seeker_b_id)
         AND u.email LIKE '%@zyra.test') < 2 THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Every party of the match must be a seeded @zyra.test account.';
  END IF;

  v_cats := jsonb_build_object(
    'Deen',                least(100, greatest(0, p_score + 7)),
    'Marriage Goals',      least(100, greatest(0, p_score + 3)),
    'Communication',       least(100, greatest(0, p_score - 4)),
    'Lifestyle',           least(100, greatest(0, p_score - 9)),
    'Family Expectations', least(100, greatest(0, p_score + 1))
  );

  INSERT INTO journey_compatibility (match_id) VALUES (p_match_id)
  ON CONFLICT (match_id) DO NOTHING;

  -- BOTH sides set to the same figure, deliberately. This is a dev fixture
  -- for looking at a screen, not a simulation of the engine — and setting
  -- only the caller's would leave the other account showing nothing when
  -- the Founder switches to it to check the other half.
  UPDATE journey_compatibility
     SET seeker_a_score      = p_score,
         seeker_b_score      = p_score,
         seeker_a_categories = v_cats,
         seeker_b_categories = v_cats,
         seeker_a_revealed   = TRUE,
         seeker_b_revealed   = TRUE,
         revealed_at         = now()
   WHERE match_id = p_match_id;

  RETURN p_score;
END;
$function$;

CREATE OR REPLACE FUNCTION public.zyra_dev_set_counterpart_reveal(p_match_id uuid, p_revealed boolean)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  caller  UUID := (SELECT auth.uid());
  v_email TEXT;
  m       RECORD;
  v_col   TEXT;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Counterpart reveal is limited to seeded @zyra.test accounts.';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;

  -- GUARD BOTH PARTIES (2026-08-20, OA-ZYRA-200): this sets the
  -- COUNTERPART's reveal flag — a write on the other person — so the
  -- other party must be a seeded account too.
  IF (SELECT count(*) FROM auth.users u
       WHERE u.id IN (m.seeker_a_id, m.seeker_b_id)
         AND u.email LIKE '%@zyra.test') < 2 THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Every party of the match must be a seeded @zyra.test account.';
  END IF;

  -- The COUNTERPART's column, never the caller's. If the caller is A we set
  -- B, and the other way round. Getting this backwards would make the toggle
  -- silently set your own flag and look like it worked.
  v_col := CASE WHEN caller = m.seeker_a_id
                THEN 'seeker_b_revealed' ELSE 'seeker_a_revealed' END;

  INSERT INTO journey_compatibility (match_id) VALUES (p_match_id)
  ON CONFLICT (match_id) DO NOTHING;

  EXECUTE format('UPDATE journey_compatibility SET %I = $1 WHERE match_id = $2', v_col)
    USING p_revealed, p_match_id;

  RETURN p_revealed;
END;
$function$;

CREATE OR REPLACE FUNCTION public.zyra_dev_set_journey_stage(p_match_id uuid, p_stage text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  caller  UUID := (SELECT auth.uid());
  v_email TEXT;
  m       RECORD;
  v_attempt UUID;
BEGIN
  IF caller IS NULL THEN RAISE EXCEPTION 'not_signed_in'; END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Stage jumping is limited to seeded @zyra.test accounts.';
  END IF;

  IF p_stage NOT IN ('compatibility_reveal','salam_exchange','wali_gate',
                     'phase_1','phase_2','phase_3','family_stage','conversation') THEN
    RAISE EXCEPTION 'unknown_stage'
      USING HINT = 'Stage must be one of the eight in zyra_journey_stages.dart.';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;

  -- GUARD BOTH PARTIES (2026-08-20, OA-ZYRA-200): stage jumps rewrite the
  -- shared match / journey_attempts / conversations rows, so both parties
  -- must be seeded accounts.
  IF (SELECT count(*) FROM auth.users u
       WHERE u.id IN (m.seeker_a_id, m.seeker_b_id)
         AND u.email LIKE '%@zyra.test') < 2 THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Every party of the match must be a seeded @zyra.test account.';
  END IF;

  IF m.status <> 'active' THEN
    RAISE EXCEPTION 'journey_not_active'
      USING HINT = 'Only an Active Journey has stages to jump between.';
  END IF;

  UPDATE matches SET journey_stage = p_stage WHERE id = p_match_id;

  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id AND a.status = 'active'
   ORDER BY a.attempt_number DESC LIMIT 1;

  IF v_attempt IS NULL THEN
    RAISE EXCEPTION 'no_active_attempt'
      USING HINT = 'The Journey is active but has no active attempt row.';
  END IF;

  UPDATE journey_attempts SET journey_stage = p_stage WHERE id = v_attempt;

  -- CHANGED IN STAGE 4a: conflict target is now attempt_id, and attempt_id is
  -- NOT NULL, so v_attempt is required rather than optional. Previously this
  -- inserted with a possibly-NULL attempt_id and conflicted on match_id —
  -- both of which stopped being legal in the statements above.
  INSERT INTO conversations (match_id, attempt_id, status)
  VALUES (p_match_id, v_attempt, 'active')
  ON CONFLICT (attempt_id) DO UPDATE SET status = 'active', closed_at = NULL;

  INSERT INTO timelines (match_id, attempt_id)
  VALUES (p_match_id, v_attempt)
  ON CONFLICT (attempt_id) DO NOTHING;

  RETURN p_stage;
END;
$function$;
