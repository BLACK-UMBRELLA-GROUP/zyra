// Corrected LOCK 2 uses the real offline Founder sample shell. Existing
// Profiles identity, LOCK 4 avatar and LOCK 5 attention remain current.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

import 'baseline_capture_support.dart';

const _enabled = bool.fromEnvironment('ZYRA_LOCK2_CAPTURE');
const _output =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/PRODUCT/APPROVED/REQUESTS_AND_GUARDIANS/BUILT';
const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/LOCK2_REQUESTS_AND_GUARDIANS_2026-10-29';
const _amira = 'draft-amira';
const _sara = 'draft-sara';
const _yusuf = 'draft-guardian-yusuf';

DateTime _clock() => DateTime.utc(2026, 10, 29, 12);
ViewRequestDraftModel _model() =>
    ViewRequestDraftModel(capacity: 3, clock: _clock);

BaselineHarness _harness(WidgetTester tester, String group) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return BaselineHarness(
    tester,
    group: 'lock2_$group',
    outputRoot: _output,
    evidenceRoot: _evidence,
    flatOutput: true,
  );
}

Finder _guardianAction(String key) => find.descendant(
  of: find.byKey(const ValueKey('guardian-quiet-sections-$_yusuf')),
  matching: find.byKey(ValueKey(key)),
);

