FEATURE NAME
SEEKER ONBOARDING QUESTIONS
Document: Summary

============================================================
SUMMARY
============================================================

Status: Approved
Last Updated: 2026-06-28
Change: Restructured from 4-section to 5-chapter model.

RESOLVED 2026-07-25 (OA-ZYRA-140 item 9, Founder decision:
"Classification doc is authoritative"). This document and Flow
Diagram.md previously described a ~69-question, 10-category
structure (5 Core + 5 Extended) that was never actually built.
"Chapter 3 Classification — Ch4 Mapping.md" (same date, marked
"V3 — APPROVED") specifies the real structure — 104 Chapter 3
questions + 70 Chapter 4 preference questions across 9
categories — and live code (chapter3_categories.dart) already
implements exactly that. The CATEGORY STRUCTURE and QUESTION
TOTALS sections below are rewritten to match the Classification
doc; that document remains the authoritative per-question
source, this Summary gives the structural overview.

Purpose:
Owns the Seeker onboarding experience and question flow
used to build a marriage profile and compatibility engine.

Owns:
• Seeker onboarding
• System information collection
• Public profile questions
• Private values questions (Chapter 3)
• Compatibility preferences — traffic light system (Chapter 4)
• Category summaries with expandable cards
• Transition pages between chapters
• Onboarding UX rules and principles

Note:
• Wali onboarding will be developed separately.

------------------------------------------------------------
CORE PHILOSOPHY
------------------------------------------------------------

The onboarding experience should feel like preparing for a
meaningful journey rather than completing a registration form.

Users are encouraged to take their time, knowing they can
leave and return whenever they wish.

The experience should communicate:
"We're helping you find the right match, not the quickest one."

------------------------------------------------------------
FIVE-CHAPTER STRUCTURE
------------------------------------------------------------

Chapter 1 — About You
  Establishes identity for the system.
  3 questions. Not displayed publicly as-is.

Chapter 2 — Your Profile
  Builds the public and semi-public profile.
  8 questions. Revealed progressively during matching.

Chapter 3 — Your Values
  Private answers about the user's own circumstances,
  values and life. Teaching ZYRA who they are.
  104 questions across 9 categories (see Chapter 3
  Classification — Ch4 Mapping.md). Private — never shown
  on profile.

Chapter 4 — Your Preferences
  Traffic-light preferences. Teaching ZYRA who they're
  looking for. One preference question per Chapter 3 topic
  that has a confirmed Chapter 4 mapping (not every Chapter 3
  question does — some are descriptive-only).
  70 questions. Private — used only by compatibility engine.

Chapter 5 — Profile Ready
  Profile review, ID verification, photo check status.
  Profile goes live automatically once all checks pass.

------------------------------------------------------------
KEY ARCHITECTURAL DECISION — VALUES BEFORE PREFERENCES
------------------------------------------------------------

Chapters 3 and 4 are deliberately separated.

Chapter 3 collects ALL "About You" answers first.
Chapter 4 collects ALL compatibility preferences second.

This replaces the previous interleaved pattern where each
question asked "About You" then immediately asked for
compatibility preferences on the same screen.

Reason: Separation of cognitive modes. The user first
reflects entirely on themselves (Chapter 3), then shifts
entirely to reflecting on what they want in a partner
(Chapter 4). This is more natural and less fatiguing.

------------------------------------------------------------
INFORMATION VISIBILITY
------------------------------------------------------------

SYSTEM (internal only)
• Name (first + last)
• Gender
• Date of Birth

LEVEL 1 — Browse (visible immediately on profile card)
• Main photo
• First name
• Age
• Location (city only)

LEVEL 2 — Profile Unlock (after mutual match)
• All photos
• Sect
• Revert Status
• Country of Birth
• Nationality
• Ethnicity
• Languages Spoken

PRIVATE — Your Values (never displayed publicly)
• All Chapter 3 responses
• Used only by ZYRA's compatibility engine

PRIVATE — Your Preferences (never displayed publicly)
• All Chapter 4 traffic-light preferences
• Used only by ZYRA's compatibility engine

------------------------------------------------------------
THREE DECISION STAGES (Browse Experience)
------------------------------------------------------------

1. Browse
   "Am I interested?"

2. Profile Unlock
   "Are we culturally and personally compatible?"

3. Journey
   "Let's genuinely get to know each other."

The browse card is intentionally minimal. Users decide on
interest before seeing detailed profile information.

