-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806110723, applied name
-- 'oa155_close_classification_gaps') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Four columns the zyra_data_ownership view flagged as UNCLASSIFIED on its
-- first run. Exactly what it is for — these were missed in the hand-written
-- pass and surfaced in seconds rather than during a subject access request.

comment on column public.matches.seeker_a_id is
  'OWNERSHIP: joint — who you matched with is equally each party''s own fact. NOT a route to the other person''s data; it is an identifier both already hold.';
comment on column public.matches.seeker_b_id is
  'OWNERSHIP: joint — see seeker_a_id.';

comment on column public.profile_photos.display_order is
  'OWNERSHIP: row-scoped(user_id) — the owner''s own ordering choice.';
comment on column public.profile_photos.is_primary is
  'OWNERSHIP: row-scoped(user_id)';
