---
id: DOC-ZYRA-0335
type: SPEC
status: ARCHIVED (2026-10-30)
feature: PRODUCT BLUEPRINT
purpose: Spec for LOCK 14 - ZYRA app colours: Ivory, gold and warm neutrals, no purple; matching app icon and splash; no member colour choice
links: [DR-ZYRA-276, AD-AIOS-115]
owner: ZYRA chat
---

# APP COLOURS — SPEC — V1 (LOCKED 30 OCT 2026)

**Ivory · no purple** replaces Midnight Plum everywhere in the planned app — Seeker and Guardian, One and Basic, every tab and
page, sheets, the app icon, the iPhone launch screen and the app splash. **Layouts do not change; only colours.** Every
earlier LOCK master (LOCK 2–13) shows the old Plum colours: build those layouts as locked and apply this colour table to them.

Masters (430 × 932 @3x, prototype V79) in `../MASTERS/`: c01 profiles · c02 journey_tab · c03 my_zyra · c04 guardian_tab ·
c05 profile_tab · c06 filters_where · c07 requests_opened · c08 add_guardian_found · c09 guardian_my_zyra · c10 guardian_network;
c11 app_icon_1024 (colour reference) · c12 splash · c13 iphone_launch.

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
| Gold buttons | fill `#E8C98A`, text `#241A2F` | fill `#A9792E`, text `#2B2420` |
| Glass cards, tiles, pills, tab bar | `rgba(255,255,255,.07)` | `rgba(255,255,255,.78)` |
| Borders | `rgba(255,255,255,.14)` | `rgba(62,46,30,.13)` |
| Dividers | `rgba(255,255,255,.12)` | `rgba(62,46,30,.10)` |
| Other white overlays (segment fills, quiet backgrounds) | `rgba(255,255,255,a)` | `rgba(62,46,30,a)` (same alpha) |
| Solid card / details surfaces | `#2A1F36`, `#3A2A4A`, `#2C1F3B` | `#FFFFFF` |
| Lower card / sheet surfaces | `#2B2035`, `#1B1226`, `#1A1126` | `#FBF8F2`, `#F7F2EA`, `#F2ECE2` |
| Danger (End Journey, Remove, Decline accents) | `#E07B76` | `#B84A42` |
| Sample avatar tints | plum/lilac tones | warm sand tones (`#9C8A72`, `#6B5B49`, `#857560`) |
| Text on photos (Profiles photo pages, Journey card) | white on dark fade | **unchanged** — white on the dark fade |
| System keyboard, iPhone prompts | — | system default |

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
| Background picker | Profile → Appearance & haptics: the **Background** choice (Midnight Plum, Royal Blue, Rose Pink, Deep Emerald, Sapphire Night, Desert Rose, Warm Cocoa, Charcoal Gold, Midnight blue) is **removed**. Everyone sees Ivory. Saved palette preferences are ignored (no member data deleted) |
| Rest of Appearance & haptics | Haptics unchanged. Gold accents switch unchanged (the gold dust uses `#A9792E` on ivory) |
| Developer palettes | Unused palette values and their code go (moved to `~/_to_delete/`), together with the developer toggle removal (queue line 35) |

## Accessibility

Body text `#2B2420` and secondary `#6E6257` meet WCAG AA on the ivory background; gold `#A9792E` is used for large text,
icons, outlines and the gold-button fill (with `#2B2420` text), not for small body text. Check every screen with Larger Text and
Increase Contrast.
