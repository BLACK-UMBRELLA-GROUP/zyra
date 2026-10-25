---
id: DOC-ZYRA-0169
type: HANDOVER
status: CURRENT
feature: GENERAL
purpose: ZYRA Current Style Default — Implementation Handover
links: []
owner: ZYRA chat
---

# ZYRA Current Style Default — Implementation Handover

**Version:** V1  
**Status:** CURRENT_VERSION — internally verified; Founder device acceptance pending  
**Date:** 2026-08-24; latest splash-wordmark alignment 2026-10-01  
**Implementer:** Codex  
**Authority:** Founder direct instruction in Codex conversation, 2026-08-24  
**Related governance:** AD-AIOS-099; AD-AIOS-104; DR-ZYRA-214; OA-ZYRA-257  
**Product sources:** `BUSINESS/COLOUR THEME/Summary.md`; `APP/Onboarding/SEEKER ONBOARDING QUESTIONS/Onboarding Rules & UX.md`

> **Current-reading rule:** §13 aligns the enlarged splash mark with the
> existing small onboarding-header wordmark. §12 fixes ordinary app text to Poppins and the
> standalone ZYRA wordmark to locally bundled Syne. It supersedes §11's
> member-selectable font wording. §11 supersedes older statements below that
> describe Style as a four-door developer comparison lab, App Surface as a
> persisted choice, or palette/font/haptic as developer-only session state.
> Those passages remain as implementation lineage, not current runtime truth.

## 1 · What was built

ZYRA now launches with these current defaults across Seeker, Guardian, auth
and signup/onboarding surfaces:

- **Background:** Midnight Plum, `#684D78` → `#241A2C`.
- **Reading text:** Poppins.
- **ZYRA wordmark:** Syne remains locked and unchanged.

Developer Style still contains all ten background options, all eighteen
reading-font options, Paper White and Crystal UI light-background families,
seven light accents, seven navigation styles, five haptic levels and the locked
wordmark. The
shared restore action now reads `Restore default style` and returns to Midnight
Plum + Poppins + Floating Glass + Subtle haptic. Those Style selections remain session-only;
the separate Home-owned App Surface is the exception and persists locally.
Cold relaunch returns the Style axes to those defaults while restoring the
last App Surface selection (Classic Glass on fresh install/reset). The current as-built combinator
and evidence are authoritative in
`ZYRA_STYLE_LAB_COMBINATOR_HANDOVER_2026-08-29_V1.md`.

## 2 · Why this shape

The Founder requested a current default without deleting the comparison
choices. One central colour notifier and one central font notifier already
drive the whole `MaterialApp`, so their initial values and shared reset action
were changed instead of editing individual screens.

Poppins was previously available through `google_fonts` runtime loading only.
Making that the launch default would have allowed first-paint fallback text,
post-paint re-layout and no-font behaviour offline. Six official Poppins
weights are therefore bundled locally and the Poppins branch resolves through
a synchronous `TextStyle(fontFamily: 'Poppins')`. Other comparison fonts keep
their existing session-only Google Fonts behaviour.

## 3 · Architecture and data flow

```text
app process starts
  ├─ ZyraColors.devPaletteSelection = midnightPlum
  ├─ ZyraText.appFontSelection      = poppins
  └─ ZyraColors.appSurfaceStyleSelection
         ← ZyraLocalPrefs.cachedAppSurfaceStyleName (Classic Glass fallback)
                  ↓
ZyraApp ListenableBuilder rebuilds MaterialApp
                  ↓
all shared gradients + ZyraText styles resolve current defaults

Developer Style selection → same notifiers → live app rebuild
Restore default style     → midnightPlum + poppins + purple White accent
cold relaunch             → Style defaults + persisted App Surface
```

No individual screen owns or persists a colour/font preference. App Surface is
persisted centrally as device-local developer state; it is not a member or
server setting.

## 4 · Responsive correction found during verification

