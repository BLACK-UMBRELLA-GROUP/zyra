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
CHAPTER 3 — YOUR VALUES                           (~29 Qs)
============================================================

Purpose: Teaching ZYRA who you are.
         All answers are private — never shown on profile.
         Used only by ZYRA's compatibility engine.

NOTE: Chapter 3 contains only "About You" answers.
      Compatibility preferences (traffic lights) are
      collected entirely in Chapter 4.

  CATEGORY — FAMILY
  Previous Marriage Status
  Do You Have Children?
  Category Summary
        │
        ▼
  CATEGORY — EDUCATION & FINANCES
  Highest Education Level
  Employment Status
  Annual Income
  Financial Readiness for Marriage
  Preferred Mahr Budget
  Category Summary
        │
        ▼
  CATEGORY — MARRIAGE GOALS
  Do You Want Children?
  Marriage Structure
  Category Summary
        │
        ▼
  CATEGORY — FAITH
  How Often Do You Pray?
  How Often Do You Read The Quran?
  Quran Memorisation
  Do You Fast During Ramadan?
  Do You Pay Zakat?
  Have You Performed Umrah?
  Have You Performed Hajj?
  Approach To Riba Financial Products
  Category Summary
        │
        ▼
  CATEGORY — LIFESTYLE
  Do You Smoke Or Vape?
  Are You Willing To Relocate?
  Category Summary
        │
        ▼
  CATEGORY — HOUSING & LIVING
  Current Living Situation
  Preferred Post-Marriage Living Arrangement
  Category Summary
        │
        ▼
  CATEGORY — FINANCIAL
  Current Debt Situation
  Do You Currently Have A Mortgage?
  Category Summary
        │
        ▼
  CATEGORY — FAITH (EXTENDED)
  Do You Observe Sunnah Fasts?
  [Men Only] Masjid Attendance For Congregational Prayer
  Category Summary
        │
        ▼
  CATEGORY — MARRIAGE EXPECTATIONS
  View On Household Finances
  Category Summary
        │
        ▼
  CATEGORY — ADDITIONAL
  Do You Own A Car Or Motorbike?
  How Often Do You Read Surah Al-Baqarah At Home?
  View On Pictures Or Statues In The Home
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
CHAPTER 4 — YOUR PREFERENCES                      (~29 Qs)
============================================================

Purpose: Teaching ZYRA who you're looking for.
         Based on the answers given in Chapter 3.
         Each topic from Chapter 3 reappears here as a
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

