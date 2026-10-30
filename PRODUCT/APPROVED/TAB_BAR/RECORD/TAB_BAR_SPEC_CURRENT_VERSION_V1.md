---
id: DOC-ZYRA-0320
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 6 - bottom tab bar look and the small idle state, Seeker and Guardian
links: [DR-ZYRA-276, DOC-ZYRA-0282]
owner: ZYRA chat
---

# TAB BAR — SPEC — V1 (LOCKED 29 OCT 2026)

Masters (430 × 932 @3x): `../MASTERS/seeker_tab_bar__idle_small.png`, `seeker_tab_bar__touched_full.png`,
`guardian_tab_bar__idle_small.png`, `guardian_tab_bar__touched_full.png`. The Guardian masters show the proposed five Guardian
tabs (not yet LOCKed); apply this bar to whatever tabs the Guardian app has when it is built.

| Item | Rule (logical points) |
|---|---|
| Base | Today's Floating Glass bar (same glass fill, border, radius, position above the home indicator) |
| Current tab | **No ring.** The icon is white, with a **gold underline** (journey gold, 2.5 tall, rounded, inset 10 from each side of the 44-wide tap area, 3 below the icon). Full state: icon scaled to the normal 21 |
| Other tabs | Muted icon colour as today |
| Gold "new activity" icon | Unchanged rule (LOCK 5): gold until that tab is opened — in both states |
| **Idle state (small)** | Whenever the member is not touching the bar: the bar shrinks to **40% of its full width** (full 390 → **156**), height 58 → **46**, centred; icons 16, spacing 26 each; the underline shortens to sit under the small icon. Animation 250 ms ease, no bounce |
| **Touched state (full)** | Touching anywhere on the bar grows it to full size (250 ms). In the small state the **first tap only expands** the bar (it never switches tab — the small icons are below the 44-point touch minimum); taps on the full bar switch tab as today |
| Back to small | 3 seconds after the last touch on the bar, or as soon as the page scrolls |
| Accessibility | With VoiceOver, Switch Control or Larger Text on, the bar stays full size; with Reduce Motion on, the change is instant. Each tab keeps its name for screen readers |
| Where | Every tab root, Seeker and Guardian. Pages without a tab bar are unchanged |
| The ••• action bar on Profiles | Unchanged (full size, icons only) |
