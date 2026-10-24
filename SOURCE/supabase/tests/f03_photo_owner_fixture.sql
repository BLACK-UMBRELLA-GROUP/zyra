-- F03 synthetic-only catalog fixture. NEVER run against a linked/live project.
-- Root supplies a fresh database named zyra_f03_synthetic_<suffix> and
-- PGOPTIONS='-c zyra.synthetic_fixture=f03_owner_binding'. No service start,
-- real member identity, real object, file, signing request or seed repair here.
-- Order: this fixture -> candidate migration -> f03_photo_owner_assertions.sql.
\set ON_ERROR_STOP on

do $guard$
begin
  if pg_catalog.current_database() not like 'zyra\_f03\_synthetic\_%' escape '\'
     or pg_catalog.current_setting('zyra.synthetic_fixture', true)
        is distinct from 'f03_owner_binding' then
    raise exception 'F03 fixture refused: synthetic database prefix/GUC required';
  end if;
  if pg_catalog.to_regclass('public.profiles') is not null
     or pg_catalog.to_regclass('public.profile_photos') is not null
     or pg_catalog.to_regclass('storage.objects') is not null
     or pg_catalog.to_regclass('storage.buckets') is not null
     or pg_catalog.to_regprocedure('auth.uid()') is not null
     or pg_catalog.to_regprocedure('public.zyra_can_view_profile(uuid)') is not null
     or pg_catalog.to_regprocedure('public.zyra_can_read_photo_object(text)') is not null then
    raise exception 'F03 fixture refused: existing target catalog';
  end if;
  if current_user <> 'postgres' then
    raise exception 'F03 fixture requires isolated postgres owner';
  end if;
end;
$guard$;

begin;
do $roles$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin bypassrls;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'supabase_storage_admin') then
    create role supabase_storage_admin nologin bypassrls;
  end if;
  if exists (select 1 from pg_roles
             where rolname in ('anon', 'authenticated')
               and (rolsuper or rolbypassrls)) then
    raise exception 'F03 fixture refuses privileged member roles';
  end if;
end;
$roles$;
create schema auth;
create schema storage;
create schema private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema public, auth, storage to anon, authenticated;
grant usage on schema public, auth, storage to service_role, supabase_storage_admin;
create function auth.uid() returns uuid language sql stable as $function$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$function$;
create function storage.foldername(name text) returns text[]
language sql immutable as $function$
  select (string_to_array(name, '/'))[1:array_length(string_to_array(name, '/'), 1) - 1];
$function$;

create table public.profiles (
  id uuid primary key,
  role text not null,
  gender text,
  is_active boolean not null,
  profile_complete boolean not null,
  onboarding_complete boolean not null
);
create table public.wali_links (seeker_id uuid, wali_id uuid, status text);
create table public.matches (
  id uuid primary key, seeker_a_id uuid, seeker_b_id uuid, end_reason text
);
create table public.zyra_attempt_participant_rows (
  attempt_id uuid, match_id uuid, user_id uuid, role text
);
create table public.profile_blocks (blocker_id uuid, blocked_id uuid);
create function public.zyra_block_exists(p_target uuid) returns boolean
language sql stable security definer set search_path = '' as $function$
  select exists (select 1 from public.profile_blocks b
    where (b.blocker_id = (select auth.uid()) and b.blocked_id = p_target)
       or (b.blocked_id = (select auth.uid()) and b.blocker_id = p_target));
$function$;

