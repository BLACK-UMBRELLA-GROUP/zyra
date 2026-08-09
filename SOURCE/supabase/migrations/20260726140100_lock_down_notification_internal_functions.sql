-- create_notification and notify_new_message are internal helpers
-- only ever meant to be called from inside other SECURITY DEFINER
-- functions/triggers (owned by the same role), never directly via
-- REST RPC. Same anon/authenticated-bootstrap-grant gap as
-- ages_for/score_candidates in 20260726120300_restrict_ages_for_and_
-- score_candidates_to_authenticated.sql — REVOKE ALL FROM PUBLIC
-- doesn't touch Supabase's separate direct grants to anon/
-- authenticated.
REVOKE EXECUTE ON FUNCTION public.create_notification(UUID, TEXT, TEXT, TEXT, UUID) FROM anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.notify_new_message() FROM anon, authenticated;
