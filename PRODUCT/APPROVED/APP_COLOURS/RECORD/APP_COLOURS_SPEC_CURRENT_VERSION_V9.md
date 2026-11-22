---
id: DOC-ZYRA-0338
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 14 - ZYRA app colours: Ivory, gold and warm neutrals, no purple; matching app icon and splash; no member colour choice
links: [DR-ZYRA-276, AD-AIOS-115]
owner: ZYRA chat
---

# APP COLOURS — SPEC — V9 (LOCKED 10 NOV 2026, APPEARANCE PAGE REMOVED 11 NOV, NO DARKER FILLS 11 NOV, CLEARER TEXT 22 NOV)

**V9 (22 Nov 2026, Founder in the design-100% pass, clickable "B · Clearer text (Recommended)", OA-ZYRA-371 / audit F-15):** see "Clearer text (V9)" below. V8 is in `../ARCHIVE/APP_COLOURS_SPEC_2026-11-22_V8.md`.
**V9 correction (22 Nov, after Codex preflight, QUESTIONS 177; no design change):** small green text `#326B4C` (`#3D7D5A` measured 3.96 / 4.13 : 1 on `#EEE6D8` / `#F1EBDF`); 4.5 : 1 for all text under 24 pt at any weight (the bold 18.66 pt exception is removed); reference prototype V302. Applies the Founder's Decision 4 ("every small text 4.5 : 1").

**V8 (11 Nov 21:48, Founder iPhone screenshot of Settings with grey-brown cards):** "Remove this darker colour everywhere it is in app" → prototype V185 → clickable **"LOCK it app-wide (Recommended)"**. **No surface may be darker than the background.** The row "Other white overlays" below is replaced: cards, tiles, list cards (Settings, Profile, every page), search boxes, inputs, code boxes, the selected segment / tab pill, icon circles, quiet buttons ("Keep …", "Cancel") and Basic monogram fills use the **ivory floating fill** (`#FBF7F0` or `rgba(250,245,236,.85)`) with the soft floating shadow where they must stand out; a selected segment = ivory fill + gold border + soft shadow. Darker tints (`rgba(62,46,30,a)`) are allowed **only** for: thin dividers, the dim layer behind sheets, grab handles, slider / progress tracks and inactive page dots. V7 is in `../ARCHIVE/APP_COLOURS_SPEC_2026-11-11_V7.md`.

**V7 (11 Nov):** the Appearance & haptics page no longer exists (LOCK 21 V2); the two rows below that described it are updated. Nothing else changes. V6 is in `../ARCHIVE/APP_COLOURS_SPEC_2026-11-11_V6.md`.

