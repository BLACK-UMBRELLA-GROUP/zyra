// Real protected-shell coverage for the Ended portrait card. Every subject,
// disclosure and credit is a caller-owned offline fixture, never member data.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_draft_browse_utility_presentation.dart';
import 'package:zyra/dev/zyra_draft_compatibility_access_store.dart';
import 'package:zyra/dev/zyra_draft_compatibility_presentation.dart';
import 'package:zyra/dev/zyra_draft_journey_bio_presentation.dart';
import 'package:zyra/dev/zyra_draft_timeline_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_card_content.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_profile_image.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _sara = 'draft-sara';
const _amira = 'draft-amira';
const _font = 'PoppinsEndedJourneyCard';
const _boundary = ValueKey('ended-journey-card-candidate');
const _captureDirectory = String.fromEnvironment(
  'ZYRA_ENDED_JOURNEY_CAPTURE_DIR',
);
const _options = [
  ZyraConceptJourneyOption.profile,
  ZyraConceptJourneyOption.timeline,
  ZyraConceptJourneyOption.bio,
  ZyraConceptJourneyOption.compatibility,
  ZyraConceptJourneyOption.guardians,
  ZyraConceptJourneyOption.report,
];

Finder _key(String id) => find.byKey(ValueKey(id));
Finder _option(ZyraConceptJourneyOption option) =>
    _key('draft_options_${option.name}_$_sara');

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Ended Journey review must remain offline.');
  }
}

class _Owner {
  final navigator = GlobalKey<NavigatorState>();
  final observer = ZyraDevControlsRouteObserver();
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];
  late final access = ZyraDraftCompatibilityAccessStore(canAct: () => true);

  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;
  ViewRequestDraftModel get model =>
      ViewRequestDraftModel.fromSnapshot(latest.model);

  Future<void> mount(
    WidgetTester tester, {
    ViewRequestDraftModel? model,
    ZyraPreviewNavigationCheckpoint? checkpoint,
    Size size = const Size(393, 852),
    double scale = 1,
    DateTime Function()? clock,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    final ready = Completer<void>();
    final ownerGeneration = ZyraAccountState.generation;
    final ownerId = ZyraAccountState.userId;
    final initial =
        checkpoint ??
        ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: (model ?? _ended()).snapshot(),
          tab: 2,
          pages: const ['ended'],
          personId: _sara,
        );
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [observer],
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: RepaintBoundary(key: _boundary, child: child!),
        ),
        home: clock != null
            ? ZyraOneJourneyConceptShell(
                key: UniqueKey(),
                canAct: () =>
                    ZyraDeveloperAccess.isAuthorizedOperator &&
                    ZyraAccountState.generation == ownerGeneration &&
                    ZyraAccountState.userId == ownerId,
                onExit: () {},
                initialCheckpoint: initial,
                previewClock: clock,
                compatibilityAccess: access,
                onCheckpoint: checkpoints.add,
                onPresentationReady: () {
                  if (!ready.isCompleted) ready.complete();
                },
              )
            : ViewRequestDraftScreen(
                key: UniqueKey(),
                ownerGeneration: ZyraAccountState.generation,
                ownerId: ZyraAccountState.userId,
                initialCheckpoint: initial,
                compatibilityAccess: access,
                onCheckpoint: checkpoints.add,
                onPresentationReady: () {
                  if (!ready.isCompleted) ready.complete();
                },
              ),
      ),
    );
    // Local codecs prepare off the fake clock. Bound the actual photo-ready
    // publication rather than substituting network or blank image providers.
    for (var frame = 0; frame < 100 && !ready.isCompleted; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
    }
    expect(ready.isCompleted, isTrue, reason: 'Bundled portraits prepared');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(checkpoints, isNotEmpty);
    expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
  }

  void close() {
    access.close();
    observer.dispose();
  }
}

