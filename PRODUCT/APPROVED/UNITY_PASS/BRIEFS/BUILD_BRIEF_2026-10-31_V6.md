---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 22 V6 - Guardian Safety & advice page (Guardian One and Guardian Basic)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — UNITY PASS V6 (GUARDIAN SAFETY & ADVICE) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue lines 42, 52 (Profile tab), 55 and 64 (Seeker Safety & advice — reuse its widget); before line 44.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (spec **V6** §3d and §3e) and masters x08, x09. Today's page: `BASELINE/SCREENSHOTS/guardian/profile_membership_settings/safety__no_subject.png` |
| 2 | Guardian Profile → **Safety & advice** opens the new page (both Guardian One and Guardian Basic). Reuse the Seeker Safety & advice layout from line 64 with the §3e words; do not duplicate the widget |
| 3 | Report a profile → the Guardian's existing Safety page; Help & support → existing Help page. Nothing else on the Guardian Profile tab changes |
| 4 | Tests: row opens the page for both Guardian plans; both rows reach their targets; Larger Text scrolls, never clips. Analyser clean |
| 5 | Render x08, x09 into `UNITY_PASS/BUILT/V6/` with master-beside-build; task note; commit within core rule 2; mark queue line 66 BUILT or FAILED |
