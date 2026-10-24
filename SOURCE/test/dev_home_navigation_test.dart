import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/dev/zyra_dev_home.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/screens/dev/developer_access_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

const _rootKey = ValueKey('home-first-root');
const _flowKey = ValueKey('home-current-flow');
const _button = ValueKey('home-protected-action');
const _founder = User(
  id: '11111111-1111-4111-8111-111111111111',
  appMetadata: {'zyra_role': 'founder'},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-09-29T00:00:00Z',
);
const _member = User(
  id: '11111111-1111-4111-8111-111111111111',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-09-29T00:00:00Z',
);

class _Audit extends NavigatorObserver {
  int pushes = 0;
  int removals = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      removals++;
}

class _Harness {
  _Harness(this.navigator, this.audit, this.floating, this.outcomes);

  final GlobalKey<NavigatorState> navigator;
  final _Audit audit;
  final BuildContext floating;
  final List<bool> outcomes;
}

Future<_Harness> _mount(
  WidgetTester tester, {
  bool nested = false,
  bool Function()? isCurrent,
}) async {
  final navigator = GlobalKey<NavigatorState>();
  final audit = _Audit();
  final outcomes = <bool>[];
  BuildContext? floating;
  Widget action(BuildContext _) => Scaffold(
    key: _flowKey,
    body: Builder(
      builder: (context) => TextButton(
        key: _button,
        onPressed: () => unawaited(
          ZyraDevHome.open(context, isCurrent: isCurrent).then(outcomes.add),
        ),
        child: const Text('Home fixture'),
      ),
    ),
  );
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      navigatorObservers: [audit],
      home: nested
          ? Scaffold(
              key: _rootKey,
              body: Navigator(
                onGenerateRoute: (_) =>
                    MaterialPageRoute<void>(builder: action),
              ),
            )
          : const Scaffold(key: _rootKey, body: Text('Retained root')),
    ),
  );
  if (!nested) {
    unawaited(
      navigator.currentState!.push<void>(
        MaterialPageRoute<void>(builder: action),
      ),
    );
  }
  await tester.pumpAndSettle();
  // Production Entry tools live in the root Navigator's OverlayEntry:
  // below a Navigator, but outside a ModalRoute. MaterialApp.builder is
  // above the Navigator and cannot exercise that same context boundary.
  final entry = OverlayEntry(
    builder: (context) {
      floating = context;
      return const SizedBox.shrink();
    },
  );
  navigator.currentState!.overlay!.insert(entry);
  await tester.pump();
  expect(ModalRoute.of(floating!), isNull);
  expect(
    Navigator.of(floating!, rootNavigator: true),
    same(navigator.currentState),
  );
  addTearDown(() async {
    entry.remove();
    entry.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  return _Harness(navigator, audit, floating!, outcomes);
}

void _expectLanding(_Harness harness) {
  expect(find.byType(DeveloperAccessScreen), findsOneWidget);
  for (final key in const [
    'dev_access_seeker',
    'dev_access_guardian',
    'dev_access_signup',
  ]) {
    expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget);
  }
  expect(find.byKey(_rootKey, skipOffstage: false), findsOneWidget);
  expect(find.byKey(_rootKey), findsNothing);
  expect(harness.navigator.currentState!.canPop(), isTrue);
}

