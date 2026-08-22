-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260801144341, applied name
-- 'restrict_mock_purchase_rpcs_to_test_accounts') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- C4b (Critical, engineering audit 2026-07-26) — free paid subscriptions.
--
-- mock_purchase_wali_premium() and mock_set_wali_plan() are SECURITY
-- DEFINER, granted to `authenticated`, and write a real subscriptions row
-- with plan_type='wali_premium', status='active' — with no payment. Any
-- signed-in user could call either directly against /rest/v1/rpc/ and
-- grant themselves a paid plan. `subscriptions` deliberately has no
-- client INSERT/UPDATE policy precisely so this can't happen; these two
-- functions were an unintended way around that boundary.
--
-- NOT DROPPED, deliberately. Both are still wired to live UI:
--   • wali_network_screen.dart:61 — the user-facing "Get Wali One"
--     mock-purchase button
--   • developer_access_screen.dart:287 — Wali Basic/One preset switching
-- Dropping them outright would break the only way to exercise Wali One
-- gating in a preview build that has no real payment processing yet.
--
-- Instead: restrict to the seeded test accounts. `.test` is an RFC 2606
-- reserved TLD, so no real mailbox can exist there — and ZYRA's only
-- user-facing auth is Google/Apple, neither of which can issue a
-- @zyra.test identity. That makes this a hard boundary rather than a
-- naming convention. Real users now get a clean exception instead of a
-- free subscription; the Dart callers already handle failure by
-- returning false.
--
-- When real payment processing lands (#20), drop both functions entirely
-- and delete this guard with them.

CREATE OR REPLACE FUNCTION public.mock_purchase_wali_premium()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  caller UUID := auth.uid();
  caller_role TEXT;
  updated INT;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'Not signed in';
  END IF;

  -- ADDED 2026-08-01 (C4b): seeded test accounts only.
  IF NOT EXISTS (
    SELECT 1 FROM auth.users u WHERE u.id = caller AND u.email LIKE '%@zyra.test'
  ) THEN
    RAISE EXCEPTION 'mock_purchase_disabled'
      USING HINT = 'Mock purchases are limited to seeded test accounts. Real payment processing is not built yet.';
  END IF;

  SELECT role INTO caller_role FROM profiles WHERE id = caller;
  IF caller_role IS DISTINCT FROM 'wali' THEN
    RAISE EXCEPTION 'Extended Wali is a Wali-account entitlement';
  END IF;

  UPDATE subscriptions SET plan_type = 'wali_premium' WHERE user_id = caller AND status = 'active';
  GET DIAGNOSTICS updated = ROW_COUNT;
  IF updated = 0 THEN
    INSERT INTO subscriptions (user_id, plan_type, status) VALUES (caller, 'wali_premium', 'active');
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.mock_set_wali_plan(p_plan text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  caller UUID := auth.uid();
  caller_role TEXT;
  updated INT;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'Not signed in';
  END IF;
  IF p_plan NOT IN ('wali_basic', 'wali_premium') THEN
    RAISE EXCEPTION 'invalid plan';
  END IF;

  -- ADDED 2026-08-01 (C4b): seeded test accounts only.
  IF NOT EXISTS (
    SELECT 1 FROM auth.users u WHERE u.id = caller AND u.email LIKE '%@zyra.test'
  ) THEN
    RAISE EXCEPTION 'mock_purchase_disabled'
      USING HINT = 'Developer plan switching is limited to seeded test accounts.';
  END IF;

  SELECT role INTO caller_role FROM profiles WHERE id = caller;
  IF caller_role IS DISTINCT FROM 'wali' THEN
    RAISE EXCEPTION 'Wali-only';
  END IF;

  UPDATE subscriptions SET plan_type = p_plan WHERE user_id = caller AND status = 'active';
  GET DIAGNOSTICS updated = ROW_COUNT;
  IF updated = 0 THEN
    INSERT INTO subscriptions (user_id, plan_type, status) VALUES (caller, p_plan, 'active');
  END IF;
END;
$function$;

-- Trigger function exposed as an RPC by accident (audit finding M3) —
-- harmless (it errors if called directly) but it has no business being
-- in the client-callable surface.
REVOKE ALL ON FUNCTION public.auto_designate_main_wali() FROM PUBLIC, anon, authenticated;
