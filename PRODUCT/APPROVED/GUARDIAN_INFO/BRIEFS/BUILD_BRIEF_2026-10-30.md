---
id: DOC-ZYRA-0312
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 3 - What Guardians can do - copy the locked spec and masters exactly into the Founder preview
links: [AD-AIOS-115, DR-ZYRA-292]
owner: ZYRA chat
---

# BUILD BRIEF — WHAT GUARDIANS CAN DO — 30 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting with the code → stop and report in the task note.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/LOCK_RECORD.md`, `../RECORD/WHAT_GUARDIANS_CAN_DO_SPEC_CURRENT_VERSION_V2.md`, every picture in `../MASTERS/` |
| 1b | First do spec §3b (V2): Circle past-Journey topics follow the Seeker's per-Guardian Share past Journey summaries switch — off: none; on: "Adam & Hafsa · 1–10 Sep 2026" (first names and dates only). Tests as in §3b |
| 2 | Build in the **Founder preview** only (Seeker Profile tab: `zyra_one_journey_account_presentation.dart` / shell `_ownProfile`; a new page id, e.g. `guardian_info`). Reuse the Profiles details-card and bottom-row components — do not copy the prototype's code |
| 3 | Card 1 subtitle uses the preview's Main Guardian (sample Hassan · Father); with no Main Guardian show "You have no Main Guardian yet" |
| 4 | Tests: row present only for Seekers and first in SAFETY & SHARING; NEW tag clears after first open; four cards in order with exact words; swipe/tap/‹ › behaviour and limits; Manage your Guardians opens the Guardian tab. Analyser clean |
| 5 | Render every master state into `GUARDIAN_INFO/BUILT/` with the same names (baseline route, 430 × 932 @3x) |
| 6 | Task note ("Built from", BUILT/ beside MASTERS/, code-size table), commit within core rule 2, mark the queue line BUILT or FAILED |
