---
id: DOC-ZYRA-0403
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 8 V6 - Guardian's Seeker page in Monogram + cards
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — GUARDIAN SEEKER PAGE (LOCK 8 V6) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue lines 42 and 56 (LOCK 8 V5); before line 44. This line changes **only the Seeker page** (g11, g12).

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (LOCK record + spec **V6**, "Seeker page" row) and masters g11, g12 |
| 2 | Head: 84 pt gold-ring monogram with the Seeker's initial, name 24 light, gold small caps "YOU ARE HIS MAIN GUARDIAN" / "YOU ARE AN ADDITIONAL GUARDIAN" (her/his from the Seeker's gender) |
| 3 | Card 1 (grows 5): rows Status ("✓ Active · linked 20 Sep 2026", gold tick) · Role · Journeys · Journey requests · Past summaries — same values as today. Card 2 (grows 2): **Current Journey** "With Sara · Family Review" → existing Journey page (or muted "No current Journey"), **<Name>'s Guardian Circle** → Circle. Cards fill the height |
| 4 | Remove the old status bar, labels and the two outline buttons (no dead code). Tests: Main and Additional values; targets; Larger Text. Analyser clean |
| 5 | Render g11, g12 into `GUARDIAN_TABS/BUILT/V6/` with master-beside-build; task note; commit within core rule 2; mark queue line 58 BUILT or FAILED |
