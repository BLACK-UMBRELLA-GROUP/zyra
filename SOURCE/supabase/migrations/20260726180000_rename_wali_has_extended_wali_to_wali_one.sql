-- Founder decision, 2026-07-26: "Extended Wali" renamed to "Wali One"
-- (matching "ZYRA One" naming pattern) for the entitlement tier. Pure
-- rename — behaviour, resolution rule, and grants are all unchanged.
-- ALTER FUNCTION ... RENAME TO preserves existing REVOKE/GRANT state
-- (verified below), so no separate re-grant migration is needed, unlike
-- when this function was first created (20260726160000).
ALTER FUNCTION public.wali_has_extended_wali() RENAME TO wali_has_wali_one;

-- Sanity check: grants must have survived the rename unchanged (anon
-- false, authenticated true) — same verification discipline used when
-- the function was first created.
DO $$
DECLARE
  anon_ok boolean;
  auth_ok boolean;
BEGIN
  SELECT has_function_privilege('anon', 'public.wali_has_wali_one()', 'EXECUTE') INTO anon_ok;
  SELECT has_function_privilege('authenticated', 'public.wali_has_wali_one()', 'EXECUTE') INTO auth_ok;
  IF anon_ok THEN
    RAISE EXCEPTION 'wali_has_wali_one() is executable by anon after rename — grants did not survive as expected';
  END IF;
  IF NOT auth_ok THEN
    RAISE EXCEPTION 'wali_has_wali_one() is NOT executable by authenticated after rename — grants did not survive as expected';
  END IF;
END $$;
