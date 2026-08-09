-- APPLIED LIVE 2026-08-08, version 20260808145239.
-- Supabase security advisor sweep. 57 notices; three actionable here,
-- the rest tracked or dashboard-only. Verified 11/11.
--
-- 1 · MY OVERSIGHT, FIXED. zyra_enforce_one_active_match() — added hours
--     earlier in step 6 — was left EXECUTE-able by anon and authenticated.
--     Its sibling zyra_enforce_one_active_attempt() has both revoked, so
--     the pattern existed and I did not follow it. Not exploitable
--     (Postgres refuses to call a trigger function directly), but exactly
--     the drift that makes a grant surface unreadable.
--
-- 2 · zyra_my_attempt_participation granted SELECT to `anon`. An
--     unauthenticated caller gets zero rows anyway — the view filters on
--     auth.uid(), NULL for anon — so noise rather than exposure. Revoked
--     because a grant that does nothing is a grant nobody questions later.
--
-- 3 · The advisor's only ERROR — security_definer_view on
--     zyra_my_attempt_participation — is DELIBERATE. See the comment.
--
-- CHECKED, NOT A PROBLEM: zyra_attempt_participant_rows, the view holding
-- EVERY participant of every attempt, has no grant to anon or
-- authenticated at all. Only the caller-filtered view is exposed. The
-- enumeration risk that zyra_attempt_participants() carried earlier today
-- does not exist on the view behind it.
--
-- NOT ACTIONABLE HERE: 53 "authenticated can execute SECURITY DEFINER"
-- warnings are OA-ZYRA-172, raised and deliberately not started.
-- Leaked-password protection is an Auth dashboard setting.

revoke execute on function public.zyra_enforce_one_active_match() from public, anon, authenticated;
revoke select on public.zyra_my_attempt_participation from anon;

comment on view public.zyra_my_attempt_participation is
  'SECURITY DEFINER BY DESIGN — do not "fix" the advisor ERROR on this. '
  'It is read from inside roughly eighteen RLS policies. As an INVOKER '
  'view it would be subject to the caller''s own RLS on the base tables, '
  'which is the policy currently being evaluated: either infinite '
  'recursion or an empty result. Definer is what makes it usable as a '
  'policy helper. Safe because it filters to auth.uid() internally and '
  'returns only the caller''s own participation rows — the unfiltered '
  'sibling, zyra_attempt_participant_rows, is granted to nobody.';

comment on view public.zyra_attempt_participant_rows is
  'EVERY participant of every attempt — both Seekers and all active '
  'Guardians of both. Granted to NO client role, and it must stay that '
  'way: it is a complete who-is-attached-to-whom map. Read it through '
  'zyra_my_attempt_participation, which filters to the caller.';

-- VERIFIED 2026-08-08:
--   trigger fn executable by anon / authenticated ....... false / false
--   participation view: anon SELECT ..................... false
--   participation view: authenticated SELECT ............ true (must stay)
--   full roster view: authenticated SELECT .............. false
--   conversations_select / messages_select / matches_select still work
--     (all three read the view from inside their policies)
