import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// All identities, credentials and responses in this file are artificial.
// MockClient intercepts every request: these tests never authenticate live.
// They exercise the installed SDK's headers/session handling, not server RLS.
const _url = 'https://key-migration-fixture.supabase.invalid';
const _publishableKey = 'sb_publishable_artificial_sdk_test_only';
const _memberId = '00000000-0000-4000-8000-000000009401';
const _sessionStorageKey = 'sb-key-migration-fixture-auth-token';

Map<String, Object?> _session({String revision = 'initial'}) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return {
    'access_token':
        '${part({'alg': 'none'})}.${part({'sub': _memberId, 'role': 'authenticated', 'exp': 4102444800, 'revision': revision})}.artificial',
    'token_type': 'bearer',
    'expires_in': 3600,
    'refresh_token': 'artificial-refresh-$revision',
    'user': {
      'id': _memberId,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'member@example.invalid',
      'created_at': '2026-09-24T00:00:00Z',
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
    },
  };
}

http.Response _json(http.Request request, Object? body, {int status = 200}) =>
    http.Response(
      jsonEncode(body),
      status,
      request: request,
      headers: {'content-type': 'application/json'},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <http.Request>[];
  late http.Response Function(http.Request request) respond;
  Supabase? instance;

  Future<SupabaseClient> initialize({String? persistedSession}) async {
    SharedPreferences.setMockInitialValues({
      _sessionStorageKey: ?persistedSession,
    });
    instance = await Supabase.initialize(
      url: _url,
      publishableKey: _publishableKey,
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        return respond(request);
      }),
    );
    return instance!.client;
  }

  setUp(() {
    requests.clear();
    respond = (request) => throw StateError(
      'Unexpected mocked request: ${request.method} ${request.url.path}',
    );
  });

  tearDown(() async {
    await instance?.dispose();
    instance = null;
  });

  test(
    'publishable initialization keeps member bearer through login and refresh',
    () async {
      final initial = _session();
      final refreshed = _session(revision: 'refreshed');
      respond = (request) {
        if (request.url.path == '/auth/v1/token') {
          return _json(
            request,
            request.url.queryParameters['grant_type'] == 'refresh_token'
                ? refreshed
                : initial,
          );
        }
        if (request.url.path == '/rest/v1/profiles') {
          return _json(request, [
            {'id': _memberId},
          ]);
        }
        if (request.url.path == '/auth/v1/user') {
          return _json(request, refreshed['user']);
        }
        throw StateError('Unexpected mocked path: ${request.url.path}');
      };
      final client = await initialize();
      expect(client.auth.currentSession, isNull);

      await client.auth.signInWithPassword(
        email: 'member@example.invalid',
        password: 'artificial-password',
      );
      await client.from('profiles').select('id');
      final login = requests[0];
      final firstRead = requests[1];
      expect(login.url.queryParameters['grant_type'], 'password');
      expect(login.headers['apikey'], _publishableKey);
      expect(firstRead.headers['apikey'], _publishableKey);
      expect(
        firstRead.headers['authorization'],
        'Bearer ${initial['access_token']}',
      );

      await client.auth.refreshSession();
      await client.from('profiles').select('id');
      final verifiedUser = await client.auth.getUser();
      final refresh = requests[2];
      expect(refresh.url.queryParameters['grant_type'], 'refresh_token');
      expect(
        jsonDecode(refresh.body)['refresh_token'],
        initial['refresh_token'],
      );
      expect(refresh.headers['apikey'], _publishableKey);
      for (final request in requests.skip(3)) {
        expect(request.headers['apikey'], _publishableKey);
        expect(
          request.headers['authorization'],
          'Bearer ${refreshed['access_token']}',
        );
      }
      expect(verifiedUser.user?.id, _memberId);
      expect(
        client.auth.currentSession?.refreshToken,
        refreshed['refresh_token'],
      );
      expect(client.auth.currentUser?.appMetadata, isEmpty);
    },
  );

  test(
    'existing member session survives API key change in the same project',
    () async {
      // This is the same SDK storage slot used by a previous legacy-key build.
      // Its name depends on the project host, not on the application API key.
      final persisted = _session(revision: 'from-previous-build');
      respond = (request) {
        if (request.url.path != '/rest/v1/profiles') {
          throw StateError(
            'Session recovery unexpectedly required new sign-in',
          );
        }
        return _json(request, [
          {'id': _memberId},
        ]);
      };
      final client = await initialize(persistedSession: jsonEncode(persisted));
      await client.from('profiles').select('id');
      expect(client.auth.currentUser?.id, _memberId);
      expect(
        client.auth.currentSession?.refreshToken,
        persisted['refresh_token'],
      );
      expect(requests, hasLength(1));
      expect(requests.single.headers['apikey'], _publishableKey);
      expect(
        requests.single.headers['authorization'],
        'Bearer ${persisted['access_token']}',
      );
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey(_sessionStorageKey), isTrue);
    },
  );

  test(
    'rejected sign-in creates no member session and grants no RPC access',
    () async {
      respond = (request) => request.url.path == '/auth/v1/token'
          ? _json(request, {
              'code': 'invalid_credentials',
              'message': 'Invalid login credentials',
            }, status: 400)
          : _json(request, {
              'code': '42501',
              'message': 'Permission denied',
            }, status: 403);
      final client = await initialize();
      await expectLater(
        client.auth.signInWithPassword(
          email: 'member@example.invalid',
          password: 'artificial-wrong-password',
        ),
        throwsA(isA<AuthException>()),
      );
      expect(client.auth.currentSession, isNull);
      expect(client.auth.currentUser, isNull);
      await expectLater(
        client.rpc('member_only_fixture'),
        throwsA(isA<PostgrestException>()),
      );
      expect(requests.last.headers['apikey'], _publishableKey);
      expect(requests.last.headers['authorization'], 'Bearer $_publishableKey');
    },
  );

  test(
    'revoked refresh token clears the prior member and stored session',
    () async {
      respond = (request) {
        if (request.url.path == '/auth/v1/token') {
          return _json(request, {
            'code': 'refresh_token_not_found',
            'message': 'Invalid refresh token',
          }, status: 400);
        }
        return _json(request, {
          'code': '42501',
          'message': 'Permission denied',
        }, status: 403);
      };
      final client = await initialize(persistedSession: jsonEncode(_session()));
      expect(client.auth.currentUser?.id, _memberId);
      // Complete the SDK's asynchronous startup recovery before provoking failure.
      await Future<void>.delayed(Duration.zero);
      await expectLater(
        client.auth.refreshSession(),
        throwsA(isA<AuthException>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(client.auth.currentSession, isNull);
      expect(client.auth.currentUser, isNull);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey(_sessionStorageKey), isFalse);
      await expectLater(
        client.rpc('member_only_fixture'),
        throwsA(isA<PostgrestException>()),
      );
      expect(requests.last.headers['apikey'], _publishableKey);
      expect(requests.last.headers['authorization'], 'Bearer $_publishableKey');
    },
  );

  test(
    'incomplete stored session cannot become an authenticated member',
    () async {
      final incomplete = _session()..remove('access_token');
      final client = await initialize(persistedSession: jsonEncode(incomplete));
      await Future<void>.delayed(Duration.zero);
      expect(client.auth.currentSession, isNull);
      expect(client.auth.currentUser, isNull);
      expect(requests, isEmpty);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.containsKey(_sessionStorageKey), isFalse);
    },
  );
}
