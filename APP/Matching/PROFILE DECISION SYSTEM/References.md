---
id: DOC-ZYRA-0027
type: GUIDE
status: CURRENT
feature: APP: MATCHING
purpose: Matching / Profile Decision System — References
links: []
owner: ZYRA chat
---

FEATURE NAME
PROFILE DECISION SYSTEM

============================================================
REFERENCES
============================================================

Superseded 2026-07-12: rewritten against
ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4 and DR-076 alongside
Summary.md. Decline/Review/Consider and Basic/Pro/Premium
references replaced with Decline/Save/Like and ZYRA Basic/One.

Updated 2026-07-25 (DR-ZYRA-099, caught by the DR-ZYRA-101
repository audit): Decline/Save/Like renamed Pass/Save/Consider
throughout this file (Summary.md was updated for DR-099 at the
time; this References.md file was missed). Underlying meaning
unchanged — see USER-FACING TERMINOLOGY MAP below for the
system-name mapping, which is also unchanged (AppState's
decline()/like() method and field names were deliberately not
renamed, per OA-ZYRA-138).

------------------------------------------------------------
References (depends on)
------------------------------------------------------------

Browse
- The Browse tab is the access point for profile decisions.
- Pass / Save / Consider are accessible from Browse via swipe
  gestures (DR-ZYRA-099).
- Status: Referenced — definition lives in APP/Browse.

Entitlement (ZYRA Basic / ZYRA One)
- Save/Like daily limits are gated by entitlement (10/day on
  Basic, unlimited on ZYRA One).
- Immediate Incoming Potentials and Mutual Save Detection are
  ZYRA One features.
- Status: Referenced — entitlement definitions live in
  ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4, Part 1.
- ⚠️ OVERLAP FLAG: entitlement feature lists exist in both this
  file and BUSINESS/USER FEATURES. Keep in sync.

Communication System
- Controls communication permissions after a Match event.
- Handles messaging pause when an Outgoing Potential is removed.
- Status: Referenced — definition lives elsewhere.

Family Introduction System
- Family Introduction events are recorded in the Journey Timeline.
- Status: Referenced — definition lives elsewhere. Eligibility
  under ZYRA One vs ZYRA Basic not yet re-confirmed post-
  alignment — flag for follow-up.

Notifications System
- Incoming Potential notifications sent to ZYRA One recipients
  immediately; ZYRA Basic recipients only on reciprocation.
- Mutual Save Detected notifications sent per the entitlement
  table in Summary.md.
- Outgoing Potential removal notifications sent to affected Seeker.
- Match event notifications sent to both Seekers.
- Status: Referenced — definition lives in APP/Notifications.

------------------------------------------------------------
Referenced By
------------------------------------------------------------

Browse
- Hosts the Pass / Save / Consider swipe actions.

Communication System
- Depends on Match event and Potential Journey status.

Notifications
- Receives events from this system to trigger notifications.

Timeline
- Journey Timeline is owned and populated by this system
  (Browse-stage events); Active Journey stage events are
  owned elsewhere per ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4.

Family Introduction System
- Uses Match event and Journey status as prerequisites.

------------------------------------------------------------
USER-FACING TERMINOLOGY MAP
------------------------------------------------------------

| User Sees          | System Uses            |
|---------------------|------------------------|
| Pass                | Declined                |
| Save                | Saves                   |
| Consider            | Outgoing Potential       |
| Incoming Potential  | Incoming Potentials      |
| Mutual Save         | Mutual Save Detected     |
| Match               | Match event              |
| Potential Journey   | Potential Journey        |
| Timeline            | Journey Timeline         |

------------------------------------------------------------
Open Dependencies
------------------------------------------------------------

- Communication System rules post-Match not fully defined here.
- Family Introduction System prerequisites not fully defined
  here, and not yet re-confirmed against ZYRA One (see flag
  above).
- Whether declined profiles can be re-discovered not specified.
