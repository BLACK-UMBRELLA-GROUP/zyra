---
id: DOC-ZYRA-0428
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 22 V2 - Report profile page in Monogram + cards
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — UNITY PASS V2 (REPORT PROFILE) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue lines 42, 50 (LOCK 16 V2 sheets sit on this page) and 55; before line 44.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (LOCK record + spec **V2**, Report row) and masters x05, x06. Today's page: `BASELINE/SCREENSHOTS/seeker/browse_and_requests/report__reason_selected.png` |
| 2 | Head: 72 pt round photo with gold ring, "<First> <Surname>" 22 light, gold small caps "CHOOSE THE REASON" |
| 3 | One floating card with the seven reasons as radio rows (gold filled radio when chosen; first reason chosen by default as today) |
| 4 | Bottom: **Submit report** outline button (unchanged behaviour — still a draft, LOCK 16 V2); links **Hide profile** (muted) and **Block profile** (red) opening the existing flows and the LOCK 16 warning sheets |
| 5 | Remove the old grey pill rows (no dead code). Tests: choose each reason; Hide/Block open the LOCK 16 sheet during a Journey; Larger Text. Analyser clean |
| 6 | Render x05, x06 into `UNITY_PASS/BUILT/V2/` with master-beside-build; task note; commit within core rule 2; mark queue line 59 BUILT or FAILED |
