-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260807183341, applied name
-- 'freeze_identity_on_first_publication') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- IDENTITY FREEZE — make it a rule rather than a policy.
-- Founder decision 2026-08-07.
--
-- BEFORE. zyra_create_profile() froze gender and date_of_birth while
-- profiles.profile_complete was true. zyra_set_profile_complete(false)
-- un-publishes unconditionally, and deliberately so — its own comment
-- says "nobody should need permission to withdraw themselves", which is
-- right. Neither function was wrong. Neither knew the other existed.
-- Together they allowed:
--
--   zyra_set_profile_complete(false)
--     -> zyra_create_profile(..., new gender, new dob)   "still onboarding"
--       -> zyra_set_profile_complete(true)
--
-- so the freeze could be stepped around by anyone who found the route.
--
-- AFTER. The freeze keys on first_published_at, which is written once and
-- never cleared — including on un-publish. Withdrawing yourself stays
-- unconditional; it simply no longer thaws your identity.
--
-- THIS IS NOT A SECURITY FIX. Nothing here crossed a user boundary: the
-- route was only ever available to a person acting on their own row, and
-- every value written still had to satisfy the CHECK constraints. It is a
-- correctness change, because the code previously asserted both that
-- identity was frozen and that it was not.
--
-- BEHAVIOUR PRESERVED: un-publishing, name editing, the 18+ check, the
-- role refusal, and the client contract (which reads only `status`).

-- ── 1. The marker ──────────────────────────────────────────────────────
alter table public.profiles
  add column if not exists first_published_at timestamptz;

comment on column public.profiles.first_published_at is
  'OWNERSHIP: row-scoped(id). Set the first time a profile is published and '
  'NEVER cleared, including on un-publish. Gender and date_of_birth are frozen '
  'once this is non-null — that is the whole reason the column exists, and it '
  'is why profile_complete could not be used: profile_complete is reversible. '
  'BACKFILL WARNING: rows that existed before 2026-08-07 were backfilled from '
  'created_at, which is a lower bound and not the real publication moment. '
  'Safe to test for NULL. NOT safe to show a user as a date.';

-- Backfill with the updated_at trigger disabled. Without this, marking
-- 149 rows would rewrite updated_at on every one of them and destroy the
-- only "when did this person last change something" signal we have.
alter table public.profiles disable trigger profiles_updated_at;

update public.profiles
   set first_published_at = created_at
 where profile_complete = true
   and first_published_at is null;

alter table public.profiles enable trigger profiles_updated_at;

-- SELECT so the client can tell whether identity is editable and stop
-- offering fields it cannot write. Deliberately NO update grant: this
-- column is written by zyra_set_profile_complete and nothing else.
grant select (first_published_at) on public.profiles to authenticated;

-- ── 2. Publication stamps the marker ───────────────────────────────────
-- CREATE OR REPLACE, same signature: existing grants are preserved.
create or replace function public.zyra_set_profile_complete(p_complete boolean default true)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
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
    SELECT count(*) INTO v_photos FROM public.profile_photos WHERE user_id = v_me;
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

-- ── 3. The freeze reads the marker, not the reversible flag ────────────
create or replace function public.zyra_create_profile(p_role text, p_first_name text, p_gender text, p_dob date)
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  v_me       uuid := auth.uid();
  v_existing record;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  -- 'admin' is deliberately unreachable here even though the column CHECK
  -- permits it. If an admin role is ever needed it will be granted by an
  -- operator, never claimed by a client.
  IF p_role NOT IN ('seeker','wali') THEN
    RAISE EXCEPTION 'invalid_role' USING HINT = 'seeker or wali';
  END IF;
  IF p_gender NOT IN ('male','female') THEN
    RAISE EXCEPTION 'invalid_gender';
  END IF;
  IF p_first_name IS NULL OR btrim(p_first_name) = '' THEN
    RAISE EXCEPTION 'first_name_required';
  END IF;
  IF char_length(p_first_name) > 60 THEN
    RAISE EXCEPTION 'first_name_too_long';
  END IF;
  -- Checked here as well as by the constraint, so the client gets a named
  -- error rather than a raw constraint violation.
  IF p_dob IS NULL OR p_dob > (current_date - interval '18 years') THEN
    RAISE EXCEPTION 'must_be_18';
  END IF;

  SELECT role, profile_complete, first_published_at
    INTO v_existing
    FROM public.profiles WHERE id = v_me;

  IF v_existing IS NULL THEN
    INSERT INTO public.profiles (id, role, first_name, gender, date_of_birth)
    VALUES (v_me, p_role, btrim(p_first_name), p_gender, p_dob);
    RETURN jsonb_build_object('status','created');
  END IF;

  -- EVER published: identity is frozen, permanently. Was
  -- `v_existing.profile_complete`, which meant "published RIGHT NOW" and
  -- so could be turned off first. Name stays editable through the ordinary
  -- column grant, so this is not a dead end for someone fixing a typo —
  -- only for someone changing who they are.
  --
  -- A genuine correction (a mistyped birth year) has no self-service route
  -- by design and is a support case. Founder 2026-08-07.
  IF v_existing.first_published_at IS NOT NULL THEN
    UPDATE public.profiles SET first_name = btrim(p_first_name) WHERE id = v_me;
    RETURN jsonb_build_object('status','name_only','reason','identity_frozen');
  END IF;

  -- Never published: everything is still correctable, but role never flips.
  UPDATE public.profiles
     SET first_name    = btrim(p_first_name),
         gender        = p_gender,
         date_of_birth = p_dob
   WHERE id = v_me;
  RETURN jsonb_build_object('status','updated');
END;
$function$;
