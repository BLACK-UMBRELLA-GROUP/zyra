import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_compatibility_score_designs.dart';
import 'package:zyra/dev/zyra_draft_compatibility_store_presentation.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/models/zyra_compatibility_area.dart';
import 'package:zyra/screens/subscription/zyra_one_upgrade_page.dart';
import 'package:zyra/widgets/zyra_browse_options_button.dart';
import 'package:zyra/widgets/zyra_compatibility_area_row.dart';

import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

const _person = 'draft-sara';
const _next = 'draft_compatibility_score_next';
const _action = 'draft_compatibility_area_action';
const _upgrade = 'draft_compatibility_area_upgrade';
Finder get _reader => find.byType(ZyraCompatibilityScoreReader);
const _captures = String.fromEnvironment(
  'ZYRA_LINE81_COMPATIBILITY_CAPTURE_DIR',
);

ZyraPreviewNavigationCheckpoint _basicJourney({
  bool mutual = true,
  bool archived = false,
  String? historyPage,
  bool one = false,
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
    pages: !archived
        ? const []
        : historyPage != null
        ? [historyPage]
        : const ['ended', 'ended_compatibility'],
    personId: _person,
    seekerMembership: one ? 'Seeker One' : 'Seeker Basic',
  );
}

Future<void> _openCompatibility(BaselineHarness harness) async {
  if (harness.latest.pages.any(const {'ended', 'past_journeys'}.contains)) {
    // LOCK 2 V4 preserves the archived reader behind the Timeline door.
    await harness.tap('draft_journey_${_person}_header');
    await harness.tap('draft_ended_view_$_person');
    await harness.tap('draft_ended_timeline_$_person');
    await harness.tapFinder(find.text('View compatibility').first);
    return;
  }
  await harness.tap('draft_journey_options_$_person');
  await harness.tap('draft_options_compatibility_$_person');
}

void _expectAreas(WidgetTester tester, {required bool locked}) {
  expect(find.text('2 / 2'), findsOneWidget);
  expect(find.text('Every area'), findsOneWidget);
  final areaPage = find.byKey(const ValueKey('draft_compatibility_areas'));
  final rows = find.descendant(
    of: areaPage,
    matching: find.byType(ZyraCompatibilityAreaRow),
  );
  expect(
    tester.widgetList<ZyraCompatibilityAreaRow>(rows).map((row) => row.area),
    ZyraCompatibilityArea.values,
  );
  expect(
    find.descendant(of: areaPage, matching: find.textContaining('%')),
    findsNothing,
  );
  final reader = tester.widget<ZyraCompatibilityScoreReader>(_reader);
  if (locked) {
    expect(reader.areaBands, isNull);
    expect(find.text('Locked'), findsNWidgets(12));
    for (final band in ZyraCompatibilityBand.values) {
      expect(find.text(band.label), findsNothing);
    }
  } else {
    expect(reader.areaBands?.length, 12);
    expect(find.text('Locked'), findsNothing);
    for (final band in ZyraCompatibilityBand.values) {
      expect(find.text(band.label), findsWidgets);
    }
  }
}

