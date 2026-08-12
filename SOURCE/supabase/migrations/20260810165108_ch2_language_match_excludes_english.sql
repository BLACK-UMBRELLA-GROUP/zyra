-- ═══════════════════════════════════════════════════════════════════════
-- CHAPTER 2 · the language match no longer counts English.
--
-- Founder decision 2026-08-10, from SYSTEM/DOCUMENTS/
-- ZYRA_CHAPTER2_BACKFILL_AND_WEIGHT_FINDINGS_2026-08-10.md §5.
-- Applied 2026-08-10.
--
-- WHY. Measured over 10,368 real pairs after the UK-representative Chapter 2
-- backfill: English appears in 100% of profiles AND 100% of preference
-- lists. The rule greened on ANY match, so it returned green on EVERY pair —
-- +2 to the numerator and +2 to the denominator, every time. It was 26% of
-- Chapter 2's entire scored mass, it could not tell any two people apart,
-- and it dragged every score toward 100.
--
-- Simulated removal of the term raised the spread by 43% (σ 5.95 → 8.54) and
-- dropped the floor from 50 to 25 with the top unchanged. This does the same
-- thing more precisely: the attribute is kept for the people it means
-- something to — those who want a shared heritage language — and stops
-- paying out for a language everyone in this market already shares.
--
-- Measured live after this migration, 40 viewers × ~68 candidates:
--   mean score            96.0 → 94.1
--   spread per viewer     11.4 → 13.2  (+16%)
--
-- THE SUBTLE PART, AND IT IS THE WHOLE FIX. If a Seeker's preferred list is
-- ONLY English, the attribute is now SKIPPED rather than scored as a miss.
-- Falling through to `flexibility` would punish candidates for failing to
-- match a preference that no longer contains anything — turning a
-- meaningless green into a meaningless yellow, which is worse.
--
-- NOT CHANGED. v_ch2_weight is still 1, deliberately. It should be revisited
-- only once Chapter 3/4 data exists to measure it against — see CLAUDE.md.
-- Everything else in this function is byte-identical to migration
-- 20260810154645; only the languages block moved.
-- ═══════════════════════════════════════════════════════════════════════

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

          -- ── LANGUAGES · ENGLISH EXCLUDED, 2026-08-10 ──────────────────
          v_block := v_my_ch2 -> 'languages';
          IF v_block IS NOT NULL
             AND NOT COALESCE((v_block ->> 'skipped')::boolean, FALSE)
             AND v_cand.languages IS NOT NULL
             AND array_length(v_cand.languages, 1) > 0 THEN

            -- Strip English from the PREFERENCE side.
            SELECT jsonb_agg(p.value)
              INTO v_pref_arr
              FROM jsonb_array_elements_text(COALESCE(v_block -> 'preferred', '[]'::jsonb)) p
             WHERE p.value <> 'en';

            -- Only English preferred => no heritage-language preference to
            -- express => the attribute does not score AT ALL. See the header.
            IF v_pref_arr IS NOT NULL AND jsonb_array_length(v_pref_arr) > 0 THEN
              IF EXISTS (
                SELECT 1 FROM jsonb_array_elements_text(v_pref_arr) p
                 WHERE p.value = ANY (v_cand.languages)
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
