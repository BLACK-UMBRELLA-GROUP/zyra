-- APPLIED LIVE 2026-08-08, version 20260808135019.
-- OA-ZYRA-156 stage 4e · STEP 2. Authorised by DR-ZYRA-122.
--
-- Re-points the four Family Review RPCs onto journey_attempts.
-- "No rule changes": every authorisation test is character-for-character
-- the one it replaces. Only the KEY changes.
--
-- SIGNATURES UNCHANGED, deliberately — step 1 (Dart resolves the attempt)
-- has not landed and cannot until `flutter analyze` can be run. This step
-- is therefore purely server-side and verifiable on its own, which is
-- what makes it safe to stop after.
--
-- The READ path was already here: journey_family_reviews_read and
-- journey_family_review_responses_read both join
-- zyra_my_attempt_participation on ATTEMPT_ID. The policies were
-- re-pointed; the functions were not. This closes that gap.
--
-- ALSO FIXED, in scope: these functions wrote journey_stage to `matches`
-- only, so the copy on journey_attempts drifted from the first transition
-- onward. Raised 2026-08-08 and left out of zyra_advance_stage(), which
-- owns only its own writes. These are its writes. matches stays
-- authoritative until step 7; both copies now move together.

create unique index if not exists journey_family_reviews_one_pending_per_attempt
  on public.journey_family_reviews (attempt_id) where status = 'pending';

create or replace function public.open_family_review(p_match_id uuid, p_from_stage text, p_to_stage text)
 returns uuid language plpgsql security definer set search_path to 'public'
as $function$
DECLARE m RECORD; caller UUID := auth.uid(); v_attempt UUID; existing_id UUID; new_id UUID;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match not found'; END IF;
  IF caller IS NULL OR (caller <> m.seeker_a_id AND caller <> m.seeker_b_id) THEN
    RAISE EXCEPTION 'not a party to this match';
  END IF;
  -- Same selection rule as zyra_set_attempt_from_match(), stated here
  -- because attempt_id is now written explicitly, not left to the trigger.
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id
   ORDER BY (a.status = 'active') DESC, a.attempt_number DESC LIMIT 1;
  IF v_attempt IS NULL THEN RAISE EXCEPTION 'no_attempt_for_match'; END IF;
  -- Idempotency keyed on the ATTEMPT. Identical today; correct once a
  -- pair can have several.
  SELECT id INTO existing_id FROM journey_family_reviews
   WHERE attempt_id = v_attempt AND status = 'pending';
  IF existing_id IS NOT NULL THEN RETURN existing_id; END IF;
  INSERT INTO journey_family_reviews (match_id, attempt_id, from_stage, to_stage, deadline_at)
    VALUES (p_match_id, v_attempt, p_from_stage, p_to_stage, NOW() + INTERVAL '48 hours')
    RETURNING id INTO new_id;
  RETURN new_id;
END; $function$;

create or replace function public.wali_review_decision(p_review_id uuid, p_decision text)
 returns void language plpgsql security definer set search_path to 'public'
as $function$
DECLARE r RECORD; m RECORD; caller UUID := auth.uid();
        is_authorised_wali BOOLEAN; expected_count INTEGER; continued_count INTEGER;
BEGIN
  IF p_decision NOT IN ('continue','pause') THEN RAISE EXCEPTION 'invalid decision'; END IF;
  SELECT * INTO r FROM journey_family_reviews WHERE id = p_review_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'review not found'; END IF;
  IF r.status <> 'pending' THEN RAISE EXCEPTION 'review already resolved'; END IF;
  -- Single path, loudly (I3). A review with no attempt is a broken row,
  -- not a case to route around with a second match_id path that would
  -- outlive step 7.
  IF r.attempt_id IS NULL THEN RAISE EXCEPTION 'review_has_no_attempt'; END IF;
  SELECT mm.* INTO m FROM journey_attempts a JOIN matches mm ON mm.id = a.match_id
   WHERE a.id = r.attempt_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'attempt not found'; END IF;
  SELECT EXISTS (SELECT 1 FROM wali_links
    WHERE wali_id = caller AND status='active' AND is_main = TRUE
      AND seeker_id IN (m.seeker_a_id, m.seeker_b_id)) INTO is_authorised_wali;
  IF caller IS NULL OR NOT is_authorised_wali THEN
    RAISE EXCEPTION 'not an authorised Wali for this Journey'; END IF;
  INSERT INTO journey_family_review_responses (review_id, wali_id, decision)
    VALUES (p_review_id, caller, p_decision)
    ON CONFLICT (review_id, wali_id) DO UPDATE SET decision=EXCLUDED.decision, responded_at=NOW();
  IF p_decision = 'pause' THEN
    UPDATE journey_family_reviews SET status='paused', resolved_at=NOW() WHERE id=p_review_id;
    RETURN;
  END IF;
  -- UNCHANGED counting rule. Its behaviour when one side holds no Main
  -- Guardian is OA-ZYRA-173 — raised, deliberately not altered here.
  SELECT COUNT(DISTINCT wali_id) INTO expected_count FROM wali_links
   WHERE status='active' AND is_main = TRUE AND seeker_id IN (m.seeker_a_id, m.seeker_b_id);
  SELECT COUNT(*) INTO continued_count FROM journey_family_review_responses
   WHERE review_id = p_review_id AND decision='continue';
  IF expected_count >= 1 AND continued_count >= expected_count THEN
    UPDATE journey_family_reviews SET status='continued', resolved_at=NOW() WHERE id=p_review_id;
    UPDATE matches          SET journey_stage = r.to_stage WHERE id = m.id;
    UPDATE journey_attempts SET journey_stage = r.to_stage WHERE id = r.attempt_id;
    IF r.to_stage = 'conversation' THEN
      UPDATE conversations SET status='active' WHERE attempt_id = r.attempt_id;
    END IF;
  END IF;
