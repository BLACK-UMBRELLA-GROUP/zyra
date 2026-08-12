-- ═══════════════════════════════════════════════════════════════════════
-- ONBOARDING DIRECTION B — STAGE 1
-- Hard Requirements become per-OPTION instead of per-QUESTION.
--
-- Founder decision 2026-08-10 (Direction B, from
-- SYSTEM/DOCUMENTS/ZYRA_ONBOARDING_DIRECTION_OPTIONS_2026-08-10.md).
-- Applied 2026-08-10. Verified 22/22.
--
-- WHY NOW AND NOT LATER. `onboarding_answers` has zero rows, verified
-- immediately before this ran. Today the reshape is a default change on an
-- empty table. After the first real signup it is a backfill that CANNOT be
-- done correctly: from {"ch3_q1": true} there is no way to recover WHICH red
-- option the person meant to exclude, so every multi-red hard requirement
-- would have to be widened (showing people they said never) or dropped
-- (hiding people they wanted to see). Neither is acceptable. The window
-- closes at first signup; this is the last cheap moment.
--
-- WHAT WAS WRONG. ch4_hard_requirements was {question_id: bool}, and
-- score_candidates() excluded on ANY red option of a flagged question. So on
-- ch3_q1 (Never Married / Separated / Divorced / Annulled / Widowed /
-- Currently Married) a Seeker could not say "Currently Married — never;
-- Divorced — I'd rather not, but I'd consider the right person". Ticking the
-- box excluded both. There was no third position, and the UI gave no hint
-- that the checkbox reached past the option the user was looking at.
--
-- THE SECOND CHANGE, AND IT IS NOT COSMETIC. The exclusion test used to sit
-- INSIDE the `v_light = 'red'` branch, so a hard requirement only fired if a
-- matching red light also existed. That coupling is a trap for the
-- dealbreakers-first screen (H3), which sets exclusions BEFORE the user has
-- walked the questions that would produce those lights — the dealbreaker
-- would have been silently inert. A hard requirement is a promise; it must
-- not depend on a second piece of state being in sync. It is now tested on
-- its own, before the light, and it no longer needs a light to exist.
--
-- NOT CHANGED: ch4_preferences (same {question: {option: light}} map), the
-- Chapter 2 block, v_ch2_weight (still 1, still a Founder decision, still
-- waiting on the 120-profile backfill), the H-3 zyra_can_view_profile guard,
-- and the 50.0 no-preferences path.
--
-- CHAPTER 2 DELIBERATELY NOT INCLUDED. seeker_details.preferences still holds
-- {sect: {hard_requirement: bool}} and the Chapter 2 block below still reads
-- it that way. 24 rows, 8 with the flag set — not free, and out of the scope
-- the Founder approved. Tracked as OA-ZYRA-185. The shared widget carries an
-- explicit HardRequirementScope so Chapter 2 keeps the coarse control rather
-- than showing a precise one the engine cannot honour.
-- ═══════════════════════════════════════════════════════════════════════

-- ── 1 · shape validator ────────────────────────────────────────────────
-- A CHECK constraint cannot contain a subquery, so the shape test has to
-- live in an IMMUTABLE function. KNOWN FOOTGUN, recorded deliberately:
-- CREATE OR REPLACE on this function does NOT revalidate existing rows.
-- If the accepted shape ever changes, drop the constraint, replace the
-- function, and re-add the constraint with a VALIDATE pass.
CREATE OR REPLACE FUNCTION public.zyra_ch4_hard_shape_ok(p jsonb)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
SET search_path TO 'public'
AS $$
  SELECT p IS NULL
      OR ( jsonb_typeof(p) = 'object'
       AND NOT EXISTS (
             SELECT 1
               FROM jsonb_each(p) e
              WHERE jsonb_typeof(e.value) <> 'array'
                 OR EXISTS ( SELECT 1
                               FROM jsonb_array_elements(e.value) a
                              WHERE jsonb_typeof(a) <> 'string' )
           ) );
$$;

COMMENT ON FUNCTION public.zyra_ch4_hard_shape_ok(jsonb) IS
  'Shape guard for onboarding_answers.ch4_hard_requirements. Accepts '
  '{question_id: [option_label, ...]} only. Exists so the retired '
  '{question_id: bool} shape cannot be written by an older client build — '
  'a silent old-shape write would read as "no hard requirement at all", '
  'which fails OPEN on a promise the Seeker made. Fail loudly instead.';

-- ── 2 · enforce it ─────────────────────────────────────────────────────
ALTER TABLE public.onboarding_answers
  DROP CONSTRAINT IF EXISTS onboarding_answers_ch4_hard_shape;
ALTER TABLE public.onboarding_answers
  ADD CONSTRAINT onboarding_answers_ch4_hard_shape
  CHECK (public.zyra_ch4_hard_shape_ok(ch4_hard_requirements));

