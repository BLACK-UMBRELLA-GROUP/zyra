# ZYRA VISUAL AUDIT — 2026-08-26 · run d493f18b

**Verdict:** FAIL  
**Source fingerprint:** `4e6f579dfd369224` · **duration:** 7.0s · **cost:** $0.00 · **AI calls:** 0  
**Governance:** OA-ZYRA-257 · DR-ZYRA-214 · baselines may not update automatically

## Coverage measured

- Render variants executed: **189** across 60 representative fixtures.
- Roles declared: female-seeker, male-seeker, guardian.
- Devices: small, standard, large.
- Candidate screenshots present: 153.
- Approved baselines compared: 0.
- L1 live findings: 164 (critical 0, high 0, medium 15, low 149).
- L2 findings: new 0 · resolved 0.

## Changed inputs

- `lib/data/zyra_entitlements.dart`
- `lib/data/zyra_journey_pause_state.dart`
- `lib/dev/dev_scenario_panel_v2.dart`
- `lib/dev/dev_splash_lab.dart`
- `lib/dev/wali_dev_scenario_panel.dart`
- `lib/dev/zyra_dashboard_lab_controls.dart`
- `lib/dev/zyra_dev_control_system.dart`
- `lib/dev/zyra_dev_scenario.dart`
- `lib/dev/zyra_page_preview_screen.dart`
- `lib/main.dart`
- `lib/models/journey_bio.dart`
- `lib/models/journey_match.dart`
- `lib/models/zyra_dashboard_lab.dart`
- `lib/screens/browse/browse_screen.dart`
- `lib/screens/connections/connections_screen.dart`
- `lib/screens/dev/developer_access_screen.dart`
- `lib/screens/home/home_shell.dart`
- `lib/screens/home/seeker_dashboard_screen.dart`
- `lib/screens/journey/journey_flow_screen.dart`
- `lib/screens/onboarding/account_path_overview_screen.dart`
- `lib/screens/onboarding/bio_onboarding_flow.dart`
- `lib/screens/onboarding/chapter2_flow.dart`
- `lib/screens/onboarding/initial_identity_check_screen.dart`
- `lib/screens/onboarding/onboarding_flow.dart`
- `lib/screens/onboarding/profile_ready_screen.dart`
- `lib/screens/onboarding/values_preferences_flow.dart`
- `lib/screens/profile/profile_screen.dart`
- `lib/screens/profile/seeker_profile_screen.dart`
- `lib/screens/splash_screen.dart`
- `lib/screens/subscription/upgrade_screen.dart`
- `lib/screens/wali/accept_guardian_invite_screen.dart`
- `lib/screens/wali/link_guardian_panel.dart`
- `lib/screens/wali/seeker_guardian_designs.dart`
- `lib/screens/wali/seeker_wali_tab.dart`
- `lib/screens/wali/wali_dashboard_screen.dart`
- `lib/screens/wali/wali_gn_shared.dart`
- `lib/screens/wali/wali_invite_seeker_screen.dart`
- `lib/screens/wali/wali_journey_detail_screen.dart`
- `lib/screens/wali/wali_network_screen.dart`
- `lib/screens/wali/wali_profile_screen.dart`
- `lib/screens/wali/wali_seekers_screen.dart`
- `lib/services/zyra_auth.dart`
- `lib/services/zyra_consent_service.dart`
- `lib/services/zyra_dev_app_icon.dart`
- `lib/services/zyra_journey_service.dart`
- `lib/services/zyra_local_prefs.dart`
- `lib/services/zyra_onboarding_answers_service.dart`
- `lib/services/zyra_photo_service.dart`
- `lib/services/zyra_profile_service.dart`
- `lib/services/zyra_session_router.dart`
- `lib/services/zyra_wali_journey_service.dart`
- `lib/services/zyra_wali_link_service.dart`
- `lib/theme/zyra_colors.dart`
- `lib/widgets/floating_nav_bar.dart`
- `lib/widgets/report_profile_sheet.dart`
- `lib/widgets/zyra_account_switch_sheet.dart`
- `lib/widgets/zyra_bottom_promotion.dart`
- `lib/widgets/zyra_comet_rule.dart`
- `lib/widgets/zyra_dashboard_experience.dart`
- `lib/widgets/zyra_full_screen_error.dart`
- `lib/widgets/zyra_glass_dialog.dart`
- `lib/widgets/zyra_guardian_invitation_dashboard.dart`
- `lib/widgets/zyra_loading.dart`
- `lib/widgets/zyra_meet_and_pass_rule.dart`
- `lib/widgets/zyra_splash_motion.dart`
- `lib/widgets/zyra_ward_card.dart`
- `test/visual/zyra_visual_regression_test.dart`
- `ZYRA/SYSTEM/RESOURCES/UI_GATE/state_matrix.json`
- `REMOVED: lib/widgets/zyra_trails_meet_rule.dart`

