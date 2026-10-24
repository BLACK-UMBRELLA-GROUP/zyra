-- Developer Mode test accounts (Fable, 2026-07-19 — Founder request,
-- hybrid approach approved 2026-07-19). Seeds real auth users +
-- profiles + subscriptions + active wali_links, matching the presets
-- in lib/screens/dev/developer_access_screen.dart.
--
-- UPDATED 2026-07-25 (Founder request: male/female Wali presets at
-- both tiers were missing). Added dev.wali.f@zyra.test (Khadija) so
-- both Wali dev presets exist in both genders — previously only a
-- male Wali (Ibrahim) existed, meaning ZyraColors.genderGradient()
-- could never be exercised for a female Wali in Developer Mode.
-- Khadija is linked to Yusuf (ZYRA One) so both Wali test accounts
-- have a linked Seeker covering a different plan tier than the
-- other (Ibrahim <-> Maryam, ZYRA Basic).
--
-- HISTORICAL RECORD: this was applied to the then-live dev project
-- (sxoaxonzjqkgajmlagyk). That production-era application is history, not
-- authority to run this file there again. The seed is retained only as a
-- reproducible, staging-only reset aid and is default-deny until an exact
-- staging project ref is separately approved and pinned below.
--
-- Accounts (their password is caller-supplied at execution time and is never
-- stored in this repository):
--   dev.seeker.basic.m@zyra.test  Adam     seeker  seeker_basic
--   dev.seeker.basic.f@zyra.test  Maryam   seeker  seeker_basic   <- linked to Ibrahim
--   dev.seeker.one.m@zyra.test    Yusuf    seeker  seeker_premium <- linked to Khadija
--   dev.seeker.one.f@zyra.test    Aisha    seeker  seeker_premium
--   dev.wali@zyra.test            Ibrahim  wali    wali_basic
--   dev.wali.f@zyra.test          Khadija  wali    wali_basic
--
-- UPDATED 2026-07-26 (#19): Wali One gating is now real —
-- wali_has_wali_one() (created as wali_has_extended_wali() by
-- 20260726160000_wali_extended_wali_real_gating.sql, renamed by
-- 20260726180000_rename_wali_has_extended_wali_to_wali_one.sql when
-- "Extended Wali" was renamed "Wali One") resolves it from this
-- table, either the Wali's own wali_premium row or a linked Seeker's
-- seeker_premium row. Confirms the seed above already exercises both
-- branches without any extra accounts: Khadija (wali_basic) <-> Yusuf
-- (seeker_premium) resolves Wali One TRUE via free bundling; Ibrahim
-- (wali_basic) <-> Maryam (seeker_basic) resolves FALSE.
-- developer_access_screen.dart's "Wali — One" presets now call
-- mock_set_wali_plan() to force-write a real wali_premium row on
-- entry, rather than a local-only flag.
--
-- NOTE: these are historical dev/preview identities for a database with no
-- real users. This comment records the old clean-up instruction; it does not
-- authorise a production write. Before any real launch, the intended outcome
-- was:
--   delete from auth.users where email like 'dev.%@zyra.test';
--
-- Governed invocation contract (psql example; never put the password in this
-- file or on a command line): start a transaction, use set_config(..., true)
-- to set BOTH `zyra.target_project_ref` and `zyra.dev_seed_password`, include
-- this file in that same transaction, and commit only after review. A local
-- setting made outside an open transaction expires before this file can see
-- it. The password setting is cleared again immediately after validation.

do $$
declare
  v_approved_staging_project_ref constant text := 'UNASSIGNED_STAGING_PROJECT_REF';
  v_production_project_ref constant text := 'sxoaxonzjqkgajmlagyk';
  v_runtime_project_ref text := nullif(
    btrim(current_setting('zyra.target_project_ref', true)),
    ''
  );
  v_pass text;
  rec record;
  v_id uuid;
begin
  if v_approved_staging_project_ref = 'UNASSIGNED_STAGING_PROJECT_REF' then
    raise exception using
      errcode = '22023',
      message = 'Developer seed is disabled: the approved staging project ref is unassigned';
  end if;

  if v_approved_staging_project_ref = v_production_project_ref then
    raise exception using
      errcode = '22023',
      message = 'Developer seed is disabled: the approved pin must never be production';
  end if;

  if v_runtime_project_ref is null then
    raise exception using
      errcode = '22023',
      message = 'Developer seed requires a transaction-local target project ref';
  end if;

  if v_runtime_project_ref = v_production_project_ref then
    raise exception using
      errcode = '22023',
      message = 'Developer seed refuses the production project';
  end if;

  if v_runtime_project_ref <> v_approved_staging_project_ref then
    raise exception using
      errcode = '22023',
      message = 'Developer seed target does not match the separately approved staging pin';
  end if;

  v_pass := nullif(current_setting('zyra.dev_seed_password', true), '');
  if v_pass is null or char_length(v_pass) < 16 then
    raise exception using
      errcode = '22023',
      message = 'Developer seed requires a transaction-local password of at least 16 characters';
  end if;

  -- Keep the working copy only inside this DO block; remove the setting before
  -- any row write so later statements in the session cannot recover it.
  perform set_config('zyra.dev_seed_password', '', true);

  for rec in
    select * from (values
      ('dev.seeker.basic.m@zyra.test', 'seeker', 'Adam',   'male',   date '1997-03-14', 'London',     'seeker_basic'),
      ('dev.seeker.basic.f@zyra.test', 'seeker', 'Maryam', 'female', date '1998-07-22', 'Birmingham', 'seeker_basic'),
      ('dev.seeker.one.m@zyra.test',   'seeker', 'Yusuf',  'male',   date '1994-11-02', 'Manchester', 'seeker_premium'),
      ('dev.seeker.one.f@zyra.test',   'seeker', 'Aisha',  'female', date '1996-05-09', 'Leeds',      'seeker_premium'),
      ('dev.wali@zyra.test',           'wali',   'Ibrahim','male',   date '1968-01-15', 'Birmingham', 'wali_basic'),
      ('dev.wali.f@zyra.test',         'wali',   'Khadija','female', date '1970-04-02', 'Manchester', 'wali_basic')
    ) as t(email, prole, fname, gender, dob, city, plan)
  loop
    select id into v_id from auth.users where email = rec.email;
    if v_id is null then
      v_id := gen_random_uuid();
      insert into auth.users (instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
        confirmation_token, recovery_token, email_change, email_change_token_new, email_change_token_current)
      values ('00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
        rec.email, extensions.crypt(v_pass, extensions.gen_salt('bf')),
        now(), '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(),
        '', '', '', '', '');
      insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
      values (gen_random_uuid(), v_id, v_id::text,
        jsonb_build_object('sub', v_id::text, 'email', rec.email, 'email_verified', true),
        'email', now(), now(), now());
    else
      -- A governed staging rerun rotates every retained seed identity away
      -- from any historical shared credential.
      update auth.users
      set encrypted_password = extensions.crypt(v_pass, extensions.gen_salt('bf')),
          updated_at = now()
      where id = v_id;
    end if;

    insert into public.profiles (id, role, first_name, date_of_birth, gender, location_text, bio, is_active, profile_complete)
    values (v_id, rec.prole, rec.fname, rec.dob, rec.gender, rec.city,
      'Developer Mode test account — not a real person.', true, rec.prole = 'seeker')
    on conflict (id) do update set role = excluded.role, first_name = excluded.first_name,
      date_of_birth = excluded.date_of_birth, gender = excluded.gender,
      location_text = excluded.location_text, is_active = true;

    if not exists (select 1 from public.subscriptions s where s.user_id = v_id) then
      insert into public.subscriptions (user_id, plan_type, status) values (v_id, rec.plan, 'active');
    end if;
  end loop;

  insert into public.wali_links (seeker_id, wali_id, status)
  select s.id, w.id, 'active'
  from auth.users s, auth.users w
  where s.email = 'dev.seeker.basic.f@zyra.test' and w.email = 'dev.wali@zyra.test'
    and not exists (select 1 from public.wali_links wl where wl.seeker_id = s.id and wl.wali_id = w.id);

  insert into public.wali_links (seeker_id, wali_id, status)
  select s.id, w.id, 'active'
  from auth.users s, auth.users w
  where s.email = 'dev.seeker.one.m@zyra.test' and w.email = 'dev.wali.f@zyra.test'
    and not exists (select 1 from public.wali_links wl where wl.seeker_id = s.id and wl.wali_id = w.id);
end $$;
