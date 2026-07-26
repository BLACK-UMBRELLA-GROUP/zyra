# Notifications

**Status:** Partially built — preferences only, no delivery
**Updated:** 2026-07-26 (DR-ZYRA-101 audit, scope defined)

------------------------------------------------------------
CURRENT STATE
------------------------------------------------------------

No push notification system exists in this build: no delivery
mechanism, no backend table, no Bell icon anywhere in the app yet —
despite APP/Navigation/SEEKER NAVIGATION/Summary.md's own ratified
rule ("Notifications use the Bell Icon. Bell Icon is positioned
top-right. Notifications are not a navigation tab") assuming one
exists. That rule is still the approved design for whenever
notifications are actually built; it just isn't built yet.

------------------------------------------------------------
WHAT WAS BUILT 2026-07-26
------------------------------------------------------------

A Settings → Notifications screen (SOURCE/lib/screens/settings/
notification_settings_screen.dart) that says the above plainly, and
three preference toggles (New Matches, New Messages, Wali Requests)
persisted in AppState for the session. These toggles do not currently
gate or trigger anything — there's nothing yet for them to gate —
they exist so the preference model is ready the moment real push
infrastructure (and the Bell icon) is built.

------------------------------------------------------------
NOT BUILT
------------------------------------------------------------

  • Bell icon / in-app notification feed
  • Push delivery (device tokens, APNs/FCM wiring)
  • Any backend notification/event table
  • Actually triggering a notification on any event (new Match,
    message, Wali request, etc.)
