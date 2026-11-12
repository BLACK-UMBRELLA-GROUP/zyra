-- OA-ZYRA-317 / DOC-ZYRA-0445 / LOCK 29 V2.
-- Run after the governed SERVER 0 replay and the profile-video migration in
-- a fresh zyra_server0_v2_* database. Fixture data rolls back at the end.
\set ON_ERROR_STOP on
begin;
\ir fixtures/server0_v2_full_schema_prestate.sql

grant select on server0_v2_fixture_actors to authenticated, service_role;

create function pg_temp.video_actor(p_label text)
returns uuid language sql stable security invoker as $$
  select id from server0_v2_fixture_actors where fixture_label = p_label;
$$;

create function pg_temp.video_path(p_label text, p_slot integer)
returns text language sql stable security invoker as $$
  select pg_temp.video_actor(p_label)::text || '/7a700000-0000-4000-8000-'
    || lpad(p_slot::text, 12, '0') || '.mp4';
$$;

create function pg_temp.video_as(p_label text)
returns void language plpgsql security invoker as $$
begin
  perform pg_catalog.set_config(
    'request.jwt.claims',
    pg_catalog.json_build_object('sub', pg_temp.video_actor(p_label), 'role', 'authenticated')::text,
    true
  );
end;
$$;

create function pg_temp.video_assert(p_ok boolean, p_label text)
returns void language plpgsql security invoker as $$
begin
  if p_ok is distinct from true then
    raise exception 'PROFILE VIDEO FAIL: %', p_label;
  end if;
  raise notice 'PROFILE VIDEO PASS: %', p_label;
end;
$$;

create function pg_temp.video_refused(p_sql text, p_error text, p_label text)
returns void language plpgsql security invoker as $$
begin
  execute p_sql;
  raise exception 'PROFILE VIDEO unexpectedly allowed: %', p_label;
exception when others then
  if sqlstate <> p_error and sqlerrm <> p_error then
    raise;
  end if;
  raise notice 'PROFILE VIDEO PASS refusal: %', p_label;
end;
$$;

create function pg_temp.video_view(p_slot integer, p_visible boolean, p_label text)
returns void language sql security invoker as $$
  select pg_temp.video_assert(
    public.zyra_can_read_profile_video_object(pg_temp.video_path('male1', p_slot)) = p_visible
    and exists (
      select 1 from public.zyra_profile_video_for(pg_temp.video_actor('male1'))
      where storage_path = pg_temp.video_path('male1', p_slot) and duration_ms = 8000
    ) = p_visible
    and exists (
      select 1 from storage.objects
      where bucket_id = 'profile-videos' and name = pg_temp.video_path('male1', p_slot)
    ) = p_visible,
    p_label
  );
$$;

grant execute on function
  pg_temp.video_actor(text), pg_temp.video_path(text, integer), pg_temp.video_as(text),
  pg_temp.video_assert(boolean, text), pg_temp.video_refused(text, text, text),
  pg_temp.video_view(integer, boolean, text)
to authenticated, service_role;
grant execute on function pg_temp.video_refused(text, text, text) to anon;

select pg_temp.video_assert(
  (select not public and file_size_limit = 20971520
     and cardinality(allowed_mime_types) = 2
     and allowed_mime_types @> array['video/mp4', 'video/quicktime']::text[]
   from storage.buckets where id = 'profile-videos'),
  'bucket is private and limits size and media types'
);
select pg_temp.video_assert(
  (select count(*) = 2 and bool_and(not rolsuper and not rolbypassrls)
   from pg_catalog.pg_roles where rolname in ('anon', 'authenticated')),
  'member roles are subject to RLS'
);

set local role authenticated;
select set_config('storage.operation', 'storage.object.upload', true);
select pg_temp.video_as('male1');
select pg_temp.video_assert(not public.zyra_my_paid_access('seeker'), 'owner starts as Basic');
select pg_temp.video_refused(
  $sql$insert into storage.objects(bucket_id, name, owner_id)
  values ('profile-videos', pg_temp.video_path('male1', 1), auth.uid()::text)$sql$,
  '42501', 'Basic cannot upload to their own folder'
);
select pg_temp.video_assert(not exists (select 1 from public.zyra_my_profile_video()), 'empty owner has no current video');
reset role;

-- Seed the object as trusted setup to exercise the independent record gate.
insert into storage.objects(bucket_id, name, owner_id)
values ('profile-videos', pg_temp.video_path('male1', 4), pg_temp.video_actor('male1')::text);
set local role service_role;
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
select pg_temp.video_refused(
  $sql$select public.zyra_record_profile_video(pg_temp.video_actor('male1'), pg_temp.video_path('male1', 4), 8000)$sql$,
  '42501', 'service record independently refuses Basic'
);
reset role;

