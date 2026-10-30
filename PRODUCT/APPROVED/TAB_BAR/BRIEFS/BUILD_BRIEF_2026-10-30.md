---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 6 V2 - tab bar small state 40% to 60%
links: [DR-ZYRA-276]
owner: ZYRA chat
---

# BUILD BRIEF — TAB BAR V2 (60%) — 30 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. The bar was built from V1 on 29 Oct (queue line 14);
this changes only the small idle state's size. The 29 Oct brief is in `../ARCHIVE/BUILD_BRIEF_2026-10-29.md`.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (spec **V2**) and the four `../MASTERS/` pictures |
| 2 | In the planned app's bottom bar (`ZyraShellNavigation` / `FloatingNavItem`), both roles: idle width 156 → **234**, height 46 → **50**, icons 16 → **18**, tap slot 26 → **38**. Nothing else changes (underline, first-tap-expands, 3 s / scroll collapse, accessibility, LOCK 5 gold rule) |
| 3 | Update the existing tab-bar tests to the new numbers. Analyser clean |
| 4 | Render the four master states into `TAB_BAR/BUILT/` (430 × 932 @3x), replacing the V1 pictures (move the old ones to `TAB_BAR/BUILT/ARCHIVE_V1/`), plus one master-beside-build picture |
| 5 | Task note, commit within core rule 2, mark the queue line BUILT or FAILED |
