// Opt-in LOCK 36 evidence of the real Founder shell; no reference images change.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_one_journey_sample_photos.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import '../support/received_request_fixture.dart';
import 'baseline_capture_support.dart';

const _output = String.fromEnvironment('ZYRA_LINE124_OUTPUT');
late ZyraOneJourneySamplePhotos _photos;

const _seekerFrames = [
  't00_welcome',
  't01_profiles_this_is_profiles',
  't02_profiles_each_card_is_one_person',
  't03_profiles_see_their_photos',
  't04_profiles_ready_to_begin',
  't05_journey_this_is_journey',
  't06_journey_nothing_here_yet',
  't07_my_zyra_this_is_my_zyra',
  't08_my_zyra_needs_you',
  't09_my_zyra_at_a_glance',
  't10_my_zyra_quick_access',
  't11_guardian_this_is_guardian',
  't12_guardian_your_guardians',
  't13_guardian_what_they_can_see',
  't14_guardian_talk_and_add',
  't15_profile_this_is_profile',
  't16_profile_your_profile',
  't17_profile_your_membership',
  't18_profile_settings',
  't19_end',
];

const _guardianFrames = [
  'tg00_welcome',
  'tg01_network_this_is_network',
  'tg02_network_choose_your_seeker',
  'tg03_network_introduce_or_connect',
  'tg04_journeys_this_is_journeys',
  'tg05_journeys_open_a_journey',
  'tg06_my_zyra_this_is_my_zyra',
  'tg07_my_zyra_needs_you',
  'tg08_my_zyra_quick_access',
  'tg09_seekers_this_is_seekers',
  'tg10_seekers_swipe_through',
  'tg11_seekers_talk_and_invite',
  'tg12_profile_this_is_profile',
  'tg13_profile_your_membership',
  'tg14_profile_settings',
  'tg15_end',
];

// LOCK 36 page order, including each welcome and end card.
const _seekerTabs = [
  0,
  0,
  0,
  0,
  0,
  1,
  1,
  2,
  2,
  2,
  2,
  3,
  3,
  3,
  3,
  4,
  4,
  4,
  4,
  4,
];
const _guardianTabs = [2, 0, 0, 0, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 4];

Finder _key(String value) => find.byKey(ValueKey(value));

BaselineHarness _harness(WidgetTester tester) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return BaselineHarness(
    tester,
    group: 'line124_first_tour',
    outputRoot: _output,
    evidenceRoot: _output,
    flatOutput: true,
    logicalSize: const Size(430, 932),
    devicePixelRatio: 3,
    reduceMotion: true,
  );
}

