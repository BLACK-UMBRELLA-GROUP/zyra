-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806200024, applied name
-- 'profile_reports_guardian_source') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Reports raised from the Guardian page need their own source, so a report
-- about your own Guardian is distinguishable from one about a stranger in
-- Browse. They are different situations and whoever reviews them should not
-- have to infer which is which.
--
-- Report and Remove stay INDEPENDENT (Founder, 2026-08-06). A report says
-- "this person broke the rules"; a removal says "I no longer want them
-- linked". Someone may report an impersonated Guardian account and still
-- want the link kept while it is investigated.

alter table public.profile_reports
  drop constraint if exists profile_reports_source_check;

alter table public.profile_reports
  add constraint profile_reports_source_check
  check (source = any (array[
    'browse', 'chat', 'journey', 'connections', 'profile', 'guardian'
  ]));
