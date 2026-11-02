---
id: DOC-ZYRA-0390
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 20 - Guardian Circle as Topics
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — GUARDIAN CIRCLE (TOPICS) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue lines 42, 46 and 48 (LOCK 19 V2 — the "Reads only" row opens its sheet); before line 44.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (LOCK record + spec **V2**) and all 14 `../MASTERS/`. Today's pages: `BASELINE/SCREENSHOTS/seeker/guardians/` (Circle) and the Guardian Circle captures in `BASELINE/SCREENSHOTS/guardian/` |
| 2 | Rebuild the Seeker and Guardian Circle pages as Topics (spec §2–§3) using the **existing** Circle transcript and its existing Journey discussion data (incl. `discussionArchiveFor`). Remove the member count and the old layout code it replaces |
| 3 | Journey tabs: current Journeys; for Guardians only those with View access. Tie messages sent from a Journey tab to that Journey using the existing discussion link; show the About chip |
| 4 | Past (spec §4): Seeker always; Guardian only with the existing past-summaries sharing on (LOCK 3 V2 §3b format, no photo). Open until end date + 30 days, then composer replaced by the closed text. Use the Journey end date the app already has |
| 5 | ••• sheet (spec §5) with members, Mute/Unmute (existing), Report (existing press-and-hold), Manage your Guardians (Seeker only). Seeker's "Reads only" row opens the LOCK 19 Basic sheet |
| 6 | Guardian Basic (spec §6): read-only view with the lock line and **See Guardian One** (existing Guardian membership page). Spec §8: **local preview only** — show it with preview data; do **not** change server guards, admission, release switches or retention. If the preview can only show Basic by changing a guard, stop and report that one point. **Local preview writing rule (1 Nov, Codex question 6):** change only the Founder-preview Circle check in `SOURCE/lib/dev/` (today `_currentCircleData` funded/canSend needs Seeker One and every Guardian One) to a per-member rule: the **Seeker writes on Seeker One or Seeker Basic** (both paid roles; masters gc02, gc08), a **Guardian One writes**, a **Guardian Basic reads only** (gc13), and a Guardian Basic being in the Circle never stops anyone else writing. No server guard, admission, release switch or retention change |
| 7 | Tests: All shows every message; new-family empty state; tabs per Journey; Guardian tabs follow View access; tag on send; Past hidden for a Guardian with sharing off; open vs closed at day 30/31; closed has no composer; Basic has no composer; menu rows; bubble clears on open; opens at newest. Analyser clean |
| 8 | Render gc01–gc14 into `GUARDIAN_CIRCLE/BUILT/` with master-beside-build; task note; commit within core rule 2; mark queue line 51 BUILT or FAILED |