Future<void> _requests(
  BaselineHarness h,
  ViewRequestDraftModel model, {
  int tab = 0,
}) async {
  await h.mount(
    tab: 2,
    pages: const ['requests'],
    requestsTab: tab,
    model: model,
  );
  h.assertPage('requests');
  expect(h.latest.requestsTab, tab);
  expect(find.text('Received'), findsOneWidget);
  expect(find.text('Sent'), findsOneWidget);
  expect(find.text('Past'), findsOneWidget);
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  testWidgets(
    'LOCK 2 Profiles actual default Sara before and after sending',
    (tester) async {
      final h = _harness(tester, 'profiles');
      await h.mount();
      expect(h.latest.tab, 0);
      expect(h.latest.pages, isEmpty);
      expect(h.latest.browseId, _sara);
      expect(h.latest.model.states[_sara], isNull);
      expect(find.text('Request a Journey'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('concept_browse_details_avatar_$_sara')),
        findsOneWidget,
      );
      await h.capture(
        'browse_and_requests',
        'profiles_tab',
        'request_not_sent',
        'Actual default Sara Profiles details card; unchanged current LOCK 4 photo avatar and LOCK 5 nav attention; no request sent',
      );

      await h.tap('draft_profile_$_sara');
      expect(h.latest.model.states[_sara], DraftJourneyState.sent);
      expect(find.text('Request sent'), findsOneWidget);
      expect(find.text('Journey invitation sent'), findsNothing);
      await h.capture(
        'browse_and_requests',
        'profiles_tab',
        'request_sent',
        'Actual existing Sara Request a Journey action; same profile and sent gold-outline button',
      );
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'LOCK 2 My ZYRA and all eight requests master states',
    (tester) async {
      final h = _harness(tester, 'requests');
      final dashboard = _model();
      expect(dashboard.request(_sara), isTrue);
      await h.mount(tab: 2, model: dashboard);
      expect(h.latest.pages, isEmpty);
      expect(
        find.byKey(const ValueKey('my-zyra-new-activity-heading')),
        findsOneWidget,
      );
      await h.capture(
        'profile_membership_settings',
        'my_zyra_tab',
        'new_request',
        'Actual My ZYRA root with one untouched Amira arrival and one local Sara Sent request; existing New activity remains',
      );

      await _requests(h, _model());
      expect(find.text('Amira Rahman'), findsOneWidget);
      await h.capture(
        'browse_and_requests',
        'requests',
        'received',
        'Actual Received page, default local Amira request, collapsed card and three equal tabs',
      );
      await h.tap('concept_request_${_amira}_header');
      expect(find.text('Accept request'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      await h.capture(
        'browse_and_requests',
        'requests',
        'received_expanded',
        'Actual Amira Received card header tap opens unchanged request actions',
      );
      await h.tap('draft_decline_$_amira');
      expect(h.latest.model.states[_amira], isNull);
      expect(find.text('No received requests yet.'), findsOneWidget);
      await h.capture(
        'browse_and_requests',
        'requests',
        'received_empty',
        'Actual Decline action removes the only Received item into Past; Received empty presenter',
      );

      final sent = _model();
      expect(sent.request(_sara), isTrue);
      await _requests(h, sent, tab: 1);
      expect(find.text('Sara Ahmed'), findsOneWidget);
      await h.capture(
        'browse_and_requests',
        'requests',
        'sent',
        'Local Sara request fixture; actual Sent page with its unchanged collapsed card',
      );
      await h.tap('concept_request_${_sara}_header');
      expect(find.text('Cancel request'), findsOneWidget);
      await h.capture(
        'browse_and_requests',
        'requests',
        'sent_expanded',
        'Actual Sara Sent card header tap; existing Founder demo action remains as in the baseline',
      );
      await h.tap('draft_cancel_$_sara');
      expect(h.latest.model.states[_sara], isNull);
      expect(find.text('No sent requests yet.'), findsOneWidget);
      await h.capture(
        'browse_and_requests',
        'requests',
        'sent_empty',
        'Actual Cancel request action moves Sara into Past; Sent empty presenter',
      );

      final past = _model();
      expect(
        past.seedPastRequest(
          profileId: 'draft-aisha',
          outcome: DraftPastRequestOutcome.notTakenUp,
          requestedAt: DateTime.utc(2026, 10, 12),
          movedAt: DateTime.utc(2026, 10, 14),
        ),
        isTrue,
      );
      expect(
        past.seedPastRequest(
          profileId: 'draft-maryam',
          outcome: DraftPastRequestOutcome.youDeclined,
          requestedAt: DateTime.utc(2026, 10, 20),
          movedAt: DateTime.utc(2026, 10, 22),
        ),
        isTrue,
      );
      await _requests(h, past, tab: 2);
      expect(find.text('Maryam Hussain'), findsOneWidget);
      expect(find.text('Aisha Khan'), findsOneWidget);
      expect(find.text('Received 20 Oct'), findsOneWidget);
      expect(find.text('Sent 12 Oct'), findsOneWidget);
      expect(find.text('You declined'), findsOneWidget);
      expect(find.text('Not taken up'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Maryam Hussain')).dy,
        lessThan(tester.getTopLeft(find.text('Aisha Khan')).dy),
      );
      expect(find.textContaining('listed until'), findsNothing);
      await h.capture(
        'browse_and_requests',
        'requests',
        'past',
        'Explicit allowed local history fixtures: Maryam Received 20 Oct/You declined newest, Aisha Sent 12 Oct/Not taken up older; actual passive cards',
      );

      await _requests(h, _model(), tab: 2);
      expect(h.latest.model.pastRequests, isEmpty);
      expect(find.text('No past requests.'), findsOneWidget);
      expect(
        find.text(
          'Requests that were declined, expired or cancelled stay here.',
        ),
        findsOneWidget,
      );
      await h.capture(
        'browse_and_requests',
        'requests',
        'past_empty',
        'Fresh default Founder model has no history; actual Past clock and exact locked empty wording',
      );
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 8)),
  );

  testWidgets(
    'LOCK 2 actual full capacity choice before and after selection',
    (tester) async {
      final h = _harness(tester, 'capacity');
      final full = _model()..seedJourneys(3);
      await _requests(h, full);
      await h.tap('concept_request_${_amira}_header');
      await h.tap('draft_accept_$_amira');
      h.assertPage('request_capacity');
      expect(find.text('Your Journey places are full.'), findsOneWidget);
      expect(find.text('End & accept request'), findsOneWidget);
      expect(find.text('Keep my Journeys'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('request_capacity_continue')),
            )
            .onPressed,
        isNull,
      );
      await h.capture(
        'browse_and_requests',
        'request_capacity',
        'full_nothing_chosen',
        'Actual Amira Received Accept request with three seeded sample Journeys; no ending chosen and primary disabled',
      );
      await h.tap('request_capacity_journey_draft-aisha');
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('request_capacity_continue')),
            )
            .onPressed,
        isNotNull,
      );
      await h.capture(
        'browse_and_requests',
        'request_capacity',
        'full_journey_chosen',
        'Actual Aisha Journey row selection; End & accept request enabled without ending or accepting anything',
      );
      expect(h.latest.model.states[_amira], DraftJourneyState.received);
      expect(h.latest.model.endedAttempts, isEmpty);
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'LOCK 2 actual local Make Main opens the one-time Yusuf message',
    (tester) async {
      final h = _harness(tester, 'guardian_main');
      await h.mount(
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: _model().snapshot(),
          tab: 3,
          pages: const [],
          guardianPage: 0,
        ),
      );
      expect(h.latest.mainGuardianId, 'draft-guardian-hassan');
      expect(h.latest.pendingMainGuardianNoticeId, isNull);
      expect(
        find.byKey(const ValueKey('concept_main_guardian_notice')),
        findsNothing,
      );
      await tester.drag(
        find.byKey(const ValueKey('guardian-page-view')),
        const Offset(-340, 0),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<PageView>(find.byKey(const ValueKey('guardian-page-view')))
            .controller!
            .page,
        closeTo(1, .01),
      );
      await h.tapFinder(_guardianAction('guardian-make-main'));
      await h.tapFinder(
        find.descendant(
          of: _guardianAction('guardian-make-main-confirmation'),
          matching: find.text('Confirm'),
        ),
      );
      h.assertPage('guardian_main_notice');
      expect(h.latest.mainGuardianId, _yusuf);
      expect(h.latest.pendingMainGuardianNoticeId, _yusuf);
      expect(find.text('Yusuf will be your Main Guardian'), findsOneWidget);
      expect(
        find.text(
          "Yusuf is part of every Journey you begin. Yusuf will also see your Journey requests — the ones you send and the ones you receive — and who each is with. Yusuf sees that person's profile as anyone browsing would. Nothing more.",
        ),
        findsOneWidget,
      );
      await h.capture(
        'guardians',
        'guardian_main',
        'first_main_message',
        'Actual existing Yusuf Make Main and Confirm controls from the Guardian tab; no invented link event; actual centered shared gold-ring initial',
      );
      await h.tap('concept_main_guardian_continue');
      expect(h.latest.pendingMainGuardianNoticeId, isNull);
      expect(h.latest.mainGuardianId, _yusuf);
      expect(
        find.byKey(const ValueKey('concept_main_guardian_notice')),
        findsNothing,
      );
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
