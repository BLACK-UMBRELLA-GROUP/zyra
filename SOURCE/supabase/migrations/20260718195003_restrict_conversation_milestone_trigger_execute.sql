-- Supabase grants EXECUTE to anon/authenticated by default on new
-- public-schema functions (ALTER DEFAULT PRIVILEGES) — revoking from
-- PUBLIC alone doesn't remove those explicit grants, same lesson
-- learned earlier with create_match_on_mutual_like. Trigger-only
-- function, no legitimate direct-call reason.
REVOKE EXECUTE ON FUNCTION create_conversation_started_milestone() FROM anon, authenticated;
