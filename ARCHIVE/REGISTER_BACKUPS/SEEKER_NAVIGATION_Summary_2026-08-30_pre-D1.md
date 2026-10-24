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
• Guardian Navigation is temporarily documented here.
• When a Guardian Navigation file is created, Guardian content
  will be moved out of this file.
• Terminology corrected 2026-07-12 against
  ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V5 and
  WALI_ARCHITECTURE_CURRENT_VERSION_V6 — Seeker Basic/Premium
  tier names and Guardian Basic/Pro/Premium replaced with ZYRA
  Basic/ZYRA One and Standard Guardian/Guardian+. Browse action
  terminology (Decline/Save/Like) was already correct.

------------------------------------------------------------
USER ROLES
------------------------------------------------------------

Seeker
The Seeker is the person actively looking for marriage.
The Seeker is the primary user of ZYRA and manages their
own marriage journey.

Guardian
The Guardian is the supervisor or guardian supporting the
Seeker throughout the marriage process.
The Guardian is never treated as a Seeker and supervises one
or more linked Seekers.

------------------------------------------------------------
CORE DIFFERENCE
------------------------------------------------------------

| Feature     | Seeker                        | Guardian                          |
|-------------|-------------------------------|-------------------------------|
| User Type   | Person looking for marriage   | Supervisor / Guardian         |
| Primary Goal| Find a spouse                 | Support and supervise Seekers |
| Browse      | Finds a spouse for themselves | Browses for linked Seekers    |
| Connections | Manages relationship journey  | Not available                 |
| Seekers     | Not available                 | Manages linked Seekers        |
| Dashboard   | Seeker hub                    | Main control centre           |
| Network     | Not available (Guardian only)     | Guardian & family ecosystem       |

------------------------------------------------------------
NAVIGATION PHILOSOPHY
------------------------------------------------------------

• Seeker navigation reflects the marriage journey.
• Guardian navigation reflects supervision.
• ZYRA One and Guardian+ expose additional workflows.
• Navigation differs by role.
• Navigation differs by entitlement.
• The Family Network is exclusively for Guardian+.
  Seekers do not have access to Network at any entitlement.

------------------------------------------------------------
NAVIGATION STRUCTURE
------------------------------------------------------------

| Account                | Tabs                                     |
|--------------------------|------------------------------------------|
| Seeker (ZYRA Basic)      | Browse • Connections • Dashboard • Guardian • Profile |
| Seeker (ZYRA One)        | Browse • Connections • Dashboard • Guardian • Profile |
| Guardian (Standard)          | Dashboard • Seekers • Profile            |
| Guardian (Extended)          | Dashboard • Seekers • Browse • Network • Profile |

Decision: Network is removed from all Seeker entitlements.
Network is available to Guardian+ only.
Confirmed: 2026-06-27; terminology corrected 2026-07-12.

CHANGED 2026-08-24 (Founder direct): Dashboard replaces the standalone
Notifications Seeker tab and sits between Connections and Guardian. Notifications remains a
full management page reached from the Dashboard; its unread count remains on
the Dashboard navigation item. The Guardian rows are untouched by this ruling.

------------------------------------------------------------
BROWSE
------------------------------------------------------------

Purpose:
Primary discovery page for marriage candidates.
The centrepiece of the Seeker experience.

Available To:
• Seeker (ZYRA Basic)
• Seeker (ZYRA One)
• Guardian+ (browses on behalf of linked Seeker)

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

**Superseded 2026-07-25 (DR-ZYRA-099, Founder decision) — see
replacement below.** The floating action-button pair described here
is removed. Kept below, struck through in spirit not in text, as the
historical record of what this replaces:

~~Actions (bottom of screen): two button groups at the bottom of the
Browse screen. Left isolated pill: gallery/photo icon, opens
additional photo options (TBC). Right action pill: ✗ (X) = Decline —
pass on this profile; ✓ (single) = Save — "I'd like to come back to
this"; ✓✓ (double) = Like — "I'm genuinely interested in this
person." Note: Swipe gestures are not used for Decline/Save/Like.
Actions are tap-only. This is intentional — swiping feels casual and
conflicts with ZYRA's serious marriage philosophy.~~

