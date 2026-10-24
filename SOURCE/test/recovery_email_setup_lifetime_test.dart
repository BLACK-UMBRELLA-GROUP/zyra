import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/screens/settings/sign_in_security_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_text.dart';

// This exercises authenticated recovery-email SETUP, not email sign-in.
// Every Auth request is intercepted in memory; no provider or account exists.
const _a = '00000000-0000-4000-8000-000000000946';
const _b = '00000000-0000-4000-8000-000000000947';
const _recovery = 'recovery@example.invalid';
const _accountEmail = 'account@example.invalid';
const _send = 'recovery_setup_send';
const _verifyNew = 'recovery_setup_verify_new';
const _verifyCurrent = 'recovery_setup_verify_current';

Map<String, Object?> _user(String id, {bool recoveryVerified = false}) => {
  'id': id,
  'app_metadata': {
    'provider': 'google',
    'providers': ['google', if (recoveryVerified) 'email'],
  },
  'user_metadata': <String, Object?>{},
  'aud': 'authenticated',
  'email': recoveryVerified ? _recovery : _accountEmail,
  'created_at': '2026-10-10T00:00:00Z',
  'identities': [
    for (final provider in ['google', if (recoveryVerified) 'email'])
      {
        'id': '$id-$provider',
        'user_id': id,
        'identity_id': '$id-$provider-subject',
        'provider': provider,
        'identity_data': {
          'email': provider == 'email' ? _recovery : _accountEmail,
          'email_verified': true,
        },
        'created_at': '2026-10-10T00:00:00Z',
        'updated_at': '2026-10-10T00:00:00Z',
        'last_sign_in_at': '2026-10-10T00:00:00Z',
      },
  ],
};

Map<String, Object?> _sessionData(String id, {bool recoveryVerified = false}) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return {
    'access_token':
        '${part({'alg': 'none'})}.${part({'sub': id, 'exp': 4102444800})}.synthetic',
    'token_type': 'bearer',
    'refresh_token': 'synthetic-refresh',
    'expires_in': 3600,
    'user': _user(id, recoveryVerified: recoveryVerified),
  };
}

Future<void> _session(String id) async {
  await supabase.auth.setInitialSession(jsonEncode(_sessionData(id)));
  await ZyraAccountState.synchronize(id);
}

http.Response _json(http.Request request, Object body, {int status = 200}) =>
    http.Response(
      jsonEncode(body),
      status,
      request: request,
      headers: {'content-type': 'application/json'},
    );

Finder _button(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(FilledButton),
);

VoidCallback _renderedAction(WidgetTester tester, String key) =>
    tester.widget<FilledButton>(_button(key)).onPressed!;

Future<void> _flush(WidgetTester tester) async {
  // Account preference cleanup has a real-zone serialization queue. Drain it
  // explicitly without treating frame settling as completed device I/O.
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _mount(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const MaterialApp(home: RecoveryEmailSetupScreen()));
  await tester.enterText(
    find.byKey(const ValueKey('recovery_setup_email')),
    _recovery,
  );
}

