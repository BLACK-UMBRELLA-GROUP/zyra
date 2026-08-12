-- OA-ZYRA-159 · Stage 1 of 5. Founder-approved 2026-08-10 (option B).
--
-- D2 from the implementation plan. notifications_type_check permitted four
-- types only. A journey-request notification would have thrown at runtime —
-- the same shape as contradiction-audit finding 4.9, where the one actionable
-- Guardian prompt could never fire because the code wrote a status the CHECK
-- forbade. Extending the constraint BEFORE the first write, not after.
--
-- ONE decline type on purpose. OA-ZYRA-159: "THE REQUESTER IS NEVER TOLD
-- WHICH — both render identically as no option to request." A single
-- notification type makes that structural rather than a discipline: there is
-- no column in which the difference could leak, so no future caller can leak
-- it by accident. Expiry emits this same type for the same reason — if a
-- decline notified and an expiry stayed silent, the requester could tell the
-- two apart, and OA-159 makes expiry count as a decline.

ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications ADD CONSTRAINT notifications_type_check
  CHECK (type = ANY (ARRAY[
    'new_match',
    'new_message',
    'wali_request',
    'journey_ended',
    'journey_request',           -- to the recipient: someone asks to begin again
    'journey_request_accepted',  -- to the requester: a new attempt now exists
    'journey_request_declined'   -- to the requester: declined OR expired, indistinguishable
  ]));

COMMENT ON CONSTRAINT notifications_type_check ON public.notifications IS
  'OA-ZYRA-159. journey_request_declined covers a plain decline, a permanent '
  '"don''t ask again", and a 14-day expiry alike — the requester must not be '
  'able to distinguish them (DR-ZYRA-121 item 8).';