**Current (2026-07-25) — Gesture-Based Profile Actions:** source:
ChatGPT UX proposal (OA-ZYRA-135), Founder-ratified same day
alongside a terminology rename (Pass/Save/Consider — see
`APP/Matching/PROFILE DECISION SYSTEM/Summary.md`). The floating
action buttons above the bottom navigation bar are removed entirely.
Primary profile actions are performed via swipe gestures directly on
the profile card:

• Physical swipe Left  (finger Right → Left) → 🟢 Consider (was: Like)
• Physical swipe Right (finger Left → Right) → 🔴 Pass (was: Decline)
• Swipe Down  → 🟡 Save (unchanged)

Each gesture includes smooth animation and clear visual feedback so
the user immediately understands what action occurred. The bottom
navigation bar remains dedicated solely to app navigation — no
profile-action buttons appear above or overlap it. These profile
swipe gestures are entirely separate from, and must not interfere
with, the bottom navigation bar's own Slide Navigation gesture
(§NAVIGATION UI, DR-ZYRA-098) — different screen regions, no overlap
in practice, but both are gesture-based so this is called out
explicitly.

**Reversal note:** the "swiping feels casual and conflicts with
ZYRA's serious marriage philosophy" rule directly above was an
explicit, deliberate design decision at the time it was written — not
an oversight. The Founder's 2026-07-25 instruction directly and
knowingly overrides it: *"we will stick with swiping actions for
cleaner UI."* The underlying philosophy (deliberate, one-decision-at-
a-time progression toward marriage, not casual mass-swiping) is
judged unchanged by this — see `PROFILE DECISION SYSTEM/Summary.md`
§PHILOSOPHY for the updated reasoning. Only the specific "no swipe
gestures, ever" implementation rule is reversed.

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

**Slide Navigation (added 2026-07-25, DR-ZYRA-098, from
OA-ZYRA-136):** the bottom navigation bar supports two input
methods — Tap (existing) and Slide (new). Both remain available;
slide does not replace tap. Checked first against this document's
existing "tap-only" rule (Approved Rules, below) — that rule is
explicitly scoped to Browse's Decline/Save/Like actions on the
profile card, not to bottom-navigation, so there is no conflict.
This also complements, rather than duplicates, the already-approved
Instagram-style motion behaviour above (DR-ZYRA-091's sliding
circular highlight) — slide navigation is the natural extension of
an interface that already animates a highlight moving between tabs.
**Note added same day, later:** the "tap-only" rule referenced above
was itself reversed later on 2026-07-25 by DR-ZYRA-099 (see §BROWSE
above) — that reversal doesn't change this decision's reasoning
(bottom-nav slide gestures were never in conflict with it either
way), but the rule this paragraph cites no longer exists in its
original form.

Behaviour: user places a finger anywhere on the navigation bar and
slides horizontally across the items. While sliding: the highlighted
item follows the finger in real time, with continuous visual
feedback and a smoothly animating floating indicator — but no
navigation occurs yet. On release: the currently highlighted item
becomes selected and the app navigates to it immediately, with the
page transition animation beginning at that point.

Must not interfere with: vertical scrolling, page swipe gestures
(including the Browse card's own tap-decision transition, Script_V2
§DECISION FEEDBACK), or any other in-app interaction. Implementation
detects horizontal drag input, continuously resolves which nav item
is currently beneath the finger, and only triggers the actual page
change on gesture release — not during the drag itself.

This inherits, but does not resolve, this document's already-flagged
2026-07-19 tab-count/naming inconsistency (see FLAGGED section
below) — slide navigation applies to whatever the final tab set
turns out to be; it is not itself a decision about tab count or
naming.

------------------------------------------------------------
CONNECTIONS
------------------------------------------------------------

Purpose:
Relationship management centre for Seekers.

