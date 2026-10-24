-- F03 / OA-ZYRA-305, OA-ZYRA-302: PREPARED, NOT PRODUCTION-APPLIED.
-- Founder authorized local/synthetic implementation, not production mutation.
-- Exact production GO must identify this final file hash, fresh catalog proof,
-- delivery/stop checks, seed impact and forward repair before execution.
--
-- Invariant: profile_photos.user_id = the canonical object-name UUID prefix
-- = storage.objects.owner_id, for an existing object in private profile-photos.
-- This is an authorization repair, not moderation/verification implementation.
-- No member rows, object metadata, files, bucket flags or seeds are rewritten.
-- Existing shared seed rows and NULL/mismatched owner_id fail closed on reads.
-- No test-account, seed, app_metadata or service-role exemption is introduced.
-- A separate approved Storage-API provenance reconciliation/re-upload is needed
-- before such legacy rows can become readable/editable. Never copy a member's
-- private photo to repair a seed, infer ownership, or bulk backfill owner_id.
--
-- Pre-commit failure: rollback this transaction (no data mutation to undo).
-- Post-commit: prefer a fresh reviewed forward repair. Restoring the old gate
-- reopens CRITICAL F03 and is not a safe automatic rollback. Existing signed
-- URLs/cache pixels are not revoked by RLS; token lifetime/cache remediation
-- and real-API signing acceptance remain separate exact-GO release gates.

begin;
set local lock_timeout = '5s';
set local statement_timeout = '30s';

do $preflight$
declare
  expected record;
  actual record;
