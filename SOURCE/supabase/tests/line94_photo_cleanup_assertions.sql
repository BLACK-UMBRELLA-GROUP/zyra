-- DOC-ZYRA-0473 V4 / Q131. Rollback-only checks after the full migration replay.
begin;

create function pg_temp.photo_assert(p_pass boolean, p_label text)
returns void language plpgsql as $$
begin
  if p_pass is distinct from true then raise exception 'Q131 FAIL: %', p_label; end if;
  raise notice 'Q131 PASS: %', p_label;
end;
$$;

insert into auth.users (id, email, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values
  ('94000000-0000-4000-8000-000000000131', 'line94-owner@example.com', '{}', '{}', now(), now()),
  ('94000000-0000-4000-8000-000000000132', 'line94-viewer@example.com', '{}', '{}', now(), now()),
  ('94000000-0000-4000-8000-000000000134', 'line94-signup@example.com', '{}', '{}', now(), now());
insert into public.profiles (
  id, role, first_name, date_of_birth, gender, location_text, bio, is_active, profile_complete
) values
  ('94000000-0000-4000-8000-000000000131', 'seeker', 'Test', '1990-01-01', 'male', 'Test', 'Test', true, true),
  ('94000000-0000-4000-8000-000000000132', 'seeker', 'Test', '1990-01-01', 'female', 'Test', 'Test', true, true);
-- These synthetic profiles are eligible for ordinary cross-profile Browse reads.
update public.profiles set onboarding_complete = true
where id in ('94000000-0000-4000-8000-000000000131', '94000000-0000-4000-8000-000000000132');

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"94000000-0000-4000-8000-000000000134","role":"authenticated"}', true);
select set_config('storage.operation', 'storage.object.upload', true);
insert into storage.objects (bucket_id, name, owner_id) values
  ('profile-photos', auth.uid()::text || '/signup.jpg', auth.uid()::text);
select set_config('storage.operation', 'storage.object.sign', true);
select pg_temp.photo_assert(
  not exists (select 1 from public.profiles where id = auth.uid())
  and exists (select 1 from storage.objects where name = auth.uid()::text || '/signup.jpg'),
  'signup can sign an owned staging upload before either a profile or gallery row exists'
);
select set_config('request.jwt.claims', '{"sub":"94000000-0000-4000-8000-000000000131","role":"authenticated"}', true);
select set_config('storage.operation', 'storage.object.upload', true);
insert into storage.objects (bucket_id, name, owner_id) values
  ('profile-photos', auth.uid()::text || '/gallery.jpg', auth.uid()::text),
  ('profile-photos', auth.uid()::text || '/staged.jpg', auth.uid()::text),
  ('profile-photo-sources', auth.uid()::text || '/94000000-0000-4000-8000-000000000133.jpg', auth.uid()::text);
select public.zyra_save_profile_photo(
  '94000000-0000-4000-8000-000000000133',
  auth.uid()::text || '/gallery.jpg',
  auth.uid()::text || '/94000000-0000-4000-8000-000000000133.jpg',
  '{"x":0,"y":0,"w":0.5,"h":1}', 0, 0
);

select set_config('storage.operation', 'storage.object.sign', true);
select pg_temp.photo_assert(
  exists (select 1 from storage.objects where name = auth.uid()::text || '/staged.jpg'),
  'owner can still sign a staged display before saving its gallery row'
);
select pg_temp.photo_assert(
  not exists (select 1 from storage.objects where bucket_id = 'profile-photo-sources'
    and owner_id = auth.uid()::text),
  'source photos still cannot be signed'
);

select set_config('request.jwt.claims', '{"sub":"94000000-0000-4000-8000-000000000132","role":"authenticated"}', true);
select pg_temp.photo_assert(
  exists (select 1 from storage.objects where name = '94000000-0000-4000-8000-000000000131/gallery.jpg')
  and not exists (select 1 from storage.objects where name = '94000000-0000-4000-8000-000000000131/staged.jpg'),
  'eligible viewer can sign the gallery display only'
);
reset role;

