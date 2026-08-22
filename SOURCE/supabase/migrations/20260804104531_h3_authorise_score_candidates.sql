-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804104531, applied name
-- 'h3_authorise_score_candidates') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- H-3 — score_candidates() accepted arbitrary candidate UUIDs.
--
-- ONE LINE added at the top of the candidate loop. The scoring logic below
-- is unchanged from the version applied earlier today; re-emitted only
-- because plpgsql bodies cannot be patched in place.
--
-- Why CONTINUE rather than raising: a caller asking about a profile they
-- cannot see now gets NO ROW back for it, which is indistinguishable from
-- "that profile has no data". Raising an error would confirm the UUID
-- exists, which is the same information leak in a different shape.

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
  v_my_ch2   JSONB;
  v_cand     RECORD;
  v_block    JSONB;
  v_pref_arr JSONB;
  -- OPEN, FOUNDER DECISION: 1 = one Chapter 2 attribute counts the same as
  -- one Chapter 3 question. See ZYRA_DECISIONS_CURRENT_VERSION_V2 §9.2.
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

  IF v_my_prefs = '{}'::jsonb AND v_my_ch2 = '{}'::jsonb THEN
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

    -- ================= CHAPTER 2 =================
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

revoke all on function public.score_candidates(uuid[]) from public;
revoke all on function public.score_candidates(uuid[]) from anon;
grant execute on function public.score_candidates(uuid[]) to authenticated;
