-- DOC-ZYRA-0472 Q95 / OA-ZYRA-302 / OA-ZYRA-317.
-- Throw-away proof only until separately approved for live application.
begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile-photo-sources', 'profile-photo-sources', false, 8388608, array['image/jpeg']);

alter table public.profile_photos
  add column source_path text,
  add column crop jsonb,
  add column rotation integer not null default 0 check (rotation in (0, 90, 180, 270)),
  add column revision integer not null default 1 check (revision > 0),
  add column removed_at timestamptz,
  add constraint profile_photo_source_name check (
    source_path is null or source_path = user_id::text || '/' || id::text || '.jpg'
  );

-- Existing Browse and gallery clients use named legacy columns.
revoke select, insert, update, references on public.profile_photos from public, anon, authenticated;
grant select (id, user_id, storage_path, is_primary, display_order, created_at),
  insert (id, user_id, storage_path, is_primary, display_order, created_at),
  update (id, user_id, storage_path, is_primary, display_order, created_at)
  on public.profile_photos to authenticated;

create index profile_photos_live_source_idx on public.profile_photos (source_path)
  where removed_at is null and source_path is not null;

create table public.photo_object_deletions (
  path text not null,
  bucket text not null check (bucket in ('profile-photos', 'profile-photo-sources')),
  attempts integer not null default 0 check (attempts between 0 and 10),
  last_error text,
  done_at timestamptz,
  primary key (bucket, path)
);
alter table public.photo_object_deletions enable row level security;
revoke all on public.photo_object_deletions from public, anon, authenticated, service_role;
grant select on public.photo_object_deletions to service_role;
create index photo_object_deletions_pending_idx on public.photo_object_deletions (attempts, bucket, path)
  where done_at is null and attempts < 10;

create table private.zyra_photo_cleanup_leases (
  bucket text not null,
  path text not null,
  expires_at timestamptz not null,
  primary key (bucket, path),
  foreign key (bucket, path) references public.photo_object_deletions (bucket, path)
);
alter table private.zyra_photo_cleanup_leases enable row level security;
revoke all on private.zyra_photo_cleanup_leases from public, anon, authenticated, service_role;

create table private.zyra_photo_folder_guard (
  folder text primary key
);
alter table private.zyra_photo_folder_guard enable row level security;
revoke all on private.zyra_photo_folder_guard from public, anon, authenticated, service_role;

-- The gallery writer and cleanup claim serialize on the owner namespace. A
-- started path stays retired even after success so an old HTTP DELETE retry
-- cannot delete a newly uploaded photo with the same name.
create function private.zyra_lock_photo_folder(p_folder text)
returns void language plpgsql volatile set search_path = ''
as $$
begin
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('zyra-photo:' || p_folder, 0));
  -- The advisory lock orders current writers. The shared row write also
  -- rejects a stale repeatable-read/serializable snapshot after lock handoff.
  insert into private.zyra_photo_folder_guard (folder) values (p_folder)
  on conflict (folder) do update set folder = excluded.folder;
end;
$$;
revoke all on function private.zyra_lock_photo_folder(text)
  from public, anon, authenticated, service_role;

create function private.zyra_photo_path_writable(p_bucket text, p_path text)
returns boolean language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null or p_path is null or pg_catalog.split_part(p_path, '/', 1) <> v_me::text then
    return false;
  end if;
  perform private.zyra_lock_photo_folder(v_me::text);
  return exists (select 1 from auth.users u where u.id = v_me)
    and not exists (
      select 1 from public.photo_object_deletions d
      where d.bucket = p_bucket and d.path = p_path and d.attempts > 0
    );
end;
$$;
revoke all on function private.zyra_photo_path_writable(text,text)
  from public, anon, authenticated, service_role, supabase_storage_admin;
grant execute on function private.zyra_photo_path_writable(text,text) to authenticated;

