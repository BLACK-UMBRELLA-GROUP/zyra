# ZYRA VISUAL AUDIT — 2026-08-24 · run 0d2653d8

**Verdict:** FAIL  
**Source fingerprint:** `3a67cfa6fe538304` · **duration:** 40.5s · **cost:** $0.00 · **AI calls:** 0  
**Governance:** OA-ZYRA-257 · DR-ZYRA-214 · baselines may not update automatically

## Coverage measured

- Render variants executed: **44** across 12 representative fixtures.
- Roles declared: female-seeker, male-seeker, guardian.
- Devices: small, standard, large.
- Candidate screenshots present: 44.
- Approved baselines compared: 0.
- L1 live findings: 153 (critical 0, high 0, medium 13, low 140).
- L2 findings: new 8 · resolved 0.

## Changed inputs

- `assets/auth/google_g_logo.png`
- `assets/icon/icon.png`
- `assets/splash/splash_logo.png`
- `lib/config/oauth_config.dart`
- `lib/config/supabase_config.dart`
- `lib/constants/zyra_plan_names.dart`
- `lib/data/chapter3_categories.dart`
- `lib/data/compatibility_categories.dart`
- `lib/data/help_content.dart`
- `lib/data/journey_questions.dart`
- `lib/data/onboarding_bank_contract.dart`
- `lib/data/onboarding_category_guidance.dart`
- `lib/data/zyra_entitlements.dart`
- `lib/data/zyra_journey_advance_policy.dart`
- `lib/data/zyra_journey_guardian_selection.dart`
- `lib/data/zyra_journey_intelligence.dart`
- `lib/data/zyra_journey_life_snapshot.dart`
- `lib/data/zyra_journey_pause_state.dart`
- `lib/data/zyra_journey_scroll.dart`
- `lib/data/zyra_journey_stages.dart`
- `lib/data/zyra_reference_data.dart`
- `lib/dev/dev_scenario_panel_v2.dart`
- `lib/dev/dev_splash_lab.dart`
- `lib/dev/journey_experience_lab.dart`
- `lib/dev/wali_dashboard_preview.dart`
- `lib/dev/wali_dev_scenario_panel.dart`
- `lib/dev/zyra_dev_control_system.dart`
- `lib/dev/zyra_dev_scenario.dart`
- `lib/dev/zyra_dev_signup.dart`
- `lib/dev/zyra_dev_surface_coordinator.dart`
- `lib/dev/zyra_global_dev_overlay.dart`
- `lib/dev/zyra_page_preview_screen.dart`
- `lib/main.dart`
- `lib/models/journey_bio.dart`
- `lib/models/journey_match.dart`
- `lib/models/onboarding_question.dart`
- `lib/models/seeker_profile.dart`
- `lib/models/zyra_error_state.dart`
- `lib/models/zyra_gender.dart`
- `lib/screens/auth/email_recovery_screen.dart`
- `lib/screens/auth/role_selection_screen.dart`
- `lib/screens/auth_gate.dart`
- `lib/screens/browse/browse_screen.dart`
- `lib/screens/browse/match_notification_screen.dart`
- `lib/screens/chat/chat_screen.dart`
- `lib/screens/connections/connections_screen.dart`
- `lib/screens/dev/developer_access_screen.dart`
- `lib/screens/home/home_shell.dart`
- `lib/screens/journey/journey_flow_screen.dart`
- `lib/screens/journey/journey_map_screen.dart`
- `lib/screens/matches/journey_timeline_screen.dart`
- `lib/screens/notifications/notifications_screen.dart`
- `lib/screens/onboarding/account_path_overview_screen.dart`
- `lib/screens/onboarding/article9_consent_screen.dart`
- `lib/screens/onboarding/bio_onboarding_flow.dart`
- `lib/screens/onboarding/category_summary_screen.dart`
- `lib/screens/onboarding/chapter2_flow.dart`
- `lib/screens/onboarding/compatibility_category_intro_screen.dart`
- `lib/screens/onboarding/generic_select_question_screen.dart`
- `lib/screens/onboarding/onboarding_flow.dart`
- `lib/screens/onboarding/onboarding_stage_intro_screen.dart`
- `lib/screens/onboarding/profile_ready_screen.dart`
- `lib/screens/onboarding/traffic_light_question_screen.dart`
- `lib/screens/onboarding/transition_screen.dart`
- `lib/screens/onboarding/values_preferences_flow.dart`
- `lib/screens/profile/edit_profile_screen.dart`
- `lib/screens/profile/profile_screen.dart`
- `lib/screens/profile/seeker_profile_screen.dart`
- `lib/screens/settings/account_advanced_screen.dart`
- `lib/screens/settings/app_lock_screen.dart`
- `lib/screens/settings/blocked_users_screen.dart`
- `lib/screens/settings/feedback_screen.dart`
- `lib/screens/settings/help_support_screen.dart`
- `lib/screens/settings/notification_settings_screen.dart`
- `lib/screens/settings/privacy_and_data_screen.dart`
- `lib/screens/settings/privacy_settings_screen.dart`
- `lib/screens/settings/settings_screen.dart`
- `lib/screens/settings/sign_in_security_screen.dart`
- `lib/screens/splash_screen.dart`
- `lib/screens/subscription/profile_unlock_screen.dart`
- `lib/screens/subscription/upgrade_screen.dart`
- `lib/screens/wali/accept_guardian_invite_screen.dart`
- `lib/screens/wali/accept_wali_invite_screen.dart`
- `lib/screens/wali/guardian_detail_screen.dart`
- `lib/screens/wali/link_guardian_panel.dart`
- `lib/screens/wali/link_wali_screen.dart`
- `lib/screens/wali/seeker_wali_tab.dart`
- `lib/screens/wali/wali_dashboard_screen.dart`
- `lib/screens/wali/wali_gn_shared.dart`
- `lib/screens/wali/wali_home_shell.dart`
- `lib/screens/wali/wali_invite_seeker_screen.dart`
- `lib/screens/wali/wali_journey_detail_screen.dart`
- `lib/screens/wali/wali_network_screen.dart`
- `lib/screens/wali/wali_notification_settings_screen.dart`
- `lib/screens/wali/wali_onboarding_flow.dart`
- `lib/screens/wali/wali_profile_screen.dart`
- `lib/screens/wali/wali_seekers_screen.dart`
- `lib/screens/welcome_screen.dart`
- `lib/services/zyra_ages_service.dart`
- `lib/services/zyra_app_lock.dart`
- `lib/services/zyra_auth.dart`
- `lib/services/zyra_consent_service.dart`
- `lib/services/zyra_developer_access.dart`
- `lib/services/zyra_discovery_service.dart`
- `lib/services/zyra_entitlement_service.dart`
- `lib/services/zyra_feedback_service.dart`
- `lib/services/zyra_guardian_info_service.dart`
- `lib/services/zyra_guardian_suggestion_service.dart`
- `lib/services/zyra_image_cache.dart`
- `lib/services/zyra_journey_service.dart`
- `lib/services/zyra_local_prefs.dart`
- `lib/services/zyra_match_service.dart`
- `lib/services/zyra_notification_prefs_service.dart`
- `lib/services/zyra_notification_service.dart`
- `lib/services/zyra_onboarding_answers_service.dart`
- `lib/services/zyra_photo_service.dart`
- `lib/services/zyra_profile_service.dart`
- `lib/services/zyra_promotion_engine.dart`
- `lib/services/zyra_report_service.dart`
- `lib/services/zyra_seeker_details_service.dart`
- `lib/services/zyra_session_router.dart`
- `lib/services/zyra_truthful_write.dart`
- `lib/services/zyra_unlock_service.dart`
- `lib/services/zyra_wali_journey_service.dart`
- `lib/services/zyra_wali_link_service.dart`
- `lib/state/app_state.dart`
- `lib/theme/zyra_card_metrics.dart`
- `lib/theme/zyra_colors.dart`
- `lib/theme/zyra_text.dart`
- `lib/widgets/anchored_card_overlay.dart`
- `lib/widgets/fab_continue_button.dart`
- `lib/widgets/flexibility_choice.dart`
- `lib/widgets/floating_nav_bar.dart`
- `lib/widgets/glass_icon_button.dart`
- `lib/widgets/help_report_sheet.dart`
- `lib/widgets/notification_bell.dart`
- `lib/widgets/onboarding_scaffold.dart`
- `lib/widgets/onboarding_top_bar.dart`
- `lib/widgets/privacy_indicator.dart`
- `lib/widgets/report_profile_sheet.dart`
- `lib/widgets/searchable_list_picker.dart`
- `lib/widgets/zyra_account_switch_sheet.dart`
- `lib/widgets/zyra_app_lock_gate.dart`
- `lib/widgets/zyra_bottom_promotion.dart`
- `lib/widgets/zyra_comet_rule.dart`
- `lib/widgets/zyra_fade_edges.dart`
- `lib/widgets/zyra_full_screen_error.dart`
- `lib/widgets/zyra_glass_dialog.dart`
- `lib/widgets/zyra_intelligence_card.dart`
- `lib/widgets/zyra_loading.dart`
- `lib/widgets/zyra_locked_feature_upgrade.dart`
- `lib/widgets/zyra_meet_and_pass_rule.dart`
- `lib/widgets/zyra_moment.dart`
- `lib/widgets/zyra_paused_limit_refusal.dart`
- `lib/widgets/zyra_profile_image.dart`
- `lib/widgets/zyra_profile_name_block.dart`
- `lib/widgets/zyra_segmented_toggle.dart`
- `lib/widgets/zyra_state_widgets.dart`
- `lib/widgets/zyra_trails_meet_rule.dart`
- `lib/widgets/zyra_ward_card.dart`
- `lib/widgets/zyra_write_feedback.dart`
- `pubspec.yaml`
- `test/visual/approved/manifest.json`
- `test/visual/zyra_visual_regression_test.dart`
- `ZYRA/SYSTEM/RESOURCES/UI_GATE/state_matrix.json`
- `ZYRA/SYSTEM/RESOURCES/UI_GATE/ui_gate_config.json`

