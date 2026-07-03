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

Wali System
• Wali may view onboarding data through their supervision role.

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
• Green / Amber / Red compatibility rating system not yet built.
• Compatibility scoring algorithm not yet designed.
• Wali onboarding not yet designed.
• Which extended questions affect scoring vs informational
  only — not yet decided.
• Men-only question logic (conditional display) not yet
  fully specified.
