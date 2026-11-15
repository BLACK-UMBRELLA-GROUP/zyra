---
id: DOC-ZYRA-0421
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 6 - bottom tab bar look and the small idle state, Seeker and Guardian (V2 - small state 60%)
links: [DR-ZYRA-276, DOC-ZYRA-0282]
owner: ZYRA chat
---

# TAB BAR — SPEC — V3 (LOCKED 11 NOV 2026)

**V3 (11 Nov, prototype V154–V155; Founder: "im also thinking of remeing the shrinking tab bar options and leaving it the one sizde - (bigger size)" → clickable **"LOCK one size (Recommended)"**):** the small idle state is removed. The bar is **always full size**; every tap switches tab. V2 is in `../ARCHIVE/TAB_BAR_SPEC_2026-11-11_V2.md`. The rows below marked V3 replace the V2 rows.

V1 (DOC-ZYRA-0320, built 29 Oct, queue line 14) is in `../ARCHIVE/TAB_BAR_SPEC_2026-10-30_V1.md`, its masters in
`../ARCHIVE/MASTERS_V1/`. **Only change:** the small idle state is **60%** of the full width instead of 40% (Founder 30 Oct:
"can we change this to 60% when small" → "LOCK 60%").

Masters (430 × 932 @3x): `../MASTERS/seeker_tab_bar__idle_small.png`, `seeker_tab_bar__touched_full.png`,
`guardian_tab_bar__idle_small.png`, `guardian_tab_bar__touched_full.png` (prototype V59).

| Item | Rule (logical points) |
|---|---|
| Base | Today's Floating Glass bar (same glass fill, border, radius, position above the home indicator) |
| Current tab | **No ring.** The icon is white, with a **gold underline** (journey gold, 2.5 tall, rounded, inset 10 from each side of the 44-wide tap area, 3 below the icon). Full state: icon scaled to the normal 21 |
| Other tabs | Muted icon colour as today |
| Gold "new activity" icon | Unchanged rule (LOCK 5): gold until that tab is opened — in both states |
| **One size (V3)** | The bar is always the full size: full width (390 on a 430 screen), **58** high, icons **21**, tap slots **44**, underline inset 10. It never shrinks, never grows and does not change size or brightness under a finger (no "breathing"). Touch feedback = the haptic (LOCK 21 V2) and the tab highlight |
| **Taps (V3)** | Every tap on a tab switches tab at once (no expand-first tap) |
| Back to small (V3) | Removed |
| Accessibility | (V3) Always full size, so no special case. Each tab keeps its name for screen readers |
| Where | Every tab root, Seeker and Guardian. Pages without a tab bar are unchanged |
| The ••• action bar on Profiles | Unchanged (full size, icons only) |
