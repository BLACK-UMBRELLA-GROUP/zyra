-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260801144754, applied name
-- 'profile_reports_and_blocks') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Reporting and blocking (Founder request 2026-08-01).
--
-- Until now ZYRA had NO way to report or block anyone. The Browse
-- long-press menu offered "Report a Problem", but it opened the generic
-- Help & Support screen — there was no subject, no reason, and nowhere
-- for a report to go. This is the storage that makes it real. UI without
-- these tables would be a safety feature that silently discards reports,
-- which is worse than having none: a woman who reports someone would
-- believe she had been heard.
--
-- Muzz's reason list (reviewed 2026-08-01, see MUZZ_TEARDOWN_CURRENT_
-- VERSION_V1.md) is the guideline for the taxonomy, with one borrowed
-- idea worth calling out: their first option is "I don't want to see this
-- person", which is a BLOCK, not a report. Most people reaching for
-- "report" just want the person gone. Separating those two keeps the
-- moderation queue clean and gives the user the outcome they actually
-- wanted. Hence two tables, not one.

-- ============================================================
-- BLOCKS — mutual invisibility, no moderation involvement
-- ============================================================
CREATE TABLE profile_blocks (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (blocker_id, blocked_id),
  CHECK (blocker_id <> blocked_id)
);

-- Both directions are queried by profiles_select below (a block hides the
-- pair from EACH OTHER, not just one way), so both orderings need an
-- index or that policy becomes a sequential scan on every profile read.
CREATE INDEX profile_blocks_blocker ON profile_blocks(blocker_id, blocked_id);
CREATE INDEX profile_blocks_blocked ON profile_blocks(blocked_id, blocker_id);

ALTER TABLE profile_blocks ENABLE ROW LEVEL SECURITY;

-- You can see, create and remove your OWN blocks. You can never see that
-- someone has blocked you — that would turn a safety tool into a signal.
CREATE POLICY profile_blocks_select ON profile_blocks FOR SELECT
  USING (blocker_id = (select auth.uid()));

CREATE POLICY profile_blocks_insert ON profile_blocks FOR INSERT
  WITH CHECK (blocker_id = (select auth.uid()));

-- Unblocking is free and self-service, from the Settings list. DR-K
-- (proposed) says a block must never be PURCHASABLE to undo — it says
-- nothing against the person who set it changing their own mind, and an
-- accidental block with no way back would be its own problem.
CREATE POLICY profile_blocks_delete ON profile_blocks FOR DELETE
  USING (blocker_id = (select auth.uid()));

-- ============================================================
-- REPORTS — goes to moderation, never visible to the reported user
-- ============================================================
CREATE TABLE profile_reports (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reported_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reason       TEXT NOT NULL CHECK (reason IN (
                 'fake_profile',
                 'inappropriate_content',
                 'harassment',
                 'underage',
                 'violence',
                 'privacy',
                 'other'
               )),
  detail       TEXT,
  -- Where the report was raised from. Moderation needs this: a report
  -- from an active Journey is a materially different signal to one from
  -- a Browse card the reporter saw for four seconds.
  source       TEXT NOT NULL DEFAULT 'browse' CHECK (source IN ('browse', 'chat', 'journey', 'connections', 'profile')),
  status       TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewing', 'actioned', 'dismissed')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reviewed_at  TIMESTAMPTZ
);

-- Deliberately NOT unique on (reporter_id, reported_id): repeat reports
-- about the same person are themselves signal, and silently swallowing
-- the second one would tell a user their report worked when it didn't.
CREATE INDEX profile_reports_reported ON profile_reports(reported_id, created_at DESC);
CREATE INDEX profile_reports_pending  ON profile_reports(created_at DESC) WHERE status = 'pending';

ALTER TABLE profile_reports ENABLE ROW LEVEL SECURITY;

-- Insert your own only. No UPDATE and no DELETE policy at all: a report,
-- once made, is not editable or retractable by either party — that's what
-- makes it evidence. `status` moves only from the moderation side
-- (service_role), never from a client.
CREATE POLICY profile_reports_insert ON profile_reports FOR INSERT
  WITH CHECK (reporter_id = (select auth.uid()));

-- You may read back your OWN reports (what you sent, and when). You can
-- never read reports about you — that would let a harasser learn they had
-- been reported, and by how many people.
CREATE POLICY profile_reports_select ON profile_reports FOR SELECT
  USING (reporter_id = (select auth.uid()));

-- ============================================================
-- MAKE BLOCKING REAL AT THE BOUNDARY
-- ============================================================
-- Enforced in RLS rather than in the Dart discovery query, deliberately.
-- A block filtered client-side is a block that only works on the one
-- screen someone remembered to filter — Browse would honour it while
-- Matches, Journey and the profile fetches in three other services
-- silently would not. Putting it here means every present and future
-- query path inherits it for free, including ones not written yet.
--
-- Mutual: if either party blocked the other, neither can read the other's
-- profile row. profile_photos_select and the storage read policy both
-- delegate to a profiles lookup, so photos follow automatically.
DROP POLICY profiles_select ON profiles;
CREATE POLICY profiles_select ON profiles FOR SELECT USING (
  id = (select auth.uid())
  OR (
    is_active = true
    AND profile_complete = true
    AND NOT EXISTS (
      SELECT 1 FROM profile_blocks b
      WHERE (b.blocker_id = (select auth.uid()) AND b.blocked_id = profiles.id)
         OR (b.blocked_id = (select auth.uid()) AND b.blocker_id = profiles.id)
    )
  )
);
