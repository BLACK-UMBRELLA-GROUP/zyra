---
id: DOC-ZYRA-0461
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 27 - who sees every compatibility topic (Seeker One, Guardian One, or one Unlock) and the Seeker Basic locked topic pages
links: [AD-AIOS-115, DR-ZYRA-250, DR-ZYRA-288]
owner: ZYRA chat
---

# COMPATIBILITY TOPICS — SPEC — V3 (LOCKED 11 NOV 2026, GUARDIAN ENTRY 12 NOV, BANDS 12 NOV)

**V3 (12 Nov, Founder clickable):** the earlier "6 topics with exact %" conflicted with the Founder's **DR-ZYRA-250 (28 Sep, D3 twelve internal categories + D4 reduced-disclosure bands, no exact category %)**. Founder: **"Keep 28 Sep: bands, no exact % (Recommended)"**, then **"Strong · Good · Some differences"**, **"75%+ / 50–74% / under 50%"**, **"'Not enough answers' in grey"** (all Recommended). V3 replaces every "6 topics / topic %" rule below; where an older row says "topic", read "area". V2 is in `../ARCHIVE/COMPATIBILITY_TOPICS_SPEC_2026-11-12_V2.md`.

## Bands (V3) — the display contract
| Item | Rule |
|---|---|
| Areas | The **12 areas** of DR-ZYRA-250 D3, in this fixed order: Deen & Islamic Practice · Marriage Intentions & Structure · Children & Parenting · Family & In-Laws · Finances & Provision · Education, Career & Work · Home Life & Household Roles · Communication & Conflict · Personality & Connection · Lifestyle, Health & Well-being · Digital Life, Privacy & Boundaries · Culture & Language |
| Shown per area | One word, never a number: **Strong** (area match **75 % or more**) · **Good** (**50–74 %**) · **Some differences** (**under 50 %**) · **Not enough answers** (grey, when fewer than **3** applicable questions in that area have answers and preferences on both sides). The area % is worked out on the server and **never sent to the app** — only the band code |
| Area match | Same rule as the Overall score (D1: Green 1, Amber 0.5, Red 0; D2 applicability and strict validation), counted only over that area's applicable questions. The exact formula and the question → area map belong to Fable's scorer (OA-ZYRA-193); this spec fixes only the bands and thresholds |
| Saved result | Bands come from the **same one saved result** as the Overall (D5): no refresh; reopening never re-calculates or uses another Unlock |
| Reader | **2 pages** (swipe or ‹ › loop): **1 Overall** (overall % ring, "You and Sara", Guardian information card kept separate from the score, D4) · **2 Every area** (title, "How you and Sara line up, area by area.", 12 rows sharing the height: area name left, band chip right). Chips: Strong = fill `#C08A3A`, text `#2B2420`; Good = ivory, gold border 60 %, text `#845F24`; Some differences = ivory, thin border, body text; Not enough answers = grey italic text, no chip. Pager "1 / 2" |
| Locked (Seeker Basic / Guardian Basic) | Page 2 shows the 12 names with a small gold lock + "Locked" (no band, nothing sent); Seeker Basic: gold **See every area for Sara** (1 Unlock; 0 left → **Get an Unlock for Sara** → store), "Uses 1 Unlock · n left", link **Seeker One shows every area in every Journey ›**. Guardian Basic: **See Guardian One**, no Unlock |
| Wording | Everywhere the app said "topic" for this reader, it says **area** |


**V2 (12 Nov, QUESTIONS row 93):** where a Guardian opens the reader. Founder clickable "A row on the Guardian's Journey page (Recommended)" + "Yes, read-only in Past (Recommended)". V1 is in `../ARCHIVE/COMPATIBILITY_TOPICS_SPEC_2026-11-11_V1.md`.

Founder 11 Nov: Seeker One idea 1 "yes but if basic paid for compatibility unlock and used it on that person then that overrides"; Guardian One G2 yes; prototype V181 answer **"if seeker one is 7 pages then copy that"**; Guardians: **"No, Guardian One only (Recommended)"**. Reference: prototype copy `BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V194.html` (Seeker Basic → Journey → Compatibility; screen list "Compatibility in a Journey · Seeker Basic").

| Item | Rule |
|---|---|
| Who sees every topic | **Seeker One** and **Guardian One**: all 7 pages (Overall + 6 topics), as today |
| Seeker Basic | Overall score only — **unless** they used an Unlock on that person (in Profiles or here): then every topic for that person, everywhere (Journey Bio, archive), as the Unlock rule already says |
| Guardian Basic | Overall score only. A Seeker's Unlock does **not** open topics for the Guardians |
| Reader for Basic | **Same 7-page reader as Seeker One** (same frame, ‹ › / swipe, loop, "n / 7"). Page 1 Overall: unchanged. Pages 2–7: topic name at the top, then centred in the space: the ring drawn empty (gold at 16 %), a gold lock (44) in its centre, **"Every topic comes with Seeker One"** (17 light), "Seeker Basic shows the overall score. Use 1 Unlock to see every topic for Sara." (12.5 muted); at the bottom gold **See every topic for Sara** (uses 1 Unlock; with 0 left it reads **Get an Unlock for Sara** and opens the Unlocks store), the line "Uses 1 Unlock · n left" / "0 Unlocks left", and the link **Seeker One shows every topic in every Journey ›** (upgrade page); then the pager. No scores, colours or percentages of locked topics are shown or sent |
| Guardian Basic reader | Same locked pages with "Every topic comes with Guardian One", gold **See Guardian One** (Guardian One page) and no Unlock button |
| **Guardian entry (V2)** | On the Guardian's Journey page: a **"Compatibility score"** floating row, same style and place as on the Seeker's Journey page; shown only once both Seekers have revealed (Journey step 2). Opens the reader: Guardian One every topic, Guardian Basic page 1 + locked topic pages. On an ended Journey the same row sits on the **Past** summary, read-only, while the archive is readable (3 months). Data only through the result Fable specifies (QUESTIONS 91–92, OA-ZYRA-317) |
| After an Unlock | The reader opens on page 1 with every page open; toast "Every topic is now open for Sara." |
| Server | Topic scores must not be sent to a Basic member without an Unlock for that person (not only hidden by the app) — server work for Fable (OA-ZYRA-317). If the server still sends them, file a QUESTIONS row; the app shows the locked pages anyway |
| Upgrade tables | "Compatibility score · Overall score · Every topic" rows (LOCK 25) become true once this ships (honest-table rule) |

## Change log

| Date | Version | Change |
|---|---|---|
| 2026-11-11 | V1 | First version |
| 2026-11-12 | V3 | Bands per DR-ZYRA-250: 12 areas, Strong / Good / Some differences / Not enough answers, 75 / 50 thresholds, 2-page reader, area % never sent. V2 archived |
| 2026-11-12 | V2 | Guardian entry: row on the Guardian's Journey page + read-only in Past (QUESTIONS 93). V1 archived |
