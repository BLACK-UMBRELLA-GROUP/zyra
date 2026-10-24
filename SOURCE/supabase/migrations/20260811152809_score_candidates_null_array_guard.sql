-- ⟲ APPLIED-IN-REMOTE RECORD — 2026-08-12 stewardship pass.
--
-- This migration was applied straight to the live database via MCP on
-- 2026-08-11 and existed in no repo file. This record file preserves the
-- version slot and WHAT IT DID; the verbatim statements live in
-- supabase_migrations.schema_migrations version 20260811152809 and can be
-- regenerated with tools/export_missing_migrations.sql (OA-ZYRA-198).
-- House precedent for a record-not-body file: 20260811094513.
--
-- WHAT IT DID:
-- score_candidates(): FOREACH over a NULL array raised 22004; now returns empty for NULL/empty input. Full function restated
-- OA-ZYRA-198 RECOVERY — 2026-09-10:
-- The record-only placeholder was replaced in place under the Founder's
-- governed history-recovery authority using the one retained production
-- migration-history statement for version 20260811152809.
-- Retained identity: 7,058 characters; 7,062 UTF-8 bytes;
-- SHA-256 38a2a20e810895d1975d4ec27eaea5db0cd03e78d3a114848171343bb2b16366.
-- The bytes between the BEGIN/END markers are exactly statements[1];
-- neither marker is part of the retained statement.
--
-- BEGIN VERBATIM LIVE STATEMENT 20260811152809
-- One-line robustness fix found while measuring the new scale: FOREACH over
-- a NULL array raises 22004 and takes the whole call down. Reachable from any
-- caller that builds its id list from a query returning no rows — array_agg
-- gives NULL, not an empty array, and the two are easy to confuse.
--
-- Empty in, empty out. A SECURITY DEFINER function should not fail loudly on
-- "nothing to score".
CREATE OR REPLACE FUNCTION public.score_candidates(p_candidate_ids uuid[])
RETURNS TABLE(candidate_id uuid, score numeric)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_me UUID := auth.uid();
  v_my_prefs JSONB; v_my_hard JSONB; v_candidate_id UUID; v_ch3 JSONB;
  v_pref_rec RECORD; v_value TEXT; v_light TEXT;
  v_total NUMERIC; v_max NUMERIC; v_excluded BOOLEAN;
  v_my_ch2 JSONB; v_cand RECORD; v_block JSONB; v_pref_arr JSONB;
  v_ch2_weight INT := 1;   -- STILL OPEN — OA-ZYRA-193(e), now answerable.
