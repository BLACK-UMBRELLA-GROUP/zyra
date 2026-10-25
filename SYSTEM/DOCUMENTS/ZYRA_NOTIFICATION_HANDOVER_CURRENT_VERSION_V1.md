---
id: DOC-ZYRA-0227
type: HANDOVER
status: CURRENT
feature: MESSAGING AND NOTIFICATIONS
purpose: ZYRA Notification — Implementation Handover
links: []
owner: ZYRA chat
---

# ZYRA Notification — Implementation Handover

**Version:** V1  
**Status:** CURRENT_VERSION  
**Date:** 2026-09-19  
**Owner:** Founder  
**Implementation owner:** Codex  
**Specification:** `ZYRA_NOTIFICATION_SPECIFICATION_CURRENT_VERSION_V1.md`

## PROJECT LOCATION

- **Major Folder:** `12_NOTIFICATIONS/`
- **Purpose:** Notification delivery, category preferences and consent-safe controls.
- **Owns:** Notification category state and the member controls that change it.
- **References:** Profile surfaces, My ZYRA notification centre, Guardian role context.
- **Referenced By:** Seeker and Guardian Profile/Settings surfaces.

## 1. Current Profile implementation

Guardian Profile now presents an active `Notifications` switch directly in its
Settings section. The row remains tappable and opens the existing detailed
Guardian notification screen.

The Profile switch is a service-notification master control for exactly these
three existing specification categories:

- `matches_journeys`;
- `guardian_activity`; and
- `introductions`.

`On` means at least one service category is enabled. Switching on enables all
three; switching off disables all three. Each change uses the existing
append-only `zyra_set_notification_preference` RPC. The switch is disabled only
while its writes are in flight or when current preference truth could not be
loaded. After writing, the Profile reloads server truth rather than assuming
success. A partial failure is disclosed and the refreshed state is shown.

Marketing Emails and Product Updates are deliberately excluded. They remain
separate affirmative-consent controls on the detailed Notifications screen and
cannot be enabled by a bundled Profile switch. Essential account and safety
notices remain non-optional as required by the specification.

## 2. Shared detailed screen

The existing `NotificationSettingsScreen` remains the single detailed category
implementation for Seeker and Guardian. `WaliNotificationSettingsScreen` only
supplies Guardian role copy and continues to use the same service, codes,
append-only writes, optimistic rollback and error disclosure.

This change does not claim that APNs/FCM device delivery is live. The Profile
switch controls governed category creation/feed eligibility; device permission
and external push delivery remain their separate truthful status.

## 3. Verification

- Guardian Profile and notification parity tests: **5/5 PASS**.
- `flutter analyze`: **PASS, no issues**.
- The new regression proves all three service categories are persisted, the
  visible state changes, and neither marketing-consent category is written.
- Wireless iPhone profile build/install: **PASS**. Xcode completed in 60.5s
  and installation completed in 39.5s. Flutter then lost the iPhone mDNS name
  while attaching its debugger; direct `devicectl` launch of the installed
  `app.zyraconnect.zyra` bundle succeeded.

## 4. Files and hashes

- `lib/screens/wali/wali_profile_screen.dart`  
  `d46ec0d8b6bff3b9fe4aabc9e44c6c2dc14f08ea2d3a03ccde5228b638c08876`
- `test/profile_membership_consistency_test.dart`  
  `f3088e609c5f6a4f6a3f3abcdb11fbd19dadb4e1f6fb790b350a8d29c7629ef3`
- Existing detailed screen: `lib/screens/settings/notification_settings_screen.dart`  
  `cb1076bc7160da23f6c55651959f6e680fd8518b51bbccc3b68804f4c7694933`
- Existing persistence service: `lib/services/zyra_notification_prefs_service.dart`  
  `89e39ad671e5fc6c645006c59bc0daccbbb696bdd59e77e90b069d13120e84d5`

## 5. Migrations and production boundary

No database migration, push provider, token registration, schema change or new
consent category was created. The implementation reuses the existing governed
preference RPC and category table. Founder phone visual acceptance remains the
next evidence step.
