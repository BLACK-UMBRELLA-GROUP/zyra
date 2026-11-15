---
id: DOC-ZYRA-0459
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 26 - one sideways-swipe behaviour for the whole app (copied from the Guardian card carousel, LOCK 19 V9)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# APP SWIPE — SPEC — V2 (LOCKED 11 NOV 2026, NO EDGES WHILE SWIPING 21:45)

**V2 (11 Nov 21:45, Founder iPhone screenshot of line 81, Profiles mid-swipe):** "As i scroll i dont like the line below card. Can that be fixed please" + "And that applies to all card swipe features". Cause: the track is clipped to the card's own box, so the card shadow is cut off in a straight line under the cards and the cards are cut straight at the 20 pt side margins. Rule in §1 row "Edges (V2)". The prototype already behaves this way (copy V183). V1 is in `../ARCHIVE/APP_SWIPE_SPEC_2026-11-11_V1.md`.

**Founder, 11 Nov:** "how i want the swipe feature for gurdians page i want same in filters so the whol app wheever we swipe the page i want same feature unifed across whole app cp[ying the gurdian page if correct" → prototype **V177** → clickable **"LOCK it app-wide (Recommended)"**. No masters (charter rule 13).

## 1. The one swipe
| Item | Rule |
|---|---|
| Model | The swipeable cards / pages sit side by side in one horizontal track, **24 pt apart**; neighbours are off-screen at rest |
| Drag | Once the movement is clearly sideways (more horizontal than vertical, ~8 pt), the current card **and its neighbour move with the finger**, so the next (or previous) one slides into view — never an empty area. Vertical drags keep scrolling |
| Release | Past ~60 pt (or a quick flick) the track settles on the neighbour in **0.24 s**, curve (0.2, 0.8, 0.2, 1); otherwise it springs back the same way |
| Ends | At the first / last card the drag moves at ~30 % (resistance) and springs back; no wrap |
| Taps | A swipe never fires the tap of the control it started on (tiles, chips, buttons). Dots, edge taps and ‹ › controls animate the same track |
| Dots / counters | Update when the track settles |
| Reduce Motion | No slide: the content changes instantly |
| **Edges (V2)** | While swiping, **no line, band or straight edge** may show around the cards: (1) the track is **full screen width** and cards are only cut by the **screen edges**, never at the 20 pt side margins (at rest the card still sits 20 pt in from each side, 24 pt between cards); (2) **nothing is clipped top or bottom** — the card shadow shows in full under and around every card, exactly as at rest; (3) the track has no background or tint of its own. Same on every swipe surface in §2 (Profiles, Guardian cards, Journey places, Filters, My ZYRA Seeker + Guardian) because they share one component |
| Build | One shared component (a PageView-style track, viewport fraction 1, 24 pt page gap) used everywhere; no per-screen gesture code |

## 2. Where (today)
Profiles cards (LOCK 7 V4) · Guardian cards (LOCK 19 V9, the reference) · Journey tab places (LOCK 13) · Filters cards (LOCK 10) · My ZYRA "Needs you", Seeker and Guardian (LOCK 15 V5 whole-page swipe: the gesture can start anywhere above the tab bar; the Needs-you card is what moves) · any future sideways-swipe surface.
Not included: full-screen photo views (vertical photo paging) and pages that only scroll up / down.

## 3. Version history
| Version | Date | Change |
|---|---|---|
| V1 | 2026-11-11 | First version |
| V2 | 2026-11-11 | Edges (V2): full-width track, no top / bottom clip, card shadows never cut, on every swipe surface (Founder iPhone 21:45). V1 archived |
