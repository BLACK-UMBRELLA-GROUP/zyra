---
id: DOC-ZYRA-0457
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 26 - one sideways-swipe behaviour for the whole app (copied from the Guardian card carousel, LOCK 19 V9)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# APP SWIPE — SPEC — V1 (LOCKED 11 NOV 2026)

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
| Build | One shared component (a PageView-style track, viewport fraction 1, 24 pt page gap) used everywhere; no per-screen gesture code |

## 2. Where (today)
Guardian cards (LOCK 19 V9, the reference) · Journey tab places (LOCK 13) · Filters cards (LOCK 10) · My ZYRA "Needs you", Seeker and Guardian (LOCK 15 V5 whole-page swipe: the gesture can start anywhere above the tab bar; the Needs-you card is what moves) · any future sideways-swipe surface.
Not included: full-screen photo views (vertical photo paging) and pages that only scroll up / down.

## 3. Version history
| Version | Date | Change |
|---|---|---|
| V1 | 2026-11-11 | First version |
