import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
// This matches the existing first-photo fixture's cache boundary.
// ignore: depend_on_referenced_packages
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/models/zyra_initial_signup_draft.dart';
import 'package:zyra/models/zyra_signup_membership_choice.dart';
import 'package:zyra/screens/onboarding/identity_verification_screen.dart';
import 'package:zyra/screens/onboarding/signup_membership_choice_screen.dart';
import 'package:zyra/screens/profile/zyra_photo_batch_flow.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_image_cache.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_photo_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';
import 'package:zyra/widgets/zyra_signup_first_photo_card.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';

import 'initial_signup_draft_test.dart' show FakeSignupStore;
import 'support/queue44_signup_flow_driver.dart';

const _ownerId = 'guardian-signup-photo-owner';
const _firstUrl =
    'https://test.invalid/storage/v1/object/sign/profile-photos/$_ownerId/first.jpg?token=synthetic';
const _secondUrl =
    'https://test.invalid/storage/v1/object/sign/profile-photos/$_ownerId/second.jpg?token=synthetic';
const _localPhoto =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
const _question = ValueKey('guardian_signup_first_photo_question');
const _choose = ValueKey('signup_first_photo_choose');
const _preview = ValueKey('signup_first_photo_preview');
const _continue = ValueKey('wali_onboarding_continue');

Future<void> _tap(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _primeLocalPhotoPaints(WidgetTester tester) async {
  final source = base64Decode(_localPhoto.split(',').last);
  late ui.Image pixel;
  await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(source);
    pixel = (await codec.getNextFrame()).image;
    codec.dispose();
  });
  for (final url in [_firstUrl, _secondUrl]) {
    final provider = CachedNetworkImageProvider(
      url,
      cacheKey: ZyraImageCache.keyFor(url),
      cacheManager: ZyraImageCache.manager,
    );
    PaintingBinding.instance.imageCache.putIfAbsent(
      provider,
      () => OneFrameImageStreamCompleter(
        Future<ImageInfo>.value(ImageInfo(image: pixel.clone())),
      ),
    );
  }
  pixel.dispose();
}

Future<void> _mount(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await _primeLocalPhotoPaints(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
        child: OnboardingPreviewStyle(
          directionName: 'luma',
          child: ZyraOnboardingArrowScope(enabled: true, child: child!),
        ),
      ),
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
}

bool _canContinue(WidgetTester tester) =>
    tester.widget<ZyraOnboardingArrowAction>(find.byKey(_continue)).active;

ZyraSignupFirstPhotoCard _photoCard(WidgetTester tester) => tester
    .widget<ZyraSignupFirstPhotoCard>(find.byType(ZyraSignupFirstPhotoCard));

ZyraInitialSignupDraft _liveDraft({
  int step = 4,
  String? firstPhotoPath,
  ZyraSignupMembershipChoice? choice,
}) => ZyraInitialSignupDraft(
  role: ZyraSignupRole.guardian,
  step: step,
  firstName: 'Hassan',
  lastName: 'Ahmed',
  gender: 'male',
  dob: DateTime(1980, 1, 2),
  relationship: 'Father',
  firstPhotoPath: firstPhotoPath,
  membershipChoice: choice,
);

