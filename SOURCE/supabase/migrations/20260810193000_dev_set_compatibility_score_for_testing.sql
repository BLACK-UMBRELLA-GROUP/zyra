-- DEV ONLY · force a Compatibility Reveal result.
--
-- Founder request 2026-08-10: "you have good reveal and bad reveal — one is
-- 21% and one is 92%."
--
-- WHY AN OVERRIDE AND NOT REAL DATA. After the 2026-08-10 backfills every
-- seeded profile scores between 77 and 100 against every other, because they
-- all carry similar synthetic answers. A genuine 21% is not reachable without
-- hand-building an incompatible profile, and even then the number would not be
-- controllable. Testing how a LOW result READS matters as much as a high one.
--
-- THIS IS THE TENTH DEV RPC. OA-ZYRA-184 is the list; drop it before launch
-- with the other nine.
--
-- Sets BOTH reveal flags: a forced score with only one flag would land on the
-- Plus-early screen rather than the mutual one, which is a different state and
-- not what the toggle is for.
CREATE OR REPLACE FUNCTION public.zyra_dev_set_compatibility(
  p_match_id uuid,
  p_score    numeric
)
RETURNS numeric
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  caller  UUID := (SELECT auth.uid());
  v_email TEXT;
  m       RECORD;
  v_cats  JSONB;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'not_signed_in';
  END IF;

  SELECT email INTO v_email FROM auth.users WHERE id = caller;
  IF v_email IS NULL OR v_email NOT LIKE '%@zyra.test' THEN
    RAISE EXCEPTION 'dev_only'
      USING HINT = 'Forcing a compatibility score is limited to seeded @zyra.test accounts.';
  END IF;

  IF p_score < 0 OR p_score > 100 THEN
    RAISE EXCEPTION 'score_out_of_range' USING HINT = '0 to 100.';
  END IF;

  SELECT * INTO m FROM matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'match_not_found'; END IF;
  IF caller <> m.seeker_a_id AND caller <> m.seeker_b_id THEN
    RAISE EXCEPTION 'not_a_party';
  END IF;

  -- Spread around the overall rather than five copies of it, so the screen
  -- shows something shaped like a real breakdown. Clamped, so 92 does not
  -- produce a 107% row.
  v_cats := jsonb_build_object(
    'Deen',                least(100, greatest(0, p_score + 7)),
    'Marriage Goals',      least(100, greatest(0, p_score + 3)),
    'Communication',       least(100, greatest(0, p_score - 4)),
    'Lifestyle',           least(100, greatest(0, p_score - 9)),
    'Family Expectations', least(100, greatest(0, p_score + 1))
  );

  INSERT INTO journey_compatibility (match_id) VALUES (p_match_id)
  ON CONFLICT (match_id) DO NOTHING;

  UPDATE journey_compatibility
     SET overall_score      = p_score,
         category_scores    = v_cats,
         seeker_a_revealed  = TRUE,
         seeker_b_revealed  = TRUE,
         revealed_at        = now()
   WHERE match_id = p_match_id;

  RETURN p_score;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.zyra_dev_set_compatibility(uuid, numeric) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.zyra_dev_set_compatibility(uuid, numeric) TO authenticated;

-- VERIFIED 10/10, 2026-08-10: low and high both store; both reveal flags set
-- so it lands on the mutual screen; five distinct category values, none below
-- 0 or above 100; out-of-range refused; a non-party refused; and the real
-- score path still computes for the same pair.
