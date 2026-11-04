import 'package:zyra/theme/zyra_app_gold_style.dart';
// LOCK 13 V3, JOURNEY_TAB/MASTERS/j01–j07,j10–j12 replaces the old
// three-slot presentation with one swipe card per place and a pushed options
// page. Capacity, local model facts and retained owner guards remain unchanged.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_tab.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/dev/zyra_one_journey_options_page.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _font = 'PoppinsJourneyCapacitySlots';
const _captureDirectory = String.fromEnvironment(
  'ZYRA_CAPACITY_SLOTS_CAPTURE_DIR',
);
const _boundary = ValueKey('journey-capacity-slots-review');
const _sara = 'draft-sara';

Finder _key(String value) => find.byKey(ValueKey(value));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Journey capacity fixtures must remain offline.');
  }
}

class _Owner {
  bool allowed = true;
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];
  final navigator = GlobalKey<NavigatorState>();

  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;

  Future<void> mount(
    WidgetTester tester, {
    required ViewRequestDraftModel model,
    bool basic = false,
    Size size = const Size(393, 852),
    double scale = 1,
  }) async {
    if (find.byType(ZyraOneJourneyConceptShell).evaluate().isNotEmpty) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final ready = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        navigatorKey: navigator,
        navigatorObservers: [ZyraPreviewRouteObserver()],
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
        home: RepaintBoundary(
          key: _boundary,
          child: ZyraOneJourneyConceptShell(
            fixture: ZyraShellTestFixture().fixture,
            key: UniqueKey(),
            canAct: () => allowed,
            onExit: () => fail('Capacity slots never leave their owner.'),
            initialCheckpoint: ZyraPreviewNavigationCheckpoint(
              guardian: false,
              model: model.snapshot(),
              tab: 1,
              pages: const [],
              seekerMembership: basic ? 'Seeker Basic' : 'Seeker One',
            ),
            onCheckpoint: checkpoints.add,
            onPresentationReady: () {
              if (!ready.isCompleted) ready.complete();
            },
          ),
        ),
      ),
    );
    for (var frame = 0; frame < 100 && !ready.isCompleted; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(ready.isCompleted, isTrue);
    await tester.pumpAndSettle();
    expect(checkpoints, isNotEmpty);
    expect(tester.takeException(), isNull);
  }
}

ZyraOneJourneyTab _reader(WidgetTester tester) =>
    tester.widget<ZyraOneJourneyTab>(find.byType(ZyraOneJourneyTab));

VoidCallback _upgrade(WidgetTester tester) =>
    tester.widget<InkWell>(_key('journey_tab_plans')).onTap!;

void _expectReadableText(WidgetTester tester, Finder owner) {
  for (final element
      in find.descendant(of: owner, matching: find.byType(Text)).evaluate()) {
    final text = element.widget as Text;
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    final paragraph = element.findRenderObject();
    if (paragraph is RenderParagraph) {
      expect(paragraph.didExceedMaxLines, isFalse);
    }
  }
}

void _expectModelUnchanged(
  ViewRequestDraftSnapshot before,
  ViewRequestDraftSnapshot after,
) {
  expect(after.states, before.states);
  expect(after.capacity, before.capacity);
  expect(after.hiddenPeers, before.hiddenPeers);
  expect(after.blockedPeers, before.blockedPeers);
  expect(after.progress, before.progress);
  expect(after.journeyStartedAt, before.journeyStartedAt);
  expect(after.endedAttempts, before.endedAttempts);
  expect(after.currentEndedAttemptIds, before.currentEndedAttemptIds);
  expect(after.guardianAccess, before.guardianAccess);
  expect(after.requiredPaidGuardianAccess, before.requiredPaidGuardianAccess);
}

