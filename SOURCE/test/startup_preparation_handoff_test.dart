// Cold-start frame integration and shared local-entry lifetime regressions.
// All sessions/claims are synthetic; Auth refresh and HTTP are intercepted.
// These tests do not establish native/provider, live RLS or member admission.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
import 'package:zyra/dev/zyra_concept_preview_boundary.dart';
import 'package:zyra/dev/zyra_dev_local_preview.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/dev/zyra_founder_launch_screen.dart';
import 'package:zyra/dev/zyra_global_dev_overlay.dart';
import 'package:zyra/main.dart';
import 'package:zyra/screens/auth_gate.dart';
import 'package:zyra/screens/splash_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_app_lock.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_full_screen_error.dart';
import 'package:zyra/widgets/zyra_loading.dart';

const _founder = ZyraInternalFounderPolicy.approvedFounderUserId;
const _other = '00000000-0000-4000-8000-000000000977';
const _timeout = Timeout(Duration(seconds: 25));
const _captureDirectory = String.fromEnvironment(
  'ZYRA_STARTUP_RETURN_CAPTURE_DIRECTORY',
);
const _captureBoundary = ValueKey('interrupted-startup-capture');

// Optional UI evidence only. The suite's reading fonts are test stubs, not a
// native typography qualification. Default runs create no files or boundary.
Future<void> _captureReturn(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  expect(_captureDirectory.startsWith('/'), isTrue);
  expect(Directory(_captureDirectory).existsSync(), isTrue);
  final output = File('$_captureDirectory/$name.png');
  expect(
    output.existsSync(),
    isFalse,
    reason: 'Retain immutable review frames',
  );
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureBoundary),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(bytes, isNotNull);
      await output.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

Future<void> _session(String id, {int? expiry = 4102444800, int nonce = 0}) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': id, 'exp': ?expiry, 'nonce': nonce})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': id,
        'app_metadata': id == _founder ? {'zyra_role': 'founder'} : {},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-14T00:00:00Z',
      },
    }),
  );
}

