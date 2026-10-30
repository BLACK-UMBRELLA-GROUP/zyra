---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 8 - Guardian tabs, second attempt after queue line 20 stopped
links: [DR-ZYRA-306, DR-ZYRA-110, OA-ZYRA-325]
owner: ZYRA chat
---

# BUILD BRIEF — GUARDIAN TABS — V2 — 30 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Replaces the brief for queue line 20
(`../ARCHIVE/BUILD_BRIEF_2026-10-30_LINE20.md`). The three gaps it stopped on are closed in spec **V2** (Family Review trigger and
Pause/Reopen; g01 count; Connect Received, accepted, chat and empty states). Founder LOCK 30 Oct ("LOCK all three"; Connect accept →
"private chat").

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (spec **V2**) and the 20 `../MASTERS/` pictures (g01–g20). V1 masters in `../ARCHIVE/MASTERS_V1/` are history only |
| 2 | In the Founder preview (`SOURCE/lib/dev/zyra_one_journey_concept_shell.dart`, Guardian role) change the Guardian app to the five tabs Network · Journeys · My ZYRA · Seekers · Profile, opening on My ZYRA, and draw each page as its master |
| 3 | Remove "Guardian Dashboard", Guardian Insights (including the Basic insights-locked card) and the Updates card from the Guardian app. Move anything removed only by moving files to `~/_to_delete/`; list it in the task note |
| 4 | Network: add **Introduce to <Seeker>** (DR-ZYRA-280 §9) and rename "Speak to Guardian" to **Connect with Guardian** everywhere in the planned app. Network sample list excludes any Seeker whose only Guardian is Guardian Basic |
| 5 | Family Review in the preview: a seeded local sample state (open, 41 hours) for Adam and Sara; Continue / Pause / Reopen review exactly as spec §Family Review, including the stage line on Journeys, Seekers and the Seeker page. Local only — do not call the review RPCs, do not change `advanceStage` |
| 6 | Connect with Guardian: Sent / Received tabs; seeded received request from Noor's Main Guardian; Accept → accepted card → Open chat → Guardian chat page (reuse the existing chat bubble/composer/report components; local only); Not now → removed. My ZYRA tile opens Received; Quick access counts are this Guardian's own requests |
| 7 | Keep: DR-ZYRA-233 sharing rule, DR-ZYRA-292 read-only requests for Main only, the Journey page, Guardian Circle and invite screens unchanged; LOCK 5 and LOCK 6 tab-bar rules |
| 8 | Tests: five tabs in order, opens on My ZYRA; each page's text and buttons as the masters; Pause → paused card, Reopen → 48 hours, Continue → all caught up when nothing else waits; Connect Received Accept / Not now / Open chat; counts consistent on one screen; "All Seekers ▾" and "for Adam ▾" switch; Additional Guardian sees no requests and no review buttons; no "Dashboard"/"Insights"/"Speak to Guardian" text left. Analyser clean |
| 9 | Render the 20 master states into `GUARDIAN_TABS/BUILT/` with the same names (430 × 932 @3x), plus one master-beside-build picture |
| 10 | Task note, commit within core rule 2, mark the queue line BUILT or FAILED |
