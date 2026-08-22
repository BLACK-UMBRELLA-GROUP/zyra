-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260806192353, applied name
-- 'wali_suggestions_seen_at') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- BUG: the Introductions dot stayed lit until every introduction had been
-- decided, so it kept nagging for days about something already looked at.
--
-- The code was written to the ORIGINAL badge rule ("clears on resolution,
-- never on view"). The Founder amended that rule the same day and the code
-- was never brought along:
--
--   BADGE      counts UNSEEN     clears when you arrive at the surface
--   LIST COUNT counts UNRESOLVED clears when the item is resolved
--
-- The badge is the alert; the list is the work. Arriving discharges the
-- alert. It does not do the work, and the heading goes on saying so.
--
-- NOT a last_seen_at bookmark (CLAUDE.md §3d). "Unseen" is a per-ITEM state,
-- the same shape as unresolved: null here means unseen, the dot counts
-- nulls, and nothing anywhere stores a timestamp about the observer. See two
-- introductions, a third arrives, the dot returns.

alter table public.wali_suggestions
  add column if not exists seen_at timestamptz;

comment on column public.wali_suggestions.seen_at is
  'OWNERSHIP: row-scoped(seeker_id) — when the Seeker first landed on '
  'Introductions with this suggestion present. Null means unseen. Drives the '
  'badge only; it is not a read receipt shown to the Guardian, who must not '
  'learn whether their suggestion has been looked at but not yet answered.';

create index if not exists wali_suggestions_unseen
  on public.wali_suggestions (seeker_id)
  where seen_at is null and status = 'pending';
