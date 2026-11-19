---
id: DOC-ZYRA-0505
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 2 V4 - Ended Journeys and Introductions use the Journey request card; Introductions Received/Past tabs; the Guardian's "Not taken forward"
links: [AD-AIOS-115, DR-ZYRA-284]
owner: ZYRA chat
---

# BUILD BRIEF — ONE CARD STYLE (ENDED JOURNEYS, INTRODUCTIONS) — 12 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Spec: `REQUESTS_AND_GUARDIANS/RECORD/REQUESTS_AND_GUARDIANS_SPEC_CURRENT_VERSION_V4.md` §2.6 (LOCK 2 V4). Reference: prototype V212
(private copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V226.html`) → My ZYRA → Ended Journeys /
Introductions (admin Developer panel loads sample data). Reuse the existing Journey request card component — do not draw a new one.
§2.7 (account deletion) is built by line 93 step 5, not here.

| Step | Detail |
|---|---|
| 1 | Build after lines 93 and 95 (this replaces line 93's ••• menu on Ended Journeys; the menu's actions and confirm words stay) |
| 1b | Needs: Founder present - at the Mac to click Allow if a test run asks to write the Flutter SDK cache (charters rule 15, QUESTIONS 169, 19 Nov). Daytime GO only; test logs under `SOURCE/build/` |
| 2 | **Ended Journeys:** each card = the Received request card (photo, first name + surname, **<age> · <city>**, gold **Journey ended · Timeline kept**, chevron). Open: gold **View Timeline** → read-only page "Journey with <first name>" with rows **Timeline** · **Journey Bio** · **Guardians**, each opening today's archived read-only page (QUESTIONS 164; master `MASTERS/ended_journeys__view_timeline_read_only.png`) · **Request a new Journey** (existing restart flow) · red **Remove from my Journeys** → existing LOCK 28 confirm and toast. Remove the ••• button |
| 3 | **Introductions:** tabs **Received · Past** (request tab pills, two equal). Received card line 3 gold **Put forward by <Guardian> · <relation>**; open: gold **View profile** · **Request a Journey** · **Decline** |
| 4 | **Request a Journey** sends a normal Journey request (it then shows in Journey requests → Sent) and moves the introduction to Past as **Journey requested**; toast "Request sent to <name>. It’s in Journey requests → Sent." |
| 5 | **Decline** moves it to Past as **You declined**; toast "Declined. <Guardian> sees “Not taken forward”." Past card: line 2 **Introduced <date> · from <Guardian>**, muted status, no chevron, no buttons; newest first; no expiry. Empty Past: history icon, **No past introductions.** / **Introductions you declined or took forward stay here.** |
| 6 | **Guardian side:** Introductions you’ve made — a declined one shows muted **Not taken forward** instead of "Suggested to <Seeker>". If the server has no field for this yet, keep it on preview data and mark this line QUESTION for that part only |
| 7 | Tests: card parity with the Received card (same widget); one card open at a time; each button's result; Past order and empty state; Guardian status after Decline |
| 8 | Gate: `flutter analyze` clean; no new failures. Visual check on 430 × 932 and 375 × 667 |
| 9 | Task note; commit within core rule 2; mark the queue line BUILT or FAILED |
