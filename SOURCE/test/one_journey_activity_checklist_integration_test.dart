// Exercise the admitted, actual preview host. Every activity is fictional;
// choosing a rehearsal must not manufacture requests, grants or messages.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_discovery_directions.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_draft_compatibility_access_store.dart';
import 'package:zyra/dev/zyra_my_zyra_activity_preview.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_my_zyra_navigation_card.dart';
import 'package:zyra/widgets/zyra_quiet_dashboard.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

Finder _key(String id) => find.byKey(ValueKey(id));

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Activity rehearsal must remain offline.');
  }
}

class _Owner {
  final navigator = GlobalKey<NavigatorState>();
  final observer = ZyraDevControlsRouteObserver();
  final checkpoints = <ZyraPreviewNavigationCheckpoint>[];
  late final access = ZyraDraftCompatibilityAccessStore(canAct: () => true);
  ZyraPreviewNavigationCheckpoint get latest => checkpoints.last;

  Future<void> mount(
    WidgetTester tester, {
    ViewRequestDraftModel? model,
    bool guardian = false,
    int tab = 2,
    List<String> pages = const [],
    Size size = const Size(393, 852),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    final ready = Completer<void>();
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
          child: child!,
        ),
        home: ViewRequestDraftScreen(
          key: UniqueKey(),
          ownerGeneration: ZyraAccountState.generation,
          ownerId: ZyraAccountState.userId,
          initialCheckpoint: ZyraPreviewNavigationCheckpoint(
            guardian: guardian,
            model: (model ?? ViewRequestDraftModel(capacity: 3)).snapshot(),
            tab: tab,
            pages: pages,
          ),
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
    expect(ready.isCompleted, isTrue, reason: 'Actual bundled portraits ready');
    await tester.pumpAndSettle();
    expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  }

  void close() {
    access.close();
    observer.dispose();
  }
}

Future<void> _press(WidgetTester tester, String id) async {
  final target = _key(id);
  if (target.evaluate().isEmpty) {
    final controls = _key('dev_controls_scroll');
    final source = controls.evaluate().isNotEmpty
        ? controls
        : _key('my-zyra-quiet-scroll-0');
    expect(source, findsOneWidget);
    await tester.scrollUntilVisible(
      target,
      160,
      scrollable: find.descendant(
        of: source,
        matching: find.byType(Scrollable),
      ),
    );
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
  var visible = tester
      .getRect(target)
      .intersect(
        Offset.zero & (tester.view.physicalSize / tester.view.devicePixelRatio),
      );
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
  final local = box.globalToLocal(visible.center);
  expect(
    target.hitTestable(
      at: Alignment(
        local.dx * 2 / box.size.width - 1,
        local.dy * 2 / box.size.height - 1,
      ),
    ),
    findsOneWidget,
  );
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _nav(WidgetTester tester, int index) async {
  await tester.tapAt(tester.getCenter(_key('floating-nav-item-$index')));
  await tester.pumpAndSettle();
  expect(
    tester
        .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
        .currentIndex,
    index,
  );
}

Future<void> _checklist(WidgetTester tester) async {
  await openZyraDevControls(tester);
  if (find.byType(ZyraMyZyraActivityChecklist).evaluate().isEmpty) {
    await _press(tester, 'concept_activity_checklist');
  }
  expect(find.byType(ZyraMyZyraActivityChecklist), findsOneWidget);
}

Future<void> _select(
  WidgetTester tester,
  ZyraMyZyraActivityExample example,
) async {
  await _checklist(tester);
  await _press(tester, 'activity-checklist-${example.name}');
  expect(_key('dev_controls_page'), findsNothing);
  expect(
    tester
        .widget<ZyraMyZyraActivityPreviewBar>(
          find.byType(ZyraMyZyraActivityPreviewBar),
        )
        .example,
    example,
  );
}

Map<String, Object?> _modelData(ViewRequestDraftSnapshot value) => {
  'capacity': value.capacity,
  'states': value.states,
  'saved': value.saved,
  'busy': value.busyPeers,
  'hidden': value.hiddenPeers,
  'blocked': value.blockedPeers,
  'acknowledged': value.acknowledgedReceivedRequestIds,
  'progress': value.progress,
  'peerMain': value.peerMainGuardianOverrides,
  'memberships': value.guardianMemberships,
  'permissions': value.guardianAccess,
  'requiredPaid': value.requiredPaidGuardianAccess,
  'ownMain': value.ownMainGuardianPresent,
  'otherMain': value.peerMainGuardianPresent,
};

List<Object?> _quickAccess(WidgetTester tester) => [
  for (final card
      in tester
          .widget<ZyraQuietDashboard>(find.byType(ZyraQuietDashboard))
          .fixtureCards
          .where((card) => ZyraMyZyraNavigationCard.isDestination(card.id)))
    (
      card.id,
      card.title,
      card.detail,
      card.actionLabel,
      card.target,
      card.hasNewActivity,
    ),
];

Future<void> _expectMountedQuickAccess(
  WidgetTester tester,
  List<Object?> expected,
) async {
  final scroll = find.descendant(
    of: _key('my-zyra-quiet-scroll-0'),
    matching: find.byType(Scrollable),
  );
  expect(scroll, findsOneWidget);
  for (final (index, id) in ZyraMyZyraNavigationCard.destinationIds.indexed) {
    final card = _key('my-zyra-item-$id');
    await tester.scrollUntilVisible(card, 160, scrollable: scroll);
    await tester.pumpAndSettle();
    final mounted = tester.widget<ZyraMyZyraNavigationCard>(
      find.ancestor(of: card, matching: find.byType(ZyraMyZyraNavigationCard)),
    );
    expect((
      mounted.card.id,
      mounted.card.title,
      mounted.card.detail,
      mounted.card.actionLabel,
      mounted.card.target,
      mounted.card.hasNewActivity,
    ), expected[index]);
    expect(_key('my-zyra-route-$id'), findsOneWidget);
  }
  tester.state<ScrollableState>(scroll).position.jumpTo(0);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final owners = <_Owner>[];
  late HttpOverrides? oldNetwork;
  late _NoNetwork network;
  late bool oldStubs;
  late ZyraHapticLevel oldHaptics;
  final oldFatal = WidgetController.hitTestWarningShouldBeFatal;
  _Owner owner() {
    final value = _Owner();
    owners.add(value);
    return value;
  }

  setUpAll(() => WidgetController.hitTestWarningShouldBeFatal = true);
  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraAccountState.clearImagesForTesting = () async {};
    AppState.instance.resetForAccountChange();
    final gold = ZyraDevAppGold.instance;
    gold.select(
      false,
      expectedGeneration: ZyraAccountState.generation,
      expectedRevision: gold.revision,
    );
    oldStubs = ZyraText.useTestFontStubs;
    ZyraText.useTestFontStubs = true;
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
    ZyraText.useTestFontStubs = oldStubs;
    ZyraInteractionStyle.selectHapticLevel(oldHaptics);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });
  tearDownAll(() => WidgetController.hitTestWarningShouldBeFatal = oldFatal);

  testWidgets('checklist belongs only to the Seeker My ZYRA root', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final current = owner();
    await current.mount(tester);
    await _checklist(tester);
    await closeZyraDevControls(tester);
    for (final tab in [0, 1, 3, 4]) {
      await _nav(tester, tab);
      await openZyraDevControls(tester);
      expect(_key('concept_activity_checklist'), findsNothing);
      expect(find.byType(ZyraMyZyraActivityChecklist), findsNothing);
      await closeZyraDevControls(tester);
    }
    await _nav(tester, 2);
    await _press(tester, 'my-zyra-route-concept-my-ended');
    await openZyraDevControls(tester);
    expect(_key('concept_activity_checklist'), findsNothing);
    await closeZyraDevControls(tester);
    await returnZyraPreviewPage(tester);
    await openZyraDevControls(tester);
    await _press(tester, 'draft_role_guardian');
    expect(current.latest.guardian, isTrue);
    await openZyraDevControls(tester);
    expect(_key('concept_activity_checklist'), findsNothing);
  });

