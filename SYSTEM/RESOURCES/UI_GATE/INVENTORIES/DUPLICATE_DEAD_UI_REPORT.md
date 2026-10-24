# ZYRA Duplicate / Dead UI Report

**Generated:** 2026-10-03T14:49:29.099681+00:00
**Programme:** OA-ZYRA-257 · **Decision:** DR-ZYRA-214

This is reachability evidence, not deletion authority. Test-only, routed-by-name,
developer-only and future components can legitimately have zero `lib/` consumers.
Fable/Founder decide merge, archive, keep or remove; the gate changes nothing.

## Unreferenced widget candidates (17)

| Component | File | Contract status | Replacement | Risk |
|---|---|---|---|---|
| `anchored_card_overlay` | `lib/widgets/anchored_card_overlay.dart` | unreferenced-candidate | — | High — intent unknown |
| `FabContinueButton` | `lib/widgets/fab_continue_button.dart` | retired-candidate | current in-flow Journey continuation control | Medium — inspect tests/routes before archival |
| `GlassIconButton` | `lib/widgets/glass_icon_button.dart` | unreferenced-candidate | — | High — intent unknown |
| `GlassFlashCircle` | `lib/widgets/glass_icon_button.dart` | unreferenced-candidate | — | High — intent unknown |
| `HelpReportSheet` | `lib/widgets/help_report_sheet.dart` | unreferenced-candidate | — | High — intent unknown |
| `NotificationBell` | `lib/widgets/notification_bell.dart` | retired-candidate | Dashboard notification card and nav badge | Medium — inspect tests/routes before archival |
| `report_profile_sheet` | `lib/widgets/report_profile_sheet.dart` | unreferenced-candidate | — | High — intent unknown |
| `searchable_list_picker` | `lib/widgets/searchable_list_picker.dart` | unreferenced-candidate | — | High — intent unknown |
| `ZyraDashboardExperience` | `lib/widgets/zyra_dashboard_experience.dart` | unreferenced-candidate | — | High — intent unknown |
| `ZyraDashboardLearningPreviewCard` | `lib/widgets/zyra_dashboard_experience.dart` | unreferenced-candidate | — | High — intent unknown |
| `zyra_guardian_capacity_notice` | `lib/widgets/zyra_guardian_capacity_notice.dart` | unreferenced-candidate | — | High — intent unknown |
| `zyra_locked_feature_upgrade` | `lib/widgets/zyra_locked_feature_upgrade.dart` | unreferenced-candidate | — | High — intent unknown |
| `zyra_my_zyra_design_kit` | `lib/widgets/zyra_my_zyra_design_kit.dart` | unreferenced-candidate | — | High — intent unknown |
| `zyra_paused_limit_refusal` | `lib/widgets/zyra_paused_limit_refusal.dart` | unreferenced-candidate | — | High — intent unknown |
| `ZyraResolvedDashboard` | `lib/widgets/zyra_resolved_dashboard.dart` | unreferenced-candidate | — | High — intent unknown |
| `ZyraSupportiveDashboard` | `lib/widgets/zyra_supportive_dashboard.dart` | unreferenced-candidate | — | High — intent unknown |
| `zyra_write_feedback` | `lib/widgets/zyra_write_feedback.dart` | unreferenced-candidate | — | High — intent unknown |

## Duplicate widget names (0)

No same-named widget classes were detected.

## Queue discipline

These observations remain under OA-ZYRA-257 until product/design triage.
A separate OA is required only if Fable graduates a genuine independent finding.
