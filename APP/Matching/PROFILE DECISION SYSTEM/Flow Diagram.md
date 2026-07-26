FEATURE NAME
PROFILE DECISION SYSTEM

============================================================
FLOW DIAGRAM
============================================================

Superseded 2026-07-12: rewritten against
ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V3 and DR-076 alongside
Summary.md and References.md.

Terminology updated 2026-07-25 (DR-ZYRA-099, caught by the
DR-ZYRA-101 repository audit): Decline/Save/Like renamed
Pass/Save/Consider throughout below — underlying mechanics
unchanged, this file was simply missed in the DR-099 sweep.

------------------------------------------------------------
CORE DECISION FLOW
------------------------------------------------------------

Seeker views profile in Browse
            │
            ▼
    ┌───────────────┐
    │  Make Decision │
    └───────────────┘
       │        │        │
       ▼        ▼        ▼
    Pass       Save    Consider
       │        │        │
       ▼        ▼        ▼
   Next      Added     Added to
  Profile   to Saves  Outgoing Potentials

------------------------------------------------------------
MATCH EVENT FLOW
------------------------------------------------------------

Seeker A Considers Seeker B
            │
            ▼
  Does Seeker B Consider Seeker A?
       │               │
      YES              NO
       │               │
       ▼               ▼
  Match event         No Match.
  fires               Seeker A stays in Seeker
       │              B's Incoming Potentials
       ▼              (if B is ZYRA One) or
  Potential Journey    unrevealed (if B is Basic)
  created
       │
       ▼
  Both Seekers Notified
       │
       ▼
  Communication System
  controls next steps
  (no conversation opens yet —
  Pre-Journey Ritual required first)

------------------------------------------------------------
MUTUAL SAVE DETECTION FLOW
------------------------------------------------------------

Seeker A saves Seeker B
            │
            ▼
  Has Seeker B also saved Seeker A?
       │               │
      YES              NO
       │               │
       ▼               ▼
  Mutual Save        No Detection
  exists             No Notification
       │
       ▼
  Is either Seeker on ZYRA One?
       │               │
      YES              NO — both Basic
       │               │
       ▼               ▼
  ZYRA One side(s)    Completely private —
  notified:           neither notified
  "Mutual Save Detected"
       │
       ▼
  Does NOT create a Match —
  Match only fires on mutual Consider

------------------------------------------------------------
OUTGOING POTENTIAL REMOVAL FLOW
------------------------------------------------------------

Seeker removes an Outgoing Potential
            │
            ▼
  Consider removed
            │
            ▼
  Other Seeker notified (only if they had already
  received an Incoming Potential — ZYRA One only)
            │
            ▼
  Event recorded in Journey Timeline
            │
            ▼
  Future re-Considering allowed
  (unless blocked)

------------------------------------------------------------
SAVE / CONSIDER DAILY LIMIT FLOW
------------------------------------------------------------

Seeker tries to Save or Consider a profile
            │
            ▼
  Is Seeker on ZYRA One?
       │               │
      YES              NO — ZYRA Basic
       │               │
       ▼               ▼
  Unlimited          Under 10 for today?
  Save/Consider           │        │
                          YES      NO
                           │        │
                           ▼        ▼
                     Action        Blocked until
                     allowed       next day
