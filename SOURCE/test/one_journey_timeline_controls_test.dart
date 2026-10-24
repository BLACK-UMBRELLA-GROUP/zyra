// Actual request-shell Timeline controls, using only detached offline fixtures.
// These tests cannot establish member access, write real history or disclose
// compatibility answers through a testing scenario.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_stages.dart';
import 'package:zyra/data/zyra_timeline_milestones.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_draft_timeline_presentation.dart';
import 'package:zyra/dev/zyra_draft_timeline_preview.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _font = 'PoppinsTimelineShellControls';

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Timeline shell fixtures must remain offline.');
  }
}

Finder _key(String key) => find.byKey(ValueKey(key));
Finder get _timeline => find.byType(ZyraDraftTimelinePresentation);

Finder _picker<T>(String kind) => find.byWidgetPredicate((widget) {
  if (widget is! DropdownButtonFormField<T>) return false;
  final key = widget.key;
  if (key is! ValueKey) return false;
  final value = key.value;
  return value is (String, Object) &&
      value.$1 == 'concept_timeline_${kind}_dropdown';
});

ZyraPreviewNavigationCheckpoint _seed({
  bool preparing = false,
  bool guardian = false,
  int tab = 1,
  String subject = 'draft-sara',
  List<String> pages = const ['timeline'],
}) {
  final model = ViewRequestDraftModel(capacity: 3);
  if (preparing) {
    expect(model.acceptReceived('draft-amira'), isTrue);
  } else {
    expect(model.seedJourneys(3), isTrue);
  }
  return ZyraPreviewNavigationCheckpoint(
    guardian: guardian,
    model: model.snapshot(),
    tab: tab,
    pages: pages,
    personId: preparing ? 'draft-amira' : subject,
  );
}

Future<void> _flush(WidgetTester tester) async {
  // Loading is an intentional test scenario; do not require an indefinitely
  // animating loading indicator to settle before checking its actual state.
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
  expect(tester.takeException(), isNull);
}

class _Owner {
  bool allowed = true;
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];

  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;

  Future<void> mount(
    WidgetTester tester, {
    required ZyraPreviewNavigationCheckpoint checkpoint,
    bool guardian = false,
  }) async {
    final ready = Completer<void>();
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: ZyraOneJourneyConceptShell(
          key: UniqueKey(),
          canAct: () => allowed,
          onExit: () => fail('Timeline testing must not exit its app owner.'),
          initialGuardianRole: guardian,
          initialCheckpoint: checkpoint,
          onCheckpoint: checkpoints.add,
          onPresentationReady: () {
            if (!ready.isCompleted) ready.complete();
          },
        ),
      ),
    );
    for (var frame = 0; frame < 100 && !ready.isCompleted; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(
      ready.isCompleted,
      isTrue,
      reason: 'Actual bundled deck preparation completes',
    );
    await _flush(tester);
    expect(checkpoints, isNotEmpty);
  }
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  expect(target, findsOneWidget);
  if (find
      .ancestor(of: target, matching: find.byType(Scrollable))
      .evaluate()
      .isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await _flush(tester);
  }
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await _flush(tester);
}

Future<void> _controls(WidgetTester tester) async {
  // The shared rail's current source identity, also used by the Journey
  // expansion and Page-options suites. Do not invent a separate controls door.
  await toggleZyraDevControls(tester);
  expect(find.text('Page options'), findsOneWidget);
}

Future<void> _closeControls(WidgetTester tester) async {
  await toggleZyraDevControls(tester);
  expect(find.text('Page options'), findsNothing);
  expect(_timeline, findsOneWidget);
}

ZyraDraftTimelinePresentation _shown(WidgetTester tester) =>
    tester.widget<ZyraDraftTimelinePresentation>(_timeline);

void _expectCurrent(WidgetTester tester, String subject) {
  final current = _shown(tester);
  expect(current.subjectId, subject);
  expect(current.view.status, ZyraDraftTimelineStatus.ready);
  expect(current.view.pending, isNull);
  expect(current.view.entries.map((entry) => entry.type), [
    'match_created',
    'journey_started',
  ]);
  expect(current.view.entries.first.invitationAccepted, isTrue);
  expect(current.view.entries.first.answers, isEmpty);
  expect(
    current.view.entries.every((entry) => entry.occurredOn == null),
    isTrue,
    reason: 'Current draft facts never manufacture dated history',
  );
}