V1 is in `../ARCHIVE/APP_COLOURS_SPEC_2026-10-30_V1.md` (masters in `../ARCHIVE/MASTERS_V1/`). **What changed (V2):** the **floating
look** — surfaces are ivory like the background and separated by a soft warm shadow instead of white boxes (Founder 30 Oct:
"lets see how this looks with it loking similiar to background so it looks floating", "do it for everything thats white and
seperated in colour" → "LOCK it").

**Ivory · no purple** replaces Midnight Plum everywhere in the planned app — Seeker and Guardian, One and Basic, every tab and
page, sheets, the app icon, the iPhone launch screen and the app splash. **Layouts do not change; only colours.** Every
earlier LOCK master (LOCK 2–13) shows the old Plum colours: build those layouts as locked and apply this colour table to them.

Masters (430 × 932 @3x, prototype **V82**; c11–c13 unchanged from V79) in `../MASTERS/`: c01 profiles · c02 journey_tab · c03 my_zyra · c04 guardian_tab ·
c05 profile_tab · c06 filters_where · c07 requests_opened · c08 add_guardian_found · c09 guardian_my_zyra · c10 guardian_network;
c11 app_icon_1024 (colour reference) · c12 splash · c13 iphone_launch; **c14 traffic_light_dots (V3, prototype V86)**.
**V4 (31 Oct, prototype V94):** gold-button fill changed for readability; c08 and c14 re-rendered (V3 pictures in `../ARCHIVE/MASTERS_V3/`).
**V6 (10 Nov, prototype V144):** small danger text deepened to `#AC453E` for readability (was `#B84A42`, 4.1 : 1; Founder clickable "Deeper red #AC453E (Recommended)", QUESTIONS row 21). No masters re-rendered (charter rule 13): the prototype is the reference; masters keep their V5 pictures. V5 is in `../ARCHIVE/APP_COLOURS_SPEC_2026-11-10_V5.md`.
**V5 (31 Oct, prototype V97):** small gold text deepened for readability; c01, c02, c05–c10 re-rendered (V4 pictures in `../ARCHIVE/MASTERS_V4/`). c03 still shows the old My ZYRA layout (replaced by LOCK 15) — use it for surfaces only; its small gold text follows this table.

## Colour table (old → new)

| Role | Old (Plum) | New (Ivory) |
|---|---|---|
| App background | gradient `#30203F → #160E20` | gradient `#FBF7F0 → #EEE6D8` (170°, top-left to bottom-right) |
| Primary text | `#FFFFFF` / `#F3EDF7` | `#2B2420` (espresso) |
| Secondary text | `#D8CDE3`, `#CDBFD9` | `#6E6257` |
| Strong secondary text | `#E2D8EA`, `#DDD3E6` | `#4F443A` |
| Icons / quiet text | `#CFC3DC` | `#7A6E62` |
| Muted / hints | `#B7A9C6`, `#A99CB7`, `#9D92A9` | `#857868` / `#867A6E` |
| Gold accent (eyebrows, links, active underline, outlines, sliders, checks) | `#E8C98A`, `rgba(232,201,138,a)` | `#A9792E`, `rgba(169,121,46,a)` |
| **Small gold text (V5)** — any gold-coloured text below large size (smaller than 24 pt regular / 18.66 pt bold): eyebrows ("NEEDS YOU", "NEW ACTIVITY"), links ("View request →", "Change ›", "Clear"), status words ("Journey request", "1 new"), gold pill outlines' labels such as "Request sent" | `#E8C98A` | **`#845F24`** (≥ 4.65 : 1 on every Ivory background; `#A9792E` measured 3.1–3.6 : 1, failed). One token, e.g. `ZyraColors.goldText` |
| **Gold fills with text (V4)** — gold buttons, the filled "Request a Journey" pill, NEW badges and other gold pills with text | fill `#E8C98A`, text `#241A2F` | fill **`#C08A3A`**, text `#2B2420` (contrast 5.0 : 1; was `#A9792E` = 3.97 : 1, failed). Button shadow tint follows the fill. The accent gold `#A9792E` stays for icons, lines, outlines, sliders, dots and the active underline |
| Glass cards, tiles, pills, tab bar | `rgba(255,255,255,.07)` | `rgba(250,245,236,.85)` — ivory like the background (**floating**, see below); tab bar solid `#F1EBDF` |
| Borders | `rgba(255,255,255,.14)` | `rgba(62,46,30,.06)` (almost invisible) — gold borders stay gold |
| Dividers | `rgba(255,255,255,.12)` | `rgba(62,46,30,.10)` |
| Other white overlays (segment fills, quiet backgrounds) — **replaced by V8** | `rgba(255,255,255,a)` | **V8: ivory `#FBF7F0` + soft shadow** (darker tint only for dividers, dim layer, handles, tracks, inactive dots) |
| Solid card / details surfaces | `#2A1F36`, `#3A2A4A`, `#2C1F3B` | `#F4EEE4` |
| Lower card / sheet surfaces | `#2B2035`, `#1B1226`, `#1A1126` | `#F1EBDF`, `#F3EDE2`, `#F1EBDF` |
| Danger (End Journey, Remove, Decline accents) | `#E07B76` | `#B84A42` for icons, outlines and large text; **small danger text `#AC453E` (V6)** |
| **Traffic-light dots (V3)** — Prefer / No preference / Not for me (Green / Yellow / Red editor, partner-preference questions, Meaning card) | green `#84D0A8` (`positiveGreen`), gold `#E8C98A`, red `#E18A91` (`negativeRed`) | green `#4E9A72`, gold `#A9792E`, red `#B84A42`; selected button fill = the dot colour at 14% with a border at 82%; selected label `#2B2420` (was white) — c14 |
| Sample avatar tints | plum/lilac tones | warm sand tones (`#9C8A72`, `#6B5B49`, `#857560`) |
| Text on photos (Profiles photo pages, Journey card) | white on dark fade | **unchanged** — white on the dark fade |
| System keyboard, iPhone prompts | — | system default |

## Floating look (V2)

| Item | Rule |
|---|---|
| What floats | Every separate surface: cards, tiles, list rows in cards, pills, segmented controls, tabs, chips, buttons (outline and gold), search boxes, the request pill, the Profiles card, Filters cards, Journey cards, code boxes, sheets' option cards, the tab bar and the Profiles ••• bar |
| Shadow | `0 10px 24px rgba(62,46,30,.12), 0 2px 6px rgba(62,46,30,.07)`; tab bar `0 12px 28px rgba(62,46,30,.16), 0 3px 8px rgba(62,46,30,.08)`; gold buttons a faint gold glow `0 8px 18px rgba(169,121,46,.25)`. Nested boxes inside a floating box get no second shadow |
| No cut-off shadows | Scrolling page areas must leave room for the shadow on both sides (pad the scroll area, not the content) so no shadow ends in a hard line — check every page |
| Kept | Gold borders and outlines (Profiles card, opened request, selected tab underline), the thin dividers (`rgba(62,46,30,.10)`) and the camera frame (`rgba(62,46,30,.55)`) |

**No purple anywhere** — no plum, lilac or lavender tints in text, borders, surfaces or avatars.

## Icon, launch and splash

| Asset | New |
|---|---|
| App icon (`AppIcon.appiconset`, and Android adaptive foreground) | Same design as today's icon (ZYRA wordmark + gold line with its glow) on the ivory gradient; wordmark and line `#A9792E`. Re-generate from today's icon source with only the colours changed (c11 is a colour reference — keep today's wordmark lettering) |
| iPhone launch screen (`LaunchBackground` + `LaunchImage`, `splash_logo.png`) | Background `#FBF7F0`; ZYRA logo in `#A9792E` (today's white logo would vanish) — c13 |
| App splash screen | Ivory gradient; ZYRA `#A9792E`; "Connecting Through Trust" `#6E6257`; gold line `#A9792E` — c12 |

## Member choice removed (Founder 30 Oct: "Ivory only")

| Item | Rule |
|---|---|
| Background picker | (V7: the whole Appearance & haptics page is removed, LOCK 21 V2.) The **Background** choice (Midnight Plum, Royal Blue, Rose Pink, Deep Emerald, Sapphire Night, Desert Rose, Warm Cocoa, Charcoal Gold, Midnight blue) is **removed**. Everyone sees Ivory. Saved palette preferences are ignored (no member data deleted) |
| Rest of Appearance & haptics (V7) | Page removed (LOCK 21 V2). Gold accents off for everyone; haptics move to Settings → Haptics |
| Developer palettes | Unused palette values and their code go (moved to `~/_to_delete/`), together with the developer toggle removal (queue line 35) |

## Clearer text (V9) — app-wide rule
| Rule | Detail |
|---|---|
| Contrast | **Every piece of text under 24 pt reaches 4.5 : 1 against what is actually behind it, whatever its weight**; text 24 pt and larger 3 : 1. Measured on the real background, including cards, pills and the darkest end of the page gradient (`#EEE6D8`). (Corrected 22 Nov, QUESTIONS 177: no bold 18.66 pt exception — matches the brief and the Founder's "every small text".) |
| Replacements for small text | Journey gold `#A9792E` and bright gold `#C08A3A` used as small text → `#845F24` · green `#4E9A72` (and `#3D7D5A`) small text → **`#326B4C`** (5.07 : 1 on `#EEE6D8`, 5.29 : 1 on `#F1EBDF`; `#3D7D5A` failed at 3.96 / 4.13, QUESTIONS 177) · muted / quiet greys below 4.5 → `#6E6257` · faded labels (45 % strength) → full `#6E6257` · light text on a gold fill → `#2B2420` |
| Weight | No text below regular (400) under 16 pt; thin (300) stays only for 16 pt and larger |
| Unchanged | Large titles, icons, outlines, shapes, gold fills, dark/gold backgrounds keep their colours |
| Proof | An automatic contrast check over every planned-app screen in the preview (Seeker and Guardian), failing on any small text under 4.5 : 1 |
Reference: prototype V302 (`BLACK UMBRELLA GROUP/BUSINESS/ZYRA/PROTOTYPE/ZYRA_PROTOTYPE_CURRENT_VERSION_V302.html`, the Founder's private copy; same as the live prototype artifact V302), which applies this on every page. Check values: gold `#845F24` 4.65, secondary `#6E6257` 4.78, danger `#AC453E` 4.61, green `#326B4C` 5.07 — all on `#EEE6D8`.

## Accessibility

Body text `#2B2420` and secondary `#6E6257` meet WCAG AA on the ivory background; gold `#A9792E` is used for large text,
icons, outlines and large text; small gold text uses `#845F24` (V5). Small danger text uses `#AC453E` (4.6 : 1, V6); `#B84A42` stays for icons, outlines, traffic-light dots and large text. Gold fills that carry text use `#C08A3A` with `#2B2420` text (5.0 : 1, V4). Check every screen with Larger Text and
Increase Contrast.
