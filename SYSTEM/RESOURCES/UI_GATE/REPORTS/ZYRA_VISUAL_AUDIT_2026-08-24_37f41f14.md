# ZYRA VISUAL AUDIT — 2026-08-24 · run 37f41f14

**Verdict:** BASELINE-PENDING  
**Source fingerprint:** `df2c5e04d759f773` · **duration:** 23.0s · **cost:** $0.00 · **AI calls:** 0  
**Governance:** OA-ZYRA-257 · DR-ZYRA-214 · baselines may not update automatically

## Coverage measured

- Render variants executed: **99** across 30 representative fixtures.
- Roles declared: female-seeker, male-seeker, guardian.
- Devices: small, standard, large.
- Candidate screenshots present: 99.
- Approved baselines compared: 0.
- L1 live findings: 159 (critical 0, high 0, medium 14, low 145).
- L2 findings: new 0 · resolved 2.

## Changed inputs

- Forced audit; no fingerprint delta was required.

## Deterministic and render checks

- **PASS — inventory** · 1.60s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_inventory.py`
- **PASS — L1 deterministic gate** · 0.40s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_gate.py --force`
- **PASS — format check** · 1.11s · exit 0 · `dart format --output=none --set-exit-if-changed lib test`
- **PASS — flutter analyze** · 3.53s · exit 0 · `flutter analyze --no-pub`
- **PASS — structural checker self-tests** · 0.04s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 -m unittest tools/test_zyra_check.py`
- **PASS — zyra structural/reference check** · 4.79s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_check.py --quiet`
- **PASS — visual render and approved-baseline checks** · 5.10s · exit 0 · `flutter test --no-pub test/visual/zyra_visual_regression_test.dart`
- **PASS — candidate screenshot capture** · 6.37s · exit 0 · `flutter test --no-pub test/visual/zyra_visual_regression_test.dart --update-goldens --dart-define=ZYRA_CAPTURE_CANDIDATES=true`

## Finding ledger

No open L2 findings.

### Resolved

- `01508299f69a` Notifications — resolved 2026-08-24 after 2 occurrence(s).
- `240610613908` Application build — resolved 2026-08-24 after 1 occurrence(s).
- `2dec010c5a38` Repository UI source — resolved 2026-08-24 after 5 occurrence(s).
- `62f92a6283eb` Application structure — resolved 2026-08-24 after 5 occurrence(s).
- `6ec9fe22add9` UI gate — resolved 2026-08-24 after 1 occurrence(s).
- `7a637737690c` Onboarding — resolved 2026-08-24 after 3 occurrence(s).
- `8ed32a7c6733` UI gate — resolved 2026-08-24 after 1 occurrence(s).
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
