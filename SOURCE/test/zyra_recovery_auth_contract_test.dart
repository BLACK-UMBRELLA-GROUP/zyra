import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_auth.dart';
import 'package:zyra/services/zyra_local_prefs.dart';

const _a = '00000000-0000-4000-8000-000000000926';
const _b = '00000000-0000-4000-8000-000000000927';

Map<String, Object?> _session(String id) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return {
    'access_token':
        '${part({'alg': 'none'})}.${part({'sub': id, 'exp': 4102444800})}.synthetic',
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'synthetic-refresh',
    'user': {
      'id': id,
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'aud': 'authenticated',
      'created_at': '2026-10-06T00:00:00Z',
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bodies = <Map<String, dynamic>>[];
  Future<void> Function()? beforeVerify;
  Object responseBody = {};
  var failTransport = false;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://test.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        if (request.url.path.endsWith('/verify')) {
          await beforeVerify?.call();
        }
        if (failTransport) throw StateError('Synthetic transport failure');
        return http.Response(
          jsonEncode(responseBody),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });
  setUp(() async {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await supabase.auth.signOut(scope: SignOutScope.local);
    await ZyraAccountState.synchronize(null);
    bodies.clear();
    beforeVerify = null;
    responseBody = {};
    failTransport = false;
  });
  tearDown(() {
    ZyraAccountState.clearImagesForTesting = null;
    ZyraAccountState.endSignOutAttempt();
  });
  tearDownAll(() => Supabase.instance.dispose());

  test(
    'recovery requests never create a user and retain normalized address',
    () async {
      final result = await ZyraAuth.sendRecoverySignInCode(
        '  MEMBER@EXAMPLE.INVALID ',
      );
      expect(result.outcome, ZyraAuthOutcome.success);
      expect(bodies.single['create_user'], isFalse);
      expect(bodies.single['email'], 'member@example.invalid');
      expect(supabase.auth.currentUser, isNull);
    },
  );

  test(
    'invalid recovery address does not request provider transport',
    () async {
      final result = await ZyraAuth.sendRecoverySignInCode('invalid address');
      expect(result.outcome, ZyraAuthOutcome.error);
      expect(bodies, isEmpty);
    },
  );

  test('email verification binds only its returned Auth principal', () async {
    responseBody = _session(_a);
    final result = await ZyraAuth.verifyRecoverySignInCode(
      email: '  MEMBER@EXAMPLE.INVALID ',
      code: ' 123456 ',
    );
    expect(bodies.single['type'], 'email');
    expect(bodies.single['email'], 'member@example.invalid');
    expect(bodies.single['token'], '123456');
    expect(result.outcome, ZyraAuthOutcome.success);
    expect(result.authenticatedUserId, _a);
    expect(supabase.auth.currentUser?.id, _a);
  });

  test('verification without session cannot claim recovery success', () async {
    responseBody = {'user': _session(_a)['user']};
    final result = await ZyraAuth.verifyRecoverySignInCode(
      email: 'member@example.invalid',
      code: '123456',
    );
    expect(result.outcome, ZyraAuthOutcome.error);
    expect(result.authenticatedUserId, isNull);
  });

  test('verification transport throw maps to existing neutral error', () async {
    failTransport = true;
    final result = await ZyraAuth.verifyRecoverySignInCode(
      email: 'member@example.invalid',
      code: '123456',
    );
    expect(result.outcome, ZyraAuthOutcome.error);
    expect(result.errorMessage, isNot(contains('Synthetic')));
  });

  test(
    'superseded owner rejects local recovery handoff despite SDK session mutation',
    () async {
      responseBody = _session(_a);
      beforeVerify = () async {
        await supabase.auth.setInitialSession(jsonEncode(_session(_b)));
        await ZyraAccountState.synchronize(_b);
      };
      final result = await ZyraAuth.verifyRecoverySignInCode(
        email: 'member@example.invalid',
        code: '123456',
      );
      expect(result.outcome, ZyraAuthOutcome.cancelled);
      expect(result.authenticatedUserId, isNull);
      // Pinned SDK saves OTP's response before returning. This test expressly
      // proves denial of the local handoff, not cancellation of SDK Auth work.
      expect(supabase.auth.currentUser?.id, _a);
      expect(ZyraAccountState.userId, _b);
    },
  );

  test('logout lifetime rejects a late verification handoff', () async {
    responseBody = _session(_a);
    beforeVerify = () => ZyraAccountState.beginSignOut();
    final result = await ZyraAuth.verifyRecoverySignInCode(
      email: 'member@example.invalid',
      code: '123456',
    );
    expect(result.outcome, ZyraAuthOutcome.cancelled);
    expect(result.authenticatedUserId, isNull);
  });
}