-- Include both an earlier ordinary queue row and an earlier deadline for an
-- object from this account. Closing an account must never extend a deadline.
insert into public.photo_object_deletions (bucket, path, account_delete_due_at) values
  ('profile-photos', '94000000-0000-4000-8000-000000000132/ordinary.jpg', null),
  ('profile-photos', '94000000-0000-4000-8000-000000000131/staged.jpg', now() + interval '1 hour');
create temp table q131_closure_clock as select clock_timestamp() as before_deletion;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"94000000-0000-4000-8000-000000000131","role":"authenticated"}', true);
select pg_temp.photo_assert(
  not exists (select 1 from storage.objects where name = auth.uid()::text || '/staged.jpg'),
  'the staging exception cannot sign a queued path with no current gallery row'
);
select public.delete_own_account();
select pg_temp.photo_assert(
  not exists (select 1 from storage.objects where owner_id = auth.uid()::text),
  'deleted owner cannot sign or read queued display or source objects with its old JWT'
);
select set_config('request.jwt.claims', '{"sub":"94000000-0000-4000-8000-000000000132","role":"authenticated"}', true);
select pg_temp.photo_assert(
  not exists (select 1 from storage.objects where name = '94000000-0000-4000-8000-000000000131/gallery.jpg'),
  'eligible viewer cannot sign the deleted gallery photo while Storage still holds it'
);
reset role;

select pg_temp.photo_assert(
  not exists (select 1 from public.profile_photos where user_id = '94000000-0000-4000-8000-000000000131')
  and (select count(*) = 3 from storage.objects where owner_id = '94000000-0000-4000-8000-000000000131'),
  'database visibility ends before asynchronous physical deletion'
);
select pg_temp.photo_assert(
  (select count(*) = 2 and bool_and(
      d.account_delete_due_at between c.before_deletion + interval '24 hours'
      and clock_timestamp() + interval '24 hours')
   from public.photo_object_deletions d cross join q131_closure_clock c
   where d.path in ('94000000-0000-4000-8000-000000000131/gallery.jpg',
     '94000000-0000-4000-8000-000000000131/94000000-0000-4000-8000-000000000133.jpg'))
  and (select d.account_delete_due_at = now() + interval '1 hour'
       from public.photo_object_deletions d where d.path = '94000000-0000-4000-8000-000000000131/staged.jpg'),
  'account deletion assigns 24-hour deadlines to all owned paths and keeps earlier deadlines'
);

set local role service_role;
create temp table q131_claim as select * from public.zyra_claim_photo_object_deletions();
select pg_temp.photo_assert(
  (select count(*) = 1 and bool_and(
    attempts = 1 and path = '94000000-0000-4000-8000-000000000131/staged.jpg') from q131_claim),
  'worker claims the earliest account-deletion deadline before ordinary work'
);
select public.zyra_finish_photo_object_deletion(bucket, path, attempts, null) from q131_claim;
reset role;

update public.photo_object_deletions set account_delete_due_at = now() - interval '1 second'
where path = '94000000-0000-4000-8000-000000000131/gallery.jpg';
update public.photo_object_deletions set attempts = 10, last_error = 'storage_unavailable'
where path = '94000000-0000-4000-8000-000000000132/ordinary.jpg';

select pg_temp.photo_assert(
  not has_table_privilege('anon', 'public.zyra_photo_cleanup_failures', 'select')
  and not has_table_privilege('authenticated', 'public.zyra_photo_cleanup_failures', 'select'),
  'cleanup review listing stays service-only'
);
set local role service_role;
select pg_temp.photo_assert(
  (select count(*) = 2 from public.zyra_photo_cleanup_failures)
  and exists (select 1 from public.zyra_photo_cleanup_failures
    where path = '94000000-0000-4000-8000-000000000131/gallery.jpg' and attempts = 0)
  and exists (select 1 from public.zyra_photo_cleanup_failures
    where path = '94000000-0000-4000-8000-000000000132/ordinary.jpg' and last_error = 'storage_unavailable'),
  'review includes overdue and exhausted paths, excluding finished and on-time paths'
);
select pg_temp.photo_assert(
  (select count(*) = 1 and bool_and(path = '94000000-0000-4000-8000-000000000131/gallery.jpg')
   from public.zyra_claim_photo_object_deletions()),
  'a missed deadline still gets cleanup attempts'
);
reset role;

rollback;
