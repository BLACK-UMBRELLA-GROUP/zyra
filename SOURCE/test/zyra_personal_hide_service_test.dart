// Ordinary-session transport tests only. Synthetic SDK tokens/HTTP; no live API.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_personal_hide_service.dart';

const _owner = '00000000-0000-4000-8000-000000005101';
const _other = '00000000-0000-4000-8000-000000005102';
const _target = '00000000-0000-4000-8000-000000005103';

Future<void> _session(String id, {String marker = 'opening'}) async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.'
          '${part({'sub': id, 'exp': 4102444800, 'session_id': marker})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': id,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-19T00:00:00Z',
      },
    }),
  );
}

Map<String, Object?> _readAck([List<Object?> ids = const []]) => {
  'schema_version': 1,
  'viewer_id': _owner,
  'profile_ids': ids,
};

Map<String, Object?> _writeAck(bool hidden) => {
  'schema_version': 1,
  'viewer_id': _owner,
  'profile_id': _target,
  'hidden': hidden,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Object? response;
  var status = 200;
  final requests = <http.Request>[];
  Completer<void>? release;
  Completer<void>? started;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (started != null && !started!.isCompleted) started!.complete();
        await release?.future;
        return http.Response(
          jsonEncode(response),
          status,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() async {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraAccountState.resetForTesting();
    await _session(_owner);
    requests.clear();
    response = _readAck();
    status = 200;
    release = null;
    started = null;
  });
  tearDown(() {
    if (release != null && !release!.isCompleted) release!.complete();
    ZyraInternalPreviewClient.finishSignOut();
  });

  test(
    'exact empty/populated personal-hide reads pin the opening bearer',
    () async {
      final token = supabase.auth.currentSession!.accessToken;
      expect(await ZyraPersonalHideService.hiddenIdsOrNull(), isEmpty);
      response = _readAck([_target]);
      expect(await ZyraPersonalHideService.hiddenIdsOrNull(), [_target]);
      expect(requests, hasLength(2));
      for (final request in requests) {
        expect(request.url.path, '/rest/v1/rpc/zyra_my_hidden_profile_ids');
        expect(request.headers['Authorization'], 'Bearer $token');
      }
    },
  );

  for (final malformed in <String, Object?>{
    'old block row list': [
      {'blocked_id': _target},
    ],
    'null': null,
    'array envelope': [
      _readAck([_target]),
    ],
    'wrong owner': {..._readAck(), 'viewer_id': _other},
    'floating schema': {..._readAck(), 'schema_version': 1.0},
    'missing field': {'schema_version': 1, 'viewer_id': _owner},
    'additional identity': {..._readAck(), 'first_name': 'Private name'},
    'non-UUID': _readAck(['local-fixture']),
    'non-string': _readAck([null]),
    'duplicate': _readAck([_target, _target.toUpperCase()]),
    'self': _readAck([_owner]),
  }.entries) {
    test('read rejects ${malformed.key} without an empty fallback', () async {
      response = malformed.value;
      expect(await ZyraPersonalHideService.hiddenIdsOrNull(), isNull);
      expect(requests, hasLength(1));
    });
  }

  for (final hidden in [true, false]) {
    test('${hidden ? 'hide' : 'unhide'} requires its own exact ACK', () async {
      response = _writeAck(hidden);
      final token = supabase.auth.currentSession!.accessToken;
      expect(
        await ZyraPersonalHideService.setHidden(_target, hidden: hidden),
        isTrue,
      );
      expect(requests.single.url.path, '/rest/v1/rpc/zyra_set_profile_hidden');
      expect(jsonDecode(requests.single.body), {
        'p_other': _target,
        'p_hidden': hidden,
      });
      expect(requests.single.headers['Authorization'], 'Bearer $token');
      response = _writeAck(!hidden);
      expect(
        await ZyraPersonalHideService.setHidden(_target, hidden: hidden),
        isFalse,
      );
    });
  }

  for (final malformed in <String, Object?>{
    'null': null,
    'array envelope': [_writeAck(true)],
    'wrong owner': {..._writeAck(true), 'viewer_id': _other},
    'wrong profile': {..._writeAck(true), 'profile_id': _other},
    'string boolean': {..._writeAck(true), 'hidden': 'true'},
    'missing boolean': {
      'schema_version': 1,
      'viewer_id': _owner,
      'profile_id': _target,
    },
    'extra field': {..._writeAck(true), 'blocked': true},
    'wrong schema': {..._writeAck(true), 'schema_version': 2},
  }.entries) {
    test('write rejects ${malformed.key} without Block fallback', () async {
      response = malformed.value;
      expect(await ZyraPersonalHideService.hide(_target), isFalse);
      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/rest/v1/rpc/zyra_set_profile_hidden');
    });
  }

  for (final code in [404, 503]) {
    test('missing/unavailable endpoint $code never becomes success', () async {
      status = code;
      response = {'code': 'unavailable', 'message': 'synthetic unavailable'};
      expect(await ZyraPersonalHideService.hiddenIdsOrNull(), isNull);
      expect(await ZyraPersonalHideService.hide(_target), isFalse);
      expect(await ZyraPersonalHideService.unhide(_target), isFalse);
      expect(requests, hasLength(3));
      expect(
        requests.any((request) => request.url.path.contains('block')),
        isFalse,
      );
    });
  }

  test('non-UUID and self writes make no HTTP request', () async {
    expect(await ZyraPersonalHideService.hide('local-fixture'), isFalse);
    expect(await ZyraPersonalHideService.hide(_owner), isFalse);
    expect(requests, isEmpty);
  });

  test('signed-out requests remain unavailable without HTTP', () async {
    await supabase.auth.signOut(scope: SignOutScope.local);
    requests.clear();
    expect(await ZyraPersonalHideService.hiddenIdsOrNull(), isNull);
    expect(await ZyraPersonalHideService.hide(_target), isFalse);
    expect(requests, isEmpty);
  });

  test('active local preview cannot transmit ordinary read or write', () async {
    ZyraInternalPreviewClient.beginPreview();
    expect(await ZyraPersonalHideService.hiddenIdsOrNull(), isNull);
    expect(await ZyraPersonalHideService.hide(_target), isFalse);
    expect(requests, isEmpty);
  });

  for (final action in ['read', 'hide', 'unhide']) {
    for (final change in ['owner', 'ABA', 'same-ID', 'generation', 'preview']) {
      test('late $action is denied after $change lifetime change', () async {
        response = action == 'read'
            ? _readAck([_target])
            : _writeAck(action == 'hide');
        release = Completer<void>();
        started = Completer<void>();
        final Future<Object?> pending = action == 'read'
            ? ZyraPersonalHideService.hiddenIdsOrNull()
            : ZyraPersonalHideService.setHidden(
                _target,
                hidden: action == 'hide',
              );
        await started!.future;
        switch (change) {
          case 'owner':
            await _session(_other);
          case 'ABA':
            await _session(_other);
            await _session(_owner);
          case 'same-ID':
            await _session(_owner, marker: 'replacement');
          case 'generation':
            ZyraAccountState.resetForTesting();
          case 'preview':
            ZyraInternalPreviewClient.beginPreview();
            ZyraInternalPreviewClient.finishSignOut();
        }
        await Future<void>.delayed(Duration.zero);
        release!.complete();
        expect(await pending, action == 'read' ? isNull : isFalse);
        expect(requests, hasLength(1));
      });
    }
  }
}
