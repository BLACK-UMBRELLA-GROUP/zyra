// OA-ZYRA-371: fresh route/presenter fixtures from the accepted app and V9.
// Admission stays in the shell. Email fixtures measure the actual presenter;
// pre-existing developer-entry tests separately check its guarded navigation.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_developer_inactivity_email.dart';
import 'package:zyra/dev/zyra_draft_compatibility_store_presentation.dart';
import 'package:zyra/dev/zyra_email_settings_preview.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_pause_private_preview.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_info_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_one_journey_settings_details.dart';
import 'package:zyra/dev/zyra_one_journey_switch_signup_preview.dart';
import 'package:zyra/dev/zyra_privacy_security_preview.dart';
import 'package:zyra/dev/zyra_signup_preview.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_subscription_wallet_preview.dart';
import 'package:zyra/dev/zyra_profile_small_pages_preview.dart';
import 'package:zyra/dev/zyra_subscription_wallet_draft.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import 'package:zyra/screens/profile/edit_photos_screen.dart';
import 'package:zyra/screens/profile/my_profile_preview_screen.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/zyra_guardian_dashboard_profile_card.dart';
import 'package:zyra/widgets/zyra_membership_choices.dart';

import 'baseline_capture_support.dart';

// Optional direct fixture matrix. The shared raster callback normally measures
// all four V9 combinations itself and restores geometry, so this stays false.
bool line126RemainingAuditAllDimensions = false;