create function private.zyra_lock_member_photo_statement()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is not null then perform private.zyra_lock_photo_folder(v_me::text); end if;
  return null;
end;
$$;
revoke all on function private.zyra_lock_member_photo_statement()
  from public, anon, authenticated, service_role;
create trigger zyra_lock_member_photo_statement
before insert or update or delete on public.profile_photos
for each statement execute function private.zyra_lock_member_photo_statement();

-- The same fence covers old direct gallery writes and the new RPC.
create or replace function private.zyra_enforce_photo_row_owner()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if new.user_id is distinct from (select auth.uid())
     or not private.zyra_photo_reference_owned(new.user_id, new.storage_path) then
    raise exception using errcode = '42501', message = 'photo_reference_not_owned';
  end if;
  if new.removed_at is null and exists (
    select 1 from public.photo_object_deletions d where d.attempts > 0
      and ((d.bucket = 'profile-photos' and d.path = new.storage_path)
        or (d.bucket = 'profile-photo-sources' and d.path = new.source_path))
  ) then
    raise exception using errcode = '22023', message = 'photo_path_retired';
  end if;
  if tg_op = 'UPDATE' and new.revision = old.revision then
    new.revision := old.revision + 1;
  end if;
  return new;
end;
$$;

drop policy profile_photos_select on public.profile_photos;
create policy profile_photos_select on public.profile_photos for select to authenticated
using (
  removed_at is null and private.zyra_photo_reference_owned(user_id, storage_path)
  and (user_id = (select auth.uid()) or exists (
    select 1 from public.profiles p
    where p.id = profile_photos.user_id and p.is_active and p.profile_complete
  ))
);

create or replace function public.zyra_can_read_photo_object(p_object_name text)
returns boolean language sql stable security definer set search_path = ''
as $$
  select (select auth.uid()) is not null and exists (
    select 1 from public.profile_photos pp
    where pp.storage_path = p_object_name and pp.removed_at is null
      and private.zyra_photo_reference_owned(pp.user_id, pp.storage_path)
      and public.zyra_can_view_profile(pp.user_id)
  );
$$;

create policy zyra_display_photo_writable_insert on storage.objects
  as restrictive for insert to authenticated with check (
    bucket_id <> 'profile-photos' or private.zyra_photo_path_writable(bucket_id, name)
  );
create policy zyra_display_photo_writable_update on storage.objects
  as restrictive for update to authenticated using (true) with check (
    bucket_id <> 'profile-photos' or private.zyra_photo_path_writable(bucket_id, name)
  );

-- Storage may authorize an upload in a rolled-back policy probe before its
-- privileged metadata write. Apply the fence to that final write as well.
create function private.zyra_enforce_photo_upload_fence()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare
  v_folder text := pg_catalog.split_part(new.name, '/', 1);
begin
  if v_folder !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    return new;
  end if;
  perform private.zyra_lock_photo_folder(v_folder);
  if (new.owner_id = v_folder and not exists (select 1 from auth.users u where u.id = v_folder::uuid))
     or exists (
       select 1 from public.photo_object_deletions d
        where d.bucket = new.bucket_id and d.path = new.name and d.attempts > 0
     ) then
    raise exception using errcode = '42501', message = 'photo_path_retired';
  end if;
  return new;
end;
$$;
revoke all on function private.zyra_enforce_photo_upload_fence()
  from public, anon, authenticated, service_role, supabase_storage_admin;
create trigger zyra_enforce_photo_upload_fence
before insert or update of bucket_id, name, owner_id on storage.objects
for each row when (new.bucket_id in ('profile-photos', 'profile-photo-sources'))
execute function private.zyra_enforce_photo_upload_fence();

create function private.zyra_source_photo_path_owned(p_path text, p_owner text)
returns boolean language sql stable set search_path = ''
as $$
  select p_owner = (select auth.uid())::text and
    p_path ~ ('^' || p_owner || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.]jpg$');
