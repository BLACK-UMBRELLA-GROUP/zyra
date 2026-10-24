-- ⟲ APPLIED-IN-REMOTE RECORD — 2026-08-12 stewardship pass.
--
-- This migration was applied straight to the live database via MCP on
-- 2026-08-11 and existed in no repo file. This record file preserves the
-- version slot and WHAT IT DID; the verbatim statements live in
-- supabase_migrations.schema_migrations version 20260811153416 and can be
-- regenerated with tools/export_missing_migrations.sql (OA-ZYRA-198).
-- House precedent for a record-not-body file: 20260811094513.
--
-- WHAT IT DID:
-- OA-ZYRA-193(c) part 1 — zyra_seed_ch4_questions RENAMED zyra_onboarding_questions (canonical bank, mirrors chapter3_categories.dart — drift risk raised); + show_if columns; zyra_question_is_due(), zyra_onboarding_missing(), zyra_onboarding_complete(), zyra_my_onboarding_progress(); revokes on the new fns
-- OA-ZYRA-198 RECOVERY — 2026-09-10:
-- The record-only placeholder was replaced in place under the Founder's
-- governed history-recovery authority using the one retained production
-- migration-history statement for version 20260811153416.
-- Retained identity: 9,277 characters; 10,006 UTF-8 bytes;
-- SHA-256 0f9022853b97fa328940e15296e885e917d83842ee19ff9d469ebef88e42fcfc.
-- The bytes between the BEGIN/END markers are exactly statements[1];
-- neither marker is part of the retained statement.
--
-- BEGIN VERBATIM LIVE STATEMENT 20260811153416
-- ═══════════════════════════════════════════════════════════════════════
-- OA-ZYRA-193(c) — THE COMPLETENESS GATE, PART 1: KNOWING WHAT COMPLETE IS
-- ═══════════════════════════════════════════════════════════════════════
--
-- Founder, 2026-08-11: "No answer is optional." Finish onboarding or you are
-- not in the pool. Part 1 is the hard half — the server has to be able to
-- work out what a given Seeker was actually asked.
--
-- ── THE FIRST ATTEMPT WAS WRONG, AND IT IS WORTH RECORDING WHY.
--
-- "Every question in the bank must be answered" excluded 38 of 144 seeded
-- profiles. They were not incomplete. Every one of them had answered "No" to
-- ch3_q3 (do you want children) and had therefore correctly never been shown
-- ch3_q24 (when). Enforcing that gate would have removed 26% of the
-- population from Browse for answering honestly.
--
-- Measured before enforcing rather than after:
--     ch3_q3 = 'Yes'            68 seekers, 68 answered ch3_q24
--     ch3_q3 = 'No'             38 seekers,  0 answered ch3_q24
--     ch3_q3 = 'If Allah wills' 30 seekers, 30 answered ch3_q24
--     ch3_q3 = 'Unsure'          8 seekers,  8 answered ch3_q24
--
-- ── WHY IT COULD NOT HAVE KNOWN.
--
-- Applicability is gender AND a conditional rule. The gender half was already
-- in this table; the conditional half — `showIf` — lived only in Dart, in
-- data/chapter3_categories.dart. The server held half a rule and did not know
-- it. Both halves live here now.
--
-- ⚠️ THE BANK NOW EXISTS TWICE — here and in Dart. That is a real drift risk
-- and it is the price of a server-side gate: a question added to Dart and not
-- to this table is a question the gate silently stops requiring. Raised as
-- its own action rather than left as a comment nobody reads.

-- ── 1 · THE TABLE STOPS LYING ABOUT ITSELF ─────────────────────────────
-- Named for the job it was created for — seeding the synthetic backfill —
-- and it now holds the canonical question bank the gate depends on. Nothing
-- in the repo or the app references the old name; it was only ever reached
-- from ad-hoc SQL.
ALTER TABLE IF EXISTS zyra_seed_ch4_questions RENAME TO zyra_onboarding_questions;