------------------------------------------------------------
CATEGORY STRUCTURE
------------------------------------------------------------

Chapter 3 & 4 share the same 9-category order (per Chapter 3
Classification — Ch4 Mapping.md, matching chapter3_categories.dart):

1. Family
2. Education & Finances
3. Marriage Goals
4. Faith
5. Lifestyle
6. Household Roles & Expectations
7. Communication & Emotional Intelligence
8. Technology & Digital Lifestyle
9. Health & Well-Being

------------------------------------------------------------
CATEGORY SUMMARY
------------------------------------------------------------

At the end of every category, users review all answers
before continuing.

Chapter 3 summary — shows only "Your Answer" per question.
Chapter 4 summary — shows traffic light preference per option.

Collapsed card example (Chapter 3):
  ▶ Annual Income
  Your Answer      £75k–99k

Expanded card example (Chapter 4):
  ▼ Annual Income
  £100k+           🟢
  £75k–99k         🟢
  £50k–74k         🟡
  £25k–49k         🔴
  Below £25k       🔴
  ────────────────────
  Your Answer      £75k–99k

Rules:
• "Your Answer" is never colour coded.
• Users can edit any answer before continuing.
• Only one card expands at a time.

Category completion screen:
  ✓ [Category Name] Complete
  [Edit Category]    [Continue]

------------------------------------------------------------
CHAPTER PROGRESS INDICATOR
------------------------------------------------------------

All screens show 5 dots representing 5 chapters.
Dot states: ● Active  ✓ Done  ○ Pending

Progress bar tracks completion within the current chapter.
Bar resets to 0% at the start of each new chapter.
Bar fills to 100% at each chapter complete transition.

------------------------------------------------------------
QUESTION TOTALS
------------------------------------------------------------

Pre-Onboarding    Account Creation
Chapter 1         3 questions    About You
Chapter 2         8 questions    Your Profile
Chapter 3       104 questions    Your Values (9 categories)
Chapter 4        70 questions    Your Preferences (traffic-light,
                                 one per Ch3 question with a
                                 confirmed Ch4 mapping)
─────────────────────────────────────────────────
Total           185 questions

(Chapter 3 + Chapter 4 combined = 174 questions — see Chapter 3
Classification — Ch4 Mapping.md "FINAL COUNTS" for the exact
per-category breakdown and REQUIRED/OPTIONAL split.)

------------------------------------------------------------
PHOTO REQUIREMENTS
------------------------------------------------------------

• Minimum 3 photos required to proceed past photo screen.
• Maximum 6 photos.
• First photo becomes main profile photo.
• Hold and drag to reorder.
• AI photo check runs in background during onboarding
  (nudity detection, face detection, quality check).
• Profile does not go live until photo check passes.
• No message sent during onboarding — single status
  screen shown at the end of Chapter 5.

------------------------------------------------------------
PROFILE NOT LIVE — END STATE
------------------------------------------------------------

If profile cannot go live immediately after onboarding:
  "Your profile isn't live yet."

Possible reasons (shown as checklist):
  ○ Photos are being reviewed — usually within a few hours.
  ○ ID verification is pending.

Profile goes live automatically when all checks pass.
No emails or push notifications during the check period.

------------------------------------------------------------
APPROVED DESIGN PRINCIPLES
------------------------------------------------------------

• Onboarding feels like a guided journey through chapters,
  not a form sequence.
• Transitions are first-class screens with meaningful content.
• Chapter names reflect what the user is doing, not
  system terminology.
• Values and Preferences are cognitively separate stages.
• Category summaries provide transparency and allow review.
• Structured data (predefined lists) used wherever practical.
• Free text only where no practical structured alternative
  exists.
• The experience should feel thoughtful, calm, and
  intentional — finding the right match, not the fastest.

============================================================
APPROVED TO-DO LIST
============================================================

• Design Wali onboarding flow.
• Confirm Chapter 3 detailed question specs per category.
• Confirm Chapter 4 traffic-light matrix per question.
• Confirm Hard Requirement support per question.
• Build the Green / Yellow / Red compatibility system.
• Design compatibility scoring algorithm.
• Design Category Summary expandable card UI.
• Finalise transition page wording (see Onboarding Rules).
• Design men-only conditional display logic for
  Masjid attendance question.
• Design Profile Ready / not-live end screen.
• Review extended question list after user testing.
• Decide which extended questions affect compatibility
  scoring vs informational only.

