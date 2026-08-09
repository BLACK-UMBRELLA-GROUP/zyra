-- AUDIT FINDING 2.10 — delete_own_account died with a raw FK violation
-- for anyone who had ever ACCEPTED a Guardian invite.
--
-- delete_own_account() does exactly two things: remove the caller's photo
-- objects, then DELETE FROM auth.users. Everything else is left to FK
-- cascades. 68 of 70 FKs referencing profiles/auth.users cascade or set
-- null. wali_invites.accepted_by was ON DELETE NO ACTION, and the invite
-- row belongs to the INVITER, so it survives the accepter and holds a
-- reference to a person who is trying to leave.
--
-- Reproduced 2026-08-09, rolled back:
--   update or delete on table "profiles" violates foreign key constraint
--   "wali_invites_accepted_by_fkey" on table "wali_invites"
-- A control account with no accepted invite deleted cleanly.
--
-- This is a right-to-erasure failure. It surfaces as an unexplained
-- failure, and zyra_auth.dart's own doc comment states the opposite —
-- that deletion "cascades through every table that references it ... see
-- 20260726170000_delete_own_account.sql for the full verified list."
-- After this migration that sentence is true again.
--
-- ── SET NULL, NOT CASCADE. Cascade would delete the invite row, which is
-- the INVITER's record, not the accepter's. One person leaving must not
-- erase another person's history. SET NULL keeps the invite and its
-- 'accepted' status while dissociating the departed member, which is
-- also the correct data-protection outcome: erase the link to the
-- person, keep the counterparty's record.
--
-- Safe because nothing reads the column: zero references in 109 Dart
-- files, and no function or policy depends on it being non-null. The
-- column was already nullable.
--
-- ── A CORRECTION TO MY OWN EARLIER CLAIM. I told the Founder there were
-- TWO blocking FKs, the second being matches.suspended_by, and that it
-- would trap anyone who had ever paused a Journey. THAT WAS WRONG, and
-- tested rather than reasoned this time. matches.suspended_by is indeed
-- NO ACTION, but it can only ever point at a party to that same match,
-- and matches.seeker_a_id/seeker_b_id both CASCADE — so the match row is
-- removed before the NO ACTION constraint is checked at end of
-- statement. Verified: a user who had paused a Journey deleted cleanly.
-- The audit was right and I was not.
--
-- matches.suspended_by is therefore left ALONE, deliberately. It is not
-- reachable today, and turning it into SET NULL would mean "silently
-- unpause the Journey" if it ever did become reachable — pause is
-- defined as suspended_by IS NOT NULL. That is a product decision, not
-- cleanup. Recorded so the inconsistency with journey_attempts.paused_by
-- (which IS SET NULL) is a known choice rather than an oversight.

ALTER TABLE public.wali_invites
  DROP CONSTRAINT wali_invites_accepted_by_fkey;

ALTER TABLE public.wali_invites
  ADD CONSTRAINT wali_invites_accepted_by_fkey
  FOREIGN KEY (accepted_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
