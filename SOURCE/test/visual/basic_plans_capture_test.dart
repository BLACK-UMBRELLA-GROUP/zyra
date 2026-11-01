// Queue 15: capture existing Basic-plan Founder-preview surfaces unchanged.
// No real account, data adapter, payment, quota, timer, or relationship is added.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

const _enabled = bool.fromEnvironment('ZYRA_BASIC_GUARDIAN_CAPTURE');
const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/BASIC_GUARDIAN_CAPTURE_2026-10-29';
const _sara = 'draft-sara';
const _amira = 'draft-amira';
const _hassan = 'draft-guardian-hassan';
const _yusuf = 'draft-guardian-yusuf';

DateTime _clock() => DateTime.utc(2026, 10, 29, 12);
ViewRequestDraftModel _seeker({bool active = false}) {
  final model = ViewRequestDraftModel(capacity: 1, clock: _clock);
  if (active) expect(model.seedJourneys(1), isTrue);
  return model;
}

ViewRequestDraftModel _guardian({bool active = true}) {
  final model = ViewRequestDraftModel(capacity: 3, clock: _clock);
  if (active) expect(model.seedJourneys(1), isTrue);
  expect(
    model.setSampleGuardianMembership(_hassan, DraftGuardianMembership.basic),
    isTrue,
  );
  return model;
}

BaselineHarness _harness(WidgetTester tester, {required bool guardian}) =>
    BaselineHarness(
      tester,
      group: guardian ? 'basic_guardian' : 'basic_seeker',
      outputRoot:
          '$baselineRoot/${guardian ? 'guardian_basic' : 'seeker_basic'}',
      evidenceRoot: _evidence,
      flatOutput: true,
    );

Future<void> _mount(
  BaselineHarness h, {
  bool guardian = false,
  int tab = 0,
  ViewRequestDraftModel? model,
  List<String> pages = const [],
  int requestsTab = 0,
  Iterable<String> removedGuardians = const [],
}) async {
  final fixture = model ?? (guardian ? _guardian() : _seeker());
  await h.mount(
    guardian: guardian,
    initialSeekerBasic: !guardian,
    initialGuardianBasic: guardian,
    checkpoint: ZyraPreviewNavigationCheckpoint(
      guardian: guardian,
      model: fixture.snapshot(),
      tab: tab,
      pages: pages,
      personId: _sara,
      requestsTab: requestsTab,
      seekerMembership: guardian ? 'Seeker One' : 'Seeker Basic',
      guardianMembership: guardian ? 'Guardian Basic' : 'Guardian One',
      removedGuardians: removedGuardians,
    ),
  );
  expect(h.latest.guardian, guardian);
  expect(
    guardian ? h.latest.guardianMembership : h.latest.seekerMembership,
    guardian ? 'Guardian Basic' : 'Seeker Basic',
  );
  if (guardian) {
    expect(
      ViewRequestDraftModel.fromSnapshot(
        h.latest.model,
      ).sampleGuardianMembershipFor(_hassan),
      DraftGuardianMembership.basic,
    );
  } else {
    expect(h.latest.model.capacity, 1);
  }
}

Future<void> _nav(BaselineHarness h, int index) async {
  await expandZyraPreviewTabBarIfIdle(h.tester);
  final cell = h.key('floating-nav-item-$index');
  expect(cell, findsOneWidget);
  await h.tester.tapAt(h.tester.getCenter(cell));
  await h.flush();
  expect(h.latest.tab, index);
  expect(h.latest.pages, isEmpty);
}

ScrollPosition? _pageScroll(WidgetTester tester) {
  final positions = tester
      .stateList<ScrollableState>(find.byType(Scrollable).hitTestable())
      .where((state) => ModalRoute.of(state.context)?.isCurrent == true)
      .map((state) => state.position)
      .where(
        (position) =>
            position.axis == Axis.vertical && position.hasContentDimensions,
      )
      .toList();
  if (positions.isEmpty) return null;
  positions.sort((a, b) => b.viewportDimension.compareTo(a.viewportDimension));
  return positions.first;
}

Future<void> _record(
  BaselineHarness h,
  String page,
  String state,
  String reached,
) async {
  await h.capture('basic_plans', page, state, reached);
  final file = '${page}__$state.png';
  final row = h.rows.singleWhere((row) => row['file'] == file);
  row['plan'] = h.guardian ? 'Guardian Basic' : 'Seeker Basic';
  row['folder'] = h.guardian ? 'guardian_basic' : 'seeker_basic';
  await h.tester.runAsync(() async {
    await File('$_evidence/rows_${h.group}.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(h.rows),
      flush: true,
    );
  });
}

