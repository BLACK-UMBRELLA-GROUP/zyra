import 'package:zyra/theme/zyra_app_gold_style.dart';
// Real-shell, offline coverage of LOCK 13 V3 Journey places and Options.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_card_content.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/dev/zyra_one_journey_options_page.dart';
import 'package:zyra/dev/zyra_one_journey_tab.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _font = 'PoppinsJourneyCardChoices';
const _people = ['draft-sara', 'draft-aisha', 'draft-maryam'];

Finder _key(String key) => find.byKey(ValueKey(key));
Finder get _picker => _key('concept_journey_card_layout');

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Journey layout choices must remain offline.');
  }
}

ZyraPreviewNavigationCheckpoint _seed({
  bool guardian = false,
  int tab = 1,
  int count = 3,
  List<String> pages = const [],
  bool continued = false,
}) {
  final model = ViewRequestDraftModel(capacity: 3);
  expect(model.seedJourneys(count), isTrue);
  if (continued) expect(model.sendSalam('draft-sara'), isTrue);
  return ZyraPreviewNavigationCheckpoint(
    guardian: guardian,
    model: model.snapshot(),
    tab: tab,
    pages: pages,
  );
}

class _Owner {
  bool allowed = true;
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];

  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;

  Future<void> mount(
    WidgetTester tester, {
    ZyraPreviewNavigationCheckpoint? checkpoint,
    bool guardian = false,
    double scale = 1,
    Size size = const Size(393, 852),
  }) async {
    final ready = Completer<void>();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: ZyraOneJourneyConceptShell(
          fixture: ZyraShellTestFixture().fixture,
          key: UniqueKey(),
          canAct: () => allowed,
          onExit: () => fail('Layout choice testing must not exit the app.'),
          initialGuardianRole: guardian,
          initialCheckpoint: checkpoint,
          onCheckpoint: checkpoints.add,
          onPresentationReady: () {
            if (!ready.isCompleted) ready.complete();
          },
        ),
      ),
    );
    // Use the same real offline deck preparation as the shipped shell.
    for (var frame = 0; frame < 100 && !ready.isCompleted; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(ready.isCompleted, isTrue, reason: 'Bundled photo frames prepare');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(checkpoints, isNotEmpty);
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  if (await pressZyraDevControlKey(tester, key)) return;
  final target = _key(key);
  expect(target, findsOneWidget, reason: 'Actual shell action $key');
  if (find
      .ancestor(of: target, matching: find.byType(Scrollable))
      .evaluate()
      .isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, int index) async {
  await expandZyraPreviewTabBarIfIdle(tester);
  expect(find.byType(ZyraShellNavigation), findsOneWidget);
  await tester.tapAt(tester.getCenter(_key('floating-nav-item-$index')));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _chooseSample(WidgetTester tester, int count) async {
  await openZyraDevControls(tester);
  expect(find.text('Page options'), findsNothing);
  await _tap(tester, 'concept_journey_preview_$count');
  await closeZyraDevControls(tester);
  _expectRetiredChoices();
}

void _expectRetiredChoices() {
  expect(_picker, findsNothing);
  expect(
    find.byType(DropdownButtonFormField<ZyraOneJourneyCardDesign>),
    findsNothing,
  );
  expect(find.text('Journey cards'), findsNothing);
  for (final name in [
    'quietMinimal',
    'largerPortrait',
    'portraitSplit',
    'roundedPortrait',
    'identityHeader',
    'editorial',
  ]) {
    expect(_key('concept_journey_card_choice_$name'), findsNothing);
  }
}

ZyraOneJourneyTab _places(WidgetTester tester) =>
    tester.widget(find.byType(ZyraOneJourneyTab));

ZyraConceptJourneyOptions _options(WidgetTester tester) =>
    tester.widget(find.byType(ZyraConceptJourneyOptions));

void _expectPlace(WidgetTester tester, String id) {
  final places = _places(tester);
  expect(places.journeys[places.index].id, id);
  expect(_key('draft_journey_options_$id'), findsOneWidget);
  expect(_key('journey_tab_continue').hitTestable(), findsOneWidget);
  for (final other in _people.where((person) => person != id)) {
    expect(_key('draft_journey_options_$other'), findsNothing);
  }
}

Future<void> _expectOptionsReachable(
  WidgetTester tester,
  String id, {
  required bool reading,
}) async {
  await _tap(tester, 'draft_journey_options_$id');
  expect(find.byType(ZyraOneJourneyOptionsPage), findsOneWidget);
  expect(_options(tester).id, id);
  final scroll = _key('journey_options_scroll_$id');
  expect(scroll, reading ? findsOneWidget : findsNothing);
  for (final option in ZyraConceptJourneyOption.values) {
    final row = _key('draft_options_${option.name}_$id');
    expect(row, findsOneWidget);
    if (reading) {
      await Scrollable.ensureVisible(tester.element(row), alignment: .5);
      await tester.pumpAndSettle();
    }
    expect(row.hitTestable(), findsOneWidget);
    for (final text in tester.renderObjectList<RenderParagraph>(
      find.descendant(of: row, matching: find.byType(Text)),
    )) {
      expect(text.didExceedMaxLines, isFalse);
    }
  }
  await returnZyraPreviewPage(tester);
  _expectPlace(tester, id);
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
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
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
    final gold = ZyraAppGoldStyle.instance;
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

  test('only selected Portrait split remains', () {
    expect(ZyraOneJourneyCardDesign.values, [
      ZyraOneJourneyCardDesign.portraitSplit,
    ]);
  });

  // QUESTIONS Q19: Back from pushed Options restores the addressed place.
  for (final count in [1, 2, 3]) {
    testWidgets(
      'pushed Options return to the same place with $count Journeys',
      (tester) async {
        final owner = _Owner();
        await owner.mount(tester, checkpoint: _seed(count: count));
        expect(_places(tester).capacity, 3);
        expect(
          _places(tester).journeys.map((person) => person.id),
          _people.take(count),
        );
        for (var index = 0; index < count; index++) {
          final id = _people[index];
          _expectPlace(tester, id);
          await _tap(tester, 'draft_journey_options_$id');
          expect(owner.latest.pages, ['journey_options']);
          expect(owner.latest.personId, id);
          expect(_options(tester).id, id);
          final before = owner.latest.model;
          await returnZyraPreviewPage(tester);
          expect(owner.latest.pages, isEmpty);
          expect(owner.latest.journeyPlaceIndex, index);
          expect(owner.latest.model.states, before.states);
          expect(owner.latest.model.progress, before.progress);
          _expectPlace(tester, id);
          if (index + 1 < count) {
            await _tap(tester, 'journey_tab_next');
          }
        }
      },
    );
  }

  // QUESTIONS Q19: each current Options row remains reachable when scrolled.
  for (final viewport in [
    (size: const Size(320, 852), scale: 2.0, reading: true),
    (size: const Size(393, 852), scale: 1.0, reading: true),
    (size: const Size(430, 932), scale: 1.0, reading: false),
  ]) {
    testWidgets(
      'pushed Options remain reachable at ${viewport.size}, ${viewport.scale}x',
      (tester) async {
        final owner = _Owner();
        await owner.mount(
          tester,
          checkpoint: _seed(),
          size: viewport.size,
          scale: viewport.scale,
        );
        await _expectOptionsReachable(
          tester,
          'draft-sara',
          reading: viewport.reading,
        );
        expect(owner.latest.pages, isEmpty);
      },
    );
  }

  // QUESTIONS Q19: Continue preserves progress and its Options parent.
  testWidgets('pushed Options Continue preserves actual progress', (
    tester,
  ) async {
    final owner = _Owner();
    await owner.mount(tester, checkpoint: _seed(continued: true));
    final before = owner.latest.model;
    await _tap(tester, 'draft_journey_options_draft-sara');
    expect(find.text('Continue Journey'), findsOneWidget);
    expect(find.text('Start Journey'), findsNothing);
    await _tap(tester, 'draft_journey_draft-sara');
    expect(owner.latest.personId, 'draft-sara');
    expect(owner.latest.pages, ['journey_options', 'journey']);
    expect(owner.latest.model.progress, before.progress);
    await returnZyraPreviewPage(tester);
    expect(owner.latest.pages, ['journey_options']);
    await returnZyraPreviewPage(tester);
    _expectPlace(tester, 'draft-sara');
  });

  // QUESTIONS Q19: return, remount and Reset all use the current reader.
  testWidgets(
    'warm return, fresh owner and Reset use the selected place reader',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      await _tap(tester, 'journey_tab_next');
      await _nav(tester, 0);
      await _nav(tester, 1);
      _expectPlace(tester, 'draft-aisha');
      final saved = owner.latest;
      final resumed = _Owner();
      await resumed.mount(tester, checkpoint: saved);
      _expectPlace(tester, 'draft-aisha');
      expect(resumed.latest.model.states, saved.model.states);
      final fresh = _Owner();
      await fresh.mount(tester);
      await _nav(tester, 1);
      await _chooseSample(tester, 3);
      _expectPlace(tester, 'draft-sara');
      await openZyraDevControls(tester);
      await _tap(tester, 'draft_reset');
      await closeZyraDevControls(tester);
      await _nav(tester, 1);
      await _chooseSample(tester, 3);
      _expectPlace(tester, 'draft-sara');
    },
  );

  testWidgets(
    'retired layout choices are absent from every role and page options context',
    (tester) async {
      for (final guardian in [false, true]) {
        for (var tab = 0; tab < (guardian ? 4 : 5); tab++) {
          final owner = _Owner();
          await owner.mount(
            tester,
            guardian: guardian,
            checkpoint: _seed(guardian: guardian, tab: tab),
          );
          await openZyraDevControls(tester);
          expect(find.text('Page options'), findsNothing);
          _expectRetiredChoices();
          for (final count in [1, 2, 3]) {
            expect(_key('concept_journey_preview_$count'), findsNothing);
          }
        }
      }
      final owner = _Owner();
      await owner.mount(
        tester,
        checkpoint: _seed(tab: 2, pages: const ['requests']),
      );
      await openZyraDevControls(tester);
      expect(find.text('Page options'), findsNothing);
      _expectRetiredChoices();
    },
  );

  // QUESTIONS Q19: Back expires the old Options lease, even when reopened.
  testWidgets('dismissed Options cannot navigate after reopening', (
    tester,
  ) async {
    final owner = _Owner();
    await owner.mount(tester, checkpoint: _seed());
    await _tap(tester, 'draft_journey_options_draft-sara');
    final stale = _options(tester).onSelected;
    await returnZyraPreviewPage(tester);
    await _tap(tester, 'draft_journey_options_draft-sara');
    final before = owner.checkpoints.length;
    stale(ZyraConceptJourneyOption.profile);
    await tester.pumpAndSettle();
    expect(owner.latest.pages, ['journey_options']);
    expect(owner.checkpoints.length, before);
    expect(find.byType(ZyraOneJourneyOptionsPage), findsOneWidget);
  });

  // QUESTIONS Q19: selected-place actions cannot cross an authorized role switch.
  testWidgets(
    'retained primary and menu actions are rejected after role switch',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      final place = _places(tester);
      await openZyraDevControls(tester);
      await _tap(tester, 'draft_role_guardian');
      final before = owner.checkpoints.length;
      place.onContinue();
      place.onOptions();
      await tester.pumpAndSettle();
      expect(owner.latest.guardian, isTrue);
      expect(owner.latest.pages, isEmpty);
      expect(owner.checkpoints.length, before);
      expect(find.byType(ZyraOneJourneyTab), findsNothing);
    },
  );

  // QUESTIONS Q19: a withdrawn owner cannot navigate or publish a checkpoint.
  testWidgets(
    'denied owner cannot use retained place or pushed Options actions',
    (tester) async {
      final owner = _Owner();
      await owner.mount(tester, checkpoint: _seed());
      final place = _places(tester);
      await _tap(tester, 'draft_journey_options_draft-sara');
      final options = _options(tester).onSelected;
      final before = owner.checkpoints.length;
      final pages = owner.latest.pages;
      owner.allowed = false;
      place.onContinue();
      place.onOptions();
      options(ZyraConceptJourneyOption.end);
      await tester.pumpAndSettle();
      expect(owner.latest.pages, pages);
      expect(owner.checkpoints.length, before);
      expect(tester.takeException(), isNull);
    },
  );
}
