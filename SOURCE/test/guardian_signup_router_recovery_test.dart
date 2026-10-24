import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/main.dart';
import 'package:zyra/models/zyra_initial_signup_draft.dart';
import 'package:zyra/models/zyra_signup_membership_choice.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/wali/wali_home_shell.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_session_router.dart';
import 'package:zyra/state/app_state.dart';

import 'initial_signup_draft_test.dart' show FakeSignupStore;

// Routing only: widgets are returned, never mounted. HTTP and protected store
// are synthetic, with no provider, native storage or live backend contacted.
const _owner = '00000000-0000-0000-0000-000000000821';
const _other = '00000000-0000-0000-0000-000000000822';
const _backend = 'https://example.supabase.co';
const _marker = '{"version":1,"pending":true}';

Future<void> _session(String userId) async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': userId, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': userId,
        'app_metadata': {
          'provider': 'google',
          'providers': ['google'],
        },
        'user_metadata': {
          'full_name': 'Provider Display Name',
          'gender': 'female',
        },
        'aud': 'authenticated',
        'created_at': '2026-10-12T00:00:00Z',
      },
    }),
  );
  await ZyraAccountState.synchronize(userId);
}

class _Store extends FakeSignupStore {
  final reads = <String>[];
  String? failingKey;
  Future<void> Function(String key)? duringRead;
  @override
  Future<String?> read(String key) async {
    reads.add(key);
    await duringRead?.call(key);
    if (key == failingKey) {
      throw StateError('Synthetic protected store unavailable.');
    }
    return super.read(key);
  }
}

