-- FUNCTION EXECUTE HYGIENE + PROBE TABLE RLS — 2026-08-12 stewardship pass
-- (applied live 2026-08-11 23:38 UTC via MCP; file written back the same
-- night).
--
-- The 2026-08-04 audit closed H-5 with "0 of 35 SECURITY DEFINER functions
-- reachable by anon". The security advisor showed FIVE reachable again —
-- every one created after that closure. The pattern keeps regressing because
-- Postgres grants EXECUTE to PUBLIC on every new function by default, and
-- each migration must remember the revoke by hand.
--
-- 1) Re-close the five (three are trigger functions — uncallable directly,
--    revoked anyway for a clean advisor and to honour H-5's zero;
--    zyra_onboarding_data_complete(p_user, p_gender) IS callable and let
--    anon probe any user's onboarding completeness by uuid).
-- 2) Fix the root cause: default privileges for functions created by
--    postgres in public no longer include PUBLIC/anon. A new RPC is BORN
--    unreachable until its migration grants EXECUTE explicitly — forgetting
--    now fails loud in testing instead of silently exposing. (House pattern
--    already grants `to authenticated` explicitly, so existing style keeps
--    working unchanged.)
-- 3) zyra_probe_score: scratch table from the 2026-08-10/11 scoring
--    analysis sitting in public with RLS OFF — the exact class the
--    2026-08-08 session dropped four of. Locked (RLS on, grants revoked)
--    rather than dropped unattended; dropping it and zyra_dev_probe /
--    zyra_seed_answers is raised for Founder decision instead.
--
-- Verified after: anon-reachable SECURITY DEFINER functions = 0.

REVOKE EXECUTE ON FUNCTION public.zyra_answers_refresh_onboarding_complete() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.zyra_onboarding_data_complete(uuid, text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.zyra_profiles_set_onboarding_complete() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.zyra_record_journey_milestone() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.zyra_refresh_onboarding_complete(uuid) FROM PUBLIC, anon;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE EXECUTE ON FUNCTIONS FROM anon;

ALTER TABLE public.zyra_probe_score ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.zyra_probe_score FROM anon, authenticated;
