-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260804105522, applied name
-- 'c3_profile_rpcs_and_column_lockdown') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- C-3 — privilege escalation. July audit finding C4, still open until now.
--
-- VERIFIED BEFORE THE FIX: has_column_privilege('authenticated','profiles',
-- 'role','UPDATE') = true, likewise date_of_birth, gender, profile_complete
-- and is_active. And the role CHECK explicitly permits 'admin':
--
--   CHECK (role = ANY (ARRAY['seeker','wali','admin']))
--
-- So self-promotion was not a theoretical state the schema tolerated — it
-- was a value the schema names. A user could also falsify their age,
-- switch gender (defeating segregation), and self-publish past any
-- moderation.
--
-- ORDER MATTERS, as both reviews said: the RPCs must exist before the
-- revoke, or onboarding breaks the moment permissions drop. Both happen in
-- this one migration so there is no window where either is true alone.
--
-- WHAT A USER MAY STILL WRITE DIRECTLY, and why:
--   first_name, surname_line, bio, location_text   theirs to edit
--   is_active                                      their own hide/show toggle
--
-- WHAT MOVES BEHIND AN RPC:
--   role, gender, date_of_birth   identity. Fixed at onboarding.
--   profile_complete              a publication gate, not a user setting.
--
-- THE ONBOARDING NUANCE: gender and date of birth must stay editable while
-- someone is still onboarding — Chapter 1 can be re-entered, and Developer
-- Access's "Test Sign Up" does exactly that. They lock on publication
-- (profile_complete = true), which is the honest boundary: correct your
-- details freely until other people can see them.

create or replace function public.zyra_create_profile(
  p_role       text,
  p_first_name text,
  p_gender     text,
  p_dob        date
)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
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

  SELECT role, profile_complete INTO v_existing FROM public.profiles WHERE id = v_me;

  IF v_existing IS NULL THEN
    INSERT INTO public.profiles (id, role, first_name, gender, date_of_birth)
    VALUES (v_me, p_role, btrim(p_first_name), p_gender, p_dob);
    RETURN jsonb_build_object('status','created');
  END IF;

  -- Already published: identity is frozen. Name stays editable through the
  -- ordinary column grant, so this is not a dead end for someone fixing a
  -- typo — only for someone changing who they are.
  IF v_existing.profile_complete THEN
    UPDATE public.profiles SET first_name = btrim(p_first_name) WHERE id = v_me;
    RETURN jsonb_build_object('status','name_only','reason','profile_published');
  END IF;

  -- Still onboarding: everything is correctable, but role never flips.
  UPDATE public.profiles
     SET first_name    = btrim(p_first_name),
         gender        = p_gender,
         date_of_birth = p_dob
   WHERE id = v_me;
  RETURN jsonb_build_object('status','updated');
END;
$$;

-- Publication gate. Server decides whether a profile is presentable,
-- rather than trusting the client that walked the flow.
create or replace function public.zyra_set_profile_complete(p_complete boolean default true)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
DECLARE
  v_me uuid := auth.uid();
  v_p  record;
  v_photos int;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  -- Un-publishing is always allowed: nobody should need permission to
  -- withdraw themselves.
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

  UPDATE public.profiles SET profile_complete = true WHERE id = v_me;
  RETURN jsonb_build_object('status','published');
END;
$$;

-- =====================================================================
-- THE LOCKDOWN
-- =====================================================================
-- Creation is RPC-only now, so no direct INSERT at all.
revoke insert on public.profiles from authenticated, anon;
revoke delete on public.profiles from authenticated, anon;

-- Replace the blanket UPDATE with a column list. Anything absent here can
-- now only be written by the two functions above.
revoke update on public.profiles from authenticated, anon;
grant  update (first_name, surname_line, bio, location_text, is_active)
  on public.profiles to authenticated;

-- The INSERT policy is unreachable without the INSERT grant; dropped so it
-- does not read as an active permission during the next review.
drop policy if exists profiles_insert on public.profiles;

revoke all on function public.zyra_create_profile(text,text,text,date) from public, anon;
revoke all on function public.zyra_set_profile_complete(boolean)       from public, anon;
grant execute on function public.zyra_create_profile(text,text,text,date) to authenticated;
grant execute on function public.zyra_set_profile_complete(boolean)      to authenticated;
