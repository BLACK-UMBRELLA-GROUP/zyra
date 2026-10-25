# ZYRA Splash Screen — As-Built Implementation Handover

**Version:** V1  
**Status:** CURRENT_VERSION — QUIET HORIZON MAIN; 0.65s FINISHED HOLD; LATEST WORDMARK PROFILE INSTALLED/LAUNCHED; FOUNDER DEVICE ACCEPTANCE PENDING  
**Date:** 2026-10-01 (current overlay; original evidence 2026-08-26)  
**Implementer:** Codex; current operating authority AD-AIOS-111  
**Authority:** Founder direct Quiet Horizon selection, 2026-09-27, and splash/Welcome text-colour and finished-hold corrections, 2026-09-30; OA-ZYRA-257; historical DR-ZYRA-125/126; ZYRA Brand Guidelines  
**Scope:** Production splash motion, its protected Developer Splash Lab and the shared Welcome brand lockup colours  

## Current overlay — 2026-10-01 splash/header wordmark proportion

The Founder chose the small onboarding-header `ZYRA` as the typography
reference for the large splash `ZYRA`. Both already use the locally bundled
Syne SemiBold wordmark face; the splash had retained a fixed 4-point tracking
value at a larger size. `SOURCE/lib/widgets/zyra_splash_artwork.dart` now
scales the header's tracking-to-size ratio (4/18) and fits the result within
compact screens. This applies to the main Quiet Horizon frame and the shared
code-native splash studies. The splash remains gold; the Poppins tagline,
purple gradient, 2400ms motion, 650ms finished hold and app icon are
unchanged. Sentence-level `ZYRA`, such as `Welcome to ZYRA.`, remains
Poppins. Style Default handover §13 and the named 2026-10-01 verification
receipt own file hashes, 88/88 focused checks, scoped clean analyzer, signed
PROFILE build and paired-iPhone install/launch. Founder on-device visual
acceptance remains pending under OA-ZYRA-257 and OA-ZYRA-286. No migration,
backend, credit/payment, TestFlight or Git action occurred. Earlier
locked-device delivery statements below are dated history, not the latest
delivery status.

## Current overlay — 2026-09-30 second finished-hold shortening

After trying the previous 1250ms completed frame, the Founder asked for a
further reduction to **650ms**. The animation itself remains **2400ms**, so
the nominal splash duration is **3050ms**. This is 600ms less still
time than the immediately previous implementation; Quiet Horizon artwork,
brand colours and the protected comparisons are not being redesigned. The
shared `zyraSplashFinishedHoldMilliseconds` constant is now 650ms, so the
production path and protected previews continue to agree. The 1250ms
measurements below are preserved as dated history, not current targets.

The calculated motion fraction is **48/61**. Focused
`flutter test --no-pub test/splash_motion_test.dart
test/dev_splash_directions_test.dart test/welcome_splash_palette_test.dart`
passed **82/82**; adjacent
`flutter test --no-pub test/zyra_startup_routing_test.dart` passed
**14/14**; candidate-only
`flutter test --no-pub test/visual/splash_directions_visual_test.dart`
passed **14/14** with no approved-golden replacement. Combined named
checks passed **110/110**. These local checks do not prove physical-device timing. Scoped
`flutter analyze` on five edited source/test files
reported no issues. The deterministic UI gate report
`SYSTEM/RESOURCES/UI_GATE/REPORTS/ZYRA_UI_AUDIT_2026-09-30_582280e2.md`
is **ATTENTION**: 0 critical / 1 known stale pricing-rule high / 23
medium / 263 low, with 0 new / 0 reopened / 0 resolved findings across
three changed UI files. The existing Founder-only production-flavor iOS
PROFILE build completed in **56.2s** (Runner.app **55.7MB**) with the same
compile-time access definitions. `codesign --verify --deep --strict
--verbose=2 build/ios/iphoneos/Runner.app` passed. Runner executable
SHA-256 is
`3f17324bc22c526c3f17a8489332c1b156c37d6b157b47f4f03b67d7957093eb`;
Dart AOT `App.framework/App` SHA-256 is
`1c5522afd16929b6d3b20fffc34e148f9c648d099a62dec14110a05886617831`.
The same main ZYRA app installed on the Founder's iPhone as database
sequence **5056**. A direct launch attempt was denied solely because the
phone was **locked**. The new binary is installed, but running-screen timing
and Founder acceptance are **not verified**. AuthGate may retain the final
frame while a session resolves, so 3050ms is the nominal splash timing,
not an end-to-end loading guarantee. OA-ZYRA-257 remains open for the
Founder's felt timing acceptance. No TestFlight upload, backend, migration,
payment/credit or Git action occurred.