Future<void> _mount(
  BaselineHarness harness, {
  required bool guardian,
  int? tourIndex,
  int? initialTab,
  List<String> pages = const [],
}) async {
  // This existing sample supplies an incoming request without a Seeker Journey.
  // Guardian Journey targets use the same populated fixture as LOCK 35 checks.
  final model = ReceivedRequestFixture(capacity: 3);
  if (guardian) expect(model.seedJourneys(1), isTrue);
  final checkpoint = ZyraPreviewNavigationCheckpoint(
    guardian: guardian,
    model: model.snapshot(),
    guardianTabs: guardian
        ? const ZyraGuardianTabsSnapshot(
            connection: ZyraGuardianConnection.pending,
          )
        : const ZyraGuardianTabsSnapshot.quiet(),
    tab:
        initialTab ??
        (pages.isNotEmpty
            ? 4
            : tourIndex == null
            ? (guardian ? 2 : 0)
            : (guardian ? _guardianTabs : _seekerTabs)[tourIndex]),
    pages: pages,
    seekerMembership: 'Seeker One',
    guardianMembership: 'Guardian One',
  );
  final ready = Completer<void>();
  await harness.mountPresentation(
    checkpoint: checkpoint,
    child: ZyraOneJourneyConceptShell(
      key: UniqueKey(),
      canAct: () => true,
      onExit: () =>
          fail('The tour capture stays in the local Founder preview.'),
      initialGuardianRole: guardian,
      initialCheckpoint: checkpoint,
      restoreLocation: true,
      previewClock: () => DateTime.utc(2026, 11, 19, 18, 40),
      onPresentationReady: () {
        if (!ready.isCompleted) ready.complete();
      },
      fixture: ZyraOneJourneyShellFixture(
        firstTourIndex: tourIndex,
        seekerPhotos: [_photos.seekerPhoto],
      ),
    ),
  );
  for (var attempt = 0; attempt < 150 && !ready.isCompleted; attempt++) {
    await harness.tester.pump(const Duration(milliseconds: 20));
    await harness.tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  expect(
    ready.isCompleted,
    isTrue,
    reason: 'Bundled sample photos must prepare',
  );
  await harness.flush();
  if (pages.isEmpty) {
    expect(
      harness.tester
          .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
          .currentIndex,
      checkpoint.tab,
      reason: 'The real shell tab must match the locked page and evidence row',
    );
  }
}

void _assertPlacement(WidgetTester tester) {
  final noteFinder = _key('first_tour_note');
  final targetFinder = _key('first_tour_target');
  final tabFinder = _key('first_tour_tab');
  expect(noteFinder, findsOneWidget);
  expect(targetFinder, findsOneWidget);
  expect(tabFinder, findsOneWidget);
  final note = tester.getRect(noteFinder);
  final target = tester.getRect(targetFinder);
  final tab = tester.getRect(tabFinder);
  expect(note.size.isEmpty, isFalse);
  expect(target.size.isEmpty, isFalse);
  expect(tab.size.isEmpty, isFalse);
  expect(
    note.overlaps(target),
    isFalse,
    reason: 'Q175 keeps the lit item clear',
  );
  expect(
    note.overlaps(tab),
    isFalse,
    reason: 'Q175 keeps the current tab clear',
  );
  expect(note.left, greaterThanOrEqualTo(20));
  expect(note.right, lessThanOrEqualTo(410));
  expect(note.top, greaterThanOrEqualTo(48));
}

Future<void> _capture(BaselineHarness harness, String name) async {
  final previousShadows = debugDisableShadows;
  debugDisableShadows = false;
  try {
    void repaint(RenderObject node) {
      node.markNeedsPaint();
      node.visitChildren(repaint);
    }

    repaint(
      harness.tester.renderObject(_key('zyra-founder-baseline-boundary')),
    );
    await harness.tester.pump();
    await harness.capture(
      'first_tour',
      name,
      'lock36',
      'Real offline Founder shell with existing sample data and LOCK 36 overlay; '
          'Reduce Motion keeps the touch point still.',
      fileName: '$name.png',
    );
  } finally {
    debugDisableShadows = previousShadows;
  }
}

void main() {
  setUpAll(() async {
    await baselineSetUp(
      evidenceRoot: _output.isEmpty ? null : _output,
      useSystemSymbolFont: Platform.isMacOS,
    );
    _photos = await ZyraOneJourneySamplePhotos.load();
  });
  tearDownAll(baselineTearDown);

  testWidgets(
    'LOCK36 Guardian welcome preserves the current tab before Network begins',
    (tester) async {
      final harness = _harness(tester);
      for (final tab in [2, 1, 3, 4, 0]) {
        await _mount(harness, guardian: true, tourIndex: 0, initialTab: tab);
        expect(find.text('Hi Hassan, welcome'), findsOneWidget);
        expect(
          tester
              .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
              .currentIndex,
          tab,
        );
        if (tab == 2) expect(find.text('My ZYRA'), findsOneWidget);
        await tester.tap(_key('first_tour_next'));
        await harness.flush();
        expect(find.text('This is Network'), findsOneWidget);
        expect(
          tester
              .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
              .currentIndex,
          0,
        );
      }
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK36 Guardian replay opens over Profile then restores Settings',
    (tester) async {
      final harness = _harness(tester);
      await _mount(harness, guardian: true, pages: const ['settings']);
      final replay = find.text('Replay the walkthrough');
      await Scrollable.ensureVisible(tester.element(replay), alignment: .5);
      await harness.flush();
      await tester.tap(replay);
      await harness.flush();
      expect(find.text('Hi Hassan, welcome'), findsOneWidget);
      expect(
        tester
            .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
            .currentIndex,
        4,
      );
      for (var step = 0; step < _guardianFrames.length; step++) {
        await tester.tap(_key('first_tour_next'));
        await harness.flush();
      }
      expect(_key('first_tour_overlay'), findsNothing);
      expect(find.text('Replay the walkthrough'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  for (final guardian in [false, true]) {
    final frames = guardian ? _guardianFrames : _seekerFrames;
    for (var index = 0; index < frames.length; index++) {
      final name = frames[index];
      testWidgets(
        'LOCK36 real shell $name',
        (tester) async {
          final harness = _harness(tester);
          await _mount(harness, guardian: guardian, tourIndex: index);
          expect(_key('first_tour_overlay'), findsOneWidget);
          if (index > 0 && index < frames.length - 1) {
            _assertPlacement(tester);
          }
          await _capture(harness, name);
          expect(tester.takeException(), isNull);
        },
        skip: _output.isEmpty,
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );
    }
  }

  testWidgets(
    'LOCK36 real Settings has Replay first in Support',
    (tester) async {
      final harness = _harness(tester);
      await _mount(harness, guardian: false, pages: const ['settings']);
      expect(_key('first_tour_overlay'), findsNothing);
      final replay = find.text('Replay the walkthrough');
      expect(replay, findsOneWidget);
      await Scrollable.ensureVisible(tester.element(replay), alignment: .5);
      await harness.flush();
      expect(replay.hitTestable(), findsOneWidget);
      expect(
        tester.getTopLeft(replay).dy,
        lessThan(tester.getTopLeft(find.text('Help & support')).dy),
      );
      await _capture(harness, 't99_settings_replay_row');
      expect(tester.takeException(), isNull);
    },
    skip: _output.isEmpty,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
