-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806152858, applied name
-- 'guardian_relationship_column') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Guardian Relationship, step 1 of 8.
-- Founder-approved 2026-08-06. Codes only, never labels: 'uncle' is stored
-- and displayed as "Paternal Uncle", which is why the code is the thing that
-- must never change.
--
-- Nullable by necessity, not by design: live links already exist whose
-- relationship nobody has been asked. Backfilling a guess would be inventing
-- data about real people. NOT NULL goes on once they have been asked.

alter table public.wali_links
  add column if not exists relationship text;

alter table public.wali_links
  drop constraint if exists wali_links_relationship_check;

alter table public.wali_links
  add constraint wali_links_relationship_check
  check (relationship is null or relationship in (
    'father', 'brother', 'grandfather', 'uncle',
    'legal_guardian', 'family_representative', 'other'
  ));

comment on column public.wali_links.relationship is
  'OWNERSHIP: joint(seeker_id, wali_id) — both parties know the relationship. '
  'Disclosed to a Seeker only via guardians_for_unlocked, which is gated on a '
  'paid profile unlock. Stored as a code; "uncle" renders as "Paternal Uncle".';
