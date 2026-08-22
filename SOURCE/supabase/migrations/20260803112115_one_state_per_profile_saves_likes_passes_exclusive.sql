-- OA-ZYRA-198: repo/live migration reconciliation (2026-08-21).
-- This file was regenerated FROM THE LIVE PROJECT's
-- supabase_migrations.schema_migrations (version 20260803112115, applied name
-- 'one_state_per_profile_saves_likes_passes_exclusive') because the migration was applied via API in the
-- 2026-08-01..08 window before the repo-file discipline existed.
-- It is the applied statement text verbatim; do not re-run.

-- ONE STATE PER PROFILE — Founder decision 2026-08-03.
--
-- Saved, Considering (likes) and Declined (passes) are now MUTUALLY
-- EXCLUSIVE. Acting on a profile clears whatever state it was in.
--
-- THIS REVERSES the 2026-08-01 model, where `saves` was a bookmark on its
-- own axis and the triggers deliberately did NOT touch it. Recorded here
-- because those triggers carried a comment saying the opposite, and the
-- next person to read them would otherwise assume this was a mistake:
--
--   1 Aug   passes_clear_like / likes_clear_pass. Saved untouched, by
--           design — "a bookmark survives every decision".
--   3 Aug   Founder, on seeing one profile under both CONSIDERED and
--           SAVED: "a user can't be both saved and considered."
--
-- Three tables, six deletions. Each insert clears the other two.

CREATE OR REPLACE FUNCTION zyra_pass_clears_others()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM likes WHERE liker_id = NEW.passer_id AND liked_id = NEW.passed_id;
  DELETE FROM saves WHERE saver_id = NEW.passer_id AND saved_id = NEW.passed_id;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION zyra_like_clears_others()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM passes WHERE passer_id = NEW.liker_id AND passed_id = NEW.liked_id;
  DELETE FROM saves  WHERE saver_id  = NEW.liker_id AND saved_id  = NEW.liked_id;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION zyra_save_clears_others()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM passes WHERE passer_id = NEW.saver_id AND passed_id = NEW.saved_id;
  DELETE FROM likes  WHERE liker_id  = NEW.saver_id AND liked_id  = NEW.saved_id;
  RETURN NEW;
END;
$$;

-- Replace the two 1-Aug triggers rather than adding alongside them, so
-- there is never a moment with both models running.
DROP TRIGGER IF EXISTS passes_clear_like ON passes;
DROP TRIGGER IF EXISTS likes_clear_pass  ON likes;
DROP FUNCTION IF EXISTS zyra_pass_clears_like();
DROP FUNCTION IF EXISTS zyra_like_clears_pass();

CREATE TRIGGER passes_clear_others
  AFTER INSERT ON passes
  FOR EACH ROW EXECUTE FUNCTION zyra_pass_clears_others();

CREATE TRIGGER likes_clear_others
  AFTER INSERT ON likes
  FOR EACH ROW EXECUTE FUNCTION zyra_like_clears_others();

CREATE TRIGGER saves_clear_others
  AFTER INSERT ON saves
  FOR EACH ROW EXECUTE FUNCTION zyra_save_clears_others();

-- Existing rows predate the rule and can violate it. Resolve by most
-- recent action, which is what the rule itself says wins.
--
-- Done as an explicit backfill rather than left to sort itself out: a
-- Seeker signing in tomorrow would otherwise still see somebody in two
-- lists, and would report the same bug again.
WITH ranked AS (
  SELECT owner_id, other_id, src, created_at,
         ROW_NUMBER() OVER (PARTITION BY owner_id, other_id ORDER BY created_at DESC) AS rn
  FROM (
    SELECT saver_id  AS owner_id, saved_id  AS other_id, 'save' AS src, created_at FROM saves
    UNION ALL
    SELECT liker_id  AS owner_id, liked_id  AS other_id, 'like' AS src, created_at FROM likes
    UNION ALL
    SELECT passer_id AS owner_id, passed_id AS other_id, 'pass' AS src, created_at FROM passes
  ) all_states
),
losers AS (SELECT * FROM ranked WHERE rn > 1)
DELETE FROM saves s
USING losers l
WHERE l.src = 'save' AND s.saver_id = l.owner_id AND s.saved_id = l.other_id;

WITH ranked AS (
  SELECT owner_id, other_id, src, created_at,
         ROW_NUMBER() OVER (PARTITION BY owner_id, other_id ORDER BY created_at DESC) AS rn
  FROM (
    SELECT saver_id, saved_id, 'save', created_at FROM saves
    UNION ALL SELECT liker_id, liked_id, 'like', created_at FROM likes
    UNION ALL SELECT passer_id, passed_id, 'pass', created_at FROM passes
  ) AS t(owner_id, other_id, src, created_at)
),
losers AS (SELECT * FROM ranked WHERE rn > 1)
DELETE FROM likes k
USING losers l
WHERE l.src = 'like' AND k.liker_id = l.owner_id AND k.liked_id = l.other_id;

WITH ranked AS (
  SELECT owner_id, other_id, src, created_at,
         ROW_NUMBER() OVER (PARTITION BY owner_id, other_id ORDER BY created_at DESC) AS rn
  FROM (
    SELECT saver_id, saved_id, 'save', created_at FROM saves
    UNION ALL SELECT liker_id, liked_id, 'like', created_at FROM likes
    UNION ALL SELECT passer_id, passed_id, 'pass', created_at FROM passes
  ) AS t(owner_id, other_id, src, created_at)
),
losers AS (SELECT * FROM ranked WHERE rn > 1)
DELETE FROM passes p
USING losers l
WHERE l.src = 'pass' AND p.passer_id = l.owner_id AND p.passed_id = l.other_id;
