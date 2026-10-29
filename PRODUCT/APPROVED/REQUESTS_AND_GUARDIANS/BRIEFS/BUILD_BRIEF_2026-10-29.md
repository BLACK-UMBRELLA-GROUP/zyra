---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 2 - Journey requests and Guardians - copy the locked spec and masters exactly into the Founder preview
links: [AD-AIOS-115, DR-ZYRA-284, DR-ZYRA-292]
owner: ZYRA chat
---

# BUILD BRIEF — JOURNEY REQUESTS AND GUARDIANS — 29 OCT 2026

**Copy exactly. No improvements, no redesign, no extra wording.** If anything in the locked files is unclear or
conflicts with the code, stop and say so in your task note before building — do not guess.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/LOCK_RECORD.md` and `../RECORD/REQUESTS_AND_GUARDIANS_SPEC_CURRENT_VERSION_V1.md` in full, and look at every picture in `../MASTERS/` |
| 2 | Build the four changes in spec §2 in the **Founder preview only** (`SOURCE/lib/dev/` — `zyra_one_journey_concept_shell.dart`, `zyra_view_request_draft_model.dart`, `zyra_request_activity_presentation.dart` and what they import). Found so far: the sent label is in `_invitationLabel` (shell ≈ line 1844); the places-full page and its confirmation are around shell lines 2790–2845; request tabs and actions around 2560–2630 |
| 3 | Past tab needs sample data in the preview model only (spec §2.2): decline → "You declined", cancel → "Cancelled", seeded "Not taken up". Items stay — no expiry; no server work |
| 4 | Do not touch spec §3 "Must not change". Do not add any "Main Guardian can see this request" line (spec §4) |
| 5 | Tests: update the preview's tests for the changed words and add tests for the Past tab (empty, entries, newest first, items never expire) and the Main Guardian message (shown once per Main change). Analyser clean |
| 6 | Screenshots: re-render every master state with the baseline route (430 × 932 @3x) into `PRODUCT/APPROVED/REQUESTS_AND_GUARDIANS/BUILT/` with the same file names as `MASTERS/`, so the ZYRA chat can compare side by side |
| 7 | Task note ("Built from: <these paths>", the BUILT/ pictures beside the masters, code-size table), commit and push within core rule 2, mark queue line 4 BUILT or FAILED |
| 8 | Phone: if the native route is cleared and the Founder's iPhone is connected, install with `./run.sh`; otherwise say so in the note |
