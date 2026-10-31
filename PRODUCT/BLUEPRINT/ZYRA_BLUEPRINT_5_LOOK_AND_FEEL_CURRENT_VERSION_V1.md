---
id: DOC-ZYRA-0282
type: SPEC
status: CURRENT
feature: PRODUCT BLUEPRINT
purpose: Blueprint part 5 - ZYRA's look and feel from the code: every colour (hex), background, font and weight, text size, spacing, corner shape, shared component, haptic and motion, with differences from the colour theme document
links: [OA-ZYRA-309, DOC-ZYRA-0102, DOC-ZYRA-0278, OA-ZYRA-313, OA-ZYRA-314]
owner: Fable
---

# ZYRA BLUEPRINT — PART 5 — LOOK AND FEEL — V1 (CURRENT)

Status: **CURRENT - approved by the Founder, 26 Oct 2026** (all 14 blueprint pages, review pack DOC-ZYRA-0299). Building anything that breaks this page needs a new decision first. Written 25 Oct 2026 from the code in `SOURCE/lib/theme/` (colours, text, card sizes,
interaction style), the app theme in `SOURCE/lib/main.dart`, the 69 shared widgets in `SOURCE/lib/widgets/` and the font
files in `SOURCE/pubspec.yaml`. **The code wins** where a document disagrees; every difference is listed in §9.

## In one paragraph

ZYRA is a **dark, glass-on-purple** app. Every page sits on one background gradient — **Midnight Plum #30203F → #160E20**,
corner to corner — and everything on it is translucent white "glass" with a thin **gold edge** where something is selected or
important. Text is **Poppins**, mostly thin (200 for headings, 300 for body), in white at four strengths. The word **ZYRA** itself is
**Syne SemiBold in pale gold #E5CE8E**. Corners are soft (cards 14, sheets and dialogs 24, buttons fully round). Motion is short and
eases out (most moves 180–420 ms, `easeOutCubic`), and every tap selection gives a **subtle** haptic that members can change.

## 1. At a glance

### Colours you will see on every screen