## Deterministic and render checks

- **PASS — inventory** · 1.74s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_inventory.py`
- **PASS — L1 deterministic gate** · 0.41s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_gate.py --force`
- **FAIL — format check** · 0.06s · exit 1 · `dart format --output=none --set-exit-if-changed lib test`
- **FAIL — flutter analyze** · 0.05s · exit 1 · `flutter analyze --no-pub`
- **PASS — structural checker self-tests** · 0.05s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 -m unittest tools/test_zyra_check.py`
- **PASS — zyra structural/reference check** · 4.60s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_check.py --quiet`
- **FAIL — visual render and approved-baseline checks** · 0.05s · exit 1 · `flutter test --no-pub test/visual/zyra_visual_regression_test.dart`

## Failed-check evidence

### format check

```text
/opt/homebrew/share/flutter/bin/internal/update_engine_version.sh: line 71: /opt/homebrew/share/flutter/bin/cache/engine.stamp.tmp.69369: Operation not permitted
/opt/homebrew/share/flutter/bin/internal/update_engine_version.sh: line 78: /opt/homebrew/share/flutter/bin/cache/engine.realm: Operation not permitted
```

### flutter analyze

```text
/opt/homebrew/share/flutter/bin/internal/update_engine_version.sh: line 71: /opt/homebrew/share/flutter/bin/cache/engine.stamp.tmp.69400: Operation not permitted
/opt/homebrew/share/flutter/bin/internal/update_engine_version.sh: line 78: /opt/homebrew/share/flutter/bin/cache/engine.realm: Operation not permitted
```

### visual render and approved-baseline checks

```text
/opt/homebrew/share/flutter/bin/internal/update_engine_version.sh: line 71: /opt/homebrew/share/flutter/bin/cache/engine.stamp.tmp.69435: Operation not permitted
/opt/homebrew/share/flutter/bin/internal/update_engine_version.sh: line 78: /opt/homebrew/share/flutter/bin/cache/engine.realm: Operation not permitted
```


## Finding ledger

### Open

| Fingerprint | Severity | Screen / state | Role / plan | Device | Evidence | Expected / actual | Impact / correction | Owner | Status / trace |
|---|---|---|---|---|---|---|---|---|---|
| `240610613908` | CRITICAL | Application build / validation | all / all | all · not applicable | flutter analyze exited 1; command: flutter analyze --no-pub | Expected: Flutter static analysis completes with no errors. Actual: flutter analyze failed. | Impact: The application may not compile or may contain a broken production path. Correction: Resolve analyzer errors before any UI feature or release is marked complete. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 3× |
| `2dec010c5a38` | MEDIUM | Repository UI source / validation | all / all | all · not applicable | format check exited 1; command: dart format --output=none --set-exit-if-changed lib test | Expected: Dart UI and test sources already match the deterministic formatter. Actual: dart format reported files that would change. | Impact: Formatting drift makes review noisier and can conceal meaningful UI changes. Correction: Format the reported files in an owned, reviewable change without altering product intent. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 7× |
| `8ed32a7c6733` | HIGH | UI gate / validation | all / all | all · not applicable | visual render and approved-baseline checks exited 1; command: flutter test --no-pub test/visual/zyra_visual_regression_test.dart | Expected: visual render and approved-baseline checks passes. Actual: visual render and approved-baseline checks exited 1. | Impact: The UI gate cannot attest this validation layer. Correction: Inspect the permanent failed-check evidence and correct or classify the failure. | Codex | open · OA-ZYRA-257 · DR-ZYRA-214 · seen 3× |

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
