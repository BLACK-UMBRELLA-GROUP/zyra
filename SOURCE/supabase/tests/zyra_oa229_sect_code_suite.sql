-- OA-ZYRA-229 evidence probe. Transactional: leaves all seeded rows unchanged.
-- Green = a hyphenated sect value scores as one fully-green question and the
-- title-case bridge is absent from the live scorer.

BEGIN;

DO $suite$
DECLARE
  viewer_id uuid := '9805470a-d9e6-4e7f-aff1-933031e4aaed';
  measured_score numeric;
  scorer_definition text;
BEGIN
  IF public.zyra_sect_code(' Ahl-e-Hadith ') <> 'ahl-e-hadith' THEN
    RAISE EXCEPTION 'OA-ZYRA-229 canonical code probe failed';
  END IF;

  SELECT pg_get_functiondef('public.score_candidates(uuid[])'::regprocedure)
  INTO scorer_definition;
  IF position('initcap(v_cand.sect)' IN scorer_definition) > 0 THEN
    RAISE EXCEPTION 'OA-ZYRA-229 scorer still contains the title-case bridge';
  END IF;

  UPDATE public.onboarding_answers
  SET ch4_preferences = '{}'::jsonb,
      ch4_hard_requirements = '{}'::jsonb
  WHERE user_id = viewer_id;

  UPDATE public.seeker_details
  SET preferences = jsonb_build_object(
    'sect', jsonb_build_object(
      'matrix', jsonb_build_object('ahl-e-hadith', 'green'),
      'hard_requirement', '[]'::jsonb
    )
  ),
      sect = 'ahl-e-hadith',
      sect_other = 'Ahl-e-Hadith'
  WHERE user_id = viewer_id;

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object('sub', viewer_id)::text,
    true
  );

  SELECT scored.score
  INTO measured_score
  FROM public.score_candidates(ARRAY[viewer_id]) AS scored
  WHERE scored.candidate_id = viewer_id;

  IF measured_score IS DISTINCT FROM 100.0 THEN
    RAISE EXCEPTION
      'OA-ZYRA-229 hyphenated sect score: got %, expected 100.0',
      measured_score;
  END IF;
END
$suite$;

ROLLBACK;