void main() {
  var transportCalls = 0;
  var refreshes = 0;
  User? current = _founder;
  late SharedPreferences preferences;

  Future<void> proof(Future<User?> Function() refresh) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.configureAuthorizationForTesting(
      variant: ZyraAppVariant.production,
      currentUser: () => current,
      refreshSession: () {
        refreshes++;
        return refresh();
      },
      founderIdentityMatches: (user) =>
          user.appMetadata['zyra_role'] == 'founder',
    );
    await ZyraDeveloperAccess.acceptFreshTokenRefresh(_founder);
    expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'local-widget-test',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((_) async {
        transportCalls++;
        return http.Response(
          '{"message":"mock transport denied"}',
          403,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    await ZyraLocalPrefs.init();
    preferences = await SharedPreferences.getInstance();
  });
  tearDownAll(() => Supabase.instance.dispose());

  setUp(() async {
    transportCalls = 0;
    refreshes = 0;
    current = _founder;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await ZyraAccountState.synchronize(_founder.id);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraText.useTestFontStubs = true;
    await preferences.setString('dev-home-preserved-sentinel', 'preserved');
    AppState.instance.name = 'Preserved local member';
    AppState.instance.plan = ZyraPlan.one;
  });

  tearDown(() {
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraInternalPreviewClient.finishSignOut();
    ZyraText.useTestFontStubs = false;
  });

  for (final nested in [false, true]) {
    testWidgets(
      'Home refreshes proof and uses root navigation from ${nested ? 'nested' : 'outer'} flow without member mutation',
      (tester) async {
        await proof(() async => current);
        final harness = await _mount(tester, nested: nested);
        final before = (
          ZyraAccountState.userId,
          ZyraAccountState.generation,
          AppState.instance.name,
          AppState.instance.plan,
          Supabase.instance.client.auth.currentSession,
          preferences.getString('dev-home-preserved-sentinel'),
        );
        expect(ZyraInternalPreviewClient.isActive, isTrue);
        await tester.tap(find.byKey(_button));
        await tester.pumpAndSettle();
        _expectLanding(harness);
        expect(harness.outcomes, [true]);
        expect(harness.audit.pushes, nested ? 2 : 3);
        expect(harness.audit.removals, nested ? 0 : 1);
        expect(
          refreshes,
          2,
          reason: 'Helper and protected landing each verify fresh proof',
        );
        expect((
          ZyraAccountState.userId,
          ZyraAccountState.generation,
          AppState.instance.name,
          AppState.instance.plan,
          Supabase.instance.client.auth.currentSession,
          preferences.getString('dev-home-preserved-sentinel'),
        ), before);
        expect(current, same(_founder));
        expect(ZyraAccountState.isSigningOut, isFalse);
        expect(ZyraInternalPreviewClient.isActive, isTrue);
        expect(transportCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Home denies absent authority before refreshing', (tester) async {
    final harness = await _mount(tester);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.tap(find.byKey(_button));
    await tester.pumpAndSettle();
    expect(harness.outcomes, [false]);
    expect(find.byKey(_flowKey), findsOneWidget);
    expect(find.byType(DeveloperAccessScreen), findsNothing);
    expect(refreshes, 0);
    expect(transportCalls, 0);
  });

  testWidgets(
    'Home rejects revoked fresh proof rather than trusting cached authority',
    (tester) async {
      await proof(() async {
        current = _member;
        return current;
      });
      final harness = await _mount(tester);
      await tester.tap(find.byKey(_button));
      await tester.pumpAndSettle();
      expect(harness.outcomes, [false]);
      expect(find.byKey(_flowKey), findsOneWidget);
      expect(find.byType(DeveloperAccessScreen), findsNothing);
      expect(refreshes, 1);
      expect(transportCalls, 0);
    },
  );

  testWidgets('double Home while proof is pending commits only one landing', (
    tester,
  ) async {
    final response = Completer<User?>();
    await proof(() => refreshes == 1 ? response.future : Future.value(current));
    final harness = await _mount(tester);
    final retained = tester.widget<TextButton>(find.byKey(_button)).onPressed!;
    retained();
    retained();
    await tester.pump();
    expect(refreshes, 1);
    response.complete(_founder);
    await tester.pumpAndSettle();
    _expectLanding(harness);
    expect(harness.outcomes, [false, true]);
    expect(harness.audit.pushes, 3);
    expect(harness.audit.removals, 1);
    retained();
    await tester.pumpAndSettle();
    expect(harness.outcomes, [false, true, false]);
    expect(harness.audit.pushes, 3);
    expect(transportCalls, 0);
    expect(tester.takeException(), isNull);
  });

  for (final change in ['generation', 'disposal', 'owner-current']) {
    testWidgets('Home denies $change changes during pending proof', (
      tester,
    ) async {
      final response = Completer<User?>();
      await proof(() => response.future);
      var ownerCurrent = true;
      final harness = await _mount(
        tester,
        isCurrent: change == 'owner-current' ? () => ownerCurrent : null,
      );
      await tester.tap(find.byKey(_button));
      await tester.pump();
      expect(refreshes, 1);
      if (change == 'generation') {
        ZyraAccountState.resetForTesting();
      } else if (change == 'disposal') {
        harness.navigator.currentState!.pop();
        await tester.pump(const Duration(milliseconds: 400));
      } else {
        ownerCurrent = false;
      }
      response.complete(_founder);
      await tester.pumpAndSettle();
      expect(harness.outcomes, [false]);
      expect(find.byType(DeveloperAccessScreen), findsNothing);
      expect(harness.audit.pushes, 2);
      expect(transportCalls, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'stale null-route Home refuses newly registered and covered onboarding owners',
    (tester) async {
      await proof(() async => current);
      final harness = await _mount(tester);
      expect(ModalRoute.of(harness.floating), isNull);
      final first = Object();
      final second = Object();
      final coordinator = ZyraDevSurfaceCoordinator.instance;
      coordinator.attachOnboarding(
        first,
        (_) {},
        onClose: () {},
        isCurrent: () => false,
      );
      expect(await ZyraDevHome.open(harness.floating), isFalse);
      coordinator.attachOnboarding(
        second,
        (_) {},
        onClose: () {},
        isCurrent: () => true,
      );
      expect(await ZyraDevHome.open(harness.floating), isFalse);
      expect(refreshes, 0);
      expect(find.byKey(_flowKey), findsOneWidget);
      expect(find.byType(DeveloperAccessScreen), findsNothing);
      expect(transportCalls, 0);
    },
  );

  testWidgets(
    'null-route Home refuses an owner registered during pending proof',
    (tester) async {
      final response = Completer<User?>();
      await proof(() => response.future);
      final harness = await _mount(tester);
      bool? result;
      unawaited(
        ZyraDevHome.open(harness.floating).then((value) => result = value),
      );
      await tester.pump();
      expect(refreshes, 1);
      ZyraDevSurfaceCoordinator.instance.attachOnboarding(
        Object(),
        (_) {},
        onClose: () {},
        isCurrent: () => true,
      );
      response.complete(_founder);
      await tester.pumpAndSettle();
      expect(result, isFalse);
      expect(find.byKey(_flowKey), findsOneWidget);
      expect(find.byType(DeveloperAccessScreen), findsNothing);
      expect(harness.audit.pushes, 2);
      expect(transportCalls, 0);
    },
  );
}
