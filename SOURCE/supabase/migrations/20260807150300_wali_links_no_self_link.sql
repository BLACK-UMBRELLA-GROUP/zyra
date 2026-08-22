-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260807150300, applied name
-- 'wali_links_no_self_link') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Nobody can be their own Guardian.
--
-- Founder, 2026-08-07: "I agree this should exist regardless of any wider
-- decisions. That feels like a fundamental integrity constraint rather than
-- business logic." Applied ahead of the dual-context work for that reason —
-- it is true under every version of the architecture being discussed.
--
-- accept_wali_invite already refuses "cannot accept your own invite", but
-- that guards one PATH. Nothing guarded the ROW, so any other writer —
-- a dev seeder, a future RPC, a migration — could have created one. The
-- table now refuses it regardless of who is asking.
--
-- Verified zero existing rows violate it before adding.

alter table public.wali_links
  drop constraint if exists wali_links_no_self_link;

alter table public.wali_links
  add constraint wali_links_no_self_link
  check (seeker_id <> wali_id);

comment on constraint wali_links_no_self_link on public.wali_links is
  'A Guardian relationship requires two people. Integrity, not policy.';
