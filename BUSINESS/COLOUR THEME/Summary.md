---
id: DOC-ZYRA-0102
type: BRAND
status: CURRENT
feature: BUSINESS: COLOUR THEME
purpose: Colour Theme — the one current record of ZYRA's colours, backgrounds, surfaces and fonts, taken from the app code
links: [DOC-ZYRA-0282, DOC-ZYRA-0100, DOC-ZYRA-0101, OA-ZYRA-313, OA-ZYRA-314]
owner: Founder (decisions) · Fable (document)
---

# ZYRA — COLOUR THEME — V2 (CURRENT)

Rewritten 25 Oct 2026 by Fable from `SOURCE/lib/theme/zyra_colors.dart`, `zyra_text.dart` and the theme in `SOURCE/lib/main.dart`
(OA-ZYRA-313). The code is the authority; if this page and the code ever disagree, the code wins and this page is fixed.
V1, with all its dated banners, is kept unchanged in `ARCHIVE/COLOUR_THEME_SUMMARY_2026-10-25_V1.md`.
Full detail (spacing, components, haptics, motion): blueprint part 5, DOC-ZYRA-0282.

## The feel

Royal, luxury, warm, modern, soft, trustworthy. A **dark, glass-on-purple** app: one deep purple background, translucent white
"glass" on top, a thin **gold edge** on whatever is selected or important, thin white Poppins text, and the ZYRA mark in pale gold.

## 1. Background

| | |
|---|---|
| **Default for everyone** | **Midnight Plum: #30203F → #160E20**, top-left to bottom-right |
| Applies to | Every page, both roles (Seeker and Guardian), sign-up, onboarding and splash |
| Gender | **Does not change colour.** One background for all since 20 Aug 2026 |
| Member choice | Profile → Personalisation → Background: the 10 dark options below. The choice is kept per account on the device |
| One-off reset | On 27 Sep 2026 every installation was moved to Midnight Plum once (revision `dark-hulu-app-2026-09-27-v1`). Later choices are kept |

| Background option | Gradient | Direction |
|---|---|---|
| **Midnight Plum (default)** | #30203F → #160E20 | top-left → bottom-right |
| ZYRA Purple (the original brand gradient) | #8A6A9E → #3D2A4A | top → bottom |
| Royal Blue | #607BA7 → #26364F | top → bottom |
| Rose Pink | #A6788F → #503343 | top → bottom |
| Deep Emerald | #47756B → #18352F | top → bottom |
| Sapphire Night | #48698B → #192A3E | top → bottom |
| Desert Rose | #A26F70 → #513436 | top → bottom |
| Warm Cocoa | #7B665F → #352A28 | top → bottom |
| Charcoal Gold | #55505D → #211E27 | top → bottom |
| Midnight blue (added 22 Oct) | #183F83 → #07132B | top-right → bottom-left |

Two light backgrounds (Paper White, Crystal UI) and seven light accent colours exist only for developer comparison and old test
pictures; members cannot choose them.

**Gold accents** (member option, starts Off): adds a slow gold dust and a diagonal gold edge behind the background. Kept per
account on the device, cleared on sign-out, still when the phone asks for reduced motion.

## 2. Named colours

| Name in code | Value | Used for |
|---|---|---|
| `royalPurple` | **#30203F** | Top of the default background; seed colour of the app theme |
| `luxuryDarkPurple` | **#160E20** | Bottom of the default background; text on light/lavender fills; launch screen before the app starts |
| `darkPlumSurface` | **#241A2F** | Every bottom sheet, centred dialog and snackbar (opaque). Anchored menus use it at 92% |
| `splashWordmark` | **#E5CE8E** | The ZYRA wordmark and the app icon lettering |
| `journeyGold` | **#E8C98A** | Gold accents: selected edges (at 70%), Journey, premium |
| `primaryAction` | **#CEA2D1** Pastel Grey Lavender | The theme's "primary" colour; text on it is #160E20 |
| `destructive` | **#E08080** coral (edge at 40%) | End Journey, delete, report |
| `positiveGreen` / `negativeRed` | **#84D0A8** / **#E18A91** | Up / down signals |
| `journeyDotGreen` | **#78C69D** | Journey progress dots |
| `successTick` | **#50B478** (progress done: 60%) | Completed steps |
| Privacy dots | Public **#3D9A6A**, Unlock **#C49A44**, Private **#8A6A9E** | Privacy label dots |
| Privacy words | Public #C8DC8C 50%, Unlock #DCB964 45%, Private #B496D2 45% | Privacy label words — **too faint**, see §6 |

