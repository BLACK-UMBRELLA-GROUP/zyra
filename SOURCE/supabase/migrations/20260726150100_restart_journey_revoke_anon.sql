-- Same Supabase bootstrap-grant gotcha as ages_for/score_candidates
-- (20260726120300) and create_notification/notify_new_message
-- (20260726140100): REVOKE ... FROM PUBLIC doesn't remove Supabase's
-- separate direct grant of EXECUTE to anon on new public-schema
-- functions. Verified fixed via has_function_privilege.
REVOKE EXECUTE ON FUNCTION public.restart_journey(UUID) FROM anon;
