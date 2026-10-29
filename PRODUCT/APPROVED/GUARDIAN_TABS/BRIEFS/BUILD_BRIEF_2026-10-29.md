---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 8 - Guardian five tabs and pages
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — GUARDIAN TABS — 29 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue lines 13 (LOCK 3, Circle fix)
and 14 (LOCK 6, tab bar).

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` and the 14 `../MASTERS/` pictures (g01–g14) |
| 2 | In the Founder preview (`SOURCE/lib/dev/zyra_one_journey_concept_shell.dart`, Guardian role: today 4 tabs 'Dashboard'/'My ZYRA', 'Network', 'Seekers', 'Profile' near lines 344 and 1390, headings near 5406 / 5590 / 5622 / 5650) change the Guardian app to the five tabs Network · Journeys · My ZYRA · Seekers · Profile, opening on My ZYRA, and draw each page as its master |
| 3 | Remove "Guardian Dashboard", Guardian Insights (including the Basic insights-locked card) and the Updates card from the Guardian app. Move anything removed only by moving files to `~/_to_delete/`; list it in the task note |
| 4 | Network: add **Introduce to <Seeker>** (DR-ZYRA-280 §9) and rename "Speak to Guardian" to **Connect with Guardian** everywhere in the planned app (terminology V2). Sample data only; no server change |
| 5 | Keep: DR-ZYRA-233 sharing rule, DR-ZYRA-292 read-only requests for Main only, the Journey page, Guardian Circle and invite screens unchanged; LOCK 5 and LOCK 6 tab-bar rules |
| 6 | Tests: five tabs in order, opens on My ZYRA; each page's text and buttons as the masters; "All Seekers ▾" and "for Adam ▾" switch; Additional Guardian sees no requests; Introduce and Connect confirm screens; no "Dashboard"/"Insights"/"Speak to Guardian" text left in the planned app. Analyser clean |
| 7 | Render the 14 master states into `GUARDIAN_TABS/BUILT/` with the same names (430 × 932 @3x) |
| 8 | Task note, commit within core rule 2, mark the queue line BUILT or FAILED |