Future<void> _page(
  BaselineHarness h,
  String page,
  String state,
  String reached,
) async {
  final position = _pageScroll(h.tester);
  position?.jumpTo(position.minScrollExtent);
  await h.flush();
  if (h.latest.pages.isEmpty) {
    // Capture the actual new LOCK 6 idle bar, without forcing another style.
    await h.tester.pump(const Duration(seconds: 3));
    await h.flush();
  }
  await _record(h, page, state, reached);
  if (position == null || position.maxScrollExtent <= 1) return;
  final stride = math.max(1.0, position.viewportDimension * .72);
  var frame = 1;
  while (position.pixels < position.maxScrollExtent - .5) {
    final target = math.min(position.maxScrollExtent, position.pixels + stride);
    position.jumpTo(target);
    await h.flush();
    await _record(
      h,
      page,
      '${state}_scroll_${frame.toString().padLeft(2, '0')}',
      '$reached; actual current-route vertical ScrollPosition '
          '${position.pixels.toStringAsFixed(1)} of '
          '${position.maxScrollExtent.toStringAsFixed(1)} logical points',
    );
    frame++;
    expect(frame, lessThan(40));
  }
  position.jumpTo(position.minScrollExtent);
  await h.flush();
}

Future<void> _membership(BaselineHarness h, {required bool guardian}) async {
  await _mount(h, guardian: guardian, tab: guardian ? 3 : 4);
  await h.tap('concept_membership');
  h.assertPage('membership');
  await _page(
    h,
    'membership',
    'current_basic',
    'Actual Basic Profile > Membership; local confirmed Basic wallet only.',
  );
  final role = guardian ? 'guardian' : 'seeker';
  await h.tap('membership-section-$role');
  await _page(
    h,
    'membership',
    'upgrade_one',
    'Actual Membership $role section shows its existing One catalogue card; '
        'no selection, payment, or entitlement action.',
  );
  await h.tap('membership-next');
  await _page(
    h,
    'membership',
    'basic_plan',
    'Actual $role Membership pager > Basic catalogue card; no purchase.',
  );
}

