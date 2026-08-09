-- AUDIT FINDING 2.4 — a block did not close the blocked person's channel.
--
-- messages_insert checked two things: you are the sender, and you are a
-- seeker participant in the attempt. It did NOT check profile_blocks,
-- conversations.status or the attempt's lifecycle. So after blocking
-- someone, their messages still arrived, and notify_new_message still
-- pushed their name and the first 140 characters of the message to the
-- blocked-by party's phone.
--
-- This is the other half of the 2026-08-09 blocking fix (finding 1.2).
-- That one made the block record and end the Journey; without this one
-- the word "blocked" was still not true.
--
-- ── WHAT IS ADDED
--   1. NOT zyra_block_exists(counterpart) — in EITHER direction, because
--      blocking is mutual invisibility, not a one-way mute.
--   2. r.attempt_status = 'active' — no messaging into an ended Journey.
--   3. c.status = 'active' — no messaging into a closed conversation.
--
-- ── WHY zyra_block_exists AND NOT AN INLINE EXISTS. profile_blocks RLS
-- deliberately prevents anyone from seeing who blocked them. An inline
-- EXISTS in this policy is evaluated as the SENDER, so the blocked party
-- would read zero rows and the check would pass for exactly the person it
-- is meant to stop. zyra_block_exists is SECURITY DEFINER, already exists,
-- already checks both directions, and is already granted. One predicate,
-- one place — invariant I3.
--
-- ── WHY notify_new_message IS UNCHANGED. It is an AFTER INSERT trigger.
-- A refused insert never fires it, so the push is closed by the same
-- change. Adding a second block check inside the trigger would be a
-- second copy of the same rule.
--
-- ── WHY journey_attempts IS NOT JOINED HERE, though it holds the
-- lifecycle. journey_attempts has RLS ENABLED WITH ZERO POLICIES, so
-- every row is invisible to `authenticated`. Joining it inside a policy
-- would make this EXISTS false for everyone and silently break ALL
-- messaging. The lifecycle is read through
-- zyra_my_attempt_participation, which is SECURITY DEFINER and already
-- exposes attempt_status. Recorded because it is a live trap for the
-- next policy anyone writes against that table.
--
-- ── WHAT IS DELIBERATELY NOT ADDED, and raised rather than guessed:
--   · journey_stage = 'conversation'. Free messaging is defined to begin
--     only at Open Conversation and ChatScreen is gated on it client
--     side, but the participation view does not expose journey_stage, and
--     journey_attempts cannot be joined (above). Extending that view
--     also changes what messages_select and conversations_select read.
--     Out of scope for a safety fix.
--   · paused. Same reason — paused is paused_by IS NOT NULL on
--     journey_attempts, not a status, and the view does not expose it.
--     c.status = 'active' is the intended guard and nothing currently
--     maintains that column, so today it is dormant but correct.
--
-- ── MIGRATION RISK: NONE. Measured 2026-08-09 immediately before
-- applying — the database holds 0 messages, 0 conversations, 0 attempts
-- and 0 matches. Nothing existing can be invalidated by tightening this.

DROP POLICY IF EXISTS messages_insert ON public.messages;

CREATE POLICY messages_insert ON public.messages
FOR INSERT
WITH CHECK (
  sender_id = (SELECT auth.uid())
  AND EXISTS (
    SELECT 1
    FROM conversations c
    JOIN zyra_my_attempt_participation r ON r.attempt_id = c.attempt_id
    JOIN matches mt ON mt.id = r.match_id
    WHERE c.id = messages.conversation_id
      AND r.role = 'seeker'
      AND r.attempt_status = 'active'
      AND c.status = 'active'
      AND NOT public.zyra_block_exists(
            CASE WHEN mt.seeker_a_id = (SELECT auth.uid())
                 THEN mt.seeker_b_id
                 ELSE mt.seeker_a_id END)
  )
);