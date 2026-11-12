import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

const _captures = String.fromEnvironment('ZYRA_LINE93_CAPTURE_DIR');
const _peer = 'draft-sara';
final _reminderTitle = find.textContaining(
  RegExp(r'Your Journey with\s+Sara\s+is waiting'),
);

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  for (final (size, safePadding) in [
    (const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34)),
    (const Size(375, 667), const EdgeInsets.only(top: 20)),
  ]) {
    final dimensions = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('Line 93 ready and archive at $dimensions', (tester) async {
      final h = BaselineHarness(
        tester,
        group: 'line93_$dimensions',
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
          'time_rules',
          'line93',
          state,
          state,
          fileName: '${state}_$dimensions.png',
        );
      }

      final acceptedAt = DateTime.utc(2026, 11, 12);
      var now = acceptedAt;
      final model = ViewRequestDraftModel(capacity: 3, clock: () => now);
      expect(model.seedReceived(_peer), isTrue);
      expect(model.acceptReceived(_peer), isTrue);
      now = acceptedAt.add(const Duration(hours: 48, seconds: -2));
      await h.mount(tab: 2, model: model, previewClock: () => now);
      expect(_reminderTitle, findsNothing);

      now = acceptedAt.add(const Duration(hours: 48));
      await tester.pump(const Duration(seconds: 2));
      await h.flush();
      expect(_reminderTitle, findsOneWidget);
      expect(
        find.text("Tap I'm ready to begin within 24 hours to start."),
        findsOneWidget,
      );
      await capture('ready_reminder');
      await h.tapFinder(find.text("I'm ready to begin"));
      h.assertPage('journey');
      expect(h.shellFixture.model.isReady(_peer), isTrue);
      expect(find.text('Waiting for Sara'), findsOneWidget);
      await capture('ready_waiting');

      now = acceptedAt.add(const Duration(hours: 72));
      await h.mount(
        tab: 2,
        pages: const ['requests'],
        requestsTab: 2,
        model: h.shellFixture.model,
        previewClock: () => now,
      );
      expect(find.text('Not taken up'), findsOneWidget);
      expect(h.shellFixture.model.occupiedCount, 0);
      await capture('ready_closed');

      final archive = ViewRequestDraftModel(capacity: 3, clock: () => now);
      expect(archive.request(_peer), isTrue);
      expect(archive.simulateRecipientAccept(_peer), isTrue);
      expect(archive.end(_peer), isTrue);
      now = now.add(const Duration(days: 365));
      await h.mount(
        tab: 2,
        pages: const ['ended'],
        model: archive,
        previewClock: () => now,
      );
      await h.tap('draft_journey_options_$_peer');
      expect(find.text('Remove from my Journeys'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      await capture('archive_menu');
      await h.tapFinder(find.text('Request a new Journey'));
      expect(find.textContaining('The request lasts 30 days.'), findsOneWidget);
      await capture('restart_request');
      await h.tap('draft_restart_send_$_peer');
      expect(
        find.textContaining('Request sent. It expires on'),
        findsOneWidget,
      );
      await returnZyraPreviewPage(tester);
      await h.tap('draft_journey_options_$_peer');
      await h.tapFinder(find.text('Remove from my Journeys'));
      expect(find.text('Remove this Journey?'), findsOneWidget);
      expect(find.textContaining('Sara still sees her copy.'), findsOneWidget);
      await capture('archive_confirm');
      await h.tapFinder(find.text('Keep Journey'));
      expect(h.key('draft_journey_options_$_peer'), findsOneWidget);
      await h.tap('draft_journey_options_$_peer');
      await h.tapFinder(find.text('Remove from my Journeys'));
      await h.tapFinder(find.text('Remove Journey'));
      expect(find.text('No ended Journeys'), findsOneWidget);
      expect(find.text('Removed from your Journeys.'), findsOneWidget);
      expect(h.shellFixture.model.currentEndedAttemptFor(_peer), isNotNull);
      await capture('archive_removed');

      expect(archive.markPeerDeparted(_peer), isTrue);
      await h.mount(
        tab: 2,
        pages: const ['ended'],
        model: archive,
        previewClock: () => now,
      );
      await h.tap('draft_journey_$_peer');
      h.assertPage('journey');
      expect(find.text('This member has left ZYRA'), findsOneWidget);
      expect(find.text('Journey ended'), findsOneWidget);
      expect(find.text('Messages'), findsNothing);
      expect(find.textContaining('Sara'), findsNothing);
      await capture('journey_member_left');
      await h.mount(
        tab: 2,
        pages: const ['ended', 'timeline'],
        model: archive,
        previewClock: () => now,
      );
      h.assertPage('timeline');
      expect(find.text('This member has left ZYRA'), findsOneWidget);
      expect(find.text('Journey ended'), findsOneWidget);
      expect(find.textContaining('Sara'), findsNothing);
      await capture('timeline_member_left');
      await h.mount(
        tab: 3,
        pages: const ['guardian_circle'],
        model: archive,
        previewClock: () => now,
      );
      expect(find.text('Guardian Circle'), findsOneWidget);
      expect(find.text('This member has left ZYRA'), findsOneWidget);
      expect(find.text('Sara'), findsNothing);
      await capture('circle_member_left');
    });
  }
}
