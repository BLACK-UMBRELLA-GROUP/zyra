# ZYRA — Repository Tree View

**Generated:** 2026-07-26
**Governing Reference:** DR-ZYRA-103 (repository navigation ratification)
**Regenerate by:** directory listing, not by hand. Refresh whenever
top-level folder structure changes; do not add commentary here — see
`ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V2.md` for purpose/owner/status per document.

Excluded from this listing: `.git/`, build/tooling output
(`SOURCE/.dart_tool`, `SOURCE/.idea`, `SOURCE/build`), platform build
folders (`SOURCE/ios`, `SOURCE/android`, `SOURCE/macos`, `SOURCE/linux`,
`SOURCE/windows`, `SOURCE/web`), `.DS_Store` files, and
`SOURCE/supabase/dev_test_photos/` (100 dev-only portrait PNGs, ~370MB,
not part of the app or its documentation).

**Note (2026-07-26, OA-ZYRA-141):** The `DEVELOPMENT_TEAM/` and
`LIVE_OPERATIONS/` root folders previously flagged here as
undocumented legacy/parallel structures have been resolved — both were
dead scaffolding from a single 2026-06-26 session, never used again,
and are now archived under `ARCHIVE/DEVELOPMENT_TEAM_2026-06-26/` and
`ARCHIVE/LIVE_OPERATIONS_2026-06-26/` (see `ARCHIVE/README.md`). Repo
root no longer carries undocumented top-level folders.

---

