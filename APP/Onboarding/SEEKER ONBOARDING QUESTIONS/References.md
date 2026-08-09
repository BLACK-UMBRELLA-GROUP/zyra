FEATURE NAME
SEEKER ONBOARDING QUESTIONS

============================================================
REFERENCES
============================================================

------------------------------------------------------------
References (depends on)
------------------------------------------------------------

Compatibility Preferences
• Onboarding flows directly into Compatibility Preferences
  (Green / Amber / Red) after the question flow completes.
• Status: Referenced — document not yet created.
  ⚠️ Open dependency — Compatibility Preferences needs a home.

Discover / Matching System
• Onboarding feeds profile data into the Discover and
  Matching systems.
• Status: Referenced — definition lives in APP/Matching.

User Profile
• Public Profile Information from onboarding populates
  the user's profile.
• Status: Referenced — definition lives in APP/Profiles.

------------------------------------------------------------
Referenced By
------------------------------------------------------------

Discover Page
• Onboarding data powers profile discovery.

Matching System
• Private Core and Extended Compatibility data feeds
  the matching algorithm.

Compatibility Engine
• All compatibility question responses feed into the
  compatibility scoring system.

User Profile
• Public Profile Information is displayed on the user profile.

Guardian System
• Guardian may view onboarding data through their supervision role.

------------------------------------------------------------
Overlap Flags
------------------------------------------------------------

⚠️ APP/Profiles
- User Profile is both a reference and a referenced-by.
- Onboarding creates the profile — ensure no duplication
  of question definitions between this file and Profiles.

------------------------------------------------------------
Open Dependencies
------------------------------------------------------------

• Compatibility Preferences document not yet created.
• Green / Amber / Red compatibility rating system: the input
  side (Chapter 4 traffic-light preference UI) is built —
  `traffic_light_question_screen.dart`. The output side (an
  actual Green/Amber/Red compatibility score/badge shown to
  users) is NOT built. Updated 2026-07-25, DR-ZYRA-101 audit —
  see also the scoring-algorithm line below, which is the more
  important open item here.
• Compatibility scoring algorithm: RESOLVED 2026-07-25
  (OA-ZYRA-140 item 12, Founder decision: "ratify as-is").
  `SOURCE/lib/services/compatibility_scoring.dart` (DR-ZYRA-079)
  and its live wiring into `zyra_discovery_service.dart`
  (DR-ZYRA-084) are both now RATIFIED — no longer an unratified
  draft governing live candidate visibility.
• Guardian onboarding not yet designed.
• Which extended questions affect scoring vs informational
  only — not yet decided (depends on DR-ZYRA-079 above).
• Men-only question logic (conditional display) — RESOLVED,
  built: `GenderVisibility.menOnly` in
  `models/onboarding_question.dart` implements this (used for
  the Masjid Attendance question). Confirmed 2026-07-25,
  DR-ZYRA-101 audit.
