---
id: DOC-ZYRA-0350
type: SPEC
status: ARCHIVED (2026-10-30)
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 10 - Filters page
links: [DOC-ZYRA-0284]
owner: ZYRA chat
---

# FILTERS — SPEC — V1 (LOCKED 30 OCT 2026)

Masters (430 × 932 @3x): `../MASTERS/filters__default.png`, `filters__age_range.png`, `filters__city_and_distance.png`.
Location origin (the "From … · Change" line) is LOCK 11.

| Item | Rule |
|---|---|
| Layout | Title "Filters"; scrolling list of glass **cards** (radius 20, padding 14/16, 10 apart); a fixed bottom bar: **Clear** (outlined, shows "(n)" = number of filters switched on) and gold **Show profiles** (52 high) |
| Age card | Icon + "Age"; segmented "Any age (18+)" / "Set range"; with Set range a **two-handle slider 18–70** (gold), live label "24 – 32" |
| Background card | Rows with icon: Country of residence · Nationality · Ethnicity, each "Any ›", opening today's lists |
| Distance card | Icon + "Distance"; origin line (LOCK 11); **one-handle slider** with steps 5, 10, 15, 25, 50, 75, 100, 150, 200, 300, 500 km, then **Any distance** at the far right; live label "Within 50 km" / "Any distance"; ends labelled "5 km" and "Any" |
| City card | Icon + "City"; **"Search any city"** field with type-ahead; tap a result to add it; several cities allowed, each a gold chip with ×; none chosen = "All places — add cities to narrow it down."; when the field is empty show "SUGGESTED" popular cities |
| Line under the cards | "✦ Best matches are shown first" (12.5 pt, muted) |
| **No member counts — ever** | Never show how many profiles or members match (Founder: "it exposes zyras user count"). The only number allowed is the count of filters switched on |
| No Compatibility filter | Scores are only seen with an Unlock (DR-ZYRA-288) |
| Show profiles | Applies and returns to Profiles; Clear resets every filter |
| Accessibility | Sliders adjustable with VoiceOver (step up/down), labels spoken ("Distance, within 50 km"); Larger Text wraps, never clips |
| Data | City list: in the preview, the sample cities; for members, from stored locations (server design). Distance needs LOCK 11 + the server design |
