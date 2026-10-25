---
id: DOC-ZYRA-0039
type: SPEC
status: CURRENT
feature: APP: ONBOARDING
purpose: Onboarding / Seeker Onboarding Questions — Onboarding Rules & UX
links: []
owner: ZYRA chat
---

FEATURE NAME
SEEKER ONBOARDING QUESTIONS
Document: Onboarding Rules & UX

============================================================
ONBOARDING RULES & UX
============================================================

Status: Approved
Last Updated: 2026-06-28

CURRENT ACCOUNT-NAME OVERLAY — 2026-10-02 / DR-ZYRA-251:
The Master Product Spec governs required, public first and last names for
new Seeker and Guardian signup. One name question has two open Poppins
inputs with gold underlines; no filled answer card. Neither field may be
empty/whitespace or over 60 characters when continuing. Keyboard Next
focuses last name; Done dismisses without advancing. Both names persist
in protected same-device recovery and surname is confirmed in the existing
public surname_line field before admission. Legacy unfinished drafts return
to this question retaining valid later answers. Required Male/Female and
private DOB are unchanged. This does not force existing admitted accounts
to supply surname or add a database-wide constraint. Onboarding Preview
§89 governs the current Luma/four-profile flow; §90 records this follow-up.
Older layouts, counts and name-visibility rules below are historical where
they conflict with those current records.

CURRENT COMPATIBILITY POLICY OVERLAY — 2026-09-28:
ZYRA_PRODUCT_SPEC Part 1 section 8 / DR-ZYRA-250 govern future
capture. Versioned future labels replace the old wording: Prefer this /
Open to this / Not for me (1 / 0.5 / 0). Legacy Amber No preference is
not silently reinterpreted; only affected controls require reconfirmation,
with structural repair separately. Every applicable required answer/light
must exist. Chapter4 Skip must not invent Green or any default preference.
Old wording/auto-Green rules below are history; no app code changes here.
Governed Chapter2 skip/no-preference contribution conditions are separate.
Counterpart targeting, validation and execution boundaries follow the
policy reference; final new capture/repair copy is not deployed by filing.

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
  FAB is active immediately only for actually optional questions.
  Last Name in Q1 is REQUIRED under DR-ZYRA-251, not an example of this rule.
  Optional status is noted below the field.

Under-18 validation (Date of Birth)
  Red error bar: "You must be 18 or older to join ZYRA."
  FAB remains dimmed.
  Cannot proceed.

First account photo (DR-ZYRA-264, before Membership)
  Seeker signup requires one first photo before choosing Membership.
  It is privately staged and carried into the later Your Profile photo step.
  Upload is not a moderation verdict or public-profile completion.
  Guardian identity-only account setup has no Seeker-photo checkpoint.

Photo minimum (Your Profile photo screen)
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

Minimum 3 photos required to complete the later Your Profile photo step.
The earlier account-photo checkpoint requires one, not three (DR-ZYRA-264).
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

  Historical colour explanation — superseded for future versioned
  capture by DR-ZYRA-250; retained for chronology:

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

Historical meaning — superseded by the current policy overlay:
  🟢 = Open / most compatible
  🟡 = Flexible / depends
  🔴 = Not preferred / outside preference

Wording beside each traffic light changes per question.
Colour meaning never changes.

Historical Chapter4 Skip behaviour — not future capture authority
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

