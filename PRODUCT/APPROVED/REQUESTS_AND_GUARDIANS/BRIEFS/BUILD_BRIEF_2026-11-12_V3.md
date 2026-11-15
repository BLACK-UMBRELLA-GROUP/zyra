---
id: DOC-ZYRA-0504
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 2 V3 - Journey requests Past shows one card per person (repeat requests grouped) and the ask-again date (7 / 14 / 30 days)
links: [AD-AIOS-115, DR-ZYRA-284]
owner: ZYRA chat
---

# BUILD BRIEF — JOURNEY REQUESTS PAST, ONE CARD PER PERSON — 12 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Spec: `REQUESTS_AND_GUARDIANS/RECORD/REQUESTS_AND_GUARDIANS_SPEC_CURRENT_VERSION_V4.md` §2.2 (LOCK 2 V3, kept in V4). Reference: prototype V204
(private copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V224.html` → My ZYRA → Journey requests →
Past; tap the page title → Developer → Past **Same person**). Layout from the app's existing Past card, not the prototype drawing.

| Step | Detail |
|---|---|
| 1 | Build after line 93 (it sets the 7-day ask-again copy this line extends) |
| 2 | **Group Past by person and direction:** one card per person you sent to, one per person who sent to you. A single request keeps today's card exactly |
| 3 | **Grouped card (2 or more):** line 2 **Last sent <date> · <n> requests** / **Last received <date> · <n> requests**; line 3 newest status (muted: Not taken up / Cancelled / You declined / You let it go); chevron like the Received/Sent cards; the card sits in the list at its newest request's date |
| 4 | **Open card:** thin divider, then one muted row per request — **Sent <date>** left, status right — newest first; newest **5** shown, then gold text link **Show all <n>** (shows the rest in place) |
| 5 | **Ask-again line:** in an open card you sent whose newest status is Not taken up → muted **You can ask <first name> again from <date>.** Date = newest "Not taken up" date + wait: **7 days**; after **5** consecutive Not taken up to that person **14 days**; after **10**, **30 days** (never more). Count is per pair and consecutive; a request that is taken up starts the count again. Read the date from the server when it exists (Fable, QUESTIONS row 128); until then compute it on preview data |
| 6 | Requests button on that person's profile: while the wait runs, the existing not-yet-allowed state shows the same date (no new design) |
| 7 | Tests: 1 request = old card; 20 to one person = 1 card, "20 requests", 5 rows then Show all 20; waits 7 (4 in a row), 14 (5–9), 30 (10, 20); count restarts after a taken-up request; received group never shows the ask-again line |
| 8 | Gate: `flutter analyze` clean; no new failures. Visual check of Past on 430 × 932 and 375 × 667 |
| 9 | Task note; commit within core rule 2; mark the queue line BUILT or FAILED |
