-- OA-ZYRA-198 RECONSTRUCTED REPLAY BRIDGE
-- REPLAY-ONLY GOVERNED ARTIFACT — NOT RETAINED PRODUCTION HISTORY — DO NOT APPLY
--
-- Founder authority: message 079 §§3–5, approved 2026-09-11.
-- Intended future use: only after a separate one-replay GO, copy this exact
-- file into an isolated scratch migration set at version 20260811153415.
-- It must remain outside SOURCE/supabase/migrations and must never be applied
-- to the production project.
--
-- Provenance boundary: the original ad-hoc CREATE/INSERT SQL is unavailable.
-- This bridge deterministically reconstructs the four evidenced data fields
-- from the byte-pinned 2026-08-10 Dart question bank. NOT NULL choices, the
-- composite primary key, execution-owner and no-FORCE/no-policy RLS
-- representation are
-- explicit reconstruction choices, not claims about the lost original DDL.
--
-- Canonical scored projection: 72 rows / 71 qids / 12,927 UTF-8 bytes /
-- SHA-256 eb355693f50651c7090aeaa5e7eb15187eb9a37855a785aaa259991cb1b43f90.

BEGIN;

DO $oa198_preflight$
DECLARE
  v_frontier_count integer;
  v_current_count integer;
  v_unexpected_versions text;
