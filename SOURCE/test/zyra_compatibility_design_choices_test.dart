// Actual protected shell, physical controls entry and caller-owned fictional
// access only. No member answers, SDK sessions, ledger, service or PNG I/O.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_draft_compatibility_access_store.dart';
import 'package:zyra/dev/zyra_draft_compatibility_presentation.dart';
import 'package:zyra/dev/zyra_draft_compatibility_score_designs.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
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
const _revealOptions = 'concept_compatibility_reveal_design';
const _scoreOptions = 'concept_compatibility_score_design';
Finder _key(String id) => find.byKey(ValueKey(id));

void _expectNoDesignControls() {
  expect(_key(_revealOptions), findsNothing);
  expect(_key(_scoreOptions), findsNothing);
  expect(find.text('Reveal action'), findsNothing);
  expect(find.text('Swipeable score pages'), findsNothing);
}

void _expectRequestHeading() {
  final page = find.byType(ZyraDraftCompatibilityPresentation);
  final presentation =
      page.evaluate().single.widget as ZyraDraftCompatibilityPresentation;
  expect(
    find.descendant(of: page, matching: find.text('Compatibility score')),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: page,
      matching: find.text('You and ${presentation.personName}'),
    ),
    presentation.revealed ? findsNothing : findsOneWidget,
  );
}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Fixed compatibility tests must stay offline.');
  }
}

class _Opening {
  bool current = true;
}

class _Owner {
  bool allowed = true;
  bool cleanupRegistered = false;
  _Opening? opening;
  final navigator = GlobalKey<NavigatorState>();
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];
  late final access = ZyraDraftCompatibilityAccessStore(
    canAct: () => allowed,
    balance: 5,
  );
  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;

  Future<void> mount(
    WidgetTester tester, {
    String person = _sara,
    bool guardian = false,
    List<String> pages = const ['compatibility'],
  }) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    if (!cleanupRegistered) {
      cleanupRegistered = true;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() async {
        opening?.current = false;
        await tester.pumpWidget(const SizedBox.shrink());
        await _flush(tester, frames: 2);
      });
    }
    opening?.current = false;
    final epoch = opening = _Opening();
    final ready = Completer<void>();
    final model = ViewRequestDraftModel(capacity: 3)..seedJourneys(3);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [ZyraDevControlsRouteObserver()],
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
            disableAnimations: true,
            accessibleNavigation: true,
          ),
          child: child!,
        ),
        home: ZyraOneJourneyConceptShell(
          key: UniqueKey(),
          canAct: () => allowed && epoch.current,
          onExit: () =>
              fail('The compatibility fixture must stay in its shell.'),
          compatibilityAccess: access,
          initialGuardianRole: guardian,
          initialCheckpoint: ZyraPreviewNavigationCheckpoint(
            guardian: guardian,
            model: model.snapshot(),
            tab: guardian ? 3 : 0,
            pages: pages,
            personId: person,
          ),
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
    expect(ready.isCompleted, isTrue, reason: 'Actual bundled photos prepared');
    await _flush(tester);
    expect(tester.takeException(), isNull);
    expect(checkpoints, isNotEmpty);
  }

  void close() {
    opening?.current = false;
    access.close();
  }
}

Future<void> _flush(WidgetTester tester, {int frames = 20}) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

ZyraDraftCompatibilityPresentation _result(WidgetTester tester) =>
    tester.widget(
      find.byType(ZyraDraftCompatibilityPresentation, skipOffstage: false),
    );

Future<void> _press(WidgetTester tester, String key) async {
  final target = _key(key);
  expect(target, findsOneWidget, reason: 'Actual action $key exists');
  await Scrollable.ensureVisible(tester.element(target), alignment: .5);
  await _flush(tester, frames: 2);
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await _flush(tester);
  expect(tester.takeException(), isNull);
}

Future<void> _controlsRoundTrip(WidgetTester tester) async {
  await openZyraDevControls(tester);
  _expectNoDesignControls();
  await closeZyraDevControls(tester);
  await _flush(tester);
}

int _page(WidgetTester tester) => tester
    .widget<PageView>(_key('draft_compatibility_score_pages'))
    .controller!
    .page!
    .round();

