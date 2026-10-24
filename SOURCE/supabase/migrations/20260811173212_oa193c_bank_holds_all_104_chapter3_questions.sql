-- ⟲ APPLIED-IN-REMOTE RECORD — 2026-08-12 stewardship pass.
--
-- This migration was applied straight to the live database via MCP on
-- 2026-08-11 and existed in no repo file. This record file preserves the
-- version slot and WHAT IT DID; the verbatim statements live in
-- supabase_migrations.schema_migrations version 20260811173212 and can be
-- regenerated with tools/export_missing_migrations.sql (OA-ZYRA-198).
-- House precedent for a record-not-body file: 20260811094513.
--
-- WHAT IT DID:
-- Bank grows from 72 rows/71 qids to all 104 Chapter 3 questions; ch4_scored + category columns added (nine categories per OA-ZYRA-193(d)); 33 profile-detail questions INSERTed; gate requires an ANSWER for all 104, a PREFERENCE only where ch4_scored
-- OA-ZYRA-198 RECOVERY — 2026-09-10:
-- The record-only placeholder was replaced in place under the Founder's
-- governed history-recovery authority using the one retained production
-- migration-history statement for version 20260811173212.
-- Retained identity: 11,792 characters; 12,104 UTF-8 bytes;
-- SHA-256 2e814b5f9962429ca202721788c7a0ad1778b20e908ed5e1fda2603a89b3d558.
-- The bytes between the BEGIN/END markers are exactly statements[1];
-- neither marker is part of the retained statement.
--
-- BEGIN VERBATIM LIVE STATEMENT 20260811173212
-- ═══════════════════════════════════════════════════════════════════════
-- "COMPLETE" MEANS EVERY QUESTION YOU WERE ASKED — Founder, 2026-08-11
-- ═══════════════════════════════════════════════════════════════════════
--
-- Chapter 3 asks 104 questions. The bank held 72 rows (71 distinct qids)
-- and the completeness gate therefore checked 71 of them. A member could
-- skip 33 real questions about themselves — siblings, whether they are
-- studying, Umrah — and still be let into the pool.
--
-- ── THE 33 ARE NOT A DEFECT IN THE BANK. I thought they were, and said so,
-- and was wrong. Every OnboardingQuestion carries a `ch4Status`:
--
--     required  31  \  = 72 rows in the bank (ch3_q26 has two gender
--     optional  41  /    variants sharing one qid)
--     none      33     asked in Chapter 3, no Chapter 4 preference step,
--                      never scored — values_preferences_flow.dart:66
--                      filters on `q.ch4Status != Ch4Status.none`
--
-- The bank was exactly right for SCORING. It was never meant to answer
-- "what was this person asked", and the gate leaned on it for that.
--
-- ── SO THE BANK GAINS A DISTINCTION IT DID NOT HAVE.
--
--     ch4_scored = true   feeds matching. Needs an answer AND a preference.
--     ch4_scored = false  profile detail only. Needs an answer. No
--                         preference screen exists, so requiring one would
--                         gate on something the app never asks for.
--
-- score_candidates is UNTOUCHED and unaffected: it iterates the Seeker's
-- stored ch4_preferences, so a question with no preference never appears.
-- Scoring stays over the 71. Only "have you finished" changes.
--
-- ── PARSED FROM data/chapter3_categories.dart AND CROSS-CHECKED FIRST.
-- Two parser bugs were caught before anything was written: apostrophes
-- ("Planning to, In Sha' Allah" truncated to "In Sha") and segment bleed
-- (genderVisibility read from the following question, producing 8 gendered
-- questions where there are 3). The corrected parse was verified against
-- the existing 72 rows — 72/72, zero option-count mismatches, nothing extra
-- on either side — before the 33 were trusted.

ALTER TABLE zyra_onboarding_questions
  ADD COLUMN IF NOT EXISTS ch4_scored boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS category   text;

COMMENT ON COLUMN zyra_onboarding_questions.ch4_scored IS
  'Mirrors OnboardingQuestion.ch4Status != none. True: has a Chapter 4 preference screen and feeds score_candidates. False: asked in Chapter 3 as profile detail only.';
COMMENT ON COLUMN zyra_onboarding_questions.category IS
  'Mirrors OnboardingCategory.name. Nine categories, per the Founder decision of 2026-08-11 on OA-ZYRA-193(d).';

INSERT INTO zyra_onboarding_questions
  (qid, gender_visibility, is_multi, options, show_if_qid, show_if_not_any_of, ch4_scored)
