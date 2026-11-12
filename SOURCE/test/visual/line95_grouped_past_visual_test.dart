import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

import 'baseline_capture_support.dart';

const _captures = String.fromEnvironment('ZYRA_LINE95_CAPTURE_DIR');
const _sara = 'draft-sara';
const _aisha = 'draft-aisha';
final _movedAt = DateTime.utc(2026, 11, 12, 12);
final _requestedAt = DateTime.utc(2026, 11, 9, 12);

void _seed(
  ViewRequestDraftModel model, {
  required DateTime requestedAt,
  required DateTime movedAt,
  String id = _sara,
  DraftPastRequestOutcome outcome = DraftPastRequestOutcome.notTakenUp,
}) {
  expect(
    model.seedPastRequest(
      profileId: id,
      outcome: outcome,
      requestedAt: requestedAt,
      movedAt: movedAt,
    ),
    isTrue,
  );
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  for (final (size, safePadding) in [
    (const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34)),
    (const Size(375, 667), const EdgeInsets.only(top: 20)),
  ]) {
    final dimensions = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('Line 95 Past and profile at $dimensions', (tester) async {
      final h = BaselineHarness(
        tester,
        group: 'line95_$dimensions',
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
          'journey_requests',
          'line95',
          state,
          state,
          fileName: '${state}_$dimensions.png',
        );
      }

      var now = _movedAt;
      final model = ViewRequestDraftModel(capacity: 3, clock: () => now);
      for (var i = 0; i < 20; i++) {
        final age = Duration(days: i * 31);
        _seed(
          model,
          requestedAt: _requestedAt.subtract(age),
          movedAt: _movedAt.subtract(age),
        );
      }
      await h.mount(tab: 2, model: model, previewClock: () => now);
      await h.tap('concept-my-requests');
      h.assertPage('requests');
      expect(h.latest.requestsTab, 0);
      await h.tap('draft_requests_2');
      expect(h.latest.requestsTab, 2);
      expect(find.byType(ZyraPastRequestActivityCard), findsOneWidget);
      expect(find.text('Last sent 9 Nov · 20 requests'), findsOneWidget);
      final historyDates = find.textContaining(RegExp(r'^Sent \d'));
      final header = h.key(
        'past_request_activity_header_past_request_${_sara}_sent',
      );
      const retry = 'You can ask Sara again from 12 Dec.';
      expect(historyDates, findsNothing);
      expect(find.text(retry), findsNothing);
      await capture('past_group_collapsed');

      await h.tapFinder(header);
      expect(historyDates, findsNWidgets(5));
      expect(find.text('Show all 20'), findsOneWidget);
      expect(find.text(retry), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Sent 9 Nov')).dy,
        lessThan(tester.getTopLeft(find.text('Sent 9 Oct')).dy),
      );
      await capture('past_group_five');

      await h.tapText('Show all 20');
      expect(historyDates, findsNWidgets(20));
      expect(find.text('Show all 20'), findsNothing);
      await capture('past_group_show_all');
      await Scrollable.ensureVisible(
        tester.element(find.text(retry)),
        alignment: .5,
      );
      await h.flush();
      expect(find.text(retry).hitTestable(), findsOneWidget);
      await capture('past_group_end');
      await h.tapFinder(header);
      await h.tapFinder(header);
      expect(historyDates, findsNWidgets(5));

      now = _movedAt.add(const Duration(days: 30, seconds: -1));
      await h.mount(tab: 0, model: model, previewClock: () => now);
      expect(h.latest.browseId, _sara);
      await h.tapText('Ask again from 12 Dec');
      expect(h.shellFixture.model.canRequest(_sara), isFalse);
      await capture('profile_waiting');
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await h.flush();
      expect(find.text('Request a Journey').hitTestable(), findsOneWidget);
      await h.tap('draft_profile_$_sara');
      expect(h.shellFixture.model.stateFor(_sara), DraftJourneyState.sent);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Past keeps one card per direction and orders by Past transition',
    (tester) async {
      final h = BaselineHarness(
        tester,
        group: 'line95_directions',
        outputRoot: _captures,
        evidenceRoot: _captures,
        flatOutput: true,
        reduceMotion: true,
      );
      final model = ViewRequestDraftModel(capacity: 3, clock: () => _movedAt);
      _seed(
        model,
        requestedAt: DateTime.utc(2026, 11, 9),
        movedAt: DateTime.utc(2026, 11, 10),
      );
      _seed(
        model,
        requestedAt: DateTime.utc(2026, 11, 5),
        movedAt: DateTime.utc(2026, 11, 11),
        outcome: DraftPastRequestOutcome.cancelled,
      );
      _seed(
        model,
        requestedAt: DateTime.utc(2026, 11, 2),
        movedAt: DateTime.utc(2026, 11, 3),
        outcome: DraftPastRequestOutcome.youDeclined,
      );
      _seed(
        model,
        requestedAt: DateTime.utc(2026, 11, 3),
        movedAt: DateTime.utc(2026, 11, 12),
        outcome: DraftPastRequestOutcome.youDeclined,
      );
      _seed(
        model,
        id: _aisha,
        requestedAt: DateTime.utc(2026, 11, 9),
        movedAt: DateTime.utc(2026, 11, 10),
      );
      await h.mount(
        tab: 2,
        model: model,
        pages: const ['requests'],
        requestsTab: 2,
        previewClock: () => _movedAt,
      );
      expect(find.byType(ZyraPastRequestActivityCard), findsNWidgets(3));
      expect(find.text('Sara Ahmed'), findsNWidgets(2));
      final received = find.text('Last received 3 Nov · 2 requests');
      final sent = find.text('Last sent 5 Nov · 2 requests');
      final single = find.text('Sent 9 Nov');
      expect(
        tester.getTopLeft(received).dy,
        lessThan(tester.getTopLeft(sent).dy),
      );
      expect(
        tester.getTopLeft(sent).dy,
        lessThan(tester.getTopLeft(single).dy),
      );
      await h.tapFinder(received);
      expect(find.text('Sent 3 Nov'), findsOneWidget);
      expect(find.text('Sent 2 Nov'), findsOneWidget);
      expect(find.textContaining('You can ask Sara'), findsNothing);
      expect(find.textContaining('Show all'), findsNothing);
      await h.tapFinder(sent);
      expect(find.text('Sent 3 Nov'), findsNothing);
      expect(find.text('Sent 5 Nov'), findsOneWidget);
      expect(find.textContaining('You can ask Sara'), findsNothing);
      final statusRows = find.text('Not taken up');
      expect(statusRows, findsNWidgets(2));
      expect(tester.widget<Text>(statusRows.first).textAlign, TextAlign.end);
      expect(
        tester.getTopRight(statusRows.first).dx,
        tester.getTopRight(find.text('Cancelled').last).dx,
      );
      await h.tap('draft_requests_1');
      await h.tap('draft_requests_2');
      expect(find.text('Sent 5 Nov'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
