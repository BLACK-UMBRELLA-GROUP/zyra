# ZYRA VISUAL AUDIT — 2026-08-24 · run b7f4c630

**Verdict:** FAIL  
**Source fingerprint:** `df2c5e04d759f773` · **duration:** 15.7s · **cost:** $0.00 · **AI calls:** 0  
**Governance:** OA-ZYRA-257 · DR-ZYRA-214 · baselines may not update automatically

## Coverage measured

- Render variants executed: **99** across 30 representative fixtures.
- Roles declared: female-seeker, male-seeker, guardian.
- Devices: small, standard, large.
- Candidate screenshots present: 69.
- Approved baselines compared: 0.
- L1 live findings: 159 (critical 0, high 0, medium 14, low 145).
- L2 findings: new 2 · resolved 0.

## Changed inputs

- `lib/dev/dev_scenario_panel_v2.dart`
- `lib/dev/wali_dev_scenario_panel.dart`
- `lib/dev/zyra_dashboard_lab_controls.dart`
- `lib/dev/zyra_dev_scenario.dart`
- `lib/models/zyra_dashboard_lab.dart`
- `lib/screens/home/home_shell.dart`
- `lib/screens/home/seeker_dashboard_screen.dart`
- `lib/screens/wali/wali_dashboard_screen.dart`
- `lib/widgets/zyra_dashboard_experience.dart`
- `test/visual/zyra_visual_regression_test.dart`
- `ZYRA/SYSTEM/RESOURCES/UI_GATE/state_matrix.json`

## Deterministic and render checks

- **PASS — inventory** · 1.61s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_inventory.py`
- **PASS — L1 deterministic gate** · 0.40s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_gate.py --force`
- **PASS — format check** · 1.19s · exit 0 · `dart format --output=none --set-exit-if-changed lib test`
- **PASS — flutter analyze** · 4.12s · exit 0 · `flutter analyze --no-pub`
- **PASS — structural checker self-tests** · 0.05s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 -m unittest tools/test_zyra_check.py`
- **PASS — zyra structural/reference check** · 4.56s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_check.py --quiet`
- **FAIL — visual render and approved-baseline checks** · 1.63s · exit 1 · `flutter test --no-pub test/visual/zyra_visual_regression_test.dart`
- **FAIL — candidate screenshot capture** · 2.00s · exit 1 · `flutter test --no-pub test/visual/zyra_visual_regression_test.dart --update-goldens --dart-define=ZYRA_CAPTURE_CANDIDATES=true`

## Failed-check evidence

### visual render and approved-baseline checks

```text
00:00 +0: loading /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart
00:00 +0 -1: loading /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart [E]
  Failed to load "/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
  dart:io-patch/socket_patch.dart 1216:7                           _NativeSocket.bind
  ===== asynchronous gap ===========================
  dart:io-patch/socket_patch.dart 2163:12                          _RawServerSocket.bind.<fn>
  ===== asynchronous gap ===========================
  dart:io-patch/socket_patch.dart 2483:12                          _ServerSocket.bind.<fn>
  ===== asynchronous gap ===========================
  dart:_http/http_impl.dart 3476:24                                _HttpServer.bind.<fn>
  ===== asynchronous gap ===========================
  package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
  ===== asynchronous gap ===========================
  package:flutter_tools/src/test/flutter_platform.dart 680:51      FlutterPlatform._startTest.<fn>
  ===== asynchronous gap ===========================
  package:flutter_tools/src/base/async_guard.dart 108:24           asyncGuard.<fn>
  
00:00 +0 -1: Some tests failed.

Failing tests:
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: loading /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart
```

### candidate screenshot capture