-- Verbatim October 3 catalog definition; candidate checks its MD5 unchanged.
CREATE OR REPLACE FUNCTION public.zyra_can_view_profile(p_target uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select
    p_target = (select auth.uid())

    -- CLAUSE 2 — your own ward, or your own Guardian. UNCHANGED.
    -- This is the entire legitimate basis of Guardian visibility.
    or exists (
      select 1 from public.wali_links w
      where w.status = 'active'
        and (   (w.seeker_id = p_target and w.wali_id   = (select auth.uid()))
             or (w.wali_id   = p_target and w.seeker_id = (select auth.uid())) )
    )

    -- CLAUSE 3 — the two Seekers of a shared attempt. SEEKERS ONLY.
    --   2026-08-08 (item 1): Guardians removed entirely. Previously any
    --     participant could see any participant, which handed every
    --     Guardian a gender-blind view of the other family.
    --   The old status guard (Step 1) is gone with them — it existed to
    --     stop families meeting at 'potential', and Seeker<->Seeker was
    --     always exempt from it anyway, because clause 4 requires
    --     is_active and this clause is the only thing keeping a PAUSED
    --     counterpart visible in Potential Journeys.
    --   Block guards (Step 1b) retained verbatim, both halves.
    --   2026-08-11: NOT gated on onboarding completeness, on purpose —
    --     see the header. A live Journey outranks a tidy pool.
    or exists (
      select 1
      from public.zyra_attempt_participant_rows me
      join public.zyra_attempt_participant_rows them
        on them.attempt_id = me.attempt_id
      join public.matches mm on mm.id = me.match_id
      where me.user_id   = (select auth.uid())
        and them.user_id = p_target
        and me.role   = 'seeker'
        and them.role = 'seeker'
        -- (b) durable: a safety ending is terminal, block row or not
        and mm.end_reason is distinct from 'safety_concern'
        -- (a) live: a standing block, for pairs with nothing to end
        and not exists (
          select 1 from public.profile_blocks b
          where (b.blocker_id = mm.seeker_a_id and b.blocked_id = mm.seeker_b_id)
             or (b.blocker_id = mm.seeker_b_id and b.blocked_id = mm.seeker_a_id)
        )
    )

    -- CLAUSE 4 — browsing.
    --
    -- 2026-08-11, OA-ZYRA-193(c): both parties must have finished
    -- onboarding. Reads the materialised profiles.onboarding_complete
    -- rather than recomputing — this function is the USING clause of
    -- profiles_select and runs per row on every profile read in the app.
    or exists (
      select 1
      from public.profiles p
      cross join lateral (
        select pv.role, pv.gender, pv.onboarding_complete
          from public.profiles pv where pv.id = (select auth.uid())
      ) viewer
      where p.id = p_target
        and p.is_active = true
        and p.profile_complete = true
        and p.onboarding_complete = true          -- they finished
        and viewer.onboarding_complete = true     -- and so did you
        and not public.zyra_block_exists(p_target)
        and viewer.role = 'seeker'
        and viewer.gender is not null
        and p.gender is not null
        and p.gender <> viewer.gender
    );
$function$;
revoke all on function public.zyra_can_view_profile(uuid) from public, anon;
grant execute on function public.zyra_can_view_profile(uuid) to authenticated;
alter table public.profiles enable row level security;
create policy profiles_select on public.profiles for select to authenticated
using (public.zyra_can_view_profile(id));

create table storage.buckets (id text primary key, public boolean not null);
create table storage.objects (
  id uuid primary key,
  bucket_id text references storage.buckets(id),
  name text,
  owner_id text,
  unique (bucket_id, name)
);
create table public.profile_photos (
  id uuid primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  storage_path text not null,
  is_primary boolean not null default false,
  display_order integer not null default 0,
  created_at timestamptz not null default now()
);
create index photo_storage_path_idx on public.profile_photos(storage_path);
alter table public.profile_photos enable row level security;
alter table storage.objects enable row level security;
grant select on public.profiles to authenticated;
grant select, insert, update, delete on public.profile_photos, storage.objects
to authenticated;
grant select on storage.buckets to authenticated;
grant all on public.profile_photos, storage.objects, storage.buckets
to service_role, supabase_storage_admin;

-- Verbatim October 3 photo gate; intentionally vulnerable synthetic baseline.
CREATE OR REPLACE FUNCTION public.zyra_can_read_photo_object(p_object_name text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1
    from public.profile_photos pp
    where pp.storage_path = p_object_name
      and public.zyra_can_view_profile(pp.user_id)
  );
$function$;
revoke all on function public.zyra_can_read_photo_object(text) from public, anon;
grant execute on function public.zyra_can_read_photo_object(text)
to authenticated, service_role, supabase_storage_admin;
create policy profile_photos_delete on public.profile_photos for delete
using (user_id = (select auth.uid()));
create policy profile_photos_insert on public.profile_photos for insert
with check (user_id = (select auth.uid()));
create policy profile_photos_update on public.profile_photos for update
using (user_id = (select auth.uid()));
create policy profile_photos_select on public.profile_photos for select
using (user_id = (select auth.uid()) or exists (
  select 1 from public.profiles p
  where p.id = profile_photos.user_id and p.is_active and p.profile_complete
));
create policy profile_photos_storage_delete on storage.objects for delete
using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy profile_photos_storage_insert on storage.objects for insert
with check (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy profile_photos_storage_update on storage.objects for update
using (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);
create policy profile_photos_storage_read on storage.objects for select
using (bucket_id = 'profile-photos' and (
  (storage.foldername(name))[1] = (select auth.uid())::text
  or public.zyra_can_read_photo_object(name)
));

insert into storage.buckets values ('profile-photos', false), ('unrelated', false);
insert into public.profiles values
 ('00000000-0000-0000-0000-00000000f301', 'seeker', 'male', true, true, true),
 ('00000000-0000-0000-0000-00000000f302', 'seeker', 'female', true, true, true),
 ('00000000-0000-0000-0000-00000000f303', 'seeker', 'male', true, true, true),
 ('00000000-0000-0000-0000-00000000f304', 'seeker', 'female', false, false, false),
 ('00000000-0000-0000-0000-00000000f305', 'guardian', 'female', true, true, true),
 ('00000000-0000-0000-0000-00000000f306', 'guardian', 'female', true, true, true),
 ('00000000-0000-0000-0000-00000000f307', 'seeker', 'male', true, false, false),
 ('00000000-0000-0000-0000-00000000f308', 'seeker', 'male', true, true, true);
insert into public.wali_links values
 ('00000000-0000-0000-0000-00000000f304', '00000000-0000-0000-0000-00000000f305', 'active');
insert into public.matches values
 ('00000000-0000-0000-0000-00000000f320', '00000000-0000-0000-0000-00000000f301', '00000000-0000-0000-0000-00000000f304', null);
insert into public.zyra_attempt_participant_rows values
 ('00000000-0000-0000-0000-00000000f321', '00000000-0000-0000-0000-00000000f320', '00000000-0000-0000-0000-00000000f301', 'seeker'),
 ('00000000-0000-0000-0000-00000000f321', '00000000-0000-0000-0000-00000000f320', '00000000-0000-0000-0000-00000000f304', 'seeker');
insert into storage.objects values
 ('00000000-0000-0000-0000-00000000f331', 'profile-photos', '00000000-0000-0000-0000-00000000f301/owner.jpg', '00000000-0000-0000-0000-00000000f301'),
 ('00000000-0000-0000-0000-00000000f332', 'profile-photos', '00000000-0000-0000-0000-00000000f302/owner.jpg', '00000000-0000-0000-0000-00000000f302'),
 ('00000000-0000-0000-0000-00000000f333', 'profile-photos', '00000000-0000-0000-0000-00000000f303/owner.jpg', '00000000-0000-0000-0000-00000000f303'),
 ('00000000-0000-0000-0000-00000000f334', 'profile-photos', '00000000-0000-0000-0000-00000000f304/owner.jpg', '00000000-0000-0000-0000-00000000f304'),
 ('00000000-0000-0000-0000-00000000f335', 'profile-photos', '00000000-0000-0000-0000-00000000f301/orphan.jpg', '00000000-0000-0000-0000-00000000f301'),
 ('00000000-0000-0000-0000-00000000f336', 'profile-photos', '00000000-0000-0000-0000-00000000f302/null-owner.jpg', null),
 ('00000000-0000-0000-0000-00000000f337', 'profile-photos', '00000000-0000-0000-0000-00000000f301/wrong-owner.jpg', '00000000-0000-0000-0000-00000000f302'),
 ('00000000-0000-0000-0000-00000000f338', 'profile-photos', '00000000-0000-0000-0000-00000000f308/shared.jpg', '00000000-0000-0000-0000-00000000f308');
insert into public.profile_photos (id, user_id, storage_path, is_primary) values
 ('00000000-0000-0000-0000-00000000f341', '00000000-0000-0000-0000-00000000f301', '00000000-0000-0000-0000-00000000f301/owner.jpg', true),
 ('00000000-0000-0000-0000-00000000f342', '00000000-0000-0000-0000-00000000f302', '00000000-0000-0000-0000-00000000f302/owner.jpg', true),
 ('00000000-0000-0000-0000-00000000f343', '00000000-0000-0000-0000-00000000f303', '00000000-0000-0000-0000-00000000f303/owner.jpg', true),
 ('00000000-0000-0000-0000-00000000f344', '00000000-0000-0000-0000-00000000f304', '00000000-0000-0000-0000-00000000f304/owner.jpg', true),
 -- Synthetic legacy attack: own row points at same-gender stranger's object.
 ('00000000-0000-0000-0000-00000000f345', '00000000-0000-0000-0000-00000000f301', '00000000-0000-0000-0000-00000000f303/owner.jpg', false),
 ('00000000-0000-0000-0000-00000000f346', '00000000-0000-0000-0000-00000000f302', '00000000-0000-0000-0000-00000000f302/null-owner.jpg', false),
 ('00000000-0000-0000-0000-00000000f347', '00000000-0000-0000-0000-00000000f301', '00000000-0000-0000-0000-00000000f301/wrong-owner.jpg', false),
 -- Synthetic legacy shared seed; intentionally no owner/seed exemption.
 ('00000000-0000-0000-0000-00000000f348', '00000000-0000-0000-0000-00000000f301', '00000000-0000-0000-0000-00000000f308/shared.jpg', false);

do $baseline$
begin
  if md5(pg_get_functiondef('public.zyra_can_view_profile(uuid)'::regprocedure))
        <> '10bebeecc1fb937cc257816711baf99b'
     or md5(pg_get_functiondef('public.zyra_can_read_photo_object(text)'::regprocedure))
        <> 'b9fefed6b1c4e2b92bea4bb4d879b493' then
    raise exception 'F03 fixture failed to reproduce October 3 gate hashes';
  end if;
end;
$baseline$;
commit;

-- Demonstrate the known defect solely with synthetic records before repair.
set role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-00000000f301', false);
do $baseline_exploit$
begin
  if public.zyra_can_view_profile('00000000-0000-0000-0000-00000000f303') is not false
     or public.zyra_can_read_photo_object('00000000-0000-0000-0000-00000000f303/owner.jpg') is not true then
    raise exception 'F03 fixture did not reproduce synthetic cross-owner/self-row defect';
  end if;
end;
$baseline_exploit$;
reset role;
select set_config('request.jwt.claim.sub', '', false);
