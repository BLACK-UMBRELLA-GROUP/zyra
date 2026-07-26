-- Pre-Journey Ritual (PRE-JOURNEY RITUAL/Summary.md), real v1 build.
-- Scope for this pass, per Founder decision 2026-07-25: build the full
-- sequential structure for real (Compatibility Reveal, Salam Exchange,
-- Wali Gate, Phases 1-3, Family Stage — Seeker<->Wali directions only,
-- Wali<->Wali deferred as the source doc itself marks it TBC), with a
-- FIXED curated question order standing in for "AI-adaptive question
-- selection" (no LLM integration exists in this codebase — flagged
-- separately). Part B (searchable personal question library) is
-- deferred as its own follow-up, not built here.

-- 1. Main Wali designation — Wali Gate requires "one Wali must be
-- designated as Main Wali", which wali_links had no way to express.
ALTER TABLE wali_links ADD COLUMN is_main BOOLEAN NOT NULL DEFAULT FALSE;

CREATE UNIQUE INDEX wali_links_one_main_per_seeker
  ON wali_links(seeker_id)
  WHERE is_main = TRUE AND status = 'active';

-- Auto-designate the first active link as Main Wali for a Seeker who
-- has none yet, so existing/new links aren't left without one.
CREATE OR REPLACE FUNCTION public.auto_designate_main_wali()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.status = 'active' AND NOT EXISTS (
    SELECT 1 FROM wali_links WHERE seeker_id = NEW.seeker_id AND is_main = TRUE AND status = 'active'
  ) THEN
    NEW.is_main := TRUE;
  END IF;
  RETURN NEW;
END;
$function$;

CREATE TRIGGER wali_links_auto_main
  BEFORE INSERT OR UPDATE ON wali_links
  FOR EACH ROW EXECUTE FUNCTION auto_designate_main_wali();

-- 2. Salam Exchange
CREATE TABLE journey_salams (
  match_id   UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  seeker_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  sent_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (match_id, seeker_id)
);
ALTER TABLE journey_salams ENABLE ROW LEVEL SECURITY;
CREATE POLICY journey_salams_read ON journey_salams FOR SELECT
  USING (EXISTS (SELECT 1 FROM matches m WHERE m.id = match_id AND (auth.uid() = m.seeker_a_id OR auth.uid() = m.seeker_b_id)));
CREATE POLICY journey_salams_write ON journey_salams FOR INSERT
  WITH CHECK (seeker_id = auth.uid() AND EXISTS (SELECT 1 FROM matches m WHERE m.id = match_id AND (auth.uid() = m.seeker_a_id OR auth.uid() = m.seeker_b_id)));

-- 3. Compatibility Reveal — one row per match, both parties must tap
-- reveal before the score is shown to either.
CREATE TABLE journey_compatibility (
  match_id           UUID PRIMARY KEY REFERENCES matches(id) ON DELETE CASCADE,
  seeker_a_revealed  BOOLEAN NOT NULL DEFAULT FALSE,
  seeker_b_revealed  BOOLEAN NOT NULL DEFAULT FALSE,
  overall_score      NUMERIC,
  category_scores    JSONB,
  revealed_at        TIMESTAMPTZ
);
ALTER TABLE journey_compatibility ENABLE ROW LEVEL SECURITY;
CREATE POLICY journey_compatibility_read ON journey_compatibility FOR SELECT
  USING (EXISTS (SELECT 1 FROM matches m WHERE m.id = match_id AND (auth.uid() = m.seeker_a_id OR auth.uid() = m.seeker_b_id)));
CREATE POLICY journey_compatibility_insert ON journey_compatibility FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM matches m WHERE m.id = match_id AND (auth.uid() = m.seeker_a_id OR auth.uid() = m.seeker_b_id)));
CREATE POLICY journey_compatibility_update ON journey_compatibility FOR UPDATE
  USING (EXISTS (SELECT 1 FROM matches m WHERE m.id = match_id AND (auth.uid() = m.seeker_a_id OR auth.uid() = m.seeker_b_id)));