ZyraInitialSignupDraft _draft(ZyraSignupRole role) => ZyraInitialSignupDraft(
  role: role,
  step: role == ZyraSignupRole.guardian ? 5 : 4,
  firstName: 'Saved',
  lastName: 'Family',
  gender: 'male',
  dob: DateTime(1985, 2, 3),
  relationship: role == ZyraSignupRole.guardian ? 'Father' : null,
  firstPhotoPath: '$_owner/first.jpg',
  membershipChoice: const ZyraSignupMembershipChoice(
    kind: ZyraSignupMembershipKind.basic,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Store store;
  late ZyraSignupDraftRepository repository;
  final requests = <String>[];
  Map<String, Object?>? profile;
  var profileFails = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: _backend,
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        final path = request.url.path;
        requests.add(path);
        http.Response json(Object? value, [int status = 200]) => http.Response(
          jsonEncode(value),
          status,
          request: request,
          headers: {'content-type': 'application/json'},
        );
        if (path == '/rest/v1/profiles') {
          expect(request.method, 'GET');
          expect(request.url.queryParameters['id'], 'eq.$_owner');
          expect(
            request.url.queryParameters['select'],
            isNot(contains('date_of_birth')),
          );
          if (profileFails) {
            return json({'message': 'synthetic profile unavailable'}, 503);
          }
          return json(profile == null ? [] : [profile]);
        }
        if (path.endsWith('/zyra_my_identity_verification_state')) {
          return json({
            'result': 'verified',
            'duplicate_review_required': false,
            'consent_granted': true,
            'consent_version': 'synthetic-consent',
            'consent_recorded_at': '2026-10-12T00:00:00Z',
            'updated_at': '2026-10-12T00:00:00Z',
          });
        }
        return json({'message': 'unexpected synthetic routing request'}, 400);
      }),
    );
    await ZyraLocalPrefs.init();
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() async {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await _session(_owner);
    ZyraDeveloperAccess.configureAuthorizationForTesting(
      variant: ZyraAppVariant.production,
      currentUser: () => supabase.auth.currentUser,
      refreshSession: () async => supabase.auth.currentUser,
      founderIdentityMatches: (_) => false,
    );
    ZyraLocalPrefs.setCachedRole('wali');
    store = _Store();
    repository = ZyraSignupDraftRepository(
      store: store,
      backend: _backend,
      currentUserId: () => supabase.auth.currentUser?.id,
      isPreview: () => ZyraInternalPreviewClient.isActive,
    );
    ZyraInitialSignupDraftService.setRepositoryForTesting(repository);
    profile = {
      'role': 'wali',
      'first_name': 'Server Display',
      'surname_line': 'Server Family',
      'gender': 'female',
      'location_text': 'Server City',
    };
    profileFails = false;
    requests.clear();
  });
  tearDown(() {
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraInternalPreviewClient.finishSignOut();
    ZyraSessionRouter.setReadTimeoutForTesting(null);
    ZyraAccountState.clearImagesForTesting = null;
    debugDefaultTargetPlatformOverride = null;
  });

  String markerKey(ZyraSignupRole role) => role == ZyraSignupRole.guardian
      ? repository.pendingGuardianFinalizationKeyFor(_owner)
      : repository.pendingSeekerFinalizationKeyFor(_owner);
  Future<Widget> resolve() {
    store.reads.clear();
    requests.clear();
    return ZyraSessionRouter.resolveHome();
  }

  void expectBothRead() {
    expect(
      store.reads,
      contains(repository.pendingSeekerFinalizationKeyFor(_owner)),
    );
    expect(
      store.reads,
      contains(repository.pendingGuardianFinalizationKeyFor(_owner)),
    );
  }

  void expectUnhydrated() {
    expect(AppState.instance.hydrated, isFalse);
    expect(AppState.instance.name, isNull);
    expect(AppState.instance.gender, isNull);
    expect(AppState.instance.photos, isEmpty);
  }

  Future<void> expectClosed(Matcher error) async {
    final before = Map<String, String>.of(store.values);
    await expectLater(resolve(), throwsA(error));
    expectUnhydrated();
    expect(store.values, before);
    // The pinned Postgrest transport retries a 503 three times. Every
    // attempt must remain the same profile read; no hydration/admission call.
    expect(requests, List.filled(profileFails ? 4 : 1, '/rest/v1/profiles'));
  }

  for (final existingProfile in [false, true]) {
    test(
      'Guardian marker re-enters setup with existing profile=$existingProfile',
      () async {
        if (!existingProfile) profile = null;
        await repository.beginPendingGuardianFinalization(_owner);
        final route = await resolve() as WaliOnboardingFlow;
        expect(route.signupUserId, _owner);
        expect(route.recoverExistingPhoto, isTrue);
        expect(route.initialDraft, isNull);
        expect(route.initialVerificationState, isNull);
        expectUnhydrated();
        expectBothRead();
        expect(store.values, {markerKey(ZyraSignupRole.guardian): _marker});
        expect(requests, ['/rest/v1/profiles']);
      },
    );
  }

  test(
    'legacy Guardian step four retains answers and membership at photo question',
    () async {
      final legacy = {
        ..._draft(ZyraSignupRole.guardian).toJson(),
        'version': 4,
        'step': 4,
        'firstPhotoPath': null,
      };
      store.values[repository.keyFor(_owner)] = jsonEncode(legacy);
      await repository.saveMembershipIntent(
        _owner,
        const ZyraSignupMembershipIntent(
          role: ZyraSignupRole.guardian,
          choice: ZyraSignupMembershipChoice(
            kind: ZyraSignupMembershipKind.basic,
          ),
        ),
      );
      final before = Map<String, String>.of(store.values);
      final route = await resolve() as WaliOnboardingFlow;
      final restored = route.initialDraft!;
      expect(route.recoverExistingPhoto, isTrue);
      expect(restored.toJson()['version'], 5);
      expect(restored.step, 4);
      expect(restored.questionCount, 5);
      expect(restored.awaitsVerification, isFalse);
      expect(restored.firstPhotoPath, isNull);
      expect(restored.firstName, 'Saved');
      expect(restored.lastName, 'Family');
      expect(restored.gender, 'male');
      expect(restored.dob, DateTime(1985, 2, 3));
      expect(restored.relationship, 'Father');
      expect(restored.membershipChoice?.kind, ZyraSignupMembershipKind.basic);
      expect(
        (await repository.readMembershipIntent(_owner))?.choice.kind,
        ZyraSignupMembershipKind.basic,
      );
      expect(store.values, before);
      expectBothRead();
      expectUnhydrated();
    },
  );

  test(
    'saved Guardian verification draft keeps owner and existing photo recovery',
    () async {
      await repository.save(_owner, _draft(ZyraSignupRole.guardian));
      await repository.beginPendingGuardianFinalization(_owner);
      final route = await resolve() as WaliOnboardingFlow;
      expect(
        route.initialDraft!.toJson(),
        _draft(ZyraSignupRole.guardian).toJson(),
      );
      expect(route.signupUserId, _owner);
      expect(route.recoverExistingPhoto, isTrue);
      expect(route.initialVerificationState?.allowsApp, isTrue);
      expectBothRead();
      expectUnhydrated();
    },
  );

  test(
    'existing Seeker marker still selects its ordinary recovery flow',
    () async {
      profile = {...profile!, 'role': 'seeker'};
      await repository.beginPendingSeekerFinalization(_owner);
      final route = await resolve() as OnboardingFlow;
      expect(route.signupUserId, _owner);
      expect(route.recoverExistingPhoto, isTrue);
      expect(route.initialDraft, isNull);
      expectBothRead();
      expectUnhydrated();
    },
  );

  for (final role in ZyraSignupRole.values) {
    for (final malformed in {
      'version': '{"version":2,"pending":true}',
      'pending': '{"version":1,"pending":false}',
      'extra field': '{"version":1,"pending":true,"name":"Injected"}',
    }.entries) {
      test(
        '$role malformed ${malformed.key} marker fails before selecting a valid Guardian draft',
        () async {
          await repository.save(_owner, _draft(ZyraSignupRole.guardian));
          store.values[markerKey(role)] = malformed.value;
          await expectClosed(isA<FormatException>());
        },
      );
    }
    test(
      '$role marker storage failure cannot open a cached Guardian shell',
      () async {
        store.failingKey = markerKey(role);
        await expectClosed(isA<StateError>());
      },
    );
    test('$role marker cannot select an opposite-role saved draft', () async {
      profile = null;
      final opposite = role == ZyraSignupRole.guardian
          ? ZyraSignupRole.seeker
          : ZyraSignupRole.guardian;
      await repository.save(_owner, _draft(opposite));
      store.values[markerKey(role)] = _marker;
      await expectClosed(isA<StateError>());
      expectBothRead();
    });
  }

  for (final withDraft in [false, true]) {
    test(
      'both pending roles conflict even with valid draft=$withDraft',
      () async {
        if (withDraft) {
          await repository.save(_owner, _draft(ZyraSignupRole.guardian));
        }
        store.values[markerKey(ZyraSignupRole.guardian)] = _marker;
        store.values[markerKey(ZyraSignupRole.seeker)] = _marker;
        await expectClosed(isA<StateError>());
        expectBothRead();
      },
    );
  }

  for (final withDraft in [false, true]) {
    test(
      'Guardian recovery cannot reuse a Seeker profile draft=$withDraft',
      () async {
        profile = {...profile!, 'role': 'seeker'};
        if (withDraft) {
          await repository.save(_owner, _draft(ZyraSignupRole.guardian));
        }
        store.values[markerKey(ZyraSignupRole.guardian)] = _marker;
        await expectClosed(isA<StateError>());
      },
    );
  }

  for (final role in ZyraSignupRole.values) {
    for (final replacement in ['owner', 'epoch', 'ABA']) {
      test(
        '$replacement during $role marker read rejects the stale route',
        () async {
          store.values[markerKey(ZyraSignupRole.guardian)] = _marker;
          store.duringRead = (key) async {
            if (key != markerKey(role)) return;
            if (replacement == 'epoch') {
              ZyraAccountState.resetForTesting();
              await ZyraAccountState.synchronize(_owner);
            } else {
              await _session(_other);
              if (replacement == 'ABA') await _session(_owner);
            }
          };
          await expectClosed(isA<StateError>());
        },
      );
    }
  }

  for (final recovery in ['marker', 'draft', 'malformed', 'unavailable']) {
    test(
      'profile failure cannot bypass protected Guardian $recovery recovery',
      () async {
        profileFails = true;
        if (recovery == 'draft') {
          await repository.save(_owner, _draft(ZyraSignupRole.guardian));
        }
        if (recovery == 'marker') {
          store.values[markerKey(ZyraSignupRole.guardian)] = _marker;
        }
        if (recovery == 'malformed') {
          store.values[markerKey(ZyraSignupRole.guardian)] = '{';
        }
        if (recovery == 'unavailable') {
          store.failingKey = markerKey(ZyraSignupRole.guardian);
        }
        await expectClosed(
          recovery == 'malformed'
              ? isA<FormatException>()
              : recovery == 'unavailable'
              ? isA<StateError>()
              : isA<PostgrestException>(),
        );
      },
    );
  }

  test(
    'profile failure retains cached Guardian fallback after both markers prove empty',
    () async {
      profileFails = true;
      expect(await resolve(), isA<WaliHomeShell>());
      expectBothRead();
      expect(store.values, isEmpty);
      expectUnhydrated();
    },
  );

  test(
    'same-owner ABA during fallback Guardian marker read cannot open cached shell',
    () async {
      profileFails = true;
      store.duringRead = (key) async {
        if (key != markerKey(ZyraSignupRole.guardian)) return;
        await _session(_other);
        await _session(_owner);
      };
      await expectClosed(isA<StateError>());
    },
  );
}
