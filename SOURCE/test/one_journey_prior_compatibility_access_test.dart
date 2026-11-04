import 'package:zyra/theme/zyra_app_gold_style.dart';
// Exercise the real protected shell with caller-owned, fictional access.
// These fixtures never read member data, private answers or a live ledger.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_compatibility_access_store.dart';
import 'package:zyra/dev/zyra_draft_compatibility_presentation.dart';
import 'package:zyra/dev/zyra_draft_journey_bio_presentation.dart';
import 'package:zyra/dev/zyra_one_journey_browse_designs.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_options.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

const _sara = 'draft-sara';
const _aisha = 'draft-aisha';
Finder _key(String id) => find.byKey(ValueKey(id));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Prior access integration fixtures must remain offline.');
  }
}

class _UiEpoch {
  bool current = true;
}

class _Owner {
  _Owner({this.initialBalance = 1});

  final int initialBalance;
  bool allowed = true;
  _UiEpoch? _epoch;
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];
  late final access = ZyraDraftCompatibilityAccessStore(
    canAct: () => allowed,
    balance: initialBalance,
  );

  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;
  ViewRequestDraftModel get model =>
      ViewRequestDraftModel.fromSnapshot(latest.model);

  Future<void> mount(
    WidgetTester tester, {
    ZyraPreviewNavigationCheckpoint? checkpoint,
    bool guardian = false,
  }) async {
    _epoch?.current = false;
    final epoch = _epoch = _UiEpoch();
    final ready = Completer<void>();
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
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
          fixture: ZyraShellTestFixture().fixture,
          key: UniqueKey(),
          canAct: () => allowed && epoch.current,
          onExit: () => fail('Access fixtures stay inside their local shell.'),
          initialGuardianRole: guardian,
          initialCheckpoint: checkpoint,
          compatibilityAccess: access,
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
    expect(ready.isCompleted, isTrue, reason: 'Actual bundled photos prepare');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(checkpoints, isNotEmpty);
  }

  void close() {
    _epoch?.current = false;
    access.close();
  }
}

ZyraPreviewNavigationCheckpoint _seed({
  ViewRequestDraftModel? model,
  int tab = 1,
  List<String> pages = const [],
  String? personId = _sara,
  bool guardian = false,
  int? compatibilityBalance,
  bool compatibilityRevealed = false,
}) => ZyraPreviewNavigationCheckpoint(
  guardian: guardian,
  model: (model ?? (ViewRequestDraftModel(capacity: 3)..seedJourneys(3)))
      .snapshot(),
  tab: tab,
  pages: pages,
  personId: personId,
  compatibilityBalance: compatibilityBalance,
  compatibilityRevealed: compatibilityRevealed,
);

Future<void> _press(WidgetTester tester, String id) async {
  if (await pressZyraDevControlKey(tester, id)) return;
  final target = _key(id);
  expect(target, findsOneWidget, reason: 'Actual action $id exists');
  if (find
      .ancestor(of: target, matching: find.byType(Scrollable))
      .evaluate()
      .isNotEmpty) {
    await Scrollable.ensureVisible(tester.element(target), alignment: .5);
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget, reason: '$id receives the tap');
  await tester.tap(target);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, int index) async {
  for (
    var depth = 0;
    find.byType(ZyraShellNavigation).evaluate().isEmpty && depth < 8;
    depth++
  ) {
    await returnZyraPreviewPage(tester);
  }
  expect(find.byType(ZyraShellNavigation), findsOneWidget);
  await expandZyraPreviewTabBarIfIdle(tester);
  final cell = _key('floating-nav-item-$index');
  expect(cell, findsOneWidget);
  // The whole bar owns touches; the icon cell intentionally ignores them.
  await tester.tapAt(tester.getCenter(cell));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  expect(
    tester
        .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
        .currentIndex,
    index,
  );
}

ZyraDraftCompatibilityPresentation _result(WidgetTester tester) =>
    tester.widget(find.byType(ZyraDraftCompatibilityPresentation));

