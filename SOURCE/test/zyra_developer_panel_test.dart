import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_journey_stages.dart';
import 'package:zyra/models/zyra_developer_preview.dart';
import 'package:zyra/models/zyra_error_state.dart';
import 'package:zyra/state/zyra_developer_samples.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/widgets/zyra_tap_feedback.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_confirm_sheet.dart';
import 'package:zyra/widgets/zyra_developer_panel.dart';

const _captureDirectory = String.fromEnvironment('ZYRA_LOCK31_CAPTURE_DIR');
const _boundary = ValueKey('lock31_capture_boundary');
const _email =
    'founder'
    '@'
    'example.test';

Finder _key(String name) => find.byKey(ValueKey('dev_$name'));

const _real = ZyraDeveloperPanelValues(
  active: 0,
  ended: 0,
  received: 0,
  sent: 0,
  past: ZyraDeveloperPast.none,
  introductions: 0,
);

Future<void> _mount(
  WidgetTester tester, {
  required int places,
  required ValueNotifier<ZyraDeveloperPanelValues> values,
  required List<String> changes,
  double width = 430,
  double height = 932,
  double scale = 1,
  ZyraDeveloperPreviewActions? previewActions,
  ZyraDeveloperPanelValues? clearValues,
  ValueNotifier<bool>? visibility,
  bool parentFeedback = false,
  ValueChanged<bool Function()>? captureParentGuard,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  Widget launcher(BuildContext context) => SafeArea(
    child: TextButton(
      child: Text('My ZYRA', style: ZyraText.pageTitle()),
      onPressed: () {
        late final ModalBottomSheetRoute<void> route;
        bool current() => route.isCurrent && visibility?.value != false;
        void Function(T) guarded<T>(void Function(T) action) => (value) {
          if (current()) action(value);
        };
        final actions = previewActions;
        route = zyraDeveloperPanelRoute(
          context,
          email: _email,
          planName: places == 1 ? 'Seeker Basic' : 'Seeker One',
          journeyPlaces: places,
          values: values,
          isVisible: () => visibility?.value != false,
          visibilityListenable: visibility,
          previewActions: actions == null
              ? null
              : ZyraDeveloperPreviewActions(
                  onViewAs: guarded(actions.onViewAs),
                  onUnverified: guarded(actions.onUnverified),
                  onSetupUnfinished: guarded(actions.onSetupUnfinished),
                  onJourney: guarded(actions.onJourney),
                  onStage: guarded(actions.onStage),
                  onPreset: guarded(actions.onPreset),
                  onNotice: guarded(actions.onNotice),
                  onError: guarded(actions.onError),
                ),
          onActive: guarded((value) => changes.add('active $value')),
          onEnded: guarded((value) => changes.add('ended $value')),
          onReceived: guarded((value) => changes.add('received $value')),
          onSent: guarded((value) => changes.add('sent $value')),
          onPast: guarded((value) => changes.add('past ${value.name}')),
          onIntroductions: guarded(
            (value) => changes.add('introductions $value'),
          ),
          onClear: () {
            if (!current()) return;
            changes.add('clear');
            values.value = clearValues ?? _real;
          },
        );
        Navigator.of(context).push(route);
      },
    ),
  );

  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(platform: TargetPlatform.iOS),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          ),
          child: child!,
        ),
        home: Scaffold(
          backgroundColor: ZyraColors.ivoryTop,
          body: Builder(
            builder: (context) {
              final parentRoute = ModalRoute.of(context)!;
              bool parentCurrent() => parentRoute.isCurrent;
              captureParentGuard?.call(parentCurrent);
              final button = Builder(builder: launcher);
              return parentFeedback
                  ? ZyraTapFeedback(
                      level: () => ZyraHapticLevel.off,
                      canAct: parentCurrent,
                      child: button,
                    )
                  : button;
            },
          ),
        ),
      ),
    ),
  );
  await _open(tester);
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('My ZYRA'));
  await tester.pumpAndSettle();
  expect(_key('panel'), findsOneWidget);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  try {
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    repaint(boundary);
    await tester.pump();
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '$_captureDirectory/$name.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  } finally {
    debugDisableShadows = previous;
  }
}

