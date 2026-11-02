---
id: DOC-ZYRA-0033
type: SPEC
status: CURRENT
feature: APP: NAVIGATION
purpose: Navigation / Seeker Navigation / Script — Script V2
links: []
owner: ZYRA chat
---

FEATURE NAME
SEEKER NAVIGATION

SCRIPT VERSION: V2
STATUS: Approved Specification
SOURCE: Master Script Parts 1, 4, 5, 7

Terminology corrected 2026-07-12 against
ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4 (DR-076) — Review/Consider
action and view names replaced with Save/Like throughout. Design,
animation, and glass-system rules below are unaffected — only the
labels were stale. Note: this UI script predates the Match-is-
an-event architecture; the Connections view structure here
(Declined/Save/Like/Matched) is coarser than the Potential
Journey model in PROFILE DECISION SYSTEM (Saves/Outgoing
Potentials/Incoming Potentials/Journey Queue) — a design
pass to reconcile the two has not been done and is out of scope
for this terminology-only correction.

============================================================
DESIGN PHILOSOPHY
============================================================

ZYRA is a premium matrimonial platform for a faith community built around:
• Trust
• Family involvement
• Simplicity
• Premium design
• Photo-first browsing
• Consistent interactions

Reference quality:
• Instagram
• Apple Music
• Threads
• Tinder
• Bumble

------------------------------------------------------------
OFFICIAL COLOUR SYSTEM
------------------------------------------------------------

Brand:         Purple Gradient  #8A6A9E → #3D2A4A
Male Accounts: Blue Gradient    #3D5A80 → #3D2A4A
Female Accounts: Pink Gradient  #D4868F → #3D2A4A

Rules:
• Use uploaded colour references as source of truth.
• Do not modify gradients.
• Do not create alternative shades.

------------------------------------------------------------
UNIVERSAL HEADER
------------------------------------------------------------

Display only the ZYRA branding.

Do not display subscription labels:
• Basic
• Pro
• Premium
• Guardian plans

------------------------------------------------------------
HEADER CONTROLS
------------------------------------------------------------

Normal Users:
• Notification Bell

Developer Mode:
• Back
• Home
• Bell

============================================================
GLASS DESIGN SYSTEM
============================================================

Glassmorphism is the primary visual language.

Shared styling applies to:
• Navigation
• Toggle
• Bell
• Developer buttons
• Decision strip
• Cards
• Floating Buttons
• Future Floating Components

Shared properties:
• Frosted Glass
• Background Blur
• Soft Transparency
• Rounded Corners
• Subtle Border
• Soft Shadow

There is one universal Glass System.
Never mix multiple glass styles.

============================================================
UNIVERSAL NAVIGATION SYSTEM
============================================================

One navigation architecture for all Seeker pages.

------------------------------------------------------------
UNIVERSAL TOGGLE
------------------------------------------------------------

• Fixed on the far left.
• Never changes page.
• Switches between Navigation Mode and Action Mode.
• Only the icon changes.

Toggle Icons:
| Page        | Icon             |
|-------------|------------------|
| Browse      | Magnifying Glass |
| Connections | Connections Icon |
| Guardian        | Shield Icon      |
| Network     | Network Icon     |
| Profile     | User Icon        |

Future pages provide their own icon while keeping Toggle fixed.

------------------------------------------------------------
NAVIGATION MODE
------------------------------------------------------------

Shows destinations only.
Never display the current page in the navigation list.
The Toggle always represents the current page.
Never display a page twice.

------------------------------------------------------------
ACTION MODE
------------------------------------------------------------

Browse:
• Decline
• Save
• Like

Connections:
• Declined
• Save
• Like
• Matched

Future pages may define their own Action Bars using the
same Toggle system.

------------------------------------------------------------
CONTINUOUS INTERACTION
------------------------------------------------------------

The Toggle Button and Action Bar behave as one interaction
surface.

Support:
• Tap → Hold → Slide → Release
Without lifting the user's finger.

------------------------------------------------------------
NAVIGATION ANIMATIONS
------------------------------------------------------------

Switching between Navigation Mode and Action Mode uses:
• Fade
• Scale
• Glass Morph
• Smooth easing

Transitions should never snap.

------------------------------------------------------------
BOTTOM NAVIGATION
------------------------------------------------------------

Use floating Glass Navigation.

Requirements:
• Background Blur
• Frosted Glass
• Rounded Corners
• Soft Shadow
• Floating appearance

Reference quality: Instagram
Maintain ZYRA styling.

============================================================
DECISION STRIP
============================================================

Replace separate decision buttons with one connected
floating Decision Strip.

Position: Centered directly above the Bottom Navigation.

------------------------------------------------------------
DECISION STRIP LAYOUT
------------------------------------------------------------

Three connected sections:
• Decline (✕)
• Save (✓)
• Like (✓✓)

All sections share:
• Glass styling
• Blur
• Shadow
• Height
• Width
• Border Radius

No coloured circular buttons.

------------------------------------------------------------
DECISION STRIP STATES
------------------------------------------------------------

Idle:
• Same transparency as Bottom Navigation.

Pressed:
• Higher opacity
• More blur
• Slight scale animation
• Maintain premium glass appearance.

------------------------------------------------------------
TOUCH TARGET
------------------------------------------------------------

Use generous invisible touch targets so nearby touches
still activate the intended section.

------------------------------------------------------------
PROFILE DECISIONS
------------------------------------------------------------

• Decline   → Declined
• Save      → Save
• Like      → Like

------------------------------------------------------------
PROFILE TRANSITION
------------------------------------------------------------

After every decision, animate to the next profile.

Preferred transition: Swipe Right → Left