## Current overlay — 2026-09-30 finished-hold shortening

Founder found the static period after the main splash animation too long
and requested a reduction of 0.5–1.0 seconds. The completed-frame hold is
now **1250ms**, 750ms shorter than the previous 2000ms. The arrival motion
remains **2400ms**, so the normal total is **3650ms**. Production and all
protected splash design studies consume one shared timing definition;
the Quiet Horizon artwork, text, gradient, motion sequence and AuthGate
handoff are otherwise unchanged. The older 4400ms statements below record
their dated as-built state, not the current lifecycle. AuthGate still waits
for both splash completion and session resolution, so a slow session can
extend the final still frame beyond 3650ms. This is not a guaranteed
end-to-end loading deadline.

Focused production/preview motion tests passed **79/79**; Welcome palette,
visual splash and startup-routing suites passed **31/31**. Scoped Dart
analysis/formatting were clean. The deterministic UI gate report
`ZYRA_UI_AUDIT_2026-09-30_cb568e6e.md` has **0 new / 0 reopened /
0 resolved** findings, with its pre-existing stale pricing-rule high still
tracked under OA-ZYRA-257. The same Founder-enabled production-flavor
PROFILE app `app.zyraconnect.zyra` `1.0.0(5)` built in 59.7s (55.6MB),
passed deep/strict signing for Team `9Y7Z8F36SJ`, and installed on the
paired iPhone as sequence **5032** in container
`A50611AB-E7B3-43A1-8C27-CAE9BCF3F259`. Direct launch succeeded and
the new container's Runner process was observed as PID **53348**. Runner
SHA-256 is
`3077f4db23748cfac65d59aacb06d963e118502ef9536faab0e5bcdef4af0635`;
Dart AOT SHA-256 is
`51a4ebf552ea3381c4b5482a441f8b7a4eba73c323a6387860b91be39454c34a`.
This supersedes the previous colour-alignment install sequence 5008; that
dated receipt remains historical. No second app, TestFlight upload, remote
backend, member-data write, payment/credit, migration or Git action. The
named receipt is
`SYSTEM/RESOURCES/REVIEWS/SPLASH_FINISHED_HOLD_2026-09-30_VERIFICATION.json`.
Founder device timing acceptance remains pending; a successful launch
alone does not establish the felt duration.

## Current overlay — 2026-09-30 splash-to-Welcome text-colour alignment

The Founder compared the main splash with the sign-in/Onboarding welcome
screen and selected the **main splash** as the colour authority for both
lockup lines. The actual Quiet Horizon splash already used gold `#E5CE8E`
for **ZYRA** and white at 78% opacity for **Connecting Through Trust**.
Welcome had used opaque white for the wordmark and the ordinary 70%-white
secondary-text colour for the tagline. Shared
`ZyraColors.splashWordmark`/`ZyraColors.splashTagline` now express the
existing splash values, and both ordinary Welcome and the protected local
Onboarding Welcome use them. Splash artwork reads the same tokens, so the
two screens cannot drift through a generic foreground-theme change. The
purple gradient, Syne/Poppins fonts, wording, sizes, positions, provider
buttons, splash timing and AuthGate handoff are unchanged. The toggle's
separate **Original** legacy Bloom + Draw comparison remains untouched.

The focused palette checks cover the settled main splash and both Welcome
routes; the wider splash/signup/no-heart regression passed **168/168**, the
real-font splash-to-Welcome candidate capture passed **18/18** at standard
and compact sizes, and the four normal-auth visual regression geometries
passed **4/4** without approved-golden replacement. Scoped Dart analysis and
formatting found no issues. A final seven-suite post-cleanup run passed
**204/204**, with scoped analyzer/formatter still clean. The candidate images were inspected and show the
same gold/near-white lockup, not a changed splash design. Internal evidence
does not substitute for the Founder's physical-device acceptance.

