---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 8 V9 - Network card gold-ring monogram
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — NETWORK CARD MONOGRAM (LOCK 8 V9) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue lines 42 and 61 (LOCK 8 V8); before line 44. This line changes **only the avatar on the Network card** (g06).

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (spec **V9**) and master g06 |
| 2 | Replace the small dark filled circle with the shared gold-ring monogram: 110 pt circle, 1 pt gold ring `rgba(169,121,46,.7)`, the other Seeker's initial 52 pt weight 200 in gold; name line "A., 29" at 34 light. Privacy unchanged — no photo, no surname. Everything else on the card and the actions stay as built |
| 3 | Reuse the monogram widget from LOCK 19 / LOCK 21 (no new copy of it). Tests: initial shown, no photo; Larger Text. Analyser clean |
| 4 | Render g06 into `GUARDIAN_TABS/BUILT/V9/` with master-beside-build; task note; commit within core rule 2; mark queue line 63 BUILT or FAILED |