$$;
revoke all on function private.zyra_source_photo_path_owned(text,text)
  from public, anon, authenticated, service_role;
grant execute on function private.zyra_source_photo_path_owned(text,text) to authenticated;

create function private.zyra_photo_object_referenced(p_bucket text, p_path text)
returns boolean language sql volatile security definer set search_path = ''
as $$
  select case p_bucket
    when 'profile-photos' then exists (
      select 1 from public.profile_photos p where p.storage_path = p_path and p.removed_at is null
    )
    when 'profile-photo-sources' then exists (
      select 1 from public.profile_photos p where p.source_path = p_path and p.removed_at is null
    )
    else false end;
$$;
revoke all on function private.zyra_photo_object_referenced(text,text)
  from public, anon, authenticated, service_role;

create function private.zyra_source_photo_can_delete(p_path text)
returns boolean language plpgsql volatile security definer set search_path = ''
as $$
begin
  if not private.zyra_photo_path_writable('profile-photo-sources', p_path) then
    return false;
  end if;
  return not private.zyra_photo_object_referenced('profile-photo-sources', p_path);
end;
$$;
revoke all on function private.zyra_source_photo_can_delete(text)
  from public, anon, authenticated, service_role;
grant execute on function private.zyra_source_photo_can_delete(text) to authenticated;

create policy zyra_photo_sources_read on storage.objects for select to authenticated using (
  bucket_id = 'profile-photo-sources' and private.zyra_source_photo_path_owned(name, owner_id)
  and storage.allow_any_operation(array[
    'storage.object.get_authenticated', 'object.head_authenticated_info',
    'object.get_authenticated_info', 'storage.object.list', 'storage.object.list_v2',
    'storage.object.upload', 'storage.object.delete', 'storage.object.delete_many'
  ])
);
create policy zyra_photo_sources_insert on storage.objects for insert to authenticated with check (
  bucket_id = 'profile-photo-sources' and private.zyra_source_photo_path_owned(name, owner_id)
  and private.zyra_photo_path_writable(bucket_id, name)
);
create policy zyra_photo_sources_delete on storage.objects for delete to authenticated using (
  bucket_id = 'profile-photo-sources' and private.zyra_source_photo_path_owned(name, owner_id)
  and private.zyra_source_photo_can_delete(name)
);

create function private.zyra_queue_owned_photo_object(p_owner uuid, p_bucket text, p_path text)
returns void language sql volatile security definer set search_path = ''
as $$
  insert into public.photo_object_deletions (bucket, path)
  select p_bucket, p_path
  where pg_catalog.split_part(p_path, '/', 1) = p_owner::text
    and pg_catalog.length(p_path) > 37
    and not exists (
      select 1 from storage.objects o where o.bucket_id = p_bucket and o.name = p_path
        and o.owner_id is not null and o.owner_id <> p_owner::text
    )
  on conflict (bucket, path) do nothing;
$$;
revoke all on function private.zyra_queue_owned_photo_object(uuid,text,text)
  from public, anon, authenticated, service_role;

-- Old clients physically delete gallery rows before re-inserting display
-- paths. They do not carry the source or its UUID through that rewrite.
create function private.zyra_queue_deleted_photo_source()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  perform private.zyra_queue_owned_photo_object(old.user_id, 'profile-photo-sources', old.source_path);
  return old;
end;
$$;
revoke all on function private.zyra_queue_deleted_photo_source()
  from public, anon, authenticated, service_role;
create trigger zyra_queue_deleted_photo_source
after delete on public.profile_photos
for each row when (old.source_path is not null)
execute function private.zyra_queue_deleted_photo_source();

