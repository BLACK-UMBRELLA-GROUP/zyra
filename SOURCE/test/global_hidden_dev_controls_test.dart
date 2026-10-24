import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;
import 'package:zyra/dev/dev_scenario_panel_v2.dart';
import 'package:zyra/dev/wali_dev_scenario_panel.dart';
import 'package:zyra/dev/zyra_concept_preview_boundary.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_dev_hold_to_open.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/dev/zyra_global_dev_overlay.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';

const _underlying = ValueKey('hidden-controls-underlying');
const _close = ValueKey('dev_controls_close');

Future<void> _mount(
  WidgetTester tester, {
  required GlobalKey<NavigatorState> navigatorKey,
  required ZyraDevControlsRouteObserver? routeObserver,
  TextEditingController? draft,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [?routeObserver],
      builder: (context, child) => ZyraGlobalDevOverlayHost(
        navigatorKey: navigatorKey,
        routeObserver: routeObserver,
        authStateChangesOverride: const Stream<AuthState>.empty(),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Unchanged member page', key: _underlying),
              if (draft != null)
                TextField(
                  key: const ValueKey('member_draft'),
                  controller: draft,
                ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<TestGesture> _beginHold(WidgetTester tester) =>
    tester.startGesture(tester.getCenter(find.byKey(_underlying)));

Future<void> _holdToOpen(WidgetTester tester) async {
  final hold = await _beginHold(tester);
  await tester.pump(const Duration(milliseconds: 2999));
  expect(find.byKey(_close), findsNothing);
  await tester.pump(const Duration(milliseconds: 1));
  await hold.up();
  await tester.pumpAndSettle();
  expect(find.byKey(_close), findsOneWidget);
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
  });

  tearDown(() {
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('public configuration mounts no developer hold detector', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final draft = TextEditingController(text: 'unchanged member draft');
    addTearDown(draft.dispose);
    await _mount(
      tester,
      navigatorKey: navigatorKey,
      routeObserver: null,
      draft: draft,
    );
    expect(find.byType(ZyraGlobalDevOverlayHost), findsOneWidget);
    expect(find.byType(ZyraDevHoldToOpen), findsNothing);
    expect(
      find.byKey(const ValueKey('dev_controls_hold_surface')),
      findsNothing,
    );
    final hold = await _beginHold(tester);
    await tester.pump(const Duration(seconds: 4));
    await hold.up();
    await tester.pumpAndSettle();
    expect(find.byKey(_close), findsNothing);
    expect(find.byKey(_underlying), findsOneWidget);
    expect(draft.text, 'unchanged member draft');
    expect(navigatorKey.currentState!.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final surface in ZyraDevSurface.values) {
    testWidgets(
      '$surface opens hidden page options and X restores member page',
      (tester) async {
        final coordinator = ZyraDevSurfaceCoordinator.instance;
        final owner = Object();
        if (surface == ZyraDevSurface.seeker) {
          coordinator.attachSeeker(owner, (DevPage _) {});
        } else if (surface == ZyraDevSurface.guardian) {
          coordinator.attachGuardian(owner, (WaliPage _) {});
        } else {
          coordinator.beginEntryFlow('Onboarding');
        }
        addTearDown(() {
          coordinator.detachSeeker(owner);
          coordinator.detachGuardian(owner);
          coordinator.endEntryFlow();
        });

        final navigatorKey = GlobalKey<NavigatorState>();
        final routeObserver = ZyraDevControlsRouteObserver();
        final draft = TextEditingController(text: 'unsent local draft');
        addTearDown(draft.dispose);
        await _mount(
          tester,
          navigatorKey: navigatorKey,
          routeObserver: routeObserver,
          draft: draft,
        );
        expect(find.byType(ZyraDevControlRail), findsNothing);
        expect(find.byKey(_close), findsNothing);
        final originalRevision = routeObserver.revision;

        await _holdToOpen(tester);
        expect(
          find.byKey(const ValueKey('dev_controls_tab_actions')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('dev_controls_tab_preview')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('dev_controls_tab_home')),
          findsOneWidget,
        );
        expect(find.byType(ZyraDevControlRail), findsNothing);
        expect(
          find.byType(switch (surface) {
            ZyraDevSurface.entry => ZyraEntryDevPanel,
            ZyraDevSurface.seeker => DevScenarioPanelV2,
            ZyraDevSurface.guardian => WaliDevScenarioPanel,
          }),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('dev_controls_tab_home')));
        await tester.pumpAndSettle();
        expect(find.text('Home'), findsWidgets);
        await tester.tap(
          find.byKey(const ValueKey('dev_controls_tab_preview')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(_close));
        await tester.pumpAndSettle();
        expect(find.byKey(_close), findsNothing);
        expect(find.byKey(_underlying), findsOneWidget);
        expect(draft.text, 'unsent local draft');
        expect(routeObserver.revision, originalRevision);
        expect(navigatorKey.currentState!.canPop(), isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('route ABA during hold cannot open controls after return', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final routeObserver = ZyraDevControlsRouteObserver();
    await _mount(
      tester,
      navigatorKey: navigatorKey,
      routeObserver: routeObserver,
    );
    final hold = await _beginHold(tester);
    await tester.pump(const Duration(seconds: 1));
    navigatorKey.currentState!.push<void>(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Covered route')),
      ),
    );
    await tester.pumpAndSettle();
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await hold.up();
    await tester.pumpAndSettle();
    expect(find.byKey(_close), findsNothing);
    await _holdToOpen(tester);
  });

  testWidgets('revocation and concept isolation suppress the hidden trigger', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final routeObserver = ZyraDevControlsRouteObserver();
    await _mount(
      tester,
      navigatorKey: navigatorKey,
      routeObserver: routeObserver,
    );
    final hold = await _beginHold(tester);
    await tester.pump(const Duration(seconds: 1));
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await hold.up();
    expect(find.byKey(_close), findsNothing);
    expect(find.byType(ZyraDevControlRail), findsNothing);

    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pumpAndSettle();
    final isolation = ZyraConceptPreviewIsolation.acquire();
    addTearDown(isolation.release);
    await tester.pumpAndSettle();
    final isolatedHold = await _beginHold(tester);
    await tester.pump(const Duration(seconds: 4));
    await isolatedHold.up();
    expect(find.byKey(_close), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('same-frame context ABA cannot complete a pending hold', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final routes = ZyraDevControlsRouteObserver();
    await _mount(tester, navigatorKey: navigatorKey, routeObserver: routes);
    final coordinator = ZyraDevSurfaceCoordinator.instance;
    final label = coordinator.entryLabel;
    final hold = await _beginHold(tester);
    await tester.pump(const Duration(seconds: 2));
    coordinator.beginEntryFlow('Temporary context');
    coordinator.endEntryFlow();
    expect(coordinator.entryLabel, label);
    // The timer fires before a deferred frame could replace the callbacks.
    await tester.pump(const Duration(seconds: 1));
    await hold.up();
    await tester.pumpAndSettle();
    expect(find.byKey(_close), findsNothing);
    await _holdToOpen(tester);
  });
}
