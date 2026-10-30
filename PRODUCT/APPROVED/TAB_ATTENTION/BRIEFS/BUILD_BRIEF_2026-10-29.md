---
id: DOC-ZYRA-0318
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 5 - tab icon gold clears when the tab is opened
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — TAB ICON ATTENTION — 29 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` and both `../MASTERS/` pictures |
| 2 | Founder preview only: the tab bar's gold for My ZYRA (shell ≈ line 1592, `_hasNewReceivedRequests`) clears when the My ZYRA tab is opened, via a "tab last opened" marker; gold returns only for activity newer than that marker. Do not change the request-seen rules inside My ZYRA |
| 3 | Tests: gold with an unseen request; plain after opening My ZYRA and leaving; gold again when a newer request arrives. Analyser clean |
| 4 | Render both master states into `TAB_ATTENTION/BUILT/` (430 × 932 @3x) |
| 5 | Task note, commit within core rule 2, mark the queue line BUILT or FAILED |
