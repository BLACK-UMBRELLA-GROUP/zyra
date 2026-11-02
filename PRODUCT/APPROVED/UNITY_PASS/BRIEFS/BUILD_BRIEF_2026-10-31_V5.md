---
id: DOC-ZYRA-0431
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 22 V5 - Safety & advice page (Seeker)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — SAFETY & ADVICE PAGE (LOCK 22 V5) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue lines 52 (Profile tab) and 55 (Safety page); before line 44.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (spec **V5** §3d) and master x07 |
| 2 | New page **Safety & advice** (Seeker): back + title; Monogram head 88 with the gold health-and-safety shield, "Stay safe on your Journey", gold small caps "ZYRA SAFETY"; one floating card with the five tips exactly as spec V5 (gold icon, title, muted text); card with **Report a profile** "Open their profile and choose Report" → the existing Safety page (x04) and **Help & support** → existing Help page; muted line "In danger right now? Call your local emergency number (999 in the UK)." |
| 3 | Profile tab (LOCK 21) row **Safety & advice** now opens this page. Nothing else changes. No heart icons |
| 4 | Tests: Profile row opens the page; both rows' targets; Larger Text (page scrolls, never clips). Analyser clean |
| 5 | Render x07 into `UNITY_PASS/BUILT/V5/` with master-beside-build; task note; commit within core rule 2; mark queue line 64 BUILT or FAILED |
