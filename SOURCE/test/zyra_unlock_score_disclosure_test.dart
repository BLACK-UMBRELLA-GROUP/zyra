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
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_discovery_service.dart';
import 'package:zyra/services/zyra_unlock_service.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_gold_action_pill.dart';

const _owner = '00000000-0000-4000-8000-000000004501';
const _otherOwner = '00000000-0000-4000-8000-000000004502';
const _target = '00000000-0000-4000-8000-000000004503';
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
  Future<http.Response> defaults(http.Request request) async {
    if (request.url.path.endsWith('/profile_unlocks')) return json([]);
    if (request.url.path.endsWith('/unlock_balance')) {
      return json([
        {'tier': 'paid_plus_single', 'balance': 5},
      ]);
    }
    if (request.url.path.endsWith('/guardians_for_unlocked')) return json([]);
    if (request.url.path.endsWith('/score_candidates')) {
      return json([
        {'candidate_id': _target, 'score': 77},
      ]);
    }
    if (request.url.path.endsWith('/logout')) return json({});
    throw StateError('Unexpected synthetic endpoint ${request.url.path}');
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://score-disclosure.invalid',
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
    responder = defaults;
    await _session(_owner);
    ZyraUnlockService.clearForSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = true;
    requests.clear();
  });
  tearDown(() {
    ZyraUnlockService.clearForSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = false;
  });

  Iterable<http.Request> scoreReads() =>
      requests.where((r) => r.url.path.endsWith('/score_candidates'));
  Iterable<http.Request> debits() =>
      requests.where((r) => r.url.path.endsWith('/zyra_unlock_profile'));

  test('unowned target never requests a numeric score', () async {
    expect(await ZyraDiscoveryService.fetchMyScoreFor(_target), isNull);
    expect(scoreReads(), isEmpty);
    expect(requests, hasLength(1));
    expect(requests.single.url.path, endsWith('/profile_unlocks'));
  });

  test('unknown ownership never requests a numeric score', () async {
    responder = (_) async => json({'message': 'synthetic denied'}, status: 403);
    expect(await ZyraDiscoveryService.fetchMyScoreFor(_target), isNull);
    expect(scoreReads(), isEmpty);
    expect(debits(), isEmpty);
  });

  for (final type in ['paid_single', 'paid_bundle', 'paid_plus_bundle']) {
    test('$type ownership is checked before the numeric endpoint', () async {
      responder = (request) {
        if (request.url.path.endsWith('/profile_unlocks')) {
          return Future.value(
            json([
              {'unlocked_id': _target, 'unlock_type': type},
            ]),
          );
        }
        return defaults(request);
      };
      expect(await ZyraDiscoveryService.fetchMyScoreFor(_target), 77);
      expect(requests, hasLength(2));
      expect(requests.first.url.path, endsWith('/profile_unlocks'));
      expect(requests.last.url.path, endsWith('/score_candidates'));
      expect(jsonDecode(requests.last.body), {
        'p_candidate_ids': [_target],
      });
      expect(debits(), isEmpty);
    });
  }

  for (final rows in [
    <Object?>[],
    [
      {'candidate_id': _target, 'score': '77'},
    ],
    [
      {'candidate_id': _target, 'score': -1},
    ],
    [
      {'candidate_id': _target, 'score': 101},
    ],
    [
      {'candidate_id': _target, 'score': 77},
      {'candidate_id': _target, 'score': 88},
    ],
    [
      {'score': 77},
    ],
    [
      {'candidate_id': null, 'score': 77},
    ],
    [
      {'candidate_id': 77, 'score': 77},
    ],
    [
      {'candidate_id': 'not-a-uuid', 'score': 77},
    ],
    [
      {'candidate_id': _otherOwner, 'score': 77},
    ],
  ]) {
    test('malformed numeric result $rows is withheld', () async {
      responder = (request) {
        if (request.url.path.endsWith('/profile_unlocks')) {
          return Future.value(
            json([
              {'unlocked_id': _target, 'unlock_type': 'paid_single'},
            ]),
          );
        }
        if (request.url.path.endsWith('/score_candidates')) {
          return Future.value(json(rows));
        }
        return defaults(request);
      };
      expect(await ZyraDiscoveryService.fetchMyScoreFor(_target), isNull);
    });
  }

  test('candidate UUID comparison accepts matching normalized case', () async {
    const candidate = 'abcd0000-0000-4000-8000-000000004503';
    responder = (request) {
      if (request.url.path.endsWith('/profile_unlocks')) {
        return Future.value(
          json([
            {'unlocked_id': candidate, 'unlock_type': 'paid_single'},
          ]),
        );
      }
      if (request.url.path.endsWith('/score_candidates')) {
        return Future.value(
          json([
            {'candidate_id': candidate.toUpperCase(), 'score': 77},
          ]),
        );
      }
      return defaults(request);
    };
    expect(await ZyraDiscoveryService.fetchMyScoreFor(candidate), 77);
    expect(scoreReads(), hasLength(1));
    expect(debits(), isEmpty);
  });

  for (final reset in ['owner', 'generation', 'ABA', 'epoch restored']) {
    test('late numeric response is withdrawn after $reset change', () async {
      final started = Completer<void>();
      final score = Completer<http.Response>();
      responder = (request) {
        if (request.url.path.endsWith('/profile_unlocks')) {
          return Future.value(
            json([
              {'unlocked_id': _target, 'unlock_type': 'paid_plus_single'},
            ]),
          );
        }
        if (request.url.path.endsWith('/score_candidates')) {
          started.complete();
          return score.future;
        }
        return defaults(request);
      };
      final pending = ZyraDiscoveryService.fetchMyScoreFor(_target);
      await started.future.timeout(const Duration(seconds: 3));
      if (reset == 'generation') {
        ZyraAccountState.resetForTesting();
      } else if (reset == 'epoch restored') {
        ZyraUnlockService.clearForSignOut();
        expect(
          await ZyraUnlockService.confirmOwnedAccess(
            _target,
            UnlockTier.standard,
          ),
          isTrue,
        );
      } else {
        await _session(_otherOwner);
        if (reset == 'ABA') {
          ZyraAccountState.resetForTesting();
          await _session(_owner);
        }
      }
      score.complete(
        json([
          {'candidate_id': _target, 'score': 99},
        ]),
      );
      expect(await pending, isNull);
      expect(debits(), isEmpty);
    });
  }

  test('sample and signed-out callers request no numeric data', () async {
    expect(await ZyraDiscoveryService.fetchMyScoreFor('sample'), isNull);
    expect(requests, isEmpty);
    await supabase.auth.signOut(scope: SignOutScope.local);
    requests.clear();
    expect(await ZyraDiscoveryService.fetchMyScoreFor(_target), isNull);
    expect(requests, isEmpty);
  });

  testWidgets('Journey flag and five credits are not numeric-read authority', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileUnlockScreen(profile: _profile, journeyRevealed: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(scoreReads(), isEmpty);
    expect(debits(), isEmpty);
    expect(find.text('77%'), findsNothing);
    expect(
      find.text('Your compatibility score isn’t available right now.'),
      findsOneWidget,
    );
    expect(find.textContaining('Not enough answers'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('paid grant loads when initial full-cache hydration is absent', (
    tester,
  ) async {
    responder = (request) {
      if (request.url.path.endsWith('/profile_unlocks')) {
        return Future.value(
          json([
            {'unlocked_id': _target, 'unlock_type': 'paid_plus_bundle'},
          ]),
        );
      }
      return defaults(request);
    };
    expect(ZyraUnlockService.loaded, isFalse);
    await tester.pumpWidget(
      const MaterialApp(home: ProfileUnlockScreen(profile: _profile)),
    );
    await tester.pumpAndSettle();
    expect(find.text('77%'), findsOneWidget);
    expect(scoreReads(), hasLength(1));
    expect(ZyraUnlockService.loaded, isFalse);
    expect(debits(), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'unknown grant can be checked using existing read-only recovery',
    (tester) async {
      var available = false;
      responder = (request) {
        if (request.url.path.endsWith('/profile_unlocks')) {
          return Future.value(
            available
                ? json([
                    {'unlocked_id': _target, 'unlock_type': 'paid_plus_bundle'},
                  ])
                : json({'message': 'synthetic denied'}, status: 403),
          );
        }
        return defaults(request);
      };
      await tester.pumpWidget(
        const MaterialApp(home: ProfileUnlockScreen(profile: _profile)),
      );
      await tester.pumpAndSettle();
      expect(scoreReads(), isEmpty);
      final callback = tester
          .widget<ZyraGoldActionPill>(
            find.byKey(const ValueKey('compatibility-unlock-Check access')),
          )
          .onPressed;
      expect(callback, isNotNull);
      available = true;
      callback!();
      await tester.pumpAndSettle();
      expect(find.text('77%'), findsOneWidget);
      expect(scoreReads(), hasLength(1));
      expect(debits(), isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