update public.subscriptions
set plan_type = 'seeker_premium', expires_at = now() + interval '1 day'
where user_id = pg_temp.video_actor('male1');

set local role authenticated;
select pg_temp.video_as('male1');
select pg_temp.video_assert(public.zyra_my_paid_access('seeker'), 'owner has direct One');
select pg_temp.video_refused(
  $sql$insert into storage.objects(bucket_id, name, owner_id)
  values ('profile-videos', pg_temp.video_path('fem1', 1), auth.uid()::text)$sql$,
  '42501', 'One cannot upload into another member folder'
);
insert into storage.objects(bucket_id, name, owner_id)
values ('profile-videos', pg_temp.video_path('male1', 1), auth.uid()::text);
select set_config('storage.operation', 'storage.object.get_authenticated', true);
select pg_temp.video_assert(
  exists (select 1 from storage.objects where bucket_id = 'profile-videos' and name = pg_temp.video_path('male1', 1)),
  'One can upload and read their own object before submitting'
);
with changed as (
  update storage.objects set name = name
  where bucket_id = 'profile-videos' and name = pg_temp.video_path('male1', 1)
  returning id
)
select pg_temp.video_assert(not exists (select 1 from changed), 'member cannot update uploaded objects');
select pg_temp.video_refused(
  $sql$insert into public.profile_videos(user_id, storage_path, status, duration_ms)
  values (auth.uid(), pg_temp.video_path('male1', 1), 'approved', 8000)$sql$,
  '42501', 'member cannot insert an approved row directly'
);
select pg_temp.video_refused(
  $sql$select public.zyra_record_profile_video(auth.uid(), pg_temp.video_path('male1', 1), 8000)$sql$,
  '42501', 'member cannot execute the service record RPC'
);
select pg_temp.video_refused(
  $sql$select public.zyra_review_profile_video(null, 'approved', null)$sql$,
  '42501', 'member cannot execute the service reviewer RPC'
);
reset role;

set local role service_role;
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
select public.zyra_record_profile_video(pg_temp.video_actor('male1'), pg_temp.video_path('male1', 1), 8000) as first_id \gset
select pg_temp.video_assert(
  public.zyra_record_profile_video(pg_temp.video_actor('male1'), pg_temp.video_path('male1', 1), 8000) = :'first_id'::uuid,
  'retry of the same pending path returns its existing row'
);
reset role;

set local role authenticated;
select pg_temp.video_as('male1');
select pg_temp.video_assert(
  (select id = :'first_id'::uuid and status = 'pending' and storage_path = pg_temp.video_path('male1', 1)
     and duration_ms = 8000 and reject_reason is null
   from public.zyra_my_profile_video()),
  'owner sees the pending row, path and duration'
);
select pg_temp.video_refused(
  $sql$update public.profile_videos set status = 'approved' where user_id = auth.uid()$sql$,
  '42501', 'member cannot approve their own row directly'
);
select pg_temp.video_refused(
  $sql$delete from public.profile_videos where user_id = auth.uid()$sql$,
  '42501', 'member cannot delete their own row directly'
);
select pg_temp.video_as('fem1');
select pg_temp.video_assert(
  not public.zyra_my_paid_access('seeker') and public.zyra_can_view_profile(pg_temp.video_actor('male1')),
  'Basic viewer can see the owner profile'
);
select pg_temp.video_view(1, false, 'eligible profile viewer cannot read pending video');
select pg_temp.video_assert(
  not exists (select 1 from public.profile_videos where user_id = pg_temp.video_actor('male1')),
  'viewer cannot read the owner table row directly'
);
reset role;

set local role service_role;
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
select pg_temp.video_refused(
  format('select public.zyra_review_profile_video(%L, %L, null)', :'first_id', 'rejected'),
  '22023', 'reviewer must provide a rejection reason'
);
select public.zyra_review_profile_video(:'first_id', 'rejected', 'Please try another clip.');
select pg_temp.video_refused(
  format('select public.zyra_review_profile_video(%L, %L, null)', :'first_id', 'approved'),
  '55000', 'reviewer cannot approve a stale review'
);
reset role;

set local role authenticated;
select pg_temp.video_as('fem1');
select pg_temp.video_view(1, false, 'eligible profile viewer cannot read rejected video');
select pg_temp.video_as('male1');
select pg_temp.video_assert(
  (select status = 'rejected' and reject_reason = 'Please try another clip.'
     and storage_path = pg_temp.video_path('male1', 1) from public.zyra_my_profile_video())
  and exists (select 1 from storage.objects where bucket_id = 'profile-videos' and name = pg_temp.video_path('male1', 1)),
  'owner can read the rejected object and member-facing reason'
);
select pg_temp.video_assert(
  (select reviewed_at is not null from public.profile_videos where id = :'first_id'::uuid),
  'rejection stamps review time'
);
select set_config('storage.operation', 'storage.object.upload', true);
insert into storage.objects(bucket_id, name, owner_id) values
  ('profile-videos', pg_temp.video_path('male1', 2), auth.uid()::text),
  ('profile-videos', pg_temp.video_path('male1', 3), auth.uid()::text);
