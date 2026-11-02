---
id: DOC-ZYRA-0402
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 8 V5 - Guardian Journeys tab as a photo card
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — GUARDIAN JOURNEYS PHOTO CARD (LOCK 8 V5) — 31 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report. Build after queue lines 42 (Ivory), 68 (page dots — reissue of 49) and 70 (LOCK 8 V4 — reissue of 54); before line 44. This line changes **only the Guardian Journeys tab** (g09). Everything else in LOCK 8 stays as built.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (LOCK record + spec **V5**, "Journeys" row) and masters g09, g09b, g09c |
| 2 | Under the title and "for Adam ▾", show LOCK 18 page dots (one per current Journey of the chosen Seeker), then **one full photo card per Journey** filling the space down to the Ended Journeys tile, using the same card component as the Seeker Journey tab (LOCK 13). Swipe moves between the Journeys. **Which Journeys (1 Nov, question 8):** Cards come from the existing permitted projection (`_permittedGuardianJourneys` — the chosen Seeker's current Journeys this Guardian may View), in the Seeker's Journey-tab order; nothing is inferred from requests and a card never grants View or Chat. The local Adam–Sara Family Review sample belongs **only to the Sara card**: its stage line follows the existing review mapping (open = Stage 4 Family Review, paused = Paused by family, continued = Stage 5 Building a Life); every other card shows its own model stage with no review. **Open Journey** opens the existing Journey page for that card's person (`_conceptGuardianJourney` focused on that Journey). Masters g09–g09c show the one-Journey case (Sara, first card) |
| 3 | On the photo, bottom-left, over a dark fade: **white** small caps stage line (as masters g09–g09c; corrected 1 Nov, question 9) ("STAGE 4 OF 8 · FAMILY REVIEW" / "· PAUSED BY FAMILY" / "STAGE 5 OF 8 · BUILDING A LIFE"), "Adam & Sara" 28 light, "Sara Ahmed · 27 · Birmingham · You: Main Guardian · View and Chat" (Guardian Basic: "View only"), then a full-width gold **Open Journey** (existing Journey page) |
| 4 | Keep the Ended Journeys tile under the card (unchanged). Remove the old letter tile and its layout (no dead code) |
| 5 | Tests: photo shows; stage text in all three review states; Basic "View only"; Open Journey and Ended Journeys targets; Larger Text wraps. Analyser clean |
| 6 | Render g09, g09b, g09c into `GUARDIAN_TABS/BUILT/V5/` with master-beside-build; task note; commit within core rule 2; mark queue line 56 BUILT or FAILED |
