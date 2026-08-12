-- OA-ZYRA-159 · Stage 3 of 5 — the request itself. DR-ZYRA-121 item 8.
--
-- "One person requests; the other decides. Never unilateral, never a
--  resurrection — a new attempt starts fresh with its own timeline."
--
-- ONE PENDING REQUEST PER PAIR, enforced by a partial unique index rather
-- than by every caller remembering. Two pending requests on one pair is not a
-- state the product has an answer for: if both people ask at once, whose
-- accept creates the attempt?
--
-- THE OUTCOME IS DELIBERATELY COARSE. The row records 'accepted' or
-- 'declined' and NOT which kind of decline, and not whether the decline was a
-- decision or a 14-day expiry. That distinction lives only in
-- protection_holds, which the requester cannot read
-- (OA-ZYRA-159: "THE REQUESTER IS NEVER TOLD WHICH"). Keeping it out of this
-- table means no future SELECT, view or debug screen can leak it — the safest
-- place for a secret is a table it was never written to.

CREATE TABLE IF NOT EXISTS public.journey_requests (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id      UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  requested_by  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  requested_to  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status        TEXT NOT NULL DEFAULT 'pending',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at    TIMESTAMPTZ NOT NULL,
  responded_at  TIMESTAMPTZ,
  attempt_id    UUID REFERENCES public.journey_attempts(id) ON DELETE SET NULL,

  CONSTRAINT requests_status_known
    CHECK (status = ANY (ARRAY['pending'::TEXT, 'accepted'::TEXT, 'declined'::TEXT])),
  CONSTRAINT requests_not_to_self CHECK (requested_by <> requested_to),
  CONSTRAINT requests_response_matches_status
    CHECK ((status = 'pending') = (responded_at IS NULL)),
  -- An accepted request must name the attempt it produced; a declined one
  -- must not name any. Without this, "accepted" and "nothing happened" are
  -- indistinguishable after the fact.
  CONSTRAINT requests_accepted_has_attempt
    CHECK ((status = 'accepted') = (attempt_id IS NOT NULL))
);

CREATE UNIQUE INDEX IF NOT EXISTS journey_requests_one_pending_per_pair
  ON public.journey_requests (match_id) WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS journey_requests_recipient_idx
  ON public.journey_requests (requested_to) WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS journey_requests_expiry_sweep_idx
  ON public.journey_requests (expires_at) WHERE status = 'pending';

ALTER TABLE public.journey_requests ENABLE ROW LEVEL SECURITY;

-- Both parties may READ their own request. This is the one part of the flow
-- the requester is entitled to see: that they asked, and that it is pending.
-- What they must not see is the SHAPE of a refusal, and there is nothing here
-- to see it in.
--
-- No inline join to journey_attempts anywhere in this policy: that table has
-- RLS on with zero policies, so any policy joining it evaluates false for
-- everyone and silently kills the feature. Learned 2026-08-09; recorded again
-- here because this is exactly the table where it would have happened.
DROP POLICY IF EXISTS journey_requests_select ON public.journey_requests;
CREATE POLICY journey_requests_select ON public.journey_requests
  FOR SELECT TO authenticated
  USING (requested_by = (SELECT auth.uid()) OR requested_to = (SELECT auth.uid()));

-- NO INSERT, UPDATE OR DELETE POLICY, DELIBERATELY.
-- Every write goes through the stage-4 RPCs, which are the only place the
-- cooldown, block, Tier-1 and one-active-Journey checks all run together. A
-- direct INSERT would be a request that skipped every gate.
--
-- NOTE: the anon revoke below was MISSING from the migration as first applied
-- and is corrected in 20260810_oa159_stage3b. Left visible rather than
-- rewritten — see that file.
REVOKE ALL ON public.journey_requests FROM anon;
REVOKE INSERT, UPDATE, DELETE ON public.journey_requests FROM authenticated;
GRANT SELECT ON public.journey_requests TO authenticated;

COMMENT ON TABLE public.journey_requests IS
  'OA-ZYRA-159 / DR-ZYRA-121 item 8. One pending request per pair. Readable by '
  'both parties; writable only through request_new_journey() and '
  'respond_to_journey_request(). status is coarse ON PURPOSE — which kind of '
  'decline, and whether it was a decision or an expiry, is recorded only in '
  'protection_holds, which the requester cannot read.';
