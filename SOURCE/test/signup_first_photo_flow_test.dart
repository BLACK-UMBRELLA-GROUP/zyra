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
// The cache engine's transitive plugin API is used only by this local fixture.
// ignore: depend_on_referenced_packages
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/models/zyra_initial_signup_draft.dart';
import 'package:zyra/models/zyra_identity_verification.dart';
import 'package:zyra/services/zyra_identity_verification_service.dart';
import 'package:zyra/screens/onboarding/account_path_overview_screen.dart';
import 'package:zyra/screens/onboarding/chapter2_flow.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/onboarding/signup_membership_choice_screen.dart';
import 'package:zyra/screens/profile/zyra_photo_batch_flow.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/services/zyra_image_cache.dart';
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

const _ownerId = 'signup-photo-owner';
const _firstUrl =
    'https://test.invalid/storage/v1/object/sign/profile-photos/$_ownerId/first.jpg?token=synthetic';
const _secondUrl =
    'https://test.invalid/storage/v1/object/sign/profile-photos/$_ownerId/second.jpg?token=synthetic';
const _localPhoto =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
const _question = ValueKey('signup_first_photo_question');
const _choose = ValueKey('signup_first_photo_choose');
const _preview = ValueKey('signup_first_photo_preview');
const _continue = ValueKey('onboarding_continue');

Future<void> _tap(WidgetTester tester, Key key) async {
  final target = find.byKey(key);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
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

Future<void> _primeLocalPhotoPaints(WidgetTester tester) async {
  final image = await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(
      base64Decode(_localPhoto.split(',').last),
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  });
  try {
    for (final url in [_firstUrl, _secondUrl]) {
      PaintingBinding.instance.imageCache.putIfAbsent(
        CachedNetworkImageProvider(
          url,
          cacheKey: ZyraImageCache.keyFor(url),
          cacheManager: ZyraImageCache.manager,
        ),
        () => OneFrameImageStreamCompleter(
          Future.value(ImageInfo(image: image!.clone())),
        ),
      );
    }
    await tester.pump();
  } finally {
    image?.dispose();
  }
}

bool _canContinue(WidgetTester tester) =>
    tester.widget<ZyraOnboardingArrowAction>(find.byKey(_continue)).active;

ZyraSignupFirstPhotoCard _photoCard(WidgetTester tester) => tester
    .widget<ZyraSignupFirstPhotoCard>(find.byType(ZyraSignupFirstPhotoCard));

ZyraInitialSignupDraft _liveDraft({String? firstPhotoPath}) =>
    ZyraInitialSignupDraft(
      role: ZyraSignupRole.seeker,
      step: 3,
      firstName: 'Amina',
      lastName: 'Hassan',
      gender: 'female',
      dob: DateTime(1995, 1, 2),
      firstPhotoPath: firstPhotoPath,
    );

