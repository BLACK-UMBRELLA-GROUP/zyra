---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 18 V2 - page dots always at the top under the title, app-wide (photo dots on full-screen photo views excluded). Reissue: the line 49 brief file was empty
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — PAGE DOTS (LOCK 18 V2) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue lines 42, 43 and 48 (the Guardian tab masters of line 48 already show the dots at the top); before line 44.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (LOCK record + spec **V2**) and masters d01–d04 |
| 2 | Every page whose page dots sit at the bottom today: move them to the top, centred, directly under the title (spec "Where (moves to top)"): Seeker Guardian tab; My ZYRA Seeker and Guardian (remove the ‹ › arrows under the button — LOCK 15 V3); Photos; Your subscriptions; Journey → Guardians; any other bottom dots found |
| 3 | One shared dots widget with today's Profiles look: dot 6 × 6, gap 6, inactive 35 % ink, active 30 × 6 gold pill (animated width). Tappable where dots switch items (hit area ≥ 24 high); swiping still works |
| 4 | Do **not** touch: step progress bars (Journey stages, sign-up progress) and the vertical photo dots on full-screen photo views (`_profileView` → `_photoSurface`, `_guardianLinkedProfile`, `_guardianNetworkProfile`) |
| 5 | Remove the old bottom dots and arrows (no dead code). Tests: dots at top on each listed page; tap and swipe switch items; photo views unchanged; Larger Text. Analyser clean |
| 6 | Render d01–d04 into `PAGE_DOTS/BUILT/V2/` with master-beside-build; task note; commit within core rule 2; mark queue line 68 BUILT or FAILED |
