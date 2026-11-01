---
id: DOC-ZYRA-0345
type: PLAN
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Codex task - the Compatibility score reader's 7 pages loop instead of stopping at the ends
links: [DR-ZYRA-288, OA-ZYRA-286]
owner: ZYRA chat
---

# COMPATIBILITY PAGES LOOP — BRIEF — 30 OCT 2026

**Founder, 30 Oct 2026** (comment on the prototype's Compatibility score page): **"lets make this a loop instead of back adn
forward meaning when thhey get to 7 and click right button it goes to 1 again"**. Founder-named task; no new picture — the
page looks exactly as today, only the ends change. Prototype version 43 shows it.

| Step | Detail |
|---|---|
| 1 | File: `SOURCE/lib/dev/zyra_draft_compatibility_score_designs.dart` (`_arrow`, `_goTo`, the `PageView`) |
| 2 | **→ on page 7 goes to page 1; ← on page 1 goes to page 7.** Both arrows are always enabled (no faded arrow). Page counter keeps showing "1 / 7" … "7 / 7" |
| 3 | Swiping does the same: swipe left on 7 → 1, swipe right on 1 → 7, with the normal page-turn movement (never a fast run back through all pages) |
| 4 | Screen readers: arrows keep "Previous page" / "Next page"; the page label still says "Page 1 of 7: Overall" |
| 5 | Same behaviour wherever this reader is used (Journey Compatibility after reveal, Profiles Compatibility after an Unlock, Ended Journey archive) |
| 6 | Tests: 7 → 1 and 1 → 7 by arrow and by swipe; arrows never disabled; counter and labels right. Analyser clean. Render page 7 and page 1 after a wrap into `COMPATIBILITY_LOOP/BUILT/` (430 × 932 @3x). Task note, commit within core rule 2, mark the queue line BUILT or FAILED |