The final same-bundle Founder-enabled production-flavor PROFILE build
completed in 53.6s (Runner.app 55.6MB). Deep/strict code-signature
verification passed for Team `9Y7Z8F36SJ`; the bundle remains
`app.zyraconnect.zyra` version `1.0.0(5)`. Runner SHA-256 is
`bc1cef7696e17ec94a165910b7ae44098b623e07c3a1b56cf14c2ef4e9604085`
and Dart AOT SHA-256 is
`b45d5a6635fb174721f3d817f8c98c076034eb55b237ccd88be2228798aaa7bd`.
The paired iPhone installed this build as database sequence **5008** in
container `FDFCCD9C-5B88-49B1-A68B-F1E19C1542CC` and reported the expected
version. Direct launch was attempted but iOS denied it because the phone
was **Locked**. Installation is verified; running-screen appearance and
Founder visual acceptance remain unverified. No TestFlight upload, second
app, remote backend, payment/credit, migration or Git action occurred.
Named evidence:
`SYSTEM/RESOURCES/REVIEWS/SPLASH_WELCOME_TEXT_COLOUR_ALIGNMENT_2026-09-30_VERIFICATION.json`.

## Current overlay — 2026-09-27 Quiet Horizon main (OA-ZYRA-257)

Founder selected option **6 · Quiet Horizon** as the main opening while
explicitly retaining every other comparison. `SplashScreen()` now renders
that shared gold-wordmark / quiet-horizon artwork by default on the current
deep-purple `#30203F → #160E20` gradient. Production keeps the canonical
`Connecting Through Trust` tagline; study-only `Connecting with trust` is not
a global messaging change.

Neutral `SOURCE/lib/widgets/zyra_splash_artwork.dart` owns the twelve-direction
enum, artwork frame and preview animation. Production consumes its pure
`ZyraSplashArtworkFrame`, not any developer import or preview timer. Existing
production controller remains exactly **4400ms: 2400ms motion + 2000ms hold**
(`_animFraction = 6 / 11`). Reduced motion resolves artwork immediately but
does not change the completion deadline. AuthGate waits for the same callback
and session resolution; disposal suppresses completion and rebuilding does
not restart launch timing.

Home still offers all twelve comparisons. The former Current is now Original
and explicitly renders legacy Bloom + Draw; Quiet Horizon is marked Main.
Opening, replaying, cycling or closing previews does not reset or refresh
login, store a production choice or bypass existing protected developer
authority. The separate five-motion legacy lab remains available; only its
current/original copy changed. Native flat launch colour and app-icon choice
are unchanged. No backend, migration, Auth write, git or TestFlight action.

Focused combined suite **127 PASS**: production lifecycle/motion, twelve
directions, Home, global overlay, visual harness and app-shell correctness.
Analyzer **7 files PASS**, formatter **7 files / 0 changes**. Two new
font-backed main-design candidate captures at 390×844 and 320×568 were
generated and inspected; **2 PASS**, no approved golden replacement.
The current UI Consistency Gate handover records source hashes and native
delivery evidence. Final fresh main iOS PROFILE/production build PASS65.3s;
signature and bundle identity PASS. Physical iPhone installation PASS
sequence4640, main-bundle launch PASS and post-install version query PASS.
Internal verification and delivery are not Founder visual acceptance.

The following sections preserve the original **2026-08-26 historical**
as-built record. Their Bloom + Draw default, 3.4-second timing and retired
Fable routing do not override this current overlay or AD-AIOS-111.

## 1. Historical as-built state — 2026-08-26

The production cold-start splash uses **Soft Bloom + Centre Draw**:

1. a warm, diffuse gold bloom opens behind the locked ZYRA wordmark;
2. the Z/Y/R/A letter arrival and `Connecting Through Trust` remain unchanged;
3. a short gold line grows symmetrically from its centre beneath the tagline;
4. the bloom and line dissolve before the existing still hold;
5. no travelling dot or joined centre dot remains on the splash.

Founder device review found the selected composition correct but too fast.
The motion phase therefore runs for 2.4 seconds rather than 2.0 seconds. The
final still hold remains 1.0 second, producing a 3.4-second cold-start splash.

