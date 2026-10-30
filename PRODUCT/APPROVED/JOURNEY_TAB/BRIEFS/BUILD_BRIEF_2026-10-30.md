---
id: TBC (Fable assigns)
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief for LOCK 13 - Seeker Journey tab swipe cards
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — JOURNEY TAB — 30 OCT 2026

**Copy exactly. No improvements.** Unclear or conflicting → stop and report.

| Step | Detail |
|---|---|
| 1 | Read `../RECORD/` (spec **V2**) and the eight `../MASTERS/` pictures (j01–j08) |
| 2 | Founder preview, Seeker Journey tab (both Seeker One and Seeker Basic): replace today's tab body with the locked swipe cards, dots, header •••, bottom pill, free-place card, empty state and Basic upsell. Reuse the Profiles request-pill component (LOCK 7) and the Profiles dots. The tab bar is LOCK 6 |
| 3 | Continue Journey opens today's Journey page (unchanged). ••• opens the new **Journey options page** (j08): build it from today's expanded Journey card, remove its inner ••• button, make the card fill the height, and wire all seven rows to today's destination pages as the spec lists. Browse profiles → Profiles tab; See Seeker One → today's Plans page |
| 4 | Next-step line from the existing local Journey state, using the spec's wording table; progress bar from the current stage number (1–8) |
| 5 | Tests: 0 / 1 / 2 / 3 Journeys on One and 0 / 1 on Basic match the masters; swipe and arrows (no loop, ends disabled); ••• only on a Journey card; free place → Browse profiles; Journey options: no inner •••, every row opens its page, locked rows greyed with a lock; the card fills to the pill (no dead space) at the 430 × 932 size and on a small phone; no hearts; VoiceOver card label; Larger Text. Analyser clean |
| 6 | Render the eight master states into `JOURNEY_TAB/BUILT/` (430 × 932 @3x) plus one master-beside-build picture |
| 7 | Task note, commit within core rule 2, mark the queue line BUILT or FAILED |
