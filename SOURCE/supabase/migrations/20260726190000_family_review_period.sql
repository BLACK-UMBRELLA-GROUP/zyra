-- Family Review Period (#31, OA-31 / WALI_ARCHITECTURE_CURRENT_
-- VERSION_V6.md "FAMILY REVIEW PERIOD"): "After both Seekers complete
-- a Journey stage, the next stage does not unlock immediately.
-- Instead, the Journey enters a 48-hour Family Review Period. Each
-- Wali may Continue (explicitly confirm readiness) or Pause (halt
-- progression until resolved). If neither Wali raises a concern
-- within 48 hours, the Journey automatically continues."
--
-- SCOPE (v1, documented here since the source spec doesn't fully
-- pin these down — see DR-ZYRA-110):
--
--   WHICH TRANSITIONS ARE GATED — only the 4 points where the ritual
--   flow (journey_flow_screen.dart) treats a milestone as "both
--   Seekers complete a stage": phase_1->phase_2, phase_2->phase_3,
--   phase_3->family_stage, family_stage->conversation. NOT applied to
--   compatibility_reveal->salam_exchange, salam_exchange->wali_gate,
--   or wali_gate->phase_1 — those are individual ritual/handshake
--   steps (a single reveal, a single Salam, a single Wali-Gate check),
--   not the enumerated "stages" the spec's Family Review Period
--   section is describing.
--
--   WHO PARTICIPATES — only each Seeker's MAIN Wali (wali_links.
--   is_main=true, status='active'), matching the existing Wali Gate
--   precedent (hasActiveMainWali()). The spec's "Primary Wali" concept
--   (per-Journey authority among several linked Wali Ones) is not
--   modelled anywhere else in this codebase yet and is out of scope
--   here too — every active main Wali on either side may Continue or
--   Pause; there's no multi-Wali-per-seeker tie-breaking logic to
--   build for a v1 where at most one main Wali per seeker exists.
--
--   RESOLUTION — ANY main Wali's Pause halts progression immediately
--   (status='paused', journey_stage does NOT advance). If ALL
--   currently-expected main Walis (i.e. active is_main links for
--   seeker_a and/or seeker_b) have explicitly chosen Continue, the
--   review resolves immediately (no need to wait out the full 48h).
--   Otherwise, resolution is lazy — resolve_family_review_if_due() is
--   called from the client's existing 3-second poll (same pattern
--   already used for compatibility reveal / salam / phase polling;
--   this project has no server-side scheduled-job infrastructure, per
--   the Journey Suspension migration's own note about the 30-day
--   auto-end timer being deferred for the same reason).
--
--   REOPENING A PAUSED REVIEW — the spec says a Pause "means the
--   family needs more time" and "ZYRA support is available to assist
--   if the pause cannot be resolved between both families," but never
--   specifies a resolution mechanic. Rather than invent one the spec
--   doesn't describe, this ships the minimum needed to keep the
--   feature usable end-to-end: any active main Wali on the match may
--   call reopen_family_review() to clear responses and restart a
--   fresh 48h window once the family has actually spoken. This is a
--   deliberate v1 scope choice, not a claim that it's the final
--   product answer.

-- 1. Reviews — at most one 'pending' review per match at a time.
CREATE TABLE journey_family_reviews (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id     UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  from_stage   TEXT NOT NULL,
  to_stage     TEXT NOT NULL,
  opened_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deadline_at  TIMESTAMPTZ NOT NULL,
  status       TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'continued', 'paused')),
  resolved_at  TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX journey_family_reviews_one_pending_per_match
  ON journey_family_reviews(match_id) WHERE status = 'pending';

ALTER TABLE journey_family_reviews ENABLE ROW LEVEL SECURITY;

-- Read: both Seekers on the match, and any active main Wali linked to
-- either of them — same visibility shape as journey_family_answers.
CREATE POLICY journey_family_reviews_read ON journey_family_reviews FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM matches m WHERE m.id = match_id AND (auth.uid() = m.seeker_a_id OR auth.uid() = m.seeker_b_id))
    OR EXISTS (
      SELECT 1 FROM wali_links wl JOIN matches m ON m.id = match_id
      WHERE wl.wali_id = auth.uid() AND wl.status = 'active' AND wl.is_main = TRUE
        AND wl.seeker_id IN (m.seeker_a_id, m.seeker_b_id)
    )
  );
