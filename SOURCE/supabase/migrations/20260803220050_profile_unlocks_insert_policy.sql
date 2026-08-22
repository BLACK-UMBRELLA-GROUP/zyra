-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260803220050, applied name
-- 'profile_unlocks_insert_policy') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Compatibility Unlock persistence — Founder approved 2026-08-03:
-- "A profile may only be Compatibility Unlocked once per user. Once
-- unlocked, the compatibility remains permanently accessible to that user.
-- Returning to the same profile must never consume another unlock."
--
-- `profile_unlocks` had a SELECT policy and nothing else, so the client
-- could read unlocks that no code path could ever create. The table has
-- existed since the initial schema with zero rows.
--
-- INSERT only. Deliberately no UPDATE and no DELETE: an unlock is
-- permanent by the rule above, so there is nothing to amend and nothing to
-- revoke. A user cannot un-buy access they were sold.

CREATE POLICY profile_unlocks_insert ON profile_unlocks FOR INSERT TO authenticated
  WITH CHECK (unlocker_id = (SELECT auth.uid()));

-- Enforces "only once per user, per profile, per tier" in the database
-- rather than trusting the client to check first. Without this, a double
-- tap during a slow network would write two rows and — once payments are
-- real — charge twice for something the rule says is permanent.
--
-- Scoped per tier: Unlock and Unlock+ are separate purchases of different
-- depth, so holding one must not block buying the other.
CREATE UNIQUE INDEX profile_unlocks_once
  ON profile_unlocks (unlocker_id, unlocked_id, unlock_type);

CREATE INDEX profile_unlocks_by_unlocker ON profile_unlocks (unlocker_id);
