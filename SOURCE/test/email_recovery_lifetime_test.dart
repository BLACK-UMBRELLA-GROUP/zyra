import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/screens/auth/email_recovery_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_auth.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_text.dart';

const _owner = '00000000-0000-4000-8000-000000000906';

Future<void> _session(String userId) async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': userId, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': userId,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-06T00:00:00Z',
      },
    }),
  );
  await ZyraAccountState.synchronize(userId);
}

Future<void> _mount(
  WidgetTester tester, {
  RecoveryCodeSender? sender,
  RecoveryCodeVerifier? verifier,
  Future<void> Function()? recovered,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: EmailRecoveryScreen(
        sendCode: sender ?? (_) async => const ZyraAuthResult.success(),
        verifyCode:
            verifier ??
            ({required email, required code}) async =>
                const ZyraAuthResult.success(),
        onRecovered: recovered ?? () async {},
      ),
    ),
  );
  await tester.enterText(
    find.byKey(const ValueKey('recovery_signin_email')),
    'member@example.invalid',
  );
}

Future<void> _showCode(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('recovery_signin_send')));
  await tester.pump();
  await tester.enterText(
    find.byKey(const ValueKey('recovery_signin_code')),
    '123456',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      // Every request is intercepted. There is no real provider/account.
      httpClient: MockClient(
        (request) async => http.Response(
          '{}',
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    await ZyraLocalPrefs.init();
  });
  setUp(() async {
    await supabase.auth.signOut(scope: SignOutScope.local);
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await ZyraAccountState.synchronize(null);
    ZyraText.useTestFontStubs = true;
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraAccountState.clearImagesForTesting = null;
  });
  tearDownAll(() => Supabase.instance.dispose());

  testWidgets('thrown recovery sender releases busy and offers retry', (
    tester,
  ) async {
    var calls = 0;
    await _mount(
      tester,
      sender: (_) async {
        calls++;
        throw StateError('Synthetic private sender error');
      },
    );
    await tester.tap(find.byKey(const ValueKey('recovery_signin_send')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('recovery_signin_send')),
          )
          .onPressed,
      isNotNull,
    );
    expect(find.textContaining('Synthetic private'), findsNothing);
    expect(calls, 1);
  });

  testWidgets('thrown recovery verifier releases busy and retains code retry', (
    tester,
  ) async {
    await _mount(
      tester,
      verifier: ({required email, required code}) async {
        throw StateError('Synthetic private verifier error');
      },
    );
    await _showCode(tester);
    await tester.tap(find.byKey(const ValueKey('recovery_signin_verify')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('recovery_signin_verify')),
          )
          .onPressed,
      isNotNull,
    );
    expect(find.textContaining('Synthetic private'), findsNothing);
  });

  testWidgets('thrown recovered routing releases busy without claiming entry', (
    tester,
  ) async {
    await _mount(
      tester,
      recovered: () async {
        throw StateError('Synthetic private routing error');
      },
    );
    await _showCode(tester);
    await tester.tap(find.byKey(const ValueKey('recovery_signin_verify')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.byKey(const ValueKey('recovery_signin_verify')),
      findsOneWidget,
    );
    expect(find.textContaining('Synthetic private'), findsNothing);
  });

  testWidgets('retained duplicate send callback starts only one request', (
    tester,
  ) async {
    final response = Completer<ZyraAuthResult>();
    var calls = 0;
    await _mount(
      tester,
      sender: (_) {
        calls++;
        return response.future;
      },
    );
    final action = tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('recovery_signin_send')),
        )
        .onPressed!;
    action();
    action();
    await tester.pump();
    expect(calls, 1);
    response.complete(const ZyraAuthResult.cancelled());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'retained change-email callback cannot reset pending verification',
    (tester) async {
      final response = Completer<ZyraAuthResult>();
      var entries = 0;
      await _mount(
        tester,
        verifier: ({required email, required code}) => response.future,
        recovered: () async {
          entries++;
        },
      );
      await _showCode(tester);
      final change = tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Use a different email'),
          )
          .onPressed!;
      await tester.tap(find.byKey(const ValueKey('recovery_signin_verify')));
      // A callback retained from before the pending frame cannot reset its work.
      change();
      await tester.pump();
      response.complete(const ZyraAuthResult.success());
      await tester.pump();
      expect(entries, 1);
      expect(
        find.byKey(const ValueKey('recovery_signin_code')),
        findsOneWidget,
      );
    },
  );

  testWidgets('late recovery send cannot publish after account replacement', (
    tester,
  ) async {
    final response = Completer<ZyraAuthResult>();
    await _mount(tester, sender: (_) => response.future);
    await tester.tap(find.byKey(const ValueKey('recovery_signin_send')));
    await tester.pump();
    await tester.runAsync(() => _session(_owner));
    response.complete(const ZyraAuthResult.success());
    await tester.pump();
    expect(find.text('Check your email.'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelled verifier releases busy without entry', (tester) async {
    var entries = 0;
    await _mount(
      tester,
      verifier: ({required email, required code}) async =>
          const ZyraAuthResult.cancelled(),
      recovered: () async {
        entries++;
      },
    );
    await _showCode(tester);
    await tester.tap(find.byKey(const ValueKey('recovery_signin_verify')));
    await tester.pump();
    expect(entries, 0);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retained duplicate verify callback starts only one request', (
    tester,
  ) async {
    final response = Completer<ZyraAuthResult>();
    var calls = 0;
    var entries = 0;
    await _mount(
      tester,
      verifier: ({required email, required code}) {
        calls++;
        return response.future;
      },
      recovered: () async {
        entries++;
      },
    );
    await _showCode(tester);
    final action = tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('recovery_signin_verify')),
        )
        .onPressed!;
    action();
    action();
    await tester.pump();
    expect(calls, 1);
    response.complete(const ZyraAuthResult.success());
    await tester.pump();
    expect(entries, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('foreign account during verification cannot enter recovery', (
    tester,
  ) async {
    final response = Completer<ZyraAuthResult>();
    var entries = 0;
    await _mount(
      tester,
      verifier: ({required email, required code}) => response.future,
      recovered: () async {
        entries++;
      },
    );
    await _showCode(tester);
    await tester.tap(find.byKey(const ValueKey('recovery_signin_verify')));
    await tester.runAsync(() => _session(_owner));
    response.complete(const ZyraAuthResult.success());
    await tester.pump();
    expect(entries, 0);
    expect(find.byKey(const ValueKey('recovery_signin_code')), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('legitimate signed-out to verified-owner handoff still enters', (
    tester,
  ) async {
    final response = Completer<ZyraAuthResult>();
    var entries = 0;
    await _mount(
      tester,
      verifier: ({required email, required code}) => response.future,
      recovered: () async {
        entries++;
      },
    );
    await _showCode(tester);
    await tester.tap(find.byKey(const ValueKey('recovery_signin_verify')));
    await tester.runAsync(() => _session(_owner));
    response.complete(
      const ZyraAuthResult.success(authenticatedUserId: _owner),
    );
    await tester.pump();
    expect(entries, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'foreign account during post-OTP routing cannot publish routing error',
    (tester) async {
      final route = Completer<void>();
      await _mount(tester, recovered: () => route.future);
      await _showCode(tester);
      await tester.tap(find.byKey(const ValueKey('recovery_signin_verify')));
      await tester.pump();
      await tester.runAsync(() => _session(_owner));
      route.completeError(StateError('Synthetic obsolete route'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('Having trouble connecting'), findsNothing);
      expect(find.byKey(const ValueKey('recovery_signin_code')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('disposed recovery ignores a late thrown sender', (tester) async {
    final response = Completer<ZyraAuthResult>();
    await _mount(tester, sender: (_) => response.future);
    await tester.tap(find.byKey(const ValueKey('recovery_signin_send')));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    response.completeError(StateError('Synthetic disposed result'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pending sender is withdrawn before a replaced-account response settles',
    (tester) async {
      final response = Completer<ZyraAuthResult>();
      await _mount(tester, sender: (_) => response.future);
      await tester.tap(find.byKey(const ValueKey('recovery_signin_send')));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.runAsync(() => _session(_owner));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      // Withdrawal happens while the sender is still pending, not on its result.
      response.complete(const ZyraAuthResult.success());
      await tester.pump();
      expect(find.text('Check your email.'), findsNothing);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    },
  );
}