reset role;

set local role service_role;
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
select public.zyra_record_profile_video(pg_temp.video_actor('male1'), pg_temp.video_path('male1', 2), 8000) as second_id \gset
select public.zyra_review_profile_video(:'second_id', 'approved', null);
reset role;

set local role authenticated;
select pg_temp.video_as('fem1');
select set_config('storage.operation', 'storage.object.get_authenticated', true);
select pg_temp.video_view(2, true, 'Basic profile viewer can read approved video and duration');
select pg_temp.video_assert(
  not exists (select 1 from public.profile_videos where id = :'second_id'::uuid),
  'approved metadata remains private in the table'
);
select set_config('storage.operation', 'storage.object.sign', true);
select pg_temp.video_assert(
  not exists (select 1 from storage.objects where bucket_id = 'profile-videos' and name = pg_temp.video_path('male1', 2)),
  'viewer cannot mint a signed URL for an approved video'
);
select pg_temp.video_as('male1');
select pg_temp.video_assert(
  not exists (select 1 from storage.objects where bucket_id = 'profile-videos' and name = pg_temp.video_path('male1', 2)),
  'owner cannot mint a signed URL for an approved video'
);
select pg_temp.video_as('fem1');
select set_config('storage.operation', 'storage.object.delete_many', true);
with removed as (
  delete from storage.objects
  where bucket_id = 'profile-videos' and name = pg_temp.video_path('male1', 2)
  returning id
)
select pg_temp.video_assert(not exists (select 1 from removed), 'viewer cannot delete visible foreign object');
select set_config('storage.operation', 'storage.object.get_authenticated', true);
select pg_temp.video_as('male2');
select pg_temp.video_assert(not public.zyra_can_view_profile(pg_temp.video_actor('male1')), 'same-gender nonparticipant has no profile access');
select pg_temp.video_view(2, false, 'approved video is hidden from a caller without profile access');

-- Even after deletion, a member cannot recreate a path that has been reviewed.
select pg_temp.video_as('male1');
select set_config('storage.operation', 'storage.object.delete_many', true);
delete from storage.objects
where bucket_id = 'profile-videos' and name = pg_temp.video_path('male1', 2)
returning id as old_object_id
\gset
select set_config('storage.operation', 'storage.object.upload', true);
select pg_temp.video_refused(
  $sql$insert into storage.objects(bucket_id, name, owner_id)
  values ('profile-videos', pg_temp.video_path('male1', 2), auth.uid()::text)$sql$,
  '42501', 'member cannot recreate a path that has been approved'
);
reset role;

-- Trusted fixture insertion exercises object binding independently of insert RLS.
insert into storage.objects(bucket_id, name, owner_id)
values ('profile-videos', pg_temp.video_path('male1', 2), pg_temp.video_actor('male1')::text)
returning id as replacement_object_id
\gset
select pg_temp.video_assert(
  :'old_object_id'::uuid <> :'replacement_object_id'::uuid,
  'fixture replacement at the same path has a distinct object identity'
);
set local role authenticated;
select set_config('storage.operation', 'storage.object.get_authenticated', true);
select pg_temp.video_as('fem1');
select pg_temp.video_view(2, false, 'fixture replacement does not inherit the old approval');
reset role;

set local role service_role;
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
select pg_temp.video_refused(
  format(
    'select public.zyra_record_profile_video(pg_temp.video_actor(%L), pg_temp.video_path(%L, 2), 8000, %L)',
    'male1', 'male1', :'old_object_id'
  ),
  '55000', 'service cannot record a path after the validated object identity changes'
);
select public.zyra_record_profile_video(pg_temp.video_actor('male1'), pg_temp.video_path('male1', 3), 8000) as third_id \gset
reset role;

set local role authenticated;
select pg_temp.video_as('male1');
select pg_temp.video_assert(
  (select status = 'removed' from public.profile_videos where id = :'second_id'::uuid)
  and (select id = :'third_id'::uuid and status = 'pending' from public.zyra_my_profile_video())
  and (select count(*) = 1 from public.profile_videos where status in ('pending', 'approved')),
  'replacement removes the older approval and leaves one active row'
);
select pg_temp.video_as('fem1');
select pg_temp.video_view(2, false, 'replacement hides the previous video');
select pg_temp.video_view(3, false, 'replacement stays private pending approval');
reset role;

