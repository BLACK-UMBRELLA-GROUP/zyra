import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/models/journey_bio.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/models/zyra_compatibility_area.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_compatibility_topics_service.dart';
import 'package:zyra/services/zyra_onboarding_answers_service.dart';

const _owner = '00000000-0000-4000-8000-000000005501';
const _other = '00000000-0000-4000-8000-000000005502';
const _read = '/rest/v1/rpc/zyra_my_lights_needing_reconfirmation';
const _hiddenRead = '/rest/v1/rpc/zyra_my_lights_needed_for_compatibility';
const _write = '/rest/v1/rpc/zyra_confirm_preference_lights';
const _topics = '/rest/v1/rpc/zyra_compatibility_topics';
const _answers = '/rest/v1/onboarding_answers';
const _legacy = (questionId: 'ch3_q26', optionValue: 'No preference');
const _confirmed = (questionId: 'ch3_q1', optionValue: 'Usually');
const _hidden = (questionId: 'ch3_q24', optionValue: 'Within 2–3 years');
const _matchId = '00000000-0000-4000-8000-000000005503';

Future<void> _session(String userId) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.'
          '${part({'sub': userId, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-local-only',
      'user': {
        'id': userId,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-19T00:00:00Z',
      },
    }),
  );
}

Map<String, String> _item(ZyraPreferenceOption option, String light) => {
  'question_id': option.questionId,
  'option_value': option.optionValue,
  'light': light,
};

List<Map<String, Object?>> _topicRows(
  String state, {
  double? overall,
  bool locked = false,
}) => [
  for (final area in ZyraCompatibilityArea.values)
    {
      'overall': overall,
      'topics_locked': locked,
      'area_no': area.index + 1,
      'area_code': area.name,
      'band': state == 'ok' && !locked
          ? const [
              'strong',
              'good',
              'some_differences',
              'not_enough',
            ][area.index % 4]
          : null,
      'state': state,
    },
];

