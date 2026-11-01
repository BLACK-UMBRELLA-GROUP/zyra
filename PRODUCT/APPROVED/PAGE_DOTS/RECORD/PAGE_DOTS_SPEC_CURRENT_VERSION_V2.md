---
id: TBC (Fable assigns)
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 18 - page dots always at the top, under the title, app-wide
links: [AD-AIOS-115]
owner: ZYRA chat
---

# PAGE DOTS — SPEC — V2 (LOCKED 31 OCT 2026)

Masters (430 × 932 @3x, Ivory, prototype V104) in `../MASTERS/`: d01 profiles · d02 journey_tab · d03 guardian_tab · d04 my_zyra.

| Item | Rule |
|---|---|
| Rule | **Page dots always sit at the top, centred, directly under the page title** (above the card / content they belong to). Never at the bottom |
| Look | Dot 6 × 6, gap 6, inactive = 35 % ink; active = 30 × 6 gold pill (animates width) — today's Profiles dots |
| Tap | Dots that switch items are tappable (hit area at least 24 high); swiping still works |
| Where (already top) | Profiles, Journey tab, Filters, What Guardians can do |
| Where (moves to top) | **Seeker Guardian tab** (today at the bottom); **My ZYRA** Seeker and Guardian — the ‹ › arrows under the button are removed, dots at the top under the title / greeting (LOCK 15 V3); **Photos**, **Your subscriptions**, **Journey → Guardians** and any other page whose dots are at the bottom today |
| Not | Step progress bars (e.g. Journey stages, sign-up progress) are not page dots and stay as they are |
| Not (V2) | **Photo dots on full-screen photo views stay exactly as they are** — the vertical dots on the left of the photo that move through one person's photos. They are photo position, not page dots, and these views have no title. Today: shell `_profileView` → `_photoSurface`, `_guardianLinkedProfile`, `_guardianNetworkProfile` (all `ZyraOneJourneyBrowsePresentation`). Do not move, restyle or retitle them |

## Version history
| Date | Version | Change |
|---|---|---|
| 2026-10-31 | V1 | Founder: "LOCK dots at top" |
| 2026-10-31 | V2 | Codex line 47 stop (titleless photo views). Founder: "Leave them as is" — photo dots on full-screen photo views excluded |
