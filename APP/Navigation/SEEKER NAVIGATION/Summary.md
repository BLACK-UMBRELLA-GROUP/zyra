FEATURE NAME
SEEKER NAVIGATION
Group: 4 — Page Responsibilities

============================================================
SUMMARY
============================================================

Purpose:
Defines the navigation architecture for Seeker accounts,
including role-based navigation, subscription-based
navigation, Browse behaviour, Connections behaviour,
and navigation implementation standards.

Owns:
• Navigation Philosophy
• Navigation Structure
• Browse
• Connections
• Seeker Navigation
• Navigation Rules

Note:
• Wali Navigation is temporarily documented here.
• When a Wali Navigation file is created, Wali content
  will be moved out of this file.

------------------------------------------------------------
USER ROLES
------------------------------------------------------------

Seeker
The Seeker is the person actively looking for marriage.
The Seeker is the primary user of ZYRA and manages their
own marriage journey.

Wali
The Wali is the supervisor or guardian supporting the
Seeker throughout the marriage process.
The Wali is never treated as a Seeker and supervises one
or more linked Seekers.

------------------------------------------------------------
CORE DIFFERENCE
------------------------------------------------------------

| Feature     | Seeker                        | Wali                          |
|-------------|-------------------------------|-------------------------------|
| User Type   | Person looking for marriage   | Supervisor / Guardian         |
| Primary Goal| Find a spouse                 | Support and supervise Seekers |
| Browse      | Finds a spouse for themselves | Browses for linked Seekers    |
| Connections | Manages relationship journey  | Not available                 |
| Seekers     | Not available                 | Manages linked Seekers        |
| Dashboard   | Not available                 | Main control centre           |
| Network     | Not available (Wali only)     | Wali & family ecosystem       |

------------------------------------------------------------
NAVIGATION PHILOSOPHY
------------------------------------------------------------

• Seeker navigation reflects the marriage journey.
• Wali navigation reflects supervision.
• Premium subscriptions expose additional workflows.
• Navigation differs by role.
• Navigation differs by subscription.
• The Family Network is exclusively for Wali Premium.
  Seekers at any tier do not have access to Network.

------------------------------------------------------------
NAVIGATION STRUCTURE
------------------------------------------------------------

| Account        | Tabs                                     |
|----------------|------------------------------------------|
| Seeker Basic   | Browse • Connections • Wali • Profile    |
| Seeker Premium | Browse • Connections • Wali • Profile    |
| Wali Basic     | Dashboard • Seekers • Profile            |
| Wali Premium   | Dashboard • Seekers • Browse • Network • Profile |

Decision: Network is removed from all Seeker tiers.
Network is available to Wali Premium only.
Confirmed: 2026-06-27

------------------------------------------------------------
BROWSE
------------------------------------------------------------

Purpose:
Primary discovery page for marriage candidates.
The centrepiece of the Seeker experience.

Available To:
• Seeker Basic
• Seeker Premium
• Wali Premium (browses on behalf of linked Seeker)

Design:
• Full-screen photo experience — photo fills the entire screen
• Photo is the primary content; text is secondary
• Multiple photo indicator dots on the left side of the screen
• First dot highlighted to show current photo position

Photo Navigation:
• Tap right side of photo = Next photo
• Tap left side of photo = Previous photo
• Dot indicators update to reflect current photo

Visible Information (Browse level only):
• First name initial
• Age
• City / Location

No other profile information is shown at Browse level.
Additional information revealed only after profile unlock or mutual match.

Actions (bottom of screen):
Two button groups at the bottom of the Browse screen:

Left isolated pill:
• Gallery / photo icon
• Opens additional photo options (TBC)

Right action pill:
• ✗  (X)         = Decline — pass on this profile
• ✓  (single)    = Save — "I'd like to come back to this"
• ✓✓ (double)    = Like — "I'm genuinely interested in this person"

These map to the product spec actions:
• Decline = X
• Save    = single tick
• Like    = double tick

Note: Swipe gestures are not used for Decline/Save/Like.
Actions are tap-only. This is intentional — swiping feels
casual and conflicts with ZYRA's serious marriage philosophy.

End of Profiles:
Displays: "No more profiles right now."
          "Check back soon, in shaa Allah."

Actions after end of profiles:
• Restart Search (previously declined profiles may reappear)
• Edit Search Filters (future feature)

------------------------------------------------------------
PHOTO-FIRST PHILOSOPHY
------------------------------------------------------------

ZYRA is a photo-first platform.

This is rooted in the teaching of Imam Ahmad ibn Hanbal:
"Choose the one whose looks appeal to you first, then
her religion. For if you choose religion first but her
looks don't appeal to you, you have still married for looks."

Application to ZYRA:
• Browse shows photo only — name initial, age, location
• Bio, values, and compatibility remain private until match
• Once two Seekers match, the deeper profile opens
• The religion and character side is explored within
  the relationship, not before it begins

