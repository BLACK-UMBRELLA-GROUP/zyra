import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/services/zyra_consent_service.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_hidden_profile_store.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_photo_service.dart';
import 'package:zyra/services/zyra_promotion_engine.dart';
import 'package:zyra/services/zyra_unlock_service.dart';

// Synthetic unsigned sessions; every HTTP request is intercepted in memory.
const _a = '00000000-0000-0000-0000-000000000801';
const _b = '00000000-0000-0000-0000-000000000802';
const _target = '00000000-0000-0000-0000-000000000803';

Future<void> _session(String id) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return supabase.auth.setInitialSession(
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
        'email': 'synthetic@example.invalid',
        'created_at': '2026-09-14T00:00:00Z',
      },
    }),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Future<http.Response> Function(http.Request) responder;
  http.Request? responseRequest;

  http.Response json(Object? value) => http.Response(
    jsonEncode(value),
    200,
    request: responseRequest,
    headers: {'content-type': 'application/json'},
  );

  void clear() {
    ZyraUnlockService.clearForSignOut();
    ZyraConsentService.clearForSignOut();
    ZyraPhotoService.clearUrlMemoForSignOut();
    ZyraHiddenProfileStore.clearForAccountChange();
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    responder = (_) async => json([]);
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) {
        responseRequest = request;
        return responder(request);
      }),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await _session(_a);
    clear();
    responder = (_) async => json([]);
  });

  test(
    'unlock load arriving after same-account reset cannot refill cache',
    () async {
      final started = Completer<void>();
      final response = Completer<http.Response>();
      responder = (_) {
        started.complete();
        return response.future;
      };
      final pending = ZyraUnlockService.load();
      await started.future;
      ZyraUnlockService.clearForSignOut();
      response.complete(
        json([
          {'unlocked_id': _target, 'unlock_type': 'paid_single'},
        ]),
      );
      await pending;
      expect(ZyraUnlockService.loaded, isFalse);
      expect(
        ZyraUnlockService.isUnlocked(_target, UnlockTier.standard),
        isFalse,
      );
    },
  );

  test(
    'late unlock success cannot grant cache access to another account',
    () async {
      final started = Completer<void>();
      final response = Completer<http.Response>();
      responder = (_) {
        started.complete();
        return response.future;
      };
      final pending = ZyraUnlockService.unlock(_target, UnlockTier.standard);
      await started.future;
      await _session(_b);
      response.complete(json({'status': 'unlocked'}));
      expect(await pending, UnlockOutcome.failed);
      expect(
        ZyraUnlockService.isUnlocked(_target, UnlockTier.standard),
        isFalse,
      );
    },
  );

  test('late balances cannot be returned under another account', () async {
    final started = Completer<void>();
    final response = Completer<http.Response>();
    responder = (_) {
      started.complete();
      return response.future;
    };
    final pending = ZyraUnlockService.readBalances();
    await started.future;
    await _session(_b);
    response.complete(
      json([
        {'tier': 'paid_single', 'balance': 99},
      ]),
    );
    final result = await pending;
    expect(result.status, UnlockBalanceStatus.stale);
    expect(result.values, isEmpty);
  });

  test(
    'loaded unlock cache never survives a direct principal change',
    () async {
      responder = (_) async => json([
        {'unlocked_id': _target, 'unlock_type': 'paid_single'},
      ]);
      await ZyraUnlockService.load();
      expect(
        ZyraUnlockService.isUnlocked(_target, UnlockTier.standard),
        isTrue,
      );
      await _session(_b);
      expect(ZyraUnlockService.loaded, isFalse);
      expect(
        ZyraUnlockService.isUnlocked(_target, UnlockTier.standard),
        isFalse,
      );
    },
  );

  test(
    'consent check arriving after reset cannot repopulate consent',
    () async {
      final started = Completer<void>();
      final response = Completer<http.Response>();
      responder = (_) {
        started.complete();
        return response.future;
      };
      final pending = ZyraConsentService.hasArticle9Consent();
      await started.future;
      ZyraConsentService.clearForSignOut();
      response.complete(json(true));
      expect(await pending, isFalse);
      responder = (_) async => json(false);
      expect(await ZyraConsentService.hasArticle9Consent(), isFalse);
    },
  );

  test('late consent grant cannot consent the next account', () async {
    final started = Completer<void>();
    final response = Completer<http.Response>();
    responder = (request) {
      expect(jsonDecode(request.body)['user_id'], _a);
      started.complete();
      return response.future;
    };
    final pending = ZyraConsentService.record(granted: true);
    await started.future;
    await _session(_b);
    response.complete(json(null));
    expect(await pending, isFalse);
    responder = (_) async => json(false);
    expect(await ZyraConsentService.hasArticle9Consent(), isFalse);
  });

  test('late consent history is discarded after principal change', () async {
    final started = Completer<void>();
    final response = Completer<http.Response>();
    responder = (_) {
      started.complete();
      return response.future;
    };
    final pending = ZyraConsentService.history();
    await started.future;
    await _session(_b);
    response.complete(
      json([
        {
          'granted': true,
          'policy_version': 'synthetic',
          'recorded_at': '2026-09-14T00:00:00Z',
        },
      ]),
    );
    expect(await pending, isEmpty);
  });

  test(
    'late signed URLs cannot return or refill the cleared bearer memo',
    () async {
      final started = Completer<void>();
      final response = Completer<http.Response>();
      var requests = 0;
      responder = (_) {
        requests++;
        started.complete();
        return response.future;
      };
      final pending = ZyraPhotoService.signedUrlMap(['shared/photo.jpg']);
      await started.future;
      ZyraPhotoService.clearUrlMemoForSignOut();
      response.complete(
        json([
          {
            'path': 'shared/photo.jpg',
            'signedURL':
                '/object/sign/profile-photos/shared/photo.jpg?token=synthetic-a',
          },
        ]),
      );
      expect(await pending, isEmpty);
      responder = (_) async {
        requests++;
        return json([
          {
            'path': 'shared/photo.jpg',
            'signedURL':
                '/object/sign/profile-photos/shared/photo.jpg?token=synthetic-new',
          },
        ]);
      };
      final fresh = await ZyraPhotoService.signedUrlMap(['shared/photo.jpg']);
      expect(fresh['shared/photo.jpg'], contains('synthetic-new'));
      expect(requests, 2);
    },
  );

  test(
    'late own-photo list does not trigger signing under next account',
    () async {
      final started = Completer<void>();
      final response = Completer<http.Response>();
      var requests = 0;
      responder = (_) {
        requests++;
        started.complete();
        return response.future;
      };
      final pending = ZyraPhotoService.fetchOwnPhotos();
      await started.future;
      await _session(_b);
      response.complete(
        json([
          {'storage_path': '$_a/photo.jpg', 'display_order': 0},
        ]),
      );
      expect(await pending, isEmpty);
      expect(requests, 1);
    },
  );

  test(
    'photo sync stops after old-account delete when principal changes',
    () async {
      final started = Completer<void>();
      final response = Completer<http.Response>();
      var requests = 0;
      responder = (request) {
        requests++;
        expect(request.method, 'DELETE');
        expect(request.url.queryParameters['user_id'], 'eq.$_a');
        started.complete();
        return response.future;
      };
      final pending = ZyraPhotoService.syncPhotos([
        'https://example.supabase.co/storage/v1/object/sign/profile-photos/$_a/photo.jpg?token=synthetic',
      ]);
      await started.future;
      await _session(_b);
      response.complete(json(null));
      await pending;
      expect(requests, 1);
    },
  );

  const demo = SeekerProfile(
    id: 'synthetic-hidden',
    firstName: 'Synthetic',
    age: 25,
    city: 'Test',
    photos: [],
    gender: 'female',
  );

  test('hidden remember cannot read A then write its summary into B', () async {
    final pending = ZyraHiddenProfileStore.remember(demo);
    final switchAccount = _session(_b);
    ZyraHiddenProfileStore.clearForAccountChange();
    await switchAccount;
    await pending;
    expect(await ZyraHiddenProfileStore.records(), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('zyra.hidden_profiles.v1.$_b'), isNull);
  });

  test('hidden forget cannot overwrite next account records', () async {
    await _session(_b);
    await ZyraHiddenProfileStore.remember(demo);
    await _session(_a);
    final pending = ZyraHiddenProfileStore.forget(demo.id);
    final switchAccount = _session(_b);
    ZyraHiddenProfileStore.clearForAccountChange();
    await switchAccount;
    await pending;
    expect((await ZyraHiddenProfileStore.records()).single.id, demo.id);
  });

  test(
    'promotion reset is synchronous and stale initialize never notifies',
    () async {
      await ZyraLocalPrefs.init();
      await ZyraLocalPrefs.bindAccount(_a);
      final engine = ZyraPromotionEngine();
      var changes = 0;
      engine.addListener(() => changes++);
      final pending = engine.initialize();
      engine.resetForAccountChange();
      expect(changes, 1);
      expect(
        engine.permissionState,
        ZyraNotificationPermissionState.unavailable,
      );
      expect(engine.promptHistory.notificationExplainers, 0);
      await pending;
      expect(changes, 1);
      await engine.initialize();
      expect(
        changes,
        2,
        reason: 'reset made initialization available for the next owner',
      );
      engine.dispose();
    },
  );

  test(
    'late developer policy reset cannot restore previous account memory',
    () async {
      await ZyraLocalPrefs.init();
      await ZyraLocalPrefs.bindAccount(_a);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      final engine = ZyraPromotionEngine();
      await engine.initialize();
      var changes = 0;
      engine.addListener(() => changes++);
      final pending = engine.resetDeveloperPolicy();
      engine.resetForAccountChange();
      await pending;
      expect(changes, 1);
      expect(
        engine.permissionState,
        ZyraNotificationPermissionState.unavailable,
      );
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      engine.dispose();
    },
  );
}