Relationship Journey:
Save → Consider → Match → Conversation → Family Stage
(was: Save → Like → Match..., renamed 2026-07-25 with the rest of
the Pass/Save/Consider terminology change, DR-ZYRA-099)

Sections (in order):
• Passed (was: Declined)
• Saved
• Family Introductions
• Considered (was: Likes)
• Matches

(Renamed 2026-07-12: "Review" → "Saved", to match the Save
action and the Saves list defined in PROFILE DECISION SYSTEM.
Renamed again 2026-07-25: "Declined" → "Passed", "Likes" →
"Considered" — same DR-ZYRA-099 terminology change.)

Decision: Family Introductions is a dedicated section.
It is not merged into Saved.
Clarity is more important than reducing one nav item.
Sections can be merged later if user testing supports it —
but untangling a merge is much harder than separating cleanly.

Family Introductions:
Introductions initiated through the Guardian Network.
Presented to the Seeker only after both Guardians have agreed.
Seeker accepts or declines independently.
If both Seekers accept, the normal ZYRA Journey begins.
Guardians do not accept on behalf of Seekers.

Matches — each entry displays:
• Profile Photo
• Name
• Age
• Location

Actions per Match:
• Message
• Timeline
• Guardian

Timeline Records:
• Saves
• Considers (was: Likes)
• Matches
• Conversation activity
• Guardian actions
• Family introductions

As-built Connections hierarchy — UPDATED 2026-08-28 by Founder direct:
• Active, Potential, Paused and Ended keep one person-level Report flag at the
  top-right of the card rather than repeating Report in the destination rail.
• Potential gives the remaining secondary width to View Profile and
  Compatibility Unlock/View.
• Paused and Ended place Timeline and the already-revealed compatibility
  report together under the card's JOURNEY reference area. Paused separately
  offers View Profile and End Journey; Ended offers View Profile only outside
  the historical references.
• Paused copy says `Paused` / `Paused · duration`; it does not say `Paused
  together` or imply either person can resume unilaterally.
• View Profile from Connections is a temporary full-photo inspection surface:
  swipe down to dismiss, with no top-left X. Other profile-entry contexts keep
  their existing navigation contract.
• Developer Test Introductions opens the Introductions segment after staging.
  Real server rows remain authoritative; non-release local fallbacks are
  visibly labelled Preview, inspection-only and cannot invoke account writes.

------------------------------------------------------------
GUARDIAN NAVIGATION (TEMPORARY — TO BE MOVED)
------------------------------------------------------------

Both Guardian entitlements share the same 4-tab navigation structure.
Browse is not part of the Guardian experience (except as noted below
for Guardian+).
The Guardian's role is guidance and family involvement — not discovery.

Standard Guardian
Dashboard • Seekers • Network (locked) • Profile

Guardian+
Dashboard • Seekers • Network • Profile
(also gains Browse — browses on behalf of linked Seeker; see
NAVIGATION STRUCTURE table above)

Navigation style:
Floating glass pill. No Universal Toggle (Seeker-only mechanic).
4 equal tabs. Active tab highlighted. Same glass design as Seeker nav.

Network (locked — Standard Guardian):
Tapping Network shows a feature page explaining what Network
offers and gives the option to upgrade to Guardian+.
This keeps the UI consistent across both Guardian entitlements while
naturally showcasing the locked functionality.

Network (unlocked — Guardian+):
Family introductions. Guardian-to-Guardian communication.
Trusted family connections. Suggested introductions.
Community referrals. Future networking features.
Discovery (if added later) lives inside Network — not Browse.

Dashboard displays:
• Linked Seeker cards with journey status
• Pending approvals / gate actions
• Recent messages preview
• Recent activity / milestones
• Notifications

Resolved 2026-07-12 (was: pending architectural question):
The Guardian tier model is Standard Guardian / Guardian+ — two
entitlements, not three. The earlier "Basic, Pro, Premium"
three-tier framing was stale; see
WALI_ARCHITECTURE_CURRENT_VERSION_V6 for the confirmed
Guardian Permissions Model.

Pending T&C work (deferred):
Clear terms required for features that depend on:
  — Having a linked Seeker
  — Linked Seeker being on ZYRA One
