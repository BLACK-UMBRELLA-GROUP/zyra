FEATURE NAME
Profile Unlocks (Name TBC)
Group: 4 — Page Responsibilities

============================================================
SUMMARY
============================================================

Purpose:
Provides deeper compatibility insight before progressing
further with a profile. Helps users make better-informed
marriage decisions without revealing private answers.

Corrected 2026-07-12 against ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3
and BUSINESS/ZYRA PRICING/Summary.md — Seeker Basic/Pro/Premium
replaced with ZYRA Basic/ZYRA One; Review/Consider stages
replaced with Saved/Liked; pricing "TBC" resolved to Option A,
which matches Product Spec V3 Part 1 Section 8 exactly (Option B
was never adopted — see BUSINESS/ZYRA PRICING/Summary.md).

------------------------------------------------------------
Feature Name
------------------------------------------------------------

Current options (decision pending):
• Profile Unlock / Profile Unlock+
• Compatibility Preview / Compatibility Preview+
• Insight Unlock

A naming review will determine the final product name.

------------------------------------------------------------
Availability
------------------------------------------------------------

Seeker Only (ZYRA Basic, ZYRA One).
Wali cannot purchase or use Profile Unlocks.
This is a Seeker-only feature.

------------------------------------------------------------
Usage Rules
------------------------------------------------------------

• Cannot be used while swiping.
• Cannot be used on passed profiles.
• Profile must first be Saved or Considered
  before an unlock can be purchased.
  (UPDATED 2026-07-25, DR-ZYRA-099 terminology sweep-miss:
  Declined/Liked -> Passed/Considered.)
• Once purchased and used, the profile remains
  permanently unlocked for that user.
  No repurchase required to view again.

------------------------------------------------------------
Profile Unlock
------------------------------------------------------------

Provides a high-level compatibility overview based on
the user's onboarding preferences compared against
the other user's responses.

Displays:
• Overall Compatibility %
• Green / Yellow / Red counts

Example:
  Overall Compatibility: 81%
  🟢 Green:  50
  🟡 Yellow: 25
  🔴 Red:    13

Green / Yellow / Red Logic:
  Generated from the user's own onboarding preferences.
  Example — Smoking Preference:
    Green  = Non-smoker
    Yellow = Occasionally
    Red    = Smoker
  The system compares onboarding responses against the
  user's preferences and generates compatibility results.

Privacy Protection:
  Does NOT reveal:
  • Actual onboarding answers
  • Exact responses
  • Private profile information
  • Which specific questions caused Green, Yellow or Red
  Only compatibility outcomes are shown.

Pricing (confirmed 2026-07-12): 1 Unlock = £0.99 / 5 Unlocks = £2.99

------------------------------------------------------------
Profile Unlock+
------------------------------------------------------------

Includes everything in Profile Unlock, plus a detailed
category-level compatibility breakdown.

Compatibility Categories (pending final confirmation):
• Lifestyle
• Work & Education
• Family Values
• Marriage Goals
• Personality
• Deen

Example:
  Overall Compatibility: 89%
  🟢 Green:  76
  🟡 Yellow: 18
  🔴 Red:     6

  Lifestyle ............ 78%
  Work & Education ..... 80%
  Family Values ........ 85%
  Marriage Goals ....... 91%
  Personality .......... 74%
  Deen ................. 95%

Privacy Protection:
  Still does NOT reveal:
  • Actual onboarding answers
  • Exact responses
  • Private profile information
  • Which specific questions caused incompatibilities
  Only category-level percentages are shown.

Pricing (confirmed 2026-07-12): 1 Unlock+ = £1.99 / 5 Unlocks+ = £4.99

------------------------------------------------------------
UI Notes
------------------------------------------------------------

• Unlock button shown on the profile card.
• Remaining unlock balance displayed clearly within
  the profile view.
• Compatibility score shown in a clean, easy-to-read
  format after unlock is used.
• Green / Yellow / Red counts displayed prominently.

------------------------------------------------------------
Notes
------------------------------------------------------------

• Never reveals photos.
• Never bypasses privacy settings.
• Uses the Green / Yellow / Red compatibility system.
• Optional, purchasable feature.
• Seeker only — not available to Wali.

============================================================
APPROVED TO-DO LIST
============================================================

• Decide final feature name (Profile Unlock vs
  Compatibility Preview vs Insight Unlock).
• Confirm final compatibility categories for Unlock+
  (current set pending: Lifestyle, Work & Education,
  Family Values, Marriage Goals, Personality, Deen).
• Define the complete Green / Yellow / Red scoring
  methodology.
• Define what "Saved" and "Liked" stages look like
  in the UI so users understand the unlock trigger.
• Design the unlock button UI on the profile card.
• Design the balance display within the profile view.
• Decide whether unused purchased unlocks expire or
  carry forward indefinitely.
