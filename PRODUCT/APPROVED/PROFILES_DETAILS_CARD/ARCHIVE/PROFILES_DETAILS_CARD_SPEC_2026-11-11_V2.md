---
id: DOC-ZYRA-0314
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 4 - the circle above the name on the Profiles details card shows the person's own profile photo
links: [DR-ZYRA-276, DOC-ZYRA-0292]
owner: ZYRA chat
---

# PROFILES DETAILS CARD PHOTO — SPEC — V2 (LOCKED 29 OCT 2026) · GOLD RING = SEEKER ONE (11 NOV 2026)

**V2 (11 Nov, prototype V165):** the gold ring now means **Seeker One**. Founder: "we already have a gold ring to show they are seeker one which other person should be able to see anyway" → "yes gold and basic get no ring just profiel photo". Seeker One profiles: the 56 × 56 gold ring as V1. **Seeker Basic profiles: no ring, no glow, the photo circle only (56 × 56).** No-photo fallback: Seeker One keeps the gold ring and person icon; Seeker Basic shows the person icon in a plain circle without the gold ring. VoiceOver adds "Seeker One" to the photo label when the ring shows. V1 is in `../ARCHIVE/PROFILES_DETAILS_CARD_SPEC_2026-11-11_V1.md`.

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
