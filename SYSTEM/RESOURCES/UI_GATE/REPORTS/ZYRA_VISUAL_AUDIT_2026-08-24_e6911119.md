# ZYRA VISUAL AUDIT — 2026-08-24 · run e6911119

**Verdict:** FAIL  
**Source fingerprint:** `3a67cfa6fe538304` · **duration:** 30.1s · **cost:** $0.00 · **AI calls:** 0  
**Governance:** OA-ZYRA-257 · DR-ZYRA-214 · baselines may not update automatically

## Coverage measured

- Render variants executed: **44** across 12 representative fixtures.
- Roles declared: female-seeker, male-seeker, guardian.
- Devices: small, standard, large.
- Candidate screenshots present: 44.
- Approved baselines compared: 0.
- L1 live findings: 153 (critical 0, high 0, medium 13, low 140).
- L2 findings: new 0 · resolved 0.

## Changed inputs

- Forced audit; no fingerprint delta was required.

## Deterministic and render checks

- **PASS — inventory** · 1.49s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_inventory.py`
- **PASS — L1 deterministic gate** · 0.38s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_gate.py --force`
- **FAIL — format check** · 1.05s · exit 1 · `dart format --output=none --set-exit-if-changed lib test`
- **PASS — flutter analyze** · 3.03s · exit 0 · `flutter analyze --no-pub`
- **FAIL — zyra structural/reference check** · 4.18s · exit 1 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_check.py --quiet`
- **FAIL — visual render and approved-baseline checks** · 3.55s · exit 1 · `flutter test --no-pub test/visual/zyra_visual_regression_test.dart`
  - Failed cases: `notifications-empty__small renders without overflow or exceptions`; `notifications-empty__standard__text-130 renders without overflow or exceptions`; `notifications-error__small renders without overflow or exceptions`; `onboarding-intro__small renders without overflow or exceptions`; `subscription-upgrade__large renders without overflow or exceptions`; `subscription-upgrade__standard renders without overflow or exceptions`
- **FAIL — candidate screenshot capture** · 3.79s · exit 1 · `flutter test --no-pub test/visual/zyra_visual_regression_test.dart --update-goldens --dart-define=ZYRA_CAPTURE_CANDIDATES=true`
  - Failed cases: `notifications-empty__small renders without overflow or exceptions`; `notifications-empty__standard__text-130 renders without overflow or exceptions`; `notifications-error__small renders without overflow or exceptions`; `onboarding-intro__small renders without overflow or exceptions`; `subscription-upgrade__large renders without overflow or exceptions`; `subscription-upgrade__standard renders without overflow or exceptions`
- **FAIL — complete Flutter suite** · 12.59s · exit 1 · `flutter test --no-pub`
  - Failed cases: `notifications-empty__small renders without overflow or exceptions`; `notifications-empty__standard__text-130 renders without overflow or exceptions`; `notifications-error__small renders without overflow or exceptions`; `onboarding-intro__small renders without overflow or exceptions`; `subscription-upgrade__large renders without overflow or exceptions`; `subscription-upgrade__standard renders without overflow or exceptions`

## Failed-check evidence

### format check

```text
Changed lib/screens/chat/chat_screen.dart
Changed lib/screens/dev/developer_access_screen.dart
Changed lib/screens/onboarding/bio_onboarding_flow.dart
Changed lib/screens/onboarding/chapter2_flow.dart
Changed lib/screens/profile/edit_profile_screen.dart
Changed lib/screens/settings/help_support_screen.dart
Changed lib/screens/settings/notification_settings_screen.dart
Changed lib/screens/subscription/upgrade_screen.dart
Changed lib/screens/wali/accept_guardian_invite_screen.dart
Changed lib/screens/wali/wali_journey_detail_screen.dart
Changed lib/widgets/onboarding_scaffold.dart
Changed lib/widgets/report_profile_sheet.dart
Changed test/decision_model_test.dart
Formatted 193 files (13 changed) in 0.93 seconds.
```

### zyra structural/reference check

```text
MISSING MEMBER  (2)
    lib/services/zyra_journey_service.dart:1251  PausedLimitReachedException.new is not declared on PausedLimitReachedException
    lib/services/zyra_journey_service.dart:1252  SuspensionRequiresOneException.new is not declared on SuspensionRequiresOneException

  BAD NAMED ARG  (3)
    lib/dev/zyra_page_preview_screen.dart:24  ZyraPagePreviewScreen._(...) got 'groups:' which it does not declare

  UNUSED IMPORT  (1)
    lib/screens/journey/journey_flow_screen.dart:60  '../../models/zyra_gender.dart' — nothing from it is referenced
