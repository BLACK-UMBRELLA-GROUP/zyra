-- Advisor flagged: public buckets don't need a broad SELECT policy for
-- object URL access (that's served directly, bypassing RLS) — a broad
-- policy only adds the ability to LIST/enumerate every file in the
-- bucket via the storage API, which isn't wanted. Narrow to own-folder,
-- matching the insert/update/delete policies already in place.
--
-- [SUPERSEDED 2026-07-19: replaced by
-- 20260719080749_private_profile_photos_bucket.sql — see that file.]

DROP POLICY profile_photos_storage_read ON storage.objects;

CREATE POLICY profile_photos_storage_read ON storage.objects FOR SELECT
  USING (
    bucket_id = 'profile-photos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
