import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/data/chapter3_categories.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/models/journey_bio.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/screens/home/home_shell.dart';
import 'package:zyra/screens/onboarding/values_preferences_flow.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_onboarding_answers_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';

const _userA = '00000000-0000-0000-0000-000000000001';
const _userB = '00000000-0000-0000-0000-000000000002';
Map<String, dynamic>? _savedRow;
bool _failRead = false;
bool _failWrite = false;
String? _writeReplyOwner;
Completer<void>? _readWait;
Completer<void>? _writeWait;
int _reads = 0;
int _writes = 0;
Map<String, dynamic>? _lastPayload;

Future<void> _setSession(String userId) => supabase.auth.setInitialSession(
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

http.Response _jsonResponse(Object value, int status, http.Request request) =>
    http.Response(
      jsonEncode(value),
      status,
      request: request,
      headers: {'content-type': 'application/json'},
    );

Future<void> _mountValues(
  WidgetTester tester, {
  bool devPreview = false,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: ValuesPreferencesFlow(gender: 'male', devPreview: devPreview),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'local-persistence-test',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        if (request.url.path != '/rest/v1/onboarding_answers') {
          return _jsonResponse({'message': 'local test denied'}, 403, request);
        }
        if (request.method == 'GET') {
          _reads++;
          final snapshot = _savedRow;
          if (_readWait != null) await _readWait!.future;
          return _failRead
              ? _jsonResponse({'message': 'local read failed'}, 400, request)
              : _jsonResponse([?snapshot], 200, request);
        }
        if (request.method == 'POST') {
          _writes++;
          final payload = jsonDecode(request.body) as Map<String, dynamic>;
          _lastPayload = payload;
          if (_writeWait != null) await _writeWait!.future;
          if (_failWrite) {
            return _jsonResponse(
              {'message': 'local write failed'},
              400,
              request,
            );
          }
          _savedRow = payload;
          return _jsonResponse(
            {'user_id': _writeReplyOwner ?? payload['user_id']},
            200,
            request,
          );
        }
        return _jsonResponse({'message': 'local test denied'}, 403, request);
      }),
    );
  });

  tearDownAll(() => Supabase.instance.dispose());

  setUp(() async {
    _savedRow = null;
    _failRead = false;
    _failWrite = false;
    _writeReplyOwner = null;
    _readWait = null;
    _writeWait = null;
    _reads = 0;
    _writes = 0;
    _lastPayload = null;
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraInternalPreviewClient.finishSignOut();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraOnboardingAnswersService.setClientReadyForTesting(true);
    await _setSession(_userA);
    await ZyraAccountState.synchronize(_userA);
  });

  tearDown(() {
    _readWait?.completeIfPending();
    _writeWait?.completeIfPending();
    ZyraOnboardingAnswersService.setClientReadyForTesting(null);
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
    ZyraAccountState.resetForTesting();
  });

  test(
    'no initialized client cannot claim a saved Bio or Values checkpoint',
    () async {
      ZyraOnboardingAnswersService.setClientReadyForTesting(false);
      expect(
        await ZyraOnboardingAnswersService.syncJourneyBio(const JourneyBio()),
        isFalse,
      );
      expect(
        await ZyraOnboardingAnswersService.syncAnswers(
          ch3Answers: {},
          ch4Preferences: {},
          ch4HardRequirements: {},
        ),
        isFalse,
      );
      await expectLater(
        ZyraOnboardingAnswersService.fetchOwn(throwOnError: true),
        throwsStateError,
      );
      expect(_reads, 0);
      expect(_writes, 0);
    },
  );

  test('a genuine empty draft differs from a failed restore', () async {
    expect(
      await ZyraOnboardingAnswersService.fetchOwn(
        expectedUserId: _userA,
        throwOnError: true,
      ),
      isNull,
    );
    _failRead = true;
    await expectLater(
      ZyraOnboardingAnswersService.fetchOwn(
        expectedUserId: _userA,
        throwOnError: true,
      ),
      throwsA(anything),
    );
    expect(_writes, 0);
  });

  test('the wrong principal cannot read or write another setup', () async {
    expect(
      await ZyraOnboardingAnswersService.syncJourneyBio(
        const JourneyBio(),
        expectedUserId: _userB,
      ),
      isFalse,
    );
    await expectLater(
      ZyraOnboardingAnswersService.fetchOwn(
        expectedUserId: _userB,
        throwOnError: true,
      ),
      throwsStateError,
    );
    expect(_reads, 0);
    expect(_writes, 0);
  });

  test('a late restore cannot publish data after an account switch', () async {
    _savedRow = {
      'ch3_answers': {'bio_about_me': 'Previous account draft'},
      'ch4_preferences': {},
      'ch4_hard_requirements': {},
    };
    _readWait = Completer<void>();
    final restoring = ZyraOnboardingAnswersService.fetchOwn(
      expectedUserId: _userA,
      throwOnError: true,
    );
    final rejected = expectLater(restoring, throwsStateError);
    await Future<void>.delayed(Duration.zero);
    await _setSession(_userB);
    await ZyraAccountState.synchronize(_userB);
    AppState.instance.name = 'Current member';
    _readWait!.complete();
    await rejected;
    expect(AppState.instance.name, 'Current member');
    expect(AppState.instance.journeyBio.isEmpty, isTrue);
  });

  test(
    'Bio saves preserve compatibility and confirm the returned owner',
    () async {
      _savedRow = {
        'ch3_answers': {'ch3_q1': 'Never Married', 'bio_about_me': 'Old draft'},
        'ch4_preferences': {
          'ch3_q1': {'Never Married': 'green'},
        },
        'ch4_hard_requirements': {
          'ch3_q1': ['Currently Married'],
        },
      };
      const bio = JourneyBio(aboutMe: 'Faith and kindness.', reviewed: true);
      expect(
        await ZyraOnboardingAnswersService.syncJourneyBio(
          bio,
          expectedUserId: _userA,
        ),
        isTrue,
      );
      final answers = _lastPayload!['ch3_answers'] as Map;
      expect(answers['ch3_q1'], 'Never Married');
      expect(answers['bio_about_me'], 'Faith and kindness.');
      expect(answers['bio_reviewed'], isTrue);
      expect((_lastPayload!['ch4_preferences'] as Map)['ch3_q1'], {
        'Never Married': 'green',
      });
      _writeReplyOwner = _userB;
      expect(
        await ZyraOnboardingAnswersService.syncJourneyBio(
          bio,
          expectedUserId: _userA,
        ),
        isFalse,
      );
    },
  );

  test(
    'a checkpoint captures detached answers and rejects a late account change',
    () async {
      final answer = <String>['First selection'];
      _writeWait = Completer<void>();
      final saving = ZyraOnboardingAnswersService.syncAnswers(
        ch3Answers: {'ch3_q1': answer},
        ch4Preferences: {
          'ch3_q1': {'Never Married': TrafficLight.green},
        },
        ch4HardRequirements: {},
        expectedUserId: _userA,
      );
      answer.add('Later edit');
      await Future<void>.delayed(Duration.zero);
      expect((_lastPayload!['ch3_answers'] as Map)['ch3_q1'], [
        'First selection',
      ]);
      await _setSession(_userB);
      await ZyraAccountState.synchronize(_userB);
      _writeWait!.complete();
      expect(await saving, isFalse);
    },
  );

  testWidgets(
    'Values restore failure offers retry without an empty replacement',
    (tester) async {
      _failRead = true;
      await _mountValues(tester);
      expect(find.byKey(const ValueKey('values_recovery')), findsOneWidget);
      expect(
        find.textContaining('couldn’t restore your saved answers'),
        findsOneWidget,
      );
      expect(find.byType(OnboardingScaffold), findsNothing);
      expect(_writes, 0);

      _failRead = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('compatibility_section_continue')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Values waits for each answer save, retains a failed answer and retries once',
    (tester) async {
      await _mountValues(tester);
      await tester.tap(
        find.byKey(const ValueKey('compatibility_section_continue')),
      );
      await tester.pumpAndSettle();
      final first = chapter3Categories.first.questions.first;
      final second = chapter3Categories.first.questions[1];
      await tester.tap(find.text(first.options.first));
      await tester.pump();
      _failWrite = true;
      _writeWait = Completer<void>();
      final callback = tester
          .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
          .onContinue!;
      callback();
      callback();
      await tester.pump();
      expect(_writes, 1);
      expect(find.text('Saving your progress…'), findsOneWidget);
      _writeWait!.complete();
      await tester.pumpAndSettle();
      expect(find.text(first.prompt), findsWidgets);
      expect(find.text(second.prompt), findsNothing);
      expect(find.textContaining('answers weren’t saved'), findsOneWidget);

      _writeWait = null;
      _failWrite = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text(second.prompt), findsWidgets);
      expect(_writes, 2);
      expect(
        (_lastPayload!['ch3_answers'] as Map)[first.id],
        first.options.first,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mid-section re-entry resumes the first unsaved valid question', (
    tester,
  ) async {
    final first = chapter3Categories.first.questions.first;
    final second = chapter3Categories.first.questions[1];
    _savedRow = {
      'ch3_answers': {
        first.id: first.options.first,
        second.id: 'invalid stale option',
      },
      'ch4_preferences': {},
      'ch4_hard_requirements': {},
    };
    await _mountValues(tester);
    expect(find.text(second.prompt), findsWidgets);
    expect(find.text(first.prompt), findsNothing);
    expect(
      tester
          .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
          .fabActive,
      isFalse,
    );
    expect(_writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'finish later saves only the partial draft and cannot bypass IDV',
    (tester) async {
      await _mountValues(tester);
      await tester.tap(
        find.byKey(const ValueKey('compatibility_section_continue')),
      );
      await tester.pumpAndSettle();
      final first = chapter3Categories.first.questions.first;
      final second = chapter3Categories.first.questions[1];
      await tester.tap(find.text(first.options.first));
      await tester.pump();
      _failWrite = true;
      _writeWait = Completer<void>();
      final callback = tester
          .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
          .onFinishLater!;
      callback();
      callback();
      await tester.pump();
      expect(_writes, 1);
      expect(find.text('Saving your progress…'), findsOneWidget);
      _writeWait!.complete();
      await tester.pumpAndSettle();
      expect(find.text(first.prompt), findsWidgets);
      expect(find.textContaining('answers weren’t saved'), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
      final answers = _lastPayload!['ch3_answers'] as Map;
      expect(answers[first.id], first.options.first);
      expect(answers.containsKey(second.id), isFalse);

      _writeWait = null;
      _failWrite = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      // This mock supplies no verified identity state. A confirmed draft save
      // alone must not admit an ordinary account to the main app.
      expect(_writes, 2);
      expect(find.textContaining('couldn’t return to My ZYRA'), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
      expect(find.text(first.prompt), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'protected preview can finish later without a persistence write',
    (tester) async {
      ZyraOnboardingAnswersService.setClientReadyForTesting(false);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
      ZyraInternalPreviewClient.beginPreview();
      AppState.instance.applyDevPreset(name: 'Aaliyah', gender: 'male');
      await _mountValues(tester, devPreview: true);
      await tester.tap(
        find.byKey(const ValueKey('compatibility_section_continue')),
      );
      await tester.pumpAndSettle();
      final callback = tester
          .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
          .onFinishLater!;
      callback();
      callback();
      await tester.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.byType(ValuesPreferencesFlow), findsNothing);
      expect(_reads, 0);
      expect(_writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
}

extension on Completer<void> {
  void completeIfPending() {
    if (!isCompleted) complete();
  }
}
