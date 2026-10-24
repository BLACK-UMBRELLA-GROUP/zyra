import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_entitlement_service.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_wali_link_service.dart'
    show ZyraSourceFailure;
import 'package:zyra/state/app_state.dart';

const _a = '00000000-0000-4000-8000-000000000751';
const _b = '00000000-0000-4000-8000-000000000752';

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
        'created_at': '2026-09-23T00:00:00Z',
      },
    }),
  );
  await ZyraAccountState.synchronize(id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Object? answer = true;
  Future<void> Function()? beforeResponse;
  Future<http.Response> Function(http.Request)? customResponse;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.method != 'POST' ||
            request.url.path != '/rest/v1/rpc/wali_has_wali_one') {
          throw StateError('Unexpected synthetic entitlement transport.');
        }
        // Bind each reply before a held request can overlap another read.
        final response = customResponse;
        final before = beforeResponse;
        final body = answer;
        if (response != null) return response(request);
        await before?.call();
        return http.Response(
          jsonEncode(body),
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
    beforeResponse = null;
    customResponse = null;
    answer = true;
    await _session(_a);
  });
  tearDown(() => ZyraAccountState.clearImagesForTesting = null);
  tearDownAll(() => Supabase.instance.dispose());

  test(
    'confirmed Guardian access updates the shared membership screen state',
    () async {
      expect(AppState.instance.waliHasWaliOne, isFalse);
      expect(await ZyraEntitlementService.hasWaliOne(), isTrue);
      expect(AppState.instance.waliHasWaliOne, isTrue);
    },
  );

  test('confirmed loss of entitlement updates shared state', () async {
    AppState.instance.setWaliOne(true);
    answer = false;
    expect(await ZyraEntitlementService.hasWaliOne(), isFalse);
    expect(AppState.instance.waliHasWaliOne, isFalse);
  });

  test('old entitlement cannot grant access to a new account', () async {
    beforeResponse = () => _session(_b);
    expect(await ZyraEntitlementService.hasWaliOne(), isFalse);
    expect(AppState.instance.waliHasWaliOne, isFalse);
    expect(ZyraAccountState.userId, _b);
  });

  test(
    'a replaced same-user session cannot inherit an earlier grant',
    () async {
      beforeResponse = () async {
        await ZyraAccountState.synchronize(null);
        await _session(_a);
      };
      expect(await ZyraEntitlementService.hasWaliOne(), isFalse);
      expect(AppState.instance.waliHasWaliOne, isFalse);
    },
  );

  test(
    'malformed response denies access without inventing a membership change',
    () async {
      AppState.instance.setWaliOne(true);
      answer = null;
      expect(await ZyraEntitlementService.hasWaliOne(), isFalse);
      expect(AppState.instance.waliHasWaliOne, isTrue);
    },
  );

  for (final scenario in [
    (
      name: 'older true cannot overwrite newer false',
      older: true,
      newer: false,
    ),
    (
      name: 'older false cannot overwrite newer true',
      older: false,
      newer: true,
    ),
    (
      name: 'older true cannot grant after newer unavailable',
      older: true,
      newer: null,
    ),
  ]) {
    test('same-owner overlap: ${scenario.name}', () async {
      final started = Completer<void>();
      final releaseOlder = Completer<void>();
      var reads = 0;
      customResponse = (request) async {
        final read = ++reads;
        if (read > 2) throw StateError('Unexpected third entitlement read.');
        final value = read == 1 ? scenario.older : scenario.newer;
        final unavailable = read == 2 && scenario.newer == null;
        if (read == 1) {
          started.complete();
          await releaseOlder.future;
        }
        return http.Response(
          jsonEncode(
            unavailable
                ? {
                    'code': 'SYNTHETIC_UNAVAILABLE',
                    'message': 'Synthetic read unavailable',
                  }
                : value,
          ),
          unavailable ? 503 : 200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      };

      final older = ZyraEntitlementService.hasWaliOne();
      try {
        await started.future.timeout(const Duration(seconds: 5));
        final newer = await ZyraEntitlementService.hasWaliOne().timeout(
          const Duration(seconds: 5),
        );
        expect(newer, scenario.newer ?? false);
        expect(AppState.instance.waliHasWaliOne, scenario.newer ?? false);
        releaseOlder.complete();
        expect(await older.timeout(const Duration(seconds: 5)), isFalse);
        expect(
          AppState.instance.waliHasWaliOne,
          scenario.newer ?? false,
          reason: 'The superseded reply cannot publish its old access state',
        );
        expect(reads, 2);
        expect(ZyraAccountState.userId, _a);
      } finally {
        if (!releaseOlder.isCompleted) releaseOlder.complete();
      }
    });
  }

  for (final confirmed in [true, false]) {
    test('typed paid access preserves confirmed $confirmed', () async {
      AppState.instance.setWaliOne(!confirmed);
      answer = confirmed;
      final result = await ZyraEntitlementService.resolveGuardianPaidAccess();
      expect(result.isAvailable, isTrue);
      expect(result.isUnavailable, isFalse);
      expect(result.failure, isNull);
      expect(result.valueOrNull, confirmed);
      expect(AppState.instance.waliHasWaliOne, confirmed);
    });
  }

  test(
    'typed malformed response preserves the last confirmed display',
    () async {
      AppState.instance.setWaliOne(true);
      answer = null;
      final result = await ZyraEntitlementService.resolveGuardianPaidAccess();
      expect(result.isUnavailable, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failure, ZyraSourceFailure.invalidResponse);
      expect(AppState.instance.waliHasWaliOne, isTrue);
    },
  );

  test(
    'typed failed read is not confirmed Basic or a display downgrade',
    () async {
      AppState.instance.setWaliOne(true);
      customResponse = (request) async => http.Response(
        jsonEncode({
          'code': 'SYNTHETIC_UNAVAILABLE',
          'message': 'Synthetic read unavailable',
        }),
        503,
        request: request,
        headers: {'content-type': 'application/json'},
      );
      final result = await ZyraEntitlementService.resolveGuardianPaidAccess();
      expect(result.isUnavailable, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failure, ZyraSourceFailure.requestFailed);
      expect(AppState.instance.waliHasWaliOne, isTrue);
    },
  );

  for (final replacement in [false, true]) {
    test(
      'typed paid access refuses ${replacement ? 'A to B to A' : 'replacement owner'}',
      () async {
        beforeResponse = () async {
          await _session(_b);
          if (replacement) await _session(_a);
        };
        final generation = ZyraAccountState.generation;
        final result = await ZyraEntitlementService.resolveGuardianPaidAccess();
        expect(result.isUnavailable, isTrue);
        expect(result.valueOrNull, isNull);
        expect(result.failure, ZyraSourceFailure.signedOut);
        expect(AppState.instance.waliHasWaliOne, isFalse);
        expect(ZyraAccountState.userId, replacement ? _a : _b);
        expect(ZyraAccountState.generation, greaterThan(generation));
      },
    );
  }

  test('typed pending sign-out denies before making an RPC', () async {
    var reads = 0;
    customResponse = (request) async {
      reads++;
      return http.Response(
        'true',
        200,
        request: request,
        headers: {'content-type': 'application/json'},
      );
    };
    await ZyraAccountState.beginSignOut();
    // A synthetic sentinel verifies this denied read performs no display write.
    AppState.instance.setWaliOne(true);
    final result = await ZyraEntitlementService.resolveGuardianPaidAccess();
    expect(result.isUnavailable, isTrue);
    expect(result.valueOrNull, isNull);
    expect(result.failure, ZyraSourceFailure.signedOut);
    expect(reads, 0);
    expect(AppState.instance.waliHasWaliOne, isTrue);
    expect(ZyraAccountState.isSigningOut, isTrue);
    expect(ZyraAccountState.userId, isNull);
  });

  test(
    'typed read cannot return a grant after publication resets its owner',
    () async {
      Future<void>? signingOut;
      void withdraw() {
        if (AppState.instance.waliHasWaliOne && signingOut == null) {
          signingOut = ZyraAccountState.beginSignOut();
        }
      }

      AppState.instance.addListener(withdraw);
      try {
        final result = await ZyraEntitlementService.resolveGuardianPaidAccess();
        expect(signingOut, isNotNull);
        await signingOut;
        expect(result.isUnavailable, isTrue);
        expect(result.valueOrNull, isNull);
        expect(AppState.instance.waliHasWaliOne, isFalse);
        expect(ZyraAccountState.userId, isNull);
        expect(ZyraAccountState.isSigningOut, isTrue);
      } finally {
        AppState.instance.removeListener(withdraw);
        if (signingOut != null) await signingOut;
      }
    },
  );

  test('unused client mock purchase writers have been retired', () {
    final source = File(
      'lib/services/zyra_entitlement_service.dart',
    ).readAsStringSync();
    expect(source, isNot(contains('mockPurchaseWaliPremium')));
    expect(source, isNot(contains('mockSetWaliPlan')));
    expect(source, isNot(contains('mock_purchase_wali_premium')));
    expect(source, isNot(contains('mock_set_wali_plan')));
  });
}
