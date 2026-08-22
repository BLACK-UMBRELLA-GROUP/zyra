-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260801144230, applied name
-- 'fix_dob_column_revoke_actually_works') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- C2 (Critical, engineering audit 2026-07-26) — the date_of_birth
-- REVOKE has never worked.
--
-- 20260726120000_hide_raw_dob_expose_age.sql ran:
--     REVOKE SELECT (date_of_birth) ON public.profiles FROM authenticated, anon;
-- and reported success. It did nothing.
--
-- In PostgreSQL a column-level REVOKE cannot subtract from a TABLE-level
-- GRANT. Supabase grants `authenticated` and `anon` table-wide privileges
-- on public tables by default, and that table-level SELECT continues to
-- confer access to every column regardless of any column-level revoke.
-- Verified live on 2026-08-01:
--     has_column_privilege('authenticated','public.profiles','date_of_birth','SELECT') -> true
--
-- So for the last week every signed-in user has been able to read every
-- other user's exact date of birth with a plain
-- `select=date_of_birth` on /rest/v1/profiles. All the client-side work
-- that accompanied that migration (ages_for(), removing date_of_birth
-- from every .select() in the Dart services) was real and correct — it
-- just wasn't the boundary. This is.
--
-- The only form that works: revoke at TABLE level, then re-grant the
-- allowed columns explicitly.

-- 1. Drop the blanket table-level SELECT that was overriding everything.
REVOKE SELECT ON public.profiles FROM authenticated, anon;

-- 2. Re-grant every column EXCEPT date_of_birth. Age reaches the client
--    only via ages_for() (SECURITY DEFINER), which returns a derived
--    integer and never the birthdate itself.
--
--    Listed explicitly rather than generated, so that ADDING A COLUMN TO
--    profiles DOES NOT AUTOMATICALLY EXPOSE IT. A new column is invisible
--    to the client until someone consciously adds it here. That is the
--    intended behaviour, not an oversight — if a future column silently
--    fails to appear in the app, this list is why.
GRANT SELECT (
  id,
  role,
  first_name,
  surname_line,
  gender,
  location_text,
  bio,
  is_active,
  profile_complete,
  created_at,
  updated_at
) ON public.profiles TO authenticated;

-- 3. `anon` gets nothing at all. Nothing in the app reads profiles
--    unauthenticated: every path (AuthGate -> resolveHome, Browse,
--    Matches, Journey) requires a session first. The two functions an
--    unauthenticated user can legitimately hit — preview_wali_invite and
--    accept_wali_invite — are SECURITY DEFINER and run as the owner, so
--    they are unaffected by this. Previously anon could read every
--    active, complete profile in the database, including date_of_birth.

-- NOT DONE HERE, deliberately — see audit finding C4 (write side).
-- `authenticated` still holds UPDATE on role, date_of_birth, gender and
-- profile_complete, which permits self-promotion to role='admin', age
-- falsification, and self-publishing without moderation. Those cannot be
-- revoked in isolation: ZyraProfileService._createProfile uses an UPSERT
-- that writes role/gender/date_of_birth, so revoking UPDATE on them
-- breaks profile creation on any second run (a name edit, or Developer
-- Access "Test Sign Up"). Closing C4 properly means moving profile
-- creation behind a SECURITY DEFINER RPC first. Doing half of it now
-- would break onboarding, which cannot be tested from this environment.
-- Tracked as the next migration, not forgotten.
