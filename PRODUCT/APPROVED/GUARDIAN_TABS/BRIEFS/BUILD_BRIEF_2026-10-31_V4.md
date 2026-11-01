---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 8 V4 - Guardian chat header (Guardian app)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — GUARDIAN CHAT HEADER (LOCK 8 V4) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue line 42 (Ivory); before line 44. Line 29 built V2; this line changes **only the Guardian chat page** (g19). Everything else in LOCK 8 stays as built.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (LOCK record + spec **V4**, "Guardian chat" row) and masters g19, g21, g22 |
| 2 | Title **Guardian chat**. Under it a floating header card: 44 pt gold-ring monogram (other Guardian's initial for the Seeker, e.g. "N"), "Noor's Main Guardian", gold small caps "ABOUT ADAM AND NOOR", round **•••** |
| 3 | Empty chat: centred lock, **A private chat**, "Only you and Noor's Main Guardian see it. Keep it respectful — you can report anything here." Hidden once there is a message |
| 4 | Composer = the Guardian Circle composer (LOCK 20): field "Message Noor's Main Guardian" + gold round send |
| 5 | ••• opens a bottom sheet "Guardian chat": **Report a message** (existing press-and-hold report), **Block Noor's Main Guardian** (red; existing block flow with its confirm), gold **Done**. No other rows |
| 6 | Remove the old header and lock line (no dead code). Tests: header, empty → message, sheet rows and targets. Analyser clean |
| 7 | Render g19, g21, g22 into `GUARDIAN_TABS/BUILT/V4/` with master-beside-build; task note; commit within core rule 2; mark queue line 54 BUILT or FAILED |
