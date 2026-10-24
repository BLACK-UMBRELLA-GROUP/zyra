# ZYRA VISUAL AUDIT — 2026-08-24 · run 4979682c

**Verdict:** BASELINE-PENDING  
**Source fingerprint:** `408f6cf300091e03` · **duration:** 31.6s · **cost:** $0.00 · **AI calls:** 0  
**Governance:** OA-ZYRA-257 · DR-ZYRA-214 · baselines may not update automatically

## Coverage measured

- Render variants executed: **44** across 12 representative fixtures.
- Roles declared: female-seeker, male-seeker, guardian.
- Devices: small, standard, large.
- Candidate screenshots present: 44.
- Approved baselines compared: 0.
- L1 live findings: 153 (critical 0, high 0, medium 13, low 140).
- L2 findings: new 0 · resolved 2.

## Changed inputs

- `lib/screens/chat/chat_screen.dart`
- `lib/screens/dev/developer_access_screen.dart`
- `lib/screens/onboarding/bio_onboarding_flow.dart`
- `lib/screens/onboarding/chapter2_flow.dart`
- `lib/screens/profile/edit_profile_screen.dart`
- `lib/screens/settings/help_support_screen.dart`
- `lib/screens/settings/notification_settings_screen.dart`
- `lib/screens/subscription/upgrade_screen.dart`
- `lib/screens/wali/accept_guardian_invite_screen.dart`
- `lib/screens/wali/wali_journey_detail_screen.dart`
- `lib/widgets/onboarding_scaffold.dart`
- `lib/widgets/report_profile_sheet.dart`

## Deterministic and render checks

- **PASS — inventory** · 1.49s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_inventory.py`
- **PASS — L1 deterministic gate** · 0.37s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_gate.py --force`
- **PASS — format check** · 1.01s · exit 0 · `dart format --output=none --set-exit-if-changed lib test`
- **PASS — flutter analyze** · 2.42s · exit 0 · `flutter analyze --no-pub`
- **PASS — zyra structural/reference check** · 4.15s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_check.py --quiet`
- **PASS — visual render and approved-baseline checks** · 3.82s · exit 0 · `flutter test --no-pub test/visual/zyra_visual_regression_test.dart`
- **PASS — candidate screenshot capture** · 4.04s · exit 0 · `flutter test --no-pub test/visual/zyra_visual_regression_test.dart --update-goldens --dart-define=ZYRA_CAPTURE_CANDIDATES=true`
- **PASS — complete Flutter suite** · 14.33s · exit 0 · `flutter test --no-pub`

## Finding ledger

No open L2 findings.

### Resolved

- `01508299f69a` Notifications — resolved 2026-08-24 after 2 occurrence(s).
- `240610613908` Application build — resolved 2026-08-24 after 1 occurrence(s).
- `2dec010c5a38` Repository UI source — resolved 2026-08-24 after 5 occurrence(s).
- `62f92a6283eb` Application structure — resolved 2026-08-24 after 5 occurrence(s).
- `7a637737690c` Onboarding — resolved 2026-08-24 after 2 occurrence(s).
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