  for (final viewport in [
    (size: const Size(393, 852), scale: 1.0),
    (size: const Size(320, 568), scale: 2.0),
  ]) {
    testWidgets('every activity steps and restores current at ${viewport.size} '
        '${viewport.scale}x without model or credit mutation', (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final current = owner();
      await current.mount(tester, size: viewport.size, scale: viewport.scale);
      expect(current.access.unlock('draft-sara'), isTrue);
      final result = current.access.resultFor('draft-sara');
      final before = _modelData(current.latest.model);
      final cards = _quickAccess(tester);
      expect(cards, hasLength(3));
      await _expectMountedQuickAccess(tester, cards);
      await _select(tester, ZyraMyZyraActivityExample.quiet);
      for (final example in ZyraMyZyraActivityExample.values) {
        final bar = tester.widget<ZyraMyZyraActivityPreviewBar>(
          find.byType(ZyraMyZyraActivityPreviewBar),
        );
        expect(bar.example, example);
        expect(_quickAccess(tester), cards);
        expect(_modelData(current.latest.model), before);
        expect(current.access.balance, 0);
        expect(current.access.resultFor('draft-sara'), same(result));
        expect(AppState.instance.activeJourneys, isEmpty);
        expect(_key('concept_message'), findsNothing);
        await _press(tester, 'activity-preview-next');
      }
      expect(
        tester
            .widget<ZyraMyZyraActivityPreviewBar>(
              find.byType(ZyraMyZyraActivityPreviewBar),
            )
            .example,
        ZyraMyZyraActivityExample.quiet,
      );
      await _press(tester, 'activity-preview-previous');
      expect(
        tester
            .widget<ZyraMyZyraActivityPreviewBar>(
              find.byType(ZyraMyZyraActivityPreviewBar),
            )
            .example,
        ZyraMyZyraActivityExample.circleMessage,
      );
      await _press(tester, 'activity-preview-checklist');
      expect(find.text('10 of 10 viewed'), findsOneWidget);
      await _press(tester, 'activity-checklist-current');
      expect(find.byType(ZyraMyZyraActivityPreviewBar), findsNothing);
      expect(find.text('Journey request from Amira'), findsOneWidget);
      expect(_quickAccess(tester), cards);
      expect(_modelData(current.latest.model), before);
      expect(current.access.resultFor('draft-sara'), same(result));
      await _expectMountedQuickAccess(tester, cards);
    });
  }

