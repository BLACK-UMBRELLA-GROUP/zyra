---
id: DOC-ZYRA-0043
type: GUIDE
status: CURRENT
feature: APP: ONBOARDING
purpose: Onboarding / Seeker Onboarding Questions — References
links: []
owner: ZYRA chat
---

FEATURE NAME
SEEKER ONBOARDING QUESTIONS

============================================================
REFERENCES
============================================================

CURRENT FIRST SEEKER PHOTO — 2026-10-04 / DR-ZYRA-264:
The Master Product Spec owns the required first photo before Membership and
unchanged verified-only profile creation, Guardian identity-only flow and later
profile/publication rules. Onboarding Preview §109 owns private staging/recovery,
attachment confirmation and tests/delivery limits. No migration, live upload,
provider/commerce activation or physical acceptance is inferred; existing
photo pipeline/publication gaps remain OA-ZYRA-193/303.

CURRENT FAMILY INTRODUCTORY COMPARISON — 2026-10-04 / DR-ZYRA-263:
Pricing owns the protected Family introduction amount/boundary. Onboarding
Preview §108 and Paid Membership §12 own as-built display and delivery facts.
The configurator counts selected role places, not deduplicated verified
people; OA-ZYRA-253 retains eligibility/dual-role billing and live commerce.
Ordinary prices/trials and account/privacy/identity policy remain unchanged.

CURRENT GUIDED ANSWER PRESENTATION — 2026-10-04 / DR-ZYRA-262:
Onboarding Preview §107 owns the scoped separate-card choice presentation,
motion, internal checks and paired-phone delivery state. The generic selector
is explicitly opt-in so profile editors retain their previous default.
No account/privacy/identity/compatibility policy changes; Founder physical
acceptance remains separate under OA-ZYRA-303/257/286.

CURRENT ACCOUNT HANDOFF ARTWORK — 2026-10-04 / DR-ZYRA-261:
Onboarding Preview §106 owns the account-only gold person outline/halo and
checked routine local delivery. No account/identity/privacy policy changes.
Physical Founder acceptance remains separate under OA-ZYRA-303/257/286.

CURRENT CHECKPOINT MOTION REPAIR — 2026-10-04 / DR-ZYRA-260:
Onboarding Preview handover §105 owns the finger-release/scroll handoff,
settlement locks and bounded callback repairs. It changes no account,
identity, consent or profile policy. Routine paired-phone delivery is governed
by DR-ZYRA-257; internal checks are not physical Founder acceptance.

CURRENT VERIFICATION TRUST PAGE — 2026-10-04 / DR-ZYRA-256/259:
The protected opening now presents the DR-ZYRA-221 mandatory admission
standard on its own Our community page, not in the Welcome prayer block.
Onboarding Preview handover §99 owns unchanged copy; §103 / DR-ZYRA-259
supersedes its standalone navigation/count. Verified people is slide 1/4 of
the shared Verified/Photos/Compatibility/Guardian section, not another down
checkpoint. Welcome stays separate; Guardian retains the final down exit.
Authentication and the Master Product Spec remain the policy owners. This
local presentation does not prove universal live verification, activate a
provider or the held existing-account gate, or resolve OA-ZYRA-266.

CURRENT POLICY REFERENCE — 2026-09-28:
ZYRA_PRODUCT_SPEC Part 1 section 8 / DR-ZYRA-250 govern future
capture/calculation/disclosure. Old ratified scorer history below does
not certify the corrected manifest, validator, snapshot or server gate
as built. Stage1 and later execution remain held; only the Founder approves.

------------------------------------------------------------
References (depends on)
------------------------------------------------------------

Compatibility Preferences
• Onboarding flows directly into Compatibility Preferences
  (Green / Amber / Red) after the question flow completes.
• Policy home: ZYRA_PRODUCT_SPEC / DR-ZYRA-250. The local build brief
  is a draft, not a deployed system or engineering execution GO.

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

• Approved policies need versioned answer/preference registries,
  strict raw validation and targeted legacy reconfirmation/repair.
  Those dependencies remain open under OA193/226/285.
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
  HISTORICAL RATIFICATION ONLY: later question-based arithmetic and
  D1–D6 govern prospective work. No old own-gender variant, silent skip,
  partial map or unversioned Amber thereby becomes the corrected future
  contract. No live configuration is reverified by this filing.
• Guardian onboarding not yet designed.
• Which extended questions affect scoring vs informational
  only — not yet decided (depends on DR-ZYRA-079 above).
• Men-only question logic (conditional display) — RESOLVED,
  built: `GenderVisibility.menOnly` in
  `models/onboarding_question.dart` implements this (used for
  the Masjid Attendance question). Confirmed 2026-07-25,
  DR-ZYRA-101 audit.
  This describes own-answer visibility, not preference capture.
  Future q39 follows the permitted prospective male pool; q24/q26
  targeting and strict variants follow DR-ZYRA-250.
