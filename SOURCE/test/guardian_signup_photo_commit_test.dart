import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/main.dart';
import 'package:zyra/models/zyra_initial_signup_draft.dart';
import 'package:zyra/models/zyra_signup_membership_choice.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';

// Mock HTTP, unsigned synthetic sessions and an in-memory protected-store
// boundary only. No live backend, provider or secure-storage plugin is used.
const _owner = '00000000-0000-0000-0000-000000000811';
const _other = '00000000-0000-0000-0000-000000000812';
const _photo = '$_owner/first.jpg';
const _backend = 'https://example.supabase.co';
const _url =
    '$_backend/storage/v1/object/sign/profile-photos/$_photo?token=synthetic';

String _token(String userId) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${part({'alg': 'none'})}.${part({'sub': userId, 'exp': 4102444800})}.synthetic';
}

Future<void> _session(String userId) async {
  await supabase.auth.setInitialSession(
    jsonEncode({
      'access_token': _token(userId),
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': userId,
        'app_metadata': {
          'provider': 'google',
          'providers': ['google'],
        },
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'email': 'synthetic@example.invalid',
        'created_at': '2026-10-12T00:00:00Z',
      },
    }),
  );
  await ZyraAccountState.synchronize(userId);
}

class _Store implements ZyraSignupDraftStore {
  final values = <String, String>{};
  final List<String> events;
  _Store(this.events);
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    if (key.startsWith('zyra.signup_pending_guardian.')) events.add('pending');
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (key.startsWith('zyra.initial_signup.')) events.add('clear');
    if (key.startsWith('zyra.signup_pending_guardian.')) {
      events.add('clear-marker');
    }
    values.remove(key);
  }
}

enum _Failure {
  none,
  signing,
  missingObject,
  rows,
  insert,
  readbackMissing,
  readback,
  resign,
}

