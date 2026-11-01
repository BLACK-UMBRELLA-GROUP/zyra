---
id: DOC-ZYRA-0349
type: PLAN
status: ARCHIVED (2026-10-30)
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 10 V3 - Filters with the Where card
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — FILTERS — V3 — 30 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Replaces queue line 31 (V2 brief, never built —
`../ARCHIVE/BUILD_BRIEF_2026-10-30_V2.md`). Founder LOCK 30 Oct ("LOCK it").

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (spec **V3**) and the four `../MASTERS/` pictures; also `LOCATION/` (LOCK 11, spec V2) for the origin line |
| 2 | Founder preview `_filters` page: rebuild as the locked cards — Age, Where (Near me / Country / Worldwide), Nationality + Ethnicity — the two lines and the bottom bar. Keep today's filter state and how Profiles uses it; sample data only, no server change |
| 3 | Remove any City filter or city search, any profile/member count, and Country of residence from the Background card. Do not add a Compatibility, verified, bio or membership filter |
| 4 | Preview distances: give each sample city its real position (latitude/longitude constants for the sample cities only) and measure real km (great-circle). Near me filters sample people within the slider's km; Country filters by sample country of residence; Worldwide shows all |
| 5 | Tests: age range drag + labels; Where default Country; Near me slider steps 5…500 km and "Within 50 km" default; Worldwide line; Country row text; Clear resets and "(n)" counts Age and Near me only; preferences link present; no count text anywhere; VoiceOver labels; Larger Text. Analyser clean |
| 6 | Render the four master states into `FILTERS/BUILT/` (430 × 932 @3x) plus one master-beside-build picture |
| 7 | Task note, commit within core rule 2, mark the queue line BUILT or FAILED |
