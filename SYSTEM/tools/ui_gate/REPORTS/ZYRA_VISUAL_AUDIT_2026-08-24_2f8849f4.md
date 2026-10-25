# ZYRA VISUAL AUDIT — 2026-08-24 · run 2f8849f4

**Verdict:** FAIL  
**Source fingerprint:** `5a757ea20973825b` · **duration:** 30.7s · **cost:** $0.00 · **AI calls:** 0  
**Governance:** OA-ZYRA-257 · DR-ZYRA-214 · baselines may not update automatically

## Coverage measured

- Render variants executed: **44** across 12 representative fixtures.
- Roles declared: female-seeker, male-seeker, guardian.
- Devices: small, standard, large.
- Candidate screenshots present: 44.
- Approved baselines compared: 0.
- L1 live findings: 153 (critical 0, high 0, medium 13, low 140).
- L2 findings: new 1 · resolved 1.

## Changed inputs

- `pubspec.yaml`
- `test/visual/zyra_visual_regression_test.dart`

## Deterministic and render checks

- **PASS — inventory** · 1.49s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_inventory.py`
- **PASS — L1 deterministic gate** · 0.38s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_gate.py --force`
- **FAIL — format check** · 1.03s · exit 1 · `dart format --output=none --set-exit-if-changed lib test`
- **FAIL — flutter analyze** · 3.21s · exit 1 · `flutter analyze --no-pub`
- **FAIL — zyra structural/reference check** · 4.22s · exit 1 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_check.py --quiet`
- **PASS — visual render and approved-baseline checks** · 3.92s · exit 0 · `flutter test --no-pub test/visual/zyra_visual_regression_test.dart`
- **PASS — candidate screenshot capture** · 3.81s · exit 0 · `flutter test --no-pub test/visual/zyra_visual_regression_test.dart --update-goldens --dart-define=ZYRA_CAPTURE_CANDIDATES=true`
- **PASS — complete Flutter suite** · 12.60s · exit 0 · `flutter test --no-pub`

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

### flutter analyze

```text
Analyzing SOURCE...                                             

   info • The import of 'dart:typed_data' is unnecessary because all of the used elements are also provided by the import of 'package:flutter/services.dart'. Try removing the import directive • test/visual/zyra_visual_regression_test.dart:3:8 • unnecessary_import

1 issue found. (ran in 2.6s)
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


## Finding ledger

### Open

| Fingerprint | Severity | Screen / state | Role / plan | Device | Evidence | Expected / actual | Impact / correction | Owner | Status / trace |
|---|---|---|---|---|---|---|---|---|---|
| `240610613908` | CRITICAL | Application build / validation | all / all | all · not applicable | flutter analyze exited 1; command: flutter analyze --no-pub | Expected: Flutter static analysis completes with no errors. Actual: flutter analyze failed. | Impact: The application may not compile or may contain a broken production path. Correction: Resolve analyzer errors before any UI feature or release is marked complete. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 1× |
| `2dec010c5a38` | MEDIUM | Repository UI source / validation | all / all | all · not applicable | format check exited 1; command: dart format --output=none --set-exit-if-changed lib test | Expected: Dart UI and test sources already match the deterministic formatter. Actual: dart format reported files that would change. | Impact: Formatting drift makes review noisier and can conceal meaningful UI changes. Correction: Format the reported files in an owned, reviewable change without altering product intent. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 4× |
| `62f92a6283eb` | HIGH | Application structure / validation | all / all | all · not applicable | zyra structural/reference check exited 1; command: /Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_check.py --quiet | Expected: ZYRA's structural/reference contract passes for current sources. Actual: The structural/reference checker reported unresolved references or contract drift. | Impact: Reference drift can leave stale architecture, invalid calls or misleading validation evidence. Correction: Review each reported site against analyzer truth and the current architecture; fix source or checker false positives explicitly. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 4× |

### Resolved

- `01508299f69a` Notifications — resolved 2026-08-24 after 2 occurrence(s).
- `7a637737690c` Onboarding — resolved 2026-08-24 after 2 occurrence(s).
- `9d6c8757d105` Visual fixture — resolved 2026-08-24 after 1 occurrence(s).
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
