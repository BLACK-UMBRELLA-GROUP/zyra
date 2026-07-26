-- Security advisory fix (anon/authenticated_security_definer_function_
-- executable, WARN). create_match_on_mutual_like() is a trigger
-- function only — it references NEW, which only exists in trigger
-- context, so calling it directly via the auto-exposed PostgREST RPC
-- endpoint would just error. Still, Supabase flags any SECURITY
-- DEFINER function left callable via RPC as a WARN, and there's no
-- legitimate reason for a client to invoke this directly, so revoke
-- EXECUTE for anon/authenticated explicitly rather than rely on that
-- error as the only guard.
REVOKE EXECUTE ON FUNCTION create_match_on_mutual_like() FROM anon, authenticated;
