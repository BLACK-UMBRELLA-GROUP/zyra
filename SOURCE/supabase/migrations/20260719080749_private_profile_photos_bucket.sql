-- Photo privacy fix (Fable review, 2026-07-19) — implements
-- IMAGE_HANDLING_CURRENT_VERSION_V1.md: "Originals never publicly
-- accessible."
--
-- The profile-photos bucket was public:true, which meant the
-- own-folder read policy added on 2026-07-18 was ineffective — public
-- buckets serve objects by URL with NO auth or RLS check at all, so
-- any photo was fetchable by anyone holding the URL, signed out.
--
-- Making the bucket private makes storage RLS actually apply. The
-- read policy is simultaneously broadened from own-folder-only to
-- "own photos, or photos belonging to an active + complete profile" —
-- deliberately mirroring the EXISTING approved profile_photos table
-- SELECT policy, so storage and table visibility now agree. Without
-- this broadening, a private bucket would have broken Browse/Matches
-- photo display entirely (signed-URL creation respects storage RLS).
--
-- App code switches from getPublicUrl to createSignedUrl(s) in the
-- same change set.
update storage.buckets set public = false where id = 'profile-photos';

drop policy "profile_photos_storage_read" on storage.objects;
create policy "profile_photos_storage_read" on storage.objects for select
using (
  bucket_id = 'profile-photos'
  and (
    (storage.foldername(name))[1] = (select auth.uid())::text
    or exists (
      select 1 from public.profiles p
      where p.id::text = (storage.foldername(name))[1]
        and p.is_active
        and p.profile_complete
    )
  )
);
