---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 17 - unread-count bubble
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — UNREAD BUBBLE — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue line 42 (Ivory colours); before line 44.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (spec V1) and `../MASTERS/u01` |
| 2 | Make one shared bubble widget to the spec; show it on the Seeker Guardian tab's Guardian Circle button with the real unread count from the existing Circle data |
| 3 | Find every other icon button in the Founder preview that opens a conversation and already knows an unread count; use the same widget. List them in the task note. Do not add unread counting where none exists |
| 4 | Tests: 0 = hidden; 1–9 number; ≥10 "9+"; clears after opening; colours. Analyser clean |
| 5 | Render u01 into `UNREAD_BADGE/BUILT/` with master-beside-build; task note; commit within core rule 2; mark the queue line BUILT or FAILED |