Future<void> _zeroFrames(WidgetTester tester, [int count = 16]) async {
  // Advance real preference/Auth queues without advancing the visible clock.
  for (var frame = 0; frame < count; frame++) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _advance(WidgetTester tester, Duration duration) async {
  // Preserve exact elapsed time while drawing real intermediate frames. The
  // pinned controller completes at the first frame STRICTLY past 3050ms:
  // animation_controller.dart _InterpolationSimulation.isDone uses `>`.
  var remaining = duration.inMicroseconds;
  while (remaining > 0) {
    final step = remaining > 16000 ? 16000 : remaining;
    await tester.pump(Duration(microseconds: step));
    remaining -= step;
  }
}

Future<T> _wait<T>(WidgetTester tester, Future<T> flight) async {
  var done = false;
  T? result;
  Object? failure;
  StackTrace? stack;
  flight.then(
    (value) {
      result = value;
      done = true;
    },
    onError: (Object error, StackTrace trace) {
      failure = error;
      stack = trace;
      done = true;
    },
  );
  for (var frame = 0; frame < 100 && !done; frame++) {
    await _zeroFrames(tester, 1);
  }
  expect(done, isTrue, reason: 'The exact fixture operation must complete');
  if (failure != null) Error.throwWithStackTrace(failure!, stack!);
  return result as T;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Future<User?> Function() refresh;
  var refreshCalls = 0;
  final forwarded = <String>[];

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/local_auth'),
      (_) async => true,
    );
    await Supabase.initialize(
      url: ZyraInternalFounderPolicy.approvedSupabaseUrl,
      publishableKey: 'synthetic-startup-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        // This synthetic session fixture has no native app-link acceptance.
        detectSessionInUri: false,
      ),
      httpClient: ZyraInternalPreviewClient(
        MockClient((request) async {
          forwarded.add(request.url.path);
          return http.Response(
            jsonEncode({'message': 'Unexpected synthetic member operation'}),
            403,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());

  Future<void> initialize(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    SharedPreferences.setMockInitialValues({});
    await _wait(tester, ZyraLocalPrefs.init());
    await _wait(tester, _session(_founder));
    await _wait(tester, ZyraAccountState.synchronize(_founder));
    refreshCalls = 0;
    forwarded.clear();
    refresh = () async => supabase.auth.currentUser;
    ZyraDeveloperAccess.configureAuthorizationForTesting(
      variant: ZyraAppVariant.production,
      currentUser: () => supabase.auth.currentUser,
      refreshSession: () {
        refreshCalls++;
        return refresh();
      },
      founderIdentityMatches: (user) =>
          user.id == _founder && user.appMetadata['zyra_role'] == 'founder',
    );
    // Only compile-time presentation is enabled here. Fresh exact identity
    // and app_metadata still decide every real preparation's proof.
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraDevLocalPreview.genderSelection.value = 'male';
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    ZyraAppLock.instance.clearForSignOut();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _wait(tester, ZyraAccountState.synchronize(null));
    // Leave the static preference tail in the real zone while this widget's
    // fake clock can still drain old listeners. AccountState resets per case.
    var preferencesRehomed = false;
    Zone.root.run(() {
      ZyraLocalPrefs.bindAccount(_founder);
      ZyraLocalPrefs.bindAccount(null).then((_) => preferencesRehomed = true);
    });
    for (var frame = 0; frame < 60 && !preferencesRehomed; frame++) {
      await _zeroFrames(tester, 1);
    }
    expect(
      preferencesRehomed,
      isTrue,
      reason: 'Preference tail leaves the current fake zone before teardown',
    );
    await _wait(tester, ZyraAccountState.synchronize(null));
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    expect(ZyraConceptPreviewIsolation.active, isFalse);
    expect(tester.takeException(), isNull);
  }

  Future<void> mount(
    WidgetTester tester, {
    bool reducedMotion = false,
    bool realOverlay = false,
    GlobalKey<NavigatorState>? navigator,
    Widget home = const AuthGate(),
  }) async {
    final navigatorKey = navigator ?? GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        theme: ThemeData.dark(),
        builder: (context, child) {
          final content = MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reducedMotion),
            child: child!,
          );
          final presented = realOverlay
              ? ZyraGlobalDevOverlayHost(
                  navigatorKey: navigatorKey,
                  // Deliberately use the production Auth stream and refresh
                  // policy, rather than the older empty-stream test seam.
                  child: content,
                )
              : content;
          return _captureDirectory.isEmpty
              ? presented
              : RepaintBoundary(key: _captureBoundary, child: presented);
        },
        home: home,
      ),
    );
    await _zeroFrames(tester);
  }

  testWidgets('runtime quiet wait resets hidden time and disposes its delay', (
    tester,
  ) async {
    await initialize(tester);
    try {
      await mount(tester, home: const ZyraQuietLoading());
      expect(find.byType(ZyraLoading), findsNothing);
      await tester.pump(const Duration(milliseconds: 799));
      expect(find.text('Updating…'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Updating…'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 799));
      expect(find.text('Updating…'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('Updating…'), findsOneWidget);
      expect(find.text('ZYRA'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
      expect(forwarded, isEmpty);
    } finally {
      await close(tester);
    }
  });

  for (final coldGateAlreadyPresented in [false, true]) {
    testWidgets(
      'runtime gate ${coldGateAlreadyPresented ? 'after cold destination' : 'without splash'} never replays Golden',
      (tester) async {
        await initialize(tester);
        final pending = Completer<User?>();
        try {
          if (coldGateAlreadyPresented) {
            await mount(tester);
            await _advance(tester, const Duration(milliseconds: 3051));
            await _zeroFrames(tester);
            expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
            expect(refreshCalls, 2);
            // Finish the existing cold crossfade so the destination really
            // paints, rather than mistaking its zero-alpha first build for
            // an already presented page. This time precedes the warm check.
            await _advance(tester, const Duration(milliseconds: 300));
            await _zeroFrames(tester);
            expect(find.byType(SplashScreen), findsNothing);
            final gate = tester.state(find.byType(AuthGate));
            refresh = () => pending.future;
            await _wait(tester, _session(_founder, nonce: 99));
            // A genuine SDK session replacement re-resolves the same mounted
            // gate; playSplash stays true but this is no longer cold arrival.
            // ignore: invalid_use_of_internal_member
            supabase.auth.notifyAllSubscribers(AuthChangeEvent.signedIn);
            await _zeroFrames(tester);
            expect(refreshCalls, 3);
            expect(tester.state(find.byType(AuthGate)), same(gate));
          } else {
            refresh = () => pending.future;
            await mount(tester, home: const AuthGate(playSplash: false));
            expect(refreshCalls, 1);
          }
          expect(find.byType(SplashScreen), findsNothing);
          expect(find.byType(ZyraLoading), findsNothing);
          expect(find.text('ZYRA'), findsNothing);
          expect(find.text('Updating…'), findsNothing);
          await tester.pump(const Duration(milliseconds: 799));
          expect(find.text('Updating…'), findsNothing);
          await tester.pump(const Duration(milliseconds: 1));
          expect(find.text('Updating…'), findsOneWidget);
          expect(find.byType(ZyraLoading), findsNothing);
          expect(forwarded, isEmpty);
          pending.complete(supabase.auth.currentUser);
          await _zeroFrames(tester);
          // A runtime wait has no one-second success floor.
          expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
          expect(refreshCalls, coldGateAlreadyPresented ? 4 : 2);
          expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
          expect(forwarded, isEmpty);
        } finally {
          if (!pending.isCompleted) pending.complete(supabase.auth.currentUser);
          await close(tester);
        }
      },
      timeout: _timeout,
    );
  }

  testWidgets(
    'runtime fast same-gate replacement cannot retain a cold splash',
    (tester) async {
      await initialize(tester);
      try {
        await mount(tester);
        await _advance(tester, const Duration(milliseconds: 3051));
        await _zeroFrames(tester);
        await _advance(tester, const Duration(milliseconds: 300));
        await _zeroFrames(tester);
        expect(find.byType(SplashScreen), findsNothing);
        expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
        final gate = tester.state(find.byType(AuthGate));
        final originalSurface = tester.state(
          find.byType(ZyraFounderReviewSurface),
        );
        var sessionReady = false;
        _session(_founder, nonce: 100).then((_) => sessionReady = true);
        for (var frame = 0; frame < 40; frame++) {
          await _zeroFrames(tester, 1);
          expect(find.byType(SplashScreen), findsNothing);
          expect(find.byType(ZyraLoading), findsNothing);
          expect(tester.state(find.byType(AuthGate)), same(gate));
        }
        expect(sessionReady, isTrue);
        expect(refreshCalls, 4);
        expect(
          tester
              .stateList(find.byType(ZyraFounderReviewSurface))
              .any((surface) => !identical(surface, originalSurface)),
          isTrue,
          reason: 'The fresh destination commits without a warm minimum.',
        );
        // Only retire AnimatedSwitcher’s outgoing presentation now. This time
        // is not required to commit the fresh route or finish its access work.
        await _advance(tester, const Duration(milliseconds: 300));
        await _zeroFrames(tester);
        expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
        expect(
          tester.state(find.byType(ZyraFounderReviewSurface)),
          isNot(same(originalSurface)),
        );
        expect(forwarded, isEmpty);
      } finally {
        await close(tester);
      }
    },
    timeout: _timeout,
  );

  Future<Completer<User?>> slowSecond(WidgetTester tester) async {
    final pending = Completer<User?>();
    refresh = () => refreshCalls == 2
        ? pending.future
        : Future<User?>.value(supabase.auth.currentUser);
    await mount(tester);
    expect(refreshCalls, 2, reason: 'Both fresh phases begin beneath splash');
    await _advance(tester, const Duration(milliseconds: 3050));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(ZyraLoading), findsNothing);
    await _advance(tester, const Duration(milliseconds: 1));
    expect(find.byType(ZyraLoading), findsNothing);
    expect(find.byType(ZyraQuietLoading), findsOneWidget);
    expect(find.byKey(const ValueKey('zyra_loading_wordmark')), findsNothing);
    expect(find.byType(ZyraFounderReviewSurface), findsNothing);
    expect(AppState.instance.name, isNull);
    return pending;
  }

  for (final playSplash in [false, true]) {
    testWidgets(
      'newly remounted ${playSplash ? 'default cold' : 'runtime'} gate cannot recreate branded loading',
      (tester) async {
        await initialize(tester);
        final pending = Completer<User?>();
        try {
          await mount(tester);
          await _advance(tester, const Duration(milliseconds: 3351));
          await _zeroFrames(tester);
          final previousGate = tester.state(find.byType(AuthGate));
          expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
          expect(refreshCalls, 2);

          // Recreate the navigator/gate, not merely resume the same State.
          // This models the missing lifetime boundary (for example, a
          // privacy-locked subtree or a new routing root), without changing
          // any lock/session policy or faking fresh authorization.
          await tester.pumpWidget(const SizedBox.shrink());
          await _zeroFrames(tester);
          refresh = () => refreshCalls == 3
              ? pending.future
              : Future<User?>.value(supabase.auth.currentUser);
          await mount(tester, home: AuthGate(playSplash: playSplash));
          expect(
            tester.state(find.byType(AuthGate)),
            isNot(same(previousGate)),
          );
          expect(refreshCalls, 3);
          expect(find.byType(ZyraFounderReviewSurface), findsNothing);
          expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
          if (playSplash) {
            expect(find.byType(SplashScreen), findsOneWidget);
            await _advance(tester, const Duration(milliseconds: 3351));
          }
          expect(find.byType(SplashScreen), findsNothing);
          expect(find.byType(ZyraLoading), findsNothing);
          expect(find.byType(ZyraQuietLoading), findsOneWidget);
          expect(find.text('ZYRA'), findsNothing);
          expect(
            find.byKey(const ValueKey('zyra_loading_wordmark')),
            findsNothing,
          );
          expect(find.byType(ZyraFounderReviewSurface), findsNothing);
          expect(forwarded, isEmpty);
          pending.complete(supabase.auth.currentUser);
          await _zeroFrames(tester);
          expect(refreshCalls, 4);
          expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
          expect(find.byType(ZyraLoading), findsNothing);
          expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
          expect(forwarded, isEmpty);
        } finally {
          if (!pending.isCompleted) pending.complete(supabase.auth.currentUser);
          await close(tester);
        }
      },
      timeout: _timeout,
    );
  }

  testWidgets(
    'ready foreground handoff after quiet waiting never reveals outgoing splash',
    (tester) async {
      await initialize(tester);
      Completer<User?>? pending;
      try {
        pending = await slowSecond(tester);
        final gate = tester.state(find.byType(AuthGate));
        final generation = ZyraAccountState.generation;
        pending.complete(supabase.auth.currentUser);
        await _zeroFrames(tester);
        expect(find.byType(ZyraLoading), findsNothing);
        final destination = find.byType(ZyraFounderReviewSurface);
        expect(destination, findsOneWidget);
        final incomingFade = find.ancestor(
          of: destination,
          matching: find.byType(FadeTransition),
        );
        expect(
          tester
              .widgetList<FadeTransition>(incomingFade)
              .every((fade) => fade.opacity.value == 1),
          isTrue,
          reason: 'No destination ancestor may reveal old artwork at alpha0',
        );
        expect(find.byType(SplashScreen), findsNothing);
        expect(find.text('ZYRA').hitTestable(), findsNothing);
        expect(find.byType(ZyraLoading), findsNothing);
        expect(
          find.byKey(const ValueKey('zyra_loading_golden_thread')),
          findsNothing,
        );
        expect(AppState.instance.name, 'Adam');
        expect(ZyraAccountState.userId, _founder);
        expect(ZyraAccountState.generation, generation);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
        expect(refreshCalls, 2);
        expect(forwarded, isEmpty);
        await _captureReturn(tester, 'committed-zero-opacity-before-departure');

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await _captureReturn(tester, 'committed-zero-opacity-first-return');
        expect(tester.state(find.byType(AuthGate)), same(gate));
        expect(find.byType(ZyraLoading), findsNothing);
        expect(find.byType(SplashScreen), findsNothing);
        expect(
          find.byKey(const ValueKey('zyra_loading_golden_thread')),
          findsNothing,
        );
        expect(ZyraAccountState.userId, _founder);
        expect(ZyraAccountState.generation, generation);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
        expect(AppState.instance.name, 'Adam');
        expect(refreshCalls, 2);
        expect(forwarded, isEmpty);
      } finally {
        if (pending != null && !pending.isCompleted) {
          pending.complete(supabase.auth.currentUser);
        }
        await close(tester);
      }
    },
    timeout: _timeout,
  );

  for (final reducedMotion in [false, true]) {
    for (final readyAt in [0, 500, 3049, 3050]) {
      testWidgets(
        'cold ${reducedMotion ? 'still' : 'moving'} preparation ready at ${readyAt}ms has no Golden frame',
        (tester) async {
          await initialize(tester);
          try {
            final pending = Completer<User?>();
            refresh = () => refreshCalls == 2
                ? pending.future
                : Future<User?>.value(supabase.auth.currentUser);
            await mount(tester, reducedMotion: reducedMotion);
            expect(refreshCalls, 2);
            expect(find.byType(SplashScreen), findsOneWidget);
            await _advance(tester, Duration(milliseconds: readyAt));
            pending.complete(supabase.auth.currentUser);
            await _zeroFrames(tester);
            expect(AppState.instance.name, isNull);
            expect(find.byType(ZyraFounderReviewSurface), findsNothing);
            expect(find.byType(ZyraLoading), findsNothing);
            if (readyAt <= 3049) {
              await _advance(tester, Duration(milliseconds: 3049 - readyAt));
            }
            expect(find.byType(SplashScreen), findsOneWidget);
            expect(find.byType(ZyraLoading), findsNothing);
            if (readyAt <= 3049) {
              await _advance(tester, const Duration(milliseconds: 1));
            }
            expect(find.byType(SplashScreen), findsOneWidget);
            expect(find.byType(ZyraLoading), findsNothing);
            await _advance(tester, const Duration(milliseconds: 1));
            // Check each handoff frame rather than settling away a flash.
            for (var frame = 0; frame < 6; frame++) {
              expect(find.byType(ZyraLoading), findsNothing);
              await _zeroFrames(tester, 1);
            }
            expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
            expect(refreshCalls, 2, reason: 'No post-splash third refresh');
            expect(AppState.instance.name, 'Adam');
            expect(forwarded, isEmpty);
          } finally {
            await close(tester);
          }
        },
        timeout: _timeout,
      );
    }
  }

  testWidgets(
    'slow second phase uses quiet waiting and commits fresh readiness without a visual floor',
    (tester) async {
      await initialize(tester);
      try {
        final pending = await slowSecond(tester);
        pending.complete(supabase.auth.currentUser);
        await _zeroFrames(tester);
        expect(find.byType(ZyraLoading), findsNothing);
        expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
        expect(AppState.instance.name, 'Adam');
        expect(refreshCalls, 2);
        expect(forwarded, isEmpty);
      } finally {
        await close(tester);
      }
    },
    timeout: _timeout,
  );

  for (final boundary in [3051, 3052]) {
    testWidgets(
      'readiness at ${boundary}ms commits on a foreground frame without a loading minimum',
      (tester) async {
        await initialize(tester);
        try {
          final pending = Completer<User?>();
          refresh = () => refreshCalls == 2
              ? pending.future
              : Future<User?>.value(supabase.auth.currentUser);
          await mount(tester);
          await _advance(tester, const Duration(milliseconds: 3050));
          expect(find.byType(ZyraLoading), findsNothing);
          // Cover both queue orders around the splash-to-quiet boundary.
          if (boundary == 3051) {
            tester.binding.addPostFrameCallback((_) {
              pending.complete(supabase.auth.currentUser);
            });
          }
          await tester.pump(const Duration(milliseconds: 1));
          expect(find.byType(ZyraLoading), findsNothing);
          if (boundary == 3052) {
            await tester.pump(const Duration(milliseconds: 1));
            pending.complete(supabase.auth.currentUser);
          }
          await _zeroFrames(tester);
          expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
          expect(AppState.instance.name, 'Adam');
          expect(refreshCalls, 2);
          expect(forwarded, isEmpty);
        } finally {
          await close(tester);
        }
      },
      timeout: _timeout,
    );
  }

  for (final withdrawal in [
    'denied refresh',
    'refresh timeout',
    'proof retraction',
  ]) {
    testWidgets('$withdrawal during quiet waiting never commits', (
      tester,
    ) async {
      await initialize(tester);
      try {
        final pending = await slowSecond(tester);
        await tester.pump(const Duration(milliseconds: 40));
        if (withdrawal == 'denied refresh') {
          pending.complete(null);
        } else if (withdrawal == 'refresh timeout') {
          pending.completeError(TimeoutException('Synthetic Auth deadline'));
        } else {
          // Retraction precedes the actual eligible commit frame. It no
          // longer relies on an artificial visual hold to win the race.
          tester.binding.addPostFrameCallback((_) {
            ZyraDeveloperAccess.clearRefreshedClaims();
          });
          pending.complete(supabase.auth.currentUser);
        }
        await _zeroFrames(tester);
        expect(find.byType(ZyraFullScreenError), findsOneWidget);
        expect(find.byType(ZyraFounderReviewSurface), findsNothing);
        expect(AppState.instance.name, isNull);
        expect(forwarded, isEmpty);
      } finally {
        await close(tester);
      }
    }, timeout: _timeout);
  }

  testWidgets(
    'slow startup background withdrawal restarts fresh without replaying splash',
    (tester) async {
      await initialize(tester);
      try {
        final pending = await slowSecond(tester);
        // Finish the original outgoing splash's established 260ms crossfade;
        // subsequent assertions detect a new splash, not that retained frame.
        await tester.pump(const Duration(milliseconds: 300));
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        pending.complete(supabase.auth.currentUser);
        await _zeroFrames(tester);
        expect(AppState.instance.name, isNull);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        for (var frame = 0; frame < 20; frame++) {
          await _zeroFrames(tester, 1);
          expect(find.byType(SplashScreen), findsNothing);
          expect(find.byType(ZyraLoading), findsNothing);
        }
        expect(
          refreshCalls,
          4,
          reason: 'Resume has new routing and preparation',
        );
        // Returning to an interrupted startup is no longer cold arrival.
        // Fresh routing/preparation still ran, but no Golden success floor
        // may delay the newly authorized destination.
        expect(AppState.instance.name, 'Adam');
        expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
        expect(find.byType(SplashScreen), findsNothing);
        expect(find.byType(ZyraLoading), findsNothing);
        expect(forwarded, isEmpty);
      } finally {
        await close(tester);
      }
    },
    timeout: _timeout,
  );

  testWidgets(
    'initial hidden mount preserves the first foreground cold splash',
    (tester) async {
      await initialize(tester);
      try {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await mount(tester);
        final gate = tester.state(find.byType(AuthGate));
        expect(AppState.instance.name, isNull);
        expect(find.byType(ZyraFounderReviewSurface), findsNothing);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await _zeroFrames(tester);
        expect(tester.state(find.byType(AuthGate)), same(gate));
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.byType(ZyraLoading), findsNothing);
        await _advance(tester, const Duration(milliseconds: 3049));
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.byType(ZyraLoading), findsNothing);
        expect(AppState.instance.name, isNull);
        await _advance(tester, const Duration(milliseconds: 1));
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.byType(ZyraLoading), findsNothing);
        await _advance(tester, const Duration(milliseconds: 1));
        await _zeroFrames(tester);
        expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
        expect(AppState.instance.name, 'Adam');
        expect(find.byType(ZyraLoading), findsNothing);
        expect(forwarded, isEmpty);
      } finally {
        await close(tester);
      }
    },
    timeout: _timeout,
  );

  for (final reducedMotion in [false, true]) {
    for (final interruptedAt in [500, 3051]) {
      testWidgets(
        'interrupted startup at ${interruptedAt}ms ${reducedMotion ? 'still' : 'moving'} returns quietly while fresh authorization remains pending',
        (tester) async {
          await initialize(tester);
          final oldPending = Completer<User?>();
          final freshRouting = Completer<User?>();
          final freshPreparation = Completer<User?>();
          try {
            refresh = () => refreshCalls == 2
                ? oldPending.future
                : Future<User?>.value(supabase.auth.currentUser);
            await mount(tester, reducedMotion: reducedMotion);
            final gate = tester.state(find.byType(AuthGate));
            final generation = ZyraAccountState.generation;
            final staleSplashFinished = tester
                .widget<SplashScreen>(find.byType(SplashScreen))
                .onFinished!;
            expect(refreshCalls, 2);
            await _advance(tester, Duration(milliseconds: interruptedAt));
            if (interruptedAt == 500) {
              expect(find.byType(SplashScreen), findsOneWidget);
            }
            expect(find.byType(ZyraLoading), findsNothing);
            if (interruptedAt == 3051) {
              expect(find.byType(ZyraQuietLoading), findsOneWidget);
            }
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.inactive,
            );
            // Completing the abandoned second phase while hidden must not
            // publish that persona or reuse its former startup operation.
            oldPending.complete(supabase.auth.currentUser);
            await _zeroFrames(tester);
            expect(AppState.instance.name, isNull);
            expect(find.byType(ZyraFounderReviewSurface), findsNothing);
            expect(refreshCalls, 2);
            expect(forwarded, isEmpty);

            refresh = () => refreshCalls == 3
                ? freshRouting.future
                : freshPreparation.future;
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            );
            await tester.pump();
            expect(tester.state(find.byType(AuthGate)), same(gate));
            expect(find.byType(SplashScreen), findsNothing);
            expect(find.byType(ZyraLoading), findsNothing);
            final captureVariant = interruptedAt == 500 && !reducedMotion;
            if (captureVariant) {
              await _captureReturn(
                tester,
                'interrupted-500-moving-first-return',
              );
            }
            // The outgoing recovery page can still have a brand header in
            // AnimatedSwitcher, but the opaque quiet wait covers it. Assert
            // the actual current surface and that no old header is exposed.
            expect(find.byType(ZyraQuietLoading), findsOneWidget);
            expect(find.text('ZYRA').hitTestable(), findsNothing);
            await _zeroFrames(tester);
            expect(refreshCalls, 3, reason: 'Return must begin fresh routing');
            expect(find.byType(ZyraQuietLoading), findsOneWidget);
            expect(AppState.instance.name, isNull);
            expect(find.byType(ZyraFounderReviewSurface), findsNothing);
            expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
            // An old splash callback is presentation-only and cannot end the
            // new refresh, authorize a destination or revive cold artwork.
            staleSplashFinished();
            staleSplashFinished();
            await _zeroFrames(tester);
            expect(refreshCalls, 3);
            expect(AppState.instance.name, isNull);
            expect(find.byType(SplashScreen), findsNothing);
            expect(find.byType(ZyraLoading), findsNothing);
            freshRouting.complete(supabase.auth.currentUser);
            await _zeroFrames(tester);
            expect(
              refreshCalls,
              4,
              reason: 'Preparation also needs fresh proof',
            );
            expect(find.byType(ZyraFounderReviewSurface), findsNothing);
            expect(AppState.instance.name, isNull);
            expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
            await tester.pump(const Duration(milliseconds: 799));
            expect(find.text('Updating…'), findsNothing);
            expect(find.byType(SplashScreen), findsNothing);
            expect(find.byType(ZyraLoading), findsNothing);
            await tester.pump(const Duration(milliseconds: 1));
            expect(find.text('Updating…'), findsOneWidget);
            expect(find.byType(SplashScreen), findsNothing);
            expect(find.byType(ZyraLoading), findsNothing);
            expect(find.text('ZYRA'), findsNothing);
            expect(AppState.instance.name, isNull);
            expect(find.byType(ZyraFounderReviewSurface), findsNothing);
            expect(forwarded, isEmpty);

            freshPreparation.complete(supabase.auth.currentUser);
            // Drain asynchronous work without adding a one-second hold or
            // waiting for the remainder of the abandoned cold splash.
            for (var frame = 0; frame < 20; frame++) {
              await _zeroFrames(tester, 1);
              expect(tester.state(find.byType(AuthGate)), same(gate));
              expect(find.byType(SplashScreen), findsNothing);
              expect(find.byType(ZyraLoading), findsNothing);
            }
            expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
            expect(AppState.instance.name, 'Adam');
            expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
            expect(ZyraAccountState.generation, generation);
            expect(refreshCalls, 4);
            expect(forwarded, isEmpty);
            if (captureVariant && _captureDirectory.isNotEmpty) {
              // Readiness above was asserted without advancing the clock.
              // Only the optional PNG waits for the existing crossfade to
              // paint its incoming destination fully.
              await _advance(tester, const Duration(milliseconds: 300));
              await _zeroFrames(tester);
              await _captureReturn(tester, 'interrupted-500-moving-ready');
            }
          } finally {
            for (final pending in [
              oldPending,
              freshRouting,
              freshPreparation,
            ]) {
              if (!pending.isCompleted) {
                pending.complete(supabase.auth.currentUser);
              }
            }
            await close(tester);
          }
        },
        timeout: _timeout,
      );
    }
  }

  testWidgets(
    'disposing startup while second refresh is pending cannot publish a persona later',
    (tester) async {
      await initialize(tester);
      try {
        final pending = Completer<User?>();
        refresh = () => refreshCalls == 2
            ? pending.future
            : Future<User?>.value(supabase.auth.currentUser);
        await mount(tester);
        await tester.pumpWidget(const SizedBox.shrink());
        pending.complete(supabase.auth.currentUser);
        await _zeroFrames(tester);
        expect(AppState.instance.name, isNull);
        expect(ZyraConceptPreviewIsolation.active, isFalse);
        expect(forwarded, isEmpty);
      } finally {
        await close(tester);
      }
    },
    timeout: _timeout,
  );

  for (final replacement in [
    'account ABA',
    'SDK ABA',
    'same-ID fresh session',
    'proof ABA',
    'preference rebind',
  ]) {
    testWidgets(
      'shared preparation terminally rejects $replacement and consumes stale commit',
      (tester) async {
        await initialize(tester);
        try {
          final preparation = await _wait(
            tester,
            ZyraDevLocalPreview.prepare(current: () => true, isWali: false),
          );
          expect(preparation, isNotNull);
          expect(preparation!.isReady, isTrue);
          expect(AppState.instance.name, isNull);
          switch (replacement) {
            case 'account ABA':
              await _wait(tester, ZyraAccountState.synchronize(_other));
              await _wait(tester, ZyraAccountState.synchronize(_founder));
            case 'SDK ABA':
              await _wait(tester, _session(_other));
              await _zeroFrames(tester);
              await _wait(tester, _session(_founder));
            case 'same-ID fresh session':
              await _wait(tester, _session(_founder, nonce: 1));
              // Synthetic SDK broadcast only, not a native login operation.
              // ignore: invalid_use_of_internal_member
              supabase.auth.notifyAllSubscribers(AuthChangeEvent.signedIn);
            case 'proof ABA':
              ZyraDeveloperAccess.clearRefreshedClaims();
              await _wait(
                tester,
                ZyraDeveloperAccess.refreshCurrentAuthorizationSnapshot(),
              );
            case 'preference rebind':
              await _wait(tester, ZyraLocalPrefs.bindAccount(null));
              await _wait(tester, ZyraLocalPrefs.bindAccount(_founder));
          }
          await _zeroFrames(tester);
          expect(preparation.isReady, isFalse);
          expect(preparation.commit(), isNull);
          expect(preparation.commit(), isNull);
          expect(AppState.instance.name, isNull);
          expect(forwarded, isEmpty);
        } finally {
          await close(tester);
        }
      },
      timeout: _timeout,
    );
  }

  for (final cover in ['popup', 'fullscreen']) {
    testWidgets(
      'shared preparation cannot be revived after a painted $cover cover',
      (tester) async {
        await initialize(tester);
        try {
          final navigator = GlobalKey<NavigatorState>();
          late BuildContext origin;
          await mount(
            tester,
            navigator: navigator,
            home: Builder(
              builder: (context) {
                origin = context;
                return const Scaffold(body: Text('Origin'));
              },
            ),
          );
          final pending = Completer<User?>();
          refresh = () => pending.future;
          final route = ModalRoute.of(origin)!;
          final preparation = ZyraDevLocalPreview.prepare(
            current: () => route.isCurrent,
            route: route,
            isWali: false,
          );
          await _zeroFrames(tester);
          if (cover == 'popup') {
            unawaited(
              showModalBottomSheet<void>(
                context: origin,
                builder: (_) =>
                    const SizedBox(height: 120, child: Text('Cover')),
              ),
            );
          } else {
            unawaited(
              navigator.currentState!.push(
                MaterialPageRoute<void>(
                  fullscreenDialog: true,
                  builder: (_) => const Scaffold(body: Text('Cover')),
                ),
              ),
            );
          }
          await tester.pump();
          await _advance(tester, const Duration(milliseconds: 400));
          expect(find.text('Cover').hitTestable(), findsOneWidget);
          navigator.currentState!.pop();
          await tester.pump(const Duration(milliseconds: 400));
          expect(route.isCurrent, isTrue);
          pending.complete(supabase.auth.currentUser);
          expect(await _wait(tester, preparation), isNull);
          expect(AppState.instance.name, isNull);
          expect(forwarded, isEmpty);
        } finally {
          await close(tester);
        }
      },
      timeout: _timeout,
    );
  }

  for (final expiry in <int?>[null, 1]) {
    testWidgets(
      '${expiry == null ? 'unknown' : 'expired'} SDK expiry cannot prepare or commit Founder state',
      (tester) async {
        await initialize(tester);
        try {
          await _wait(tester, _session(_founder, expiry: expiry));
          expect(
            await _wait(
              tester,
              ZyraDevLocalPreview.prepare(current: () => true, isWali: false),
            ),
            isNull,
          );
          expect(AppState.instance.name, isNull);
          expect(ZyraConceptPreviewIsolation.active, isFalse);
          expect(forwarded, isEmpty);
        } finally {
          await close(tester);
        }
      },
      timeout: _timeout,
    );
  }

  testWidgets(
    'AppLock obscuration permanently withdraws preparation without counting hidden paint',
    (tester) async {
      await initialize(tester);
      try {
        expect(
          await _wait(tester, ZyraAppLock.instance.setEnabled(true)),
          isTrue,
        );
        final preparation = await _wait(
          tester,
          ZyraDevLocalPreview.prepare(current: () => true, isWali: false),
        );
        expect(preparation, isNotNull);
        ZyraAppLock.instance.handleLifecycle(AppLifecycleState.inactive);
        expect(ZyraAppLock.instance.isObscured, isTrue);
        ZyraAppLock.instance.handleLifecycle(AppLifecycleState.resumed);
        expect(preparation!.isReady, isFalse);
        expect(preparation.commit(), isNull);
        expect(AppState.instance.name, isNull);
        expect(forwarded, isEmpty);
      } finally {
        await close(tester);
      }
    },
    timeout: _timeout,
  );

  testWidgets(
    'a valid shared preparation commits once and releases its frame watch',
    (tester) async {
      await initialize(tester);
      try {
        final preparation = await _wait(
          tester,
          ZyraDevLocalPreview.prepare(current: () => true, isWali: false),
        );
        expect(preparation, isNotNull);
        expect(AppState.instance.name, isNull);
        final actual = supabase.auth.currentSession!;
        final forged = actual.toJson();
        forged['user'] = {...actual.user.toJson(), 'id': _other};
        // Exercise the real synthetic SDK stream, never a live refresh.
        // ignore: invalid_use_of_internal_member
        supabase.auth.notifyAllSubscribers(AuthChangeEvent.tokenRefreshed);
        // ignore: invalid_use_of_internal_member
        supabase.auth.notifyAllSubscribers(AuthChangeEvent.signedIn);
        // ignore: invalid_use_of_internal_member
        supabase.auth.notifyAllSubscribers(
          AuthChangeEvent.tokenRefreshed,
          session: Session.fromJson(forged),
        );
        await _zeroFrames(tester);
        expect(
          preparation!.isReady,
          isTrue,
          reason: 'Identical healthy replay and non-SDK payload are not login',
        );
        final presentation = preparation.commit();
        expect(presentation, isNotNull);
        expect(
          presentation!.buildDestination(),
          isA<ZyraFounderReviewSurface>(),
        );
        expect(AppState.instance.name, 'Adam');
        expect(preparation.commit(), isNull);
        await tester.pump(const Duration(seconds: 2));
        expect(tester.binding.transientCallbackCount, 0);
        expect(forwarded, isEmpty);
      } finally {
        await close(tester);
      }
    },
    timeout: _timeout,
  );

  testWidgets(
    'slow initial routing stays unbranded and needs no visual hold or third refresh',
    (tester) async {
      await initialize(tester);
      try {
        final pending = Completer<User?>();
        refresh = () => refreshCalls == 1
            ? pending.future
            : Future<User?>.value(supabase.auth.currentUser);
        await mount(tester);
        expect(refreshCalls, 1);
        await _advance(tester, const Duration(milliseconds: 3050));
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.byType(ZyraLoading), findsNothing);
        await _advance(tester, const Duration(milliseconds: 1));
        expect(find.byType(ZyraLoading), findsNothing);
        expect(find.byType(ZyraQuietLoading), findsOneWidget);
        expect(AppState.instance.name, isNull);
        pending.complete(supabase.auth.currentUser);
        await _zeroFrames(tester);
        expect(refreshCalls, 2);
        expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
        expect(AppState.instance.name, 'Adam');
        expect(refreshCalls, 2);
        expect(forwarded, isEmpty);
      } finally {
        await close(tester);
      }
    },
    timeout: _timeout,
  );

  testWidgets(
    'throwing originating predicate fails closed and releases pending observers',
    (tester) async {
      await initialize(tester);
      try {
        expect(
          await _wait(
            tester,
            ZyraDevLocalPreview.prepare(
              current: () => throw StateError('Synthetic disposed origin'),
              isWali: false,
            ),
          ),
          isNull,
        );
        expect(refreshCalls, 0);
        expect(AppState.instance.name, isNull);
        await tester.pump();
        expect(tester.binding.transientCallbackCount, 0);
      } finally {
        await close(tester);
      }
    },
    timeout: _timeout,
  );

  testWidgets(
    'replacing Founder launch owner props cannot revive the original pending entry',
    (tester) async {
      await initialize(tester);
      try {
        final pending = Completer<User?>();
        refresh = () => pending.future;
        final generation = ZyraAccountState.generation;
        const key = ValueKey('retained-founder-launch');
        final navigator = GlobalKey<NavigatorState>();
        await mount(
          tester,
          navigator: navigator,
          home: ZyraFounderLaunchScreen(
            key: key,
            ownerId: _founder,
            ownerGeneration: generation,
          ),
        );
        expect(refreshCalls, 1);
        final originalState = tester.state(find.byKey(key));
        await mount(
          tester,
          navigator: navigator,
          home: ZyraFounderLaunchScreen(
            key: key,
            ownerId: _other,
            ownerGeneration: generation,
          ),
        );
        expect(identical(tester.state(find.byKey(key)), originalState), isTrue);
        expect(
          tester.widget<ZyraFounderLaunchScreen>(find.byKey(key)).ownerId,
          _other,
        );
        await mount(
          tester,
          navigator: navigator,
          home: ZyraFounderLaunchScreen(
            key: key,
            ownerId: _founder,
            ownerGeneration: generation,
          ),
        );
        expect(identical(tester.state(find.byKey(key)), originalState), isTrue);
        pending.complete(supabase.auth.currentUser);
        await _zeroFrames(tester);
        expect(find.byType(ZyraFounderReviewSurface), findsNothing);
        expect(AppState.instance.name, isNull);
        expect(find.text('Couldn’t open this page.'), findsOneWidget);
        expect(forwarded, isEmpty);
      } finally {
        await close(tester);
      }
    },
    timeout: _timeout,
  );

  testWidgets(
    'real overlay Auth listener joins both cold phases without a post-splash refresh or Golden frame',
    (tester) async {
      await initialize(tester);
      try {
        refresh = () async {
          // SDK's real broadcast stream, current synthetic Session. This is
          // not a forged-event override or a native/provider refresh.
          // ignore: invalid_use_of_internal_member
          supabase.auth.notifyAllSubscribers(AuthChangeEvent.tokenRefreshed);
          await Future<void>.value();
          return supabase.auth.currentUser;
        };
        await mount(tester, realOverlay: true);
        expect(refreshCalls, 2);
        expect(find.byType(ZyraGlobalDevOverlayHost), findsOneWidget);
        expect(AppState.instance.name, isNull);
        await _advance(tester, const Duration(milliseconds: 3049));
        expect(find.byType(ZyraLoading), findsNothing);
        await _advance(tester, const Duration(milliseconds: 1));
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.byType(ZyraLoading), findsNothing);
        await _advance(tester, const Duration(milliseconds: 1));
        for (var frame = 0; frame < 8; frame++) {
          expect(find.byType(ZyraLoading), findsNothing);
          await _zeroFrames(tester, 1);
        }
        expect(find.byType(ZyraFounderReviewSurface), findsOneWidget);
        expect(refreshCalls, 2);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isTrue);
        expect(ZyraInternalPreviewClient.isActive, isTrue);
        expect(forwarded, isEmpty);
      } finally {
        await close(tester);
      }
    },
    timeout: _timeout,
  );

  testWidgets(
    'queued SDK ABA during a pending owned refresh cannot become its prepared lifetime',
    (tester) async {
      await initialize(tester);
      try {
        final pending = Completer<User?>();
        refresh = () => pending.future;
        final oldIntent = ZyraDevLocalPreview.prepare(
          current: () => true,
          isWali: false,
        );
        await _zeroFrames(tester);
        expect(refreshCalls, 1);
        final generation = ZyraAccountState.generation;
        final originalSession = supabase.auth.currentSession;
        // No await, pump or AccountState bind between these SDK replacements
        // and the pending Auth response. The original intent must not adopt
        // the returned A2 session merely because the final UUID is A again.
        unawaited(_session(_other));
        expect(supabase.auth.currentUser?.id, _other);
        unawaited(_session(_founder, nonce: 2));
        expect(supabase.auth.currentUser?.id, _founder);
        expect(
          identical(supabase.auth.currentSession, originalSession),
          isFalse,
        );
        pending.complete(supabase.auth.currentUser);
        final preparation = await _wait(tester, oldIntent);
        expect(ZyraAccountState.generation, generation);
        expect(preparation, isNull);
        expect(AppState.instance.name, isNull);
        expect(forwarded, isEmpty);
      } finally {
        await close(tester);
      }
    },
    timeout: _timeout,
  );
}
