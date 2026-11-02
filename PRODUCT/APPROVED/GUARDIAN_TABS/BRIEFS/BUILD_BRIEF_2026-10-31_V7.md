---
id: DOC-ZYRA-0404
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 8 V7 - Connect with Guardian and Introduce to Adam confirm pages in Monogram + card
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — GUARDIAN ACTION PAGES (LOCK 8 V7) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue lines 42 and 58 (LOCK 8 V6); before line 44. This line changes **only** the two confirm pages g07 (Introduce to Adam) and g08 (Connect with Guardian).

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (LOCK record + spec **V7**) and masters g07, g08 |
| 2 | Head: 96 pt gold-ring monogram with the other Seeker's initial (privacy as today — no photo, no surname), title 24 light, gold small caps "INTRODUCTION" / "CONNECT WITH GUARDIAN" |
| 3 | One floating card with three rows (gold icon, title, muted line): **Introduce** — "Adam sees Aisha in his Introductions" / "Marked "Suggested by Hassan"." · "Adam decides" / "Whether to send a Journey request is his choice." · "Aisha and her family are not told" / "Nothing is sent to them." **Connect** — "Send a request" / "To the Main Guardian supporting Aisha." · "They choose" / "Whether to respond is up to them." · "If they accept" / "A private chat opens between the two of you." |
| 4 | Bottom: gold **Introduce** / **Send request** (existing actions) and text **Not now** / **Not yet** (back). Remove the old paragraph layout (no dead code) |
| 5 | Tests: names come from the chosen person; actions and back unchanged; Larger Text. Analyser clean |
| 6 | Render g07, g08 into `GUARDIAN_TABS/BUILT/V7/` with master-beside-build; task note; commit within core rule 2; mark queue line 60 BUILT or FAILED |
