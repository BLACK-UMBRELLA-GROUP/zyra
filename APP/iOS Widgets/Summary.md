============================================================
ZYRA PROJECT
============================================================
APP / iOS Widgets
Summary
============================================================
Owner:        Project Owner
Status:       In Planning
Group:        7 — UI/UX Design
Last Updated: 2026-06-21
RENAMED 2026-07-25 (OA-ZYRA-140 item 11, Founder decision): folder
renamed from "WIDGETS" to "iOS Widgets" to disambiguate this iOS
WidgetKit home/lock-screen widget concept from SOURCE/lib/widgets/,
the unrelated Flutter shared-component library (no name/content
change to the feature itself, path only).
============================================================


FEATURE OVERVIEW
============================================================

iOS widgets for ZYRA that surface glanceable, at-a-glance
information. Widgets are not miniature versions of the
application. They exist to bring users back into the app
with timely, lightweight information.

Three widget sizes (small, medium, large) plus lock screen
widgets. Each size surfaces specific, appropriate content
for that format.


USER EXPERIENCE
============================================================

Users access widgets from the iOS home screen and lock
screen. Widgets display information passively or allow
lightweight interaction. Important relationship decisions
are never made via widget — they require the full
application.

Widget content is informational. Widgets do not replicate
core app screens.


FUNCTIONAL SPECIFICATION
============================================================

Small Widgets
------------------------------------------------------------
  • New matches
  • Unread messages
  • Daily reminder
  • Profile completion
  • Compatibility score

Medium Widgets
------------------------------------------------------------
  • Activity summary
  • Wali dashboard
  • Match recommendations
  • Marriage journey progress

Large Widgets
------------------------------------------------------------
  • Dashboard overview
  • New activity
  • Profile views
  • Daily summary
  • Pending actions

Lock Screen Widgets
------------------------------------------------------------
  • New matches
  • New messages
  • Pending approvals
  • Daily reminders


BUSINESS RULES
============================================================

  • Widgets surface information only. They are not
    miniature app versions.
  • Users may not Like or Decline marriage candidates
    from widgets. These actions must occur within the
    full application.
  • Interactive widgets are limited to lightweight
    actions only (e.g. navigating to a screen).
  • Important relationship decisions always occur
    within the full application.
  • Widget refresh rates are subject to iOS WidgetKit
    constraints.


RELATED FEATURES
============================================================

  • Navigation — deep links from widgets into app screens
  • Notifications — widgets complement push notifications
    but do not replace them
  • Profile Decision System — decisions always in-app,
    never from widget
  • Wali Navigation — Wali dashboard widget depends on
    this feature being defined first


DESIGN DECISIONS
============================================================

  • Glanceable information only. Widgets must not attempt
    to replicate core app functionality.
  • Lock screen widgets limited to informational use only.
  • No Like / Decline actions from any widget size.


CURRENT STATUS
============================================================

In Planning. No implementation started.

All items in this document are ideas pending individual
review, prioritisation, and approval before implementation
begins.


APPROVED FUTURE WORK
============================================================

  • Review individual widget designs during UI/UX phase.
  • Define deep link routing from each widget type.
  • Confirm iOS WidgetKit refresh strategy.
  • Wali dashboard widget requires Wali Navigation feature
    to be defined before widget design can begin.
  • Confirm which widgets require user authentication state.


============================================================
END OF DOCUMENT
============================================================