create function public.zyra_save_profile_photo(
  photo uuid, display_path text, source_path text, crop jsonb,
  rotation integer, expected_revision integer
) returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_existing public.profile_photos%rowtype;
  v_revision integer;
  v_x numeric;
  v_y numeric;
  v_w numeric;
  v_h numeric;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  perform private.zyra_lock_photo_folder(v_me::text);
  select p.* into v_existing from public.profile_photos p where p.id = photo for update;
  if (found and (v_existing.user_id <> v_me or v_existing.removed_at is not null))
     or expected_revision is distinct from coalesce(v_existing.revision, 0) then
    raise exception using errcode = '40001', message = 'stale';
  end if;
  if photo is null or source_path is distinct from v_me::text || '/' || photo::text || '.jpg'
     or not private.zyra_photo_reference_owned(v_me, display_path) then
    raise exception using errcode = '42501', message = 'photo_reference_not_owned';
  end if;
  -- Coordinate with the Storage API's row lock on delete. A staged source
  -- becomes protected by the source DELETE policy after this transaction.
  perform 1 from storage.objects o
   where o.bucket_id = 'profile-photo-sources' and o.name = source_path and o.owner_id = v_me::text
   for key share;
  if not found then
    raise exception using errcode = '42501', message = 'photo_reference_not_owned';
  end if;
  if jsonb_typeof(crop) is distinct from 'object' then
    raise exception using errcode = '22023', message = 'invalid_crop';
  end if;
  if rotation is null or rotation not in (0, 90, 180, 270)
     or crop - array['x', 'y', 'w', 'h'] <> '{}'::jsonb
     or jsonb_typeof(crop->'x') is distinct from 'number'
     or jsonb_typeof(crop->'y') is distinct from 'number'
     or jsonb_typeof(crop->'w') is distinct from 'number'
     or jsonb_typeof(crop->'h') is distinct from 'number' then
    raise exception using errcode = '22023', message = 'invalid_crop';
  end if;
  v_x := (crop->>'x')::numeric;
  v_y := (crop->>'y')::numeric;
  v_w := (crop->>'w')::numeric;
  v_h := (crop->>'h')::numeric;
  if v_x < 0 or v_y < 0 or v_w <= 0 or v_h <= 0 or v_x + v_w > 1 or v_y + v_h > 1 then
    raise exception using errcode = '22023', message = 'invalid_crop';
  end if;
  v_revision := expected_revision + 1;
  if expected_revision = 0 then
    insert into public.profile_photos (id, user_id, storage_path, source_path, crop, rotation,
                                       revision, display_order, is_primary)
    select photo, v_me, display_path, zyra_save_profile_photo.source_path,
           zyra_save_profile_photo.crop, zyra_save_profile_photo.rotation,
           v_revision, coalesce(max(p.display_order), -1) + 1, count(*) = 0
    from public.profile_photos p where p.user_id = v_me and p.removed_at is null;
  else
    update public.profile_photos p
       set storage_path = display_path, source_path = zyra_save_profile_photo.source_path,
           crop = zyra_save_profile_photo.crop, rotation = zyra_save_profile_photo.rotation,
           revision = v_revision
     where p.id = photo;
    if v_existing.storage_path is distinct from display_path then
      perform private.zyra_queue_owned_photo_object(v_me, 'profile-photos', v_existing.storage_path);
    end if;
    if v_existing.source_path is distinct from source_path then
      perform private.zyra_queue_owned_photo_object(v_me, 'profile-photo-sources', v_existing.source_path);
    end if;
  end if;
  return jsonb_build_object('revision', v_revision);
end;
$$;
revoke all on function public.zyra_save_profile_photo(uuid,text,text,jsonb,integer,integer)
  from public, anon, authenticated, service_role;
grant execute on function public.zyra_save_profile_photo(uuid,text,text,jsonb,integer,integer)
  to authenticated;

create function public.zyra_my_photo_sources()
returns table (photo uuid, display_path text, source_path text, crop jsonb, rotation integer, revision integer)
language sql stable security definer set search_path = ''
as $$
  select p.id, p.storage_path, s.name, p.crop, p.rotation, p.revision
  from public.profile_photos p
  left join storage.objects s on s.bucket_id = 'profile-photo-sources'
    and s.name = p.source_path and s.owner_id = p.user_id::text
  where p.user_id = (select auth.uid()) and p.removed_at is null
    and private.zyra_photo_reference_owned(p.user_id, p.storage_path)
  order by p.display_order, p.id;