const _sampleJourneys = [
  (id: 'sample-sara', name: 'Sara', stage: 'salam_exchange'),
  (id: 'sample-maryam', name: 'Maryam', stage: 'compatibility_reveal'),
  (id: 'sample-noor', name: 'Noor', stage: 'phase_1'),
];

ZyraDeveloperPanelValues _previewValues({
  ZyraDeveloperViewAs? viewAs = ZyraDeveloperViewAs.seekerOne,
  int journeyPlaces = 3,
  String realPlanName = 'Seeker One',
  bool canActivate = true,
  bool setupAvailable = true,
  bool unverified = false,
  bool setupUnfinished = false,
  int active = 3,
  List<({String id, String name, String stage})> journeys = _sampleJourneys,
  String? selectedJourneyId = 'sample-sara',
  ZyraDeveloperPreset? preset,
  int notice = 0,
}) => ZyraDeveloperPanelValues(
  active: active,
  ended: 0,
  received: 0,
  sent: 0,
  past: ZyraDeveloperPast.none,
  introductions: 0,
  preview: ZyraDeveloperPreviewValues(
    viewAs: viewAs,
    realPlanName: realPlanName,
    journeyPlaces: journeyPlaces,
    canActivate: canActivate,
    setupAvailable: setupAvailable,
    unverified: unverified,
    setupUnfinished: setupUnfinished,
    journeys: journeys,
    selectedJourneyId: selectedJourneyId,
    preset: preset,
    notice: notice,
  ),
);

ZyraDeveloperPreviewActions _previewActions(List<String> changes) =>
    ZyraDeveloperPreviewActions(
      onViewAs: (view) => changes.add('view ${view.name}'),
      onUnverified: (value) => changes.add('unverified $value'),
      onSetupUnfinished: (value) => changes.add('setup $value'),
      onJourney: (id) => changes.add('journey $id'),
      onStage: (stage) => changes.add('stage $stage'),
      onPreset: (preset) => changes.add('preset ${preset.name}'),
      onNotice: (notice) => changes.add('notice $notice'),
      onError: (kind) => changes.add('error ${kind.name}'),
    );