| Role | Name in code | Value | Where |
|---|---|---|---|
| Background (default) | `midnightPlum` gradient | **#30203F → #160E20**, top-left → bottom-right | Every page, both roles, sign-up, splash |
| Sheet / dialog / toast surface | `darkPlumSurface` (`modalSheetSurface`, `toastSurface`) | **#241A2F** opaque | All bottom sheets, centred dialogs, snackbars |
| Main text | `foreground` | **#FFFFFF** | Headings, icons, button text |
| Body text | `foregroundBody` | white **90%** (#E6FFFFFF) | Paragraphs |
| Secondary text | `foregroundSecondary` | white **70%** (#B3FFFFFF) | Subtext, labels |
| Muted text | `foregroundMuted` | white **54%** (#8AFFFFFF) | Privacy notes, hints |
| Glass fill | `surfaceFill` | white **7%** (#12FFFFFF) | Cards, pills, panels |
| Glass edge | `surfaceBorder` | white **14%** (#24FFFFFF) | Card outlines |
| Selected / important edge | `surfaceEmphasisBorder` | **#E8C98A at 70%** | Selected cards, main buttons, dialogs ("quiet gold halo") |
| Gold | `journeyGold` | **#E8C98A** | Journey, premium, highlights |
| Wordmark gold | `splashWordmark` | **#E5CE8E** | The ZYRA mark, app icon lettering |
| Lavender action | `primaryAction` | **#CEA2D1**, text on it **#160E20** | Theme "primary" colour, destructive-dialog buttons use the same dark text |
| Danger | `destructive` | **#E08080** (edge #E08080 at 40%) | End Journey, delete, report |
| Good / bad | `positiveGreen` / `negativeRed` | **#84D0A8** / **#E18A91** | Up/down signals |
| Tick | `successTick` | **#50B478** (progress done: same at 60%) | Completed steps |

### Fonts

| Use | Font | Weight | Size | Letter spacing |
|---|---|---|---|---|
| ZYRA wordmark | **Syne** (bundled, SemiBold file only) | 600 | 34 default | 4 |
| Page titles (main tabs) | **Poppins** | 200 ExtraLight | 26 | — |
| Headings | Poppins | 200 | 20 | — |
| Buttons | Poppins | 400 Regular | 15 | 0.5 |
| Answer options | Poppins | 300 Light | 14 | — |
| Body | Poppins | 300 | 13 | — |
| Snackbar text | Poppins | 300 | 13.5 | — |
| Subtext | Poppins | 300 | 12.5 | — |
| Privacy note | Poppins | 300 | 11 | — |
| Chapter label | Poppins | 300 | 10 | 0.8 |
| Tagline "Connecting Through Trust" | Poppins | 300 | scales with screen: 3.33% of the short side, **12.5–17** | — |

Poppins ships with the app in six weights (200, 300, 400, 500, 600, 700). Syne ships SemiBold only.

## 2. Backgrounds members can choose

Profile → Personalisation → Background offers the **10 dark** choices below (the two light ones are refused for members and kept
only for old test pictures). The default is Midnight Plum. On 27 Sep 2026 every installation was moved to Midnight Plum once
(revision `dark-hulu-app-2026-09-27-v1`); after that a member's own choice is kept.

| Choice | Gradient | Direction |
|---|---|---|
| **Midnight Plum · Current (default)** | #30203F → #160E20 | top-left → bottom-right |
| ZYRA Purple | #8A6A9E → #3D2A4A | top → bottom |
| Royal Blue | #607BA7 → #26364F | top → bottom |
| Rose Pink | #A6788F → #503343 | top → bottom |
| Deep Emerald | #47756B → #18352F | top → bottom |
| Sapphire Night | #48698B → #192A3E | top → bottom |
| Desert Rose | #A26F70 → #513436 | top → bottom |
| Warm Cocoa | #7B665F → #352A28 | top → bottom |
| Charcoal Gold | #55505D → #211E27 | top → bottom |
| Midnight blue | #183F83 → #07132B | top-right → bottom-left |
| *Paper White (not for members)* | #FFFFFF → #F4EFF6 | top → bottom |
| *Crystal UI (not for members)* | #E7E2EC → #DCE5F4 → #F8FAFD (stops 0, 0.54, 1) | top-left → bottom-right |

Light backgrounds swap the white glass for plum glass (#3D2A4A at 7–28%) and use one of seven accent colours: Purple #6B4B7D,
Royal Blue #395B88, Rose #8A4E69, Emerald #2F665A, Sapphire #355A7D, Gold #9B7835, Black #171219. Members never see these.

**Gender no longer changes colour.** The old male (blue) and female (pink) gradients now all return the one background
(`genderGradient()` ignores gender on purpose).

**Gold accents (member option, starts Off).** Personalisation → Gold accents adds a moving gold dust and a diagonal edge behind
the background. Remembered per account on that device; cleared on sign-out. Still when the phone asks for reduced motion.

## 3. Glass, surfaces and the surface styles

Three surface styles exist; **Glass Signals is the locked default** (Founder, 29 Aug 2026 in code; confirmed 29 Oct 2026 — "Glass Signals"). The other two are developer comparisons removed in the Tier 4 clean-up (DR-ZYRA-276). Until 29 Oct this page said Classic Glass, copied from a stale code comment; the app has run Glass Signals since 29 Aug.

| Style | What changes |
|---|---|
| Classic Glass | Plain white glass; signals in white (removed, Tier 4) |
| **Glass Signals (current, locked)** | Adds a light gold wash to selected surfaces; signals in gold |
| Status Accents | Tints surfaces with the lavender action colour |

On dark backgrounds (what members see) the values are:

| Surface | Fill | Edge |
|---|---|---|
| Normal card / pill / panel | white 7% | white 14% |
| Selected / emphasis | white 7% | gold #E8C98A 70% |
| Glass card (`glassFill`) | white 7% | gold 70% |
| Progress bar track | white 28% | — |
| Floating navigation bar | white 10% (20% while touched) | white 18% (30% while touched) |
| Divider | white 14% | — |

Blur behind glass: σ22 for the navigation bar, segmented toggle and seeker selector; σ16 error banners; σ18 Guardian invitation dashboard; σ30 help sheet.

## 4. Spacing and corners

| Thing | Value |
|---|---|
| Person row card (every list of people) | thumbnail **52×52**, thumbnail corner **10**, padding **12**, card corner **14**, gap thumb→text **14**, space between cards **10** |
| Main button | at least **48** tall, padding **20 × 13**, fully round (stadium) |
| Gold action pill | **48** tall, fully round (999) |
| Bottom sheets and centred dialogs | corner **24** |
| Snackbar | corner **14**, floating, inset **20** left/right/bottom |
| Navigation bar | Full: **390** wide (at 430), **58** tall, corner **28**, **24** from the sides, **14** from the bottom. Idle (not touched): **40%** wide (**156**), **46** tall, centred; back to idle 3 s after the last touch or when the page scrolls; full size always with VoiceOver, Switch Control or Larger Text (LOCK 6, DR-ZYRA-304, spec DOC-ZYRA-0320) |

Corners used across the app (count of places): 14 (81), 18 (58), 12 (52), 20 (45), 16 (45), fully round 999 (41), 24 (21), 50 (19).
There is no single corner scale — see OA-ZYRA-313.

## 5. Shared building blocks (`SOURCE/lib/widgets/`, 69 files)

| Building block | File | What it is | Used in |
|---|---|---|---|
| **Main button** | theme in `main.dart` | Glass fill, gold 70% edge, white Poppins 400 15, round | ~30 buttons app-wide |
| **Gold action pill** | `zyra_gold_action_pill.dart` | The premium action: gold-edged round pill, 48 tall (chosen 29 Aug from five designs) | 3 |
| **Glass dialog** | `zyra_glass_dialog.dart` | Centred notice/confirm: #241A2F, corner 24, gold 28% edge; danger button coral with dark text | 17 |
| **Floating navigation bar** | `floating_nav_bar.dart` | "Floating Glass" glass bar; the current tab has a **gold underline** (no ring) and the bar is small until touched (LOCK 6, DR-ZYRA-304); a gold icon means new activity until that tab is opened (LOCK 5, DR-ZYRA-303); Browse's ••• action bar is unchanged | 11 |
| Shell navigation | `zyra_shell_navigation.dart` | Tabs, plus a side rail on wide screens | 3 |
| **Segmented toggle** | `zyra_segmented_toggle.dart` | The Connections selector; **the app's motion reference** (slide 260 ms easeOutCubic) | 13 |
| State widgets | `zyra_state_widgets.dart` | Field error line, soft glass error banner, empty states | 39 |
| Loading | `zyra_loading.dart` | Sliding-dots loader | 35 |
| Profile image | `zyra_profile_image.dart` | Photo with spinner while loading | 28 |
| Name on photo | `zyra_profile_name_block.dart` | Two-layer shadow for text on photos | 4 |
| Privacy label | `privacy_indicator.dart` | Dot + word: Public (green #3D9A6A), Unlock (gold #C49A44), Private (purple #8A6A9E) | 6 |
| Moment | `zyra_moment.dart` | Full-screen celebration page, fades in over 400 ms | 3 |
| Splash artwork / motion | `zyra_splash_artwork.dart`, `zyra_splash_motion.dart` | Wordmark plus the growing line behind it | 2 / 4 |
| Comet rule | `zyra_comet_rule.dart` | Two lights meeting on a line (journey divider) | 1 |
| Fade edges | `zyra_fade_edges.dart` | Fades content at scroll edges | 4 |
| Press feedback | `zyra_press_feedback.dart` | Small press-down shrink (90 ms in, 180 ms out); none when reduced motion is on | 2 |
| Pull-down back | `zyra_pull_down_back_scope.dart` | Pull down to go back | 12 |
| Onboarding set | `onboarding_scaffold`, `zyra_onboarding_*` (9 files) | Question card, choice card (quiet gold/frost), gold arrow continue, name field, edge swipe | 1–12 each |
| Report / help sheets | `report_profile_sheet.dart`, `help_report_sheet.dart` | Report or block; help | 5 / 2 |
| Account switch | `zyra_account_switch_sheet.dart` | One login, Seeker and Guardian sides | 4 |
| App lock | `zyra_app_lock_gate.dart` | Face ID / passcode gate | 1 |
| Membership set | `zyra_membership_choices`, `_history_lock`, `zyra_locked_feature_upgrade`, `zyra_intelligence_card` | Plan choices and "this is a member feature" boundaries | 1–3 |
| Journey icon | `zyra_journey_icon.dart` | The Founder-chosen couple symbol | 1 |
| Guardian set | `zyra_guardian_*`, `zyra_ward_card.dart` | Dashboard card, capacity notice, invitation dashboard, ward stat chips | 1–3 |
| Message receipt | `zyra_message_receipt.dart` | Small "seen" receipt under your last message | 2 |
| Notification bell | `notification_bell.dart` | Bell with count | 3 |

**Not used by the app** (only tests, or nothing): `fab_continue_button`, `glass_icon_button`, `zyra_family_pricing_card`,
`zyra_paused_limit_refusal` — added to OA-ZYRA-311.

## 6. Haptics (the little vibrations)

| Setting | Phone feedback |
|---|---|
| Off | none |
| **Subtle (default)** | selection click |
| Light | light impact |
| Medium | medium impact |
| Strong | heavy impact |

Members choose in Personalisation; it is remembered on the device. All app haptics should go through
`ZyraInteractionStyle.emitSelectionHaptic()` — 13 files do (navigation bar, tabs, Browse, Find by code, photos, avatar,
ZYRA code, invites, Personalisation). **One file does not:** `screens/journey/journey_flow_screen.dart` calls the phone
directly four times (stage continue, life snapshot reveal, guardian profiles reveal, guardian salam), so it buzzes even when the
member chose Off — OA-ZYRA-314.

**Rule (Founder, 30 Oct 2026: "ensure this and all buttons have haptic feedback"):** every enabled tappable control gives one
haptic per tap at the member's level, through `emitSelectionHaptic()` in the shared tap components; none when Off, on disabled
controls, scrolling, photo swipes or typing. Being built by queue line 22.

## 7. Motion

| Thing | Value |
|---|---|
| Usual curve | `easeOutCubic` (98 places); `easeInOutCubic` 22; `easeInCubic` 16 |
| Usual lengths | 180 ms (26), 220 / 280 ms (16 each), 420 ms (13), 200 / 320 ms (12 each), 260 ms (11), 480 ms (10) |
| Tab / toggle slide | 260 ms easeOutCubic (the reference) |
| Moment page | fades in 400 ms |
| Page changes | Flutter's own default for each platform (no custom transition) |
| Reduced motion | honoured in 43 files: press shrink, gold dust and others stand still |

Navigation bar styles (developer comparison only; members get Floating Glass): Labelled Dock, Accent Ring, Soft Tiles, Gold Underline,
Raised Capsule, Quiet Dot.

## 8. Developer-only style tools

Developer Tools can try, for the running session only: 18 fonts (Jost, Manrope, DM Sans, Plus Jakarta Sans, Outfit, Urbanist,
Montserrat, Raleway, Lora, Cormorant Garamond, Inter, Poppins, Nunito Sans, Source Sans 3, Work Sans, Quicksand, Libre Baskerville,
Merriweather — all but Poppins fetched online), every background, the light accents, the surface styles and the navigation bar styles.
None of this changes what members see, and it resets on relaunch. The wordmark is never affected.

## 9. Where the documents disagree with the code

The colour theme document is DOC-ZYRA-0102, `BUSINESS/COLOUR THEME/Summary.md`. **Fixed 25 Oct:** rewritten as V2 from the code
(with its Flow Diagram and References); V1 is archived in `BUSINESS/COLOUR THEME/ARCHIVE/`. The table below records what V1 said.

| # | Document says | Code does | Which is right |
|---|---|---|---|
| 1 | Palette table: Royal Purple **#8A6A9E**, Luxury Dark Purple **#3D2A4A** | `royalPurple` = **#30203F**, `luxuryDarkPurple` = **#160E20** (renamed values since 27 Sep) | Code (banner agrees) |
| 2 | Male theme blue #3D5A80, female theme pink #D4868F, by gender | One background for everyone; Royal Blue / Rose Pink are optional backgrounds with **different** values (#607BA7, #A6788F) | Code |
| 3 | 25 Jul note: `genderGradient()` applies male/female colours | It returns the single background | Code |
| 4 | "Current bottom-sheet override" **#2A1F33** | **#241A2F** (a later banner says so too) | Code |
| 5 | Primary button fill lavender #CEA2D1 with #3D2A4A text, "every primary button" | Main buttons are **glass with a gold edge**; lavender is only the theme colour; text on it is **#160E20** | Code (22 Oct banner) |
| 6 | Centred dialogs: white 14% glass, blur σ30 | Opaque **#241A2F**, gold 28% edge (3 Oct banner agrees); a comment in `zyra_glass_dialog.dart` still says σ30 | Code |
| 7 | Bottom sheets: purple gradient + blur σ30 | Opaque #241A2F | Code |
| 8 | Four colours in total | 12 backgrounds, 7 light accents, ~20 named colours (gold, green, red, privacy dots…) | Code — the document lists too few |
| 9 | No fonts | Fonts are only in code comments; no document records Poppins / Syne | Needs a document — this part fills the gap |
| 10 | `pubspec.yaml` comment: google_fonts is for "Jost typeface" | Poppins and Syne are bundled; Jost files sit in `assets/fonts` but are not used | Code |
| 11 | `zyra_text.dart`: Poppins made official "2026-10-01" in the header, "2026-08-24" lower down | Same font either way | Date only |

Accessibility notes (contrast, normal text needs 4.5):

| Text | On #30203F | Pass? |
|---|---|---|
| White / body / secondary / muted | 15.0 / 12.3 / 8.0 / 5.4 | Yes |
| Gold #E8C98A | 9.4 | Yes |
| Coral #E08080 | 5.4 | Yes |
| Dark #160E20 on lavender | 8.7 | Yes |
| Privacy words (Public / Unlock / Private) | 3.6 / 2.7 / 2.3 | **No** — OA-ZYRA-314 |

## 10. How to rebuild the look

1. Background: one linear gradient #30203F → #160E20, top-left to bottom-right, behind every page.
2. Text: Poppins, white, weights 200/300/400 at the sizes in §1; wordmark Syne 600, #E5CE8E, letter spacing 4.
3. Surfaces: white 7% fill, white 14% edge; selected = gold #E8C98A 70% edge; blur σ22 for floating glass.
4. Sheets, dialogs and toasts: opaque #241A2F, corner 24 (toast 14).
5. Buttons: 48 tall, round ends, glass + gold edge; danger in #E08080.
6. People rows: the card sizes in §4, everywhere.
7. Motion: easeOutCubic, 180–420 ms; respect reduced motion. Haptics: selection click by default, member-adjustable.
| 2026-10-26 | V1 | Approved by the Founder ("a" - all 14 pages); status CURRENT |
| 2026-10-29 | V1 | §3 corrected: the locked surface style is Glass Signals, not Classic Glass (Founder, 29 Oct, answering Codex's Tier 4 question; ZYRA chat) |
| 2026-10-30 | V1 | §4 navigation bar and §5 floating navigation bar updated to LOCK 5 and LOCK 6 as built on 29 Oct (DR-ZYRA-303, DR-ZYRA-304) - Fable, 04:15 maintenance |
| 2026-10-30 | V1 | §6: haptic on every enabled tappable control (Founder "ensure this and all buttons have haptic feedback"); queue line 22 - ZYRA chat |
