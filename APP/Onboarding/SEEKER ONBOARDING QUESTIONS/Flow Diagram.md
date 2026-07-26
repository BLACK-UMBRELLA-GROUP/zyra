FEATURE NAME
SEEKER ONBOARDING QUESTIONS
Document: Flow Diagram

============================================================
FLOW DIAGRAM
============================================================

Status: Approved
Last Updated: 2026-06-28
Change: Restructured from 4-section to 5-chapter model.
        "Your Values" and "Your Preferences" are now
        separate dedicated chapters.

------------------------------------------------------------
PRE-ONBOARDING
------------------------------------------------------------

Open App
        │
        ▼
Splash Screen
        │
        ▼
Welcome Screen (Sign in with Apple / Google / Email)
        │
        ▼
Auth Loading State
        │
        ▼
Choose Account Type
  ○ Seeker
  ○ Wali
        │
        ▼
Account Created
        │
        ▼

------------------------------------------------------------
TRANSITION — Welcome to ZYRA
------------------------------------------------------------

  Small logo mark
  "Welcome to ZYRA."
  Chapter roadmap (● ○ ○ ○ ○)
  "Let's begin" glass pill button
        │
        ▼

============================================================
CHAPTER 1 — ABOUT YOU                              (3 Qs)
============================================================

  Name (First required, Last optional)
        │
        ▼
  Gender (Brother / Sister)
        │
        ▼
  Date of Birth (scroll wheel, age preview)
  ↳ Under-18 validation: error bar, FAB disabled
        │
        ▼

------------------------------------------------------------
CHAPTER 1 COMPLETE TRANSITION (scrollable)
------------------------------------------------------------

  ✓ Chapter 1 complete
  Chapter roadmap: ✓ ● ○ ○ ○
  Chapter 2 preview card
  "Begin Your Profile" glass pill button (below fold)
        │
        ▼

============================================================
CHAPTER 2 — YOUR PROFILE                           (8 Qs)
============================================================

  Photos
  ↳ Minimum 3 required. Up to 6.
  ↳ AI photo check runs in background (nudity, face, quality)
  ↳ FAB disabled until 3 photos added
        │
        ▼
  Location (city search + GPS shortcut)
        │
        ▼
  Sect
  ↳ "Other" expands to free text field
        │
        ▼
  Revert Status
        │
        ▼
  Country of Birth
        │
        ▼
  Nationality
        │
        ▼
  Ethnicity
        │
        ▼
  Languages Spoken
        │
        ▼

------------------------------------------------------------
CHAPTER 2 COMPLETE TRANSITION (scrollable)
------------------------------------------------------------

  ✓ Chapter 2 complete
  Chapter roadmap: ✓ ✓ ● ○ ○
  Chapter 3 preview card
  "Begin Your Values" glass pill button (below fold)
        │
        ▼

------------------------------------------------------------
TRANSITION — Private Values (before Chapter 3)
------------------------------------------------------------

  🔒 Private
  Explains that Chapter 3 answers are private.
  References Islamic principle of protecting dignity.
  "Continue" glass pill button (below fold, scrollable)
        │
        ▼

============================================================
CHAPTER 3 — YOUR VALUES                          (104 Qs)
============================================================

RESOLVED 2026-07-25 (OA-ZYRA-140 item 9, Founder decision:
"Classification doc is authoritative"). The 5-core/5-extended,
~29-question category walkthrough previously shown here was
never built. Live code (chapter3_categories.dart) implements
the 9-category, 104-question structure ratified in "Chapter 3
Classification — Ch4 Mapping.md" (V3 — APPROVED); that document
is the authoritative full per-question list. The flow below
shows the real category sequence with one illustrative example
question per category rather than duplicating all 104 inline.

Purpose: Teaching ZYRA who you are.
         All answers are private — never shown on profile.
         Used only by ZYRA's compatibility engine.

