// HAPTICS/BRIEFS/HAPTICS_BRIEF_2026-10-30.md §3; no visual master required.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/main.dart';
import 'package:zyra/models/zyra_initial_signup_draft.dart';
import 'package:zyra/models/zyra_signup_membership_choice.dart';
import 'package:zyra/screens/auth/role_selection_screen.dart';
import 'package:zyra/screens/onboarding/account_path_overview_screen.dart';
import 'package:zyra/screens/onboarding/identity_verification_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_auth.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/services/zyra_identity_verification_service.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_session_router.dart';
import 'package:zyra/services/zyra_photo_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

// All HTTP is intercepted. These unsigned synthetic JWTs are test fixtures,
// never credentials, and no live backend/account is read or written.
const _a = '00000000-0000-0000-0000-000000000701';
const _b = '00000000-0000-0000-0000-000000000702';

String _token(String userId) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.${part({'sub': userId, 'exp': 4102444800})}.synthetic';
}

Future<void> _sessionWithMetadata(
  String userId,
  Map<String, Object?> appMetadata,
) => supabase.auth.setInitialSession(
  jsonEncode({
    'access_token': _token(userId),
    'token_type': 'bearer',
    'refresh_token': 'synthetic-refresh',
    'user': {
      'id': userId,
      'app_metadata': appMetadata,
      'user_metadata': <String, Object?>{},
      'aud': 'authenticated',
      'email': 'synthetic@example.invalid',
      'created_at': '2026-08-29T00:00:00Z',
    },
  }),
);

Future<void> _session(String userId) async {
  await _sessionWithMetadata(userId, {
    'provider': 'google',
    'providers': ['google'],
  });
  await ZyraAccountState.synchronize(userId);
}

class _Store implements ZyraSignupDraftStore {
  bool discardMarkerWrite = false;
  bool rejectMarkerWrite = false;
  bool rejectMarkerDelete = false;
  final values = <String, String>{};
  bool failRead = false;
  @override
  Future<String?> read(String key) async {
    if (failRead) throw StateError('synthetic storage unavailable');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (key.startsWith('zyra.signup_pending_seeker.')) {
      if (rejectMarkerWrite) throw StateError('Synthetic marker unavailable.');
      if (discardMarkerWrite) return;
    }
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (rejectMarkerDelete && key.startsWith('zyra.signup_pending_seeker.')) {
      throw StateError('Synthetic marker erasure unavailable.');
    }
    values.remove(key);
  }
}

