// OA-ZYRA-316: capture the existing Timeline through its real shell controls.
// No presenter reconstruction, private state callback or product edit.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_stages.dart';
import 'package:zyra/data/zyra_timeline_milestones.dart';
import 'package:zyra/dev/zyra_draft_timeline_presentation.dart';
import 'package:zyra/dev/zyra_draft_timeline_preview.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

import 'baseline_capture_support.dart';

const _captureEnabled = bool.fromEnvironment('ZYRA_BASELINE_CAPTURE');

Finder _picker<T extends Object>(String kind) =>
    find.byWidgetPredicate((widget) {
      if (widget is! DropdownButtonFormField<T>) return false;
      final key = widget.key;
      if (key is! ValueKey) return false;
      final value = key.value;
      return value is (String, Object) &&
          value.$1 == 'concept_timeline_${kind}_dropdown';
    });

Future<void> _timelineTop(BaselineHarness harness) async {
  final tester = harness.tester;
  final owner = find.byKey(
    const PageStorageKey('draft_timeline_scroll_draft-sara'),
  );
  expect(owner, findsOneWidget);
  final scrollView = tester.widget<SingleChildScrollView>(owner);
  final scrollable = find.descendant(
    of: owner,
    matching: find.byElementPredicate(
      (element) =>
          element.widget is Scrollable &&
          (element.widget as Scrollable).axisDirection == AxisDirection.down &&
          identical(
            element.findAncestorWidgetOfExactType<SingleChildScrollView>(),
            scrollView,
          ),
    ),
  );
  expect(scrollable, findsOneWidget);
  final position = tester.state<ScrollableState>(scrollable).position;
  position.jumpTo(position.minScrollExtent);
  await harness.flush();
  expect(position.pixels, closeTo(position.minScrollExtent, .001));
}

Future<void> _select<T extends Object>(
  BaselineHarness harness,
  String kind,
  T value,
  String label,
) async {
  final tester = harness.tester;
  await _timelineTop(harness);
  await harness.controls();
  final field = _picker<T>(kind);
  expect(field, findsOneWidget);
  await Scrollable.ensureVisible(tester.element(field), alignment: .5);
  await harness.flush();
  final dropdown = find.descendant(
    of: field,
    matching: find.byType(DropdownButton<T>),
  );
  await harness.tapFinder(dropdown);
  final popup = find.byWidgetPredicate(
    (widget) =>
        widget is Semantics && widget.properties.role == ui.SemanticsRole.menu,
  );
  expect(popup, findsOneWidget);
  final choice = find.descendant(of: popup, matching: find.text(label));
  final scroll = find.descendant(of: popup, matching: find.byType(Scrollable));
  expect(scroll, findsOneWidget);
  await tester.scrollUntilVisible(
    choice,
    80,
    scrollable: scroll,
    maxScrolls: 30,
  );
  await harness.tapFinder(choice);
  expect(
    tester.widget<DropdownButtonFormField<T>>(_picker<T>(kind)).initialValue,
    value,
    reason: 'The real shell control must accept the selected capture state.',
  );
  await harness.closeControls();
  harness.assertPage('timeline');
  await _timelineTop(harness);
}

ZyraDraftTimelinePresentation _shown(WidgetTester tester) =>
    tester.widget<ZyraDraftTimelinePresentation>(
      find.byType(ZyraDraftTimelinePresentation),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(baselineSetUp);
  tearDownAll(baselineTearDown);

  testWidgets(
    'capture full-shell Timeline scenarios, events and stages',
    (tester) async {
      final harness = BaselineHarness(tester, group: 'timeline');
      final model = ViewRequestDraftModel(capacity: 3);
      expect(model.seedJourneys(3), isTrue);
      await harness.mount(
        tab: 1,
        pages: const ['timeline'],
        personId: 'draft-sara',
        model: model,
      );
      harness.assertPage('timeline');
      final initial = harness.latest.model;
      expect(ZyraDraftTimelineScenario.values, hasLength(17));
      expect(ZyraDraftTimelinePreview.supportedEvents, hasLength(15));
      expect(ZyraJourneyStages.all, hasLength(8));

      for (final scenario in ZyraDraftTimelineScenario.values) {
        await _select<ZyraDraftTimelineScenario>(
          harness,
          'scenario',
          scenario,
          scenario.label,
        );
        expect(_shown(tester).subjectId, 'draft-sara');
        await harness.capture(
          'journey',
          'timeline',
          'scenario-${scenario.name}',
          'Founder preview: seeded three Active Journeys → Requests → '
              'Sara Timeline → hold developer controls → Timeline examples: '
              '${scenario.label} → close controls',
        );
      }

      for (final event in ZyraDraftTimelinePreview.supportedEvents) {
        await _select<String>(
          harness,
          'event',
          event,
          ZyraTimelineMilestones.labelFor(event),
        );
        expect(_shown(tester).view.entries.map((entry) => entry.type), [event]);
        await harness.capture(
          'journey',
          'timeline',
          'event-$event',
          'Sara Timeline → hold developer controls → Individual event: '
              '${ZyraTimelineMilestones.labelFor(event)} → close controls',
        );
      }

      for (final stage in ZyraJourneyStages.all) {
        await _select<String>(harness, 'stage', stage.value, stage.label);
        expect(_shown(tester).view.currentStageValue, stage.value);
        final marker = find.byKey(
          ValueKey('draft_timeline_here_${stage.value}'),
        );
        expect(marker, findsOneWidget);
        await Scrollable.ensureVisible(tester.element(marker), alignment: .5);
        await harness.flush();
        final markerBounds = tester.getRect(marker);
        expect(markerBounds.top, greaterThanOrEqualTo(59));
        expect(markerBounds.bottom, lessThanOrEqualTo(932 - 34));
        await harness.capture(
          'journey',
          'timeline',
          'stage-${stage.value}',
          'Sara Timeline → hold developer controls → Stage and road ahead: '
              '${stage.label} → close controls → scroll to the current-stage marker',
        );
      }

      expect(harness.rows, hasLength(40));
      expect(harness.latest.model.states, initial.states);
      expect(harness.latest.model.progress, initial.progress);
      expect(harness.latest.model.guardianAccess, initial.guardianAccess);
    },
    skip: !_captureEnabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