```
ZYRA/
├── .gitignore
├── APP/
│   ├── Authentication/
│   │   └── Script/
│   │       └── Script_V1.md
│   ├── Browse/
│   │   ├── BROWSE_UX_SPEC_2026-07-25_V1.md
│   │   ├── BROWSE_UX_SPEC_2026-07-25_V2.md
│   │   ├── BROWSE_UX_SPEC_CURRENT_VERSION_V4.md
│   │   └── Script/
│   │       └── Script_V1.md
│   ├── Developer Mode/
│   │   └── Script/
│   │       ├── Script_V1.md
│   │       └── Script_V2.md
│   ├── Home/
│   │   └── SUMMARY.md
│   ├── Journey/
│   │   ├── JOURNEY AVAILABILITY/
│   │   │   └── Summary.md
│   │   ├── JOURNEY MANAGEMENT/
│   │   │   └── Summary.md
│   │   ├── JOURNEY PHILOSOPHY/
│   │   │   └── Summary.md
│   │   ├── JOURNEY SUSPENSION/
│   │   │   └── JOURNEY_SUSPENSION_CURRENT_VERSION_V1.md
│   │   └── PRE-JOURNEY RITUAL/
│   │       └── Summary.md
│   ├── Matches/
│   │   ├── MATCHES PAGE/
│   │   │   └── Summary.md
│   │   └── RELATIONSHIP SPACE/
│   │       └── Summary.md
│   ├── Matching/
│   │   ├── MATCH UX/
│   │   │   └── MATCH_UX_SPEC_CURRENT_VERSION_V1.md
│   │   └── PROFILE DECISION SYSTEM/
│   │       ├── Flow Diagram.md
│   │       ├── References.md
│   │       ├── Script/
│   │       └── Summary.md
│   ├── Messaging/
│   │   └── SUMMARY.md
│   ├── Navigation/
│   │   └── SEEKER NAVIGATION/
│   │       ├── Flow Diagram.md
│   │       ├── References.md
│   │       ├── Script/
│   │       │   ├── Script_V1.md
│   │       │   └── Script_V2.md
│   │       └── Summary.md
│   ├── Notifications/
│   │   └── SUMMARY.md
│   ├── Onboarding/
│   │   ├── PROFILE COMPLETION/
│   │   │   └── Summary.md
│   │   └── SEEKER ONBOARDING QUESTIONS/
│   │       ├── Chapter 3 Classification — Ch4 Mapping.md
│   │       ├── Flow Diagram.md
│   │       ├── Onboarding Rules & UX.md
│   │       ├── Questions Chapter 3 Your Values.md
│   │       ├── Questions Section 2 Profile Information.md
│   │       ├── Questions Section 3 Core Compatibility.md
│   │       ├── References.md
│   │       ├── Script/
│   │       └── Summary.md
│   ├── Platform/
│   │   └── GLOBAL_PLATFORM_PRINCIPLES_CURRENT_VERSION_V1.md
│   ├── Premium/
│   │   ├── ADVERTISING/
│   │   │   └── ADVERTISING_STANDARD_CURRENT_VERSION_V1.md
│   │   ├── AI TIERING/
│   │   │   └── TIERING_CURRENT_VERSION_V1.md
│   │   ├── DEPENDENCY COMMUNICATION/
│   │   │   └── DEPENDENCY_CURRENT_VERSION_V1.md
│   │   ├── Profile Unlocks/
│   │   │   ├── Flow Diagram.md
│   │   │   ├── References.md
│   │   │   ├── Script/
│   │   │   └── Summary.md
│   │   ├── SUBSCRIPTION TRANSPARENCY/
│   │   │   └── TRANSPARENCY_CURRENT_VERSION_V1.md
│   │   └── GUARDIAN PREMIUM/
│   │       └── Summary.md
│   ├── Profiles/
│   │   ├── Script/
│   │   │   └── Script_V1.md
│   │   └── Summary.md
│   ├── Safety/
│   │   ├── SAFETY_RESPECT_SYSTEM_2026-06-28_V1.md
│   │   ├── SAFETY_RESPECT_SYSTEM_2026-06-28_V2.md
│   │   ├── SAFETY_RESPECT_SYSTEM_CURRENT_VERSION_V3.md
│   │   └── Summary.md
│   ├── Search/
│   │   └── SUMMARY.md
│   ├── Settings/
│   │   └── SUMMARY.md
│   ├── Standards/
│   │   ├── IMAGE_HANDLING_2026-07-25_V1.md
│   │   ├── IMAGE_HANDLING_CURRENT_VERSION_V2.md
│   │   ├── JOURNEY_CAPABILITY_GRANT_RULES_2026-07-04_V1.md
│   │   ├── JOURNEY_CAPABILITY_GRANT_RULES_2026-07-04_V2.md
│   │   ├── JOURNEY_CAPABILITY_GRANT_RULES_CURRENT_VERSION_V4.md
│   │   ├── WALI_ARCHITECTURE_2026-06-28_V1.md
│   │   ├── WALI_ARCHITECTURE_2026-06-28_V2.md
│   │   ├── WALI_ARCHITECTURE_2026-07-04_V3.md
│   │   ├── WALI_ARCHITECTURE_2026-07-04_V4.md
│   │   └── WALI_ARCHITECTURE_CURRENT_VERSION_V6.md
│   ├── UX Writing/
│   │   ├── ERROR_AND_EMPTY_STATE_STANDARD_CURRENT_VERSION_V1.md
│   │   └── Summary.md
│   └── iOS Widgets/
│       ├── Flow Diagram.md
│       ├── References.md
│       ├── Script/
│       └── Summary.md
├── ARCHIVE/
│   ├── DEVELOPMENT_TEAM_2026-06-26/
│   │   ├── AGENTS/
│   │   │   ├── ARCHITECT_AGENT/
│   │   │   │   └── ARCHITECT_AGENT_CONTRACT_V1.md
│   │   │   ├── CODE_AGENT/
│   │   │   │   └── CODE_AGENT_CONTRACT_V1.md
│   │   │   ├── DEPLOYMENT_AGENT/
│   │   │   │   └── DEPLOYMENT_AGENT_CONTRACT_V1.md
│   │   │   ├── DOCUMENTATION_AGENT/
│   │   │   │   └── DOCUMENTATION_AGENT_CONTRACT_V1.md
│   │   │   ├── IMPACT_ANALYSIS_AGENT/
│   │   │   │   └── IMPACT_ANALYSIS_AGENT_CONTRACT_V1.md
│   │   │   ├── PRODUCT_MANAGER_AGENT/
│   │   │   │   └── PRODUCT_MANAGER_AGENT_CONTRACT_V1.md
│   │   │   ├── QA_AGENT/
│   │   │   │   └── QA_AGENT_CONTRACT_V1.md
│   │   │   └── REVIEW_AGENT/
│   │   │       └── REVIEW_AGENT_CONTRACT_V1.md
│   │   ├── DEVELOPMENT_TEAM_GOVERNANCE_V1.md
│   │   ├── LOGS/
│   │   │   └── OPERATIONAL_LOG_2026-06.md
│   │   ├── RESOURCES/
│   │   │   ├── MEMORY/
│   │   │   │   └── team_memory.json
│   │   │   ├── REPORTS/
│   │   │   │   ├── SESSION_SESSION-20260626-170013-c4d10c_2026-06-26.md
│   │   │   │   └── SESSION_SESSION-20260626-170056-86be86_2026-06-26.md
│   │   │   └── TEAM_STATE.md
│   │   ├── SESSIONS/
│   │   │   ├── SESSION-20260626-170013-c4d10c.json
│   │   │   └── SESSION-20260626-170056-86be86.json
│   │   ├── TEAM_INDEX_V1.md
│   │   ├── TEAM_INTEGRATION_GUIDE_V1.md
│   │   └── TEAM_PLAYBOOK_V1.md
│   ├── LIVE_OPERATIONS_2026-06-26/
│   │   ├── INCIDENTS/
│   │   │   ├── CLOSED/
│   │   │   ├── OPEN/
│   │   │   └── POSTMORTEMS/
│   │   ├── INCIDENT_REGISTER_V1.md
│   │   ├── LIVE_OPS_GOVERNANCE_V1.md
│   │   ├── LIVE_OPS_INDEX_V1.md
│   │   ├── LOGS/
│   │   │   └── OPERATIONAL_LOG_2026-06.md
│   │   ├── MONITORING/
│   │   │   └── CHECKS/
│   │   │       ├── BUILD_HEALTH_V1.md
│   │   │       ├── DOCS_HEALTH_V1.md
│   │   │       ├── INCIDENT_HEALTH_V1.md
│   │   │       ├── RELEASE_HEALTH_V1.md
│   │   │       └── TEST_HEALTH_V1.md
│   │   ├── RELEASES/
│   │   ├── RELEASE_REGISTER_V1.md
│   │   ├── RESOURCES/
│   │   │   ├── LIVE_OPS_STATE.md
│   │   │   ├── MEMORY/
│   │   │   │   ├── health_history.json
│   │   │   │   └── live_ops_state.json
│   │   │   └── REPORTS/
│   │   │       └── HEALTH_CHECK_2026-06-26_170406.md
│   │   └── RUNBOOKS/
│   │       └── LIVE_OPS_RUNBOOK_V1.md
│   └── README.md
├── BUSINESS/
│   ├── AI STRATEGY/
│   │   └── Summary.md
│   ├── APP BREAKDOWN/
│   │   └── Flow Diagram.md
│   ├── APP LOGO/
│   │   ├── Flow Diagram.md
│   │   ├── References.md
│   │   └── Summary.md
│   ├── APP NAME CREATION/
│   │   ├── Flow Diagram.md
│   │   ├── References.md
│   │   └── Summary.md
│   ├── BRAND MESSAGING/
│   │   ├── Flow Diagram.md
│   │   ├── References.md
│   │   └── Summary.md
│   ├── COLOUR THEME/
│   │   ├── ASSETS/
│   │   │   ├── gradient-blue.png
│   │   │   ├── gradient-pink.png
│   │   │   └── gradient-purple.png
│   │   ├── Flow Diagram.md
│   │   ├── References.md
│   │   └── Summary.md
│   ├── COMPETITOR RESEARCH/
│   │   └── COMPETITOR_REVIEW_MUSLIM_MARRIAGE_PLATFORMS_CURRENT_VERSION_V1.md
│   ├── PRODUCT PLANNING/
│   │   └── Summary.md
│   ├── USER FEATURES/
│   │   ├── Flow Diagram.md
│   │   ├── References.md
│   │   └── Summary.md
│   ├── ZYRA LAUNCH GUIDE/
│   │   ├── Flow Diagram.md
│   │   ├── References.md
│   │   └── Summary.md
│   ├── ZYRA PRICING/
│   │   ├── Flow Diagram.md
│   │   ├── References.md
│   │   └── Summary.md
│   └── ZYRA TERMINOLOGY/
│       ├── References.md
│       └── Summary.md
├── REPORTS/
│   ├── CURRENT/
│   │   └── ZYRA_FABLE_BUILD_REVIEW_2026-07-19_V1.md
│   └── INSPECTION/
├── SOURCE/
│   ├── .flutter-plugins-dependencies
│   ├── .gitignore
│   ├── .metadata
│   ├── README.md
│   ├── analysis_options.yaml
│   ├── app.iml
│   ├── assets/
│   │   ├── icon/
│   │   │   └── icon.png
│   │   └── splash/
│   │       └── splash_logo.png
│   ├── lib/
│   │   ├── config/
│   │   │   ├── oauth_config.dart
│   │   │   ├── oauth_config.dart.example
│   │   │   ├── supabase_config.dart
│   │   │   └── supabase_config.dart.example
│   │   ├── constants/
│   │   │   └── zyra_plan_names.dart
│   │   ├── data/
│   │   │   ├── chapter3_categories.dart
│   │   │   ├── journey_questions.dart
│   │   │   └── mock_reference_lists.dart
│   │   ├── main.dart
│   │   ├── models/
│   │   │   ├── journey_match.dart
│   │   │   ├── onboarding_question.dart
│   │   │   └── seeker_profile.dart
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   └── role_selection_screen.dart
│   │   │   ├── auth_gate.dart
│   │   │   ├── browse/
│   │   │   │   ├── browse_screen.dart
│   │   │   │   └── match_notification_screen.dart
│   │   │   ├── chat/
│   │   │   │   └── chat_screen.dart
│   │   │   ├── connections/
│   │   │   │   └── connections_screen.dart
│   │   │   ├── dev/
│   │   │   │   └── developer_access_screen.dart
│   │   │   ├── home/
│   │   │   │   └── home_shell.dart
│   │   │   ├── journey/
│   │   │   │   └── journey_flow_screen.dart
│   │   │   ├── matches/
│   │   │   │   └── journey_timeline_screen.dart
│   │   │   ├── notifications/
│   │   │   │   └── notifications_screen.dart
│   │   │   ├── onboarding/
│   │   │   │   ├── category_summary_screen.dart
│   │   │   │   ├── chapter2_flow.dart
│   │   │   │   ├── generic_select_question_screen.dart
│   │   │   │   ├── onboarding_flow.dart
│   │   │   │   ├── profile_ready_screen.dart
│   │   │   │   ├── traffic_light_question_screen.dart
│   │   │   │   ├── transition_screen.dart
│   │   │   │   └── values_preferences_flow.dart
│   │   │   ├── profile/
│   │   │   │   └── profile_screen.dart
│   │   │   ├── settings/
│   │   │   │   ├── help_support_screen.dart
│   │   │   │   ├── notification_settings_screen.dart
│   │   │   │   └── privacy_settings_screen.dart
│   │   │   ├── subscription/
│   │   │   │   └── upgrade_screen.dart
│   │   │   ├── guardian/
│   │   │   │   ├── accept_wali_invite_screen.dart
│   │   │   │   ├── link_wali_screen.dart
│   │   │   │   ├── seeker_wali_tab.dart
│   │   │   │   ├── wali_dashboard_screen.dart
│   │   │   │   ├── wali_home_shell.dart
│   │   │   │   ├── wali_invite_seeker_screen.dart
│   │   │   │   ├── wali_journey_detail_screen.dart
│   │   │   │   ├── wali_network_screen.dart
│   │   │   │   ├── wali_onboarding_flow.dart
│   │   │   │   ├── wali_profile_screen.dart
│   │   │   │   └── wali_seekers_screen.dart
│   │   │   └── welcome_screen.dart
│   │   ├── services/
│   │   │   ├── compatibility_scoring.dart
│   │   │   ├── zyra_auth.dart
│   │   │   ├── zyra_discovery_service.dart
│   │   │   ├── zyra_entitlement_service.dart
│   │   │   ├── zyra_journey_service.dart
│   │   │   ├── zyra_match_service.dart
│   │   │   ├── zyra_notification_service.dart
│   │   │   ├── zyra_onboarding_answers_service.dart
│   │   │   ├── zyra_photo_service.dart
│   │   │   ├── zyra_profile_service.dart
│   │   │   ├── zyra_session_router.dart
│   │   │   ├── zyra_wali_journey_service.dart
│   │   │   └── zyra_wali_link_service.dart
│   │   ├── state/
│   │   │   └── app_state.dart
│   │   ├── theme/
│   │   │   ├── zyra_colors.dart
│   │   │   └── zyra_text.dart
│   │   └── widgets/
│   │       ├── dev_nav_overlay.dart
│   │       ├── fab_continue_button.dart
│   │       ├── flexibility_choice.dart
│   │       ├── floating_nav_bar.dart
│   │       ├── glass_icon_button.dart
│   │       ├── notification_bell.dart
│   │       ├── onboarding_scaffold.dart
│   │       ├── onboarding_top_bar.dart
│   │       ├── privacy_indicator.dart
│   │       ├── searchable_list_picker.dart
│   │       └── zyra_state_widgets.dart
│   ├── pubspec.lock
│   ├── pubspec.yaml
│   ├── supabase/
│   │   ├── insert_dev_photos.sql
│   │   ├── insert_retry_photos.sql
│   │   ├── migrations/
│   │   │   ├── 20260718190011_initial_schema.sql
│   │   │   ├── 20260718190033_harden_update_updated_at_search_path.sql
│   │   │   ├── 20260718190912_profile_photos_storage_bucket.sql
│   │   │   ├── 20260718190929_narrow_profile_photos_storage_read.sql
│   │   │   ├── 20260718192024_onboarding_answers_table.sql
│   │   │   ├── 20260718192519_optimize_rls_auth_uid_initplan.sql
│   │   │   ├── 20260718192853_match_creation_on_mutual_like.sql
│   │   │   ├── 20260718192910_restrict_match_trigger_function_execute.sql
│   │   │   ├── 20260718192924_restrict_match_trigger_function_execute_v2.sql
│   │   │   ├── 20260718193130_enable_realtime_messages.sql
│   │   │   ├── 20260718193640_wali_invites_and_linking.sql
│   │   │   ├── 20260718194936_conversation_started_milestone.sql
│   │   │   ├── 20260718195003_restrict_conversation_milestone_trigger_execute.sql
│   │   │   ├── 20260719080735_security_hardening_wali_and_invites.sql
│   │   │   ├── 20260719080749_private_profile_photos_bucket.sql
│   │   │   ├── 20260725183415_add_potential_match_status_and_journey_stage.sql
│   │   │   ├── 20260725183724_pre_journey_ritual_tables.sql
│   │   │   ├── 20260726120000_hide_raw_dob_expose_age.sql
│   │   │   ├── 20260726120100_wali_invites_expiry.sql
│   │   │   ├── 20260726120200_compatibility_scoring_security_definer.sql
│   │   │   ├── 20260726120300_restrict_ages_for_and_score_candidates_to_authenticated.sql
│   │   │   ├── 20260726120400_fix_expire_wali_invite_search_path.sql
│   │   │   ├── 20260726130000_wali_journey_visibility.sql
│   │   │   ├── 20260726140000_notifications.sql
│   │   │   ├── 20260726140100_lock_down_notification_internal_functions.sql
│   │   │   ├── 20260726140200_notify_new_message_revoke_public.sql
│   │   │   ├── 20260726150000_journey_ended_cooling_period_and_restart.sql
│   │   │   ├── 20260726150100_restart_journey_revoke_anon.sql
│   │   │   ├── 20260726160000_wali_extended_wali_real_gating.sql
│   │   │   ├── 20260726160100_mock_set_wali_plan.sql
│   │   │   └── 20260726170000_delete_own_account.sql
│   │   ├── retry_failed_photos.sh
│   │   ├── seed_dev_accounts.sql
│   │   └── upload_fake_photos.sh
│   └── test/
│       └── widget_test.dart
└── SYSTEM/
    ├── AGENTS/
    │   ├── ARCHIVE/
    │   │   ├── DOCUMENTATION_AGENT/
    │   │   │   ├── DOCUMENTATION_AGENT_PROJECT_ZYRA_2026-06-22_V1.md
    │   │   │   ├── DOCUMENTATION_AGENT_PROJECT_ZYRA_2026-06-22_V2.md
    │   │   │   ├── DOCUMENTATION_AGENT_PROJECT_ZYRA_2026-06-22_V3.md
    │   │   │   ├── DOCUMENTATION_AGENT_PROJECT_ZYRA_V2.md
    │   │   │   └── DOCUMENTATION_AGENT_PROJECT_ZYRA_V3.md
    │   │   ├── IMPACT_ANALYSIS_AGENT/
    │   │   │   ├── IMPACT_ANALYSIS_AGENT_PROJECT_ZYRA_2026-06-22_V1.md
    │   │   │   ├── IMPACT_ANALYSIS_AGENT_PROJECT_ZYRA_2026-06-22_V2.md
    │   │   │   └── IMPACT_ANALYSIS_AGENT_PROJECT_ZYRA_V2.md
    │   │   ├── INSPECTION_AGENT/
    │   │   │   ├── INSPECTION_AGENT_PROJECT_ZYRA_2026-06-22_V1.md
    │   │   │   ├── INSPECTION_AGENT_PROJECT_ZYRA_2026-06-22_V2.md
    │   │   │   └── INSPECTION_AGENT_PROJECT_ZYRA_V2.md
    │   │   ├── OUTPUT_REVIEW_AGENT/
    │   │   │   ├── OUTPUT_REVIEW_AGENT_PROJECT_ZYRA_2026-06-22_V1.md
    │   │   │   ├── OUTPUT_REVIEW_AGENT_PROJECT_ZYRA_2026-06-22_V2.md
    │   │   │   └── OUTPUT_REVIEW_AGENT_PROJECT_ZYRA_V2.md
    │   │   ├── PROJECT_READINESS_AGENT/
    │   │   │   ├── PROJECT_READINESS_AGENT_2026-06-22_V1.md
    │   │   │   ├── PROJECT_READINESS_AGENT_2026-06-22_V2.md
    │   │   │   └── PROJECT_READINESS_AGENT_V2.md
    │   │   ├── REPORTING_AGENT/
    │   │   │   ├── REPORTING_AGENT_PROJECT_ZYRA_2026-06-22_V1.md
    │   │   │   ├── REPORTING_AGENT_PROJECT_ZYRA_2026-06-22_V2.md
    │   │   │   ├── REPORTING_AGENT_PROJECT_ZYRA_2026-06-22_V3.md
    │   │   │   ├── REPORTING_AGENT_PROJECT_ZYRA_V2.md
    │   │   │   └── REPORTING_AGENT_PROJECT_ZYRA_V3.md
    │   │   ├── REPOSITORY_AGENT/
    │   │   │   ├── REPOSITORY_AGENT_PROJECT_ZYRA_2026-06-22_V1.md
    │   │   │   ├── REPOSITORY_AGENT_PROJECT_ZYRA_2026-06-22_V2.md
    │   │   │   ├── REPOSITORY_AGENT_PROJECT_ZYRA_2026-06-22_V3.md
    │   │   │   ├── REPOSITORY_AGENT_PROJECT_ZYRA_V2.md
    │   │   │   └── REPOSITORY_AGENT_PROJECT_ZYRA_V3.md
    │   │   └── RESOLUTION_CLASSIFIER/
    │   │       ├── RESOLUTION_CLASSIFIER_PROJECT_ZYRA_2026-06-22_V1.md
    │   │       ├── RESOLUTION_CLASSIFIER_PROJECT_ZYRA_2026-06-22_V2.md
    │   │       ├── RESOLUTION_CLASSIFIER_PROJECT_ZYRA_2026-06-22_V3.md
    │   │       ├── RESOLUTION_CLASSIFIER_PROJECT_ZYRA_V2.md
    │   │       └── RESOLUTION_CLASSIFIER_PROJECT_ZYRA_V3.md
    │   ├── DOCUMENTATION_AGENT/
    │   │   └── DOCUMENTATION_AGENT_PROJECT_ZYRA_V4.md
    │   ├── IMPACT_ANALYSIS_AGENT/
    │   │   └── IMPACT_ANALYSIS_AGENT_PROJECT_ZYRA_V3.md
    │   ├── INSPECTION_AGENT/
    │   │   └── INSPECTION_AGENT_PROJECT_ZYRA_V3.md
    │   ├── OUTPUT_REVIEW_AGENT/
    │   │   └── OUTPUT_REVIEW_AGENT_PROJECT_ZYRA_V3.md
    │   ├── PROJECT_READINESS_AGENT/
    │   │   └── PROJECT_READINESS_AGENT_V3.md
    │   ├── REPORTING_AGENT/
    │   │   └── REPORTING_AGENT_PROJECT_ZYRA_V4.md
    │   ├── REPOSITORY_AGENT/
    │   │   └── REPOSITORY_AGENT_PROJECT_ZYRA_V4.md
    │   └── RESOLUTION_CLASSIFIER/
    │       └── RESOLUTION_CLASSIFIER_PROJECT_ZYRA_V4.md
    ├── DECISIONS_REGISTER/
    │   └── DECISIONS_V1.md
    ├── DOCUMENTS/
    │   ├── ADVANCEMENT_CONDITIONS_CURRENT_VERSION_V1.md
    │   ├── ARCHIVE/
    │   │   ├── SUMMARY_STANDARD_2026-07-19_V1.md
    │   │   ├── SUMMARY_STANDARD_2026-07-19_V2.md
    │   │   ├── ZYRA_DOCUMENTATION_INDEX_2026-07-25_V1.md
    │   │   ├── ZYRA_EXECUTION_2026-07-19_V1.md
    │   │   ├── ZYRA_EXECUTION_2026-07-19_V2.md
    │   │   ├── ZYRA_PRODUCT_SPEC_2026-06-27_V1.md
    │   │   └── ZYRA_PRODUCT_SPEC_2026-07-04_V2.md
    │   ├── MASTER_CONTRACTS/
    │   │   └── ZYRA_EXECUTION_V3.md
    │   ├── MASTER_GOVERNANCE/
    │   │   └── ZYRA_GOVERNANCE_V1.md
    │   ├── MASTER_STANDARDS/
    │   │   ├── NAMING_CONVENTIONS_V1.md
    │   │   ├── SUMMARY_STANDARD_CURRENT_VERSION_V3.md
    │   │   └── ZYRA_STANDARDS_LIBRARY_V1.md
    │   ├── PROJECT_OVERVIEW_V1.md
    │   ├── TERMINOLOGY_STANDARDS_V1.md
    │   ├── TREEVIEW.md
    │   ├── ZYRA_ARCHITECTURE_CURRENT_VERSION_V2.md
    │   ├── ZYRA_DATABASE_SCHEMA_CURRENT_VERSION_V1.md
    │   ├── ZYRA_DOCUMENTATION_INDEX_CURRENT_VERSION_V2.md
    │   ├── ZYRA_INFRASTRUCTURE_STACK_V1.md
    │   ├── ZYRA_PRODUCT_SPEC_2026-07-26_V3.md
    │   ├── ZYRA_PRODUCT_SPEC_CURRENT_VERSION_V4.md
    │   └── ZYRA_WIDGET_LIBRARY_CURRENT_VERSION_V1.md
    ├── LOGS/
    │   ├── CHANGELOG_2026-07.md
    │   └── OPERATIONAL_LOG_2026-06.md
    ├── OUTSTANDING_ACTIONS/
    │   ├── OUTSTANDING_ACTIONS_2026-06-20_V1.md
    │   └── OUTSTANDING_ACTIONS_V2.md
    └── RESOURCES/
        ├── MEMORY/
        │   ├── org_state.json
        │   └── run_memory.json
        ├── ORGANISATION_STATE.md
        ├── REPORTS/
        │   ├── ESCALATIONS_2026-06-26_0B4DA7B7.md
        │   ├── ESCALATIONS_2026-06-26_BD84F2E9.md
        │   └── ZYRA_TERMINOLOGY_PRICING_AUDIT_2026-07-12_V1.md
        └── TEMPORARY/
            ├── CHATGPT_REPLY_REPO_NAVIGATION_2026-07-25.md
            ├── SESSION_HANDOVER_2026-07-25.md
            └── ZYRA_PROJECT_CHECK_HANDOVER_2026-06-27.md
```
