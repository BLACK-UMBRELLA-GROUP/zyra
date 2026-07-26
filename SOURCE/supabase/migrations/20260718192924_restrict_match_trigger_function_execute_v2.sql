-- Follow-up: revoking from anon/authenticated directly wasn't enough
-- because Postgres grants EXECUTE to PUBLIC by default when a
-- function is created, and every role (including anon/authenticated)
-- implicitly inherits PUBLIC's privileges. Revoke from PUBLIC too.
REVOKE EXECUTE ON FUNCTION create_match_on_mutual_like() FROM PUBLIC;
