import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/widgets/zyra_focus_dashboard.dart';

import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

const _captures = String.fromEnvironment('ZYRA_LINE97_CAPTURE_DIR');
final _welcome = find.text('Welcome back, Adam');
final _openArchive = find.byKey(const ValueKey('focus-open-welcome_back'));
const _body =
    'You were away for a while. Your Ended Journeys are kept — nothing was removed.';
const _archivePeers = ['draft-zainab', 'draft-safiya'];
final _returnAt = DateTime.utc(2026, 11, 12);

ViewRequestDraftModel _sampleArchive() {
  final model = ViewRequestDraftModel(
    capacity: 3,
    clock: () => _returnAt.subtract(const Duration(days: 730)),
  );
  for (final id in _archivePeers) {
    expect(model.setPeerOccupied(id, false), isTrue);
    expect(model.request(id), isTrue);
    expect(model.simulateRecipientAccept(id), isTrue);
    expect(model.end(id), isTrue);
  }
  return model;
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  for (final (size, safePadding) in [
    (const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34)),
    (const Size(375, 667), const EdgeInsets.only(top: 20)),
  ]) {
    final dimensions = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('Welcome back opens the retained archive once at $dimensions', (
      tester,
    ) async {
      final h = BaselineHarness(
        tester,
        group: 'line97_$dimensions',
        outputRoot: _captures,
        evidenceRoot: _captures,
        flatOutput: true,
        logicalSize: size,
        safePadding: safePadding,
        reduceMotion: true,
      );

      Future<void> capture(String state) async {
        if (_captures.isEmpty) return;
        await h.capture(
          'inactivity_notice',
          'line97',
          state,
          state,
          fileName: '${state}_$dimensions.png',
        );
      }

      final model = _sampleArchive();
      expect(model.seedOpenInactivityNotice(), isTrue);
      expect(model.seedReceived('draft-amira'), isTrue);
      await h.mount(tab: 0, model: model, previewClock: () => _returnAt);
      expect(_welcome, findsNothing);
      await h.tap('floating-nav-item-2');
      expect(_welcome, findsOneWidget);
      expect(find.text(_body), findsOneWidget);
      final focus = tester.widget<ZyraFocusDashboard>(
        find.byType(ZyraFocusDashboard),
      );
      expect(focus.items.first.title, 'Welcome back, Adam');
      expect(focus.items.first.icon, Icons.history_outlined);
      expect(focus.items.first.actionLabel, 'View Ended Journeys');
      expect(focus.items.length, greaterThan(1));
      await capture('welcome_back');

      await h.tapFinder(_openArchive);
      h.assertPage('ended');
      expect(h.latest.tab, 2);
      expect(h.latest.myZyraQuickAccessPage, 'ended');
      expect(find.text('Ended Journeys'), findsOneWidget);
      expect(h.key('compact-nav-surface'), findsOneWidget);
      for (final id in _archivePeers) {
        expect(h.key('draft_journey_${id}_header'), findsOneWidget);
      }
      await capture('ended_journeys');

      await returnZyraPreviewPage(tester);
      expect(h.latest.pages, isEmpty);
      expect(_welcome, findsNothing);
      expect(
        tester
            .widget<ZyraFocusDashboard>(find.byType(ZyraFocusDashboard))
            .items
            .map((item) => item.title),
        containsAll([
          'Your Journey with Zainab has ended',
          'Your Journey with Safiya has ended',
        ]),
      );

      final afterReturn = h.latest;
      await h.mount(checkpoint: afterReturn, previewClock: () => _returnAt);
      expect(h.latest.tab, 2);
      expect(_welcome, findsNothing);
      await capture('second_open');
    });
  }

  testWidgets('No notice and completed removal produce no Welcome back', (
    tester,
  ) async {
    final h = BaselineHarness(tester, group: 'line97_no_notice');
    final model = _sampleArchive();
    await h.mount(tab: 2, model: model, previewClock: () => _returnAt);
    expect(_welcome, findsNothing);
    expect(find.text('2 ended'), findsOneWidget);

    expect(model.seedOpenInactivityNotice(), isTrue);
    for (final id in _archivePeers) {
      final attempt = model.currentEndedAttemptFor(id)!;
      expect(model.removeEndedJourney(id, attempt.id), isTrue);
    }
    expect(model.seedOpenInactivityNotice(), isFalse);
    await h.mount(tab: 2, model: model, previewClock: () => _returnAt);
    expect(_welcome, findsNothing);
    await h.tap('concept-my-ended');
    h.assertPage('ended');
    expect(find.text('No ended Journeys'), findsOneWidget);
  });

  testWidgets('Leaving My ZYRA dismisses Welcome back without its action', (
    tester,
  ) async {
    final h = BaselineHarness(tester, group: 'line97_leave');
    for (final destination in ['Journey', 'Journey requests']) {
      final model = _sampleArchive();
      expect(model.seedOpenInactivityNotice(), isTrue);
      await h.mount(tab: 2, model: model, previewClock: () => _returnAt);
      expect(_welcome, findsOneWidget);
      await h.tap(
        destination == 'Journey'
            ? 'floating-nav-item-1'
            : 'concept-my-requests',
      );
      expect(_welcome, findsNothing);
      if (destination == 'Journey') {
        expect(h.latest.tab, 1);
        await h.tap('floating-nav-item-2');
      } else {
        h.assertPage('requests');
        await returnZyraPreviewPage(tester);
      }
      expect(h.latest.tab, 2);
      expect(h.latest.pages, isEmpty);
      expect(_welcome, findsNothing);
    }
  });

  testWidgets('Foreground return consumes an open notice exactly once', (
    tester,
  ) async {
    final h = BaselineHarness(tester, group: 'line97_foreground');
    await h.mount(
      tab: 2,
      model: _sampleArchive(),
      previewClock: () => _returnAt,
    );
    expect(_welcome, findsNothing);

    final changeState = tester.binding.handleAppLifecycleStateChanged;
    void background() {
      changeState(AppLifecycleState.inactive);
      changeState(AppLifecycleState.hidden);
      changeState(AppLifecycleState.paused);
    }

    void foreground() {
      changeState(AppLifecycleState.hidden);
      changeState(AppLifecycleState.inactive);
      changeState(AppLifecycleState.resumed);
    }

    background();
    expect(h.shellFixture.model.seedOpenInactivityNotice(), isTrue);
    foreground();
    await h.flush();
    expect(_welcome, findsOneWidget);

    background();
    foreground();
    await h.flush();
    expect(_welcome, findsNothing);
  });
}
