---
id: DOC-ZYRA-0420
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 2 V2 - accepting a Journey request when Journey places are full (four cases, held ending, neutral wording) in the Founder preview
links: [AD-AIOS-115, DR-ZYRA-284, DR-ZYRA-277]
owner: ZYRA chat
---

# BUILD BRIEF — ACCEPTING WHEN PLACES ARE FULL (LOCK 2 V2) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue line 42 (Ivory); before line 44.
Founder preview only (`SOURCE/lib/dev/`), local preview state — no server, database or migration.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/LOCK_RECORD.md`, spec **V2** (§2.3 and §2.5) and the 12 new masters in `../MASTERS/` (accept__*, sent__*, my_zyra__accepted_choose_place, preparing__both_ready, requests__past_let_go). Today's pages: `BUILT/request_capacity__*.png`, `BUILT/requests__*.png`, `BASELINE/SCREENSHOTS/seeker/journey/journey__preparing.png`, `journey__self_ready.png`, `journey__both_ready.png` |
| 2 | Accept: free place on both sides → the existing preparing page at once. You full → existing Choose a place → End & accept request → preparing. Other person full → waiting card (§2.5 words). Both full → Choose a place with the §2.5 body and **Accept request**; the chosen ending is **held** and applied only on confirm |
| 3 | Sent side: Accepted · choose a place card, My ZYRA Needs-you item, Choose a place (sent words), Let it go / Keep my Journeys → Past "You let it go" |
| 4 | Preview demo buttons exactly as named in §2.5 (same style as "Demo: Sara confirms readiness"); never outside the preview. Never show text saying the other person is full |
| 5 | Tests: all four cases; held ending not applied on "doesn't go ahead"; Begin starts Stage 1 in the freed place; Larger Text. Analyser clean |
| 6 | Render the 12 masters into `REQUESTS_AND_GUARDIANS/BUILT/V2/` with master-beside-build; task note; commit within core rule 2; mark queue line 65 BUILT or FAILED |