VALUES
  ('ch3_q10','all',false,'["No", "One", "Two", "Three", "Four", "Five or more"]'::jsonb,NULL,NULL,false),
  ('ch3_q17','all',false,'["Full-Time", "Part-Time", "No"]'::jsonb,NULL,NULL,false),
  ('ch3_q19','all',false,'["Simple and modest", "Moderate", "Flexible depending on circumstances", "I''d rather discuss it together"]'::jsonb,NULL,NULL,false),
  ('ch3_q21','all',false,'["Yes", "No", "Planning to in the future"]'::jsonb,NULL,NULL,false),
  ('ch3_q27','all',false,'["To build a righteous Muslim family", "Companionship", "To complete half my Deen", "To have children", "Personal growth and partnership", "All of the above equally"]'::jsonb,NULL,NULL,false),
  ('ch3_q32','all',false,'["Building a large family", "Building a small close-knit family", "Focusing on serving the community together", "Growing together in faith above all else", "A balanced combination of family, faith and personal growth"]'::jsonb,NULL,NULL,false),
  ('ch3_q41','all',false,'["Yes", "No", "Planning to, In Sha'' Allah"]'::jsonb,NULL,NULL,false),
  ('ch3_q42','all',false,'["Yes", "No", "Planning to when able, In Sha'' Allah", "Not currently able"]'::jsonb,NULL,NULL,false),
  ('ch3_q45','all',false,'["Daily", "Several times a week", "Weekly", "Occasionally", "Rarely"]'::jsonb,NULL,NULL,false),
  ('ch3_q58','all',false,'["Very tidy and organised", "Generally tidy", "Fairly relaxed", "I''m working on becoming more organised"]'::jsonb,NULL,NULL,false),
  ('ch3_q59','all',false,'["Early bird", "Mostly an early bird", "Night owl", "It depends on my schedule"]'::jsonb,NULL,NULL,false),
  ('ch3_q62','all',true,'["Spending time with family", "Spending time with friends", "Reading", "Islamic learning", "Sports & Fitness", "Travelling", "Nature & Outdoors", "Gaming", "Cooking & Baking", "Volunteering", "Arts & Creativity", "Learning new skills", "Relaxing at home"]'::jsonb,NULL,NULL,false),
  ('ch3_q69','all',false,'["I''d definitely consider it", "Only if genuinely needed", "Only occasionally", "I''d rather manage ourselves"]'::jsonb,NULL,NULL,false),
  ('ch3_q76','all',false,'["I apologise quickly when I''m wrong", "I prefer to talk things through first", "I need time before apologising", "It depends on the situation"]'::jsonb,NULL,NULL,false),
  ('ch3_q77','all',false,'["Very comfortable", "Comfortable", "Somewhat comfortable", "I find them difficult but I am improving"]'::jsonb,NULL,NULL,false),
  ('ch3_q79','all',false,'["I appreciate honest feedback", "I need a little time to process it", "It depends how it''s delivered", "I''m working on becoming more open"]'::jsonb,NULL,NULL,false),
  ('ch3_q80','all',false,'["Very often", "Quite often", "Occasionally", "I''m trying to improve"]'::jsonb,NULL,NULL,false),
  ('ch3_q82','all',false,'["Extremely important", "Very important", "Somewhat important", "I''m still developing this mindset"]'::jsonb,NULL,NULL,false),
  ('ch3_q83','all',false,'["I forgive quickly", "I usually forgive after discussion", "It takes me time", "It depends on the situation"]'::jsonb,NULL,NULL,false),
  ('ch3_q88','all',false,'["Very little", "Moderate", "Quite a lot", "It varies depending on the day"]'::jsonb,NULL,NULL,false),
  ('ch3_q89','all',false,'["I prefer technology only when necessary", "I enjoy a balanced use of technology", "I enjoy using technology regularly", "Technology is a major part of my lifestyle"]'::jsonb,NULL,NULL,false),
  ('ch3_q91','all',false,'["I don''t play games", "Occasionally", "Weekly", "Most days"]'::jsonb,NULL,NULL,false),
  ('ch3_q92','all',false,'["Rarely", "Occasionally", "Weekly", "Most days"]'::jsonb,NULL,NULL,false),
  ('ch3_q93','all',false,'["Daily", "Several times a week", "Weekly", "Occasionally", "Rarely"]'::jsonb,NULL,NULL,false),
  ('ch3_q94','all',false,'["Excellent", "Good", "Fair", "I''m working on improving it"]'::jsonb,NULL,NULL,false),
  ('ch3_q96','all',false,'["Very healthy", "Mostly healthy", "Fairly balanced", "I''m working on improving my diet"]'::jsonb,NULL,NULL,false),
  ('ch3_q98','all',false,'["Very consistent", "Mostly consistent", "Irregular due to work or study", "I''m working on improving my routine"]'::jsonb,NULL,NULL,false),
  ('ch3_q99','all',false,'["Worship and Du''a", "Talking with family or friends", "Exercise", "Quiet time and reflection", "Keeping busy", "A combination of these"]'::jsonb,NULL,NULL,false),
  ('ch3_q100','all',false,'["Every day", "Several times a week", "Weekly", "Occasionally", "Rarely"]'::jsonb,NULL,NULL,false),
  ('ch3_q101','all',false,'["No", "Yes", "I''d prefer to discuss this privately later"]'::jsonb,NULL,NULL,false),
  ('ch3_q102','all',false,'["No", "Yes", "I''d prefer to discuss this privately later"]'::jsonb,NULL,NULL,false),
  ('ch3_q103','all',false,'["I actively prioritise my health", "I try my best to stay healthy", "I am gradually improving my habits", "I haven''t focused on this much yet"]'::jsonb,NULL,NULL,false),
  ('ch3_q104','all',false,'["I''m happy with who I am and ready for marriage.", "I''m always striving to become a better Muslim.", "I''m still growing and improving every day.", "I believe marriage will help me become a better person."]'::jsonb,NULL,NULL,false)
