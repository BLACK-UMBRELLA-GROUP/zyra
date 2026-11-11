import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_compatibility_score_designs.dart';
import 'package:zyra/dev/zyra_draft_compatibility_store_presentation.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/subscription/zyra_one_upgrade_page.dart';

import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

const _person = 'draft-sara';
const _captures = String.fromEnvironment(
  'ZYRA_LINE81_COMPATIBILITY_CAPTURE_DIR',
);

ZyraPreviewNavigationCheckpoint _basicJourney({
  bool mutual = true,
  bool archived = false,
}) {
  final model = ViewRequestDraftModel(
    capacity: 1,
    clock: () => DateTime.utc(2026, 10, 29, 12),
  );
  expect(model.seedJourneys(1), isTrue);
  expect(model.sendSalam(_person), isTrue);
  expect(model.simulatePeerSalam(_person), isTrue);
  expect(model.chooseStageContinue(_person), isTrue);
  expect(model.simulatePeerStageContinue(_person), isTrue);
  expect(model.advanceStage(_person), isTrue);
  expect(model.chooseCompatibilityReveal(_person), isTrue);
  if (mutual) {
    expect(model.simulatePeerCompatibilityReveal(_person), isTrue);
    expect(model.chooseStageContinue(_person), isTrue);
    expect(model.simulatePeerStageContinue(_person), isTrue);
    expect(model.beginBioStep(_person), isTrue);
    expect(model.canViewJourneyCompatibility(_person), isTrue);
  }
  if (archived) expect(model.end(_person), isTrue);
  return ZyraPreviewNavigationCheckpoint(
    guardian: false,
    model: model.snapshot(),
    tab: archived ? 2 : 1,
    pages: archived ? const ['ended', 'ended_compatibility'] : const [],
    personId: _person,
    seekerMembership: 'Seeker Basic',
  );
}