const _commonOverviews = [
  ZyraConceptAccountAction.signInSecurity,
  ZyraConceptAccountAction.appLock,
  ZyraConceptAccountAction.advanced,
  ZyraConceptAccountAction.notificationSettings,
  ZyraConceptAccountAction.feedback,
  ZyraConceptAccountAction.privacyData,
];
const _commonDetails = [
  (ZyraConceptAccountAction.advanced, ZyraConceptSettingsDetail.resetProfile),
  (ZyraConceptAccountAction.advanced, ZyraConceptSettingsDetail.deleteAccount),
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
final _observations = <Map<String, Object?>>[];

Finder _key(String id) => find.byKey(ValueKey(id));

class _Frame {
  const _Frame(this.size, this.scale);
  final Size size;
  final double scale;
  String get id =>
      '${size.width.toInt()}x${size.height.toInt()}_${scale.toStringAsFixed(1)}';
  BaselineHarness harness(WidgetTester tester, String state) => BaselineHarness(
    tester,
    group: 'line126_remaining_${id}_$state',
    logicalSize: size,
    textScale: scale,
    safePadding: size.width == 375
        ? const EdgeInsets.only(top: 20)
        : const EdgeInsets.only(top: 59, bottom: 34),
    reduceMotion: true,
  );
}

void _record(BaselineHarness h, String state, {String kind = 'shell_route'}) {
  _observations.add({
    'state': state,
    'kind': kind,
    'group': h.group,
    'guardian': h.latest.guardian,
    'plan': h.latest.guardian
        ? h.latest.guardianMembership
        : h.latest.seekerMembership,
    'tab': h.latest.tab,
    'pages': h.latest.pages,
    'logical_size': [h.logicalSize.width, h.logicalSize.height],
    'text_scale': h.textScale,
    'presenters':
        h.tester.allWidgets
            .map((widget) => widget.runtimeType.toString())
            .where((name) => name.startsWith('Zyra') || name.endsWith('Screen'))
            .toSet()
            .toList()
          ..sort(),
  });
}

// Q228 / LOCK46: these pages and the entered sign-up can remount during the
// real audit reflow. Resolve their exact keyed owner after every flush;
// never retain a ScrollPosition across that asynchronous reflow.
Future<void> _readCurrentPage(
  BaselineHarness h,
  String state,
  String ownerKey,
) async {
  ScrollPosition currentPosition() {
    final owner = _key(ownerKey);
    expect(
      owner,
      findsOneWidget,
      reason: 'Current migrated page scroll owner: $state',
    );
    final scroll = find.descendant(
      of: owner,
      matching: find.byType(Scrollable),
    );
    expect(
      scroll,
      findsOneWidget,
      reason: 'Unique current page reader: $state',
    );
    final current = h.tester.state<ScrollableState>(scroll);
    expect(ModalRoute.of(current.context)?.isCurrent ?? true, isTrue);
    final position = current.position;
    expect(position.axis, Axis.vertical);
    expect(position.hasContentDimensions, isTrue);
    expect(position.viewportDimension, greaterThan(0));
    return position;
  }

  await h.flush();
  final first = currentPosition();
  first.jumpTo(first.minScrollExtent);
  await h.flush();
  var count = 0;
  while (true) {
    final position = currentPosition();
    if (position.pixels >= position.maxScrollExtent - .5) break;
    position.jumpTo(
      math.min(
        position.maxScrollExtent,
        position.pixels + math.max(1, position.viewportDimension * .7),
      ),
    );
    await h.flush();
    expect(++count, lessThan(80), reason: 'Bounded reading scroll: $state');
  }
  final last = currentPosition();
  last.jumpTo(last.minScrollExtent);
  await h.flush();
}

Future<void> _readAll(BaselineHarness h, String state) async {
  await h.flush();
  final positions = h.tester
      .stateList<ScrollableState>(find.byType(Scrollable))
      .where((state) => ModalRoute.of(state.context)?.isCurrent ?? true)
      .map((state) => state.position)
      .where(
        (position) =>
            position.axis == Axis.vertical &&
            position.hasContentDimensions &&
            position.viewportDimension > 0,
      )
      .toSet();
  for (final position in positions) {
    position.jumpTo(position.minScrollExtent);
    await h.flush();
    var count = 0;
    while (position.pixels < position.maxScrollExtent - .5) {
      position.jumpTo(
        math.min(
          position.maxScrollExtent,
          position.pixels + math.max(1, position.viewportDimension * .7),
        ),
      );
      await h.flush();
      expect(++count, lessThan(80), reason: 'Bounded reading scroll: $state');
    }
    position.jumpTo(position.minScrollExtent);
    await h.flush();
  }
}

Future<BaselineHarness> _mount(
  WidgetTester tester,
  _Frame frame, {
  required bool guardian,
  required bool basic,
  required String state,
  List<String> pages = const [],
  int tab = 4,
  ZyraConceptAccountAction? action,
  ZyraConceptSettingsDetail? detail,
  ViewRequestDraftModel? model,
  String? quickPage,
  ZyraWalletReadiness seekerReadiness = ZyraWalletReadiness.ready,
}) async {
  final role = guardian ? 'guardian' : 'seeker';
  final plan = basic ? 'basic' : 'one';
  final h = frame.harness(tester, '${role}_${plan}_$state');
  await h.mount(
    guardian: guardian,
    initialSeekerBasic: !guardian && basic,
    initialGuardianBasic: guardian && basic,
    receivedRequest: false,
    checkpoint: ZyraPreviewNavigationCheckpoint(
      guardian: guardian,
      model:
          (model ?? ViewRequestDraftModel(capacity: !guardian && basic ? 1 : 3))
              .snapshot(),
      tab: tab,
      pages: pages,
      accountDestination: action?.name,
      settingsDetail: detail?.name,
      myZyraQuickAccessPage: quickPage,
      seekerReadiness: seekerReadiness,
      seekerMembership: !guardian && basic ? 'Seeker Basic' : 'Seeker One',
      guardianMembership: guardian && basic ? 'Guardian Basic' : 'Guardian One',
    ),
  );
  expect(h.latest.pages, pages, reason: 'Restore the complete parent chain');
  expect(h.latest.guardian, guardian);
  expect(
    guardian ? h.latest.guardianMembership : h.latest.seekerMembership,
    '${guardian ? 'Guardian' : 'Seeker'} ${basic ? 'Basic' : 'One'}',
  );
  return h;
}

void _case(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await body(tester);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(() async {
    final file = File('build/line126-remaining-routes.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'status': 'Route observations; the test runner determines completion',
        'action': 'OA-ZYRA-371',
        'fresh_rebuild': true,
        'all_dimensions_registered': line126RemainingAuditAllDimensions,
        'dimension_scope':
            'Fixture geometry only; the shared raster audit separately '
            'measures the four locked viewport/scale combinations',
        'observations': _observations,
      }),
    );
    await baselineTearDown();
  });
  final frames = line126RemainingAuditAllDimensions
      ? [
          for (final size in [const Size(430, 932), const Size(375, 667)])
            for (final scale in [1.0, 1.3]) _Frame(size, scale),
        ]
      : [const _Frame(Size(430, 932), 1)];
  for (final frame in frames) {
    for (final guardian in [false, true]) {
      for (final basic in [false, true]) {
        _registerAccountCases(frame, guardian: guardian, basic: basic);
      }
    }
    for (final basic in [false, true]) {
      _registerAdditionalCases(frame, basic: basic);
    }
  }
}