$$;
revoke all on function public.zyra_my_photo_sources() from public, anon, authenticated, service_role;
grant execute on function public.zyra_my_photo_sources() to authenticated;

create function public.zyra_remove_profile_photo(photo uuid, expected_revision integer)
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_existing public.profile_photos%rowtype;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  perform private.zyra_lock_photo_folder(v_me::text);
  select p.* into v_existing from public.profile_photos p
   where p.id = photo and p.user_id = v_me and p.removed_at is null for update;
  if not found or expected_revision is distinct from v_existing.revision then
    raise exception using errcode = '40001', message = 'stale';
  end if;
  update public.profile_photos
  set removed_at = now(), is_primary = false, revision = v_existing.revision + 1
  where id = photo;
  perform private.zyra_queue_owned_photo_object(v_me, 'profile-photos', v_existing.storage_path);
  perform private.zyra_queue_owned_photo_object(v_me, 'profile-photo-sources', v_existing.source_path);
  return jsonb_build_object('revision', v_existing.revision + 1);
end;
$$;
revoke all on function public.zyra_remove_profile_photo(uuid,integer)
  from public, anon, authenticated, service_role;
grant execute on function public.zyra_remove_profile_photo(uuid,integer) to authenticated;

-- Retain legacy own-prefix protection and include staged/orphaned objects.
create function private.zyra_queue_photo_folder(p_owner uuid)
returns void language plpgsql security definer set search_path = ''
as $$
declare
  v_object record;
begin
  for v_object in
    select 'profile-photos'::text as bucket, p.storage_path as path
      from public.profile_photos p where p.user_id = p_owner
    union
    select 'profile-photo-sources', p.source_path from public.profile_photos p where p.user_id = p_owner
    union
    select o.bucket_id, o.name from storage.objects o
      where o.bucket_id in ('profile-photos', 'profile-photo-sources')
        and o.name like p_owner::text || '/%'
  loop
    perform private.zyra_queue_owned_photo_object(p_owner, v_object.bucket, v_object.path);
  end loop;
end;
$$;
revoke all on function private.zyra_queue_photo_folder(uuid)
  from public, anon, authenticated, service_role;

create or replace function public.zyra_reset_profile()
returns jsonb language plpgsql security definer set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_role text;
  v_active integer;
  v_photos integer;
  v_likes integer;
  v_saves integer;
  v_passes integer;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  perform private.zyra_lock_photo_folder(v_me::text);
  select role into v_role from public.profiles where id = v_me;
  if v_role is null then raise exception 'no_profile'; end if;
  if v_role <> 'seeker' then return jsonb_build_object('status','refused','reason','not_a_seeker'); end if;
  select count(*) into v_active from public.matches
  where status = 'active' and (seeker_a_id = v_me or seeker_b_id = v_me);
  if v_active > 0 then
    return jsonb_build_object('status','blocked','reason','active_journey','active',v_active);
  end if;

  perform private.zyra_queue_photo_folder(v_me);
  delete from public.profile_photos where user_id = v_me;
  get diagnostics v_photos = row_count;
  delete from public.onboarding_answers where user_id = v_me;
  delete from public.seeker_details where user_id = v_me;
  delete from public.likes where liker_id = v_me or liked_id = v_me;
  get diagnostics v_likes = row_count;
  delete from public.saves where saver_id = v_me or saved_id = v_me;
  get diagnostics v_saves = row_count;
  delete from public.passes where passer_id = v_me or passed_id = v_me;
  get diagnostics v_passes = row_count;
  update public.profiles set bio = null, location_text = null, profile_complete = false where id = v_me;

  return jsonb_build_object('status','reset','photos',v_photos,'likes',v_likes,
    'saves',v_saves,'passes',v_passes,'storage_paths','[]'::jsonb);