Future<void> _openCompatibility(BaselineHarness harness) async {
  await harness.tap('draft_journey_options_$_person');
  await harness.tap('draft_options_compatibility_$_person');
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  for (final viewport in [
    (const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34)),
    (const Size(375, 667), const EdgeInsets.only(top: 20)),
  ]) {
    final (size, safePadding) = viewport;
    final dimensions = '${size.width.round()}x${size.height.round()}';
    testWidgets('Seeker Basic Journey topics and Unlock at $dimensions', (
      tester,
    ) async {
      final harness = BaselineHarness(
        tester,
        group: 'line81_compatibility_$dimensions',
        outputRoot: _captures,
        evidenceRoot: _captures,
        flatOutput: true,
        logicalSize: size,
        safePadding: safePadding,
        reduceMotion: true,
      );
      await harness.mount(checkpoint: _basicJourney());
      await _openCompatibility(harness);
      expect(find.text('1 / 7'), findsOneWidget);
      expect(harness.key('draft_compatibility_overall_score'), findsOneWidget);
      expect(find.text('See every topic for Sara'), findsNothing);

      final pages = harness.key('draft_compatibility_score_pages');
      await tester.drag(pages, const Offset(-240, 0));
      await harness.flush();
      expect(find.text('2 / 7'), findsOneWidget);
      final unlockAction = harness.key('draft_compatibility_topic_action');
      for (var topic = 1; topic <= 6; topic++) {
        expect(
          harness.key('draft_compatibility_locked_topic_$topic'),
          findsOneWidget,
        );
        expect(
          harness.key('draft_compatibility_category_score_$topic'),
          findsNothing,
        );
        expect(find.text('Every topic comes with Seeker One'), findsOneWidget);
        expect(find.text('Uses 1 Unlock · 1 left'), findsOneWidget);
        if (topic < 6) await harness.tap('draft_compatibility_score_next');
      }
      await harness.tap('draft_compatibility_score_next');
      expect(find.text('1 / 7'), findsOneWidget);
      await harness.tap('draft_compatibility_score_next');
      final upgrade = harness.key('draft_compatibility_topic_upgrade');
      final lockedViewport = tester.getRect(
        harness.key('draft_compatibility_locked_topic_1'),
      );
      for (final control in [
        unlockAction,
        find.text('Uses 1 Unlock · 1 left'),
        upgrade,
      ]) {
        expect(
          tester.getRect(control).bottom,
          lessThanOrEqualTo(lockedViewport.bottom),
          reason:
              'Default-size topic actions must be visible before scrolling.',
        );
      }
      if (_captures.isNotEmpty) {
        await harness.capture(
          'compatibility',
          'compatibility_topics',
          'seeker_basic_$dimensions',
          'Actual admitted Journey Options → Compatibility score → Lifestyle',
        );
      }

      await harness.tapFinder(upgrade);
      expect(find.byType(ZyraOneUpgradePage), findsOneWidget);
      await harness.tapText('Not now');
      await harness.tap('draft_compatibility_score_next');
      final stale = tester.widget<FilledButton>(unlockAction).onPressed!;
      await harness.tapFinder(unlockAction);
      stale();
      await harness.flush();
      expect(find.text('1 / 7'), findsOneWidget);
      expect(find.text('Every topic is now open for Sara.'), findsOneWidget);
      await harness.tap('draft_compatibility_score_next');
      expect(
        harness.key('draft_compatibility_category_score_1'),
        findsOneWidget,
      );
      expect(find.text('Every topic comes with Seeker One'), findsNothing);
      expect(harness.latest.compatibilityBalance, 0);
      expect(harness.latest.compatibilityRevealed, isTrue);
    });
  }

  testWidgets('Basic zero balance opens the Unlock store from a topic', (
    tester,
  ) async {
    final harness = BaselineHarness(
      tester,
      group: 'line81_compatibility_store',
      reduceMotion: true,
    );
    await harness.mount(checkpoint: _basicJourney());
    final access = zyraShellFixtureFor(tester).compatibilityAccess!;
    expect(access.setBalance(count: 0), isTrue);
    await _openCompatibility(harness);
    await harness.tap('draft_compatibility_score_next');
    expect(find.text('0 Unlocks left'), findsOneWidget);
    await harness.tapText('Get an Unlock for Sara');
    expect(
      find.byType(ZyraDraftCompatibilityStorePresentation),
      findsOneWidget,
    );
    expect(access.balance, 0);
    expect(access.isUnlocked(_person), isFalse);
  });

  testWidgets('Basic topic gate never bypasses mutual Journey disclosure', (
    tester,
  ) async {
    final harness = BaselineHarness(
      tester,
      group: 'line81_compatibility_consent',
    );
    await harness.mount(checkpoint: _basicJourney(mutual: false));
    await _openCompatibility(harness);
    expect(
      harness.key('draft_journey_compatibility_locked_$_person'),
      findsOneWidget,
    );
    expect(find.byType(ZyraCompatibilityScoreReader), findsNothing);
    expect(find.text('See every topic for Sara'), findsNothing);
  });

  testWidgets('Basic archive stays read-only and reuses an earlier Unlock', (
    tester,
  ) async {
    final harness = BaselineHarness(
      tester,
      group: 'line81_compatibility_archive',
      reduceMotion: true,
    );
    var now = DateTime.utc(2026, 11, 11);
    await harness.mount(
      checkpoint: _basicJourney(archived: true),
      previewClock: () => now,
    );
    await harness.tap('draft_compatibility_score_next');
    expect(find.text('Every topic comes with Seeker One'), findsOneWidget);
    final action = harness.key('draft_compatibility_topic_action');
    expect(action, findsNothing);
    expect(harness.key('draft_compatibility_topic_upgrade'), findsNothing);
    final fixture = zyraShellFixtureFor(tester);
    final access = fixture.compatibilityAccess!;
    now = DateTime.utc(2027, 2, 1);
    expect(fixture.refresh(), isTrue);
    await harness.flush();
    expect(
      harness.key('draft_ended_compatibility_locked_$_person'),
      findsOneWidget,
    );
    expect(access.balance, 1);
    expect(access.isUnlocked(_person), isFalse);

    // A grant supplied by the same store from another authorized route
    // remains readable even after the archived Journey window expires.
    expect(access.unlock(_person), isTrue);
    expect(fixture.refresh(), isTrue);
    await harness.flush();
    await harness.tap('draft_compatibility_score_next');
    expect(harness.key('draft_compatibility_category_score_1'), findsOneWidget);
    expect(action, findsNothing);
    expect(access.balance, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'Guardian Basic reader offers Guardian One without a Seeker Unlock',
    (tester) async {
      var upgrades = 0;
      var spends = 0;
      final harness = BaselineHarness(
        tester,
        group: 'line81_guardian_topic_presentation',
        reduceMotion: true,
      );
      await harness.mountPresentation(
        checkpoint: _basicJourney(),
        child: Scaffold(
          body: SafeArea(
            child: ZyraCompatibilityScoreReader(
              personName: 'Sara',
              overallScore: 78,
              topicGate: ZyraCompatibilityTopicGate(
                guardian: true,
                canAct: () => true,
                onUpgrade: () => upgrades++,
                balance: 5,
                onUnlock: () => spends++,
              ),
            ),
          ),
        ),
      );
      expect(find.text('1 / 7'), findsOneWidget);
      await harness.tap('draft_compatibility_score_next');
      expect(find.text('Every topic comes with Guardian One'), findsOneWidget);
      expect(harness.key('draft_compatibility_category_score_1'), findsNothing);
      expect(find.textContaining('Unlock'), findsNothing);
      await harness.tapText('See Guardian One');
      expect(upgrades, 1);
      expect(spends, 0);
    },
  );
}
