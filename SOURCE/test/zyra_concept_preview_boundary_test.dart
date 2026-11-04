import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_concept_preview_boundary.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/widgets/zyra_account_session_host.dart';

Finder _door(String name) => find.byKey(ValueKey('dev_rail_$name'));

void _expectNoRail() {
  for (final name in ['home', 'preview', 'actions']) {
    expect(_door(name), findsNothing);
  }
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
    ZyraText.useTestFontStubs = true;
  });

  tearDown(() {
    expect(network.attempts, 0);
    HttpOverrides.global = previousNetwork;
    expect(ZyraConceptPreviewIsolation.active, isFalse);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
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

  for (final (surface, role) in <(String, String?)>[
    ('entry', null),
    ('seeker', 'seeker'),
    ('guardian', 'wali'),
  ]) {
    testWidgets(
      '$surface isolation retains member route ownership without restoring developer controls',
      (tester) async {
        ZyraLocalPrefs.setCachedRole(role);
        final generation = ZyraAccountState.generation;
        final navigatorKey = GlobalKey<NavigatorState>();
        final routeObserver = ZyraPreviewRouteObserver();
        addTearDown(routeObserver.dispose);
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            navigatorObservers: [routeObserver],
            builder: (context, child) => ZyraAccountSessionHost(
              navigatorKey: navigatorKey,
              child: child!,
            ),
            home: const Scaffold(body: Text('Current ZYRA')),
          ),
        );
        await tester.pumpAndSettle();
        final underlying = ModalRoute.of(
          tester.element(find.text('Current ZYRA')),
        );
        final firstHold = await tester.startGesture(
          tester.getCenter(find.text('Current ZYRA')),
        );
        await tester.pump(const Duration(seconds: 3));
        await firstHold.up();
        _expectControlsClosed();
        navigatorKey.currentState!.push<void>(
          MaterialPageRoute(
            builder: (_) => const ZyraConceptPreviewBoundary(
              child: Scaffold(body: Text('One Journey synthetic shell')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(ZyraConceptPreviewIsolation.active, isTrue);
        final hold = await tester.startGesture(
          tester.getCenter(find.text('One Journey synthetic shell')),
        );
        await tester.pump(const Duration(seconds: 3));
        await hold.up();
        await tester.pump();
        _expectControlsClosed();
        expect(find.text('One Journey synthetic shell'), findsOneWidget);
        expect(ZyraAccountState.generation, generation);
        navigatorKey.currentState!.pop();
        await tester.pumpAndSettle();
        expect(ZyraConceptPreviewIsolation.active, isFalse);
        expect(
          ModalRoute.of(tester.element(find.text('Current ZYRA'))),
          same(underlying),
        );
        expect(navigatorKey.currentState!.canPop(), isFalse);
        final freshHold = await tester.startGesture(
          tester.getCenter(find.text('Current ZYRA')),
        );
        await tester.pump(const Duration(seconds: 3));
        await freshHold.up();
        await tester.pump();
        _expectControlsClosed();
        expect(ZyraAccountState.generation, generation);
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
    final routeObserver = ZyraPreviewRouteObserver();
    addTearDown(routeObserver.dispose);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [routeObserver],
        builder: (context, child) =>
            ZyraAccountSessionHost(navigatorKey: navigatorKey, child: child!),
        home: const Scaffold(body: Text('Current ZYRA')),
      ),
    );
    await tester.pumpAndSettle();
    final lease = ZyraConceptPreviewIsolation.acquire();
    addTearDown(lease.release);
    await tester.pump();
    _expectControlsClosed();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    lease.release();
    await tester.pumpAndSettle();
    expect(ZyraConceptPreviewIsolation.active, isFalse);
    expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
    _expectControlsClosed();
    final denied = await tester.startGesture(
      tester.getCenter(find.text('Current ZYRA')),
    );
    await tester.pump(const Duration(seconds: 3));
    await denied.up();
    await tester.pump();
    _expectControlsClosed();
    expect(find.text('Current ZYRA'), findsOneWidget);
    expect(navigatorKey.currentState!.canPop(), isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