begin
  if pg_catalog.to_regclass('public.profile_photos') is null
     or pg_catalog.to_regclass('storage.objects') is null
     or pg_catalog.to_regclass('storage.buckets') is null
     or pg_catalog.to_regnamespace('private') is null then
    raise exception 'F03 precondition: required catalog objects absent';
  end if;
  if not (select c.relrowsecurity from pg_catalog.pg_class c
          where c.oid = 'public.profile_photos'::regclass)
     or not (select c.relrowsecurity from pg_catalog.pg_class c
             where c.oid = 'storage.objects'::regclass) then
    raise exception 'F03 precondition: required RLS absent';
  end if;
  if (select count(*) from information_schema.columns
      where table_schema = 'storage' and table_name = 'objects'
        and column_name in ('owner_id', 'bucket_id', 'name')
        and data_type = 'text') <> 3
     or not exists (select 1 from storage.buckets
                    where id = 'profile-photos' and public is false) then
    raise exception 'F03 precondition: current text owner_id/bucket_id/name and private bucket required';
  end if;
  if pg_catalog.md5(pg_catalog.pg_get_functiondef(
       'public.zyra_can_read_photo_object(text)'::regprocedure))
       <> 'b9fefed6b1c4e2b92bea4bb4d879b493'
     or pg_catalog.md5(pg_catalog.pg_get_functiondef(
       'public.zyra_can_view_profile(uuid)'::regprocedure))
       <> '10bebeecc1fb937cc257816711baf99b' then
    raise exception 'F03 catalog drift: October 3 photo/profile gate hash mismatch';
  end if;
  if pg_catalog.has_function_privilege('anon',
       'public.zyra_can_read_photo_object(text)', 'execute')
     or not pg_catalog.has_function_privilege('authenticated',
       'public.zyra_can_read_photo_object(text)', 'execute') then
    raise exception 'F03 catalog drift: photo helper ACL mismatch';
  end if;
  if exists (select 1 from pg_catalog.pg_trigger
             where tgrelid = 'public.profile_photos'::regclass
               and not tgisinternal)
     or (select count(*) from pg_catalog.pg_policies
         where schemaname = 'public' and tablename = 'profile_photos') <> 4
     or (select count(*) from pg_catalog.pg_policies
         where schemaname = 'storage' and tablename = 'objects') <> 4 then
    raise exception 'F03 catalog drift: unexpected photo trigger/policy';
  end if;
  for expected in
    select * from (values
      ('public', 'profile_photos', 'profile_photos_delete', 'DELETE',
       '(user_id = ( SELECT auth.uid() AS uid))', null::text),
      ('public', 'profile_photos', 'profile_photos_insert', 'INSERT',
       null::text, '(user_id = ( SELECT auth.uid() AS uid))'),
      ('public', 'profile_photos', 'profile_photos_update', 'UPDATE',
       '(user_id = ( SELECT auth.uid() AS uid))', null::text),
      ('public', 'profile_photos', 'profile_photos_select', 'SELECT',
       '((user_id = ( SELECT auth.uid() AS uid)) OR (EXISTS ( SELECT 1
   FROM profiles p
  WHERE ((p.id = profile_photos.user_id) AND p.is_active AND p.profile_complete))))', null::text),
      ('storage', 'objects', 'profile_photos_storage_delete', 'DELETE',
       '((bucket_id = ''profile-photos''::text) AND ((storage.foldername(name))[1] = (auth.uid())::text))', null::text),
      ('storage', 'objects', 'profile_photos_storage_insert', 'INSERT',
       null::text, '((bucket_id = ''profile-photos''::text) AND ((storage.foldername(name))[1] = (auth.uid())::text))'),
      ('storage', 'objects', 'profile_photos_storage_update', 'UPDATE',
       '((bucket_id = ''profile-photos''::text) AND ((storage.foldername(name))[1] = (auth.uid())::text))', null::text),
      ('storage', 'objects', 'profile_photos_storage_read', 'SELECT',
       '((bucket_id = ''profile-photos''::text) AND (((storage.foldername(name))[1] = (( SELECT auth.uid() AS uid))::text) OR zyra_can_read_photo_object(name)))', null::text)
    ) as catalog(schema_name, table_name, policy_name, command, using_expr, check_expr)
  loop
    select * into actual from pg_catalog.pg_policies
    where schemaname = expected.schema_name and tablename = expected.table_name
      and policyname = expected.policy_name;
    if not found or actual.cmd is distinct from expected.command
       or actual.qual is distinct from expected.using_expr
       or actual.with_check is distinct from expected.check_expr
       or actual.roles is distinct from array['public']::name[]
       or actual.permissive is distinct from 'PERMISSIVE' then
      raise exception 'F03 catalog drift: policy % differs', expected.policy_name;
    end if;
  end loop;
  if not exists (
    select 1 from pg_catalog.pg_proc p join pg_catalog.pg_roles r on r.oid = p.proowner
    where p.oid = 'public.zyra_can_read_photo_object(text)'::regprocedure
      and r.rolname = 'postgres' and (r.rolsuper or r.rolbypassrls)
  ) then
    raise exception 'F03 precondition: pinned privileged lookup owner required';
  end if;
end;
$preflight$;

create function private.zyra_photo_reference_owned(p_user_id uuid, p_path text)
returns boolean language sql stable security definer set search_path = ''
as $function$
  select (select auth.uid()) is not null
    and p_user_id is not null
    and pg_catalog.split_part(p_path, '/', 1) = p_user_id::text
    and pg_catalog.length(p_path) > 37
    and exists (
      select 1 from storage.objects o
      where o.bucket_id = 'profile-photos' and o.name = p_path
        and o.owner_id = p_user_id::text
    );
$function$;
alter function private.zyra_photo_reference_owned(uuid, text) owner to postgres;
revoke all on function private.zyra_photo_reference_owned(uuid, text)
  from public, anon, authenticated, service_role, supabase_storage_admin;
-- Stored policies invoke the OID; no new private-schema USAGE/API exposure.
grant execute on function private.zyra_photo_reference_owned(uuid, text)
  to authenticated;

alter table public.profile_photos add constraint profile_photos_owner_path_ck
  check (pg_catalog.split_part(storage_path, '/', 1) = user_id::text
         and pg_catalog.length(storage_path) > 37) not valid;

