import 'package:zyra/theme/zyra_app_gold_style.dart';
// Capacity slots are presentation only: they never create a Journey or grant
// another place. The same model and owner guards remain authoritative.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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

List<ZyraOneJourneyConnectionsActiveCard> _cards(WidgetTester tester) => tester
    .widget<ZyraOneJourneyConnectionsPresentation>(
      find.byType(ZyraOneJourneyConnectionsPresentation),
    )
    .pages
    .single
    .whereType<ZyraOneJourneyConnectionsActiveCard>()
    .toList();

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

  testWidgets('one, two and three Journeys keep the same three compact slots', (
    tester,
  ) async {
    double? referenceHeight;
    for (final count in [3, 1, 2]) {
      final model = ViewRequestDraftModel(capacity: 3);
      expect(model.seedJourneys(count), isTrue);
      final before = model.snapshot();
      final owner = _Owner();
      await owner.mount(tester, model: model);
      final cards = _cards(tester);
      expect(cards, hasLength(count));
      expect(cards.every((card) => card.compact && card.fillHeight), isTrue);
      expect(find.text('Awaiting a Journey'), findsNWidgets(3 - count));
      expect(find.text('Upgrade to get more Journeys'), findsNothing);
      final cardHeight = tester.getSize(find.byWidget(cards.first)).height;
      referenceHeight ??= cardHeight;
      expect(cardHeight, closeTo(referenceHeight, 1));
      for (final card in cards) {
        expect(
          tester.getSize(find.byWidget(card)).height,
          closeTo(cardHeight, 1),
        );
      }
      for (var index = count; index < 3; index++) {
        expect(
          tester.getSize(_key('concept_journey_capacity_slot_$index')).height,
          closeTo(cardHeight, 1),
        );
      }
      _expectModelUnchanged(before, owner.latest.model);
      await _capture(tester, 'one-$count-journeys-three-slots');
    }
  });

  testWidgets('zero One Journeys shows three inert awaiting slots', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3);
    final before = model.snapshot();
    final owner = _Owner();
    await owner.mount(tester, model: model);
    expect(find.byType(ZyraOneJourneyConnectionsPresentation), findsOneWidget);
    expect(_cards(tester), isEmpty);
    expect(_key('concept_journey_empty'), findsNothing);
    expect(find.text('Your Journeys will appear here'), findsNothing);
    expect(find.text('Awaiting a Journey'), findsNWidgets(3));
    expect(find.text('Upgrade to get more Journeys'), findsNothing);
    final firstHeight = tester
        .getSize(_key('concept_journey_capacity_slot_0'))
        .height;
    for (var index = 0; index < 3; index++) {
      final slot = _key('concept_journey_capacity_slot_$index');
      expect(slot, findsOneWidget);
      expect(tester.getSize(slot).height, closeTo(firstHeight, 1));
      expect(
        find.descendant(of: slot, matching: find.byType(OutlinedButton)),
        findsNothing,
      );
      await tester.tap(slot);
      await tester.pumpAndSettle();
      expect(owner.latest.pages, isEmpty);
      expect(owner.latest.tab, 1);
      _expectModelUnchanged(before, owner.latest.model);
    }
    expect(model.occupiedCount, 0);
    await _capture(tester, 'empty-journeys');
  });

  testWidgets(
    'zero Basic Journeys keeps one awaiting and two guarded upgrades',
    (tester) async {
      final model = ViewRequestDraftModel(capacity: 1);
      final owner = _Owner();
      await owner.mount(tester, model: model, basic: true);
      final before = owner.latest.model;
      expect(_cards(tester), isEmpty);
      expect(find.text('Awaiting a Journey'), findsOneWidget);
      expect(find.text('Upgrade to get more Journeys'), findsNWidgets(2));
      final firstHeight = tester
          .getSize(_key('concept_journey_capacity_slot_0'))
          .height;
      for (var index = 0; index < 3; index++) {
        expect(
          tester.getSize(_key('concept_journey_capacity_slot_$index')).height,
          closeTo(firstHeight, 1),
        );
      }
      expect(_key('concept_journey_upgrade_slot_0'), findsNothing);
      final retained = tester
          .widget<OutlinedButton>(_key('concept_journey_upgrade_slot_2'))
          .onPressed!;
      await _capture(tester, 'basic-empty-journey-upgrade-slots');
      await _press(tester, 'concept_journey_upgrade_slot_1');
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

  testWidgets('Basic locked slots open Membership without granting places', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 1);
    expect(model.seedJourneys(1), isTrue);
    final owner = _Owner();
    await owner.mount(tester, model: model, basic: true);
    final before = owner.latest.model;
    expect(_cards(tester), hasLength(1));
    expect(_cards(tester).single.compact, isTrue);
    expect(find.text('Awaiting a Journey'), findsNothing);
    expect(find.text('Upgrade to get more Journeys'), findsNWidgets(2));
    final retained = tester
        .widget<OutlinedButton>(_key('concept_journey_upgrade_slot_2'))
        .onPressed!;
    await _capture(tester, 'basic-one-journey-upgrade-slots');
    await _press(tester, 'concept_journey_upgrade_slot_1');
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
        final owner = _Owner();
        await owner.mount(tester, model: model);
        expect(_cards(tester).single.profile.id, id);
        expect(find.text('Awaiting a Journey'), findsNWidgets(2));
        expect(owner.latest.model.states, model.snapshot().states);
      },
    );
  }

  for (final basic in [false, true]) {
    for (final empty in [false, true]) {
      testWidgets(
        '${basic ? 'Basic' : 'One'} ${empty ? 'zero-Journey' : 'one-Journey'} '
        'compact 200-percent slots remain readable',
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
          final target = basic
              ? _key('concept_journey_upgrade_slot_2')
              : find.text('Awaiting a Journey').last;
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          expect(target.hitTestable(), findsOneWidget);
          for (final element
              in find
                  .descendant(
                    of: _key('concept_journey_capacity_slot_2'),
                    matching: find.byType(Text),
                  )
                  .evaluate()) {
            final text = element.widget as Text;
            expect(text.overflow, isNot(TextOverflow.ellipsis));
            final paragraph = element.findRenderObject();
            if (paragraph is RenderParagraph) {
              expect(paragraph.didExceedMaxLines, isFalse);
            }
          }
          _expectModelUnchanged(before, owner.latest.model);
          expect(tester.takeException(), isNull);
          await _capture(
            tester,
            '${basic ? 'basic' : 'one'}-${empty ? 'empty-' : ''}'
            'compact-200-slots',
          );
        },
      );
    }
  }

  testWidgets('expanded Journey options replace slots without losing return', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3);
    expect(model.seedJourneys(1), isTrue);
    final owner = _Owner();
    await owner.mount(tester, model: model);
    await _press(tester, 'draft_journey_options_$_sara');
    expect(_key('concept_expanded_journey_$_sara'), findsOneWidget);
    expect(_key('concept_journey_capacity_slot_1'), findsNothing);
    expect(_key('concept_journey_capacity_slot_2'), findsNothing);
    expect(find.text('Continue Journey'), findsOneWidget);
    await _capture(tester, 'one-journey-expanded-options');
    await _press(tester, 'draft_journey_options_$_sara');
    expect(_key('concept_expanded_journey_$_sara'), findsNothing);
    expect(find.text('Awaiting a Journey'), findsNWidgets(2));
    expect(owner.latest.model.states, model.snapshot().states);
  });

  for (final empty in [false, true]) {
    testWidgets('retained Basic ${empty ? 'zero-Journey' : 'one-Journey'} '
        'upgrade is inert after route withdrawal', (tester) async {
      final model = ViewRequestDraftModel(capacity: 1);
      if (!empty) expect(model.seedJourneys(1), isTrue);
      final owner = _Owner();
      await owner.mount(tester, model: model, basic: true);
      final retained = tester
          .widget<OutlinedButton>(_key('concept_journey_upgrade_slot_1'))
          .onPressed!;
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
        final retained = tester
            .widget<OutlinedButton>(_key('concept_journey_upgrade_slot_1'))
            .onPressed!;
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
