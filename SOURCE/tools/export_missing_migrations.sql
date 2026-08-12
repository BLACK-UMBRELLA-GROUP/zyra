-- EXPORT MISSING MIGRATION FILES — OA-ZYRA-198 (2026-08-12 stewardship pass).
--
-- The live database holds 178 applied migrations; the repo holds files for
-- ~91 of them by name. Every applied migration's verbatim statements are
-- preserved in supabase_migrations.schema_migrations, so the repo can be
-- reconciled at any time.
--
-- HOW TO USE (Supabase Dashboard -> SQL Editor):
--   1. Run the query below. Each row is one missing file: `filename` and
--      `contents`.
--   2. Download the result as CSV, or copy row by row, into
--      SOURCE/supabase/migrations/<filename>.
--   3. Re-run: the query self-updates because it excludes by name — a file
--      you have written stops appearing once its name matches.
--
-- NOTE ON VERSION DRIFT: a few migrations exist in the repo under a
-- DIFFERENT version number than the live row with the same name (files were
-- hand-written back on 2026-08-08/11). Name-match is therefore the join key.
-- Two live rows are deliberately NOT wanted as files:
--   20260811102840 / 20260811103056 — the repo carries them hand-split as
--   20260811110300 + 20260811111500 (see 20260811110300's header).

select m.version || '_' || m.name || '.sql' as filename,
       array_to_string(m.statements, E'\n') as contents
  from supabase_migrations.schema_migrations m
 where m.version not in ('20260811102840','20260811103056')
   and not exists (
     -- paste the current repo file names here, one per row, when re-running
     -- by hand; or use the maintained list in the stewardship report.
     select 1 where m.name = any (string_to_array(
       current_setting('zyra.repo_migration_names', true), ','))
   )
 order by m.version;
