-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804101515, applied name
-- 'score_candidates_chapter2_attributes') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Extend the EXISTING scoring engine with Chapter 2 attributes.
-- Founder, 2026-08-04: "extend the existing scoring engine to incorporate
-- those additional attributes rather than creating a second scoring
-- mechanism. We should continue building on what already exists."
--
-- The Chapter 3/4 block below is UNCHANGED, deliberately. It is working,
-- exercised code; the new work is appended after it, sharing v_total and
-- v_max so both chapters land on one 0-100 scale rather than producing two
-- numbers that then need reconciling.
--
-- TWO PREFERENCE SHAPES, because Chapter 2 asks two kinds of question:
--
--   MATRIX     sect — every option gets its own traffic light, exactly
--              like ch4_preferences. Scored the same way.
--   LIST       country of birth, nationality, ethnicity, languages —
--              "here are the ones I'd prefer", plus a single flexibility
--              answer covering everyone outside that list. In the list is
--              green; outside it takes the flexibility light.
--
-- LOCATION IS DELIBERATELY NOT SCORED. `location_text` is free text with
-- no geocoding, no latitude and no longitude — which is precisely why the
-- Founder replaced mileage bands with coarse buckets on 2026-08-01. Of the
-- four buckets, only 'anywhere' (trivially green) and 'same_city' (a
-- case-insensitive string match on free text) are computable at all, and
-- 'same_region'/'same_country' are not computable in any honest sense.
-- Scoring two of four and silently ignoring the rest would reintroduce
-- exactly the fault that decision removed. Left out until there is either
-- geocoding or a structured location field.
--
-- WEIGHTING IS SET TO 1 AND NEEDS A FOUNDER DECISION. See v_ch2_weight.

create or replace function public.zyra_light_points(p_light text)
returns int
language sql
immutable
set search_path to 'public'
as $$
  select case p_light
           when 'green'  then 2
           when 'yellow' then 1
           when 'red'    then -3
           else 0
         end;
$$;

create or replace function public.score_candidates(p_candidate_ids uuid[])
returns table(candidate_id uuid, score numeric)
language plpgsql
stable security definer
set search_path to 'public'
as $function$
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

  -- Chapter 2 additions
  v_my_ch2   JSONB;
  v_cand     RECORD;
  v_block    JSONB;
  v_pref_arr JSONB;

  -- How much one Chapter 2 attribute is worth relative to one Chapter 3
  -- question. 1 = identical weight.
  --
  -- OPEN — FOUNDER DECISION. Chapter 3/4 asks ~174 questions; Chapter 2
  -- contributes at most 6 scorable attributes. At weight 1 those six move
  -- the final score by only a few percent, which may understate sect and
  -- ethnicity for this audience. Left at the neutral value rather than
  -- inventing a multiplier — the same reasoning as leaving the Guardian
  -- scope narrow. Raising it is a one-line change here.
  --
  -- Note this understates Chapter 2's real influence: sect carries a hard
  -- requirement, which EXCLUDES rather than scores, and no weight applies
  -- to an exclusion.
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

  -- Unchanged behaviour: someone who has stated no preferences at all
  -- scores everyone 50. Now correctly accounts for a user who finished
  -- Chapter 2 but not Chapter 3 — previously they fell through here and
  -- got a flat 50 despite having told us six things.
  IF v_my_prefs = '{}'::jsonb AND v_my_ch2 = '{}'::jsonb THEN
    FOREACH v_candidate_id IN ARRAY p_candidate_ids LOOP
      candidate_id := v_candidate_id;
      score := 50.0;
      RETURN NEXT;
    END LOOP;
    RETURN;
  END IF;

  FOREACH v_candidate_id IN ARRAY p_candidate_ids LOOP
    SELECT oa.ch3_answers INTO v_ch3 FROM onboarding_answers oa WHERE oa.user_id = v_candidate_id;
    v_ch3 := COALESCE(v_ch3, '{}'::jsonb);

    v_total := 0;
    v_max := 0;
    v_excluded := FALSE;

    -- ================= CHAPTER 3/4 — UNCHANGED =================
    FOR v_pref_rec IN SELECT * FROM jsonb_each(v_my_prefs) LOOP
      DECLARE
        v_question TEXT := v_pref_rec.key;
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
            IF v_light = 'green' THEN
              v_total := v_total + 2;
            ELSIF v_light = 'yellow' THEN
              v_total := v_total + 1;
            ELSIF v_light = 'red' THEN
              IF COALESCE((v_my_hard ->> v_question)::boolean, FALSE) THEN
                v_excluded := TRUE;
                EXIT;
              END IF;
              v_total := v_total - 3;
            END IF;
          END LOOP;
        ELSE
          v_value := v_answer #>> '{}';
          v_light := v_prefs_for_question ->> v_value;
          IF v_light IS NOT NULL THEN
            v_max := v_max + 2;
            IF v_light = 'green' THEN
              v_total := v_total + 2;
            ELSIF v_light = 'yellow' THEN
              v_total := v_total + 1;
            ELSIF v_light = 'red' THEN
              IF COALESCE((v_my_hard ->> v_question)::boolean, FALSE) THEN
                v_excluded := TRUE;
              ELSE
                v_total := v_total - 3;
              END IF;
            END IF;
          END IF;
        END IF;
      END;

      EXIT WHEN v_excluded;
    END LOOP;

    IF v_excluded THEN
      CONTINUE;
    END IF;

    -- ================= CHAPTER 2 — NEW 2026-08-04 =================
    IF v_my_ch2 <> '{}'::jsonb THEN
      SELECT sd.sect, sd.revert_status, sd.country_of_birth,
             sd.nationality, sd.ethnicity, sd.languages
        INTO v_cand
        FROM seeker_details sd
        WHERE sd.user_id = v_candidate_id;

      -- A candidate who has not done Chapter 2 simply contributes nothing
      -- here, rather than being penalised for it. Scoring absence as a
      -- negative would quietly bury every new joiner.
      IF FOUND THEN

        -- SECT — matrix, and the only Chapter 2 answer that can exclude.
        v_block := v_my_ch2 -> 'sect';
        IF v_block IS NOT NULL AND v_cand.sect IS NOT NULL THEN
          -- The matrix is keyed by the on-screen label ('Sunni'), the
          -- column stores the code ('sunni'). initcap bridges the two for
          -- the three fixed values; it is NOT used for reference-list
          -- codes, which never appear as matrix keys.
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

        -- REVERT — the question is "how would you feel about matching with
        -- someone who is a revert", so it only applies when they are one.
        -- A non-revert candidate is not scored either way.
        IF NOT v_excluded AND COALESCE(v_cand.revert_status, FALSE) THEN
          v_light := v_my_ch2 -> 'revert' ->> 'flexibility';
          IF v_light IS NOT NULL THEN
            v_max   := v_max   + 2 * v_ch2_weight;
            v_total := v_total + zyra_light_points(v_light) * v_ch2_weight;
          END IF;
        END IF;

        -- LIST-SHAPED ATTRIBUTES.
        -- In the preferred list -> green. Outside it -> the flexibility
        -- light. 'skipped' means the user declined to state a preference,
        -- which must contribute nothing rather than defaulting to green —
        -- otherwise skipping a question would raise everyone's score.
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

          -- LANGUAGES — list against list. Any shared language counts as
          -- green: one common language is what the question is actually
          -- about. Requiring a full match would score a trilingual
          -- candidate worse than a monolingual one.
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

revoke execute on function public.zyra_light_points(text) from anon;
revoke execute on function public.score_candidates(uuid[]) from anon;
