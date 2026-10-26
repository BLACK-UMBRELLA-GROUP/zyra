---
id: DOC-ZYRA-0100
type: BRAND
status: CURRENT
feature: BUSINESS: COLOUR THEME
purpose: Colour Theme — how the app decides which background and surface colours to show
links: [DOC-ZYRA-0102]
owner: Founder (decisions) · Fable (document)
---

# ZYRA — COLOUR THEME — FLOW — V2 (CURRENT)

Rewritten 25 Oct 2026 from the code (OA-ZYRA-313). V1 (male blue / female pink logic, retired 20 Aug 2026) is in
`ARCHIVE/COLOUR_THEME_FLOW_DIAGRAM_2026-10-25_V1.md`. Values: `Summary.md`.

```
App starts
  │
  ├─ Launch screen (before the app loads) ─────────► flat #160E20
  │
  ├─ Has this installation had the 27 Sep reset?
  │     no ─► set background to Midnight Plum once, mark it done
  │
  ├─ Did this member choose a background in Personalisation?
  │     yes ─► that background (one of the 10 dark options)
  │     no  ─► Midnight Plum #30203F → #160E20
  │
  └─ Every page, both roles, sign-up and onboarding use that ONE background
        (gender is ignored)
              │
              ├─ Gold accents On? ─► add gold dust + diagonal edge behind it
              │                      (still if the phone asks for reduced motion)
              │
              ├─ Cards, pills, panels ─► white 7% glass, white 14% edge
              ├─ Selected / important ─► same glass, gold #E8C98A 70% edge
              ├─ Sheets, dialogs, toasts ─► opaque #241A2F
              └─ Text ─► white at 100 / 90 / 70 / 54 %
```

Developer Tools can preview other backgrounds, light themes and surface styles for the running session only; members never see
them and they reset on relaunch.
