-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260807202404, applied name
-- 'zyra_reset_profile_own_storage_paths_only') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Only ever hand back storage paths that belong to the caller.
--
-- FOUND WHILE TESTING THE FUNCTION ABOVE. zyra_reset_profile() returned
-- four paths under TWO different user UUIDs. Checked across the table:
-- 498 of 597 profile_photos rows have a storage_path whose UUID prefix is
-- a different user's.
--
-- That is seeded test data — the seeder dealt photos out of a shared pool,
-- and zyra_photo_service.dart uploads real photos to '<user_id>/...', so
-- production paths will match. But the consequence is not confined to
-- test data: the caller is told to delete these objects from the bucket,
-- so on this database a reset would delete OTHER profiles' photo files.
--
-- Storage RLS would very likely refuse the removal anyway. "Very likely"
-- is not a guarantee and it is not where this belongs: a function should
-- never hand a caller a path to someone else's object in the first place.
-- Filtering here makes it impossible rather than merely unlikely.
--
-- In production this filter is a no-op. That is the point — it costs
-- nothing and removes a whole class of outcome.
--
-- NOTE FOR THE SAME PROBLEM ELSEWHERE: ZyraAuth.deleteAccount() reads
-- profile_photos.storage_path directly and removes those objects with no
-- such filter. On this seeded database it has the same hazard. Not changed
-- here — it is a different function with its own review, and quietly
-- editing it from inside this migration is exactly the habit that hides
-- changes.

create or replace function public.zyra_reset_profile()
 returns jsonb
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
DECLARE
  v_me      uuid := auth.uid();
  v_role    text;
  v_active  int;
  v_paths   text[];
  v_photos  int;
  v_likes   int;
  v_saves   int;
  v_passes  int;
BEGIN
  IF v_me IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  SELECT role INTO v_role FROM public.profiles WHERE id = v_me;
  IF v_role IS NULL THEN
    RAISE EXCEPTION 'no_profile';
  END IF;
  IF v_role <> 'seeker' THEN
    RETURN jsonb_build_object('status','refused','reason','not_a_seeker');
  END IF;

  SELECT count(*) INTO v_active
    FROM public.matches
   WHERE status = 'active'
     AND (seeker_a_id = v_me OR seeker_b_id = v_me);

  IF v_active > 0 THEN
    RETURN jsonb_build_object(
      'status','blocked', 'reason','active_journey', 'active', v_active);
  END IF;

  -- OWN PREFIX ONLY — see the header. The row is still deleted either way;
  -- it is only the bucket instruction that is withheld.
  SELECT coalesce(array_agg(storage_path), '{}')
    INTO v_paths
    FROM public.profile_photos
   WHERE user_id = v_me
     AND storage_path LIKE v_me::text || '/%';

  DELETE FROM public.profile_photos WHERE user_id = v_me;
  GET DIAGNOSTICS v_photos = ROW_COUNT;

  DELETE FROM public.onboarding_answers WHERE user_id = v_me;
  DELETE FROM public.seeker_details     WHERE user_id = v_me;

  DELETE FROM public.likes  WHERE liker_id  = v_me OR liked_id  = v_me;
  GET DIAGNOSTICS v_likes = ROW_COUNT;
  DELETE FROM public.saves  WHERE saver_id  = v_me OR saved_id  = v_me;
  GET DIAGNOSTICS v_saves = ROW_COUNT;
  DELETE FROM public.passes WHERE passer_id = v_me OR passed_id = v_me;
  GET DIAGNOSTICS v_passes = ROW_COUNT;

  UPDATE public.profiles
     SET bio              = NULL,
         location_text    = NULL,
         profile_complete = false
   WHERE id = v_me;

  RETURN jsonb_build_object(
    'status','reset',
    'photos',  v_photos,
    'likes',   v_likes,
    'saves',   v_saves,
    'passes',  v_passes,
    -- May be SHORTER than 'photos' when rows exist whose object lives
    -- under someone else's prefix. Deliberate: the row goes, the foreign
    -- object is left alone.
    'storage_paths', to_jsonb(v_paths)
  );
END;
$function$;

grant execute on function public.zyra_reset_profile() to authenticated;
