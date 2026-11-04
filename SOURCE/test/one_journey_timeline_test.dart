import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/journey_questions.dart';
import 'package:zyra/data/zyra_journey_stages.dart';
import 'package:zyra/data/zyra_timeline_milestones.dart';
import 'package:zyra/dev/zyra_draft_timeline_presentation.dart';
import 'package:zyra/dev/zyra_draft_timeline_preview.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';

const _capture = String.fromEnvironment('ZYRA_TIMELINE_CAPTURE_DIR');
const _boundary = ValueKey('timeline-presentation-capture');
const _types = [
  'liked',
  'match_created',
  'journey_started',
  'salam_exchanged',
  'compatibility_revealed',
  'guardian_linked',
  'phase_1_complete',
  'journey_paused',
  'journey_continued',
  'phase_2_complete',
  'phase_3_complete',
  'family_stage',
  'conversation_started',
  'meeting',
  'journey_ended',
  'journey_restarted',
  'nikah',
];

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Timeline fixtures must remain offline.');
  }
}

ZyraDraftTimelinePreview _preview({
  DraftJourneyState state = DraftJourneyState.active,
  String stage = 'phase_2',
  bool revealed = true,
}) => ZyraDraftTimelinePreview(
  'draft-sara',
  firstName: 'Sara',
  journeyState: state,
  stageValue: stage,
  compatibilityRevealed: revealed,
);

Future<void> _mount(
  WidgetTester tester,
  ZyraDraftTimelineView view, {
  bool owned = true,
  double scale = 1,
  Size size = const Size(393, 852),
  VoidCallback? retry,
  VoidCallback? compatibility,
  ValueChanged<String>? attemptCompatibility,
  Set<String> readableAttempts = const {},
  VoidCallback? confirm,
  VoidCallback? notYet,
  ValueChanged<String>? propose,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final presenter = ZyraDraftTimelinePresentation(
    subjectId: 'draft-sara',
    firstName: 'Sara',
    view: view,
    ownedViewport: owned,
    onRetry: retry,
    onViewCompatibility: compatibility,
    onViewAttemptCompatibility: attemptCompatibility,
    readableCompatibilityAttemptIds: readableAttempts,
    onConfirm: confirm,
    onNotYet: notYet,
    onPropose: propose,
  );
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: EdgeInsets.only(
            top: size.height < 700 ? 44 : 59,
            bottom: 34,
          ),
          viewPadding: EdgeInsets.only(
            top: size.height < 700 ? 44 : 59,
            bottom: 34,
          ),
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: RepaintBoundary(
        key: _boundary,
        child: Scaffold(
          backgroundColor: ZyraColors.luxuryDarkPurple,
          body: owned
              ? presenter
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: presenter,
                  ),
                ),
        ),
      ),
    ),
  );
  if (view.status == ZyraDraftTimelineStatus.loading) {
    await tester.pump(const Duration(milliseconds: 20));
  } else {
    await tester.pumpAndSettle();
  }
  expect(tester.takeException(), isNull);
}

