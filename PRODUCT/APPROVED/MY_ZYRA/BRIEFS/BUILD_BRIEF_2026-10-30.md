---
id: DOC-ZYRA-0368
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 15 - Seeker My ZYRA tab, Focus design
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — MY ZYRA (SEEKER, FOCUS) — 30 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build **after** queue lines 40 (Phone access) and
42 (Ivory colours V4, replaces 39), **before** line 44 (developer toggles, replaces 35). Queue line 43 (replaces 41, which stopped only because line 39 had failed).

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (spec **V2**) and the eleven `../MASTERS/` (m01–m06 Seeker, gm01–gm05 Guardian) |
| 2 | Rebuild the Seeker My ZYRA tab (`_dashboard()` in `lib/dev/zyra_one_journey_concept_shell.dart`, and the widgets it uses) to spec §1: focus area, ‹ dots › + swipe, all-caught-up, status chips, four quick-access tiles. Seeker One and Basic |
| 2b | **Guardian My ZYRA (spec §6):** rebuild the Guardian My ZYRA tab (`lib/dev/zyra_one_journey_guardian_tabs.dart`) in the same Focus layout with the LOCK 8 greeting, items, chips and tiles; Guardian Basic locked tiles. Family Review Continue / Pause / Reopen and Connect keep their existing LOCK 8 behaviour |
| 3 | Feed the "Needs you" items (§2) from the existing activity items and dashboard update keys, newest first; an item leaves once its target is opened. Where an item has no live source in the Founder preview today, show it from the existing preview fixtures only and list it in the task note — **no server work, no new dependencies** |
| 4 | Status chips (§3) from existing state (setup, Guardian link, places, notification permission, Green / Yellow / Red count). Quick tiles (§4) open today's pages (Journey requests, Introductions, Ended Journeys, Notifications list) |
| 5 | Remove from this tab: "New activity" heading + link, "Quick access" label + list tiles, "Now / Insights" switch (move unused code to `~/_to_delete/`; the developer Activity preview bar is line 35's job) |
| 6 | Tests: each master state (m01–m06) matches; stepping by ‹ › and swipe; single item has no ‹ ›; several-requests wording (2, 3, 4+); every button and tile opens its page; Basic shows "1 of 1 place in use"; Larger Text scrolls without clipping. Analyser clean |
| 7 | Render m01–m06 and gm01–gm05 into `MY_ZYRA/BUILT/` (430 × 932 @3x) plus master-beside-build pictures; task note; commit within core rule 2; mark the queue line BUILT or FAILED |