create function private.zyra_enforce_photo_row_owner()
returns trigger language plpgsql security definer set search_path = ''
as $function$
begin
  -- This is a member-write trigger, not a privileged seeding/import doorway.
  -- Even BYPASSRLS inserts require a signed-in owner and proven object binding.
  if (select auth.uid()) is null or new.user_id is distinct from (select auth.uid())
     or not private.zyra_photo_reference_owned(new.user_id, new.storage_path) then
    raise exception using errcode = '42501', message = 'photo_reference_not_owned';
  end if;
  return new;
end;
$function$;
alter function private.zyra_enforce_photo_row_owner() owner to postgres;
revoke all on function private.zyra_enforce_photo_row_owner()
  from public, anon, authenticated, service_role, supabase_storage_admin;
create trigger zyra_photo_row_owner
before insert or update on public.profile_photos
for each row execute function private.zyra_enforce_photo_row_owner();

drop policy profile_photos_insert on public.profile_photos;
create policy profile_photos_insert on public.profile_photos for insert to authenticated
with check (user_id = (select auth.uid())
            and private.zyra_photo_reference_owned(user_id, storage_path));
drop policy profile_photos_update on public.profile_photos;
create policy profile_photos_update on public.profile_photos for update to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid())
            and private.zyra_photo_reference_owned(user_id, storage_path));
drop policy profile_photos_select on public.profile_photos;
create policy profile_photos_select on public.profile_photos for select to authenticated
using (
  private.zyra_photo_reference_owned(user_id, storage_path)
  and (user_id = (select auth.uid()) or exists (
    select 1 from public.profiles p
    where p.id = profile_photos.user_id and p.is_active and p.profile_complete
  ))
);
-- DELETE policy is not expanded; invalid historic references need separately
-- authorized reconciliation instead of visibility/ownership exceptions.

create or replace function public.zyra_can_read_photo_object(p_object_name text)
returns boolean language sql stable security definer set search_path = ''
as $function$
  select (select auth.uid()) is not null and exists (
    select 1 from public.profile_photos pp
    where pp.storage_path = p_object_name
      and private.zyra_photo_reference_owned(pp.user_id, pp.storage_path)
      and public.zyra_can_view_profile(pp.user_id)
  );
$function$;
revoke all on function public.zyra_can_read_photo_object(text) from public, anon;
grant execute on function public.zyra_can_read_photo_object(text)
  to authenticated, service_role, supabase_storage_admin;
comment on function public.zyra_can_read_photo_object(text) is
  'F03: private object owner_id, canonical owner prefix and profile row owner must agree; existing profile visibility remains authoritative. No seed exemption.';

drop policy profile_photos_storage_read on storage.objects;
create policy profile_photos_storage_read on storage.objects for select to authenticated
using (
  bucket_id = 'profile-photos' and (select auth.uid()) is not null
  and owner_id = pg_catalog.split_part(name, '/', 1)
  and pg_catalog.length(name) > 37
  and (owner_id = (select auth.uid())::text
       or public.zyra_can_read_photo_object(name))
);
drop policy profile_photos_storage_insert on storage.objects;
create policy profile_photos_storage_insert on storage.objects for insert to authenticated
with check (
  bucket_id = 'profile-photos' and owner_id = (select auth.uid())::text
  and pg_catalog.split_part(name, '/', 1) = (select auth.uid())::text
  and pg_catalog.length(name) > 37
);
drop policy profile_photos_storage_update on storage.objects;
create policy profile_photos_storage_update on storage.objects for update to authenticated
using (
  bucket_id = 'profile-photos' and owner_id = (select auth.uid())::text
  and pg_catalog.split_part(name, '/', 1) = (select auth.uid())::text
)
with check (
  bucket_id = 'profile-photos' and owner_id = (select auth.uid())::text
  and pg_catalog.split_part(name, '/', 1) = (select auth.uid())::text
  and pg_catalog.length(name) > 37
);
drop policy profile_photos_storage_delete on storage.objects;
create policy profile_photos_storage_delete on storage.objects for delete to authenticated
using (
  bucket_id = 'profile-photos' and owner_id = (select auth.uid())::text
  and pg_catalog.split_part(name, '/', 1) = (select auth.uid())::text
);

commit;
