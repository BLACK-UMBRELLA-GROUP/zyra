---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 13 V3 - Journey options page in Monogram + cards
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — JOURNEY OPTIONS (LOCK 13 V3) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue line 42 (Ivory); before line 44. Line 38 built V2; this line changes **only the Journey options page** (j08 → j10–j12). Every row keeps its V2 destination.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (LOCK record + spec **V3**) and masters j10, j11, j12 |
| 2 | Head: 88 pt round photo with the gold ring, "<First> <Surname>" 24 light, gold small caps "STAGE n OF 8 · <STAGE>", muted "<age> · <city> · <nationality>"; full-width gold **Continue Journey** |
| 3 | Three floating cards that fill the height down to the tab bar (grow 4 : 1 : 2, rows share each card's height, at least 46 each): (View Profile · Timeline · Journey Bio · Compatibility score) · (Guardians) · (Report · **End Journey** in red `#B84A42`, no chevron). Gold icons; locked rows muted with a lock |
| 4 | Remove the old single-card layout and the 38 round grey icons (no dead code) |
| 5 | Tests: all seven targets unchanged; locked/unlocked Bio and Compatibility; Seeker Basic; Larger Text grows rows (scrolls if needed, never clips). Analyser clean |
| 6 | Render j10–j12 into `JOURNEY_TAB/BUILT/V3/` with master-beside-build; task note; commit within core rule 2; mark queue line 57 BUILT or FAILED |