ZyraInitialSignupDraft _draft({String path = _photo}) => ZyraInitialSignupDraft(
  role: ZyraSignupRole.guardian,
  step: 5,
  firstName: 'Synthetic',
  lastName: 'Hussain',
  gender: 'male',
  dob: DateTime(1995, 2, 3),
  relationship: 'Father',
  firstPhotoPath: path,
  membershipChoice: const ZyraSignupMembershipChoice(
    kind: ZyraSignupMembershipKind.basic,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <http.Request>[];
  final events = <String>[];
  final photoRows = <Map<String, dynamic>>[];
  final hooks = <String, Future<void> Function()>{};
  late _Store store;
  late ZyraSignupDraftRepository repository;
  Map<String, Object?>? profile;
  var failure = _Failure.none;
  var identity = 'verified';
  var publicationSucceeds = true;
  var reads = 0;
  var signs = 0;

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
        requests.add(request);
        http.Response json(Object? value, [int status = 200]) => http.Response(
          jsonEncode(value),
          status,
          request: request,
          headers: {'content-type': 'application/json'},
        );
        Future<void> boundary(String event) async {
          events.add(event);
          await hooks[event]?.call();
        }

        http.Response denied([int status = 403]) =>
            json({'code': '42501', 'message': 'synthetic refusal'}, status);
        final path = request.url.path;
        if (path.endsWith('/zyra_my_identity_verification_state')) {
          events.add('identity');
          return json({
            'result': identity,
            'duplicate_review_required': false,
            'consent_granted': true,
            'consent_version': 'synthetic-consent',
            'consent_recorded_at': '2026-10-12T00:00:00Z',
            'updated_at': '2026-10-12T00:00:00Z',
          });
        }
        if (path.endsWith('/zyra_create_profile')) {
          events.add('create');
          expect(
            jsonDecode(
              store.values[repository.pendingGuardianFinalizationKeyFor(
                _owner,
              )]!,
            ),
            {'version': 1, 'pending': true},
          );
          expect(jsonDecode(request.body), {
            'p_role': 'wali',
            'p_first_name': 'Synthetic',
            'p_gender': 'male',
            'p_dob': '1995-02-03',
          });
          profile = {
            'id': _owner,
            'role': 'wali',
            'first_name': 'Synthetic',
            'surname_line': profile?['surname_line'],
          };
          return json({'status': 'created'});
        }
        if (path == '/rest/v1/profiles') {
          expect(request.url.queryParameters['id'], 'eq.$_owner');
          if (request.method == 'PATCH') {
            events.add('surname');
            expect(jsonDecode(request.body), {'surname_line': 'Hussain'});
            profile = {...profile!, 'surname_line': 'Hussain'};
            return json(profile);
          }
          events.add('profile');
          return json(profile == null ? [] : [profile]);
        }
        if (path.startsWith('/storage/v1/object/sign/profile-photos/')) {
          expect(path, '/storage/v1/object/sign/profile-photos/$_photo');
          final event = ++signs == 1 ? 'sign' : 'resign';
          await boundary(event);
          if ((event == 'sign' && failure == _Failure.signing) ||
              (event == 'resign' && failure == _Failure.resign)) {
            return denied();
          }
          if (failure == _Failure.missingObject) return denied(404);
          return json({
            'signedURL': '/object/sign/profile-photos/$_photo?token=synthetic',
          });
        }
        if (path == '/rest/v1/profile_photos') {
          if (request.method == 'POST') {
            expect(jsonDecode(request.body), {
              'user_id': _owner,
              'storage_path': _photo,
              'display_order': 0,
              'is_primary': true,
            });
            await boundary('insert');
            if (failure == _Failure.insert) return denied();
            photoRows.add(
              Map<String, dynamic>.from(jsonDecode(request.body) as Map),
            );
            return json(null, 201);
          }
          expect(request.method, 'GET');
          expect(request.url.queryParameters['user_id'], 'eq.$_owner');
          final event = ++reads == 1 ? 'rows' : 'readback';
          await boundary(event);
          if ((event == 'rows' && failure == _Failure.rows) ||
              (event == 'readback' && failure == _Failure.readback)) {
            return denied(500);
          }
          if (event == 'readback' && failure == _Failure.readbackMissing) {
            return json([]);
          }
          return json(photoRows);
        }
        if (path.endsWith('/zyra_set_profile_complete')) {
          events.add('publish');
          expect(events, contains('resign'));
          expect(photoRows.single['storage_path'], _photo);
          expect(profile?['surname_line'], 'Hussain');
          expect(jsonDecode(request.body), {'p_complete': true});
          return json({
            'status': publicationSucceeds ? 'published' : 'refused',
          });
        }
        if (path == '/auth/v1/logout') {
          return http.Response('', 204, request: request);
        }
        return denied(400);
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
    requests.clear();
    events.clear();
    photoRows.clear();
    hooks.clear();
    profile = null;
    failure = _Failure.none;
    identity = 'verified';
    publicationSucceeds = true;
    store = _Store(events);
    repository = ZyraSignupDraftRepository(
      store: store,
      backend: _backend,
      currentUserId: () => supabase.auth.currentUser?.id,
      isPreview: () => ZyraInternalPreviewClient.isActive,
    );
    ZyraInitialSignupDraftService.setRepositoryForTesting(repository);
    await repository.save(_owner, _draft());
  });
  tearDown(() {
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraInternalPreviewClient.finishSignOut();
    ZyraAccountState.clearImagesForTesting = null;
    debugDefaultTargetPlatformOverride = null;
  });

  Future<String?> finalize({ZyraInitialSignupDraft? draft}) {
    reads = 0;
    signs = 0;
    return ZyraInitialSignupDraftService.finalize(_owner, draft ?? _draft());
  }

  void expectRetained() {
    expect(store.values[repository.keyFor(_owner)], isNotNull);
    expect(
      jsonDecode(
        store.values[repository.pendingGuardianFinalizationKeyFor(_owner)]!,
      ),
      {'version': 1, 'pending': true},
    );
    expect(events, isNot(contains('clear')));
    expect(events, isNot(contains('clear-marker')));
    expect(AppState.instance.photos, isEmpty);
  }

  void expectPinnedRequests() {
    for (final request in requests.where(
      (r) => !r.url.path.startsWith('/auth/'),
    )) {
      expect(
        request.headers['Authorization'] ?? request.headers['authorization'],
        'Bearer ${_token(_owner)}',
      );
    }
  }

  test(
    'owned photo readback precedes Guardian publication and erasure',
    () async {
      expect(_draft().toJson()['version'], 5);
      expect(await finalize(), isNull);
      expect(events, [
        'identity',
        'pending',
        'create',
        'surname',
        'profile',
        'sign',
        'rows',
        'insert',
        'readback',
        'resign',
        'publish',
        'clear',
        'clear-marker',
      ]);
      expect(photoRows, hasLength(1));
      expect(AppState.instance.photos, [_url]);
      expect(await repository.read(_owner), isNull);
      expect(await repository.readPendingGuardianFinalization(_owner), isFalse);
      expect(store.values.keys, [repository.membershipIntentKeyFor(_owner)]);
      expect(
        (await repository.readMembershipIntent(_owner))?.choice.kind,
        ZyraSignupMembershipKind.basic,
      );
      expectPinnedRequests();
    },
  );

  for (final rejected in _Failure.values.where(
    (value) => value != _Failure.none,
  )) {
    test(
      '$rejected keeps Guardian retry without publication or erasure',
      () async {
        failure = rejected;
        expect(await finalize(), isNotNull);
        expect(events, isNot(contains('publish')));
        expectRetained();
        failure = _Failure.none;
        expect(await finalize(), isNull);
        expect(photoRows, hasLength(1));
        expect(AppState.instance.photos, [_url]);
        expect(
          await repository.readPendingGuardianFinalization(_owner),
          isFalse,
        );
        expectPinnedRequests();
      },
    );
  }

  test('publication retry reuses the confirmed photo row', () async {
    publicationSucceeds = false;
    expect(await finalize(), isNotNull);
    expectRetained();
    publicationSucceeds = true;
    expect(await finalize(), isNull);
    expect(photoRows, hasLength(1));
    expect(
      requests.where(
        (r) => r.method == 'POST' && r.url.path == '/rest/v1/profile_photos',
      ),
      hasLength(1),
    );
    expect(AppState.instance.photos, [_url]);
  });

  test('wrong-owner photo rejects before any HTTP or retry marker', () async {
    expect(await finalize(draft: _draft(path: '$_other/first.jpg')), isNotNull);
    expect(requests, isEmpty);
    expect(await repository.readPendingGuardianFinalization(_owner), isFalse);
    expect((await repository.read(_owner))?.firstPhotoPath, _photo);
  });

  test('pending identity cannot create or publish a Guardian', () async {
    identity = 'pending';
    expect(await finalize(), isNotNull);
    expect(events, ['identity']);
    expect(await repository.readPendingGuardianFinalization(_owner), isFalse);
    expect(await repository.read(_owner), isNotNull);
  });

  for (final boundary in ['sign', 'rows', 'insert', 'readback', 'resign']) {
    for (final aba in [false, true]) {
      test(
        '${aba ? 'same-owner ABA' : 'owner replacement'} at $boundary blocks publication',
        () async {
          hooks[boundary] = () async {
            await _session(_other);
            if (aba) await _session(_owner);
          };
          expect(await finalize(), isNotNull);
          expect(events, isNot(contains('publish')));
          expectRetained();
          expectPinnedRequests();
        },
      );
    }
  }

  test(
    'explicit sign-out erases form but retains only opaque Guardian retry',
    () async {
      failure = _Failure.signing;
      expect(await finalize(), isNotNull);
      expectRetained();
      await repository.signOut(
        _owner,
        () => supabase.auth.signOut(scope: SignOutScope.local),
      );
      await ZyraAccountState.synchronize(null);
      expect(store.values.keys, [
        repository.pendingGuardianFinalizationKeyFor(_owner),
      ]);
      expect(jsonDecode(store.values.values.single), {
        'version': 1,
        'pending': true,
      });
      await _session(_owner);
      expect(await repository.readPendingGuardianFinalization(_owner), isTrue);
      expect(await repository.read(_owner), isNull);
    },
  );
}
