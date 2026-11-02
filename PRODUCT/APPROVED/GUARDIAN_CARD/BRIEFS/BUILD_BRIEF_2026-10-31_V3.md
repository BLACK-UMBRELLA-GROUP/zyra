---
id: DOC-ZYRA-0386
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 19 V3 - the Guardian accepts or declines a ZYRA Family place (Guardian app, local preview)
links: [AD-AIOS-115, DR-ZYRA-291, DR-ZYRA-221]
owner: ZYRA chat
---

# BUILD BRIEF — GUARDIAN ACCEPTS A ZYRA FAMILY PLACE (LOCK 19 V3) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue lines 42, 48 (LOCK 19 V2 Seeker side) and **60** (LOCK 8 V7 — it brings the shared gold-ring monogram head and floating card this line reuses; 1 Nov, Codex question 7); before line 44.
Founder preview only, local state like the Seeker side (§8): no charge, no server write.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (LOCK record + spec **V3** §6.3, §6.4, §8) and masters k14–k16, k20–k22. Today's pages: `ZYRA/PRODUCT/APPROVED/BASELINE/SCREENSHOTS/guardian_basic/dashboard__normal.png` and `ZYRA/PRODUCT/APPROVED/BASELINE/SCREENSHOTS/guardian_basic/membership__current_basic.png` (both present, checked 1 Nov) |
| 2 | When the Seeker's local invite (§6.3) is pending, the Guardian Basic preview shows the Needs-you item (k20) → the page (k21), names, relationship, role and date from the invite |
| 3 | **Accept Guardian One** → the Guardian preview becomes Guardian One with the Profile row of k22; the Seeker's card moves to k16. **Decline** → toast, Seeker card back to Guardian Basic, place free |
| 4 | Reuse the shared gold-ring monogram head and floating card (same as LOCK 8 V7 confirm pages). No new widget |
| 5 | Tests: item shows only while an invite is pending; accept and decline paths; pronoun follows the Seeker; Larger Text. Analyser clean |
| 6 | Render k20–k22 into `GUARDIAN_CARD/BUILT/V3/` with master-beside-build; task note; commit within core rule 2; mark queue line 67 BUILT or FAILED |