The old names "Royal Purple #8A6A9E" and "Luxury Dark Purple #3D2A4A" now survive only as the ZYRA Purple background option.

## 3. Text colours

| Role | Value |
|---|---|
| Main (headings, icons, buttons) | **#FFFFFF** |
| Body | white **90%** |
| Secondary | white **70%** |
| Muted | white **54%** |

## 4. Surfaces (what members see)

**Classic Glass** is the locked surface style (29 Aug 2026). Since 22 Oct the selected/important look is the **quiet gold halo**:
the normal glass fill with a 70% gold edge, not a paler fill.

| Surface | Fill | Edge |
|---|---|---|
| Card, pill, panel | white 7% | white 14% |
| Selected / important card, main button | white 7% | **#E8C98A 70%** |
| Floating navigation bar | white 10% (20% touched), blur σ22 | white 18% (30% touched) |
| Progress bar | white 28% | — |
| Divider | white 14% | — |
| Bottom sheet, centred dialog, snackbar | **#241A2F opaque** | dialogs: gold 28% |

**Main buttons** are glass with the gold edge (not a lavender fill): at least 48 tall, fully round, white Poppins 400 15.
Danger buttons are coral #E08080 with #160E20 text.

## 5. Fonts

| Use | Font | Weight | Size |
|---|---|---|---|
| ZYRA wordmark (welcome, splash, icon) | **Syne** | 600 | 34 default, letter spacing 4 |
| Page titles | **Poppins** | 200 | 26 |
| Headings | Poppins | 200 | 20 |
| Buttons | Poppins | 400 | 15, letter spacing 0.5 |
| Options | Poppins | 300 | 14 |
| Body | Poppins | 300 | 13 |
| Subtext | Poppins | 300 | 12.5 |
| Privacy note | Poppins | 300 | 11 |
| Chapter label | Poppins | 300 | 10, letter spacing 0.8 |
| Tagline "Connecting Through Trust" | Poppins | 300 | grows with the screen, 12.5–17 |

Both fonts ship inside the app. Poppins has been the reading font since 24 Aug 2026 (Jost before); Syne has been the wordmark since
7 Aug 2026 (Playfair Display before). The wordmark is also baked into `assets/splash/splash_logo.png` and the app icon — change
those too if the wordmark font ever changes.

## 6. Open items

| Item | Where |
|---|---|
| Privacy words fail contrast (3.6 / 2.7 / 2.3 against the 4.5 needed) | OA-ZYRA-314 |
| No single corner scale (14, 18, 12, 20, 16, 24 all common) — design decision after the freeze | OA-ZYRA-313 |
| Founder on-device look at the 27 Sep, 30 Sep, 3 Oct, 4 Oct and 22 Oct changes was still pending when they were recorded | V1 banners |

## 7. Decision history (short)

| Date | Decision | Ref |
|---|---|---|
| 25 Jul 2026 | Palette ratified: brand purple #8A6A9E → #3D2A4A, male blue, female pink | DR-ZYRA-094 |
| 11 Aug 2026 | One component system: lavender primary, plum text, glass dialogs, coral danger | Frost UI pass |
| 20 Aug 2026 | Background no longer changes by gender | Founder direction |
| 24 Aug 2026 | Midnight Plum becomes the default; Poppins the reading font | Founder direction |
| 29 Aug 2026 | Classic Glass surfaces locked | Founder direction |
| 27 Sep 2026 | Midnight Plum darkened to #30203F → #160E20 app-wide; sheets one opaque colour | OA-ZYRA-257 |
| 30 Sep 2026 | Icon lettering uses wordmark gold #E5CE8E | OA-ZYRA-257 |
| 3 Oct 2026 | Centred dialogs opaque #241A2F with a gold edge | OA-ZYRA-304/257 |
| 4 Oct 2026 | Gold accents becomes a member option, default Off | DR-ZYRA-258 |
| 22 Oct 2026 | Quiet gold halo for selected surfaces; Midnight blue background option | OA151, OA-ZYRA-304/305 |
