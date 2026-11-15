# FIX BRIEF — ONE CARD COLOUR — 13 NOV 2026

Founder, 13 Nov 11:15 (iPhone screenshots of My ZYRA, Profile, Guardian): "why us gurdian colour lighter, we want app consistency, any section on app whuch has that lighter colour like gurdian needs ti change" → clickable "Same colour, no gold edge (Recommended)".

## Rule (app-wide)
Every card, tile, panel and grouped list in the app uses the **same card surface as the My ZYRA tiles and the Profile groups**: the same ivory fill, the same soft shadow, and no coloured outline. No card is lighter or whiter than these. The gold edge on the Guardian card goes.

## Cause found
Cards use five different fills: the shared surface (`ZyraColors.surfaceFill`), `ZyraColors.ivoryTop` / `0xFFFBF7F0`, `0xFFF7F2EA`, `0xFFFAF5EC`, and near-whites (`0xFFFFFFFE`, `0xFFFFFDF9`, `0xFFF5F3EF`). The Guardian card (`lib/dev/zyra_one_journey_guardian_cards.dart`, about lines 376, 797-800 and 852) uses a lighter fill and a gold `Border.all`.

## Change
1. Use the exact fill, border and shadow the My ZYRA tiles and Profile groups use today. Name it once as the single card token in `ZyraColors` (for example `cardSurface`), plus one card shadow token.
2. Replace every other card fill in `lib/dev`, `lib/widgets` and `lib/screens` with that token: Guardian cards, the Add card, Circle topics, code page, Filters, Journey, Browse details, confirm sheets, the Developer panel and Feedback. List each file changed in the as-built record.
3. Remove the gold outline from the Guardian card. Gold stays only where a lock already uses it as a signal (for example the Seeker One ring and the active tab marker), not as a card edge.
4. The page background (ivory gradient) is unchanged. Sheets keep their own surface only if a lock names it; otherwise they use the card token too.
5. Seeker and Guardian sides, Founder preview and member app alike.

## Checks
- Guardian, My ZYRA and Profile cards look identical in fill and shadow when placed side by side on the iPhone.
- No `Color(0xFF...)` card fill is left outside the theme files (search and record the count before and after).
- Tests and goldens updated; no new failures.
