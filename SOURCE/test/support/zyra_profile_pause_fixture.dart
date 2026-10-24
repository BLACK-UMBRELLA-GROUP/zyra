// Synthetic sessions and intercepted HTTP only. Never connects to a project.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_text.dart';

const pauseOwnerA = '00000000-0000-4000-8000-000000002305';
const pauseOwnerB = '00000000-0000-4000-8000-000000002306';

class ProfilePauseFixture {
  final requests = <http.Request>[];
  bool paused = false;
  int revision = 1;
  bool missing = false;
  Future<http.Response?> Function(http.Request)? intercept;

  int calls(String name) => requests
      .where((request) => request.url.path == '/rest/v1/rpc/$name')
      .length;

  Map<String, Object?> payload({String owner = pauseOwnerA}) => {
    'schema_version': 1,
    'owner_id': owner,
    'paused': paused,
    'revision': revision,
  };

  Future<void> initialize() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://pause-fixture.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        http.Response attached(http.Response reply) => http.Response.bytes(
          reply.bodyBytes,
          reply.statusCode,
          headers: reply.headers,
          request: request,
          reasonPhrase: reply.reasonPhrase,
          persistentConnection: reply.persistentConnection,
          isRedirect: reply.isRedirect,
        );
        requests.add(request);
        final overridden = await intercept?.call(request);
        if (overridden != null) return attached(overridden);
        final path = request.url.path;
        if (path == '/rest/v1/rpc/zyra_my_profile_pause_state' ||
            path == '/rest/v1/rpc/zyra_set_my_profile_pause') {
          if (missing) {
            return attached(
              response({'code': 'PGRST202', 'message': 'Unavailable'}, 404),
            );
          }
          if (path.endsWith('/zyra_set_my_profile_pause')) {
            final params = jsonDecode(request.body) as Map<String, dynamic>;
            if (params['p_expected_revision'] != revision) {
              return attached(response({'message': 'Revision conflict'}, 409));
            }
            final requested = params['p_paused'] as bool;
            if (requested != paused) revision++;
            paused = requested;
          }
          return attached(response(payload()));
        }
        throw StateError(
          'Unexpected synthetic request: ${request.method} $path',
        );
      }),
    );
  }

  static http.Response response(Object? body, [int status = 200]) =>
      http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      );

  Future<void> reset() async {
    ZyraInternalPreviewClient.finishSignOut();
    paused = false;
    revision = 1;
    missing = false;
    intercept = null;
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await session(pauseOwnerA);
    requests.clear();
  }

  Map<String, Object?> sessionJson(String owner, {String marker = 'opening'}) {
    String part(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    return {
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': owner, 'exp': 4102444800, 'jti': marker})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': owner,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-19T00:00:00Z',
      },
    };
  }

  Future<void> session(String owner, {bool synchronize = true}) async {
    await supabase.auth.setInitialSession(jsonEncode(sessionJson(owner)));
    if (synchronize) {
      await ZyraAccountState.synchronize(owner);
    }
  }

  Future<void> refresh({String marker = 'refreshed'}) async {
    // Local SDK replacement plus a synthetic healthy refresh notification.
    // recoverSession does not contact Auth for this nonexpired same-owner token.
    await supabase.auth.recoverSession(
      jsonEncode(sessionJson(pauseOwnerA, marker: marker)),
    );
    // ignore: invalid_use_of_internal_member
    supabase.auth.notifyAllSubscribers(
      AuthChangeEvent.tokenRefreshed,
      session: supabase.auth.currentSession,
      broadcast: false,
    );
  }

  Future<void> transition(
    WidgetTester tester,
    String owner, {
    bool synchronize = true,
  }) async {
    // Auth persistence and AccountState's queued cleanup must originate in
    // the real async zone. A tail future created in a prior widget fake clock
    // can otherwise strand the next test's setUp while awaiting synchronize.
    await tester.runAsync(
      () => session(
        owner,
        synchronize: synchronize,
      ).timeout(const Duration(seconds: 4)),
    );
    await settle(tester);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var frame = 0; frame < 12; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
  }

  void afterEach() {
    ZyraInternalPreviewClient.finishSignOut();
    intercept = null;
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
  }

  Future<void> dispose() => Supabase.instance.dispose();
}
