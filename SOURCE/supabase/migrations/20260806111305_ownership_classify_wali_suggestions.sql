-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806111305, applied name
-- 'ownership_classify_wali_suggestions') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- wali_suggestions — surfaced by zyra_data_ownership as UNCLASSIFIED
-- immediately after the view was inverted. The table was created
-- 2026-08-05 (guardian_suggestions_use_dedicated_profiles) by a different
-- session and had no ownership classification.
--
-- This is the drift the Founder's note 2 was aimed at, caught within
-- seconds of the mechanism existing rather than during a subject access
-- request. It is also the argument for note 3 — classification belongs in
-- the migration that creates a table, not in a later sweep.
--
-- THREE PARTIES, not two. A Guardian suggests a profile to their Seeker.
-- The SUGGESTED person is not party to any of it and must never learn they
-- were suggested — still less that they were declined. Same reasoning as
-- passes and saves: one person's private consideration of another does not
-- become the other person's data by being about them.

comment on table public.wali_suggestions is
  'OWNERSHIP: joint(wali_id, seeker_id) — a Guardian''s suggestion to their Seeker. NON-EXPORTABLE to the suggested person, who is not party to it and must never learn they were suggested or declined.';

comment on column public.wali_suggestions.wali_id      is 'OWNERSHIP: joint(wali_id, seeker_id)';
comment on column public.wali_suggestions.seeker_id    is 'OWNERSHIP: joint(wali_id, seeker_id)';
comment on column public.wali_suggestions.suggested_id is
  'OWNERSHIP: non-exportable to the suggested person. They are a third party to this row.';
comment on column public.wali_suggestions.status       is
  'OWNERSHIP: joint(wali_id, seeker_id) — the Seeker''s response to their own Guardian. Never disclosed to the suggested person: "she declined you" is not theirs to receive.';
comment on column public.wali_suggestions.responded_at is 'OWNERSHIP: joint(wali_id, seeker_id)';
