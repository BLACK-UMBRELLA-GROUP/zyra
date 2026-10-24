import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_signup_process.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/zyra_dev_page_options.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/dev/zyra_global_dev_overlay.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/dev/developer_access_screen.dart';
import 'package:zyra/screens/subscription/profile_unlock_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_unlock_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

const _host = ValueKey('entry-compatibility-invoking-host');
const _launch = ValueKey('entry-compatibility-launch-signup');
const _cover = ValueKey('entry-compatibility-cover');
const _standard = 'Compatibility Unlock';
const _plus = 'Compatibility Unlock';
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

ZyraDevSurfaceCoordinator get _coordinator =>
    ZyraDevSurfaceCoordinator.instance;

class _RootRouteAudit extends NavigatorObserver {
  int pushes = 0;
  int pops = 0;
  int replacements = 0;
  int removals = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => pops++;

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
  final controlsRouteObserver = ZyraDevControlsRouteObserver();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: root,
      navigatorObservers: [audit, controlsRouteObserver],
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
        child: ZyraGlobalDevOverlayHost(
          navigatorKey: root,
          routeObserver: controlsRouteObserver,
          authStateChangesOverride: const Stream.empty(),
          child: child!,
        ),
      ),
      home: Scaffold(
        key: _host,
        body: Builder(
          builder: (context) => TextButton(
            key: _launch,
            onPressed: () {
              _coordinator.beginEntryFlow('Onboarding');
              unawaited(
                Navigator.of(context)
                    .push<void>(
                      MaterialPageRoute(
                        allowSnapshotting: false,
                        builder: (_) => const DevSignUpProcessScreen(),
                      ),
                    )
                    .whenComplete(_coordinator.endEntryFlow),
              );
            },
            child: const Text('Open bounded first-use flow'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(_launch));
  await tester.pumpAndSettle();
  final flow =
      tester
              .widget<Navigator>(
                find.descendant(
                  of: find.byType(DevSignUpProcessScreen),
                  matching: find.byType(Navigator),
                ),
              )
              .key
          as GlobalKey<NavigatorState>;
  addTearDown(() async {
    final nested = flow.currentState;
    if (nested != null && nested.mounted) {
      while (nested.canPop()) {
        nested.pop();
      }
      await tester.pumpAndSettle();
    }
    final outer = root.currentState;
    if (outer != null && outer.mounted) {
      while (outer.canPop()) {
        outer.pop();
      }
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    _coordinator.endEntryFlow();
  });
  expect(_coordinator.surface, ZyraDevSurface.entry);
  expect(_coordinator.entryLabel, 'Onboarding');
  expect(ZyraInternalPreviewClient.isActive, isTrue);
  return _Harness(root, flow, audit);
}

Future<ZyraCompatibilityDevControls> _openCompatibility(
  WidgetTester tester,
  _Harness harness, {
  SeekerProfile profile = _first,
}) async {
  unawaited(
    harness.flow.currentState!.push<void>(
      MaterialPageRoute(
        allowSnapshotting: false,
        builder: (_) => ProfileUnlockScreen(profile: profile),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final controls = _coordinator.activeCompatibilityControls;
  expect(controls, isNotNull);
  expect(controls!.profileId, profile.id);
  expect(controls.isCurrent(), isTrue);
  expect(find.byType(ZyraEntryDevPanel), findsOneWidget);
  return controls;
}

Future<void> _openActions(WidgetTester tester) async {
  final hold = await tester.startGesture(
    Offset(
      tester.view.physicalSize.width - 8,
      tester.view.physicalSize.height / 2,
    ),
  );
  await tester.pump(const Duration(seconds: 3));
  await hold.up();
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('dev_controls_close')), findsOneWidget);
}

ZyraDevPageOptions _options(WidgetTester tester) =>
    tester.widget<ZyraDevPageOptions>(find.byType(ZyraDevPageOptions));

Future<void> _choose(
  WidgetTester tester, {
  required bool plus,
  required int count,
}) async {
  final group = plus ? _plus : _standard;
  final trigger = find.byKey(ValueKey('dev_page_options_dropdown_$group'));
  await tester.ensureVisible(trigger);
  await tester.pumpAndSettle();
  await tester.tap(trigger.hitTestable());
  await tester.pumpAndSettle();
  final option = find.byKey(
    ValueKey('compatibility-${plus ? 'plus' : 'standard'}-$count'),
  );
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  expect(option.hitTestable(), findsOneWidget);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

void _expectBounded(_Harness harness) {
  expect(_coordinator.surface, ZyraDevSurface.entry);
  expect(_coordinator.entryLabel, 'Onboarding');
  expect(ZyraInternalPreviewClient.isActive, isTrue);
  expect(harness.root.currentState!.canPop(), isTrue);
  expect(harness.audit.pushes, 2);
  expect(harness.audit.replacements, 0);
  expect(harness.audit.removals, 0);
  expect(find.byKey(const ValueKey('dev_signup_close')), findsNothing);
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
    _coordinator.resetForTesting();
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
    _coordinator.resetForTesting();
    AppState.instance.name = original.$1;
    AppState.instance.plan = original.$2;
    AppState.instance.location = original.$3;
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('ordinary signup entry retains its two existing option groups', (
    tester,
  ) async {
    final harness = await _mountSignup(tester);
    await _openActions(tester);
    expect(_options(tester).options.map((option) => option.id).toSet(), {
      'dev_entry_accounts',
      'dev_entry_signup',
    });
    expect(_options(tester).options.map((option) => option.group).toSet(), {
      'Entry',
      'Onboarding',
    });
    _expectBounded(harness);
    expect(tester.takeException(), isNull);
  });

  for (final viewport in const [
    (size: Size(390, 844), scale: 1.0),
    (size: Size(320, 568), scale: 1.3),
  ]) {
    testWidgets(
      'nested Compatibility has one reachable group at ${viewport.size.width}/${viewport.scale}',
      (tester) async {
        final harness = await _mountSignup(
          tester,
          size: viewport.size,
          textScale: viewport.scale,
        );
        final controls = await _openCompatibility(tester, harness);
        await _openActions(tester);
        expect(_options(tester).options.map((option) => option.id).toSet(), {
          'compatibility-plus-0',
          'compatibility-plus-1',
          'compatibility-plus-5',
          'dev_entry_accounts',
          'dev_entry_signup',
        });
        expect(_options(tester).contextKey, startsWith('entry:compatibility-'));
        expect(controls.balance(false), 0);
        expect(controls.balance(true), 1);
        await _choose(tester, plus: true, count: 5);
        expect(controls.balance(false), 0);
        expect(controls.balance(true), 5);
        _expectBounded(harness);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('entry choices assign exact repeatable unified credits', (
    tester,
  ) async {
    final harness = await _mountSignup(tester);
    final controls = await _openCompatibility(tester, harness);
    await _openActions(tester);
    for (final plus in const [true]) {
      final other = controls.balance(!plus);
      for (final count in const [0, 1, 5, 5]) {
        await _choose(tester, plus: plus, count: count);
        expect(controls.balance(plus), count);
        expect(controls.balance(!plus), other);
      }
    }
    expect(
      _options(tester).options
          .where((option) => option.selected)
          .map((option) => option.id)
          .toSet(),
      {'compatibility-plus-5'},
    );
    controls.setBalance(false, 5);
    expect(controls.balance(false), 0);
    expect(controls.balance(true), 5);
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
  });

  testWidgets('covered nested route refuses retained entry choices', (
    tester,
  ) async {
    final harness = await _mountSignup(tester);
    final controls = await _openCompatibility(tester, harness);
    await _openActions(tester);
    final stale = _options(tester).options
        .singleWhere((option) => option.id == 'compatibility-plus-5')
        .onSelected!;
    unawaited(
      harness.flow.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const Scaffold(key: _cover, body: Text('Covered')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_coordinator.activeCompatibilityControls, isNull);
    expect(_options(tester).contextKey, 'entry:Onboarding');
    expect(
      _options(
        tester,
      ).options.any((option) => option.id.startsWith('compatibility-')),
      isFalse,
    );
    await stale();
    expect(controls.balance(true), 1);
    harness.flow.currentState!.pop();
    await tester.pumpAndSettle();
    expect(_coordinator.activeCompatibilityControls, same(controls));
    await _choose(tester, plus: true, count: 5);
    expect(controls.balance(true), 5);
    _expectBounded(harness);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a new nested sample owner invalidates the old choice', (
    tester,
  ) async {
    final harness = await _mountSignup(tester);
    final first = await _openCompatibility(tester, harness);
    await _openActions(tester);
    final firstContext = _options(tester).contextKey;
    final stale = _options(tester).options
        .singleWhere((option) => option.id == 'compatibility-plus-5')
        .onSelected!;
    final second = await _openCompatibility(tester, harness, profile: _second);
    expect(_options(tester).contextKey, isNot(firstContext));
    await stale();
    expect(first.balance(false), 0);
    expect(second.balance(false), 0);
    expect(second.balance(true), 1);
    await _choose(tester, plus: true, count: 5);
    expect(second.balance(true), 5);
    expect(first.balance(true), 1);
    _expectBounded(harness);
    expect(tester.takeException(), isNull);
  });

  testWidgets('revocation hides entry choices and refuses an old callback', (
    tester,
  ) async {
    final harness = await _mountSignup(tester);
    final controls = await _openCompatibility(tester, harness);
    await _openActions(tester);
    final stale = _options(tester).options
        .singleWhere((option) => option.id == 'compatibility-plus-5')
        .onSelected!;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpAndSettle();
    expect(find.byType(ZyraDevPageOptions), findsNothing);
    expect(_coordinator.activeCompatibilityControls, isNull);
    expect(find.byKey(const ValueKey('dev_signup_denied')), findsOneWidget);
    await stale();
    expect(controls.balance(false), 0);
    expect(controls.balance(true), 1);
    _expectBounded(harness);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Home opens Developer Access, retains first root and rejects disposed choices',
    (tester) async {
      final harness = await _mountSignup(tester);
      final controls = await _openCompatibility(tester, harness);
      await _openActions(tester);
      final stale = _options(tester).options
          .singleWhere((option) => option.id == 'compatibility-plus-5')
          .onSelected!;
      await tester.tap(
        find.byKey(const ValueKey('dev_controls_tab_home')).hitTestable(),
      );
      await tester.pumpAndSettle();
      final exit = find.byKey(const ValueKey('dev_home_navigation'));
      await tester.ensureVisible(exit);
      await tester.pumpAndSettle();
      expect(exit.hitTestable(), findsOneWidget);
      await tester.tap(exit);
      await tester.pumpAndSettle();
      expect(find.byKey(_host), findsNothing);
      expect(find.byKey(_host, skipOffstage: false), findsOneWidget);
      expect(find.byType(DeveloperAccessScreen), findsOneWidget);
      for (final key in const [
        'dev_access_seeker',
        'dev_access_guardian',
        'dev_access_signup',
      ]) {
        expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget);
      }
      expect(find.byType(DevSignUpProcessScreen), findsNothing);
      expect(harness.root.currentState!.canPop(), isTrue);
      expect(_coordinator.entryLabel, 'Developer Access');
      expect(_coordinator.activeCompatibilityControls, isNull);
      expect(_coordinator.canCloseOnboarding, isFalse);
      expect(ZyraInternalPreviewClient.isActive, isTrue);
      await stale();
      expect(controls.balance(true), 1);
      expect(harness.audit.replacements, 0);
      expect(harness.audit.removals, 1);
      expect(harness.audit.pushes, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('real UUIDs never acquire the sample credit groups in Entry', (
    tester,
  ) async {
    final harness = await _mountSignup(tester);
    unawaited(
      harness.flow.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) => const ProfileUnlockScreen(profile: _real),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _openActions(tester);
    expect(_coordinator.activeCompatibilityControls, isNull);
    expect(_options(tester).options.map((option) => option.id).toSet(), {
      'dev_entry_accounts',
      'dev_entry_signup',
    });
    _expectBounded(harness);
    expect(tester.takeException(), isNull);
  });
}
