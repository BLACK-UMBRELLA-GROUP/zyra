# Search

**Founder extension (DR-ZYRA-267, 2026-10-10):** approved filters are age,
country of residence, nationality, ethnicity and radius from current location.
Public heritage answers are separate from private compatibility answers. The
protected preview demonstrates composed filters, Apply/Cancel/Reset and empty
results using invented metadata and a clearly labelled sample location. That
is not actual device-location acquisition or real-member search. OA-ZYRA-306
owns structured residence capture, specific public disclosure/withdrawal,
narrow server projection and private location/distance predicates. Old filter
implementation facts below remain dated history. No live schema or permission
change is authorized by this overlay.

**Status:** Age-range filter built. Other attributes not yet — see below.
**Updated:** 2026-07-26 (#21)

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
BUILT 2026-07-26 (#21)
------------------------------------------------------------

Age-range filter — a filter icon (tune icon, top-left of Browse;
top-right is reserved for the Bell/Dev Access icons HomeShell overlays
above every tab) opens a bottom sheet with an 18–70 RangeSlider. Purely
client-side: filters the already-fetched candidate list (age already
known per-candidate via ages_for(), no new schema/query). Resolves the
open question this doc previously flagged ("icon on Browse's top bar,
or a separate sheet/screen") in favour of an icon + bottom sheet, since
Browse has no persistent top bar today (full-bleed photo, no chrome)
and a bottom sheet matches the pattern already used elsewhere
(searchable_list_picker.dart).

Changing the filter doesn't reset the daily 50-profile view limit
(_dailyProfileLimit) — that's a per-day counter, unrelated to
narrowing which profiles show. A distinct "No one matches your age
filter" empty state (with a Clear filter button) appears instead of
the generic "You're all caught up" state when the filter, not
genuine exhaustion, is why nothing's showing.

------------------------------------------------------------
NOT BUILT
------------------------------------------------------------

Other structured, filterable profile attributes (sect, etc.) are not
currently persisted to the `profiles` table at all, so filtering on
them would need schema work first — age was the only realistic filter
without new schema work, per this doc's own prior scoping.