END; $function$;

create or replace function public.resolve_family_review_if_due(p_match_id uuid)
 returns void language plpgsql security definer set search_path to 'public'
as $function$
DECLARE r RECORD; caller UUID := auth.uid(); m RECORD; v_attempt UUID; is_party BOOLEAN;
BEGIN
  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RETURN; END IF;
  is_party := caller IS NOT NULL AND (caller = m.seeker_a_id OR caller = m.seeker_b_id);
  IF NOT is_party AND NOT EXISTS (SELECT 1 FROM wali_links
      WHERE wali_id = caller AND status='active' AND is_main = TRUE
        AND seeker_id IN (m.seeker_a_id, m.seeker_b_id)) THEN RETURN; END IF;
  SELECT a.id INTO v_attempt FROM journey_attempts a
   WHERE a.match_id = p_match_id
   ORDER BY (a.status='active') DESC, a.attempt_number DESC LIMIT 1;
  IF v_attempt IS NULL THEN RETURN; END IF;
  SELECT * INTO r FROM journey_family_reviews
   WHERE attempt_id = v_attempt AND status='pending' AND deadline_at <= NOW();
  IF NOT FOUND THEN RETURN; END IF;
  UPDATE journey_family_reviews SET status='continued', resolved_at=NOW() WHERE id=r.id;
  UPDATE matches          SET journey_stage = r.to_stage WHERE id = p_match_id;
  UPDATE journey_attempts SET journey_stage = r.to_stage WHERE id = v_attempt;
  IF r.to_stage = 'conversation' THEN
    UPDATE conversations SET status='active' WHERE attempt_id = v_attempt;
  END IF;
END; $function$;

create or replace function public.reopen_family_review(p_review_id uuid)
 returns void language plpgsql security definer set search_path to 'public'
as $function$
DECLARE r RECORD; m RECORD; caller UUID := auth.uid(); is_authorised_wali BOOLEAN;
BEGIN
  SELECT * INTO r FROM journey_family_reviews WHERE id = p_review_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'review not found'; END IF;
  IF r.status <> 'paused' THEN RAISE EXCEPTION 'review is not paused'; END IF;
  IF r.attempt_id IS NULL THEN RAISE EXCEPTION 'review_has_no_attempt'; END IF;
  SELECT mm.* INTO m FROM journey_attempts a JOIN matches mm ON mm.id = a.match_id
   WHERE a.id = r.attempt_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'attempt not found'; END IF;
  SELECT EXISTS (SELECT 1 FROM wali_links
    WHERE wali_id = caller AND status='active' AND is_main = TRUE
      AND seeker_id IN (m.seeker_a_id, m.seeker_b_id)) INTO is_authorised_wali;
  IF caller IS NULL OR NOT is_authorised_wali THEN
    RAISE EXCEPTION 'not an authorised Wali for this Journey'; END IF;
  DELETE FROM journey_family_review_responses WHERE review_id = p_review_id;
  UPDATE journey_family_reviews
    SET status='pending', opened_at=NOW(), deadline_at=NOW()+INTERVAL '48 hours', resolved_at=NULL
   WHERE id = p_review_id;
END; $function$;

revoke execute on function public.open_family_review(uuid,text,text) from public, anon;
revoke execute on function public.wali_review_decision(uuid,text)    from public, anon;
revoke execute on function public.resolve_family_review_if_due(uuid) from public, anon;
revoke execute on function public.reopen_family_review(uuid)         from public, anon;
grant  execute on function public.open_family_review(uuid,text,text) to authenticated;
grant  execute on function public.wali_review_decision(uuid,text)    to authenticated;
grant  execute on function public.resolve_family_review_if_due(uuid) to authenticated;
grant  execute on function public.reopen_family_review(uuid)         to authenticated;

-- VERIFIED 2026-08-08, 18/18: review opens with attempt_id written
-- explicitly; second open is idempotent on the ATTEMPT; stranger and
-- ADDITIONAL Guardian both refused; one of two Mains leaves it pending;
-- both Mains continue it; matches AND journey_attempts advance together;
-- pause holds; reopen restores pending and clears prior responses; a due
-- review auto-continues and moves both copies; conversation opens via
-- attempt_id; an orphan review raises review_has_no_attempt rather than
-- silently falling back to match_id.
