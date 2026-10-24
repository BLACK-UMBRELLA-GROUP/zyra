-- F03 isolated SQL acceptance only, not real Storage API/signing acceptance.
-- Fresh synthetic fixture -> candidate -> this file. Root alone runs runtime.
-- All test changes below roll back. No member/photo data or files are used.
\set ON_ERROR_STOP on
do $guard$
begin
  if pg_catalog.current_database() not like 'zyra\_f03\_synthetic\_%' escape '\'
     or pg_catalog.current_setting('zyra.synthetic_fixture', true)
        is distinct from 'f03_owner_binding'
     or current_user <> 'postgres' then
    raise exception 'F03 assertions refused: isolated database prefix/GUC/owner required';
  end if;
  if not exists (select 1 from public.profiles
                 where id = '00000000-0000-0000-0000-00000000f301')
     or (select count(*) from public.profiles) <> 8 then
    raise exception 'F03 assertions require the exact synthetic fixture';
  end if;
end;
$guard$;

begin;
create schema f03_test;
grant usage on schema f03_test to authenticated, anon, service_role;
create function f03_test.ok(p_name text, p_condition boolean) returns void
language plpgsql as $function$
begin
  if p_condition is distinct from true then
    raise exception 'F03 FAIL: %', p_name;
  end if;
  raise notice 'F03 PASS: %', p_name;
end;
$function$;
create function f03_test.denied(p_name text, p_sql text) returns void
language plpgsql as $function$
declare
  rejected boolean := false;
begin
  begin
    execute p_sql;
  exception when insufficient_privilege then
    rejected := true;
  end;
  perform f03_test.ok(p_name, rejected);
end;
$function$;
grant execute on all functions in schema f03_test to authenticated, anon, service_role;

select f03_test.ok('profile visibility definition remains byte-identical',
  md5(pg_get_functiondef('public.zyra_can_view_profile(uuid)'::regprocedure))
  = '10bebeecc1fb937cc257816711baf99b');
select f03_test.ok('private bucket remains private',
  (select public is false from storage.buckets where id = 'profile-photos'));
select f03_test.ok('no legacy records/metadata silently rewritten',
  (select count(*) = 8 from public.profile_photos)
  and (select count(*) = 8 from storage.objects)
  and (select owner_id is null from storage.objects
       where id = '00000000-0000-0000-0000-00000000f336'));
select f03_test.ok('new path check deliberately NOT VALID for legacy quarantine',
  exists (select 1 from pg_constraint
          where conrelid = 'public.profile_photos'::regclass
            and conname = 'profile_photos_owner_path_ck' and not convalidated));
select f03_test.ok('three owner helpers have pinned empty search path',
  (select count(*) = 3 from pg_proc
   where oid in ('private.zyra_photo_reference_owned(uuid,text)'::regprocedure,
                 'private.zyra_enforce_photo_row_owner()'::regprocedure,
                 'public.zyra_can_read_photo_object(text)'::regprocedure)
     and prosecdef and proconfig = array['search_path=""']::text[]));
select f03_test.ok('anonymous photo helper execution remains denied',
  not has_function_privilege('anon', 'public.zyra_can_read_photo_object(text)', 'execute'));
select f03_test.ok('private lookup granted only to stored authenticated policies',
  has_function_privilege('authenticated', 'private.zyra_photo_reference_owned(uuid,text)', 'execute')
  and not has_function_privilege('anon', 'private.zyra_photo_reference_owned(uuid,text)', 'execute')
  and not has_function_privilege('service_role', 'private.zyra_photo_reference_owned(uuid,text)', 'execute')
  and not has_schema_privilege('authenticated', 'private', 'usage'));
select f03_test.ok('trigger has no member executable permission',
  not has_function_privilege('authenticated', 'private.zyra_enforce_photo_row_owner()', 'execute'));
select f03_test.ok('Storage policies stay exactly four and member-scoped',
  (select count(*) = 4 and bool_and(roles = array['authenticated']::name[])
   from pg_policies where schemaname = 'storage' and tablename = 'objects'));

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000f301', true);
select f03_test.ok('owned existing photo row remains readable',
  (select count(*) = 1 from public.profile_photos
   where id = '00000000-0000-0000-0000-00000000f341'));
