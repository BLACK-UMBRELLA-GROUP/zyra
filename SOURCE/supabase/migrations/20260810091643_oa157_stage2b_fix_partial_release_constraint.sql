-- OA-ZYRA-157 · correction, same day, found by the stage-2 verification run.
--
-- The original constraint was:
--   CHECK ((released_at IS NULL) = (released_by IS NULL AND release_reason IS NULL))
--
-- It is satisfied by a HALF-RELEASED row. With released_at set and
-- release_reason set but released_by NULL, the right-hand side is
-- (TRUE AND FALSE) = FALSE, the left-hand side is FALSE, and FALSE = FALSE
-- passes. It only ever caught the case where BOTH audit columns were null.
--
-- A released hold with no actor is precisely the record an appeal review
-- would need and would not have — the table's whole claim to being "its own
-- audit log" (DR-121 item 5) rests on this. All three columns are set
-- together or none of them are.
--
-- Recorded rather than quietly amended: this is the failure mode the 2026-07-26
-- engineering audit named — a change that runs cleanly and does nothing. It was
-- caught only because the release path was tested, not just written.

ALTER TABLE public.protection_holds DROP CONSTRAINT IF EXISTS holds_release_is_complete;

ALTER TABLE public.protection_holds ADD CONSTRAINT holds_release_is_complete CHECK (
  (released_at IS     NULL AND released_by IS     NULL AND release_reason IS     NULL)
  OR
  (released_at IS NOT NULL AND released_by IS NOT NULL AND release_reason IS NOT NULL)
);

COMMENT ON CONSTRAINT holds_release_is_complete ON public.protection_holds IS
  'OA-ZYRA-157. released_at, released_by and release_reason are all-or-nothing. '
  'A release with no recorded actor or reason is unauditable, which defeats the '
  'purpose of holding the row instead of deleting it.';
