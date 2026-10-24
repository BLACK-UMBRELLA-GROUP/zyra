# ZYRA Style Lab Combinator — Implementation Handover

**Version:** V1  
**Status:** SUPERSEDED — HISTORICAL LINEAGE; runtime Style lab retired by Founder 2026-08-29  
**Date:** 2026-08-24; superseded 2026-08-29  
**Implementer:** Codex, Lead Architect  
**Authority:** Founder direct instruction, 2026-08-24  
**Migration authority:** none requested or used

> Do not use this file as current runtime truth. Archived by Fable
> 2026-08-29 (renamed from CURRENT_VERSION per version management).
> The current contract is `ZYRA_STYLE_DEFAULT_HANDOVER_CURRENT_VERSION_V1.md`
> §11 plus `ZYRA_DEVELOPER_CONTROL_SYSTEM_HANDOVER_CURRENT_VERSION_V1.md` §25.
> Fable owns archival rename/reference reconciliation.

## 1 · What was built

Developer Style is now an independent presentation combinator. The Founder can
change the background, light-background accent, reading font, bottom-navigation
style and haptic feel without one selection silently replacing another.

App surface is now a separate global axis owned by the developer **Home** door,
not by Style and not by Dashboard Lab. Home offers **Classic Glass**, **Glass
Signals** and **Status Accents**; Classic Glass is the current default.

- Added **Crystal UI**, a pale translucent gradient based on the supplied visual
  reference. Its content surfaces and glass chrome use translucent white.
- Retained **Paper White** as its own light-background choice.
- Purple, Royal Blue, Rose, Emerald, Sapphire, Gold and Black accents work on
  either light background.
- Retained all dark palettes and all eighteen reading fonts. Midnight Plum and
  Poppins remain the launch defaults; the Syne ZYRA wordmark remains locked.
- Added seven navigation choices: Floating Glass, Labelled Dock, Accent Ring,
  Soft Tiles, Gold Underline, Raised Capsule and Quiet Dot. Labelled Dock adapts
  the supplied dark-dock/white-active-pill reference for ZYRA's five tabs.
- Added five haptic levels: Off, Subtle, Light, Medium and Strong.
- Added a signed-in Guardian Dashboard greeting. The public logged-out Welcome
  screen deliberately does not reveal the previous account holder's name on a
  shared device. The Seeker Dashboard already provides its signed-in greeting.

The alternate options are developer experiments, not member profile
preferences or approved brand canon. A cold launch returns to Midnight Plum,
Poppins, Floating Glass and Subtle haptic; App Surface is the exception and
restores its device-local developer selection (Classic Glass on a fresh/reset
install).

## 2 · Why this architecture

The Style lab is for comparing combinations. A single preset object would
couple unrelated decisions and make it impossible to test, for example, Crystal
UI + Black accent + Poppins + Quiet Dot. Each axis therefore has its own
in-memory notifier and the app rebuilds from their current combination.

The app-surface notifier follows the same independent-state architecture, but
its control sits in Home because its shared token readers affect ZYRA beyond
Style and beyond the Dashboard. This avoids presenting a global system as a
page-specific option. Dashboard Lab separately locks Sectioned Status and
receives the selected global surface only as render configuration.

Haptic strength is represented as named feel levels rather than a misleading
continuous amplitude. Flutter exposes native semantic haptics, while iOS and
Android retain authority over the physical motor strength and may suppress
feedback through system settings.

## 3 · Architecture and data flow

```text
Developer Home panel
  └─ app surface → ZyraColors.appSurfaceStyleSelection
                      ↕ ZyraLocalPrefs (device-local name)

Developer Style panel
  ├─ background → ZyraColors.devPaletteSelection
  ├─ light accent → ZyraColors.devLightAccentSelection
  ├─ reading font → ZyraText.appFontSelection
  ├─ nav style → ZyraInteractionStyle.navStyleSelection
  └─ haptic level → ZyraInteractionStyle.hapticLevelSelection
                         ↓
ZyraApp rebuild boundary + shared semantic/surface theme tokens
                         ↓
all mounted routes keep navigator/account state while presentation updates
                         ↓
Seeker + Guardian Dashboard mock configs receive current app surface

FloatingNavBar interaction
  → duplicate-cell guard
  → ZyraInteractionStyle.emitSelectionHaptic()
  → native system haptic request selected by current level
```

`FloatingNavBar` remains the single navigation implementation for Seeker and
Guardian. The seven styles change highlight, dock and icon presentation only;
destination order, route semantics, badges, tap handling and drag-scrub remain
shared. Developer Style is app-wide, including auth and onboarding, while a
navigation choice is visible only on screens that contain the shared bar.

The app-surface selection is consumed by shared progress, icon-button,
selected-frost and glass tokens. Classic Glass keeps shared surfaces neutral;
Glass Signals keeps neutral glass while meaningful semantic signals remain;
Status Accents strengthens active/status tint. Both Dashboard mock hosts receive
the same selection, but the mock renderer is not used as a production data
adapter.

## 4 · Haptic mapping

