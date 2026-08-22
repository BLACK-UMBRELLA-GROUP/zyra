-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260805232842, applied name
-- 'photo_storage_read_by_displaying_profile') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- ROOT CAUSE FIX, 2026-08-05 (Fable). Founder: "the profiles are not showing
-- up in Browse… the pictures are not showing up for guardian suggestions".
--
-- The old profile_photos_storage_read policy authorised an object by looking
-- up the FOLDER OWNER's profile row:
--
--   EXISTS (SELECT 1 FROM profiles p
--           WHERE p.id::text = (storage.foldername(name))[1]
--             AND p.is_active AND p.profile_complete)
--
-- That subquery is an ordinary RLS-bound read of public.profiles, so it is
-- itself filtered by profiles_select -> zyra_can_view_profile(). Two
-- consequences, both wrong and both invisible from the client:
--
--   1. GENDER COUPLING. zyra_can_view_profile() hides same-gender profiles
--      from browsing Seekers. So an object uploaded by a male user is
--      unreadable to every female viewer, and vice versa — no matter WHOSE
--      profile is displaying it. Measured: a male viewer could read 49 of 99
--      objects; the 49 were exactly the ten female-owned folders.
--
--   2. BLOCK COUPLING. A block against the uploader hides their profile,
--      which silently breaks the photos of every OTHER profile sharing that
--      folder. Measured: one female test account resolved 209 of 284 photo
--      rows and lost 7 candidates outright — the 209/284 in the Founder's
--      terminal log.
--
-- Neither is a seeding artefact. The policy asks the wrong question: "may
-- you see the person who uploaded this file?" rather than "may you see the
-- profile this photo belongs to?" Those coincide only while every profile
-- owns its own uploads, which is not guaranteed and was never enforced.
--
-- The fix asks the right question, through a SECURITY DEFINER helper so the
-- lookup is not re-filtered by the very RLS it is trying to evaluate.
--
-- This is also STRICTLY MORE RESTRICTIVE than before: an orphaned object
-- sitting in an active user's folder used to be readable by anyone, even
-- with no profile_photos row pointing at it. Now only objects genuinely
-- attached to a profile you may view are readable.

create or replace function public.zyra_can_read_photo_object(p_object_name text)
returns boolean
language sql
stable
security definer
set search_path to 'public'
as $$
  select exists (
    select 1
    from public.profile_photos pp
    where pp.storage_path = p_object_name
      and public.zyra_can_view_profile(pp.user_id)
  );
$$;

comment on function public.zyra_can_read_photo_object(text) is
  'Storage read gate for the profile-photos bucket. Answers "is this object '
  'displayed by a profile the caller may view?" — deliberately NOT "may the '
  'caller see whoever uploaded it", which is what the pre-2026-08-05 policy '
  'asked and which coupled photo visibility to the uploader''s gender and '
  'block status. SECURITY DEFINER so the profile_photos lookup is not itself '
  'filtered by the RLS being evaluated.';

-- profile_photos.storage_path is looked up once per object per signing
-- request; a 40-path batch is 40 probes. Without this it is 40 seq scans.
create index if not exists profile_photos_storage_path_idx
  on public.profile_photos (storage_path);

drop policy if exists profile_photos_storage_read on storage.objects;

create policy profile_photos_storage_read
on storage.objects
for select
using (
  bucket_id = 'profile-photos'
  and (
    -- your own uploads, always, regardless of profile state — you must be
    -- able to see your own photos mid-onboarding before the profile is
    -- complete, and while your profile is deactivated.
    (storage.foldername(name))[1] = (select auth.uid())::text
    or public.zyra_can_read_photo_object(name)
  )
);
