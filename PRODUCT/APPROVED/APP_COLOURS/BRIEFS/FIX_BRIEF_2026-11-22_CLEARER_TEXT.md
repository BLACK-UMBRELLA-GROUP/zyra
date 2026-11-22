# FIX BRIEF — CLEARER TEXT (LOCK 14 V9) — 22 NOV 2026
Spec: `PRODUCT/APPROVED/APP_COLOURS/RECORD/APP_COLOURS_SPEC_CURRENT_VERSION_V9.md` → "Clearer text (V9)". Founder 22 Nov clickable "B · Clearer text (Recommended)" (OA-ZYRA-371, audit F-15). Prototype V303 applies it on every page. Founder preview (planned app), Seeker and Guardian, every screen.

## Change
1. Put the rule in the shared theme, not screen by screen: named text colours for small text (`#845F24` gold, `#326B4C` green, `#6E6257` secondary) and a minimum weight of 400 under 16 pt.
2. Replace every small-text use of `#A9792E`, `#C08A3A`, `#4E9A72`, faded (45 %) text and any grey under 4.5 : 1 with those named colours; light text on gold fills becomes `#2B2420`, and any gold fill that carries text uses the locked text-bearing fill `#C08A3A` (spec row "Gold fills with text (V4)"), e.g. the walkthrough Next button in `zyra_first_tour_overlay.dart` (QUESTIONS 178).
3. Leave large titles, icons, outlines, shapes and fills unchanged, except a text-carrying gold fill still on `#A9792E`, which becomes `#C08A3A` (item 2).
4. List every file and count changed in the as-built record.

## Checks
- New automatic test: render every planned-app screen (Seeker One, Seeker Basic, Guardian One, Guardian Basic, sign-up, walkthrough) and fail on any text under 24 pt (any weight) below 4.5 : 1 against its real background, or weight below 400 under 16 pt.
- Screens otherwise unchanged (goldens updated only where text colour/weight changed). Analyzer clean; no new failures.