| ZYRA level | Flutter/native request |
|---|---|
| Off | none |
| Subtle | `selectionClick()` |
| Light | `lightImpact()` |
| Medium | `mediumImpact()` |
| Strong | `heavyImpact()` |

This is cross-platform. iPhone uses iOS feedback generators; Android uses the
device's supported haptic constants. The same label can feel different across
hardware because ZYRA cannot and should not override the operating system's
actuator policy.

## 5 · Developer controls, mock and production boundaries

- Style choices remain session-only `ValueNotifier` state. App Surface is the
  deliberate exception: its name is written to device-local preferences and
  hydrated before `runApp`. Nothing writes member profiles, Supabase or
  analytics.
- Release members have no Style-lab route.
- Release members also have no App Surface selector; release starts on the
  Classic Glass default.
- The haptic request is real on device. Widget tests intercept Flutter's
  platform channel only to measure the requested semantic feedback.
- Crystal UI is real shared-theme behavior, not a screenshot-only mock.
- Guardian greeting reads the current signed-in Guardian display name first and
  falls back safely; no name is cached onto the signed-out Welcome screen.
- Restore means Midnight Plum + Purple light accent + Classic Glass + Poppins
  + Floating Glass + Subtle haptic.
- Dashboard-specific surface and concept selectors are absent. Sectioned Status
  is shown as the locked Lab layout; the current Home surface is passed into
  both Seeker and Guardian mock renderers.
- Production/release Dashboards keep their existing truthful data UI because
  `ZyraDashboardExperience` still renders deterministic Lab content.

## 6 · Live files and point-in-time SHA-256 evidence

The hashes below were recorded for the 2026-08-24 Style Lab build. They predate
the 2026-08-26 app-surface/Dashboard-lock amendment and are **not** asserted as
current digests.

| File | Responsibility | SHA-256 |
|---|---|---|
| `SOURCE/lib/theme/zyra_interaction_style.dart` | Seven navigation styles, five native haptic levels and defaults | `2a040676289d222dcb0c07ae4f60087a2373921b6d7b0e19c818e2c8e1400f6b` |
| `SOURCE/lib/theme/zyra_colors.dart` | Historical digest; current file also owns three app-surface styles, Classic Glass default and shared token resolution | `0636b8ca9420c5be7280ae9c8cf891da57068827f6299f44adecc737bbc75128` |
| `SOURCE/lib/main.dart` | Historical digest; current rebuild boundary also listens to app-surface selection | `44f37f8afe9cad5873a44f1953f89b6021d0174a40ef3b2a40bd9e43eff13161` |
| `SOURCE/lib/dev/zyra_dev_control_system.dart` | Historical digest; current file owns the Home surface picker and includes Classic Glass in restore | `c6519e93625f4a405404f0f413b9ce5631ffeab25051aa62cdf0a0b2289b7c76` |
| `SOURCE/lib/widgets/floating_nav_bar.dart` | Seven compatible visual treatments and shared haptic dispatch | `35aa45b887dd8f6e032f78194598b799ba8a34c47615f5ad3a24c505e2f96d75` |
| `SOURCE/lib/screens/wali/wali_dashboard_screen.dart` | Signed-in Guardian greeting | `b55c9d7bbf05dddf84c983f74b2940f86342e1c2c9994b499c97cf4e7f2baccf` |
| `SOURCE/test/floating_nav_bar_haptics_test.dart` | Exact haptic mapping, duplicate guard and all nav styles | `2b9934146a50850fe47cc806230c35214cd02a45eb18f6b40adfcb47438d57d3` |
| `SOURCE/test/dev_scenario_panel_policy_test.dart` | Style choices, independence, slider and restore | `b939bca887903fd4f97d7750d88c5ed0140db5e21fb9052afd478c974fa3501b` |
| `SOURCE/test/style_lab_compatibility_test.dart` | Compact-phone background × nav and Crystal accent × font matrix | `986277c1a945ca49aad4f87621a2fdd08497a0d5399df7d4d762f63715a857cd` |
| `SOURCE/test/guardian_dashboard_greeting_test.dart` | Guardian-name source and rendered greeting | `540f3f79600ba5032d7be3f16ace96d86a9864ecbd12f9f3bf1d58cd5693a11a` |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | Governed Crystal UI/nav showcase fixtures | `c4db236914fbbdaa21a34ddd7d9f4c25903625e48c0f4263318889bd9d7d7ac4` |
| `SYSTEM/RESOURCES/UI_GATE/state_matrix.json` | Declared visual states and phone sizes | `fe92ab8cf48e90831f861efdea0cd3049a9717a27b43dbc56acecf368d83db02` |
| `SYSTEM/RESOURCES/UI_GATE/REPORTS/ZYRA_VISUAL_AUDIT_2026-08-24_747ff8cf.md` | Final visual-gate evidence | `353dbaf2d00923e02193268aedc3e349877e19ae0341df7c0bd6f26713d6f03e` |

This document omits its own hash because embedding it would change the value.

