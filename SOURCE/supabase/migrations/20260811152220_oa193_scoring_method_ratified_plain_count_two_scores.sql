-- ⟲ APPLIED-IN-REMOTE RECORD — 2026-08-12 stewardship pass.
--
-- This migration was applied straight to the live database via MCP on
-- 2026-08-11 and existed in no repo file. This record file preserves the
-- version slot and WHAT IT DID. On 2026-09-10, under the Founder's
-- OA-ZYRA-198 governed history-recovery authority, the one retained live
-- statement was restored below from
-- supabase_migrations.schema_migrations version 20260811152220.
-- House precedent for a record-not-body file: 20260811094513.
-- Live statement identity at recovery: 12,626 characters;
-- SHA-256 82fdc1d13db0564ddfa9aeeb09fde7eb3b0a509e678005536c17b03b703d24fa.
-- The bytes between the BEGIN/END markers are exactly statements[1];
-- neither marker is part of the retained statement.
--
-- WHAT IT DID:
-- OA-ZYRA-193 (a)(a2)(b)(c) — scoring method ratified. zyra_light_weight() green 1/yellow 0.5/red 0 replaces zyra_light_points (DROPPED); journey_compatibility gains seeker_a/b_score + seeker_a/b_categories, DROPS overall_score + category_scores; score_candidates() rewritten to the 0-100 plain count, returns NULL when nothing scoreable
-- BEGIN VERBATIM LIVE STATEMENT 20260811152220
-- ═══════════════════════════════════════════════════════════════════════
-- OA-ZYRA-193 — THE SCORING METHOD, RATIFIED. Founder, 2026-08-11.
-- ═══════════════════════════════════════════════════════════════════════
--
-- Closes parts (a), (a2), (b), (c). Parts (d) categories and (e)
-- v_ch2_weight remain open and are NOT decided here.
--
-- ZYRA_DECISIONS §10 has said "Compatibility scoring. Method undefined."
-- since it was written, and meanwhile two different methods were live:
-- this function's centred scale, and the plain count the Compatibility
-- Unlock screen's figures were built on. Not two numbers — two SCALES.
--
--   (a)  0-100 PLAIN COUNT.  green 1 · yellow 0.5 · red 0
--        score = (points / items scored) * 100
--        The +50 centring is gone. It computed something defensible and
--        communicated something false: nobody reads "50%" as "no data".
--
--   (b)  A RED NO LONGER COSTS MORE THAN A GREEN EARNS. Settled by (a),
--        not decided separately — a plain count has no penalty term. The
--        moral position the -3 encoded is not abandoned, it moves to Hard
--        Requirements, which exclude outright and are already tested
--        before and independently of the lights.
--
--   (a2) TWO SCORES, ONE EACH. See the journey_compatibility change below.
--
--   (c)  NO MINIMUM-ITEMS RULE. The Founder rejected the premise: no
--        question is optional, so a partial profile is not matchable.
--        Enforcement is an onboarding gate and does not exist yet — until
--        it does, score_candidates returns NULL rather than inventing a
--        number for someone it cannot score. See the v_max = 0 branch.
--
-- ⚠️ THIS CHANGES BROWSE ORDERING. The two scales rank differently
-- whenever reds are involved: the old one penalised red-heavy candidates
-- by 3 points each, the new one merely declines to reward them. That is
-- the decision working, not a regression.

-- ── 1 · THE WEIGHTS ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.zyra_light_weight(p_light text)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $function$
  select case p_light
           when 'green'  then 1.0
           when 'yellow' then 0.5
           when 'red'    then 0.0
           else 0.0
         end::numeric;
$function$;

COMMENT ON FUNCTION public.zyra_light_weight(text) IS
  'The ratified light weighting (OA-ZYRA-193a): green 1, yellow 0.5, red 0. Replaces zyra_light_points, which encoded the retired centred scale.';

-- zyra_light_points had exactly one caller — score_candidates, rewritten
-- below. Dropped rather than left dormant: a function that still encodes
-- the retired weighting is the second live method this decision exists to
-- end, and the next person to reach for "the light scoring function" must
-- not find two.
DROP FUNCTION IF EXISTS public.zyra_light_points(text);

