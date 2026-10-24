import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_scenario_panel_v2.dart';
import 'package:zyra/dev/wali_dev_scenario_panel.dart';
import 'package:zyra/dev/zyra_concept_preview_boundary.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_global_dev_overlay.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';

Finder _door(String name) => find.byKey(ValueKey('dev_rail_$name'));

void _expectNoRail() {
  for (final name in ['home', 'preview', 'actions']) {
    expect(_door(name), findsNothing);
  }
  expect(find.byType(ZyraDevControlRail), findsNothing);
}

void _expectControlsClosed() {
  _expectNoRail();
  expect(find.byKey(const ValueKey('dev_controls_page')), findsNothing);
  expect(find.byKey(const ValueKey('dev_controls_close')), findsNothing);
}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Concept boundary controls must remain offline.');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;

  setUp(() {
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    expect(ZyraConceptPreviewIsolation.active, isFalse);
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraText.useTestFontStubs = true;
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousNetwork;
    expect(ZyraConceptPreviewIsolation.active, isFalse);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraText.useTestFontStubs = false;
  });

  test('old lease cannot release a second owner or a replacement preview', () {
    final initialRevision = ZyraConceptPreviewIsolation.revision;
    final first = ZyraConceptPreviewIsolation.acquire();
    final second = ZyraConceptPreviewIsolation.acquire();
    addTearDown(first.release);
    addTearDown(second.release);
    expect(ZyraConceptPreviewIsolation.active, isTrue);
    expect(ZyraConceptPreviewIsolation.revision, initialRevision + 2);

    first.release();
    expect(ZyraConceptPreviewIsolation.active, isTrue);
    final revision = ZyraConceptPreviewIsolation.revision;
    first.release();
    expect(ZyraConceptPreviewIsolation.revision, revision);
    expect(ZyraConceptPreviewIsolation.active, isTrue);

    second.release();
    expect(ZyraConceptPreviewIsolation.active, isFalse);
    final replacement = ZyraConceptPreviewIsolation.acquire();
    addTearDown(replacement.release);
    final replacementRevision = ZyraConceptPreviewIsolation.revision;
    first.release();
    second.release();
    expect(ZyraConceptPreviewIsolation.active, isTrue);
    expect(ZyraConceptPreviewIsolation.revision, replacementRevision);
    replacement.release();
    expect(ZyraConceptPreviewIsolation.active, isFalse);
  });

  test('only acquire and exact first release notify monotonically', () {
    final revisions = <int>[];
    void changed() => revisions.add(ZyraConceptPreviewIsolation.revision);
    ZyraConceptPreviewIsolation.changes.addListener(changed);
    addTearDown(
      () => ZyraConceptPreviewIsolation.changes.removeListener(changed),
    );
    final initialRevision = ZyraConceptPreviewIsolation.revision;
    final lease = ZyraConceptPreviewIsolation.acquire();
    addTearDown(lease.release);
    lease.release();
    lease.release();
    expect(revisions, [initialRevision + 1, initialRevision + 2]);
    expect(ZyraConceptPreviewIsolation.active, isFalse);
  });

  testWidgets('boundary mount, replacement and disposal are frame-safe', (
    tester,
  ) async {
    Widget preview(String id) => MaterialApp(
      home: ZyraConceptPreviewBoundary(
        key: ValueKey(id),
        child: Scaffold(body: Text('Synthetic $id')),
      ),
    );
    final initialRevision = ZyraConceptPreviewIsolation.revision;
    await tester.pumpWidget(preview('first'));
    await tester.pumpAndSettle();
    expect(ZyraConceptPreviewIsolation.active, isTrue);
    expect(find.text('Synthetic first'), findsOneWidget);

    await tester.pumpWidget(preview('replacement'));
    await tester.pumpAndSettle();
    expect(ZyraConceptPreviewIsolation.active, isTrue);
    expect(find.text('Synthetic replacement'), findsOneWidget);
    expect(ZyraConceptPreviewIsolation.revision, initialRevision + 3);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(ZyraConceptPreviewIsolation.active, isFalse);
    expect(ZyraConceptPreviewIsolation.revision, initialRevision + 4);
    expect(tester.takeException(), isNull);
  });

  for (final surface in ZyraDevSurface.values) {
    testWidgets(
      '$surface ordinary controls hide and restore without rerouting',
      (tester) async {
        final coordinator = ZyraDevSurfaceCoordinator.instance;
        final registration = Object();
        var realDestinationCalls = 0;
        switch (surface) {
          case ZyraDevSurface.entry:
            break;
          case ZyraDevSurface.seeker:
            coordinator.attachSeeker(
              registration,
              (_) => realDestinationCalls++,
            );
            addTearDown(() => coordinator.detachSeeker(registration));
          case ZyraDevSurface.guardian:
            coordinator.attachGuardian(
              registration,
              (_) => realDestinationCalls++,
            );
            addTearDown(() => coordinator.detachGuardian(registration));
        }
        final navigatorKey = GlobalKey<NavigatorState>();
        final routeObserver = ZyraDevControlsRouteObserver();
        addTearDown(routeObserver.dispose);
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [routeObserver],
            builder: (context, child) => ZyraGlobalDevOverlayHost(
              navigatorKey: navigatorKey,
              routeObserver: routeObserver,
              child: child ?? const SizedBox.shrink(),
            ),
            home: const Scaffold(body: Text('Current ZYRA')),
          ),
        );
        await tester.pumpAndSettle();
        _expectControlsClosed();
        final underlyingRoute = ModalRoute.of(
          tester.element(find.text('Current ZYRA')),
        );
        expect(underlyingRoute, isNotNull);
        await openZyraDevControls(tester);
        _expectNoRail();
        expect(navigatorKey.currentState!.canPop(), isFalse);
        expect(realDestinationCalls, 0);

        navigatorKey.currentState!.push<void>(
          MaterialPageRoute(
            builder: (_) => const ZyraConceptPreviewBoundary(
              child: Scaffold(body: Text('One Journey synthetic shell')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('One Journey synthetic shell'), findsOneWidget);
        _expectControlsClosed();
        expect(find.byType(DevScenarioPanelV2), findsNothing);
        expect(find.byType(WaliDevScenarioPanel), findsNothing);
        expect(find.byType(ZyraEntryDevPanel), findsNothing);
        expect(ZyraConceptPreviewIsolation.active, isTrue);
        expect(realDestinationCalls, 0);
        final isolatedHold = await tester.startGesture(
          tester.getCenter(find.text('One Journey synthetic shell')),
        );
        await tester.pump(const Duration(seconds: 3));
        await isolatedHold.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        _expectControlsClosed();
        expect(find.text('One Journey synthetic shell'), findsOneWidget);
        expect(realDestinationCalls, 0);

        navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();
        expect(find.text('Current ZYRA'), findsOneWidget);
        expect(navigatorKey.currentState!.canPop(), isFalse);
        expect(ZyraConceptPreviewIsolation.active, isFalse);
        expect(coordinator.surface, surface);
        _expectControlsClosed();
        expect(
          ModalRoute.of(tester.element(find.text('Current ZYRA'))),
          same(underlyingRoute),
        );
        // Release restores eligibility, not a permanently visible control or
        // the old open panel. A new real hold owns the next presentation.
        await openZyraDevControls(tester);
        _expectNoRail();
        await closeZyraDevControls(tester);
        expect(find.text('Current ZYRA'), findsOneWidget);
        expect(
          ModalRoute.of(tester.element(find.text('Current ZYRA'))),
          same(underlyingRoute),
        );
        expect(navigatorKey.currentState!.canPop(), isFalse);
        _expectControlsClosed();
        expect(realDestinationCalls, 0);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }

  testWidgets('release cannot restore controls after authority loss', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final routeObserver = ZyraDevControlsRouteObserver();
    addTearDown(routeObserver.dispose);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [routeObserver],
        builder: (context, child) => ZyraGlobalDevOverlayHost(
          navigatorKey: navigatorKey,
          routeObserver: routeObserver,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Scaffold(body: Text('Current ZYRA')),
      ),
    );
    await tester.pumpAndSettle();
    _expectControlsClosed();
    await openZyraDevControls(tester);
    _expectNoRail();
    final lease = ZyraConceptPreviewIsolation.acquire();
    addTearDown(lease.release);
    await tester.pumpAndSettle();
    _expectControlsClosed();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    lease.release();
    await tester.pumpAndSettle();
    expect(ZyraConceptPreviewIsolation.active, isFalse);
    expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
    _expectControlsClosed();
    expect(find.text('Current ZYRA'), findsOneWidget);
    final deniedHold = await tester.startGesture(
      tester.getCenter(find.text('Current ZYRA')),
    );
    await tester.pump(const Duration(seconds: 3));
    await deniedHold.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    _expectControlsClosed();
    expect(find.text('Current ZYRA'), findsOneWidget);
    expect(navigatorKey.currentState!.canPop(), isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