```

### visual render and approved-baseline checks

```text
00:01 +13 -6: subscription-upgrade__standard__text-130 renders without overflow or exceptions
00:01 +14 -6: guardian-network-locked__small renders without overflow or exceptions
00:01 +15 -6: guardian-network-locked__standard renders without overflow or exceptions
00:01 +16 -6: guardian-network-locked__large renders without overflow or exceptions
00:01 +17 -6: guardian-network-locked__standard__text-130 renders without overflow or exceptions
00:01 +18 -6: guardian-network-unlinked__small renders without overflow or exceptions
00:01 +19 -6: guardian-network-unlinked__standard renders without overflow or exceptions
00:01 +20 -6: guardian-network-unlinked__large renders without overflow or exceptions
00:01 +21 -6: guardian-network-unavailable__small renders without overflow or exceptions
00:01 +22 -6: guardian-network-unavailable__standard renders without overflow or exceptions
00:01 +23 -6: guardian-network-unavailable__large renders without overflow or exceptions
00:01 +24 -6: shared-loading__small renders without overflow or exceptions
00:01 +25 -6: shared-loading__standard renders without overflow or exceptions
00:01 +26 -6: shared-loading__large renders without overflow or exceptions
00:01 +27 -6: shared-error__small renders without overflow or exceptions
00:01 +28 -6: shared-error__standard renders without overflow or exceptions
00:01 +29 -6: shared-error__large renders without overflow or exceptions
00:01 +30 -6: shared-error__standard__text-130 renders without overflow or exceptions
00:01 +31 -6: shared-empty-long-copy__small renders without overflow or exceptions
00:01 +32 -6: shared-empty-long-copy__standard renders without overflow or exceptions
00:01 +33 -6: shared-empty-long-copy__large renders without overflow or exceptions
00:01 +34 -6: shared-empty-long-copy__standard__text-130 renders without overflow or exceptions
00:01 +35 -6: guardian-slider-six-seekers__small renders without overflow or exceptions
00:01 +36 -6: guardian-slider-six-seekers__standard renders without overflow or exceptions
00:01 +37 -6: guardian-slider-six-seekers__large renders without overflow or exceptions
00:01 +38 -6: guardian-slider-six-seekers__standard__text-130 renders without overflow or exceptions
00:01 +39 -6: (tearDownAll)
00:01 +39 -6: Some tests failed.

Failing tests:
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: notifications-empty__small renders without overflow or exceptions
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: notifications-empty__standard__text-130 renders without overflow or exceptions
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: notifications-error__small renders without overflow or exceptions
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: onboarding-intro__small renders without overflow or exceptions
  ... and 2 more
