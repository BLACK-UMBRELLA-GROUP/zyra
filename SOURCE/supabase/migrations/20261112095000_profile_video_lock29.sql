-- LOCK 29 V2 / DOC-ZYRA-0445 / OA-ZYRA-317. Apply only after SERVER 0.
begin;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile-videos', 'profile-videos', false, 20971520,
        array['video/mp4', 'video/quicktime']);

create table public.profile_videos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null unique,
  status text not null check (status in ('pending', 'approved', 'rejected', 'removed')),
  duration_ms integer not null check (duration_ms between 1 and 10500),
  reject_reason text,
  created_at timestamptz not null default clock_timestamp(),
  reviewed_at timestamptz
);

create unique index profile_videos_one_current_per_user
  on public.profile_videos (user_id) where status in ('pending', 'approved');
create index profile_videos_latest_by_user
  on public.profile_videos (user_id, created_at desc, id desc);

alter table public.profile_videos enable row level security;
revoke all on public.profile_videos from public, anon, authenticated, service_role;
grant select on public.profile_videos to authenticated;
create policy profile_videos_read_own on public.profile_videos
  for select to authenticated using (user_id = (select auth.uid()));

create function public.zyra_can_read_profile_video_object(p_object_name text)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select (select auth.uid()) is not null and exists (
    select 1
    from public.profile_videos video
    join storage.objects object
      on object.id = video.id
     and object.bucket_id = 'profile-videos'
     and object.name = video.storage_path
    where video.storage_path = p_object_name
      and video.status = 'approved'
      and public.zyra_has_paid_role(video.user_id, 'seeker')
      and public.zyra_can_view_profile(video.user_id)
  );
$$;

create policy profile_videos_storage_insert on storage.objects
  for insert to authenticated with check (
    bucket_id = 'profile-videos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and name ~ '^[0-9a-f-]{36}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.](mp4|mov)$'
    and (select public.zyra_my_paid_access('seeker'))
    and storage.allow_any_operation(array['storage.object.upload'])
    and not exists (
      select 1 from public.profile_videos video where video.storage_path = name
    )
  );

create policy profile_videos_storage_read on storage.objects
  for select to authenticated using (
    bucket_id = 'profile-videos'
    and (
      (
        (storage.foldername(name))[1] = (select auth.uid())::text
        and storage.allow_any_operation(array[
          'storage.object.get_authenticated', 'object.head_authenticated_info',
          'object.get_authenticated_info', 'storage.object.list', 'storage.object.list_v2',
          'storage.object.upload', 'storage.object.delete', 'storage.object.delete_many'
        ])
      )
      or (
        storage.allow_any_operation(array[
          'storage.object.get_authenticated', 'object.head_authenticated_info'
        ])
        and public.zyra_can_read_profile_video_object(name)
      )
    )
  );

create policy profile_videos_storage_delete on storage.objects
  for delete to authenticated using (
    bucket_id = 'profile-videos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create function public.zyra_my_profile_video()
returns table (id uuid, status text, reject_reason text, storage_path text, duration_ms integer)
language sql stable security definer set search_path = ''
as $$
  select latest.id, latest.status, latest.reject_reason, latest.storage_path, latest.duration_ms
  from (
    select video.*
    from public.profile_videos video
    where video.user_id = (select auth.uid())
    order by video.created_at desc, video.id desc
    limit 1
  ) latest
  where latest.status = 'rejected'
     or (
       latest.status in ('pending', 'approved')
       and exists (
         select 1
         from storage.objects object
         where object.id = latest.id
           and object.bucket_id = 'profile-videos'
           and object.name = latest.storage_path
       )
     );
$$;

create function public.zyra_profile_video_for(p_user uuid)
returns table (storage_path text, duration_ms integer)
language sql stable security definer set search_path = ''
as $$
  select video.storage_path, video.duration_ms
  from public.profile_videos video
  where video.user_id = p_user
    and video.status = 'approved'
    and public.zyra_can_read_profile_video_object(video.storage_path);
$$;

create function public.zyra_remove_my_profile_video()
returns text
language plpgsql security definer set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_path text;
begin
  if v_user is null then
    raise insufficient_privilege using message = 'profile_video_not_allowed';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('zyra_profile_video:' || v_user::text, 0)
  );
  update public.profile_videos
  set status = 'removed'
  where user_id = v_user and status in ('pending', 'approved')
  returning storage_path into v_path;
  return v_path;
