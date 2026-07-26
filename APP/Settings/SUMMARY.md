# Settings

**Status:** Partially built
**Updated:** 2026-07-26 (DR-ZYRA-101 audit — scope defined, minimal build shipped)

------------------------------------------------------------
WHERE IT LIVES
------------------------------------------------------------

There is no standalone Settings tab or top-level Settings screen.
Settings is a section within the Profile tab (SOURCE/lib/screens/
profile/profile_screen.dart), listing:

  • Notifications  → SOURCE/lib/screens/settings/notification_settings_screen.dart
  • Privacy         → SOURCE/lib/screens/settings/privacy_settings_screen.dart
  • Manage Subscription → existing UpgradeScreen
  • Help & Support  → not built (row present, no destination yet)
  • Sign Out        → built, functional

"Link a Wali" was removed from this list 2026-07-26 — Wali linking is
now its own bottom-nav tab (see APP/Navigation/SEEKER NAVIGATION/
Summary.md), so a duplicate entry here would have been a second path
to the same flow.

------------------------------------------------------------
NOTIFICATIONS SCREEN — REAL SCOPE
------------------------------------------------------------

There is no push notification system in this build — no delivery
mechanism, no backend table, and no Bell icon anywhere yet either,
despite SEEKER NAVIGATION's own ratified rule assuming one exists.
The screen says this plainly rather than implying working
notifications, and captures three preference toggles (New Matches,
New Messages, Wali Requests) in AppState — saved for this session,
not yet wired to any real delivery mechanism.

------------------------------------------------------------
PRIVACY SCREEN — REAL SCOPE
------------------------------------------------------------

One genuinely-wired control: "Visible in Browse", toggling
`profiles.is_active` (the same column Browse's own discovery query
filters on, and that profiles_select RLS checks for row visibility).
Turning it off actually removes the Seeker from Browse for everyone
else — not cosmetic. No other privacy controls (blocking, photo
visibility rules, etc.) exist yet; the screen says so.

------------------------------------------------------------
NOT BUILT
------------------------------------------------------------

  • Help & Support destination
  • Account deletion / data export
  • Any privacy control beyond Browse visibility