http.Response _json(Object value, {int status = 200}) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <http.Request>[];
  late FutureOr<http.Response> Function(http.Request) respond;

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
        final response = await respond(request);
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
    );
    ZyraOnboardingAnswersService.setClientReadyForTesting(true);
    ZyraCompatibilityTopicsService.setClientReadyForTesting(true);
  });
  tearDownAll(() async {
    ZyraOnboardingAnswersService.setClientReadyForTesting(null);
    ZyraCompatibilityTopicsService.setClientReadyForTesting(null);
    await Supabase.instance.dispose();
  });
  setUp(() async {
    ZyraAccountState.resetForTesting();
    await _session(_owner);
    requests.clear();
    respond = (request) => throw StateError('Unexpected ${request.url.path}');
  });

  test('scoped profile saves send only their owned answer section', () async {
    respond = (request) => switch ((request.method, request.url.path)) {
      ('POST', _answers) => _json({'user_id': _owner}, status: 201),
      _ => throw StateError('Unexpected ${request.url.path}'),
    };

    expect(
      await ZyraOnboardingAnswersService.syncAnswers(
        expectedUserId: _owner,
        ch3Answers: {'ch3_q1': 'Updated answer'},
      ),
      isTrue,
    );
    final answers = jsonDecode(requests.single.body) as Map;
    expect(answers.keys, unorderedEquals(['user_id', 'ch3_answers']));
    expect(answers['ch3_answers']['ch3_q1'], 'Updated answer');
    expect(requests.single.headers['prefer'], contains('missing=default'));

    expect(
      await ZyraOnboardingAnswersService.syncAnswers(
        expectedUserId: _owner,
        ch4HardRequirements: {},
      ),
      isTrue,
    );
    expect(requests, hasLength(2));
    expect(jsonDecode(requests.last.body), {
      'user_id': _owner,
      'ch4_hard_requirements': {},
    });
  });

  for (final existingRow in [true, false]) {
    test(
      'Journey Bio preserves preference columns (row exists: $existingRow)',
      () async {
        respond = (request) => switch ((request.method, request.url.path)) {
          ('GET', _answers) => _json([
            if (existingRow)
              {
                'ch3_answers': {
                  'ch3_q1': 'Previous answer',
                  'bio_about_me': 'Previous bio',
                },
                'ch4_preferences': {
                  _confirmed.questionId: {_confirmed.optionValue: 'yellow'},
                },
              },
          ]),
          ('POST', _answers) => _json({'user_id': _owner}, status: 201),
          _ => throw StateError('Unexpected ${request.url.path}'),
        };

        const bio = JourneyBio(aboutMe: 'Updated bio', reviewed: true);
        expect(
          await ZyraOnboardingAnswersService.syncJourneyBio(
            bio,
            expectedUserId: _owner,
          ),
          isTrue,
        );
        expect(requests, hasLength(2));
        expect(requests.first.url.queryParameters['select'], 'ch3_answers');
        expect(requests.last.headers['prefer'], contains('missing=default'));
        expect(jsonDecode(requests.last.body), {
          'user_id': _owner,
          'ch3_answers': {
            if (existingRow) 'ch3_q1': 'Previous answer',
            ...bio.toOnboardingAnswers(),
          },
        });
      },
    );
  }

  test(
    'ordinary saves preserve both wire spellings without confirming',
    () async {
      final token = supabase.auth.currentSession!.accessToken;
      var needsCheck = true;
      respond = (request) => switch ((request.method, request.url.path)) {
        ('GET', _answers) => _json([
          {
            'ch4_preferences': {
              _legacy.questionId: {_legacy.optionValue: 'yellow'},
              _confirmed.questionId: {_confirmed.optionValue: 'amber'},
            },
          },
        ]),
        ('POST', _answers) => _json({'user_id': _owner}, status: 201),
        ('POST', _read) => _json([if (needsCheck) _item(_legacy, 'amber')]),
        ('POST', _write) => () {
          needsCheck = false;
          return http.Response('', 204);
        }(),
        _ => throw StateError('Unexpected ${request.url.path}'),
      };

      final snapshot = (await ZyraOnboardingAnswersService.fetchOwn(
        expectedUserId: _owner,
        throwOnError: true,
      ))!;
      expect(snapshot.canonicalAmberOptions, {_confirmed});
      expect(snapshot.ch4Preferences, {
        _legacy.questionId: {_legacy.optionValue: TrafficLight.yellow},
        _confirmed.questionId: {_confirmed.optionValue: TrafficLight.yellow},
      });
      expect(await ZyraOnboardingAnswersService.lightsNeedingReconfirmation(), {
        _legacy,
      });

      final revision =
          ZyraOnboardingAnswersService.preferenceConfirmationRevision.value;
      expect(
        await ZyraOnboardingAnswersService.syncAnswers(
          expectedUserId: _owner,
          ch3Answers: snapshot.ch3Answers,
          ch4Preferences: snapshot.ch4Preferences,
          ch4HardRequirements: snapshot.ch4HardRequirements,
          canonicalAmberOptions: snapshot.canonicalAmberOptions,
        ),
        isTrue,
      );
      final save = jsonDecode(requests.last.body) as Map;
      expect(
        save.keys,
        unorderedEquals([
          'user_id',
          'ch3_answers',
          'ch4_preferences',
          'ch4_hard_requirements',
        ]),
      );
      expect(save['ch4_preferences'], {
        _legacy.questionId: {_legacy.optionValue: 'yellow'},
        _confirmed.questionId: {_confirmed.optionValue: 'amber'},
      });
      expect(
        ZyraOnboardingAnswersService.preferenceConfirmationRevision.value,
        revision,
      );
      expect(await ZyraOnboardingAnswersService.lightsNeedingReconfirmation(), {
        _legacy,
      });

      await ZyraOnboardingAnswersService.confirmPreferenceLight(
        expectedUserId: _owner,
        option: (
          questionId: '${_legacy.questionId}::female',
          optionValue: _legacy.optionValue,
        ),
        light: TrafficLight.yellow,
      );
      expect(jsonDecode(requests.last.body), {
        'p_items': [_item(_legacy, 'amber')],
      });
      expect(
        await ZyraOnboardingAnswersService.lightsNeedingReconfirmation(),
        isEmpty,
      );
      expect(requests.map((request) => request.url.path), [
        _answers,
        _read,
        _answers,
        _read,
        _write,
        _read,
      ]);
      expect(
        requests.every((r) => r.headers['Authorization'] == 'Bearer $token'),
        isTrue,
      );
      for (final read in requests.where(
        (request) => request.url.path == _read,
      )) {
        expect(jsonDecode(read.body), isEmpty);
      }
      expect(
        ZyraOnboardingAnswersService.preferenceConfirmationRevision.value,
        revision + 1,
      );
    },
  );

  test('uses the exact setup light identifiers from Q109', () async {
    const options = {
      (questionId: 'ch2.sect.matrix', optionValue: 'shia'),
      (questionId: 'ch2.sect.outside_flexibility', optionValue: '*'),
      (questionId: 'ch2.revert.flexibility', optionValue: '*'),
    };
    respond = (request) => switch (request.url.path) {
      _read => _json([for (final option in options) _item(option, 'amber')]),
      _write => http.Response('', 204),
      _ => throw StateError('Unexpected ${request.url.path}'),
    };
    expect(
      await ZyraOnboardingAnswersService.lightsNeedingReconfirmation(),
      options,
    );

    for (final option in options) {
      await ZyraOnboardingAnswersService.confirmPreferenceLight(
        expectedUserId: _owner,
        option: option,
        light: TrafficLight.yellow,
      );
      expect(requests.last.url.path, _write);
      expect(jsonDecode(requests.last.body), {
        'p_items': [_item(option, 'amber')],
      });
    }
    expect(requests.length, 4);

    const unflagged = (questionId: 'ch2.sect.matrix', optionValue: 'sunni');
    await ZyraOnboardingAnswersService.confirmPreferenceLight(
      expectedUserId: _owner,
      option: unflagged,
      light: TrafficLight.red,
    );
    expect(jsonDecode(requests.last.body), {
      'p_items': [_item(unflagged, 'red')],
    });
    await ZyraOnboardingAnswersService.confirmPreferenceLight(
      expectedUserId: _owner,
      option: unflagged,
      light: TrafficLight.yellow,
    );
    expect(jsonDecode(requests.last.body), {
      'p_items': [_item(unflagged, 'amber')],
    });
  });

  test('the reader rejects data outside the owner response shape', () async {
    for (final response in [
      [_item(_legacy, 'yellow')],
      [_item(_legacy, 'amber'), _item(_legacy, 'amber')],
      [
        {..._item(_legacy, 'amber'), 'user_id': _other},
      ],
    ]) {
      respond = (_) => _json(response);
      await expectLater(
        ZyraOnboardingAnswersService.lightsNeedingReconfirmation(),
        throwsFormatException,
      );
    }
  });

  test(
    'combined check uses two subject-free reads and one explicit batch',
    () async {
      final token = supabase.auth.currentSession!.accessToken;
      final revision =
          ZyraOnboardingAnswersService.preferenceConfirmationRevision.value;
      respond = (request) => switch (request.url.path) {
        _read => _json([_item(_legacy, 'amber')]),
        _hiddenRead => _json([
          {..._item(_hidden, 'amber'), 'reason': 'hidden_but_applicable'},
        ]),
        _write => http.Response('', 204),
        _ => throw StateError('Unexpected ${request.url.path}'),
      };

      expect(await ZyraOnboardingAnswersService.lightsNeedingReconfirmation(), {
        _legacy,
      });
      expect(
        await ZyraOnboardingAnswersService.lightsNeededForCompatibility(
          expectedUserId: _owner,
        ),
        {_hidden},
      );
      await ZyraOnboardingAnswersService.confirmPreferenceLights(
        expectedUserId: _owner,
        selections: {_legacy: TrafficLight.green, _hidden: TrafficLight.yellow},
      );

      expect(requests.map((request) => request.url.path), [
        _read,
        _hiddenRead,
        _write,
      ]);
      expect(
        requests.every((r) => r.headers['Authorization'] == 'Bearer $token'),
        isTrue,
      );
      expect(jsonDecode(requests[0].body), isEmpty);
      expect(jsonDecode(requests[1].body), isEmpty);
      expect(jsonDecode(requests[2].body), {
        'p_items': [_item(_legacy, 'green'), _item(_hidden, 'amber')],
      });
      expect(
        ZyraOnboardingAnswersService.preferenceConfirmationRevision.value,
        revision + 1,
      );
    },
  );

  test('hidden reader rejects incorrect reasons and extra fields', () async {
    final item = _item(_hidden, 'amber');
    for (final response in [
      [item],
      [
        {...item, 'reason': 'different'},
      ],
      [
        {...item, 'reason': 'hidden_but_applicable', 'subject_id': _other},
      ],
    ]) {
      respond = (_) => _json(response);
      await expectLater(
        ZyraOnboardingAnswersService.lightsNeededForCompatibility(),
        throwsFormatException,
      );
    }
  });

  test(
    'confirmation rejects no taps or duplicate canonical controls',
    () async {
      for (final selections in <Map<ZyraPreferenceOption, TrafficLight>>[
        {},
        {
          _legacy: TrafficLight.green,
          (
            questionId: '${_legacy.questionId}::female',
            optionValue: _legacy.optionValue,
          ): TrafficLight.yellow,
        },
      ]) {
        await expectLater(
          ZyraOnboardingAnswersService.confirmPreferenceLights(
            expectedUserId: _owner,
            selections: selections,
          ),
          throwsArgumentError,
        );
      }
      expect(requests, isEmpty);
    },
  );

  test(
    'compatibility reader separates a gated result from its ready reread',
    () async {
      final token = supabase.auth.currentSession!.accessToken;
      final responses = [
        _topicRows('needs_reconfirmation'),
        _topicRows('ok', overall: 72.5),
        _topicRows('ok', overall: 72.5, locked: true),
        _topicRows('incomplete'),
        _topicRows('invalid'),
        [],
      ].iterator;
      respond = (request) {
        expect(request.url.path, _topics);
        expect(responses.moveNext(), isTrue);
        return _json(responses.current);
      };
      Future<ZyraCompatibilityTopicsResult?> fetch({String? matchId}) =>
          ZyraCompatibilityTopicsService.fetch(
            expectedUserId: _owner,
            subjectId: _other,
            matchId: matchId,
          );

      final needs = (await fetch(matchId: _matchId))!;
      expect(needs.state, ZyraCompatibilityTopicsState.needsReconfirmation);
      expect(needs.overallScore, isNull);
      expect(needs.areaBands, isNull);

      final ready = (await fetch(matchId: _matchId))!;
      expect(ready.state, ZyraCompatibilityTopicsState.ready);
      expect(ready.overallScore, 72.5);
      expect(ready.topicsLocked, isFalse);
      expect(ready.areaBands, hasLength(12));
      expect(
        ready.areaBands![ZyraCompatibilityArea.deen],
        ZyraCompatibilityBand.strong,
      );
      expect(
        ready.areaBands![ZyraCompatibilityArea.marriage],
        ZyraCompatibilityBand.good,
      );
      expect(
        ready.areaBands![ZyraCompatibilityArea.children],
        ZyraCompatibilityBand.someDifferences,
      );
      expect(
        ready.areaBands![ZyraCompatibilityArea.family],
        ZyraCompatibilityBand.notEnoughAnswers,
      );

      final locked = (await fetch(matchId: _matchId))!;
      expect(locked.overallScore, 72.5);
      expect(locked.topicsLocked, isTrue);
      expect(locked.areaBands, isNull);

      for (var i = 0; i < 2; i++) {
        final incomplete = (await fetch())!;
        expect(incomplete.state, ZyraCompatibilityTopicsState.incomplete);
        expect(incomplete.overallScore, isNull);
        expect(incomplete.areaBands, isNull);
      }
      expect(await fetch(), isNull);

      expect(requests, hasLength(6));
      for (final request in requests.take(3)) {
        expect(request.headers['Authorization'], 'Bearer $token');
        expect(jsonDecode(request.body), {
          'p_subject': _other,
          'p_match_id': _matchId,
        });
      }
      expect(jsonDecode(requests.last.body), {'p_subject': _other});
    },
  );

  test(
    'compatibility reader rejects partial and contradictory projections',
    () async {
      final complete = _topicRows('needs_reconfirmation');
      for (final response in [
        complete.take(11).toList(),
        [...complete.take(11), complete.first],
        [
          {...complete.first, 'question_id': 'ch3_q24'},
          ...complete.skip(1),
        ],
        [
          {...complete.first, 'overall': 0},
          ...complete.skip(1),
        ],
        [
          {...complete.first, 'band': 'strong'},
          ...complete.skip(1),
        ],
        [
          {...complete.first, 'topics_locked': true},
          ...complete.skip(1),
        ],
      ]) {
        respond = (_) => _json(response);
        await expectLater(
          ZyraCompatibilityTopicsService.fetch(
            expectedUserId: _owner,
            subjectId: _other,
          ),
          throwsFormatException,
        );
      }
    },
  );

  test('an account change retires in-flight check and result reads', () async {
    final readers = <Future<Object?> Function(String)>[
      (userId) => ZyraOnboardingAnswersService.lightsNeededForCompatibility(
        expectedUserId: userId,
      ),
      (userId) => ZyraCompatibilityTopicsService.fetch(
        expectedUserId: userId,
        subjectId: _other,
      ),
    ];
    for (final read in readers) {
      final requestCount = requests.length;
      await expectLater(read(_other), throwsStateError);
      expect(requests, hasLength(requestCount));

      final started = Completer<void>();
      final release = Completer<http.Response>();
      respond = (_) {
        started.complete();
        return release.future;
      };
      final pending = expectLater(read(_owner), throwsStateError);
      await started.future;
      ZyraAccountState.resetForTesting();
      release.complete(_json([]));
      await pending;
    }
  });

  test('denied or stale writes never publish a confirmation', () async {
    final revision =
        ZyraOnboardingAnswersService.preferenceConfirmationRevision.value;
    Future<void> confirm(String userId, TrafficLight light) =>
        ZyraOnboardingAnswersService.confirmPreferenceLight(
          expectedUserId: userId,
          option: _legacy,
          light: light,
        );

    await expectLater(confirm(_other, TrafficLight.green), throwsStateError);
    expect(requests, isEmpty);

    respond = (_) => _json({'ok': true});
    await expectLater(
      confirm(_owner, TrafficLight.green),
      throwsFormatException,
    );

    respond = (_) => _json({'message': 'denied'}, status: 403);
    await expectLater(
      confirm(_owner, TrafficLight.green),
      throwsA(isA<PostgrestException>()),
    );
    expect(jsonDecode(requests.last.body), {
      'p_items': [_item(_legacy, 'green')],
    });

    final started = Completer<void>();
    final release = Completer<http.Response>();
    respond = (_) {
      started.complete();
      return release.future;
    };
    final pending = expectLater(
      confirm(_owner, TrafficLight.red),
      throwsStateError,
    );
    await started.future;
    ZyraAccountState.resetForTesting();
    release.complete(http.Response('', 204));
    await pending;
    expect(jsonDecode(requests.last.body), {
      'p_items': [_item(_legacy, 'red')],
    });
    expect(
      ZyraOnboardingAnswersService.preferenceConfirmationRevision.value,
      revision,
    );
  });
}