end;
$$;

-- Use the Storage object UUID as the row UUID. Deleting and re-uploading at
-- the same path creates a different object and cannot inherit approval.
create function public.zyra_record_profile_video(
  p_user uuid, p_path text, p_duration_ms integer, p_object_id uuid
)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_previous public.profile_videos%rowtype;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('zyra_profile_video:' || p_user::text, 0)
  );
  if not public.zyra_has_paid_role(p_user, 'seeker') then
    raise insufficient_privilege using message = 'profile_video_not_allowed';
  end if;
  if p_path is null or pg_catalog.split_part(p_path, '/', 1) <> p_user::text
    or p_path !~ '^[0-9a-f-]{36}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.](mp4|mov)$'
    or p_duration_ms is null or p_duration_ms not between 1 and 10500 then
    raise invalid_parameter_value using message = 'profile_video_invalid_upload';
  end if;

  perform 1 from storage.objects object
  where object.id = p_object_id and object.bucket_id = 'profile-videos' and object.name = p_path
  for key share;
  if not found then
    raise object_not_in_prerequisite_state using message = 'profile_video_upload_changed';
  end if;

  select video.* into v_previous
  from public.profile_videos video
  where video.storage_path = p_path;
  if found then
    if v_previous.id = p_object_id and v_previous.status in ('pending', 'approved') then
      return v_previous.id;
    end if;
    raise object_not_in_prerequisite_state using message = 'profile_video_path_used';
  end if;

  update public.profile_videos
  set status = 'removed'
  where user_id = p_user and status in ('pending', 'approved');

  insert into public.profile_videos (id, user_id, storage_path, status, duration_ms)
  values (p_object_id, p_user, p_path, 'pending', p_duration_ms);
  return p_object_id;
end;
$$;

create function public.zyra_record_profile_video(p_user uuid, p_path text, p_duration_ms integer)
returns uuid
language sql security definer set search_path = ''
as $$
  select public.zyra_record_profile_video(p_user, p_path, p_duration_ms, (
    select object.id from storage.objects object
    where object.bucket_id = 'profile-videos' and object.name = p_path
  ));
$$;

create function public.zyra_review_profile_video(p_video uuid, p_decision text, p_reason text)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  v_reason text := pg_catalog.btrim(p_reason);
begin
  if p_decision is null or p_decision not in ('approved', 'rejected')
    or (p_decision = 'rejected' and (
      v_reason is null or v_reason = '' or pg_catalog.char_length(v_reason) > 160
      or v_reason ~ '[[:cntrl:]]'
    )) then
    raise invalid_parameter_value using message = 'profile_video_invalid_review';
  end if;

  update public.profile_videos video
  set status = p_decision, reviewed_at = clock_timestamp(),
      reject_reason = case when p_decision = 'rejected' then v_reason end
  where video.id = p_video and video.status = 'pending'
    and (
      p_decision = 'rejected' or exists (
        select 1 from storage.objects object
        where object.id = video.id and object.bucket_id = 'profile-videos'
          and object.name = video.storage_path
      )
    );
  if not found then
    raise object_not_in_prerequisite_state using message = 'profile_video_review_unavailable';
  end if;

  -- SERVER 0 has no shared moderation audit table. Reviewer audit: OA-AIOS-413.
end;
$$;

revoke all on function public.zyra_can_read_profile_video_object(text),
  public.zyra_my_profile_video(), public.zyra_profile_video_for(uuid),
  public.zyra_remove_my_profile_video()
  from public, anon, authenticated, service_role;
grant execute on function public.zyra_can_read_profile_video_object(text),
  public.zyra_my_profile_video(), public.zyra_profile_video_for(uuid),
  public.zyra_remove_my_profile_video() to authenticated;

revoke all on function public.zyra_record_profile_video(uuid, text, integer),
  public.zyra_record_profile_video(uuid, text, integer, uuid),
  public.zyra_review_profile_video(uuid, text, text)
  from public, anon, authenticated, service_role;
grant execute on function public.zyra_record_profile_video(uuid, text, integer),
  public.zyra_record_profile_video(uuid, text, integer, uuid),
  public.zyra_review_profile_video(uuid, text, text) to service_role;

commit;
