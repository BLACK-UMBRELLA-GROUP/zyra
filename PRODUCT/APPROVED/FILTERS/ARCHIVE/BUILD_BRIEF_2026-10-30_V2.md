---
id: DOC-ZYRA-0348
type: PLAN
status: ARCHIVED (2026-10-30)
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 10 - Filters, second attempt after queue line 25 stopped
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — FILTERS — V2 — 30 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Replaces the brief for queue line 25
(`../ARCHIVE/BUILD_BRIEF_2026-10-30_LINE25.md`), which stopped because the city search typing states were not drawn. Spec V2 adds
them; Founder LOCK 30 Oct ("LOCK all three").

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (spec **V2**) and the five `../MASTERS/` pictures; also `LOCATION/` (LOCK 11) for the origin line |
| 2 | Founder preview `_filters` page: rebuild as the locked cards, sliders, city search (empty / matches / no match / keyboard open) and bottom bar. Keep today's filter state and how Profiles uses it; sample data only, no server change |
| 3 | Remove any profile/member count from Filters and the bottom bar. Do not add a Compatibility filter |
| 4 | Tests: age range drag + labels; distance steps incl. "Any distance"; type "brad" → Bradford chip under MATCHES; type "xyzq" → No city called "xyzq".; tap a match → chip added, field cleared, SUGGESTED back; remove a chip with ×; bottom bar hidden while the keyboard is open; Clear resets and shows "(n)" correctly; no count text anywhere; VoiceOver slider actions; Larger Text. Analyser clean |
| 5 | Render the five master states into `FILTERS/BUILT/` (430 × 932 @3x; the two keyboard states with the real keyboard), plus one master-beside-build picture |
| 6 | Task note, commit within core rule 2, mark the queue line BUILT or FAILED |
