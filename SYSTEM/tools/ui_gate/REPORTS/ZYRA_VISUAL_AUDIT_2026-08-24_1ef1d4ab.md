# ZYRA VISUAL AUDIT — 2026-08-24 · run 1ef1d4ab

**Verdict:** FAIL  
**Source fingerprint:** `4eb122d3a601c50d` · **duration:** 27.8s · **cost:** $0.00 · **AI calls:** 0  
**Governance:** OA-ZYRA-257 · DR-ZYRA-214 · baselines may not update automatically

## Coverage measured

- Render variants executed: **48** across 13 representative fixtures.
- Roles declared: female-seeker, male-seeker, guardian.
- Devices: small, standard, large.
- Candidate screenshots present: 44.
- Approved baselines compared: 0.
- L1 live findings: 153 (critical 0, high 0, medium 13, low 140).
- L2 findings: new 2 · resolved 0.

## Changed inputs

- `assets/fonts/Poppins-Bold.ttf`
- `assets/fonts/Poppins-ExtraLight.ttf`
- `assets/fonts/Poppins-Light.ttf`
- `assets/fonts/Poppins-Medium.ttf`
- `assets/fonts/Poppins-OFL.txt`
- `assets/fonts/Poppins-Regular.ttf`
- `assets/fonts/Poppins-SemiBold.ttf`
- `lib/dev/zyra_dev_control_system.dart`
- `lib/main.dart`
- `lib/theme/zyra_colors.dart`
- `lib/theme/zyra_text.dart`
- `pubspec.yaml`
- `test/visual/zyra_visual_regression_test.dart`

## Deterministic and render checks

- **PASS — inventory** · 1.52s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_inventory.py`
- **PASS — L1 deterministic gate** · 0.39s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_gate.py --force`
- **PASS — format check** · 1.08s · exit 0 · `dart format --output=none --set-exit-if-changed lib test`
- **PASS — flutter analyze** · 3.66s · exit 0 · `flutter analyze --no-pub`
- **PASS — structural checker self-tests** · 0.06s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 -m unittest tools/test_zyra_check.py`
- **PASS — zyra structural/reference check** · 4.66s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_check.py --quiet`
- **FAIL — visual render and approved-baseline checks** · 3.60s · exit 1 · `flutter test --no-pub test/visual/zyra_visual_regression_test.dart`
  - Failed cases: `onboarding-intro__small renders without overflow or exceptions`
- **FAIL — complete Flutter suite** · 12.75s · exit 1 · `flutter test --no-pub`
  - Failed cases: `onboarding-intro__small renders without overflow or exceptions`; `records one explicit preference for every answer option`

## Failed-check evidence

### visual render and approved-baseline checks

```text
00:00 +18 -1: notifications-error__large renders without overflow or exceptions
00:00 +19 -1: subscription-upgrade__small renders without overflow or exceptions
00:00 +20 -1: subscription-upgrade__standard renders without overflow or exceptions
00:00 +21 -1: subscription-upgrade__large renders without overflow or exceptions
00:00 +22 -1: subscription-upgrade__standard__text-130 renders without overflow or exceptions
00:01 +23 -1: guardian-network-locked__small renders without overflow or exceptions
00:01 +24 -1: guardian-network-locked__standard renders without overflow or exceptions
00:01 +25 -1: guardian-network-locked__large renders without overflow or exceptions
00:01 +26 -1: guardian-network-locked__standard__text-130 renders without overflow or exceptions
00:01 +27 -1: guardian-network-unlinked__small renders without overflow or exceptions
00:01 +28 -1: guardian-network-unlinked__standard renders without overflow or exceptions
00:01 +29 -1: guardian-network-unlinked__large renders without overflow or exceptions
00:01 +30 -1: guardian-network-unavailable__small renders without overflow or exceptions
00:01 +31 -1: guardian-network-unavailable__standard renders without overflow or exceptions
00:01 +32 -1: guardian-network-unavailable__large renders without overflow or exceptions
00:01 +33 -1: shared-loading__small renders without overflow or exceptions
00:01 +34 -1: shared-loading__standard renders without overflow or exceptions
00:01 +35 -1: shared-loading__large renders without overflow or exceptions
00:01 +36 -1: shared-error__small renders without overflow or exceptions
00:01 +37 -1: shared-error__standard renders without overflow or exceptions
00:01 +38 -1: shared-error__large renders without overflow or exceptions
00:01 +39 -1: shared-error__standard__text-130 renders without overflow or exceptions
00:01 +40 -1: shared-empty-long-copy__small renders without overflow or exceptions
00:01 +41 -1: shared-empty-long-copy__standard renders without overflow or exceptions
00:01 +42 -1: shared-empty-long-copy__large renders without overflow or exceptions
00:01 +43 -1: shared-empty-long-copy__standard__text-130 renders without overflow or exceptions
00:01 +44 -1: guardian-slider-six-seekers__small renders without overflow or exceptions
00:01 +45 -1: guardian-slider-six-seekers__standard renders without overflow or exceptions
00:01 +46 -1: guardian-slider-six-seekers__large renders without overflow or exceptions
00:01 +47 -1: guardian-slider-six-seekers__standard__text-130 renders without overflow or exceptions
00:01 +48 -1: (tearDownAll)
00:01 +48 -1: Some tests failed.

Failing tests:
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: onboarding-intro__small renders without overflow or exceptions
```

