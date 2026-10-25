---
id: DOC-ZYRA-0172
type: SPEC
status: CURRENT
feature: GENERAL
purpose: ZYRA — Shared Widget Library
links: []
owner: ZYRA chat
---

# ZYRA — Shared Widget Library
**Version:** V1
**Status:** CURRENT_VERSION
**Date:** 2026-07-26
**Governing Reference:** ZYRA_ARCHITECTURE_CURRENT_VERSION_V2
**Related:** ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V2 (Section 7 —
Source Code), APP/iOS Widgets/ (unrelated — home-screen widgets, not
this Flutter component library; disambiguated 2026-07-25, OA-ZYRA-140
item 11)

---

## 1. Purpose

`SOURCE/lib/widgets/` is ZYRA's shared, cross-screen Flutter component
library — small presentational widgets reused across multiple screens
(as opposed to a screen's own private widgets, which live inline in
that screen's file, e.g. `_JourneyTile` in `connections_screen.dart`).

This document did not exist before 2026-07-26 — flagged as a known gap
in `SESSION_HANDOVER_2026-07-25.md` and `ZYRA_DOCUMENTATION_INDEX_
CURRENT_VERSION_V2.md` Section 7 ("undocumented in APP/, known gap").
Per `SUMMARY_STANDARD_CURRENT_VERSION_V3.md` §1, the Summary.md
standard explicitly does not apply to `SOURCE/` code — this is a
SYSTEM/ reference document instead, not a feature Summary.

This is a **reference document, not a Source of Truth for behaviour**.
The code in `SOURCE/lib/widgets/` is authoritative; this document
should be kept in sync with it but the code wins on any conflict.

---

## 2. Widgets

### GlassIconButton / GlassFlashCircle
**File:** `glass_icon_button.dart`
**Purpose:** Real glassmorphism icon button — `BackdropFilter` blur
(not just a flat translucent tint) over whatever's behind it (usually
a full-bleed photo), border, inset highlight. `GlassFlashCircle` is the
larger variant used for the brief decision-flash moment (Decline/Save/
Like confirmation) in Browse.
**Used by:** `home_shell.dart` (Bell icon, Dev Access shortcut),
`wali_home_shell.dart` (Bell icon), `browse_screen.dart` (decision
flash), `notification_bell.dart`.
**Provenance:** Adapted from the Founder's Lovable prototype
(`src/components/AppShell.tsx` `GLASS_BTN`).

