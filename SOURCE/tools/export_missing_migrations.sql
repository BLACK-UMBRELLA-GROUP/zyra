-- HISTORICAL MIGRATION DIAGNOSTIC — OA-ZYRA-198.
--
-- This read-only query was written during the 2026-08-12 stewardship pass.
-- Its old live/repo counts and "self-updating" instructions became stale, and
-- file presence was later shown not to prove chronological replayability.
--
-- GOVERNED USE ONLY:
--   * use the output to identify and compare retained history statements;
--   * populate `zyra.repo_migration_names` manually in the same SQL session;
--   * preserve statement-array boundaries and hash UTF-8 bytes independently;
--   * never copy output straight into the active migration directory without
--     a true pre-state, an explicit Founder-approved recovery scope and a
--     clean isolated replay.
--
-- `array_to_string` below is convenient inspection output, not a general
-- byte-exact exporter for multi-statement arrays. OA-ZYRA-198's eight governed
-- recoveries each had exactly one retained statement and were transferred and
-- verified separately.
--
-- VERSION DRIFT: two live rows are excluded from active replay because the
-- repo carries their hand-split equivalents:
--   20260811102840 / 20260811103056 — the repo carries them hand-split as
--   20260811110300 + 20260811111500 (see 20260811110300's header).
-- The 2026-08-21 reconciliation nevertheless added both live copies to the
-- active folder, producing the measured 2026-09-10 clean-replay collision at
-- 20260811104500. The Founder approved the byte-preserved correction on
-- 2026-09-11: both exact files now live under SYSTEM/RESOURCES/
-- MIGRATION_HISTORY/OA-ZYRA-198_2026-09-11_CHRONOLOGY_ARCHIVE/ and the active
-- folder follows 104500 -> 110300 -> 111500. Do not restore them or change
-- this exclusion without a new Founder-approved chronology decision.

select m.version || '_' || m.name || '.sql' as filename,
       array_to_string(m.statements, E'\n') as contents
  from supabase_migrations.schema_migrations m
 where m.version not in ('20260811102840','20260811103056')
   and not exists (
    -- Populate the current repo migration names explicitly before running.
     select 1 where m.name = any (string_to_array(
       current_setting('zyra.repo_migration_names', true), ','))
   )
 order by m.version;
