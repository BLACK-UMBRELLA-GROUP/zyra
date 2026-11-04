import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_compatibility_access_store.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/subscription/profile_unlock_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_unlock_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'support/queue44_gold_fixture.dart';
import 'support/queue44_signup_flow_fixture.dart';

const _host = ValueKey('entry-compatibility-invoking-host');
const _cover = ValueKey('entry-compatibility-cover');
const _first = SeekerProfile(
  id: 'dev-signup-entry-compatibility-noor',
  firstName: 'Noor',
  age: 30,
  city: 'Glasgow',
  photos: <String>[],
  gender: 'female',
);
const _second = SeekerProfile(
  id: 'dev-signup-entry-compatibility-layla',
  firstName: 'Layla',
  age: 29,
  city: 'Leeds',
  photos: <String>[],
  gender: 'female',
);
const _real = SeekerProfile(
  id: '22222222-2222-4222-8222-222222222222',
  firstName: 'Real route sentinel',
  age: 31,
  city: 'London',
  photos: <String>[],
  gender: 'female',
);

class _RootRouteAudit extends NavigatorObserver {
  int pushes = 0;
  int replacements = 0;
  int removals = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      replacements++;
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      removals++;
}

class _Harness {
  const _Harness(this.root, this.flow, this.audit);
  final GlobalKey<NavigatorState> root;
  final GlobalKey<NavigatorState> flow;
  final _RootRouteAudit audit;
}

