---
id: DOC-ZYRA-0427
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 22 V1 - Compatibility score, Compatibility Unlocks and Safety in the Monogram style
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — UNITY PASS V1 (BIG RING PAGES) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue line 42 (Ivory); before line 44.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (LOCK record + spec V1) and the 4 `../MASTERS/`. Today's pages: `BASELINE/SCREENSHOTS/seeker/profile_membership_settings/compatibility_store__normal.png` and the Compatibility / Safety captures in BASELINE |
| 2 | Rebuild the three pages to spec §2–§3, using the **existing** unlock action, unlock balance, pack data, the 8 "What's included" cards, and the existing navigation (Get more → Compatibility Unlocks) |
| 3 | Remove Safety's disabled "Submit report" button, the Unlocks page's "Unlocks remaining" box and (i) button, and the old big-ring layouts (no dead code). Leave the revealed Compatibility state untouched |
| 4 | Tests: Seeker One and Basic header lines; 0 / 1 / several Unlocks wording; pack selection default 3; Get more goes to Unlocks; Safety has no button. Larger Text grows, never clips. Analyser clean |
| 5 | Render x01–x04 into `UNITY_PASS/BUILT/V1/` with master-beside-build; task note; commit within core rule 2; mark queue line 55 BUILT or FAILED |