```

### candidate screenshot capture

```text
00:01 +13 -6: subscription-upgrade__standard__text-130 renders without overflow or exceptions
00:01 +14 -6: guardian-network-locked__small renders without overflow or exceptions
00:01 +15 -6: guardian-network-locked__standard renders without overflow or exceptions
00:01 +16 -6: guardian-network-locked__large renders without overflow or exceptions
00:01 +17 -6: guardian-network-locked__standard__text-130 renders without overflow or exceptions
00:01 +18 -6: guardian-network-unlinked__small renders without overflow or exceptions
00:01 +19 -6: guardian-network-unlinked__standard renders without overflow or exceptions
00:01 +20 -6: guardian-network-unlinked__large renders without overflow or exceptions
00:01 +21 -6: guardian-network-unavailable__small renders without overflow or exceptions
00:01 +22 -6: guardian-network-unavailable__standard renders without overflow or exceptions
00:01 +23 -6: guardian-network-unavailable__large renders without overflow or exceptions
00:01 +24 -6: shared-loading__small renders without overflow or exceptions
00:01 +25 -6: shared-loading__standard renders without overflow or exceptions
00:01 +26 -6: shared-loading__large renders without overflow or exceptions
00:01 +27 -6: shared-error__small renders without overflow or exceptions
00:01 +28 -6: shared-error__standard renders without overflow or exceptions
00:01 +29 -6: shared-error__large renders without overflow or exceptions
00:01 +30 -6: shared-error__standard__text-130 renders without overflow or exceptions
00:01 +31 -6: shared-empty-long-copy__small renders without overflow or exceptions
00:01 +32 -6: shared-empty-long-copy__standard renders without overflow or exceptions
00:01 +33 -6: shared-empty-long-copy__large renders without overflow or exceptions
00:01 +34 -6: shared-empty-long-copy__standard__text-130 renders without overflow or exceptions
00:01 +35 -6: guardian-slider-six-seekers__small renders without overflow or exceptions
00:01 +36 -6: guardian-slider-six-seekers__standard renders without overflow or exceptions
00:01 +37 -6: guardian-slider-six-seekers__large renders without overflow or exceptions
00:01 +38 -6: guardian-slider-six-seekers__standard__text-130 renders without overflow or exceptions
00:01 +39 -6: (tearDownAll)
00:01 +39 -6: Some tests failed.

Failing tests:
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: notifications-empty__small renders without overflow or exceptions
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: notifications-empty__standard__text-130 renders without overflow or exceptions
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: notifications-error__small renders without overflow or exceptions
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: onboarding-intro__small renders without overflow or exceptions
  ... and 2 more
```

### complete Flutter suite

```text
00:10 +198 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +199 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +200 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +201 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +202 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +203 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +204 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +205 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +206 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:10 +207 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:10 +207 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: shared Seeker slider drags and keeps all ten Seekers reachable
[GN-ANALYTICS] seeker_selected · dev-ws1
[GN-ANALYTICS] seeker_selected · dev-ws9
00:10 +208 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:10 +209 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: Seeker slider writes the shared GNContext and moves the page
[GN-ANALYTICS] seeker_selected · dev-ws2
00:10 +210 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: plan opens only after the member taps the explicit action
00:10 +211 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: current GNScene edge states are reachable through GNContext
00:10 +212 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: current GNScene edge states are reachable through GNContext
00:10 +213 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: developer reset clears event evidence
00:10 +214 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: Set aside updates only the shared preview state and advances
[GN-ANALYTICS] set_aside · fam-h
00:10 +215 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: Guardian Network four-state matrix fits narrow and standard
00:10 +216 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: Guardian+ explanation appears only after a user tap
00:10 +217 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: GNContext reset clears selection, scene, stages and analytics
[GN-ANALYTICS] seeker_selected · dev-ws2
[GN-ANALYTICS] request_sent · fam-h
00:10 +218 -6: Some tests failed.

Failing tests:
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: notifications-empty__small renders without overflow or exceptions
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: notifications-empty__standard__text-130 renders without overflow or exceptions
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: notifications-error__small renders without overflow or exceptions
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: onboarding-intro__small renders without overflow or exceptions
  ... and 2 more