NOTE: Chapter 3 contains only "About You" answers.
      Compatibility preferences (traffic lights) are
      collected entirely in Chapter 4.

  CATEGORY — FAMILY (10 Qs)
  e.g. Previous Marriage Status, Do You Have Children?
  Category Summary
        │
        ▼
  CATEGORY — EDUCATION & FINANCES (12 Qs)
  e.g. Highest Education Level, Annual Income
  Category Summary
        │
        ▼
  CATEGORY — MARRIAGE GOALS (10 Qs)
  e.g. Marriage Timeline, Views on Polygamy
  Category Summary
        │
        ▼
  CATEGORY — FAITH (19 Qs)
  e.g. Daily Prayers, Zakat, [Men Only] Masjid Attendance
  Category Summary
        │
        ▼
  CATEGORY — LIFESTYLE (12 Qs)
  e.g. Smoking & Vaping, Personality
  Category Summary
        │
        ▼
  CATEGORY — HOUSEHOLD ROLES & EXPECTATIONS (10 Qs)
  e.g. Household Responsibilities, Financial Provider
  Category Summary
        │
        ▼
  CATEGORY — COMMUNICATION & EMOTIONAL INTELLIGENCE (12 Qs)
  e.g. Communication Style, Conflict Resolution
  Category Summary
        │
        ▼
  CATEGORY — TECHNOLOGY & DIGITAL LIFESTYLE (8 Qs)
  e.g. Social Media Usage, Mobile Phone Boundaries
  Category Summary
        │
        ▼
  CATEGORY — HEALTH & WELL-BEING (11 Qs)
  e.g. Physical Fitness, Dietary Requirements
  Category Summary
        │
        ▼

------------------------------------------------------------
CHAPTER 3 COMPLETE TRANSITION (scrollable)
------------------------------------------------------------

  ✓ Chapter 3 complete
  Chapter roadmap: ✓ ✓ ✓ ● ○
  Chapter 4 preview card
  "Set Your Preferences" glass pill button (below fold)
        │
        ▼

------------------------------------------------------------
TRANSITION — How Preferences Work (before Chapter 4)
------------------------------------------------------------

  🚦 Explains traffic light system
  🟢 Open  🟡 Flexible  🔴 Not Preferred
  Hard Requirement explanation
  Example shown
  "Continue" glass pill button (below fold, scrollable)
        │
        ▼

============================================================
CHAPTER 4 — YOUR PREFERENCES                      (70 Qs)
============================================================

RESOLVED 2026-07-25 (OA-ZYRA-140 item 9): 70 questions, one per
Chapter 3 question with a confirmed Chapter 4 mapping (not every
Chapter 3 question has one — some are descriptive-only; see
Chapter 3 Classification — Ch4 Mapping.md "CHAPTER 4 CONFIRMED
LIST" for the exact 70).

Purpose: Teaching ZYRA who you're looking for.
         Based on the answers given in Chapter 3.
         Each mapped Chapter 3 topic reappears here as a
         preference question using the traffic light system.

Pattern per question:
  "Your answer: [their Ch3 answer]"
  ↓
  "Who would you be comfortable with?"
  ↓
  Traffic light per option (🟢 / 🟡 / 🔴)
  ↓
  Dynamic Hard Requirement (where supported)
  ↓
  Continue

  Same category structure as Chapter 3.
  Categories appear in the same order.
  Category Summary after each category.
        │
        ▼

------------------------------------------------------------
CHAPTER 4 COMPLETE TRANSITION (scrollable)
------------------------------------------------------------

  ✓ Chapter 4 complete
  Chapter roadmap: ✓ ✓ ✓ ✓ ●
  "Review your profile" glass pill button (below fold)
        │
        ▼

============================================================
CHAPTER 5 — PROFILE READY
============================================================

  Profile preview
  ID Verification prompt
  Photo check status
  ↳ If photos approved + ID verified → Go Live
  ↳ If pending → "Your profile isn't live yet" screen
        │
        ▼
Discover

------------------------------------------------------------
"PROFILE NOT LIVE" SCREEN
------------------------------------------------------------

  Shown at end of onboarding if profile cannot go live.
  No notifications sent during onboarding.
  Only one message at the end.

  "Your profile isn't live yet."

  Checklist:
  ○ Photos are being reviewed — usually within a few hours.
  ○ ID verification is pending.

  Users can still explore the app in limited mode.
  Profile goes live automatically once all checks pass.