end;
$$;
comment on function public.zyra_reset_profile() is
  'Reset the signed-in Seeker after the existing Journey check. Photo cleanup is queued server-side.';

create or replace function public.delete_own_account()
returns void language plpgsql security definer set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
begin
  if v_me is null then raise exception 'Not signed in'; end if;
  perform private.zyra_lock_photo_folder(v_me::text);
  perform private.zyra_queue_photo_folder(v_me);
  delete from auth.users where id = v_me;
end;
$$;

create function public.zyra_claim_photo_object_deletions()
returns table (bucket text, path text, attempts integer)
language plpgsql security definer set search_path = ''
as $$
declare
  v_item record;
  v_now timestamptz := clock_timestamp();
begin
  -- One claim batch at a time, with a folder lock before the live reference
  -- check. Other folders can still be written while cleanup runs.
  if not pg_catalog.pg_try_advisory_xact_lock(
    pg_catalog.hashtextextended('zyra-photo-cleanup-claim', 0)
  ) then return; end if;
  for v_item in
    select d.bucket, d.path
    from public.photo_object_deletions d
    left join private.zyra_photo_cleanup_leases l on l.bucket = d.bucket and l.path = d.path
    where d.done_at is null and d.attempts < 10 and (l.expires_at is null or l.expires_at < v_now)
      and not private.zyra_photo_object_referenced(d.bucket, d.path)
    order by d.attempts, d.bucket, d.path
    limit 12
  loop
    if not pg_catalog.pg_try_advisory_xact_lock(pg_catalog.hashtextextended(
      'zyra-photo:' || pg_catalog.split_part(v_item.path, '/', 1), 0
    )) then continue; end if;
    perform private.zyra_lock_photo_folder(pg_catalog.split_part(v_item.path, '/', 1));
    if private.zyra_photo_object_referenced(v_item.bucket, v_item.path) then
      continue;
    end if;
    return query
    update public.photo_object_deletions d
      set attempts = d.attempts + 1, last_error = 'cleanup_interrupted'
      where d.bucket = v_item.bucket and d.path = v_item.path and d.done_at is null
      returning d.bucket, d.path, d.attempts;
    if found then
      insert into private.zyra_photo_cleanup_leases (bucket, path, expires_at)
      values (v_item.bucket, v_item.path, v_now + interval '2 minutes')
      on conflict on constraint zyra_photo_cleanup_leases_pkey do update set expires_at = excluded.expires_at;
    end if;
  end loop;
end;
$$;
revoke all on function public.zyra_claim_photo_object_deletions()
  from public, anon, authenticated, service_role;
grant execute on function public.zyra_claim_photo_object_deletions() to service_role;

create function public.zyra_finish_photo_object_deletion(
  p_bucket text, p_path text, p_attempt integer, p_error text
) returns void language plpgsql security definer set search_path = ''
as $$
begin
  -- An expired attempt cannot finish a later attempt or alter its lease.
  update public.photo_object_deletions d
    set last_error = left(p_error, 128), done_at = case when p_error is null then now() end
    where d.bucket = p_bucket and d.path = p_path and d.attempts = p_attempt
      and d.done_at is null and d.attempts > 0;
  if found then
    delete from private.zyra_photo_cleanup_leases l where l.bucket = p_bucket and l.path = p_path;
  end if;
end;
$$;
revoke all on function public.zyra_finish_photo_object_deletion(text,text,integer,text)
  from public, anon, authenticated, service_role;
grant execute on function public.zyra_finish_photo_object_deletion(text,text,integer,text) to service_role;

-- Existing publication and dev suggestion routes only count live photos.
create or replace function public.zyra_set_profile_complete(p_complete boolean default true)
 returns jsonb
 language plpgsql
 security definer
 set search_path = ''