## Deterministic and render checks

- **PASS — inventory** · 1.49s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_inventory.py`
- **PASS — L1 deterministic gate** · 0.38s · exit 0 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_ui_gate.py --force`
- **FAIL — format check** · 1.02s · exit 1 · `dart format --output=none --set-exit-if-changed lib test`
- **PASS — flutter analyze** · 2.89s · exit 0 · `flutter analyze --no-pub`
- **FAIL — zyra structural/reference check** · 4.18s · exit 1 · `/Applications/Xcode.app/Contents/Developer/usr/bin/python3 tools/zyra_check.py --quiet`
- **FAIL — visual render and approved-baseline checks** · 4.31s · exit 1 · `flutter test --no-pub test/visual/zyra_visual_regression_test.dart`
  - Failed cases: `notifications-empty__small renders without overflow or exceptions`; `notifications-empty__standard__text-130 renders without overflow or exceptions`; `notifications-error__small renders without overflow or exceptions`; `onboarding-intro__small renders without overflow or exceptions`; `subscription-upgrade__large renders without overflow or exceptions`; `subscription-upgrade__standard renders without overflow or exceptions`
- **FAIL — candidate screenshot capture** · 9.65s · exit 1 · `flutter test --no-pub test/visual/zyra_visual_regression_test.dart --update-goldens --dart-define=ZYRA_CAPTURE_CANDIDATES=true`
  - Failed cases: `notifications-empty__small renders without overflow or exceptions`; `notifications-empty__standard__text-130 renders without overflow or exceptions`; `notifications-error__small renders without overflow or exceptions`; `onboarding-intro__small renders without overflow or exceptions`; `subscription-upgrade__large renders without overflow or exceptions`; `subscription-upgrade__standard renders without overflow or exceptions`