ZyraInitialSignupDraft _draft(ZyraSignupRole role) => ZyraInitialSignupDraft(
  role: role,
  step: role == ZyraSignupRole.seeker ? 4 : 5,
  firstName: 'Synthetic',
  lastName: 'Surname',
  gender: 'male',
  dob: DateTime(1995, 2, 3),
  relationship: role == ZyraSignupRole.guardian ? 'Father' : null,
  firstPhotoPath: '$_a/first.jpg',
  membershipChoice: const ZyraSignupMembershipChoice(
    kind: ZyraSignupMembershipKind.basic,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Store store;
  late ZyraSignupDraftRepository repository;
  Map<String, Object?>? profile;
  String? result;
  var profileFails = false;
  var stateFails = false;
  var publishSucceeds = true;
  var creates = 0;
  var publications = 0;
  final photoRows = <Map<String, dynamic>>[];
  var photoInsertFails = false;
  var photoSignFails = false;
  var photoReadbackMissing = false;
  Future<void> Function()? duringPhotoSign;
  Future<void> Function()? duringPhotoInsert;
  Future<void> Function()? duringCreate;
  Future<void> Function()? duringState;
  Future<void> Function()? duringConsent;
  Future<void> Function()? duringDelete;
  final authorities = <String>[];
  final authLogoutScopes = <String?>[];
  var googleSignOuts = 0;

  Map<String, Object?> state() => {
    'result': result,
    'duplicate_review': 'clear',
    'consent_granted': true,
    'consent_version': 'synthetic-consent',
    'consent_recorded_at': '2026-09-13T06:00:00Z',
    'updated_at': '2026-09-13T06:00:00Z',
  };

  void installRepository() {
    repository = ZyraSignupDraftRepository(
      store: store,
      backend: 'https://example.supabase.co',
      currentUserId: () => supabase.auth.currentUser?.id,
      isPreview: () => false,
    );
    ZyraInitialSignupDraftService.setRepositoryForTesting(repository);
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        http.Response json(Object? value, [int status = 200]) => http.Response(
          jsonEncode(value),
          status,
          request: request,
          headers: {'content-type': 'application/json'},
        );
        final path = request.url.path;
        if (path.startsWith('/storage/v1/object/sign/profile-photos/')) {
          authorities.add(
            request.headers['Authorization'] ??
                request.headers['authorization'] ??
                'missing',
          );
          await duringPhotoSign?.call();
          if (photoSignFails) {
            return json({'message': 'synthetic missing photo'}, 404);
          }
          return json({
            'signedURL':
                '${path.substring('/storage/v1'.length)}?token=synthetic',
          });
        }
        if (path == '/rest/v1/profile_photos') {
          authorities.add(
            request.headers['Authorization'] ??
                request.headers['authorization'] ??
                'missing',
          );
          if (request.method == 'POST') {
            await duringPhotoInsert?.call();
            if (photoInsertFails) {
              return json({'message': 'synthetic refused photo'}, 503);
            }
            photoRows.add(
              Map<String, dynamic>.from(jsonDecode(request.body) as Map),
            );
            return json(null, 201);
          }
          expect(request.method, 'GET');
          expect(request.url.queryParameters['user_id'], 'eq.$_a');
          return json(photoReadbackMissing ? [] : photoRows);
        }
        if (path == '/rest/v1/profiles') {
          if (profileFails) return json({'message': 'synthetic failure'}, 503);
          if (request.method == 'PATCH') {
            final payload = jsonDecode(request.body) as Map<String, dynamic>;
            if (profile != null) {
              profile = {...profile!, 'surname_line': payload['surname_line']};
            }
            return json(profile);
          }
          return json(profile == null ? [] : [profile]);
        }
        if (path.endsWith('/zyra_my_identity_verification_state')) {
          authorities.add(
            request.headers['Authorization'] ??
                request.headers['authorization'] ??
                'missing',
          );
          if (stateFails) return json({'message': 'synthetic failure'}, 503);
          await duringState?.call();
          return json(result == null ? null : state());
        }
        if (path.endsWith('/zyra_record_identity_verification_consent')) {
          authorities.add(
            request.headers['Authorization'] ??
                request.headers['authorization'] ??
                'missing',
          );
          await duringConsent?.call();
          return json(state());
        }
        if (path.endsWith(
          '/zyra_delete_my_unstarted_identity_verification_attempt',
        )) {
          authorities.add(
            request.headers['Authorization'] ??
                request.headers['authorization'] ??
                'missing',
          );
          await duringDelete?.call();
          return json(true);
        }
        if (path.endsWith('/zyra_create_profile')) {
          creates++;
          authorities.add(
            request.headers['Authorization'] ??
                request.headers['authorization'] ??
                'missing',
          );
          final params = jsonDecode(request.body) as Map<String, dynamic>;
          profile = {
            'id': _a,
            'role': params['p_role'],
            'first_name': 'Synthetic',
            'gender': 'male',
          };
          await duringCreate?.call();
          return json({'status': 'created'});
        }
        if (path.endsWith('/zyra_set_profile_complete')) {
          publications++;
          authorities.add(
            request.headers['Authorization'] ??
                request.headers['authorization'] ??
                'missing',
          );
          return json({'status': publishSucceeds ? 'published' : 'refused'});
        }
        if (path == '/auth/v1/logout') {
          authLogoutScopes.add(request.url.queryParameters['scope']);
          return http.Response('', 204, request: request);
        }
        if (path.startsWith('/auth/')) {
          return json({'message': 'unexpected auth HTTP'}, 403);
        }
        return json([]);
      }),
    );
    await ZyraLocalPrefs.init();
  });
  tearDownAll(() => Supabase.instance.dispose());

  setUp(() async {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await _session(_a);
    ZyraDeveloperAccess.configureAuthorizationForTesting(
      variant: ZyraAppVariant.production,
      currentUser: () => supabase.auth.currentUser,
      refreshSession: () async => supabase.auth.currentUser,
      founderIdentityMatches: (_) => false,
    );
    store = _Store();
    installRepository();
    profile = null;
    result = 'pending';
    profileFails = false;
    stateFails = false;
    publishSucceeds = true;
    creates = 0;
    publications = 0;
    photoRows.clear();
    photoInsertFails = false;
    photoSignFails = false;
    photoReadbackMissing = false;
    duringPhotoSign = null;
    duringPhotoInsert = null;
    duringCreate = null;
    duringState = null;
    duringConsent = null;
    duringDelete = null;
    authorities.clear();
    authLogoutScopes.clear();
    googleSignOuts = 0;
    ZyraAuth.setGoogleSignOutForTesting(() async => googleSignOuts++);
    ZyraLocalPrefs.setCachedRole(null);
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraAccountState.clearImagesForTesting = null;
    debugDefaultTargetPlatformOverride = null;
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAuth.setGoogleSignOutForTesting(null);
  });

  test(
    'provider detection accepts app_metadata.provider without identities',
    () async {
      await _sessionWithMetadata(_a, {'provider': 'Google'});
      expect(supabase.auth.currentUser?.identities ?? const [], isEmpty);
      expect(ZyraAuth.linkedProviders, contains('google'));
    },
  );

  test(
    'provider detection accepts app_metadata.providers without identities',
    () async {
      await _sessionWithMetadata(_a, {
        'providers': ['GOOGLE'],
      });
      expect(supabase.auth.currentUser?.identities ?? const [], isEmpty);
      expect(ZyraAuth.linkedProviders, contains('google'));
    },
  );

  for (final role in ZyraSignupRole.values) {
    test(
      '$role old draft with existing profile resumes required surname',
      () async {
        profile = {
          'id': _a,
          'role': role == ZyraSignupRole.seeker ? 'seeker' : 'wali',
          'first_name': 'Synthetic',
          'gender': 'male',
        };
        final legacy = _draft(role).toJson()
          ..['version'] = 1
          ..['step'] = role == ZyraSignupRole.seeker ? 3 : 4
          ..['firstPhotoPath'] = null
          ..remove('lastName');
        final key = repository.keyFor(_a);
        store.values[key] = jsonEncode(legacy);
        final route = await ZyraSessionRouter.resolveHome();
        final restored = role == ZyraSignupRole.seeker
            ? (route as OnboardingFlow).initialDraft!
            : (route as WaliOnboardingFlow).initialDraft!;
        expect(restored.step, 0);
        expect(restored.firstName, 'Synthetic');
        expect(restored.lastName, isNull);
        expect(restored.gender, 'male');
        expect(restored.dob, DateTime(1995, 2, 3));
        expect(
          restored.relationship,
          role == ZyraSignupRole.guardian ? 'Father' : null,
        );
        expect(store.values[key], jsonEncode(legacy));
        expect(creates, 0);
        expect(publications, 0);
      },
    );
    test(
      '$role cold-start reconstructs saved verification checkpoint',
      () async {
        await repository.save(_a, _draft(role));
        installRepository(); // discard the in-memory repository, retain storage
        final route = await ZyraSessionRouter.resolveHome();
        if (role == ZyraSignupRole.seeker) {
          expect(route, isA<OnboardingFlow>());
          final flow = route as OnboardingFlow;
          expect(flow.initialDraft!.awaitsVerification, isTrue);
          expect(flow.initialVerificationState!.result.name, 'pending');
          expect(flow.signupUserId, _a);
        } else {
          expect(route, isA<WaliOnboardingFlow>());
          final flow = route as WaliOnboardingFlow;
          expect(flow.initialDraft!.awaitsVerification, isTrue);
          expect(flow.initialVerificationState!.result.name, 'pending');
          expect(flow.signupUserId, _a);
        }
        expect(creates, 0);
      },
    );
  }

  test(
    'legacy missing draft resumes server verification, not page one',
    () async {
      expect(
        await ZyraSessionRouter.resolveHome(),
        isA<InitialIdentityCheckScreen>(),
      );
      expect(store.values, isEmpty);
    },
  );
  test('legacy verified asks honestly for never-saved details', () async {
    result = 'verified';
    final route = await ZyraSessionRouter.resolveHome() as RoleSelectionScreen;
    expect(route.recoveryNotice, contains('did not save'));
    expect(creates, 0);
  });
  test('no draft and no server attempt is genuine new setup', () async {
    result = null;
    final route = await ZyraSessionRouter.resolveHome() as RoleSelectionScreen;
    expect(route.recoveryNotice, isNull);
  });
  testWidgets(
    'personal Google signup exit cancel preserves its session and protected draft',
    (tester) async {
      const draft = ZyraInitialSignupDraft(
        role: ZyraSignupRole.seeker,
        showIntroduction: true,
      );
      final draftKey = repository.keyFor(_a);
      store.values[draftKey] = jsonEncode(draft.toJson());
      installRepository();
      final savedDraft = store.values[draftKey];

      await tester.pumpWidget(const MaterialApp(home: RoleSelectionScreen()));
      await tester.pumpAndSettle();

      expect(supabase.auth.currentUser?.id, _a);
      expect(supabase.auth.currentUser?.appMetadata['provider'], 'google');
      expect(
        find.byKey(const ValueKey('onboarding_account_exit')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('onboarding_account_exit')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('onboarding_account_exit')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('onboarding_account_exit_cancel')),
      );
      await tester.pumpAndSettle();

      expect(supabase.auth.currentUser?.id, _a);
      expect(store.values[draftKey], savedDraft);
      expect(authLogoutScopes, isEmpty);
      expect(googleSignOuts, 0);
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    },
  );
  testWidgets('signup account exit never signs out a replacement principal', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RoleSelectionScreen()));
    await tester.pumpAndSettle();
    await tester.runAsync(() => _session(_b));

    await tester.ensureVisible(
      find.byKey(const ValueKey('onboarding_account_exit')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboarding_account_exit')));
    await tester.pumpAndSettle();

    expect(
      find.text('Your account changed. Close and reopen ZYRA.'),
      findsOneWidget,
    );
    expect(supabase.auth.currentUser?.id, _b);
    expect(authLogoutScopes, isEmpty);
    expect(googleSignOuts, 0);
    expect(
      find.byKey(const ValueKey('onboarding_account_exit_confirm')),
      findsNothing,
    );
    debugDefaultTargetPlatformOverride = null;
  });
  testWidgets('Guardian role choice preserves a working back route', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RoleSelectionScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('role-select-guardian')),
    );
    tester
        .widget<InkWell>(find.byKey(const ValueKey('role-select-guardian')))
        .onTap!();
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(find.byType(GuardianOnboardingOverviewScreen), findsNothing);
    await tester.tap(find.byKey(const ValueKey('role-choice-continue')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GuardianOnboardingOverviewScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });
  test('failed state lookup cannot use a cached member shell', () async {
    await repository.save(_a, _draft(ZyraSignupRole.seeker));
    ZyraLocalPrefs.setCachedRole('seeker');
    stateFails = true;
    await expectLater(ZyraSessionRouter.resolveHome(), throwsA(anything));
  });
  test(
    'failed draft read on an existing row cannot use cached member shell',
    () async {
      profile = {'id': _a, 'role': 'wali'};
      ZyraLocalPrefs.setCachedRole('wali');
      store.failRead = true;
      await expectLater(ZyraSessionRouter.resolveHome(), throwsA(anything));
    },
  );
  test(
    'enabled IDV fuse cannot be skipped by a failed profile lookup',
    () async {
      profileFails = true;
      ZyraLocalPrefs.setCachedRole('seeker');
      await expectLater(ZyraSessionRouter.resolveHome(), throwsA(anything));
    },
    skip: !const bool.fromEnvironment('ZYRA_IDV_ENFORCE_EXISTING_ACCOUNTS'),
  );
  test(
    'fresh pending result denies finalization despite former UI verified state',
    () async {
      final draft = _draft(ZyraSignupRole.seeker);
      await repository.save(_a, draft);
      expect(
        await ZyraInitialSignupDraftService.finalize(_a, draft),
        isNotNull,
      );
      expect(creates, 0);
      expect(await repository.read(_a), isNotNull);
    },
  );
  test(
    'verified Seeker finalization confirms row before deleting exact draft',
    () async {
      final draft = _draft(ZyraSignupRole.seeker);
      await repository.save(_a, draft);
      result = 'verified';
      expect(await ZyraInitialSignupDraftService.finalize(_a, draft), isNull);
      expect(creates, 1);
      expect(publications, 0);
      expect(await repository.read(_a), isNull);
      expect(await repository.readPendingSeekerFinalization(_a), isFalse);
      expect(photoRows.single['storage_path'], '$_a/first.jpg');
      expect(AppState.instance.photos, hasLength(1));
      expect(
        (await repository.readMembershipIntent(_a))?.choice.kind,
        ZyraSignupMembershipKind.basic,
      );
      expect(
        authorities.every((header) => header == 'Bearer ${_token(_a)}'),
        isTrue,
      );
    },
  );
  for (final failure in ['sign', 'insert', 'readback']) {
    test(
      'first-photo $failure failure keeps draft and pending retry marker',
      () async {
        final draft = _draft(ZyraSignupRole.seeker);
        await repository.save(_a, draft);
        result = 'verified';
        photoSignFails = failure == 'sign';
        photoInsertFails = failure == 'insert';
        photoReadbackMissing = failure == 'readback';
        expect(
          await ZyraInitialSignupDraftService.finalize(_a, draft),
          isNotNull,
        );
        expect(profile, isNotNull);
        expect(await repository.read(_a), isNotNull);
        expect(await repository.readPendingSeekerFinalization(_a), isTrue);
        photoSignFails = false;
        photoInsertFails = false;
        photoReadbackMissing = false;
        expect(await ZyraInitialSignupDraftService.finalize(_a, draft), isNull);
        expect(photoRows, hasLength(1));
        expect(await repository.read(_a), isNull);
        expect(await repository.readPendingSeekerFinalization(_a), isFalse);
      },
    );
  }
  for (final failure in ['write', 'confirmation']) {
    test(
      'pending marker $failure failure stops before profile creation',
      () async {
        final draft = _draft(ZyraSignupRole.seeker);
        await repository.save(_a, draft);
        result = 'verified';
        store.rejectMarkerWrite = failure == 'write';
        store.discardMarkerWrite = failure == 'confirmation';
        expect(
          await ZyraInitialSignupDraftService.finalize(_a, draft),
          isNotNull,
        );
        expect(creates, 0);
        expect(photoRows, isEmpty);
        expect(await repository.read(_a), isNotNull);
      },
    );
  }
  test(
    'failed marker erasure never grants account-ready continuation',
    () async {
      final draft = _draft(ZyraSignupRole.seeker);
      await repository.save(_a, draft);
      result = 'verified';
      store.rejectMarkerDelete = true;
      expect(
        await ZyraInitialSignupDraftService.finalize(_a, draft),
        isNotNull,
      );
      expect(await repository.read(_a), isNull);
      expect(await repository.readPendingSeekerFinalization(_a), isTrue);
      final route = await ZyraSessionRouter.resolveHome() as OnboardingFlow;
      expect(route.signupUserId, _a);
      expect(route.initialDraft, isNull);
      expect(route.recoverExistingPhoto, isTrue);
    },
  );
  for (final existingRow in [false, true]) {
    test(
      'pending first-photo finalization survives sign-out with profile=$existingRow',
      () async {
        final draft = _draft(ZyraSignupRole.seeker);
        await repository.save(_a, draft);
        await repository.beginPendingSeekerFinalization(_a);
        if (existingRow) {
          profile = {
            'id': _a,
            'role': 'seeker',
            'first_name': 'Synthetic',
            'gender': 'male',
          };
        }
        await repository.signOut(_a, () async {});
        await _session(_b);
        expect(await repository.readPendingSeekerFinalization(_b), isFalse);
        await _session(_a);
        final route = await ZyraSessionRouter.resolveHome() as OnboardingFlow;
        expect(route.signupUserId, _a);
        expect(route.initialDraft, isNull);
        expect(route.recoverExistingPhoto, isTrue);
        expect(await repository.read(_a), isNull);
        expect(await repository.readMembershipIntent(_a), isNull);
        expect(await repository.readPendingSeekerFinalization(_a), isTrue);
      },
    );
  }
  test(
    'attachment retry preserves all saved photos and primary/order',
    () async {
      photoRows.add({
        'user_id': _a,
        'storage_path': '$_a/existing.jpg',
        'is_primary': true,
        'display_order': 0,
      });
      final generation = ZyraAccountState.generation;
      Future<List<String>?> attach() =>
          ZyraPhotoService.ensureSignupFirstPhotoConfirmed(
            '$_a/first.jpg',
            expectedUserId: _a,
            expectedGeneration: generation,
          );
      expect(await attach(), hasLength(2));
      expect(await attach(), hasLength(2));
      expect(photoRows, hasLength(2));
      expect(photoRows.first, {
        'user_id': _a,
        'storage_path': '$_a/existing.jpg',
        'is_primary': true,
        'display_order': 0,
      });
      expect(photoRows.last['is_primary'], isFalse);
      expect(photoRows.last['display_order'], 1);
    },
  );
  test('first-photo attachment never creates a seventh photo', () async {
    for (var index = 0; index < 6; index++) {
      photoRows.add({
        'user_id': _a,
        'storage_path': '$_a/existing$index.jpg',
        'is_primary': index == 0,
        'display_order': index,
      });
    }
    expect(
      await ZyraPhotoService.ensureSignupFirstPhotoConfirmed(
        '$_a/first.jpg',
        expectedUserId: _a,
        expectedGeneration: ZyraAccountState.generation,
      ),
      isNull,
    );
    expect(photoRows, hasLength(6));
  });
  for (final boundary in ['sign', 'insert']) {
    test(
      'first-photo $boundary same-user ABA keeps recovery and never admits',
      () async {
        final draft = _draft(ZyraSignupRole.seeker);
        await repository.save(_a, draft);
        result = 'verified';
        Future<void> aba() async {
          await _session(_b);
          await _session(_a);
        }

        if (boundary == 'sign') duringPhotoSign = aba;
        if (boundary == 'insert') duringPhotoInsert = aba;
        expect(
          await ZyraInitialSignupDraftService.finalize(_a, draft),
          isNotNull,
        );
        expect(await repository.read(_a), isNotNull);
        expect(await repository.readPendingSeekerFinalization(_a), isTrue);
        expect(
          authorities.every((header) => header == 'Bearer ${_token(_a)}'),
          isTrue,
        );
      },
    );
  }
  test(
    'signup references reject capabilities, traversal, foreign owner/backend',
    () async {
      String signed(String suffix) =>
          'https://example.supabase.co/storage/v1/object/sign/profile-photos/$suffix?token=synthetic';
      expect(
        ZyraPhotoService.signupStoragePathFor(
          signed('$_a/first.jpg'),
          expectedUserId: _a,
        ),
        '$_a/first.jpg',
      );
      for (final unsafe in [
        signed('$_b/first.jpg'),
        signed('$_a/%2e%2e.jpg'),
        signed(
          '$_a/first.jpg',
        ).replaceFirst('example.supabase.co', 'other.invalid'),
        'data:image/jpeg;base64,unsafe',
        '$_a/first.jpg',
      ]) {
        expect(
          ZyraPhotoService.signupStoragePathFor(unsafe, expectedUserId: _a),
          isNull,
        );
      }
      expect(
        await ZyraPhotoService.signupPhotoUrl(
          '$_b/first.jpg',
          expectedUserId: _a,
          expectedGeneration: ZyraAccountState.generation,
        ),
        isNull,
      );
      expect(authorities, isEmpty);
    },
  );
  test('stale picker guard cancels before processing or upload', () async {
    final outcome = await ZyraPhotoService.saveReviewedPhoto(
      Uint8List(0),
      localPreview: false,
      canProceed: () => false,
    );
    expect(outcome.outcome, ZyraPhotoOutcome.cancelled);
    expect(authorities, isEmpty);
    expect(photoRows, isEmpty);
  });
  test(
    'Guardian failed publication retains a resumable checkpoint despite created row',
    () async {
      final draft = _draft(ZyraSignupRole.guardian);
      await repository.save(_a, draft);
      result = 'verified';
      publishSucceeds = false;
      expect(
        await ZyraInitialSignupDraftService.finalize(_a, draft),
        isNotNull,
      );
      expect(profile, isNotNull);
      expect(publications, 1);
      installRepository();
      final route = await ZyraSessionRouter.resolveHome() as WaliOnboardingFlow;
      expect(route.initialDraft!.awaitsVerification, isTrue);
      expect(await repository.read(_a), isNotNull);
    },
  );
  test(
    'Guardian account switch during create never publishes the next account',
    () async {
      final draft = _draft(ZyraSignupRole.guardian);
      await repository.save(_a, draft);
      result = 'verified';
      duringCreate = () => _session(_b);
      expect(
        await ZyraInitialSignupDraftService.finalize(_a, draft),
        isNotNull,
      );
      expect(creates, 1);
      expect(publications, 0);
      expect(store.values, isNotEmpty);
      expect(
        authorities.every((header) => header == 'Bearer ${_token(_a)}'),
        isTrue,
      );
    },
  );
  test(
    'A to B to A during result read uses only A request authority',
    () async {
      final draft = _draft(ZyraSignupRole.seeker);
      await repository.save(_a, draft);
      duringState = () async {
        await _session(_b);
        await _session(_a);
      };
      expect(
        await ZyraInitialSignupDraftService.finalize(_a, draft),
        isNotNull,
      );
      expect(authorities, ['Bearer ${_token(_a)}']);
      expect(creates, 0);
    },
  );
  test('different account cannot finalize or recover original draft', () async {
    final draft = _draft(ZyraSignupRole.seeker);
    await repository.save(_a, draft);
    await _session(_b);
    expect(await repository.read(_b), isNull);
    expect(await ZyraInitialSignupDraftService.finalize(_a, draft), isNotNull);
    expect(creates, 0);
    expect(authorities, isEmpty);
  });

  test(
    'verified Guardian confirms publication before clearing draft',
    () async {
      final draft = _draft(ZyraSignupRole.guardian);
      await repository.save(_a, draft);
      result = 'verified';
      expect(await ZyraInitialSignupDraftService.finalize(_a, draft), isNull);
      expect(creates, 1);
      expect(publications, 1);
      expect(await repository.read(_a), isNull);
      expect(
        (await repository.readMembershipIntent(_a))?.role,
        ZyraSignupRole.guardian,
      );
      expect(
        authorities.every((header) => header == 'Bearer ${_token(_a)}'),
        isTrue,
      );
    },
  );
  test(
    'consent and deletion use only the explicitly bound principal',
    () async {
      expect(
        await ZyraIdentityVerificationService.recordConsent(
          granted: true,
          expectedUserId: _a,
        ),
        isNotNull,
      );
      expect(
        await ZyraIdentityVerificationService.deleteMyUnstartedAttempt(
          expectedUserId: _a,
        ),
        isTrue,
      );
      expect(authorities, ['Bearer ${_token(_a)}', 'Bearer ${_token(_a)}']);
    },
  );
  test('consent A to B to A remains bound to A', () async {
    duringConsent = () async {
      await _session(_b);
      await _session(_a);
    };
    expect(
      await ZyraIdentityVerificationService.recordConsent(
        granted: true,
        expectedUserId: _a,
      ),
      isNotNull,
    );
    expect(authorities, ['Bearer ${_token(_a)}']);
  });
  test('changed actor after consent cannot reuse its result', () async {
    duringConsent = () => _session(_b);
    expect(
      await ZyraIdentityVerificationService.recordConsent(
        granted: true,
        expectedUserId: _a,
      ),
      isNull,
    );
    expect(authorities, ['Bearer ${_token(_a)}']);
  });
  test('changed actor after deletion cannot continue old screen', () async {
    duringDelete = () => _session(_b);
    expect(
      await ZyraIdentityVerificationService.deleteMyUnstartedAttempt(
        expectedUserId: _a,
      ),
      isFalse,
    );
    expect(authorities, ['Bearer ${_token(_a)}']);
  });
  test(
    'changed actor after result read throws instead of returning foreign state',
    () async {
      duringState = () => _session(_b);
      await expectLater(
        ZyraIdentityVerificationService.fetchMyState(expectedUserId: _a),
        throwsStateError,
      );
      expect(authorities, ['Bearer ${_token(_a)}']);
    },
  );
  test('mismatched actor cannot send bound read, consent or delete', () async {
    await _session(_b);
    await expectLater(
      ZyraIdentityVerificationService.fetchMyState(expectedUserId: _a),
      throwsStateError,
    );
    expect(
      await ZyraIdentityVerificationService.recordConsent(
        granted: true,
        expectedUserId: _a,
      ),
      isNull,
    );
    expect(
      await ZyraIdentityVerificationService.deleteMyUnstartedAttempt(
        expectedUserId: _a,
      ),
      isFalse,
    );
    expect(authorities, isEmpty);
  });
  // This sign-out case intentionally runs last: GoTrue local sign-out closes
  // the synthetic session used by this file, just as it closes the device
  // session in production.
  testWidgets(
    'personal Google signup exit confirms one local logout and clears only its draft',
    (tester) async {
      const draft = ZyraInitialSignupDraft(
        role: ZyraSignupRole.seeker,
        showIntroduction: true,
      );
      final draftKey = repository.keyFor(_a);
      final otherDraftKey = repository.keyFor(_b);
      store.values[draftKey] = jsonEncode(draft.toJson());
      store.values[otherDraftKey] = 'other-account-draft-sentinel';
      installRepository();

      await tester.pumpWidget(const MaterialApp(home: RoleSelectionScreen()));
      await tester.pumpAndSettle();

      expect(supabase.auth.currentUser?.id, _a);
      expect(supabase.auth.currentUser?.appMetadata['provider'], 'google');
      expect(supabase.auth.currentUser?.identities ?? const [], isEmpty);
      expect(ZyraAuth.linkedProviders, contains('google'));

      await tester.ensureVisible(
        find.byKey(const ValueKey('onboarding_account_exit')),
      );
      await tester.pumpAndSettle();
      // Standard haptic wrappers expose a void tap, not an async flight.
      // Observe the real handoff and preserve every account/draft assertion.
      await tester.tap(find.byKey(const ValueKey('onboarding_account_exit')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('onboarding_account_exit_confirm')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Signing out…'), findsOneWidget);
      for (
        var frame = 0;
        frame < 80 && find.byType(WelcomeScreen).evaluate().isEmpty;
        frame++
      ) {
        await tester.pump(const Duration(milliseconds: 20));
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      }
      expect(
        find.byType(WelcomeScreen),
        findsOneWidget,
        reason: 'Public exit cleanup and handoff completed',
      );
      await tester.pumpAndSettle();

      expect(authLogoutScopes, ['local']);
      expect(googleSignOuts, 1);
      expect(supabase.auth.currentUser, isNull);
      expect(store.values.containsKey(draftKey), isFalse);
      expect(store.values[otherDraftKey], 'other-account-draft-sentinel');
      expect(find.byType(RoleSelectionScreen), findsNothing);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
