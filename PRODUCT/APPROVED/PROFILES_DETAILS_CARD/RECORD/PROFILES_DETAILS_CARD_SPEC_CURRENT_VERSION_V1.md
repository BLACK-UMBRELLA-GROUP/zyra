---
id: TBC (Fable assigns)
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 4 - the circle above the name on the Profiles details card shows the person's own profile photo
links: [DR-ZYRA-276, DOC-ZYRA-0292]
owner: ZYRA chat
---

# PROFILES DETAILS CARD PHOTO — SPEC — V1 (LOCKED 29 OCT 2026)

| Item | Rule |
|---|---|
| Where | `ZyraProfileDetailsPage` (`SOURCE/lib/widgets/zyra_profile_details_page.dart`) — page 1 of the Profiles card, and everywhere else that page is used (own profile preview) |
| Today | A 56 × 56 gold-ring circle with a gold `person_outline` icon |
| Change | The circle shows the person's **first profile photo**, filling the circle (cover crop, centred), inside the **same** 56 × 56 gold ring (journey gold at 65% opacity, same soft glow), with a 2-logical-point gap between ring and photo |
| Photo source | The same private photo source the gallery already uses for that person (never a public link) |
| No photo / loading / error | Show today's gold person icon in the ring (no spinner, no broken image) |
| Everything else | Unchanged: name, surname, rows, sizes, spacing |
| Masters | `../MASTERS/profiles_tab__details_card_photo.png` (photo; the prototype draws a coloured initial where the real photo goes) and `../MASTERS/profiles_tab__details_card_no_photo.png` (fallback) |

## Change log
| Date | Version | Change |
|---|---|---|
| 2026-10-29 | V1 | LOCKed by the Founder |