### complete Flutter suite

```text
00:09 +207 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:09 +208 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:09 +209 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:09 +210 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:09 +211 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:09 +212 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:09 +213 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:09 +214 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:09 +215 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:09 +216 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:09 +217 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:09 +218 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:09 +219 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:09 +219 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: shared Seeker slider drags and keeps all ten Seekers reachable
[GN-ANALYTICS] seeker_selected · dev-ws1
00:09 +220 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: shared Seeker slider drags and keeps all ten Seekers reachable
00:09 +221 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: shared Seeker slider drags and keeps all ten Seekers reachable
[GN-ANALYTICS] seeker_selected · dev-ws9
00:09 +222 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: notification explainer provides not-now and permanent decline
00:09 +223 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: Seeker slider writes the shared GNContext and moves the page
00:09 +224 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: Seeker slider writes the shared GNContext and moves the page
[GN-ANALYTICS] seeker_selected · dev-ws2
00:10 +225 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: current GNScene edge states are reachable through GNContext
00:10 +226 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: Set aside updates only the shared preview state and advances
[GN-ANALYTICS] set_aside · fam-h
00:10 +227 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: Guardian Network four-state matrix fits narrow and standard
00:10 +228 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: Guardian+ explanation appears only after a user tap
00:10 +229 -2: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: GNContext reset clears selection, scene, stages and analytics
[GN-ANALYTICS] seeker_selected · dev-ws2
[GN-ANALYTICS] request_sent · fam-h
00:10 +230 -2: Some tests failed.

Failing tests:
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/traffic_light_question_screen_test.dart: records one explicit preference for every answer option
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: onboarding-intro__small renders without overflow or exceptions
```


## Finding ledger

### Open

| Fingerprint | Severity | Screen / state | Role / plan | Device | Evidence | Expected / actual | Impact / correction | Owner | Status / trace |
|---|---|---|---|---|---|---|---|---|---|
| `7a637737690c` | HIGH | Onboarding / normal | male-seeker / basic | small · normal text | Flutter render case failed: onboarding-intro__small renders without overflow or exceptions | Expected: The representative screen renders within its device bounds with no Flutter layout exception. Actual: The render produced an overflow or another layout exception; candidate evidence was retained and not approved. | Impact: Content can clip, overlap or become unusable for the represented device/state. Correction: Inspect the named screen and shared component at this device width, correct the responsive layout, then rerun the same fixture. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 3× |
| `ca3609344c56` | CRITICAL | Application test suite / functional validation | all / all | representative · as declared by test | Flutter test case failed: onboarding-intro__small renders without overflow or exceptions | Expected: The named functional/widget test passes alongside the visual suite. Actual: The named case failed during the complete Flutter suite. | Impact: A functional regression or nondeterministic test boundary may exist beyond visual appearance. Correction: Reproduce the named test in isolation and with the full suite, then fix the product defect or test isolation boundary. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 1× |
| `fa5e9531d616` | CRITICAL | Application test suite / functional validation | all / all | representative · as declared by test | Flutter test case failed: records one explicit preference for every answer option | Expected: The named functional/widget test passes alongside the visual suite. Actual: The named case failed during the complete Flutter suite. | Impact: A functional regression or nondeterministic test boundary may exist beyond visual appearance. Correction: Reproduce the named test in isolation and with the full suite, then fix the product defect or test isolation boundary. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 1× |

### Resolved

- `01508299f69a` Notifications — resolved 2026-08-24 after 2 occurrence(s).
- `240610613908` Application build — resolved 2026-08-24 after 1 occurrence(s).
- `2dec010c5a38` Repository UI source — resolved 2026-08-24 after 5 occurrence(s).
- `62f92a6283eb` Application structure — resolved 2026-08-24 after 5 occurrence(s).
- `9d6c8757d105` Application test suite — resolved 2026-08-24 after 1 occurrence(s).
- `9f8da2cab1c6` Notifications — resolved 2026-08-24 after 2 occurrence(s).
- `bdba1d8efaab` Notifications — resolved 2026-08-24 after 2 occurrence(s).
- `ceb76851704e` Subscription/upgrade — resolved 2026-08-24 after 2 occurrence(s).
- `d78555211c79` Subscription/upgrade — resolved 2026-08-24 after 2 occurrence(s).

## Baseline governance

No approved screenshot baselines exist yet. The PNGs in `test/visual/candidates/` are evidence for review, not design authority.
A changed render cannot replace an approved baseline. Fable checks intent; the Founder approves where required; a new version and full metadata are then filed manually.

## Screen-matrix truth

The matrix lists every required core screen. `render+widget` means a current screenshot fixture exists; `existing-widget+static` means current functional/static coverage exists but a dedicated approved screenshot is still pending. No coverage is overstated.

## Cost and activation

This run used local Python/Dart/Flutter only: $0.00. No overnight schedule was created or enabled. Activation remains blocked on Fable review and Founder baseline approval.
