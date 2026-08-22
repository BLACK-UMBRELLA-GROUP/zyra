-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260805233111, applied name
-- 'restrict_photo_object_gate_to_authenticated') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- The advisor flagged zyra_can_read_photo_object as callable by `anon` over
-- /rest/v1/rpc. Signed-out callers have no business probing which storage
-- object names exist, and this function is only ever meant to be evaluated
-- inside the storage RLS policy, never called directly. Narrow it.
--
-- (The same warning applies to ~25 pre-existing functions and is Opus's lane
-- to sweep; fixing it for the one function added today keeps the new surface
-- clean rather than adding to the pile.)

revoke all on function public.zyra_can_read_photo_object(text) from public;
revoke all on function public.zyra_can_read_photo_object(text) from anon;

grant execute on function public.zyra_can_read_photo_object(text) to authenticated;
grant execute on function public.zyra_can_read_photo_object(text) to service_role;
grant execute on function public.zyra_can_read_photo_object(text) to supabase_storage_admin;
