import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/subscription/profile_unlock_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_unlock_service.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_gold_action_pill.dart';

// No backend is contacted: all Auth, ledger, score and Guardian HTTP is synthetic.
const _owner = '00000000-0000-0000-0000-000000000901';
const _otherOwner = '00000000-0000-0000-0000-000000000902';
const _target = '00000000-0000-0000-0000-000000000903';
const _profile = SeekerProfile(
  id: _target,
  firstName: 'Synthetic',
  age: 30,
  city: 'Test',
  photos: [],
  gender: 'female',
);

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
        'email': 'synthetic@example.invalid',
        'created_at': '2026-10-06T00:00:00Z',
      },
    }),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Future<http.Response> Function(http.Request) responder;
  final requests = <http.Request>[];
  http.Request? responseRequest;
  http.Response json(Object? value, {int status = 200}) => http.Response(
    jsonEncode(value),
    status,
    request: responseRequest,
    headers: {'content-type': 'application/json'},
  );
  Future<http.Response> defaults(http.Request request) async {
    if (request.url.path.endsWith('/logout')) return json({});
    if (request.url.path.endsWith('/unlock_balance')) {
      return json([
        {'tier': 'paid_single', 'balance': 1},
      ]);
    }
    if (request.url.path.endsWith('/score_candidates')) {
      return json([
        {'candidate_id': _target, 'score': 77},
      ]);
    }
    if (request.url.path.endsWith('/guardians_for_unlocked')) return json([]);
    if (request.url.path.endsWith('/profile_unlocks')) return json([]);
    throw StateError('Unexpected synthetic endpoint ${request.url.path}');
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    responder = defaults;
    await Supabase.initialize(
      url: 'https://test.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) {
        requests.add(request);
        responseRequest = request;
        return responder(request);
      }),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() async {
    await _session(_owner);
    ZyraUnlockService.clearForSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = true;
    requests.clear();
    responder = defaults;
  });
  tearDown(() {
    ZyraUnlockService.clearForSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = false;
  });

  for (final type in [
    'paid_single',
    'paid_bundle',
    'automatic_match',
    'paid_plus_single',
    'paid_plus_bundle',
  ]) {
    test('$type permanently grants Standard without a repeat debit', () async {
      responder = (_) async => json([
        {'unlocked_id': _target, 'unlock_type': type},
      ]);
      await ZyraUnlockService.load();
      expect(
        ZyraUnlockService.isUnlocked(_target, UnlockTier.standard),
        isTrue,
      );
      expect(
        await ZyraUnlockService.unlock(_target, UnlockTier.standard),
        UnlockOutcome.alreadyUnlocked,
      );
      expect(
        ZyraUnlockService.isUnlocked(_target, UnlockTier.plus),
        type.startsWith('paid_plus_'),
      );
      expect(
        requests.where((r) => r.url.path.endsWith('/zyra_unlock_profile')),
        isEmpty,
      );
    });
  }

  test('server Plus hold is an explicit unavailable outcome', () async {
    responder = (_) async =>
        json({'status': 'plus_unavailable', 'charged': false});
    expect(
      await ZyraUnlockService.unlock(_target, UnlockTier.standard),
      UnlockOutcome.unavailable,
    );
    expect(ZyraUnlockService.isUnlocked(_target, UnlockTier.standard), isFalse);
  });

  for (final response in [
    {'status': 'recovery_required', 'charged': false},
    {'status': 'not_a_known_ack'},
    <String, Object?>{},
  ]) {
    test(
      'uncertain acknowledgement $response requires read-only recovery',
      () async {
        responder = (_) async => json(response);
        expect(
          (await ZyraUnlockService.unlock(_target, UnlockTier.standard)).name,
          'recoveryRequired',
        );
        expect(
          ZyraUnlockService.isUnlocked(_target, UnlockTier.standard),
          isFalse,
        );
        expect(
          requests.where((r) => r.url.path.endsWith('/zyra_unlock_profile')),
          hasLength(1),
        );
      },
    );
  }

  test(
    'transport loss requires recovery and never retries the debit',
    () async {
      responder = (_) async => throw http.ClientException('synthetic lost ACK');
      expect(
        (await ZyraUnlockService.unlock(_target, UnlockTier.standard)).name,
        'recoveryRequired',
      );
      expect(
        requests.where((r) => r.url.path.endsWith('/zyra_unlock_profile')),
        hasLength(1),
      );
      expect(
        await ZyraUnlockService.unlock(_target, UnlockTier.standard),
        UnlockOutcome.recoveryRequired,
      );
      expect(
        requests.where((r) => r.url.path.endsWith('/zyra_unlock_profile')),
        hasLength(1),
      );
    },
  );

  test('ordinary sample ids cannot manufacture local access', () async {
    final outcome = await ZyraUnlockService.unlock(
      'ordinary-sample',
      UnlockTier.standard,
    );
    expect(outcome, isNot(UnlockOutcome.sampleProfile));
    expect(
      ZyraUnlockService.isUnlocked('ordinary-sample', UnlockTier.standard),
      isFalse,
    );
    expect(requests, isEmpty);
  });

  test('signed-out UUID cannot manufacture a live success', () async {
    await supabase.auth.signOut(scope: SignOutScope.local);
    requests.clear();
    final outcome = await ZyraUnlockService.unlock(
      _target,
      UnlockTier.standard,
    );
    expect(outcome, isNot(UnlockOutcome.unlocked));
    expect(ZyraUnlockService.isUnlocked(_target, UnlockTier.standard), isFalse);
    expect(requests, isEmpty);
  });

  test('same-target in-flight attempts issue one RPC', () async {
    final started = Completer<void>();
    final response = Completer<http.Response>();
    responder = (_) {
      if (!started.isCompleted) started.complete();
      return response.future;
    };
    final first = ZyraUnlockService.unlock(_target, UnlockTier.standard);
    await started.future;
    final second = ZyraUnlockService.unlock(_target, UnlockTier.standard);
    response.complete(json({'status': 'unlocked', 'charged': true}));
    await Future.wait([first, second]);
    expect(
      requests.where((r) => r.url.path.endsWith('/zyra_unlock_profile')),
      hasLength(1),
    );
  });

  test('late load cannot erase a confirmed permanent unlock', () async {
    final started = Completer<void>();
    final response = Completer<http.Response>();
    responder = (request) {
      if (request.url.path.endsWith('/profile_unlocks')) {
        started.complete();
        return response.future;
      }
      return Future.value(json({'status': 'unlocked', 'charged': true}));
    };
    final load = ZyraUnlockService.load();
    await started.future;
    expect(
      await ZyraUnlockService.unlock(_target, UnlockTier.standard),
      UnlockOutcome.unlocked,
    );
    response.complete(json([]));
    await load;
    expect(ZyraUnlockService.isUnlocked(_target, UnlockTier.standard), isTrue);
  });

  testWidgets('failed ledger read remains unknown rather than none left', (
    tester,
  ) async {
    responder = (request) {
      if (request.url.path.endsWith('/unlock_balance')) {
        return Future.value(json({'message': 'synthetic denied'}, status: 403));
      }
      return defaults(request);
    };
    await tester.pumpWidget(
      const MaterialApp(home: ProfileUnlockScreen(profile: _profile)),
    );
    await tester.pumpAndSettle();
    expect(find.text('none left'), findsNothing);
    final pill = tester.widget<ZyraGoldActionPill>(
      find.byKey(const ValueKey('compatibility-unlock-Check balance')),
    );
    expect(
      pill.onPressed,
      isNotNull,
    ); // read-only recovery works even at unknown balance
    expect(find.textContaining('balance'), findsWidgets);
    final callback = tester
        .widget<SnackBarAction>(find.byType(SnackBarAction))
        .onPressed;
    final started = Completer<void>();
    final response = Completer<http.Response>();
    responder = (request) {
      if (request.url.path.endsWith('/unlock_balance')) {
        if (!started.isCompleted) started.complete();
        return response.future;
      }
      return defaults(request);
    };
    callback();
    callback();
    await tester.pump();
    await tester.runAsync(() => started.future);
    expect(
      requests.where((r) => r.url.path.endsWith('/unlock_balance')),
      hasLength(2),
    );
    final pendingRead = tester
        .widget<ZyraGoldActionPill>(
          find.byKey(const ValueKey('compatibility-unlock-Check balance')),
        )
        .onPressed;
    // This read-only control can remain present while the balance is unknown.
    // Its invocation guard must coalesce taps into the in-flight read instead
    // of issuing another ledger request or opening a spending action.
    expect(pendingRead, isNotNull);
    final retryRead = pendingRead!;
    retryRead();
    retryRead();
    await tester.pump();
    expect(
      requests.where((r) => r.url.path.endsWith('/unlock_balance')),
      hasLength(2),
    );
    expect(
      requests.where((r) => r.url.path.endsWith('/zyra_unlock_profile')),
      isEmpty,
    );
    response.complete(
      json([
        {'tier': 'paid_plus_single', 'balance': 2},
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 left'), findsNothing);
    expect(
      find.text('Detailed compatibility isn’t available yet.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('compatibility-unlock-Check balance')),
      findsNothing,
    );
    expect(find.text('Unlock Compatibility'), findsNothing);
    callback(); // old snackbar must not launch another balance read
    await tester.pumpAndSettle();
    expect(
      requests.where((r) => r.url.path.endsWith('/unlock_balance')),
      hasLength(2),
    );
    expect(
      requests.where((r) => r.url.path.endsWith('/zyra_unlock_profile')),
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox());
  });

  test(
    'a genuine empty ledger succeeds with zero, unlike a failed read',
    () async {
      responder = (_) async => json([]);
      final balance = await ZyraUnlockService.readBalances();
      expect(balance.status, UnlockBalanceStatus.available);
      expect(balance.values[UnlockTier.standard], 0);
      responder = (_) async =>
          json({'message': 'synthetic denied'}, status: 403);
      final failed = await ZyraUnlockService.readBalances();
      expect(failed.status, UnlockBalanceStatus.failed);
      expect(failed.values, isEmpty);
    },
  );

  for (final malformed in [
    null,
    [
      {'tier': 'paid_single', 'balance': -1},
    ],
    [
      {'tier': 'paid_single', 'balance': 1.5},
    ],
    [
      {'tier': 'paid_single', 'balance': '3'},
    ],
    [
      {'tier': 'unknown', 'balance': 3},
    ],
    [
      {'tier': 'paid_single', 'balance': 1},
      {'tier': 'paid_single', 'balance': 2},
    ],
  ]) {
    test('malformed ledger $malformed is unknown, not zero', () async {
      responder = (_) async => json(malformed);
      final result = await ZyraUnlockService.readBalances();
      expect(result.status, UnlockBalanceStatus.failed);
      expect(result.values, isEmpty);
    });
  }

  test('a newer same-owner load supersedes an older snapshot', () async {
    final started = Completer<void>();
    final oldResponse = Completer<http.Response>();
    var reads = 0;
    responder = (_) {
      if (++reads == 1) {
        started.complete();
        return oldResponse.future;
      }
      return Future.value(json([]));
    };
    final old = ZyraUnlockService.load();
    await started.future;
    await ZyraUnlockService.load();
    oldResponse.complete(
      json([
        {'unlocked_id': _target, 'unlock_type': 'paid_plus_bundle'},
      ]),
    );
    await old;
    expect(ZyraUnlockService.isUnlocked(_target, UnlockTier.plus), isFalse);
    expect(ZyraUnlockService.loaded, isTrue);
  });

  test('same-owner generation reset rejects a late balance', () async {
    final started = Completer<void>();
    final response = Completer<http.Response>();
    responder = (_) {
      started.complete();
      return response.future;
    };
    final pending = ZyraUnlockService.readBalances();
    await started.future;
    ZyraAccountState.resetForTesting();
    response.complete(
      json([
        {'tier': 'paid_single', 'balance': 99},
      ]),
    );
    final result = await pending;
    expect(result.status, UnlockBalanceStatus.stale);
    expect(result.values, isEmpty);
  });

  for (final fullAccess in [false, true]) {
    testWidgets(
      'permanent historical access is preserved without a new debit, full=$fullAccess',
      (tester) async {
        responder = (request) {
          if (request.url.path.endsWith('/profile_unlocks')) {
            return Future.value(
              json([
                {
                  'unlocked_id': _target,
                  'unlock_type': fullAccess
                      ? 'paid_plus_bundle'
                      : 'paid_bundle',
                },
              ]),
            );
          }
          return defaults(request);
        };
        await tester.runAsync(() => ZyraUnlockService.load());
        await tester.pumpWidget(
          const MaterialApp(home: ProfileUnlockScreen(profile: _profile)),
        );
        await tester.pumpAndSettle();
        expect(find.text('77%'), findsOneWidget);
        expect(
          ZyraUnlockService.isUnlocked(_target, ZyraUnlockService.currentTier),
          fullAccess,
        );
        expect(find.text('Unlock Compatibility'), findsNothing);
        expect(
          find.text('Detailed compatibility isn’t available yet.'),
          findsOneWidget,
        );
        expect(
          await ZyraUnlockService.unlock(
            _target,
            ZyraUnlockService.currentTier,
          ),
          fullAccess
              ? UnlockOutcome.alreadyUnlocked
              : UnlockOutcome.unavailable,
        );
        expect(
          requests.where((r) => r.url.path.endsWith('/profile_unlocks')),
          hasLength(1),
        );
        expect(
          requests.where((r) => r.url.path.endsWith('/zyra_unlock_profile')),
          isEmpty,
        );
        await tester.runAsync(() => _session(_otherOwner));
        await tester.pumpAndSettle();
        expect(find.text('77%'), findsNothing);
        expect(
          find.byKey(const ValueKey('compatibility-account-expired')),
          findsOneWidget,
        );
        expect(
          ZyraUnlockService.isUnlocked(_target, ZyraUnlockService.currentTier),
          isFalse,
        );
        expect(
          requests.where((r) => r.url.path.endsWith('/zyra_unlock_profile')),
          isEmpty,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('late score and balance cannot publish after route disposal', (
    tester,
  ) async {
    final score = Completer<http.Response>();
    final balance = Completer<http.Response>();
    final scoreStarted = Completer<void>();
    responder = (request) {
      if (request.url.path.endsWith('/profile_unlocks')) {
        return Future.value(
          json([
            {'unlocked_id': _target, 'unlock_type': 'paid_bundle'},
          ]),
        );
      }
      if (request.url.path.endsWith('/score_candidates')) {
        scoreStarted.complete();
        return score.future;
      }
      if (request.url.path.endsWith('/unlock_balance')) return balance.future;
      return defaults(request);
    };
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileUnlockScreen(profile: _profile, journeyRevealed: true),
      ),
    );
    await tester.pump();
    await tester.runAsync(() => scoreStarted.future);
    expect(
      requests.where((r) => r.url.path.endsWith('/score_candidates')),
      hasLength(1),
    );
    await tester.pumpWidget(const SizedBox());
    score.complete(
      json([
        {'candidate_id': _target, 'score': 99},
      ]),
    );
    balance.complete(
      json([
        {'tier': 'paid_single', 'balance': 99},
      ]),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'late Guardian, score and balance cannot publish to the next owner',
    (tester) async {
      responder = (_) async => json([
        {'unlocked_id': _target, 'unlock_type': 'paid_plus_bundle'},
      ]);
      await tester.runAsync(() => ZyraUnlockService.load());
      final guardian = Completer<http.Response>();
      final score = Completer<http.Response>();
      final balance = Completer<http.Response>();
      responder = (request) {
        if (request.url.path.endsWith('/guardians_for_unlocked')) {
          return guardian.future;
        }
        if (request.url.path.endsWith('/score_candidates')) return score.future;
        if (request.url.path.endsWith('/unlock_balance')) return balance.future;
        return defaults(request);
      };
      await tester.pumpWidget(
        const MaterialApp(home: ProfileUnlockScreen(profile: _profile)),
      );
      await tester.pump();
      await tester.runAsync(() => _session(_otherOwner));
      guardian.complete(
        json([
          {'first_name': 'Old synthetic Guardian', 'is_main': true},
        ]),
      );
      score.complete(
        json([
          {'candidate_id': _target, 'score': 99},
        ]),
      );
      balance.complete(
        json([
          {'tier': 'paid_single', 'balance': 99},
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Old synthetic Guardian'), findsNothing);
      expect(find.text('99%'), findsNothing);
      expect(find.text('99 left'), findsNothing);
      expect(
        find.byKey(const ValueKey('compatibility-account-expired')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('auth stream error is handled and withdraws route data', (
    tester,
  ) async {
    responder = (request) {
      if (request.url.path.endsWith('/profile_unlocks')) {
        return Future.value(
          json([
            {'unlocked_id': _target, 'unlock_type': 'paid_bundle'},
          ]),
        );
      }
      return defaults(request);
    };
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileUnlockScreen(profile: _profile, journeyRevealed: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('77%'), findsOneWidget);
    // Test-only SDK event injection; no network/provider refresh is performed.
    // ignore: invalid_use_of_internal_member
    supabase.auth.notifyException(
      const AuthException('synthetic refresh failure'),
    );
    await tester.pumpAndSettle();
    expect(find.text('77%'), findsNothing);
    expect(
      find.byKey(const ValueKey('compatibility-account-expired')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('covered full-product route rejects a retained read callback', (
    tester,
  ) async {
    responder = (request) {
      if (request.url.path.endsWith('/unlock_balance')) {
        return Future.value(json({'message': 'synthetic denied'}, status: 403));
      }
      return defaults(request);
    };
    await tester.pumpWidget(
      const MaterialApp(home: ProfileUnlockScreen(profile: _profile)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unlock Compatibility'), findsNothing);
    final action = find.byKey(
      const ValueKey('compatibility-unlock-Check balance'),
    );
    final callback = tester.widget<ZyraGoldActionPill>(action).onPressed!;
    final navigator = Navigator.of(
      tester.element(find.byType(ProfileUnlockScreen)),
    );
    unawaited(
      navigator.push<void>(
        MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Cover'))),
      ),
    );
    await tester.pumpAndSettle();
    final beforeReads = requests
        .where((r) => r.url.path.endsWith('/unlock_balance'))
        .length;
    callback();
    callback();
    await tester.pumpAndSettle();
    expect(find.text('Cover'), findsOneWidget);
    expect(
      requests.where((r) => r.url.path.endsWith('/unlock_balance')),
      hasLength(beforeReads),
    );
    expect(
      requests.where((r) => r.url.path.endsWith('/zyra_unlock_profile')),
      isEmpty,
    );
    navigator.pop();
    await tester.pumpAndSettle();
    expect(tester.widget<ZyraGoldActionPill>(action).busy, isFalse);
    expect(tester.widget<ZyraGoldActionPill>(action).onPressed, isNotNull);
    expect(find.text('Unlock Compatibility'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('retained route withdraws old results on owner change', (
    tester,
  ) async {
    responder = (request) {
      if (request.url.path.endsWith('/profile_unlocks')) {
        return Future.value(
          json([
            {'unlocked_id': _target, 'unlock_type': 'paid_bundle'},
          ]),
        );
      }
      return defaults(request);
    };
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileUnlockScreen(profile: _profile, journeyRevealed: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('77%'), findsOneWidget);
    await tester.runAsync(() => _session(_otherOwner));
    await tester.pumpAndSettle();
    expect(find.text('77%'), findsNothing);
    expect(
      find.byKey(const ValueKey('compatibility-account-expired')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