Future<void> _openBrowseCompatibility(WidgetTester tester) async {
  expect(find.byType(ZyraOneJourneyBrowseDesigns), findsOneWidget);
  await _press(tester, 'concept_browse_menu');
  final menu = find.byType(ZyraShellNavigation);
  expect(menu, findsOneWidget);
  final navigation = tester.widget<ZyraShellNavigation>(menu);
  final item = navigation.items.firstWhere(
    (item) => item.label == 'Compatibility score',
  );
  final icon = find.descendant(of: menu, matching: find.byIcon(item.icon));
  expect(icon, findsOneWidget);
  await tester.tapAt(tester.getCenter(icon));
  await tester.pumpAndSettle();
  expect(find.byType(ZyraDraftCompatibilityPresentation), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> _openJourneyOption(
  WidgetTester tester,
  String option, {
  String person = _sara,
}) async {
  final target = _key('draft_options_${option}_$person');
  if (target.evaluate().isEmpty) {
    await _press(tester, 'draft_journey_options_$person');
  }
  await _press(tester, 'draft_options_${option}_$person');
}

void _expectNoBioData() {
  expect(find.byType(ZyraDraftJourneyBioPresentation), findsNothing);
  expect(_key('draft_journey_bio_about'), findsNothing);
  for (final id in ['occupation', 'education', 'future_children', 'home']) {
    expect(_key('draft_journey_bio_field_$id'), findsNothing);
  }
}

void _expectNoConsent(ViewRequestDraftModel model, [String person = _sara]) {
  expect(model.hasChosenCompatibilityReveal(person), isFalse);
  expect(model.peerHasChosenCompatibilityReveal(person), isFalse);
  expect(model.compatibilityRevealed(person), isFalse);
  expect(model.hasChosenBioReveal(person), isFalse);
  expect(model.peerHasChosenBioReveal(person), isFalse);
  expect(model.canViewJourneyBio(person), isFalse);
  expect(model.stageFor(person)?.value, 'salam_exchange');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;
  late bool oldFontStubs;
  late ZyraHapticLevel oldHaptics;
  final owners = <_Owner>[];

  _Owner owner({int balance = 1}) {
    final value = _Owner(initialBalance: balance);
    owners.add(value);
    return value;
  }

  setUp(() {
    oldFontStubs = ZyraText.useTestFontStubs;
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    AppState.instance.resetForAccountChange();
    ZyraAccountState.clearImagesForTesting = () async {};
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
    for (final value in owners) {
      value.close();
    }
    owners.clear();
    expect(network.attempts, 0);
    HttpOverrides.global = oldNetwork;
    ZyraText.useTestFontStubs = oldFontStubs;
    ZyraInteractionStyle.selectHapticLevel(oldHaptics);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets(
    'actual Profiles unlock survives request, mutual preparation and Journey menu without buying consent',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final current = owner();
      await current.mount(tester);
      await _openBrowseCompatibility(tester);
      expect(_result(tester).personName, 'Sara');
      await _press(tester, 'draft_compatibility_reveal');
      final saved = current.access.resultFor(_sara)!;
      expect(current.access.balance, 0);
      await returnZyraPreviewPage(tester);
      await _press(tester, 'draft_profile_$_sara');
      await _nav(tester, 2);
      await _press(tester, 'my-zyra-route-concept-my-requests');
      await _press(tester, 'draft_requests_1');
      await _press(tester, 'concept_request_${_sara}_header');
      await _press(tester, 'draft_recipient_$_sara');
      expect(current.model.stateFor(_sara), DraftJourneyState.preparing);
      await _press(tester, 'draft_ready_$_sara');
      await _press(tester, 'draft_peer_ready_$_sara');
      await _press(tester, 'draft_begin_$_sara');
      await _press(tester, 'draft_agree_guardian_access_$_sara');
      expect(current.model.stateFor(_sara), DraftJourneyState.active);
      _expectNoConsent(current.model);
      await _nav(tester, 1);
      await _openJourneyOption(tester, 'compatibility');
      expect(_result(tester).revealed, isTrue);
      expect(_result(tester).overallScore, saved.overallScore);
      expect(_result(tester).onUnlock, isNull);
      expect(find.text('${saved.overallScore}%'), findsOneWidget);
      expect(current.access.resultFor(_sara), same(saved));
      expect(current.access.balance, 0);
      _expectNoConsent(current.model);
      await returnZyraPreviewPage(tester);
      await _openJourneyOption(tester, 'bio');
      expect(_key('draft_journey_bio_waiting_$_sara'), findsOneWidget);
      expect(find.text('ACCESS ALREADY UNLOCKED'), findsOneWidget);
      _expectNoBioData();
      _expectNoConsent(current.model);
      expect(current.access.resultFor(_sara), same(saved));
      expect(current.access.balance, 0);
    },
  );

  testWidgets('unspent credits alone do not open either Journey destination', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final current = owner(balance: 5);
    await current.mount(tester, checkpoint: _seed());
    await _press(tester, 'draft_journey_options_$_sara');
    final menu = tester.widget<ZyraConceptJourneyOptions>(
      find.byType(ZyraConceptJourneyOptions),
    );
    expect(menu.canViewBio, isFalse);
    expect(menu.canViewCompatibility, isFalse);
    await _press(tester, 'draft_options_compatibility_$_sara');
    expect(_key('draft_journey_compatibility_locked_$_sara'), findsOneWidget);
    expect(find.byType(ZyraDraftCompatibilityPresentation), findsNothing);
    await returnZyraPreviewPage(tester);
    await _openJourneyOption(tester, 'bio');
    expect(_key('draft_bio_locked_$_sara'), findsOneWidget);
    _expectNoBioData();
    expect(current.access.balance, 5);
    expect(current.access.isUnlocked(_sara), isFalse);
    _expectNoConsent(current.model);
  });

  testWidgets('used access for Sara never opens Aisha or spends again', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final current = owner(balance: 5);
    expect(current.access.unlock(_sara), isTrue);
    await current.mount(tester, checkpoint: _seed());
    await _press(tester, 'draft_journey_options_$_aisha');
    final menu = tester.widget<ZyraConceptJourneyOptions>(
      find.byType(ZyraConceptJourneyOptions),
    );
    expect(menu.canViewBio, isFalse);
    expect(menu.canViewCompatibility, isFalse);
    await _press(tester, 'draft_options_compatibility_$_aisha');
    expect(_key('draft_journey_compatibility_locked_$_aisha'), findsOneWidget);
    expect(current.access.balance, 4);
    expect(current.access.isUnlocked(_sara), isTrue);
    expect(current.access.isUnlocked(_aisha), isFalse);
    _expectNoBioData();
    _expectNoConsent(current.model, _aisha);
  });

  for (final page in ['compatibility', 'journey_compatibility', 'bio']) {
    testWidgets('forged $page checkpoint is never an access grant', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final current = owner();
      await current.mount(
        tester,
        checkpoint: _seed(
          tab: page == 'compatibility' ? 0 : 1,
          pages: [page],
          compatibilityBalance: 0,
          compatibilityRevealed: true,
        ),
      );
      expect(current.access.balance, 1);
      expect(current.access.resultFor(_sara), isNull);
      expect(current.latest.compatibilityRevealed, isFalse);
      if (page == 'compatibility') {
        expect(_result(tester).revealed, isFalse);
        expect(_result(tester).onUnlock, isNotNull);
      } else {
        expect(current.latest.pages, isEmpty);
        expect(find.byType(ZyraDraftCompatibilityPresentation), findsNothing);
      }
      _expectNoBioData();
      _expectNoConsent(current.model);
    });
  }

  testWidgets('fresh child UI epoch keeps only the same external owner grant', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final current = owner();
    await current.mount(tester);
    await _openBrowseCompatibility(tester);
    final oldUnlock = _result(tester).onUnlock!;
    await _press(tester, 'draft_compatibility_reveal');
    final saved = current.access.resultFor(_sara)!;
    final checkpoint = current.latest;
    await current.mount(tester, checkpoint: checkpoint);
    expect(current.access.current, isTrue);
    expect(current.access.resultFor(_sara), same(saved));
    expect(_result(tester).revealed, isTrue);
    expect(_result(tester).onUnlock, isNull);
    expect(find.text('${saved.overallScore}%'), findsOneWidget);
    oldUnlock();
    await tester.pumpAndSettle();
    expect(current.access.balance, 0);
    expect(current.access.resultFor(_sara), same(saved));
    expect(current.latest.model.states, checkpoint.model.states);
  });

  testWidgets(
    'Guardian child rejects Seeker routes and retained menu callback',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final current = owner();
      expect(current.access.unlock(_sara), isTrue);
      await current.mount(tester, checkpoint: _seed());
      await _press(tester, 'draft_journey_options_$_sara');
      final oldMenu = tester.widget<ZyraConceptJourneyOptions>(
        find.byType(ZyraConceptJourneyOptions),
      );
      for (final page in ['compatibility', 'journey_compatibility', 'bio']) {
        await current.mount(
          tester,
          guardian: true,
          checkpoint: _seed(guardian: true, pages: [page]),
        );
        oldMenu.onSelected(ZyraConceptJourneyOption.compatibility);
        await tester.pumpAndSettle();
        expect(current.latest.guardian, isTrue);
        expect(current.latest.pages, isEmpty);
        expect(find.byType(ZyraDraftCompatibilityPresentation), findsNothing);
        _expectNoBioData();
        expect(current.access.isUnlocked(_sara), isTrue);
        expect(current.access.balance, 0);
      }
    },
  );

  testWidgets(
    'revoked owner cannot use a retained unlock or revive old access',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final current = owner(balance: 5);
      await current.mount(tester);
      await _openBrowseCompatibility(tester);
      final oldUnlock = _result(tester).onUnlock!;
      current.allowed = false;
      oldUnlock();
      await tester.pump();
      expect(current.access.current, isFalse);
      expect(current.access.resultFor(_sara), isNull);
      current.allowed = true;
      await current.mount(tester);
      await _openBrowseCompatibility(tester);
      expect(_result(tester).revealed, isFalse);
      expect(_result(tester).onUnlock, isNull);
      expect(current.access.balance, 0);
      expect(current.access.isUnlocked(_sara), isFalse);
      oldUnlock();
      await tester.pumpAndSettle();
      expect(current.access.resultFor(_sara), isNull);
    },
  );

  testWidgets('only explicit Reset preview clears a used local grant', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final current = owner();
    await current.mount(tester);
    await _openBrowseCompatibility(tester);
    await _press(tester, 'draft_compatibility_reveal');
    await returnZyraPreviewPage(tester);
    await _openBrowseCompatibility(tester);
    expect(_result(tester).revealed, isTrue);
    expect(current.access.balance, 0);
    await returnZyraPreviewPage(tester);
    await openZyraDevControls(tester);
    await _press(tester, 'draft_reset');
    expect(current.access.balance, 1);
    expect(current.access.resultFor(_sara), isNull);
    if (zyraShellFixtureFor(tester).setupScopeOpen) {
      await closeZyraDevControls(tester);
    }
    await _openBrowseCompatibility(tester);
    expect(_result(tester).revealed, isFalse);
    expect(_result(tester).balance, 1);
    expect(_result(tester).onUnlock, isNotNull);
  });
}