Not all Network/Guardian+ features are available without
both conditions being met. To be defined carefully.

------------------------------------------------------------
APPROVED RULES
------------------------------------------------------------

• Dashboard is the third Seeker navigation tab: Browse • Connections •
  Dashboard • Guardian • Profile — CHANGED 2026-08-24 by Founder direct.
  Dashboard is a hub for Connections, Guardian and Notifications. The full
  Notifications manager remains available inside it and the unread badge
  lives on the Dashboard tab. CHANGED 2026-08-26: for a normal authenticated
  Seeker Dashboard is also the default landing page. Authentication,
  missing-profile/role-selection and explicitly routed exceptional flows keep
  their own entry. Guardian account-link invitation status and cancellation
  live on Dashboard; generic bearer-code review and invite generation live
  behind the Guardian tab's top-right `+`, without duplicating ongoing status.
  UPDATED 2026-08-27: Dashboard cards carry explicit destinations. Journey,
  compatibility, milestone and Journey-update actions open Connections →
  Journeys; Saved and family-introduction actions open Connections → Activity;
  Guardian activity opens Guardian; discovery opens Browse; setup opens
  Onboarding; profile opens Profile; and preference review opens the preference
  editor. The kept-alive Connections tab receives the requested subsection
  before it opens, so its previous Journeys/Activity/Introductions page cannot
  misroute the action. UPDATED 2026-08-28 under DR-ZYRA-216: production uses
  one typed resolver and one hierarchy — Answer → Your Journey → Other Actions
  → Worth Knowing. One visual primary never discards a second obligation;
  additional obligations remain behind explicit disclosure. Passive viewing
  cannot demote an unresolved obligation. The Dashboard may say nothing needs
  attention only after every action-bearing source has returned successfully;
  loading/unavailable reads show updating or Retry rather than false calm.
  The full Notifications manager opens from the compact header utility/unread
  badge, not a generic Notifications card. Guardian invitation/activity reads
  preserve successful empty separately from unavailable.
  UPDATED 2026-08-29 under DR-ZYRA-217 (built 2026-08-28, MESSAGES/012;
  Fable-verified 2026-08-29): the four-level surface (Answer → Your Journey →
  Other Actions → Worth Knowing) is replaced by the six-level conditional HOME
  rendered by the same typed resolver: Header (greeting + notification
  utility) → RIGHT NOW → JOURNEY/SEARCH (dynamic eyebrow) → MY ZYRA
  (zero-suppressed orientation; Saved omitted in production until a
  truth-preserving reader exists) → FAMILY (always truthfully present) →
  RECENTLY (one unread-backed capped stream + milestones; no last-visit
  bookmark) → ZYRA INTELLIGENCE (honest-empty under OA-ZYRA-259). Suppression
  is a feature: MY ZYRA/RECENTLY/INTELLIGENCE render only with real content.
  Resolver remains the brain (DR-ZYRA-216 gates intact); Guardian Dashboard
  unchanged, sequenced after Seeker per DR-ZYRA-217 Decision 8.
• Navigation differs by role.
• Navigation differs by subscription.
• Guardians are never treated as Seekers.
• Network is never available to Seekers (any tier).
• Browse actions are swipe-based (was: tap-only — no swipe
  gestures; reversed 2026-07-25, DR-ZYRA-099, see §BROWSE above).
• Photo is always primary. Info is always secondary.

------------------------------------------------------------
CURRENT STATUS
------------------------------------------------------------

✅ Navigation philosophy approved.
✅ Navigation structure approved (Network removed from Seekers).
✅ Browse approved — full-screen photo-first design.
✅ Photo-first philosophy confirmed and rooted in Imam Ahmad.
❌ Action buttons (X / single tick / double tick) — SUPERSEDED
   2026-07-25, DR-ZYRA-099. Replaced by swipe gestures directly on
   the profile card; see §BROWSE above.
