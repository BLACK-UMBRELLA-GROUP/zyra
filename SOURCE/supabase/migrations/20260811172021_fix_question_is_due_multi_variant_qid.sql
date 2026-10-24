-- ⟲ APPLIED-IN-REMOTE RECORD — 2026-08-12 stewardship pass.
--
-- This migration was applied straight to the live database via MCP on
-- 2026-08-11 and existed in no repo file. This record file preserves the
-- version slot and WHAT IT DID; the verbatim statements live in
-- supabase_migrations.schema_migrations version 20260811172021 and can be
-- regenerated with tools/export_missing_migrations.sql (OA-ZYRA-198).
-- House precedent for a record-not-body file: 20260811094513.
--
-- WHAT IT DID:
-- zyra_question_is_due() assumed one row per qid; ch3_q26 has two gender variants. Rewritten as EXISTS over variants; zyra_onboarding_missing() + zyra_my_onboarding_progress() de-duplicated. Gate itself was never wrong — only the questions-left count
-- OA-ZYRA-198 RECOVERY — 2026-09-10:
-- The record-only placeholder was replaced in place under the Founder's
-- governed history-recovery authority using the one retained production
-- migration-history statement for version 20260811172021.
-- Retained identity: 5,124 characters; 5,136 UTF-8 bytes;
-- SHA-256 88eb598aab415c90338ddbb0fa58d567ba36890830086e6995ccb024b1dc9671.
-- The bytes between the BEGIN/END markers are exactly statements[1];
-- neither marker is part of the retained statement.
--
-- BEGIN VERBATIM LIVE STATEMENT 20260811172021
-- zyra_question_is_due() assumed one row per qid. It is not true.
--
-- ch3_q26 — Views on Polygamy — exists as TWO rows sharing one qid, a
-- menOnly variant and a womenOnly one. data/chapter3_categories.dart says so
-- in its own header ("Q26 has two gender-conditional variants") and the bank
-- was seeded faithfully: 72 rows, 71 distinct qids.
--
-- The function did `SELECT ... WHERE q.qid = p_qid`, which returns both rows.
-- A scalar SQL function takes whichever comes first, so for one gender it was
-- evaluating the OTHER gender's visibility rule and answering "not due" for a
-- question that was.
--
-- ⚠️ SCOPE — this did NOT affect the gate itself. zyra_onboarding_data_complete()
-- inlines the same logic as a join, so each variant row is filtered by gender
-- independently and the right one is used. The enforcing path and the
-- materialised profiles.onboarding_complete column were always correct.
--
-- What WAS wrong is zyra_onboarding_missing(), and through it
-- zyra_my_onboarding_progress() — the count Browse shows a gated Seeker.
-- It could have said "2 questions left" when there were 3. A door that is
-- correctly shut, with a wrong number written on it.
--
-- Rewritten as EXISTS over the variants: due when ANY row for this qid
-- matches the Seeker's gender and passes its own condition.
CREATE OR REPLACE FUNCTION public.zyra_question_is_due(
  p_qid text, p_gender text, p_answers jsonb
) RETURNS boolean
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1
      FROM zyra_onboarding_questions q
     WHERE q.qid = p_qid
       -- gender half
       AND (q.gender_visibility = 'all'
            OR (q.gender_visibility = 'menOnly'   AND p_gender = 'male')
            OR (q.gender_visibility = 'womenOnly' AND p_gender = 'female'))
       -- conditional half. Unanswered controller shows the question, matching
       -- ShowIf.evaluate: "showing a question that could have been skipped is
       -- recoverable, whereas hiding one that should have been asked is not."
       AND (q.show_if_qid IS NULL
            OR p_answers -> q.show_if_qid IS NULL
            OR jsonb_typeof(p_answers -> q.show_if_qid) = 'null'
            OR (jsonb_typeof(p_answers -> q.show_if_qid) = 'array'
                AND NOT EXISTS (
                  SELECT 1 FROM jsonb_array_elements_text(p_answers -> q.show_if_qid) v
                   WHERE coalesce(q.show_if_not_any_of,'[]'::jsonb) ? v.value))
            OR (jsonb_typeof(p_answers -> q.show_if_qid) <> 'array'
                AND NOT (coalesce(q.show_if_not_any_of,'[]'::jsonb)
                           ? (p_answers ->> q.show_if_qid))))
  );
$function$;

-- Same fix in the caller: it joined the bank and could yield ch3_q26 twice.
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
  SELECT d.qid,
         NOT (v_ans   ? d.qid) AS needs_answer,
         NOT (v_prefs ? d.qid) AS needs_preference
    FROM (SELECT DISTINCT q.qid FROM zyra_onboarding_questions q) d
   WHERE zyra_question_is_due(d.qid, v_gender, v_ans)
     AND (NOT (v_ans ? d.qid) OR NOT (v_prefs ? d.qid));
END;
$function$;

-- And the "how many were you asked" figure, for the same reason.
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
    (SELECT count(*)::int FROM (SELECT DISTINCT q.qid FROM zyra_onboarding_questions q) d
      WHERE zyra_question_is_due(d.qid, v_gender, v_ans)),
    (SELECT count(*)::int FROM zyra_onboarding_missing(me)),
    EXISTS (SELECT 1 FROM seeker_details sd
             WHERE sd.user_id = me AND sd.preferences IS NOT NULL
               AND sd.preferences <> '{}'::jsonb),
    EXISTS (SELECT 1 FROM profiles p WHERE p.id = me AND p.profile_complete);
END;
$function$;

REVOKE ALL ON FUNCTION public.zyra_my_onboarding_progress() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.zyra_my_onboarding_progress() TO authenticated;
-- END VERBATIM LIVE STATEMENT 20260811172021
