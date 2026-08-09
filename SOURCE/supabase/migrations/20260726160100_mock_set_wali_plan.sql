-- Companion to mock_purchase_wali_premium() (20260726160000), found
-- necessary while wiring Developer Access's "Wali — One" presets to
-- the real gating: Ibrahim/Khadija are the SAME real accounts used by
-- both the "Wali — Basic" and "Wali — One" presets (see
-- seed_dev_accounts.sql). Since Extended Wali is now resolved from a
-- real, persistent subscriptions row rather than a local AppState
-- flag, calling mock_purchase_wali_premium() when entering as "Wali —
-- One" would permanently upgrade that account — the next time someone
-- picks "Wali — Basic" for the same person, it would incorrectly still
-- show Extended Wali, since nothing ever downgraded the real row.
--
-- This general-purpose (but narrowly restricted) function lets
-- Developer Access set either direction explicitly on preset entry, so
-- switching between "Basic" and "One" presets for the same test
-- account stays deterministic and honest.
CREATE OR REPLACE FUNCTION public.mock_set_wali_plan(p_plan TEXT)
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
  IF p_plan NOT IN ('wali_basic', 'wali_premium') THEN
    RAISE EXCEPTION 'invalid plan';
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
$$;

REVOKE EXECUTE ON FUNCTION public.mock_set_wali_plan(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mock_set_wali_plan(TEXT) TO authenticated;
