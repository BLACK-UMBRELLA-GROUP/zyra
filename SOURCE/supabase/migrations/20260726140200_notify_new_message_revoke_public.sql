-- Root cause of the prior migration (20260726140100) not fully taking
-- effect: notify_new_message() was never REVOKE'd FROM PUBLIC (only
-- create_notification was, in 20260726140000_notifications.sql).
-- PUBLIC grants apply to every role implicitly, including anon/
-- authenticated, so REVOKE ... FROM anon/authenticated alone doesn't
-- remove access while PUBLIC still holds a grant. Verified fixed via
-- has_function_privilege('anon'/'authenticated', ...) both returning
-- false after this.
REVOKE EXECUTE ON FUNCTION public.notify_new_message() FROM PUBLIC;
