// Queue44: the retired coordinator is replaced by real member route ownership.
// Every retained action below is created and guarded by PersonalisationScreen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/screens/settings/personalisation_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_personalisation_content.dart';

class _Routes {
  final navigator = GlobalKey<NavigatorState>();
  final observer = ZyraPreviewRouteObserver();
  final changes = <String>[];
  final contexts = <String, BuildContext>{};

  Route<void> page(String name) => MaterialPageRoute<void>(
    settings: RouteSettings(name: name),
    builder: (context) {
      contexts[name] = context;
      return PersonalisationScreen.preview(
        key: ValueKey(name),
        // This is the caller's admission input. Route/lifecycle/revision and
        // disposal rejection remain entirely inside the production screen.
        canAct: () => ZyraDeveloperAccess.canUseDeveloperTools,
        palette: ZyraDevPalette.ivory,
        hapticLevel: ZyraHapticLevel.medium,
        goldEnabled: true,
        onHapticChanged: (_) {},
        onGoldChanged: (_) => changes.add(name),
        embedded: false,
      );
    },
  );

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [observer],
        onGenerateInitialRoutes: (_) => [page('host')],
        onGenerateRoute: (_) => page('host'),
      ),
    );
    await tester.pumpAndSettle();
  }

  ValueChanged<bool> action(WidgetTester tester, String name) => tester
      .widget<ZyraPersonalisationContent>(
        find.descendant(
          of: find.byKey(ValueKey(name), skipOffstage: false),
          matching: find.byType(
            ZyraPersonalisationContent,
            skipOffstage: false,
          ),
        ),
      )
      .onGoldChanged!;

  Future<Route<void>> push(WidgetTester tester, String name) async {
    final route = page(name);
    navigator.currentState!.push(route);
    await tester.pumpAndSettle();
    return route;
  }

  void noDeveloperControls() {
    for (final key in const [
      'dev_controls_close',
      'dev_controls_hold_surface',
      'dev_home_navigation',
      'dev_signup_close',
    ]) {
      expect(find.byKey(ValueKey(key), skipOffstage: false), findsNothing);
    }
  }
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = false;
  });

  testWidgets(
    'only the latest pushed member route can dispatch its owned action',
    (tester) async {
      final f = _Routes();
      await f.mount(tester);
      await f.push(tester, 'first');
      final first = f.action(tester, 'first');
      final epoch = f.observer.revision;
      await f.push(tester, 'second');
      first(false);
      f.action(tester, 'second')(false);
      expect(f.changes, ['second']);
      expect(f.observer.revision, greaterThan(epoch));
      f.noDeveloperControls();
    },
  );

  testWidgets('removed member routes cannot reuse their owned callbacks', (
    tester,
  ) async {
    final f = _Routes();
    await f.mount(tester);
    final route = await f.push(tester, 'removed');
    final stale = f.action(tester, 'removed');
    final epoch = f.observer.revision;
    f.navigator.currentState!.removeRoute(route);
    await tester.pumpAndSettle();
    stale(false);
    f.action(tester, 'host')(false);
    expect(f.changes, ['host']);
    expect(f.observer.revision, greaterThan(epoch));
    f.noDeveloperControls();
  });

  testWidgets(
    'pop disposes the top member action and restores fresh parent action',
    (tester) async {
      final f = _Routes();
      await f.mount(tester);
      await f.push(tester, 'first');
      final first = f.action(tester, 'first');
      await f.push(tester, 'second');
      final second = f.action(tester, 'second');
      f.navigator.currentState!.pop();
      await tester.pumpAndSettle();
      first(false);
      second(false);
      expect(f.changes, isEmpty);
      f.action(tester, 'first')(false);
      expect(f.changes, ['first']);
      f.noDeveloperControls();
    },
  );

  testWidgets(
    'a covered member callback cannot dispatch or regain revoked admission',
    (tester) async {
      final f = _Routes();
      await f.mount(tester);
      await f.push(tester, 'member');
      final stale = f.action(tester, 'member');
      await f.push(tester, 'cover');
      stale(false);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      f.navigator.currentState!.pop();
      await tester.pumpAndSettle();
      stale(false);
      expect(f.changes, isEmpty);
      expect(
        find.byKey(const ValueKey('personalisation-unavailable')),
        findsOneWidget,
      );
      f.noDeveloperControls();
    },
  );

  testWidgets(
    'disposed member ownership stays denied after another route opens',
    (tester) async {
      final f = _Routes();
      await f.mount(tester);
      await f.push(tester, 'old');
      final stale = f.action(tester, 'old');
      final old = f.contexts['old']!;
      f.navigator.currentState!.pop();
      await tester.pumpAndSettle();
      await f.push(tester, 'fresh');
      stale(false);
      f.action(tester, 'fresh')(false);
      expect(old.mounted, isFalse);
      expect(f.changes, ['fresh']);
      f.noDeveloperControls();
    },
  );

  testWidgets(
    'replacement invalidates the prior member callback and route epoch',
    (tester) async {
      final f = _Routes();
      await f.mount(tester);
      await f.push(tester, 'old');
      final stale = f.action(tester, 'old');
      final epoch = f.observer.revision;
      f.navigator.currentState!.pushReplacement(f.page('fresh'));
      await tester.pumpAndSettle();
      stale(false);
      f.action(tester, 'fresh')(false);
      expect(f.changes, ['fresh']);
      expect(f.observer.revision, greaterThan(epoch));
      f.noDeveloperControls();
    },
  );

  for (final role in ['Seeker', 'Guardian']) {
    testWidgets(
      'nested $role member presentation restores its page with fresh owned actions',
      (tester) async {
        final f = _Routes();
        await f.mount(tester);
        await f.push(tester, role);
        final original = tester.state(find.byKey(ValueKey(role)));
        final stale = f.action(tester, role);
        await f.push(tester, 'nested');
        stale(false);
        f.navigator.currentState!.pop();
        await tester.pumpAndSettle();
        stale(false);
        expect(f.changes, isEmpty);
        expect(tester.state(find.byKey(ValueKey(role))), same(original));
        f.action(tester, role)(false);
        expect(f.changes, [role]);
        f.noDeveloperControls();
      },
    );
  }

  for (final role in ['Seeker', 'Guardian']) {
    testWidgets(
      'a $role member removed while covered cannot resurrect its action',
      (tester) async {
        final f = _Routes();
        await f.mount(tester);
        final member = await f.push(tester, role);
        final stale = f.action(tester, role);
        await f.push(tester, 'nested');
        f.navigator.currentState!.removeRoute(member);
        await tester.pumpAndSettle();
        f.navigator.currentState!.pop();
        await tester.pumpAndSettle();
        stale(false);
        expect(find.byKey(ValueKey(role), skipOffstage: false), findsNothing);
        expect(f.changes, isEmpty);
        f.action(tester, 'host')(false);
        expect(f.changes, ['host']);
        f.noDeveloperControls();
      },
    );
  }

  testWidgets(
    'out-of-order member removal preserves only the live parent action',
    (tester) async {
      final f = _Routes();
      await f.mount(tester);
      await f.push(tester, 'first');
      final first = f.action(tester, 'first');
      final middle = await f.push(tester, 'middle');
      final stale = f.action(tester, 'middle');
      await f.push(tester, 'last');
      f.navigator.currentState!.removeRoute(middle);
      await tester.pumpAndSettle();
      f.navigator.currentState!.pop();
      await tester.pumpAndSettle();
      first(false);
      stale(false);
      expect(f.changes, isEmpty);
      f.action(tester, 'first')(false);
      expect(f.changes, ['first']);
      f.noDeveloperControls();
    },
  );

  testWidgets(
    'replacing one member owner records one epoch and rejects its old action',
    (tester) async {
      final f = _Routes();
      await f.mount(tester);
      await f.push(tester, 'same');
      final stale = f.action(tester, 'same');
      final before = f.observer.revision;
      f.navigator.currentState!.pushReplacement(f.page('replacement'));
      await tester.pumpAndSettle();
      stale(false);
      f.action(tester, 'replacement')(false);
      expect(f.observer.revision, before + 1);
      expect(f.changes, ['replacement']);
      f.noDeveloperControls();
    },
  );

  testWidgets(
    'nested member routes preserve cross-role order without reviving covered actions',
    (tester) async {
      final f = _Routes();
      await f.mount(tester);
      await f.push(tester, 'Seeker');
      final seeker = f.action(tester, 'Seeker');
      await f.push(tester, 'Guardian');
      final guardian = f.action(tester, 'Guardian');
      await f.push(tester, 'nested');
      seeker(false);
      guardian(false);
      expect(f.changes, isEmpty);
      f.navigator.currentState!.pop();
      await tester.pumpAndSettle();
      guardian(false);
      expect(f.changes, isEmpty);
      f.action(tester, 'Guardian')(false);
      f.navigator.currentState!.pop();
      await tester.pumpAndSettle();
      seeker(false);
      expect(f.changes, ['Guardian']);
      f.action(tester, 'Seeker')(false);
      expect(f.changes, ['Guardian', 'Seeker']);
      f.noDeveloperControls();
    },
  );
}
