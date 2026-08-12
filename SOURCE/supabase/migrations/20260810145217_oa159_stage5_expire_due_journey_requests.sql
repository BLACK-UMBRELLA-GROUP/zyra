-- OA-ZYRA-159 . Stage 5 -- expiry. DR-ZYRA-121 item 8:
--   "unanswered request expires after 14 days; EXPIRY COUNTS AS A DECLINE."
--
-- LAZY, NOT SCHEDULED. There is no cron in this database, and the project
-- already has a pattern for exactly this: resolve_family_review_if_due, which
-- the client calls on load so a review that timed out while nobody was
-- looking still resolves the moment either party opens the screen. Same shape
-- here. When a scheduler exists this function is what it should call -- the
-- logic does not move.
--
-- AN EXPIRY IS INDISTINGUISHABLE FROM A DECLINE. Same request status, same
-- cooldown hold, same notification type, same wording. That is not tidiness:
-- OA-ZYRA-159 makes expiry count as a decline, and if a decline notified
-- while an expiry stayed silent the requester could tell the two apart by
-- watching for silence. Verified byte-identical in the stage-5 test run.
--
-- WHY THE HOLD IS A COOLDOWN AND NEVER PERMANENT: silence is not "don't ask
-- again". Someone who never opened the request has not decided anything, and
-- turning inattention into a permanent bar would put words in their mouth.

CREATE OR REPLACE FUNCTION public.zyra_expire_due_journey_requests(
  p_match_id UUID DEFAULT NULL   -- NULL = sweep everything (for a future job)
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  k_cooldown CONSTANT INTERVAL := INTERVAL '6 months';  -- DR-121 item 16, a guess
  r     RECORD;
  v_cnt INT := 0;
BEGIN
  FOR r IN
    SELECT * FROM journey_requests
     WHERE status = 'pending'
       AND expires_at <= NOW()
       AND (p_match_id IS NULL OR match_id = p_match_id)
     FOR UPDATE SKIP LOCKED
  LOOP
    UPDATE journey_requests
       SET status = 'declined', responded_at = NOW()
     WHERE id = r.id;

    -- Same hold a plain decline creates. ON CONFLICT is not available here --
    -- protection_holds deliberately has no unique key, because holds coexist
    -- (DR-121 item 5) -- so guard on an existing ACTIVE hold instead, or a
    -- second expiry on the same pair would stack a second cooldown and
    -- silently double the wait.
    IF NOT zyra_hold_blocks(r.requested_by, r.requested_to) THEN
      INSERT INTO protection_holds
        (match_id, restricted_id, protected_id, hold_type, appealable, expires_at)
      VALUES (r.match_id, r.requested_by, r.requested_to,
              'decline_cooldown', TRUE, NOW() + k_cooldown);
    END IF;

    -- Byte-identical to the decline notification in
    -- respond_to_journey_request. If you change one, change both -- the whole
    -- design rests on the requester being unable to tell them apart.
    PERFORM create_notification(
      r.requested_by, 'journey_request_declined', 'Journey request',
      'Your request to begin a new Journey was not taken up.', r.match_id);

    v_cnt := v_cnt + 1;
  END LOOP;

  RETURN v_cnt;
END;
$function$;

REVOKE ALL ON FUNCTION public.zyra_expire_due_journey_requests(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.zyra_expire_due_journey_requests(UUID) TO authenticated;

COMMENT ON FUNCTION public.zyra_expire_due_journey_requests(UUID) IS
  'OA-ZYRA-159 stage 5. Expires pending Journey requests past their 14-day '
  'window, treating expiry exactly as a decline -- same status, same 6-month '
  'cooldown, same notification wording. Called lazily by the client on load, '
  'the same pattern as resolve_family_review_if_due. Pass NULL to sweep all.';