Future<_Harness> _mountSignup(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final root = GlobalKey<NavigatorState>();
  final audit = _RootRouteAudit();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: root,
      navigatorObservers: [audit, ZyraPreviewRouteObserver()],
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
        child: child!,
      ),
      home: const Scaffold(key: _host, body: Text('Invoking member route')),
    ),
  );
  await tester.pumpAndSettle();
  unawaited(
    root.currentState!.push<void>(
      MaterialPageRoute(
        allowSnapshotting: false,
        builder: (_) => const SignupFlowFixture(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final flow =
      tester
              .widget<Navigator>(
                find.descendant(
                  of: find.byType(SignupFlowFixture),
                  matching: find.byType(Navigator),
                ),
              )
              .key
          as GlobalKey<NavigatorState>;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  expect(OnboardingFixtureController.instance.entryLabel, 'Onboarding');
  expect(ZyraInternalPreviewClient.isActive, isTrue);
  return _Harness(root, flow, audit);
}

Future<ZyraCompatibilityFixture> _openCompatibility(
  WidgetTester tester,
  _Harness harness, {
  SeekerProfile profile = _first,
}) async {
  final fixture = ZyraCompatibilityFixture();
  unawaited(
    harness.flow.currentState!.push<void>(
      MaterialPageRoute(
        allowSnapshotting: false,
        builder: (_) => ProfileUnlockScreen(profile: profile, fixture: fixture),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(fixture.profileId, profile.id);
  expect(fixture.isCurrent(), profile.id != _real.id);
  _expectNoOptions();
  return fixture;
}

void _expectNoOptions() {
  expect(
    find.byWidgetPredicate(
      (w) => const {
        'ZyraGlobalDevOverlayHost',
        'ZyraDevPageOptions',
        'ZyraEntryDevPanel',
        'DeveloperAccessScreen',
      }.contains(w.runtimeType.toString()),
    ),
    findsNothing,
  );
  expect(find.byKey(const ValueKey('dev_controls_close')), findsNothing);
}

void _expectBounded(_Harness harness) {
  expect(OnboardingFixtureController.instance.entryLabel, 'Onboarding');
  expect(ZyraInternalPreviewClient.isActive, isTrue);
  expect(harness.root.currentState!.canPop(), isTrue);
  expect(harness.audit.pushes, 2);
  expect(harness.audit.replacements, 0);
  expect(harness.audit.removals, 0);
  _expectNoOptions();
}

void main() {
  late (String?, ZyraPlan, String?) original;
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.finishSignOut();
    OnboardingFixtureController.instance.resetForTesting();
    ZyraUnlockService.clearForSignOut();
    final state = AppState.instance;
    original = (state.name, state.plan, state.location);
    state.name = 'Unchanged sample owner';
    state.plan = ZyraPlan.one;
    state.location = 'Unchanged sample region';
  });
  tearDown(() {
    ZyraUnlockService.clearForSignOut();
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    OnboardingFixtureController.instance.resetForTesting();
    AppState.instance.name = original.$1;
    AppState.instance.plan = original.$2;
    AppState.instance.location = original.$3;
    ZyraText.useTestFontStubs = false;
  });

  testWidgets(
    'ordinary signup entry has no developer option groups and retains its nested route',
    (tester) async {
      final harness = await _mountSignup(tester);
      _expectBounded(harness);
      expect(find.byKey(const ValueKey('welcome_google')), findsOneWidget);
      expect(find.byKey(const ValueKey('welcome_apple')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final viewport in const [
    (size: Size(390, 844), scale: 1.0),
    (size: Size(320, 568), scale: 1.3),
  ]) {
    testWidgets(
      'nested Compatibility member action stays reachable without credit menus at ${viewport.size.width}/${viewport.scale}',
      (tester) async {
        final harness = await _mountSignup(
          tester,
          size: viewport.size,
          textScale: viewport.scale,
        );
        final fixture = await _openCompatibility(tester, harness);
        expect(fixture.balance(false), 0);
        expect(fixture.balance(true), 1);
        fixture.setBalance(true, 5);
        await tester.pumpAndSettle();
        final unlock = find.text('Unlock Compatibility');
        await tester.ensureVisible(unlock);
        await tester.pumpAndSettle();
        expect(unlock.hitTestable(), findsOneWidget);
        expect(fixture.balance(true), 5);
        _expectBounded(harness);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'code credit fixtures assign exact repeatable unified balances without member mutation',
    (tester) async {
      final harness = await _mountSignup(tester);
      final fixture = await _openCompatibility(tester, harness);
      final store = ZyraDraftCompatibilityAccessStore(
        canAct: fixture.isCurrent,
      );
      addTearDown(store.close);
      for (final count in const [0, 1, 5, 5]) {
        fixture.setBalance(true, count);
        expect(store.setBalance(count: count), isTrue);
        expect(fixture.balance(true), count);
        expect(fixture.balance(false), 0);
        expect(store.balance, count);
      }
      fixture.setBalance(false, 5);
      expect(fixture.balance(false), 0);
      expect(fixture.balance(true), 5);
      expect(store.setBalance(count: 2), isFalse);
      expect(store.unlock(draftProfiles.first.id), isTrue);
      expect(store.balance, 4);
      expect(
        (
          AppState.instance.name,
          AppState.instance.plan,
          AppState.instance.location,
        ),
        ('Unchanged sample owner', ZyraPlan.one, 'Unchanged sample region'),
      );
      _expectBounded(harness);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('covered nested route refuses retained code credit mutation', (
    tester,
  ) async {
    final harness = await _mountSignup(tester);
    final fixture = await _openCompatibility(tester, harness);
    final stale = fixture.captureBalance(true, 5);
    unawaited(
      harness.flow.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(key: _cover, body: Text('Covered')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(fixture.isCurrent(), isFalse);
    await stale();
    expect(fixture.balance(true), 1);
    harness.flow.currentState!.pop();
    await tester.pumpAndSettle();
    expect(fixture.isCurrent(), isTrue);
    await stale();
    expect(fixture.balance(true), 1);
    fixture.setBalance(true, 5);
    expect(fixture.balance(true), 5);
    _expectBounded(harness);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a new nested sample owner rejects the first owner code mutation',
    (tester) async {
      final harness = await _mountSignup(tester);
      final first = await _openCompatibility(tester, harness);
      final stale = first.captureBalance(true, 5);
      final second = await _openCompatibility(
        tester,
        harness,
        profile: _second,
      );
      expect(first.isCurrent(), isFalse);
      await stale();
      expect(first.balance(false), 0);
      expect(second.balance(false), 0);
      expect(second.balance(true), 1);
      second.setBalance(true, 5);
      expect(second.balance(true), 5);
      expect(first.balance(true), 1);
      _expectBounded(harness);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'revocation keeps credit menus absent and refuses a captured fixture callback',
    (tester) async {
      final harness = await _mountSignup(tester);
      final fixture = await _openCompatibility(tester, harness);
      final stale = fixture.captureBalance(true, 5);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpAndSettle();
      expect(fixture.isCurrent(), isFalse);
      expect(find.byKey(const ValueKey('dev_signup_denied')), findsOneWidget);
      await stale();
      expect(fixture.balance(false), 0);
      expect(fixture.balance(true), 1);
      _expectBounded(harness);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'code close retains the invoking root and rejects disposed credit callbacks',
    (tester) async {
      final harness = await _mountSignup(tester);
      final fixture = await _openCompatibility(tester, harness);
      final stale = fixture.captureBalance(true, 5);
      expect(OnboardingFixtureController.instance.closeOnboarding(), isTrue);
      await tester.pumpAndSettle();
      expect(find.byKey(_host), findsOneWidget);
      expect(find.byType(SignupFlowFixture), findsNothing);
      expect(harness.root.currentState!.canPop(), isFalse);
      expect(OnboardingFixtureController.instance.canCloseOnboarding, isFalse);
      expect(fixture.isCurrent(), isFalse);
      await stale();
      expect(fixture.balance(true), 1);
      expect(harness.audit.replacements, 0);
      expect(harness.audit.removals, 0);
      expect(harness.audit.pushes, 2);
      _expectNoOptions();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'real UUIDs never acquire code credit capability or sample menus',
    (tester) async {
      final harness = await _mountSignup(tester);
      final fixture = await _openCompatibility(tester, harness, profile: _real);
      final store = ZyraDraftCompatibilityAccessStore(
        canAct: fixture.isCurrent,
      );
      addTearDown(store.close);
      fixture.setBalance(true, 5);
      expect(fixture.isCurrent(), isFalse);
      expect(store.current, isFalse);
      expect(store.unlock(_real.id), isFalse);
      expect(store.resultFor(_real.id), isNull);
      _expectBounded(harness);
      expect(tester.takeException(), isNull);
    },
  );
}
