FEATURE NAME
SEEKER NAVIGATION

============================================================
FLOW DIAGRAM
============================================================

Corrected 2026-07-12 against SEEKER NAVIGATION/Summary.md
(the source of truth for this structure) — Seeker
Basic/Pro/Premium and Guardian Basic/Pro/Premium replaced with
ZYRA Basic/ZYRA One and Standard Guardian/Guardian+. This also
fixes a real conflict: this diagram previously showed "Seeker
Premium" gaining a Network tab, which contradicts the approved
decision that Network is Extended-Guardian-only and never available
to Seekers at any entitlement (see Summary.md, confirmed
2026-06-27).

Terminology updated 2026-07-25 (DR-ZYRA-099, caught by the
DR-ZYRA-101 repository audit): Decline/Save/Like renamed
Pass/Save/Consider below. NOT fixed by this pass: the 4-tab
"Browse • Connections • Guardian • Profile" structure and the
"Connections" page concept shown below are stale against live
code (3 tabs: Browse/Matches/Profile) — this is the same,
already-tracked gap recorded in SEEKER NAVIGATION/Summary.md's
2026-07-19 FLAGGED section, not something this terminology-only
pass resolves.

------------------------------------------------------------
SEEKER NAVIGATION STRUCTURE
------------------------------------------------------------

SEEKER (ZYRA BASIC / ZYRA ONE)
┌─────────────────────────────────────┐
│  Browse • Connections • Guardian • Profile │
└─────────────────────────────────────┘

------------------------------------------------------------
GUARDIAN NAVIGATION STRUCTURE (TEMPORARY)
------------------------------------------------------------

STANDARD GUARDIAN
┌──────────────────────────────┐
│  Dashboard • Seekers • Profile │
└──────────────────────────────┘

GUARDIAN ONE
┌────────────────────────────────────────────────────┐
│  Dashboard • Seekers • Browse • Network • Profile   │
└────────────────────────────────────────────────────┘

------------------------------------------------------------
NAVIGATION STATE FLOW
------------------------------------------------------------

User opens app
        │
        ▼
MAIN NAVIGATION displayed
(Browse • Connections • Guardian • Profile)
        │
        ▼
User taps Connections
        │
        ▼
CONNECTIONS NAVIGATION displayed
Left: Floating Back Button
Right: Last 5 Passed • Saved • Considered
       • Incoming Potentials • Matches
        │
        ▼
User taps Back Button
        │
        ▼
Returns to MAIN NAVIGATION

------------------------------------------------------------
CONNECTIONS RELATIONSHIP JOURNEY
------------------------------------------------------------

Save
  │
  ▼
Consider
  │
  ▼
Match
  │
  ▼
Communication
  │
  ▼
Family Introduction

------------------------------------------------------------
BROWSE END OF SEARCH FLOW
------------------------------------------------------------

No more profiles
        │
        ▼
"No more profiles right now."
"Check back soon, in shaa Allah."
        │
        ├── Restart Search
        │   (Passed + Reviewed profiles may reappear)
        │
        └── Edit Search Filters (Future)
