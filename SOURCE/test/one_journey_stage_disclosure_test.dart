// Actual protected local shell, detached fictional state and bundled photos.
// No member-data adapter, backend client or disclosure authority is injected.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_draft_compatibility_presentation.dart';
import 'package:zyra/dev/zyra_draft_journey_bio_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_journey_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _sara = 'draft-sara';
const _aisha = 'draft-aisha';
const _sharedFields = ['occupation', 'education', 'future_children', 'home'];
const _pendingResultCopy =
    'You both chose to reveal. Your result is not available yet.';
const _captureDirectory = String.fromEnvironment(
  'ZYRA_JOURNEY_BIO_FLOW_CAPTURE_DIR',
);
const _captureFont = 'PoppinsJourneyBioFlow';
const _captureKey = ValueKey('journey-bio-flow-capture');

Finder _key(String value) => find.byKey(ValueKey(value));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Stage disclosure fixtures must remain offline.');
  }
}

ViewRequestDraftModel _active() =>
    ViewRequestDraftModel(capacity: 3)..seedJourneys(3);

void _reachCompatibility(ViewRequestDraftModel model, [String id = _sara]) {
  expect(model.sendSalam(id), isTrue);
  expect(model.simulatePeerSalam(id), isTrue);
  expect(model.chooseStageContinue(id), isTrue);
  expect(model.simulatePeerStageContinue(id), isTrue);
  expect(model.advanceStage(id), isTrue);
}

void _readyCompatibility(ViewRequestDraftModel model, [String id = _sara]) {
  expect(model.chooseCompatibilityReveal(id), isTrue);
  expect(model.simulatePeerCompatibilityReveal(id), isTrue);
  expect(model.chooseStageContinue(id), isTrue);
  expect(model.simulatePeerStageContinue(id), isTrue);
}

void _openBio(ViewRequestDraftModel model, [String id = _sara]) {
  _reachCompatibility(model, id);
  _readyCompatibility(model, id);
  expect(model.beginBioStep(id), isTrue);
}

void _completeBio(ViewRequestDraftModel model, [String id = _sara]) {
  _openBio(model, id);
  expect(model.chooseBioReveal(id), isTrue);
  expect(model.simulatePeerBioReveal(id), isTrue);
  expect(model.chooseBioContinue(id), isTrue);
  expect(model.simulatePeerBioContinue(id), isTrue);
  expect(model.completeBioStep(id), isTrue);
}

ZyraPreviewNavigationCheckpoint _seed(
  ViewRequestDraftModel model, {
  List<String> pages = const [],
  String? personId = _sara,
  bool guardian = false,
}) => ZyraPreviewNavigationCheckpoint(
  guardian: guardian,
  model: model.snapshot(),
  tab: 1,
  pages: pages,
  personId: personId,
);

Future<void> _flush(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
  expect(tester.takeException(), isNull);
}

