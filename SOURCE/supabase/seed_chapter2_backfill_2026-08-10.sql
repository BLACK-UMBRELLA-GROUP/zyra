-- ═══════════════════════════════════════════════════════════════════════
-- CHAPTER 2 BACKFILL — 120 seeded Seekers, UK-representative distribution
--
-- Founder decision 2026-08-10: "Match the real UK distribution".
-- Applied 2026-08-10. Findings in
-- SYSTEM/DOCUMENTS/ZYRA_CHAPTER2_BACKFILL_AND_WEIGHT_FINDINGS_2026-08-10.md
--
-- SOURCES. Census 2021 (England & Wales) for ethnicity and the UK-born
-- share. The census does not ask denomination, so sect comes from the Techne
-- survey for the Institute for the Impact of Faith in Life: Sunni 83.8%,
-- Shia 7.5%, other/non-denominational 8.7%.
--
-- SECT IS CORRELATED WITH HERITAGE, NOT SPRINKLED AT RANDOM. Every Persian
-- Seeker is Shia; Arabs are mixed; Bangladeshis are almost entirely Sunni. A
-- flat 84/7.5/8.7 scattered across ethnicities would produce test data that
-- agrees with itself and measures nothing — which is the whole reason the
-- Founder was asked before it was seeded.
--
-- CODES, NEVER LABELS (zyra_reference_data.dart). ISO 3166-1 alpha-2 for
-- countries, ISO 639-1 for languages, ZYRA codes for ethnicity. Every value
-- was checked against the reference lists before insert.
--
-- SAFE TO RE-RUN. Deterministic: assignment is by row_number() over
-- profiles.id, no random(). Touches only Seekers with NO seeker_details row,
-- so the 24 pre-existing rows are never modified and a second run is a no-op.
-- ═══════════════════════════════════════════════════════════════════════
WITH targets AS (
  SELECT p.id, row_number() OVER (ORDER BY p.id) AS rn
  FROM profiles p
  WHERE p.role = 'seeker'
    AND NOT EXISTS (SELECT 1 FROM seeker_details s WHERE s.user_id = p.id)
),
mix(code, n) AS (VALUES
  ('pakistani',41),('bangladeshi',21),('indian',10),('somali',7),('black_african',6),
  ('arab',7),('north_african',2),('afghan',3),('sri_lankan',1),('central_asian',1),
  ('malay',1),('indonesian',1),('white_european',5),('bosnian',1),('albanian',1),
  ('mixed',4),('turkish',4),('kurdish',2),('persian',2)
),
expanded AS (
  SELECT m.code,
         row_number() OVER (ORDER BY m.code, g)             AS rn,
         row_number() OVER (PARTITION BY m.code ORDER BY g) AS i
  FROM mix m, generate_series(1, m.n) g
),
assigned AS (
  SELECT t.id, t.rn, e.code AS ethnicity, e.i,
    CASE
      WHEN e.code = 'persian'                              THEN 'shia'
      WHEN e.code = 'arab'           AND e.i <= 2          THEN 'shia'
      WHEN e.code = 'pakistani'      AND e.i <= 3          THEN 'shia'
      WHEN e.code = 'indian'         AND e.i <= 2          THEN 'shia'
      WHEN e.code = 'pakistani'      AND e.i BETWEEN 4 AND 7 THEN 'other'
      WHEN e.code = 'white_european' AND e.i <= 2          THEN 'other'
      WHEN e.code = 'mixed'          AND e.i <= 2          THEN 'other'
      WHEN e.code = 'turkish'        AND e.i = 1           THEN 'other'
      WHEN e.code = 'bangladeshi'    AND e.i = 1           THEN 'other'
      ELSE 'sunni'
    END AS sect,
    CASE e.code
      WHEN 'pakistani' THEN 'PK' WHEN 'bangladeshi' THEN 'BD' WHEN 'indian' THEN 'IN'
      WHEN 'somali' THEN 'SO'    WHEN 'black_african' THEN 'NG'
      WHEN 'arab' THEN (ARRAY['IQ','SY','EG','YE','LB','JO','SA'])[e.i]
      WHEN 'north_african' THEN (ARRAY['MA','DZ'])[e.i]
      WHEN 'afghan' THEN 'AF'    WHEN 'sri_lankan' THEN 'LK'
      WHEN 'central_asian' THEN 'UZ' WHEN 'malay' THEN 'MY' WHEN 'indonesian' THEN 'ID'
      WHEN 'bosnian' THEN 'BA'   WHEN 'albanian' THEN 'AL'
      WHEN 'turkish' THEN 'TR'   WHEN 'kurdish' THEN 'IQ' WHEN 'persian' THEN 'IR'
      ELSE 'GB'
    END AS heritage_country,
    CASE e.code
      WHEN 'pakistani'     THEN CASE WHEN e.i % 3 = 0 THEN ARRAY['en','ur','pa'] ELSE ARRAY['en','ur'] END
      WHEN 'bangladeshi'   THEN ARRAY['en','bn']
      WHEN 'indian'        THEN CASE WHEN e.i % 2 = 0 THEN ARRAY['en','hi'] ELSE ARRAY['en','gu'] END
      WHEN 'somali'        THEN ARRAY['en','so']
      WHEN 'black_african' THEN CASE WHEN e.i % 2 = 0 THEN ARRAY['en','ha'] ELSE ARRAY['en','sw'] END
      WHEN 'arab'          THEN ARRAY['en','ar']
      WHEN 'north_african' THEN ARRAY['en','ar','fr']
      WHEN 'afghan'        THEN CASE WHEN e.i % 2 = 0 THEN ARRAY['en','fa'] ELSE ARRAY['en','ps'] END
      WHEN 'sri_lankan'    THEN ARRAY['en','ta']
      WHEN 'central_asian' THEN ARRAY['en','ru']
      WHEN 'malay'         THEN ARRAY['en','ms']
      WHEN 'indonesian'    THEN ARRAY['en','id']
      WHEN 'bosnian'       THEN ARRAY['en','bs']
      WHEN 'albanian'      THEN ARRAY['en','sq']
      WHEN 'turkish'       THEN ARRAY['en','tr']
      WHEN 'kurdish'       THEN ARRAY['en','ku']
      WHEN 'persian'       THEN ARRAY['en','fa']
      ELSE ARRAY['en']
    END AS langs,
    -- Census 2021: 51% of Muslims in E&W were born in the UK. Converts and
    -- mixed-heritage Seekers are UK-born by construction, which lifts the
    -- realised figure to 54%.
    CASE WHEN e.code IN ('white_european','mixed') OR e.i % 2 = 1 THEN true ELSE false END AS uk_born,
    CASE WHEN (e.code = 'white_european' AND e.i <= 3)
           OR (e.code = 'mixed' AND e.i = 1)
           OR (e.code = 'black_african' AND e.i = 1) THEN true ELSE false END AS is_revert
  FROM targets t
  JOIN expanded e ON e.rn = t.rn
)
INSERT INTO seeker_details (user_id, sect, revert_status, country_of_birth, nationality, ethnicity, languages, preferences)
SELECT
  a.id,
  a.sect,
  a.is_revert,
  CASE WHEN a.uk_born THEN 'GB' ELSE a.heritage_country END,
  CASE WHEN a.uk_born OR a.rn % 3 <> 0 THEN 'GB' ELSE a.heritage_country END,
  a.ethnicity,
  a.langs,
  jsonb_build_object(
    'sect', jsonb_build_object(
      'matrix', jsonb_build_object(
        'Sunni', CASE WHEN a.sect='sunni' THEN 'green' WHEN a.rn % 4 = 0 THEN 'red' ELSE 'yellow' END,
        'Shia',  CASE WHEN a.sect='shia'  THEN 'green' WHEN a.rn % 4 = 0 THEN 'red' ELSE 'yellow' END,
        'Other', CASE WHEN a.sect='other' THEN 'green' WHEN a.rn % 4 = 0 THEN 'red' ELSE 'yellow' END),
      'hard_requirement', (a.rn % 4 = 0),
      'outside_flexibility', CASE WHEN a.rn % 4 = 0 THEN 'red' ELSE 'yellow' END),
    'revert', jsonb_build_object('flexibility', CASE WHEN a.rn % 5 = 0 THEN 'yellow' ELSE 'green' END),
    'location', jsonb_build_object(
      'preference', CASE WHEN a.rn % 3 = 0 THEN 'same_country' ELSE 'same_city' END,
      'flexibility', 'green'),
    'ethnicity', jsonb_build_object(
      'skipped', (a.rn % 4 = 1),
      'preferred', CASE WHEN a.rn % 4 = 1 THEN '[]'::jsonb ELSE to_jsonb(ARRAY[a.ethnicity]) END,
      'flexibility', CASE WHEN a.rn % 3 = 0 THEN 'yellow' ELSE 'green' END),
    'languages', jsonb_build_object(
      'skipped', false,
      'preferred', to_jsonb(a.langs),
      'flexibility', CASE WHEN a.rn % 3 = 1 THEN 'yellow' ELSE 'green' END),
    'nationality', jsonb_build_object(
      'skipped', (a.rn % 3 = 0),
      'preferred', CASE WHEN a.rn % 3 = 0 THEN '[]'::jsonb ELSE '["GB"]'::jsonb END,
      'flexibility', 'green'),
    'country_of_birth', jsonb_build_object(
      'skipped', (a.rn % 5 <> 0),
      'preferred', CASE WHEN a.rn % 5 = 0 THEN to_jsonb(ARRAY[CASE WHEN a.uk_born THEN 'GB' ELSE a.heritage_country END]) ELSE '[]'::jsonb END,
      'flexibility', 'yellow')
  )
FROM assigned a;

-- ── verification ───────────────────────────────────────────────────────
-- Expected after a clean run: 144 rows, 0 seekers without details,
-- sunni/shia/other = 84.2 / 7.5 / 8.3 across the 120 new rows.
--
--   select sect, count(*) from seeker_details group by sect;
--   select count(*) from profiles p where p.role='seeker'
--     and not exists (select 1 from seeker_details s where s.user_id=p.id);
