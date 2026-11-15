---
id: DOC-ZYRA-0459
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 26 - one sideways-swipe and scrolling feel for the whole app (smooth settle that follows the finger, iPhone bounce on every scroll)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# APP SWIPE — SPEC — V4 (LOCKED 11 NOV 2026 · V3 SMOOTH FEEL 12 NOV · V4 STILL PAGES 13 NOV)

**V4 (13 Nov 11:13, Founder iPhone screenshot of My ZYRA, "Nothing needs you right now"):** "This page doesnt need to scroll up and doen since there wont be jo scrolling so remove thst ability for me to move it". Rule (universal, Founder standing rule): **a page or sheet whose content fits the screen does not move at all when dragged up or down.** iPhone bounce stays only where the content is taller than the screen. Cause: the shared scroll feel wraps the bounce in `AlwaysScrollableScrollPhysics`, which lets short pages bounce.

**V3 (12 Nov 21:15–21:20, prototype V216 → V217):** Founder (iPhone, Guardian tab): "i cant explain it but using thr guridna page as a example, the seipign feels to sharp and too fast. I need a more smoother feel and this has to apply across whole app where scrolls, remmeber we want unifed system feel spacing ect" → clickables **"A · Smooth (Recommended)"** and **"iPhone bounce everywhere (Recommended)"**. V2 is in `../ARCHIVE/APP_SWIPE_SPEC_2026-11-12_V2.md`.

**V2 (11 Nov 21:45, Founder iPhone screenshot of line 81, Profiles mid-swipe):** "As i scroll i dont like the line below card. Can that be fixed please" + "And that applies to all card swipe features". Cause: the track is clipped to the card's own box, so the card shadow is cut off in a straight line under the cards and the cards are cut straight at the 20 pt side margins. Rule in §1 row "Edges (V2)". The prototype already behaves this way (copy V183). V1 is in `../ARCHIVE/APP_SWIPE_SPEC_2026-11-11_V1.md`.

**Founder, 11 Nov:** "how i want the swipe feature for gurdians page i want same in filters so the whol app wheever we swipe the page i want same feature unifed across whole app cp[ying the gurdian page if correct" → prototype **V177** → clickable **"LOCK it app-wide (Recommended)"**. No masters (charter rule 13).

## 1. The one swipe
| Item | Rule |
|---|---|
| Model | The swipeable cards / pages sit side by side in one horizontal track, **24 pt apart**; neighbours are off-screen at rest |
| Drag | Once the movement is clearly sideways (more horizontal than vertical, ~8 pt), the current card **and its neighbour move with the finger**, so the next (or previous) one slides into view — never an empty area. Vertical drags keep scrolling |
| Release (V3) | Moves on when the drag passes **~22 % of the card width**, or on a flick faster than **~0.45 pt/ms** that has moved at least 12 pt; otherwise it springs back. Settle curve **(0.22, 1, 0.36, 1)** (gentle slow-down). Settle time **follows the finger**: base **0.42 s**; a fast flick finishes sooner (remaining distance ÷ release speed × 1.6), never under **0.25 s** (60 % of base) and never over 0.42 s. Spring-back uses the same curve and rule. The track starts from the finger's current position and speed — no jump |
| Ends | At the first / last card the drag moves at ~30 % (resistance) and springs back; no wrap |
| Taps | A swipe never fires the tap of the control it started on (tiles, chips, buttons). Dots, edge taps and ‹ › controls animate the same track |
| Dots / counters | Update when the track settles |
| Reduce Motion | No slide: the content changes instantly |
| **Edges (V2)** | While swiping, **no line, band or straight edge** may show around the cards: (1) the track is **full screen width** and cards are only cut by the **screen edges**, never at the 20 pt side margins (at rest the card still sits 20 pt in from each side, 24 pt between cards); (2) **nothing is clipped top or bottom** — the card shadow shows in full under and around every card, exactly as at rest; (3) the track has no background or tint of its own. Same on every swipe surface in §2 (Profiles, Guardian cards, Journey places, Filters, My ZYRA Seeker + Guardian) because they share one component |
| Build | One shared component (a PageView-style track, viewport fraction 1, 24 pt page gap) used everywhere; no per-screen gesture code. **V3: one motion token file** (`ZyraMotion`: swipe base 420 ms, curve Cubic(0.22, 1, 0.36, 1), thresholds above) that every swipe, dot, edge-tap and programmatic page change reads — no other durations or curves for sideways moves |
| **Scrolling (V3)** | Every up/down scroll in the app (pages, sheets, lists, Timeline, chats, settings) uses **one** feel: iPhone bounce at the ends with normal iOS momentum **V4: only when the content is taller than the screen; a page that fits stays still** (`BouncingScrollPhysics` on its own, with no `AlwaysScrollableScrollPhysics`, via one shared scroll behaviour) — no `ClampingScrollPhysics` anywhere. Programmatic scrolls (scroll to top, jump to an item) animate with the same curve, 0.42 s. `NeverScrollable` stays only where a page must not scroll by design |

## 2. Where (today)
Profiles cards (LOCK 7 V4) · Guardian cards (LOCK 19 V9, the reference) · Journey tab places (LOCK 13) · Filters cards (LOCK 10) · My ZYRA "Needs you", Seeker and Guardian (LOCK 15 V5 whole-page swipe: the gesture can start anywhere above the tab bar; the Needs-you card is what moves) · any future sideways-swipe surface.
Not included: full-screen photo views (vertical photo paging) and pages that only scroll up / down.

## 3. Version history
| Version | Date | Change |
|---|---|---|
| V1 | 2026-11-11 | First version |
| V2 | 2026-11-11 | Edges (V2): full-width track, no top / bottom clip, card shadows never cut, on every swipe surface (Founder iPhone 21:45). V1 archived |
| V3 | 2026-11-12 | Smooth feel: settle 0.42 s curve (0.22,1,0.36,1) following finger speed, 22 % / flick threshold, one ZyraMotion token file; iPhone bounce on every scroll (Founder 21:15–21:20). V2 archived |
| V4 | 2026-11-13 | Pages and sheets that fit the screen no longer move when dragged; bounce only when content is taller than the screen (Founder, My ZYRA screenshot) |
