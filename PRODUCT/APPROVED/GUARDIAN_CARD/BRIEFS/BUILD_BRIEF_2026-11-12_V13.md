---
id: DOC-ZYRA-0484
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 19 V13 - Add card without pill, 104 pt round + button, 14 pt gaps in Journey access rows, no (i) on Past Journey summaries plus the FAQ entry
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — GUARDIAN CARD V13 — 12 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Reference: prototype V222 (private copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V224.html`). Layout from the app's existing components.

Spec: `GUARDIAN_CARD/RECORD/GUARDIAN_CARD_SPEC_CURRENT_VERSION_V13.md` (LOCK 19 V13) and `HELP_FAQ/RECORD/HELP_FAQ_SPEC_CURRENT_VERSION_V1.md`.

| Step | Detail |
|---|---|
| 1 | **Add card** (Seeker One and Seeker Basic, also with no Guardians yet): remove the pill under the card; the card fills to 16 pt above the tab bar like a Guardian card; the plus becomes a **104 pt round button** (ivory fill, 1.5 pt gold outline, soft shadow, gold plus 40 pt stroke 1.6, pressed scale 0.96) that opens Add a Guardian (LOCK 9); label "Add a Guardian". Text below unchanged (Basic keeps its boxes and link) |
| 2 | **Journey access rows:** 14 pt between the 40 pt dashed free-place circle and its text, and 14 pt between a Journey row's photo and its text |
| 3 | **Past Journey summaries** row: no (i) button |
| 4 | **FAQ:** add category **Guardians** (after "Matching and Journeys") in `lib/data/help_content.dart` with HELP_FAQ V1 entry 1, words exactly; searchable |
| 5 | Tests: add card has no pill and the + opens Add a Guardian; gaps 14 pt; FAQ entry found by search "summaries" |
| 6 | Gate: `flutter analyze` clean; no new failures; visual check 430 × 932 and 375 × 667. Task note; commit within core rule 2; mark the queue line BUILT or FAILED |