```


## Finding ledger

### Open

| Fingerprint | Severity | Screen / state | Role / plan | Device | Evidence | Expected / actual | Impact / correction | Owner | Status / trace |
|---|---|---|---|---|---|---|---|---|---|
| `01508299f69a` | HIGH | Notifications / error | guardian / zyra-one | small · normal text | Flutter render case failed: notifications-error__small renders without overflow or exceptions | Expected: The representative screen renders within its device bounds with no Flutter layout exception. Actual: The render produced an overflow or another layout exception; candidate evidence was retained and not approved. | Impact: Content can clip, overlap or become unusable for the represented device/state. Correction: Inspect the named screen and shared component at this device width, correct the responsive layout, then rerun the same fixture. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 2× |
| `2dec010c5a38` | MEDIUM | Repository UI source / validation | all / all | all · not applicable | format check exited 1; command: dart format --output=none --set-exit-if-changed lib test | Expected: Dart UI and test sources already match the deterministic formatter. Actual: dart format reported files that would change. | Impact: Formatting drift makes review noisier and can conceal meaningful UI changes. Correction: Format the reported files in an owned, reviewable change without altering product intent. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 2× |
| `62f92a6283eb` | HIGH | Application structure / validation | all / all | all · not applicable | zyra structural/reference check exited 1; command: /Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_check.py --quiet | Expected: ZYRA's structural/reference contract passes for current sources. Actual: The structural/reference checker reported unresolved references or contract drift. | Impact: Reference drift can leave stale architecture, invalid calls or misleading validation evidence. Correction: Review each reported site against analyzer truth and the current architecture; fix source or checker false positives explicitly. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 2× |
| `7a637737690c` | HIGH | Onboarding / normal | male-seeker / basic | small · normal text | Flutter render case failed: onboarding-intro__small renders without overflow or exceptions | Expected: The representative screen renders within its device bounds with no Flutter layout exception. Actual: The render produced an overflow or another layout exception; candidate evidence was retained and not approved. | Impact: Content can clip, overlap or become unusable for the represented device/state. Correction: Inspect the named screen and shared component at this device width, correct the responsive layout, then rerun the same fixture. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 2× |
| `9f8da2cab1c6` | HIGH | Notifications / empty | female-seeker / basic | standard · 130% text | Flutter render case failed: notifications-empty__standard__text-130 renders without overflow or exceptions | Expected: The representative screen renders within its device bounds with no Flutter layout exception. Actual: The render produced an overflow or another layout exception; candidate evidence was retained and not approved. | Impact: Content can clip, overlap or become unusable for the represented device/state. Correction: Inspect the named screen and shared component at this device width, correct the responsive layout, then rerun the same fixture. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 2× |
| `bdba1d8efaab` | HIGH | Notifications / empty | female-seeker / basic | small · normal text | Flutter render case failed: notifications-empty__small renders without overflow or exceptions | Expected: The representative screen renders within its device bounds with no Flutter layout exception. Actual: The render produced an overflow or another layout exception; candidate evidence was retained and not approved. | Impact: Content can clip, overlap or become unusable for the represented device/state. Correction: Inspect the named screen and shared component at this device width, correct the responsive layout, then rerun the same fixture. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 2× |
| `ceb76851704e` | HIGH | Subscription/upgrade / upgrade | male-seeker / basic | large · normal text | Flutter render case failed: subscription-upgrade__large renders without overflow or exceptions | Expected: The representative screen renders within its device bounds with no Flutter layout exception. Actual: The render produced an overflow or another layout exception; candidate evidence was retained and not approved. | Impact: Content can clip, overlap or become unusable for the represented device/state. Correction: Inspect the named screen and shared component at this device width, correct the responsive layout, then rerun the same fixture. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 2× |
| `d78555211c79` | HIGH | Subscription/upgrade / upgrade | male-seeker / basic | standard · normal text | Flutter render case failed: subscription-upgrade__standard renders without overflow or exceptions | Expected: The representative screen renders within its device bounds with no Flutter layout exception. Actual: The render produced an overflow or another layout exception; candidate evidence was retained and not approved. | Impact: Content can clip, overlap or become unusable for the represented device/state. Correction: Inspect the named screen and shared component at this device width, correct the responsive layout, then rerun the same fixture. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 2× |

### Resolved

No L2 findings resolved in the current ledger yet.

## Baseline governance

No approved screenshot baselines exist yet. The PNGs in `test/visual/candidates/` are evidence for review, not design authority.
A changed render cannot replace an approved baseline. Fable checks intent; the Founder approves where required; a new version and full metadata are then filed manually.

## Screen-matrix truth

The matrix lists every required core screen. `render+widget` means a current screenshot fixture exists; `existing-widget+static` means current functional/static coverage exists but a dedicated approved screenshot is still pending. No coverage is overstated.

## Cost and activation

This run used local Python/Dart/Flutter only: $0.00. No overnight schedule was created or enabled. Activation remains blocked on Fable review and Founder baseline approval.