COMMENT ON COLUMN public.onboarding_answers.ch4_hard_requirements IS
  'Per-OPTION hard exclusions: {question_id: [option_label, ...]}. An option '
  'listed here is never introduced, full stop — checked independently of '
  'ch4_preferences so a dealbreaker set before the questions are walked still '
  'binds. WAS {question_id: bool} until 2026-08-10, which could not express '
  '"never X, but I would consider Y" on the same question.';

-- ── 3 · the engine ─────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.score_candidates(p_candidate_ids uuid[])
 RETURNS TABLE(candidate_id uuid, score numeric)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_me UUID := auth.uid();
  v_my_prefs JSONB;
  v_my_hard JSONB;
  v_candidate_id UUID;
  v_ch3 JSONB;
  v_pref_rec RECORD;
  v_value TEXT;
  v_light TEXT;
  v_total INT;
  v_max INT;
  v_excluded BOOLEAN;
  v_my_ch2   JSONB;
  v_cand     RECORD;
  v_block    JSONB;
  v_pref_arr JSONB;
  -- OPEN, FOUNDER DECISION: 1 = one Chapter 2 attribute counts the same as
  -- one Chapter 3 question. See ZYRA_DECISIONS_CURRENT_VERSION_V2 §9.2.
  -- Deliberately untouched by the 2026-08-10 reshape.
  v_ch2_weight INT := 1;
