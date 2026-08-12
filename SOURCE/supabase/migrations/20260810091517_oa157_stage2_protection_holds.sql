-- OA-ZYRA-157 · protection_holds. DR-ZYRA-121 item 5, Founder-approved
-- 2026-08-06; build authorised 2026-08-10 as stage 2 of the OA-159 plan.
--
-- "Protection is the result of one or more active holds, which allows holds
--  to coexist, allows an appeal to release one without disturbing another,
--  and makes the table its own audit log. A SAFETY HOLD IS NEVER APPEALABLE,
--  because the barred person must never learn it exists."
--
-- DIRECTIONAL, not pair-symmetric. A decline cooldown restricts the person
-- who asked, not the person who declined — the decliner may still ask later,
-- and forbidding that would punish them for saying no. A mutual bar (a safety
-- ending) is simply two rows. One shape composes; a `mutual` flag would need
-- every reader to remember to check it.
--
-- match_id IS the pair. matches is the permanent one-row-per-pair record
-- (DR-121 item 2) with seeker_a_id < seeker_b_id enforced, so it is the only
-- stable pair identity in the schema.
--
-- RELEASE, NEVER DELETE. released_at is set; the row stays. That is what
-- "its own audit log" means, and why an appeal outcome stays reconstructable
-- without a separate event table (OA-163 stays scoped, not comprehensive).

CREATE TABLE IF NOT EXISTS public.protection_holds (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id       UUID NOT NULL REFERENCES public.matches(id) ON DELETE CASCADE,
  restricted_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  protected_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  hold_type      TEXT NOT NULL,
  appealable     BOOLEAN NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at     TIMESTAMPTZ,          -- NULL = does not expire
  released_at    TIMESTAMPTZ,
  released_by    UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  release_reason TEXT,

  CONSTRAINT holds_type_known CHECK (hold_type = ANY (ARRAY[
    'decline_cooldown'::TEXT,    -- plain decline: expires (OA-159, 6 months)
    'decline_permanent'::TEXT,   -- "don't ask again": never expires
    'safety'::TEXT,              -- safety ending (DR-121 item 7)
    'moderation'::TEXT           -- moderator action
  ])),

  -- DR-121 item 5, stated as a constraint rather than a convention.
  CONSTRAINT holds_safety_is_never_appealable
    CHECK (hold_type <> 'safety' OR appealable = FALSE),

  -- A permanent hold that expires is a contradiction; a cooldown that never
  -- does is an accidental permanent bar. Both are caught here rather than in
  -- whichever caller forgot.
  CONSTRAINT holds_permanent_never_expires
    CHECK (hold_type <> 'decline_permanent' OR expires_at IS NULL),
  CONSTRAINT holds_cooldown_must_expire
    CHECK (hold_type <> 'decline_cooldown' OR expires_at IS NOT NULL),

  CONSTRAINT holds_no_self_hold CHECK (restricted_id <> protected_id),

  -- SUPERSEDED IN 20260810091643 — this version passes a half-released row.
  -- Left here so the migration history shows the defect and its correction
  -- rather than a clean line that never happened.
  CONSTRAINT holds_release_is_complete
    CHECK ((released_at IS NULL) = (released_by IS NULL AND release_reason IS NULL))
);

CREATE INDEX IF NOT EXISTS protection_holds_active_idx
  ON public.protection_holds (restricted_id, protected_id)
  WHERE released_at IS NULL;

CREATE INDEX IF NOT EXISTS protection_holds_match_idx
  ON public.protection_holds (match_id);

-- RLS ON, ZERO POLICIES, BY DESIGN.
--
-- Same posture as journey_attempts, and here it is the point rather than an
-- oversight: a hold must be invisible to the person it restricts. If the
-- barred person could read this table they would learn a safety hold exists,
-- which DR-121 item 5 forbids in those words, and they could tell a 6-month
-- cooldown from a permanent one, which OA-159 forbids. Nothing reads it
-- directly — everything goes through zyra_hold_blocks() below.
--
-- Recorded because a session reading "RLS on, no policies" as a defect would
-- be about to reintroduce the exact leak the table exists to prevent.
ALTER TABLE public.protection_holds ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.protection_holds FROM anon, authenticated;

COMMENT ON TABLE public.protection_holds IS
  'OA-ZYRA-157 / DR-ZYRA-121 item 5. Directional bars between two people on a pair. '
  'Active = released_at IS NULL AND (expires_at IS NULL OR expires_at > now()). '
  'RLS on with no policies DELIBERATELY: a hold must be unreadable by the person '
  'it restricts. Read it only through zyra_hold_blocks().';


-- The single question every caller asks: may this person act toward that one?
-- SECURITY DEFINER because the table is deliberately unreadable; STABLE so it
-- can be used inside a policy without re-evaluating per row.
CREATE OR REPLACE FUNCTION public.zyra_hold_blocks(p_restricted UUID, p_protected UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.protection_holds h
     WHERE h.restricted_id = p_restricted
       AND h.protected_id  = p_protected
       AND h.released_at IS NULL
       AND (h.expires_at IS NULL OR h.expires_at > NOW())
  );
$$;

-- Returns a boolean and nothing else. A caller cannot learn WHICH hold, when
-- it was created, or when it lifts — so nothing built on this can leak the
-- distinction OA-159 requires to stay hidden.
REVOKE ALL ON FUNCTION public.zyra_hold_blocks(UUID, UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.zyra_hold_blocks(UUID, UUID) FROM anon;
REVOKE ALL ON FUNCTION public.zyra_hold_blocks(UUID, UUID) FROM authenticated;

COMMENT ON FUNCTION public.zyra_hold_blocks(UUID, UUID) IS
  'OA-ZYRA-157. True if an active hold restricts p_restricted toward p_protected. '
  'Boolean only, by design — the reason and the expiry must never reach the '
  'restricted person. EXECUTE withheld from authenticated: server-side callers only.';