The Developer Splash Lab preserves five real-screen comparison directions:

1. Soft Bloom;
2. Centre Draw;
3. Bloom + Draw — production current;
4. Horizon Glow;
5. Light Lift.

`Split Breath` is deliberately absent following the Founder instruction. The
former `Trails Meet` two-dot motion is retired from both production and the
Splash Lab.

## 2. Invariants preserved

- Brand background: current `ZyraColors.brandGradient`; no gender tint.
- Wordmark: locked Syne ZYRA treatment.
- Tagline: `Connecting Through Trust`.
- Total splash ownership: 3.4 seconds.
- Motion phase: first 2.4 seconds (`_animFraction = 12 / 17`).
- Still hold: final 1 second.
- AuthGate ownership, session resolution and 260ms route handoff: unchanged.
- Native launch: flat brand colour with no native wordmark; unchanged.
- `ZyraLoading`: remains a separate, repeatable wait indicator and was not
  changed into the splash motion.

## 3. Architecture and data flow

```text
main.dart
  → AuthGate(playSplash: true)
  → SplashScreen (one 3.4-second AnimationController)
  → normalised 0..1 motion progress
  → ZyraSplashMotionFrame (pure deterministic frame values)
      ├── ZyraSplashBloom behind the wordmark
      └── ZyraSplashDrawRule beneath the tagline
  → AuthGate cross-fades to the already-resolved route
```

`ZyraSplashMotionFrame` owns all timing transforms. Production and Developer
Lab consume the same `SplashScreen` and the same enum; there is no parallel
mock animation. The bloom is `Positioned` behind the wordmark and therefore
does not change measured layout. The line grows from its centre, so it has no
directional or pending-state meaning.

No network request, persistence, profile state, analytics event, database
state or external service participates in the animation.

## 4. Entry points and developer boundary

| Entry | Behaviour | Boundary |
|---|---|---|
| Cold application start | `AuthGate` mounts `SplashScreen()` with production default `bloomDraw` | Production |
| Developer Access → Labs → Splash lab | Lists and replays the five preserved motions using the real `SplashScreen` | Existing protected Developer Access only |
| Loading gaps | Continue to use `ZyraLoading` / Meet and Pass | Production; deliberately separate |

The lab changes no user/account state and stores no choice. Selecting a lab
option does not change the production default.

## 5. Live files and SHA-256 evidence

| File | SHA-256 | Responsibility |
|---|---|---|
| `SOURCE/lib/screens/splash_screen.dart` | `e0332bc4a19880c2c3977b8274f6cb40836448a2caeea300c6afb4e82065fdb1` | Real splash composition, production `bloomDraw` default, 2.4s motion plus 1.0s hold, unchanged AuthGate callback |
| `SOURCE/lib/widgets/zyra_splash_motion.dart` | `8fab5a88b6842701771e88f37a20701d583a1513c1790132578030da6d149aac` | Five dot-free motion directions and deterministic frame model |
| `SOURCE/lib/dev/dev_splash_lab.dart` | `050ec3cc65e05928a71c681ae442fe0e317f47972f01dfb451213e515531a7ef` | Real-screen preview of the five preserved directions; Split Breath absent |
| `SOURCE/lib/screens/dev/developer_access_screen.dart` | `d25c3f5c85e530c7e28af3b12ab219d25cc03134aff9466fc858804eaf0e2549` | Accurate Splash Lab entry copy |
| `SOURCE/lib/widgets/zyra_comet_rule.dart` | `e871f91513bd28d1795d6747a26102b3b172b52c7c62439e1bf85faee134610a` | Historical comet/loading candidates only; retired splash coupling and `trailsMeet` enum member removed |
| `SOURCE/lib/widgets/zyra_meet_and_pass_rule.dart` | `a742c6fff337720b20b204454c514060f9176d7ebac0b48e1240f42692f6efde` | Loading unchanged; now reads shared Journey gold directly rather than importing retired splash code |
| `SOURCE/lib/widgets/zyra_loading.dart` | `3b8525083df5a67a3de78d7e16280c05bd3ec09aaeadbd56d63ad6819664f5c6` | Loading remains distinct after the dot-free splash change; historical ending type renamed without behaviour change |
| `SOURCE/lib/widgets/zyra_full_screen_error.dart` | `8f15c0fab4d1e5ca100a039fb449951990f37fa514204d180059beb796474619` | Error UI unchanged; reads shared Journey gold directly |
| `SOURCE/test/splash_motion_test.dart` | `86e4dd3397f73688b31aee008bc76aa026abc76d0f03a36fda0cce14fbca1cf0` | 3.4s completion boundary, production default and five-option/no-Split contract |