- **FAIL — complete Flutter suite** · 16.53s · exit 1 · `flutter test --no-pub`
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
00:02 +38 -6: guardian-slider-six-seekers__standard__text-130 renders without overflow or exceptions
00:02 +39 -6: (tearDownAll)
00:02 +39 -6: Some tests failed.

Failing tests:
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: notifications-empty__small renders without overflow or exceptions
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: notifications-empty__standard__text-130 renders without overflow or exceptions
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: notifications-error__small renders without overflow or exceptions
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: onboarding-intro__small renders without overflow or exceptions
  ... and 2 more
```

### complete Flutter suite

```text
00:13 +197 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:13 +198 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:13 +199 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:13 +200 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:13 +201 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:13 +202 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:13 +203 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:13 +204 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:13 +205 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/zyra_bottom_promotion_test.dart: narrow invitation is non-blocking and never auto-opens a plan
00:13 +206 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:13 +207 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:13 +208 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:13 +209 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: D14 preview serves one family in the active Seeker context
00:13 +210 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: blank Guardian invitation is centred in the usable page
00:13 +211 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: shared Seeker slider drags and keeps all ten Seekers reachable
[GN-ANALYTICS] seeker_selected · dev-ws1
[GN-ANALYTICS] seeker_selected · dev-ws9
00:14 +212 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: Seeker slider writes the shared GNContext and moves the page
[GN-ANALYTICS] seeker_selected · dev-ws2
00:14 +213 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: current GNScene edge states are reachable through GNContext
00:14 +214 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: Set aside updates only the shared preview state and advances
[GN-ANALYTICS] set_aside · fam-h
00:14 +215 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: Guardian Network four-state matrix fits narrow and standard
00:14 +216 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: Guardian+ explanation appears only after a user tap
00:14 +217 -6: /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/guardian_network_preview_test.dart: GNContext reset clears selection, scene, stages and analytics
[GN-ANALYTICS] seeker_selected · dev-ws2
[GN-ANALYTICS] request_sent · fam-h
00:14 +218 -6: Some tests failed.

Failing tests:
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: notifications-empty__small renders without overflow or exceptions
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: notifications-empty__standard__text-130 renders without overflow or exceptions
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: notifications-error__small renders without overflow or exceptions
  /Users/shakeelahmad/Developer/DEVELOPMENT/SUB BUSINESS/ZYRA/SOURCE/test/visual/zyra_visual_regression_test.dart: onboarding-intro__small renders without overflow or exceptions
  ... and 2 more
```


## Baseline governance

No approved screenshot baselines exist yet. The PNGs in `test/visual/candidates/` are evidence for review, not design authority.
A changed render cannot replace an approved baseline. Fable checks intent; the Founder approves where required; a new version and full metadata are then filed manually.

## Screen-matrix truth

The matrix lists every required core screen. `render+widget` means a current screenshot fixture exists; `existing-widget+static` means current functional/static coverage exists but a dedicated approved screenshot is still pending. No coverage is overstated.

## Cost and activation

This run used local Python/Dart/Flutter only: $0.00. No overnight schedule was created or enabled. Activation remains blocked on Fable review and Founder baseline approval.
