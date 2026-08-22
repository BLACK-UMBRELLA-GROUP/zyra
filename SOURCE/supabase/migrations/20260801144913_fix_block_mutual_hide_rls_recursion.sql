-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260801144913, applied name
-- 'fix_block_mutual_hide_rls_recursion') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- BUG FIX, same session: the block in the previous migration only hid the
-- profile in ONE direction.
--
-- Caught by an empirical test (ES-04), not by reading the policy — the
-- policy looks correct:
--     NOT EXISTS (SELECT 1 FROM profile_blocks WHERE ...both directions...)
--
-- The failure is that a subquery inside an RLS policy is itself subject to
-- RLS. profile_blocks_select is `USING (blocker_id = auth.uid())`, so the
-- BLOCKED party cannot see the row recording that they were blocked. The
-- NOT EXISTS therefore found nothing for them and the profile stayed
-- visible. Verified: A blocks B -> A could no longer see B (correct), but
-- B could still see A (wrong).
--
-- Fix: do the lookup in a SECURITY DEFINER function so it reads
-- profile_blocks as the owner, bypassing that table's RLS, while the
-- table's own client-facing policy stays exactly as restrictive as before
-- (you still cannot list who blocked you).
--
-- On the residual leak: this function is an oracle in the narrow sense
-- that a caller who already knows a specific user id can learn whether a
-- block exists between them. That is acceptable, because it is already
-- inferable — the profile visibly disappears — and it cannot be used to
-- ENUMERATE blockers: there is no user directory, and profiles_select now
-- hides those rows, so an attacker has no way to obtain ids to probe.
-- What stays protected is the thing that matters: you cannot discover
-- that you have been blocked by someone you don't already suspect, and
-- you cannot count how many people have blocked you.

CREATE OR REPLACE FUNCTION public.zyra_block_exists(p_other UUID)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM profile_blocks
    WHERE (blocker_id = auth.uid() AND blocked_id = p_other)
       OR (blocked_id = auth.uid() AND blocker_id = p_other)
  );
$$;

REVOKE ALL ON FUNCTION public.zyra_block_exists(UUID) FROM PUBLIC, anon;
-- authenticated needs EXECUTE because RLS policy expressions are
-- evaluated as the querying role, not as the table owner.
GRANT EXECUTE ON FUNCTION public.zyra_block_exists(UUID) TO authenticated;

DROP POLICY profiles_select ON profiles;
CREATE POLICY profiles_select ON profiles FOR SELECT USING (
  id = (select auth.uid())
  OR (
    is_active = true
    AND profile_complete = true
    AND NOT public.zyra_block_exists(profiles.id)
  )
);
