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
import 'package:zyra/models/zyra_compatibility_area.dart';
import 'package:zyra/screens/subscription/profile_unlock_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_compatibility_topics_service.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_discovery_service.dart';
import 'package:zyra/services/zyra_onboarding_answers_service.dart';
import 'package:zyra/services/zyra_unlock_service.dart';
import 'package:zyra/theme/zyra_colors.dart';
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
    ZyraCompatibilityTopicsService.setClientReadyForTesting(null);
    ZyraOnboardingAnswersService.setClientReadyForTesting(null);
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
    ZyraCompatibilityTopicsService.setClientReadyForTesting(true);
    responder = (request) {
      if (request.url.path.endsWith('/profile_unlocks')) {
        return Future.value(
          json([
            {'unlocked_id': _target, 'unlock_type': 'paid_plus_bundle'},
          ]),
        );
      }
      if (request.url.path.endsWith('/zyra_compatibility_topics')) {
        return Future.value(
          json({'code': 'PGRST202', 'message': 'Unavailable'}, status: 404),
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
    expect(
      requests.where((r) => r.url.path.endsWith('/zyra_compatibility_topics')),
      hasLength(1),
    );
    expect(scoreReads(), hasLength(1));
    expect(ZyraUnlockService.loaded, isFalse);
    expect(debits(), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  void testPaidResult(
    String description, {
    bool retryRead = false,
    bool missingSect = false,
  }) {
    testWidgets(description, (tester) async {
      ZyraCompatibilityTopicsService.setClientReadyForTesting(true);
      ZyraOnboardingAnswersService.setClientReadyForTesting(true);
      const visible = (questionId: 'ch2.revert.flexibility', optionValue: '*');
      const missing = (
        questionId: 'ch2.sect.matrix',
        optionValue: 'current-sect',
      );
      const hidden = (questionId: 'ch3_q24', optionValue: 'Within 2–3 years');
      Map<String, String> item(ZyraPreferenceOption option, String light) => {
        'question_id': option.questionId,
        'option_value': option.optionValue,
        'light': light,
      };
      const topics = 'zyra_compatibility_topics';
      const visibleRead = 'zyra_my_lights_needing_reconfirmation';
      const hiddenRead = 'zyra_my_lights_needed_for_compatibility';
      const confirm = 'zyra_confirm_preference_lights';
      final checkCalls = <String>[];
      var checked = false;
      var readFailed = false;
      responder = (request) async {
        final endpoint = request.url.pathSegments.last;
        switch (endpoint) {
          case 'profile_unlocks':
            return json([
              {
                'unlocked_id': _target,
                'unlock_type': retryRead ? 'paid_plus_bundle' : 'paid_single',
              },
            ]);
          case 'guardians_for_unlocked':
            return json([
              {'first_name': 'Synthetic Guardian', 'is_main': true},
            ]);
          case topics:
            checkCalls.add(topics);
            expect(jsonDecode(request.body), {'p_subject': _target});
            if (retryRead && checked && !readFailed) {
              readFailed = true;
              return json({
                'code': '503',
                'message': 'Synthetic transient failure',
              }, status: 503);
            }
            return json([
              for (final area in ZyraCompatibilityArea.values)
                {
                  'overall': checked ? 84 : null,
                  'topics_locked': false,
                  'area_no': area.index + 1,
                  'area_code': area.name,
                  'band': checked ? 'good' : null,
                  'state': checked ? 'ok' : 'needs_reconfirmation',
                },
            ]);
          case visibleRead:
            checkCalls.add(visibleRead);
            expect(jsonDecode(request.body), {'p_include_missing': true});
            return json([
              {...item(visible, 'amber'), 'reason': null},
              if (missingSect)
                {...item(missing, 'amber'), 'light': null, 'reason': 'missing'},
            ]);
          case hiddenRead:
            checkCalls.add(hiddenRead);
            expect(jsonDecode(request.body), isEmpty);
            return json([
              {...item(hidden, 'amber'), 'reason': 'hidden_but_applicable'},
            ]);
          case confirm:
            checkCalls.add(confirm);
            expect(jsonDecode(request.body), {
              'p_items': [
                if (missingSect) item(missing, 'green'),
                item(visible, 'amber'),
                item(hidden, 'green'),
              ],
            });
            checked = true;
            return http.Response('', 204);
          default:
            return defaults(request);
        }
      };

      await tester.pumpWidget(
        const MaterialApp(home: ProfileUnlockScreen(profile: _profile)),
      );
      await tester.pumpAndSettle();
      expect(find.text('One quick check first'), findsOneWidget);
      expect(find.byTooltip('Next page'), findsNothing);
      expect(checkCalls, [topics]);

      await tester.tap(find.text('Check my answers'));
      await tester.pumpAndSettle();
      expect(find.text('Quick check'), findsOneWidget);
      expect(find.textContaining(_profile.firstName), findsNothing);
      expect(find.text('Done · ${missingSect ? 3 : 2} left'), findsOneWidget);
      expect(checkCalls, [topics, visibleRead, hiddenRead]);

      if (missingSect) {
        final notSet = find.byKey(const ValueKey(missing));
        expect(
          find.descendant(of: notSet, matching: find.text('Not set')),
          findsOneWidget,
        );
        expect(find.textContaining('current-sect'), findsNothing);
        await tester.tap(
          find.descendant(of: notSet, matching: find.text('Prefer this')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Done · 2 left'), findsOneWidget);
        expect(checked, isFalse);
      }
      final selectAmber = find.descendant(
        of: find.byKey(const ValueKey(visible)),
        matching: find.text('Open to this'),
      );
      final selectGreen = find.descendant(
        of: find.byKey(const ValueKey(hidden)),
        matching: find.text('Prefer this'),
      );
      await tester.tap(selectAmber);
      await tester.pumpAndSettle();
      expect(find.text('Done · 1 left'), findsOneWidget);
      expect(checked, isFalse);
      await tester.ensureVisible(selectGreen);
      await tester.pumpAndSettle();
      await tester.tap(selectGreen);
      await tester.pumpAndSettle();
      expect(checked, isFalse);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      final readyNotice = find.text('Thank you. Your result is ready.');
      if (retryRead) {
        expect(readFailed, isTrue);
        expect(readyNotice, findsNothing);
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
      }
      expect(find.text('84%'), findsOneWidget);
      expect(readyNotice, findsOneWidget);
      final next = find.byTooltip('Next page');
      expect(next, findsOneWidget);
      expect(checkCalls, [
        topics,
        visibleRead,
        hiddenRead,
        confirm,
        topics,
        if (retryRead) topics,
      ]);
      expect(scoreReads(), isEmpty);
      expect(debits(), isEmpty);
      if (retryRead) {
        final guardian = find.text('Synthetic Guardian');
        expect(guardian, findsOneWidget);
        await tester.ensureVisible(guardian);
        expect(tester.widget<Text>(guardian).style!.color, ZyraColors.espresso);
        expect(
          tester.widget<Text>(find.text('GUARDIAN')).style!.color,
          ZyraColors.secondaryText,
        );
        expect(
          tester.widget<Text>(find.text('Main')).style!.color,
          ZyraColors.secondaryText,
        );
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testPaidResult(
    'paid result checks both owner lists and rereads its saved score',
  );
  testPaidResult(
    'Q115 Profiles retry shows readiness and keeps Guardian text legible',
    retryRead: true,
  );
  testPaidResult(
    'Q116 paid result check saves an unset sect light only after a tap and Done',
    missingSect: true,
  );

  testWidgets('Q116 unavailable paid result has no score, bands or spend', (
    tester,
  ) async {
    ZyraCompatibilityTopicsService.setClientReadyForTesting(true);
    responder = (request) {
      return switch (request.url.pathSegments.last) {
        'profile_unlocks' => Future.value(
          json([
            {'unlocked_id': _target, 'unlock_type': 'paid_single'},
          ]),
        ),
        'zyra_compatibility_topics' => Future.value(
          json([
            for (final area in ZyraCompatibilityArea.values)
              {
                'overall': null,
                'topics_locked': true,
                'area_no': area.index + 1,
                'area_code': area.name,
                'band': null,
                'state': 'unavailable',
              },
          ]),
        ),
        _ => defaults(request),
      };
    };
    await tester.pumpWidget(
      const MaterialApp(home: ProfileUnlockScreen(profile: _profile)),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Your compatibility score isn’t available right now.'),
      findsOneWidget,
    );
    expect(find.text('Check my answers'), findsNothing);
    expect(find.text('Unlock Compatibility'), findsNothing);
    expect(
      find.byKey(const ValueKey('compatibility-area-row-deen')),
      findsNothing,
    );
    expect(scoreReads(), isEmpty);
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
