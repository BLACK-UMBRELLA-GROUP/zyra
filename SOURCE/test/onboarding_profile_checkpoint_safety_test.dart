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
import 'package:zyra/services/zyra_profile_service.dart';
import 'package:zyra/services/zyra_seeker_details_service.dart';

const _ownerA = '00000000-0000-0000-0000-000000000021';
const _ownerB = '00000000-0000-0000-0000-000000000022';
const _detailsPath = '/rest/v1/seeker_details';
const _profilesPath = '/rest/v1/profiles';
const _consentPath = '/rest/v1/rpc/has_article9_consent';
String _replyOwner = _ownerA;
bool _emptyWrite = false;
int _detailsWrites = 0;
int _locationWrites = 0;
int _consentReads = 0;
int _ownReads = 0;
Map<String, dynamic>? _detailsPayload;
String? _pausePath;
Completer<void>? _started;
Completer<void>? _release;

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

http.Response _json(Object? value, http.Request request) => http.Response(
  jsonEncode(value),
  200,
  request: request,
  headers: {'content-type': 'application/json'},
);

void _pause(String path) {
  _pausePath = path;
  _started = Completer<void>();
  _release = Completer<void>();
}

Future<void> _waitAt(http.Request request) async {
  if (_pausePath != request.url.path) return;
  if (!_started!.isCompleted) _started!.complete();
  await _release!.future;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'local-profile-checkpoint-test',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        final path = request.url.path;
        if (path == _consentPath) {
          _consentReads++;
          await _waitAt(request);
          return _json(true, request);
        }
        if (path == _detailsPath && request.method == 'POST') {
          _detailsWrites++;
          _detailsPayload = jsonDecode(request.body) as Map<String, dynamic>;
          await _waitAt(request);
          return _json(_emptyWrite ? null : {'user_id': _replyOwner}, request);
        }
        if (path == _profilesPath && request.method == 'PATCH') {
          _locationWrites++;
          await _waitAt(request);
          return _json(_emptyWrite ? null : {'id': _replyOwner}, request);
        }
        if (request.method == 'GET' && path == _detailsPath) {
          _ownReads++;
          await _waitAt(request);
          return _json([
            {
              'user_id': _replyOwner,
              'languages': ['en'],
              'preferences': <String, Object?>{},
            },
          ], request);
        }
        if (request.method == 'GET' && path == _profilesPath) {
          _ownReads++;
          await _waitAt(request);
          return _json([
            {'id': _replyOwner, 'location_text': 'London'},
          ], request);
        }
        return http.Response('local test denied', 403, request: request);
      }),
    );
  });

  tearDownAll(() => Supabase.instance.dispose());

  setUp(() async {
    _replyOwner = _ownerA;
    _emptyWrite = false;
    _detailsWrites = 0;
    _locationWrites = 0;
    _consentReads = 0;
    _ownReads = 0;
    _detailsPayload = null;
    _pausePath = null;
    _started = null;
    _release = null;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraConsentService.clearForSignOut();
    await _session(_ownerA);
    await ZyraAccountState.synchronize(_ownerA);
  });

  tearDown(() {
    if (_release != null && !_release!.isCompleted) _release!.complete();
    ZyraConsentService.clearForSignOut();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = null;
  });

  test(
    'a cached-consent yield cannot start a stale same-owner details write',
    () async {
      expect(await ZyraConsentService.hasArticle9Consent(), isTrue);
      final pending = ZyraSeekerDetailsService.saveDetails(
        const SeekerDetails(languages: ['English']),
        expectedUserId: _ownerA,
      );
      // The UID is unchanged and cached consent is true, but this draft belongs
      // to the prior account-state generation, before the await resumed.
      ZyraAccountState.resetForTesting();
      expect(await pending, isFalse);
      expect(_consentReads, 1);
      expect(_detailsWrites, 0);
    },
  );

  test(
    'details payload is detached before awaiting the consent decision',
    () async {
      final languages = ['English'];
      final distance = <String, dynamic>{'preference': 'initial-value'};
      _pause(_consentPath);
      final pending = ZyraSeekerDetailsService.saveDetails(
        SeekerDetails(
          languages: languages,
          preferences: {'location': distance},
        ),
        expectedUserId: _ownerA,
      );
      await _started!.future;
      languages.add('Arabic');
      distance['preference'] = 'edited-after-submit';
      _release!.complete();
      expect(await pending, isTrue);
      expect(_detailsPayload!['languages'], ['en']);
      expect((_detailsPayload!['preferences'] as Map)['location'], {
        'preference': 'initial-value',
      });
    },
  );

  test('strict own-details read rejects a same-UID generation reset', () async {
    _pause(_detailsPath);
    final pending = ZyraSeekerDetailsService.fetchOwn(
      expectedUserId: _ownerA,
      throwOnError: true,
    );
    final rejected = expectLater(pending, throwsStateError);
    await _started!.future;
    ZyraAccountState.resetForTesting();
    _release!.complete();
    await rejected;
    expect(_ownReads, 1);
  });

  test(
    'a late details write is not reported saved after a generation reset',
    () async {
      _pause(_detailsPath);
      final pending = ZyraSeekerDetailsService.saveDetails(
        const SeekerDetails(languages: ['English']),
        expectedUserId: _ownerA,
      );
      await _started!.future;
      ZyraAccountState.resetForTesting();
      _release!.complete();
      expect(await pending, isFalse);
      expect(_detailsWrites, 1);
    },
  );

  test('own-location read rejects a same-UID generation reset', () async {
    _pause(_profilesPath);
    final pending = ZyraProfileService.fetchOwnLocation(
      expectedUserId: _ownerA,
    );
    final rejected = expectLater(pending, throwsStateError);
    await _started!.future;
    ZyraAccountState.resetForTesting();
    _release!.complete();
    await rejected;
  });

  test(
    'location save rejects success after a same-UID generation reset',
    () async {
      _pause(_profilesPath);
      final pending = ZyraProfileService.saveLocation(
        ' London ',
        expectedUserId: _ownerA,
      );
      await _started!.future;
      ZyraAccountState.resetForTesting();
      _release!.complete();
      expect(await pending, isFalse);
      expect(_locationWrites, 1);
    },
  );

  test('details and location require the exact returned own row', () async {
    expect(
      await ZyraSeekerDetailsService.saveDetails(
        const SeekerDetails(),
        expectedUserId: _ownerA,
      ),
      isTrue,
    );
    expect(await ZyraProfileService.saveLocation('London'), isTrue);
    expect(
      await ZyraProfileService.fetchOwnLocation(expectedUserId: _ownerA),
      'London',
    );
    _replyOwner = _ownerB;
    expect(
      await ZyraSeekerDetailsService.saveDetails(const SeekerDetails()),
      isFalse,
    );
    expect(await ZyraProfileService.saveLocation('London'), isFalse);
    await expectLater(
      ZyraSeekerDetailsService.fetchOwn(
        expectedUserId: _ownerA,
        throwOnError: true,
      ),
      throwsStateError,
    );
    expect(await ZyraSeekerDetailsService.fetchOwn(), isNull);
    await expectLater(
      ZyraProfileService.fetchOwnLocation(expectedUserId: _ownerA),
      throwsStateError,
    );
  });

  test('a response with no matching updated row is not save success', () async {
    _emptyWrite = true;
    expect(
      await ZyraSeekerDetailsService.saveDetails(const SeekerDetails()),
      isFalse,
    );
    expect(await ZyraProfileService.saveLocation('London'), isFalse);
  });

  test(
    'wrong expected owners cannot read or write the current profile',
    () async {
      expect(
        await ZyraSeekerDetailsService.saveDetails(
          const SeekerDetails(),
          expectedUserId: _ownerB,
        ),
        isFalse,
      );
      expect(
        await ZyraProfileService.saveLocation(
          'London',
          expectedUserId: _ownerB,
        ),
        isFalse,
      );
      await expectLater(
        ZyraSeekerDetailsService.fetchOwn(
          expectedUserId: _ownerB,
          throwOnError: true,
        ),
        throwsStateError,
      );
      await expectLater(
        ZyraProfileService.fetchOwnLocation(expectedUserId: _ownerB),
        throwsStateError,
      );
      expect(_detailsWrites + _locationWrites + _consentReads + _ownReads, 0);
    },
  );
}
