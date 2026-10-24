import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/dev/dev_splash_lab.dart';
import 'package:zyra/dev/dev_scenario_panel_v2.dart';
import 'package:zyra/dev/wali_dev_scenario_panel.dart';
import 'package:zyra/dev/zyra_global_dev_overlay.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/dev/zyra_dev_page_options.dart';
import 'package:zyra/dev/zyra_dev_signup.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_splash_motion.dart';

final _categoryDropdowns = find.byWidgetPredicate(
  (widget) =>
      widget.key is ValueKey<String> &&
      (widget.key! as ValueKey<String>).value.startsWith(
        'dev_page_options_dropdown_',
      ),
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
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraText.useTestFontStubs = true;
    ZyraText.selectAppFont(ZyraText.currentDefaultFont);
    ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
    ZyraColors.selectAppSurfaceStyle(ZyraColors.currentDefaultSurfaceStyle);
  });

  tearDown(() {
    ZyraAccountState.clearImagesForTesting = null;
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
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
            builder: (context, child) => ZyraGlobalDevOverlayHost(
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
          builder: (context, child) => ZyraGlobalDevOverlayHost(
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

  test('Seeker coordinator forwards the dedicated Introductions route', () {
    final coordinator = ZyraDevSurfaceCoordinator.instance;
    final owner = Object();
    final pages = <DevPage>[];
    final sections = <int>[];
    var introductions = 0;

    coordinator.attachSeeker(
      owner,
      pages.add,
      onOpenConnectionsSection: sections.add,
      onOpenIntroductions: () => introductions++,
    );
    coordinator.openSeeker(DevPage.connections);
    coordinator.openSeekerConnectionsSection(1);
    coordinator.openSeekerIntroductions();

    expect(pages, const [DevPage.connections]);
    expect(sections, const [1]);
    expect(introductions, 1);

    coordinator.detachSeeker(owner);
    coordinator.openSeekerConnectionsSection(2);
    coordinator.openSeekerIntroductions();
    expect(sections, const [1]);
    expect(introductions, 1);
  });

  _isolatedTestWidgets(
    'entry and sign-up pages receive three developer doors',
    (tester) async {
      final requests = ValueNotifier<int>(0);
      addTearDown(requests.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                const Text('Sign-up page'),
                ZyraGlobalDevOverlay(openRequests: requests),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('dev_controls_close')), findsNothing);
      requests.value++;
      await tester.pumpAndSettle();
      for (final section in ['preview', 'actions', 'home']) {
        expect(
          find.byKey(ValueKey('dev_controls_tab_$section')),
          findsOneWidget,
        );
      }
      expect(find.byKey(const ValueKey('dev_rail_style')), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('dev_controls_tab_preview')).hitTestable(),
      );
      await tester.pumpAndSettle();
      expect(find.text('Entry & sign-up preview'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('dev_controls_tab_actions')).hitTestable(),
      );
      await tester.pumpAndSettle();
      expect(find.text('Entry actions'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(ZyraDevPageOptions),
          matching: find.text('Page options'),
        ),
        findsOneWidget,
      );
      final pageOptions = tester
          .widget<ZyraDevPageOptions>(find.byType(ZyraDevPageOptions))
          .options;
      expect(
        _categoryDropdowns,
        findsNWidgets(pageOptions.map((option) => option.group).toSet().length),
      );
      for (final group in pageOptions.map((option) => option.group).toSet()) {
        expect(
          find.byKey(ValueKey('dev_page_options_dropdown_$group')),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(const ValueKey('dev_page_options_dropdown')),
        findsNothing,
      );
      expect(find.text('ZYRA DEV · ACTIONS'), findsNothing);
      final group = pageOptions
          .singleWhere((option) => option.id == 'dev_entry_signup')
          .group;
      final dropdown = find.byKey(ValueKey('dev_page_options_dropdown_$group'));
      await tester.ensureVisible(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dev_entry_signup')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dev_entry_guardian_signup')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('dev_entry_seeker_signup')),
        findsNothing,
      );
    },
  );

  _isolatedTestWidgets('the hidden controls open above a pushed route', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final routeObserver = ZyraDevControlsRouteObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [routeObserver],
        builder: (context, child) => ZyraGlobalDevOverlayHost(
          navigatorKey: navigatorKey,
          routeObserver: routeObserver,
          child: child ?? const SizedBox.shrink(),
        ),
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
    await tester.pump();

    expect(find.byKey(const ValueKey('dev_controls_close')), findsNothing);
    await tester.tap(find.text('Push'));
    await tester.pumpAndSettle();
    expect(find.text('Pushed page'), findsOneWidget);
    expect(find.byKey(const ValueKey('dev_controls_close')), findsNothing);
    final hold = await tester.startGesture(
      tester.getCenter(find.text('Pushed page')),
    );
    await tester.pump(const Duration(seconds: 3));
    await hold.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dev_controls_close')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dev_controls_close')));
    await tester.pumpAndSettle();
    expect(find.text('Pushed page'), findsOneWidget);
  });

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
          builder: (context, child) => ZyraGlobalDevOverlayHost(
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
    'the app-wide rail retracts when capability is revoked',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          builder: (context, child) => ZyraGlobalDevOverlayHost(
            navigatorKey: navigatorKey,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(body: Text('Guarded page')),
        ),
      );
      await tester.pump();
      expect(find.byType(ZyraEntryDevPanel), findsOneWidget);
      expect(find.byKey(const ValueKey('dev_controls_close')), findsNothing);

      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pump();
      expect(find.byType(ZyraEntryDevPanel), findsNothing);
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
          builder: (context, child) => ZyraGlobalDevOverlayHost(
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
      expect(find.byType(ZyraEntryDevPanel), findsNothing);
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
          builder: (context, child) => ZyraGlobalDevOverlayHost(
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
      expect(find.byType(ZyraEntryDevPanel), findsOneWidget);

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
      expect(find.byType(ZyraEntryDevPanel), findsNothing);
      expect(find.text('Founder route'), findsNothing);
      expect(find.text('Fresh-claim gate'), findsOneWidget);

      refreshResult.complete(founderWithoutClaim);
      await tester.pumpAndSettle();

      expect(find.text('Founder route'), findsNothing);
      expect(find.text('Fresh-claim gate'), findsOneWidget);
      expect(find.byType(ZyraEntryDevPanel), findsNothing);
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
        builder: (context, child) => ZyraGlobalDevOverlayHost(
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
    expect(find.byType(ZyraEntryDevPanel), findsNothing);
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
          builder: (context, child) => ZyraGlobalDevOverlayHost(
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
      expect(find.byType(ZyraEntryDevPanel), findsOneWidget);

      authStates.addError(
        StateError('synthetic auth stream error'),
        StackTrace.current,
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      expect(find.text('Protected founder route'), findsNothing);
      expect(find.text('Auth stream failure gate'), findsOneWidget);
      expect(find.byType(ZyraEntryDevPanel), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  _isolatedTestWidgets(
    'Splash Lab destinations deny direct unauthorized routes',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);

      await tester.pumpWidget(const MaterialApp(home: DevSplashLabMenu()));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('dev_splash_lab_denied')),
        findsOneWidget,
      );
      expect(find.text('Splash lab'), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: DevSplashLabScreen(
            motion: ZyraSplashMotion.bloomDraw,
            label: 'Direct attempt',
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('dev_splash_lab_denied')),
        findsOneWidget,
      );
      expect(find.textContaining('Replay'), findsNothing);
    },
  );

  _isolatedTestWidgets(
    'direct developer sign-up call denies an unauthorized caller',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => ZyraDevSignUp.start(context),
                child: const Text('Attempt direct preview'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Attempt direct preview'));
      await tester.pumpAndSettle();
      expect(find.text('Attempt direct preview'), findsOneWidget);
      expect(find.text('About You'), findsNothing);
    },
  );

  _isolatedTestWidgets(
    'the global owner selects the live Seeker or Guardian panel',
    (tester) async {
      final seekerOwner = Object();
      final guardianOwner = Object();
      final coordinator = ZyraDevSurfaceCoordinator.instance;
      coordinator.attachSeeker(seekerOwner, (_) {});

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [ZyraGlobalDevOverlay()],
            ),
          ),
        ),
      );
      expect(find.byType(DevScenarioPanelV2), findsOneWidget);
      expect(find.byType(WaliDevScenarioPanel), findsNothing);

      coordinator.attachGuardian(guardianOwner, (_) {});
      await tester.pumpAndSettle();
      expect(find.byType(WaliDevScenarioPanel), findsOneWidget);
      expect(find.byType(DevScenarioPanelV2), findsNothing);

      // A sign-up pushed from either signed-in shell must use the entry tools,
      // then restore the live account tools when the onboarding route closes.
      coordinator.beginEntryFlow('Guardian sign-up');
      await tester.pumpAndSettle();
      expect(find.byType(ZyraEntryDevPanel), findsOneWidget);

      coordinator.endEntryFlow();
      await tester.pumpAndSettle();
      expect(find.byType(WaliDevScenarioPanel), findsOneWidget);

      coordinator.detachGuardian(guardianOwner);
      coordinator.detachSeeker(seekerOwner);
    },
  );

  _isolatedTestWidgets(
    'Entry Home uses a separate Home icon action, not Exit onboarding',
    (tester) async {
      final requests = ValueNotifier<int>(0);
      addTearDown(requests.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [ZyraGlobalDevOverlay(openRequests: requests)],
            ),
          ),
        ),
      );
      requests.value++;
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('dev_controls_tab_home')).hitTestable(),
      );
      await tester.pumpAndSettle();
      final home = find.byKey(const ValueKey('dev_home_navigation'));
      expect(home, findsOneWidget);
      expect(
        find.descendant(of: home, matching: find.byIcon(Icons.home_outlined)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: home, matching: find.text('Home')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('dev_home_section_navigation')),
          matching: home,
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dev_home_exit_onboarding')),
        findsNothing,
      );
      expect(find.text('Exit onboarding'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