Current 2026-08-26 amendment hashes were remeasured after the final test/build
pass:

| File | SHA-256 |
|---|---|
| `SOURCE/lib/theme/zyra_colors.dart` | `91c1cf87372037b81f6a14da934ff977f2cc0f8fb311d29cdafaaae2361c7841` |
| `SOURCE/lib/main.dart` | `a7ae853ff4b9f2640396f1d890f42de062f0304b7d2ae031c5999b53ffea5e32` |
| `SOURCE/lib/dev/zyra_dev_control_system.dart` | `136df69b97fcc0b82967d76267f581905dbb275088ac3e0b8fa1bf124d4f096a` |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `a5d216ecb122ec6e20dfca8597feed36eaf1d4b8289d644b9b62486bfc0523c7` |
| `SOURCE/lib/dev/zyra_dashboard_lab_controls.dart` | `c608d3fb8caff3b1d0466c7c823887553cb6a7d66d01e3dc87cc0613444b7470` |
| `SOURCE/lib/models/zyra_dashboard_lab.dart` | `5d069aca716d2237c30faaad482dcdd3bdbff551ddcb5680b7d434f8e777d525` |
| `SOURCE/lib/widgets/zyra_dashboard_experience.dart` | `57b98a0c605fef8abb839e81c57a29418b6851e5e526639a1cda857e8988d176` |

## 7 · Measured verification and current boundary

The table below retains the original 2026-08-24 Style Lab evidence. The
2026-08-26 global-surface/Dashboard-lock amendment was additionally measured
after its final code change: `flutter analyze` found no issues; the focused
control/Dashboard suites passed; the dedicated visual suite passed **190/190**;
the full Flutter suite passed **456/456**; `tools/zyra_check.py` returned 0
findings across 165 files; and the iOS profile build produced a 36.0 MB
`Runner.app`. Physical-phone selection remains Founder-pending. Exact commands,
all changed-file hashes and the first-run stale-test correction are recorded in
`ZYRA_DASHBOARD_LAB_HANDOVER_CURRENT_VERSION_V5.md` §7–8.

| Measurement | Result |
|---|---|
| Focused interaction/style/greeting suite | PASS · 17/17 |
| Compact compatibility matrix | PASS · every palette × 7 nav styles at 320×568; Crystal UI × 7 accents × 18 fonts at 320×568 |
| Dedicated visual regression test | PASS · 70/70 tests, including 69 declared render variants |
| Complete Flutter regression | PASS · 262/262 |
| `flutter analyze --no-pub` | PASS · no issues |
| Governed visual gate | BASELINE-PENDING only · 69/69 render variants produced; 0 approved baselines; no self-promotion |
| Manual candidate inspection | PASS · all seven navigation treatments fit compact/standard phone fixtures without overflow |
| `flutter build ios --debug --no-codesign --no-pub` | PASS · `build/ios/iphoneos/Runner.app` |
| SQL probe | Not applicable — no database change |
| Physical iPhone feel/selection | PENDING — Founder installs with `./run.sh` and compares styles/haptic levels |

## 8 · Migrations and external changes

No migration was created or applied. No database, RLS, RPC, Edge Function,
Supabase setting, authentication provider, package dependency or native project
setting changed.

## 9 · Known limitations and remaining work

1. Native haptic levels are semantic requests, not calibrated amplitudes. A
   slider-like five-stop control is provided for comparison, but physical feel
   requires the Founder on the target iPhone and later one representative
   Android device.
2. The visual-test harness may render Material icon glyphs as placeholder
   squares because golden tests use deterministic font loading. The production
   iOS build contains the real Material icon font; this is harness-only and does
   not affect layout/overflow measurement.
3. The seven navigation treatments are comparison candidates, not a ratified
   replacement for Floating Glass. Founder selection remains pending.
4. No signed-out personalised greeting is shown. This is an intentional privacy
   boundary for logged-out/shared devices, not a missing feature.
5. The visual gate remains baseline-pending under OA-ZYRA-257 because the
   Founder has not approved a golden baseline set.
6. Glass Signals and Status Accents are developer comparisons, while Classic
   Glass is the fresh-install/reset default. Persistence is device-local
   developer state, not a member-facing or server preference.
7. Sectioned Status is locked in Dashboard Lab but still consumes mock content.
   **Written refusal — no OA raised:** release continues to use the existing
   data-backed Seeker and Guardian Dashboards until a separate production
   adapter build is authorised.

No commit or git mutation was run. Codex did not self-approve or promote visual baselines.

---

## Version history

| Version | Date | Change |
|---|---|---|
| V1 | 2026-08-24 | Added independent Crystal/background, accent, font, seven-nav and five-haptic comparison axes plus Guardian greeting and evidence. |
| V1 amendment | 2026-08-26 | Recorded Home-owned app-wide surface selection, three surface options, Classic Glass default, shared token propagation, locked Sectioned Status, and the production Dashboard truth boundary. No migration. |
| V1 amendment 2 | 2026-08-26 | Corrected App Surface to device-local persistence across relaunch while all other Style axes remain session-only. |
