FEATURE NAME
SEEKER ONBOARDING QUESTIONS
Document: Onboarding Rules & UX

============================================================
ONBOARDING RULES & UX
============================================================

Status: Approved
Last Updated: 2026-06-28

------------------------------------------------------------
SCREEN ANATOMY — EVERY QUESTION SCREEN
------------------------------------------------------------

Safe Viewport
  All layout uses relative units and env(safe-area-inset-*).
  No fixed pixel heights for content areas.
  Smallest supported device (iPhone SE, 375×667pt) is
  the baseline. Larger screens breathe; nothing is cropped.
  If content overflows, the content area scrolls naturally.
  The top bar, privacy indicator, and FAB are sticky.

Top Bar (single row, always present)
  [Progress area — flex-grows to fill] [···]

  Progress area contains:
    Chapter name (e.g. YOUR PROFILE) — top left, small caps
    Chapter % complete               — top right, small
    Thin progress bar                — underneath, full width

  ··· (three bare dots, no circle, no background)
    Opens the help bottom sheet.

No back button
  Users navigate back by swiping right (iOS standard gesture).
  No back button is shown on any question screen.

Content area
  Scrollable if content overflows.
  Contains question heading, subtext, and input/options.

Privacy indicator
  Sits at the bottom of the content area, above the FAB zone.
  Subtle — a small coloured dot + plain text. No card, no box.
  Right padding: 52px minimum to avoid FAB overlap.

  Three states:
    🟢  PUBLIC PROFILE
        "Visible when people browse your profile."
        Dot colour: rgba(61,154,106,0.85)
        Text colour: rgba(100,200,140,0.5)

    🟡  PROFILE UNLOCK
        "Visible only after a mutual match."
        Dot colour: rgba(196,154,68,0.85)
        Text colour: rgba(220,185,100,0.45)

    🔒  PRIVATE COMPATIBILITY
        "Only you and ZYRA can see this answer."
        Dot colour: rgba(138,106,158,0.7)
        Text colour: rgba(180,150,210,0.45)

FAB (continue button)
  Always visible. Never hidden.
  Position: bottom right, 14px from bottom, 16px from right.
  Size: 26px circle (same as all icon buttons).
  Dimmed state: background rgba(255,255,255,0.04),
                border rgba(255,255,255,0.09),
                arrow rgba(255,255,255,0.2)
  Active state:  background rgba(255,255,255,0.1),
                border rgba(255,255,255,0.22),
                arrow rgba(255,255,255,0.85)
  Transition: smooth animate between states on valid selection.

Glass pill button (transition screens only)
  Used on chapter transition screens — not on question screens.
  Full-width pill (or near full-width).
  Background: rgba(255,255,255,0.1)
  Backdrop filter: blur(12px)
  Border: 0.5px solid rgba(255,255,255,0.22)
  Border radius: 50px
  Text: Jost Light 300, rgba(255,255,255,0.85), 0.8px letter-spacing

------------------------------------------------------------
CHAPTER PROGRESS SYSTEM
------------------------------------------------------------

5 chapters total:
  1 — About You
  2 — Your Profile
  3 — Your Values
  4 — Your Preferences
  5 — Profile Ready

Progress bar
  Tracks completion within the current chapter only.
  Resets to 0% at the start of each new chapter.
  Fills to 100% at the chapter complete transition.
  Fill colour: rgba(255,255,255,0.28)
  Track colour: rgba(255,255,255,0.07)
  Height: 1.5px

Chapter name label
  Shows the current chapter name in small caps.
  e.g. "YOUR PROFILE", "YOUR VALUES"

Chapter complete — progress bar colour
  Switches to rgba(80,180,120,0.6) green fill at 100%.

------------------------------------------------------------
TRANSITION SCREENS
------------------------------------------------------------

All transition screens are scrollable.
The glass pill button is placed below the fold.
Users must scroll to reach it — confirms they have read
the content (similar to T&C scroll-to-accept pattern).

A bouncing chevron (↓) hints that the user should scroll.

Content on transition screens:
  • Chapter complete badge (✓ + green)
  • Body text explaining what comes next and why
  • Chapter roadmap (✓ Done / ● Active / ○ Pending)
  • Next chapter preview card
  • Glass pill button (below fold)

------------------------------------------------------------
··· HELP BOTTOM SHEET
------------------------------------------------------------