-- No direct INSERT/UPDATE grants — every write happens through the
-- SECURITY DEFINER functions below, same discipline as suspend_journey/
-- resume_journey/end_journey (this is state that must be computed and
-- validated server-side, not client-writable).

-- 2. Per-Wali responses to a review.
CREATE TABLE journey_family_review_responses (
  review_id     UUID NOT NULL REFERENCES journey_family_reviews(id) ON DELETE CASCADE,
  wali_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  decision      TEXT NOT NULL CHECK (decision IN ('continue', 'pause')),
  responded_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (review_id, wali_id)
);

ALTER TABLE journey_family_review_responses ENABLE ROW LEVEL SECURITY;

CREATE POLICY journey_family_review_responses_read ON journey_family_review_responses FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM journey_family_reviews r JOIN matches m ON m.id = r.match_id
      WHERE r.id = review_id AND (auth.uid() = m.seeker_a_id OR auth.uid() = m.seeker_b_id)
    )
    OR EXISTS (
      SELECT 1 FROM journey_family_reviews r JOIN matches m ON m.id = r.match_id
      JOIN wali_links wl ON wl.seeker_id IN (m.seeker_a_id, m.seeker_b_id)
      WHERE r.id = review_id AND wl.wali_id = auth.uid() AND wl.status = 'active' AND wl.is_main = TRUE
    )
  );
-- Writes only via wali_review_decision() below.

-- 3. Open a review — called by the client the moment both Seekers'
-- side of a gated stage completes (mirrors how advanceStage() used to
-- be called directly). Idempotent: if a pending review already exists
-- for this match, returns its id rather than erroring, since both
-- Seekers' clients may race to open it at the same moment.
CREATE OR REPLACE FUNCTION public.open_family_review(p_match_id UUID, p_from_stage TEXT, p_to_stage TEXT)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  m RECORD;
  caller UUID := auth.uid();
  existing_id UUID;
  new_id UUID;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;

  SELECT id INTO existing_id FROM journey_family_reviews
    WHERE match_id = p_match_id AND status = 'pending';
  IF existing_id IS NOT NULL THEN
    RETURN existing_id;
  END IF;

  INSERT INTO journey_family_reviews (match_id, from_stage, to_stage, deadline_at)
    VALUES (p_match_id, p_from_stage, p_to_stage, NOW() + INTERVAL '48 hours')
    RETURNING id INTO new_id;
  RETURN new_id;
END;
$$;

-- 4. A Wali's Continue/Pause decision.
CREATE OR REPLACE FUNCTION public.wali_review_decision(p_review_id UUID, p_decision TEXT)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  r RECORD;
  m RECORD;
  caller UUID := auth.uid();
  is_authorised_wali BOOLEAN;
  expected_count INTEGER;
  continued_count INTEGER;
