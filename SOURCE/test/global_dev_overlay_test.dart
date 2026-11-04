import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'dart:async';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_request_activity_presentation.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'support/zyra_hidden_dev_controls_driver.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/main.dart' show ZyraApp, zyraNavigatorKey;
import 'package:zyra/widgets/zyra_account_session_host.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

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

// Exercise the production MaterialApp frame and route table with caller-owned
// inert member content, without starting the backend startup destination.
Widget _appFrame(Widget page) => Builder(
  builder: (context) {
    final rebuild = const ZyraApp().build(context) as ListenableBuilder;
    final app = rebuild.builder(context, null) as MaterialApp;
    return MaterialApp(
      navigatorKey: app.navigatorKey,
      navigatorObservers: app.navigatorObservers ?? const <NavigatorObserver>[],
      theme: app.theme,
      builder: app.builder,
      routes: app.routes ?? const <String, WidgetBuilder>{},
      onGenerateRoute: app.onGenerateRoute,
      onUnknownRoute: app.onUnknownRoute,
      home: page,
    );
  },
);

// Flush presentation queues while the widget test's FakeAsync zone is still
// alive. package:test tearDown runs too late to pump that finished zone.
void _isolatedTestWidgets(
  String name,
  Future<void> Function(WidgetTester) body,
) {
  testWidgets(name, (tester) async {
    try {
      await body(tester);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      var preferencesRehomed = false;
      Zone.root.run(() {
        ZyraLocalPrefs.bindAccount(null).then((_) => preferencesRehomed = true);
      });
      for (var frame = 0; frame < 60 && !preferencesRehomed; frame++) {
        await tester.pump();
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      }
      expect(
        preferencesRehomed,
        isTrue,
        reason: 'Rehome preferences before leaving this FakeAsync zone',
      );
    }
  });
}