Future<void> _capture(
  BaselineHarness harness,
  String name,
  String reached,
) async {
  if (_captures.isEmpty) return;
  await harness.capture('compatibility', 'seeker_compatibility', name, reached);
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
    BaselineHarness harnessFor(WidgetTester tester, String state) =>
        BaselineHarness(
          tester,
          group: 'line91_seeker_${state}_$dimensions',
          outputRoot: _captures,
          evidenceRoot: _captures,
          flatOutput: true,
          logicalSize: size,
          safePadding: safePadding,
          reduceMotion: true,
        );

    testWidgets('Seeker Basic Journey areas and Unlock at $dimensions', (
      tester,
    ) async {
      final harness = harnessFor(tester, 'journey_basic');
      await harness.mount(checkpoint: _basicJourney());
      await _openCompatibility(harness);
      expect(find.text('1 / 2'), findsOneWidget);
      expect(harness.key('draft_compatibility_overall_score'), findsOneWidget);
      expect(find.text('See every area for Sara'), findsNothing);
      await _capture(
        harness,
        'journey_basic_overall_$dimensions',
        'Seeker Basic Journey options → Compatibility score',
      );

      final pages = harness.key('draft_compatibility_score_pages');
      await tester.drag(pages, const Offset(-240, 0));
      await harness.flush();
      _expectAreas(tester, locked: true);
      expect(find.text('Uses 1 Unlock · 1 left'), findsOneWidget);
      await _capture(
        harness,
        'journey_basic_locked_$dimensions',
        'Seeker Basic Journey → Every area',
      );

      await harness.tap(_next);
      expect(find.text('1 / 2'), findsOneWidget);
      await harness.tap(_next);
      final unlockAction = harness.key(_action);
      final upgrade = harness.key(_upgrade);
      await tester.ensureVisible(upgrade);
      await harness.flush();
      expect(upgrade.hitTestable(), findsOneWidget);
      final lockedViewport = tester.getRect(
        harness.key('draft_compatibility_areas'),
      );
      for (final control in [
        unlockAction,
        find.text('Uses 1 Unlock · 1 left'),
        upgrade,
      ]) {
        expect(
          tester.getRect(control).bottom,
          lessThanOrEqualTo(lockedViewport.bottom + 1),
        );
      }
      if (size.height == 667) {
        await _capture(
          harness,
          'journey_basic_locked_actions_$dimensions',
          'Seeker Basic Journey → Every area → scroll to Unlock and Seeker One',
        );
      }

      await harness.tapFinder(upgrade);
      expect(find.byType(ZyraOneUpgradePage), findsOneWidget);
      await harness.tapText('Not now');
      await harness.tap(_next);
      final stale = tester.widget<FilledButton>(unlockAction).onPressed!;
      await harness.tapFinder(unlockAction);
      stale();
      await harness.flush();
      expect(find.text('1 / 2'), findsOneWidget);
      final notice = find.text('Every area is now open for Sara.');
      expect(notice, findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await harness.flush();
      expect(notice, findsNothing);
      await harness.tap(_next);
      _expectAreas(tester, locked: false);
      await _capture(
        harness,
        'journey_basic_unlocked_$dimensions',
        'Seeker Basic Journey → local Unlock → Every area',
      );
      if (size.height == 667) {
        final lastArea = find.text(ZyraCompatibilityArea.culture.label);
        await tester.ensureVisible(lastArea);
        await harness.flush();
        expect(lastArea.hitTestable(), findsOneWidget);
        expect(find.text('2 / 2').hitTestable(), findsOneWidget);
      }
      expect(harness.latest.compatibilityBalance, 0);
      expect(harness.latest.compatibilityRevealed, isTrue);
    });

    testWidgets('Profiles reuses the saved preview result at $dimensions', (
      tester,
    ) async {
      final harness = harnessFor(tester, 'profiles');
      await harness.mount();
      await harness.tap('concept_browse_menu');
      final option = find.descendant(
        of: harness.key('concept_browse_options_navigation'),
        matching: find.byIcon(ZyraBrowseAction.compatibility.icon),
      );
      expect(option, findsOneWidget);
      await tester.tapAt(tester.getCenter(option));
      await harness.flush();
      harness.assertPage('compatibility');
      await harness.tap('draft_compatibility_reveal');
      final access = harness.shellFixture.compatibilityAccess!;
      final result = access.resultFor(_person)!;
      expect(find.text('1 / 2'), findsOneWidget);
      await _capture(
        harness,
        'profiles_overall_$dimensions',
        'Profiles menu → Compatibility score → local Unlock → Overall',
      );
      await harness.tap(_next);
      _expectAreas(tester, locked: false);
      final lastRow = find.byKey(const ValueKey(ZyraCompatibilityArea.culture));
      final areaPage = harness.key('draft_compatibility_areas');
      expect(
        tester.getRect(lastRow).bottom,
        lessThanOrEqualTo(tester.getRect(areaPage).bottom + .5),
        reason: 'The final area is fully visible in the first admitted frame.',
      );
      expect(
        tester.widget<ZyraCompatibilityScoreReader>(_reader).areaBands,
        same(result.areaBands),
      );
      expect(access.balance, 0);
      await _capture(
        harness,
        'profiles_areas_$dimensions',
        'Profiles menu → Compatibility score → local Unlock → Every area',
      );
    });

    testWidgets('Seeker One Journey keeps the saved result at $dimensions', (
      tester,
    ) async {
      final harness = harnessFor(tester, 'journey_one');
      await harness.mount(checkpoint: _basicJourney(one: true));
      await _openCompatibility(harness);
      expect(_reader, findsNothing);
      expect(
        find.text(
          'You both chose to reveal. Your result is not available yet.',
        ),
        findsOneWidget,
      );
      final access = harness.shellFixture.compatibilityAccess!;
      expect(access.unlock(_person), isTrue);
      expect(harness.shellFixture.refresh(), isTrue);
      await harness.flush();
      expect(find.text('1 / 2'), findsOneWidget);
      await _capture(
        harness,
        'journey_one_overall_$dimensions',
        'Seeker One Journey options → Compatibility score with saved result',
      );
      await harness.tap(_next);
      _expectAreas(tester, locked: false);
      expect(
        tester.widget<ZyraCompatibilityScoreReader>(_reader).areaBands,
        same(access.resultFor(_person)!.areaBands),
      );
      await _capture(
        harness,
        'journey_one_areas_$dimensions',
        'Seeker One Journey → Every area with saved result',
      );
    });

    for (final historyPage in ['ended', 'past_journeys']) {
      testWidgets('Seeker $historyPage reader stays read-only at $dimensions', (
        tester,
      ) async {
        final harness = harnessFor(tester, historyPage);
        await harness.mount(
          checkpoint: _basicJourney(archived: true, historyPage: historyPage),
          previewClock: () => DateTime.utc(2026, 11, 11),
        );
        await _openCompatibility(harness);
        harness.assertPage('ended_compatibility');
        expect(find.text('1 / 2'), findsOneWidget);
        await _capture(
          harness,
          '${historyPage}_overall_$dimensions',
          'Seeker $historyPage → View Timeline → Timeline → Compatibility score',
        );
        await harness.tap(_next);
        _expectAreas(tester, locked: true);
        expect(harness.key(_action), findsNothing);
        expect(harness.key(_upgrade), findsNothing);
        await _capture(
          harness,
          '${historyPage}_locked_$dimensions',
          'Seeker $historyPage → read-only Every area',
        );
        final access = harness.shellFixture.compatibilityAccess!;
        expect(access.unlock(_person), isTrue);
        expect(harness.shellFixture.refresh(), isTrue);
        await harness.flush();
        expect(find.text('1 / 2'), findsOneWidget);
        await harness.tap(_next);
        _expectAreas(tester, locked: false);
        expect(
          tester.widget<ZyraCompatibilityScoreReader>(_reader).areaBands,
          same(access.resultFor(_person)!.areaBands),
        );
        expect(harness.key(_action), findsNothing);
        await _capture(
          harness,
          '${historyPage}_unlocked_$dimensions',
          'Seeker $historyPage → Every area with prior person-specific Unlock',
        );
      });
    }
  }

  testWidgets('Basic zero balance opens the Unlock store from Every area', (
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

  testWidgets('Basic area gate never bypasses mutual Journey disclosure', (
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
    expect(find.text('See every area for Sara'), findsNothing);
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
    _expectAreas(tester, locked: true);
    final action = harness.key(_action);
    expect(action, findsNothing);
    expect(harness.key(_upgrade), findsNothing);
    final fixture = zyraShellFixtureFor(tester);
    final access = fixture.compatibilityAccess!;
    now = DateTime.utc(2027, 2, 1);
    expect(fixture.refresh(), isTrue);
    await harness.flush();
    _expectAreas(tester, locked: true);
    expect(access.balance, 1);
    expect(access.isUnlocked(_person), isFalse);

    // An independent authorized Unlock opens the areas. The dated archive
    // itself remains readable without spending a credit.
    expect(access.unlock(_person), isTrue);
    expect(fixture.refresh(), isTrue);
    await harness.flush();
    await harness.tap('draft_compatibility_score_next');
    _expectAreas(tester, locked: false);
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
        group: 'line91_guardian_area_presentation',
        reduceMotion: true,
      );
      await harness.mountPresentation(
        checkpoint: _basicJourney(),
        child: Scaffold(
          body: SafeArea(
            child: ZyraCompatibilityScoreReader(
              personName: 'Sara',
              overallScore: 78,
              areaGate: ZyraCompatibilityAreaGate(
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
      expect(find.text('1 / 2'), findsOneWidget);
      await harness.tap('draft_compatibility_score_next');
      _expectAreas(tester, locked: true);
      expect(find.textContaining('Unlock'), findsNothing);
      await harness.tapText('See Guardian One');
      expect(upgrades, 1);
      expect(spends, 0);
    },
  );
}
