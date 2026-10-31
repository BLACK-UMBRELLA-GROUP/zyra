---
id: TBC (Fable assigns)
type: SPEC
status: ARCHIVED (2026-10-30)
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 11 - Location for distance
links: [DOC-ZYRA-0284, DOC-ZYRA-0329, OA-ZYRA-321]
owner: ZYRA chat
---

# LOCATION — SPEC — V1 (LOCKED 30 OCT 2026)

Masters (430 × 932 @3x): `../MASTERS/location__choose_start.png`, `location__explain.png`, `location__phone_prompt_reference.png`
(the iPhone's own prompt — reference only, not drawn by ZYRA), `filters__from_current_area.png`.

| Item | Rule |
|---|---|
| Default | Distance starts from the member's **home town** (profile location). No permission needed |
| Origin line | In the Distance card: icon + "From Manchester (home town)" / "From your current area", gold **Change** |
| Choose sheet | "Where should distance start?" — "Only used to sort and filter by distance. Nobody else ever sees it." Two options with radio: **Home town** (from your profile, no permission needed) / **My current area** (uses your phone's location, roughly — never your exact spot); Done |
| Explain first | Choosing My current area the first time shows ZYRA's own sheet: icon, "Use your current area?", the purpose text, gold **Continue**, Not now. Continue → the iPhone prompt |
| iPhone prompt | Request "When In Use" with **approximate accuracy** (Precise off). Purpose string: "Your approximate area is used to measure distance in Filters. It is never shown to anyone." Allow → origin "your current area"; Don't Allow → stays on home town, toast "No problem — distances start from your home town." Later attempts after a refusal point to iPhone Settings |
| **Privacy rules** | Use only an approximate area (rounded, never exact coordinates); **never shown** on profiles, cards or to Guardians; **no distance numbers on profile cards** (exact distances let someone pinpoint a person); used only to filter/sort by distance; switchable off in Phone access (LOCK 12); deleted with the account |
| Server (not in this build) | Storing each member's rough area and filtering by distance is in Fable's server design (DOC-ZYRA-0329); the DPIA (OA-ZYRA-321) must cover it before launch |