Opened by tapping ··· on any question screen.
Presented as a bottom sheet with handle.

Structure:
  Header: "Need help?"

  First item (changes per page):
    "Why do we ask for your [question topic]?"
    e.g. "Why do we ask for your date of birth?"
         "Why do we ask about your sect?"
         "Why do we ask about income?"

  Fixed items (always present, in this order):
    Help Centre
    Report a technical issue
    Report a billing issue
    Suggest an idea
    Contact Support

All items are tappable rows with a chevron (›).
First item uses stronger text weight than the fixed items.

------------------------------------------------------------
PRIVACY INDICATOR — ASSIGNMENT BY QUESTION
------------------------------------------------------------

Chapter 1 — About You
  Name              🟢  PUBLIC PROFILE
  Gender            🟢  PUBLIC PROFILE
  Date of Birth     🔒  PRIVATE — DOB specific text:
                        "Your date of birth stays private.
                         Only your age is shown publicly."

Chapter 2 — Your Profile
  Photos            🟢  PUBLIC PROFILE
  Location          🟢  PUBLIC PROFILE
                        "Only your city is shown publicly.
                         Your exact address is never stored."
  Sect              🟡  PROFILE UNLOCK
  Revert Status     🟡  PROFILE UNLOCK
  Country of Birth  🟡  PROFILE UNLOCK
  Nationality       🟡  PROFILE UNLOCK
  Ethnicity         🟡  PROFILE UNLOCK
  Languages Spoken  🟡  PROFILE UNLOCK

Chapter 3 — Your Values
  All questions     🔒  PRIVATE COMPATIBILITY
                        "Only you and ZYRA can see this answer."

Chapter 4 — Your Preferences
  All questions     🔒  PRIVATE COMPATIBILITY
                        "Only you and ZYRA can see this answer."

------------------------------------------------------------
FIELD VALIDATION
------------------------------------------------------------

Required fields
  FAB stays dimmed until a valid answer is given.
  FAB never disappears — always visible, dimmed or active.

Optional fields
  FAB is active immediately (e.g. Last Name in Q1).
  Optional status is noted below the field.

Under-18 validation (Date of Birth)
  Red error bar: "You must be 18 or older to join ZYRA."
  FAB remains dimmed.
  Cannot proceed.

Photo minimum (Photo screen)
  FAB dimmed until minimum 3 photos added.
  Counter text updates: "X more to continue" / "X of 6 added."

Compatibility validation (Chapter 4)
  At least one 🟢 or 🟡 per question.
  If all options are 🔴:
    Warning: "At least one option must remain 🟢 or 🟡 so
    ZYRA can introduce compatible matches."
  Cannot proceed until corrected.

------------------------------------------------------------
SECT QUESTION — SPECIAL BEHAVIOUR
------------------------------------------------------------

Options: Sunni / Shia / Ibadi / Other / Prefer not to say

If "Other" is selected:
  The Other option expands inline to reveal a text input.
  Placeholder: "e.g. Sufi, Ahmadi…"
  FAB activates once text is entered (minimum 2 characters).

"Prefer not to say" is visually distinct (dashed border,
dimmer text) to signal it is a soft opt-out rather than
a real answer.

------------------------------------------------------------
PHOTO SCREEN — SPECIAL BEHAVIOUR
------------------------------------------------------------

Minimum 3 photos required.
Maximum 6 photos.
First uploaded photo becomes the main profile photo.
Photos can be reordered by hold-and-drag.
Tap a photo to remove or replace.

AI photo check
  Runs in background as soon as photos are uploaded.
  Checks: nudity, face presence, image quality.
  No interruption during onboarding.
  Shown only as a subtle status line once 3+ photos added:
    "· Photos are being reviewed in the background."
  Profile does not go live until check passes.

------------------------------------------------------------
TRANSITION — PRIVATE VALUES (before Chapter 3)
------------------------------------------------------------

Appears: After Chapter 2 complete, before Chapter 3.

Content:
  🔒 Your answers are private.

  "The next chapter asks about your values, faith and life.
   Your answers are never shown on your profile.
   They are only used by ZYRA to find more compatible people."

  🤲 A reminder from Islam
  "All of my Ummah will be forgiven except those who
  publicize their sins."
  — Sahih al-Bukhari 6069

  "Islam teaches us to protect our dignity. In the same
   spirit, your answers remain private and are never
   displayed publicly."

  Glass pill button: "Begin Your Values" (below fold)

