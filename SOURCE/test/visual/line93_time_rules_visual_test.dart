import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_my_zyra_activity_preview.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';

import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

const _captures = String.fromEnvironment('ZYRA_LINE93_CAPTURE_DIR');
const _peer = 'draft-sara';
const _namedPeer = 'draft-amira';
const _deletionBody =
    'This profile is no longer active. Your place is free for a new Journey.';
final _reminderTitle = find.textContaining(
  RegExp(r'Your Journey with\s+Sara\s+is waiting'),
);
final _deletionTitle = find.textContaining(
  RegExp(r'^One\s+of\s+your\s+Journeys\s+has\s+ended$'),
);

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  for (final (size, safePadding) in [
    (const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34)),
    (const Size(375, 667), const EdgeInsets.only(top: 20)),
  ]) {
    final dimensions = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('Line 93 ready, archive and deletion at $dimensions', (
      tester,
    ) async {
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
      await h.tap('draft_journey_${_peer}_header');
      expect(find.text('Remove from my Journeys'), findsOneWidget);
      expect(h.key('draft_journey_options_$_peer'), findsNothing);
      await capture('archive_menu');
      await h.tapFinder(find.text('Request a new Journey'));
      expect(find.text('Request restart'), findsWidgets);
      await capture('restart_request');
      await h.tap('draft_restart_send_$_peer');
      expect(find.text('Request sent'), findsOneWidget);
      await returnZyraPreviewPage(tester);
      if (find.text('Remove from my Journeys').evaluate().isEmpty) {
        await h.tap('draft_journey_${_peer}_header');
      }
      await h.tapFinder(find.text('Remove from my Journeys'));
      expect(find.text('Remove this Journey?'), findsOneWidget);
      expect(find.textContaining('Sara still sees her copy.'), findsOneWidget);
      await capture('archive_confirm');
      await h.tapFinder(find.text('Keep Journey'));
      expect(h.key('draft_journey_${_peer}_header'), findsOneWidget);
      if (find.text('Remove from my Journeys').evaluate().isEmpty) {
        await h.tap('draft_journey_${_peer}_header');
      }
      await h.tapFinder(find.text('Remove from my Journeys'));
      await h.tapFinder(find.text('Remove Journey'));
      expect(find.text('No ended Journeys'), findsOneWidget);
      expect(find.text('Removed from your Journeys.'), findsOneWidget);
      expect(h.shellFixture.model.currentEndedAttemptFor(_peer), isNotNull);
      await capture('archive_removed');

      final active = ViewRequestDraftModel(capacity: 3, clock: () => now);
      expect(active.request(_peer), isTrue);
      expect(active.simulateRecipientAccept(_peer), isTrue);
      expect(
        active.completePreparation(
          _peer,
          linkedGuardianIds: const {'draft-guardian-hassan'},
        ),
        isTrue,
      );
      expect(active.stateFor(_peer), DraftJourneyState.active);
      expect(active.occupiedCount, 1);
      expect(active.markPeerDeparted(_peer), isTrue);
      await h.mount(tab: 2, model: active, previewClock: () => now);
      expect(h.latest.pages, isEmpty);
      expect(h.shellFixture.model.occupiedCount, 0);
      expect(find.text('NEEDS YOU'), findsOneWidget);
      expect(_deletionTitle, findsOneWidget);
      expect(find.text(_deletionBody), findsOneWidget);
      expect(find.text('Open Journey'), findsOneWidget);
      expect(find.textContaining('Sara'), findsNothing);
      await capture('q134_my_zyra_ended');
      await h.tapText('Open Journey');
      expect(h.latest.tab, 1);
      expect(h.latest.pages, isEmpty);
      expect(h.key('journey_tab_empty_title'), findsOneWidget);
      expect(h.key('journey_tab_person_$_peer'), findsNothing);
      await capture('q134_open_journey');

      final ended = ViewRequestDraftModel(capacity: 3, clock: () => now);
      for (final person in [_peer, _namedPeer]) {
        expect(ended.request(person), isTrue);
        expect(ended.simulateRecipientAccept(person), isTrue);
        expect(ended.end(person), isTrue);
      }
      expect(ended.markPeerDeparted(_peer), isTrue);
      for (final page in ['journey', 'timeline', 'ended_guardians']) {
        await h.mount(
          tab: 2,
          pages: ['ended', page],
          model: ended,
          previewClock: () => now,
        );
        h.assertPage('ended');
        expect(h.key('draft_journey_options_$_peer'), findsNothing);
        expect(h.key('draft_journey_${_namedPeer}_header'), findsOneWidget);
        expect(find.textContaining('Sara'), findsNothing);
      }
      await capture('q134_ended_journeys');
    });
  }

  testWidgets(
    'Line 93 deletion refreshes the mounted Circle and clears activity',
    (tester) async {
      const deleted = 'draft-noor';
      final now = DateTime.utc(2026, 11, 12);
      final h = BaselineHarness(
        tester,
        group: 'line93_circle',
        outputRoot: _captures,
        evidenceRoot: _captures,
        flatOutput: true,
        logicalSize: const Size(430, 932),
        safePadding: const EdgeInsets.only(top: 59, bottom: 34),
        reduceMotion: true,
      );
      final model = ViewRequestDraftModel(capacity: 3, clock: () => now);
      expect(model.seedJourneys(1), isTrue);
      expect(
        model.seedPastRequest(
          profileId: deleted,
          outcome: DraftPastRequestOutcome.youDeclined,
          requestedAt: now,
          movedAt: now,
        ),
        isTrue,
      );
      expect(model.request(deleted), isTrue);
      expect(model.simulateRecipientAccept(deleted), isTrue);
      expect(
        model.completePreparation(
          deleted,
          linkedGuardianIds: const {'draft-guardian-hassan'},
        ),
        isTrue,
      );

      await h.mount(tab: 2, model: model, previewClock: () => now);
      const example = ZyraMyZyraActivityExample.introductionReceived;
      expect(h.shellFixture.selectActivity(example), isTrue);
      await h.flush();
      expect(
        find.textContaining(RegExp(r'Hassan\s+introduced\s+Noor')),
        findsOneWidget,
      );

      await h.mount(
        tab: 3,
        pages: const ['guardian_circle'],
        model: model,
        previewClock: () => now,
      );
      ZyraGuardianCircleScreen circle() =>
          tester.widget(find.byType(ZyraGuardianCircleScreen));
      expect(
        circle().previewData!.contexts.map((context) => context.referenceId),
        containsAll([_peer, deleted]),
      );
      expect(
        circle().previewPastTopics.map((topic) => topic.firstName),
        contains('Noor'),
      );

      expect(h.shellFixture.model.markPeerDeparted(deleted), isTrue);
      await h.flush();
      h.assertPage('guardian_circle');
      expect(
        circle().previewData!.contexts.map((context) => context.referenceId),
        [_peer],
      );
      expect(
        circle().previewPastTopics.map((topic) => topic.firstName),
        isNot(contains('Noor')),
      );
      if (_captures.isNotEmpty) {
        await h.capture(
          'time_rules',
          'line93',
          'q134_circle_after',
          'q134_circle_after',
          fileName: 'q134_circle_after_430x932.png',
        );
      }

      final purged = h.shellFixture.model;
      await h.mount(
        tab: 2,
        pages: const ['requests'],
        requestsTab: 2,
        model: purged,
        previewClock: () => now,
      );
      expect(find.text('No past requests.'), findsOneWidget);
      await h.mount(tab: 2, model: purged, previewClock: () => now);
      expect(h.shellFixture.selectActivity(example), isTrue);
      await h.flush();
      expect(find.textContaining('Noor'), findsNothing);
      expect(_deletionTitle, findsOneWidget);
    },
  );
}