ALTER TABLE zyra_onboarding_questions
  ADD COLUMN IF NOT EXISTS show_if_qid         text,
  ADD COLUMN IF NOT EXISTS show_if_not_any_of  jsonb;

COMMENT ON TABLE zyra_onboarding_questions IS
  'The Chapter 3/4 question bank, server-side. Mirrors data/chapter3_categories.dart — a question added there and not here is a question the completeness gate stops requiring. Renamed from zyra_seed_ch4_questions 2026-08-11: it was created for seeding and became canonical.';
COMMENT ON COLUMN zyra_onboarding_questions.show_if_qid IS
  'Mirrors ShowIf.questionId. The question whose answer controls whether this one is asked.';
COMMENT ON COLUMN zyra_onboarding_questions.show_if_not_any_of IS
  'Mirrors ShowIf.notAnyOf. Hide this question when the controlling answer is any of these.';

-- The one conditional question in the bank today.
-- data/chapter3_categories.dart:174 — showIf: ShowIf('ch3_q3', notAnyOf: ['No'])
UPDATE zyra_onboarding_questions
   SET show_if_qid = 'ch3_q3', show_if_not_any_of = '["No"]'::jsonb
 WHERE qid = 'ch3_q24';

-- ── 2 · THE APPLICABILITY RULE, ONCE ───────────────────────────────────
--
-- A direct port of OnboardingQuestion.isVisible(gender, answers):
--   visibleFor(gender) && (showIf?.evaluate(answers) ?? true)
--
-- Including its deliberate default. From the Dart, verbatim: "An unanswered
-- controlling question shows the dependent one... showing a question that
-- could have been skipped is recoverable, whereas hiding one that should have
-- been asked is not." The same choice is safe here for the same reason — it
-- makes the gate stricter, never laxer.
CREATE OR REPLACE FUNCTION public.zyra_question_is_due(
  p_qid text, p_gender text, p_answers jsonb
) RETURNS boolean
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $function$
  SELECT CASE
    WHEN q.qid IS NULL THEN false
    -- gender half
    WHEN NOT (q.gender_visibility = 'all'
              OR (q.gender_visibility = 'menOnly'   AND p_gender = 'male')
              OR (q.gender_visibility = 'womenOnly' AND p_gender = 'female'))
      THEN false
    -- conditional half
    WHEN q.show_if_qid IS NULL THEN true
    WHEN p_answers -> q.show_if_qid IS NULL
      OR jsonb_typeof(p_answers -> q.show_if_qid) = 'null' THEN true
    WHEN jsonb_typeof(p_answers -> q.show_if_qid) = 'array' THEN
      NOT EXISTS (
        SELECT 1 FROM jsonb_array_elements_text(p_answers -> q.show_if_qid) v
         WHERE coalesce(q.show_if_not_any_of, '[]'::jsonb) ? v.value)
    ELSE
      NOT (coalesce(q.show_if_not_any_of, '[]'::jsonb) ? (p_answers ->> q.show_if_qid))
  END
  FROM zyra_onboarding_questions q WHERE q.qid = p_qid;
$function$;

-- ── 3 · WHAT IS STILL OWED ─────────────────────────────────────────────
--
-- Returns a row per unanswered-but-due question, for BOTH halves: ch3 is what
-- you said about yourself, ch4 is what you are open to in someone else. Both
-- are required — a Seeker with no preferences cannot be scored, and a Seeker
-- with no answers cannot be scored BY anyone. The gate is symmetric because
-- the harm is.
CREATE OR REPLACE FUNCTION public.zyra_onboarding_missing(p_user uuid)
RETURNS TABLE(qid text, needs_answer boolean, needs_preference boolean)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_gender TEXT;
  v_ans    JSONB;
  v_prefs  JSONB;
