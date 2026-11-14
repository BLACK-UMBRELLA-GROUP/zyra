import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/services/zyra_code_link_service.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';

const _code = 'ZYRA-1A01-1B02-1C03-1D04-1E05';
const _owner = '00000000-0000-0000-0000-000000009821';
const _host = 'zyra-code-link-rpc.example.invalid';

Map<String, Object?> _row(
  String outcome, {
  String? name,
  String? role,
  int? age,
  String? location,
}) => {
  'outcome': outcome,
  'owner_first_name': name,
  'owner_role': role,
  'owner_age': age,
  'owner_location': location,
};

String _syntheticSession() {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final token =
      '${part({'alg': 'none'})}.${part({'sub': _owner, 'exp': 4102444800})}.synthetic';
  return jsonEncode({
    'access_token': token,
    'token_type': 'bearer',
    'refresh_token': 'synthetic-session',
    'user': {
      'id': _owner,
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'aud': 'authenticated',
      'created_at': '2026-11-14T00:00:00Z',
    },
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <http.Request>[];
  late FutureOr<http.Response> Function(http.Request) reply;

  http.Response response(
    http.Request request,
    Object body, {
    int status = 200,
  }) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
    request: request,
  );

  Future<ZyraCodeLinkResult> resolve() =>
      ZyraCodeLinkService.resolve(_code, isCurrent: () => true);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    requests.clear();
    reply = (request) => response(request, [_row('unavailable')]);
    await Supabase.initialize(
      url: 'https://$_host',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url,
          Uri.https(_host, '/rest/v1/rpc/zyra_resolve_code_link'),
        );
        expect(jsonDecode(request.body), {'p_code': _code});
        expect(
          request.headers['authorization'],
          'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}',
        );
        requests.add(request);
        return reply(request);
      }),
    );
    ZyraCodeLinkService.setClientReadyForTesting(true);
  });

  tearDown(() async {
    ZyraCodeLinkService.setClientReadyForTesting(null);
    ZyraInternalPreviewClient.finishSignOut();
    await Supabase.instance.dispose();
  });

  Future<void> signIn() =>
      Supabase.instance.client.auth.setInitialSession(_syntheticSession());

  test('decodes one role-scoped outcome per charged request', () async {
    await signIn();
    final cases = [
      (
        _row('add_guardian', name: ' Ada ', role: 'wali'),
        ZyraCodeLinkOutcome.addGuardian,
        'Ada',
      ),
      (
        _row('add_seeker', name: 'Nora', role: 'seeker'),
        ZyraCodeLinkOutcome.addSeeker,
        'Nora',
      ),
      (
        _row('scan', name: 'Eli', age: 28, location: 'Bath'),
        ZyraCodeLinkOutcome.scan,
        'Eli',
      ),
      (_row('own_code'), ZyraCodeLinkOutcome.ownCode, null),
      (_row('unavailable'), ZyraCodeLinkOutcome.unavailable, null),
    ];
    for (final (row, outcome, name) in cases) {
      reply = (request) => response(request, [row]);
      final countBefore = requests.length;
      final result = await resolve();
      expect(requests.length, countBefore + 1);
      expect(result.outcome, outcome);
      expect(result.firstName, name);
    }
  });

  test('fails closed for malformed or overexposed results', () async {
    await signIn();
    final cases = [
      <Object?>[],
      [_row('unavailable'), _row('own_code')],
      [_row('unknown')],
      [_row('unavailable', name: 'Hidden')],
      [_row('add_guardian', name: 'Ada', role: 'seeker')],
      [_row('add_guardian', name: 'Ada', role: 'wali', age: 28)],
      [_row('scan', name: 'Eli', role: 'wali', age: 28, location: 'Bath')],
      [_row('scan', name: 'Eli', role: 'seeker', age: 28, location: 'Bath')],
      [_row('scan', name: 'Eli', age: 28)],
      [
        {..._row('own_code'), 'owner_id': _owner},
      ],
    ];
    for (final body in cases) {
      reply = (request) => response(request, body);
      final result = await resolve();
      expect(result.outcome, ZyraCodeLinkOutcome.failed);
      expect(result.firstName, isNull);
    }
  });

  test('only the exact server rate-limit signal maps to the limit', () async {
    await signIn();
    for (final (message, expected) in [
      ('too_many_code_checks', ZyraCodeLinkOutcome.rateLimited),
      ('not_too_many_code_checks', ZyraCodeLinkOutcome.failed),
      ('request_failed', ZyraCodeLinkOutcome.failed),
    ]) {
      reply = (request) =>
          response(request, {'message': message, 'code': 'P0001'}, status: 400);
      expect((await resolve()).outcome, expected);
    }
    expect(requests, hasLength(3));
  });

  test(
    'checks lifetime before dispatch and before exposing the result',
    () async {
      expect((await resolve()).outcome, ZyraCodeLinkOutcome.failed);
      await signIn();
      expect(
        (await ZyraCodeLinkService.resolve(
          _code,
          isCurrent: () => false,
        )).outcome,
        ZyraCodeLinkOutcome.failed,
      );
      ZyraInternalPreviewClient.beginPreview();
      expect((await resolve()).outcome, ZyraCodeLinkOutcome.failed);
      ZyraInternalPreviewClient.finishSignOut();
      expect(requests, isEmpty);

      final received = Completer<void>();
      final release = Completer<void>();
      reply = (request) async {
        received.complete();
        await release.future;
        return response(request, [
          _row('add_guardian', name: 'Ada', role: 'wali'),
        ]);
      };
      var current = true;
      final pending = ZyraCodeLinkService.resolve(
        _code,
        isCurrent: () => current,
      );
      await received.future;
      current = false;
      release.complete();
      final result = await pending;
      expect(result.outcome, ZyraCodeLinkOutcome.failed);
      expect(result.firstName, isNull);
      expect(requests, hasLength(1));
    },
  );
}