void _registerAccountCases(
  _Frame frame, {
  required bool guardian,
  required bool basic,
}) {
  final role = guardian ? 'Guardian' : 'Seeker';
  final plan = basic ? 'Basic' : 'One';
  final prefix = 'line126 ${frame.id} $role $plan';
  for (final action in [
    ..._commonOverviews,
    if (!guardian) ...[
      ZyraConceptAccountAction.visibility,
      ZyraConceptAccountAction.privateMode,
    ],
    ZyraConceptAccountAction.hiddenProfiles,
  ]) {
    _case('$prefix overview ${action.name}', (tester) async {
      final h = await _mount(
        tester,
        frame,
        guardian: guardian,
        basic: basic,
        state: 'overview_${action.name}',
        pages: const ['settings', 'account_action'],
        action: action,
      );
      if (action == ZyraConceptAccountAction.notificationSettings) {
        final view = tester.widget<ZyraEmailSettingsPreview>(
          find.byType(ZyraEmailSettingsPreview),
        );
        expect(view.settings.journeyEmails, isTrue);
        expect(view.settings.journeyRequests, isTrue);
      } else if (action == ZyraConceptAccountAction.visibility ||
          action == ZyraConceptAccountAction.privateMode) {
        final view = tester.widget<ZyraPausePrivatePreview>(
          find.byType(ZyraPausePrivatePreview),
        );
        expect(
          view.privatePage,
          action == ZyraConceptAccountAction.privateMode,
        );
        expect(view.seekerOne, !basic);
        expect(view.paused, isFalse);
        expect(find.textContaining('confirmed Pause state'), findsNothing);
        expect(find.textContaining('server setting'), findsNothing);
      } else if (action == ZyraConceptAccountAction.signInSecurity ||
          action == ZyraConceptAccountAction.appLock ||
          action == ZyraConceptAccountAction.hiddenProfiles) {
        final view = tester.widget<ZyraPrivacySecurityPreview>(
          find.byType(ZyraPrivacySecurityPreview),
        );
        expect(view.page, switch (action) {
          ZyraConceptAccountAction.signInSecurity =>
            ZyraPrivacySecurityPage.signIn,
          ZyraConceptAccountAction.appLock => ZyraPrivacySecurityPage.appLock,
          _ => ZyraPrivacySecurityPage.hiddenBlocked,
        });
      } else {
        final view = tester.widget<ZyraConceptSettingsOverview>(
          find.byType(ZyraConceptSettingsOverview),
        );
        expect(view.action, action);
        expect(view.data.guardian, guardian);
      }
      expect(h.latest.accountDestination, action.name);
      await _readAll(h, action.name);
      h.assertPage('account_action');
      _record(h, 'overview_${action.name}');
    });
  }
  for (final (action, detail) in [..._commonDetails]) {
    _case('$prefix detail ${detail.name}', (tester) async {
      final h = await _mount(
        tester,
        frame,
        guardian: guardian,
        basic: basic,
        state: 'detail_${action.name}_${detail.name}',
        pages: const ['settings', 'account_action', 'settings_detail'],
        action: action,
        detail: detail,
      );
      final view = tester.widget<ZyraConceptSettingsDetailPresentation>(
        find.byType(ZyraConceptSettingsDetailPresentation),
      );
      expect(view.detail, detail);
      expect(view.overviewAction, action);
      expect(view.guardian, guardian);
      expect(h.latest.settingsDetail, detail.name);
      await _readAll(h, detail.name);
      h.assertPage('settings_detail');
      _record(h, 'detail_${action.name}_${detail.name}');
    });
  }
  for (final route in [
    'own_profile_preview',
    'manage_photos',
    'compatibility_store',
    if (!guardian) 'guardian_info',
  ]) {
    _case('$prefix route $route', (tester) async {
      final h = await _mount(
        tester,
        frame,
        guardian: guardian,
        basic: basic,
        state: route,
        pages: [route],
      );
      switch (route) {
        case 'own_profile_preview':
          expect(find.byType(MyProfilePreviewScreen), findsOneWidget);
          expect(_key('my-profile-browse-preview'), findsOneWidget);
        case 'manage_photos':
          expect(find.byType(EditPhotosScreen), findsOneWidget);
          expect(_key('photos-title'), findsOneWidget);
        case 'compatibility_store':
          expect(
            find.byType(ZyraDraftCompatibilityStorePresentation),
            findsOneWidget,
          );
          for (var page = 1; page <= 8; page++) {
            expect(
              tester
                  .widget<Text>(
                    _key('draft_compatibility_store_preview_position'),
                  )
                  .data,
              '$page / 8',
            );
            await _readAll(h, 'store_$page');
            _record(h, 'store_$page');
            if (page < 8) await h.tap('draft_compatibility_store_preview_next');
          }
        case 'guardian_info':
          expect(find.byType(ZyraGuardianInfoPresentation), findsOneWidget);
          for (var page = 0; page < 4; page++) {
            await h.tap('guardian_info_dot_target_$page');
            expect(_key('guardian_info_scroll_$page'), findsOneWidget);
            await _readAll(h, 'guardian_info_$page');
            _record(h, 'guardian_info_$page');
          }
      }
      await _readAll(h, route);
      h.assertPage(route);
      _record(h, route);
    });
  }
  for (final state in ['empty', 'one_journey', if (!basic) 'many_journeys']) {
    _case('$prefix notifications $state', (tester) async {
      final model = ViewRequestDraftModel(capacity: basic ? 1 : 3);
      if (state != 'empty') {
        expect(model.seedJourneys(state == 'many_journeys' ? 2 : 1), isTrue);
      }
      final h = await _mount(
        tester,
        frame,
        guardian: guardian,
        basic: basic,
        state: 'notifications_$state',
        pages: const ['notifications'],
        tab: 2,
        model: model,
        quickPage: 'notifications',
      );
      expect(_key('concept_notifications_end_card'), findsOneWidget);
      expect(find.text('Only what matters to you.'), findsOneWidget);
      expect(
        find.text('No real notifications are fetched, marked read or sent.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: _key('concept_updates_connections'),
                matching: find.byType(Text),
              ),
            )
            .data,
        switch (state) {
          'empty' => 'View requests',
          'many_journeys' => 'View your Journeys',
          _ => 'Open your Journey',
        },
      );
      expect(h.latest.myZyraQuickAccessPage, 'notifications');
      await _readAll(h, state);
      h.assertPage('notifications');
      _record(h, 'notifications_$state');
    });
  }
  // Q239 / LOCK46: retain the existing Seeker One Focus witness, and
  // reach the three missing plan obligations through their real public entry.
  // Missing-role Add remains the separate signup fixture below.
  if (guardian || basic) {
    _case('$prefix unfinished covered Seeker setup', (tester) async {
      final h = await _mount(
        tester,
        frame,
        guardian: guardian,
        basic: basic,
        state: 'switch_account_setup',
        tab: guardian ? 4 : 2,
        seekerReadiness: ZyraWalletReadiness.unfinished,
      );
      expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
      expect(h.latest.seekerReadiness, ZyraWalletReadiness.unfinished);
      if (guardian) {
        await h.tap('switch-account-button');
        h.assertPage('switch_account_signup');
        final wallet = tester.widget<ZyraSubscriptionSwitchPreview>(
          find.byType(ZyraSubscriptionSwitchPreview),
        );
        expect(wallet.currentRole, ZyraWalletRole.guardian);
        expect(wallet.draft.seeker.readiness, ZyraWalletReadiness.unfinished);
        expect(wallet.draft.seeker.isCovered, isTrue);
        expect(wallet.draft.seeker.coverage, ZyraWalletCoverage.assignedFamily);
        expect(
          wallet.draft.nextStep(ZyraWalletRole.seeker),
          ZyraWalletNextStep.finishSetup,
        );
        final owner = _key('wallet_switch_scroll');
        expect(owner, findsOneWidget);
        final scroll = find.descendant(
          of: owner,
          matching: find.byType(Scrollable),
        );
        expect(scroll, findsOneWidget);
        await tester.scrollUntilVisible(
          _key('wallet_primary_seeker'),
          160,
          scrollable: scroll,
          maxScrolls: 80,
        );
        await h.flush();
        await h.tap('wallet_primary_seeker');
      } else {
        expect(h.latest.tab, 2);
        expect(h.latest.seekerMembership, 'Seeker Basic');
        expect(h.latest.model.capacity, 1);
        expect(_key('focus-setup'), findsOneWidget);
        await h.tap('focus-setup');
      }
      h.assertPage('switch_account_setup');
      final setup = tester.widget<ZyraSwitchSignupPreview>(
        find.byType(ZyraSwitchSignupPreview),
      );
      expect(setup.setupOverview, isTrue);
      expect(setup.guardian, isTrue, reason: 'The setup target is Seeker');
      expect(setup.currentMembership, '$role $plan');
      expect(h.latest.guardian, guardian);
      expect(
        guardian ? h.latest.guardianMembership : h.latest.seekerMembership,
        '$role $plan',
      );
      expect(h.latest.seekerReadiness, ZyraWalletReadiness.unfinished);
      await _readCurrentPage(h, 'switch_account_setup', 'concept_switch_setup');
      h.assertPage('switch_account_setup');
      _record(h, 'switch_account_setup');
    });
  }
  _case('$prefix subscriptions and switch setup', (tester) async {
    final h = await _mount(
      tester,
      frame,
      guardian: guardian,
      basic: basic,
      state: 'subscriptions',
    );
    await h.tap('concept_subscriptions');
    h.assertPage('subscriptions');
    expect(
      find.byType(
        guardian ? ZyraGuardianPlacesPreview : ZyraSeekerPlacesPreview,
      ),
      findsOneWidget,
    );
    await _readCurrentPage(
      h,
      'subscriptions',
      guardian
          ? 'small_pages_guardian_places_scroll'
          : 'small_pages_seeker_places_scroll',
    );
    _record(h, 'subscriptions');
    final profile = await _mount(
      tester,
      frame,
      guardian: guardian,
      basic: basic,
      state: 'switch',
    );
    await profile.controls();
    await profile.tap('concept_switch_needs_signup');
    await profile.tap('concept_wallet_coverage_individualOne');
    await profile.closeControls();
    await profile.tap('switch-account-button');
    profile.assertPage('switch_account_signup');
    final switchProfile = tester.widget<ZyraSwitchProfilePreview>(
      find.byType(ZyraSwitchProfilePreview),
    );
    expect(switchProfile.otherRoleMissing, isTrue);
    await _readCurrentPage(
      profile,
      'switch_signup',
      'small_pages_switch_profile_scroll',
    );
    _record(profile, 'switch_signup');
    await profile.tap('small_pages_add_role');
    profile.assertPage('signup');
    final signup = tester.widget<ZyraSignupPreview>(
      find.byType(ZyraSignupPreview),
    );
    expect(signup.controller.guardian, !guardian);
    if (guardian) {
      await _readCurrentPage(profile, 'switch_setup', 'signup_preferences');
    } else {
      await _readAll(profile, 'switch_setup');
    }
    expect(profile.latest.guardian, guardian);
    _record(profile, 'switch_setup');
  });
  if (!basic) {
    _case('$prefix membership review', (tester) async {
      final h = await _mount(
        tester,
        frame,
        guardian: guardian,
        basic: false,
        state: 'membership_review',
      );
      await h.tap('concept_membership');
      h.assertPage('membership');
      expect(_key('membership_paid_page'), findsOneWidget);
      await _readAll(h, 'membership_paid');
      _record(h, 'membership_paid');
      await tester.binding.handlePopRoute();
      await h.flush();
      h.shellFixture.setOtherCoverage(ZyraWalletCoverage.none);
      h.shellFixture.setOtherReadiness(ZyraWalletReadiness.ready);
      await h.flush();
      await h.tap('switch-account-button');
      expect(find.byType(ZyraSubscriptionSwitchPreview), findsOneWidget);
      await h.tap('wallet_primary_${guardian ? 'seeker' : 'guardian'}');
      expect(find.byType(ZyraMembershipChoices), findsOneWidget);
      for (final section in ['seeker', 'guardian', 'family']) {
        await h.tap('membership-section-$section');
        await _readAll(h, 'membership_$section');
        _record(h, 'membership_$section');
      }
      final ownRole = guardian ? 'guardian' : 'seeker';
      await h.tap('membership-section-$ownRole');
      await h.tap('membership-next');
      await _readAll(h, 'membership_basic');
      await h.tap('membership-select-${ownRole}Basic');
      await h.tap('membership-review-selection');
      h.assertPage('membership_review');
      expect(find.byType(ZyraMembershipReviewPresentation), findsOneWidget);
      await _readAll(h, 'membership_review');
      _record(h, 'membership_review');
    });
  }
}

