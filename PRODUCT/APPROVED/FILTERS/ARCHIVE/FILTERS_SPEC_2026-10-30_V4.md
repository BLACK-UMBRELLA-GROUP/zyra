---
id: TBC (Fable assigns)
type: SPEC
status: ARCHIVED (2026-10-30)
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 10 - Filters page (V4 - swipe cards, one filter per card; Where; searchable Nationality and Ethnicity)
links: [DOC-ZYRA-0284, DOC-ZYRA-0329, AD-AIOS-115]
owner: ZYRA chat
---

# FILTERS — SPEC — V4 (LOCKED 30 OCT 2026)

V1–V3 are in `../ARCHIVE/` (V3 masters in `../ARCHIVE/MASTERS_V3/`). **What changed** (Founder 30 Oct, prototype comments):
"remove" (Best matches line) · "lets also try the card style for this page you know swiping left to right" · "how can a person find
a nationality that isnt on here same will apply to ethnicity" · "remove text" ×2 · then **"after everythign is changed lock in
filter page for codex"**. The **Where** rules and real geography from V3 are unchanged; the page becomes swipe cards.

Masters (430 × 932 @3x, prototype V65) in `../MASTERS/`: f01 `age__any`, f02 `age__range`, f03 `where__country`, f04
`where__near_me`, f05 `where__worldwide`, f06 `nationality__popular`, f07 `nationality__typing_keyboard`, f08
`nationality__chosen`, f09 `ethnicity__popular`, f10 `ethnicity__no_match_keyboard`. Location sheets on the Where card: LOCK 11 V2.

## Page

| Item | Rule |
|---|---|
| Header | Title "Filters"; top-right gold text button **Clear** / **Clear (n)** (n = filters switched on: Age range, Near me, any Nationality chosen, any Ethnicity chosen) |
| Dots | Four dots under the title, the current one a long gold pill (same as Profiles) |
| Card | One large card filling the space (radius 22, gold border at 60%, plum gradient like the Profiles details card, padding 22/18). Content starts at the top: gold icon 34, title 26 light, one muted line, then the controls. Order: **Age → Where → Nationality → Ethnicity** |
| Moving between cards | Swipe left / right on the card (not on a slider or button), or the arrows in the bottom pill. No loop: the first card's ‹ and the last card's › are disabled (faded) |
| Under the card | Gold link **"Your preferences also shape who you see ›"** → Compatibility preferences (green / amber / red) |
| Bottom pill | Same component as the Profiles request pill (LOCK 7): one pill, 56 high, gold border — **‹** · **Show profiles** (gold text, applies and returns to Profiles) · **›** |
| Keyboard | When a search box is focused the system keyboard opens (return "Done"); the link and bottom pill hide; the card shrinks to sit above the keyboard. Done / tap outside closes it. The masters draw an iPhone keyboard only to show the layout — use the system keyboard |
| Removed | "Best matches are shown first" line; the old list layout; City search; Country of residence row |

## Cards

| Card | Content |
|---|---|
| **Age** (f01, f02) | "Any age, or set a range."; segmented "Any age (18+)" / "Set range"; with Set range a two-handle slider 18–70, live label "24 – 32", ends "18" / "70" |
| **Where** (f03–f05) | "Near you, in a country, or anywhere."; segmented **Near me · Country · Worldwide** (default Country). Near me: LOCK 11 origin line + one-handle slider 5…500 km (steps 5, 10, 15, 25, 50, 75, 100, 150, 200, 300, 500), default "Within 50 km", ends "5 km" / "500 km". Country: row with flag icon, the member's country of residence (e.g. "United Kingdom"), "Change ›" → the full country list; line "Your country of residence. Tap to choose another." Worldwide: "Members anywhere in the world." |
| **Nationality** (f06–f08) | "Search any nationality and add one or more."; search box "Search any nationality". Box empty → small caps **POPULAR** + up to 8 suggestion chips with a gold "+" (British, Pakistani, Bangladeshi, Indian, Somali, Moroccan, Egyptian, Turkish), minus chosen ones. Typing → **MATCHES**: up to 8 names **containing** the text (case-insensitive) from the **full list in `SOURCE/lib/data/zyra_reference_data.dart` (nationality names, 196)**; none → "No nationality called "<text>"." Tap a chip → added as a gold chip with × above POPULAR, box clears. Several allowed. Nothing chosen = any nationality (no extra text) |
| **Ethnicity** (f09, f10) | Same pattern: "Search any ethnicity and add one or more."; full list = `zyraEthnicities` in the same file **minus "Prefer not to say"** (28); POPULAR: Pakistani, Arab, Bangladeshi, Indian, Black African, Somali, Turkish, Mixed heritage; no match → "No ethnicity called "<text>"." |

## Rules (from V3, unchanged)

| Rule | Detail |
|---|---|
| Real geography | Real places with real map positions (proposed: GeoNames, CC-BY 4.0 — attribution in the app licences page); real km worked out on the server. In the preview, sample cities use their real positions |
| Privacy | Only the town / rough area is stored, never an exact spot; no distances on cards or profiles |
| Filter only on what is on the card | Only Age, Where, Nationality, Ethnicity. Private or Unlock answers (sect, children, marital status, education, language, height…) are never filters — they work through green / amber / red preferences |
| Not filters | Verified, completed bio, membership (ZYRA One / Guardian One), Compatibility score, City |
| No member counts — ever | Never show how many profiles or members match; the only number is Clear (n) |
| Duplicate label | The reference list has "Dominican" for both Dominica and the Dominican Republic: show "Dominican (Dominica)" and "Dominican (Dominican Republic)" in this filter |
| Accessibility | Each card is announced "Age, filter 1 of 4"; swipe has button equivalents (the arrows); sliders adjustable with VoiceOver; chips are buttons ("Add Algerian" / "Remove Algerian"); Larger Text wraps, never clips |
| Server (not in this build) | Real place list, member positions, distance/country/nationality/ethnicity filtering: Fable's DOC-ZYRA-0329 (+ DPIA for location) |
