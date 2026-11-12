import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_onboarding_answers_service.dart';

const _owner = '00000000-0000-4000-8000-000000005501';
const _other = '00000000-0000-4000-8000-000000005502';
const _read = '/rest/v1/rpc/zyra_my_lights_needing_reconfirmation';
const _write = '/rest/v1/rpc/zyra_confirm_preference_lights';
const _answers = '/rest/v1/onboarding_answers';
const _legacy = (questionId: 'ch3_q26', optionValue: 'No preference');
const _confirmed = (questionId: 'ch3_q1', optionValue: 'Usually');

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
  });
  tearDownAll(() async {
    ZyraOnboardingAnswersService.setClientReadyForTesting(null);
    await Supabase.instance.dispose();
  });
  setUp(() async {
    ZyraAccountState.resetForTesting();
    await _session(_owner);
    requests.clear();
    respond = (request) => throw StateError('Unexpected ${request.url.path}');
  });

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