❌ No swipe gestures / tap only — SUPERSEDED 2026-07-25,
   DR-ZYRA-099, same reversal. Swipe gestures are now the primary
   mechanism: physical Swipe Left / finger Right → Left = Consider,
   physical Swipe Right / finger Left → Right = Pass, Swipe Down = Save.
✅ Connections approved.
✅ Guardian navigation approved (Network = Guardian+ only).
✅ Floating Glass Navigation approved — BUILT 2026-07-19
   (DR-ZYRA-089, DR-ZYRA-091), PROPOSED/not yet ratified.
✅ Instagram motion behaviour approved — BUILT 2026-07-19
   (DR-ZYRA-091: icon grows on selection, single sliding
   circular highlight between tabs), PROPOSED/not yet ratified.
✅ Smooth navigation transitions approved — BUILT 2026-07-19,
   same DRs.
✅ Seeker Dashboard third tab — BUILT 2026-08-24; standalone Notifications
   tab replaced by a hub, Notifications retained inside it, unread badge on
   Dashboard. UPDATED 2026-08-26: normal authenticated landing and Guardian
   invitation workflow now begin/live there.

⚠ FLAGGED 2026-07-19 — implementation gaps found while filing
  DR-ZYRA-089/091, not resolved, needs a dedicated session:
    • Live Seeker nav (SOURCE/lib/screens/home/home_shell.dart)
      has 3 tabs — Browse, Matches, Profile. Neither "Matches"
      nor a 3-tab count matches this document, which specifies
      4 tabs (Browse • Connections • Guardian • Profile) in the
      NAVIGATION STRUCTURE table above. No Connections or Guardian
      tab exists in the Seeker shell at all yet.
      [RESOLVED for the tab-count half — noted 2026-08-20,
       OA-ZYRA-206 filing: the Seeker shell now carries five
       tabs (DR-ZYRA-101 built the 4-tab structure;
       DR-ZYRA-149 added Notifications, 2026-08-13; Founder direct replaced
       that destination with Dashboard, 2026-08-24). The
       Safety-vs-Guardian wording point below and the Guardian
       Network entitlement gap remain open observations.]
    • This document is internally inconsistent about what the
      4th Seeker tab even is: NAVIGATION STRUCTURE says
      "Connections • Guardian"; the NAVIGATION UI section below
      describes a "grouped pill: Connections • Safety • Profile"
      — a different item ("Safety" vs "Guardian") and a different
      visual grouping (isolated Browse + grouped pill, vs 4
      equal tabs). Needs reconciling before anyone builds
      against it.
    • Live Guardian nav (wali_home_shell.dart) shows Network as
      fully unlocked for all Guardian accounts — this document
      specifies Network should be locked/upsell-only for
      Standard Guardian (GUARDIAN NAVIGATION section), which isn't
      implemented. No entitlement check exists in code yet.
    • Browse's action buttons (browse_screen.dart) are three
      independent glass circles (Decline/Save/Like), not the
      "left isolated gallery pill + right X/tick/double-tick
      pill" grouping this document describes under BROWSE.
      **Update 2026-07-25:** this gap is now larger, not smaller —
      §BROWSE above has since moved to swipe gestures and
      Pass/Save/Consider terminology (DR-ZYRA-099), while the live
      code still has the three tap-button glass circles under the
      old Decline/Save/Like names. Not fixed as part of this
      documentation filing; noted for whenever Browse is next
      built/rebuilt.
    • Overlaps with OA-ZYRA-126, OA-ZYRA-128, OA-ZYRA-129
      (logged 2026-07-19, Outstanding Actions register) —
      those items raised related/overlapping concerns from a
      different angle (ChatGPT UX review) without knowing this
      document already specifies (inconsistently) most of it.

============================================================
APPROVED TO-DO LIST
============================================================
• Define behaviour of left isolated gallery button on Browse.
• Finalise Network functionality for Guardian+.
• Design Search Filters.
• Expand Conversation workflow.
• Expand Timeline workflow.
• Create Guardian Navigation file and move Guardian content out.
• Confirm placement of Imam Ahmad quote in onboarding flow.
• Design Connections screen layout.
