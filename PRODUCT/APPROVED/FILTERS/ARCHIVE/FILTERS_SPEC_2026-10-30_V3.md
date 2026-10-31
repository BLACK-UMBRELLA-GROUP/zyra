---
id: TBC (Fable assigns)
type: SPEC
status: ARCHIVED (2026-10-30)
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 10 - Filters page (V3 - one Where card replaces City, Distance and Country of residence; real geography)
links: [DOC-ZYRA-0284, DOC-ZYRA-0329, AD-AIOS-115]
owner: ZYRA chat
---

# FILTERS — SPEC — V3 (LOCKED 30 OCT 2026)

V1 and V2 are in `../ARCHIVE/` (V2 masters in `../ARCHIVE/MASTERS_V2/`). **What changed** (Founder 30 Oct, prototype comment:
"we have distance and city so why is city needed … we gotta allow aoption of maybe thier home contry for example uk aswell as
worldwide … it needs real gegraphy and the area radius gotta be real" → **"LOCK it"**):
City search is removed; Distance and Country of residence become one **Where** card; real places and real km; a link to the
member's Compatibility preferences. Nothing else changes.

Masters (430 × 932 @3x, prototype V60) in `../MASTERS/`: `filters__default` (Where = Country), `filters__age_range`,
`filters__where_near`, `filters__where_worldwide`. Location origin and its sheets are LOCK 11 (spec V2).

| Item | Rule |
|---|---|
| Layout | Title "Filters"; scrolling glass **cards** (radius 20, padding 14/16, 10 apart): Age · Where · Background; under them two centred lines; a fixed bottom bar: **Clear** (outlined, "(n)" = number of filters switched on) and gold **Show profiles** (52 high) |
| Age card | Icon + "Age"; segmented "Any age (18+)" / "Set range"; with Set range a **two-handle slider 18–70** (gold), live label "24 – 32" |
| **Where card** | Icon (globe) + "Where"; segmented **Near me · Country · Worldwide**. Default **Country** |
| Where — Near me | Origin line (LOCK 11: "From Manchester (home town)" / "From your current area" · Change) and a **one-handle slider** with steps 5, 10, 15, 25, 50, 75, 100, 150, 200, 300, 500 km; live label "Within 50 km"; ends "5 km" and "500 km". Default 50 km. Counts as one filter in Clear (n) |
| Where — Country | Row: flag icon, the country name (default: the member's **country of residence** from the profile, e.g. "United Kingdom"), muted "Change ›" → the full list of countries; under it "Your country of residence. Tap to choose another." |
| Where — Worldwide | Muted line "Members anywhere in the world." No other control |
| Background card | Nationality · Ethnicity, each "Any ›", opening today's lists. **Country of residence is no longer here** (it is Where → Country) |
| Lines under the cards | "✦ Best matches are shown first" (12.5 pt, muted) and a gold link **"Your preferences also shape who you see ›"** → the member's Compatibility preferences (green / amber / red) |
| **Real geography** | Every member's home town is a **real place** chosen from a real places list with real map positions (proposed: GeoNames, free, licence CC-BY 4.0 — attribution goes in the app's licences page). Distances are **real kilometres** between those positions, worked out on the server. Counties or regions are not needed: a radius from the member's town covers them (e.g. Crawley + 25 km includes Brighton and Worthing). In the Founder preview the sample people's sample cities use their real positions |
| **Privacy** | Only the town (or the rough current area, LOCK 11) is stored — never an exact spot; distances are never shown on cards or profiles; Where never reveals how many members are in a place |
| **Filter only on what is on the card** | Filters are only Age, Where, Nationality, Ethnicity. Sect, children, marital status, education, language, height and other private or Unlock answers are **never filters** (switching filters would reveal them); they work through the member's green / amber / red preferences, which already rank people and keep "red = not for me" out |
| Not filters | No "verified" filter (everyone passes the identity check), no "completed bio" filter (only complete profiles are shown), no membership filter (ZYRA One / Guardian One — would show who pays), no Compatibility filter (DR-ZYRA-288), no City search |
| **No member counts — ever** | Never show how many profiles or members match. The only number allowed is the count of filters switched on |
| Show profiles | Applies and returns to Profiles; Clear resets to the defaults (Any age, Where = Country of residence) |
| Accessibility | Sliders adjustable with VoiceOver (step up/down), labels spoken ("Distance, within 50 km"); the segmented control reads as three buttons with the selected one announced; Larger Text wraps, never clips |
| Server (not in this build) | Real place list, member town positions, distance and country filtering are server work in Fable's design DOC-ZYRA-0329 (and the DPIA for location) |