void _registerAdditionalCases(_Frame frame, {required bool basic}) {
  final plan = basic ? 'Basic' : 'One';
  final prefix = 'line126 ${frame.id}';
  _case('$prefix Guardian $plan linked profile', (tester) async {
    final model = ViewRequestDraftModel(capacity: 3);
    expect(model.seedJourneys(1), isTrue);
    final h = await _mount(
      tester,
      frame,
      guardian: true,
      basic: basic,
      state: 'linked_profile',
      pages: const ['guardian'],
      tab: 1,
      model: model,
    );
    final card = tester.widget<GuardianDashboardProfileCard>(
      find.byType(GuardianDashboardProfileCard),
    );
    expect(card.onViewProfile, isNotNull);
    await h.tapText('View profile');
    h.assertPage('guardian_linked_profile');
    final view = tester.widget<ZyraOneJourneyBrowsePresentation>(
      find.byType(ZyraOneJourneyBrowsePresentation),
    );
    expect(view.profile.id, card.person.id);
    expect(view.profile.firstName, card.person.firstName);
    expect(view.showActions, isFalse);
    expect(view.showMenu, isFalse);
    await _readAll(h, 'linked_profile');
    _record(h, 'linked_profile');
  });
  _case('$prefix Guardian $plan rejects dormant Network profile', (
    tester,
  ) async {
    final h = frame.harness(tester, 'guardian_${plan.toLowerCase()}_network');
    await h.mount(
      guardian: true,
      initialGuardianBasic: basic,
      receivedRequest: false,
      checkpoint: ZyraPreviewNavigationCheckpoint(
        guardian: true,
        model: ViewRequestDraftModel(capacity: 3).snapshot(),
        tab: 0,
        pages: const ['guardian_network_profile'],
        personId: 'draft-sara',
        guardianMembership: 'Guardian $plan',
      ),
    );
    // No current opener exists and guardianPages excludes this old route.
    expect(h.latest.pages, isEmpty);
    expect(h.latest.tab, 0);
    expect(find.byType(ZyraGuardianTabsPresentation), findsOneWidget);
    expect(find.byType(ZyraOneJourneyBrowsePresentation), findsNothing);
    await _readAll(h, 'network');
    _record(h, 'guardian_network_profile', kind: 'rejected_restore');
  });
  _case('$prefix Seeker $plan preference quick check', (tester) async {
    final h = frame.harness(tester, 'seeker_${plan.toLowerCase()}_quick_check');
    final checkpoint = ZyraPreviewNavigationCheckpoint(
      guardian: false,
      model: ViewRequestDraftModel(capacity: basic ? 1 : 3).snapshot(),
      tab: 2,
      pages: const [],
      seekerMembership: 'Seeker $plan',
    );
    final ready = Completer<void>();
    await h.mountPresentation(
      checkpoint: checkpoint,
      waitForPresentation: () async {
        for (var attempt = 0; attempt < 150 && !ready.isCompleted; attempt++) {
          await tester.pump(const Duration(milliseconds: 20));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
        }
        expect(
          ready.isCompleted,
          isTrue,
          reason:
              'Quick-check shell photos must prepare before the initial audit',
        );
        await tester.pump();
      },
      child: ZyraOneJourneyConceptShell(
        key: UniqueKey(),
        canAct: () => true,
        onExit: () => fail('Quick check stays in the local preview'),
        initialSeekerBasic: basic,
        initialCheckpoint: checkpoint,
        onCheckpoint: h.checkpoints.add,
        onPresentationReady: () {
          if (!ready.isCompleted) ready.complete();
        },
        fixture: const ZyraOneJourneyShellFixture(legacyAmberQuickCheck: true),
      ),
    );
    expect(_key('focus-open-preference-quick-check'), findsOneWidget);
    await h.tap('focus-open-preference-quick-check');
    await tester.pumpAndSettle();
    h.assertPage('preference_quick_check');
    final owner = tester.widget<CompatibilityEditorScreen>(
      find.byType(CompatibilityEditorScreen, skipOffstage: false),
    );
    expect(owner.kind, CompatibilityEditorKind.trafficLights);
    expect(owner.openQuickCheck, isTrue);
    expect(owner.quickCheck, isNotNull);
    expect(find.text("Your partner's sect"), findsOneWidget);
    expect(
      find.text('Saved before as “No preference”. Tap a light to confirm.'),
      findsOneWidget,
    );
    await _readAll(h, 'quick_check');
    _record(h, 'quick_check');
  });
  _case('$prefix Seeker $plan five email presenters', (tester) async {
    const subjects = [
      'We’ve missed you at ZYRA',
      'Your Ended Journeys: removal on 26 November',
      'Your Ended Journeys will be removed on 26 November',
      '7 days left to keep your Ended Journeys',
      'Your Ended Journeys have been removed',
    ];
    for (var number = 1; number <= 5; number++) {
      var opened = 0, returned = 0;
      final h = frame.harness(
        tester,
        'seeker_${plan.toLowerCase()}_developer_inactivity_email_$number',
      );
      await h.mountPresentation(
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: ViewRequestDraftModel(capacity: basic ? 1 : 3).snapshot(),
          tab: 2,
          pages: const ['developer_inactivity_email'],
          seekerMembership: 'Seeker $plan',
        ),
        child: Scaffold(
          backgroundColor: ZyraColors.ivoryTop,
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
            child: SizedBox.expand(
              child: ZyraDeveloperInactivityEmail(
                number: number,
                endedCount: 2,
                firstName: 'Adam',
                removalDate: DateTime(2026, 11, 26),
                onOpen: () => opened++,
                onBack: () => returned++,
              ),
            ),
          ),
        ),
      );
      h.assertPage('developer_inactivity_email');
      expect(h.latest.guardian, isFalse);
      expect(h.latest.seekerMembership, 'Seeker $plan');
      final email = tester.widget<ZyraDeveloperInactivityEmail>(
        find.byType(ZyraDeveloperInactivityEmail),
      );
      expect(email.number, number);
      expect(email.endedCount, 2);
      expect(email.removalDate, DateTime(2026, 11, 26));
      expect(find.text(subjects[number - 1]), findsOneWidget);
      expect(find.text('Assalaamu alaikum Adam,'), findsOneWidget);
      expect(find.text('Open ZYRA'), findsOneWidget);
      await _readAll(h, 'email_$number');
      expect(opened, 0);
      expect(returned, 0);
      _record(h, 'email_$number', kind: 'presenter_fixture');
    }
  });
}
