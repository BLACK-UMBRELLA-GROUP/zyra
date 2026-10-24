# ZYRA VISUAL AUDIT — 2026-08-24 · run 52cd7b62

**Verdict:** FAIL  
**Source fingerprint:** `bcef09f077a2d591` · **duration:** 32.9s · **cost:** $0.00 · **AI calls:** 0  
**Governance:** OA-ZYRA-257 · DR-ZYRA-214 · baselines may not update automatically

## Coverage measured

- Render variants executed: **44** across 12 representative fixtures.
- Roles declared: female-seeker, male-seeker, guardian.
- Devices: small, standard, large.
- Candidate screenshots present: 44.
- Approved baselines compared: 0.
- L1 live findings: 153 (critical 0, high 0, medium 13, low 140).
- L2 findings: new 1 · resolved 6.

## Changed inputs

- `assets/fonts/Jost-Bold.ttf`
- `assets/fonts/Jost-ExtraLight.ttf`
- `assets/fonts/Jost-Light.ttf`
- `assets/fonts/Jost-Medium.ttf`
- `assets/fonts/Jost-Regular.ttf`
- `assets/fonts/Jost-SemiBold.ttf`
- `assets/fonts/Syne-SemiBold.ttf`
- `lib/theme/zyra_text.dart`
- `pubspec.yaml`
- `test/visual/zyra_visual_regression_test.dart`

## Deterministic and render checks

- **PASS — inventory** · 1.49s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_inventory.py`
- **PASS — L1 deterministic gate** · 0.38s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_gate.py --force`
- **FAIL — format check** · 1.02s · exit 1 · `dart format --output=none --set-exit-if-changed lib test`
- **PASS — flutter analyze** · 4.11s · exit 0 · `flutter analyze --no-pub`
- **FAIL — zyra structural/reference check** · 4.24s · exit 1 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_check.py --quiet`
- **PASS — visual render and approved-baseline checks** · 4.60s · exit 0 · `flutter test --no-pub test/visual/zyra_visual_regression_test.dart`
- **PASS — candidate screenshot capture** · 3.96s · exit 0 · `flutter test --no-pub test/visual/zyra_visual_regression_test.dart --update-goldens --dart-define=ZYRA_CAPTURE_CANDIDATES=true`
- **FAIL — complete Flutter suite** · 13.08s · exit 1 · `flutter test --no-pub`
  - Failed cases: `records one explicit preference for every answer option`

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
Formatted 193 files (13 changed) in 0.94 seconds.
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

### complete Flutter suite

```text
00:10 +198 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +199 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +200 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +201 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +202 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +203 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +204 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +205 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +206 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +207 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +208 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +209 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +210 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:10 +211 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:10 +212 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:10 +213 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: shared Seeker slider drags and keeps all ten Seekers reachable
00:10 +214 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: shared Seeker slider drags and keeps all ten Seekers reachable
00:10 +215 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: shared Seeker slider drags and keeps all ten Seekers reachable
00:10 +216 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: shared Seeker slider drags and keeps all ten Seekers reachable
[GN-ANALYTICS] seeker_selected · dev-ws1
[GN-ANALYTICS] seeker_selected · dev-ws9
00:10 +217 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: Seeker slider writes the shared GNContext and moves the page
[GN-ANALYTICS] seeker_selected · dev-ws2
00:10 +218 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: current GNScene edge states are reachable through GNContext
00:10 +219 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: Set aside updates only the shared preview state and advances
[GN-ANALYTICS] set_aside · fam-h
00:10 +220 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: Guardian Network four-state matrix fits narrow and standard
00:10 +221 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: Guardian+ explanation appears only after a user tap
00:10 +222 -1: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: GNContext reset clears selection, scene, stages and analytics
[GN-ANALYTICS] seeker_selected · dev-ws2
[GN-ANALYTICS] request_sent · fam-h
00:10 +223 -1: Some tests failed.

Failing tests:
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/traffic_light_question_screen_test.dart: records one explicit preference for every answer option
```


## Finding ledger

### Open

| Fingerprint | Severity | Screen / state | Role / plan | Device | Evidence | Expected / actual | Impact / correction | Owner | Status / trace |
|---|---|---|---|---|---|---|---|---|---|
| `2dec010c5a38` | MEDIUM | Repository UI source / validation | all / all | all · not applicable | format check exited 1; command: dart format --output=none --set-exit-if-changed lib test | Expected: Dart UI and test sources already match the deterministic formatter. Actual: dart format reported files that would change. | Impact: Formatting drift makes review noisier and can conceal meaningful UI changes. Correction: Format the reported files in an owned, reviewable change without altering product intent. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 3× |
| `62f92a6283eb` | HIGH | Application structure / validation | all / all | all · not applicable | zyra structural/reference check exited 1; command: /Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_check.py --quiet | Expected: ZYRA's structural/reference contract passes for current sources. Actual: The structural/reference checker reported unresolved references or contract drift. | Impact: Reference drift can leave stale architecture, invalid calls or misleading validation evidence. Correction: Review each reported site against analyzer truth and the current architecture; fix source or checker false positives explicitly. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 3× |
| `9d6c8757d105` | HIGH | Visual fixture / render | representative / representative | unknown · normal text | Flutter render case failed: records one explicit preference for every answer option | Expected: The representative screen renders within its device bounds with no Flutter layout exception. Actual: The render produced an overflow or another layout exception; candidate evidence was retained and not approved. | Impact: Content can clip, overlap or become unusable for the represented device/state. Correction: Inspect the named screen and shared component at this device width, correct the responsive layout, then rerun the same fixture. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 1× |

### Resolved

- `01508299f69a` Notifications — resolved 2026-08-24 after 2 occurrence(s).
- `7a637737690c` Onboarding — resolved 2026-08-24 after 2 occurrence(s).
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
