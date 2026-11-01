---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 22 V4 - Settings and Edit profile tidy
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — UNITY PASS V4 (SETTINGS + EDIT PROFILE) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue lines 42, 52 (Profile tab) and 61; before line 44.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (spec **V4** §3c) and masters s01–s03. Today's pages: `BASELINE/SCREENSHOTS/seeker/profile_membership_settings/settings__normal.png` and `edit_profile__normal.png` |
| 2 | **Settings:** standard page header (back + large left title "Settings", like every other page) instead of the small centred title. Remove the bottom **MEMBERSHIP** section (Membership stays in the top summary card and on the Profile tab). Every other row and section unchanged |
| 3 | **Edit profile:** title **Edit profile**; intro line unchanged; floating card with About you · Lifestyle · Marriage preferences · Green / Yellow / Red · Hard requirements (gold icons, counts as today, same targets); card with Date of birth / Gender (locked, as today); note text; card row **Open Help & support** |
| 4 | Remove the old layouts (no dead code). Tests: targets unchanged; no Membership section; Larger Text. Analyser clean |
| 5 | Render s01–s03 into `UNITY_PASS/BUILT/V4/` with master-beside-build; task note; commit within core rule 2; mark queue line 62 BUILT or FAILED |