Actual Poppins metrics overflowed the 320×568 onboarding Welcome fixture by 12
pixels. `_WelcomePage` now compacts quiet vertical spacing below 620 logical
pixels while keeping the established vertical `PageView` gesture; it does not
introduce a nested competing scroller. The same verification also exposed an
asynchronous text-painter assertion in the traffic-light screen. Resolving the
bundled Poppins branch synchronously removed that post-paint font change.

Both failures were reproduced in isolation before correction and passed in the
final complete suite and visual matrix.

## 5 · Live files and SHA-256 evidence

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/theme/zyra_colors.dart` | Midnight Plum launch default; all palette options retained | `0d2b4c16ef06311d8f09f5b6e9202c418dda65fdaed6fd5b27d80057b2ac7689` |
| `SOURCE/lib/theme/zyra_text.dart` | Poppins launch default; synchronous bundled branch; all fonts and Syne wordmark retained | `d536dd0bd0d8df8a34b8b6b2995715a9d96b5151f6eea4773cf288eb8149c682` |
| `SOURCE/lib/main.dart` | App rebuild boundary documentation for current defaults | `f9868dec1e280ca08f6956a58cbc83dcd844471abce9be2f3a2fe7f67c5875f4` |
| `SOURCE/lib/dev/zyra_dev_control_system.dart` | Style labels and shared restore-to-default action | `3a5cfb28a9b7d5a8706451644658c791c31c83d4890401b3e460940c715f19f8` |
| `SOURCE/lib/screens/onboarding/onboarding_stage_intro_screen.dart` | Short-phone spacing correction for real Poppins metrics | `15ddcae3233a2e6125d315bc71dd5ff1eac40eaa54ef11f12e90801963ca159e` |
| `SOURCE/pubspec.yaml` | Registers six Poppins weights and OFL licence | `51c76c7d44683fb7d0137cbffc11fed29926068a6d12e86a4f0624b70be3a530` |
| `SOURCE/test/widget_test.dart` | Current Midnight Plum endpoints and unified-theme invariant | `c64bfe7efa1e15257e98d35919628770c768de9a4fe67670c7607ad8d7451dd5` |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | Defaults, restore, all options, wordmark and bundled-font checks | `164e12a38eeda89ab312321bad2dbd0f724598437a5dc8d1740a3f18b33e5319` |
| `SOURCE/test/global_dev_overlay_test.dart` | App-wide developer-control default isolation | `bd328fb5bebe46517888542302304ac55418e6f51ae9f3010082402749f67b75` |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | Real Poppins metrics in the phone-size render matrix | `470d60065ef60dab0a1057a572f46795c698e9378290c49e7051b57075f843e4` |
| `BUSINESS/COLOUR THEME/Summary.md` | Product record of the current Midnight Plum override | `43aba1673b6a5de207e7d0b6fa1e118ef4293f617a06b68c439d251e62e9dbcc` |
| `APP/Onboarding/SEEKER ONBOARDING QUESTIONS/Onboarding Rules & UX.md` | Product record of current Poppins typography | `ed2c0ae6405ede43407499fe3c22d079108489e5cfe12cb7c68650b4219fcc94` |
| `SYSTEM/RESOURCES/UI_GATE/REPORTS/ZYRA_VISUAL_AUDIT_2026-08-24_fb6e2ec3.md` | Final deterministic/render/regression evidence | `f4ec51d2e5ee2428b974f344a529be0f076a6e6e675e823646a9fdcc60daccde` |

Bundled official Google Fonts assets:

| Asset | Weight/licence | SHA-256 |
|---|---|---|
| `SOURCE/assets/fonts/Poppins-ExtraLight.ttf` | 200 | `55c03314cc754e26f741f97890e5e9cbe3b3278fe3abcecfecafd60111b2643d` |
| `SOURCE/assets/fonts/Poppins-Light.ttf` | 300 | `650ba57fa99d12ec40c31ccfb680be656be4497fbe14164617d67e32ffe9cd46` |
| `SOURCE/assets/fonts/Poppins-Regular.ttf` | 400 | `7e65201e9b79159e2300267cc885e16c8dcef2424cdfa09a29bfb0980a94a7ba` |
| `SOURCE/assets/fonts/Poppins-Medium.ttf` | 500 | `90373e7d838d32468438fc3e152dca0bdb12edcab99ea639f158790b1ba1fd05` |
| `SOURCE/assets/fonts/Poppins-SemiBold.ttf` | 600 | `d3bf1bdaf0550e83da9ac0b1d1d9fe6db086835a83aa28578e609a394b9a0286` |
| `SOURCE/assets/fonts/Poppins-Bold.ttf` | 700 | `983676516167748b74de6f4771fb384c664fd913acb8b471122ecacf5da5ea6c` |
| `SOURCE/assets/fonts/Poppins-OFL.txt` | SIL Open Font License | `6be04893d770899a015649c7aa3b582f871b272f8747a92b78b17c3e5c8b2573` |

The font files and licence came from the official `google/fonts` repository,
`ofl/poppins`, on 2026-08-24.

## 6 · Developer controls; mock versus production

- Production/release starts in Midnight Plum + Poppins and has no route for a
  member to change them.
- Authorised debug/profile Developer Style exposes all alternatives live.
- Alternative palette/font/navigation/haptic selection remains in-memory.
  App Surface alone writes a device-local name; none of these writes account
  data or Supabase.
- Poppins itself is not mocked in visual tests: the harness loads the bundled
  Poppins font files under a deterministic audit alias so real glyph metrics
  are measured without network access.
- The ZYRA Syne wordmark never reads `appFontSelection`.

## 7 · Migrations and external changes

No database migration was created or applied. No schema, RLS, RPC, trigger,
authentication provider or Supabase configuration changed. No new Dart package
was added. Official font binaries and their licence are the only new external
assets.

## 8 · Tests and measured verification

| Measurement | Result |
|---|---|
| Pre-change source trace | Launch/reset were hard-coded to ZYRA Purple + Jost; Poppins existed only as a runtime Google Fonts option |
| Focused default/control suite | PASS · 15/15 |
| Bundled-font probe | PASS · all six Poppins weights load from `rootBundle`, each >1,000 bytes |
| Reproduced smallest onboarding render | Before: 12px bottom overflow · After: PASS at 320×568 |
| Reproduced traffic-light test | Before: async text-painter `debugSize == size` assertion · After synchronous bundled Poppins: PASS |
| `flutter analyze --no-pub` | PASS · no issues |
| `python3 tools/zyra_visual_gate.py --force --full` | BASELINE-PENDING only · every step PASS · no open L2 findings |
| Visual render matrix | PASS · 48/48 variants across 320×568, 390×844, 430×932 and declared 1.3× text |
| Complete Flutter suite | PASS · 232/232 |
| SQL probes | Not applicable — no database change |
| Physical iPhone observation | PENDING — Founder installs through `./run.sh` |

The gate remains BASELINE-PENDING because zero screenshots have been approved;
it did not self-promote candidates. This is existing OA-ZYRA-257 governance,
not a style-default failure.

## 9 · Known limitations and owners

1. **Founder phone observation pending.** Confirm Midnight Plum, Poppins and
   Style restore on the installed profile build. This is pending measurement,
   not a known defect; no new OA raised.
2. **Fable verification pending.** Fable checks this handover against disk and
   reconciles any wider historic Jost/ZYRA Purple references. Documentation
   Owner allocates any register item required; Codex did not invent one.
3. **Other comparison fonts remain runtime-loaded.** This is unchanged and
   acceptable because they are developer experiments, not the release default.
   No OA raised for this authorised scope.

## 10 · Authority map and next steps

| Layer | Authority |
|---|---|
| Founder decision | Direct Codex conversation, 2026-08-24 |
| Colour product truth | `BUSINESS/COLOUR THEME/Summary.md` |
| Typography product truth | `APP/Onboarding/SEEKER ONBOARDING QUESTIONS/Onboarding Rules & UX.md` |
| Developer-control architecture | `ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V1.md` |
| As-built style-default truth | This handover |
| Verification contract | OA-ZYRA-257 / DR-ZYRA-214 UI gate |

Next: Founder installs and observes; Fable verifies/reconciles; any phone defect
receives an OA before correction.

No commit or git mutation was run. No migration was created or applied. Codex has not
self-approved this work.

---

## Version history

| Version | Date | Change |
|---|---|---|
| V1 | 2026-08-24 | Midnight Plum and bundled Poppins became current app defaults while all Developer Style comparisons remained. |

## 11 · 2026-08-29 Founder lock and Profile Personalisation amendment — CURRENT

The Founder selected the comparison winners and ended the general Style lab.
Current defaults and fixed design choices are:

- background default: **Midnight Plum**;
- shared wait motion: **Comet line**;
- navigation: **Floating Glass**;
- app surface: **Glass Signals**;
- Connections actions: **Compact Chips**;
- Connections section headings: **Accent Marker**;
- app icon: primary **Gold Horizon**, current/non-large wordmark;
- reading text default: **Poppins**;
- haptic default: **Subtle**.

Only background, reading text and haptic strength remain choices. They moved
to the shared Seeker/Guardian **Profile → Personalisation** screen and persist
as local account presentation state. Personalisation exposes nine dark
backgrounds; Paper White and Crystal Mist are refused by both the UI and the
persistence selection boundary. Sign-out clears the three stored values and
resets their live notifiers so another account cannot inherit them. Startup
hydrates them before `runApp`, preventing a default-colour/font flash.

Developer controls now have three doors: Preview, Actions and Home. Loading,
palette/light accent, font, navigation, haptic, App Surface and app-icon
selectors are not reachable there. Connections card/heading selectors are
also removed. Historical renderers/enums remain only as code/test lineage;
they are not a runtime selection path. The primary app icon asset remains the
already-generated Midnight Plum Gold Horizon/current-text asset.

The exact as-built file hashes, data flow, mock/production boundary and
measured 606-test/device evidence are in
`SYSTEM/RESOURCES/MESSAGES/013_CODEX-FABLE_2026-08-29_STYLE_LOCK_PERSONALISATION_COMPLETE.md`.
No migration, SQL, Supabase policy, package, credential or git action was used.
Fable verification and Founder visual acceptance remain pending; Codex has not
self-approved this amendment.

## 12 · 2026-10-01 fixed Poppins reading face and offline Syne wordmark — OA-ZYRA-270 / OA-ZYRA-257 / OA-ZYRA-286

The Founder clarified that standalone “ZYRA” lettering keeps its own face,
while the rest of ordinary app text should use Poppins. This supersedes §11's
member-selectable reading-font choice. `ZyraText.restoreAppFont` now restores
Poppins even when an older account-local font name exists. Startup clears an
old saved font choice after binding the account; the shared Seeker/Guardian
Personalisation page shows “App text · Poppins” as fixed information instead
of offering a member font picker. Its colour and haptic controls remain. The
old 18-face comparison definitions are retained as isolated developer/test
lineage, not a member-facing preference or cold-start font choice.

`ZyraText.wordmark` remains Syne but now resolves through the existing local
`Syne-SemiBold.ttf` asset, registered at weight 600 in `SOURCE/pubspec.yaml`,
instead of a runtime font fetch. The asset is accompanied by a Syne copyright/
OFL notice and the bundled full OFL text. Standalone ZYRA marks on the app
privacy veil, lock screen, membership-required screen and Settings footer now
use `ZyraText.wordmark`; onboarding and Welcome already used it. Poppins's
six registered local weights and app-wide `ThemeData.textTheme` remain the
normal reading-face path. The launcher label in the developer icon study is
an OS-label simulation, not a branded wordmark.

Seven focused font, Personalisation, onboarding, style-lab, theme and
membership suites passed **59/59**. They cover a legacy Manrope cache being
ignored, the member picker being absent, Poppins/Syne TextStyle families,
offline Syne asset loading, and the protected comparison lineage. Scoped
Flutter analysis found no issues across eleven affected source/test files.
The single main-app `SOURCE/./run.sh` production-flavour PROFILE Xcode build
completed in **49.2s**. The verified, strictly signed
`SOURCE/build/ios/Profile-production-iphoneos/Runner.app` was explicitly
installed into paired-iPhone container
`5A426D67-AC3C-4FCB-B133-DFABC7915C37`, database sequence **5548**, after
the Flutter wireless runner was stopped post-build. A separate native launch
succeeded; device inventory shows `app.zyraconnect.zyra` 1.0.0 (5). The built
`FontManifest.json` lists Poppins weights 200–700 and Syne weight 600; the
Syne font file exists in the signed app bundle. Runner SHA-256 is
`1e292606c740f73b0f235c5b1405dc759fb66628c9c243c0e790c69d57211a27`;
Dart AOT SHA-256 is
`b0173a3276020255354242b1133129074285ffbfaf09ba4b5af5c742bb2b4ab2`.
The point-in-time receipt is
`SYSTEM/RESOURCES/REVIEWS/ZYRA_POPPINS_SYNE_FONT_LOCK_LOCAL_DELIVERY_2026-10-01_VERIFICATION.json`.
Actual physical-screen font pixels were not captured in this run.
OA-ZYRA-270 remains open until Founder physical acceptance; OA-ZYRA-257 and
OA-ZYRA-286 remain open. No remote data, migration, purchase/credit, TestFlight
or Git action occurred.

## 13 · 2026-10-01 splash wordmark matches onboarding header — OA-ZYRA-257 / OA-ZYRA-286

The Founder identified the small `ZYRA` at the top of the welcome prelude as
the correct wordmark reference. The large Quiet Horizon splash mark and the
other code-native splash comparisons already used the same locally bundled
Syne SemiBold face, but retained a fixed four-point letter gap while scaling
the letters up. Their apparent tracking therefore became much tighter than
the 18-point header mark. `SOURCE/lib/widgets/zyra_splash_artwork.dart` now
scales the header's 4/18 letter-spacing ratio with the splash wordmark size.
`FittedBox.scaleDown` keeps the enlarged treatment inside compact widths;
the gold colour, gradient, animation duration, tagline, and onboarding
header itself are unchanged. The central `Welcome to ZYRA.` remains a normal
Poppins sentence, including the embedded brand name. The tagline remains
Poppins too. This does not change the app icon or any baked bitmap asset.

`SOURCE/test/welcome_splash_palette_test.dart` now asserts the splash and
header wordmarks share font family, weight and proportional tracking, while
the tagline remains Poppins. The existing onboarding story test asserts the
welcome sentence is Poppins and standalone header is Syne. Four focused
suites passed **88/88**. The splash-direction suite includes all twelve
directions across compact and standard phone geometries with no overflow;
scoped `flutter analyze` reported no issues. Source SHA-256:
`zyra_splash_artwork.dart` `7c79d08b417b249f73f5619b9ab37ed6530af78cda9ce9198105517a73002f86`;
`welcome_splash_palette_test.dart` `e2c4a7b8f40913349881353a7b53cb1d9891ba21a073c0970b419fa7dff20c6e`.

The one-main-app `SOURCE/./run.sh` production-flavour PROFILE Xcode build
completed in **49.4s**. Deep/strict signature verification passed; Runner
SHA-256 is `d4a5f22c5d7b8ee872523678c56b545a0a2db042e9a75e2c7ba51b87b56ddc1e`
and Dart AOT SHA-256 is
`79fa98083b5d64cafec194168a6f79ea51592445fe06e5522408ad4f3e82bc73`.
Flutter installed and launched the build on the paired iPhone; a separate
native launch also succeeded. Device inventory shows `app.zyraconnect.zyra`
1.0.0 (5), container `FE22BF25-32F4-4ED9-95F5-2414E218A5F0`. Exact
receipt: `SYSTEM/RESOURCES/REVIEWS/ZYRA_SPLASH_HEADER_WORDMARK_ALIGNMENT_2026-10-01_VERIFICATION.json`.
On-device pixels were not captured; Founder visual acceptance remains pending
under OA-ZYRA-257. OA-ZYRA-286 remains open for overall main-app acceptance.
No backend, migration, member-data write, payment/credit, TestFlight or Git
action occurred.
