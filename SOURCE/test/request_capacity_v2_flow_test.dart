// LOCK2 V2: actual Founder shell transitions, guarded callbacks and renders.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/dev/zyra_request_capacity_choice.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/widgets/zyra_focus_dashboard.dart';
import 'support/zyra_hidden_dev_controls_driver.dart';
import 'visual/baseline_capture_support.dart';

const _root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const _evidence =
    '$_root/REPORTS/EVIDENCE/LOCK2_REQUEST_CAPACITY_V2_2026-10-31';
const _output = '$_root/PRODUCT/APPROVED/REQUESTS_AND_GUARDIANS/BUILT/V2';
const _render = bool.fromEnvironment('ZYRA_CAPACITY_V2_RENDER');
const _hana = 'draft-hana';
const _maryam = 'draft-maryam';
const _sara = 'draft-sara';

ViewRequestDraftModel _fixture({
  bool full = false,
  bool peerFull = false,
  bool sent = false,
}) {
  var now = DateTime.utc(2026, 10, 28, 12);
  final model = ViewRequestDraftModel(capacity: 3, clock: () => now);
  if (full) model.fillCapacity();
  now = DateTime.utc(2026, 10, 29, 12);
  if (sent) {
    expect(model.request(_hana), isTrue);
  } else {
    expect(model.seedReceived(_hana), isTrue);
  }
  if (peerFull) expect(model.setPeerOccupied(_hana, true), isTrue);
  // Isolate the received Hana card; sent Focus retains the unrelated unread
  // sample request so its real count is the master's one new request.
  if (!sent) expect(model.block('draft-amira'), isTrue);
  return model;
}

BaselineHarness _h(WidgetTester tester, {double scale = 1}) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return BaselineHarness(
    tester,
    group: 'capacity_v2_${scale == 1 ? 'normal' : 'large'}',
    outputRoot: _output,
    evidenceRoot: _evidence,
    flatOutput: true,
    textScale: scale,
  );
}

ViewRequestDraftModel _model(BaselineHarness h) =>
    ViewRequestDraftModel.fromSnapshot(h.latest.model);
Finder _key(String key) => find.byKey(ValueKey(key));
ZyraRequestCapacityChoice _choice(WidgetTester tester) =>
    tester.widget(find.byType(ZyraRequestCapacityChoice));
ZyraRequestActivityCard _card(WidgetTester tester) => tester
    .widgetList<ZyraRequestActivityCard>(find.byType(ZyraRequestActivityCard))
    .firstWhere((c) => c.profile.id == _hana);
VoidCallback _cardAction(WidgetTester tester, String id) =>
    _card(tester).actions.firstWhere((a) => a.key == ValueKey(id)).onTap!;
Future<void> _mountRequests(
  BaselineHarness h,
  ViewRequestDraftModel m, {
  bool sent = false,
}) => h.mount(
  model: m,
  tab: 2,
  pages: ['requests'],
  requestsTab: sent ? 1 : 0,
  personId: _hana,
);
Future<void> _expand(BaselineHarness h) =>
    h.tap('concept_request_${_hana}_header');
Future<void> _capture(BaselineHarness h, String name) async {
  if (_render) {
    await h.capture(
      'requests',
      name,
      'locked_v2',
      'Actual shell actions from detached fixed-fixture checkpoint',
      fileName: '$name${h.textScale > 1 ? '__text200' : ''}.png',
    );
  }
}

