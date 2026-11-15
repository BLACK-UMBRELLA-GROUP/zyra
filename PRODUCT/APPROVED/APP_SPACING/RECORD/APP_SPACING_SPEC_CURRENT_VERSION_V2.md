---
id: DOC-ZYRA-0455
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 24 - one even spacing rule across the app (16 pt above the tab bar; same gap for the same pair of parts on every screen)
links: [AD-AIOS-115]
owner: ZYRA chat
---

# APP SPACING — SPEC — V2 (LOCKED 11 NOV 2026, VALUES 11 NOV)

**V2 (11 Nov evening):** the exact Rule B values, set by the ZYRA chat answering Codex QUESTIONS rows 72–74 and 76–79 after line 77's audit (`../BUILT/SPACING_AUDIT.md`). V1 is in `../ARCHIVE/APP_SPACING_SPEC_2026-11-11_V1.md`.

**Founder, 11 Nov 2026 (using the app on his iPhone):** "on that page the nav bar and journey access button is too close
together- i need a deep search aacross app to ensure the spacing are all even-similar-neat and looks good" → clickable
**"Yes, 16 pt everywhere (Recommended)"**. Reference: prototype **V146** (every tab now leaves 16 pt above the tab bar).
No masters (charter rule 13). Layouts, words and colours do not change, only gaps.

## 1. Rule A — 16 pt above the tab bar
| Screen kind | Rule |
|---|---|
| Fixed pages (a pill, button row or card sits at the bottom: Profiles, Journey tab, Seeker Guardian tab, Guardian Network, and any other page with a bottom pill) | The bottom edge of the lowest pill / button / card is **16 pt** above the top edge of the tab bar at its resting height |
| Scrolling pages (My ZYRA, Profile tab, Guardian Journeys, Seekers, lists) | When scrolled to the end, the last item rests **16 pt** above the tab bar. While scrolling, content may pass behind the floating bar as today |
| Measured on | iPhone 430 × 932 with the 34 pt home-indicator inset, and 375 × 667 with no inset; default text and Larger Text; Seeker One, Seeker Basic, Guardian One, Guardian Basic |

Today's build: the Seeker Guardian tab pill sits about **2 pt** above the bar, because its bottom padding (86) ignores the home-indicator inset. Other tabs differ (for example 110 with and without the inset).

## 2. Rule B — same pair, same gap
The same two parts are the same distance apart on every screen: page side margin · title → page dots · page dots → card
· card → bottom pill · card → card · section label → its card · last item → tab bar (Rule A). Gaps use the scale
**4 · 8 · 12 · 16 · 24 · 32 pt** only. Where screens disagree today, use the value most LOCK masters use for that pair; if
there is no clear majority, do not guess: file a QUESTIONS row with the measurements.

## 2b. Rule B values (V2)
| Pair | Value |
|---|---|
| Page side margin | **20 pt** (the page edge; not part of the gap scale) |
| Title → page dots | **12 pt** |
| Card → bottom pill | **12 pt** |
| Card → card | **12 pt** |
| Section label → its card | **8 pt** |
| Last fixed control → tab bar | **16 pt** (Rule A) |
| Centred / short states (empty Journey, filtered Profiles, short Seekers, unlinked Network, short quick-access pages) | Keep their approved centred or flowing layout; Rule A applies at a real scroll end and to fixed bottom controls only (Q74, Q76, Q79) |

## 3. Rule C — fixed pages do not move
A page designed to fit the screen (cards that fill the space between the dots and the pill) does not scroll, drag or bounce
up and down. Only when Larger Text makes the content taller than its space may that content scroll, with no bounce.

## 4. Must not change
Card sizes beyond what the gap changes force (cards still fill the space, no dead space), words, colours, icons, tab bar
size and position, photo pages' edge-to-edge photos, sheets and dialogs.

## 5. Version history
| Version | Date | Change |
|---|---|---|
| V1 | 2026-11-11 | First version |
| V2 | 2026-11-11 | Rule B values (§2b) from QUESTIONS 72–74, 76–79 |
