-- OA-ZYRA-159 . Stage 5b -- the batched form, for the Ended Journeys list.
--
-- zyra_may_request_new_journey() answers for ONE pair. The Connections screen
-- draws every ended Journey at once, so calling it per row is N+1 -- the exact
-- pattern this codebase already went out of its way to avoid: CLAUDE.md says
-- "a Family Review override on a LIST needs the batched lookup", and
-- fetchOpenReviewMatchIds exists for no other reason.
--
-- Returns only the match_ids the caller MAY ask on. A row's absence carries no
-- information about why -- cooldown, permanent refusal, block, Tier-1, an
-- active Journey elsewhere and a pending request are all simply "not in the
-- set". Same asymmetry as the single-pair function, preserved in the SHAPE of
-- the result rather than depended on in the caller.

CREATE OR REPLACE FUNCTION public.zyra_may_request_new_journey_ids()
RETURNS SETOF UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  SELECT m.id
    FROM matches m
   WHERE (m.seeker_a_id = (SELECT auth.uid()) OR m.seeker_b_id = (SELECT auth.uid()))
     AND m.status = 'ended'
     AND public.zyra_may_request_new_journey(m.id);
$function$;

REVOKE ALL ON FUNCTION public.zyra_may_request_new_journey_ids() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.zyra_may_request_new_journey_ids() TO authenticated;

COMMENT ON FUNCTION public.zyra_may_request_new_journey_ids() IS
  'OA-ZYRA-159 stage 5b. The ended match_ids on which the caller may request a '
  'new Journey, in one query. Absence carries no reason, by design.';
