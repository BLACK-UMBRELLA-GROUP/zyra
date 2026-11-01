---
id: DOC-ZYRA-0355
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 10 V4 - Filters as swipe cards
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — FILTERS — V4 (SWIPE CARDS) — 30 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Replaces queue line 36 (V3 brief, never built —
`../ARCHIVE/BUILD_BRIEF_2026-10-30_V3.md`). Founder 30 Oct: "after everythign is changed lock in filter page for codex".

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (spec **V6** — slider spacing; card titled "Location") and the ten `../MASTERS/` pictures (f01–f10); also `LOCATION/` (LOCK 11 V2) for the origin line and sheets |
| 2 | Founder preview `_filters` page: rebuild as four swipe cards (Age, Location, Nationality, Ethnicity) with dots, Clear (n), the preferences link and the bottom pill. Reuse the Profiles request-pill component (LOCK 7) and the Profiles dots; sample data only, no server change |
| 3 | Nationality / Ethnicity search: use the app's own lists in `SOURCE/lib/data/zyra_reference_data.dart` (nationality names; `zyraEthnicities` minus "Prefer not to say"); POPULAR, MATCHES, no-match text and chips exactly as the spec; show the two "Dominican" entries with their country in brackets |
| 4 | Remove the old list layout, City search, Country of residence row, "Best matches are shown first" and any member count |
| 5 | Preview distances: real latitude/longitude for the sample cities only and real km (great-circle); Near me / Country / Worldwide filter the sample people |
| 6 | Tests: swipe and arrows move between the 4 cards (no loop; ends disabled); Age range; Where segments and Near me steps; search "alg" → Algerian, "xyzq" → no-match text; add/remove chips; Clear (n) counts the four kinds; keyboard hides the pill; no count text; VoiceOver labels ("Age, filter 1 of 4"); Larger Text. Analyser clean |
| 7 | Render the ten master states into `FILTERS/BUILT/` (430 × 932 @3x; keyboard states with the real keyboard) plus one master-beside-build picture |
| 8 | Task note, commit within core rule 2, mark the queue line BUILT or FAILED |
