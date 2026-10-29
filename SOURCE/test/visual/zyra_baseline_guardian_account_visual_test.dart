// Authorized screenshot-only baseline of the unchanged local Founder shell.
// Opt in explicitly so ordinary test runs cannot rewrite approved pictures.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_settings_details.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

import 'baseline_capture_support.dart';

const _capture = bool.fromEnvironment('ZYRA_BASELINE_CAPTURE');
const _account = 'profile_membership_settings';
const _guardians = 'guardians';

ZyraPreviewNavigationCheckpoint _accountCheckpoint(
  bool guardian, {
  required ZyraConceptAccountAction action,
  ZyraConceptSettingsDetail? detail,
  ViewRequestDraftModel? model,
}) => ZyraPreviewNavigationCheckpoint(
  guardian: guardian,
  model: (model ?? ViewRequestDraftModel(capacity: 3)).snapshot(),
  tab: guardian ? 3 : 4,
  pages: ['settings', 'account_action', if (detail != null) 'settings_detail'],
  accountDestination: action.name,
  settingsDetail: detail?.name,
);

void main() {
  setUpAll(baselineSetUp);
  tearDownAll(baselineTearDown);

  for (final guardian in [false, true]) {
    final role = guardian ? 'Guardian' : 'Seeker';
    final profileTab = guardian ? 3 : 4;

    for (final page in [
      'settings',
      'personalisation',
      'compatibility_store',
      'help_support',
    ]) {
      testWidgets(
        '$role baseline $page',
        (tester) async {
          final h = BaselineHarness(tester, group: 'guardian_account');
          await h.mount(guardian: guardian, tab: profileTab, pages: [page]);
          h.assertPage(page);
          await h.capture(
            _account,
            page,
            'normal',
            'Restored safe local Profile checkpoint to $page; unchanged shell.',
          );
        },
        skip: !_capture,
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );
    }

    testWidgets(
      '$role baseline Help search states',
      (tester) async {
        final h = BaselineHarness(tester, group: 'guardian_account');
        await h.mount(
          guardian: guardian,
          tab: profileTab,
          pages: ['help_support'],
        );
        await tester.enterText(h.key('help-support-preview-search'), 'sign in');
        await h.capture(
          _account,
          'help_support',
          'search_matches',
          'Actual local Help search field > sign in.',
        );
        await tester.enterText(
          h.key('help-support-preview-search'),
          'zzzz-no-result',
        );
        await h.capture(
          _account,
          'help_support',
          'search_empty',
          'Actual local Help search field > unmatched query; no answer invented.',
        );
      },
      skip: !_capture,
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      '$role baseline personalisation choice sheets',
      (tester) async {
        final h = BaselineHarness(tester, group: 'guardian_account');
        for (final choice in ['Background', 'Haptic feel']) {
          await h.mount(
            guardian: guardian,
            tab: profileTab,
            pages: ['personalisation'],
          );
          await h.tapText(choice);
          await h.capture(
            _account,
            'personalisation',
            choice == 'Background' ? 'background_choices' : 'haptic_choices',
            'Actual Personalisation > $choice choice sheet; nothing selected.',
          );
        }
      },
      skip: !_capture,
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    final actions = [
      ZyraConceptAccountAction.signInSecurity,
      ZyraConceptAccountAction.appLock,
      ZyraConceptAccountAction.advanced,
      ZyraConceptAccountAction.visibility,
      guardian
          ? ZyraConceptAccountAction.guardianPrivacy
          : ZyraConceptAccountAction.hiddenProfiles,
      ZyraConceptAccountAction.notificationSettings,
      ZyraConceptAccountAction.feedback,
      ZyraConceptAccountAction.privacyData,
    ];
    for (final action in actions) {
      testWidgets(
        '$role baseline settings overview ${action.name}',
        (tester) async {
          final h = BaselineHarness(tester, group: 'guardian_account');
          await h.mount(
            guardian: guardian,
            checkpoint: _accountCheckpoint(guardian, action: action),
          );
          h.assertPage('account_action');
          await h.capture(
            _account,
            'account_action',
            'overview_${action.name}',
            'Safe local Settings parent chain; ${action.name} overview.',
          );
        },
        skip: !_capture,
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );
    }

    final details = <(ZyraConceptAccountAction, ZyraConceptSettingsDetail)>[
      (
        ZyraConceptAccountAction.signInSecurity,
        ZyraConceptSettingsDetail.recovery,
      ),
      (ZyraConceptAccountAction.appLock, ZyraConceptSettingsDetail.appLock),
      (
        ZyraConceptAccountAction.advanced,
        ZyraConceptSettingsDetail.resetProfile,
      ),
      (
        ZyraConceptAccountAction.advanced,
        ZyraConceptSettingsDetail.deleteAccount,
      ),
      (
        ZyraConceptAccountAction.visibility,
        ZyraConceptSettingsDetail.discovery,
      ),
      if (!guardian)
        (
          ZyraConceptAccountAction.hiddenProfiles,
          ZyraConceptSettingsDetail.hiddenProfiles,
        ),
      (
        ZyraConceptAccountAction.notificationSettings,
        ZyraConceptSettingsDetail.notifications,
      ),
      (ZyraConceptAccountAction.feedback, ZyraConceptSettingsDetail.feedback),
      (
        ZyraConceptAccountAction.privacyData,
        ZyraConceptSettingsDetail.privacyPolicy,
      ),
      (ZyraConceptAccountAction.privacyData, ZyraConceptSettingsDetail.terms),
    ];
    for (final (action, detail) in details) {
      testWidgets(
        '$role baseline settings detail ${detail.name}',
        (tester) async {
          final h = BaselineHarness(tester, group: 'guardian_account');
          await h.mount(
            guardian: guardian,
            checkpoint: _accountCheckpoint(
              guardian,
              action: action,
              detail: detail,
            ),
          );
          h.assertPage('settings_detail');
          await h.capture(
            _account,
            'settings_detail',
            detail.name,
            'Safe local Settings > ${action.name} > ${detail.name} chain.',
          );
        },
        skip: !_capture,
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );
    }

    testWidgets(
      '$role baseline account safety and invite',
      (tester) async {
        final h = BaselineHarness(tester, group: 'guardian_account');
        await h.mount(guardian: guardian, tab: profileTab);
        await h.tap('concept_safety_advice');
        h.assertPage('safety');
        await h.capture(
          _account,
          'safety',
          'no_subject',
          'Profile > Safety & advice; actual local action, no person selected.',
        );
        await h.mount(guardian: guardian, tab: profileTab);
        await h.tap('concept_invite');
        h.assertPage('account_action');
        await h.capture(
          _account,
          'account_action',
          'invite_held',
          'Profile > Invite someone to ZYRA; actual held local action.',
        );
      },
      skip: !_capture,
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      '$role baseline membership sections and review',
      (tester) async {
        final h = BaselineHarness(tester, group: 'guardian_account');
        await h.mount(guardian: guardian, tab: profileTab);
        await h.tap('concept_membership');
        h.assertPage('membership');
        for (final section in [
          'current',
          'unlocks',
          'seeker',
          'guardian',
          'family',
        ]) {
          await h.tap('membership-section-$section');
          await h.capture(
            _account,
            'membership',
            'section_$section',
            'Profile > Membership > actual $section section control.',
          );
          if (section == 'seeker' || section == 'guardian') {
            final next = h.key('membership-next');
            if (tester.widget<IconButton>(next).onPressed != null) {
              await h.tap('membership-next');
            }
            await h.capture(
              _account,
              'membership',
              'section_${section}_basic',
              'Actual $section membership pager > second Basic card.',
            );
          }
        }
        await h.tap('membership-section-${guardian ? 'guardian' : 'seeker'}');
        final next = h.key('membership-next');
        if (tester.widget<IconButton>(next).onPressed != null) {
          await h.tap('membership-next');
        }
        await h.capture(
          _account,
          'membership',
          'basic_paid_before',
          'Membership role pager > Basic; unchanged previously-paid example.',
        );
        await h.tap(
          'membership-select-${guardian ? 'guardianBasic' : 'seekerBasic'}',
        );
        await h.tap('membership-review-selection');
        h.assertPage('membership_review');
        await h.capture(
          _account,
          'membership_review',
          'basic_paid_before',
          'Actual Basic selection > Review selection; no store or payment.',
        );
        await h.mount(guardian: guardian, tab: profileTab);
        await h.tap('concept_membership');
        await h.tap('concept_cancel_membership');
        h.assertPage('account_action');
        await h.capture(
          _account,
          'account_action',
          'cancel_membership_held',
          'Actual Current Membership > Cancel membership; held explanation only.',
        );
      },
      skip: !_capture,
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      '$role baseline membership payment history examples',
      (tester) async {
        final h = BaselineHarness(tester, group: 'guardian_account');
        for (final history in ['neverPaid', 'unknown']) {
          await h.mount(guardian: guardian, tab: profileTab);
          await h.tap('concept_membership');
          await h.controls();
          await h.tap('concept_membership_history_$history');
          await h.closeControls();
          await h.tap('membership-section-${guardian ? 'guardian' : 'seeker'}');
          final next = h.key('membership-next');
          if (tester.widget<IconButton>(next).onPressed != null) {
            await h.tap('membership-next');
          }
          await h.capture(
            _account,
            'membership',
            'basic_history_$history',
            'Actual Membership controls > $history > Basic role pager.',
          );
        }
      },
      skip: !_capture,
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      '$role baseline subscriptions',
      (tester) async {
        final h = BaselineHarness(tester, group: 'guardian_account');
        await h.mount(guardian: guardian, tab: profileTab);
        await h.tap('concept_subscriptions');
        h.assertPage('subscriptions');
        await h.capture(
          _account,
          'subscriptions',
          'normal',
          'Profile > Your subscriptions; unchanged local wallet.',
        );
      },
      skip: !_capture,
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      '$role baseline switch account coverage',
      (tester) async {
        final h = BaselineHarness(tester, group: 'guardian_account');
        final other = guardian ? 'seeker' : 'guardian';
        for (final coverage in [
          'individualOne',
          'assignedFamily',
          'basic',
          'none',
          'unavailable',
        ]) {
          await h.mount(guardian: guardian, tab: profileTab);
          await h.controls();
          await h.tap('concept_wallet_coverage_$coverage');
          await h.closeControls();
          await h.tap('draft_role_$other');
          h.assertPage('switch_account_signup');
          await h.capture(
            _account,
            'switch_account_signup',
            'coverage_$coverage',
            'Actual Profile controls > other role $coverage > Switch.',
          );
        }
        await h.mount(guardian: guardian, tab: profileTab);
        await h.controls();
        await h.tap('concept_switch_needs_signup');
        await h.tap('concept_wallet_coverage_individualOne');
        await h.closeControls();
        await h.tap('draft_role_$other');
        await h.capture(
          _account,
          'switch_account_signup',
          'needs_signup',
          'Actual Profile controls > Needs sign-up with existing coverage > Switch.',
        );
        await h.tap('wallet_primary_$other');
        h.assertPage('switch_account_setup');
        await h.capture(
          _account,
          'switch_account_setup',
          'normal',
          'Actual switch wallet > Set up other profile; local setup overview.',
        );
      },
      skip: !_capture,
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      '$role baseline Profile controls',
      (tester) async {
        final h = BaselineHarness(tester, group: 'guardian_account');
        await h.mount(guardian: guardian, tab: profileTab);
        await h.controls();
        await h.capture(
          _account,
          'controls',
          'profile',
          'Actual admitted three-second hold on Profile; controls intentionally visible.',
        );
      },
      skip: !_capture,
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }

  for (final page in ['own_profile_preview', 'edit_profile', 'manage_photos']) {
    testWidgets(
      'Seeker baseline retained $page',
      (tester) async {
        final h = BaselineHarness(tester, group: 'guardian_account');
        await h.mount(tab: 4);
        await h.tap(switch (page) {
          'own_profile_preview' => 'concept_preview_profile',
          'edit_profile' => 'concept_edit_profile',
          _ => 'concept_manage_photos',
        });
        h.assertPage(page);
        await h.capture(
          _account,
          page,
          'normal',
          'Actual Seeker Profile action opens the retained local $page.',
        );
      },
      skip: !_capture,
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }

  testWidgets(
    'Seeker baseline populated hidden profiles',
    (tester) async {
      final h = BaselineHarness(tester, group: 'guardian_account');
      final model = ViewRequestDraftModel(capacity: 3)..hide('draft-sara');
      await h.mount(
        checkpoint: _accountCheckpoint(
          false,
          action: ZyraConceptAccountAction.hiddenProfiles,
          model: model,
        ),
      );
      h.assertPage('account_action');
      await h.capture(
        _account,
        'account_action',
        'hidden_profiles_populated',
        'Safe local checkpoint containing the supported fictional Hide transition.',
      );
      await h.tap('concept_hidden_profile_unhide_draft-sara');
      await h.capture(
        _account,
        'account_action',
        'hidden_profile_restore_confirmation',
        'Actual Hidden Profiles > Unhide confirmation; not submitted.',
      );
    },
    skip: !_capture,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  for (var tab = 0; tab < 4; tab++) {
    testWidgets(
      'Guardian baseline root tab $tab',
      (tester) async {
        final h = BaselineHarness(tester, group: 'guardian_account');
        final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(1);
        await h.mount(guardian: true, tab: tab, model: model);
        final page = [
          'tab_my_zyra',
          'tab_network',
          'tab_seekers',
          'tab_profile',
        ][tab];
        await h.capture(
          tab == 3 ? _account : _guardians,
          page,
          'normal',
          'Guardian root tab $tab with one supported local Active Journey.',
        );
        if (tab < 3) {
          await h.controls();
          await h.capture(
            _guardians,
            'controls',
            'root_$tab',
            'Actual Guardian root $tab admitted hold; contextual controls visible.',
          );
        }
      },
      skip: !_capture,
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }

  testWidgets(
    'Guardian baseline network and profile destinations',
    (tester) async {
      final h = BaselineHarness(tester, group: 'guardian_account');
      await h.mount(guardian: true, tab: 1);
      await h.tapFinder(find.text('View profile').hitTestable().first);
      h.assertPage('guardian_network_profile');
      await h.capture(
        _guardians,
        'guardian_network_profile',
        'normal',
        'Actual Guardian Network > View profile.',
      );
      await h.mount(guardian: true, tab: 1);
      await h.tap('concept_network_suggestion');
      h.assertPage('network_request');
      await h.capture(
        _guardians,
        'network_request',
        'confirmation',
        'Actual Guardian Network > Speak to Guardian; no request sent.',
      );
      final id = h.latest.personId!;
      await h.tap('concept_confirm_network_request_$id');
      await h.tap('concept_network_sent');
      await h.capture(
        _guardians,
        'tab_network',
        'sent_populated',
        'Actual local Speak confirmation > Sent tab.',
      );
      await h.tap('concept_network_received');
      await h.capture(
        _guardians,
        'tab_network',
        'received_empty',
        'Actual Guardian Network Received tab; no received fixture exists.',
      );
    },
    skip: !_capture,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Guardian baseline linked profile and Journey',
    (tester) async {
      final h = BaselineHarness(tester, group: 'guardian_account');
      final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(1);
      await h.mount(guardian: true, tab: 0, model: model);
      await h.tapFinder(find.text('View profile').hitTestable().first);
      h.assertPage('guardian_linked_profile');
      await h.capture(
        _guardians,
        'guardian_linked_profile',
        'normal',
        'Actual Guardian My ZYRA family card > View profile.',
      );
      await h.mount(guardian: true, tab: 2, model: model);
      await h.tapText('Open current Journey');
      h.assertPage('guardian');
      await h.capture(
        _guardians,
        'guardian',
        'active_journey',
        'Actual embedded Seeker workspace > Open current Journey.',
      );
    },
    skip: !_capture,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Guardian baseline Basic and Additional boundaries',
    (tester) async {
      final h = BaselineHarness(tester, group: 'guardian_account');
      final basic = ViewRequestDraftModel(capacity: 3)
        ..seedJourneys(1)
        ..setSampleGuardianMembership(
          'draft-guardian-hassan',
          DraftGuardianMembership.basic,
        );
      await h.mount(
        guardian: true,
        model: basic,
        guardianMembership: 'Guardian Basic',
      );
      await h.capture(
        _guardians,
        'tab_my_zyra',
        'basic_insights_locked',
        'Safe local checkpoint matching the actual Guardian Basic plan control.',
      );
      await h.mount(
        guardian: true,
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: true,
          model: ViewRequestDraftModel(capacity: 3).snapshot(),
          tab: 1,
          pages: const [],
          mainGuardianId: 'draft-guardian-yusuf',
        ),
      );
      await h.capture(
        _guardians,
        'tab_network',
        'additional_guardian_held',
        'Safe local checkpoint after supported Main change; Hassan is Additional.',
      );
      await h.mount(guardian: true);
      await h.capture(
        _guardians,
        'tab_my_zyra',
        'no_current_journey',
        'Fresh local Guardian preview with linked Seeker and no Active Journey.',
      );
    },
    skip: !_capture,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Guardian baseline unlinked roots and held invitation',
    (tester) async {
      final h = BaselineHarness(tester, group: 'guardian_account');
      for (var tab = 0; tab < 3; tab++) {
        await h.mount(
          guardian: true,
          checkpoint: ZyraPreviewNavigationCheckpoint(
            guardian: true,
            model: ViewRequestDraftModel(capacity: 3).snapshot(),
            tab: tab,
            pages: const [],
            removedGuardians: const ['draft-guardian-hassan'],
          ),
        );
        await h.capture(
          _guardians,
          ['tab_my_zyra', 'tab_network', 'tab_seekers'][tab],
          'unlinked_empty',
          'Safe local checkpoint after supported Guardian unlink; Guardian root $tab.',
        );
      }
      await h.mount(
        guardian: true,
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: true,
          model: ViewRequestDraftModel(capacity: 3).snapshot(),
          tab: 1,
          pages: const [],
          removedGuardians: const ['draft-guardian-hassan'],
        ),
      );
      await h.tapFinder(find.byIcon(Icons.add).hitTestable());
      h.assertPage('held_action');
      await h.capture(
        _guardians,
        'held_action',
        'invite_seeker',
        'Actual unlinked Guardian Network > Invite your Seeker; held local explanation.',
      );
    },
    skip: !_capture,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
