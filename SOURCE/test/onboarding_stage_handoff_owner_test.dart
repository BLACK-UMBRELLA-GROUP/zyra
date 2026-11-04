// Isolated mock transport only: these handoffs never contact a member backend.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/data/chapter3_categories.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/screens/onboarding/bio_onboarding_flow.dart';
import 'package:zyra/screens/onboarding/chapter2_flow.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/screens/onboarding/profile_ready_screen.dart';
import 'package:zyra/screens/onboarding/values_preferences_flow.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_onboarding_answers_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';
import 'support/queue44_signup_flow_driver.dart';

const _userA = '00000000-0000-0000-0000-000000000001';
const _userB = '00000000-0000-0000-0000-000000000002';
Map<String, dynamic>? _answers;
int _writes = 0;
late _HandoffObserver _observer;

class _HandoffObserver extends NavigatorObserver {
  int replacements = 0;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replacements++;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

enum _Handoff { profileToBio, bioToCompatibility, compatibilityToReview }

Future<void> _session(String userId) => supabase.auth.setInitialSession(
  jsonEncode({
    'access_token':
        '${base64Url.encode(utf8.encode('{"alg":"none"}'))}.'
        '${base64Url.encode(utf8.encode(jsonEncode({'sub': userId, 'exp': 4102444800})))}.local-test-signature',
    'token_type': 'bearer',
    'refresh_token': 'local-fake-refresh',
    'user': {
      'id': userId,
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'aud': 'authenticated',
      'created_at': '2026-10-02T00:00:00Z',
    },
  }),
);

http.Response _reply(Object value, int status, http.Request request) =>
    http.Response(
      jsonEncode(value),
      status,
      request: request,
      headers: {'content-type': 'application/json'},
    );

Map<String, dynamic> _completeCompatibility() {
  final questions = chapter3Categories
      .expand((category) => category.questions)
      .where((question) => question.visibleFor('male'));
  return {
    'user_id': _userA,
    'ch3_answers': {
      for (final question in questions) question.id: question.options.first,
    },
    'ch4_preferences': {
      for (final question in questions)
        question.id: {for (final option in question.options) option: 'green'},
    },
    'ch4_hard_requirements': <String, Object?>{},
  };
}

Future<void> _settleHandoff(
  WidgetTester tester, {
  required bool devPreview,
  VoidCallback? advance,
}) async {
  if (devPreview) {
    advance?.call();
  } else {
    // The mocked HTTP client and stream decoding need real event-loop turns,
    // not hundreds of repeated callbacks inside the widget FakeAsync zone.
    await tester.runAsync(() async {
      advance?.call();
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
  }
  await tester.pumpAndSettle(
    const Duration(milliseconds: 50),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 3),
  );
}

Future<OnboardingStageIntroScreen> _stage(
  WidgetTester tester,
  _Handoff handoff, {
  bool devPreview = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  if (handoff == _Handoff.compatibilityToReview) {
    _answers = _completeCompatibility();
  }
  AppState.instance.gender = 'male';
  AppState.instance.location = 'London';
  final screen = switch (handoff) {
    _Handoff.profileToBio => Chapter2Flow(
      gender: 'male',
      devPreview: devPreview,
    ),
    _Handoff.bioToCompatibility => BioOnboardingFlow(
      gender: 'male',
      devPreview: devPreview,
    ),
    _Handoff.compatibilityToReview => ValuesPreferencesFlow(
      gender: 'male',
      devPreview: devPreview,
    ),
  };
  _observer = _HandoffObserver();
  await tester.pumpWidget(
    MaterialApp(home: screen, navigatorObservers: [_observer]),
  );
  await _settleHandoff(tester, devPreview: devPreview);
  final maxSteps = switch ((handoff, devPreview)) {
    (_Handoff.profileToBio, false) => 2,
    (_Handoff.bioToCompatibility, false) => 6,
    (_Handoff.compatibilityToReview, false) => 2,
    (_Handoff.profileToBio, true) => 25,
    (_Handoff.bioToCompatibility, true) => 6,
    (_Handoff.compatibilityToReview, true) => 180,
  };
  for (var step = 0; step < maxSteps; step++) {
    if (find.byType(OnboardingStageIntroScreen).evaluate().isNotEmpty) break;
    final scaffold = find.byType(OnboardingScaffold);
    String? before;
    if (scaffold.evaluate().isNotEmpty) {
      final widget = tester.widget<OnboardingScaffold>(scaffold);
      before = '${widget.progressLabel}|${widget.question}';
    }
    final advance = deferredOnboardingContinueFixtureCallback(tester);
    await _settleHandoff(tester, devPreview: devPreview, advance: advance);
    if (before != null && scaffold.evaluate().isNotEmpty) {
      final current = tester.widget<OnboardingScaffold>(scaffold);
      expect(
        '${current.progressLabel}|${current.question}',
        isNot(before),
        reason:
            '${handoff.name} did not advance after checkpoint $before '
            '(mock writes: $_writes). Check the restore/save fixture instead '
            'of repeatedly invoking a busy or failed page.',
      );
    }
  }
  expect(
    find.byType(OnboardingStageIntroScreen),
    findsOneWidget,
    reason:
        '${handoff.name} did not reach its stage within $maxSteps checkpoints.',
  );
  return tester.widget<OnboardingStageIntroScreen>(
    find.byType(OnboardingStageIntroScreen),
  );
}

Finder _nextForm(_Handoff handoff) => switch (handoff) {
  _Handoff.profileToBio => find.byType(BioOnboardingFlow),
  _Handoff.bioToCompatibility => find.byType(ValuesPreferencesFlow),
  _Handoff.compatibilityToReview => find.byType(ProfileReadyScreen),
};

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'local-handoff-test',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        final path = request.url.path;
        if (request.method == 'GET' && path == '/rest/v1/onboarding_answers') {
          return _reply([?_answers], 200, request);
        }
        if (request.method == 'POST' && path == '/rest/v1/onboarding_answers') {
          _writes++;
          _answers = jsonDecode(request.body) as Map<String, dynamic>;
          return _reply({'user_id': _answers!['user_id']}, 200, request);
        }
        if (request.method == 'GET' && path == '/rest/v1/seeker_details') {
          // A saved consent-refusal path resumes its completed last question.
          return _reply(
            [
              {
                'user_id': _userA,
                'languages': ['en'],
                'preferences': {
                  'location': {
                    'preference': 'anywhere',
                    'flexibility': 'green',
                  },
                  'languages': {
                    'preferred': ['en'],
                    'flexibility': 'green',
                  },
                },
              },
            ],
            200,
            request,
          );
        }
        if (request.method == 'GET' && path == '/rest/v1/consents') {
          return _reply(
            [
              {
                'granted': false,
                'policy_version': 'local-test',
                'recorded_at': '2026-10-02T00:00:00Z',
              },
            ],
            200,
            request,
          );
        }
        if (request.method == 'GET' && path == '/rest/v1/profile_photos') {
          return _reply(
            [
              for (var index = 0; index < 3; index++)
                {
                  'storage_path': '$_userA/photo-$index.jpg',
                  'display_order': index,
                },
            ],
            200,
            request,
          );
        }
        if (path.startsWith('/storage/v1/object/sign/')) {
          final body = jsonDecode(request.body) as Map;
          return _reply(
            [
              for (final photo in body['paths'] as List)
                {
                  'path': photo,
                  'signedURL': '/object/sign/profile-photos/$photo?token=local',
                  'error': null,
                },
            ],
            200,
            request,
          );
        }
        if (path == '/rest/v1/profile_photos' &&
            (request.method == 'DELETE' || request.method == 'POST')) {
          _writes++;
          return _reply(<Object>[], 200, request);
        }
        if (path == '/rest/v1/profiles' && request.method == 'PATCH') {
          _writes++;
          return _reply({'id': _userA}, 200, request);
        }
        return _reply({'message': 'local test denied'}, 403, request);
      }),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() async {
    _answers = null;
    _writes = 0;
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraInternalPreviewClient.finishSignOut();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraOnboardingAnswersService.setClientReadyForTesting(true);
    await _session(_userA);
    await ZyraAccountState.synchronize(_userA);
  });
  tearDown(() {
    ZyraOnboardingAnswersService.setClientReadyForTesting(null);
    ZyraAccountState.clearImagesForTesting = null;
    ZyraAccountState.endSignOutAttempt();
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
  });

  for (final handoff in _Handoff.values) {
    for (final change in ['switch', 'same ID new generation', 'sign out']) {
      testWidgets('${handoff.name} rejects $change after its stage opens', (
        tester,
      ) async {
        final stage = await _stage(tester, handoff);
        final writesBefore = _writes;
        await tester.runAsync(() async {
          Future<void> changeOwner() async {
            if (change == 'sign out') {
              await ZyraAccountState.beginSignOut();
            } else {
              await _session(_userB);
              await ZyraAccountState.synchronize(_userB);
              if (change == 'same ID new generation') {
                await _session(_userA);
                await ZyraAccountState.synchronize(_userA);
              }
            }
          }

          await changeOwner().timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw StateError(
              '${handoff.name}: mock owner change $change timed out after '
              'the stage was reached.',
            ),
          );
        });
        stage.onContinue();
        await tester.pumpAndSettle();
        expect(find.byType(OnboardingStageIntroScreen), findsOneWidget);
        expect(_nextForm(handoff), findsNothing);
        expect(_writes, writesBefore);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('${handoff.name} revoked preview cannot become a live route', (
      tester,
    ) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
      final stage = await _stage(tester, handoff, devPreview: true);
      expect(stage.devPreview, isTrue);
      final staleContinue = stage.onContinue;
      final staleSkip = stage.onContinue;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpAndSettle();
      staleContinue();
      staleSkip();
      await tester.pumpAndSettle();
      expect(_nextForm(handoff), findsNothing);
      expect(_writes, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${handoff.name} repeated preview callbacks open once', (
      tester,
    ) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
      final stage = await _stage(tester, handoff, devPreview: true);
      final replacementsBefore = _observer.replacements;
      stage.onContinue();
      stage.onContinue();
      stage.onContinue();
      await tester.pumpAndSettle();
      expect(_nextForm(handoff), findsOneWidget);
      expect(_observer.replacements, replacementsBefore + 1);
      expect(_writes, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
