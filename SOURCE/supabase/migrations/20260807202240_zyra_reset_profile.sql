-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260807202240, applied name
-- 'zyra_reset_profile') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Reset profile — start fresh without deleting the account.
-- Founder decision 2026-08-07. Scope: "answers + discovery history".
--
-- WHAT IT IS FOR. Someone whose search is not working wants to be seen
-- anew. Clearing only their answers would not achieve that: everyone who
-- already passed on them has passed, and a pass is permanent, so they
-- would rewrite everything and remain invisible to exactly the people they
-- were trying to reach. That is why other people's decisions ABOUT them
-- are cleared too, and it is the deliberate, approved core of this feature.
--
-- ── CLEARED
--   onboarding_answers   their answers
--   seeker_details       lifestyle, sect, nationality, preferences
--   profile_photos       rows here; STORAGE OBJECTS ARE RETURNED, not
--                        deleted — a function cannot reach the bucket. The
--                        caller must remove them, exactly as
--                        ZyraAuth.deleteAccount already does.
--   profiles.bio, location_text
--   likes / saves / passes   BOTH DIRECTIONS
--
-- ── KEPT, each for a stated reason
--   identity             frozen. first_published_at is untouched, so a
--                        reset does NOT reopen gender or date of birth.
--                        This is Principle 4 holding under a new feature:
--                        starting fresh is not a route to becoming someone
--                        else.
--   wali_links           Guardians linked to the PERSON, not the profile.
--   unlock_credits       paid. Erasing a purchased balance because someone
--                        redid their answers would be theft.
--   subscriptions        same.
--   matches              JOINT data (see zyra_data_ownership). A match is
--                        equally the other person's record, and deleting it
--                        unilaterally would erase their history. Kept
--                        deliberately — not an oversight.
--   consents, article9   consent EVIDENCE. Append-only, never deleted.
--   profile_reports      SAFETY RECORD. Deleting these would make "reset my
--                        profile" a way to erase reports made against you,
--                        which is the single most dangerous thing this
--                        feature could accidentally become.
--
-- ── DELETING OTHER PEOPLE'S ROWS, deliberately. `likes WHERE liked_id =
-- me`, and the same for saves and passes, remove rows another user wrote.
-- That is the point of the feature and it is irreversible. It does not
-- disclose anything — the person doing it never sees who those rows
-- belonged to; the function returns counts, never identities.
--
-- Note that a kept `matches` row may now have no surviving likes behind it.
-- That is fine: create_match_on_mutual_like fires on INSERT only, so
-- nothing re-evaluates, and the match is a fact in its own right.
--
-- ── AN ACTIVE JOURNEY BLOCKS IT. Founder decision. Another family is in
-- that conversation, and they should not lose a Journey because someone
-- pressed a button in Settings. Ending a Journey already has its own
-- considered flow with a reason and a note; this refuses and points there.
-- Potential Journeys do not block — nothing has started.

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
  -- A Guardian has no answers, no photos and no Browse presence, so there
  -- is nothing here for them to reset. Refused by name rather than quietly
  -- doing nothing and reporting success.
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

  -- Collected BEFORE the delete, and returned so the caller can clear the
  -- bucket. Orphaned objects would otherwise sit in storage for the life
  -- of the project, still fetchable by anyone holding an old signed URL.
  SELECT coalesce(array_agg(storage_path), '{}')
    INTO v_paths
    FROM public.profile_photos WHERE user_id = v_me;

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

  -- profile_complete = false returns them to onboarding. is_active is NOT
  -- touched: whether they want to be visible is a separate choice they
  -- already made, and this is not the place to silently change it.
  UPDATE public.profiles
     SET bio           = NULL,
         location_text = NULL,
         profile_complete = false
   WHERE id = v_me;

  RETURN jsonb_build_object(
    'status','reset',
    'photos',  v_photos,
    'likes',   v_likes,
    'saves',   v_saves,
    'passes',  v_passes,
    'storage_paths', to_jsonb(v_paths)
  );
END;
$function$;

comment on function public.zyra_reset_profile() is
  'Clears a Seeker''s answers, details, photos and ALL discovery history in '
  'both directions, returning them to onboarding. Keeps identity (frozen), '
  'Guardians, credits, subscription, matches, consent evidence and reports. '
  'Refuses while an Active Journey exists. Returns storage paths for the '
  'caller to remove from the bucket.';

-- New function: it has no grants until given some. anon deliberately
-- omitted — there is no signed-out use for this.
grant execute on function public.zyra_reset_profile() to authenticated;