void main() {
  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraText.useTestFontStubs = true;
    ZyraText.selectAppFont(ZyraText.currentDefaultFont);
    ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
    ZyraColors.selectAppSurfaceStyle(ZyraColors.currentDefaultSurfaceStyle);
  });

  tearDown(() {
    ZyraAccountState.clearImagesForTesting = null;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.selectAppFont(ZyraText.currentDefaultFont);
    ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
    ZyraColors.selectAppSurfaceStyle(ZyraColors.currentDefaultSurfaceStyle);
    ZyraText.useTestFontStubs = false;
  });

  for (final event in [
    AuthChangeEvent.initialSession,
    AuthChangeEvent.signedIn,
  ]) {
    _isolatedTestWidgets(
      '$event joins the route refresh without losing its result',
      (tester) async {
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        const founder = User(
          id: '11111111-1111-4111-8111-111111111111',
          appMetadata: {'zyra_role': 'founder'},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-09-14T00:00:00Z',
        );
        await tester.runAsync(() async {
          ZyraAccountState.resetForTesting();
          await ZyraAccountState.synchronize(founder.id);
        });
        final response = Completer<User?>();
        var refreshes = 0;
        ZyraDeveloperAccess.configureAuthorizationForTesting(
          variant: ZyraAppVariant.production,
          currentUser: () => founder,
          refreshSession: () {
            refreshes++;
            return response.future;
          },
          founderIdentityMatches: (user) =>
              user.appMetadata['zyra_role'] == 'founder',
        );
        final route = ZyraDeveloperAccess.refreshCurrentAuthorizationSnapshot();
        ZyraAuthorizationRefreshSnapshot? routeResult;
        unawaited(route.then((value) => routeResult = value));
        final authStates = StreamController<AuthState>();
        addTearDown(authStates.close);
        final navigatorKey = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigatorKey,
            builder: (context, child) => ZyraAccountSessionHost(
              navigatorKey: navigatorKey,
              authStateChangesOverride: authStates.stream,
              child: child!,
            ),
            home: const Scaffold(body: Text('Resolving route')),
          ),
        );
        final session = Session(
          accessToken: 'not-a-real-token',
          tokenType: 'bearer',
          user: founder,
        );
        authStates.add(AuthState(event, session));
        await tester.pump();
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        expect(refreshes, 1);
        authStates.add(AuthState(AuthChangeEvent.tokenRefreshed, session));
        response.complete(founder);
        await tester.pumpAndSettle();
        expect(routeResult?.founderAuthorized, isTrue);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
        expect(refreshes, 1);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  _isolatedTestWidgets(
    'a different member removes the old member’s complete route stack',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      const first = User(
        id: '11111111-1111-4111-8111-111111111111',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-09-14T00:00:00Z',
      );
      const second = User(
        id: '22222222-2222-4222-8222-222222222222',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-09-14T00:00:00Z',
      );
      var current = first;
      ZyraDeveloperAccess.configureAuthorizationForTesting(
        variant: ZyraAppVariant.production,
        currentUser: () => current,
        refreshSession: () async => current,
        founderIdentityMatches: (_) => false,
      );
      await tester.runAsync(() async {
        ZyraAccountState.resetForTesting();
        await ZyraAccountState.synchronize(first.id);
      });
      final authStates = StreamController<AuthState>();
      addTearDown(authStates.close);
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) => ZyraAccountSessionHost(
            navigatorKey: navigatorKey,
            authStateChangesOverride: authStates.stream,
            authorityLossDestinationBuilder: (_) =>
                const Scaffold(body: Text('New account gate')),
            child: child!,
          ),
          home: const Scaffold(body: Text('Old account home')),
        ),
      );
      navigatorKey.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Text('Old account private details')),
        ),
      );
      await tester.pumpAndSettle();
      current = second;
      authStates.add(
        AuthState(
          AuthChangeEvent.signedIn,
          Session(accessToken: 'synthetic', tokenType: 'bearer', user: second),
        ),
      );
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(
        find.text('Old account private details', skipOffstage: false),
        findsNothing,
      );
      expect(find.text('Old account home', skipOffstage: false), findsNothing);
      expect(find.text('New account gate'), findsOneWidget);
      expect(navigatorKey.currentState!.canPop(), isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  _isolatedTestWidgets(
    'member Introductions navigation retains route epochs without developer dispatch',
    (tester) async {
      final routes = ZyraPreviewRouteObserver();
      final navigator = GlobalKey<NavigatorState>();
      final fixture = ZyraShellTestFixture();
      addTearDown(fixture.dispose);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          navigatorObservers: [routes],
          home: ZyraOneJourneyConceptShell(
            canAct: () => ZyraDeveloperAccess.canUseDeveloperTools,
            onExit: () {},
            restoreLocation: false,
            fixture: fixture.fixture,
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation))
          .onTap(2);
      await tester.pumpAndSettle();
      expect(fixture.latest!.tab, 2);
      final before = fixture.captureGuard();
      final entry = find.byKey(const ValueKey('concept-my-introductions'));
      await tester.ensureVisible(entry);
      await tester.tap(entry);
      await tester.pumpAndSettle();
      final page = tester.widget<ZyraRequestActivityPresentation>(
        find.byKey(const ValueKey('concept_activity_introductions')),
      );
      expect(page.title, 'Introductions');
      expect(page.labels, ['Introductions']);
      expect(find.text('No introductions yet'), findsOneWidget);
      expect(fixture.latest!.pages, ['introductions']);
      expect(before(), isFalse);
      final sourceGuard = fixture.captureGuard();
      final revision = routes.revision;
      navigator.currentState!.push<void>(
        MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Text('Cover actual Introductions')),
        ),
      );
      await tester.pumpAndSettle();
      expect(routes.revision, greaterThan(revision));
      expect(sourceGuard(), isFalse);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(sourceGuard(), isFalse);
      await returnZyraPreviewPage(tester);
      expect(fixture.latest!.pages, isEmpty);
      expect(
        find.byKey(const ValueKey('concept-my-introductions')),
        findsOneWidget,
      );
      _expectNoDeveloperControls();
    },
  );

  _isolatedTestWidgets(
    'entry and sign-up pages retain content without developer doors',
    (tester) async {
      final draft = TextEditingController(text: 'Unsubmitted sign-up draft');
      addTearDown(draft.dispose);
      await tester.pumpWidget(
        _appFrame(
          Scaffold(
            body: Column(
              children: [
                const Text('Sign-up page'),
                TextField(controller: draft),
              ],
            ),
          ),
        ),
      );
      final hold = await tester.startGesture(
        tester.getCenter(find.text('Sign-up page')),
      );
      await tester.pump(const Duration(seconds: 4));
      await hold.up();
      await tester.pumpAndSettle();
      _expectNoDeveloperControls();
      expect(find.text('Sign-up page'), findsOneWidget);
      expect(draft.text, 'Unsubmitted sign-up draft');
      expect(zyraNavigatorKey.currentState!.canPop(), isFalse);
    },
  );

  _isolatedTestWidgets(
    'holds on a pushed route cannot expose developer controls',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final routeObserver = ZyraPreviewRouteObserver();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [routeObserver],
          builder: (context, child) =>
              ZyraAccountSessionHost(navigatorKey: navigatorKey, child: child!),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(body: Text('Pushed page')),
                  ),
                ),
                child: const Text('Push'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();
      final hold = await tester.startGesture(
        tester.getCenter(find.text('Pushed page')),
      );
      await tester.pump(const Duration(seconds: 3));
      await hold.up();
      await tester.pumpAndSettle();
      _expectNoDeveloperControls();
      expect(find.text('Pushed page'), findsOneWidget);
      expect(navigatorKey.currentState!.canPop(), isTrue);
      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Push'), findsOneWidget);
    },
  );

  _isolatedTestWidgets(
    'a successful resume refresh preserves a permission-screen route',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final refresh = Completer<bool>();
      var allowed = true;
      var refreshCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) => ZyraAccountSessionHost(
            navigatorKey: navigatorKey,
            authorizationReaderOverride: () => allowed,
            authorityLossDestinationBuilder: (_) =>
                const Scaffold(body: Text('Home after real authority loss')),
            resumeAuthorizationRefreshOverride: () {
              refreshCalls += 1;
              allowed = false;
              return refresh.future.then((value) {
                allowed = value;
                return value;
              });
            },
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(body: Text('Scan ZYRA Code')),
        ),
      );
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(refreshCalls, 1);
      expect(find.text('Scan ZYRA Code'), findsOneWidget);
      expect(find.text('Home after real authority loss'), findsNothing);
      expect(find.byKey(const ValueKey('dev_controls_close')), findsNothing);

      refresh.complete(true);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Scan ZYRA Code'), findsOneWidget);
      expect(find.text('Home after real authority loss'), findsNothing);
    },
  );

  _isolatedTestWidgets(
    'developer capability changes cannot insert an app-wide rail',
    (tester) async {
      await tester.pumpWidget(
        _appFrame(const Scaffold(body: Text('Guarded page'))),
      );
      _expectNoDeveloperControls();
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pump();
      _expectNoDeveloperControls();
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await tester.pump();
      _expectNoDeveloperControls();
      expect(find.text('Guarded page'), findsOneWidget);
      expect(zyraNavigatorKey.currentState!.canPop(), isFalse);
    },
  );

  _isolatedTestWidgets(
    'a refreshed session that loses authority removes guarded routes',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final authStates = StreamController<AuthState>();
      addTearDown(authStates.close);
      var allowed = true;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) => ZyraAccountSessionHost(
            navigatorKey: navigatorKey,
            authStateChangesOverride: authStates.stream,
            authorizationReaderOverride: () => allowed,
            authorityLossDestinationBuilder: (_) =>
                const Scaffold(body: Text('Safe auth gate')),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(body: Text('Guarded developer page')),
        ),
      );
      await tester.pump();
      expect(find.text('Guarded developer page'), findsOneWidget);

      allowed = false;
      authStates.add(
        AuthState(
          AuthChangeEvent.tokenRefreshed,
          Session(
            accessToken: 'not-a-real-token',
            tokenType: 'bearer',
            user: const User(
              id: '00000000-0000-4000-8000-000000000111',
              appMetadata: {},
              userMetadata: {},
              aud: 'authenticated',
              email: 'founder@example.com',
              createdAt: '2026-09-12T00:00:00Z',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Guarded developer page'), findsNothing);
      expect(find.text('Safe auth gate'), findsOneWidget);
      _expectNoDeveloperControls();
    },
  );

  _isolatedTestWidgets(
    'userUpdated cannot restore authority without a real refresh',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      final founderWithClaim = User(
        id: '11111111-1111-4111-8111-111111111111',
        appMetadata: const {'zyra_role': 'founder'},
        userMetadata: const {},
        aud: 'authenticated',
        email: 'founder@example.com',
        createdAt: '2026-09-12T00:00:00Z',
      );
      final founderWithoutClaim = User(
        id: founderWithClaim.id,
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        email: founderWithClaim.email,
        createdAt: '2026-09-12T00:00:00Z',
      );
      User? current = founderWithClaim;
      var refreshCalls = 0;
      final refreshResult = Completer<User?>();
      ZyraDeveloperAccess.configureAuthorizationForTesting(
        variant: ZyraAppVariant.production,
        currentUser: () => current,
        refreshSession: () {
          refreshCalls += 1;
          current = founderWithoutClaim;
          return refreshResult.future;
        },
        founderIdentityMatches: (user) =>
            user.appMetadata['zyra_role'] == 'founder',
      );
      // The real entry path binds this owner before mounting protected routes.
      // A null-owner fixture would invalidate its own redirect lease on update.
      var ownerReady = false;
      Zone.root.run(() {
        ZyraAccountState.resetForTesting();
        ZyraAccountState.synchronize(
          founderWithClaim.id,
        ).then((_) => ownerReady = true);
      });
      // Drain the live widget-test queue while waiting for account cleanup;
      // runAsync alone would suspend the FakeAsync preference/cleanup queue.
      for (var frame = 0; frame < 60 && !ownerReady; frame++) {
        await tester.pump();
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      }
      expect(ownerReady, isTrue, reason: 'Bind the real fixture owner first');
      await ZyraDeveloperAccess.acceptFreshTokenRefresh(founderWithClaim);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);

      final navigatorKey = GlobalKey<NavigatorState>();
      final authStates = StreamController<AuthState>();
      addTearDown(authStates.close);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) => ZyraAccountSessionHost(
            navigatorKey: navigatorKey,
            authStateChangesOverride: authStates.stream,
            authorityLossDestinationBuilder: (_) =>
                const Scaffold(body: Text('Fresh-claim gate')),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(body: Text('Founder route')),
        ),
      );
      await tester.pump();
      _expectNoDeveloperControls();

      authStates.add(
        AuthState(
          AuthChangeEvent.userUpdated,
          Session(
            accessToken: 'not-a-real-token',
            tokenType: 'bearer',
            // The event payload deliberately retains the old privileged claim.
            user: founderWithClaim,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // The new host repaint may queue the route transition for the next frame.
      // Let that finite transition finish, without completing the held refresh.
      expect(refreshResult.isCompleted, isFalse);
      await tester.pumpAndSettle();
      expect(refreshCalls, 1);
      expect(refreshResult.isCompleted, isFalse);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      _expectNoDeveloperControls();
      expect(find.text('Founder route'), findsNothing);
      expect(find.text('Fresh-claim gate'), findsOneWidget);

      refreshResult.complete(founderWithoutClaim);
      await tester.pumpAndSettle();

      expect(find.text('Founder route'), findsNothing);
      expect(find.text('Fresh-claim gate'), findsOneWidget);
      _expectNoDeveloperControls();
    },
  );

  _isolatedTestWidgets('sign-out removes an already-open guarded route', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final authStates = StreamController<AuthState>();
    addTearDown(authStates.close);
    var allowed = true;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, child) => ZyraAccountSessionHost(
          navigatorKey: navigatorKey,
          authStateChangesOverride: authStates.stream,
          authorizationReaderOverride: () => allowed,
          authorityLossDestinationBuilder: (_) =>
              const Scaffold(body: Text('Signed-out gate')),
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Scaffold(body: Text('Open developer route')),
      ),
    );
    await tester.pump();

    allowed = false;
    authStates.add(const AuthState(AuthChangeEvent.signedOut, null));
    await tester.pumpAndSettle();

    expect(find.text('Open developer route'), findsNothing);
    expect(find.text('Signed-out gate'), findsOneWidget);
    _expectNoDeveloperControls();
  });

  _isolatedTestWidgets(
    'an auth stream error clears authority and removes guarded routes',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      final founder = User(
        id: '11111111-1111-4111-8111-111111111111',
        appMetadata: const {'zyra_role': 'founder'},
        userMetadata: const {},
        aud: 'authenticated',
        email: 'founder@example.com',
        createdAt: '2026-09-12T00:00:00Z',
      );
      ZyraDeveloperAccess.configureAuthorizationForTesting(
        variant: ZyraAppVariant.production,
        currentUser: () => founder,
        refreshSession: () async => founder,
        founderIdentityMatches: (user) =>
            user.appMetadata['zyra_role'] == 'founder',
      );
      await ZyraDeveloperAccess.acceptFreshTokenRefresh(founder);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);

      final navigatorKey = GlobalKey<NavigatorState>();
      final authStates = StreamController<AuthState>();
      addTearDown(authStates.close);
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) => ZyraAccountSessionHost(
            navigatorKey: navigatorKey,
            authStateChangesOverride: authStates.stream,
            authorityLossDestinationBuilder: (_) =>
                const Scaffold(body: Text('Auth stream failure gate')),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(body: Text('Protected founder route')),
        ),
      );
      await tester.pump();

      expect(find.text('Protected founder route'), findsOneWidget);
      _expectNoDeveloperControls();

      authStates.addError(
        StateError('synthetic auth stream error'),
        StackTrace.current,
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      expect(find.text('Protected founder route'), findsNothing);
      expect(find.text('Auth stream failure gate'), findsOneWidget);
      _expectNoDeveloperControls();
      expect(tester.takeException(), isNull);
    },
  );

  _isolatedTestWidgets(
    'unauthorized entry cannot navigate to a retired developer sign-up route',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpWidget(
        _appFrame(const Scaffold(body: Text('Safe entry page'))),
      );
      expect(
        () => zyraNavigatorKey.currentState!.pushNamed<void>('/dev/sign-up'),
        throwsFlutterError,
      );
      await tester.pumpAndSettle();
      expect(find.text('Safe entry page'), findsOneWidget);
      expect(find.text('About You'), findsNothing);
      expect(zyraNavigatorKey.currentState!.canPop(), isFalse);
      _expectNoDeveloperControls();
    },
  );

  _isolatedTestWidgets(
    'member role changes retain drafts without inserting developer panels',
    (tester) async {
      final draft = TextEditingController(text: 'Member-owned draft');
      addTearDown(draft.dispose);
      await tester.pumpWidget(
        _appFrame(Scaffold(body: TextField(controller: draft))),
      );
      for (final role in ['seeker', 'wali', null]) {
        ZyraLocalPrefs.setCachedRole(role);
        await tester.pump();
        _expectNoDeveloperControls();
        expect(draft.text, 'Member-owned draft');
        expect(find.byType(TextField), findsOneWidget);
        expect(zyraNavigatorKey.currentState!.canPop(), isFalse);
      }
    },
  );

  _isolatedTestWidgets(
    'entry navigation has no developer Home or Exit onboarding action',
    (tester) async {
      await tester.pumpWidget(
        _appFrame(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) =>
                        const Scaffold(body: Text('Member details')),
                  ),
                ),
                child: const Text('Continue entry'),
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('dev_home_navigation')), findsNothing);
      expect(find.text('Exit onboarding'), findsNothing);
      await tester.tap(find.text('Continue entry'));
      await tester.pumpAndSettle();
      expect(find.text('Member details'), findsOneWidget);
      _expectNoDeveloperControls();
      zyraNavigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Continue entry'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
