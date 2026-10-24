import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_report_service.dart';

const _owner = '00000000-0000-4000-8000-000000000741';
const _hidden = '00000000-0000-4000-8000-000000000742';

Future<void> _session() async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.'
          '${part({'sub': _owner, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': _owner,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-03T00:00:00Z',
      },
    }),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Object response = <Object>[];
  int status = 200;
  Completer<void>? paused;
  Completer<void>? started;
  String? queriedOwner;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/profile_blocks')) {
          queriedOwner = request.url.queryParameters['blocker_id'];
          started?.complete();
          await paused?.future;
          return http.Response(
            jsonEncode(response),
            status,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200, request: request);
      }),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() async {
    ZyraAccountState.resetForTesting();
    response = <Object>[];
    status = 200;
    paused = null;
    started = null;
    queriedOwner = null;
    await _session();
  });

  test('confirmed empty and populated hide lists remain distinct', () async {
    expect(await ZyraReportService.blockedIdsOrNull(), isEmpty);
    expect(queriedOwner, 'eq.$_owner');
    response = [
      {'blocked_id': _hidden},
    ];
    expect(await ZyraReportService.blockedIdsOrNull(), [_hidden]);
  });
  test('failed read is unavailable, never a confirmed empty list', () async {
    status = 503;
    response = {'message': 'synthetic offline'};
    expect(await ZyraReportService.blockedIdsOrNull(), isNull);
    expect(await ZyraReportService.blockedIds(), isEmpty);
  });
  test('malformed source cannot become a successful empty list', () async {
    response = [
      {'blocked_id': null},
    ];
    expect(await ZyraReportService.blockedIdsOrNull(), isNull);
  });
  test('signed-out read is unavailable and performs no query', () async {
    await supabase.auth.signOut(scope: SignOutScope.local);
    expect(await ZyraReportService.blockedIdsOrNull(), isNull);
    expect(queriedOwner, isNull);
  });
  test('same-ID replacement invalidates a completed in-flight read', () async {
    response = [
      {'blocked_id': _hidden},
    ];
    paused = Completer<void>();
    started = Completer<void>();
    final read = ZyraReportService.blockedIdsOrNull();
    await started!.future;
    ZyraAccountState.resetForTesting();
    paused!.complete();
    expect(await read, isNull);
  });
}
