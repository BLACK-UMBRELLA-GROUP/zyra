-- DOC-ZYRA-0473 V4 / Q131 / OA-ZYRA-317.
begin;

-- The owner may sign a staged photo before inserting a gallery row.
-- Require that the owning Auth account still exists for this exception.
create function private.zyra_photo_caller_exists()
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from auth.users u where u.id = (select auth.uid()));
$$;
revoke all on function private.zyra_photo_caller_exists()
  from public, anon, authenticated, service_role;
grant execute on function private.zyra_photo_caller_exists() to authenticated;

alter table public.photo_object_deletions add column account_delete_due_at timestamptz;
comment on column public.photo_object_deletions.account_delete_due_at is
  'Physical removal deadline for an account deletion. Null for other queue entries.';

create index photo_object_deletions_pending_owner_idx
  on public.photo_object_deletions ((pg_catalog.split_part(path, '/', 1)))
  where done_at is null;

drop index public.photo_object_deletions_pending_idx;
create index photo_object_deletions_pending_idx on public.photo_object_deletions
  (account_delete_due_at, attempts, bucket, path)
  where done_at is null and attempts < 10;

-- Permit staging for signup and gallery uploads, but do not sign a deleted
-- row's object while it is queued and still physically present.
create function private.zyra_photo_not_queued(p_path text)
returns boolean language sql stable security definer set search_path = ''
as $$
  select not exists (
    select 1 from public.photo_object_deletions d
    where d.bucket = 'profile-photos' and d.path = p_path
  );
$$;
revoke all on function private.zyra_photo_not_queued(text)
  from public, anon, authenticated, service_role;
grant execute on function private.zyra_photo_not_queued(text) to authenticated;

alter policy profile_photos_storage_read on storage.objects using (
  bucket_id = 'profile-photos'
  and (select private.zyra_photo_caller_exists())
  and owner_id = pg_catalog.split_part(name, '/', 1)
  and pg_catalog.length(name) > 37
  and (
    public.zyra_can_read_photo_object(name)
    or (owner_id = (select auth.uid())::text and private.zyra_photo_not_queued(name))
  )
);

create or replace function public.delete_own_account()
returns void language plpgsql security definer set search_path = ''
as $$
declare
  v_me uuid := auth.uid();
  v_due_at timestamptz;
begin
  if v_me is null then raise exception 'Not signed in'; end if;
  perform private.zyra_lock_photo_folder(v_me::text);
  perform private.zyra_queue_photo_folder(v_me);
  v_due_at := clock_timestamp() + interval '24 hours';
  update public.photo_object_deletions d
    set account_delete_due_at = least(d.account_delete_due_at, v_due_at)
    where pg_catalog.split_part(d.path, '/', 1) = v_me::text and d.done_at is null;
  delete from auth.users where id = v_me;
end;
$$;

create or replace function public.zyra_claim_photo_object_deletions()
returns table (bucket text, path text, attempts integer)
language plpgsql security definer set search_path = ''
as $$
declare
  v_item record;
  v_now timestamptz := clock_timestamp();
begin
  -- Keep Q95's single claim, folder serialization and retry lease.
  if not pg_catalog.pg_try_advisory_xact_lock(
    pg_catalog.hashtextextended('zyra-photo-cleanup-claim', 0)
  ) then return; end if;
  for v_item in
    select d.bucket, d.path
    from public.photo_object_deletions d
    left join private.zyra_photo_cleanup_leases l on l.bucket = d.bucket and l.path = d.path
    where d.done_at is null and d.attempts < 10 and (l.expires_at is null or l.expires_at < v_now)
      and not private.zyra_photo_object_referenced(d.bucket, d.path)
    order by d.account_delete_due_at nulls last, d.attempts, d.bucket, d.path
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
      return;
    end if;
  end loop;
end;
$$;

-- Overdue account deletions stay retryable until the existing ten-attempt
-- cap. The service can review both missed deadlines and exhausted retries.
create view public.zyra_photo_cleanup_failures with (security_invoker = true) as
select d.bucket, d.path, d.attempts, d.last_error, d.account_delete_due_at
from public.photo_object_deletions d
where d.done_at is null and (d.attempts = 10 or d.account_delete_due_at <= now());
revoke all on public.zyra_photo_cleanup_failures from public, anon, authenticated, service_role;
grant select on public.zyra_photo_cleanup_failures to service_role;

commit;