// Storage/auth transport is entirely local. Pump the widget zone between real
// asynchronous turns; pumpAndSettle alone is not an HTTP/persistence barrier.
Future<void> _flushLocalWork(WidgetTester tester) async {
  for (var turn = 0; turn < 6; turn++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<ZyraInitialSignupDraft?> _readSavedDraft(
  WidgetTester tester,
  ZyraSignupDraftRepository repository,
) async {
  await _flushLocalWork(tester);
  final saved = await tester.runAsync(
    () => repository.read(_ownerId).timeout(const Duration(seconds: 2)),
  );
  await tester.pumpAndSettle();
  return saved;
}

Future<void> _installLocalSession(WidgetTester tester) async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await tester.runAsync(() async {
    await Supabase.instance.client.auth.setInitialSession(
      jsonEncode({
        'access_token':
            '${part({'alg': 'none'})}.${part({'sub': _ownerId, 'exp': 4102444800})}.synthetic',
        'token_type': 'bearer',
        'refresh_token': 'synthetic-refresh',
        'user': {
          'id': _ownerId,
          'app_metadata': {
            'provider': 'google',
            'providers': ['google'],
          },
          'user_metadata': <String, Object?>{},
          'aud': 'authenticated',
          'email': 'synthetic@example.invalid',
          'created_at': '2026-10-04T00:00:00Z',
        },
      }),
    );
    await ZyraAccountState.synchronize(_ownerId);
  });
}

Future<void> _openDevPhoto(
  WidgetTester tester, {
  ZyraPhotoBatchRunner? runner,
  ZyraIdentityVerificationState? verificationState,
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  ZyraDeveloperAccess.setAuthorizedForTesting(true);
  ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
  ZyraInternalPreviewClient.beginPreview();
  await _mount(
    tester,
    OnboardingFlow(
      devPreview: true,
      welcomeName: 'Amina',
      photoRunner: runner,
      initialVerificationState: verificationState,
    ),
    size: size,
    scale: scale,
  );
  await _tap(tester, const ValueKey('onboarding_stage_continue'));
  for (var index = 0; index < 3; index++) {
    await advanceSignupQuestionFromCode(tester, installPhotoFixture: false);
  }
  expect(find.byKey(_question), findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeSignupStore store;
  late ZyraSignupDraftRepository repository;
  late Directory cacheRoot;
  sqflite.DatabaseFactory? previousDatabaseFactory;
  var cacheInitialized = false;
  var supabaseInitialized = false;
  String? owner;
  var httpCalls = 0;
  var photoReadFails = false;
  final savedPhotoRows = <Map<String, Object?>>[];
  final photoRequests = <({String method, String path})>[];

  void installSixSavedPhotos() {
    savedPhotoRows.addAll([
      for (var index = 0; index < 6; index++)
        {
          'user_id': _ownerId,
          'storage_path':
              '$_ownerId/${index == 0 ? 'first' : 'saved-$index'}.jpg',
          'display_order': index,
          'is_primary': index == 0,
        },
    ]);
  }

  setUpAll(() async {
    cacheRoot = await Directory.systemTemp.createTemp('zyra-first-photo-test-');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // CacheManager eagerly opens its directory/repository even when the actual
    // photo is primed in Flutter's memory cache. Isolate those platform calls;
    // no real member files, image downloads or SQLite writes are involved.
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => cacheRoot.path,
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
    // Initialize this single local repository outside any widget FakeAsync
    // zone, so one case cannot leave a plugin Future queued in the next case.
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
        http.Response json(Object? value, [int status = 200]) => http.Response(
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
          return json({
            'signedURL':
                '${path.substring('/storage/v1'.length)}?token=synthetic',
          });
        }
        return http.Response(
          '{"message":"All service traffic is rejected by this local test"}',
          403,
          headers: {'content-type': 'application/json'},
        );
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
    photoReadFails = false;
    savedPhotoRows.clear();
    photoRequests.clear();
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
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    AppState.instance.resetForAccountChange();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('Seeker requires one photo after DOB and before membership', (
    tester,
  ) async {
    await _openDevPhoto(tester);
    final scaffold = tester.widget<OnboardingScaffold>(find.byKey(_question));
    expect(scaffold.progressLabel, 'QUESTION 4 OF 4');
    expect(scaffold.chapterProgress, 1);
    expect(scaffold.frameContent, isFalse);
    expect(_canContinue(tester), isFalse);
    final staleContinue = tester
        .widget<ZyraOnboardingArrowAction>(find.byKey(_continue))
        .onPressed!;
    staleContinue();
    await tester.pump();
    expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
    expect(store.operations, 0);
    expect(httpCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelled picker keeps the photo question available for retry', (
    tester,
  ) async {
    var calls = 0;
    await _openDevPhoto(
      tester,
      runner: (context, remaining, progress) async {
        calls++;
        expect(remaining, 1);
        return const ZyraPhotoBatchResult.cancelled();
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
  });

  testWidgets(
    'picker error retries successfully without advancing automatically',
    (tester) async {
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
      expect(find.byKey(_preview), findsOneWidget);
      expect(_canContinue(tester), isTrue);
      expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
      await _tap(tester, _continue);
      expect(find.byType(SignupMembershipChoiceScreen), findsOneWidget);
      expect(store.operations, 0);
      expect(httpCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('busy selection blocks duplicate pick and advance callbacks', (
    tester,
  ) async {
    final result = Completer<ZyraPhotoBatchResult>();
    var calls = 0;
    ValueChanged<String?>? reportProgress;
    await _openDevPhoto(
      tester,
      runner: (context, remaining, progress) {
        calls++;
        reportProgress = progress;
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
    reportProgress!('Preparing 1 of 1');
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
    expect(_canContinue(tester), isTrue);
    expect(_photoCard(tester).busy, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary photo is not advanceable until secure save confirms', (
    tester,
  ) async {
    final wait = Completer<void>();
    store.writeWait = wait;
    await _mount(
      tester,
      OnboardingFlow(
        signupUserId: _ownerId,
        initialDraft: _liveDraft(),
        photoRunner: (context, remaining, progress) async =>
            const ZyraPhotoBatchResult.added([_firstUrl]),
      ),
    );
    _photoCard(tester).onChoose();
    await tester.pump();
    expect(_photoCard(tester).busy, isTrue);
    expect(_canContinue(tester), isFalse);
    expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
    wait.complete();
    // A frame-settle is not a persistence barrier. Wait for the repository's
    // serialized confirmation before expecting the flow's finally to clear.
    final saved = await _readSavedDraft(tester, repository);
    expect(_photoCard(tester).busy, isFalse);
    expect(_canContinue(tester), isTrue);
    expect(saved!.firstPhotoPath, '$_ownerId/first.jpg');
    expect(store.values.values.join(), isNot(contains('token=')));
    expect(store.values.values.join(), isNot(contains('https://')));
    expect(httpCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed replacement retains the confirmed first photo and retries',
    (tester) async {
      var calls = 0;
      await _mount(
        tester,
        OnboardingFlow(
          signupUserId: _ownerId,
          initialDraft: _liveDraft(),
          photoRunner: (context, remaining, progress) async =>
              ZyraPhotoBatchResult.added([
                calls++ == 0 ? _firstUrl : _secondUrl,
              ]),
        ),
      );
      await _tap(tester, _choose);
      expect(
        (await _readSavedDraft(tester, repository))!.firstPhotoPath,
        '$_ownerId/first.jpg',
      );
      await tester.pumpAndSettle();
      expect(_photoCard(tester).photo, _firstUrl);
      store.rejectWrite = true;
      await _tap(tester, _choose);
      final afterFailure = await _readSavedDraft(tester, repository);
      expect(_photoCard(tester).photo, _firstUrl);
      expect(_canContinue(tester), isTrue);
      expect(
        find.textContaining("couldn't save your progress securely"),
        findsOneWidget,
      );
      expect(afterFailure!.firstPhotoPath, '$_ownerId/first.jpg');
      store.rejectWrite = false;
      await _tap(tester, _choose);
      final afterRetry = await _readSavedDraft(tester, repository);
      expect(_photoCard(tester).photo, _secondUrl);
      expect(afterRetry!.firstPhotoPath, '$_ownerId/second.jpg');
      expect(httpCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('foreign storage photo cannot become a signup photo', (
    tester,
  ) async {
    await _mount(
      tester,
      OnboardingFlow(
        signupUserId: _ownerId,
        initialDraft: _liveDraft(),
        photoRunner: (context, remaining, progress) async =>
            const ZyraPhotoBatchResult.added([
              'https://test.invalid/storage/v1/object/sign/profile-photos/other-owner/first.jpg?token=synthetic',
            ]),
      ),
    );
    await _tap(tester, _choose);
    expect(_photoCard(tester).photo, isNull);
    expect(_canContinue(tester), isFalse);
    expect(store.operations, 0);
    expect(httpCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'six saved photos reuse the main photo and block a seventh selection',
    (tester) async {
      installSixSavedPhotos();
      await _installLocalSession(tester);
      var picks = 0;
      await _mount(
        tester,
        OnboardingFlow(
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
      expect(_photoCard(tester).busy, isFalse);
      expect(_photoCard(tester).canChoose, isFalse);
      expect(find.byKey(_choose), findsNothing);
      expect(_canContinue(tester), isTrue);
      // Even a retained callback must respect the server-derived six limit.
      _photoCard(tester).onChoose();
      await _flushLocalWork(tester);
      expect(picks, 0);
      expect(savedPhotoRows, hasLength(6));
      await _tap(tester, _continue);
      final saved = await _readSavedDraft(tester, repository);
      expect(find.byType(SignupMembershipChoiceScreen), findsOneWidget);
      expect(saved!.firstPhotoPath, '$_ownerId/first.jpg');
      expect(saved.step, 4);
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
    'saved-photo load failure blocks changes and advance until retry succeeds',
    (tester) async {
      installSixSavedPhotos();
      photoReadFails = true;
      await _installLocalSession(tester);
      var picks = 0;
      await _mount(
        tester,
        OnboardingFlow(
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
      final advance = tester
          .widget<ZyraOnboardingArrowAction>(find.byKey(_continue))
          .onPressed!;
      advance();
      await _flushLocalWork(tester);
      expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
      expect(store.operations, 0);
      final error = tester.widget<ZyraErrorBanner>(
        find.byType(ZyraErrorBanner),
      );
      expect(error.onRetry, isNotNull);
      photoReadFails = false;
      error.onRetry!();
      await _flushLocalWork(tester);
      expect(find.byType(ZyraErrorBanner), findsNothing);
      expect(_photoCard(tester).photo, _firstUrl);
      expect(_photoCard(tester).canChoose, isFalse);
      expect(_canContinue(tester), isTrue);
      expect(picks, 0);
      expect(
        photoRequests.where(
          (request) => request.path == '/rest/v1/profile_photos',
        ),
        hasLength(2),
      );
      expect(savedPhotoRows, hasLength(6));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'six saved photos repair a staged seventh reference to the saved main photo',
    (tester) async {
      installSixSavedPhotos();
      await _installLocalSession(tester);
      var picks = 0;
      await _mount(
        tester,
        OnboardingFlow(
          signupUserId: _ownerId,
          initialDraft: _liveDraft(
            firstPhotoPath: '$_ownerId/staged-seventh.jpg',
          ),
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
      expect(_canContinue(tester), isTrue);
      _photoCard(tester).onChoose();
      await _flushLocalWork(tester);
      expect(picks, 0);
      await _tap(tester, _continue);
      final saved = await _readSavedDraft(tester, repository);
      expect(find.byType(SignupMembershipChoiceScreen), findsOneWidget);
      expect(saved!.firstPhotoPath, '$_ownerId/first.jpg');
      expect(store.values.values.join(), isNot(contains('staged-seventh')));
      expect(savedPhotoRows, hasLength(6));
      expect(
        photoRequests.where(
          (request) =>
              request.path.contains('staged-seventh') ||
              (request.path == '/rest/v1/profile_photos' &&
                  request.method != 'GET'),
        ),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'marker-only photo recovery failure preserves the untouched essentials sequence',
    (tester) async {
      installSixSavedPhotos();
      photoReadFails = true;
      await _installLocalSession(tester);
      await _mount(
        tester,
        const OnboardingFlow(
          signupUserId: _ownerId,
          recoverExistingPhoto: true,
        ),
      );
      await _flushLocalWork(tester);
      await _tap(tester, const ValueKey('onboarding_stage_continue'));
      await _readSavedDraft(tester, repository);
      expect(find.text("What's your name?"), findsOneWidget);
      expect(find.text('QUESTION 1 OF 4'), findsOneWidget);
      expect(find.byKey(_question), findsNothing);
      expect(_canContinue(tester), isFalse);
      final error = tester.widget<ZyraErrorBanner>(
        find.byType(ZyraErrorBanner),
      );
      photoReadFails = false;
      error.onRetry!();
      await _flushLocalWork(tester);
      expect(find.text("What's your name?"), findsOneWidget);
      expect(find.byType(ZyraErrorBanner), findsNothing);
      expect(_canContinue(tester), isFalse);
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_first_name')),
        'Amina',
      );
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_last_name')),
        'Hassan',
      );
      await _tap(tester, _continue);
      await _readSavedDraft(tester, repository);
      expect(find.text("What's your gender?"), findsOneWidget);
      expect(find.text('QUESTION 2 OF 4'), findsOneWidget);
      await _tap(tester, const ValueKey('seeker_gender_female'));
      await _tap(tester, _continue);
      await _readSavedDraft(tester, repository);
      expect(find.text('When were you born?'), findsOneWidget);
      expect(find.text('QUESTION 3 OF 4'), findsOneWidget);
      await tester.tap(find.text('Select date of birth'));
      await tester.pumpAndSettle();
      // The preselected default date is an adult date, not a skipped question.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await _tap(tester, _continue);
      final saved = await _readSavedDraft(tester, repository);
      expect(find.byKey(_question), findsOneWidget);
      expect(find.text('QUESTION 4 OF 4'), findsOneWidget);
      expect(_photoCard(tester).photo, _firstUrl);
      expect(_photoCard(tester).canChoose, isFalse);
      expect(saved!.firstName, 'Amina');
      expect(saved.lastName, 'Hassan');
      expect(saved.gender, 'female');
      expect(saved.dob, isNotNull);
      expect(saved.step, 3);
      expect(saved.firstPhotoPath, '$_ownerId/first.jpg');
      expect(tester.takeException(), isNull);
    },
  );

  for (final invalidateEpoch in [false, true]) {
    testWidgets(
      'pending photo ignores a changed ${invalidateEpoch ? 'account epoch' : 'owner'}',
      (tester) async {
        final result = Completer<ZyraPhotoBatchResult>();
        ValueChanged<String?>? progress;
        await _mount(
          tester,
          OnboardingFlow(
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
          owner = 'different-owner';
        }
        progress!('Late preparation');
        result.complete(const ZyraPhotoBatchResult.added([_firstUrl]));
        await tester.pumpAndSettle();
        expect(_photoCard(tester).photo, isNull);
        expect(find.byType(SignupMembershipChoiceScreen), findsNothing);
        expect(store.operations, 0);
        expect(httpCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'disposed photo question ignores late progress and picker result',
    (tester) async {
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
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'protected preview photo carries through identity into profile setup',
    (tester) async {
      await _openDevPhoto(
        tester,
        verificationState: ZyraIdentityVerificationState(
          result: ZyraIdentityVerificationResult.verified,
          duplicateReview: ZyraDuplicateReviewState.clear,
          consentGranted: true,
          consentVersion: kIdentityVerificationConsentVersion,
          consentRecordedAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          decidedAt: DateTime.now().toUtc(),
        ),
        runner: (context, remaining, progress) async =>
            const ZyraPhotoBatchResult.added([_localPhoto]),
      );
      await _tap(tester, _choose);
      await _tap(tester, _continue);
      await _tap(tester, const ValueKey('signup_membership_basic'));
      await _tap(tester, const ValueKey('signup_membership_continue'));
      expect(find.byKey(const ValueKey('identity_dev_skip')), findsNothing);
      await _tap(tester, const ValueKey('identity-continue'));
      expect(find.byType(SeekerPostIdentityChoiceScreen), findsOneWidget);
      expect(AppState.instance.photos, [_localPhoto]);
      // IDV replaced the Navigator's home route. A different home on the same
      // MaterialApp does not dispose that active route; start a fresh tree.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(AppState.instance.photos, [_localPhoto]);
      await _mount(
        tester,
        const Chapter2Flow(gender: 'male', devPreview: true),
      );
      expect(find.text('Add more photos'), findsOneWidget);
      expect(
        find.textContaining('Your first photo is already here.'),
        findsOneWidget,
      );
      expect(AppState.instance.photos, [_localPhoto]);
      expect(store.operations, 0);
      expect(httpCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'large-text photo action remains reachable with one clear semantic button',
    (tester) async {
      await _openDevPhoto(tester, size: const Size(320, 568), scale: 1.4);
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
