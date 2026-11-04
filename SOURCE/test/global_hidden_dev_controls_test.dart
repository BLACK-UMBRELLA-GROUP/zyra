import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_concept_preview_boundary.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/main.dart' show ZyraApp, zyraNavigatorKey;
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';
import 'package:zyra/theme/zyra_text.dart';

const _underlying = ValueKey('hidden-controls-underlying');

void _expectNoDeveloperControls() {
  expect(
    find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          ((widget.key! as ValueKey<String>).value.startsWith(
                'dev_controls_',
              ) ||
              (widget.key! as ValueKey<String>).value.startsWith('dev_rail_')),
    ),
    findsNothing,
  );
}

Future<void> _mount(
  WidgetTester tester, {
  ZyraPreviewRouteObserver? routeObserver,
  TextEditingController? draft,
}) async {
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        final rebuild = const ZyraApp().build(context) as ListenableBuilder;
        final app = rebuild.builder(context, null) as MaterialApp;
        return MaterialApp(
          navigatorKey: app.navigatorKey,
          navigatorObservers: [...?app.navigatorObservers, ?routeObserver],
          theme: app.theme,
          builder: app.builder,
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
        );
      },
    ),
  );
  await tester.pumpAndSettle();
}

Future<TestGesture> _beginHold(WidgetTester tester) =>
    tester.startGesture(tester.getCenter(find.byKey(_underlying)));

Future<void> _holdWithoutControls(WidgetTester tester) async {
  final hold = await _beginHold(tester);
  await tester.pump(const Duration(milliseconds: 2999));
  _expectNoDeveloperControls();
  await tester.pump(const Duration(milliseconds: 1));
  await hold.up();
  await tester.pumpAndSettle();
  _expectNoDeveloperControls();
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
  });

  tearDown(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('public configuration mounts no developer hold detector', (
    tester,
  ) async {
    final draft = TextEditingController(text: 'unchanged member draft');
    addTearDown(draft.dispose);
    await _mount(tester, draft: draft);
    _expectNoDeveloperControls();
    final hold = await _beginHold(tester);
    await tester.pump(const Duration(seconds: 4));
    await hold.up();
    await tester.pumpAndSettle();
    _expectNoDeveloperControls();
    expect(find.byKey(_underlying), findsOneWidget);
    expect(draft.text, 'unchanged member draft');
    expect(zyraNavigatorKey.currentState!.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final (surface, role) in <(String, String?)>[
    ('entry', null),
    ('seeker', 'seeker'),
    ('guardian', 'wali'),
  ]) {
    testWidgets(
      '$surface holds retain member drafts without hidden page options',
      (tester) async {
        ZyraLocalPrefs.setCachedRole(role);
        final routes = ZyraPreviewRouteObserver();
        final draft = TextEditingController(text: 'unsent local draft');
        addTearDown(draft.dispose);
        await _mount(tester, routeObserver: routes, draft: draft);
        final before = routes.revision;
        await _holdWithoutControls(tester);
        expect(find.byKey(_underlying), findsOneWidget);
        expect(draft.text, 'unsent local draft');
        expect(routes.revision, before);
        expect(zyraNavigatorKey.currentState!.canPop(), isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('route ABA during hold cannot open controls after return', (
    tester,
  ) async {
    final routes = ZyraPreviewRouteObserver();
    await _mount(tester, routeObserver: routes);
    final before = routes.revision;
    final hold = await _beginHold(tester);
    await tester.pump(const Duration(seconds: 1));
    zyraNavigatorKey.currentState!.push<void>(
      MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Covered route')),
      ),
    );
    await tester.pumpAndSettle();
    zyraNavigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(routes.revision, greaterThan(before));
    await tester.pump(const Duration(seconds: 3));
    await hold.up();
    _expectNoDeveloperControls();
    await _holdWithoutControls(tester);
    expect(find.byKey(_underlying), findsOneWidget);
  });

  testWidgets('revocation and concept isolation suppress the hidden trigger', (
    tester,
  ) async {
    await _mount(tester);
    final hold = await _beginHold(tester);
    await tester.pump(const Duration(seconds: 1));
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pump(const Duration(seconds: 3));
    await hold.up();
    _expectNoDeveloperControls();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    final isolation = ZyraConceptPreviewIsolation.acquire();
    addTearDown(isolation.release);
    await _holdWithoutControls(tester);
    expect(find.byKey(_underlying), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('same-frame presentation ABA cannot expose hidden controls', (
    tester,
  ) async {
    await _mount(tester);
    final member = ZyraAppGoldStyle.instance;
    final initialGold = member.enabled;
    final hold = await _beginHold(tester);
    await tester.pump(const Duration(seconds: 2));
    member.restore(!initialGold);
    member.restore(initialGold);
    await tester.pump(const Duration(seconds: 1));
    await hold.up();
    await tester.pumpAndSettle();
    _expectNoDeveloperControls();
    expect(member.enabled, initialGold);
    await _holdWithoutControls(tester);
    expect(find.byKey(_underlying), findsOneWidget);
  });
}