Future<void> _showNewCode(WidgetTester tester) async {
  await tester.tap(_button(_send));
  await _flush(tester);
  expect(find.byKey(const ValueKey(_verifyNew)), findsOneWidget);
  await tester.enterText(
    find.byKey(const ValueKey('recovery_setup_code')),
    '123456',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <http.Request>[];
  late Future<http.Response> Function(http.Request) respond;
  final pending = <Completer<http.Response>>[];
  var resettingFixture = false;

  List<http.Request> calls(String method, String endpoint) => requests
      .where(
        (request) =>
            request.method == method &&
            request.url.path == '/auth/v1/$endpoint',
      )
      .toList();

  Future<http.Response> defaultResponse(http.Request request) async => _json(
    request,
    request.method == 'POST' ? {'user': _user(_a)} : _user(_a),
  );

  Completer<http.Response> hold(String method, String endpoint) {
    final response = Completer<http.Response>();
    pending.add(response);
    respond = (request) {
      if (request.method == method &&
          request.url.path == '/auth/v1/$endpoint') {
        return response.future;
      }
      return defaultResponse(request);
    };
    return response;
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    respond = defaultResponse;
    await Supabase.initialize(
      url: 'https://test.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) {
        requests.add(request);
        // gotrue's local signOut still sends /logout for the old synthetic
        // access token. Permit it ONLY during fixture reset, independently of
        // the previous test's delayed/failing responder. No runtime action is
        // allowed this endpoint, and no real HTTP client is ever constructed.
        if (resettingFixture &&
            request.method == 'POST' &&
            request.url.path == '/auth/v1/logout' &&
            request.url.queryParameters['scope'] == 'local') {
          return Future.value(http.Response('', 204, request: request));
        }
        final allowed =
            (request.url.path == '/auth/v1/user' &&
                (request.method == 'GET' || request.method == 'PUT')) ||
            (request.url.path == '/auth/v1/verify' && request.method == 'POST');
        if (!allowed) {
          throw StateError(
            'Unexpected synthetic Auth operation: '
            '${request.method} ${request.url.path}',
          );
        }
        return respond(request);
      }),
    );
  });

  setUp(() async {
    resettingFixture = true;
    try {
      await supabase.auth.signOut(scope: SignOutScope.local);
    } finally {
      resettingFixture = false;
    }
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = true;
    await _session(_a);
    requests.clear();
    pending.clear();
    respond = defaultResponse;
  });

  tearDown(() {
    // A failed assertion must not strand an SDK response in the next test.
    for (final response in pending) {
      if (!response.isCompleted) {
        response.complete(
          http.Response(
            '{"message":"Synthetic cleanup refusal"}',
            400,
            headers: {'content-type': 'application/json'},
          ),
        );
      }
    }
    ZyraAccountState.clearImagesForTesting = null;
    ZyraAccountState.endSignOutAttempt();
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
  });
  tearDownAll(() => Supabase.instance.dispose());

  testWidgets('ordinary same-owner secure two-code setup remains functional', (
    tester,
  ) async {
    var verifies = 0;
    respond = (request) async {
      if (request.method == 'POST') {
        verifies++;
        return _json(
          request,
          verifies == 1
              ? {'user': _user(_a)}
              : _sessionData(_a, recoveryVerified: true),
        );
      }
      return _json(request, _user(_a, recoveryVerified: verifies == 2));
    };
    await _mount(tester);
    await _showNewCode(tester);
    await tester.tap(_button(_verifyNew));
    await _flush(tester);
    expect(find.byKey(const ValueKey(_verifyCurrent)), findsOneWidget);
    expect(find.text('Your backup is ready.'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('recovery_setup_code')),
      '654321',
    );
    await tester.tap(_button(_verifyCurrent));
    await _flush(tester);
    expect(find.text('Your backup is ready.'), findsOneWidget);
    expect(calls('PUT', 'user'), hasLength(1));
    expect(calls('POST', 'verify'), hasLength(2));
    final first = jsonDecode(calls('POST', 'verify').first.body);
    final second = jsonDecode(calls('POST', 'verify').last.body);
    expect(first['type'], 'email_change');
    expect(first['email'], _recovery);
    expect(second['email'], _accountEmail);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retained duplicate setup Send dispatches once', (tester) async {
    final response = hold('PUT', 'user');
    await _mount(tester);
    final send = _renderedAction(tester, _send);
    send();
    send();
    await _flush(tester);
    expect(calls('PUT', 'user'), hasLength(1));
    response.complete(_json(calls('PUT', 'user').first, _user(_a)));
    await _flush(tester);
    expect(find.byKey(const ValueKey(_verifyNew)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retained A Send cannot update replacement B email', (
    tester,
  ) async {
    await _mount(tester);
    final send = _renderedAction(tester, _send);
    await tester.runAsync(() => _session(_b));
    send();
    await _flush(tester);
    expect(calls('PUT', 'user'), isEmpty);
    expect(find.byKey(const ValueKey(_verifyNew)), findsNothing);
    expect(supabase.auth.currentUser?.id, _b);
    expect(tester.takeException(), isNull);
  });

  testWidgets('same-ID replacement denies retained previous-lifetime Send', (
    tester,
  ) async {
    await _mount(tester);
    final send = _renderedAction(tester, _send);
    await tester.runAsync(() async {
      await _session(_b);
      await _session(_a);
    });
    send();
    await _flush(tester);
    expect(calls('PUT', 'user'), isEmpty);
    expect(find.byKey(const ValueKey(_verifyNew)), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late Send response cannot advance replaced account setup', (
    tester,
  ) async {
    final response = hold('PUT', 'user');
    await _mount(tester);
    await tester.tap(_button(_send));
    await _flush(tester);
    expect(calls('PUT', 'user'), hasLength(1));
    await tester.runAsync(() => _session(_b));
    response.complete(_json(calls('PUT', 'user').single, _user(_a)));
    await _flush(tester);
    expect(find.byKey(const ValueKey(_verifyNew)), findsNothing);
    expect(find.text('Your backup is ready.'), findsNothing);
    // The SDK owns any already-dispatched session mutation. This assertion
    // proves denial of the stale widget handoff, not cancellation of Auth.
    expect(ZyraAccountState.userId, _b);
    expect(calls('GET', 'user'), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposed setup ignores a late Send response', (tester) async {
    final response = hold('PUT', 'user');
    await _mount(tester);
    await tester.tap(_button(_send));
    await _flush(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    response.complete(_json(calls('PUT', 'user').single, _user(_a)));
    await _flush(tester);
    expect(find.byType(RecoveryEmailSetupScreen), findsNothing);
    expect(calls('GET', 'user'), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retained duplicate new-email Verify dispatches once', (
    tester,
  ) async {
    await _mount(tester);
    await _showNewCode(tester);
    final response = hold('POST', 'verify');
    final verify = _renderedAction(tester, _verifyNew);
    verify();
    verify();
    await _flush(tester);
    expect(calls('POST', 'verify'), hasLength(1));
    response.complete(
      _json(calls('POST', 'verify').single, {'user': _user(_a)}),
    );
    await _flush(tester);
    expect(find.byKey(const ValueKey(_verifyCurrent)), findsOneWidget);
    expect(calls('GET', 'user'), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('retained A Verify cannot dispatch after replacement B', (
    tester,
  ) async {
    await _mount(tester);
    await _showNewCode(tester);
    final verify = _renderedAction(tester, _verifyNew);
    await tester.runAsync(() => _session(_b));
    verify();
    await _flush(tester);
    expect(calls('POST', 'verify'), isEmpty);
    expect(calls('GET', 'user'), isEmpty);
    expect(find.text('Your backup is ready.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late Verify response does not read replacement identity', (
    tester,
  ) async {
    await _mount(tester);
    await _showNewCode(tester);
    final response = hold('POST', 'verify');
    await tester.tap(_button(_verifyNew));
    await _flush(tester);
    await tester.runAsync(() => _session(_b));
    response.complete(
      _json(calls('POST', 'verify').single, {'user': _user(_a)}),
    );
    await _flush(tester);
    expect(calls('GET', 'user'), isEmpty);
    expect(find.byKey(const ValueKey(_verifyCurrent)), findsNothing);
    expect(find.text('Your backup is ready.'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('late identity read cannot claim setup complete after change', (
    tester,
  ) async {
    await _mount(tester);
    await _showNewCode(tester);
    final response = hold('GET', 'user');
    await tester.tap(_button(_verifyNew));
    await _flush(tester);
    expect(calls('GET', 'user'), hasLength(1));
    await tester.runAsync(() => _session(_b));
    response.complete(
      _json(calls('GET', 'user').single, _user(_a, recoveryVerified: true)),
    );
    await _flush(tester);
    expect(find.text('Your backup is ready.'), findsNothing);
    expect(find.byKey(const ValueKey(_verifyCurrent)), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposed setup Verify does not continue into identity reads', (
    tester,
  ) async {
    await _mount(tester);
    await _showNewCode(tester);
    final response = hold('POST', 'verify');
    await tester.tap(_button(_verifyNew));
    await _flush(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    response.complete(
      _json(calls('POST', 'verify').single, {'user': _user(_a)}),
    );
    await _flush(tester);
    expect(calls('GET', 'user'), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('known Send failure releases busy and permits honest retry', (
    tester,
  ) async {
    var refused = true;
    respond = (request) async {
      if (refused) {
        return _json(request, {
          'message': 'Synthetic update refusal',
        }, status: 400);
      }
      return defaultResponse(request);
    };
    await _mount(tester);
    await tester.tap(_button(_send));
    await _flush(tester);
    expect(find.byKey(const ValueKey(_verifyNew)), findsNothing);
    expect(tester.widget<FilledButton>(_button(_send)).onPressed, isNotNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Synthetic update refusal'), findsNothing);
    refused = false;
    await tester.tap(_button(_send));
    await _flush(tester);
    expect(calls('PUT', 'user'), hasLength(2));
    expect(find.byKey(const ValueKey(_verifyNew)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('known Verify failure retains code and permits honest retry', (
    tester,
  ) async {
    await _mount(tester);
    await _showNewCode(tester);
    respond = (request) async {
      if (request.method == 'POST') {
        return _json(request, {'message': 'OTP expired'}, status: 400);
      }
      return defaultResponse(request);
    };
    await tester.tap(_button(_verifyNew));
    await _flush(tester);
    expect(find.byKey(const ValueKey(_verifyNew)), findsOneWidget);
    expect(
      tester.widget<FilledButton>(_button(_verifyNew)).onPressed,
      isNotNull,
    );
    expect(find.text('Your backup is ready.'), findsNothing);
    expect(calls('GET', 'user'), isEmpty);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    respond = defaultResponse;
    await tester.tap(_button(_verifyNew));
    await _flush(tester);
    expect(calls('POST', 'verify'), hasLength(2));
    expect(jsonDecode(calls('POST', 'verify').last.body)['token'], '123456');
    expect(find.byKey(const ValueKey(_verifyCurrent)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