Future<void> _flushLocalWork(WidgetTester tester) async {
  // Frame settling does not await the repository's serialized readback.
  for (var turn = 0; turn < 6; turn++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<ZyraInitialSignupDraft?> _readSavedDraft(
  WidgetTester tester,
  ZyraSignupDraftRepository repository,
) async {
  await _flushLocalWork(tester);
  final draft = await tester.runAsync(
    () => repository.read(_ownerId).timeout(const Duration(seconds: 2)),
  );
  await tester.pumpAndSettle();
  return draft;
}

Future<void> _installLocalSession(WidgetTester tester) async {
  String encode(Map<String, Object?> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final token =
      '${encode({'alg': 'none', 'typ': 'JWT'})}.${encode({'sub': _ownerId, 'exp': 4102444800})}.synthetic';
  await tester.runAsync(() async {
    await Supabase.instance.client.auth.setInitialSession(
      jsonEncode({
        'access_token': token,
        'refresh_token': 'synthetic-local-refresh',
        'token_type': 'bearer',
        'expires_in': 31536000,
        'user': {
          'id': _ownerId,
          'email': 'synthetic@guardian-photo.test.invalid',
          'aud': 'authenticated',
          'role': 'authenticated',
          'app_metadata': {
            'provider': 'google',
            'providers': ['google'],
          },
          'user_metadata': <String, Object?>{},
          'created_at': '2026-10-12T00:00:00Z',
        },
      }),
    );
    await ZyraAccountState.synchronize(_ownerId);
  });
}

Future<void> _openDevPhoto(
  WidgetTester tester, {
  ZyraPhotoBatchRunner? runner,
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  ZyraDeveloperAccess.setAuthorizedForTesting(true);
  ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
  ZyraInternalPreviewClient.beginPreview();
  await _mount(
    tester,
    WaliOnboardingFlow(devPreview: true, photoRunner: runner),
    size: size,
    scale: scale,
  );
  for (var question = 0; question < 4; question++) {
    await advanceSignupQuestionFromCode(tester, installPhotoFixture: false);
  }
  expect(find.byKey(_question), findsOneWidget);
}

void main() {
  late FakeSignupStore store;
  late ZyraSignupDraftRepository repository;
  late Directory cacheRoot;
  sqflite.DatabaseFactory? previousDatabaseFactory;
  var supabaseInitialized = false;
  var cacheInitialized = false;
  String? owner;
  var httpCalls = 0;
  var signingFails = false;
  var photoReadFails = false;
  Completer<void>? signingWait;
  final photoRequests = <({String method, String path})>[];
  final savedPhotoRows = <Map<String, Object?>>[];

  void installSavedPhotos(int count) {
    savedPhotoRows.addAll([
      for (var index = 0; index < count; index++)
        {
          'user_id': _ownerId,
          'storage_path': index == 0
              ? '$_ownerId/first.jpg'
              : '$_ownerId/saved-$index.jpg',
          'display_order': index,
          'is_primary': index == 0,
        },
    ]);
  }

  setUpAll(() async {
    // Test-owned temporary cache only; no member files, real camera or database.
    cacheRoot = await Directory.systemTemp.createTemp(
      'zyra-guardian-first-photo-test-',
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => cacheRoot.path,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.tekartik.sqflite'),
      (call) async => switch (call.method) {
        'openDatabase' => 1,
        'query' =>
          (call.arguments as Map?)?['sql'] == 'PRAGMA user_version'
              ? <Map<String, Object?>>[
                  {'user_version': 3},
                ]
              : <Map<String, Object?>>[],
        'batch' => <Object?>[],
        'insert' || 'update' => 0,
        'getDatabasesPath' => cacheRoot.path,
        'databaseExists' => false,
        _ => null,
      },
    );
    previousDatabaseFactory = sqflite.databaseFactoryOrNull;
    sqflite.databaseFactory = sqflite.databaseFactorySqflitePlugin;
    await ZyraImageCache.manager
        .getFileFromCache('synthetic-not-present')
        .timeout(const Duration(seconds: 2));
    cacheInitialized = true;
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.invalid',
      publishableKey: 'synthetic-local-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        httpCalls++;
        final path = request.url.path;
        photoRequests.add((method: request.method, path: path));
        http.Response json(Object value, [int status = 200]) => http.Response(
          jsonEncode(value),
          status,
          request: request,
          headers: {'content-type': 'application/json'},
        );
        if (request.method == 'GET' && path == '/rest/v1/profile_photos') {
          expect(request.url.queryParameters['user_id'], 'eq.$_ownerId');
          return photoReadFails
              ? json({'message': 'Synthetic saved-photo read unavailable'}, 403)
              : json(savedPhotoRows);
        }
        if (request.method == 'POST' &&
            path == '/storage/v1/object/sign/profile-photos') {
          await signingWait?.future;
          if (signingFails) {
            return json({'message': 'Synthetic unavailable'}, 403);
          }
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final paths = (body['paths'] as List).cast<String>();
          return json([
            for (final photoPath in paths)
              {
                'path': photoPath,
                'signedURL':
                    '/object/sign/profile-photos/$photoPath?token=synthetic',
              },
          ]);
        }
        if (request.method == 'POST' &&
            path.startsWith('/storage/v1/object/sign/profile-photos/')) {
          await signingWait?.future;
          if (signingFails) {
            return json({'message': 'Synthetic unavailable'}, 403);
          }
          return json({
            'signedURL':
                '${path.substring('/storage/v1'.length)}?token=synthetic',
          });
        }
        return json({
          'message': 'Every other service request is rejected',
        }, 403);
      }),
    );
    supabaseInitialized = true;
  });

  tearDownAll(() async {
    if (supabaseInitialized) await Supabase.instance.dispose();
    if (cacheInitialized) await ZyraImageCache.manager.dispose();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.tekartik.sqflite'),
      null,
    );
    sqflite.databaseFactory = previousDatabaseFactory;
    await cacheRoot.delete(recursive: true);
  });

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraPhotoService.clearUrlMemoForSignOut();
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    AppState.instance.resetForAccountChange();
    owner = _ownerId;
    httpCalls = 0;
    signingFails = false;
    photoReadFails = false;
    signingWait = null;
    photoRequests.clear();
    savedPhotoRows.clear();
    store = FakeSignupStore();
    repository = ZyraSignupDraftRepository(
      store: store,
      backend: 'https://test.invalid',
      currentUserId: () => owner,
      isPreview: () => false,
    );
    ZyraInitialSignupDraftService.setRepositoryForTesting(repository);
  });

  tearDown(() {
    final pending = store.writeWait;
    if (pending != null && !pending.isCompleted) pending.complete();
    final pendingSign = signingWait;
    if (pendingSign != null && !pendingSign.isCompleted) pendingSign.complete();
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    AppState.instance.resetForAccountChange();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('Guardian requires photo after relationship before membership', (
    tester,
  ) async {
    await _mount(
      tester,
      WaliOnboardingFlow(
        signupUserId: _ownerId,
        initialDraft: _liveDraft(step: 3),
      ),
    );
    expect(find.text('QUESTION 4 OF 5'), findsOneWidget);
    expect(find.byKey(_question), findsNothing);
    await _tap(tester, _continue);
    await _flushLocalWork(tester);
    final scaffold = tester.widget<OnboardingScaffold>(find.byKey(_question));
    expect(scaffold.progressLabel, 'QUESTION 5 OF 5');
    expect(scaffold.chapterProgress, 1);
    expect(scaffold.frameContent, isFalse);
    expect(scaffold.privacy, isNull);
    expect(_canContinue(tester), isFalse);
    final staleContinue = tester
        .widget<ZyraOnboardingArrowAction>(find.byKey(_continue))
        .onPressed!;
    staleContinue();
    await _flushLocalWork(tester);
    expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
    expect((await _readSavedDraft(tester, repository))!.step, 4);
    expect(httpCalls, 0);
    expect(tester.takeException(), isNull);
  });

  for (final result in [
    const ZyraPhotoBatchResult.cancelled(),
    const ZyraPhotoBatchResult.added([]),
    const ZyraPhotoBatchResult.added([_firstUrl, _secondUrl]),
  ]) {
    testWidgets(
      'Guardian ${result.outcome.name} ${result.urls.length} cannot satisfy one photo',
      (tester) async {
        var calls = 0;
        await _openDevPhoto(
          tester,
          runner: (context, remaining, progress) async {
            calls++;
            expect(remaining, 1);
            return result;
          },
        );
        await _tap(tester, _choose);
        expect(calls, 1);
        expect(_photoCard(tester).busy, isFalse);
        expect(_photoCard(tester).photo, isNull);
        expect(_canContinue(tester), isFalse);
        expect(find.byKey(_preview), findsNothing);
        expect(store.operations, 0);
        expect(httpCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Guardian picker failure retries without automatic advance', (
    tester,
  ) async {
    var calls = 0;
    await _openDevPhoto(
      tester,
      runner: (context, remaining, progress) async => calls++ == 0
          ? const ZyraPhotoBatchResult.error(ZyraPhotoFailureKind.processing)
          : const ZyraPhotoBatchResult.added([_localPhoto]),
    );
    await _tap(tester, _choose);
    expect(_canContinue(tester), isFalse);
    expect(find.textContaining('Reference:'), findsOneWidget);
    await _tap(tester, _choose);
    expect(calls, 2);
    expect(_photoCard(tester).photo, _localPhoto);
    expect(_canContinue(tester), isTrue);
    expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
    await _tap(tester, _continue);
    expect(find.byType(SignupMembershipChoiceScreen), findsOneWidget);
    expect(store.operations, 0);
    expect(httpCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Guardian busy picker blocks duplicate pick and advance', (
    tester,
  ) async {
    final result = Completer<ZyraPhotoBatchResult>();
    var calls = 0;
    ValueChanged<String?>? progress;
    await _openDevPhoto(
      tester,
      runner: (context, remaining, report) {
        calls++;
        progress = report;
        return result.future;
      },
    );
    final choose = _photoCard(tester).onChoose;
    final advance = tester
        .widget<ZyraOnboardingArrowAction>(find.byKey(_continue))
        .onPressed!;
    choose();
    choose();
    await tester.pump();
    progress!('Preparing 1 of 1');
    await tester.pump();
    expect(_photoCard(tester).busy, isTrue);
    expect(find.text('Preparing 1 of 1'), findsOneWidget);
    expect(_canContinue(tester), isFalse);
    advance();
    await tester.pump();
    expect(calls, 1);
    expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
    result.complete(const ZyraPhotoBatchResult.added([_localPhoto]));
    await tester.pumpAndSettle();
    expect(_photoCard(tester).busy, isFalse);
    expect(_canContinue(tester), isTrue);
    expect(httpCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ordinary Guardian waits for private tokenless save confirmation',
    (tester) async {
      final wait = Completer<void>();
      store.writeWait = wait;
      await _mount(
        tester,
        WaliOnboardingFlow(
          signupUserId: _ownerId,
          initialDraft: _liveDraft(),
          photoRunner: (context, remaining, progress) async {
            expect(remaining, 1);
            return const ZyraPhotoBatchResult.added([_firstUrl]);
          },
        ),
      );
      _photoCard(tester).onChoose();
      await tester.pump();
      expect(_photoCard(tester).busy, isTrue);
      expect(_canContinue(tester), isFalse);
      expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
      wait.complete();
      final saved = await _readSavedDraft(tester, repository);
      expect(saved!.role, ZyraSignupRole.guardian);
      expect(saved.step, 4);
      expect(saved.firstPhotoPath, '$_ownerId/first.jpg');
      expect(saved.awaitsVerification, isFalse);
      expect(store.values.values.join(), isNot(contains('token=')));
      expect(store.values.values.join(), isNot(contains('https://')));
      expect(_photoCard(tester).busy, isFalse);
      expect(_canContinue(tester), isTrue);
      await _tap(tester, _continue);
      final membershipDraft = await _readSavedDraft(tester, repository);
      expect(membershipDraft!.step, 5);
      expect(find.byType(SignupMembershipChoiceScreen), findsOneWidget);
      expect(httpCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rejected Guardian photo save remains blocked and can retry', (
    tester,
  ) async {
    store.rejectWrite = true;
    await _mount(
      tester,
      WaliOnboardingFlow(
        signupUserId: _ownerId,
        initialDraft: _liveDraft(),
        photoRunner: (context, remaining, progress) async =>
            const ZyraPhotoBatchResult.added([_firstUrl]),
      ),
    );
    await _tap(tester, _choose);
    await _flushLocalWork(tester);
    expect(_photoCard(tester).photo, isNull);
    expect(_canContinue(tester), isFalse);
    expect(
      find.textContaining("couldn't save your progress securely"),
      findsOneWidget,
    );
    expect(await _readSavedDraft(tester, repository), isNull);
    store.rejectWrite = false;
    await _tap(tester, _choose);
    expect(
      (await _readSavedDraft(tester, repository))!.firstPhotoPath,
      '$_ownerId/first.jpg',
    );
    expect(_canContinue(tester), isTrue);
    expect(httpCalls, 0);
    expect(tester.takeException(), isNull);
  });

  for (final invalidUrl in [
    'https://test.invalid/storage/v1/object/sign/profile-photos/other-owner/first.jpg?token=synthetic',
    'https://different.test.invalid/storage/v1/object/sign/profile-photos/$_ownerId/first.jpg?token=synthetic',
    _localPhoto,
  ]) {
    testWidgets(
      'ordinary Guardian rejects photo outside own private Storage ${invalidUrl == _localPhoto ? 'data URL' : Uri.parse(invalidUrl).host + Uri.parse(invalidUrl).path}',
      (tester) async {
        await _mount(
          tester,
          WaliOnboardingFlow(
            signupUserId: _ownerId,
            initialDraft: _liveDraft(),
            photoRunner: (context, remaining, progress) async =>
                ZyraPhotoBatchResult.added([invalidUrl]),
          ),
        );
        await _tap(tester, _choose);
        expect(_photoCard(tester).photo, isNull);
        expect(_canContinue(tester), isFalse);
        expect(store.operations, 0);
        expect(httpCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final invalidateEpoch in [false, true]) {
    testWidgets(
      'Guardian late picker ignores replaced ${invalidateEpoch ? 'account epoch' : 'owner'}',
      (tester) async {
        final result = Completer<ZyraPhotoBatchResult>();
        ValueChanged<String?>? progress;
        await _mount(
          tester,
          WaliOnboardingFlow(
            signupUserId: _ownerId,
            initialDraft: _liveDraft(),
            photoRunner: (context, remaining, report) {
              progress = report;
              return result.future;
            },
          ),
        );
        _photoCard(tester).onChoose();
        await tester.pump();
        if (invalidateEpoch) {
          ZyraAccountState.resetForTesting();
        } else {
          owner = 'replacement-owner';
        }
        progress!('Late preparation');
        result.complete(const ZyraPhotoBatchResult.added([_firstUrl]));
        await tester.pumpAndSettle();
        expect(_photoCard(tester).photo, isNull);
        expect(find.text('Late preparation'), findsNothing);
        expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
        expect(store.operations, 0);
        expect(httpCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Guardian revoked preview ignores retained pick and late result',
    (tester) async {
      final result = Completer<ZyraPhotoBatchResult>();
      var calls = 0;
      ValueChanged<String?>? progress;
      await _openDevPhoto(
        tester,
        runner: (context, remaining, report) {
          calls++;
          progress = report;
          return result.future;
        },
      );
      final choose = _photoCard(tester).onChoose;
      choose();
      await tester.pump();
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pump();
      choose();
      progress!('Late preparation');
      result.complete(const ZyraPhotoBatchResult.added([_localPhoto]));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('guardian_signup_preview_denied')),
        findsOneWidget,
      );
      expect(find.byKey(_preview), findsNothing);
      expect(calls, 1);
      expect(store.operations, 0);
      expect(httpCalls, 0);
      expect(AppState.instance.photos, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('disposed Guardian ignores late picker progress and photo', (
    tester,
  ) async {
    final result = Completer<ZyraPhotoBatchResult>();
    ValueChanged<String?>? progress;
    await _openDevPhoto(
      tester,
      runner: (context, remaining, report) {
        progress = report;
        return result.future;
      },
    );
    _photoCard(tester).onChoose();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    progress!('Late preparation');
    result.complete(const ZyraPhotoBatchResult.added([_localPhoto]));
    await tester.pumpAndSettle();
    expect(AppState.instance.photos, isEmpty);
    expect(store.operations, 0);
    expect(httpCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy Guardian membership intent returns to required photo', (
    tester,
  ) async {
    const choice = ZyraSignupMembershipChoice(
      kind: ZyraSignupMembershipKind.one,
    );
    final migrated = ZyraInitialSignupDraft.fromJson({
      'version': 4,
      'role': 'guardian',
      'step': 4,
      'showIntroduction': false,
      'firstName': 'Hassan',
      'lastName': 'Ahmed',
      'gender': 'male',
      'dob': '1980-01-02',
      'relationship': 'Father',
      'firstPhotoPath': null,
      'membershipChoice': choice.toJson(),
    });
    expect(migrated.step, 4);
    expect(migrated.firstPhotoPath, isNull);
    expect(migrated.awaitsVerification, isFalse);
    expect(migrated.membershipChoice?.kind, choice.kind);
    await _mount(
      tester,
      WaliOnboardingFlow(
        signupUserId: _ownerId,
        initialDraft: migrated,
        photoRunner: (context, remaining, progress) async =>
            const ZyraPhotoBatchResult.added([_firstUrl]),
      ),
    );
    expect(find.byKey(_question), findsOneWidget);
    expect(_canContinue(tester), isFalse);
    expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
    await _tap(tester, _choose);
    await _readSavedDraft(tester, repository);
    await _tap(tester, _continue);
    final saved = await _readSavedDraft(tester, repository);
    expect(saved!.step, 5);
    expect(saved.firstPhotoPath, '$_ownerId/first.jpg');
    expect(saved.membershipChoice?.kind, choice.kind);
    expect(find.byType(SignupMembershipChoiceScreen), findsOneWidget);
    expect(httpCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unavailable restored Guardian photo cannot bypass question', (
    tester,
  ) async {
    await _installLocalSession(tester);
    signingFails = true;
    await _mount(
      tester,
      WaliOnboardingFlow(
        signupUserId: _ownerId,
        initialDraft: _liveDraft(
          step: 5,
          firstPhotoPath: '$_ownerId/first.jpg',
        ),
      ),
    );
    await _flushLocalWork(tester);
    expect(find.byKey(_question), findsOneWidget);
    expect(_photoCard(tester).photo, isNull);
    expect(_canContinue(tester), isFalse);
    expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
    expect(store.operations, 0);
    expect(photoRequests, isNotEmpty);
    expect(
      photoRequests,
      everyElement(
        predicate<({String method, String path})>(
          (request) =>
              request.method == 'POST' &&
              request.path ==
                  '/storage/v1/object/sign/profile-photos/$_ownerId/first.jpg',
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Guardian recovers its saved first photo without choosing again',
    (tester) async {
      installSavedPhotos(1);
      await _installLocalSession(tester);
      var picks = 0;
      await _mount(
        tester,
        WaliOnboardingFlow(
          signupUserId: _ownerId,
          initialDraft: _liveDraft(),
          recoverExistingPhoto: true,
          photoRunner: (context, remaining, progress) async {
            picks++;
            return const ZyraPhotoBatchResult.cancelled();
          },
        ),
      );
      await _flushLocalWork(tester);
      expect(_photoCard(tester).photo, _firstUrl);
      expect(_photoCard(tester).busy, isFalse);
      expect(_canContinue(tester), isTrue);
      expect(picks, 0);
      await _tap(tester, _continue);
      final saved = await _readSavedDraft(tester, repository);
      expect(saved!.step, 5);
      expect(saved.firstPhotoPath, '$_ownerId/first.jpg');
      expect(find.byType(SignupMembershipChoiceScreen), findsOneWidget);
      expect(savedPhotoRows, hasLength(1));
      expect(
        photoRequests,
        everyElement(
          predicate<({String method, String path})>(
            (request) =>
                (request.method == 'GET' &&
                    request.path == '/rest/v1/profile_photos') ||
                (request.method == 'POST' &&
                    request.path == '/storage/v1/object/sign/profile-photos'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Guardian saved-photo failure blocks pick and advance until retry',
    (tester) async {
      installSavedPhotos(1);
      photoReadFails = true;
      await _installLocalSession(tester);
      var picks = 0;
      await _mount(
        tester,
        WaliOnboardingFlow(
          signupUserId: _ownerId,
          initialDraft: _liveDraft(),
          recoverExistingPhoto: true,
          photoRunner: (context, remaining, progress) async {
            picks++;
            return const ZyraPhotoBatchResult.added([_secondUrl]);
          },
        ),
      );
      await _flushLocalWork(tester);
      expect(find.byType(ZyraSignupFirstPhotoCard), findsNothing);
      expect(find.byKey(_choose), findsNothing);
      expect(_canContinue(tester), isFalse);
      final staleAdvance = tester
          .widget<ZyraOnboardingArrowAction>(find.byKey(_continue))
          .onPressed!;
      staleAdvance();
      await _flushLocalWork(tester);
      expect(store.operations, 0);
      expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
      final retry = tester
          .widget<ZyraErrorBanner>(find.byType(ZyraErrorBanner))
          .onRetry;
      expect(retry, isNotNull);
      photoReadFails = false;
      retry!();
      await _flushLocalWork(tester);
      expect(find.byType(ZyraErrorBanner), findsNothing);
      expect(_photoCard(tester).photo, _firstUrl);
      expect(_photoCard(tester).busy, isFalse);
      expect(_canContinue(tester), isTrue);
      expect(picks, 0);
      expect(
        photoRequests.where(
          (request) => request.path == '/rest/v1/profile_photos',
        ),
        hasLength(2),
      );
      expect(savedPhotoRows, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'six saved Guardian photos reuse main photo and forbid seventh pick',
    (tester) async {
      installSavedPhotos(6);
      await _installLocalSession(tester);
      var picks = 0;
      await _mount(
        tester,
        WaliOnboardingFlow(
          signupUserId: _ownerId,
          initialDraft: _liveDraft(),
          recoverExistingPhoto: true,
          photoRunner: (context, remaining, progress) async {
            picks++;
            return const ZyraPhotoBatchResult.added([_secondUrl]);
          },
        ),
      );
      await _flushLocalWork(tester);
      expect(_photoCard(tester).photo, _firstUrl);
      expect(_photoCard(tester).canChoose, isFalse);
      expect(find.byKey(_choose), findsNothing);
      expect(_canContinue(tester), isTrue);
      // Retaining the original chooser cannot bypass the saved-photo limit.
      _photoCard(tester).onChoose();
      await _flushLocalWork(tester);
      expect(picks, 0);
      expect(savedPhotoRows, hasLength(6));
      await _tap(tester, _continue);
      final saved = await _readSavedDraft(tester, repository);
      expect(saved!.step, 5);
      expect(saved.firstPhotoPath, '$_ownerId/first.jpg');
      expect(find.byType(SignupMembershipChoiceScreen), findsOneWidget);
      expect(
        photoRequests,
        everyElement(
          predicate<({String method, String path})>(
            (request) =>
                (request.method == 'GET' &&
                    request.path == '/rest/v1/profile_photos') ||
                (request.method == 'POST' &&
                    request.path == '/storage/v1/object/sign/profile-photos'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'completed Guardian checkpoint waits for signing before identity',
    (tester) async {
      await _installLocalSession(tester);
      final wait = Completer<void>();
      signingWait = wait;
      await _mount(
        tester,
        WaliOnboardingFlow(
          signupUserId: _ownerId,
          initialDraft: _liveDraft(
            step: 5,
            firstPhotoPath: '$_ownerId/first.jpg',
            choice: const ZyraSignupMembershipChoice(
              kind: ZyraSignupMembershipKind.one,
            ),
          ),
        ),
      );
      await _flushLocalWork(tester);
      expect(find.byKey(_question), findsOneWidget);
      expect(_photoCard(tester).busy, isTrue);
      expect(_canContinue(tester), isFalse);
      expect(find.byType(InitialIdentityCheckScreen), findsNothing);
      expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
      expect(store.operations, 0);
      wait.complete();
      await _flushLocalWork(tester);
      expect(find.byKey(_question), findsNothing);
      expect(find.byType(InitialIdentityCheckScreen), findsOneWidget);
      expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
      expect(store.operations, 0);
      expect(
        photoRequests.where(
          (request) =>
              request.path ==
              '/storage/v1/object/sign/profile-photos/$_ownerId/first.jpg',
        ),
        hasLength(1),
      );
      expect(savedPhotoRows, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('covered Guardian route denies its late picker result', (
    tester,
  ) async {
    final result = Completer<ZyraPhotoBatchResult>();
    await _mount(
      tester,
      WaliOnboardingFlow(
        signupUserId: _ownerId,
        initialDraft: _liveDraft(),
        photoRunner: (context, remaining, progress) => result.future,
      ),
    );
    _photoCard(tester).onChoose();
    await tester.pump();
    final navigator = Navigator.of(
      tester.element(find.byType(WaliOnboardingFlow)),
    );
    unawaited(
      navigator.push<void>(
        MaterialPageRoute<void>(
          builder: (_) =>
              const Scaffold(key: ValueKey('unrelated_cover_route')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    result.complete(const ZyraPhotoBatchResult.added([_firstUrl]));
    await _flushLocalWork(tester);
    expect(find.byKey(const ValueKey('unrelated_cover_route')), findsOneWidget);
    expect(store.operations, 0);
    expect(httpCalls, 0);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(_question), findsOneWidget);
    expect(_photoCard(tester).photo, isNull);
    expect(_photoCard(tester).busy, isFalse);
    expect(_canContinue(tester), isFalse);
    expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Guardian busy photo cannot navigate back before picker closes', (
    tester,
  ) async {
    final result = Completer<ZyraPhotoBatchResult>();
    await _openDevPhoto(
      tester,
      runner: (context, remaining, progress) => result.future,
    );
    final back = tester
        .widget<OnboardingScaffold>(find.byKey(_question))
        .onSwipeBack;
    expect(back, isNotNull);
    _photoCard(tester).onChoose();
    await tester.pump();
    expect(_photoCard(tester).busy, isTrue);
    back!();
    await tester.pump();
    expect(find.byKey(_question), findsOneWidget);
    expect(find.text('QUESTION 5 OF 5'), findsOneWidget);
    result.complete(const ZyraPhotoBatchResult.cancelled());
    await tester.pumpAndSettle();
    back();
    await tester.pumpAndSettle();
    expect(find.byKey(_question), findsNothing);
    expect(find.text('QUESTION 4 OF 5'), findsOneWidget);
    expect(
      find.text('What is your relationship to the Seeker you support?'),
      findsOneWidget,
    );
    expect(store.operations, 0);
    expect(httpCalls, 0);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'Guardian photo choose remains reachable at ${scale}x on 320 phone',
      (tester) async {
        await _openDevPhoto(tester, size: const Size(320, 568), scale: scale);
        await tester.ensureVisible(find.byKey(_choose));
        await tester.pumpAndSettle();
        expect(find.byKey(_choose).hitTestable(), findsOneWidget);
        expect(
          tester.getSize(find.byKey(_choose)).height,
          greaterThanOrEqualTo(48),
        );
        final semantics = tester.widget<Semantics>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == 'Choose a photo',
          ),
        );
        expect(semantics.excludeSemantics, isTrue);
        expect(semantics.properties.button, isTrue);
        expect(semantics.properties.onTap, isNotNull);
        expect(_canContinue(tester), isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