void _unchangedJourney(_Owner owner) {
  final model = ViewRequestDraftModel.fromSnapshot(owner.latest.model);
  expect(model.hasChosenCompatibilityReveal(_sara), isFalse);
  expect(model.peerHasChosenCompatibilityReveal(_sara), isFalse);
  expect(model.hasChosenBioReveal(_sara), isFalse);
  expect(model.peerHasChosenBioReveal(_sara), isFalse);
  expect(model.canViewJourneyBio(_sara), isFalse);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? priorNetwork;
  late _NoNetwork network;
  late bool priorStubs;
  late ZyraHapticLevel priorHaptics;
  final owners = <_Owner>[];
  _Owner owner() {
    final value = _Owner();
    owners.add(value);
    return value;
  }

  setUp(() {
    priorNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    priorStubs = ZyraText.useTestFontStubs;
    ZyraText.useTestFontStubs = true;
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
    priorHaptics = ZyraInteractionStyle.hapticLevel;
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.off);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });
  tearDown(() {
    for (final value in owners) {
      value.close();
    }
    owners.clear();
    expect(network.attempts, 0);
    HttpOverrides.global = priorNetwork;
    ZyraText.useTestFontStubs = priorStubs;
    ZyraInteractionStyle.selectHapticLevel(priorHaptics);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  testWidgets(
    'actual compatibility toggle has no design controls and locked reader stays absent',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final current = owner();
      await current.mount(tester);
      _expectRequestHeading();
      for (var opening = 0; opening < 2; opening++) {
        await _controlsRoundTrip(tester);
        expect(_key('draft_compatibility_score_reader'), findsNothing);
        expect(find.byType(ZyraCompatibilityScoreReader), findsNothing);
        expect(_result(tester).revealed, isFalse);
        expect(current.access.balance, 5);
        expect(current.access.isUnlocked(_sara), isFalse);
      }
      expect(current.access.balance, 5);
      expect(current.access.isUnlocked(_sara), isFalse);
      _unchangedJourney(current);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'reveal once and controls roundtrip preserve the selected score page and grant',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final current = owner();
      await current.mount(tester);
      final staleUnlock = _result(tester).onUnlock!;
      await _press(tester, 'draft_compatibility_reveal');
      staleUnlock();
      await _flush(tester);
      expect(current.access.balance, 4);
      final grant = current.access.resultFor(_sara)!;
      expect(_key('draft_compatibility_score_reader'), findsOneWidget);
      expect(find.byType(ZyraCompatibilityScoreReader), findsOneWidget);
      _expectRequestHeading();
      expect(_page(tester), 0);
      final pages = _key('draft_compatibility_score_pages');
      await tester.dragFrom(tester.getCenter(pages), const Offset(-250, 0));
      await _flush(tester);
      expect(_page(tester), 1);
      final controller = tester.widget<PageView>(pages).controller;
      await _controlsRoundTrip(tester);
      expect(_page(tester), 1);
      expect(tester.widget<PageView>(pages).controller, same(controller));
      expect(find.byType(ZyraCompatibilityScoreReader), findsOneWidget);
      expect(_key('draft_compatibility_actions'), findsNothing);
      expect(_result(tester).onUnlock, isNull);
      expect(_result(tester).personName, 'Sara');
      expect(current.access.resultFor(_sara), same(grant));
      expect(current.access.balance, 4);
      _unchangedJourney(current);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'closed and reopened controls cannot revive a retained Reveal action',
    (tester) async {
      final current = owner();
      await current.mount(tester);
      final stale = _result(tester).onUnlock!;
      await openZyraDevControls(tester);
      _expectNoDesignControls();
      stale();
      expect(current.access.balance, 5);
      expect(current.access.isUnlocked(_sara), isFalse);
      await closeZyraDevControls(tester);
      stale();
      await openZyraDevControls(tester);
      _expectNoDesignControls();
      stale();
      await _flush(tester);
      expect(current.access.balance, 5);
      expect(current.access.isUnlocked(_sara), isFalse);
      await closeZyraDevControls(tester);
      stale();
      await _flush(tester);
      expect(current.access.balance, 5);
      expect(_result(tester).revealed, isFalse);
      expect(_key('draft_compatibility_score_reader'), findsNothing);
      await _press(tester, 'draft_compatibility_reveal');
      stale();
      await _flush(tester);
      expect(current.access.balance, 4);
      expect(current.access.isUnlocked(_sara), isTrue);
      expect(_key('draft_compatibility_score_reader'), findsOneWidget);
      _unchangedJourney(current);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'cover-uncover route ABA retires old Reveal action but permits a fresh action',
    (tester) async {
      final current = owner();
      await current.mount(tester);
      final stale = _result(tester).onUnlock!;
      current.navigator.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Unrelated cover')),
        ),
      );
      await _flush(tester);
      stale();
      expect(find.text('Unrelated cover'), findsOneWidget);
      expect(current.access.balance, 5);
      expect(current.access.isUnlocked(_sara), isFalse);
      current.navigator.currentState!.pop();
      await _flush(tester);
      stale();
      expect(current.access.balance, 5);
      expect(current.access.isUnlocked(_sara), isFalse);
      expect(_result(tester).revealed, isFalse);
      expect(_key('draft_compatibility_score_reader'), findsNothing);
      await _press(tester, 'draft_compatibility_reveal');
      stale();
      await _flush(tester);
      expect(current.access.balance, 4);
      expect(current.access.isUnlocked(_sara), isTrue);
      expect(_key('draft_compatibility_score_reader'), findsOneWidget);
      _unchangedJourney(current);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final boundary in ['peer', 'role', 'authority', 'dispose']) {
    testWidgets('$boundary boundary denies captured Reveal callbacks', (
      tester,
    ) async {
      final current = owner();
      await current.mount(tester);
      final stale = _result(tester).onUnlock!;
      switch (boundary) {
        case 'peer':
          await current.mount(tester, person: _aisha);
        case 'role':
          await current.mount(tester, guardian: true);
          stale();
          await _flush(tester);
          expect(find.byType(ZyraDraftCompatibilityPresentation), findsNothing);
          await current.mount(tester, person: _aisha);
        case 'authority':
          current.allowed = false;
          current.opening!.current = false;
          stale();
          current.allowed = true;
          await current.mount(tester);
        case 'dispose':
          await tester.pumpWidget(const SizedBox.shrink());
          stale();
          await current.mount(tester);
      }
      stale();
      await _flush(tester);
      expect(_result(tester).revealed, isFalse);
      expect(_key('draft_compatibility_score_reader'), findsNothing);
      expect(current.access.balance, 5);
      expect(current.access.isUnlocked(_sara), isFalse);
      expect(current.access.isUnlocked(_aisha), isFalse);
      _unchangedJourney(current);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'Journey result keeps fixed Halo through controls without spending or Bio disclosure',
    (tester) async {
      final current = owner();
      expect(current.access.unlock(_sara), isTrue);
      await current.mount(tester, pages: const ['journey_compatibility']);
      expect(_result(tester).revealed, isTrue);
      expect(_result(tester).onUnlock, isNull);
      final grant = current.access.resultFor(_sara)!;
      final pages = _key('draft_compatibility_score_pages');
      await tester.dragFrom(tester.getCenter(pages), const Offset(-250, 0));
      await _flush(tester);
      expect(_page(tester), 1);
      await _controlsRoundTrip(tester);
      expect(_page(tester), 1);
      expect(_key('draft_compatibility_score_reader'), findsOneWidget);
      expect(find.byType(ZyraCompatibilityScoreReader), findsOneWidget);
      expect(_key('draft_compatibility_actions'), findsNothing);
      _expectRequestHeading();
      expect(current.access.resultFor(_sara), same(grant));
      expect(current.access.balance, 4);
      _unchangedJourney(current);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'center paging and first-page overscroll do not close; the 44px edge returns once',
    (tester) async {
      final current = owner();
      expect(current.access.unlock(_sara), isTrue);
      await current.mount(tester);
      final pages = _key('draft_compatibility_score_pages');
      await tester.dragFrom(tester.getCenter(pages), const Offset(220, 0));
      await _flush(tester);
      expect(_page(tester), 0);
      expect(find.byType(ZyraDraftCompatibilityPresentation), findsOneWidget);
      await tester.dragFrom(tester.getCenter(pages), const Offset(-250, 0));
      await _flush(tester);
      expect(_page(tester), 1);
      final edge = tester.getRect(_key('zyra_back_swipe_edge'));
      expect(edge.width, greaterThanOrEqualTo(44));
      await tester.dragFrom(
        Offset(edge.left + 3, edge.center.dy),
        const Offset(240, 0),
      );
      await _flush(tester);
      expect(find.byType(ZyraDraftCompatibilityPresentation), findsNothing);
      expect(find.byType(ZyraOneJourneyBrowseDesigns), findsOneWidget);
      expect(current.access.balance, 4);
      _unchangedJourney(current);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
