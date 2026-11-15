---
id: DOC-ZYRA-0487
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 32 app side - the one-time "Welcome back" item in My ZYRA after a 2-year inactivity notice
links: [OA-ZYRA-317, AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — "WELCOME BACK" ITEM (2-YEAR NOTICE) — 12 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Spec: `INACTIVITY_NOTICE/RECORD/INACTIVITY_NOTICE_SPEC_CURRENT_VERSION_V1.md` §3 (LOCK 32). The emails (§2) are server work for Fable, not this line.

| Step | Detail |
|---|---|
| 1 | Build after line 94 (server inactivity notice) |
| 2 | My ZYRA Needs-you item, newest first, history icon: **Welcome back, <first name>** / **You were away for a while. Your Ended Journeys are kept — nothing was removed.** / gold **View Ended Journeys** → Ended Journeys page |
| 3 | Shown **once**, only when this sign-in or app open cleared an open notice. Read the server's "notice cleared on return" field (QUESTIONS row 130, Fable); until it exists keep the item on preview data only and mark this line QUESTION for the read |
| 4 | Gone after it is tapped or the member leaves My ZYRA; never shown after a removal, never to accounts without a notice |
| 5 | Tests: open notice + return → item once; second open → none; no notice → none; after removal → none |
| 6 | Gate: `flutter analyze` clean; no new failures. Task note; commit within core rule 2; mark the queue line BUILT or FAILED |