Future<void> _selectScenario(
  WidgetTester tester,
  ZyraDraftTimelineScenario scenario,
) async {
  final picker = tester
      .widget<DropdownButtonFormField<ZyraDraftTimelineScenario>>(
        _picker<ZyraDraftTimelineScenario>('scenario'),
      );
  picker.onChanged!(scenario);
  await _flush(tester);
}

Future<void> _actualAllEventsSelection(WidgetTester tester) async {
  final field = _picker<ZyraDraftTimelineScenario>('scenario');
  await Scrollable.ensureVisible(tester.element(field), alignment: .5);
  await _flush(tester);
  final dropdown = find.descendant(
    of: field,
    matching: find.byType(DropdownButton<ZyraDraftTimelineScenario>),
  );
  await _tap(tester, dropdown);
  final popup = find.byWidgetPredicate(
    (widget) =>
        widget is Semantics && widget.properties.role == ui.SemanticsRole.menu,
  );
  expect(popup, findsOneWidget);
  final choice = find.descendant(
    of: popup,
    matching: find.text(ZyraDraftTimelineScenario.allEvents.label),
  );
  final scroll = find.descendant(of: popup, matching: find.byType(Scrollable));
  await tester.scrollUntilVisible(
    choice,
    80,
    scrollable: scroll,
    maxScrolls: 10,
  );
  await _tap(tester, choice);
}

Future<void> _pullBack(WidgetTester tester) async {
  // The locked-in return is the physical left-edge horizontal gesture, not
  // the retired vertical pull. Keep the real gesture and every close assertion.
  await returnZyraPreviewPage(tester);
  await _flush(tester);
}