BEGIN
  IF v_me IS NULL THEN
    RETURN;
  END IF;

  SELECT oa.ch4_preferences, oa.ch4_hard_requirements
    INTO v_my_prefs, v_my_hard
    FROM onboarding_answers oa
    WHERE oa.user_id = v_me;

  SELECT sd.preferences INTO v_my_ch2
    FROM seeker_details sd
    WHERE sd.user_id = v_me;

  v_my_prefs := COALESCE(v_my_prefs, '{}'::jsonb);
  v_my_ch2   := COALESCE(v_my_ch2,   '{}'::jsonb);
  v_my_hard  := COALESCE(v_my_hard,  '{}'::jsonb);

  -- A person who has set ONLY dealbreakers (H3 runs before the preference
  -- questions) has no ch4_preferences yet. Before 2026-08-10 they would have
  -- fallen through to the flat-50 path and their exclusions would have been
  -- ignored entirely — the exact failure the dealbreakers-first screen exists
  -- to avoid. v_my_hard now counts as having said something.
  IF v_my_prefs = '{}'::jsonb AND v_my_ch2 = '{}'::jsonb AND v_my_hard = '{}'::jsonb THEN
    FOREACH v_candidate_id IN ARRAY p_candidate_ids LOOP
      -- H-3 also applies on the no-preferences path. Without it, a caller
      -- with no answers could still confirm which UUIDs are visible.
      CONTINUE WHEN NOT public.zyra_can_view_profile(v_candidate_id);
      candidate_id := v_candidate_id;
      score := 50.0;
      RETURN NEXT;
    END LOOP;
    RETURN;
  END IF;

  FOREACH v_candidate_id IN ARRAY p_candidate_ids LOOP
    -- ===================== H-3, ADDED 2026-08-04 =====================
    -- Without this the function was an inference oracle: craft a
    -- preference matrix that scores green on exactly one sect, submit
    -- arbitrary UUIDs, and read a stranger's religious answers out of the
    -- score movements.
    CONTINUE WHEN NOT public.zyra_can_view_profile(v_candidate_id);
    -- =================================================================

    SELECT oa.ch3_answers INTO v_ch3 FROM onboarding_answers oa WHERE oa.user_id = v_candidate_id;
    v_ch3 := COALESCE(v_ch3, '{}'::jsonb);

    v_total := 0;
    v_max := 0;
    v_excluded := FALSE;

    -- ============== HARD EXCLUSIONS — CHECKED FIRST, ALONE ==============
    -- Independent of ch4_preferences by design (2026-08-10). Walks the
    -- HARD map, not the preference map, so an exclusion binds even when the
    -- matching preference question has never been shown.
    FOR v_pref_rec IN SELECT * FROM jsonb_each(v_my_hard) LOOP
      DECLARE
        v_answer JSONB := v_ch3 -> v_pref_rec.key;
      BEGIN
        CONTINUE WHEN v_answer IS NULL OR jsonb_typeof(v_answer) = 'null';

        IF jsonb_typeof(v_answer) = 'array' THEN
          -- Multi-select: ANY excluded value excludes the person.
          IF EXISTS (
            SELECT 1 FROM jsonb_array_elements_text(v_answer) t
             WHERE v_pref_rec.value ? t.value
          ) THEN
            v_excluded := TRUE;
          END IF;
        ELSE
          IF v_pref_rec.value ? (v_answer #>> '{}') THEN
            v_excluded := TRUE;
          END IF;
        END IF;
      END;

      EXIT WHEN v_excluded;
    END LOOP;

    IF v_excluded THEN
      CONTINUE;
    END IF;
    -- ====================================================================

    -- ================= CHAPTER 3/4 — SCORING ONLY =================
    -- No exclusion logic here any more. A red option that is NOT hard-listed
    -- scores -3 exactly as before; a red option that IS hard-listed never
    -- reaches this loop, because the block above already skipped the person.
    FOR v_pref_rec IN SELECT * FROM jsonb_each(v_my_prefs) LOOP
      DECLARE
        v_prefs_for_question JSONB := v_pref_rec.value;
        v_answer JSONB := v_ch3 -> v_pref_rec.key;
      BEGIN
        IF v_answer IS NULL OR jsonb_typeof(v_answer) = 'null' THEN
          CONTINUE;
        END IF;

        IF jsonb_typeof(v_answer) = 'array' THEN
          FOR v_value IN SELECT jsonb_array_elements_text(v_answer) LOOP
            v_light := v_prefs_for_question ->> v_value;
            IF v_light IS NULL THEN
              CONTINUE;
            END IF;
            v_max := v_max + 2;
            v_total := v_total + zyra_light_points(v_light);
          END LOOP;
        ELSE
          v_value := v_answer #>> '{}';
          v_light := v_prefs_for_question ->> v_value;
          IF v_light IS NOT NULL THEN
            v_max   := v_max   + 2;
            v_total := v_total + zyra_light_points(v_light);
          END IF;
        END IF;
      END;
    END LOOP;

    -- ================= CHAPTER 2 — UNCHANGED =================
    IF v_my_ch2 <> '{}'::jsonb THEN
      SELECT sd.sect, sd.revert_status, sd.country_of_birth,
             sd.nationality, sd.ethnicity, sd.languages
        INTO v_cand
        FROM seeker_details sd
        WHERE sd.user_id = v_candidate_id;

      IF FOUND THEN
        v_block := v_my_ch2 -> 'sect';
        IF v_block IS NOT NULL AND v_cand.sect IS NOT NULL THEN
          v_light := v_block -> 'matrix' ->> initcap(v_cand.sect);
          IF v_light IS NOT NULL THEN
            IF v_light = 'red' AND COALESCE((v_block ->> 'hard_requirement')::boolean, FALSE) THEN
              v_excluded := TRUE;
            ELSE
              v_max   := v_max   + 2 * v_ch2_weight;
              v_total := v_total + zyra_light_points(v_light) * v_ch2_weight;
            END IF;
          END IF;
        END IF;

        IF NOT v_excluded AND COALESCE(v_cand.revert_status, FALSE) THEN
          v_light := v_my_ch2 -> 'revert' ->> 'flexibility';
          IF v_light IS NOT NULL THEN
            v_max   := v_max   + 2 * v_ch2_weight;
            v_total := v_total + zyra_light_points(v_light) * v_ch2_weight;
          END IF;
        END IF;

        IF NOT v_excluded THEN
          FOR v_pref_rec IN
            SELECT * FROM (VALUES
              ('country_of_birth', v_cand.country_of_birth),
              ('nationality',      v_cand.nationality),
              ('ethnicity',        v_cand.ethnicity)
            ) AS t(key, cand_value)
          LOOP
            v_block := v_my_ch2 -> v_pref_rec.key;
            CONTINUE WHEN v_block IS NULL
                       OR COALESCE((v_block ->> 'skipped')::boolean, FALSE)
                       OR v_pref_rec.cand_value IS NULL;

            v_pref_arr := v_block -> 'preferred';
            IF v_pref_arr IS NULL OR jsonb_array_length(v_pref_arr) = 0 THEN
              CONTINUE;
            END IF;

            IF v_pref_arr ? v_pref_rec.cand_value THEN
              v_light := 'green';
            ELSE
              v_light := v_block ->> 'flexibility';
            END IF;

            IF v_light IS NOT NULL THEN
              v_max   := v_max   + 2 * v_ch2_weight;
              v_total := v_total + zyra_light_points(v_light) * v_ch2_weight;
            END IF;
          END LOOP;

          v_block := v_my_ch2 -> 'languages';
          IF v_block IS NOT NULL
             AND NOT COALESCE((v_block ->> 'skipped')::boolean, FALSE)
             AND v_cand.languages IS NOT NULL
             AND array_length(v_cand.languages, 1) > 0 THEN
            v_pref_arr := v_block -> 'preferred';
            IF v_pref_arr IS NOT NULL AND jsonb_array_length(v_pref_arr) > 0 THEN
              IF EXISTS (
                SELECT 1 FROM jsonb_array_elements_text(v_pref_arr) p
                WHERE p = ANY (v_cand.languages)
              ) THEN
                v_light := 'green';
              ELSE
                v_light := v_block ->> 'flexibility';
              END IF;
              IF v_light IS NOT NULL THEN
                v_max   := v_max   + 2 * v_ch2_weight;
                v_total := v_total + zyra_light_points(v_light) * v_ch2_weight;
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
    END IF;

    IF v_excluded THEN
      CONTINUE;
    END IF;

    candidate_id := v_candidate_id;
    IF v_max = 0 THEN
      score := 50.0;
    ELSE
      score := LEAST(100, GREATEST(0, ((v_total::numeric / v_max) * 50) + 50));
    END IF;
    RETURN NEXT;
  END LOOP;
END;
$function$;
