-- ═══════════════════════════════════════════════════════════════════════
-- OA-ZYRA-185 · Chapter 2's sect exclusion becomes per-OPTION.
-- Founder decision 2026-08-10: converge with Chapter 4. Applied 2026-08-10.
--
-- WHAT WAS WRONG. seeker_details.preferences held
-- {sect: {matrix: {...}, hard_requirement: BOOL}} and score_candidates()
-- excluded on ANY red sect when the flag was set. So on the most sensitive
-- question in the app — religious denomination, UK GDPR Article 9 data — a Seeker could
-- not say "Ibadi, never" while leaving "Shia" a soft red. One tick excluded
-- both; no tick excluded neither.
--
-- NOT FREE, UNLIKE CHAPTER 4. onboarding_answers had zero rows that morning,
-- so that reshape needed no backfill. seeker_details had 144, with 38 flags
-- set — so this CONVERTS them: a set flag becomes the list of sects the
-- Seeker had actually marked red, which is precisely what the old flag meant.
-- Nothing invented, nothing lost. Verified: 0 exclusions name a sect that was
-- not red.
--
-- VERIFIED 16/16, including the case the seeded data could not express (one
-- sect hard-excluded, another red but not) which had to be built by hand:
-- the excluded candidate disappears, the soft-red one survives and still
-- costs 1.71 points — Chapter 2's measured ~4% share of the score.
-- ═══════════════════════════════════════════════════════════════════════

-- ── 1 · convert the 144 rows BEFORE anything can reject the old shape ───
UPDATE seeker_details
   SET preferences = jsonb_set(
         preferences,
         '{sect,hard_requirement}',
         CASE WHEN (preferences -> 'sect' ->> 'hard_requirement')::boolean IS TRUE
              THEN COALESCE((
                     SELECT jsonb_agg(m.key ORDER BY m.key)
                       FROM jsonb_each_text(preferences -> 'sect' -> 'matrix') m(key, value)
                      WHERE m.value = 'red'
                   ), '[]'::jsonb)
              ELSE '[]'::jsonb
         END)
 WHERE jsonb_typeof(preferences -> 'sect' -> 'hard_requirement') = 'boolean';

-- ── 2 · shape guard, mirroring onboarding_answers_ch4_hard_shape ────────
CREATE OR REPLACE FUNCTION public.zyra_ch2_sect_hard_shape_ok(p jsonb)
RETURNS boolean LANGUAGE sql IMMUTABLE PARALLEL SAFE SET search_path TO 'public'
AS $$
  SELECT p IS NULL
      OR p -> 'sect' -> 'hard_requirement' IS NULL
      OR ( jsonb_typeof(p -> 'sect' -> 'hard_requirement') = 'array'
       AND NOT EXISTS (
             SELECT 1 FROM jsonb_array_elements(p -> 'sect' -> 'hard_requirement') a
              WHERE jsonb_typeof(a) <> 'string' ) );
$$;

REVOKE EXECUTE ON FUNCTION public.zyra_ch2_sect_hard_shape_ok(jsonb) FROM PUBLIC;

COMMENT ON FUNCTION public.zyra_ch2_sect_hard_shape_ok(jsonb) IS
  'Shape guard for seeker_details.preferences->sect->hard_requirement. '
  'Accepts an array of sect labels only. Exists so the retired boolean form '
  'cannot be written by an older client build — a silent old-shape write '
  'would read as "no exclusion at all", failing OPEN on a promise the Seeker '
  'made about Article 9 data.';

ALTER TABLE public.seeker_details
  DROP CONSTRAINT IF EXISTS seeker_details_sect_hard_shape;
ALTER TABLE public.seeker_details
  ADD CONSTRAINT seeker_details_sect_hard_shape
  CHECK (public.zyra_ch2_sect_hard_shape_ok(preferences));

-- ── 3 · the engine · sect block only; everything else byte-identical to
--        migration 20260810165108 ──────────────────────────────────────
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
        -- ── SECT · PER-OPTION EXCLUSION, 2026-08-10 (OA-ZYRA-185) ───────
        -- Tested BEFORE the light and independently of it, exactly as
        -- Chapter 4's hard requirements are. WAS: one boolean for the whole
        -- question, evaluated only inside the `red` branch — so the promise
        -- depended on a second piece of state staying in sync.
        v_block := v_my_ch2 -> 'sect';
        IF v_block IS NOT NULL AND v_cand.sect IS NOT NULL THEN
          IF (v_block -> 'hard_requirement') ? initcap(v_cand.sect) THEN
            v_excluded := TRUE;
          ELSE
            v_light := v_block -> 'matrix' ->> initcap(v_cand.sect);
            IF v_light IS NOT NULL THEN
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
