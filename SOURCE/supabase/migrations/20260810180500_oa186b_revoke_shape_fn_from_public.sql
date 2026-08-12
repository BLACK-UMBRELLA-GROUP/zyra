-- OA-ZYRA-186, corrective. The sweep revoked EXECUTE on
-- zyra_ch4_hard_shape_ok FROM anon and SILENTLY DID NOTHING.
--
-- The function's proacl was NULL — "defaults apply" — and the default for a
-- function is EXECUTE to PUBLIC. anon held it via PUBLIC, not directly, so
-- revoking from anon removed a grant that was never there. The migration
-- reported success; only the verification query caught it.
--
-- Recorded because the failure mode is invisible: a REVOKE against a role
-- that inherits through PUBLIC succeeds and changes nothing.
REVOKE EXECUTE ON FUNCTION public.zyra_ch4_hard_shape_ok(jsonb) FROM PUBLIC;

-- MEASURED, NOT ASSUMED: with EXECUTE revoked from PUBLIC, `authenticated`
-- can still UPDATE onboarding_answers, so the CHECK constraint calling this
-- function does not require the writing role to hold EXECUTE. Verified
-- 2026-08-10 by running that update as authenticated. If this ever changes,
-- onboarding writes fail with "permission denied for function
-- zyra_ch4_hard_shape_ok" and the fix is GRANT EXECUTE ... TO authenticated.