SUPERSEDED 2026-07-19 — DR-ZYRA-090, itself superseded
2026-07-25 by DR-ZYRA-094 (see update below). Founder
instruction overrode the three-variant gender-derived
background system below: onboarding no longer varies by
gender at all. Every onboarding screen now uses a single flat
Royal Purple (#8A6A9E) background, matching the Welcome
screen and every other "Default Screen" — the gender-derived
variants (and Luxury Dark Purple generally) are not to appear as backgrounds or gradients
(scoped 2026-08-12 stewardship pass: Luxury Dark Purple IS the ratified text colour ON the
Pastel Grey Lavender primary button, app-wide — see BUSINESS/COLOUR THEME/Summary.md
§Component colour rules; the prohibition here governs surfaces, not button foregrounds)
anywhere active in the app for now, though the Founder has
noted the dark shade may return as primary in future. This
section is left in place below for historical reference, not
as current behaviour — do not implement against it.
See BUSINESS/COLOUR THEME/Summary.md and
SOURCE/lib/theme/zyra_colors.dart (backgroundFor()) for the
live implementation.

UPDATE (2026-07-25) — DR-ZYRA-094 ratified the final palette
and restored the gradient fade (every theme fades into Luxury
Dark Purple #3D2A4A) for profile-context screens app-wide, via
ZyraColors.genderGradient() (DR-ZYRA-101). This does NOT
reverse DR-090's onboarding-specific rule above: onboarding
still stays flat Royal Purple regardless of gender, per
OA-ZYRA-123 ("gender accents reserved for profile only") —
confirmed still true in code (`backgroundFor()` returns
`brandGradient` for every variant). The two decisions govern
different scopes: DR-094 is the palette itself and its
profile-context application; DR-090/OA-123 is the onboarding-
specific carve-out from that application.

Source of truth: ZYRA/BUSINESS/COLOUR THEME/Summary.md
Brand palette:   Royal Purple #8A6A9E | Luxury Dark Purple #3D2A4A
                 Royal Blue #3D5A80   | Rose Pink #D4868F

Three background variants — derived from official brand palette:

ZYRA Brand / Gender Neutral (Chapter 1 Q1 only — before gender set):
  linear-gradient(175deg, #2a1840 0%, #160c2e 50%, #080318 100%)
  Hue derived from: Royal Purple #8A6A9E

Male Seeker (Chapter 1 Q2 onwards for male, all Guardian screens):
  linear-gradient(175deg, #111f30 0%, #0a1520 50%, #040b14 100%)
  Hue derived from: Royal Blue #3D5A80

Female Seeker (Chapter 1 Q2 onwards for female):
  linear-gradient(175deg, #2e1018 0%, #1c0b10 50%, #0d060a 100%)
  Hue derived from: Rose Pink #D4868F

Accent (selected options — purple, all themes):
  bg rgba(154,114,190,0.14) / border rgba(154,114,190,0.4)

NOTE: A darker privacy/Guardian variant was previously listed.
This variant is REJECTED. All screens use the gender-appropriate
background above. No additional darkening is applied.

Progress bar: rgba(255,255,255,0.28) fill / rgba(255,255,255,0.07) track
Icon buttons: rgba(255,255,255,0.07) bg / 0.5px rgba(255,255,255,0.14) border
Ch complete:  rgba(80,180,120,0.6) progress fill

------------------------------------------------------------
TYPOGRAPHY
------------------------------------------------------------

Current reading font: Poppins (Google Fonts; bundled locally)
  Weights: 200 (headings), 300 (body/subtext), 400 (buttons)

CURRENT DEFAULT OVERRIDE (Founder direct, 2026-08-24): Poppins replaces Jost
as the launch/default reading face across onboarding and the rest of the app.
Jost and every other comparison remain available in Developer Style. The ZYRA
wordmark remains locked to Syne and is not affected by reading-font selection.

UPDATED 2026-07-25 (DR-ZYRA-101 audit, Founder decision: keep the
larger, more readable sizes actually built — this spec's original
7–8.5px values were superseded, not code). Wordmark is a deliberate
exception (Playfair Display, not Jost — see zyra_text.dart header,
2026-07-18 Founder request).

Question heading:    Poppins 200, ~20px (ZyraText.heading, default)
Body text:           Poppins 300, 13px (ZyraText.body)
Subtext:             Poppins 300, 12.5px (ZyraText.subtext)
Option text:         Poppins 300, 14px (ZyraText.option)
Button text:         Poppins 400, 15px, letter-spacing 0.5 (ZyraText.button)
Chapter name label:  Poppins 300, 10px, letter-spacing 0.8px (ZyraText.chapterLabel)
Privacy indicator:   Poppins 300, 11px (ZyraText.privacyText)
Progress %:          no dedicated style built — the "X/50 profiles"-
                     style counter this would apply to was removed
                     from Browse per OA-ZYRA-125 §5; not currently
                     needed anywhere. Removed from spec rather than
                     left as a phantom requirement — re-add if a
                     future screen needs it.