Future<void> _back(BaselineHarness h) async {
  await returnZyraPreviewPage(h.tester);
  await h.flush();
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  setUp(() async {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await ZyraAccountState.synchronize('capacity-v2-owner');
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
  });

  testWidgets(
    'both space accept enters preparation and mutual Begin starts Salam only',
    (tester) async {
      final h = _h(tester);
      await _mountRequests(h, _fixture());
      await _expand(h);
      await h.tap('draft_accept_$_hana');
      expect(_model(h).stateFor(_hana), DraftJourneyState.preparing);
      expect(_model(h).occupiedCount, 1);
      expect(_key('concept_send_message'), findsNothing);
      expect(
        tester.widget<OutlinedButton>(_key('draft_begin_$_hana')).onPressed,
        isNull,
      );
      await _capture(h, 'accept__both_space_preparing');
      await h.tap('draft_ready_$_hana');
      expect(
        tester.widget<OutlinedButton>(_key('draft_begin_$_hana')).onPressed,
        isNull,
      );
      await h.tap('draft_peer_ready_$_hana');
      await _capture(h, 'preparing__both_ready');
      await h.tap('draft_begin_$_hana');
      await h.tap('draft_agree_guardian_access_$_hana');
      expect(_model(h).stateFor(_hana), DraftJourneyState.active);
      expect(_model(h).stageFor(_hana)?.value, 'salam_exchange');
    },
  );

  testWidgets(
    'you full replacement keeps confirmation and frees exactly the chosen place',
    (tester) async {
      final h = _h(tester);
      await _mountRequests(h, _fixture(full: true));
      await _expand(h);
      await h.tap('draft_accept_$_hana');
      expect(_choice(tester).onContinue, isNull);
      expect(_choice(tester).holdEnding, isFalse);
      await h.tap('request_capacity_journey_$_maryam');
      await _capture(h, 'accept__you_full_choose');
      await h.tap('request_capacity_continue');
      expect(find.text('End Journey & accept request?'), findsOneWidget);
      await h.tap('request_capacity_keep');
      expect(_model(h).stateFor(_maryam), DraftJourneyState.active);
      await h.tap('request_capacity_continue');
      await h.tap('request_capacity_confirm');
      expect(_model(h).stateFor(_maryam), DraftJourneyState.ended);
      expect(_model(h).stateFor(_hana), DraftJourneyState.preparing);
      expect(_model(h).stateFor(_sara), DraftJourneyState.active);
      expect(_model(h).occupiedCount, 3);
      expect(_model(h).endedAttemptsFor(_maryam), hasLength(1));
    },
  );

  testWidgets('other full waiting is neutral then decline changes no Journey', (
    tester,
  ) async {
    final h = _h(tester);
    await _mountRequests(h, _fixture(peerFull: true));
    await _expand(h);
    await h.tap('draft_accept_$_hana');
    expect(_model(h).isAcceptedWaiting(_hana), isTrue);
    expect(_model(h).occupiedCount, 0);
    expect(find.text('You accepted · waiting for Hana'), findsOneWidget);
    expect(
      find.text(
        'Waiting for Hana to confirm. Nothing changes for you until then.',
      ),
      findsOneWidget,
    );
    await _capture(h, 'accept__other_full_waiting');
    await h.tap('draft_waiting_decline_$_hana');
    final m = _model(h);
    expect(m.stateFor(_hana), isNull);
    expect(m.occupiedCount, 0);
    expect(m.pastRequests.first.outcome, DraftPastRequestOutcome.notTakenUp);
    expect(m.endedAttemptsFor(_hana), isEmpty);
  });

  for (final confirm in [false, true]) {
    testWidgets(
      'both full held ending ${confirm ? 'confirms atomically and begins' : 'does not go ahead without any ending'}',
      (tester) async {
        final h = _h(tester);
        await _mountRequests(h, _fixture(full: true, peerFull: true));
        await _expand(h);
        await h.tap('draft_accept_$_hana');
        expect(_choice(tester).holdEnding, isTrue);
        if (!confirm) await _capture(h, 'accept__both_full_nothing_chosen');
        await h.tap('request_capacity_journey_$_maryam');
        if (!confirm) await _capture(h, 'accept__both_full_choose');
        await h.tap('request_capacity_continue');
        expect(find.text('End Journey & accept request?'), findsNothing);
        expect(_model(h).stateFor(_maryam), DraftJourneyState.active);
        expect(_model(h).heldEndingId(_hana), _maryam);
        expect(_model(h).occupiedCount, 3);
        if (!confirm) await _capture(h, 'accept__both_full_waiting');
        final retained = _cardAction(tester, 'draft_waiting_confirm_$_hana');
        await h.tap('draft_waiting_${confirm ? 'confirm' : 'decline'}_$_hana');
        retained();
        retained();
        await h.flush();
        if (confirm) {
          expect(_model(h).stateFor(_maryam), DraftJourneyState.ended);
          expect(_model(h).stateFor(_hana), DraftJourneyState.preparing);
          expect(_model(h).endedAttemptsFor(_maryam), hasLength(1));
          await h.tap('draft_ready_$_hana');
          await h.tap('draft_peer_ready_$_hana');
          await h.tap('draft_begin_$_hana');
          await h.tap('draft_agree_guardian_access_$_hana');
          expect(_model(h).stateFor(_hana), DraftJourneyState.active);
          expect(_model(h).stageFor(_hana)?.value, 'salam_exchange');
        } else {
          expect(_model(h).stateFor(_maryam), DraftJourneyState.active);
          expect(_model(h).endedAttemptsFor(_maryam), isEmpty);
          expect(
            _model(h).pastRequests.first.outcome,
            DraftPastRequestOutcome.notTakenUp,
          );
        }
        expect(_model(h).occupiedCount, 3);
      },
    );
  }

  testWidgets(
    'sent accepted full projects Focus then Keep moves only request to Past',
    (tester) async {
      final h = _h(tester);
      await _mountRequests(h, _fixture(full: true, sent: true), sent: true);
      await _expand(h);
      await _capture(h, 'sent__waiting_demo_accept');
      await h.tap('draft_recipient_$_hana');
      expect(_model(h).occupiedCount, 3);
      expect(find.text('Accepted · choose a place'), findsOneWidget);
      await _capture(h, 'sent__accepted_you_full');
      await _back(h);
      final dashboard = tester.widget<ZyraFocusDashboard>(
        find.byType(ZyraFocusDashboard),
      );
      dashboard.items.firstWhere(
        (i) => i.title == 'Hana accepted your request',
      );
      await _capture(h, 'my_zyra__accepted_choose_place');
      await h.tapText('Choose a place');
      await h.flush();
      expect(_choice(tester).acceptedSent, isTrue);
      await h.tap('request_capacity_journey_$_maryam');
      await _capture(h, 'sent__accepted_choose_place');
      await h.tap('request_capacity_cancel');
      expect(_model(h).stateFor(_maryam), DraftJourneyState.active);
      expect(_model(h).occupiedCount, 3);
      expect(
        _model(h).pastRequests.first.outcome,
        DraftPastRequestOutcome.youLetItGo,
      );
      await h.tap('draft_requests_2');
      expect(find.text('You let it go'), findsOneWidget);
      await _capture(h, 'requests__past_let_go');
    },
  );

  testWidgets(
    'sent accepted choose end confirm prepares without fourth place',
    (tester) async {
      final h = _h(tester);
      await _mountRequests(h, _fixture(full: true, sent: true), sent: true);
      await _expand(h);
      await h.tap('draft_recipient_$_hana');
      await h.tap('draft_choose_place_$_hana');
      await h.tap('request_capacity_journey_$_maryam');
      await h.tap('request_capacity_continue');
      await h.tap('request_capacity_confirm');
      expect(_model(h).stateFor(_hana), DraftJourneyState.preparing);
      expect(_model(h).stateFor(_maryam), DraftJourneyState.ended);
      expect(_model(h).occupiedCount, 3);
    },
  );

  for (final stale in ['route', 'controls', 'account', 'role']) {
    testWidgets('retained waiting confirms reject $stale change', (
      tester,
    ) async {
      final h = _h(tester);
      final m = _fixture(full: true, peerFull: true);
      expect(
        m.replaceJourneyForRequest(_hana, _maryam, incoming: true),
        isTrue,
      );
      await _mountRequests(h, m);
      await _expand(h);
      final retained = _cardAction(tester, 'draft_waiting_confirm_$_hana');
      if (stale == 'route') {
        await _back(h);
      } else if (stale == 'controls') {
        await openZyraDevControls(tester);
        await closeZyraDevControls(tester);
      } else if (stale == 'account') {
        await tester.runAsync(() async {
          await ZyraAccountState.synchronize('other-capacity-owner');
          await ZyraAccountState.synchronize('capacity-v2-owner');
        });
        ZyraDeveloperAccess.setAuthorizedForTesting(true);
      } else {
        await h.mount(guardian: true, model: _model(h), tab: 2);
      }
      retained();
      retained();
      await h.flush();
      expect(_model(h).stateFor(_maryam), DraftJourneyState.active);
      expect(_model(h).endedAttemptsFor(_maryam), isEmpty);
    });
  }

  testWidgets(
    'Basic full holds its sole ending and confirms into one preparing place',
    (tester) async {
      final h = _h(tester);
      final m = ViewRequestDraftModel(capacity: 1)..fillCapacity();
      expect(m.seedReceived(_hana), isTrue);
      expect(m.setPeerOccupied(_hana, true), isTrue);
      await h.mount(
        model: m,
        tab: 2,
        pages: ['requests'],
        seekerMembership: 'Seeker Basic',
        initialSeekerBasic: true,
      );
      await _expand(h);
      await h.tap('draft_accept_$_hana');
      expect(_choice(tester).capacity, 1);
      expect(_choice(tester).onContinue, isNull);
      await h.tap('request_capacity_journey_$_sara');
      await h.tap('request_capacity_continue');
      expect(_model(h).stateFor(_sara), DraftJourneyState.active);
      await h.tap('draft_waiting_confirm_$_hana');
      expect(_model(h).stateFor(_sara), DraftJourneyState.ended);
      expect(_model(h).stateFor(_hana), DraftJourneyState.preparing);
      expect(_model(h).occupiedCount, 1);
      expect(_model(h).canBrowse, isFalse);
    },
  );

  testWidgets('other full explicit confirmation uses a current free place', (
    tester,
  ) async {
    final h = _h(tester);
    await _mountRequests(h, _fixture(peerFull: true));
    await _expand(h);
    await h.tap('draft_accept_$_hana');
    await h.tap('draft_waiting_confirm_$_hana');
    expect(_model(h).stateFor(_hana), DraftJourneyState.preparing);
    expect(_model(h).occupiedCount, 1);
    expect(_key('concept_send_message'), findsNothing);
  });

  testWidgets(
    '200 percent text choice waiting sent past and ready remain reachable',
    (tester) async {
      final h = _h(tester, scale: 2);
      await _mountRequests(h, _fixture(full: true, peerFull: true));
      await _expand(h);
      await h.tap('draft_accept_$_hana');
      await _capture(h, 'accept__both_full_nothing_chosen');
      await h.tap('request_capacity_journey_$_maryam');
      await _capture(h, 'accept__both_full_choose');
      await h.tap('request_capacity_continue');
      await _capture(h, 'accept__both_full_waiting');
      await h.tap('draft_waiting_confirm_$_hana');
      await h.tap('draft_ready_$_hana');
      await h.tap('draft_peer_ready_$_hana');
      await _capture(h, 'preparing__both_ready');
      await h.tap('draft_begin_$_hana');
      await h.tap('draft_agree_guardian_access_$_hana');
      expect(_model(h).stageFor(_hana)?.value, 'salam_exchange');
      await h.mount(
        model: _fixture(full: true, sent: true),
        tab: 2,
        pages: ['requests'],
        requestsTab: 1,
      );
      await _expand(h);
      await h.tap('draft_recipient_$_hana');
      await _capture(h, 'sent__accepted_you_full');
      await h.tap('draft_choose_place_$_hana');
      await h.tap('request_capacity_journey_$_maryam');
      await _capture(h, 'sent__accepted_choose_place');
      await h.tap('request_capacity_cancel');
      await h.tap('draft_requests_2');
      await _capture(h, 'requests__past_let_go');
      expect(find.text('You let it go'), findsWidgets);
      final held = _fixture(full: true, peerFull: true);
      expect(
        held.replaceJourneyForRequest(_hana, _maryam, incoming: true),
        isTrue,
      );
      await _mountRequests(h, held);
      await _expand(h);
      await h.tap('draft_waiting_decline_$_hana');
      expect(_model(h).stateFor(_maryam), DraftJourneyState.active);
      expect(_model(h).endedAttemptsFor(_maryam), isEmpty);
      final sent = _fixture(full: true, sent: true);
      expect(sent.simulateRecipientAccept(_hana), isTrue);
      await _mountRequests(h, sent, sent: true);
      await _expand(h);
      await h.tap('draft_let_go_$_hana');
      expect(
        _model(h).pastRequests.first.outcome,
        DraftPastRequestOutcome.youLetItGo,
      );
      expect(_model(h).occupiedCount, 3);
    },
  );
}
