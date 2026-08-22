-- OA-ZYRA-204: real Journey rows expose whether the OTHER party currently
-- holds an unsuspended Active Journey with a third person.

CREATE OR REPLACE FUNCTION public.zyra_journey_busy_flags(p_match_ids uuid[])
RETURNS TABLE(match_id uuid, in_another_journey boolean)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT
    requested.id AS match_id,
    EXISTS (
      SELECT 1
      FROM public.matches AS other_match
      WHERE other_match.id <> requested.id
        AND other_match.status = 'active'
        AND other_match.suspended_by IS NULL
        AND other_match.also_paused_by IS NULL
        AND (
          other_match.seeker_a_id = CASE
            WHEN requested.seeker_a_id = auth.uid()
              THEN requested.seeker_b_id
            ELSE requested.seeker_a_id
          END
          OR other_match.seeker_b_id = CASE
            WHEN requested.seeker_a_id = auth.uid()
              THEN requested.seeker_b_id
            ELSE requested.seeker_a_id
          END
        )
        AND auth.uid() NOT IN (
          other_match.seeker_a_id,
          other_match.seeker_b_id
        )
    ) AS in_another_journey
  FROM public.matches AS requested
  WHERE requested.id = ANY(COALESCE(p_match_ids, '{}'::uuid[]))
    AND auth.uid() IN (requested.seeker_a_id, requested.seeker_b_id);
$function$;

REVOKE ALL ON FUNCTION public.zyra_journey_busy_flags(uuid[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.zyra_journey_busy_flags(uuid[]) TO authenticated;

COMMENT ON FUNCTION public.zyra_journey_busy_flags(uuid[]) IS
  'For requested Journey rows owned by auth.uid(), returns whether the other party has a different unsuspended active match. OA-ZYRA-204.';

