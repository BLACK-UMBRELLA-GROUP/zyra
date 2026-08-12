-- DEV ONLY — set the OTHER party's Compatibility Reveal flag.
-- Founder request 2026-08-10: the stage panel needs "other user has revealed
-- compatibility, and other user hasn't", because the reveal is a two-sided
-- gate and one person cannot test both sides of it alone.
--
-- ⚠️ Same guard, same removal list, same warnings as
-- zyra_dev_set_journey_stage — OA-ZYRA-184 now covers EIGHT functions, not
-- seven. Update that entry when this lands.
--
-- WHY A SERVER FUNCTION AND NOT A CLIENT WRITE: journey_compatibility's
-- policies let a Seeker set their OWN flag. Setting the counterpart's is
-- exactly the thing the policy exists to prevent — contradiction-audit 2.5
-- ("either Seeker can set both flags: consent given on someone else's
-- behalf") is an OPEN finding about this very column pair. This function does
-- not weaken that policy; it sits beside it, behind the @zyra.test guard, so
-- the fix for 2.5 can still be a WITH CHECK without breaking testing.
--
-- IT DOES NOT COMPUTE THE SCORE. Deliberately. Scoring runs on the real
-- reveal path, so the correct test is: set the counterpart revealed here,
-- then press Reveal in the app and watch the real code run. A dev function
-- that also scored would be testing itself.

CREATE OR REPLACE FUNCTION public.zyra_dev_set_counterpart_reveal(
  p_match_id UUID,
  p_revealed BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  caller  UUID := (SELECT auth.uid());
  v_email TEXT;
  m       RECORD;
  v_col   TEXT;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Counterpart reveal is limited to seeded @zyra.test accounts.';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;

  -- The COUNTERPART's column, never the caller's. If the caller is A we set
  -- B, and the other way round. Getting this backwards would make the toggle
  -- silently set your own flag and look like it worked. Verified both ways
  -- round against the live database, 2026-08-10.
  v_col := CASE WHEN caller = m.seeker_a_id
                THEN 'seeker_b_revealed' ELSE 'seeker_a_revealed' END;

  INSERT INTO journey_compatibility (match_id) VALUES (p_match_id)
  ON CONFLICT (match_id) DO NOTHING;

  EXECUTE format('UPDATE journey_compatibility SET %I = $1 WHERE match_id = $2', v_col)
    USING p_revealed, p_match_id;

  RETURN p_revealed;
END;
$function$;

REVOKE ALL ON FUNCTION public.zyra_dev_set_counterpart_reveal(UUID, BOOLEAN) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.zyra_dev_set_counterpart_reveal(UUID, BOOLEAN) FROM anon;
GRANT EXECUTE ON FUNCTION public.zyra_dev_set_counterpart_reveal(UUID, BOOLEAN) TO authenticated;

COMMENT ON FUNCTION public.zyra_dev_set_counterpart_reveal(UUID, BOOLEAN) IS
  'DEV ONLY. Sets the counterpart''s Compatibility Reveal flag so one tester '
  'can exercise both sides of a two-sided gate. Guarded server-side on '
  '@zyra.test. DROP BEFORE PUBLIC LAUNCH — OA-ZYRA-184.';
