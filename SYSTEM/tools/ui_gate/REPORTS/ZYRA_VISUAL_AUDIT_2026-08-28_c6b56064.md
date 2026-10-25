# ZYRA VISUAL AUDIT — 2026-08-28 · run c6b56064

**Verdict:** FAIL  
**Source fingerprint:** `226bc7a0d27b527b` · **duration:** 8.0s · **cost:** $0.00 · **AI calls:** 0  
**Governance:** OA-ZYRA-257 · DR-ZYRA-214 · baselines may not update automatically

## Coverage measured

- Render variants executed: **215** across 65 representative fixtures.
- Roles declared: female-seeker, male-seeker, guardian.
- Devices: small, standard, large.
- Candidate screenshots present: 153.
- Approved baselines compared: 0.
- L1 live findings: 168 (critical 0, high 0, medium 15, low 153).
- L2 findings: new 0 · resolved 0.

## Changed inputs

- `lib/dev/dev_scenario_panel_v2.dart`
- `lib/dev/zyra_dev_scenario.dart`
- `lib/dev/zyra_dev_surface_coordinator.dart`
- `lib/dev/zyra_global_dev_overlay.dart`
- `lib/screens/connections/connections_screen.dart`
- `lib/screens/home/home_shell.dart`
- `lib/screens/profile/seeker_profile_screen.dart`
- `lib/widgets/zyra_loading.dart`

## Deterministic and render checks

- **PASS — inventory** · 1.89s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_inventory.py`
- **PASS — L1 deterministic gate** · 0.44s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_gate.py --force`
- **FAIL — format check** · 0.07s · exit 1 · `dart format --output=none --set-exit-if-changed lib test`
- **FAIL — flutter analyze** · 0.05s · exit 1 · `flutter analyze --no-pub`
- **PASS — structural checker self-tests** · 0.05s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 -m unittest tools/test_zyra_check.py`
- **PASS — zyra structural/reference check** · 5.28s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_check.py --quiet`
- **FAIL — visual render and approved-baseline checks** · 0.05s · exit 1 · `flutter test --no-pub test/visual/zyra_visual_regression_test.dart`
- **FAIL — complete Flutter suite** · 0.05s · exit 1 · `flutter test --no-pub`

## Failed-check evidence

### format check

```text
/opt/homebrew/share/flutter/bin/internal/update_engine_version.sh: line 71: /opt/homebrew/share/flutter/bin/cache/engine.stamp.tmp.64891: Operation not permitted
/opt/homebrew/share/flutter/bin/internal/update_engine_version.sh: line 78: /opt/homebrew/share/flutter/bin/cache/engine.realm: Operation not permitted
```

### flutter analyze

```text
/opt/homebrew/share/flutter/bin/internal/update_engine_version.sh: line 71: /opt/homebrew/share/flutter/bin/cache/engine.stamp.tmp.64922: Operation not permitted
/opt/homebrew/share/flutter/bin/internal/update_engine_version.sh: line 78: /opt/homebrew/share/flutter/bin/cache/engine.realm: Operation not permitted
```

### visual render and approved-baseline checks

```text
/opt/homebrew/share/flutter/bin/internal/update_engine_version.sh: line 71: /opt/homebrew/share/flutter/bin/cache/engine.stamp.tmp.64959: Operation not permitted
/opt/homebrew/share/flutter/bin/internal/update_engine_version.sh: line 78: /opt/homebrew/share/flutter/bin/cache/engine.realm: Operation not permitted
```

### complete Flutter suite

```text
/opt/homebrew/share/flutter/bin/internal/update_engine_version.sh: line 71: /opt/homebrew/share/flutter/bin/cache/engine.stamp.tmp.64990: Operation not permitted
/opt/homebrew/share/flutter/bin/internal/update_engine_version.sh: line 78: /opt/homebrew/share/flutter/bin/cache/engine.realm: Operation not permitted
```


## Finding ledger

### Open

| Fingerprint | Severity | Screen / state | Role / plan | Device | Evidence | Expected / actual | Impact / correction | Owner | Status / trace |
|---|---|---|---|---|---|---|---|---|---|
| `240610613908` | CRITICAL | Application build / validation | all / all | all · not applicable | flutter analyze exited 1; command: flutter analyze --no-pub | Expected: Flutter static analysis completes with no errors. Actual: flutter analyze failed. | Impact: The application may not compile or may contain a broken production path. Correction: Resolve analyzer errors before any UI feature or release is marked complete. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 5× |
| `2dec010c5a38` | MEDIUM | Repository UI source / validation | all / all | all · not applicable | format check exited 1; command: dart format --output=none --set-exit-if-changed lib test | Expected: Dart UI and test sources already match the deterministic formatter. Actual: dart format reported files that would change. | Impact: Formatting drift makes review noisier and can conceal meaningful UI changes. Correction: Format the reported files in an owned, reviewable change without altering product intent. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 9× |
| `8ed32a7c6733` | HIGH | UI gate / validation | all / all | all · not applicable | visual render and approved-baseline checks exited 1; command: flutter test --no-pub test/visual/zyra_visual_regression_test.dart | Expected: visual render and approved-baseline checks passes. Actual: visual render and approved-baseline checks exited 1. | Impact: The UI gate cannot attest this validation layer. Correction: Inspect the permanent failed-check evidence and correct or classify the failure. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 5× |
| `e06ad7a98058` | CRITICAL | Application test suite / validation | all / all | all · not applicable | complete Flutter suite exited 1; command: flutter test --no-pub | Expected: The complete Flutter suite passes. Actual: One or more Flutter tests failed. | Impact: A functional regression may exist beyond visual appearance. Correction: Resolve or explicitly classify each failing test before release. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 2× |

### Resolved

- `01508299f69a` Notifications — resolved 2026-08-24 after 2 occurrence(s).
- `62f92a6283eb` Application structure — resolved 2026-08-24 after 5 occurrence(s).
- `6ec9fe22add9` UI gate — resolved 2026-08-25 after 2 occurrence(s).
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