ViewRequestDraftModel _ended({
  bool blocked = false,
  bool sharedBio = false,
  bool completedBio = true,
  DateTime? endedAt,
}) {
  final model = ViewRequestDraftModel(
    capacity: 3,
    clock: endedAt == null ? null : () => endedAt,
  )..seedJourneys(1);
  if (sharedBio) {
    expect(model.sendSalam(_sara), isTrue);
    expect(model.simulatePeerSalam(_sara), isTrue);
    expect(model.chooseStageContinue(_sara), isTrue);
    expect(model.simulatePeerStageContinue(_sara), isTrue);
    expect(model.advanceStage(_sara), isTrue);
    expect(model.chooseCompatibilityReveal(_sara), isTrue);
    expect(model.simulatePeerCompatibilityReveal(_sara), isTrue);
    expect(model.chooseStageContinue(_sara), isTrue);
    expect(model.simulatePeerStageContinue(_sara), isTrue);
    expect(model.beginBioStep(_sara), isTrue);
    expect(model.chooseBioReveal(_sara), isTrue);
    expect(model.simulatePeerBioReveal(_sara), isTrue);
    if (completedBio) {
      expect(model.chooseBioContinue(_sara), isTrue);
      expect(model.simulatePeerBioContinue(_sara), isTrue);
      expect(model.completeBioStep(_sara), isTrue);
    }
  }
  expect(model.end(_sara), isTrue);
  if (blocked) expect(model.block(_sara), isTrue);
  expect(model.hasUnseenReceivedRequest(_amira), isTrue);
  return model;
}

VoidCallback _action(WidgetTester tester, Finder target) {
  expect(target, findsOneWidget);
  final widget = tester.widget<Widget>(target);
  if (widget is ButtonStyleButton) return widget.onPressed!;
  if (widget is InkWell) return widget.onTap!;
  if (widget is GestureDetector) return widget.onTap!;
  final receiver = find.descendant(of: target, matching: find.byType(InkWell));
  expect(receiver, findsOneWidget);
  return tester.widget<InkWell>(receiver).onTap!;
}

