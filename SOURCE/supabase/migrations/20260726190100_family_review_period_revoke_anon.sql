-- Superseded by the very next migration in this same pass
-- (20260726190200) — REVOKE ... FROM anon alone doesn't remove the
-- implicit PUBLIC grant every new function gets by default, so this
-- step had no real effect and had to be corrected immediately. Kept
-- as its own file rather than silently folded away, per this
-- project's standing policy that applied migration files are a
-- historical record, not retroactively rewritten.
--
-- Tighter than the existing suspend_journey/resume_journey/end_journey/
-- promote_journey_to_active precedent (which left EXECUTE granted to
-- anon by default, relying solely on the internal auth.uid() IS NULL
-- checks) — these four are new, so hold them to the same explicit
-- anon-revoke discipline #19 already established for wali_has_wali_one().
-- Internal auth.uid() checks remain as defense in depth regardless.
REVOKE EXECUTE ON FUNCTION public.open_family_review(UUID, TEXT, TEXT) FROM anon;
REVOKE EXECUTE ON FUNCTION public.wali_review_decision(UUID, TEXT) FROM anon;
REVOKE EXECUTE ON FUNCTION public.resolve_family_review_if_due(UUID) FROM anon;
REVOKE EXECUTE ON FUNCTION public.reopen_family_review(UUID) FROM anon;
