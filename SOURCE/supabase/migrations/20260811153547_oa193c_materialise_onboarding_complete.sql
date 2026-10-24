-- ⟲ APPLIED-IN-REMOTE RECORD — 2026-08-12 stewardship pass.
--
-- This migration was applied straight to the live database via MCP on
-- 2026-08-11 and existed in no repo file. This record file preserves the
-- version slot and WHAT IT DID; the verbatim statements live in
-- supabase_migrations.schema_migrations version 20260811153547 and can be
-- regenerated with tools/export_missing_migrations.sql (OA-ZYRA-198).
-- House precedent for a record-not-body file: 20260811094513.
--
-- WHAT IT DID:
-- OA-ZYRA-193(c) part 2 — profiles.onboarding_complete column materialised + maintained by 3 triggers (profiles BEFORE; onboarding_answers + seeker_details AFTER) via zyra_onboarding_data_complete(p_user,p_gender) / zyra_refresh_onboarding_complete(); backfill UPDATE
-- OA-ZYRA-198 RECOVERY — 2026-09-10:
-- The record-only placeholder was replaced in place under the Founder's
-- governed history-recovery authority using the one retained production
-- migration-history statement for version 20260811153547.
-- Retained identity: 5,977 characters; 6,657 UTF-8 bytes;
-- SHA-256 0a4149339dfbddc7b18a1bbf9da59ff79ea8f5cf73c6a97607d65f47ad852f5f.
-- The bytes between the BEGIN/END markers are exactly statements[1];
-- neither marker is part of the retained statement.
--
-- BEGIN VERBATIM LIVE STATEMENT 20260811153547
-- ═══════════════════════════════════════════════════════════════════════
-- OA-ZYRA-193(c) — PART 2: MAKING THE GATE CHEAP ENOUGH TO SIT IN RLS
-- ═══════════════════════════════════════════════════════════════════════
--
-- zyra_onboarding_complete() walks the 72-row question bank. That is fine
-- for a report and wrong for a policy: zyra_can_view_profile() is the USING
-- clause of profiles_select, so it runs once per profile row on every read
-- in the app. Seventy-two jsonb key tests per row per read is a cost nobody
-- would find until Browse got slow with no obvious cause.
--
-- So the answer is materialised onto the row and maintained by trigger. The
-- RULE still lives in exactly one place — the triggers call the same
-- function — but the POLICY reads a boolean.

-- ── 1 · THE RULE, SPLIT SO A TRIGGER CAN USE IT ────────────────────────
--
-- Gender is passed in rather than read, so the BEFORE trigger on profiles
-- can evaluate NEW's gender instead of the row's current one. Without that
-- split, changing gender and completeness in one statement would compute the
-- new flag from the old gender.
CREATE OR REPLACE FUNCTION public.zyra_onboarding_data_complete(p_user uuid, p_gender text)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT p_gender IS NOT NULL
    AND EXISTS (SELECT 1 FROM seeker_details sd
                 WHERE sd.user_id = p_user
                   AND sd.preferences IS NOT NULL
                   AND sd.preferences <> '{}'::jsonb)
    AND NOT EXISTS (
      SELECT 1
        FROM zyra_onboarding_questions q
        LEFT JOIN onboarding_answers oa ON oa.user_id = p_user
       WHERE (q.gender_visibility = 'all'
              OR (q.gender_visibility = 'menOnly'   AND p_gender = 'male')
              OR (q.gender_visibility = 'womenOnly' AND p_gender = 'female'))
         AND (q.show_if_qid IS NULL
              OR coalesce(oa.ch3_answers,'{}'::jsonb) -> q.show_if_qid IS NULL
              OR jsonb_typeof(coalesce(oa.ch3_answers,'{}'::jsonb) -> q.show_if_qid) = 'null'
              OR NOT (coalesce(q.show_if_not_any_of,'[]'::jsonb)
                        ? (coalesce(oa.ch3_answers,'{}'::jsonb) ->> q.show_if_qid)))
         AND (NOT (coalesce(oa.ch3_answers,     '{}'::jsonb) ? q.qid)
              OR NOT (coalesce(oa.ch4_preferences,'{}'::jsonb) ? q.qid))
    );
$function$;

-- Restated on top of it, so there is still one thing to ask "is this Seeker
-- done?" in a report or a probe.
CREATE OR REPLACE FUNCTION public.zyra_onboarding_complete(p_user uuid)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM profiles p
     WHERE p.id = p_user AND p.role = 'seeker'
       AND p.profile_complete
       AND zyra_onboarding_data_complete(p.id, p.gender)
  );
$function$;

-- ── 2 · THE COLUMN ─────────────────────────────────────────────────────
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS onboarding_complete boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN profiles.onboarding_complete IS
  'OA-ZYRA-193(c). Maintained by trigger, never written by the app. True when this Seeker has finished onboarding — basic profile, Chapter 2, and every Chapter 3/4 question they were actually shown. Distinct from profile_complete, which means only the name/date-of-birth/photos step.';

-- ── 3 · MAINTENANCE ────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.zyra_refresh_onboarding_complete(p_user uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  UPDATE profiles p
     SET onboarding_complete =
           (p.role = 'seeker' AND p.profile_complete
            AND zyra_onboarding_data_complete(p.id, p.gender))
   WHERE p.id = p_user
     -- Only when it actually changes: this fires from AFTER triggers on
     -- other tables, and an unconditional UPDATE would re-enter the BEFORE
     -- trigger on profiles on every answer saved during onboarding.
     AND p.onboarding_complete IS DISTINCT FROM
           (p.role = 'seeker' AND p.profile_complete
            AND zyra_onboarding_data_complete(p.id, p.gender));
END;
$function$;

CREATE OR REPLACE FUNCTION public.zyra_profiles_set_onboarding_complete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- BEFORE, and computed from NEW: no second write, so no recursion.
  NEW.onboarding_complete :=
    (NEW.role = 'seeker' AND NEW.profile_complete
     AND zyra_onboarding_data_complete(NEW.id, NEW.gender));
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.zyra_answers_refresh_onboarding_complete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  PERFORM zyra_refresh_onboarding_complete(
    CASE WHEN TG_OP = 'DELETE' THEN OLD.user_id ELSE NEW.user_id END);
  RETURN NULL;
END;
$function$;

DROP TRIGGER IF EXISTS profiles_set_onboarding_complete ON profiles;
CREATE TRIGGER profiles_set_onboarding_complete
  BEFORE INSERT OR UPDATE OF profile_complete, gender, role ON profiles
  FOR EACH ROW EXECUTE FUNCTION zyra_profiles_set_onboarding_complete();

DROP TRIGGER IF EXISTS onboarding_answers_refresh_complete ON onboarding_answers;
CREATE TRIGGER onboarding_answers_refresh_complete
  AFTER INSERT OR UPDATE OR DELETE ON onboarding_answers
  FOR EACH ROW EXECUTE FUNCTION zyra_answers_refresh_onboarding_complete();

DROP TRIGGER IF EXISTS seeker_details_refresh_complete ON seeker_details;
CREATE TRIGGER seeker_details_refresh_complete
  AFTER INSERT OR UPDATE OR DELETE ON seeker_details
  FOR EACH ROW EXECUTE FUNCTION zyra_answers_refresh_onboarding_complete();

-- ── 4 · BACKFILL ───────────────────────────────────────────────────────
UPDATE profiles p
   SET onboarding_complete =
         (p.role = 'seeker' AND p.profile_complete
          AND zyra_onboarding_data_complete(p.id, p.gender));
-- END VERBATIM LIVE STATEMENT 20260811153547