  testWidgets('samples without a real source are read-only; addressed request '
      'and circle use their existing routes', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final current = owner();
    await current.mount(tester);
    final before = _modelData(current.latest.model);
    for (final example in [
      ZyraMyZyraActivityExample.requestAccepted,
      ZyraMyZyraActivityExample.requestDeclined,
      ZyraMyZyraActivityExample.introductionReceived,
      ZyraMyZyraActivityExample.journeyReady,
      ZyraMyZyraActivityExample.journeyEnded,
      ZyraMyZyraActivityExample.guardianUpdate,
    ]) {
      await _select(tester, example);
      await _press(tester, 'my-zyra-route-${example.items.single.id}');
      expect(_key('activity-preview-detail'), findsOneWidget);
      expect(
        find.text(
          'No request, Journey, permission or notification '
          'has changed.',
        ),
        findsOneWidget,
      );
      expect(_modelData(current.latest.model), before);
      await returnZyraPreviewPage(tester);
    }
    await _select(tester, ZyraMyZyraActivityExample.requestReceived);
    await _press(
      tester,
      'my-zyra-route-${ZyraMyZyraActivityExample.requestReceived.items.single.id}',
    );
    expect(current.latest.pages.last, 'requests');
    expect(_key('activity-preview-detail'), findsNothing);
    await returnZyraPreviewPage(tester);
    final afterAcknowledgement = _modelData(current.latest.model);
    await _select(tester, ZyraMyZyraActivityExample.circleMessage);
    await _press(
      tester,
      'my-zyra-route-${ZyraMyZyraActivityExample.circleMessage.items.single.id}',
    );
    expect(current.latest.pages.last, 'guardian_circle');
    expect(_key('activity-preview-detail'), findsNothing);
    expect(_modelData(current.latest.model), afterAcknowledgement);
    expect(current.access.balance, 1);
  });

  testWidgets('captured selection and dashboard callbacks fail after controls, '
      'native route, role and reset changes', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final current = owner();
    await current.mount(tester);
    await _checklist(tester);
    final oldSelection = tester
        .widget<ZyraMyZyraActivityChecklist>(
          find.byType(ZyraMyZyraActivityChecklist),
        )
        .onSelected;
    await closeZyraDevControls(tester);
    oldSelection(ZyraMyZyraActivityExample.requestReceived);
    await tester.pumpAndSettle();
    expect(find.byType(ZyraMyZyraActivityPreviewBar), findsNothing);
    await _select(tester, ZyraMyZyraActivityExample.requestDeclined);
    final dashboard = tester.widget<ZyraQuietDashboard>(
      find.byType(ZyraQuietDashboard),
    );
    final staleNavigate = dashboard.onNavigate!;
    final sample = dashboard.fixtureCards.firstWhere(
      (card) =>
          card.id == ZyraMyZyraActivityExample.requestDeclined.items.single.id,
    );
    final oldNext = tester
        .widget<ZyraMyZyraActivityPreviewBar>(
          find.byType(ZyraMyZyraActivityPreviewBar),
        )
        .onNext;
    unawaited(
      current.navigator.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Native cover')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    staleNavigate(sample);
    oldNext();
    await tester.pumpAndSettle();
    expect(find.text('Native cover'), findsOneWidget);
    current.navigator.currentState!.pop();
    await tester.pumpAndSettle();
    staleNavigate(sample);
    oldNext();
    await tester.pumpAndSettle();
    expect(current.latest.pages, isEmpty);
    expect(
      tester
          .widget<ZyraMyZyraActivityPreviewBar>(
            find.byType(ZyraMyZyraActivityPreviewBar),
          )
          .example,
      ZyraMyZyraActivityExample.requestDeclined,
    );
    await openZyraDevControls(tester);
    await _press(tester, 'draft_role_guardian');
    oldSelection(ZyraMyZyraActivityExample.severalRequests);
    oldNext();
    staleNavigate(sample);
    await tester.pumpAndSettle();
    expect(current.latest.guardian, isTrue);
    expect(current.latest.pages, isEmpty);
    await openZyraDevControls(tester);
    await _press(tester, 'draft_role_seeker');
    await _nav(tester, 2);
    expect(find.byType(ZyraMyZyraActivityPreviewBar), findsNothing);
    await _select(tester, ZyraMyZyraActivityExample.journeyReady);
    final resetStale = tester
        .widget<ZyraMyZyraActivityPreviewBar>(
          find.byType(ZyraMyZyraActivityPreviewBar),
        )
        .onNext;
    await openZyraDevControls(tester);
    await _press(tester, 'draft_reset');
    resetStale();
    await tester.pumpAndSettle();
    await _nav(tester, 2);
    expect(find.byType(ZyraMyZyraActivityPreviewBar), findsNothing);
    await _checklist(tester);
    expect(find.text('0 of 10 viewed'), findsOneWidget);
    expect(AppState.instance.activeJourneys, isEmpty);
  });
}