select f03_test.ok('owned orphan upload readable before publication',
  (select count(*) = 1 from storage.objects
   where name = '00000000-0000-0000-0000-00000000f301/orphan.jpg'));
select f03_test.ok('authenticated policy OID works without private schema USAGE',
  (select count(*) = 1 from storage.objects
   where name = '00000000-0000-0000-0000-00000000f301/owner.jpg')
  and public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f301/owner.jpg'));
select f03_test.ok('legacy self-owned row cannot reveal same-gender foreign object',
  not public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f303/owner.jpg')
  and (select count(*) = 0 from storage.objects
       where name = '00000000-0000-0000-0000-00000000f303/owner.jpg')
  and (select count(*) = 0 from public.profile_photos
       where id = '00000000-0000-0000-0000-00000000f345'));
select f03_test.ok('legacy row/path owner mismatch is not a shared seed exemption',
  not public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f308/shared.jpg')
  and (select count(*) = 0 from storage.objects
       where name = '00000000-0000-0000-0000-00000000f308/shared.jpg')
  and (select count(*) = 0 from public.profile_photos
       where id = '00000000-0000-0000-0000-00000000f348'));
select f03_test.ok('matching own prefix with foreign object owner_id is denied',
  not public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f301/wrong-owner.jpg')
  and (select count(*) = 0 from storage.objects
       where name = '00000000-0000-0000-0000-00000000f301/wrong-owner.jpg')
  and (select count(*) = 0 from public.profile_photos
       where id = '00000000-0000-0000-0000-00000000f347'));
select f03_test.ok('visible target with NULL object owner remains denied',
  not public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f302/null-owner.jpg')
  and (select count(*) = 0 from storage.objects
       where name = '00000000-0000-0000-0000-00000000f302/null-owner.jpg'));

insert into storage.objects values
 ('00000000-0000-0000-0000-00000000f351', 'profile-photos',
  '00000000-0000-0000-0000-00000000f301/fresh.jpg', '00000000-0000-0000-0000-00000000f301');
insert into public.profile_photos (id, user_id, storage_path) values
 ('00000000-0000-0000-0000-00000000f361', '00000000-0000-0000-0000-00000000f301',
  '00000000-0000-0000-0000-00000000f301/fresh.jpg');
select f03_test.ok('legitimate Storage upload and row registration succeed',
  (select count(*) = 1 from public.profile_photos
   where id = '00000000-0000-0000-0000-00000000f361')
  and public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f301/fresh.jpg'));
update storage.objects set name = name, owner_id = owner_id
where id = '00000000-0000-0000-0000-00000000f351';
update public.profile_photos set display_order = 4, is_primary = true
where id = '00000000-0000-0000-0000-00000000f361';
select f03_test.ok('owned metadata upsert/reorder succeeds',
  (select display_order = 4 and is_primary from public.profile_photos
   where id = '00000000-0000-0000-0000-00000000f361'));
insert into storage.objects values
 ('00000000-0000-0000-0000-00000000f352', 'profile-photos',
  '00000000-0000-0000-0000-00000000f301/replacement.jpg', '00000000-0000-0000-0000-00000000f301');
update public.profile_photos set storage_path = '00000000-0000-0000-0000-00000000f301/replacement.jpg'
where id = '00000000-0000-0000-0000-00000000f361';
select f03_test.ok('owned uploaded replacement can become the registered photo',
  public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f301/replacement.jpg'));
delete from storage.objects where id = '00000000-0000-0000-0000-00000000f351';
select f03_test.ok('owned superseded upload can be deleted',
  (select count(*) = 0 from storage.objects where id = '00000000-0000-0000-0000-00000000f351'));

select f03_test.denied('Storage upload cannot spoof another owner_id', $sql$
  insert into storage.objects values ('00000000-0000-0000-0000-00000000f353',
   'profile-photos', '00000000-0000-0000-0000-00000000f301/spoof.jpg',
   '00000000-0000-0000-0000-00000000f302')
$sql$);
select f03_test.denied('Storage upload cannot use another folder', $sql$
  insert into storage.objects values ('00000000-0000-0000-0000-00000000f353',
   'profile-photos', '00000000-0000-0000-0000-00000000f302/spoof.jpg',
   '00000000-0000-0000-0000-00000000f301')
$sql$);
select f03_test.denied('Storage upload cannot omit owner_id', $sql$
  insert into storage.objects values ('00000000-0000-0000-0000-00000000f353',
   'profile-photos', '00000000-0000-0000-0000-00000000f301/spoof.jpg', null)
$sql$);
select f03_test.denied('Storage upload cannot target another bucket', $sql$
  insert into storage.objects values ('00000000-0000-0000-0000-00000000f353',
   'unrelated', '00000000-0000-0000-0000-00000000f301/spoof.jpg',
   '00000000-0000-0000-0000-00000000f301')
$sql$);
select f03_test.denied('Storage upload cannot use NULL bucket', $sql$
  insert into storage.objects values ('00000000-0000-0000-0000-00000000f353',
   null, '00000000-0000-0000-0000-00000000f301/spoof.jpg',
   '00000000-0000-0000-0000-00000000f301')
$sql$);
select f03_test.denied('Storage upload cannot use NULL name', $sql$
  insert into storage.objects values ('00000000-0000-0000-0000-00000000f353',
   'profile-photos', null, '00000000-0000-0000-0000-00000000f301')
$sql$);
select f03_test.denied('Storage upload cannot register empty owner-folder filename', $sql$
  insert into storage.objects values ('00000000-0000-0000-0000-00000000f353',
   'profile-photos', '00000000-0000-0000-0000-00000000f301/',
   '00000000-0000-0000-0000-00000000f301')
$sql$);
select f03_test.denied('Storage replacement cannot reassign owner_id', $sql$
  update storage.objects set owner_id = '00000000-0000-0000-0000-00000000f302'
  where id = '00000000-0000-0000-0000-00000000f352'
$sql$);
select f03_test.denied('Storage replacement cannot move to foreign folder', $sql$
  update storage.objects set name = '00000000-0000-0000-0000-00000000f302/moved.jpg'
  where id = '00000000-0000-0000-0000-00000000f352'
$sql$);
select f03_test.denied('Storage replacement cannot move bucket', $sql$
  update storage.objects set bucket_id = 'unrelated'
  where id = '00000000-0000-0000-0000-00000000f352'
$sql$);
select f03_test.denied('profile row cannot register a known foreign object', $sql$
  insert into public.profile_photos (id, user_id, storage_path) values
   ('00000000-0000-0000-0000-00000000f362', '00000000-0000-0000-0000-00000000f301',
    '00000000-0000-0000-0000-00000000f303/owner.jpg')
$sql$);
select f03_test.denied('profile row cannot register a nonexistent own object', $sql$
  insert into public.profile_photos (id, user_id, storage_path) values
   ('00000000-0000-0000-0000-00000000f362', '00000000-0000-0000-0000-00000000f301',
    '00000000-0000-0000-0000-00000000f301/nonexistent.jpg')
$sql$);
select f03_test.denied('profile row cannot use correct path with mismatched object owner', $sql$
  insert into public.profile_photos (id, user_id, storage_path) values
   ('00000000-0000-0000-0000-00000000f362', '00000000-0000-0000-0000-00000000f301',
    '00000000-0000-0000-0000-00000000f301/wrong-owner.jpg')
$sql$);
select f03_test.denied('photo replacement cannot register foreign object', $sql$
  update public.profile_photos
  set storage_path = '00000000-0000-0000-0000-00000000f303/owner.jpg'
  where id = '00000000-0000-0000-0000-00000000f361'
$sql$);
select f03_test.denied('photo replacement cannot transfer row user', $sql$
  update public.profile_photos set user_id = '00000000-0000-0000-0000-00000000f302',
  storage_path = '00000000-0000-0000-0000-00000000f302/owner.jpg'
  where id = '00000000-0000-0000-0000-00000000f361'
$sql$);
select f03_test.ok('rejected replacement keeps legitimate binding unchanged',
  (select user_id = '00000000-0000-0000-0000-00000000f301'
   and storage_path = '00000000-0000-0000-0000-00000000f301/replacement.jpg'
   from public.profile_photos where id = '00000000-0000-0000-0000-00000000f361'));
with changed as (update storage.objects set name = name
  where id = '00000000-0000-0000-0000-00000000f333' returning id)
select f03_test.ok('foreign object update filters to zero rows', (select count(*) = 0 from changed));
with changed as (delete from storage.objects
  where id = '00000000-0000-0000-0000-00000000f333' returning id)
select f03_test.ok('foreign object deletion filters to zero rows', (select count(*) = 0 from changed));
with changed as (update public.profile_photos set display_order = 5
  where id = '00000000-0000-0000-0000-00000000f342' returning id)
select f03_test.ok('foreign row update filters to zero rows', (select count(*) = 0 from changed));
delete from public.profile_photos where id = '00000000-0000-0000-0000-00000000f361';
delete from storage.objects where id = '00000000-0000-0000-0000-00000000f352';
select f03_test.ok('legitimate own row/object cleanup remains allowed',
  (select count(*) = 0 from public.profile_photos where id = '00000000-0000-0000-0000-00000000f361')
  and (select count(*) = 0 from storage.objects where id = '00000000-0000-0000-0000-00000000f352'));

-- Existing profile decisions, rather than a new F03 visibility shortcut.
select f03_test.ok('completed opposite-gender discovery remains allowed',
  public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f302/owner.jpg')
  and (select count(*) = 1 from storage.objects
       where name = '00000000-0000-0000-0000-00000000f302/owner.jpg'));
select f03_test.ok('shared Seeker Journey remains allowed for incomplete paused counterpart',
  public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f304/owner.jpg')
  and (select count(*) = 1 from storage.objects
       where name = '00000000-0000-0000-0000-00000000f304/owner.jpg'));
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000f305', true);
select f03_test.ok('active Guardian link preserves incomplete ward Storage read',
  public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f304/owner.jpg')
  and (select count(*) = 1 from storage.objects
       where name = '00000000-0000-0000-0000-00000000f304/owner.jpg'));
select f03_test.ok('Guardian cannot browse unrelated verified-looking target',
  not public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f302/owner.jpg'));
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000f306', true);
select f03_test.ok('unlinked Guardian cannot read another ward',
  not public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f304/owner.jpg'));
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000f307', true);
select f03_test.ok('incomplete viewer cannot enter discovery through a photo gate',
  not public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f302/owner.jpg'));

reset role;
insert into public.profile_blocks values
 ('00000000-0000-0000-0000-00000000f302', '00000000-0000-0000-0000-00000000f301');
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000f301', true);
select f03_test.ok('reverse-direction block denies discovery photo reads',
  not public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f302/owner.jpg')
  and (select count(*) = 0 from storage.objects
       where name = '00000000-0000-0000-0000-00000000f302/owner.jpg'));
reset role;
delete from public.profile_blocks;
insert into public.profile_blocks values
 ('00000000-0000-0000-0000-00000000f301', '00000000-0000-0000-0000-00000000f304');
set local role authenticated;
select f03_test.ok('standing Journey block still denies counterpart photo',
  not public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f304/owner.jpg'));
reset role;
delete from public.profile_blocks;
update public.matches set end_reason = 'safety_concern'
where id = '00000000-0000-0000-0000-00000000f320';
set local role authenticated;
select f03_test.ok('terminal safety ending still denies Journey photo',
  not public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f304/owner.jpg'));
reset role;
update public.profiles set is_active = false where id = '00000000-0000-0000-0000-00000000f302';
set local role authenticated;
select f03_test.ok('withdrawn target stays out of discovery photo reads',
  not public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f302/owner.jpg'));
reset role;
update public.profiles set is_active = true, onboarding_complete = false
where id = '00000000-0000-0000-0000-00000000f302';
set local role authenticated;
select f03_test.ok('incomplete target stays out of discovery photo reads',
  not public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f302/owner.jpg'));
reset role;
update public.wali_links set status = 'revoked';
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000f305', true);
select f03_test.ok('revoked Guardian link stops photo access',
  not public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f304/owner.jpg'));

-- NULL JWT cannot exploit SECURITY DEFINER or an authenticated table grant.
select set_config('request.jwt.claim.sub', '', true);
select f03_test.ok('authenticated role with no member subject reads nothing',
  not public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f301/owner.jpg')
  and (select count(*) = 0 from storage.objects)
  and (select count(*) = 0 from public.profile_photos));
select f03_test.denied('no-subject member cannot register a row', $sql$
 insert into public.profile_photos (id,user_id,storage_path) values
 ('00000000-0000-0000-0000-00000000f362','00000000-0000-0000-0000-00000000f301',
  '00000000-0000-0000-0000-00000000f301/owner.jpg')
$sql$);
reset role;
set local role service_role;
select f03_test.denied('BYPASSRLS without member subject is not a row-import exemption', $sql$
 insert into public.profile_photos (id,user_id,storage_path) values
 ('00000000-0000-0000-0000-00000000f362','00000000-0000-0000-0000-00000000f301',
  '00000000-0000-0000-0000-00000000f301/owner.jpg')
$sql$);
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000f301', true);
select f03_test.denied('BYPASSRLS with a member subject still rejects cross-owner row', $sql$
 insert into public.profile_photos (id,user_id,storage_path) values
 ('00000000-0000-0000-0000-00000000f362','00000000-0000-0000-0000-00000000f301',
  '00000000-0000-0000-0000-00000000f303/owner.jpg')
$sql$);
reset role;
set local role anon;
select set_config('request.jwt.claim.sub', '', true);
select f03_test.denied('anonymous cannot execute public photo lookup', $sql$
 select public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f301/owner.jpg')
$sql$);
select f03_test.denied('anonymous cannot enumerate profile photo records', $sql$
 select * from public.profile_photos
$sql$);
select f03_test.denied('anonymous cannot enumerate Storage metadata', $sql$
 select * from storage.objects
$sql$);
reset role;

-- Simulated privileged metadata corruption/deletion must fail closed on READ.
-- This does not claim Storage RLS constrains service-key metadata writes.
update storage.objects set owner_id = '00000000-0000-0000-0000-00000000f302'
where id = '00000000-0000-0000-0000-00000000f331';
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000f301', true);
select f03_test.ok('metadata owner changed after row registration cannot sign/read',
  not public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f301/owner.jpg')
  and (select count(*) = 0 from storage.objects
       where name = '00000000-0000-0000-0000-00000000f301/owner.jpg')
  and (select count(*) = 0 from public.profile_photos
       where id = '00000000-0000-0000-0000-00000000f341'));
reset role;
delete from storage.objects where id = '00000000-0000-0000-0000-00000000f332';
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000f302', true);
select f03_test.ok('deleted object leaves a denied orphan row rather than a signing permit',
  not public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f302/owner.jpg')
  and (select count(*) = 0 from public.profile_photos
       where id = '00000000-0000-0000-0000-00000000f342'));
reset role;
rollback;

-- Independent follow-up confirms assertions did not rewrite fixture data.
do $postcondition$
begin
  if (select count(*) from public.profile_photos) <> 8
     or (select count(*) from storage.objects) <> 8
     or (select owner_id from storage.objects
         where id = '00000000-0000-0000-0000-00000000f331')
        <> '00000000-0000-0000-0000-00000000f301'
     or pg_catalog.to_regnamespace('f03_test') is not null then
    raise exception 'F03 FAIL: synthetic assertion transaction did not roll back';
  end if;
  raise notice 'F03 PASS: assertion transaction rolled back without fixture mutation';
end;
$postcondition$;
