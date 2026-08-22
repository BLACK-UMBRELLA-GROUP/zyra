-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260808093943, applied name
-- 'record_permanence_invariant') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Founder governance rule, 2026-08-08. Recorded on the two columns that
-- exist BECAUSE of it, so it is found by someone reading the schema rather
-- than only by someone reading a document.
--
--   PERMANENT PRODUCT BEHAVIOUR MUST ALWAYS BE DERIVED FROM PERMANENT DATA.
--   Temporary records — blocks, invitations, sessions, toggles, publication
--   flags — must never be the sole source of a permanent permission or
--   restriction.
--
-- The rule was written after it caught the same bug twice, five days apart,
-- in unrelated areas:
--
--   identity freeze     keyed on profile_complete   — user can switch it off
--                    -> keyed on first_published_at — written once, never cleared
--
--   block revocation    keyed on a profile_blocks row — user can delete it
--                    -> keyed on end_reason='safety_concern' — permanent
--
-- Both read correctly and were undone by a state the user controlled.
--
-- THE TEST, for any permanent consequence: "can the user clear the thing
-- this depends on?" If yes, it is the wrong anchor.

comment on column public.profiles.first_published_at is
  'Set the first time a profile is published and NEVER cleared, including '
  'on un-publish. Gender and date_of_birth are frozen once this is '
  'non-null — that is the whole reason the column exists, and it is why '
  'profile_complete could not be used: profile_complete is reversible, and '
  'PERMANENT BEHAVIOUR MUST DERIVE FROM PERMANENT DATA (Founder invariant, '
  '2026-08-08). '
  'BACKFILL WARNING: rows predating 2026-08-07 were backfilled from '
  'created_at, a lower bound. Safe to test for NULL. NOT safe to show a '
  'user as a date.';

comment on column public.matches.ended_at is
  'When the Journey ended. Set by zyra_end_match_internal(), the single '
  'path both ordinary and safety endings take — two paths would drift and '
  'the drift would be a disclosure channel. '
  'NOTE the companion rule: visibility revoked by a block keys on '
  'end_reason=''safety_concern'' (permanent), NOT on a profile_blocks row '
  '(deletable). PERMANENT BEHAVIOUR MUST DERIVE FROM PERMANENT DATA.';
