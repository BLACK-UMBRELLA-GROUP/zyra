-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260801192352, applied name
-- 'passes_table_and_reset_search') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- Declined profiles, persisted. Founder decision 2026-08-01.
--
-- Until now a Decline lived only in AppState, in memory. It died on every
-- app restart, so "profiles I passed on" came straight back, and Reset
-- Search could not be built at all because there was nothing to reset.
--
-- The model this enforces (Founder, 2026-08-01):
--   DECISION  Considering (likes) | Declined (passes). Mutually
--             exclusive. Most recent wins.
--   SAVED     (saves) A bookmark on its own axis. Never touched by a
--             decision, in either direction.

CREATE TABLE passes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  passer_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  passed_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (passer_id <> passed_id),
  UNIQUE (passer_id, passed_id)
);

CREATE INDEX passes_passer_idx ON passes (passer_id);

ALTER TABLE passes ENABLE ROW LEVEL SECURITY;

-- Deliberately narrower than `likes`. A Like is readable by the person
-- liked (the mutual-match trigger depends on it). A Pass must never be:
-- being able to see who declined you is a feature nobody has asked for
-- and one this app should not have.
CREATE POLICY passes_select ON passes FOR SELECT TO authenticated
  USING (passer_id = (SELECT auth.uid()));

CREATE POLICY passes_insert ON passes FOR INSERT TO authenticated
  WITH CHECK (passer_id = (SELECT auth.uid()));

-- DELETE is what makes Reset Search, and re-Considering someone you
-- previously passed on, possible.
CREATE POLICY passes_delete ON passes FOR DELETE TO authenticated
  USING (passer_id = (SELECT auth.uid()));

-- ---------------------------------------------------------------------
-- Exclusivity, enforced server-side rather than trusted to the client.
--
-- The Dart layer now clears the opposite list itself, but the app is not
-- the only thing that can write here, and "most recent decision wins" is
-- a rule about the DATA. A client that forgets recreates exactly the bug
-- this migration exists to fix.
--
-- Note these triggers do NOT touch `saves`. That is the whole point of
-- the two-axis model: a bookmark survives every decision.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION zyra_pass_clears_like()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM likes WHERE liker_id = NEW.passer_id AND liked_id = NEW.passed_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER passes_clear_like
  AFTER INSERT ON passes
  FOR EACH ROW EXECUTE FUNCTION zyra_pass_clears_like();

CREATE OR REPLACE FUNCTION zyra_like_clears_pass()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM passes WHERE passer_id = NEW.liker_id AND passed_id = NEW.liked_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER likes_clear_pass
  AFTER INSERT ON likes
  FOR EACH ROW EXECUTE FUNCTION zyra_like_clears_pass();

-- ---------------------------------------------------------------------
-- Reset Search. Founder decision: clears Declined ONLY.
--
-- Not Considering ("if I've already decided to Consider someone, I don't
-- need to discover them again"), not Saved ("I've intentionally preserved
-- them"), not Journeys, not Matches. Those stay exactly where the user
-- put them.
--
-- SECURITY DEFINER but scoped to auth.uid() — it can only ever clear the
-- caller's own passes. Returns the number cleared so the UI can say
-- something true.
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION zyra_reset_search()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  me      UUID := auth.uid();
  cleared INTEGER;
BEGIN
  IF me IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;
  DELETE FROM passes WHERE passer_id = me;
  GET DIAGNOSTICS cleared = ROW_COUNT;
  RETURN cleared;
END;
$$;

REVOKE ALL ON FUNCTION zyra_reset_search() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION zyra_reset_search() TO authenticated;
