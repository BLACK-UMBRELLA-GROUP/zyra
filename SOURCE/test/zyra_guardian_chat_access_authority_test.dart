// Synthetic SDK contract tests, not deployed receipt/RLS enforcement evidence.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_wali_link_service.dart';

const _a = '00000000-0000-4000-8000-000000000951';
const _b = '00000000-0000-4000-8000-000000000952';

Future<void> _session(String id) async {
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
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-09T00:00:00Z',
      },
    }),
  );
  await ZyraAccountState.synchronize(id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <Map<String, dynamic>>[];
  bool? entitled;
  bool included = true;
  bool main = false;
  bool available = true;
  Future<void> Function()? beforeResponse;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://generated.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        expect(request.url.path, '/rest/v1/rpc/zyra_guardian_journey_access');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        requests.add(body);
        await beforeResponse?.call();
        return http.Response(
          jsonEncode([
            {
              'attempt_id': 'attempt-1',
              'match_id': 'match-1',
              'counterpart_first_name': 'Maryam',
              'included': included,
              'can_change': !main,
              'guardian_is_main': main,
              'chat_available': available,
              'chat_enabled': body['p_chat_enabled'] ?? true,
              'guardian_chat_entitled': ?entitled,
            },
          ]),
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
    ZyraWaliLinkService.setGuardianAccessReadyForTesting(true);
    requests.clear();
    entitled = false;
    included = available = true;
    main = false;
    beforeResponse = null;
    await _session(_a);
  });
  tearDown(() {
    ZyraWaliLinkService.setGuardianAccessReadyForTesting(null);
    ZyraAccountState.clearImagesForTesting = null;
  });
  tearDownAll(() => Supabase.instance.dispose());

  Future<ZyraSourceResult<List<GuardianJourneyAccessState>>> enable() =>
      ZyraWaliLinkService.guardianJourneyAccess(
        guardianId: 'guardian-1',
        attemptId: 'attempt-1',
        chatEnabled: true,
      );

  for (final isMain in [false, true]) {
    test(
      '${isMain ? 'Main' : 'Additional'} Basic cannot send a Chat-enable write',
      () async {
        main = isMain;
        expect((await enable()).isUnavailable, isTrue);
        expect(requests, hasLength(1));
        expect(requests.single['p_chat_enabled'], isNull);
        expect(requests.single['p_attempt'], isNull);
      },
    );
  }
  test(
    'legacy response without entitlement proof never sends enable',
    () async {
      entitled = null;
      expect((await enable()).isUnavailable, isTrue);
      expect(requests, hasLength(1));
    },
  );
  test(
    'One confirmation permits only the guarded current enable write',
    () async {
      entitled = true;
      expect((await enable()).valueOrNull?.single.chatEnabled, isTrue);
      expect(requests, hasLength(2));
      expect(requests.last['p_attempt'], 'attempt-1');
      expect(requests.last['p_guardian'], 'guardian-1');
      expect(requests.last['p_chat_enabled'], isTrue);
    },
  );
  test(
    'stage unavailable rejects enable even with paid confirmation',
    () async {
      entitled = true;
      available = false;
      expect((await enable()).isUnavailable, isTrue);
      expect(requests, hasLength(1));
    },
  );
  test(
    'account replacement during preflight sends no old-owner write',
    () async {
      entitled = true;
      beforeResponse = () => _session(_b);
      expect((await enable()).isUnavailable, isTrue);
      expect(requests, hasLength(1));
    },
  );
  test(
    'same-account replacement during preflight sends no old-generation write',
    () async {
      entitled = true;
      beforeResponse = () async {
        await ZyraAccountState.synchronize(null);
        await _session(_a);
      };
      expect((await enable()).isUnavailable, isTrue);
      expect(requests, hasLength(1));
    },
  );
  test('late permission read cannot be returned to another account', () async {
    entitled = true;
    beforeResponse = () => _session(_b);
    expect(
      (await ZyraWaliLinkService.guardianJourneyAccess(
        guardianId: 'guardian-1',
      )).isUnavailable,
      isTrue,
    );
  });
  test('Basic may revoke Chat without a paid-enable preflight', () async {
    expect(
      (await ZyraWaliLinkService.guardianJourneyAccess(
        guardianId: 'guardian-1',
        attemptId: 'attempt-1',
        chatEnabled: false,
      )).isAvailable,
      isTrue,
    );
    expect(requests, hasLength(1));
    expect(requests.single['p_chat_enabled'], isFalse);
  });
  test('default startup-not-ready guard sends zero HTTP', () async {
    ZyraWaliLinkService.setGuardianAccessReadyForTesting(null);
    expect(supabaseReady, isFalse);
    expect((await enable()).isUnavailable, isTrue);
    expect(requests, isEmpty);
  });
}
