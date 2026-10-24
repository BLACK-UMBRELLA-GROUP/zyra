import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_unlock_service.dart';

// Synthetic HTTP only. These fixtures never query a real account/database.
const _owner = '00000000-0000-4000-8000-000000004401';
const _otherOwner = '00000000-0000-4000-8000-000000004402';
const _target = '00000000-0000-4000-8000-00000000440a';
const _otherTarget = '00000000-0000-4000-8000-00000000440b';

Future<void> _session(String owner) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': owner, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': owner,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-20T00:00:00Z',
      },
    }),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Future<http.Response> Function(http.Request) responder;
  final requests = <http.Request>[];
  http.Response json(Object? body, {int status = 200}) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://owned-access.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = await responder(request);
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
          reasonPhrase: response.reasonPhrase,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
        );
      }),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() async {
    responder = (request) async =>
        json(request.url.path.endsWith('/logout') ? {} : []);
    await _session(_owner);
    ZyraUnlockService.clearForSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    requests.clear();
  });
  tearDown(() {
    ZyraUnlockService.clearForSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
  });

  for (final type in [
    'paid_single',
    'paid_bundle',
    'automatic_match',
    'paid_plus_single',
    'paid_plus_bundle',
  ]) {
    test('bounded $type grant read preserves permanent access', () async {
      responder = (_) async => json([
        {'unlocked_id': _target.toUpperCase(), 'unlock_type': type},
      ]);
      expect(
        await ZyraUnlockService.confirmOwnedAccess(
          _target.toUpperCase(),
          UnlockTier.standard,
        ),
        isTrue,
      );
      expect(ZyraUnlockService.loaded, isFalse);
      expect(requests, hasLength(1));
      final query = requests.single.url.queryParameters;
      expect(requests.single.url.path, endsWith('/profile_unlocks'));
      expect(query['unlocker_id'], 'eq.$_owner');
      expect(query['unlocked_id'], 'eq.$_target');
      expect(query['select'], 'unlocked_id,unlock_type');
      expect(
        ZyraUnlockService.isUnlocked(_target, UnlockTier.plus),
        type.startsWith('paid_plus_'),
      );
      // Reopening before, during or after a Journey uses the same grant key;
      // there is no Journey/attempt argument and no debit or balance call.
      for (var visit = 0; visit < 3; visit++) {
        expect(
          await ZyraUnlockService.confirmOwnedAccess(
            _target,
            UnlockTier.standard,
          ),
          isTrue,
        );
        expect(
          await ZyraUnlockService.unlock(_target, UnlockTier.standard),
          UnlockOutcome.alreadyUnlocked,
        );
      }
      expect(requests, hasLength(1));
    });
  }

  test('Standard ownership does not manufacture Plus', () async {
    responder = (_) async => json([
      {'unlocked_id': _target, 'unlock_type': 'paid_bundle'},
    ]);
    expect(
      await ZyraUnlockService.confirmOwnedAccess(_target, UnlockTier.plus),
      isFalse,
    );
    expect(ZyraUnlockService.isUnlocked(_target, UnlockTier.standard), isTrue);
    expect(ZyraUnlockService.isUnlocked(_target, UnlockTier.plus), isFalse);
    expect(
      await ZyraUnlockService.unlock(_target, UnlockTier.plus),
      UnlockOutcome.unavailable,
    );
    expect(requests, hasLength(1));
  });

  test('read guard cannot be revived by a grant in a later epoch', () async {
    responder = (_) async => json([
      {'unlocked_id': _target, 'unlock_type': 'paid_single'},
    ]);
    final guard = ZyraUnlockService.ownedReadGuard(
      _target,
      UnlockTier.standard,
    );
    expect(guard(), isFalse);
    expect(
      await ZyraUnlockService.confirmOwnedAccess(_target, UnlockTier.standard),
      isTrue,
    );
    expect(guard(), isTrue);
    ZyraUnlockService.clearForSignOut();
    expect(guard(), isFalse);
    expect(
      await ZyraUnlockService.confirmOwnedAccess(_target, UnlockTier.standard),
      isTrue,
    );
    expect(guard(), isFalse);
    expect(
      ZyraUnlockService.ownedReadGuard(_target, UnlockTier.standard)(),
      isTrue,
    );
  });

  test('empty is confirmed unowned; failed read stays unknown', () async {
    expect(
      await ZyraUnlockService.confirmOwnedAccess(_target, UnlockTier.standard),
      isFalse,
    );
    responder = (_) async => json({'message': 'synthetic denied'}, status: 403);
    expect(
      await ZyraUnlockService.confirmOwnedAccess(_target, UnlockTier.standard),
      isNull,
    );
    expect(ZyraUnlockService.loaded, isFalse);
    expect(ZyraUnlockService.isUnlocked(_target, UnlockTier.standard), isFalse);
  });

  for (final malformed in [
    [
      {'unlocked_id': _otherTarget, 'unlock_type': 'paid_plus_single'},
    ],
    [
      {'unlocked_id': _target, 'unlock_type': 'unknown'},
    ],
    [
      {'unlocked_id': null, 'unlock_type': 'paid_single'},
    ],
    [
      {'unlocked_id': _target, 'unlock_type': 'paid_single'},
      {'unlocked_id': _otherTarget, 'unlock_type': 'paid_plus_single'},
    ],
  ]) {
    test('malformed $malformed is unknown with no partial grant', () async {
      responder = (_) async => json(malformed);
      expect(
        await ZyraUnlockService.confirmOwnedAccess(
          _target,
          UnlockTier.standard,
        ),
        isNull,
      );
      expect(
        ZyraUnlockService.isUnlocked(_target, UnlockTier.standard),
        isFalse,
      );
      expect(
        ZyraUnlockService.isUnlocked(_otherTarget, UnlockTier.plus),
        isFalse,
      );
    });
  }

  test('independent target read survives concurrent full hydration', () async {
    final started = Completer<void>();
    final hydration = Completer<http.Response>();
    responder = (request) {
      if (!request.url.queryParameters.containsKey('unlocked_id')) {
        started.complete();
        return hydration.future;
      }
      return Future.value(
        json([
          {'unlocked_id': _target, 'unlock_type': 'paid_plus_bundle'},
        ]),
      );
    };
    final fullRead = ZyraUnlockService.load();
    await started.future.timeout(const Duration(seconds: 3));
    expect(
      await ZyraUnlockService.confirmOwnedAccess(_target, UnlockTier.standard),
      isTrue,
    );
    expect(ZyraUnlockService.loaded, isFalse);
    hydration.complete(json([]));
    await fullRead;
    expect(ZyraUnlockService.loaded, isTrue);
    expect(ZyraUnlockService.isUnlocked(_target, UnlockTier.plus), isTrue);
  });

  test(
    'concurrent confirmed debit is not erased by an older empty read',
    () async {
      final started = Completer<void>();
      final read = Completer<http.Response>();
      responder = (request) {
        if (request.url.path.endsWith('/profile_unlocks')) {
          started.complete();
          return read.future;
        }
        if (request.url.path.endsWith('/zyra_unlock_profile')) {
          return Future.value(json({'status': 'unlocked', 'charged': true}));
        }
        throw StateError('Unexpected synthetic request');
      };
      final pending = ZyraUnlockService.confirmOwnedAccess(
        _target,
        UnlockTier.standard,
      );
      await started.future.timeout(const Duration(seconds: 3));
      expect(
        await ZyraUnlockService.unlock(_target, UnlockTier.standard),
        UnlockOutcome.unlocked,
      );
      read.complete(json([]));
      expect(await pending, isTrue);
      expect(
        ZyraUnlockService.isUnlocked(_target, UnlockTier.standard),
        isTrue,
      );
    },
  );

  test('older failed read preserves a concurrently confirmed grant', () async {
    final started = Completer<void>();
    final read = Completer<http.Response>();
    responder = (request) {
      if (request.url.path.endsWith('/profile_unlocks')) {
        started.complete();
        return read.future;
      }
      if (request.url.path.endsWith('/zyra_unlock_profile')) {
        return Future.value(json({'status': 'unlocked', 'charged': true}));
      }
      throw StateError('Unexpected synthetic request');
    };
    final pending = ZyraUnlockService.confirmOwnedAccess(
      _target,
      UnlockTier.standard,
    );
    await started.future.timeout(const Duration(seconds: 3));
    expect(
      await ZyraUnlockService.unlock(_target, UnlockTier.standard),
      UnlockOutcome.unlocked,
    );
    read.complete(json({'message': 'synthetic denied'}, status: 403));
    expect(await pending, isTrue);
    expect(ZyraUnlockService.isUnlocked(_target, UnlockTier.standard), isTrue);
    expect(ZyraUnlockService.loaded, isFalse);
    expect(
      requests.where((r) => r.url.path.endsWith('/profile_unlocks')),
      hasLength(1),
    );
    expect(
      requests.where((r) => r.url.path.endsWith('/zyra_unlock_profile')),
      hasLength(1),
    );
  });

  testWidgets('older timed-out read preserves a concurrently confirmed grant', (
    tester,
  ) async {
    final started = Completer<void>();
    final read = Completer<http.Response>();
    responder = (request) {
      if (request.url.path.endsWith('/profile_unlocks')) {
        started.complete();
        return read.future;
      }
      if (request.url.path.endsWith('/zyra_unlock_profile')) {
        return Future.value(json({'status': 'unlocked', 'charged': true}));
      }
      throw StateError('Unexpected synthetic request');
    };
    final pending = ZyraUnlockService.confirmOwnedAccess(
      _target,
      UnlockTier.standard,
    );
    await tester.pump();
    await tester.runAsync(
      () => started.future.timeout(const Duration(seconds: 3)),
    );
    expect(
      await tester.runAsync(
        () => ZyraUnlockService.unlock(_target, UnlockTier.standard),
      ),
      UnlockOutcome.unlocked,
    );
    await tester.pump(const Duration(seconds: 9));
    expect(await pending, isTrue);
    expect(ZyraUnlockService.isUnlocked(_target, UnlockTier.standard), isTrue);
    read.complete(json([]));
    await tester.pump();
    expect(
      requests.where((r) => r.url.path.endsWith('/zyra_unlock_profile')),
      hasLength(1),
    );
    expect(
      requests.where((r) => r.url.path.endsWith('/profile_unlocks')),
      hasLength(1),
    );
  });

  for (final reset in ['generation', 'owner', 'owner ABA', 'epoch']) {
    test('$reset change rejects a late target grant', () async {
      final started = Completer<void>();
      final read = Completer<http.Response>();
      responder = (_) {
        started.complete();
        return read.future;
      };
      final pending = ZyraUnlockService.confirmOwnedAccess(
        _target,
        UnlockTier.standard,
      );
      await started.future.timeout(const Duration(seconds: 3));
      switch (reset) {
        case 'generation':
          ZyraAccountState.resetForTesting();
        case 'owner':
          await _session(_otherOwner);
        case 'owner ABA':
          await _session(_otherOwner);
          // Account synchronization changes the generation even when the
          // original principal returns before the first read finishes.
          ZyraAccountState.resetForTesting();
          await _session(_owner);
        case 'epoch':
          ZyraUnlockService.clearForSignOut();
      }
      read.complete(
        json([
          {'unlocked_id': _target, 'unlock_type': 'paid_plus_bundle'},
        ]),
      );
      expect(await pending, isNull);
      expect(ZyraUnlockService.isUnlocked(_target, UnlockTier.plus), isFalse);
    });
  }

  testWidgets('target read times out without a late grant', (tester) async {
    final read = Completer<http.Response>();
    responder = (_) => read.future;
    bool? result;
    var complete = false;
    final pending =
        ZyraUnlockService.confirmOwnedAccess(_target, UnlockTier.standard).then(
          (value) {
            result = value;
            complete = true;
          },
        );
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    expect(complete, isTrue);
    expect(result, isNull);
    read.complete(
      json([
        {'unlocked_id': _target, 'unlock_type': 'paid_plus_single'},
      ]),
    );
    await tester.pump();
    await pending;
    expect(ZyraUnlockService.isUnlocked(_target, UnlockTier.plus), isFalse);
  });

  test('sample and signed-out inputs do not start member reads', () async {
    expect(
      await ZyraUnlockService.confirmOwnedAccess('sample', UnlockTier.standard),
      isFalse,
    );
    expect(requests, isEmpty);
    await supabase.auth.signOut(scope: SignOutScope.local);
    requests.clear();
    expect(
      await ZyraUnlockService.confirmOwnedAccess(_target, UnlockTier.standard),
      isNull,
    );
    expect(requests, isEmpty);
  });
}
