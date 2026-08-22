-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260727100958, applied name
-- 'add_surname_line_to_profiles') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- 2026-07-27: adds the display-only surname/second-line field that
-- SeekerProfile.surnameLine (SOURCE/lib/models/seeker_profile.dart) has
-- expected since 2026-07-26, and backfills it for the 26 seeded test
-- profiles so the Browse identity block's second line is finally
-- visible against real data (previously only mockProfiles had this,
-- which ZyraDiscoveryService.fetchCandidates() stopped returning once
-- real seeded rows existed). Nullable, no default — real new users have
-- no surname until a capture UI exists (tracked separately as an
-- Outstanding Action, not built here).
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS surname_line text;

UPDATE public.profiles SET surname_line = CASE id
  WHEN '369d1627-e190-471d-ae45-af35d51eef39' THEN 'Farooq'        -- Adam
  WHEN 'fd47fa36-99fb-4f11-b891-034a769e42c4' THEN 'Malik'          -- Aisha
  WHEN 'b96daf45-e619-4d9a-894f-940a7932b2d8' THEN 'Siddiqui'       -- Amina
  WHEN '7e030c51-925d-47a5-8069-75da5350ad00' THEN 'Chaudhry'       -- Anas
  WHEN '1e16657e-80cc-4644-929a-b9276d2e824c' THEN 'Abdul Malik'    -- Bilal
  WHEN '761657eb-e675-4657-ac27-c02a52675e76' THEN 'Rahman'         -- Hafsa
  WHEN '62badf17-db60-4be6-b7d8-e3e8d11fc37d' THEN 'Iqbal'          -- Hamza
  WHEN 'fa846b99-0212-4b3e-ae55-ede02a6d9e0f' THEN 'Ali'            -- Hassan
  WHEN 'c75c01ca-6dde-4ae0-8b5e-89f9e18a445c' THEN 'Ahmed'          -- Huda
  WHEN '6493a6e6-6fc7-4d7a-b1b5-58b637c08647' THEN 'Rashid'         -- Ibrahim
  WHEN '12421707-fe06-4604-94bb-771ccd8ae30a' THEN 'Qureshi'        -- Idris
  WHEN 'c9fd085c-f9ba-4045-877a-b061fde30b6f' THEN 'Yousef'         -- Iman
  WHEN '257d6ebc-ccd0-4c16-a878-3c416ad7b530' THEN 'Abdul Aziz'     -- Khadija
  WHEN '07599948-9f00-4a64-adca-ad8d2deb08e8' THEN 'Hussain'        -- Layla
  WHEN 'c66fd953-9b09-4256-8f6c-6d7500bfa3f9' THEN 'Begum'          -- Maryam
  WHEN '1531370a-99fb-44c2-981b-49482522744f' THEN 'Farooqi'        -- Noor
  WHEN '80f6ff65-498f-4314-8038-4559940f788e' THEN 'Sheikh'         -- Rayyan
  WHEN 'e5bcbf1b-ff6e-4997-b69d-02e54f8f8b52' THEN 'Khatun'         -- Salma
  WHEN '607a6108-1de1-4f1d-997b-f077b35a9be3' THEN 'Abdul Karim'    -- Sami
  WHEN '39dee4ca-a60c-4435-9abe-a6af57026730' THEN 'Yasin'          -- Sara
  WHEN '4b2fff7c-29d1-4532-9886-32b0bb0443c8' THEN 'Nasser'         -- Tariq
  WHEN 'b8332572-7db3-468d-8200-ebb090db0e72' THEN 'Farid'          -- Usman
  WHEN '07dc54c0-fba1-4319-b10f-af8dde2b68ea' THEN 'Choudhury'      -- Yasmin
  WHEN 'ac6f5cf7-4695-4332-8cc6-58227ac2f89f' THEN 'Khan'           -- Yusuf
  WHEN '607577f8-be03-42c8-bb8b-2834d56adc60' THEN 'Rahim'          -- Zainab
  WHEN 'b3006ac6-0ad2-46e6-9e8c-7d5ff987e50b' THEN 'Haque'          -- Zayd
  ELSE surname_line
END
WHERE id IN (
  '369d1627-e190-471d-ae45-af35d51eef39','fd47fa36-99fb-4f11-b891-034a769e42c4',
  'b96daf45-e619-4d9a-894f-940a7932b2d8','7e030c51-925d-47a5-8069-75da5350ad00',
  '1e16657e-80cc-4644-929a-b9276d2e824c','761657eb-e675-4657-ac27-c02a52675e76',
  '62badf17-db60-4be6-b7d8-e3e8d11fc37d','fa846b99-0212-4b3e-ae55-ede02a6d9e0f',
  'c75c01ca-6dde-4ae0-8b5e-89f9e18a445c','6493a6e6-6fc7-4d7a-b1b5-58b637c08647',
  '12421707-fe06-4604-94bb-771ccd8ae30a','c9fd085c-f9ba-4045-877a-b061fde30b6f',
  '257d6ebc-ccd0-4c16-a878-3c416ad7b530','07599948-9f00-4a64-adca-ad8d2deb08e8',
  'c66fd953-9b09-4256-8f6c-6d7500bfa3f9','1531370a-99fb-44c2-981b-49482522744f',
  '80f6ff65-498f-4314-8038-4559940f788e','e5bcbf1b-ff6e-4997-b69d-02e54f8f8b52',
  '607a6108-1de1-4f1d-997b-f077b35a9be3','39dee4ca-a60c-4435-9abe-a6af57026730',
  '4b2fff7c-29d1-4532-9886-32b0bb0443c8','b8332572-7db3-468d-8200-ebb090db0e72',
  '07dc54c0-fba1-4319-b10f-af8dde2b68ea','ac6f5cf7-4695-4332-8cc6-58227ac2f89f',
  '607577f8-be03-42c8-bb8b-2834d56adc60','b3006ac6-0ad2-46e6-9e8c-7d5ff987e50b'
);