## 6. Retired implementation and lineage

Removed:

- `SOURCE/lib/widgets/zyra_trails_meet_rule.dart` — pre-removal SHA-256
  `7b212390c52d67fb7318c858c525538675265bb5413d13ff287eba52fca726b1`;
  former two-dot inward connector.
- `SOURCE/test/splash_trails_meet_test.dart` — pre-removal SHA-256
  `d5c3196cdfbb4bb796be35988647d6c572448a388952e7d68a0e6e98b8ba3857`;
  superseded by `splash_motion_test.dart`.

The deletion is intentional: leaving the dot painter callable would contradict
the Founder-selected dot-free splash and make the next review ambiguous.
Historical comet code remains only where existing loading alternatives still
consume it; it is not a production splash reader.

## 7. Verification evidence

### Before change

- `flutter test test/splash_trails_meet_test.dart` — **2/2 PASS**. Confirmed
  the replaced default and its existing test baseline.

### During dependency review

- First post-change focused compile truthfully failed because
  `zyra_meet_and_pass_rule.dart` and `zyra_full_screen_error.dart` imported
  the retired splash widget solely for its gold constant.
- Both consumers were moved to the existing shared
  `ZyraColors.journeyGold` token. Their behaviour was not changed.

### Final measurements

- `flutter test --no-pub test/splash_motion_test.dart` — **3/3 PASS**,
  including incomplete at 3.0s and complete immediately beyond 3.4s.
- `flutter analyze` — **PASS, no issues**.
- `flutter test --no-pub --reporter compact` — **404/404 PASS**.
- `flutter build ios --profile --no-codesign` — **PASS**; final Xcode build 35.9s,
  produced `build/ios/iphoneos/Runner.app` (34.3 MB).
- Physical iPhone observation — **PENDING — not yet measured by Founder**.
- SQL/database probes — **none; no database change**.

## 8. Migrations and external changes

None. No migration, schema, RPC, RLS policy, Edge Function, storage policy,
package, credential, provider or external resource changed.

## 9. Known limitations and action disposition

1. **Physical appearance remains pending.** Simulator/build evidence cannot
   decide whether the bloom strength and line timing feel right on the
   Founder's OLED device. Next owner: Founder, using the standard profile
   device run.
2. **Reduced-motion splash behaviour is pre-existing.** The splash still
   always plays, while `ZyraLoading` already honours reduced motion. No OA is
   raised in this cosmetic work because changing cold-start duration/arrival
   semantics is a separate accessibility/product decision outside the
   authorised painter replacement; this handover refuses silent expansion.
3. **Slow-session final-frame behaviour was not changed.** AuthGate's pending
   route branch is outside the approved visual replacement. No OA is raised
   here because no failure was reproduced and this implementation did not
   alter the branch; a separate launch-flow review should own any future test.
4. DR-ZYRA-125/126 contain historical animation/timing wording. This handover
   records measured current code truth rather than silently editing decision
   history. Fable must reconcile citations/indexing; no separate OA is raised
   because documentation reconciliation is already the mandatory handover
   completion step for this work.

No new unresolved runtime defect or migration requirement was introduced.

## 10. Authority map and next steps

| Truth | Authority |
|---|---|
| Brand identity/background/wordmark direction | `BUSINESS/BRAND MESSAGING/ZYRA_BRAND_GUIDELINES_CURRENT_VERSION_V1.md` |
| Splash versus loading and AuthGate handoff | DR-ZYRA-125 and DR-ZYRA-126 |
| Current implementation reality | This handover plus the live files/hashes above |
| Implementation/handover process | `ZYRA_EXECUTION_CURRENT_VERSION_V5.md`; `IMPLEMENTATION_HANDOVER_STANDARD_CURRENT_VERSION_V4.md` |

Ordered next steps:

