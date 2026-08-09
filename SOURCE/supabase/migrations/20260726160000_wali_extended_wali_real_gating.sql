-- #19 — Wire Extended Wali real gating, replacing the local
-- AppState.waliHasExtendedWali mock toggle. Per APP/Premium/WALI
-- PREMIUM/Summary.md ("Extended Wali pricing... £9.99/month if
-- purchased independently by the Wali, or included free as the one
-- entitlement bundled with a Seeker's ZYRA One") and WALI_ARCHITECTURE_
-- CURRENT_VERSION_V5.md's Extended Wali capability list.
--
-- A Wali has Extended Wali if EITHER:
--   (a) their own subscriptions row is plan_type='wali_premium',
--       status='active' (independent £9.99/month purchase), OR
--   (b) any Seeker they're actively linked to (wali_links.status=
--       'active') has an active 'seeker_premium' (ZYRA One)
--       subscription (bundled free entitlement).
--
-- This is a SECURITY DEFINER function rather than a client-side join
-- because subscriptions_select only permits user_id = auth.uid() —
-- correctly, a Wali should never be able to read a linked Seeker's
-- raw subscription row (privacy), only get a computed yes/no answer.
--
-- Known limitation, flagged not hidden: branch (b) depends on Seekers
-- having a REAL subscriptions row, which itself doesn't happen yet —
-- upgrade_screen.dart's ZYRA One purchase is still a local AppState
-- mock (see #20, Real payment processing). Until #20 ships, branch
-- (b) only resolves true for accounts with a real seeded
-- seeker_premium row (e.g. supabase/seed_dev_accounts.sql's Yusuf/
-- Aisha), not for a real user who "upgraded" via the current mock
-- Upgrade screen. Branch (a) works fully today via
-- mock_purchase_wali_premium() below.
--
-- Verified against the real seeded dev accounts (execute_sql,
-- 2026-07-26): Khadija (Wali) <-> Yusuf (Seeker, seeker_premium) —
-- resolves true. Ibrahim (Wali) <-> Maryam (Seeker, seeker_basic) —
-- resolves false. Both anon and authenticated EXECUTE checked via
-- has_function_privilege — anon false, authenticated true, for both
-- functions below.
CREATE OR REPLACE FUNCTION public.wali_has_extended_wali()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller UUID := auth.uid();
BEGIN
  IF caller IS NULL THEN
    RETURN false;
  END IF;

  IF EXISTS (
    SELECT 1 FROM subscriptions
    WHERE user_id = caller AND plan_type = 'wali_premium' AND status = 'active'
  ) THEN
    RETURN true;
  END IF;

  IF EXISTS (
    SELECT 1 FROM wali_links wl
    JOIN subscriptions s ON s.user_id = wl.seeker_id
    WHERE wl.wali_id = caller AND wl.status = 'active'
      AND s.plan_type = 'seeker_premium' AND s.status = 'active'
  ) THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.wali_has_extended_wali() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.wali_has_extended_wali() TO authenticated;

-- Backs the existing "Get Extended Wali — £9.99/month... Preview
-- build, no real payment is taken" button in wali_network_screen.dart.
-- Writes a REAL subscriptions row (so wali_has_extended_wali() above
-- is genuinely exercised end-to-end) without any actual payment
-- integration — same category of mock as the rest of this preview
-- build's purchase flows. Restricted to wali-role callers only.
CREATE OR REPLACE FUNCTION public.mock_purchase_wali_premium()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller UUID := auth.uid();
  caller_role TEXT;
  updated INT;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'Not signed in';
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
$$;

REVOKE EXECUTE ON FUNCTION public.mock_purchase_wali_premium() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mock_purchase_wali_premium() TO authenticated;