Future<void> _press(WidgetTester tester, String key) async {
  if (await pressZyraDevControlKey(tester, key)) return;
  final target = _key(key);
  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  for (final element in find.byType(Image).evaluate()) {
    await tester.runAsync(
      () => precacheImage((element.widget as Image).image, element),
    );
  }
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 1));
  final bytes = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.png),
  );
  image!.dispose();
  expect(bytes, isNotNull);
  await tester.runAsync(() async {
    final file = File('$_captureDirectory/$name.png');
    await file.parent.create(recursive: true);
    expect(await file.exists(), isFalse);
    await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;
  late bool previousFontStubs;
  late String? previousReading;
  late ZyraHapticLevel previousHaptics;

  setUpAll(() async {
    final reading = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });
  setUp(() {
    previousFontStubs = ZyraText.useTestFontStubs;
    previousReading = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    AppState.instance.resetForAccountChange();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraAppGoldStyle.instance.select(
      false,
      expectedGeneration: ZyraAccountState.generation,
      expectedRevision: ZyraAppGoldStyle.instance.revision,
    );
    previousHaptics = ZyraInteractionStyle.hapticLevel;
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.off);
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousNetwork;
    ZyraText.useTestFontStubs = previousFontStubs;
    ZyraText.testReadingFontFamily = previousReading;
    ZyraInteractionStyle.selectHapticLevel(previousHaptics);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'one, two and three Journeys keep identical full-height place cards',
    (tester) async {
      double? referenceHeight;
      for (final count in [3, 1, 2]) {
        final model = ViewRequestDraftModel(capacity: 3);
        expect(model.seedJourneys(count), isTrue);
        final before = model.snapshot();
        final owner = _Owner();
        await owner.mount(tester, model: model);
        expect(_reader(tester).journeys, hasLength(count));
        expect(_reader(tester).capacity, 3);
        final ids = _reader(tester).journeys.map((card) => card.id).toList();
        final firstHeight = tester.getSize(_key('journey_tab_card')).height;
        referenceHeight ??= firstHeight;
        expect(firstHeight, closeTo(referenceHeight, 1));
        for (var index = 0; index < 3; index++) {
          await _press(tester, 'journey_tab_dot_target_$index');
          expect(_reader(tester).index, index);
          expect(
            tester.getSize(_key('journey_tab_card')).height,
            closeTo(firstHeight, 1),
          );
          if (index < count) {
            expect(_key('journey_tab_person_${ids[index]}'), findsOneWidget);
            expect(find.text('Free place'), findsNothing);
          } else {
            expect(find.text('Free place'), findsOneWidget);
            expect(_key('journey_tab_browse'), findsOneWidget);
            expect(_key('draft_journey_options_$_sara'), findsNothing);
          }
          _expectModelUnchanged(before, owner.latest.model);
        }
        expect(find.text('More Journeys come with Seeker One'), findsNothing);
        await _capture(tester, 'one-$count-journeys-three-places');
      }
    },
  );

  testWidgets(
    'zero One Journeys has an honest empty state and Browse creates no Journey',
    (tester) async {
      final model = ViewRequestDraftModel(capacity: 3);
      final before = model.snapshot();
      final owner = _Owner();
      await owner.mount(tester, model: model);
      expect(_reader(tester).journeys, isEmpty);
      expect(_reader(tester).capacity, 3);
      expect(_key('journey_tab_empty_title'), findsOneWidget);
      expect(find.text('No Journey yet'), findsOneWidget);
      expect(find.textContaining('You have 3 places.'), findsOneWidget);
      expect(_key('journey_tab_card'), findsNothing);
      expect(_key('journey_tab_dot_target_0'), findsNothing);
      expect(_key('journey_tab_continue'), findsNothing);
      expect(_key('journey_tab_plans'), findsNothing);
      await _capture(tester, 'empty-journeys');
      await _press(tester, 'journey_tab_browse');
      expect(owner.latest.pages, isEmpty);
      expect(owner.latest.tab, 0);
      _expectModelUnchanged(before, owner.latest.model);
      expect(model.occupiedCount, 0);
    },
  );

  testWidgets(
    'zero Basic Journeys keeps one place and its guarded One upsell',
    (tester) async {
      final model = ViewRequestDraftModel(capacity: 1);
      final owner = _Owner();
      await owner.mount(tester, model: model, basic: true);
      final before = owner.latest.model;
      expect(_reader(tester).journeys, isEmpty);
      expect(_reader(tester).capacity, 1);
      expect(find.textContaining('You have 1 place.'), findsOneWidget);
      expect(_key('journey_tab_dot_target_0'), findsNothing);
      expect(_key('journey_tab_upsell'), findsOneWidget);
      expect(find.text('More Journeys come with Seeker One'), findsOneWidget);
      expect(find.text('Up to 3 at once.'), findsOneWidget);
      final retained = _upgrade(tester);
      await _capture(tester, 'basic-empty-journey-upsell');
      await _press(tester, 'journey_tab_plans');
      expect(owner.latest.pages, ['membership']);
      expect(owner.latest.tab, 1);
      _expectModelUnchanged(before, owner.latest.model);
      expect(owner.latest.model.capacity, 1);
      expect(model.occupiedCount, 0);
      retained();
      await tester.pumpAndSettle();
      expect(owner.latest.pages, ['membership']);
      _expectModelUnchanged(before, owner.latest.model);
    },
  );

  testWidgets('Basic upsell opens Membership without granting places', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 1);
    expect(model.seedJourneys(1), isTrue);
    final owner = _Owner();
    await owner.mount(tester, model: model, basic: true);
    final before = owner.latest.model;
    expect(_reader(tester).journeys.single.id, _sara);
    expect(_reader(tester).capacity, 1);
    expect(_key('journey_tab_dot_target_0'), findsOneWidget);
    expect(_key('journey_tab_dot_target_1'), findsNothing);
    expect(find.text('Free place'), findsNothing);
    expect(_key('journey_tab_upsell'), findsOneWidget);
    final retained = _upgrade(tester);
    await _capture(tester, 'basic-one-journey-upsell');
    await _press(tester, 'journey_tab_plans');
    expect(owner.latest.pages, ['membership']);
    expect(owner.latest.tab, 1);
    _expectModelUnchanged(before, owner.latest.model);
    retained();
    await tester.pumpAndSettle();
    expect(owner.latest.pages, ['membership']);
    _expectModelUnchanged(before, owner.latest.model);
  });

  for (final preparing in [true, false]) {
    testWidgets(
      '${preparing ? 'preparing' : 'active'} places remain occupied cards',
      (tester) async {
        final model = ViewRequestDraftModel(capacity: 3);
        final id = preparing ? draftProfiles.first.id : _sara;
        if (preparing) {
          expect(model.acceptReceived(id), isTrue);
        } else {
          expect(model.seedJourneys(1), isTrue);
        }
        final before = model.snapshot();
        final owner = _Owner();
        await owner.mount(tester, model: model);
        expect(_reader(tester).journeys.single.id, id);
        expect(_key('journey_tab_person_$id'), findsOneWidget);
        for (final place in [1, 2]) {
          await _press(tester, 'journey_tab_dot_target_$place');
          expect(find.text('Free place'), findsOneWidget);
          _expectModelUnchanged(before, owner.latest.model);
        }
      },
    );
  }

  for (final basic in [false, true]) {
    for (final empty in [false, true]) {
      testWidgets(
        '${basic ? 'Basic' : 'One'} ${empty ? 'zero-Journey' : 'one-Journey'} '
        'compact 200-percent places remain readable',
        (tester) async {
          final model = ViewRequestDraftModel(capacity: basic ? 1 : 3);
          if (!empty) expect(model.seedJourneys(1), isTrue);
          final before = model.snapshot();
          final owner = _Owner();
          await owner.mount(
            tester,
            model: model,
            basic: basic,
            size: const Size(320, 568),
            scale: 2,
          );
          if (!basic && !empty) {
            await _press(tester, 'journey_tab_dot_target_2');
            expect(find.text('Free place'), findsOneWidget);
          }
          final target = _key(
            basic ? 'journey_tab_plans' : 'journey_tab_browse',
          );
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          expect(target.hitTestable(), findsOneWidget);
          _expectReadableText(
            tester,
            _key(
              basic
                  ? 'journey_tab_upsell'
                  : empty
                  ? 'journey_tab_empty_scroll'
                  : 'journey_tab_free_scroll',
            ),
          );
          _expectModelUnchanged(before, owner.latest.model);
          expect(tester.takeException(), isNull);
          await _capture(
            tester,
            '${basic ? 'basic' : 'one'}-${empty ? 'empty-' : ''}compact-200-places',
          );
        },
      );
    }
  }

  testWidgets(
    'pushed Journey options replace the reader without losing return',
    (tester) async {
      final model = ViewRequestDraftModel(capacity: 3);
      expect(model.seedJourneys(1), isTrue);
      final before = model.snapshot();
      final owner = _Owner();
      await owner.mount(tester, model: model);
      await _press(tester, 'draft_journey_options_$_sara');
      final options = tester.widget<ZyraConceptJourneyOptions>(
        find.byType(ZyraConceptJourneyOptions),
      );
      expect(options.id, _sara);
      expect(options.lockedPage, isTrue);
      expect(find.byType(ZyraOneJourneyOptionsPage), findsOneWidget);
      expect(_key('journey_tab_card'), findsNothing);
      expect(_key('draft_journey_options_$_sara'), findsNothing);
      expect(find.text('Continue Journey'), findsOneWidget);
      expect(owner.latest.pages, ['journey_options']);
      await _capture(tester, 'one-journey-options-page');
      await swipeZyraBack(tester);
      expect(find.byType(ZyraConceptJourneyOptions), findsNothing);
      expect(owner.latest.pages, isEmpty);
      expect(_reader(tester).journeys.single.id, _sara);
      expect(_key('journey_tab_person_$_sara'), findsOneWidget);
      _expectModelUnchanged(before, owner.latest.model);
    },
  );

  for (final empty in [false, true]) {
    testWidgets('retained Basic ${empty ? 'zero-Journey' : 'one-Journey'} '
        'upgrade is inert after route withdrawal', (tester) async {
      final model = ViewRequestDraftModel(capacity: 1);
      if (!empty) expect(model.seedJourneys(1), isTrue);
      final owner = _Owner();
      await owner.mount(tester, model: model, basic: true);
      final retained = _upgrade(tester);
      await expandZyraPreviewTabBarIfIdle(tester);
      await tester.tapAt(tester.getCenter(_key('floating-nav-item-2')));
      await tester.pumpAndSettle();
      final before = owner.latest;
      retained();
      await tester.pumpAndSettle();
      expect(owner.latest, same(before));
      expect(owner.latest.pages, isEmpty);
      expect(owner.latest.tab, 2);
      _expectModelUnchanged(model.snapshot(), owner.latest.model);
    });

    testWidgets(
      'covered, denied and disposed Basic ${empty ? 'zero-Journey' : 'one-Journey'} '
      'upgrade callbacks are inert',
      (tester) async {
        final model = ViewRequestDraftModel(capacity: 1);
        if (!empty) expect(model.seedJourneys(1), isTrue);
        final owner = _Owner();
        await owner.mount(tester, model: model, basic: true);
        final retained = _upgrade(tester);
        unawaited(
          owner.navigator.currentState!.push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Covered')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        retained();
        await tester.pumpAndSettle();
        expect(owner.latest.pages, isEmpty);
        _expectModelUnchanged(model.snapshot(), owner.latest.model);
        owner.navigator.currentState!.pop();
        await tester.pumpAndSettle();
        retained();
        await tester.pumpAndSettle();
        expect(owner.latest.pages, isEmpty);
        owner.allowed = false;
        retained();
        await tester.pumpAndSettle();
        expect(owner.latest.pages, isEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        retained();
        await tester.pumpAndSettle();
        expect(owner.latest.pages, isEmpty);
        _expectModelUnchanged(model.snapshot(), owner.latest.model);
      },
    );
  }
}