1. Founder installs the current profile build and observes one cold launch.
2. If approved on device, no code action remains.
3. If another comparison is requested, Developer Access → Splash Lab contains
   the five retained real-screen options; `Split Breath` must not return.
4. Fable verifies the hashes/evidence, reconciles documentation/indexing and
   records handover completion. Codex does not self-approve that gate.

## 11. 2026-08-28 loading-motion comparison amendment

Founder review of the dot-free splash authorised a separate comparison of the
repeatable wait indicator. Splash ownership is unchanged: Soft Bloom + Centre
Draw remains the one-time cold-start motion and the locked ZYRA wordmark is not
drawn or animated by any loader.

The Seeker developer Style door now exposes ten real shared loading motions:

1. Meet & pass;
2. Comet line;
3. Travelling light;
4. Flowing dots;
5. Soft bloom;
6. Centre draw;
7. Bloom + draw;
8. Linked orbit;
9. Constellation; and
10. Ripple bridge.

The first four are retained loading directions and the latter six share one
compact `CustomPainter` footprint. Every option uses one 2.8-second controller
and has a static reduced-motion frame. The Style selector changes every
unpinned `ZyraLoading` immediately for the current developer session; Reset
restores Meet & pass. Release remains pinned to Meet & pass until the Founder
selects a replacement. **FOUNDER DESIGN SELECTION PENDING.**

Current code evidence:

| File | SHA-256 | Responsibility |
|---|---|---|
| `SOURCE/lib/widgets/zyra_loading.dart` | `40dd86f9adc1b10cf777d7da95524fe065ccb636f9927431069dfb63f12ac459` | Ten repeatable geometries, shared session selection, static reduced-motion frames and unchanged release default |
| `SOURCE/lib/dev/zyra_dev_scenario.dart` | `2ed58aebb81c6b7158c3f29f84b2ef2b3763447532d6369b6ec5ecd714efad07` | Session selector and Reset ownership |
| `SOURCE/lib/dev/dev_scenario_panel_v2.dart` | `1c0011bf9be4325e1cc5cf7a78c38f9d8be1de08dfa8b16c50d682a624f9ece5` | Seeker Style control and live loader preview |
| `SOURCE/test/loading_meet_and_pass_test.dart` | `bb89fbb9bf9aec22d12110f0db37b0a91edf2acc42d5b994e10c0012406c12b5` | All ten animated and reduced-motion states, selection and no-wordmark contract |

Measured: loading-focused **6/6 PASS**; combined changed-path **40/40 PASS**;
complete Flutter **577/577 PASS**; analyzer and formatter clean; governed
visual gate **215 variants PASS / BASELINE-PENDING** because no screenshot
baseline may be self-approved. Signed iOS profile build produced a 36.6 MB
`Runner.app`. No migration, package, credential, server state or production
default changed.

## 12. 2026-08-28 all-gold shared-loader palette amendment

Cold-start splash ownership is unchanged: Soft Bloom + Centre Draw remains the
one-time production splash and retains the locked ZYRA wordmark. Repeatable
loading indicators remain a separate system.

All ten shared loading options now use `ZyraColors.journeyGold` (`#E8C98A`)
for both animated and static reduced-motion states. Meet & pass remains the
release and Reset default. No geometry, timing, selector, splash composition
or no-wordmark boundary changed.

| File | SHA-256 |
|---|---|
| `SOURCE/lib/widgets/zyra_loading.dart` | `8fd625580317587597e17f5a8a634b35e508b252f718a42dd74f80bca9c6d797` |
| `SOURCE/lib/widgets/zyra_comet_rule.dart` | `04d2506583accf1688927ac1146142b35b98fca52fb728bf7874f34f0a221177` |
| `SOURCE/test/loading_meet_and_pass_test.dart` | `ff77e1369cbdab10a28575e1598f54e51c091327a42e1a96ddd680d9a1a604bb` |

Measured evidence: loading/icon focused **11/11 PASS**, combined focused
Dashboard/loading/icon **92/92 PASS**, complete Flutter **599/599 PASS**,
analyzer clean, and governed visual gate **219 variants PASS /
BASELINE-PENDING**. No migration, package, credential, server state, release
default or baseline approval changed. Founder device observation remains
pending.