Future<void> _tapControl(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

bool _buttonEnabled(WidgetTester tester, String key) =>
    tester.widget<TextButton>(_key(key)).onPressed != null;

// WidgetTester checks active handles before package:test teardown callbacks.
// Release at the end of the widget body, with an idempotent teardown fallback.
VoidCallback _semanticsLease(WidgetTester tester) {
  final handle = tester.ensureSemantics();
  var disposed = false;
  void dispose() {
    if (disposed) return;
    disposed = true;
    handle.dispose();
  }

  addTearDown(dispose);
  return dispose;
}

bool _selected(WidgetTester tester, String label) =>
    tester
        .getSemantics(find.bySemanticsLabel(label))
        .flagsCollection
        .isSelected ==
    ui.Tristate.isTrue;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('ZYRALock31Poppins');
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'SemiBold']) {
      loader.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await loader.load();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'ZYRALock31Poppins';
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  testWidgets('Basic uses the real plan, caps Active and resets in place', (
    tester,
  ) async {
    final values = ValueNotifier(_real);
    addTearDown(values.dispose);
    final changes = <String>[];
    await _mount(tester, places: 1, values: values, changes: changes);
    expect(find.textContaining('$_email · Seeker Basic'), findsOneWidget);
    expect(find.text('Seeker Basic has 1 place'), findsOneWidget);
    expect(tester.widget<TextButton>(_key('active_2')).onPressed, isNull);
    expect(tester.widget<TextButton>(_key('active_3')).onPressed, isNull);
    final semantics = tester.ensureSemantics();
    try {
      await tester.pump();
      expect(find.bySemanticsLabel('Active Journeys 0'), findsOneWidget);
      expect(find.bySemanticsLabel('Active Journeys 3'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
    for (final key in [
      'active_1',
      'ended_3',
      'received_1',
      'sent_3',
      'past_2',
      'introductions_2',
    ]) {
      await tester.tap(_key(key));
      await tester.pump();
    }
    expect(changes, [
      'active 1',
      'ended 3',
      'received 1',
      'sent 3',
      'past samePerson',
      'introductions 2',
    ]);
    values.value = const ZyraDeveloperPanelValues(
      active: 1,
      ended: 3,
      received: 1,
      sent: 3,
      past: ZyraDeveloperPast.samePerson,
      introductions: 2,
    );
    await tester.pumpAndSettle();
    await _capture(tester, 'lock31_developer_basic');
    await tester.tap(_key('clear'));
    await tester.pump();
    expect(changes.last, 'clear');
    expect(values.value, _real);
    expect(find.text('Sample data cleared.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.text('Sample data cleared.'), findsNothing);
    await tester.tap(_key('done'));
    await tester.pumpAndSettle();
    expect(_key('panel'), findsNothing);
  });

  testWidgets('One permits 3 and closes by backdrop or swipe', (tester) async {
    final values = ValueNotifier(_real);
    addTearDown(values.dispose);
    final changes = <String>[];
    await _mount(tester, places: 3, values: values, changes: changes);
    expect(find.text('Seeker One has 3 places'), findsOneWidget);
    await tester.tap(_key('active_3'));
    await tester.pumpAndSettle();
    expect(changes, ['active 3']);
    await _capture(tester, 'lock31_developer_one');
    await tester.tapAt(const Offset(215, 90));
    await tester.pumpAndSettle();
    expect(_key('panel'), findsNothing);
    await _open(tester);
    await tester.drag(find.text('Developer'), const Offset(0, 420));
    await tester.pumpAndSettle();
    expect(_key('panel'), findsNothing);
  });

  testWidgets(
    'large text fits a compact phone and the last control is reachable',
    (tester) async {
      final values = ValueNotifier(_real);
      addTearDown(values.dispose);
      await _mount(
        tester,
        places: 1,
        values: values,
        changes: [],
        width: 320,
        scale: 2,
      );
      expect(
        tester.getSize(_key('panel')).height,
        lessThanOrEqualTo(932 * .88),
      );
      await tester.ensureVisible(_key('done'));
      await tester.pumpAndSettle();
      expect(_key('done').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(ZyraIvorySheetHandle),
        const Offset(0, 520),
      );
      await tester.pumpAndSettle();
      expect(_key('panel'), findsNothing);
    },
  );
  testWidgets(
    'V2 switches and notices follow provider state and Clear stays open',
    (tester) async {
      final real = _previewValues(
        active: 0,
        journeys: const [],
        selectedJourneyId: null,
      );
      final values = ValueNotifier(_previewValues());
      addTearDown(values.dispose);
      final changes = <String>[];
      final disposeSemantics = _semanticsLease(tester);
      try {
        await _mount(
          tester,
          places: 3,
          values: values,
          changes: changes,
          previewActions: _previewActions(changes),
          clearValues: real,
        );
        expect(find.text('Start sign-up'), findsOneWidget);
        expect(_buttonEnabled(tester, 'start_signup'), isFalse);
        await _tapControl(tester, 'unverified');
        expect(changes.last, 'unverified true');
        values.value = _previewValues(unverified: true);
        await tester.pumpAndSettle();
        expect(tester.widget<Switch>(_key('unverified')).value, isTrue);
        await _tapControl(tester, 'setup_unfinished');
        expect(changes.last, 'setup true');
        values.value = _previewValues(unverified: true, setupUnfinished: true);
        await tester.pumpAndSettle();
        expect(tester.widget<Switch>(_key('setup_unfinished')).value, isTrue);
        await _tapControl(tester, 'preset_1');
        expect(changes.last, 'preset typicalDay');
        for (var notice = 0; notice <= 6; notice++) {
          await _tapControl(tester, 'notice_$notice');
          expect(changes.last, 'notice $notice');
          values.value = _previewValues(
            unverified: true,
            setupUnfinished: true,
            preset: ZyraDeveloperPreset.typicalDay,
            notice: notice,
          );
          await tester.pumpAndSettle();
          final label = notice == 0
              ? 'None'
              : notice == 6
              ? 'Welcome back'
              : 'Email $notice';
          expect(_selected(tester, '2-year inactivity $label'), isTrue);
        }
        for (final kind in const [
          ZyraErrorKind.offline,
          ZyraErrorKind.serviceUnavailable,
          ZyraErrorKind.sessionExpired,
        ]) {
          await _tapControl(tester, 'error_${kind.name}');
          expect(changes.last, 'error ${kind.name}');
        }
        await _tapControl(tester, 'clear');
        expect(changes.last, 'clear');
        expect(values.value, same(real));
        expect(_key('panel'), findsOneWidget);
        expect(find.text('Sample data cleared.'), findsOneWidget);
        expect(tester.widget<Switch>(_key('unverified')).value, isFalse);
        expect(tester.widget<Switch>(_key('setup_unfinished')).value, isFalse);
        await tester.ensureVisible(_key('notice_0'));
        await tester.pumpAndSettle();
        expect(_selected(tester, '2-year inactivity None'), isTrue);
        await tester.ensureVisible(_key('view_as_0'));
        await tester.pumpAndSettle();
        expect(_selected(tester, 'View as Seeker One'), isTrue);
        await tester.pump(const Duration(milliseconds: 1700));
        await _tapControl(tester, 'done');
        expect(_key('panel'), findsNothing);
      } finally {
        disposeSemantics();
      }
    },
  );

  testWidgets(
    'V2 View as covers four plans and keeps Guardian Seeker capacity',
    (tester) async {
      final values = ValueNotifier(_previewValues());
      addTearDown(values.dispose);
      final changes = <String>[];
      final disposeSemantics = _semanticsLease(tester);
      try {
        await _mount(
          tester,
          places: 3,
          values: values,
          changes: changes,
          previewActions: _previewActions(changes),
        );
        for (final sample in const [
          (view: ZyraDeveloperViewAs.seekerOne, places: 3),
          (view: ZyraDeveloperViewAs.guardianOne, places: 3),
          (view: ZyraDeveloperViewAs.guardianBasic, places: 3),
          (view: ZyraDeveloperViewAs.seekerBasic, places: 1),
        ]) {
          await _tapControl(tester, 'view_as_${sample.view.index}');
          expect(changes.last, 'view ${sample.view.name}');
          values.value = _previewValues(
            viewAs: sample.view,
            journeyPlaces: sample.places,
            active: sample.places,
            journeys: sample.places == 1
                ? [_sampleJourneys.first]
                : _sampleJourneys,
          );
          await tester.pumpAndSettle();
          expect(_selected(tester, 'View as ${sample.view.label}'), isTrue);
          expect(
            find.textContaining(
              'Viewing as ${sample.view.label} · real plan Seeker One',
            ),
            findsOneWidget,
          );
          expect(_buttonEnabled(tester, 'active_1'), isTrue);
          expect(_buttonEnabled(tester, 'active_2'), sample.places == 3);
          expect(_buttonEnabled(tester, 'active_3'), sample.places == 3);
          expect(
            find.text(
              sample.places == 1
                  ? 'Seeker Basic has 1 place'
                  : 'Seeker One has 3 places',
            ),
            findsOneWidget,
          );
        }
        await _tapControl(tester, 'active_1');
        expect(changes.last, 'active 1');
      } finally {
        disposeSemantics();
      }
    },
  );

  testWidgets('V2 Journey selection maps every canonical stage to its value', (
    tester,
  ) async {
    final values = ValueNotifier(_previewValues());
    addTearDown(values.dispose);
    final changes = <String>[];
    final disposeSemantics = _semanticsLease(tester);
    try {
      await _mount(
        tester,
        places: 3,
        values: values,
        changes: changes,
        previewActions: _previewActions(changes),
      );
      await _tapControl(tester, 'journey_1');
      expect(changes.last, 'journey sample-maryam');
      values.value = _previewValues(selectedJourneyId: 'sample-maryam');
      await tester.pumpAndSettle();
      expect(_selected(tester, 'Open Journey Maryam'), isTrue);
      expect(_selected(tester, 'Open Journey Sara'), isFalse);
      for (
        var index = 0;
        index < ZyraJourneyStages.previewAll.length;
        index++
      ) {
        final stage = ZyraJourneyStages.previewAll[index];
        await _tapControl(tester, 'stage_$index');
        expect(changes.last, 'stage ${stage.value}');
        values.value = _previewValues(
          selectedJourneyId: 'sample-maryam',
          journeys: [
            _sampleJourneys[0],
            (id: 'sample-maryam', name: 'Maryam', stage: stage.value),
            _sampleJourneys[2],
          ],
        );
        await tester.pumpAndSettle();
        expect(_selected(tester, 'Stage ${stage.label}'), isTrue);
      }
      final lastStage = ZyraJourneyStages.previewAll.last;
      await _tapControl(
        tester,
        'stage_${ZyraJourneyStages.previewAll.length - 1}',
      );
      expect(changes.sublist(changes.length - 2), [
        'stage ${lastStage.value}',
        'stage ${lastStage.value}',
      ]);
      await _tapControl(tester, 'journey_2');
      expect(changes.last, 'journey sample-noor');
      await _tapControl(tester, 'journey_0');
      expect(changes.last, 'journey sample-sara');
    } finally {
      disposeSemantics();
    }
  });

  testWidgets(
    'V2 no real membership starts and clears to honest Seeker One sample view',
    (tester) async {
      final start = _previewValues(
        realPlanName: 'none',
        setupAvailable: false,
        active: 0,
        journeys: const [],
        selectedJourneyId: null,
      );
      final values = ValueNotifier(start);
      addTearDown(values.dispose);
      final changes = <String>[];
      final disposeSemantics = _semanticsLease(tester);
      try {
        await _mount(
          tester,
          places: 3,
          values: values,
          changes: changes,
          previewActions: _previewActions(changes),
          clearValues: start,
        );
        expect(
          find.textContaining('Viewing as Seeker One · real plan: none'),
          findsOneWidget,
        );
        expect(_selected(tester, 'View as Seeker One'), isTrue);
        expect(_buttonEnabled(tester, 'active_3'), isTrue);
        expect(tester.widget<Switch>(_key('unverified')).onChanged, isNotNull);
        expect(
          tester.widget<Switch>(_key('setup_unfinished')).onChanged,
          isNotNull,
        );
        expect(find.text('Seeker One has 3 places'), findsOneWidget);
        await _tapControl(tester, 'view_as_3');
        expect(changes.last, 'view guardianBasic');
        values.value = _previewValues(
          viewAs: ZyraDeveloperViewAs.guardianBasic,
          realPlanName: 'none',
          setupAvailable: false,
          active: 0,
          journeys: const [],
          selectedJourneyId: null,
        );
        await tester.pumpAndSettle();
        expect(find.text('NOTICES'), findsNothing);
        await _tapControl(tester, 'clear');
        expect(values.value, same(start));
        expect(_key('panel'), findsOneWidget);
        expect(
          find.textContaining('Viewing as Seeker One · real plan: none'),
          findsOneWidget,
        );
        await tester.ensureVisible(_key('view_as_0'));
        await tester.pumpAndSettle();
        expect(_selected(tester, 'View as Seeker One'), isTrue);
        expect(_buttonEnabled(tester, 'active_3'), isTrue);
        expect(find.text('NOTICES'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 1700));
      } finally {
        disposeSemantics();
      }
    },
  );

  testWidgets('V2 setup switches and presets work without a signup callback', (
    tester,
  ) async {
    final values = ValueNotifier(_previewValues(setupAvailable: false));
    addTearDown(values.dispose);
    final changes = <String>[];
    await _mount(
      tester,
      places: 3,
      values: values,
      changes: changes,
      previewActions: _previewActions(changes),
    );
    expect(
      tester.widget<Switch>(_key('setup_unfinished')).onChanged,
      isNotNull,
    );
    expect(tester.widget<Switch>(_key('unverified')).onChanged, isNotNull);
    for (final preset in ZyraDeveloperPreset.values) {
      expect(_buttonEnabled(tester, 'preset_${preset.index}'), isTrue);
      await _tapControl(tester, 'preset_${preset.index}');
      expect(changes.last, 'preset ${preset.name}');
    }
    await _tapControl(tester, 'setup_unfinished');
    expect(changes.last, 'setup true');
    values.value = _previewValues(
      setupAvailable: false,
      setupUnfinished: true,
      preset: ZyraDeveloperPreset.everything,
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(_key('setup_unfinished')).value, isTrue);
    expect(_buttonEnabled(tester, 'preset_3'), isTrue);
    expect(find.text('Start sign-up'), findsOneWidget);
    expect(_buttonEnabled(tester, 'start_signup'), isFalse);
    expect(find.text('Continue setting up'), findsNothing);
  });

  testWidgets(
    'V2 Guardian views hide the whole notice section and Seeker restores it',
    (tester) async {
      final values = ValueNotifier(_previewValues(notice: 4));
      addTearDown(values.dispose);
      final changes = <String>[];
      await _mount(
        tester,
        places: 3,
        values: values,
        changes: changes,
        previewActions: _previewActions(changes),
      );
      expect(find.text('NOTICES'), findsOneWidget);
      for (var notice = 0; notice <= 6; notice++) {
        expect(_key('notice_$notice'), findsOneWidget);
      }
      for (final view in const [
        ZyraDeveloperViewAs.guardianOne,
        ZyraDeveloperViewAs.guardianBasic,
      ]) {
        await _tapControl(tester, 'view_as_${view.index}');
        expect(changes.last, 'view ${view.name}');
        values.value = _previewValues(viewAs: view, notice: 4);
        await tester.pumpAndSettle();
        expect(find.text('NOTICES'), findsNothing);
        expect(find.text('2-year inactivity'), findsNothing);
        for (var notice = 0; notice <= 6; notice++) {
          expect(_key('notice_$notice'), findsNothing);
        }
        expect(_buttonEnabled(tester, 'error_offline'), isTrue);
      }
      await _tapControl(tester, 'view_as_0');
      values.value = _previewValues();
      await tester.pumpAndSettle();
      expect(find.text('NOTICES'), findsOneWidget);
      for (var notice = 0; notice <= 6; notice++) {
        expect(_buttonEnabled(tester, 'notice_$notice'), isTrue);
      }
      await _tapControl(tester, 'notice_6');
      expect(changes.last, 'notice 6');
    },
  );

  testWidgets(
    'V2 sheet feedback survives a covered parent and withdraws stale taps',
    (tester) async {
      final values = ValueNotifier(_previewValues());
      addTearDown(values.dispose);
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);
      final changes = <String>[];
      bool Function()? parentCurrent;
      await _mount(
        tester,
        places: 3,
        values: values,
        changes: changes,
        previewActions: _previewActions(changes),
        visibility: visible,
        parentFeedback: true,
        captureParentGuard: (guard) => parentCurrent = guard,
      );
      expect(parentCurrent, isNotNull);
      expect(parentCurrent!(), isFalse);
      await _tapControl(tester, 'view_as_3');
      expect(changes, ['view guardianBasic']);
      final retained = tester.widget<TextButton>(_key('view_as_0')).onPressed!;
      visible.value = false;
      await tester.pumpAndSettle();
      expect(_key('panel'), findsNothing);
      retained();
      await tester.pumpAndSettle();
      expect(changes, ['view guardianBasic']);
    },
  );

  for (final size in const [Size(320, 568), Size(430, 932)]) {
    testWidgets(
      'V2 2x text scrolls every control at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        final values = ValueNotifier(_previewValues());
        addTearDown(values.dispose);
        await _mount(
          tester,
          places: 3,
          values: values,
          changes: [],
          previewActions: _previewActions([]),
          width: size.width,
          height: size.height,
          scale: 2,
        );
        expect(
          tester.getSize(_key('panel')).height,
          lessThanOrEqualTo(size.height * .88),
        );
        expect(tester.takeException(), isNull);
        final suffix = '${size.width.toInt()}x${size.height.toInt()}_2x';
        await _capture(tester, 'lock31_v2_${suffix}_top');
        for (final key in [
          'view_as_3',
          'unverified',
          'setup_unfinished',
          'active_3',
          'journey_2',
          'stage_${ZyraJourneyStages.previewAll.length - 1}',
          'ended_3',
          'received_3',
          'sent_3',
          'past_2',
          'introductions_3',
          'preset_3',
          'notice_6',
          'error_sessionExpired',
          'clear',
          'done',
        ]) {
          await tester.ensureVisible(_key(key));
          await tester.pumpAndSettle();
          expect(_key(key).hitTestable(), findsOneWidget, reason: key);
          expect(tester.takeException(), isNull, reason: key);
        }
        await _capture(tester, 'lock31_v2_${suffix}_bottom');
        await _tapControl(tester, 'done');
        expect(_key('panel'), findsNothing);
      },
    );
  }
}
