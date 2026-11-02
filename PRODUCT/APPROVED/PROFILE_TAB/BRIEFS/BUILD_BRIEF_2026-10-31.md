---
id: DOC-ZYRA-0417
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 21 - Profile tab Monogram
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — PROFILE TAB (MONOGRAM) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue line 42 (Ivory); before line 44.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (LOCK record + spec V1) and the 6 `../MASTERS/`. Today's tabs: `BASELINE/SCREENSHOTS/seeker/profile_membership_settings/profile_tab__normal.png` and the Guardian profile tab capture in `BASELINE/SCREENSHOTS/guardian/` |
| 2 | Rebuild the Seeker and Guardian Profile tab pages to spec §2–§3. Every row and pill opens the **same existing page or action** it opens today (spec table "Opens"). Add no new pages |
| 3 | Remove what spec §4 lists, along with the code that only served it (no dead code). Rename the "Your subscriptions" row label only; the page itself is unchanged |
| 4 | Basic variants: the Seeker Basic and Guardian Basic membership rows read "See Seeker One" / "See Guardian One" and open the existing upgrade pages |
| 5 | Tests: row order and targets for all four roles; Sign out last and red; no About me; Larger Text wraps pills. Analyser clean |
| 6 | Render p01–p06 into `PROFILE_TAB/BUILT/` with master-beside-build; task note; commit within core rule 2; mark queue line 52 BUILT or FAILED |