Reference: Tinder / Bumble / Instagram Stories

------------------------------------------------------------
DECISION FEEDBACK
------------------------------------------------------------

Do not use toast notifications.

Provide feedback through Decision Strip animation:
• Brightens
• Expands slightly
• Pulses once
• Glass highlight sweep

Load the next profile simultaneously.

============================================================
CONNECTIONS SYSTEM
============================================================

Connections is a relationship management system rather
than a messaging page.

Users should feel they are organising relationships
instead of navigating separate pages.

Movement between views should feel instant.

------------------------------------------------------------
CONNECTIONS ACTION BAR
------------------------------------------------------------

When Connections is active, Action Mode displays:
• Declined
• Save
• Like
• Matched

These are views within the Connections page.
They are NOT separate pages.

------------------------------------------------------------
CONNECTION ICONS
------------------------------------------------------------

| View     | Icon | Accent       |
|----------|------|--------------|
| Declined | ✕    | Soft Red     |
| Save     | ✓    | Soft Yellow  |
| Like     | ✓✓   | Soft Green   |
| Matched  | ♡    | Heart        |

All icons share:
• Glass styling
• Blur
• Shadow
• Animation
• Size

Only the icon and subtle accent colour change.

------------------------------------------------------------
NAVIGATION TOGGLE IN CONNECTIONS
------------------------------------------------------------

The Toggle Button is not a Back button.
Its only purpose is switching between Navigation Mode
and Action Mode.
The current page remains Connections.
No reload. No transition.

When Navigation Mode is active, the Toggle icon becomes
the Connections icon. Selecting it restores the Connections
Action Bar without leaving the page.

------------------------------------------------------------
DECLINED VIEW
------------------------------------------------------------

Display:
• Heading: Recently Declined
• Subtitle: Last 5 skipped profiles

Each profile contains:
• Photo
• Name
• Age
• Location

Actions:
• Move to Save
• Move to Like

------------------------------------------------------------
SAVE VIEW
------------------------------------------------------------

Display:
• Heading: Save
• Progress: X / 50

Actions:
• Move to Declined
• Move to Like

Note: 50 is the Save cap only. Like has no cap.

------------------------------------------------------------
LIKE VIEW
------------------------------------------------------------

Display:
• Heading: Like

Actions:
• Move to Declined
• Move to Save

------------------------------------------------------------
MATCHED VIEW
------------------------------------------------------------

Display:
• Profile Photo
• Name
• Age
• Location

Actions:
• Timeline
• Message

Use identical Glass Card styling.

------------------------------------------------------------
RELATIONSHIP TIMELINE
------------------------------------------------------------

Selecting Timeline opens a vertical relationship timeline.

Example progression:
• Saved Profile
• They Saved You
• Matched
• Profile Unlocked
• Started Chat

Use elegant Glassmorphism styling.

------------------------------------------------------------
MESSAGING
------------------------------------------------------------

Selecting Message opens the existing production Chat system.
Never create a second messaging implementation.
Reuse the production chat architecture.

------------------------------------------------------------
GLOBAL SWIPE BACK
------------------------------------------------------------

Apply throughout Connections.
Swipe from the left edge to return to the previous view.

Examples:
• Timeline → Matched
• Message → Matched
• Save → Connections

Animations should match modern iOS navigation.

------------------------------------------------------------
PROFILE CARDS
------------------------------------------------------------

Every Connections view uses the same reusable Glass Card.

Each card contains:
• Photo
• Name
• Age
• Location
• Action Buttons

Cards animate smoothly when moving between categories.

============================================================
ANIMATION SYSTEM
============================================================

Animations should feel:
• Smooth
• Continuous
• Elegant
• Responsive

Avoid:
• Snap
• Jump
• Lag
• Flicker

Motion communicates interaction rather than decoration.

------------------------------------------------------------
UNIVERSAL ANIMATION RULES
------------------------------------------------------------

Every interactive component supports:
• Tap → Scale Down → Scale Up
• Desktop Hover → Brightness Increase → Subtle Glow

Navigation transitions use:
• Fade
• Scale
• Blur Transition
• Glass Morph

Use identical animation timing throughout the application.

============================================================
DESIGN GOALS
============================================================

• Navigation feels like one living component transforming
  between navigation modes.
• The user never perceives separate navigation bars —
  only one navigation component changing state.
• Motion quality closely matches Instagram while preserving
  the approved ZYRA visual language.
• Connections feels like a premium relationship management
  system — fast, instant, predictable, elegant.
• Everything feels like one connected experience.

============================================================
COMPONENT REUSE
============================================================

Reusable components exist only once:
• Universal Toggle
• Glass Navigation
• Notification Bell
• Decision Strip
• Profile Card
• Developer Buttons

Future features inherit existing components instead of
creating new ones.

============================================================
UI CONSISTENCY
============================================================

Every page shares:
• Spacing
• Blur
• Shadows
• Glass Styling
• Motion
• Corner Radius
• Animation Timing

The application should feel like one unified design system.

============================================================
RESPONSIVE DESIGN
============================================================

Automatically adapt to:
• Small Phones
• Large Phones
• Tablets
• Desktop

Maintain proportional spacing.

Never overlap:
• Profile Information
• Navigation
• Decision Strip
• Notification Controls

============================================================
PERFORMANCE
============================================================

Prioritise:
• Fast Transitions
• Low Latency
• Minimal Layout Shifts

Avoid unnecessary rebuilds.
Reuse components wherever possible.

============================================================
ACCESSIBILITY
============================================================

Support:
• Large Touch Targets
• Consistent Spacing
• Readable Typography
• High Contrast where required

Glass effects must never reduce usability.