as $function$
DECLARE
  v_me uuid := auth.uid();
  v_p  record;
  v_photos int;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  -- Un-publishing is always allowed: nobody should need permission to
  -- withdraw themselves. It no longer unfreezes identity — first_published_at
  -- is deliberately untouched here.
  IF NOT p_complete THEN
    UPDATE public.profiles SET profile_complete = false WHERE id = v_me;
    RETURN jsonb_build_object('status','unpublished');
  END IF;

  SELECT * INTO v_p FROM public.profiles WHERE id = v_me;
  IF v_p IS NULL THEN
    RAISE EXCEPTION 'no_profile';
  END IF;

  IF v_p.first_name IS NULL OR btrim(v_p.first_name) = ''
     OR v_p.gender IS NULL OR v_p.date_of_birth IS NULL THEN
    RETURN jsonb_build_object('status','incomplete','missing','identity');
  END IF;

  -- A Guardian has no photos and no Browse presence; the photo rule is a
  -- Seeker rule only.
  IF v_p.role = 'seeker' THEN
    PERFORM private.zyra_lock_photo_folder(v_me::text);
    SELECT count(*) INTO v_photos
      FROM public.profile_photos p
      WHERE p.user_id = v_me AND p.removed_at IS NULL
        AND private.zyra_photo_reference_owned(p.user_id, p.storage_path);
    IF v_photos < 1 THEN
      RETURN jsonb_build_object('status','incomplete','missing','photos');
    END IF;
  END IF;

  -- coalesce, not a bare now(): re-publishing after a break must not move
  -- the date, or the freeze would restart every time someone came back.
  UPDATE public.profiles
     SET profile_complete   = true,
         first_published_at = coalesce(first_published_at, now())
   WHERE id = v_me;
  RETURN jsonb_build_object('status','published');
END;
$function$;

create or replace function public.zyra_dev_set_guardian_suggestions(p_count int)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_my_gender text;
  v_wali uuid;
  v_ids uuid[];
  v_i int;
begin
  if v_me is null then raise exception 'not_signed_in'; end if;
  if not exists (select 1 from auth.users u where u.id = v_me and u.email like '%@zyra.test') then
    raise exception 'dev_accounts_only';
  end if;
  if p_count < 0 or p_count > 10 then raise exception 'count_out_of_range'; end if;

  select gender into v_my_gender from public.profiles where id = v_me;

  select wali_id into v_wali from public.wali_links
    where seeker_id = v_me and status = 'active'
    order by is_main desc nulls last limit 1;
  if v_wali is null then
    select p.id into v_wali from public.profiles p join auth.users u on u.id = p.id
      where u.email = 'dev.guardian.a@zyra.test';
  end if;
  if v_wali is null then raise exception 'no_guardian_available'; end if;

  delete from public.wali_suggestions where seeker_id = v_me;
  if p_count = 0 then return jsonb_build_object('created', 0); end if;

  select array_agg(id) into v_ids from (
    select p.id
    from public.profiles p
    left join auth.users u on u.id = p.id
    where p.role = 'seeker' and p.is_active and p.profile_complete
      and p.id <> v_me
      and (v_my_gender is null or p.gender <> v_my_gender)
    order by
      (u.email like 'dev.sugg.%') desc,
      (exists (select 1 from public.profile_photos ph
        where ph.user_id = p.id and ph.removed_at is null)) desc,
      p.created_at
    limit p_count
  ) x;

  if v_ids is null then return jsonb_build_object('created', 0); end if;

  for v_i in 1..array_length(v_ids,1) loop
    insert into public.wali_suggestions (wali_id, seeker_id, suggested_id, status)
    values (v_wali, v_me, v_ids[v_i], 'pending')
    on conflict (wali_id, seeker_id, suggested_id) do nothing;
  end loop;

  return jsonb_build_object('created', array_length(v_ids,1));
end;
$$;

commit;
