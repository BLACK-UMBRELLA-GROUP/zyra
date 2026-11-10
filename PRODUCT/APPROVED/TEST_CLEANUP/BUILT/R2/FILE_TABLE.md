---
id: BUILD-ZYRA-75-FILES
type: REPORT
status: CURRENT
feature: TEST CLEAN-UP
purpose: File-level round 2 verification and size table
owner: Codex
---

# Round 2 file changes and results

The result columns give passes, failures or errors, and skips in that order. Sizes are file bytes. The JSON records retain exact case and archive hashes.

| File | Before (B) | After (B) | Round 2 case or file actions | Post-74 P/F/S | Final P/F/S |
|---|---:|---:|---|---:|---:|
| `README.md` | 5,436 | 5,607 | Publication | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/dev/zyra_draft_browse_utility_presentation.dart` | 23,038 | 23,037 | App fix 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/dev/zyra_draft_journey_block_hide_sheet.dart` | 5,770 | 5,766 | App fix 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/dev/zyra_draft_journey_end_presentation.dart` | 8,141 | 8,140 | App fix 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/dev/zyra_one_journey_concept_shell.dart` | 305,224 | 305,343 | App fix 2 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/dev/zyra_one_journey_discovery_presentation.dart` | 43,844 | 44,024 | App fix 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/dev/zyra_one_journey_guardian_action.dart` | 8,422 | 8,564 | App fix 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/dev/zyra_one_journey_guardian_cards.dart` | 34,301 | 32,169 | App fix 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/dev/zyra_one_journey_guardian_tabs.dart` | 60,314 | 61,846 | App fix 2 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/dev/zyra_one_journey_journey_presentation.dart` | 66,648 | 66,647 | App fix 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/dev/zyra_one_journey_options.dart` | 16,492 | 16,600 | App fix 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/dev/zyra_one_journey_tab.dart` | 21,696 | 21,695 | App fix 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/screens/connections/connections_screen.dart` | 220,222 | 220,245 | App fix 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/screens/journey/journey_flow_screen.dart` | 318,534 | 318,481 | App fix 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/screens/wali/seeker_guardian_designs.dart` | 98,335 | 99,168 | App fix 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/theme/zyra_colors.dart` | 18,956 | 19,039 | App fix 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/widgets/floating_nav_bar.dart` | 70,368 | 73,707 | App fix 2 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/widgets/report_profile_sheet.dart` | 35,111 | 35,196 | App fix 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/widgets/zyra_browse_designs.dart` | 36,854 | 36,460 | App fix 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/lib/widgets/zyra_guardian_add_card.dart` | 0 | 3,279 | App fix 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/test/browse_edge_alignment_test.dart` | 18,799 | 18,871 | App fix 6 | 1 / 6 / 0 | 7 / 0 / 0 |
| `SOURCE/test/browse_more_actions_haptics_test.dart` | 6,229 | 6,297 | Update 1 | 5 / 0 / 0 | 5 / 0 / 0 |
| `SOURCE/test/browse_options_menu_test.dart` | 48,147 | 48,581 | App fix 2 | 28 / 2 / 0 | 30 / 0 / 0 |
| `SOURCE/test/browse_photo_tap_navigation_test.dart` | 31,827 | 32,236 | App fix 4 | 25 / 4 / 0 | 29 / 0 / 0 |
| `SOURCE/test/compatibility_route_toggle_test.dart` | 33,896 | 34,447 | Update 1 | 18 / 1 / 0 | 19 / 0 / 0 |
| `SOURCE/test/draft_journey_end_presentation_test.dart` | 9,854 | 9,927 | Update 1 | 8 / 0 / 0 | 8 / 0 / 0 |
| `SOURCE/test/founder_launch_review_test.dart` | 31,883 | 31,963 | Finding 28 | 7 / 28 / 0 | 7 / 28 / 0 |
| `SOURCE/test/guardian_card_interaction_test.dart` | 28,363 | 28,508 | Update 1 | 28 / 0 / 0 | 28 / 0 / 0 |
| `SOURCE/test/guardian_circle_topic_options_test.dart` | 89,363 | 83,930 | Update 8, Finding 1 | 55 / 9 / 0 | 63 / 1 / 0 |
| `SOURCE/test/guardian_one_page_designs_test.dart` | 43,546 | 41,136 | Update 29 | 16 / 29 / 0 | 45 / 0 / 0 |
| `SOURCE/test/guardian_section_labels_test.dart` | 26,843 | 25,833 | Update 3 | 16 / 3 / 0 | 19 / 0 / 0 |
| `SOURCE/test/guardianship_manager_phase1_test.dart` | 11,204 | 11,602 | App fix 3 | 5 / 3 / 0 | 8 / 0 / 0 |
| `SOURCE/test/journey_card_layout_choices_test.dart` | 41,994 | 17,039 | Update 11 | 2 / 11 / 0 | 13 / 0 / 0 |
| `SOURCE/test/journey_options_v3_layout_test.dart` | 13,368 | 13,649 | Update 1 | 9 / 0 / 0 | 9 / 0 / 0 |
| `SOURCE/test/membership_wallet_visual_test.dart` | 34,831 | 35,199 | Fixture 2 | 16 / 2 / 0 | 18 / 0 / 0 |
| `SOURCE/test/migration_inventory_test.dart` | 810 | 0 | Retire 1 | 0 / 1 / 0 | 0 / 0 / 0 |
| `SOURCE/test/no_heart_icons_test.dart` | 1,393 | 1,574 | Update 1 | 0 / 1 / 0 | 1 / 0 / 0 |
| `SOURCE/test/onboarding_checkpoint_persistence_test.dart` | 15,460 | 15,824 | Update 2 | 9 / 2 / 0 | 11 / 0 / 0 |
| `SOURCE/test/one_journey_back_button_preview_test.dart` | 38,765 | 38,325 | Update 5, Finding 2 | 7 / 7 / 0 | 12 / 2 / 0 |
| `SOURCE/test/one_journey_bottom_close_cue_test.dart` | 35,272 | 35,847 | Update 5, Finding 1, Retire 1 | 15 / 7 / 0 | 21 / 1 / 0 |
| `SOURCE/test/one_journey_compact_controls_test.dart` | 27,035 | 28,282 | Fixture 7 | 9 / 7 / 0 | 16 / 0 / 0 |
| `SOURCE/test/one_journey_ended_card_test.dart` | 42,320 | 42,535 | Fixture 3 | 29 / 3 / 0 | 32 / 0 / 0 |
| `SOURCE/test/one_journey_guardian_details_polish_test.dart` | 38,011 | 25,420 | Update 13, Retire 3 | 2 / 16 / 0 | 16 / 0 / 0 |
| `SOURCE/test/one_journey_inline_options_test.dart` | 22,728 | 22,803 | Update 1 | 16 / 0 / 0 | 16 / 0 / 0 |
| `SOURCE/test/one_journey_monthly_capacity_widget_test.dart` | 63,575 | 42,801 | Retire 12, Update 20 | 0 / 32 / 0 | 21 / 0 / 0 |
| `SOURCE/test/one_journey_prior_compatibility_access_test.dart` | 19,218 | 19,408 | Fixture 2 | 8 / 2 / 0 | 10 / 0 / 0 |
| `SOURCE/test/one_journey_pull_down_routes_test.dart` | 21,003 | 24,065 | Finding 2, Update 1 | 6 / 3 / 0 | 8 / 2 / 0 |
| `SOURCE/test/one_journey_theme_actions_test.dart` | 39,107 | 34,817 | Update 16 | 0 / 16 / 0 | 16 / 0 / 0 |
| `SOURCE/test/request_page_options_context_test.dart` | 36,049 | 35,869 | Fixture 9 | 15 / 9 / 0 | 24 / 0 / 0 |
| `SOURCE/test/request_shell_titles_circle_test.dart` | 23,053 | 23,797 | Update 11 | 4 / 11 / 0 | 17 / 0 / 0 |
| `SOURCE/test/seeker_wali_tab_truth_test.dart` | 19,040 | 19,118 | App fix 2 | 9 / 2 / 0 | 11 / 0 / 0 |
| `SOURCE/test/support/oa198_historical_inventory.dart` | 465 | 0 | Publication | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/test/view_request_draft_widget_test.dart` | 195,410 | 195,171 | Update 1, Fixture 12, Finding 3 | 91 / 16 / 0 | 104 / 3 / 0 |
| `SOURCE/test/visual/approved/manifest.json` | 160,610 | 185,551 | Fixture 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/test/visual/approved/queue75/g11_seeker__adam_main.png` | 0 | 94,681 | Fixture 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/test/visual/approved/queue75/g12_seeker__yusuf_additional.png` | 0 | 94,426 | Fixture 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/test/visual/approved/queue75/gm01_family_review.png` | 0 | 153,092 | Fixture 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/test/visual/approved/queue75/gm04_all_caught_up.png` | 0 | 123,577 | Fixture 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/test/visual/approved/queue75/k07_card__omar_invited.png` | 0 | 76,824 | Fixture 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/test/visual/approved/queue75/k08_card__add_a_guardian.png` | 0 | 78,623 | Fixture 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/test/visual/approved/queue75/k17_basic__card_front_hassan.png` | 0 | 80,960 | Fixture 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/test/visual/approved/queue75/m05_new_member.png` | 0 | 122,584 | Fixture 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/test/visual/approved/queue75/m06_seeker_basic.png` | 0 | 130,047 | Fixture 1 | 0 / 0 / 0 | 0 / 0 / 0 |
| `SOURCE/test/visual/zyra_visual_regression_test.dart` | 66,046 | 52,668 | Retire 68, Fixture 36, Finding 8 | 63 / 112 / 0 | 109 / 0 / 0 |
| `SOURCE/test/widget_test.dart` | 5,013 | 5,203 | App fix 1 | 6 / 1 / 0 | 7 / 0 / 0 |
| `SOURCE/test/zyra_dev_app_icon_test.dart` | 8,880 | 6,774 | Update 1, Retire 2 | 4 / 3 / 0 | 5 / 0 / 0 |
| `SOURCE/test/zyra_oa198_probe_score_replay_bridge_artifact_test.dart` | 9,182 | 6,291 | Retire 1 | 3 / 1 / 0 | 3 / 0 / 0 |
| `SOURCE/test/zyra_oa198_replay_bridge_artifact_test.dart` | 20,545 | 17,963 | Retire 1 | 5 / 1 / 0 | 5 / 0 / 0 |
| `SOURCE/test/zyra_oa198_replay_bridge_v2_artifact_test.dart` | 11,011 | 6,412 | Retire 1 | 3 / 1 / 0 | 3 / 0 / 0 |
| `SOURCE/test/zyra_request_page_titles_test.dart` | 8,587 | 8,587 | App fix 3 | 12 / 3 / 0 | 15 / 0 / 0 |
| `SOURCE/test/zyra_subscription_wallet_preview_test.dart` | 45,436 | 45,436 | Finding 2 | 34 / 2 / 0 | 34 / 2 / 0 |
| `SOURCE/test/zyra_wordmark_colour_test.dart` | 5,310 | 5,310 | Resolved by line 74 1 | 13 / 0 / 0 | 13 / 0 / 0 |
| `SYSTEM/tools/ui_gate/BASELINES/manifest.json` | 160,639 | 185,580 | Fixture 1 | 0 / 0 / 0 | 0 / 0 / 0 |
