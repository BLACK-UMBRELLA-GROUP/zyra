import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/main.dart';
import 'package:zyra/screens/auth_gate.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_auth.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_full_screen_error.dart';

const _a = '00000000-0000-4000-8000-000000000916';
const _b = '00000000-0000-4000-8000-000000000917';

Future<void> _session(String id, {bool awaitCleanup = true}) async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': id, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': id,
        'app_metadata': {
          'provider': 'google',
          'providers': ['google'],
        },
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-06T00:00:00Z',
      },
    }),
  );
  if (!ZyraAccountState.isSigningOut) {
    final cleanup = ZyraAccountState.synchronize(id);
    if (awaitCleanup) await cleanup;
  }
}

Future<ZyraFullScreenError> _error(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const MaterialApp(home: AuthGate(playSplash: false)));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pumpAndSettle();
  return tester.widget<ZyraFullScreenError>(find.byType(ZyraFullScreenError));
}

Future<void> _disposeAndDrain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  expect(find.byType(AuthGate), findsNothing);
  var drained = false;
  ZyraAccountState.synchronize(supabase.auth.currentUser?.id).then((_) {
    drained = true;
  });
  for (var frame = 0; frame < 20 && !drained; frame++) {
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(
    drained,
    isTrue,
    reason: 'Fixture cleanup must finish in its own zone',
  );
}

Future<void> _startExit(ZyraFullScreenError error) {
  final dynamic action = error.onPrimary;
  // The native button type discards the async callback result. Keep this
  // exact public callback Future so an SDK-null intermediate state is not
  // mistaken for completed cleanup and a completed navigation handoff.
  return action() as Future<void>;
}

Future<void> _settleExit(WidgetTester tester, Future<void> flight) async {
  var settled = false;
  Object? failure;
  StackTrace? failureStack;
  flight.then(
    (_) => settled = true,
    onError: (Object error, StackTrace stack) {
      failure = error;
      failureStack = stack;
      settled = true;
    },
  );
  for (var frame = 0; frame < 80 && !settled; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
  expect(settled, isTrue, reason: 'The originating exit callback completed');
  if (failure != null) Error.throwWithStackTrace(failure!, failureStack!);
  await tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 2),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.app_links/messages'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.app_links/events'),
      (_) async => null,
    );
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'message': 'Session expired synthetic',
            'code': 'PGRST301',
          }),
          401,
          request: request,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
  });
  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await ZyraAccountState.synchronize(null);
    await _session(_a);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.configureAuthorizationForTesting(
      variant: ZyraAppVariant.production,
      currentUser: () => supabase.auth.currentUser,
      refreshSession: () async => supabase.auth.currentUser,
      founderIdentityMatches: (_) => false,
    );
    ZyraAuth.setGoogleSignOutForTesting(() async {});
  });
  tearDown(() {
    ZyraAuth.setGoogleSignOutForTesting(null);
    ZyraAccountState.clearImagesForTesting = null;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
    debugDefaultTargetPlatformOverride = null;
  });
  tearDownAll(() => Supabase.instance.dispose());

  testWidgets(
    'expired-account callbacks are owner-bound, duplicate-safe and replacement-safe',
    (tester) async {
      // These three independently reset scenarios deliberately share a single
      // FakeAsync zone: static account/prefs Futures must not outlive that zone.
      {
        final error = await _error(tester);
        await tester.runAsync(() => _session(_b, awaitCleanup: false));
        await _settleExit(tester, _startExit(error));
        expect(
          supabase.auth.currentUser?.id,
          _b,
          reason: 'Retained A exit cannot sign out B',
        );
        expect(find.byType(WelcomeScreen), findsNothing);
        expect(tester.takeException(), isNull);
        await _disposeAndDrain(tester);
      }
      ZyraAccountState.resetForTesting();
      await tester.runAsync(() => _session(_a, awaitCleanup: false));
      await _disposeAndDrain(tester);
      {
        final error = await _error(tester);
        final release = Completer<void>();
        var calls = 0;
        ZyraAuth.setGoogleSignOutForTesting(() {
          calls++;
          return release.future;
        });
        final firstExit = _startExit(error);
        final duplicateExit = _startExit(error);
        await tester.pump();
        expect(calls, 1, reason: 'Retained duplicate exit has one owner');
        expect(
          find.byType(WelcomeScreen),
          findsNothing,
          reason: 'Welcome waits for actual sign-out completion',
        );
        release.complete();
        await _settleExit(
          tester,
          Future.wait([firstExit, duplicateExit]).then((_) {}),
        );
        expect(supabase.auth.currentUser, isNull);
        expect(find.byType(WelcomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _disposeAndDrain(tester);
      }
      ZyraAccountState.resetForTesting();
      await tester.runAsync(() => _session(_a, awaitCleanup: false));
      await _disposeAndDrain(tester);
      {
        final error = await _error(tester);
        final release = Completer<void>();
        ZyraAuth.setGoogleSignOutForTesting(() => release.future);
        final exit = _startExit(error);
        await tester.pump();
        await tester.runAsync(() => _session(_b, awaitCleanup: false));
        release.complete();
        await _settleExit(tester, exit);
        expect(
          supabase.auth.currentUser?.id,
          _b,
          reason: 'Replacement during exit retains B session',
        );
        expect(find.byType(WelcomeScreen), findsNothing);
        expect(
          find.byType(ZyraFullScreenError),
          findsOneWidget,
          reason: 'B gets fresh routing/recovery, never a permanent spinner',
        );
        expect(tester.takeException(), isNull);
        await _disposeAndDrain(tester);
      }
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
