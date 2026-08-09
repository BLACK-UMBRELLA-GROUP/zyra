FEATURE NAME
PROFILE PAGE

SCRIPT VERSION: V1
STATUS: Approved Specification
SOURCE: Master Script Part 8 (LOVABLE_CURRENT_VERSION_V1)

Terminology corrected 2026-07-12 against
ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4 — Seeker Basic/Pro/Premium
plan labels replaced with ZYRA Basic/ZYRA One; connection
categories Declined/Review/Consider replaced with
Declined/Saved/Likes (DR-076). The layout, interaction, and
reuse-the-Browse-viewer decisions below are unaffected — only
the labels were stale.

============================================================
PROFILE PAGE REWORK
============================================================

------------------------------------------------------------
PROFILE LAYOUT
------------------------------------------------------------

• Remove all white content containers.
• Remove About Me card.
• Remove Public Information card.
• Remove any large white content boxes.
• Information sits directly on the page background using
  typography and spacing only.

------------------------------------------------------------
SECTION HEADINGS
------------------------------------------------------------

Change all section headings to white.

Examples:
• ABOUT ME
• PUBLIC INFORMATION
• LANGUAGES
• MARRIAGE INTENTIONS

------------------------------------------------------------
PROFILE MEMBERSHIP LABEL
------------------------------------------------------------

Replace the generic "Member" label with the Seeker's plan.

Options:
• ZYRA Basic
• ZYRA One

Use the existing badge component.

============================================================
CONNECTION PROFILE EXPANSION
============================================================

Applies to:
• Declined
• Saved
• Likes

------------------------------------------------------------
CARD TAP BEHAVIOUR
------------------------------------------------------------

Tapping anywhere on a profile card (except action buttons)
expands the profile.

Expanded state:
• Approximately 50% screen height.
• Floating card.
• Left and right margins maintained.

------------------------------------------------------------
EXPANDED PROFILE CONTENT
------------------------------------------------------------

Display:
• Profile photos
• Name
• Age
• Location

Allow:
• Photo swiping
• Photo scrolling
• Photo indicators

Reuse the Browse profile experience.
Do not create a second profile viewer.

------------------------------------------------------------
EXPANDED ACTION BUTTONS
------------------------------------------------------------

| Category | Available Actions              |
|----------|-------------------------------|
| Declined | Save • Like • Unlock Profile   |
| Saved    | Decline • Like • Unlock Profile |
| Likes    | Decline • Save • Unlock Profile |

------------------------------------------------------------
UNLOCK BUTTON
------------------------------------------------------------

Show on:
• Collapsed cards
• Expanded cards

------------------------------------------------------------
DESIGN GOAL
------------------------------------------------------------

Connections should let users revisit profiles without
leaving the current workflow.

The expanded card should feel like a lightweight Browse
experience where users can:
• Review photos
• Reconsider decisions
• Unlock profiles

The experience should remain consistent with the Browse
profile viewer.
Never build a parallel or competing profile viewer system.

============================================================
PHASE 0 — FEATURE REVIEW RECORD
============================================================

Duplicate Existing Feature?  No — expanded card did not
previously exist in Declined, Saved or Likes.

Overlaps Existing Systems?   Yes
Affected systems:
• Profile Page
• Declined
• Saved
• Likes
• Profile Unlock
• Photo Viewer

Technical Debt Risk?  Low — reuses existing Browse
profile viewer.

MVP or Future Feature?  MVP — users need to review
profiles they previously acted on.

Better Existing Solution?  Yes — reuse Browse profile
layout, do not create a new card design.

Final Decision: BUILD NOW
Reasoning: Improves profile review workflow while
reusing existing systems.