Future<void> _press(WidgetTester tester, Finder target) async {
  if (target.evaluate().isEmpty) {
    final controls = _key('dev_controls_scroll');
    expect(controls, findsOneWidget);
    await tester.scrollUntilVisible(
      target,
      160,
      scrollable: find.descendant(
        of: controls,
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
  }
  expect(target, findsOneWidget);
  final ancestors = find.ancestor(
    of: target,
    matching: find.byType(Scrollable),
  );
  if (ancestors.evaluate().isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  final logicalSize = tester.view.physicalSize / tester.view.devicePixelRatio;
  var visible = tester.getRect(target).intersect(Offset.zero & logicalSize);
  for (final element in ancestors.evaluate()) {
    visible = visible.intersect(
      tester.getRect(
        find.byElementPredicate((candidate) => identical(element, candidate)),
      ),
    );
  }
  expect(visible.width, greaterThan(0));
  expect(visible.height, greaterThan(0));
  final box = tester.renderObject<RenderBox>(target);
  final point = box.globalToLocal(visible.center);
  expect(
    target.hitTestable(
      at: Alignment(
        point.dx * 2 / box.size.width - 1,
        point.dy * 2 / box.size.height - 1,
      ),
    ),
    findsOneWidget,
    reason: 'The visible action must receive its physical tap.',
  );
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _openOptions(WidgetTester tester) async {
  if (find.byType(ZyraConceptJourneyOptions).evaluate().isEmpty) {
    await _press(tester, _key('draft_journey_options_$_sara'));
  }
  expect(find.byType(BottomSheet), findsNothing);
  expect(find.byType(ZyraConceptJourneyOptions), findsOneWidget);
}

Future<void> _nav(WidgetTester tester, int index) async {
  for (
    var depth = 0;
    find.byType(ZyraShellNavigation).evaluate().isEmpty && depth < 8;
    depth++
  ) {
    await returnZyraPreviewPage(tester);
  }
  final cell = _key('floating-nav-item-$index');
  expect(cell, findsOneWidget);
  // The shared bar owns dispatch; its individual icon cells ignore pointers.
  await tester.tapAt(tester.getCenter(cell));
  await tester.pumpAndSettle();
  expect(
    tester
        .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
        .currentIndex,
    index,
  );
  expect(tester.takeException(), isNull);
}

void _expectNoJourneyWrites() {
  for (final id in [
    'draft_end_$_sara',
    'draft_pause_$_sara',
    'draft_options_end_$_sara',
    'draft_options_pause_$_sara',
    'concept_message',
    'concept_send_message',
  ]) {
    expect(_key(id), findsNothing);
  }
  expect(AppState.instance.activeJourneys, isEmpty);
}

void _expectSameModel(_Owner owner, ViewRequestDraftSnapshot before) {
  final after = owner.latest.model;
  expect(after.capacity, before.capacity);
  expect(after.states, before.states);
  expect(after.progress, before.progress);
  expect(after.hiddenPeers, before.hiddenPeers);
  expect(after.blockedPeers, before.blockedPeers);
  expect(
    after.acknowledgedReceivedRequestIds,
    before.acknowledgedReceivedRequestIds,
  );
  expect(after.guardianAccess, before.guardianAccess);
  expect(after.journeyStartedAt, before.journeyStartedAt);
  expect(after.endedAttempts, before.endedAttempts);
  expect(after.currentEndedAttemptIds, before.currentEndedAttemptIds);
  expect(owner.model.occupiedCount, 0);
  expect(owner.model.hasUnseenReceivedRequest(_amira), isTrue);
  expect(owner.model.stateFor(_sara), DraftJourneyState.ended);
  _expectNoJourneyWrites();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  for (final element in find.byType(Image).evaluate()) {
    final widget = element.widget as Image;
    await tester.runAsync(() async {
      final ready = Completer<void>();
      final stream = widget.image.resolve(
        createLocalImageConfiguration(element),
      );
      final listener = ImageStreamListener(
        (info, _) {
          info.dispose();
          if (!ready.isCompleted) ready.complete();
        },
        onError: (Object error, StackTrace? stack) {
          if (!ready.isCompleted) ready.completeError(error, stack);
        },
      );
      stream.addListener(listener);
      try {
        await ready.future.timeout(const Duration(seconds: 5));
      } finally {
        stream.removeListener(listener);
      }
    });
  }
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  await tester.runAsync(() async {
    final output = File('$_captureDirectory/$name.png');
    expect(output.existsSync(), isFalse, reason: 'Never replace evidence');
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
  final owners = <_Owner>[];
  late HttpOverrides? oldOverrides;
  late _NoNetwork network;
  late bool oldStubs;
  late String? oldFont;
  late ZyraHapticLevel oldHaptics;
  final oldFatal = WidgetController.hitTestWarningShouldBeFatal;

  _Owner owner() {
    final current = _Owner();
    owners.add(current);
    return current;
  }

  setUpAll(() async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    final font = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await font.load();
    if (_captureDirectory.isNotEmpty) {
      final directory = Directory(_captureDirectory).absolute;
      final parent = directory.parent.resolveSymbolicLinksSync();
      final workspace = Directory.current.resolveSymbolicLinksSync();
      final temporary = Directory.systemTemp.resolveSymbolicLinksSync();
      expect(
        parent.startsWith('$workspace${Platform.pathSeparator}') ||
            parent == temporary ||
            parent.startsWith('$temporary${Platform.pathSeparator}'),
        isTrue,
        reason: 'Capture must use a dedicated local workspace/temp child.',
      );
      expect(directory.path.contains('PRIVATE'), isFalse);
      expect(directory.path.split(Platform.pathSeparator).last, isNotEmpty);
      expect(directory.existsSync(), isFalse, reason: 'Use a fresh directory');
      directory.createSync();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });

  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    ZyraAccountState.clearImagesForTesting = () async {};
    final gold = ZyraDevAppGold.instance;
    gold.select(
      false,
      expectedGeneration: ZyraAccountState.generation,
      expectedRevision: gold.revision,
    );
    oldStubs = ZyraText.useTestFontStubs;
    oldFont = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
    oldHaptics = ZyraInteractionStyle.hapticLevel;
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.off);
    oldOverrides = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    for (final current in owners) {
      current.close();
    }
    owners.clear();
    expect(network.attempts, 0);
    HttpOverrides.global = oldOverrides;
    ZyraText.useTestFontStubs = oldStubs;
    ZyraText.testReadingFontFamily = oldFont;
    ZyraInteractionStyle.selectHapticLevel(oldHaptics);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  tearDownAll(() {
    WidgetController.hitTestWarningShouldBeFatal = oldFatal;
  });

  testWidgets(
    'Ended keeps the active portrait card and holds Request restart',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final current = owner();
      await current.mount(tester);
      final before = current.latest.model;
      expect(_key('draft_journey_${_sara}_header'), findsOneWidget);
      final card = tester.widget<ZyraOneJourneyConnectionsActiveCard>(
        find.byType(ZyraOneJourneyConnectionsActiveCard),
      );
      expect(card.profile.id, _sara);
      expect(card.profile.photos, isNotEmpty);
      expect(card.cardDesign, ZyraOneJourneyCardDesign.portraitSplit);
      expect(card.onReport, isNull);
      expect(find.byType(ZyraOneJourneyConnectionsPersonCard), findsNothing);
      expect(find.text('Request restart'), findsOneWidget);
      expect(_key('draft_journey_$_sara'), findsNothing);
      expect(_key('draft_journey_options_$_sara'), findsOneWidget);
      _expectNoJourneyWrites();
      await _capture(tester, 'ended_card_393');
      await _press(tester, _key('draft_restart_$_sara'));
      expect(_key('draft_ended_restart_$_sara'), findsOneWidget);
      final send = _key('draft_restart_send_$_sara');
      expect(send, findsOneWidget);
      expect(tester.widget<OutlinedButton>(send).onPressed, isNull);
      expect(find.text('Request sent'), findsNothing);
      expect(find.textContaining('No request has been sent.'), findsOneWidget);
      _expectSameModel(current, before);
      await _capture(tester, 'ended_restart_393');
      expect(_key('draft_restart_archive_$_sara'), findsNothing);
      expect(find.text('View archive'), findsNothing);
      await returnZyraPreviewPage(tester);
      expect(_key('concept_activity_ended'), findsOneWidget);
      await _openOptions(tester);
      expect(find.text('View archive'), findsNothing);
      await _press(tester, _option(ZyraConceptJourneyOption.timeline));
      expect(find.byType(ZyraDraftTimelinePresentation), findsOneWidget);
      _expectSameModel(current, before);
      await _capture(tester, 'ended_timeline_393');
    },
  );

  testWidgets('all six read-only options address their owned destination', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final current = owner();
    await current.mount(tester);
    final before = current.latest.model;
    for (final choice in _options) {
      await _openOptions(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ZyraConceptJourneyOptions), findsOneWidget);
      expect(_option(choice), findsOneWidget);
      final menu = tester.widget<ZyraConceptJourneyOptions>(
        find.byType(ZyraConceptJourneyOptions),
      );
      expect(menu.inline, isTrue);
      expect(menu.canEnd, isFalse);
      if (choice == _options.first) {
        await _capture(tester, 'ended_options_393');
      }
      await _press(tester, _option(choice));
      switch (choice) {
        case ZyraConceptJourneyOption.profile:
          final profile = tester.widget<ZyraOneJourneyBrowsePresentation>(
            find.byType(ZyraOneJourneyBrowsePresentation),
          );
          expect(profile.profile.id, _sara);
          expect(profile.onRequest, isNull);
        case ZyraConceptJourneyOption.timeline:
          final timeline = tester.widget<ZyraDraftTimelinePresentation>(
            find.byType(ZyraDraftTimelinePresentation),
          );
          expect(timeline.subjectId, _sara);
          expect(timeline.onPropose, isNull);
          expect(timeline.onConfirm, isNull);
        case ZyraConceptJourneyOption.bio:
          expect(_key('draft_ended_bio_$_sara'), findsOneWidget);
          expect(find.byType(ZyraDraftJourneyBioPresentation), findsNothing);
          expect(_key('draft_journey_bio_about'), findsNothing);
        case ZyraConceptJourneyOption.compatibility:
          expect(
            _key('draft_ended_compatibility_locked_$_sara'),
            findsOneWidget,
          );
          expect(find.byType(ZyraDraftCompatibilityPresentation), findsNothing);
        case ZyraConceptJourneyOption.guardians:
          expect(_key('draft_ended_guardians_$_sara'), findsOneWidget);
          expect(find.text('Ibrahim'), findsNothing);
          expect(find.text('Yusuf'), findsNothing);
        case ZyraConceptJourneyOption.report:
          expect(find.byType(ZyraDraftReportPresentation), findsOneWidget);
        case ZyraConceptJourneyOption.end:
          fail('Ended never exposes a Journey mutation option.');
      }
      expect(find.byType(ZyraConceptJourneyOptions), findsNothing);
      _expectSameModel(current, before);
      await returnZyraPreviewPage(tester);
      expect(_key('concept_activity_ended'), findsOneWidget);
    }
  });

  testWidgets('ordinary compatibility spends once and grants no ended Bio', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final current = owner();
    final ended = _ended();
    // Spending is deliberate ordinary Profile access, not an archive shortcut.
    await current.mount(
      tester,
      checkpoint: ZyraPreviewNavigationCheckpoint(
        guardian: false,
        model: ended.snapshot(),
        tab: 0,
        pages: const ['compatibility'],
        personId: _sara,
      ),
    );
    final before = current.latest.model;
    await _press(tester, _key('draft_compatibility_reveal'));
    final saved = current.access.resultFor(_sara)!;
    expect(current.access.balance, 0);
    expect(saved.profileId, _sara);
    await _nav(tester, 2);
    await _press(tester, _key('my-zyra-route-concept-my-ended'));
    await _openOptions(tester);
    await _press(tester, _option(ZyraConceptJourneyOption.compatibility));
    final result = tester.widget<ZyraDraftCompatibilityPresentation>(
      find.byType(ZyraDraftCompatibilityPresentation),
    );
    expect(result.revealed, isTrue);
    expect(result.overallScore, saved.overallScore);
    expect(result.onUnlock, isNull);
    expect(current.access.resultFor(_sara), same(saved));
    expect(current.access.balance, 0);
    await returnZyraPreviewPage(tester);
    await _openOptions(tester);
    await _press(tester, _option(ZyraConceptJourneyOption.bio));
    expect(_key('draft_ended_bio_$_sara'), findsOneWidget);
    expect(find.byType(ZyraDraftJourneyBioPresentation), findsNothing);
    expect(_key('draft_journey_bio_about'), findsNothing);
    for (final id in ['occupation', 'education', 'future_children', 'home']) {
      expect(_key('draft_journey_bio_field_$id'), findsNothing);
    }
    expect(current.model.hasChosenBioReveal(_sara), isFalse);
    expect(current.model.peerHasChosenBioReveal(_sara), isFalse);
    _expectSameModel(current, before);
  });

  testWidgets('a real prior profile unlock survives the physical End flow', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final current = owner();
    final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(1);
    await current.mount(
      tester,
      checkpoint: ZyraPreviewNavigationCheckpoint(
        guardian: false,
        model: model.snapshot(),
        tab: 0,
        pages: const ['compatibility'],
        personId: _sara,
      ),
    );
    await _press(tester, _key('draft_compatibility_reveal'));
    final saved = current.access.resultFor(_sara)!;
    expect(current.access.balance, 0);
    await _nav(tester, 1);
    await _press(tester, _key('draft_journey_options_$_sara'));
    await _press(tester, _key('draft_options_end_$_sara'));
    await _press(tester, _key('draft_confirm_end_$_sara'));
    expect(current.model.stateFor(_sara), DraftJourneyState.ended);
    await _nav(tester, 2);
    await _press(tester, _key('my-zyra-route-concept-my-ended'));
    final before = current.latest.model;
    await _openOptions(tester);
    await _press(tester, _option(ZyraConceptJourneyOption.compatibility));
    final result = tester.widget<ZyraDraftCompatibilityPresentation>(
      find.byType(ZyraDraftCompatibilityPresentation),
    );
    expect(result.revealed, isTrue);
    expect(result.overallScore, saved.overallScore);
    expect(result.onUnlock, isNull);
    expect(current.access.resultFor(_sara), same(saved));
    expect(current.access.balance, 0);
    _expectSameModel(current, before);
  });

  for (final page in [
    'ended_bio',
    'ended_guardians',
    'ended_compatibility',
    'ended_restart',
  ]) {
    testWidgets('fresh Ended checkpoint safely restores $page', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final current = owner();
      await current.mount(
        tester,
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: _ended().snapshot(),
          tab: 2,
          pages: ['ended', page],
          personId: _sara,
          compatibilityBalance: 0,
          compatibilityRevealed: true,
        ),
      );
      // Checkpoint flags cannot manufacture either disclosure or credits.
      expect(current.access.balance, 1);
      expect(current.access.isUnlocked(_sara), isFalse);
      expect(find.byType(ZyraDraftJourneyBioPresentation), findsNothing);
      expect(_key('draft_journey_bio_about'), findsNothing);
      if (page == 'ended_restart') {
        expect(current.latest.pages, ['ended']);
        expect(_key('draft_ended_restart_$_sara'), findsNothing);
        expect(_key('draft_restart_$_sara'), findsOneWidget);
      } else {
        expect(current.latest.pages, ['ended', page]);
        expect(
          _key(
            page == 'ended_compatibility'
                ? 'draft_ended_compatibility_locked_$_sara'
                : 'draft_${page}_$_sara',
          ),
          findsOneWidget,
        );
      }
      expect(current.model.hasUnseenReceivedRequest(_amira), isTrue);
      expect(current.model.occupiedCount, 0);
      _expectNoJourneyWrites();
    });
  }

  for (final offset in [-1, 0, 1]) {
    testWidgets('Ended private doors use exact calendar boundary $offset', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final current = owner();
      final end = DateTime.utc(2026, 7, 31, 12);
      final now = DateTime.utc(2026, 10, 31, 12).add(Duration(minutes: offset));
      await current.mount(
        tester,
        model: _ended(endedAt: end, sharedBio: true),
        clock: () => now,
      );
      final before = current.latest.model;
      await _openOptions(tester);
      final menu = tester.widget<ZyraConceptJourneyOptions>(
        find.byType(ZyraConceptJourneyOptions),
      );
      expect(menu.canViewBio, offset < 0);
      expect(menu.canViewCompatibility, offset < 0);
      expect(menu.canViewGuardians, offset < 0);
      await _press(tester, _option(ZyraConceptJourneyOption.bio));
      expect(
        find.byType(ZyraDraftJourneyBioPresentation),
        offset < 0 ? findsOneWidget : findsNothing,
      );
      await returnZyraPreviewPage(tester);
      await _openOptions(tester);
      await _press(tester, _option(ZyraConceptJourneyOption.compatibility));
      expect(
        find.byType(ZyraDraftCompatibilityPresentation),
        offset < 0 ? findsOneWidget : findsNothing,
      );
      if (offset < 0) {
        final score = tester.widget<ZyraDraftCompatibilityPresentation>(
          find.byType(ZyraDraftCompatibilityPresentation),
        );
        expect(score.revealed, isTrue);
        expect(score.onUnlock, isNull);
        expect(score.onBuyMore, isNull);
      }
      expect(current.access.balance, 1);
      _expectSameModel(current, before);
    });
  }

  for (final wrongProfileGrant in [false, true]) {
    testWidgets(
      'expired score rejects balance and wrong-profile grant: $wrongProfileGrant',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final current = owner();
        expect(current.access.setBalance(count: 5), isTrue);
        if (wrongProfileGrant) expect(current.access.unlock(_amira), isTrue);
        final balance = current.access.balance;
        final model = _ended(
          endedAt: DateTime.utc(2026, 1, 31),
          sharedBio: true,
        );
        await current.mount(
          tester,
          clock: () => DateTime.utc(2026, 5, 1),
          checkpoint: ZyraPreviewNavigationCheckpoint(
            guardian: false,
            model: model.snapshot(),
            tab: 2,
            pages: const ['ended', 'ended_compatibility'],
            personId: _sara,
            compatibilityRevealed: true,
            compatibilityBalance: 5,
          ),
        );
        expect(_key('draft_ended_compatibility_locked_$_sara'), findsOneWidget);
        expect(find.byType(ZyraDraftCompatibilityPresentation), findsNothing);
        expect(_key('draft_compatibility_reveal'), findsNothing);
        expect(current.access.balance, balance);
        expect(current.access.isUnlocked(_sara), isFalse);
      },
    );
  }

  testWidgets('used profile Unlock outlasts only the score window', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final current = owner();
    expect(current.access.unlock(_sara), isTrue);
    final saved = current.access.resultFor(_sara);
    await current.mount(
      tester,
      model: _ended(endedAt: DateTime.utc(2025, 1, 31), sharedBio: true),
      clock: () => DateTime.utc(2026, 10, 22),
    );
    await _openOptions(tester);
    final menu = tester.widget<ZyraConceptJourneyOptions>(
      find.byType(ZyraConceptJourneyOptions),
    );
    expect(menu.canViewCompatibility, isTrue);
    expect(menu.canViewBio, isFalse);
    expect(menu.canViewGuardians, isFalse);
    await _press(tester, _option(ZyraConceptJourneyOption.compatibility));
    final score = tester.widget<ZyraDraftCompatibilityPresentation>(
      find.byType(ZyraDraftCompatibilityPresentation),
    );
    expect(score.overallScore, saved!.overallScore);
    expect(score.revealed, isTrue);
    expect(score.onUnlock, isNull);
    expect(current.access.resultFor(_sara), same(saved));
    await returnZyraPreviewPage(tester);
    await _openOptions(tester);
    await _press(tester, _option(ZyraConceptJourneyOption.guardians));
    expect(find.text('Journey access has ended'), findsOneWidget);
    expect(find.text('Hassan'), findsNothing);
    expect(find.text('Yusuf'), findsNothing);
  });

  testWidgets(
    'visible Ended Bio withdraws and retained actions recheck expiry',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final current = owner();
      final deadline = DateTime.utc(2026, 10, 31, 12);
      var now = deadline.subtract(const Duration(minutes: 10));
      await current.mount(
        tester,
        model: _ended(endedAt: DateTime.utc(2026, 7, 31, 12), sharedBio: true),
        clock: () => now,
      );
      await _openOptions(tester);
      final retained = tester
          .widget<ZyraConceptJourneyOptions>(
            find.byType(ZyraConceptJourneyOptions),
          )
          .onSelected;
      await _press(tester, _option(ZyraConceptJourneyOption.bio));
      expect(find.byType(ZyraDraftJourneyBioPresentation), findsOneWidget);
      now = deadline;
      await tester.pump(const Duration(minutes: 10));
      await tester.pumpAndSettle();
      expect(find.byType(ZyraDraftJourneyBioPresentation), findsNothing);
      expect(find.text('Journey access has ended'), findsOneWidget);
      retained(ZyraConceptJourneyOption.compatibility);
      await tester.pumpAndSettle();
      expect(current.latest.pages.last, 'ended_bio');
      expect(find.byType(ZyraDraftCompatibilityPresentation), findsNothing);
    },
  );

  testWidgets('Timeline score door rechecks the same deadline at tap time', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final current = owner();
    final deadline = DateTime.utc(2026, 10, 31, 12);
    var now = deadline.subtract(const Duration(minutes: 10));
    await current.mount(
      tester,
      model: _ended(endedAt: DateTime.utc(2026, 7, 31, 12), sharedBio: true),
      clock: () => now,
    );
    await _openOptions(tester);
    await _press(tester, _option(ZyraConceptJourneyOption.timeline));
    final timeline = tester.widget<ZyraDraftTimelinePresentation>(
      find.byType(ZyraDraftTimelinePresentation),
    );
    final attemptId = current.model.currentEndedAttemptFor(_sara)!.id;
    expect(timeline.readableCompatibilityAttemptIds, contains(attemptId));
    final retained = timeline.onViewAttemptCompatibility!;
    now = deadline;
    retained(attemptId);
    await tester.pump();
    expect(current.latest.pages.last, 'timeline');
    expect(find.byType(ZyraDraftCompatibilityPresentation), findsNothing);
    expect(current.access.balance, 1);
  });

  testWidgets('restart has no age cap but hidden profiles cannot request it', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final current = owner();
    final model = _ended(endedAt: DateTime.utc(2020, 1, 1));
    await current.mount(
      tester,
      model: model,
      clock: () => DateTime.utc(2026, 10, 22),
    );
    await _press(tester, _key('draft_restart_$_sara'));
    expect(_key('draft_ended_restart_$_sara'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(_key('draft_restart_send_$_sara'))
          .onPressed,
      isNull,
    );
    expect(model.hide(_sara), isTrue);
    await current.mount(
      tester,
      model: model,
      clock: () => DateTime.utc(2026, 10, 22),
    );
    expect(current.latest.pages, ['ended']);
    expect(tester.widget<InkWell>(_key('draft_restart_$_sara')).onTap, isNull);
    expect(_key('draft_ended_restart_$_sara'), findsNothing);
  });

  for (final completed in [false, true]) {
    testWidgets('Ended Bio requires both shares and completion: $completed', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final current = owner();
      await current.mount(
        tester,
        model: _ended(sharedBio: true, completedBio: completed),
      );
      final before = current.latest.model;
      await _openOptions(tester);
      await _press(tester, _option(ZyraConceptJourneyOption.bio));
      expect(_key('draft_ended_bio_$_sara'), findsOneWidget);
      if (completed) {
        final bio = tester.widget<ZyraDraftJourneyBioPresentation>(
          find.byType(ZyraDraftJourneyBioPresentation),
        );
        expect(bio.subjectId, _sara);
        expect(bio.projection!.subjectId, _sara);
        expect(_key('draft_journey_bio_about'), findsOneWidget);
      } else {
        expect(find.byType(ZyraDraftJourneyBioPresentation), findsNothing);
        expect(_key('draft_journey_bio_about'), findsNothing);
      }
      _expectSameModel(current, before);
    });
  }

  for (final change in [
    'reset',
    'role',
    'controls',
    'controls ABA',
    'covered route',
    'covered route ABA',
    'account generation',
    'revocation',
    'authorization ABA',
    'unmount',
  ]) {
    testWidgets('Ended retained actions deny after $change', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final current = owner();
      await current.mount(tester);
      final restart = _action(tester, _key('draft_restart_$_sara'));
      final dots = _action(tester, _key('draft_journey_options_$_sara'));
      await _openOptions(tester);
      final menu = tester.widget<ZyraConceptJourneyOptions>(
        find.byType(ZyraConceptJourneyOptions),
      );
      switch (change) {
        case 'reset':
        case 'role':
        case 'controls':
        case 'controls ABA':
          await openZyraDevControls(tester);
          if (change == 'reset' || change == 'role') {
            await _press(
              tester,
              _key(change == 'reset' ? 'draft_reset' : 'draft_role_guardian'),
            );
          } else if (change == 'controls ABA') {
            await closeZyraDevControls(tester);
          }
        case 'covered route':
        case 'covered route ABA':
          unawaited(
            current.navigator.currentState!.push<void>(
              MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('Owned cover route')),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (change == 'covered route ABA') {
            current.navigator.currentState!.pop();
            await tester.pumpAndSettle();
          }
        case 'account generation':
          ZyraAccountState.resetForTesting();
          AppState.instance.resetForAccountChange();
        case 'revocation':
        case 'authorization ABA':
          ZyraDeveloperAccess.setAuthorizedForTesting(false);
          if (change == 'authorization ABA') {
            ZyraDeveloperAccess.setAuthorizedForTesting(true);
          }
        case 'unmount':
          await tester.pumpWidget(const SizedBox.shrink());
      }
      await tester.pumpAndSettle();
      final before = current.latest.model;
      final pages = List<String>.of(current.latest.pages);
      restart();
      dots();
      for (final choice in _options) {
        menu.onSelected(choice);
      }
      await tester.pumpAndSettle();
      expect(current.latest.pages, pages);
      expect(current.latest.model.states, before.states);
      expect(current.latest.model.progress, before.progress);
      expect(
        current.latest.model.acknowledgedReceivedRequestIds,
        before.acknowledgedReceivedRequestIds,
      );
      expect(_key('draft_ended_restart_$_sara'), findsNothing);
      expect(_key('concept_archive_$_sara'), findsNothing);
      expect(_key('draft_ended_bio_$_sara'), findsNothing);
      expect(_key('draft_ended_guardians_$_sara'), findsNothing);
      expect(find.byType(ZyraDraftReportPresentation), findsNothing);
      _expectNoJourneyWrites();
      if (change == 'role') {
        expect(
          tester
              .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
              .items
              .map((item) => item.label),
          ['Dashboard', 'Network', 'Seekers', 'Profile'],
        );
      }
    });
  }

  testWidgets('blocked Ended peer retains a neutral archive without actions', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final current = owner();
    await current.mount(tester, model: _ended(blocked: true));
    final before = current.latest.model;
    expect(_key('concept_blocked_archive_$_sara'), findsOneWidget);
    expect(find.text('Sara'), findsNothing);
    expect(find.byType(ZyraOneJourneyConnectionsActiveCard), findsNothing);
    expect(find.byType(ZyraProfileImage), findsNothing);
    expect(_key('draft_journey_options_$_sara'), findsNothing);
    expect(_key('draft_restart_$_sara'), findsNothing);
    await _press(tester, _key('draft_journey_$_sara'));
    expect(_key('concept_user_not_found'), findsOneWidget);
    expect(find.text('Journey with Sara'), findsNothing);
    expect(find.byType(ZyraProfileImage), findsNothing);
    expect(_key('concept_archive_$_sara'), findsNothing);
    _expectSameModel(current, before);
  });

  for (final viewport in [
    (size: const Size(393, 852), scale: 1.0, suffix: '393'),
    (size: const Size(320, 568), scale: 2.0, suffix: '320_200'),
  ]) {
    testWidgets('Ended card options stay reachable at ${viewport.suffix}', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final current = owner();
      await current.mount(tester, size: viewport.size, scale: viewport.scale);
      final before = current.latest.model;
      await _capture(tester, 'ended_card_layout_${viewport.suffix}');
      await _press(tester, _key('draft_restart_$_sara'));
      expect(_key('draft_ended_restart_$_sara'), findsOneWidget);
      await returnZyraPreviewPage(tester);
      await _openOptions(tester);
      if (viewport.scale > 1) {
        // Ended retains the ordinary card's single reading scroll owner.
        // Its unbounded inline deck must not add a competing nested scroll.
        final owner = find.ancestor(
          of: _option(ZyraConceptJourneyOption.timeline),
          matching: find.byType(Scrollable),
        );
        expect(owner, findsWidgets);
        expect(
          tester
              .stateList<ScrollableState>(owner)
              .any((state) => state.position.maxScrollExtent > 0),
          isTrue,
        );
      }
      await _capture(tester, 'ended_options_layout_${viewport.suffix}');
      for (final choice in _options) {
        await _press(tester, _option(choice));
        expect(find.byType(ZyraConceptJourneyOptions), findsNothing);
        _expectSameModel(current, before);
        await returnZyraPreviewPage(tester);
        await _openOptions(tester);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
