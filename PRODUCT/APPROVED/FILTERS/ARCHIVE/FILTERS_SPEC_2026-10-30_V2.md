---
id: DOC-ZYRA-0351
type: SPEC
status: ARCHIVED (2026-10-30)
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 10 - Filters page (V2 - city search typing states and keyboard)
links: [DOC-ZYRA-0284, AD-AIOS-115]
owner: ZYRA chat
---

# FILTERS — SPEC — V2 (LOCKED 30 OCT 2026)

V1 is in `../ARCHIVE/FILTERS_SPEC_2026-10-30_V1.md`. **What changed:** queue line 25 stopped because the city search had no
picture for typing, matches, no match or the keyboard. V2 adds them. Nothing else changes.

Masters (430 × 932 @3x) in `../MASTERS/`: `filters__default`, `filters__age_range`, `filters__city_and_distance` (V1, unchanged) and
**new** `filters__city_search_matches`, `filters__city_search_no_match`. Location origin (the "From … · Change" line) is LOCK 11.

| Item | Rule |
|---|---|
| Layout | Title "Filters"; scrolling list of glass **cards** (radius 20, padding 14/16, 10 apart); a fixed bottom bar: **Clear** (outlined, shows "(n)" = number of filters switched on) and gold **Show profiles** (52 high) |
| Age card | Icon + "Age"; segmented "Any age (18+)" / "Set range"; with Set range a **two-handle slider 18–70** (gold), live label "24 – 32" |
| Background card | Rows with icon: Country of residence · Nationality · Ethnicity, each "Any ›", opening today's lists |
| Distance card | Icon + "Distance"; origin line (LOCK 11); **one-handle slider** with steps 5, 10, 15, 25, 50, 75, 100, 150, 200, 300, 500 km, then **Any distance** at the far right; live label "Within 50 km" / "Any distance"; ends labelled "5 km" and "Any" |
| City card | Icon + "City"; **"Search any city"** field; several cities allowed, each a gold chip with ×; none chosen = "All places — add cities to narrow it down." |
| City — field empty | Small caps label **SUGGESTED** and up to 6 popular cities as outlined chips with a gold "+" (London, Birmingham, Manchester, Bradford, Leicester, Glasgow), minus any already chosen |
| **City — typing, matches** (new, master `filters__city_search_matches`) | As soon as one letter is typed the label changes to **MATCHES** and the chips show up to 6 cities whose name **contains** the text (case-insensitive), in list order, minus any already chosen. Tapping one adds it as a gold chip, clears the field and goes back to SUGGESTED. The typed text stays in the field until then |
| **City — typing, no match** (new, master `filters__city_search_no_match`) | Label MATCHES, then muted text **No city called "<text>".** No chips, no button |
| **Keyboard** (new, both new masters) | The standard phone keyboard opens when the field is tapped (return key "Done"). While it is open the bottom bar (Clear / Show profiles) is hidden and the page scrolls so the City card sits just above the keyboard; "Best matches are shown first" may show between them. Done or tapping outside closes the keyboard and the bottom bar comes back. The masters draw an iPhone dark keyboard only to show where it sits — use the system keyboard, do not draw one |
| Line under the cards | "✦ Best matches are shown first" (12.5 pt, muted) |
| **No member counts — ever** | Never show how many profiles or members match (Founder: "it exposes zyras user count"). The only number allowed is the count of filters switched on |
| No Compatibility filter | Scores are only seen with an Unlock (DR-ZYRA-288) |
| Show profiles | Applies and returns to Profiles; Clear resets every filter |
| Accessibility | Sliders adjustable with VoiceOver (step up/down), labels spoken ("Distance, within 50 km"); the city results are announced ("3 matches" / "No city called …"); Larger Text wraps, never clips |
| Data | City list: in the preview, a fixed sample list of about 50 UK cities (Bradford, Leicester, Glasgow etc. are labels only and add no profiles); for members, from stored locations (server design). Distance needs LOCK 11 + the server design |