class _Owner {
  bool allowed = true;
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];

  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;
  ViewRequestDraftModel get model =>
      ViewRequestDraftModel.fromSnapshot(latest.model);

  Future<void> mount(
    WidgetTester tester,
    ZyraPreviewNavigationCheckpoint checkpoint, {
    Size size = const Size(393, 852),
    double textScale = 1,
    bool guardian = false,
  }) async {
    final ready = Completer<void>();
    tester.view.physicalSize = size;
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
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: RepaintBoundary(key: _captureKey, child: child!),
        ),
        home: ZyraOneJourneyConceptShell(
          key: UniqueKey(),
          canAct: () => allowed,
          onExit: () =>
              fail('Disclosure tests must stay in their local shell.'),
          initialCheckpoint: checkpoint,
          initialGuardianRole: guardian,
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
    expect(ready.isCompleted, isTrue, reason: 'Actual offline photos prepare');
    await _flush(tester);
    expect(checkpoints, isNotEmpty);
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captureDirectory/$name.png');
    await file.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.writeAsBytes(data!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

Future<void> _tap(WidgetTester tester, String id) async {
  if (await pressZyraDevControlKey(tester, id)) return;
  final target = _key(id);
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

Future<void> _local(WidgetTester tester, String id) async {
  final pages = _key('concept_current_journey_pages');
  if (pages.evaluate().isNotEmpty) {
    final stage = tester
        .widget<ZyraConceptJourneyPresentation>(
          find.byType(ZyraConceptJourneyPresentation),
        )
        .stage;
    final pager = tester.widget<PageView>(pages).controller!;
    if (pager.page! <= stage.order - 1) {
      await tester.drag(pages, Offset(0, -tester.getSize(pages).height * .8));
      await _flush(tester);
    }
  }
  await _tap(tester, id);
}

void _expectNoBioContent() {
  expect(find.byType(ZyraDraftJourneyBioPresentation), findsNothing);
  expect(_key('draft_journey_bio_about'), findsNothing);
  for (final field in _sharedFields) {
    expect(_key('draft_journey_bio_field_$field'), findsNothing);
  }
}

void _expectNoCompatibilityContent() {
  expect(find.byType(ZyraDraftCompatibilityPresentation), findsNothing);
  expect(find.text('COMPATIBILITY REVEAL COMPLETE'), findsNothing);
  expect(find.text(_pendingResultCopy), findsNothing);
}

void _expectSharedBio(WidgetTester tester, String id) {
  final readers = find.byType(ZyraDraftJourneyBioPresentation);
  expect(readers, findsOneWidget);
  final reader = tester.widget<ZyraDraftJourneyBioPresentation>(readers);
  expect(reader.subjectId, id);
  expect(reader.projection?.subjectId, id);
  expect(reader.projection?.fields.map((field) => field.id), _sharedFields);
  expect(_key('draft_journey_bio_about'), findsOneWidget);
  for (final field in _sharedFields) {
    expect(_key('draft_journey_bio_field_$field'), findsOneWidget);
  }
  expect(_key('draft_journey_bio_unavailable'), findsNothing);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;
  late bool oldFontStubs;
  String? oldReadingFont;
  late ZyraHapticLevel oldHaptics;

  setUpAll(() async {
    if (_captureDirectory.isEmpty) return;
    if (!_captureDirectory.startsWith('/') ||
        !Directory(_captureDirectory).existsSync()) {
      throw StateError(
        'Bio-flow captures need an existing absolute directory.',
      );
    }
    final reading = FontLoader(_captureFont);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium']) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });

  setUp(() {
    oldFontStubs = ZyraText.useTestFontStubs;
    oldReadingFont = ZyraText.testReadingFontFamily;
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _captureDirectory.isEmpty
        ? null
        : _captureFont;
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
    ZyraText.testReadingFontFamily = oldReadingFont;
    ZyraInteractionStyle.selectHapticLevel(oldHaptics);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final option in ['bio', 'compatibility']) {
    testWidgets(
      'early $option menu is locked and explains the uncompleted step',
      (tester) async {
        final owner = _Owner();
        await owner.mount(tester, _seed(_active()));
        await _tap(tester, 'draft_journey_options_$_sara');
        final menu = tester.widget<ZyraConceptJourneyOptions>(
          find.byType(ZyraConceptJourneyOptions),
        );
        expect(menu.canViewBio, isFalse);
        expect(menu.canViewCompatibility, isFalse);
        expect(_key('draft_options_${option}_locked_$_sara'), findsOneWidget);
        await _tap(tester, 'draft_options_${option}_$_sara');
        final page = option == 'bio' ? 'bio' : 'journey_compatibility';
        expect(_key('draft_${page}_locked_$_sara'), findsOneWidget);
        expect(owner.latest.pages, ['${page}_locked']);
        expect(
          find.text(
            option == 'bio'
                ? 'Complete Journey Bio together to view it here.'
                : 'Complete Compatibility Reveal together to view your result.',
          ),
          findsOneWidget,
        );
        final explanation = find.text(
          option == 'bio'
              ? 'Complete Journey Bio together to view it here.'
              : 'Complete Compatibility Reveal together to view your result.',
        );
        final explanationBounds = tester.getRect(explanation);
        expect(explanationBounds.left, greaterThanOrEqualTo(40));
        expect(
          explanationBounds.right,
          lessThanOrEqualTo(tester.view.physicalSize.width - 40),
          reason:
              'The completion explanation stays clear of the developer rail.',
        );
        _expectNoBioContent();
        _expectNoCompatibilityContent();
        await _capture(tester, 'locked_$option');
        await _tap(tester, 'draft_disclosure_continue_$_sara');
        expect(owner.latest.pages.last, 'journey');
        expect(owner.latest.personId, _sara);
        expect(owner.model.stageFor(_sara)?.value, 'salam_exchange');
      },
    );
  }

  testWidgets(
    'completed Compatibility enters separate Bio sharing and completion through actual controls',
    (tester) async {
      final model = _active();
      _reachCompatibility(model);
      _readyCompatibility(model);
      final owner = _Owner();
      await owner.mount(tester, _seed(model, pages: ['journey']));
      await _local(tester, 'draft_stage_next_$_sara');
      expect(_key('draft_journey_bio_step_$_sara'), findsOneWidget);
      expect(owner.model.stageFor(_sara)?.value, 'compatibility_reveal');
      expect(owner.model.hasCompletedCompatibilityStep(_sara), isTrue);
      expect(owner.model.canViewJourneyCompatibility(_sara), isTrue);
      _expectNoBioContent();
      await _tap(tester, 'draft_bio_reveal_$_sara');
      expect(owner.model.hasChosenBioReveal(_sara), isTrue);
      expect(owner.model.peerHasChosenBioReveal(_sara), isFalse);
      _expectNoBioContent();
      await _tap(tester, 'draft_back');
      await _tap(tester, 'draft_peer_bio_reveal_$_sara');
      expect(owner.model.bioRevealed(_sara), isTrue);
      expect(owner.model.canViewJourneyBio(_sara), isFalse);
      await _tap(tester, 'draft_back');
      _expectSharedBio(tester, _sara);
      await _capture(tester, 'bio_step_mutually_shared');
      await _tap(tester, 'draft_bio_continue_$_sara');
      expect(owner.model.hasChosenBioContinue(_sara), isTrue);
      expect(owner.model.peerHasChosenBioContinue(_sara), isFalse);
      expect(owner.model.canViewJourneyBio(_sara), isFalse);
      expect(find.text('Waiting for Sara to continue.'), findsOneWidget);
      await _tap(tester, 'draft_back');
      await _tap(tester, 'draft_peer_bio_ready_$_sara');
      await _tap(tester, 'draft_back');
      await _tap(tester, 'draft_bio_continue_$_sara');
      expect(owner.model.stageFor(_sara)?.value, 'wali_gate');
      expect(owner.model.canViewJourneyBio(_sara), isTrue);
      expect(_key('draft_journey_bio_step_$_sara'), findsNothing);
      // A fresh owner restores the completed reader, not the substep controls.
      await owner.mount(tester, _seed(owner.model, pages: ['bio']));
      _expectSharedBio(tester, _sara);
      expect(_key('draft_bio_reveal_$_sara'), findsNothing);
      expect(_key('draft_bio_continue_$_sara'), findsNothing);
    },
  );

  for (final partial in [
    'neither',
    'one Compatibility reveal',
    'both Compatibility reveals',
    'Bio shared but unfinished',
  ]) {
    testWidgets(
      '$partial checkpoint never restores a completed disclosure reader',
      (tester) async {
        final model = _active();
        _reachCompatibility(model);
        if (partial != 'neither') {
          expect(model.chooseCompatibilityReveal(_sara), isTrue);
        }
        if (partial == 'both Compatibility reveals' ||
            partial == 'Bio shared but unfinished') {
          expect(model.simulatePeerCompatibilityReveal(_sara), isTrue);
        }
        if (partial == 'Bio shared but unfinished') {
          expect(model.chooseStageContinue(_sara), isTrue);
          expect(model.simulatePeerStageContinue(_sara), isTrue);
          expect(model.beginBioStep(_sara), isTrue);
          expect(model.chooseBioReveal(_sara), isTrue);
          expect(model.simulatePeerBioReveal(_sara), isTrue);
        }
        final owner = _Owner();
        for (final page in [
          'bio',
          if (partial != 'Bio shared but unfinished') 'journey_compatibility',
        ]) {
          await owner.mount(tester, _seed(model, pages: [page]));
          expect(owner.latest.pages, isEmpty);
          _expectNoBioContent();
          _expectNoCompatibilityContent();
          expect(owner.latest.model.progress, model.snapshot().progress);
        }
      },
    );
  }

  testWidgets(
    'an unfinished shared Bio may resume its in-stage view but not its menu reader',
    (tester) async {
      final model = _active();
      _openBio(model);
      expect(model.chooseBioReveal(_sara), isTrue);
      expect(model.simulatePeerBioReveal(_sara), isTrue);
      final owner = _Owner();
      await owner.mount(tester, _seed(model, pages: ['journey']));
      _expectSharedBio(tester, _sara);
      expect(_key('draft_journey_bio_step_$_sara'), findsOneWidget);
      expect(owner.model.canViewJourneyBio(_sara), isFalse);
      await owner.mount(tester, _seed(owner.model));
      await _tap(tester, 'draft_journey_options_$_sara');
      expect(_key('draft_options_bio_locked_$_sara'), findsOneWidget);
      expect(_key('draft_options_compatibility_locked_$_sara'), findsNothing);
      await _tap(tester, 'draft_options_bio_$_sara');
      expect(_key('draft_bio_locked_$_sara'), findsOneWidget);
      _expectNoBioContent();
    },
  );

  testWidgets(
    'completed Bio and Compatibility checkpoints restore only their addressed subject',
    (tester) async {
      final model = _active();
      _completeBio(model);
      final owner = _Owner();
      for (final page in ['bio', 'journey_compatibility']) {
        await owner.mount(tester, _seed(model, pages: [page]));
        final captured = owner.latest;
        await owner.mount(tester, captured);
        expect(owner.latest.pages, [page]);
        expect(owner.latest.personId, _sara);
        if (page == 'bio') {
          _expectSharedBio(tester, _sara);
        } else {
          expect(find.text('Compatibility score'), findsOneWidget);
          expect(find.text('COMPATIBILITY REVEAL COMPLETE'), findsOneWidget);
          expect(find.byType(ZyraDraftCompatibilityPresentation), findsNothing);
          expect(find.text('Your result is not available yet.'), findsNothing);
          expect(find.text(_pendingResultCopy), findsOneWidget);
          _expectNoBioContent();
        }
        await owner.mount(
          tester,
          _seed(model, pages: [page], personId: _aisha),
        );
        expect(owner.latest.pages, isEmpty);
        _expectNoBioContent();
        _expectNoCompatibilityContent();
        expect(owner.model.canViewJourneyBio(_sara), isTrue);
        expect(owner.model.canViewJourneyBio(_aisha), isFalse);
      }
    },
  );

  for (final restriction in ['blocked', 'paused', 'ended', 'missing Main']) {
    testWidgets(
      '$restriction prevents completed-reader checkpoint restoration',
      (tester) async {
        final model = _active();
        _completeBio(model);
        switch (restriction) {
          case 'blocked':
            expect(model.block(_sara), isTrue);
          case 'paused':
            expect(model.requestPause(_sara), isTrue);
            expect(model.agreePause(_sara), isTrue);
          case 'ended':
            expect(model.end(_sara), isTrue);
          case 'missing Main':
            expect(model.setPeerMainGuardianPresent(false, id: _sara), isTrue);
        }
        final owner = _Owner();
        for (final page in ['bio', 'journey_compatibility']) {
          await owner.mount(tester, _seed(model, pages: [page]));
          expect(owner.latest.pages, isEmpty);
          _expectNoBioContent();
          _expectNoCompatibilityContent();
          expect(owner.model.bioRevealed(_sara), isTrue);
          expect(owner.model.canViewJourneyBio(_sara), isFalse);
        }
      },
    );
  }

  testWidgets(
    'Guardian role cannot restore completed Seeker disclosure routes',
    (tester) async {
      final model = _active();
      _completeBio(model);
      final owner = _Owner();
      for (final page in ['bio', 'journey_compatibility', 'journey']) {
        await owner.mount(
          tester,
          _seed(model, pages: [page], guardian: true),
          guardian: true,
        );
        expect(owner.latest.guardian, isTrue);
        expect(owner.latest.pages, isEmpty);
        _expectNoBioContent();
        _expectNoCompatibilityContent();
        expect(_key('draft_journey_bio_step_$_sara'), findsNothing);
      }
    },
  );

  for (final option in ['bio', 'compatibility']) {
    testWidgets(
      '320 by 568 double text keeps locked $option readable and its continuation reachable',
      (tester) async {
        final owner = _Owner();
        await owner.mount(
          tester,
          _seed(_active()),
          size: const Size(320, 568),
          textScale: 2,
        );
        await _tap(tester, 'draft_journey_options_$_sara');
        await _tap(tester, 'draft_options_${option}_$_sara');
        final page = option == 'bio' ? 'bio' : 'journey_compatibility';
        final locked = _key('draft_${page}_locked_$_sara');
        expect(locked, findsOneWidget);
        expect(MediaQuery.textScalerOf(tester.element(locked)).scale(1), 2);
        final scrollable = find.descendant(
          of: locked,
          matching: find.byType(Scrollable),
        );
        expect(scrollable, findsOneWidget);
        final state = tester.state<ScrollableState>(scrollable);
        expect(state.position.viewportDimension, greaterThan(0));
        expect(state.position.maxScrollExtent, greaterThanOrEqualTo(0));
        _expectNoBioContent();
        await _tap(tester, 'draft_disclosure_continue_$_sara');
        expect(owner.latest.pages.last, 'journey');
        expect(owner.model.stageFor(_sara)?.value, 'salam_exchange');
        expect(owner.model.hasCompletedCompatibilityStep(_sara), isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    '320 by 568 double text scrolls a revealed Bio substep to its real Continue action',
    (tester) async {
      final model = _active();
      _openBio(model);
      expect(model.chooseBioReveal(_sara), isTrue);
      expect(model.simulatePeerBioReveal(_sara), isTrue);
      final owner = _Owner();
      await owner.mount(
        tester,
        _seed(model, pages: ['journey']),
        size: const Size(320, 568),
        textScale: 2,
      );
      _expectSharedBio(tester, _sara);
      final step = _key('draft_journey_bio_step_$_sara');
      expect(MediaQuery.textScalerOf(tester.element(step)).scale(1), 2);
      final scrollable = find.descendant(
        of: step,
        matching: find.byType(Scrollable),
      );
      expect(scrollable, findsOneWidget);
      final state = tester.state<ScrollableState>(scrollable);
      expect(state.position.maxScrollExtent, greaterThan(0));
      await tester.drag(
        find.descendant(of: step, matching: find.byType(SingleChildScrollView)),
        const Offset(0, -300),
      );
      await _flush(tester);
      expect(state.position.pixels, greaterThan(0));
      await _tap(tester, 'draft_bio_continue_$_sara');
      expect(owner.model.hasChosenBioContinue(_sara), isTrue);
      expect(owner.model.peerHasChosenBioContinue(_sara), isFalse);
      expect(owner.model.canViewJourneyBio(_sara), isFalse);
      expect(owner.model.stageFor(_sara)?.value, 'compatibility_reveal');
      expect(tester.takeException(), isNull);
    },
  );

  for (final action in ['reveal', 'continue']) {
    testWidgets('captured Bio $action button cannot mutate a revoked owner', (
      tester,
    ) async {
      final model = _active();
      _openBio(model);
      if (action == 'continue') {
        expect(model.chooseBioReveal(_sara), isTrue);
        expect(model.simulatePeerBioReveal(_sara), isTrue);
      }
      final owner = _Owner();
      await owner.mount(tester, _seed(model, pages: ['journey']));
      final button = _key('draft_bio_${action}_$_sara');
      expect(button, findsOneWidget);
      final savedHandler = tester.widget<OutlinedButton>(button).onPressed;
      expect(savedHandler, isNotNull);
      final invokeSaved = savedHandler!;
      final before = owner.latest;
      owner.allowed = false;
      invokeSaved();
      await _flush(tester);
      expect(owner.latest.model.progress, before.model.progress);
      expect(owner.latest.model.states, before.model.states);
      expect(owner.latest.pages, before.pages);
      expect(owner.latest.personId, before.personId);
      expect(owner.model.hasChosenBioContinue(_sara), isFalse);
      expect(owner.model.canViewJourneyBio(_sara), isFalse);
      if (action == 'reveal') {
        expect(owner.model.hasChosenBioReveal(_sara), isFalse);
        expect(owner.model.peerHasChosenBioReveal(_sara), isFalse);
      }
      // Disposing the old widget does not revive the retained handler either.
      await tester.pumpWidget(const SizedBox.shrink());
      invokeSaved();
      await _flush(tester);
      expect(owner.latest.model.progress, before.model.progress);
    });
  }

  for (final option in ['profile', 'report']) {
    testWidgets(
      'early locked disclosures do not remove essential $option access',
      (tester) async {
        final owner = _Owner();
        await owner.mount(tester, _seed(_active()));
        await _tap(tester, 'draft_journey_options_$_sara');
        expect(_key('draft_options_bio_locked_$_sara'), findsOneWidget);
        expect(
          _key('draft_options_compatibility_locked_$_sara'),
          findsOneWidget,
        );
        await _tap(tester, 'draft_options_${option}_$_sara');
        expect(owner.latest.personId, _sara);
        expect(owner.latest.pages, [
          option == 'profile' ? 'profile' : 'safety',
        ]);
        if (option == 'profile') {
          final profile = tester.widget<ZyraOneJourneyBrowsePresentation>(
            find.byType(ZyraOneJourneyBrowsePresentation),
          );
          expect(profile.profile.id, _sara);
        } else {
          expect(find.text('Report profile'), findsOneWidget);
        }
        _expectNoBioContent();
        expect(owner.model.hasCompletedCompatibilityStep(_sara), isFalse);
      },
    );
  }
}
