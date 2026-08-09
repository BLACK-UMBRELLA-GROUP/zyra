-- #22 — real account deletion, per APP/Settings/SUMMARY.md's "NOT
-- BUILT: Account deletion / data export" gap (also an App Store/Play
-- Store review requirement for any app with account creation).
--
-- Verified mechanics via a scratch test row (execute_sql, 2026-07-26,
-- not touching real seed accounts): deleting auth.users cascades
-- through profiles.id REFERENCES auth.users(id) ON DELETE CASCADE,
-- and from there through every table that references profiles(id) ON
-- DELETE CASCADE (matches, conversations, messages, timelines,
-- timeline_milestones, wali_links, wali_invites, saves, likes,
-- subscriptions, profile_photos, notifications, onboarding_answers,
-- journey_* tables, etc.) — confirmed all zero rows left afterward.
--
-- Storage objects (actual photo files in the profile-photos bucket)
-- are NOT covered by that cascade — Storage lives in its own
-- storage.objects table, which has a protect_delete trigger blocking
-- plain SQL DELETE ("Use the Storage API instead") unless
-- storage.allow_delete_query is explicitly set. Verified working via
-- the same scratch test: set_config(...) then DELETE, zero rows left.
-- Path convention is `{user_id}/{filename}` (see
-- zyra_photo_service.dart pickAndUpload), matching the existing
-- profile_photos_storage_delete RLS policy's own foldername check.
--
-- Full end-to-end verification (execute_sql, 2026-07-26): called
-- public.delete_own_account() itself as the `authenticated` role with
-- a simulated request.jwt.claims sub, not just the raw DELETE
-- statements — confirms auth.uid() resolution and the whole function
-- body work together, not just its individual pieces.
--
-- Disclosed to the user in the confirmation dialog, not silent: since
-- matches/conversations/messages/timelines are shared rows (both
-- seeker_a_id and seeker_b_id reference profiles(id) ON DELETE
-- CASCADE), deleting one party's account also deletes the OTHER
-- party's copy of that shared history — an unavoidable consequence of
-- a real hard delete, not a bug.
CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller UUID := auth.uid();
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'Not signed in';
  END IF;

  PERFORM set_config('storage.allow_delete_query', 'true', true);
  DELETE FROM storage.objects
  WHERE bucket_id = 'profile-photos' AND name LIKE caller::text || '/%';

  DELETE FROM auth.users WHERE id = caller;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.delete_own_account() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
