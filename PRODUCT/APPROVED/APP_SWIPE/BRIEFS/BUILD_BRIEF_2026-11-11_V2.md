---
id: DOC-ZYRA-0458
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex build brief - remove the line / straight edges around cards while swiping, on every swipe surface (LOCK 26 V2)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# BUILD BRIEF — NO EDGES WHILE SWIPING — 11 NOV 2026

**Copy exactly. No improvements.** Unclear → `QUESTIONS.md` row. ROADMAP row (charter rule 12): "Test baseline and final interface pass" (do not tick).
Founder (iPhone, Profiles mid-swipe after line 81): "As i scroll i dont like the line below card. Can that be fixed please" + "And that applies to all card swipe features".
What the screenshot shows: a straight line under the cards where their shadow is cut off, and the cards cut straight at the 20 pt side margins.
Reference: `APP_SWIPE/RECORD/APP_SWIPE_SPEC_CURRENT_VERSION_V2.md` row "Edges (V2)", and the prototype copy `PRODUCT/APPROVED/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V187.html` (swipe Profiles, Guardian, Journey, Filters, My ZYRA: no line, cards slide off at the screen edge).

| Step | Detail |
|---|---|
| 1 | In the **one shared swipe component** (line 81 step 1e): make the track **full screen width** so cards are cut only by the screen edges (at rest: card 20 pt from each side, 24 pt between cards — e.g. viewport fraction and page padding set so the gap stays 24) |
| 2 | **No top / bottom clipping**: the card shadow shows in full during a swipe exactly as at rest (e.g. clip off vertically, or the track tall enough to hold the shadow). The track has no background or tint |
| 3 | Check every surface uses the shared component with this fix: Profiles, Guardian cards, Journey places, Filters, My ZYRA (Seeker + Guardian). Any surface still using its own gesture → move it onto the shared component |
| 4 | Visual check mid-swipe against the prototype copy on 430 × 932 and 375 × 667: no line under or around any card; note the result in the task note |
| 5 | Tests: during a drag the track's clip box is the screen width and does not end at the card's bottom edge (shadow area inside the visible box) on each surface; layout at rest unchanged (20 pt sides, 16 pt to the tab bar) |
| 6 | Gate: `flutter analyze` clean; no new failures against line 81 |
| 7 | iPhone: protected route only, on Shakeel's GO with the phone connected, telling him the build first |
| 8 | Task note; commit within core rule 2; mark queue line 82 BUILT or FAILED |