This is a deliberate design principle — not a limitation.
Every feature that conflicts with photo-first must be
reviewed against this philosophy before implementation.

The Imam Ahmad quote should be surfaced prominently in:
• App onboarding (explaining the ZYRA philosophy)
• Marketing and brand communication
• In-app educational moments (TBC)

------------------------------------------------------------
NAVIGATION UI
------------------------------------------------------------

Bottom Navigation Bar:
• Isolated icon on the left  = Browse (magnifier glass)
• Grouped pill on the right  = Connections • Safety • Profile

The Browse icon (magnifier) is visually isolated from the
pill group to signal it is the primary / current destination.

Tapping Browse again while on Browse returns the user to
the X / ✓ / ✓✓ action state.

Navigation style: Apple-inspired floating pill with
Instagram-style motion behaviour.

------------------------------------------------------------
CONNECTIONS
------------------------------------------------------------

Purpose:
Relationship management centre for Seekers.

Relationship Journey:
Save → Like → Match → Conversation → Family Stage

Sections (in order):
• Declined
• Review
• Family Introductions
• Likes
• Matches

Decision: Family Introductions is a dedicated section.
It is not merged into Review.
Clarity is more important than reducing one nav item.
Sections can be merged later if user testing supports it —
but untangling a merge is much harder than separating cleanly.

Family Introductions:
Introductions initiated through the Wali Network.
Presented to the Seeker only after both Walis have agreed.
Seeker accepts or declines independently.
If both Seekers accept, the normal ZYRA Journey begins.
Walis do not accept on behalf of Seekers.

Matches — each entry displays:
• Profile Photo
• Name
• Age
• Location

Actions per Match:
• Message
• Timeline
• Wali

Timeline Records:
• Saves
• Likes
• Matches
• Conversation activity
• Wali actions
• Family introductions

------------------------------------------------------------
WALI NAVIGATION (TEMPORARY — TO BE MOVED)
------------------------------------------------------------

All Wali tiers share the same 4-tab navigation structure.
Browse is not part of the Wali experience.
The Wali's role is guidance and family involvement — not discovery.

Wali Basic
Dashboard • Seekers • Network (locked) • Profile

Wali Pro
Dashboard • Seekers • Network • Profile

Wali Premium
Dashboard • Seekers • Network • Profile

Navigation style:
Floating glass pill. No Universal Toggle (Seeker-only mechanic).
4 equal tabs. Active tab highlighted. Same glass design as Seeker nav.

Network (locked — Wali Basic):
Tapping Network shows a premium feature page explaining what
Network offers and gives the option to upgrade.
This keeps the UI consistent across all Wali tiers while
naturally showcasing premium functionality.

Network (unlocked — Wali Pro / Premium):
Family introductions. Wali-to-Wali communication.
Trusted family connections. Suggested introductions.
Community referrals. Future networking features.
Discovery (if added later) lives inside Network — not Browse.

Dashboard displays:
• Linked Seeker cards with journey status
• Pending approvals / gate actions
• Recent messages preview
• Recent activity / milestones
• Notifications

Pending architectural question (deferred):
Three Wali tiers now identified: Basic, Pro, Premium.
Previously only Basic and Pro were defined.
Differences between Pro and Premium to be established separately.

Pending T&C work (deferred):
Clear terms required for features that depend on:
  — Having a linked Seeker
  — Linked Seeker being on Seeker Premium
Not all Network/Premium features are available without
both conditions being met. To be defined carefully.

------------------------------------------------------------
APPROVED RULES
------------------------------------------------------------

• Notifications use the Bell Icon.
• Bell Icon is positioned top-right.
• Notifications are not a navigation tab.
• Navigation differs by role.
• Navigation differs by subscription.
• Walis are never treated as Seekers.
• Network is never available to Seekers (any tier).
• Browse actions are tap-only — no swipe gestures.
• Photo is always primary. Info is always secondary.

------------------------------------------------------------
CURRENT STATUS
------------------------------------------------------------

✅ Navigation philosophy approved.
✅ Navigation structure approved (Network removed from Seekers).
✅ Browse approved — full-screen photo-first design.
✅ Photo-first philosophy confirmed and rooted in Imam Ahmad.
✅ Action buttons confirmed: X / single tick / double tick.
✅ No swipe gestures — tap only.
✅ Connections approved.
✅ Wali navigation approved (Network = Wali Premium only).
✅ Floating Glass Navigation approved.
✅ Instagram motion behaviour approved.
✅ Smooth navigation transitions approved.

============================================================
APPROVED TO-DO LIST
============================================================
• Define behaviour of left isolated gallery button on Browse.
• Finalise Network functionality for Wali Premium.
• Design Search Filters.
• Expand Conversation workflow.
• Expand Timeline workflow.
• Create Wali Navigation file and move Wali content out.
• Confirm placement of Imam Ahmad quote in onboarding flow.
• Design Connections screen layout.