void main() {
  setUp(ZyraInternalPreviewClient.beginPreview);
  tearDown(ZyraInternalPreviewClient.finishSignOut);
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);

  testWidgets(
    'capture Seeker Basic five tab roots and its full-place surfaces',
    (tester) async {
      final h = _harness(tester, guardian: false);
      const pages = [
        'profiles_tab',
        'journey_tab',
        'my_zyra_tab',
        'guardian_tab',
        'profile_tab',
      ];
      for (var tab = 0; tab < pages.length; tab++) {
        await _mount(h, tab: tab);
        await _page(
          h,
          pages[tab],
          'normal',
          'Existing same-role Founder checkpoint with capacity1 and '
              'Seeker Basic, matching the preview Basic plan control; tab$tab.',
        );
      }
      final full = _seeker(active: true);
      await _mount(h, tab: 1, model: full);
      await _page(
        h,
        'journey_tab',
        'active_1',
        'Existing seedJourneys(1), capacity1 and Seeker Basic.',
      );
      await _nav(h, 0);
      expect(find.text('Your Journey has your focus.'), findsOneWidget);
      await _page(
        h,
        'profiles_tab',
        'place_full',
        'Actual Profiles tab after the only Basic place is occupied; '
            'the preview hides Browse while this place is active.',
      );
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 12)),
  );

  testWidgets(
    'capture Seeker Basic Membership, zero Unlocks and one-linked Guardian invite',
    (tester) async {
      final h = _harness(tester, guardian: false);
      await _membership(h, guardian: false);
      await _mount(h);
      await h.controls();
      await h.tap('draft_compatibility_unlock_0');
      await h.closeControls();
      expect(h.latest.compatibilityBalance, 0);
      await _nav(h, 4);
      await h.tap('concept_compatibility_buy_more');
      h.assertPage('compatibility_store');
      await _page(
        h,
        'compatibility_store',
        'zero_unlocks',
        'Actual existing Browse controls set local Unlock balance0 > '
            'Profile > Compatibility Unlocks. Basic includes no credits; '
            'no wallet grant or purchase.',
      );
      await _mount(h, tab: 3, removedGuardians: const [_yusuf]);
      expect(h.latest.removedGuardians, {_yusuf});
      await _page(
        h,
        'guardian_tab',
        'one_linked',
        'Existing local unlink checkpoint leaves Hassan as the sole linked '
            'Main Guardian, with Seeker Basic.',
      );
      await h.tap('guardian-add-top');
      h.assertPage('guardian_invite');
      expect(
        find.byKey(const ValueKey('zyra_code_local_preview_denied')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('zyra_code_details')), findsOneWidget);
      expect(find.text('Add a Guardian').hitTestable(), findsOneWidget);
      expect(find.textContaining('ZYRA-DEMO-'), findsOneWidget);
      await _page(
        h,
        'guardian_invite',
        'one_linked',
        'Actual Add a Guardian while Hassan alone is linked. The local '
            'preview opens its existing invite UI; it does not enforce a '
            'Basic link-limit paywall or send a real invitation.',
      );
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 12)),
  );

  testWidgets(
    'capture Seeker Basic three pending requests, full place and Ended archive',
    (tester) async {
      final h = _harness(tester, guardian: false);
      final pending = _seeker();
      expect(pending.request(_sara), isTrue);
      expect(pending.request('draft-aisha'), isTrue);
      expect(
        pending.states.values.where(
          (state) =>
              state == DraftJourneyState.received ||
              state == DraftJourneyState.sent,
        ),
        hasLength(3),
      );
      await _mount(h, tab: 2, pages: const ['requests'], model: pending);
      await _page(
        h,
        'requests',
        'pending_3_received',
        'Existing local model has one received + two sent requests, total3. '
            'This depicts three pending records, not enforced quota UI.',
      );
      await h.tap('draft_requests_1');
      await _page(
        h,
        'requests',
        'pending_3_sent',
        'Actual Sent pill in the same three-pending fixture; no records created.',
      );
      final full = _seeker(active: true);
      expect(full.stateFor(_amira), DraftJourneyState.received);
      expect(full.canAttemptAccept(_amira), isFalse);
      await _mount(h, tab: 2, pages: const ['requests'], model: full);
      await _page(
        h,
        'requests',
        'received_place_full',
        'Existing one-place active Basic Journey plus received Amira request. '
            'The preview preserves the received item while its place is full.',
      );
      await h.tap('concept_request_${_amira}_header');
      expect(
        tester.widget<InkWell>(h.key('draft_accept_$_amira')).onTap,
        isNull,
      );
      await _page(
        h,
        'requests',
        'received_place_full_expanded',
        'Actual received request expanded; Basic full-place Accept is disabled. '
            'The capacity replacement chooser is only implemented for3 places.',
      );
      await _mount(h, tab: 2, pages: const ['ended']);
      expect(find.text('No ended Journeys'), findsOneWidget);
      await _page(
        h,
        'ended',
        'empty',
        'Existing Basic Ended route with no history.',
      );
      final ended = _seeker(active: true);
      expect(ended.end(_sara), isTrue);
      await _mount(h, tab: 2, pages: const ['ended'], model: ended);
      await _page(
        h,
        'ended',
        'populated',
        'Existing local model end(Sara); the completed attempt stays archived.',
      );
      await h.tap('draft_restart_$_sara');
      h.assertPage('ended_restart');
      expect(
        find.textContaining(
          'Restart requests are not available in this preview.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<OutlinedButton>(h.key('draft_restart_send_$_sara'))
            .onPressed,
        isNull,
      );
      await _page(
        h,
        'ended_restart',
        'unavailable',
        'Actual existing Request restart information; its send action is '
            'disabled for every preview plan. No restart or old attempt mutation.',
      );
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 12)),
  );

  testWidgets(
    'capture Guardian Basic four actual roots, Membership and Network states',
    (tester) async {
      final h = _harness(tester, guardian: true);
      const pages = ['dashboard', 'network', 'seekers', 'profile_tab'];
      for (var tab = 0; tab < pages.length; tab++) {
        await _mount(h, guardian: true, tab: tab);
        final nav = tester.widget<ZyraShellNavigation>(
          find.byType(ZyraShellNavigation),
        );
        expect(nav.items.map((item) => item.label), [
          'Dashboard',
          'Network',
          'Seekers',
          'Profile',
        ]);
        await _page(
          h,
          pages[tab],
          'normal',
          'Existing Guardian Basic checkpoint, Hassan Main and one active '
              'linked Journey. Guardian My ZYRA is currently named Dashboard; '
              'the actual root has four tabs.',
        );
      }
      await _membership(h, guardian: true);
      await _mount(h, guardian: true, tab: 1);
      await h.tap('concept_network_sent');
      await _page(
        h,
        'network',
        'sent_empty',
        'Actual Network Sent pill; no sent records.',
      );
      await h.tap('concept_network_received');
      await _page(
        h,
        'network',
        'received_empty',
        'Actual Network Received pill; no received fixture.',
      );
      await _mount(h, guardian: true, tab: 1);
      await h.tap('concept_network_suggestion');
      h.assertPage('network_request');
      await _page(
        h,
        'network_request',
        'confirmation',
        'Actual Main Guardian Basic Network > Speak to Guardian; bounded '
            'local confirmation, no real invitation or conversation.',
      );
      final person = h.latest.personId!;
      await h.tap('concept_confirm_network_request_$person');
      expect(h.latest.networkSent, contains(person));
      // Let the existing transient local notice finish before the final image.
      await tester.pump(const Duration(seconds: 4));
      await h.flush();
      await _page(
        h,
        'network',
        'sent_populated',
        'Actual local Speak confirmation > Send request > Sent. Existing '
            'fictional record only; no server or chat access.',
      );
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 12)),
  );

  testWidgets(
    'capture Guardian Basic linked view-only Journey and no-current-Journey states',
    (tester) async {
      final h = _harness(tester, guardian: true);
      final basic = _guardian();
      expect(basic.sampleGuardianAccessFor(_hassan, _sara, isMain: true), (
        view: true,
        chat: false,
      ));
      await _mount(h, guardian: true, tab: 2, model: basic);
      await h.tapText('Open current Journey');
      h.assertPage('guardian');
      expect(h.key('concept_send_message'), findsNothing);
      expect(h.key('concept_message'), findsNothing);
      await _page(
        h,
        'guardian',
        'view_only',
        'Actual Basic Seekers workspace > Open current Journey; genuine '
            'Main Guardian view grant and chat=false. Current summary has '
            'no chat composer.',
      );
      for (final tab in [0, 2]) {
        await _mount(
          h,
          guardian: true,
          tab: tab,
          model: _guardian(active: false),
        );
        await _page(
          h,
          tab == 0 ? 'dashboard' : 'seekers',
          'no_current_journey',
          'Existing Guardian Basic with linked Adam and no active Journey.',
        );
      }
      await tester.runAsync(() async {
        final file = File('$_evidence/basic_plans_not_in_preview.json');
        await file.parent.create(recursive: true);
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert([
            {
              'role': 'Seeker',
              'plan': 'Seeker Basic',
              'page': 'requests',
              'state': 'pending_limit_enforced',
              'status': 'not in preview',
              'reason':
                  'The sample model has no production pending-request quota. '
                  'The captured total3 fixture is a display state, not an enforced limit. '
                  'ViewRequestDraftModel explicitly bounds requests only by finite fixtures.',
            },
            {
              'role': 'Seeker',
              'plan': 'Seeker Basic',
              'page': 'profiles_tab',
              'state': '25_per_4_hours_reached',
              'status': 'not in preview',
              'reason':
                  'No Basic browse counter, four-hour window, or quota-reached '
                  'presenter exists in the Founder preview. Do not substitute the '
                  'separate full-place Browse boundary for this state.',
            },
            {
              'role': 'Seeker',
              'plan': 'Seeker Basic',
              'page': 'guardian_invite',
              'state': 'one_linked_limit_enforced',
              'status': 'not in preview',
              'reason':
                  'The existing Add Guardian route opens its local invite UI '
                  'even with one linked Guardian. No Basic link-limit paywall or '
                  'local link-accepted event exists. The one-linked invite is captured.',
            },
            {
              'role': 'Seeker',
              'plan': 'Seeker Basic',
              'page': 'request_capacity',
              'state': 'one_place_full_replacement',
              'status': 'not in preview',
              'reason':
                  'The sample model permits the replacement chooser only for '
                  'capacity3. Basic capacity1 keeps its received item with disabled '
                  'Accept; that actual expanded state is captured.',
            },
            {
              'role': 'Guardian',
              'plan': 'Guardian Basic',
              'page': 'family_review',
              'state': 'main_guardian',
              'status': 'not in preview',
              'reason':
                  'The Founder shell only supplies a current Journey summary '
                  'and stage label. No Family Review decision/timer fixture or '
                  'Guardian Family Review route is connected to this preview.',
            },
          ]),
          flush: true,
        );
      });
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
