---
id: DOC-ZYRA-0421
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 6 - bottom tab bar look and the small idle state, Seeker and Guardian (V2 - small state 60%)
links: [DR-ZYRA-276, DOC-ZYRA-0282]
owner: ZYRA chat
---

# TAB BAR — SPEC — V2 (LOCKED 30 OCT 2026)

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
| **Idle state (small)** | Whenever the member is not touching the bar: the bar shrinks to **60% of its full width** (full 390 → **234**), height 58 → **50**, centred; icons **18**, each tap slot **38** wide; the underline shortens to sit under the small icon (inset 5). Animation 250 ms ease, no bounce |
| **Touched state (full)** | Touching anywhere on the bar grows it to full size (250 ms). In the small state the **first tap only expands** the bar (it never switches tab); taps on the full bar switch tab as today |
| Back to small | 3 seconds after the last touch on the bar, or as soon as the page scrolls |
| Accessibility | With VoiceOver, Switch Control or Larger Text on, the bar stays full size; with Reduce Motion on, the change is instant. Each tab keeps its name for screen readers |
| Where | Every tab root, Seeker and Guardian. Pages without a tab bar are unchanged |
| The ••• action bar on Profiles | Unchanged (full size, icons only) |