BEGIN
  IF v_me IS NULL THEN RETURN; END IF;
  IF p_candidate_ids IS NULL OR array_length(p_candidate_ids, 1) IS NULL THEN RETURN; END IF;

  SELECT oa.ch4_preferences, oa.ch4_hard_requirements INTO v_my_prefs, v_my_hard
    FROM onboarding_answers oa WHERE oa.user_id = v_me;
  SELECT sd.preferences INTO v_my_ch2 FROM seeker_details sd WHERE sd.user_id = v_me;

  v_my_prefs := COALESCE(v_my_prefs, '{}'::jsonb);
  v_my_ch2   := COALESCE(v_my_ch2,   '{}'::jsonb);
  v_my_hard  := COALESCE(v_my_hard,  '{}'::jsonb);

  IF v_my_prefs = '{}'::jsonb AND v_my_ch2 = '{}'::jsonb AND v_my_hard = '{}'::jsonb THEN
    FOREACH v_candidate_id IN ARRAY p_candidate_ids LOOP
      CONTINUE WHEN NOT public.zyra_can_view_profile(v_candidate_id);
      candidate_id := v_candidate_id; score := NULL; RETURN NEXT;
    END LOOP;
    RETURN;
  END IF;

  FOREACH v_candidate_id IN ARRAY p_candidate_ids LOOP
    CONTINUE WHEN NOT public.zyra_can_view_profile(v_candidate_id);

    SELECT oa.ch3_answers INTO v_ch3 FROM onboarding_answers oa WHERE oa.user_id = v_candidate_id;
    v_ch3 := COALESCE(v_ch3, '{}'::jsonb);
    v_total := 0; v_max := 0; v_excluded := FALSE;

    FOR v_pref_rec IN SELECT * FROM jsonb_each(v_my_hard) LOOP
      DECLARE v_answer JSONB := v_ch3 -> v_pref_rec.key;
      BEGIN
        CONTINUE WHEN v_answer IS NULL OR jsonb_typeof(v_answer) = 'null';
        IF jsonb_typeof(v_answer) = 'array' THEN
          IF EXISTS (SELECT 1 FROM jsonb_array_elements_text(v_answer) t
                      WHERE v_pref_rec.value ? t.value) THEN v_excluded := TRUE; END IF;
        ELSE
          IF v_pref_rec.value ? (v_answer #>> '{}') THEN v_excluded := TRUE; END IF;
        END IF;
      END;
      EXIT WHEN v_excluded;
    END LOOP;
    IF v_excluded THEN CONTINUE; END IF;

    FOR v_pref_rec IN SELECT * FROM jsonb_each(v_my_prefs) LOOP
      DECLARE
        v_prefs_for_question JSONB := v_pref_rec.value;
        v_answer JSONB := v_ch3 -> v_pref_rec.key;
      BEGIN
        IF v_answer IS NULL OR jsonb_typeof(v_answer) = 'null' THEN CONTINUE; END IF;
        IF jsonb_typeof(v_answer) = 'array' THEN
          FOR v_value IN SELECT jsonb_array_elements_text(v_answer) LOOP
            v_light := v_prefs_for_question ->> v_value;
            IF v_light IS NULL THEN CONTINUE; END IF;
            v_max := v_max + 1; v_total := v_total + zyra_light_weight(v_light);
          END LOOP;
        ELSE
          v_value := v_answer #>> '{}';
          v_light := v_prefs_for_question ->> v_value;
          IF v_light IS NOT NULL THEN
            v_max := v_max + 1; v_total := v_total + zyra_light_weight(v_light);
          END IF;
        END IF;
      END;
    END LOOP;

    IF v_my_ch2 <> '{}'::jsonb THEN
      SELECT sd.sect, sd.revert_status, sd.country_of_birth,
             sd.nationality, sd.ethnicity, sd.languages
        INTO v_cand FROM seeker_details sd WHERE sd.user_id = v_candidate_id;

      IF FOUND THEN
        v_block := v_my_ch2 -> 'sect';
        IF v_block IS NOT NULL AND v_cand.sect IS NOT NULL THEN
          IF (v_block -> 'hard_requirement') ? initcap(v_cand.sect) THEN
            v_excluded := TRUE;
          ELSE
            v_light := v_block -> 'matrix' ->> initcap(v_cand.sect);
            IF v_light IS NOT NULL THEN
              v_max   := v_max   + v_ch2_weight;
              v_total := v_total + zyra_light_weight(v_light) * v_ch2_weight;
            END IF;
          END IF;
        END IF;

        IF NOT v_excluded AND COALESCE(v_cand.revert_status, FALSE) THEN
          v_light := v_my_ch2 -> 'revert' ->> 'flexibility';
          IF v_light IS NOT NULL THEN
            v_max   := v_max   + v_ch2_weight;
            v_total := v_total + zyra_light_weight(v_light) * v_ch2_weight;
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
            IF v_pref_arr IS NULL OR jsonb_array_length(v_pref_arr) = 0 THEN CONTINUE; END IF;
            IF v_pref_arr ? v_pref_rec.cand_value THEN v_light := 'green';
            ELSE v_light := v_block ->> 'flexibility'; END IF;
            IF v_light IS NOT NULL THEN
              v_max   := v_max   + v_ch2_weight;
              v_total := v_total + zyra_light_weight(v_light) * v_ch2_weight;
            END IF;
          END LOOP;

          v_block := v_my_ch2 -> 'languages';
          IF v_block IS NOT NULL
             AND NOT COALESCE((v_block ->> 'skipped')::boolean, FALSE)
             AND v_cand.languages IS NOT NULL
             AND array_length(v_cand.languages, 1) > 0 THEN
            SELECT jsonb_agg(p.value) INTO v_pref_arr
              FROM jsonb_array_elements_text(COALESCE(v_block -> 'preferred', '[]'::jsonb)) p
             WHERE p.value <> 'en';
            IF v_pref_arr IS NOT NULL AND jsonb_array_length(v_pref_arr) > 0 THEN
              IF EXISTS (SELECT 1 FROM jsonb_array_elements_text(v_pref_arr) p
                          WHERE p.value = ANY (v_cand.languages)) THEN v_light := 'green';
              ELSE v_light := v_block ->> 'flexibility'; END IF;
              IF v_light IS NOT NULL THEN
                v_max   := v_max   + v_ch2_weight;
                v_total := v_total + zyra_light_weight(v_light) * v_ch2_weight;
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;
    END IF;

    IF v_excluded THEN CONTINUE; END IF;

    candidate_id := v_candidate_id;
    IF v_max = 0 THEN score := NULL;
    ELSE score := round(LEAST(100, GREATEST(0, (v_total / v_max) * 100)), 1);
    END IF;
    RETURN NEXT;
  END LOOP;
END;
$function$;
-- END VERBATIM LIVE STATEMENT 20260811152809
