import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

const _captures = String.fromEnvironment('ZYRA_LINE98_CAPTURE_DIR');
const _archivePeers = ['draft-zainab', 'draft-safiya', 'draft-noor'];
final _now = DateTime.utc(2026, 11, 19, 12);

ViewRequestDraftModel _archive() {
  final model = ViewRequestDraftModel(
    capacity: 3,
    clock: () => _now.subtract(const Duration(days: 7)),
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

  for (final (size, padding) in [
    (const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34)),
    (const Size(375, 667), const EdgeInsets.only(top: 20)),
  ]) {
    final dimensions = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('LOCK 2 V4 Ended list and read-only hub at $dimensions', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = BaselineHarness(
        tester,
        group: 'line98_ended_$dimensions',
        outputRoot: _captures,
        evidenceRoot: _captures,
        flatOutput: true,
        logicalSize: size,
        safePadding: padding,
        reduceMotion: true,
      );
      Future<void> capture(String state) async {
        if (_captures.isEmpty) return;
        await h.capture(
          'ended_journeys',
          'line98',
          state,
          state,
          fileName: '${state}_$dimensions.png',
        );
      }

      await h.mount(tab: 2, model: _archive(), previewClock: () => _now);
      await h.tap('concept-my-ended');
      h.assertPage('ended');
      expect(find.byType(ZyraRequestActivityCard), findsNWidgets(3));
      expect(find.text('Journey ended · Timeline kept'), findsNWidgets(3));
      expect(find.text('Zainab Malik'), findsOneWidget);
      expect(h.key('draft_journey_options_draft-zainab'), findsNothing);
      await capture('ended_journeys__list');
      await h.tap('draft_journey_draft-zainab_header');
      expect(find.text('View Timeline'), findsOneWidget);
      expect(find.text('Request a new Journey'), findsOneWidget);
      expect(find.text('Remove from my Journeys'), findsOneWidget);
      await capture('ended_journeys__open');
      await h.tap('draft_ended_view_draft-zainab');
      h.assertPage('ended_archive');
      expect(h.key('compact-nav-surface'), findsOneWidget);
      expect(find.text('Journey with Zainab'), findsOneWidget);
      expect(
        find.text('Read only · nothing here can be changed'),
        findsOneWidget,
      );
      await capture('ended_journeys__view_timeline_read_only');
      for (final destination in ['timeline', 'bio', 'guardians']) {
        await h.tap('draft_ended_${destination}_draft-zainab');
        h.assertPage(
          destination == 'timeline' ? 'timeline' : 'ended_$destination',
        );
        expect(h.key('concept_send_message'), findsNothing);
        await returnZyraPreviewPage(tester);
        h.assertPage('ended_archive');
      }
      expect(tester.takeException(), isNull);

      await h.mount(
        tab: 2,
        model: ViewRequestDraftModel(capacity: 3),
        receivedRequest: false,
        previewClock: () => _now,
      );
      await h.tap('concept-my-ended');
      expect(find.text('No ended Journeys'), findsOneWidget);
      expect(find.byType(ZyraRequestActivityCard), findsNothing);
      await capture('ended_journeys__empty');
    });
  }
}
