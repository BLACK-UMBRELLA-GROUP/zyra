-- Correction to 20260726190100 — revoking from anon alone doesn't
-- remove the implicit PUBLIC grant every new function gets by
-- default; PUBLIC must be revoked explicitly too, exactly as
-- wali_has_extended_wali()'s own migration
-- (20260726160000_wali_extended_wali_real_gating.sql) did it.
-- Re-grants to authenticated afterward. Verified via
-- has_function_privilege(): anon false, authenticated true, for all
-- four functions.
REVOKE EXECUTE ON FUNCTION public.open_family_review(UUID, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.wali_review_decision(UUID, TEXT) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.resolve_family_review_if_due(UUID) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.reopen_family_review(UUID) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.open_family_review(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.wali_review_decision(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_family_review_if_due(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reopen_family_review(UUID) TO authenticated;