-- ── 2 · TWO SCORES ─────────────────────────────────────────────────────
--
-- (a2). score_candidates is ASYMMETRIC by construction: it asks "how well
-- do THEIR answers fit MY stated preferences", which is a different
-- question for each person. Yusuf scores Aisha 84.5; Aisha scores Yusuf
-- 88.2. Same pair, same data, same day.
--
-- The old single overall_score forced one of those to win, and which one
-- was an accident of sequence: revealCompatibility() computed it when the
-- SECOND person revealed, from that person's perspective. A couple's
-- "shared" compatibility therefore depended on who happened to tap last.
--
-- Two columns, mirroring seeker_a_revealed / seeker_b_revealed, which is
-- the shape this table already used for the other per-person fact.
ALTER TABLE journey_compatibility
  ADD COLUMN IF NOT EXISTS seeker_a_score      numeric,
  ADD COLUMN IF NOT EXISTS seeker_b_score      numeric,
  ADD COLUMN IF NOT EXISTS seeker_a_categories jsonb,
  ADD COLUMN IF NOT EXISTS seeker_b_categories jsonb;

-- DROPPED, NOT DEPRECATED IN PLACE. A client built before this migration
-- reading a stale overall_score would show a number on the RETIRED scale
-- and look right doing it. Dropping makes that client fail closed — it
-- shows nothing — instead of failing open with a wrong number. Every
-- reader is rewritten in this same change.
ALTER TABLE journey_compatibility
  DROP COLUMN IF EXISTS overall_score,
  DROP COLUMN IF EXISTS category_scores;

COMMENT ON COLUMN journey_compatibility.seeker_a_score IS
  'seeker_a''s own compatibility figure: how well seeker_b''s answers fit seeker_a''s stated preferences. NOT shared with seeker_b — OA-ZYRA-193 a2.';
COMMENT ON COLUMN journey_compatibility.seeker_b_score IS
  'seeker_b''s own compatibility figure. See seeker_a_score.';

-- ── 3 · THE ENGINE ─────────────────────────────────────────────────────
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

  SELECT oa.ch4_preferences, oa.ch4_hard_requirements INTO v_my_prefs, v_my_hard
    FROM onboarding_answers oa WHERE oa.user_id = v_me;
  SELECT sd.preferences INTO v_my_ch2 FROM seeker_details sd WHERE sd.user_id = v_me;

  v_my_prefs := COALESCE(v_my_prefs, '{}'::jsonb);
  v_my_ch2   := COALESCE(v_my_ch2,   '{}'::jsonb);
  v_my_hard  := COALESCE(v_my_hard,  '{}'::jsonb);

  -- WAS: return 50.0 for everyone when the caller has stated nothing. On a
  -- centred scale 50 meant "no information"; on a plain count it would mean
  -- "half of everything matched", which is a claim rather than an absence.
  -- NULL is the honest answer and the callers are written for it.
  IF v_my_prefs = '{}'::jsonb AND v_my_ch2 = '{}'::jsonb AND v_my_hard = '{}'::jsonb THEN
    FOREACH v_candidate_id IN ARRAY p_candidate_ids LOOP
      CONTINUE WHEN NOT public.zyra_can_view_profile(v_candidate_id);
      candidate_id := v_candidate_id; score := NULL; RETURN NEXT;
    END LOOP;
    RETURN;
  END IF;

  FOREACH v_candidate_id IN ARRAY p_candidate_ids LOOP
    CONTINUE WHEN NOT public.zyra_can_view_profile(v_candidate_id);   -- H-3

    SELECT oa.ch3_answers INTO v_ch3 FROM onboarding_answers oa WHERE oa.user_id = v_candidate_id;
    v_ch3 := COALESCE(v_ch3, '{}'::jsonb);
    v_total := 0; v_max := 0; v_excluded := FALSE;

    -- ===== CH4 HARD EXCLUSIONS — FIRST, INDEPENDENT OF THE LIGHTS =====
    -- Unchanged, and now carrying more weight than before: with the -3 gone,
    -- this is the ONLY place a dealbreaker acts. That is deliberate (b) —
    -- an exclusion is a promise, a light is a preference.
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

    -- ===== CHAPTER 3/4 — one item, one point =====
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

    -- ===== CHAPTER 2 =====
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
    -- NOTHING SCORED = NO NUMBER. Distinct from a hard-requirement
    -- exclusion, which returns no row at all: this row says "they exist and
    -- I cannot score them yet". Unreachable once (c)'s onboarding gate is
    -- built; honest until then.
    IF v_max = 0 THEN score := NULL;
    ELSE score := round(LEAST(100, GREATEST(0, (v_total / v_max) * 100)), 1);
    END IF;
    RETURN NEXT;
  END LOOP;
END;
$function$;

COMMENT ON FUNCTION public.score_candidates(uuid[]) IS
  'Scores candidates against the CALLER''s stated preferences. 0-100 plain count (green 1, yellow 0.5, red 0) per OA-ZYRA-193a. Asymmetric by construction — each person gets their own figure. NULL score means not scoreable yet; an absent row means excluded by a Hard Requirement.';
-- END VERBATIM LIVE STATEMENT 20260811152220
