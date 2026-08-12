-- Backstory for the seeded dev Journeys — Founder, 2026-08-11: "create fake
-- scenarios when they liked each other, when they matched."
--
-- These matches were written straight into the table for testing, so they
-- never went through create_match_on_mutual_like() and carry no record of how
-- the two people found each other. Real matches get 'match_created' from that
-- trigger; nothing has ever written 'liked', because a like that becomes a
-- match is currently only implied by the match existing.
--
-- Dated backwards from the match so the Timeline reads in a believable order:
-- liked three days before, matched, Journey began half an hour later.
--
-- Idempotent, and safe to re-run after a rewind — the rewind keeps exactly
-- these three types, so this will find them already present and do nothing.
WITH t AS (
  INSERT INTO timelines (match_id, attempt_id)
  SELECT m.id, a.id FROM matches m
    JOIN journey_attempts a ON a.match_id = m.id
  ON CONFLICT (attempt_id) DO NOTHING
  RETURNING id, match_id
), all_t AS (
  SELECT id, match_id FROM t
  UNION
  SELECT tl.id, tl.match_id FROM timelines tl
)
INSERT INTO timeline_milestones (timeline_id, milestone_type, occurred_at)
SELECT at.id, v.mtype, m.created_at + v.offset_
FROM all_t at
JOIN matches m ON m.id = at.match_id
CROSS JOIN (VALUES
  ('liked',           -interval '3 days'),
  ('match_created',    interval '0 minutes'),
  ('journey_started',  interval '30 minutes')
) AS v(mtype, offset_)
WHERE NOT EXISTS (
  SELECT 1 FROM timeline_milestones tm
   WHERE tm.timeline_id = at.id AND tm.milestone_type = v.mtype
);
