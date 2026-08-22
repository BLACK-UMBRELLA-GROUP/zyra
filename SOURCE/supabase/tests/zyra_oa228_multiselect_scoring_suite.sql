-- OA-ZYRA-228 evidence probe. Transactional: the synthetic answer changes
-- are rolled back. Green proves a multi-select answer contributes one unit.

BEGIN;

DO $suite$
DECLARE
  viewer_id uuid := '9805470a-d9e6-4e7f-aff1-933031e4aaed';
  one_option_score numeric;
  two_option_score numeric;
BEGIN
  UPDATE public.seeker_details
     SET preferences = '{}'::jsonb
   WHERE user_id = viewer_id;

  UPDATE public.onboarding_answers
     SET ch4_hard_requirements = '{}'::jsonb,
         ch4_preferences = jsonb_build_object(
           'oa228_multi', jsonb_build_object(
             'green_option', 'green',
             'red_option', 'red'
           ),
           'oa228_single', jsonb_build_object('yes', 'green')
         ),
         ch3_answers = jsonb_build_object(
           'oa228_multi', jsonb_build_array('green_option'),
           'oa228_single', 'yes'
         )
   WHERE user_id = viewer_id;

  PERFORM set_config(
    'request.jwt.claims',
    json_build_object('sub', viewer_id)::text,
    true
  );

  SELECT scored.score
    INTO one_option_score
    FROM public.score_candidates(ARRAY[viewer_id]) AS scored
   WHERE scored.candidate_id = viewer_id;

  UPDATE public.onboarding_answers
     SET ch3_answers = jsonb_set(
       ch3_answers,
       '{oa228_multi}',
       '["green_option", "red_option"]'::jsonb
     )
   WHERE user_id = viewer_id;

  SELECT scored.score
    INTO two_option_score
    FROM public.score_candidates(ARRAY[viewer_id]) AS scored
   WHERE scored.candidate_id = viewer_id;

  IF one_option_score IS DISTINCT FROM 100.0 THEN
    RAISE EXCEPTION
      'OA-ZYRA-228 one-option baseline: got %, expected 100.0',
      one_option_score;
  END IF;

  -- One green single-select question plus one multi-select question whose
  -- selected lights average to 0.5: (1 + 0.5) / 2 = 75.0. The old
  -- per-option denominator produced 66.7 here.
  IF two_option_score IS DISTINCT FROM 75.0 THEN
    RAISE EXCEPTION
      'OA-ZYRA-228 one-question-unit score: got %, expected 75.0',
      two_option_score;
  END IF;
END
$suite$;

ROLLBACK;
