-- Server-side compatibility scoring (Founder decision, 2026-07-26 —
-- see REPORTS/CURRENT/ZYRA_FABLE_BUILD_REVIEW_2026-07-19_V1.md
-- §Open Decisions item 1).
--
-- Problem: onboarding_answers RLS (20260718192024_onboarding_answers_
-- table.sql) is own-row-only by design (these are personal values/
-- preference answers). zyra_discovery_service.dart's _applyCompatibility
-- and zyra_journey_service.dart's Compatibility Reveal both try to
-- read a SECOND user's ch3_answers directly from the client — this
-- always returns empty under real RLS for two distinct real accounts,
-- so every real candidate silently scores the neutral 50.0, with no
-- Hard Requirement exclusion and no real ordering.
--
-- Fix: keep onboarding_answers RLS exactly as-is (no broadening —
-- these answers stay own-row-only at the table level, so a direct
-- `.from('onboarding_answers').select(...)` for someone else's row
-- still returns nothing) and instead do the scoring itself inside a
-- SECURITY DEFINER function, which runs as its owner and so can read
-- both sides' rows internally. The client only ever gets back a
-- computed score per candidate — never another user's raw ch3/ch4
-- answers. This mirrors the exact model already used for
-- preview_wali_invite/accept_wali_invite.
--
-- Port of compatibility_scoring.dart's scoreCandidate() into SQL, kept
-- as close to the original algorithm as PL/pgSQL allows: for each
-- question the SEEKER (caller) has a Ch4 preference for, look at the
-- CANDIDATE's Ch3 answer(s) for that same question. A candidate value
-- falling under the seeker's green option scores +2, yellow +1, red
-- scores -3 (or excludes the candidate outright if the seeker flagged
-- that question as a Hard Requirement). No comparable data at all
-- (candidate never answered, or the seeker has no preference for it)
-- scores neither positive nor negative — 0 impact on the total, but
-- also doesn't inflate the max-possible denominator. Final score is
-- normalised from [-1.5x, +1x] onto [0,100], same formula as the
-- Dart original. maxPossible == 0 (nothing comparable at all) ->
-- neutral 50, same as before.
--
-- This deliberately keeps compatibility_scoring.dart's Dart function
-- in place (untouched) as the reference implementation / any future
-- client-side preview use — it is simply no longer the thing that
-- decides real ordering, since it can never see other users' answers
-- under RLS. The two implementations must be kept in sync by hand if
-- the scoring model changes (see DR-ZYRA-079, still PROPOSED).

CREATE OR REPLACE FUNCTION public.score_candidates(p_candidate_ids UUID[])
RETURNS TABLE(candidate_id UUID, score NUMERIC)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
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
BEGIN
  IF v_me IS NULL THEN
    RETURN;
  END IF;

  SELECT oa.ch4_preferences, oa.ch4_hard_requirements
    INTO v_my_prefs, v_my_hard
    FROM onboarding_answers oa
    WHERE oa.user_id = v_me;

  -- No Ch4 preferences recorded yet (or hasn't done onboarding_answers
  -- at all) — every candidate is neutral, none excluded, matches the
  -- Dart original's "return candidates unchanged" behaviour.
  IF v_my_prefs IS NULL OR v_my_prefs = '{}'::jsonb THEN
    FOREACH v_candidate_id IN ARRAY p_candidate_ids LOOP
      candidate_id := v_candidate_id;
      score := 50.0;
      RETURN NEXT;
    END LOOP;
    RETURN;
  END IF;

  v_my_hard := COALESCE(v_my_hard, '{}'::jsonb);

  FOREACH v_candidate_id IN ARRAY p_candidate_ids LOOP
    SELECT oa.ch3_answers INTO v_ch3 FROM onboarding_answers oa WHERE oa.user_id = v_candidate_id;
    v_ch3 := COALESCE(v_ch3, '{}'::jsonb);

    v_total := 0;
    v_max := 0;
    v_excluded := FALSE;

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
      CONTINUE; -- Hard Requirement violated — omit this candidate entirely.
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
$$;

REVOKE ALL ON FUNCTION public.score_candidates(UUID[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.score_candidates(UUID[]) TO authenticated;