BEGIN
  IF p_decision NOT IN ('continue', 'pause') THEN
    RAISE EXCEPTION 'invalid decision';
  END IF;

  SELECT * INTO r FROM journey_family_reviews WHERE id = p_review_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'review not found'; END IF;
  IF r.status <> 'pending' THEN RAISE EXCEPTION 'review already resolved'; END IF;

  SELECT * INTO m FROM matches WHERE id = r.match_id;

  SELECT EXISTS (
    SELECT 1 FROM wali_links
    WHERE wali_id = caller AND status = 'active' AND is_main = TRUE
      AND seeker_id IN (m.seeker_a_id, m.seeker_b_id)
  ) INTO is_authorised_wali;
  IF caller IS NULL OR NOT is_authorised_wali THEN
    RAISE EXCEPTION 'not an authorised Wali for this Journey';
  END IF;

  INSERT INTO journey_family_review_responses (review_id, wali_id, decision)
    VALUES (p_review_id, caller, p_decision)
    ON CONFLICT (review_id, wali_id) DO UPDATE SET decision = EXCLUDED.decision, responded_at = NOW();

  IF p_decision = 'pause' THEN
    UPDATE journey_family_reviews SET status = 'paused', resolved_at = NOW() WHERE id = p_review_id;
    RETURN;
  END IF;

  -- Early-resolve on Continue only once every currently-expected main
  -- Wali (across both seekers) has explicitly said Continue. With zero
  -- expected Walis this never early-resolves — it waits for the 48h
  -- deadline instead, same as if the expected Walis stayed silent.
  SELECT COUNT(DISTINCT wali_id) INTO expected_count
    FROM wali_links WHERE status = 'active' AND is_main = TRUE
      AND seeker_id IN (m.seeker_a_id, m.seeker_b_id);

  SELECT COUNT(*) INTO continued_count
    FROM journey_family_review_responses
    WHERE review_id = p_review_id AND decision = 'continue';

  IF expected_count >= 1 AND continued_count >= expected_count THEN
    UPDATE journey_family_reviews SET status = 'continued', resolved_at = NOW() WHERE id = p_review_id;
    UPDATE matches SET journey_stage = r.to_stage WHERE id = r.match_id;
    IF r.to_stage = 'conversation' THEN
      UPDATE conversations SET status = 'active' WHERE match_id = r.match_id;
    END IF;
  END IF;
END;
$$;

-- 5. Lazy timeout resolution — called from the client poll. No-op if
-- there's no pending review, or the deadline hasn't passed yet.
CREATE OR REPLACE FUNCTION public.resolve_family_review_if_due(p_match_id UUID)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  r RECORD;
  caller UUID := auth.uid();
  m RECORD;
  is_party BOOLEAN;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RETURN; END IF;

  is_party := caller IS NOT NULL AND (caller = m.seeker_a_id OR caller = m.seeker_b_id);
  IF NOT is_party AND NOT EXISTS (
    SELECT 1 FROM wali_links WHERE wali_id = caller AND status = 'active' AND is_main = TRUE
      AND seeker_id IN (m.seeker_a_id, m.seeker_b_id)
  ) THEN
    RETURN; -- silently do nothing for an unrelated caller
  END IF;

  SELECT * INTO r FROM journey_family_reviews
    WHERE match_id = p_match_id AND status = 'pending' AND deadline_at <= NOW();
  IF NOT FOUND THEN RETURN; END IF;

  UPDATE journey_family_reviews SET status = 'continued', resolved_at = NOW() WHERE id = r.id;
  UPDATE matches SET journey_stage = r.to_stage WHERE id = r.match_id;
  IF r.to_stage = 'conversation' THEN
    UPDATE conversations SET status = 'active' WHERE match_id = r.match_id;
  END IF;
END;
$$;

-- 6. Reopen a paused review — v1's answer to "the family needs more
-- time [then changes their mind]" (see scope note above). Any
-- currently-active main Wali on the match may call this once the
-- families have actually resolved their concern outside the app.
CREATE OR REPLACE FUNCTION public.reopen_family_review(p_review_id UUID)
RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  r RECORD;
  m RECORD;
  caller UUID := auth.uid();
  is_authorised_wali BOOLEAN;
BEGIN
  SELECT * INTO r FROM journey_family_reviews WHERE id = p_review_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'review not found'; END IF;
  IF r.status <> 'paused' THEN RAISE EXCEPTION 'review is not paused'; END IF;

  SELECT * INTO m FROM matches WHERE id = r.match_id;
  SELECT EXISTS (
    SELECT 1 FROM wali_links
    WHERE wali_id = caller AND status = 'active' AND is_main = TRUE
      AND seeker_id IN (m.seeker_a_id, m.seeker_b_id)
  ) INTO is_authorised_wali;
  IF caller IS NULL OR NOT is_authorised_wali THEN
    RAISE EXCEPTION 'not an authorised Wali for this Journey';
  END IF;

  DELETE FROM journey_family_review_responses WHERE review_id = p_review_id;
  UPDATE journey_family_reviews
    SET status = 'pending', opened_at = NOW(), deadline_at = NOW() + INTERVAL '48 hours', resolved_at = NULL
    WHERE id = p_review_id;
END;
$$;