BEGIN
  SELECT p.gender INTO v_gender FROM profiles p WHERE p.id = p_user;
  IF v_gender IS NULL THEN RETURN; END IF;

  SELECT coalesce(oa.ch3_answers,'{}'::jsonb), coalesce(oa.ch4_preferences,'{}'::jsonb)
    INTO v_ans, v_prefs
    FROM onboarding_answers oa WHERE oa.user_id = p_user;
  v_ans   := coalesce(v_ans,   '{}'::jsonb);
  v_prefs := coalesce(v_prefs, '{}'::jsonb);

  RETURN QUERY
  SELECT q.qid,
         NOT (v_ans   ? q.qid) AS needs_answer,
         NOT (v_prefs ? q.qid) AS needs_preference
    FROM zyra_onboarding_questions q
   WHERE zyra_question_is_due(q.qid, v_gender, v_ans)
     AND (NOT (v_ans ? q.qid) OR NOT (v_prefs ? q.qid));
END;
$function$;

-- ── 4 · THE GATE ITSELF ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.zyra_onboarding_complete(p_user uuid)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT
    -- The basic profile, which profile_complete already means and which this
    -- deliberately does NOT redefine. That flag is written at the end of the
    -- name/date-of-birth/photos step and has its own history of going wrong;
    -- this composes with it rather than replacing it.
    EXISTS (SELECT 1 FROM profiles p
             WHERE p.id = p_user AND p.role = 'seeker'
               AND p.profile_complete AND p.gender IS NOT NULL)
    -- Chapter 2.
    AND EXISTS (SELECT 1 FROM seeker_details sd
                 WHERE sd.user_id = p_user
                   AND sd.preferences IS NOT NULL
                   AND sd.preferences <> '{}'::jsonb)
    -- Chapters 3 and 4, every question they were actually asked.
    AND NOT EXISTS (SELECT 1 FROM zyra_onboarding_missing(p_user));
$function$;

COMMENT ON FUNCTION public.zyra_onboarding_complete(uuid) IS
  'OA-ZYRA-193(c). True when this Seeker has finished onboarding: basic profile, Chapter 2, and every Chapter 3/4 question they were actually shown. Applicability accounts for gender AND conditional showIf rules — a question skipped because it did not apply is not missing.';

-- ── 5 · THE CLIENT-FACING VIEW OF IT ───────────────────────────────────
--
-- A gate that returns nothing and says nothing reads as a broken app. This
-- is what the app asks so it can say "3 questions left" instead of showing an
-- empty Browse with no explanation.
CREATE OR REPLACE FUNCTION public.zyra_my_onboarding_progress()
RETURNS TABLE(complete boolean, questions_due int, questions_missing int,
              has_chapter_2 boolean, basic_profile boolean)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  me       UUID := (SELECT auth.uid());
  v_gender TEXT;
  v_ans    JSONB;
BEGIN
  IF me IS NULL THEN RETURN; END IF;

  SELECT p.gender INTO v_gender FROM profiles p WHERE p.id = me;
  SELECT coalesce(oa.ch3_answers,'{}'::jsonb) INTO v_ans
    FROM onboarding_answers oa WHERE oa.user_id = me;
  v_ans := coalesce(v_ans, '{}'::jsonb);

  RETURN QUERY
  SELECT
    zyra_onboarding_complete(me),
    (SELECT count(*)::int FROM zyra_onboarding_questions q
      WHERE zyra_question_is_due(q.qid, v_gender, v_ans)),
    (SELECT count(*)::int FROM zyra_onboarding_missing(me)),
    EXISTS (SELECT 1 FROM seeker_details sd
             WHERE sd.user_id = me AND sd.preferences IS NOT NULL
               AND sd.preferences <> '{}'::jsonb),
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = me AND p.profile_complete);
END;
$function$;

REVOKE ALL ON FUNCTION public.zyra_my_onboarding_progress() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.zyra_my_onboarding_progress() TO authenticated;
REVOKE ALL ON FUNCTION public.zyra_onboarding_missing(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.zyra_onboarding_complete(uuid) FROM PUBLIC;
-- END VERBATIM LIVE STATEMENT 20260811153416