-- 4. Phase question answers (Phases 1-3, Part A only — fixed curated
-- order stands in for AI-adaptive selection this pass).
CREATE TABLE journey_phase_answers (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id     UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  phase        INTEGER NOT NULL CHECK (phase IN (1, 2, 3)),
  seeker_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  question_id  TEXT NOT NULL,
  answer_text  TEXT NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (match_id, phase, seeker_id, question_id)
);
ALTER TABLE journey_phase_answers ENABLE ROW LEVEL SECURITY;
CREATE POLICY journey_phase_answers_read ON journey_phase_answers FOR SELECT
  USING (EXISTS (SELECT 1 FROM matches m WHERE m.id = match_id AND (auth.uid() = m.seeker_a_id OR auth.uid() = m.seeker_b_id)));
CREATE POLICY journey_phase_answers_write ON journey_phase_answers FOR INSERT
  WITH CHECK (seeker_id = auth.uid() AND EXISTS (SELECT 1 FROM matches m WHERE m.id = match_id AND (auth.uid() = m.seeker_a_id OR auth.uid() = m.seeker_b_id)));

-- 5. Private per-answer ratings — never visible to the other party.
CREATE TABLE journey_phase_ratings (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id     UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  phase        INTEGER NOT NULL CHECK (phase IN (1, 2, 3)),
  rater_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  question_id  TEXT NOT NULL,
  rating       TEXT NOT NULL CHECK (rating IN ('reassured', 'discuss_further', 'concerns')),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (match_id, phase, rater_id, question_id)
);
ALTER TABLE journey_phase_ratings ENABLE ROW LEVEL SECURITY;
CREATE POLICY journey_phase_ratings_own ON journey_phase_ratings FOR ALL
  USING (rater_id = auth.uid()) WITH CHECK (rater_id = auth.uid());

-- 6. Phase checkpoints — both parties must choose before advancing.
CREATE TABLE journey_phase_checkpoints (
  match_id   UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  phase      INTEGER NOT NULL CHECK (phase IN (1, 2, 3)),
  seeker_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  decision   TEXT NOT NULL CHECK (decision IN ('continue', 'ask_more', 'end')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (match_id, phase, seeker_id)
);
ALTER TABLE journey_phase_checkpoints ENABLE ROW LEVEL SECURITY;
CREATE POLICY journey_phase_checkpoints_read ON journey_phase_checkpoints FOR SELECT
  USING (EXISTS (SELECT 1 FROM matches m WHERE m.id = match_id AND (auth.uid() = m.seeker_a_id OR auth.uid() = m.seeker_b_id)));
CREATE POLICY journey_phase_checkpoints_write ON journey_phase_checkpoints FOR INSERT
  WITH CHECK (seeker_id = auth.uid() AND EXISTS (SELECT 1 FROM matches m WHERE m.id = match_id AND (auth.uid() = m.seeker_a_id OR auth.uid() = m.seeker_b_id)));

-- 7. Family Compatibility Stage — Seeker<->Wali directions only this
-- pass (Wali<->Wali is TBC per the source doc itself).
CREATE TABLE journey_family_answers (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id      UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  direction     TEXT NOT NULL CHECK (direction IN ('seeker_to_wali', 'wali_to_seeker')),
  question_id   TEXT NOT NULL,
  answerer_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  answer_text   TEXT NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (match_id, direction, question_id, answerer_id)
);
ALTER TABLE journey_family_answers ENABLE ROW LEVEL SECURITY;
CREATE POLICY journey_family_answers_read ON journey_family_answers FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM matches m WHERE m.id = match_id AND (auth.uid() = m.seeker_a_id OR auth.uid() = m.seeker_b_id))
    OR EXISTS (SELECT 1 FROM wali_links wl JOIN matches m ON m.id = match_id WHERE wl.wali_id = auth.uid() AND wl.status = 'active' AND wl.seeker_id IN (m.seeker_a_id, m.seeker_b_id))
  );