------------------------------------------------------------
TRANSITION — HOW PREFERENCES WORK (before Chapter 4)
------------------------------------------------------------

Appears: After Chapter 3 complete, before Chapter 4.

Content:
  🚦 Your preferences

  "Now ZYRA needs to understand who you're looking for.
   For each topic, you'll see the possible answers and
   tell us how you feel about each one."

  The colours always mean the same thing:

  🟢 Open
  You're happy for ZYRA to introduce people with this answer.

  🟡 Flexible
  It depends on the individual or the situation.

  🔴 Not Preferred
  You'd prefer not to be introduced to people with this answer.

  Sometimes you'll see a Hard Requirement option after
  selecting 🔴.
  Enable it and ZYRA will never introduce anyone with that
  specific answer. Leave it off and ZYRA may still introduce
  exceptional matches.

  Example:
    Previous marriage status
    Never Married    🟢
    Divorced         🔴
    Widowed          🟢
    ─────────────────────
    ☑ Never show me divorced people.

  Glass pill button: "Set Your Preferences" (below fold)

------------------------------------------------------------
GLOBAL TRAFFIC LIGHT RULES (Chapter 4)
------------------------------------------------------------

Meaning (never changes):
  🟢 = Open / most compatible
  🟡 = Flexible / depends
  🔴 = Not preferred / outside preference

Wording beside each traffic light changes per question.
Colour meaning never changes.

Skip behaviour
  If the user selects Skip:
    Record 🟢 (No Preference) automatically.
    Do not display Hard Requirement.
    Continue to next question.

Hard Requirement
  Only shown when one or more 🔴 selections exist.
  Generated dynamically from selected 🔴 answers.
  Examples:
    ☑ Never show me divorced people.
    ☑ Never show me smokers.
    ☑ Never show me people with children.
  If no 🔴 selections: Hard Requirement not shown.

Display pattern per question:
  Questions with 3+ options → traffic light table
  Yes/No questions → single traffic light question

------------------------------------------------------------
LOCATION-AWARE QUESTIONS
------------------------------------------------------------

Questions that depend on location adapt automatically
based on the user's selected country or region.
Examples: Annual Income ranges, Mahr Budget, currency.
The onboarding flow itself does not change.

------------------------------------------------------------
COLOUR SYSTEM
------------------------------------------------------------

Source of truth: ZYRA/BUSINESS/COLOUR THEME/Summary.md
Brand palette:   Royal Purple #8A6A9E | Luxury Dark Purple #3D2A4A
                 Royal Blue #3D5A80   | Rose Pink #D4868F

Three background variants — derived from official brand palette:

ZYRA Brand / Gender Neutral (Chapter 1 Q1 only — before gender set):
  linear-gradient(175deg, #2a1840 0%, #160c2e 50%, #080318 100%)
  Hue derived from: Royal Purple #8A6A9E

Male Seeker (Chapter 1 Q2 onwards for male, all Wali screens):
  linear-gradient(175deg, #111f30 0%, #0a1520 50%, #040b14 100%)
  Hue derived from: Royal Blue #3D5A80

Female Seeker (Chapter 1 Q2 onwards for female):
  linear-gradient(175deg, #2e1018 0%, #1c0b10 50%, #0d060a 100%)
  Hue derived from: Rose Pink #D4868F

Accent (selected options — purple, all themes):
  bg rgba(154,114,190,0.14) / border rgba(154,114,190,0.4)

NOTE: A darker privacy/Wali variant was previously listed.
This variant is REJECTED. All screens use the gender-appropriate
background above. No additional darkening is applied.

Progress bar: rgba(255,255,255,0.28) fill / rgba(255,255,255,0.07) track
Icon buttons: rgba(255,255,255,0.07) bg / 0.5px rgba(255,255,255,0.14) border
Ch complete:  rgba(80,180,120,0.6) progress fill

------------------------------------------------------------
TYPOGRAPHY
------------------------------------------------------------

Font: Jost (Google Fonts)
  Weights: 200 (headings/wordmark), 300 (body/subtext), 400 (buttons)

Question heading:    Jost 200, ~19–20px
Subtext:             Jost 300, 8.5px
Option text:         Jost 300, 10px
Chapter name label:  Jost 300, 7px, letter-spacing 0.8px
Privacy indicator:   Jost 300, 8px
Progress %:          Jost 300, 7px

