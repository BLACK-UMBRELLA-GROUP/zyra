---
id: DOC-ZYRA-0381
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 10 V7 - Filters cards in the Monogram style
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — FILTERS MONOGRAM CARDS (LOCK 10 V7) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue line 42 (Ivory); before line 44. Line 37 built V6; this line changes **only the card head and the vertical placement** — everything else in Filters stays as built.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (LOCK record + spec **V7**) and the 10 `../MASTERS/` (f01–f10, re-rendered at V7) |
| 2 | Card head on all four cards: 92 pt circle with a 1 pt gold ring (`rgba(169,121,46,.7)`) holding the gold icon at 36; title 28 light; under it a gold small-caps line (11 pt, letter-spacing 1.2) showing the **current choice** (spec V7 table); then the existing muted line and controls |
| 3 | Age and Location cards: content block centred vertically in the card (no empty block at the bottom). Nationality and Ethnicity: content starts at the top as today |
| 4 | Remove the old head code (no dead code) |
| 5 | Tests: current-choice line updates live for every state in spec V7; centring on Age/Location at standard and Larger Text (wraps, never clips); swipe and arrows unchanged. Analyser clean |
| 6 | Render f01–f10 into `FILTERS/BUILT/V7/` with master-beside-build; task note; commit within core rule 2; mark queue line 53 BUILT or FAILED |