Future<void> _captureFrame(WidgetTester tester, String name) async {
  if (_capture.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final output = File('$_capture/$name.png');
    expect(output.existsSync(), isFalse);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await output.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;
  late bool oldFontStubs;
  late String? oldFontFamily;

  setUpAll(() async {
    if (_capture.isEmpty) return;
    final directory = Directory(_capture);
    expect(
      directory.existsSync(),
      isFalse,
      reason: 'Visual evidence uses a fresh immutable destination.',
    );
    directory.createSync(recursive: true);
    final font = FontLoader('PoppinsTimelineEvidence');
    for (final weight in ['ExtraLight', 'Light', 'Regular']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await font.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() {
    oldFontStubs = ZyraText.useTestFontStubs;
    oldFontFamily = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    if (_capture.isNotEmpty) {
      ZyraText.testReadingFontFamily = 'PoppinsTimelineEvidence';
    }
    oldNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = oldNetwork;
    ZyraText.useTestFontStubs = oldFontStubs;
    ZyraText.testReadingFontFamily = oldFontFamily;
  });

  List<DraftEndedJourneyAttempt> attempts() {
    final values = <DraftEndedJourneyAttempt>[];
    for (final date in [
      DateTime.utc(2026, 1, 31),
      DateTime.utc(2026, 4, 30),
      DateTime.utc(2026, 8, 31),
    ]) {
      final model = ViewRequestDraftModel(capacity: 3, clock: () => date)
        ..seedJourneys(1);
      expect(model.sendSalam('draft-sara'), isTrue);
      expect(model.simulatePeerSalam('draft-sara'), isTrue);
      expect(model.chooseStageContinue('draft-sara'), isTrue);
      expect(model.simulatePeerStageContinue('draft-sara'), isTrue);
      expect(model.advanceStage('draft-sara'), isTrue);
      if (values.isEmpty) {
        expect(model.chooseCompatibilityReveal('draft-sara'), isTrue);
        expect(model.simulatePeerCompatibilityReveal('draft-sara'), isTrue);
      }
      expect(model.end('draft-sara'), isTrue);
      values.add(model.currentEndedAttemptFor('draft-sara')!);
    }
    final fresh = ViewRequestDraftModel(capacity: 3)..seedJourneys(1);
    final combined = ViewRequestDraftModel.fromSnapshot(
      fresh.snapshot(),
      earlierAttempts: values.reversed,
    );
    expect(combined.stateFor('draft-sara'), DraftJourneyState.active);
    expect(combined.compatibilityRevealed('draft-sara'), isFalse);
    return combined.endedAttemptsFor('draft-sara');
  }

  test(
    'three immutable attempts project chronological metadata without consent carry-forward',
    () {
      final history = attempts();
      final preview = ZyraDraftTimelinePreview(
        'draft-sara',
        firstName: 'Sara',
        journeyState: DraftJourneyState.active,
        stageValue: 'salam_exchange',
        compatibilityRevealed: false,
        endedAttempts: history,
      );
      final view = preview.view;
      final ends = view.entries
          .where((entry) => entry.type == 'journey_ended')
          .toList();
      expect(
        ends.map((entry) => entry.attemptId),
        history.map((attempt) => attempt.id),
      );
      expect(ends.map((entry) => entry.attemptNumber), [1, 2, 3]);
      expect(ends.map((entry) => entry.occurredOn), [
        DateTime.utc(2026, 1, 31),
        DateTime.utc(2026, 4, 30),
        DateTime.utc(2026, 8, 31),
      ]);
      expect(
        view.entries
            .where((entry) => entry.type == 'compatibility_revealed')
            .map((entry) => entry.attemptId),
        [history.first.id],
      );
      expect(view.entries.last.type, 'journey_started');
      expect(view.entries.last.attemptId, isNull);
      expect(view.compatibilityRevealed, isFalse);
      expect(view.currentStageValue, 'salam_exchange');
      expect(view.entries.every((entry) => entry.answers.isEmpty), isTrue);
      expect(view.entries.every((entry) => !entry.answersRevealed), isTrue);
      expect(() => preview.endedAttempts.clear(), throwsUnsupportedError);
      expect(history.first.progress.compatibilityConsent, isTrue);
      expect(history[1].progress.compatibilityConsent, isFalse);
      expect(history[2].progress.compatibilityConsent, isFalse);
    },
  );

  testWidgets(
    'attempt headings retain each Journey and only explicit score doors',
    (tester) async {
      final history = attempts();
      final view = ZyraDraftTimelinePreview(
        'draft-sara',
        firstName: 'Sara',
        journeyState: DraftJourneyState.ended,
        stageValue: 'compatibility_reveal',
        endedAttempts: history,
      ).view;
      String? opened;
      await _mount(
        tester,
        view,
        owned: false,
        readableAttempts: {history.first.id},
        attemptCompatibility: (id) => opened = id,
      );
      for (var index = 0; index < history.length; index++) {
        expect(
          find.byKey(ValueKey('draft_timeline_attempt_${history[index].id}')),
          findsOneWidget,
        );
        expect(find.text('Journey ${index + 1}'), findsOneWidget);
      }
      final door = find.byKey(
        ValueKey('draft_timeline_compatibility_${history.first.id}'),
      );
      expect(door, findsOneWidget);
      await tester.ensureVisible(door);
      await tester.tap(door);
      expect(opened, history.first.id);
      await _mount(
        tester,
        view,
        owned: false,
        attemptCompatibility: (id) => opened = id,
      );
      expect(door, findsNothing);
      expect(
        find.byKey(const ValueKey('draft_timeline_compatibility')),
        findsNothing,
      );
    },
  );

  test('one exact existing17-event vocabulary, no private-event expansion', () {
    expect(ZyraTimelineMilestones.supportedTypes, _types);
    expect(ZyraTimelineMilestones.supportedTypes.toSet(), hasLength(17));
    expect(
      () => ZyraTimelineMilestones.supportedTypes.add('report_submitted'),
      throwsUnsupportedError,
    );
    expect(ZyraTimelineMilestones.labelFor('journey_started'), 'Journey began');
    expect(
      ZyraTimelineMilestones.labelFor('phase_1_complete'),
      'Finished Faith & Values',
    );
    expect(ZyraTimelineMilestones.iconFor('liked'), Icons.handshake_outlined);
    expect(ZyraTimelineMilestones.isQuiet('journey_paused'), isTrue);
    expect(ZyraTimelineMilestones.isQuiet('journey_continued'), isTrue);
    expect(ZyraTimelineMilestones.isQuiet('journey_ended'), isFalse);
    for (final private in [
      'profile_viewed',
      'report_submitted',
      'blocked',
      'end_reason',
      'guardian_decision',
      'credit_spent',
      'proposal_declined',
    ]) {
      expect(ZyraTimelineMilestones.isSupported(private), isFalse);
      expect(() => ZyraDraftTimelineEntry(type: private), throwsArgumentError);
    }
    final legacy = File(
      'lib/screens/matches/journey_timeline_screen.dart',
    ).readAsStringSync();
    for (final helper in [
      'supportedTypes',
      'labelFor(type)',
      'iconFor(type)',
      'isQuiet(type)',
    ]) {
      expect(legacy, contains('ZyraTimelineMilestones.$helper'));
    }
    expect(legacy, isNot(contains("'liked' =>")));
  });

  test(
    'normal draft uses proven progress and never invents dates or answers',
    () {
      final current = _preview().view;
      expect(current.entries.map((entry) => entry.type), [
        'match_created',
        'journey_started',
        'salam_exchanged',
        'compatibility_revealed',
        'guardian_linked',
        'phase_1_complete',
      ]);
      expect(
        current.entries.every((entry) => entry.occurredOn == null),
        isTrue,
      );
      expect(current.entries.every((entry) => entry.answers.isEmpty), isTrue);
      expect(current.currentStageValue, 'phase_2');
      final preparing = _preview(state: DraftJourneyState.preparing).view;
      expect(preparing.entries.single.type, 'match_created');
      expect(preparing.entries.single.invitationAccepted, isTrue);
      expect(preparing.entries.single.occurredOn, isNull);
      expect(preparing.entries.single.answers, isEmpty);
      expect(
        () => ZyraDraftTimelineEntry(
          type: 'journey_ended',
          invitationAccepted: true,
        ),
        throwsArgumentError,
      );
      expect(
        _preview(state: DraftJourneyState.preparing).view.currentStageValue,
        isNull,
      );
      expect(
        _preview(revealed: false).view.entries.map((entry) => entry.type),
        isNot(contains('compatibility_revealed')),
      );
      final ended = _preview(state: DraftJourneyState.ended).view;
      expect(ended.entries.last.type, 'journey_ended');
      expect(ended.frozen, isTrue);
      expect(ended.canPropose, isFalse);
    },
  );

  test('review gallery is explicit, fixed, chronological and immutable', () {
    final preview = _preview();
    final original = preview.view.entries.map((entry) => entry.type).toList();
    preview.selectScenario(ZyraDraftTimelineScenario.allEvents);
    final view = preview.view;
    expect(
      view.entries.map((entry) => entry.type),
      _types.where((type) => !ZyraTimelineMilestones.isQuiet(type)),
    );
    for (var i = 1; i < view.entries.length; i++) {
      expect(
        view.entries[i].occurredOn!.isAfter(view.entries[i - 1].occurredOn!),
        isTrue,
      );
    }
    expect(view.entries.first.occurredOn, DateTime(2026, 9, 1));
    expect(() => view.entries.clear(), throwsUnsupportedError);
    preview.selectScenario(ZyraDraftTimelineScenario.current);
    expect(preview.view.entries.map((entry) => entry.type), original);
    expect(
      preview.view.entries.every((entry) => entry.occurredOn == null),
      isTrue,
    );
    expect(preview.selectEvent('safety_concern'), isFalse);
    expect(preview.selectEvent('journey_paused'), isFalse);
    expect(preview.selectEvent('journey_continued'), isFalse);
    expect(preview.selectStage('life_snapshot_preview'), isFalse);
  });

  test('all canonical positions use the same eight-stage map', () {
    final preview = _preview();
    for (final stage in ZyraJourneyStages.all) {
      expect(preview.selectStage(stage.value), isTrue);
      expect(preview.view.currentStageValue, stage.value);
      expect(preview.view.entries.first.type, 'journey_started');
    }
  });

  test('pending mutual milestones are not recorded until confirmation', () {
    final preview = _preview();
    expect(preview.propose('report'), isFalse);
    expect(preview.propose('meeting'), isTrue);
    expect(
      preview.view.pending!.state,
      ZyraDraftTimelinePendingState.waitingForPeer,
    );
    expect(
      preview.view.entries.map((entry) => entry.type),
      isNot(contains('meeting')),
    );
    expect(preview.confirm(), isFalse);
    preview.selectScenario(ZyraDraftTimelineScenario.meetingToConfirm);
    expect(preview.confirm(), isTrue);
    expect(preview.view.pending, isNull);
    expect(preview.view.entries.last.type, 'meeting');
    preview.selectScenario(ZyraDraftTimelineScenario.nikahToConfirm);
    expect(preview.notYet(), isTrue);
    expect(preview.view.pending, isNull);
    expect(
      preview.view.entries.map((entry) => entry.type),
      isNot(contains('nikah')),
    );
    preview.selectScenario(ZyraDraftTimelineScenario.nikahConfirming);
    expect(preview.confirm(), isFalse);
    expect(_preview(state: DraftJourneyState.ended).propose('nikah'), isFalse);
  });

  testWidgets('empty loading and unavailable stay distinct with local retry', (
    tester,
  ) async {
    final preview = _preview();
    preview.selectScenario(ZyraDraftTimelineScenario.empty);
    await _mount(tester, preview.view);
    expect(find.text('Your story starts here.'), findsOneWidget);
    expect(
      tester.widget(find.byKey(const ValueKey('draft_timeline_empty'))),
      isA<ZyraEmptyState>(),
    );
    preview.selectScenario(ZyraDraftTimelineScenario.loading);
    await _mount(tester, preview.view);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Your story starts here.'), findsNothing);
    expect(
      find.byKey(const ValueKey('draft_timeline_empty_viewport')),
      findsNothing,
    );
    preview.selectScenario(ZyraDraftTimelineScenario.unavailable);
    var retried = 0;
    await _mount(tester, preview.view, retry: () => retried++);
    expect(find.text('Couldn’t load your timeline'), findsOneWidget);
    expect(find.text('Your story starts here.'), findsNothing);
    expect(
      find.byKey(const ValueKey('draft_timeline_empty_viewport')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('draft_timeline_retry')));
    expect(retried, 1);
  });

  for (final enlarged in [false, true]) {
    testWidgets(
      'standalone ready empty Timeline centers its LOCK 22 gold-ring state at ${enlarged ? 'compact200' : 'normal'} size',
      (tester) async {
        await _mount(
          tester,
          ZyraDraftTimelineView(),
          scale: enlarged ? 2 : 1,
          size: enlarged ? const Size(320, 568) : const Size(393, 852),
        );
        final viewport = find.byKey(
          const ValueKey('draft_timeline_empty_viewport'),
        );
        final empty = find.byKey(const ValueKey('draft_timeline_empty'));
        expect(tester.widget(empty), isA<ZyraEmptyState>());
        // LOCK 22 V3, UNITY_PASS/MASTERS/e01–e02: shared 96 pt gold ring.
        final ring = tester.widget<Container>(
          find.descendant(of: empty, matching: find.byType(Container)),
        );
        expect(ring.constraints?.maxWidth, 96);
        expect(ring.constraints?.maxHeight, 96);
        expect((ring.decoration! as BoxDecoration).shape, BoxShape.circle);
        final group = find.descendant(of: empty, matching: find.byType(Column));
        final scroll = tester
            .state<ScrollableState>(
              find.descendant(of: viewport, matching: find.byType(Scrollable)),
            )
            .position;
        if (!enlarged) expect(scroll.maxScrollExtent, 0);
        // Center when it fits; at full 200% preserve natural content height
        // and readable scrolling instead of shrinking the user's type.
        expect(
          tester.getRect(group).center.dy,
          closeTo(
            tester.getRect(viewport).center.dy + scroll.maxScrollExtent / 2,
            .01,
          ),
        );
        final icon = tester.widget<Icon>(
          find.descendant(of: empty, matching: find.byType(Icon)),
        );
        expect(icon.size, 34);
        expect(icon.color, ZyraColors.journeyGold);
        await tester.ensureVisible(find.text('Your story starts here.'));
        await tester.pumpAndSettle();
        expect(
          find.text('Your story starts here.').hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('draft_timeline_retry')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('embedded empty Timeline keeps its inline owner layout', (
    tester,
  ) async {
    await _mount(tester, ZyraDraftTimelineView(), owned: false);
    expect(
      find.byKey(const ValueKey('draft_timeline_empty_viewport')),
      findsNothing,
    );
    expect(find.byType(ZyraEmptyState), findsNothing);
    expect(find.text('Your story starts here.'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Your story starts here.')).style!.fontSize,
      16,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pending or current-stage facts do not become standalone empty Timelines',
    (tester) async {
      await _mount(tester, ZyraDraftTimelineView(currentStageValue: 'phase_2'));
      expect(
        find.byKey(const ValueKey('draft_timeline_empty_viewport')),
        findsNothing,
      );
      expect(find.text('Your story starts here.'), findsNothing);
      await _mount(
        tester,
        ZyraDraftTimelineView(
          pending: ZyraDraftTimelinePending(
            type: 'meeting',
            occurredOn: DateTime.utc(2026, 10, 22),
            state: ZyraDraftTimelinePendingState.waitingForPeer,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('draft_timeline_empty_viewport')),
        findsNothing,
      );
      expect(find.byType(ZyraEmptyState), findsNothing);
      expect(
        find.byKey(const ValueKey('draft_timeline_pending')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('standard title and explicit context use existing typography', (
    tester,
  ) async {
    await _mount(tester, _preview().view);
    final title = tester.widget<Text>(
      find.byKey(const ValueKey('draft_timeline_title')),
    );
    expect(title.data, 'Timeline');
    expect(title.style, ZyraText.pageTitle());
    expect(title.textAlign, TextAlign.left);
    expect(find.text('Journey with Sara'), findsOneWidget);
    expect(find.textContaining('sample'), findsNothing);
    expect(find.textContaining('DEVELOPMENT'), findsNothing);
  });

  testWidgets('locked answers cannot paint supplied hidden answer payload', (
    tester,
  ) async {
    final bank = JourneyQuestions.forPhase(1);
    final view = ZyraDraftTimelineView(
      entries: [
        ZyraDraftTimelineEntry(
          type: 'phase_1_complete',
          showAnswers: true,
          answersRevealed: false,
          answers: [
            ZyraDraftTimelineAnswer(
              questionId: bank.first.id,
              question: bank.first.text,
              mine: 'Never paint mine',
              theirs: 'Never paint theirs',
            ),
          ],
        ),
      ],
    );
    await _mount(tester, view);
    expect(
      find.byKey(const ValueKey('draft_timeline_answers_locked')),
      findsOneWidget,
    );
    expect(find.text('Never paint mine'), findsNothing);
    expect(find.text('Never paint theirs'), findsNothing);
  });

  testWidgets(
    'revealed phase answer opens interactively, same canonical question',
    (tester) async {
      final preview = _preview()
        ..selectScenario(ZyraDraftTimelineScenario.answersRevealed);
      final pair = preview.view.entries.single.answers.single;
      await _mount(tester, preview.view);
      expect(find.text(pair.question), findsOneWidget);
      expect(find.text(pair.mine), findsNothing);
      await tester.tap(find.text(pair.question));
      await tester.pumpAndSettle();
      expect(find.text(pair.mine), findsOneWidget);
      expect(find.text(pair.theirs), findsOneWidget);
      expect(find.text('YOU'), findsOneWidget);
      expect(find.text('SARA'), findsOneWidget);
    },
  );

  testWidgets(
    'compatibility door needs both admitted view and caller callback',
    (tester) async {
      final preview = _preview()..selectEvent('compatibility_revealed');
      await _mount(tester, preview.view);
      expect(
        find.byKey(const ValueKey('draft_timeline_compatibility')),
        findsNothing,
      );
      var opened = 0;
      await _mount(tester, preview.view, compatibility: () => opened++);
      await tester.tap(
        find.byKey(const ValueKey('draft_timeline_compatibility')),
      );
      expect(opened, 1);
      await _mount(
        tester,
        ZyraDraftTimelineView(
          entries: [ZyraDraftTimelineEntry(type: 'compatibility_revealed')],
        ),
        compatibility: () => opened++,
      );
      expect(
        find.byKey(const ValueKey('draft_timeline_compatibility')),
        findsNothing,
      );
      expect(opened, 1);
    },
  );

  testWidgets(
    'pending confirmation calls only provided local callbacks and busy is inert',
    (tester) async {
      final preview = _preview()
        ..selectScenario(ZyraDraftTimelineScenario.nikahToConfirm);
      var confirmations = 0;
      var deferrals = 0;
      await _mount(
        tester,
        preview.view,
        confirm: () => confirmations++,
        notYet: () => deferrals++,
      );
      await tester.tap(find.byKey(const ValueKey('draft_timeline_confirm')));
      await tester.tap(find.byKey(const ValueKey('draft_timeline_not_yet')));
      expect(confirmations, 1);
      expect(deferrals, 1);
      preview.selectScenario(ZyraDraftTimelineScenario.nikahConfirming);
      await _mount(tester, preview.view, confirm: () => confirmations++);
      expect(find.text('Confirming…'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('draft_timeline_confirm')),
            )
            .onPressed,
        isNull,
      );
      expect(confirmations, 1);
    },
  );

  testWidgets(
    'all planned rows are available and small double text can scroll safely',
    (tester) async {
      final preview = _preview()
        ..selectScenario(ZyraDraftTimelineScenario.allEvents);
      await _mount(tester, preview.view, size: const Size(320, 568), scale: 2);
      final types = ZyraDraftTimelinePreview.supportedEvents;
      for (var i = 0; i < types.length; i++) {
        expect(
          find.byKey(ValueKey('draft_timeline_event_${types[i]}_$i')),
          findsOneWidget,
        );
      }
      await tester.ensureVisible(
        find.byKey(ValueKey('draft_timeline_event_nikah_${types.length - 1}')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nikah').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('all8 position states have one current marker and exact road', (
    tester,
  ) async {
    final preview = _preview();
    for (final stage in ZyraJourneyStages.all) {
      preview.selectStage(stage.value);
      await _mount(tester, preview.view, owned: false);
      expect(
        find.byKey(ValueKey('draft_timeline_here_${stage.value}')),
        findsOneWidget,
      );
      for (final next in ZyraJourneyStages.all) {
        expect(
          find.byKey(ValueKey('draft_timeline_ahead_${next.value}')),
          next.order > stage.order ? findsOneWidget : findsNothing,
        );
      }
    }
  });

  test('date formatting preserves supplied calendar components', () {
    expect(
      ZyraDraftTimelinePresentation.dateLabel(DateTime.utc(2026, 8, 8, 23, 30)),
      '08 August 2026',
    );
  });

  testWidgets('optional real-Poppins Timeline visual evidence', (tester) async {
    final preview = _preview();
    for (final scenario in [
      ZyraDraftTimelineScenario.current,
      ZyraDraftTimelineScenario.allEvents,
      ZyraDraftTimelineScenario.meetingToConfirm,
      ZyraDraftTimelineScenario.answersRevealed,
      ZyraDraftTimelineScenario.empty,
    ]) {
      preview.selectScenario(scenario);
      await _mount(
        tester,
        preview.view,
        compatibility: () {},
        confirm: () {},
        notYet: () {},
      );
      await _captureFrame(tester, scenario.name);
    }
    preview.selectScenario(ZyraDraftTimelineScenario.allEvents);
    await _mount(tester, preview.view, size: const Size(320, 568), scale: 2);
    await _captureFrame(tester, 'compact_double_text');
  });
}