```text
00:00 +0: loading /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart
00:00 +0 -1: loading /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart [E]
  Failed to load "/Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart": Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0
  dart:io-patch/socket_patch.dart 1216:7                           _NativeSocket.bind
  ===== asynchronous gap ===========================
  dart:io-patch/socket_patch.dart 2163:12                          _RawServerSocket.bind.<fn>
  ===== asynchronous gap ===========================
  dart:io-patch/socket_patch.dart 2483:12                          _ServerSocket.bind.<fn>
  ===== asynchronous gap ===========================
  dart:_http/http_impl.dart 3476:24                                _HttpServer.bind.<fn>
  ===== asynchronous gap ===========================
  package:flutter_tools/src/test/flutter_tester_device.dart 89:15  FlutterTesterTestDevice.start
  ===== asynchronous gap ===========================
  package:flutter_tools/src/test/flutter_platform.dart 680:51      FlutterPlatform._startTest.<fn>
  ===== asynchronous gap ===========================
  package:flutter_tools/src/base/async_guard.dart 108:24           asyncGuard.<fn>
  
00:00 +0 -1: Some tests failed.

Failing tests:
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: loading /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart
```


## Finding ledger

### Open

| Fingerprint | Severity | Screen / state | Role / plan | Device | Evidence | Expected / actual | Impact / correction | Owner | Status / trace |
|---|---|---|---|---|---|---|---|---|---|
| `6ec9fe22add9` | HIGH | UI gate / validation | all / all | all · not applicable | candidate screenshot capture exited 1; command: flutter test --no-pub test/visual/zyra_visual_regression_test.dart --update-goldens --dart-define=ZYRA_CAPTURE_CANDIDATES=true | Expected: candidate screenshot capture passes. Actual: candidate screenshot capture exited 1. | Impact: The UI gate cannot attest this validation layer. Correction: Inspect the permanent failed-check evidence and correct or classify the failure. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 1× |
| `8ed32a7c6733` | HIGH | UI gate / validation | all / all | all · not applicable | visual render and approved-baseline checks exited 1; command: flutter test --no-pub test/visual/zyra_visual_regression_test.dart | Expected: visual render and approved-baseline checks passes. Actual: visual render and approved-baseline checks exited 1. | Impact: The UI gate cannot attest this validation layer. Correction: Inspect the permanent failed-check evidence and correct or classify the failure. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 1× |

### Resolved

- `01508299f69a` Notifications — resolved 2026-08-24 after 2 occurrence(s).
- `240610613908` Application build — resolved 2026-08-24 after 1 occurrence(s).
- `2dec010c5a38` Repository UI source — resolved 2026-08-24 after 5 occurrence(s).
- `62f92a6283eb` Application structure — resolved 2026-08-24 after 5 occurrence(s).
- `7a637737690c` Onboarding — resolved 2026-08-24 after 3 occurrence(s).
- `9d6c8757d105` Application test suite — resolved 2026-08-24 after 1 occurrence(s).
- `9f8da2cab1c6` Notifications — resolved 2026-08-24 after 2 occurrence(s).
- `bdba1d8efaab` Notifications — resolved 2026-08-24 after 2 occurrence(s).
- `ca3609344c56` Application test suite — resolved 2026-08-24 after 1 occurrence(s).
- `ceb76851704e` Subscription/upgrade — resolved 2026-08-24 after 2 occurrence(s).
- `d78555211c79` Subscription/upgrade — resolved 2026-08-24 after 2 occurrence(s).
- `fa5e9531d616` Application test suite — resolved 2026-08-24 after 1 occurrence(s).

## Baseline governance

No approved screenshot baselines exist yet. The PNGs in `test/visual/candidates/` are evidence for review, not design authority.
A changed render cannot replace an approved baseline. Fable checks intent; the Founder approves where required; a new version and full metadata are then filed manually.

## Screen-matrix truth

The matrix lists every required core screen. `render+widget` means a current screenshot fixture exists; `existing-widget+static` means current functional/static coverage exists but a dedicated approved screenshot is still pending. No coverage is overstated.

## Cost and activation

This run used local Python/Dart/Flutter only: $0.00. No overnight schedule was created or enabled. Activation remains blocked on Fable review and Founder baseline approval.
