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
-- ALREADY APPLIED to the live dev project (sxoaxonzjqkgajmlagyk).
-- Kept here so the seed is reproducible after a db reset.
-- Idempotent — safe to re-run.
--
-- Accounts (password for all: ZyraTest!2026):
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
-- NOTE: these are dev/preview credentials for a database with no real
-- users. Delete all dev.*@zyra.test accounts before any real launch:
--   delete from auth.users where email like 'dev.%@zyra.test';

do $$
declare
  v_pass text := 'ZyraTest!2026';
  rec record;
  v_id uuid;
begin
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
