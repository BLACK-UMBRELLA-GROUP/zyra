-- Founder decision 2026-08-10: seed Chapter 3/4 fully, "clearly labelled".
--
-- This is the label. Chapter 2's backfill could be checked against a census;
-- Chapter 3 is VALUES — there is no external distribution for "how involved
-- should your parents be during your marriage". Seeded answers there are a
-- plausible invention, and anything tuned against them is tuned against an
-- invention. The flag exists so that can never be forgotten by anyone reading
-- a score.
--
-- BLOCKING FOR PUBLIC LAUNCH, same class as the dev RPCs in OA-ZYRA-184:
-- every synthetic row must be deleted before real Seekers exist, or a real
-- person will be matched against fiction. Tracked as OA-ZYRA-190.
--
-- Both columns default FALSE, so a real Seeker can never be caught by the
-- launch sweep.
ALTER TABLE public.onboarding_answers
  ADD COLUMN IF NOT EXISTS is_synthetic boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.onboarding_answers.is_synthetic IS
  'TRUE for seeded test data, never for a real Seeker. Chapter 3 answers are '
  'values, not demographics — there is no census to check them against, so '
  'any engine tuned on these rows is tuned on an invention. DELETE ALL '
  'is_synthetic ROWS BEFORE PUBLIC LAUNCH (see OA-ZYRA-190).';

CREATE INDEX IF NOT EXISTS onboarding_answers_synthetic_idx
  ON public.onboarding_answers (is_synthetic) WHERE is_synthetic;

ALTER TABLE public.seeker_details
  ADD COLUMN IF NOT EXISTS is_synthetic boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.seeker_details.is_synthetic IS
  'TRUE for seeded test data. Chapter 2 was backfilled 2026-08-10 to the real '
  'UK distribution (Census 2021 + Techne/IIFL) — checkable, but still not real '
  'people. Delete alongside onboarding_answers.is_synthetic before launch.';

UPDATE public.seeker_details SET is_synthetic = true;