ON CONFLICT DO NOTHING;

-- The nine categories (OA-ZYRA-193d, Founder 2026-08-11: "all nine, as
-- onboarding has them"). Ranges taken from OnboardingCategory blocks.
UPDATE zyra_onboarding_questions SET category='Family'
  WHERE (substring(qid from 6))::int BETWEEN 1 AND 10;
UPDATE zyra_onboarding_questions SET category='Education & Finances'
  WHERE (substring(qid from 6))::int BETWEEN 11 AND 22;
UPDATE zyra_onboarding_questions SET category='Marriage Goals'
  WHERE (substring(qid from 6))::int BETWEEN 23 AND 32;
UPDATE zyra_onboarding_questions SET category='Faith'
  WHERE (substring(qid from 6))::int BETWEEN 33 AND 51;
UPDATE zyra_onboarding_questions SET category='Lifestyle'
  WHERE (substring(qid from 6))::int BETWEEN 52 AND 63;
UPDATE zyra_onboarding_questions SET category='Household Roles & Expectations'
  WHERE (substring(qid from 6))::int BETWEEN 64 AND 73;
UPDATE zyra_onboarding_questions SET category='Communication & Emotional Intelligence'
  WHERE (substring(qid from 6))::int BETWEEN 74 AND 85;
UPDATE zyra_onboarding_questions SET category='Technology & Digital Lifestyle'
  WHERE (substring(qid from 6))::int BETWEEN 86 AND 93;
UPDATE zyra_onboarding_questions SET category='Health & Well-being'
  WHERE (substring(qid from 6))::int BETWEEN 94 AND 104;

-- ── THE GATE NOW ASKS FOR ALL 104 ANSWERS, PREFERENCES ONLY WHERE SCORED
CREATE OR REPLACE FUNCTION public.zyra_onboarding_data_complete(p_user uuid, p_gender text)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT p_gender IS NOT NULL
    AND EXISTS (SELECT 1 FROM seeker_details sd
                 WHERE sd.user_id = p_user
                   AND sd.preferences IS NOT NULL
                   AND sd.preferences <> '{}'::jsonb)
    AND NOT EXISTS (
      SELECT 1
        FROM zyra_onboarding_questions q
        LEFT JOIN onboarding_answers oa ON oa.user_id = p_user
       WHERE (q.gender_visibility = 'all'
              OR (q.gender_visibility = 'menOnly'   AND p_gender = 'male')
              OR (q.gender_visibility = 'womenOnly' AND p_gender = 'female'))
         AND (q.show_if_qid IS NULL
              OR coalesce(oa.ch3_answers,'{}'::jsonb) -> q.show_if_qid IS NULL
              OR jsonb_typeof(coalesce(oa.ch3_answers,'{}'::jsonb) -> q.show_if_qid) = 'null'
              OR NOT (coalesce(q.show_if_not_any_of,'[]'::jsonb)
                        ? (coalesce(oa.ch3_answers,'{}'::jsonb) ->> q.show_if_qid)))
         AND (NOT (coalesce(oa.ch3_answers,'{}'::jsonb) ? q.qid)
              OR (q.ch4_scored
                  AND NOT (coalesce(oa.ch4_preferences,'{}'::jsonb) ? q.qid)))
    );
$function$;

-- Same rule in the "what is still owed" report.
CREATE OR REPLACE FUNCTION public.zyra_onboarding_missing(p_user uuid)
RETURNS TABLE(qid text, needs_answer boolean, needs_preference boolean)
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_gender TEXT; v_ans JSONB; v_prefs JSONB;
BEGIN
  SELECT p.gender INTO v_gender FROM profiles p WHERE p.id = p_user;
  IF v_gender IS NULL THEN RETURN; END IF;
  SELECT coalesce(oa.ch3_answers,'{}'::jsonb), coalesce(oa.ch4_preferences,'{}'::jsonb)
    INTO v_ans, v_prefs FROM onboarding_answers oa WHERE oa.user_id = p_user;
  v_ans := coalesce(v_ans,'{}'::jsonb); v_prefs := coalesce(v_prefs,'{}'::jsonb);

  RETURN QUERY
  SELECT d.qid,
         NOT (v_ans ? d.qid) AS needs_answer,
         (d.scored AND NOT (v_prefs ? d.qid)) AS needs_preference
    FROM (SELECT q.qid, bool_or(q.ch4_scored) AS scored
            FROM zyra_onboarding_questions q GROUP BY q.qid) d
   WHERE zyra_question_is_due(d.qid, v_gender, v_ans)
     AND (NOT (v_ans ? d.qid) OR (d.scored AND NOT (v_prefs ? d.qid)));
END;
$function$;
-- END VERBATIM LIVE STATEMENT 20260811173212
