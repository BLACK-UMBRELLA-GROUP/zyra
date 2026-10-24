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
import 'package:zyra/services/zyra_profile_service.dart';

// All HTTP is intercepted. Unsigned fixture JWTs are not credentials and no
// live backend, provider, member account or secure-store plugin is contacted.
const _owner = '00000000-0000-0000-0000-000000000801';
const _other = '00000000-0000-0000-0000-000000000802';
const _firstName = 'Synthetic';
const _surname = 'Hussain';

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
        'created_at': '2026-10-02T00:00:00Z',
      },
    }),
  );
  // Exercise the real same-user ABA epoch, not merely a synthetic ID change.
  await ZyraAccountState.synchronize(userId);
}

Future<void> _sameOwnerAba() async {
  await _session(_other);
  await _session(_owner);
}

class _Store implements ZyraSignupDraftStore {
  final values = <String, String>{};
  final List<String> events;

  _Store(this.events);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    if (key.startsWith('zyra.initial_signup.')) events.add('clear');
    values.remove(key);
  }
}

enum _SurnameReply {
  confirmed,
  zeroRows,
  wrongOwner,
  wrongRole,
  wrongValue,
  error,
}

ZyraInitialSignupDraft _draft(ZyraSignupRole role) => ZyraInitialSignupDraft(
  role: role,
  membershipChoice: const ZyraSignupMembershipChoice(
    kind: ZyraSignupMembershipKind.basic,
  ),
  step: role == ZyraSignupRole.seeker ? 4 : 5,
  firstName: _firstName,
  lastName: _surname,
  gender: 'male',
  dob: DateTime(1995, 2, 3),
  relationship: role == ZyraSignupRole.guardian ? 'Father' : null,
  firstPhotoPath: '$_owner/first.jpg',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final requests = <http.Request>[];
  final events = <String>[];
  late _Store store;
  late ZyraSignupDraftRepository repository;
  Map<String, Object?>? profile;
  var surnameReply = _SurnameReply.confirmed;
  var identityResult = 'verified';
  var publicationSucceeds = true;
  final photoRows = <Map<String, dynamic>>[];
  Future<void> Function()? duringIdentity;
  Future<void> Function()? duringCreate;
  Future<void> Function()? duringSurname;
  Future<void> Function()? duringPublication;
  Future<void> Function()? duringConfirmation;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
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
        final path = request.url.path;
        if (path.endsWith('/zyra_my_identity_verification_state')) {
          events.add('identity');
          await duringIdentity?.call();
          return json({
            'result': identityResult,
            'duplicate_review_required': false,
            'consent_granted': true,
            'consent_version': 'synthetic-consent',
            'consent_recorded_at': '2026-10-02T00:00:00Z',
            'updated_at': '2026-10-02T00:00:00Z',
          });
        }
        if (path.endsWith('/zyra_create_profile')) {
          events.add('create');
          final params = jsonDecode(request.body) as Map<String, dynamic>;
          // The RPC deliberately still has its original four arguments.
          expect(params.keys.toSet(), {
            'p_role',
            'p_first_name',
            'p_gender',
            'p_dob',
          });
          profile = {
            'id': _owner,
            'role': params['p_role'],
            'first_name': params['p_first_name'],
            'gender': params['p_gender'],
            'surname_line': profile?['surname_line'],
          };
          await duringCreate?.call();
          return json({'status': 'created'});
        }
        if (path == '/rest/v1/profiles' && request.method == 'PATCH') {
          events.add('surname');
          final payload = jsonDecode(request.body) as Map<String, dynamic>;
          expect(payload.keys.toList(), ['surname_line']);
          expect(request.url.queryParameters['id'], 'eq.$_owner');
          expect(request.url.queryParameters['select'], contains('id'));
          expect(request.url.queryParameters['select'], contains('role'));
          expect(
            request.url.queryParameters['select'],
            contains('surname_line'),
          );
          await duringSurname?.call();
          if (surnameReply == _SurnameReply.error) {
            return json({'code': '42501', 'message': 'synthetic denial'}, 403);
          }
          if (surnameReply == _SurnameReply.zeroRows || profile == null) {
            return json(null);
          }
          profile = {...profile!, 'surname_line': payload['surname_line']};
          final confirmed = {...profile!};
          switch (surnameReply) {
            case _SurnameReply.wrongOwner:
              confirmed['id'] = _other;
            case _SurnameReply.wrongRole:
              confirmed['role'] = 'admin';
            case _SurnameReply.wrongValue:
              confirmed['surname_line'] = 'Different';
            case _SurnameReply.confirmed:
            case _SurnameReply.zeroRows:
            case _SurnameReply.error:
              break;
          }
          // PATCH maybeSingle requests object JSON, unlike GET's list envelope.
          return json(confirmed);
        }
        if (path.endsWith('/zyra_set_profile_complete')) {
          events.add('publish');
          expect(profile?['surname_line'], _surname);
          expect(photoRows.single['storage_path'], '$_owner/first.jpg');
          expect(jsonDecode(request.body), {'p_complete': true});
          await duringPublication?.call();
          return json({
            'status': publicationSucceeds ? 'published' : 'refused',
          });
        }
        if (path == '/rest/v1/profiles' && request.method == 'GET') {
          events.add('confirm');
          expect(request.url.queryParameters['id'], 'eq.$_owner');
          await duringConfirmation?.call();
          return json(profile == null ? [] : [profile]);
        }
        if (path == '/auth/v1/logout') {
          return http.Response('', 204, request: request);
        }
        if (path.startsWith('/storage/v1/object/sign/profile-photos/')) {
          return json({
            'signedURL':
                '${path.substring('/storage/v1'.length)}?token=synthetic',
          });
        }
        if (path == '/rest/v1/profile_photos') {
          expect(
            request.url.queryParameters['user_id'],
            request.method == 'GET' ? 'eq.$_owner' : isNull,
          );
          if (request.method == 'POST') {
            photoRows.add(
              Map<String, dynamic>.from(jsonDecode(request.body) as Map),
            );
            return json(null, 201);
          }
          return json(photoRows);
        }
        return json({'message': 'unexpected synthetic request'}, 400);
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
    store = _Store(events);
    repository = ZyraSignupDraftRepository(
      store: store,
      backend: 'https://example.supabase.co',
      currentUserId: () => supabase.auth.currentUser?.id,
      isPreview: () => ZyraInternalPreviewClient.isActive,
    );
    ZyraInitialSignupDraftService.setRepositoryForTesting(repository);
    profile = {
      'id': _owner,
      'role': 'seeker',
      'first_name': _firstName,
      'surname_line': null,
    };
    surnameReply = _SurnameReply.confirmed;
    identityResult = 'verified';
    publicationSucceeds = true;
    photoRows.clear();
    duringIdentity = null;
    duringCreate = null;
    duringSurname = null;
    duringPublication = null;
    duringConfirmation = null;
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.clearImagesForTesting = null;
    debugDefaultTargetPlatformOverride = null;
  });

  Future<bool> save(
    String surname, {
    String role = 'seeker',
    int? generation,
  }) => ZyraProfileService.savePublicSurname(
    surname,
    expectedUserId: _owner,
    expectedRole: role,
    expectedGeneration: generation ?? ZyraAccountState.generation,
  );

  void expectPinnedAuthority() {
    final dataRequests = requests.where(
      (request) => request.url.path.startsWith('/rest/v1/'),
    );
    expect(dataRequests, isNotEmpty);
    for (final request in dataRequests) {
      expect(
        request.headers['Authorization'] ?? request.headers['authorization'],
        'Bearer ${_token(_owner)}',
      );
    }
  }

  test(
    'surname save trims and confirms only the owner public-name column',
    () async {
      expect(await save('  $_surname  '), isTrue);
      expect(profile?['surname_line'], _surname);
      expect(events, ['surname']);
      expectPinnedAuthority();
    },
  );

  test(
    'public surname supports apostrophes, hyphens and non-Latin names',
    () async {
      for (final surname in ["O'Neill", 'Al-Hussain', 'حسين', 'عبد الرحمن']) {
        expect(await save(surname), isTrue);
        expect(profile?['surname_line'], surname);
      }
      expect(events, List.filled(4, 'surname'));
      expectPinnedAuthority();
    },
  );

  test('empty or overlong surname cannot issue a write', () async {
    for (final surname in ['', '   ', List.filled(61, 'a').join()]) {
      expect(await save(surname), isFalse);
    }
    expect(requests, isEmpty);
  });

  test('unsupported role cannot issue a surname write', () async {
    expect(await save(_surname, role: 'admin'), isFalse);
    expect(requests, isEmpty);
  });

  test('signed-out surname save never succeeds or dispatches HTTP', () async {
    await supabase.auth.signOut(scope: SignOutScope.local);
    await ZyraAccountState.synchronize(null);
    requests.clear();
    expect(await save(_surname), isFalse);
    expect(requests, isEmpty);
  });

  test(
    'another principal cannot issue the original owner surname write',
    () async {
      await _session(_other);
      requests.clear();
      expect(await save(_surname), isFalse);
      expect(requests, isEmpty);
    },
  );

  test('stale same-owner generation cannot issue a surname write', () async {
    final generation = ZyraAccountState.generation;
    await _sameOwnerAba();
    requests.clear();
    expect(await save(_surname, generation: generation), isFalse);
    expect(requests, isEmpty);
  });

  test('local preview never dispatches a public surname write', () async {
    ZyraInternalPreviewClient.beginPreview();
    expect(await save(_surname), isFalse);
    expect(requests, isEmpty);
  });

  for (final reply in [
    _SurnameReply.zeroRows,
    _SurnameReply.wrongOwner,
    _SurnameReply.wrongRole,
    _SurnameReply.wrongValue,
    _SurnameReply.error,
  ]) {
    test('surname $reply cannot be mistaken for confirmed success', () async {
      surnameReply = reply;
      expect(await save(_surname), isFalse);
      expect(events, ['surname']);
      expectPinnedAuthority();
    });
  }

  test(
    'same-owner ABA during surname response cannot report success',
    () async {
      duringSurname = _sameOwnerAba;
      expect(await save(_surname), isFalse);
      expect(events, ['surname']);
      expectPinnedAuthority();
    },
  );

  test(
    'preview activation during surname response cannot report success',
    () async {
      duringSurname = () async => ZyraInternalPreviewClient.beginPreview();
      expect(await save(_surname), isFalse);
      expect(events, ['surname']);
      expectPinnedAuthority();
    },
  );

  for (final role in ZyraSignupRole.values) {
    test(
      '$role confirms public surname before erasing the signup draft',
      () async {
        final draft = _draft(role);
        profile = null;
        await repository.save(_owner, draft);
        expect(
          await ZyraInitialSignupDraftService.finalize(_owner, draft),
          isNull,
        );
        expect(profile?['first_name'], _firstName);
        expect(profile?['surname_line'], _surname);
        expect(events, [
          'identity',
          'create',
          'surname',
          'confirm',
          if (role == ZyraSignupRole.guardian) 'publish',
          'clear',
        ]);
        expect(store.values.containsKey(repository.keyFor(_owner)), isFalse);
        final intent = await repository.readMembershipIntent(_owner);
        expect(intent?.role, role);
        expect(intent?.choice.kind, ZyraSignupMembershipKind.basic);
        expect(store.values.keys, [repository.membershipIntentKeyFor(_owner)]);
        expectPinnedAuthority();
      },
    );
  }

  test(
    'pending identity still prevents profile and surname creation',
    () async {
      final draft = _draft(ZyraSignupRole.seeker);
      await repository.save(_owner, draft);
      identityResult = 'pending';
      expect(
        await ZyraInitialSignupDraftService.finalize(_owner, draft),
        isNotNull,
      );
      expect(events, ['identity']);
      expect(store.values, isNotEmpty);
    },
  );

  for (final role in ZyraSignupRole.values) {
    test(
      '$role failed surname retains draft and cannot publish or admit',
      () async {
        final draft = _draft(role);
        await repository.save(_owner, draft);
        surnameReply = _SurnameReply.error;
        expect(
          await ZyraInitialSignupDraftService.finalize(_owner, draft),
          isNotNull,
        );
        expect(events, ['identity', 'create', 'surname']);
        expect((await repository.read(_owner))?.lastName, _surname);
        expect(store.values, isNotEmpty);
        expectPinnedAuthority();
      },
    );
  }

  test(
    'failed Guardian publication preserves the confirmed surname and draft',
    () async {
      final draft = _draft(ZyraSignupRole.guardian);
      await repository.save(_owner, draft);
      publicationSucceeds = false;
      expect(
        await ZyraInitialSignupDraftService.finalize(_owner, draft),
        isNotNull,
      );
      expect(events, ['identity', 'create', 'surname', 'confirm', 'publish']);
      expect(profile?['surname_line'], _surname);
      expect(store.values, isNotEmpty);
    },
  );

  test(
    'retry after creation and failed surname confirms before erasure',
    () async {
      final draft = _draft(ZyraSignupRole.seeker);
      await repository.save(_owner, draft);
      surnameReply = _SurnameReply.error;
      expect(
        await ZyraInitialSignupDraftService.finalize(_owner, draft),
        isNotNull,
      );
      expect(store.values, isNotEmpty);
      surnameReply = _SurnameReply.confirmed;
      expect(
        await ZyraInitialSignupDraftService.finalize(_owner, draft),
        isNull,
      );
      expect(events, [
        'identity',
        'create',
        'surname',
        'identity',
        'create',
        'surname',
        'confirm',
        'clear',
      ]);
      expect(store.values.containsKey(repository.keyFor(_owner)), isFalse);
      expect(
        (await repository.readMembershipIntent(_owner))?.choice.kind,
        ZyraSignupMembershipKind.basic,
      );
      expect(profile?['surname_line'], _surname);
    },
  );

  for (final mismatchedField in ['id', 'role', 'first_name', 'surname_line']) {
    test(
      'final $mismatchedField mismatch preserves the signup draft',
      () async {
        final draft = _draft(ZyraSignupRole.seeker);
        await repository.save(_owner, draft);
        duringConfirmation = () async {
          profile = {...profile!, mismatchedField: 'wrong'};
        };
        expect(
          await ZyraInitialSignupDraftService.finalize(_owner, draft),
          isNotNull,
        );
        expect(events, ['identity', 'create', 'surname', 'confirm']);
        expect(store.values, isNotEmpty);
      },
    );
  }

  for (final boundary in [
    'identity',
    'create',
    'surname',
    'publish',
    'confirm',
  ]) {
    test(
      'Guardian same-owner ABA at $boundary never clears or admits',
      () async {
        final draft = _draft(ZyraSignupRole.guardian);
        await repository.save(_owner, draft);
        switch (boundary) {
          case 'identity':
            duringIdentity = _sameOwnerAba;
          case 'create':
            duringCreate = _sameOwnerAba;
          case 'surname':
            duringSurname = _sameOwnerAba;
          case 'publish':
            duringPublication = _sameOwnerAba;
          case 'confirm':
            duringConfirmation = _sameOwnerAba;
        }
        expect(
          await ZyraInitialSignupDraftService.finalize(_owner, draft),
          isNotNull,
        );
        expect(events, isNot(contains('clear')));
        expect(store.values, isNotEmpty);
        if (['identity', 'create', 'surname', 'confirm'].contains(boundary)) {
          expect(events, isNot(contains('publish')));
        }
        expectPinnedAuthority();
      },
    );
  }

  test('preview finalization cannot read or mutate member data', () async {
    final draft = _draft(ZyraSignupRole.seeker);
    await repository.save(_owner, draft);
    ZyraInternalPreviewClient.beginPreview();
    expect(
      await ZyraInitialSignupDraftService.finalize(_owner, draft),
      isNotNull,
    );
    expect(requests, isEmpty);
    expect(store.values, isNotEmpty);
  });
}