Future<void> _openSubject(WidgetTester tester, String subject) async {
  await _tap(tester, _key('draft_journey_options_$subject'));
  await _tap(tester, _key('draft_options_timeline_$subject'));
  expect(_shown(tester).subjectId, subject);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;
  late bool oldFontStubs;
  late String? oldReading;
  late ZyraHapticLevel oldHaptics;

  setUpAll(() async {
    final reading = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });

  setUp(() {
    oldFontStubs = ZyraText.useTestFontStubs;
    oldReading = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    final gold = ZyraDevAppGold.instance;
    gold.select(
      false,
      expectedGeneration: ZyraAccountState.generation,
      expectedRevision: gold.revision,
    );
    oldHaptics = ZyraInteractionStyle.hapticLevel;
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.off);
    oldNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = oldNetwork;
    ZyraText.useTestFontStubs = oldFontStubs;
    ZyraText.testReadingFontFamily = oldReading;
    ZyraInteractionStyle.selectHapticLevel(oldHaptics);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'preparing Timeline records only undated invitation acceptance and active facts have no invented dates',
    (tester) async {
      final preparing = _Owner();
      await preparing.mount(tester, checkpoint: _seed(preparing: true));
      expect(_shown(tester).subjectId, 'draft-amira');
      final accepted = _shown(tester).view.entries;
      expect(accepted, hasLength(1));
      expect(accepted.single.type, 'match_created');
      expect(accepted.single.invitationAccepted, isTrue);
      expect(accepted.single.occurredOn, isNull);
      expect(accepted.single.answers, isEmpty);
      expect(accepted.single.showAnswers, isFalse);
      expect(find.text('Journey invitation accepted'), findsOneWidget);
      expect(_shown(tester).view.currentStageValue, isNull);
      final active = _Owner();
      await active.mount(tester, checkpoint: _seed());
      _expectCurrent(tester, 'draft-sara');
      expect(_shown(tester).ownedViewport, isTrue);
    },
  );

  testWidgets(
    'actual All events popup selection survives covered controls and cannot change Journey facts',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      final initial = owner.latest.model;
      await _controls(tester);
      expect(
        tester.widget<Text>(_key('concept_page_options_context')).data,
        'Timeline',
      );
      await _actualAllEventsSelection(tester);
      await _closeControls(tester);
      expect(
        _shown(tester).view.entries.map((entry) => entry.type),
        ZyraTimelineMilestones.supportedTypes,
      );
      await _controls(tester);
      expect(
        tester
            .widget<DropdownButtonFormField<ZyraDraftTimelineScenario>>(
              _picker<ZyraDraftTimelineScenario>('scenario'),
            )
            .initialValue,
        ZyraDraftTimelineScenario.allEvents,
      );
      await _closeControls(tester);
      expect(_shown(tester).view.entries, hasLength(17));
      expect(owner.latest.model.states, initial.states);
      expect(owner.latest.model.progress, initial.progress);
      expect(owner.latest.model.guardianAccess, initial.guardianAccess);
    },
  );

  testWidgets(
    'all 17 event choices and eight stage positions reach the current Timeline presenter',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      final initial = owner.latest.model;
      expect(ZyraTimelineMilestones.supportedTypes, hasLength(17));
      for (final type in ZyraTimelineMilestones.supportedTypes) {
        await _controls(tester);
        final picker = tester.widget<DropdownButtonFormField<String>>(
          _picker<String>('event'),
        );
        picker.onChanged!(type);
        await _flush(tester);
        await _closeControls(tester);
        expect(_shown(tester).view.entries.map((entry) => entry.type), [type]);
        expect(_shown(tester).subjectId, 'draft-sara');
      }
      expect(ZyraJourneyStages.all, hasLength(8));
      for (final stage in ZyraJourneyStages.all) {
        await _controls(tester);
        final picker = tester.widget<DropdownButtonFormField<String>>(
          _picker<String>('stage'),
        );
        picker.onChanged!(stage.value);
        await _flush(tester);
        await _closeControls(tester);
        expect(_shown(tester).view.currentStageValue, stage.value);
        expect(_shown(tester).subjectId, 'draft-sara');
      }
      expect(owner.latest.model.states, initial.states);
      expect(owner.latest.model.progress, initial.progress);
    },
  );

  testWidgets(
    'empty, loading and unavailable scenarios use actual presentation states and retry is local',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      for (final scenario in [
        ZyraDraftTimelineScenario.empty,
        ZyraDraftTimelineScenario.loading,
        ZyraDraftTimelineScenario.unavailable,
      ]) {
        await _controls(tester);
        await _selectScenario(tester, scenario);
        await _closeControls(tester);
        final view = _shown(tester).view;
        expect(view.entries, isEmpty);
        expect(view.status, switch (scenario) {
          ZyraDraftTimelineScenario.loading => ZyraDraftTimelineStatus.loading,
          ZyraDraftTimelineScenario.unavailable =>
            ZyraDraftTimelineStatus.unavailable,
          _ => ZyraDraftTimelineStatus.ready,
        });
      }
      _shown(tester).onRetry!();
      await _flush(tester);
      _expectCurrent(tester, 'draft-sara');
    },
  );

  testWidgets(
    'Timeline pickers appear only in the addressed Seeker Timeline context',
    (tester) async {
      for (final context in [
        (guardian: false, tab: 0),
        (guardian: false, tab: 1),
        (guardian: true, tab: 0),
        (guardian: true, tab: 1),
      ]) {
        final owner = _Owner();
        await owner.mount(
          tester,
          guardian: context.guardian,
          checkpoint: _seed(
            guardian: context.guardian,
            tab: context.tab,
            pages: const [],
          ),
        );
        await _controls(tester);
        expect(_picker<ZyraDraftTimelineScenario>('scenario'), findsNothing);
        expect(_picker<String>('event'), findsNothing);
        expect(_picker<String>('stage'), findsNothing);
        expect(find.text('Timeline examples'), findsNothing);
      }
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      await _controls(tester);
      expect(_picker<ZyraDraftTimelineScenario>('scenario'), findsOneWidget);
      expect(_picker<String>('event'), findsOneWidget);
      expect(_picker<String>('stage'), findsOneWidget);
      expect(_key('concept_journey_preview_3'), findsNothing);
      expect(_key('draft_compatibility_unlock_1'), findsNothing);
    },
  );

  testWidgets(
    'blocked, unknown and request-only checkpoint subjects disclose no Timeline or its selectors',
    (tester) async {
      for (final invalid in ['blocked', 'unknown', 'request-only']) {
        final model = ViewRequestDraftModel(capacity: 3);
        late final String subject;
        if (invalid == 'request-only') {
          subject = 'draft-amira';
          expect(model.stateFor(subject), DraftJourneyState.received);
        } else {
          expect(model.seedJourneys(3), isTrue);
          subject = invalid == 'blocked' ? 'draft-sara' : 'not-a-draft-profile';
          if (invalid == 'blocked') expect(model.block(subject), isTrue);
        }
        final checkpoint = ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: model.snapshot(),
          tab: 1,
          pages: const ['timeline'],
          personId: subject,
        );
        final owner = _Owner();
        await owner.mount(tester, checkpoint: checkpoint);
        expect(
          _timeline,
          findsNothing,
          reason: '$invalid subject cannot open another relationship history',
        );
        expect(find.text('Journey invitation accepted'), findsNothing);
        await _controls(tester);
        expect(_picker<ZyraDraftTimelineScenario>('scenario'), findsNothing);
        expect(_picker<String>('event'), findsNothing);
        expect(_picker<String>('stage'), findsNothing);
        expect(find.text('Timeline examples'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'closing Timeline or opening another subject resets examples and rejects stale control and action callbacks',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      final oldAction = _shown(tester).onPropose!;
      await _controls(tester);
      await _selectScenario(tester, ZyraDraftTimelineScenario.allEvents);
      final oldChanged = tester
          .widget<DropdownButtonFormField<ZyraDraftTimelineScenario>>(
            _picker<ZyraDraftTimelineScenario>('scenario'),
          )
          .onChanged!;
      await _closeControls(tester);
      await _pullBack(tester);
      expect(_timeline, findsNothing);
      expect(
        find.byType(ZyraOneJourneyConnectionsActiveCard),
        findsNWidgets(3),
      );
      final closedCount = owner.checkpoints.length;
      oldChanged(ZyraDraftTimelineScenario.empty);
      oldAction('meeting');
      await _flush(tester);
      expect(_timeline, findsNothing);
      expect(owner.latest.pages, isEmpty);
      expect(owner.checkpoints.length, closedCount);
      await _openSubject(tester, 'draft-aisha');
      _expectCurrent(tester, 'draft-aisha');
      final before = owner.checkpoints.length;
      oldChanged(ZyraDraftTimelineScenario.allEvents);
      oldAction('meeting');
      await _flush(tester);
      _expectCurrent(tester, 'draft-aisha');
      expect(owner.checkpoints.length, before);
      expect(owner.latest.personId, 'draft-aisha');
      await _pullBack(tester);
      await _openSubject(tester, 'draft-sara');
      _expectCurrent(tester, 'draft-sara');
    },
  );

  testWidgets(
    'role switch revokes old Timeline pickers and presenter actions',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      final oldAction = _shown(tester).onPropose!;
      await _controls(tester);
      final oldChanged = tester
          .widget<DropdownButtonFormField<ZyraDraftTimelineScenario>>(
            _picker<ZyraDraftTimelineScenario>('scenario'),
          )
          .onChanged!;
      await _tap(tester, _key('draft_role_guardian'));
      final before = owner.checkpoints.length;
      oldChanged(ZyraDraftTimelineScenario.allEvents);
      oldAction('meeting');
      await _flush(tester);
      expect(owner.latest.guardian, isTrue);
      expect(owner.latest.pages, isEmpty);
      expect(owner.checkpoints.length, before);
      expect(_timeline, findsNothing);
    },
  );

  testWidgets(
    'denied or replaced owners cannot replay old Timeline controls or actions',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      final oldAction = _shown(tester).onPropose!;
      await _controls(tester);
      final oldChanged = tester
          .widget<DropdownButtonFormField<ZyraDraftTimelineScenario>>(
            _picker<ZyraDraftTimelineScenario>('scenario'),
          )
          .onChanged!;
      final oldCount = owner.checkpoints.length;
      owner.allowed = false;
      oldChanged(ZyraDraftTimelineScenario.allEvents);
      oldAction('meeting');
      await _flush(tester);
      expect(owner.checkpoints.length, oldCount);
      final next = _Owner();
      await next.mount(tester, checkpoint: _seed(subject: 'draft-aisha'));
      final nextCount = next.checkpoints.length;
      oldChanged(ZyraDraftTimelineScenario.allEvents);
      oldAction('meeting');
      await _flush(tester);
      _expectCurrent(tester, 'draft-aisha');
      expect(next.checkpoints.length, nextCount);
      expect(owner.checkpoints.length, oldCount);
    },
  );
}
