# Search

**Status:** Scope defined, not yet built
**Updated:** 2026-07-26 (DR-ZYRA-101 audit)

------------------------------------------------------------
SCOPE DECISION
------------------------------------------------------------

"Search" has no standalone spec content beyond this placeholder, but
APP/Navigation/SEEKER NAVIGATION/Summary.md's own Approved To-Do List
already contains "Design Search Filters" as a Browse-adjacent item —
there is no other reference anywhere in the approved documentation to
a standalone Search feature, screen, or nav tab.

Reading these together: Search is not a separate feature. It is
Browse's filter controls (age range, and any other candidate
attributes worth narrowing by) — a refinement of who appears in
Browse's existing candidate feed, not a new search surface, inbox, or
tab. This folder is kept as a placeholder-with-resolved-scope rather
than deleted, since "Search" may still be referenced elsewhere in
Founder-facing material.

------------------------------------------------------------
NOT BUILT YET
------------------------------------------------------------

No filter UI exists in Browse today. Candidate age is only known
client-side after zyra_discovery_service.dart's per-candidate
ages_for() RPC call (see the DOB/age fix, 2026-07-26) — an age-range
filter is realistic to add as a client-side filter over that already-
fetched data without new schema work. Other structured, filterable
profile attributes (sect, etc.) are not currently persisted to the
`profiles` table at all, so filtering on them would need schema work
first.

------------------------------------------------------------
APPROVED TO-DO LIST
------------------------------------------------------------

• Design Search Filters (age range, then evaluate what else is
  realistic given what's actually persisted server-side).
• Decide whether filters live behind an icon on Browse's existing top
  bar, or a separate sheet/screen.
