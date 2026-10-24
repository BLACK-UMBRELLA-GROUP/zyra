import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_consent_service.dart';

const _ownerA = '00000000-0000-0000-0000-000000000011';
const _ownerB = '00000000-0000-0000-0000-000000000012';
List<Map<String, Object?>> _rows = [];
bool _failRead = false;
int _reads = 0;
int _writes = 0;
http.Request? _lastRequest;
Completer<void>? _started;
Completer<void>? _wait;

Future<void> _session(String owner) => supabase.auth.setInitialSession(
  jsonEncode({
    'access_token':
        '${base64Url.encode(utf8.encode('{"alg":"none"}'))}.'
        '${base64Url.encode(utf8.encode(jsonEncode({'sub': owner, 'exp': 4102444800})))}.local-test-signature',
    'token_type': 'bearer',
    'refresh_token': 'local-test-refresh',
    'user': {
      'id': owner,
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'aud': 'authenticated',
      'created_at': '2026-10-02T00:00:00Z',
    },
  }),
);

Map<String, Object?> _decision(bool granted, {String? date}) => {
  'granted': granted,
  'policy_version': 'synthetic-local-policy',
  'recorded_at': date ?? '2026-10-02T00:00:00Z',
};

http.Response _json(Object body, int status, http.Request request) =>
    http.Response(
      jsonEncode(body),
      status,
      request: request,
      headers: {'content-type': 'application/json'},
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'local-consent-restore-test',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        if (request.method != 'GET') {
          _writes++;
          return _json({'message': 'local test denied'}, 403, request);
        }
        if (request.url.path != '/rest/v1/consents') {
          return _json({'message': 'local test denied'}, 403, request);
        }
        _reads++;
        _lastRequest = request;
        final rows = _rows;
        if (_started != null && !_started!.isCompleted) _started!.complete();
        if (_wait != null) await _wait!.future;
        return _failRead
            ? _json({'message': 'synthetic read failure'}, 400, request)
            : _json(rows, 200, request);
      }),
    );
  });

  tearDownAll(() => Supabase.instance.dispose());

  setUp(() async {
    _rows = [];
    _failRead = false;
    _reads = 0;
    _writes = 0;
    _lastRequest = null;
    _started = null;
    _wait = null;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraConsentService.clearForSignOut();
    await _session(_ownerA);
    await ZyraAccountState.synchronize(_ownerA);
  });

  tearDown(() {
    if (_wait != null && !_wait!.isCompleted) _wait!.complete();
    ZyraConsentService.clearForSignOut();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = null;
  });

  test(
    'strict null means no recorded decision and the read is own-row only',
    () async {
      expect(
        await ZyraConsentService.currentArticle9Decision(
          expectedUserId: _ownerA,
          throwOnError: true,
        ),
        isNull,
      );
      expect(_reads, 1);
      expect(_writes, 0);
      expect(_lastRequest!.url.queryParameters['user_id'], 'eq.$_ownerA');
      expect(
        _lastRequest!.url.queryParameters['consent_type'],
        'eq.article9_special_category',
      );
      expect(
        _lastRequest!.url.queryParameters['order'],
        'recorded_at.desc.nullslast',
      );
    },
  );

  test(
    'a recorded decline remains false rather than unknown or unasked',
    () async {
      _rows = [_decision(false), _decision(true, date: '2026-10-01T00:00:00Z')];
      expect(
        await ZyraConsentService.currentArticle9Decision(
          expectedUserId: _ownerA,
          throwOnError: true,
        ),
        isFalse,
      );
      expect(_writes, 0);
    },
  );

  test(
    'strict restore surfaces read failure while read-only defaults stay compatible',
    () async {
      _failRead = true;
      expect(await ZyraConsentService.history(), isEmpty);
      expect(await ZyraConsentService.currentArticle9Decision(), isNull);
      await expectLater(
        ZyraConsentService.history(expectedUserId: _ownerA, throwOnError: true),
        throwsA(anything),
      );
      await expectLater(
        ZyraConsentService.currentArticle9Decision(
          expectedUserId: _ownerA,
          throwOnError: true,
        ),
        throwsA(anything),
      );
      expect(_reads, 4);
      expect(_writes, 0);
    },
  );

  test('a mismatched expected principal cannot read consent history', () async {
    await expectLater(
      ZyraConsentService.history(expectedUserId: _ownerB, throwOnError: true),
      throwsStateError,
    );
    await expectLater(
      ZyraConsentService.currentArticle9Decision(
        expectedUserId: _ownerB,
        throwOnError: true,
      ),
      throwsStateError,
    );
    expect(await ZyraConsentService.history(expectedUserId: _ownerB), isEmpty);
    expect(
      await ZyraConsentService.currentArticle9Decision(expectedUserId: _ownerB),
      isNull,
    );
    expect(_reads, 0);
    expect(_writes, 0);
  });

  test(
    'a late decision throws after the signed-in principal changes',
    () async {
      _rows = [_decision(false)];
      _started = Completer<void>();
      _wait = Completer<void>();
      final pending = ZyraConsentService.currentArticle9Decision(
        expectedUserId: _ownerA,
        throwOnError: true,
      );
      final rejected = expectLater(pending, throwsStateError);
      await _started!.future;
      await _session(_ownerB);
      await ZyraAccountState.synchronize(_ownerB);
      _wait!.complete();
      await rejected;
      expect(_reads, 1);
      expect(_writes, 0);
    },
  );

  test(
    'a same-principal session reset invalidates a pending strict read',
    () async {
      _rows = [_decision(true)];
      _started = Completer<void>();
      _wait = Completer<void>();
      final pending = ZyraConsentService.history(
        expectedUserId: _ownerA,
        throwOnError: true,
      );
      final rejected = expectLater(pending, throwsStateError);
      await _started!.future;
      ZyraAccountState.resetForTesting();
      await ZyraAccountState.synchronize(_ownerA);
      _wait!.complete();
      await rejected;
      expect(_writes, 0);
    },
  );

  test(
    'a malformed decision cannot become an unasked onboarding checkpoint',
    () async {
      _rows = [_decision(false, date: 'invalid local timestamp')];
      await expectLater(
        ZyraConsentService.currentArticle9Decision(
          expectedUserId: _ownerA,
          throwOnError: true,
        ),
        throwsFormatException,
      );
      expect(await ZyraConsentService.currentArticle9Decision(), isNull);
      expect(_writes, 0);
    },
  );
}