set local role service_role;
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
select public.zyra_review_profile_video(:'third_id', 'approved', null);
reset role;

update public.subscriptions set plan_type = 'seeker_basic'
where user_id = pg_temp.video_actor('male1');
set local role authenticated;
select pg_temp.video_as('fem1');
select pg_temp.video_assert(public.zyra_can_view_profile(pg_temp.video_actor('male1')), 'downgrade leaves the profile visible');
select pg_temp.video_view(3, false, 'downgrade hides approved video from profile viewer');
select pg_temp.video_as('male1');
select pg_temp.video_assert(
  (select id = :'third_id'::uuid and status = 'approved' from public.zyra_my_profile_video())
  and exists (select 1 from storage.objects where bucket_id = 'profile-videos' and name = pg_temp.video_path('male1', 3)),
  'downgrade keeps the owner row and object readable'
);
reset role;

update public.subscriptions set plan_type = 'seeker_premium'
where user_id = pg_temp.video_actor('male1');
set local role authenticated;
select pg_temp.video_as('fem1');
select pg_temp.video_view(3, true, 'return to One reveals the same approved video');
select pg_temp.video_as('male1');
select pg_temp.video_assert(
  public.zyra_remove_my_profile_video() = pg_temp.video_path('male1', 3),
  'owner removal returns the object path'
);
select pg_temp.video_assert(
  (select status = 'removed' from public.profile_videos where id = :'third_id'::uuid),
  'owner removal marks the approved row removed'
);
select pg_temp.video_assert(
  not exists (select 1 from public.zyra_my_profile_video()),
  'removed owner returns to Add without an older rejection reason'
);
select pg_temp.video_as('fem1');
select pg_temp.video_view(3, false, 'owner removal hides the video before object deletion');
select pg_temp.video_as('male1');
select set_config('storage.operation', 'storage.object.delete_many', true);
with removed as (
  delete from storage.objects
  where bucket_id = 'profile-videos' and name = pg_temp.video_path('male1', 3)
  returning id
)
select pg_temp.video_assert((select count(*) = 1 from removed), 'owner can delete the removed object');
select pg_temp.video_assert(public.zyra_remove_my_profile_video() is null, 'repeat removal returns no path');
reset role;

-- A funded Family Seeker seat grants access without a direct One plan.
select set_config('request.jwt.claims', '{}', true);
insert into private.verified_people(id, provider_code, provider_person_ref_hash)
values ('7a700000-0000-4000-8000-000000000101', 'stripe', repeat('a', 64));
insert into private.verified_person_accounts(verified_person_id, user_id, role)
values ('7a700000-0000-4000-8000-000000000101', pg_temp.video_actor('male2'), 'seeker');
insert into public.family_subscriptions(id, owner_id, owner_role, status, seeker_places, guardian_places, coverage_ends_at)
values ('7a700000-0000-4000-8000-000000000102', pg_temp.video_actor('male2'), 'seeker', 'active', 1, 0, now() + interval '1 day');
insert into public.family_seat_assignments(family_subscription_id, member_id, role, funded_until)
values ('7a700000-0000-4000-8000-000000000102', pg_temp.video_actor('male2'), 'seeker', now() + interval '1 day');
set constraints family_owner_row_guard, family_owner_seat_guard immediate;

set local role authenticated;
select pg_temp.video_as('male2');
select pg_temp.video_assert(public.zyra_my_paid_access('seeker'), 'funded Family Seeker has paid access');
select set_config('storage.operation', 'storage.object.upload', true);
insert into storage.objects(bucket_id, name, owner_id)
values ('profile-videos', pg_temp.video_path('male2', 1), auth.uid()::text);
reset role;
set local role service_role;
select set_config('request.jwt.claims', '{"role":"service_role"}', true);
select public.zyra_record_profile_video(pg_temp.video_actor('male2'), pg_temp.video_path('male2', 1), 8000) as family_id \gset
reset role;
set local role authenticated;
select pg_temp.video_as('male2');
select pg_temp.video_assert(
  (select id = :'family_id'::uuid and status = 'pending' from public.zyra_my_profile_video()),
  'funded Family Seeker can upload and submit'
);
select pg_temp.video_assert(
  public.zyra_remove_my_profile_video() = pg_temp.video_path('male2', 1),
  'owner can also remove a pending video'
);
reset role;

set local role anon;
select set_config('request.jwt.claims', '{"role":"anon"}', true);
select pg_temp.video_refused('select public.zyra_my_profile_video()', '42501', 'anon cannot use owner RPC');
select pg_temp.video_refused('select public.zyra_profile_video_for(null)', '42501', 'anon cannot use viewer RPC');
reset role;

rollback;
