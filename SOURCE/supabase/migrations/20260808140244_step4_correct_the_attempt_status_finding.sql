-- APPLIED LIVE 2026-08-08, version 20260808140244.
-- Correction to step 4's header, caught by step 4's own test.
--
-- I wrote "an attempt's status is NEVER 'active'". Too absolute, and the
-- suite proved it: an attempt created from a match that is ALREADY active
-- inherits 'active' from zyra_create_first_attempt(), so a mirrored pause
-- was accepted in a test that built the match directly rather than
-- through the product's own path.
--
-- Re-tested against the REAL path — match born 'potential' via
-- create_match_on_mutual_like(), then promoted — 6/6:
--   attempt status at creation ...................... potential
--   match status after promote ...................... active
--   ATTEMPT status after promote .................... potential  <-- finding
--   mirroring pause after a real promote ............ rejected by
--                                        attempts_pause_needs_active
--   per-person trigger on attempts able to fire ..... false
--
-- Accurate statement: promote_journey_to_active() does not touch
-- journey_attempts at all, so on any Journey that reached 'active' the
-- normal way the attempt is still 'potential'. Step 5 fixes it.

comment on function public.suspend_journey(uuid) is
  'Pause state lives on matches.suspended_by. journey_attempts.paused_by '
  'is deliberately NOT mirrored: promote_journey_to_active() never updates '
  'the attempt''s status, so on a real Journey the attempt is still '
  '''potential'' and attempts_pause_needs_active rejects the write. '
  'Measured 2026-08-08. Step 5 (rewrite promote) unblocks it.';

comment on function public.resume_journey(uuid) is
  'Reads Active-Journey state from matches, not journey_attempts — an '
  'attempt promoted the normal way is still ''potential'', so the attempt '
  'copy would return nothing. Moves at step 5/7.';

comment on function public.zyra_enforce_one_active_attempt() is
  'INERT ON THE REAL PATH as of 2026-08-08. Fires only AFTER UPDATE OF '
  'status to ''active'', and promote_journey_to_active() never sets an '
  'attempt''s status. zyra_enforce_one_active_match() on `matches` carries '
  'the invariant until step 5 maintains attempt status. Do not delete this '
  'one — it becomes the enforcement point at step 7.';
