-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806192159, applied name
-- 'fix_profile_unlocks_allow_both_tiers') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- BUG: buying Compatibility+ on a profile already unlocked at the standard
-- tier always failed with "That didn't go through."
--
-- profile_unlocks carried TWO unique constraints that cannot both hold:
--
--   profile_unlocks_unlocker_id_unlocked_id_key  UNIQUE (unlocker, unlocked)
--   profile_unlocks_once                         UNIQUE (unlocker, unlocked, unlock_type)
--
-- The first predates unlock tiers — back then one row per pair WAS the
-- model. The second was added with the tiers and is the correct one.
-- Nobody removed the first, so the second was decorative: the pair was
-- already unique, and a second row for a different tier could never insert.
--
-- Everything else in the system assumes two rows per pair:
--   * zyra_unlock_profile() checks `unlock_type = p_tier` before charging
--   * guardians_for_unlocked() requires specifically 'paid_plus_single'
--   * the Dart client keys its cache '<profileId>:<unlockType>'
--
-- So the stale constraint is the outlier, and it is what goes.
--
-- Verified before applying: zero pairs currently hold two tiers, which is
-- itself the evidence — no user has ever been able to buy Plus after
-- standard on the same profile since tiers shipped.

alter table public.profile_unlocks
  drop constraint if exists profile_unlocks_unlocker_id_unlocked_id_key;

-- Belt and braces: the correct constraint must exist, not be assumed.
create unique index if not exists profile_unlocks_once
  on public.profile_unlocks (unlocker_id, unlocked_id, unlock_type);
