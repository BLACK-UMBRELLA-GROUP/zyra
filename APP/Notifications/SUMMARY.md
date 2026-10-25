---
id: DOC-ZYRA-0035
type: SPEC
status: CURRENT
feature: APP: NOTIFICATIONS
purpose: Notifications — SUMMARY
links: []
owner: ZYRA chat
---

# Notifications

**Status:** In-app delivery built. Push not built.
**Updated:** 2026-07-26 (#16 build)

------------------------------------------------------------
CURRENT STATE
------------------------------------------------------------

In-app notifications are real: a `notifications` table
(SOURCE/supabase/migrations/20260726140000_notifications.sql), a Bell
icon positioned top-right in both HomeShell (Seeker) and WaliHomeShell
(Guardian) per this document's own longstanding ratified rule ("Notifications
use the Bell Icon. Bell Icon is positioned top-right. Notifications are
not a navigation tab"), and a notification feed screen
(SOURCE/lib/screens/notifications/notifications_screen.dart).

Push (device-level notifications when the app isn't open) is NOT
built — that requires a Firebase project (FCM, Android) and an Apple
APNs auth key (iOS), both of which only the Founder can create/supply.
Tracked as its own follow-up task, deliberately not blocking this pass.

------------------------------------------------------------
WHAT WAS BUILT 2026-07-26
------------------------------------------------------------

  • `notifications` table (RLS: read/mark-read own rows only; all
    writes are server-side — no client INSERT policy at all)
  • Three event types, matching the three preference toggles already
    in Settings → Notifications:
      - new_match    — fires from the mutual-Like trigger
        (create_match_on_mutual_like), the moment a Potential match
        is created
      - new_message  — fires from a new trigger on `messages`
        (notify_new_message)
      - wali_request — fires from accept_wali_invite when a Guardian-link
        invite is accepted (either direction)
  • Bell icon (widgets/notification_bell.dart) with an unread-count
    badge, polling every 20s
  • Notification feed screen with mark-read / mark-all-read
  • Both new internal helper functions (create_notification,
    notify_new_message) had their own anon/authenticated-execute gap
    (same class of issue as ages_for/score_candidates) — found and
    fixed in the same pass via get_advisors + has_function_privilege
    verification

------------------------------------------------------------
NOT BUILT / KNOWN GAPS
------------------------------------------------------------

  • Push delivery (device tokens, APNs/FCM wiring, Edge Function
    sender) — blocked on Founder providing Firebase + APNs credentials
  • The three Settings toggles (New Matches/New Messages/Guardian
    Requests) are session-only preferences (AppState), not synced to
    the database — they do NOT currently gate which in-app
    notifications get created. The server-side triggers fire
    regardless of the toggle state. Fixing this needs a synced
    preferences table; not done here to avoid scope creep.
  • Journey-stage-advancement notifications (e.g. "Your Journey moved
    to Family Stage") are NOT included — no existing toggle covers
    that category; would be new scope
  • Tapping a notification in the feed marks it read but does not
    deep-link to the related Match/Journey screen (Seeker and Guardian
    have different detail screens for this) — follow-up if wanted
