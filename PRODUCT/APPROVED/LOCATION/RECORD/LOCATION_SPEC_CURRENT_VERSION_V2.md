---
id: TBC (Fable assigns)
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 11 - location for distance (V2 - sits in the Filters Where card under Near me; real geography)
links: [DOC-ZYRA-0329, OA-ZYRA-321]
owner: ZYRA chat
---

# LOCATION — SPEC — V2 (LOCKED 30 OCT 2026)

V1 is in `../ARCHIVE/LOCATION_SPEC_2026-10-30_V1.md`, its masters in `../ARCHIVE/MASTERS_V1/`. **What changed:** the Filters
redesign (LOCK 10 V3, Founder "LOCK it", 30 Oct) moved distance into the **Where** card under **Near me**, and distances use real
places. The sheets, wording and privacy rules are unchanged; the masters are re-rendered on the new Filters page.

Masters (430 × 932 @3x, prototype **V65** — re-rendered on the Filters V4 swipe-card **Where** card; the V60 list-page renders are in `../ARCHIVE/MASTERS_V2_LIST/`): `../MASTERS/location__choose_start.png`, `location__explain.png`,
`location__phone_prompt_reference.png` (the iPhone's own prompt — reference only, not drawn by ZYRA), `filters__from_current_area.png`.

| Item | Rule |
|---|---|
| Default | Near me starts from the member's **home town** (a real place from the profile). No permission needed |
| Origin line | On the Filters **Where** card (LOCK 10 V4, card 2), only when **Near me** is chosen: icon + "From Manchester (home town)" / "From your current area", gold **Change** |
| Choose sheet | "Where should distance start?" — "Only used to sort and filter by distance. Nobody else ever sees it." Two options with radio: **Home town** (from your profile, no permission needed) / **My current area** (uses your phone's location, roughly — never your exact spot); Done |
| Explain first | Choosing My current area the first time shows ZYRA's own sheet: icon, "Use your current area?", the purpose text, gold **Continue**, Not now. Continue → the iPhone prompt |
| iPhone prompt | Request "When In Use" with **approximate accuracy** (Precise off). Purpose string: "Your approximate area is used to measure distance in Filters. It is never shown to anyone." Allow → origin "your current area"; Don't Allow → stays on home town, toast "No problem — distances start from your home town." Later attempts after a refusal point to iPhone Settings |
| Real geography | Home towns are real places with real map positions; the current area is rounded to an approximate area; distances are real km (LOCK 10 V3) |
| **Privacy rules** | Use only an approximate area (rounded, never exact coordinates); **never shown** on profiles, cards or to Guardians; **no distance numbers on profile cards**; used only to filter/sort by distance; switchable off in Phone access (LOCK 12); deleted with the account |
| Server (not in this build) | Storing each member's town / rough area and filtering by distance is in Fable's server design (DOC-ZYRA-0329); the DPIA (OA-ZYRA-321) must cover it before launch |
