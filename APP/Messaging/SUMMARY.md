# Messaging

**Status:** Built and working
**Updated:** 2026-07-26 (DR-ZYRA-101 audit — spec corrected to match shipped code)

------------------------------------------------------------
CORRECTION
------------------------------------------------------------

This file previously read "Placeholder — Approved Application
Structure, Reserved for future implementation" (dated 2026-06-27).
That has been stale since at least 2026-07-18: SOURCE/lib/screens/
chat/chat_screen.dart is built and working, wired to the real
`conversations`/`messages` tables via ZyraMatchService, with Realtime
subscription for incoming messages. This audit found the doc/code
mismatch and is correcting it rather than leaving the spec claiming a
feature doesn't exist when it does.

------------------------------------------------------------
WHAT'S BUILT
------------------------------------------------------------

  • ChatScreen (SOURCE/lib/screens/chat/chat_screen.dart) — per
    MATCH_UX_SPEC_CURRENT_VERSION_V1.md: "Conversation belongs to
    Active Journey only."
  • Real wiring: for a real matched Seeker, resolves the real
    conversation (ZyraMatchService.resolveConversationId), loads
    message history (fetchMessages), subscribes to Supabase Realtime
    for incoming messages, and sends via the real `messages` table
    (sendMessage).
  • Graceful mock fallback: if `withProfile` is a mock Browse
    candidate with no backing match (or nothing real resolves), falls
    back to the original local-only mock chat — including a
    `[failtest]` deterministic failure trigger for testing — so the
    screen stays testable in both states.
  • Reachable from an Active Journey in the Connections tab (see
    APP/Navigation/SEEKER NAVIGATION/Summary.md's Matches section:
    each Match entry has Message/Timeline/Guardian actions).

------------------------------------------------------------
NOT BUILT
------------------------------------------------------------

  • Push notifications for new messages (see APP/Notifications/
    Summary.md — no delivery mechanism exists anywhere yet).
  • Read receipts, typing indicators, media/attachments.
  • Guardian visibility into conversations (deliberately unbuilt — see
    ZYRA_FABLE_BUILD_REVIEW_2026-07-19_V1.md §Open Decisions item 4).