BEGIN
  IF pg_catalog.to_regclass(
       'supabase_migrations.schema_migrations'
     ) IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = '55000',
      MESSAGE = 'OA-ZYRA-198 bridge refused: migration history is unavailable';
  END IF;

  IF pg_catalog.to_regclass('public.zyra_seed_ch4_questions') IS NOT NULL
     OR pg_catalog.to_regclass('public.zyra_onboarding_questions') IS NOT NULL
  THEN
    RAISE EXCEPTION USING
      ERRCODE = '55000',
      MESSAGE = 'OA-ZYRA-198 bridge refused: old or canonical bank already exists';
  END IF;

  SELECT pg_catalog.count(*)
    INTO v_frontier_count
    FROM supabase_migrations.schema_migrations
   WHERE version::text = '20260811152809';

  IF v_frontier_count <> 1 THEN
    RAISE EXCEPTION USING
      ERRCODE = '55000',
      MESSAGE = 'OA-ZYRA-198 bridge refused: exact 20260811152809 frontier is absent';
  END IF;

  SELECT pg_catalog.count(*)
    INTO v_current_count
    FROM supabase_migrations.schema_migrations
   WHERE version::text = '20260811153415';

  IF v_current_count <> 0 THEN
    RAISE EXCEPTION USING
      ERRCODE = '55000',
      MESSAGE = 'OA-ZYRA-198 bridge refused: 20260811153415 is already recorded';
  END IF;

  IF EXISTS (
    SELECT 1
      FROM supabase_migrations.schema_migrations
     WHERE version::text >= '20260811153416'
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '55000',
      MESSAGE = 'OA-ZYRA-198 bridge refused: 20260811153416 or later already ran';
  END IF;

  SELECT pg_catalog.string_agg(
           version::text,
           ', ' ORDER BY version::text
         )
    INTO v_unexpected_versions
    FROM supabase_migrations.schema_migrations
   WHERE version::text > '20260811152809'
     AND version::text < '20260811153416';

  IF v_unexpected_versions IS NOT NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = '55000',
      MESSAGE = 'OA-ZYRA-198 bridge refused: unexpected frontier version(s): '
                || v_unexpected_versions;
  END IF;
END
$oa198_preflight$;

CREATE TEMPORARY TABLE oa198_expected_question_bank (
  qid text NOT NULL,
  gender_visibility text NOT NULL,
  is_multi boolean NOT NULL,
  options jsonb NOT NULL,
  PRIMARY KEY (qid, gender_visibility)
) ON COMMIT DROP;

DO $oa198_load$
DECLARE
  v_projection CONSTANT text := $oa198_rows$[{"gender_visibility":"all","is_multi":false,"options":["Never Married","Separated","Divorced","Annulled","Widowed","Currently Married"],"qid":"ch3_q1"},{"gender_visibility":"all","is_multi":false,"options":["No","Yes, living with me","Yes, shared custody","Yes, living elsewhere"],"qid":"ch3_q2"},{"gender_visibility":"all","is_multi":false,"options":["Yes","No","If Allah wills","Unsure"],"qid":"ch3_q3"},{"gender_visibility":"all","is_multi":false,"options":["Very involved","Some involvement","Only when needed","Minimal involvement"],"qid":"ch3_q4"},{"gender_visibility":"all","is_multi":false,"options":["Daily","Weekly","Fortnightly","Monthly","Occasionally","Rarely"],"qid":"ch3_q5"},{"gender_visibility":"all","is_multi":false,"options":["Same home","Same neighbourhood","Same city","Same country","No preference"],"qid":"ch3_q6"},{"gender_visibility":"all","is_multi":false,"options":["Yes, regularly","Occasionally","Not currently"],"qid":"ch3_q7"},{"gender_visibility":"all","is_multi":false,"options":["I expect us both to help","I would mainly take responsibility","I'd support where possible","It depends on the circumstances"],"qid":"ch3_q8"},{"gender_visibility":"all","is_multi":false,"options":["Yes","For a short period only","Only if necessary","No"],"qid":"ch3_q9"},{"gender_visibility":"all","is_multi":false,"options":["No Formal Qualification","Secondary School / GCSE","College / A Levels / Equivalent","Diploma","Bachelor's Degree","Master's Degree","Doctorate (PhD)","Islamic Studies Qualification","Other"],"qid":"ch3_q11"},{"gender_visibility":"all","is_multi":false,"options":["Under £20,000","£20,000 – £39,999","£40,000 – £59,999","£60,000 – £79,999","£80,000 – £99,999","£100,000+"],"qid":"ch3_q12"},{"gender_visibility":"all","is_multi":false,"options":["Ready now","Mostly ready","Still preparing","Just beginning my journey"],"qid":"ch3_q13"},{"gender_visibility":"all","is_multi":false,"options":["I save consistently","I save when I can","I'm just starting to save","I'm not currently saving"],"qid":"ch3_q14"},{"gender_visibility":"all","is_multi":false,"options":["Very organised","Mostly organised","Fairly relaxed","Improving my financial habits"],"qid":"ch3_q15"},{"gender_visibility":"all","is_multi":false,"options":["Extremely important","Important","Moderately important","Not a major priority"],"qid":"ch3_q16"},{"gender_visibility":"all","is_multi":false,"options":["I plan to continue working","I'd prefer to reduce my working hours","I'd prefer not to work","It depends on our circumstances"],"qid":"ch3_q18"},{"gender_visibility":"all","is_multi":false,"options":["No debt","Mortgage only","Student finance only","Personal debt","Business debt","Multiple types of debt"],"qid":"ch3_q20"},{"gender_visibility":"all","is_multi":false,"options":["Very careful spender","Balanced spender","Enjoy spending when appropriate","Working on improving my spending habits"],"qid":"ch3_q22"},{"gender_visibility":"all","is_multi":false,"options":["As soon as possible","Within 6 months","Within 1 year","Within 2 years","I'm flexible"],"qid":"ch3_q23"},{"gender_visibility":"all","is_multi":false,"options":["As soon as possible","Within 1 year","Within 2–3 years","After 3 years","I'll decide together with my spouse","If Allah wills"],"qid":"ch3_q24"},{"gender_visibility":"all","is_multi":false,"options":["Monogamous Marriage","Open to Polygamous Marriage","Currently in a Polygamous Marriage"],"qid":"ch3_q25"},{"gender_visibility":"menOnly","is_multi":false,"options":["I only wish to have one wife","I'm open to more than one wife in the future","I already have more than one wife","I'm unsure"],"qid":"ch3_q26"},{"gender_visibility":"womenOnly","is_multi":false,"options":["I would only marry as the only wife","I would consider being a first wife in a future polygamous marriage","I would consider being an additional wife","I'm unsure"],"qid":"ch3_q26"},{"gender_visibility":"all","is_multi":false,"options":["Anywhere","Within my country","Internationally","Only for the right person","I'd prefer not to relocate"],"qid":"ch3_q28"},{"gender_visibility":"all","is_multi":false,"options":["I would prefer homeschooling","I would prefer mainstream schooling","I would consider either","I haven't thought about it yet"],"qid":"ch3_q29"},{"gender_visibility":"all","is_multi":false,"options":["Very important","Quite important","Nice occasionally","Not particularly important"],"qid":"ch3_q30"},{"gender_visibility":"all","is_multi":false,"options":["I'd like to move quickly if we're compatible","A balanced pace","I'd prefer to take things slowly","It depends on the situation"],"qid":"ch3_q31"},{"gender_visibility":"all","is_multi":false,"options":["Every prayer, every day","Usually all five prayers","Most days","Occasionally","I'm working towards praying consistently"],"qid":"ch3_q33"},{"gender_visibility":"all","is_multi":false,"options":["Daily","Several times a week","Weekly","Occasionally","I'm working towards reading more regularly"],"qid":"ch3_q34"},{"gender_visibility":"all","is_multi":false,"options":["None yet","Juz 'Amma (30th Juz)","1–5 Juz","6–10 Juz","11–20 Juz","More than 20 Juz","Hafiz / Hafizah"],"qid":"ch3_q35"},{"gender_visibility":"all","is_multi":false,"options":["Every year","Most years","Sometimes","I have valid exemptions","I'm working towards fasting consistently"],"qid":"ch3_q36"},{"gender_visibility":"all","is_multi":true,"options":["None","Mondays","Thursdays","Mondays & Thursdays","White Days (13th, 14th & 15th)","Day of Arafah","Ashura","Six Days of Shawwal","During Sha'ban","Other Sunnah Fasts"],"qid":"ch3_q37"},{"gender_visibility":"all","is_multi":false,"options":["Always","Usually","Sometimes","I'm still learning about Zakat","Zakat is not currently due upon me"],"qid":"ch3_q38"},{"gender_visibility":"menOnly","is_multi":false,"options":["Every prayer, every day","Most daily prayers","Jumu'ah (Friday) only","Occasionally","I'm working towards attending more regularly"],"qid":"ch3_q39"},{"gender_visibility":"all","is_multi":false,"options":["Regularly","Occasionally","Rarely","Whenever I have the opportunity"],"qid":"ch3_q40"},{"gender_visibility":"all","is_multi":false,"options":["A major part of my life","Very important","Important","Somewhat important","I'm trying to improve"],"qid":"ch3_q43"},{"gender_visibility":"all","is_multi":false,"options":["Weekly","Monthly","Occasionally","Rarely","Not currently"],"qid":"ch3_q44"},{"gender_visibility":"all","is_multi":false,"options":["Hanafi","Maliki","Shafi'i","Hanbali","I benefit from all recognised Madhhabs","I'm still learning"],"qid":"ch3_q46"},{"gender_visibility":"all","is_multi":false,"options":["I completely avoid them","I avoid them whenever possible","I'm currently trying to move away from them","I'm still learning about this topic"],"qid":"ch3_q47"},{"gender_visibility":"all","is_multi":false,"options":["Essential","Very important","Important","Somewhat important"],"qid":"ch3_q48"},{"gender_visibility":"all","is_multi":false,"options":["Regularly","Occasionally","Rarely","I'm working towards it"],"qid":"ch3_q49"},{"gender_visibility":"all","is_multi":false,"options":["Daily","Most days","Occasionally","Rarely","I'm working towards making it a habit"],"qid":"ch3_q50"},{"gender_visibility":"all","is_multi":false,"options":["I avoid both pictures and statues","I avoid statues but accept photographs","I don't mind either","I'm still learning about this topic"],"qid":"ch3_q51"},{"gender_visibility":"all","is_multi":false,"options":["I don't smoke or vape","I vape only","I smoke only","I both smoke and vape","I'm trying to quit"],"qid":"ch3_q52"},{"gender_visibility":"all","is_multi":false,"options":["I never drink alcohol","I previously drank but no longer do","I'm trying to stop drinking"],"qid":"ch3_q53"},{"gender_visibility":"all","is_multi":false,"options":["I only eat Halal food","I always avoid pork and alcohol, but Halal is not always available","I'm improving in this area"],"qid":"ch3_q54"},{"gender_visibility":"all","is_multi":false,"options":["I completely avoid music","I mostly avoid music","I listen occasionally","I'm still learning about this topic"],"qid":"ch3_q55"},{"gender_visibility":"all","is_multi":false,"options":["Very active","Active","Occasionally active","Rarely active","I'm working on becoming more active"],"qid":"ch3_q56"},{"gender_visibility":"all","is_multi":false,"options":["I enjoy having pets","I'm happy either way","I'd prefer not to have pets","It depends on the type of pet"],"qid":"ch3_q57"},{"gender_visibility":"all","is_multi":false,"options":["I love hosting","I'm happy to host occasionally","Only for close family","I'd rather keep things private"],"qid":"ch3_q60"},{"gender_visibility":"all","is_multi":false,"options":["Introvert","Ambivert","Extrovert"],"qid":"ch3_q61"},{"gender_visibility":"all","is_multi":false,"options":["Family always comes first","I try to balance family and career equally","Career is my current priority","It depends on my stage of life"],"qid":"ch3_q63"},{"gender_visibility":"all","is_multi":false,"options":["Mostly traditional roles","Shared equally","Based on each person's circumstances","Flexible depending on our situation","We'll decide together as our marriage develops"],"qid":"ch3_q64"},{"gender_visibility":"all","is_multi":false,"options":["I enjoy cooking regularly","I don't mind cooking","I'd prefer to share cooking responsibilities","I'd rather cook only occasionally","It depends on our circumstances"],"qid":"ch3_q65"},{"gender_visibility":"all","is_multi":false,"options":["Shared equally","Mostly by me","Mostly by my spouse","Whoever has more time","We would consider hiring help if possible"],"qid":"ch3_q66"},{"gender_visibility":"all","is_multi":false,"options":["Husband","Mostly husband, but both may contribute","Shared responsibility","Depends on our circumstances"],"qid":"ch3_q67"},{"gender_visibility":"all","is_multi":false,"options":["Completely shared finances","Mostly shared with some personal finances","Mostly separate finances","We'd decide together after marriage"],"qid":"ch3_q68"},{"gender_visibility":"all","is_multi":false,"options":["Joint discussion before every major decision","Husband leads after discussion","Depends on the situation","Every decision should be mutual"],"qid":"ch3_q70"},{"gender_visibility":"all","is_multi":false,"options":["Quiet and peaceful","Family-centred and lively","Frequently hosting guests","A balance of both"],"qid":"ch3_q71"},{"gender_visibility":"all","is_multi":false,"options":["Highly structured","Fairly organised","Flexible","I prefer not to follow a routine"],"qid":"ch3_q72"},{"gender_visibility":"all","is_multi":false,"options":["Very important","Important","Somewhat important","I prefer spending most of my time together"],"qid":"ch3_q73"},{"gender_visibility":"all","is_multi":false,"options":["Open and direct","Calm and thoughtful","Quiet until I'm comfortable","It depends on the situation"],"qid":"ch3_q74"},{"gender_visibility":"all","is_multi":false,"options":["I prefer to resolve things immediately","I like some time to think before talking","I stay calm and discuss it later","It depends on the situation"],"qid":"ch3_q75"},{"gender_visibility":"all","is_multi":false,"options":["After discussing everything together","I like taking the lead after discussion","I prefer my spouse to lead after discussion","It depends on the situation"],"qid":"ch3_q78"},{"gender_visibility":"all","is_multi":false,"options":["Islamic mediation","Professional marriage counselling","Family mediation","A combination depending on the situation"],"qid":"ch3_q81"},{"gender_visibility":"all","is_multi":false,"options":["Essential","Very important","Important","Nice when possible"],"qid":"ch3_q84"},{"gender_visibility":"all","is_multi":false,"options":["Completely private","Mostly private","Comfortable sharing major milestones","Fairly open with close family and friends"],"qid":"ch3_q85"},{"gender_visibility":"all","is_multi":false,"options":["I don't use social media","Private accounts for family and friends only","Active but mostly private","Public and regularly active"],"qid":"ch3_q86"},{"gender_visibility":"all","is_multi":false,"options":["I prefer to keep everything private","I am happy sharing major milestones only","Occasionally sharing is fine","I am comfortable sharing regularly"],"qid":"ch3_q87"},{"gender_visibility":"all","is_multi":false,"options":["Extremely important","Very important","Important","I haven't really thought about it"],"qid":"ch3_q90"},{"gender_visibility":"all","is_multi":false,"options":["Extremely important","Very important","Moderately important","I'm trying to make it more important"],"qid":"ch3_q95"},{"gender_visibility":"all","is_multi":true,"options":["None","Vegetarian","Vegan","Gluten Free","Dairy Free","Nut Allergy","Seafood Allergy","Other Food Allergy"],"qid":"ch3_q97"}]$oa198_rows$;
  v_projection_json jsonb;
BEGIN
  IF pg_catalog.octet_length(v_projection) <> 12927 THEN
    RAISE EXCEPTION 'OA-ZYRA-198 canonical projection byte length changed';
  END IF;

  IF pg_catalog.encode(
       pg_catalog.sha256(pg_catalog.convert_to(v_projection, 'UTF8')),
       'hex'
     ) <> 'eb355693f50651c7090aeaa5e7eb15187eb9a37855a785aaa259991cb1b43f90'
  THEN
    RAISE EXCEPTION 'OA-ZYRA-198 canonical projection SHA-256 changed';
  END IF;

  v_projection_json := v_projection::jsonb;

  IF pg_catalog.jsonb_typeof(v_projection_json) <> 'array'
     OR pg_catalog.jsonb_array_length(v_projection_json) <> 72
  THEN
    RAISE EXCEPTION 'OA-ZYRA-198 canonical projection is not the pinned 72-row array';
  END IF;

  INSERT INTO pg_temp.oa198_expected_question_bank (
    qid,
    gender_visibility,
    is_multi,
    options
  )
  SELECT row.qid,
         row.gender_visibility,
         row.is_multi,
         row.options
    FROM pg_catalog.jsonb_to_recordset(v_projection_json)
           AS row(
             gender_visibility text,
             is_multi boolean,
             options jsonb,
             qid text
           );

  IF (SELECT pg_catalog.count(*)
        FROM pg_temp.oa198_expected_question_bank) <> 72
     OR
     (SELECT pg_catalog.count(DISTINCT qid)
        FROM pg_temp.oa198_expected_question_bank) <> 71
  THEN
    RAISE EXCEPTION 'OA-ZYRA-198 canonical projection count contract failed';
  END IF;

  IF EXISTS (
    SELECT 1
      FROM pg_temp.oa198_expected_question_bank
     WHERE qid !~ '^ch3_q[1-9][0-9]*$'
        OR gender_visibility NOT IN ('all', 'menOnly', 'womenOnly')
        OR pg_catalog.jsonb_typeof(options) <> 'array'
        OR pg_catalog.jsonb_array_length(options) = 0
  ) THEN
    RAISE EXCEPTION 'OA-ZYRA-198 canonical projection value contract failed';
  END IF;

  IF EXISTS (
    SELECT 1
      FROM pg_temp.oa198_expected_question_bank bank
      CROSS JOIN LATERAL pg_catalog.jsonb_array_elements(bank.options) item
     WHERE pg_catalog.jsonb_typeof(item.value) <> 'string'
  ) THEN
    RAISE EXCEPTION 'OA-ZYRA-198 canonical projection contains a non-text option';
  END IF;
END
$oa198_load$;

CREATE TABLE public.zyra_seed_ch4_questions (
  qid text NOT NULL,
  gender_visibility text NOT NULL,
  is_multi boolean NOT NULL,
  options jsonb NOT NULL,
  CONSTRAINT zyra_seed_ch4_questions_pkey
    PRIMARY KEY (qid, gender_visibility)
);

ALTER TABLE public.zyra_seed_ch4_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.zyra_seed_ch4_questions NO FORCE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.zyra_seed_ch4_questions FROM PUBLIC;
REVOKE ALL ON TABLE public.zyra_seed_ch4_questions FROM anon;
REVOKE ALL ON TABLE public.zyra_seed_ch4_questions FROM authenticated;

INSERT INTO public.zyra_seed_ch4_questions (
  qid,
  gender_visibility,
  is_multi,
  options
)
SELECT qid,
       gender_visibility,
       is_multi,
       options
  FROM pg_temp.oa198_expected_question_bank
 ORDER BY
       (pg_catalog.substring(qid, '[0-9]+$'))::integer,
       gender_visibility;

DO $oa198_postconditions$
DECLARE
  v_columns jsonb;
  v_constraint_count integer;
  v_index_count integer;
  v_owner name;
  v_rls boolean;
  v_force_rls boolean;
  v_policy_count integer;
  v_unexpected_acl_count integer;
  v_column_acl_count integer;
  v_multi_qids text[];
  v_q26_variants text[];
  v_later_overlap integer;
  v_relation oid := 'public.zyra_seed_ch4_questions'::regclass;
BEGIN
  IF (SELECT pg_catalog.count(*)
        FROM public.zyra_seed_ch4_questions) <> 72
     OR
     (SELECT pg_catalog.count(DISTINCT qid)
        FROM public.zyra_seed_ch4_questions) <> 71
  THEN
    RAISE EXCEPTION 'OA-ZYRA-198 reconstructed bank count contract failed';
  END IF;

  IF EXISTS (
    (
      SELECT qid, gender_visibility, is_multi, options
        FROM public.zyra_seed_ch4_questions
      EXCEPT ALL
      SELECT qid, gender_visibility, is_multi, options
        FROM pg_temp.oa198_expected_question_bank
    )
    UNION ALL
    (
      SELECT qid, gender_visibility, is_multi, options
        FROM pg_temp.oa198_expected_question_bank
      EXCEPT ALL
      SELECT qid, gender_visibility, is_multi, options
        FROM public.zyra_seed_ch4_questions
    )
  ) THEN
    RAISE EXCEPTION 'OA-ZYRA-198 reconstructed bank differs from canonical projection';
  END IF;

  SELECT pg_catalog.array_agg(gender_visibility ORDER BY gender_visibility)
    INTO v_q26_variants
    FROM public.zyra_seed_ch4_questions
   WHERE qid = 'ch3_q26';

  IF v_q26_variants <> ARRAY['menOnly', 'womenOnly']::text[] THEN
    RAISE EXCEPTION 'OA-ZYRA-198 ch3_q26 gender variants changed';
  END IF;

  IF (SELECT pg_catalog.count(*)
        FROM (
          SELECT qid
            FROM public.zyra_seed_ch4_questions
           GROUP BY qid
          HAVING pg_catalog.count(*) > 1
        ) duplicate_qids) <> 1 THEN
    RAISE EXCEPTION 'OA-ZYRA-198 ch3_q26 is not the sole duplicate qid';
  END IF;

  IF (SELECT pg_catalog.count(*)
        FROM public.zyra_seed_ch4_questions
       WHERE qid = 'ch3_q39'
         AND gender_visibility = 'menOnly') <> 1
     OR
     (SELECT pg_catalog.count(*)
        FROM public.zyra_seed_ch4_questions
       WHERE qid = 'ch3_q39') <> 1
  THEN
    RAISE EXCEPTION 'OA-ZYRA-198 ch3_q39 visibility changed';
  END IF;

  SELECT pg_catalog.array_agg(qid ORDER BY qid)
    INTO v_multi_qids
    FROM (
      SELECT DISTINCT qid
        FROM public.zyra_seed_ch4_questions
       WHERE is_multi
    ) multi_rows;

  IF v_multi_qids <> ARRAY['ch3_q37', 'ch3_q97']::text[] THEN
    RAISE EXCEPTION 'OA-ZYRA-198 scored multi-select set changed';
  END IF;

  SELECT pg_catalog.count(*)
    INTO v_later_overlap
    FROM public.zyra_seed_ch4_questions
   WHERE qid = ANY (
     ARRAY[
       'ch3_q10', 'ch3_q17', 'ch3_q19', 'ch3_q21', 'ch3_q27',
       'ch3_q32', 'ch3_q41', 'ch3_q42', 'ch3_q45', 'ch3_q58',
       'ch3_q59', 'ch3_q62', 'ch3_q69', 'ch3_q76', 'ch3_q77',
       'ch3_q79', 'ch3_q80', 'ch3_q82', 'ch3_q83', 'ch3_q88',
       'ch3_q89', 'ch3_q91', 'ch3_q92', 'ch3_q93', 'ch3_q94',
       'ch3_q96', 'ch3_q98', 'ch3_q99', 'ch3_q100', 'ch3_q101',
       'ch3_q102', 'ch3_q103', 'ch3_q104'
     ]::text[]
   );

  IF v_later_overlap <> 0 THEN
    RAISE EXCEPTION 'OA-ZYRA-198 bridge overlaps the 33 later non-scored rows';
  END IF;

  SELECT pg_catalog.jsonb_agg(
           pg_catalog.jsonb_build_object(
             'name', attribute.attname,
             'type', pg_catalog.format_type(
               attribute.atttypid,
               attribute.atttypmod
             ),
             'not_null', attribute.attnotnull,
             'default', pg_catalog.pg_get_expr(
               attribute_default.adbin,
               attribute_default.adrelid
             )
           )
           ORDER BY attribute.attnum
         )
    INTO v_columns
    FROM pg_catalog.pg_attribute attribute
    LEFT JOIN pg_catalog.pg_attrdef attribute_default
      ON attribute_default.adrelid = attribute.attrelid
     AND attribute_default.adnum = attribute.attnum
   WHERE attribute.attrelid = v_relation
     AND attribute.attnum > 0
     AND NOT attribute.attisdropped;

  IF v_columns <> '[
    {"name":"qid","type":"text","not_null":true,"default":null},
    {"name":"gender_visibility","type":"text","not_null":true,"default":null},
    {"name":"is_multi","type":"boolean","not_null":true,"default":null},
    {"name":"options","type":"jsonb","not_null":true,"default":null}
  ]'::jsonb THEN
    RAISE EXCEPTION 'OA-ZYRA-198 reconstructed column contract changed';
  END IF;

  SELECT pg_catalog.count(*)
    INTO v_constraint_count
    FROM pg_catalog.pg_constraint constraint_row
   WHERE constraint_row.conrelid = v_relation;

  IF v_constraint_count <> 1
     OR NOT EXISTS (
       SELECT 1
         FROM pg_catalog.pg_constraint constraint_row
        WHERE constraint_row.conrelid = v_relation
          AND constraint_row.conname = 'zyra_seed_ch4_questions_pkey'
          AND constraint_row.contype = 'p'
          AND constraint_row.conkey = ARRAY[1, 2]::smallint[]
     )
  THEN
    RAISE EXCEPTION 'OA-ZYRA-198 reconstructed primary-key contract changed';
  END IF;

  SELECT pg_catalog.count(*)
    INTO v_index_count
    FROM pg_catalog.pg_index index_row
   WHERE index_row.indrelid = v_relation;

  IF v_index_count <> 1
     OR NOT EXISTS (
       SELECT 1
         FROM pg_catalog.pg_index index_row
        WHERE index_row.indrelid = v_relation
          AND index_row.indisprimary
          AND index_row.indisunique
     )
  THEN
    RAISE EXCEPTION 'OA-ZYRA-198 reconstructed index contract changed';
  END IF;

  SELECT pg_catalog.pg_get_userbyid(class_row.relowner),
         class_row.relrowsecurity,
         class_row.relforcerowsecurity
    INTO v_owner, v_rls, v_force_rls
    FROM pg_catalog.pg_class class_row
   WHERE class_row.oid = v_relation
     AND class_row.relkind = 'r';

  IF v_owner IS DISTINCT FROM current_user::name
     OR v_rls IS DISTINCT FROM true
     OR v_force_rls IS DISTINCT FROM false
  THEN
    RAISE EXCEPTION 'OA-ZYRA-198 reconstructed owner/RLS contract changed';
  END IF;

  SELECT pg_catalog.count(*)
    INTO v_policy_count
    FROM pg_catalog.pg_policy policy_row
   WHERE policy_row.polrelid = v_relation;

  IF v_policy_count <> 0 THEN
    RAISE EXCEPTION 'OA-ZYRA-198 reconstructed table unexpectedly has RLS policies';
  END IF;

  SELECT pg_catalog.count(*)
    INTO v_unexpected_acl_count
    FROM pg_catalog.pg_class class_row
    CROSS JOIN LATERAL pg_catalog.aclexplode(
      COALESCE(
        class_row.relacl,
        pg_catalog.acldefault('r', class_row.relowner)
      )
    ) acl
    LEFT JOIN pg_catalog.pg_roles role_row
      ON role_row.oid = acl.grantee
   WHERE class_row.oid = v_relation
     AND acl.grantee <> class_row.relowner
     AND role_row.rolname IS DISTINCT FROM 'service_role';

  IF v_unexpected_acl_count <> 0 THEN
    RAISE EXCEPTION 'OA-ZYRA-198 reconstructed table has an unexpected table ACL';
  END IF;

  SELECT pg_catalog.count(*)
    INTO v_column_acl_count
    FROM pg_catalog.pg_attribute attribute
    JOIN pg_catalog.pg_class class_row
      ON class_row.oid = attribute.attrelid
    CROSS JOIN LATERAL pg_catalog.aclexplode(
      COALESCE(
        attribute.attacl,
        pg_catalog.acldefault('c', class_row.relowner)
      )
    ) acl
   WHERE attribute.attrelid = v_relation
     AND attribute.attnum > 0
     AND NOT attribute.attisdropped;

  IF v_column_acl_count <> 0 THEN
    RAISE EXCEPTION 'OA-ZYRA-198 reconstructed table has a column ACL';
  END IF;

  IF EXISTS (
    SELECT 1
      FROM (
        VALUES ('anon'::name), ('authenticated'::name)
      ) denied_roles(role_name)
      CROSS JOIN (
        VALUES
          ('SELECT'::text),
          ('INSERT'::text),
          ('UPDATE'::text),
          ('DELETE'::text),
          ('TRUNCATE'::text),
          ('REFERENCES'::text),
          ('TRIGGER'::text),
          ('MAINTAIN'::text)
      ) table_privileges(privilege_name)
     WHERE pg_catalog.has_table_privilege(
             denied_roles.role_name,
             v_relation,
             table_privileges.privilege_name
           )
  ) THEN
    RAISE EXCEPTION 'OA-ZYRA-198 reconstructed table exposes an effective client privilege';
  END IF;

  IF EXISTS (
    SELECT 1
      FROM (
        VALUES ('anon'::name), ('authenticated'::name)
      ) denied_roles(role_name)
      CROSS JOIN (
        VALUES
          ('qid'::text),
          ('gender_visibility'::text),
          ('is_multi'::text),
          ('options'::text)
      ) bank_columns(column_name)
      CROSS JOIN (
        VALUES
          ('SELECT'::text),
          ('INSERT'::text),
          ('UPDATE'::text),
          ('REFERENCES'::text)
      ) column_privileges(privilege_name)
     WHERE pg_catalog.has_column_privilege(
             denied_roles.role_name,
             v_relation,
             bank_columns.column_name,
             column_privileges.privilege_name
           )
  ) THEN
    RAISE EXCEPTION 'OA-ZYRA-198 reconstructed table exposes an effective client column privilege';
  END IF;
END
$oa198_postconditions$;

COMMIT;
