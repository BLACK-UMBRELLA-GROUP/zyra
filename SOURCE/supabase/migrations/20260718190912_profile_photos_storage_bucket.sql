-- OA-104: Supabase Storage bucket for profile photos.
-- Public bucket (photos are meant to be visible to other members browsing
-- an active/complete profile, same visibility rule as profile_photos_select
-- in the initial schema migration) but writes are restricted per-user via
-- a folder-per-user convention: objects must live under `{auth.uid()}/...`.
--
-- [SUPERSEDED 2026-07-19: bucket made private by
-- 20260719080749_private_profile_photos_bucket.sql — see that file.]

INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-photos', 'profile-photos', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY profile_photos_storage_read ON storage.objects FOR SELECT
  USING (bucket_id = 'profile-photos');

CREATE POLICY profile_photos_storage_insert ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY profile_photos_storage_update ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY profile_photos_storage_delete ON storage.objects FOR DELETE
  USING (
    bucket_id = 'profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