CREATE POLICY journey_family_answers_write ON journey_family_answers FOR INSERT
  WITH CHECK (answerer_id = auth.uid());

-- 8. Suspension (Journey Suspension / Pause-Resume, per
-- JOURNEY_SUSPENSION_CURRENT_VERSION_V1.md). Core mechanics only —
-- notifications and the 30-day auto-end timer need infrastructure
-- (a notification system, a server-side scheduled job) that doesn't
-- exist anywhere in this codebase yet; flagged, not built here.
ALTER TABLE matches ADD COLUMN suspended_by UUID REFERENCES profiles(id);
ALTER TABLE matches ADD COLUMN suspended_at TIMESTAMPTZ;
-- Peer-Suspended (One<->One, only one side suspended): the
-- non-initiator's slot stays occupied per §5.2 of the Suspension spec.
-- Represented as status still 'active' but suspended_by set to the
-- initiator — the non-initiator's match row is a SEPARATE row from
-- the initiator's "Suspended Journeys" view (same match_id, viewed
-- differently per who's asking), so no extra column needed for that
-- distinction beyond suspended_by itself.

CREATE OR REPLACE FUNCTION public.suspend_journey(p_match_id UUID)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  m RECORD;
  caller UUID := auth.uid();
  caller_plan TEXT;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;
  IF m.status <> 'active' THEN RAISE EXCEPTION 'match is not active'; END IF;

  SELECT plan_type INTO caller_plan FROM subscriptions WHERE user_id = caller AND status = 'active';
  IF caller_plan IS DISTINCT FROM 'seeker_premium' THEN
    RAISE EXCEPTION 'suspension_requires_one' USING HINT = 'Journey Suspension requires ZYRA One.';
  END IF;

  UPDATE matches SET suspended_by = caller, suspended_at = NOW() WHERE id = p_match_id;
  UPDATE conversations SET status = 'paused' WHERE match_id = p_match_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.resume_journey(p_match_id UUID)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  m RECORD;
  caller UUID := auth.uid();
  other_id UUID;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR caller <> m.suspended_by THEN
    RAISE EXCEPTION 'only the suspending Seeker may resume';
  END IF;

  other_id := CASE WHEN m.seeker_a_id = caller THEN m.seeker_b_id ELSE m.seeker_a_id END;

  -- Auto-End: if the other Seeker started a new Active Journey while
  -- this one was suspended, resume is not possible (§5.1/§5.3).
  IF EXISTS (
    SELECT 1 FROM matches
    WHERE status = 'active' AND id <> p_match_id
      AND (seeker_a_id = other_id OR seeker_b_id = other_id)
  ) THEN
    UPDATE matches SET status = 'ended', ended_at = NOW() WHERE id = p_match_id;
    RAISE EXCEPTION 'auto_ended' USING HINT = 'The other Seeker started a new Journey while this one was suspended — it has now ended.';
  END IF;

  UPDATE matches SET suspended_by = NULL, suspended_at = NULL WHERE id = p_match_id;
  UPDATE conversations SET status = 'active' WHERE match_id = p_match_id AND status = 'paused';
END;
$function$;

-- Non-initiator (Peer-Suspended, One<->One) may End instead of waiting.
CREATE OR REPLACE FUNCTION public.end_journey(p_match_id UUID)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  m RECORD;
  caller UUID := auth.uid();
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;
  IF m.status = 'ended' THEN RAISE EXCEPTION 'already ended'; END IF;

  UPDATE matches SET status = 'ended', ended_at = NOW(), suspended_by = NULL, suspended_at = NULL WHERE id = p_match_id;
  UPDATE conversations SET status = 'closed', closed_at = NOW() WHERE match_id = p_match_id;
END;
$function$;