### NotificationBell
**File:** `notification_bell.dart`
**Purpose:** Bell icon with an unread-count badge, polling every 20s —
per `APP/Navigation/SEEKER NAVIGATION/Summary.md`'s ratified "Bell Icon
is positioned top-right... not a navigation tab" rule. Opens
`screens/notifications/notifications_screen.dart`. Built 2026-07-26
(#16) alongside the `notifications` table.
**Used by:** `home_shell.dart`, `wali_home_shell.dart`.
**Depends on:** `services/zyra_notification_service.dart`.

### FloatingNavBar
**File:** `floating_nav_bar.dart`
**Purpose:** The shared floating glassmorphic pill bottom-nav bar used
identically by both Seeker (`HomeShell`) and Guardian (`WaliHomeShell`)
shells — icon-grows-when-selected behaviour, single sliding circular
highlight (not per-item static backgrounds). Drag/scrub-enabled.
**Used by:** `home_shell.dart`, `wali_home_shell.dart`.
**Provenance:** DR-ZYRA-091 — rebuilt from a solid dark-purple bar onto
this shared widget per Founder-supplied Instagram/Lovable reference
recordings (DR-ZYRA-089).

### FabContinueButton
**File:** `fab_continue_button.dart`
**Purpose:** The onboarding "Continue" FAB — per Onboarding Rules & UX
§SCREEN ANATOMY (FAB): always visible, never hidden; dimmed when the
current answer is invalid/missing, active once valid. Fixed position
(14px from bottom, 16px from right, 52px circle, arrow-forward icon).
**Used by:** `onboarding_scaffold.dart` (composed internally — question
screens don't place this directly).

### FlexibilityChoice
**File:** `flexibility_choice.dart`
**Purpose:** The single 🟢/🟡/🔴 sentence-choice pattern used
throughout Chapter 2 onboarding questions ("Questions Section 2 Profile
Information.md") — three full-sentence options, one per traffic-light
value. Distinct from Chapter 4's per-option traffic-light matrix, which
is handled by a screen (`traffic_light_question_screen.dart`), not a
shared widget.
**Depends on:** `models/onboarding_question.dart` (`TrafficLight` enum).

### OnboardingScaffold / OnboardingTopBar
**Files:** `onboarding_scaffold.dart`, `onboarding_top_bar.dart`
**Purpose:** `OnboardingScaffold` is the shared page chrome every
onboarding question screen renders through — wires together the
gradient background, `OnboardingTopBar` (chapter name, progress bar,
"···" help sheet), scrollable question content, an optional
`PrivacyIndicator`, and the `FabContinueButton`. Deliberately has no
back button (spec: back navigation is swipe-right); a 2026-07-18 fix
added a real `onHorizontalDragEnd` swipe-back handler, since onboarding
uses a manual step index rather than `PageView` and the swipe had never
actually been wired up before.
**Used by:** every onboarding question screen.

### PrivacyIndicator
**File:** `privacy_indicator.dart`
**Purpose:** The Public/Unlock/Private dot-and-label indicator shown at
the bottom of onboarding question content (§PRIVACY INDICATOR —
ASSIGNMENT BY QUESTION) — "Visible when people browse your profile" /
"Visible only after a mutual match" / "Only you and ZYRA can see this
answer," with colours from `zyra_colors.dart`
(`publicDot`/`unlockDot`/`privateDot` + text variants). Supports an
`overrideText` for question-specific phrasing.
**Used by:** `onboarding_scaffold.dart` (optional `privacy` param).

### SearchableListPicker
**File:** `searchable_list_picker.dart`
**Purpose:** `showSingleSearchPicker()` / `showMultiSearchPicker()` —
bottom-sheet searchable picker over a static string list. Explicitly a
stand-in for a real country/language/ethnicity search backend
(`mock_reference_lists.dart`), not backed by a live API.
**Depends on:** `zyra_state_widgets.dart` (`ZyraEmptyState` for the
no-matches state).

### Shared error/empty-state widgets
**File:** `zyra_state_widgets.dart`
**Purpose:** Implements `ERROR_AND_EMPTY_STATE_STANDARD_CURRENT_
VERSION_V1.md` (DR-ZYRA-080) — five widgets, one per standard category,
so no screen writes a one-off `Text()` error string: `ZyraFieldError`
(inline field-validation message), `ZyraErrorBanner` (dismissible glass
banner for backend/network errors, with optional Retry), `ZyraEmptyState`
(centred icon + message + optional single CTA — "nothing here yet"),
`ZyraUnknownErrorState` (fallback for anything unanticipated, built on
`ZyraEmptyState`), `ZyraDisabledHint` (small "why is this disabled" hint
under a disabled Continue button).
**Used by:** Extremely broad — Connections, Guardian Dashboard,
Notifications, Journey screens, `searchable_list_picker.dart`, and more.
This is the most widely reused file in the library.

### DevNavOverlay
**File:** `dev_nav_overlay.dart`
**Purpose:** Temporary testing aid — floating Back/Home buttons so
testing can proceed even on screens that don't push real Navigator
routes (several onboarding flows track a step index in local State
rather than the route stack). Gated on `!kReleaseMode`, so it appears
in debug AND profile builds, not just debug — profile-mode gating was
added 2026-07-19 after diagnosing that untethered device testing
requires `flutter run --profile`/`--release` (iOS kills debug/JIT
builds without an attached debugger), so the overlay needed to survive
in profile mode too. Never appears in a release build. Sits above the
whole app via `MaterialApp`'s `builder:` using a global
`navigatorKey`, not a local `BuildContext`.
**Related:** `screens/dev/developer_access_screen.dart`.

---

## 3. Known Gaps

- No widget-level tests exist for anything in this folder.
- No Storybook-style visual catalog / preview harness — this document
  is the only index.
- Every entry above was written from a direct read of the actual
  widget file (not inferred from filename alone), but "Used by" is
  based on the imports/comments found in each file at the time of
  writing, not an exhaustive grep of every call site — treat it as
  representative, not a guaranteed-complete usage graph.

---

## 4. Version History

| Version | Date | Change |
|---------|------|--------|
| V1 | 2026-07-26 | Initial release — closes the gap flagged in `SESSION_HANDOVER_2026-07-25.md` and `ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V2.md` Section 7 (#18). |
