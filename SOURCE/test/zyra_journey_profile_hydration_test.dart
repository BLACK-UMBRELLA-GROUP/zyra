// OA-ZYRA-151: linked Journey identity hydration, using synthetic sessions
// and an in-memory HTTP transport only. This does not attest deployed RLS,
// storage moderation, receipt authority, or real-member integration.

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/services/zyra_journey_service.dart';
import 'package:zyra/services/zyra_photo_service.dart';

const _actor = '00000000-0000-4000-8000-000000000901';
const _otherA = '00000000-0000-4000-8000-000000000902';
const _otherB = '00000000-0000-4000-8000-000000000903';
const _matchA = '00000000-0000-4000-8000-000000001901';
const _matchB = '00000000-0000-4000-8000-000000001902';
const _origin = 'https://oa151-hydration.invalid';

Future<void> _session() async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': _actor, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': _actor,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-09T00:00:00Z',
      },
    }),
  );
}

Map<String, Object?> _match(String id, String other, {bool reversed = false}) =>
    {
      'id': id,
      'seeker_a_id': reversed ? other : _actor,
      'seeker_b_id': reversed ? _actor : other,
      'status': 'active',
      'journey_stage': 'salams',
      'suspended_by': null,
      'suspended_at': null,
      'ended_at': null,
    };

Map<String, Object?> _photo(String path, int order) => {
  'storage_path': path,
  'display_order': order,
};

Map<String, Object?> _profile(
  String id, {
  String? surname,
  List<Map<String, Object?>>? photos,
}) => {
  'id': id,
  'first_name': id == _otherA ? 'Synthetic A' : 'Synthetic B',
  'surname_line': surname,
  'location_text': 'Synthetic city',
  'gender': 'female',
  'profile_photos': photos,
};

String _signed(String path) =>
    '$_origin/storage/v1/object/sign/profile-photos/$path?token=synthetic';

class _Transport {
  List<Map<String, Object?>> matches = [_match(_matchA, _otherA)];
  List<Map<String, Object?>> profiles = [_profile(_otherA)];
  List<Map<String, Object?>> pauses = [];
  List<Map<String, Object?>> busy = [];
  final calls = <http.Request>[];
  final signingBatches = <List<String>>[];
  String? failPath;
  List<Map<String, String>> Function(List<String>)? signingResponse;
  bool Function(List<String>)? failSigning;

  http.Response json(http.Request request, Object? value, {int status = 200}) =>
      http.Response(
        jsonEncode(value),
        status,
        request: request,
        headers: {'content-type': 'application/json'},
      );

  Future<http.Response> respond(http.Request request) async {
    calls.add(request);
    final path = request.url.path;
    if (path == failPath) {
      return json(request, {
        'code': '42501',
        'message': 'synthetic-private-backend-message',
        'details': 'synthetic-private-backend-details',
      }, status: 403);
    }
    switch (path) {
      case '/rest/v1/matches':
        return json(request, matches);
      case '/rest/v1/profiles':
        return json(request, profiles);
      case '/rest/v1/rpc/zyra_my_pause_states':
        return json(request, pauses);
      case '/rest/v1/rpc/zyra_journey_busy_flags':
        return json(request, busy);
      case '/rest/v1/rpc/ages_for':
        return json(request, [
          {'id': _otherA, 'age': 28},
          {'id': _otherB, 'age': 29},
        ]);
      case '/storage/v1/object/sign/profile-photos':
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final paths = List<String>.from(body['paths'] as List);
        signingBatches.add(paths);
        if (failSigning?.call(paths) == true) {
          return json(request, {
            'statusCode': '403',
            'error': 'Synthetic signing unavailable',
            'message': 'Synthetic signing unavailable',
          }, status: 403);
        }
        return json(
          request,
          signingResponse?.call(paths) ??
              [
                for (final path in paths)
                  {
                    'path': path,
                    'signedURL':
                        '/object/sign/profile-photos/$path?token=synthetic',
                  },
              ],
        );
      case '/auth/v1/logout':
        return json(request, <String, Object?>{});
      default:
        throw StateError('Unexpected mocked HTTP path: $path');
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Transport transport;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    transport = _Transport();
    await Supabase.initialize(
      url: _origin,
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) => transport.respond(request)),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());
  setUp(() async {
    transport = _Transport();
    SharedPreferences.setMockInitialValues({});
    await _session();
    ZyraPhotoService.clearUrlMemoForSignOut();
    transport.calls.clear();
  });

  test(
    'hydrates surname without imposing Browse eligibility on links',
    () async {
      transport.profiles = [
        {
          ..._profile(_otherA, surname: 'Middle Surname'),
          'is_active': false,
          'profile_complete': false,
        },
      ];
      transport.pauses = [
        {'match_id': _matchA, 'suspended_by': _actor},
      ];
      transport.busy = [
        {'match_id': _matchA, 'in_another_journey': true},
      ];

      final result = await ZyraJourneyService.fetchJourneyMatches(
        statuses: ['active', 'ended'],
      );

      expect(result, hasLength(1));
      final journey = result!.single;
      expect(journey.profile.surnameLine, 'Middle Surname');
      expect(journey.profile.age, 28);
      expect(journey.isSuspended, isTrue);
      expect(journey.inAnotherJourney, isTrue);
      final matchRead = transport.calls.singleWhere(
        (r) => r.url.path == '/rest/v1/matches',
      );
      expect(matchRead.url.queryParameters['status'], 'in.("active","ended")');
      expect(
        matchRead.url.queryParameters['or'],
        '(seeker_a_id.eq.$_actor,seeker_b_id.eq.$_actor)',
      );
      final profileRead = transport.calls.singleWhere(
        (r) => r.url.path == '/rest/v1/profiles',
      );
      expect(
        profileRead.url.queryParameters['select'],
        contains('surname_line'),
      );
      expect(profileRead.url.queryParameters['id'], 'in.("$_otherA")');
      expect(
        profileRead.url.queryParameters.keys,
        unorderedEquals(['select', 'id']),
      );
      expect(
        transport.calls.every((r) => r.method == 'GET' || r.method == 'POST'),
        isTrue,
      );
    },
  );

  test('signs multiple linked profiles in one path-correlated batch', () async {
    transport.matches = [
      _match(_matchA, _otherA),
      _match(_matchB, _otherB, reversed: true),
    ];
    transport.profiles = [
      _profile(
        _otherA,
        photos: [_photo('a/second.jpg', 1), _photo('shared.jpg', 0)],
      ),
      _profile(
        _otherB,
        surname: 'Surname B',
        photos: [_photo('shared.jpg', 1), _photo('b/first.jpg', 0)],
      ),
    ];

    final result = await ZyraJourneyService.fetchJourneyMatches(
      statuses: ['active'],
    );

    expect(transport.signingBatches, [
      ['shared.jpg', 'a/second.jpg', 'b/first.jpg'],
    ]);
    expect(result, hasLength(2));
    expect(result![0].profile.photos, [
      _signed('shared.jpg'),
      _signed('a/second.jpg'),
    ]);
    expect(result[1].profile.photos, [
      _signed('b/first.jpg'),
      _signed('shared.jpg'),
    ]);
    expect(result[1].profile.surnameLine, 'Surname B');
    expect(result[1].matchId, _matchB);
  });

  test('no visible photos remains a neutral linked profile', () async {
    final result = await ZyraJourneyService.fetchJourneyMatches(
      statuses: ['active'],
    );

    expect(result, hasLength(1));
    expect(result!.single.profile.surnameLine, isNull);
    expect(result.single.profile.photos, isEmpty);
    expect(result.single.profile.photoUrl, isEmpty);
    expect(transport.signingBatches, isEmpty);
  });

  test(
    'signing failure does not fabricate a photo or remove a Journey',
    () async {
      transport.profiles = [
        _profile(_otherA, photos: [_photo('a/private.jpg', 0)]),
      ];
      transport.failSigning = (_) => true;

      final result = await ZyraJourneyService.fetchJourneyMatches(
        statuses: ['active'],
      );

      expect(result, hasLength(1));
      expect(result!.single.profile.photos, isEmpty);
      expect(result.single.profile.photoUrl, isEmpty);
      expect(transport.signingBatches, hasLength(2));
    },
  );

  test('short signing response is not assigned to the wrong photo', () async {
    transport.profiles = [
      _profile(
        _otherA,
        photos: [_photo('a/first.jpg', 0), _photo('a/second.jpg', 1)],
      ),
    ];
    transport.signingResponse = (_) => [
      {
        'path': 'a/second.jpg',
        'signedURL': '/object/sign/profile-photos/a/second.jpg?token=synthetic',
      },
    ];

    final result = await ZyraJourneyService.fetchJourneyMatches(
      statuses: ['active'],
    );

    expect(result, hasLength(1));
    expect(result!.single.profile.photos, isEmpty);
    expect(transport.signingBatches, hasLength(2));
  });

  test(
    'partial signing preserves successful path associations and links',
    () async {
      transport.matches = [_match(_matchA, _otherA), _match(_matchB, _otherB)];
      transport.profiles = [
        _profile(
          _otherA,
          photos: [for (var i = 0; i < 39; i++) _photo('a/$i.jpg', i)],
        ),
        _profile(
          _otherB,
          photos: [_photo('b/missing.jpg', 1), _photo('b/visible.jpg', 0)],
        ),
      ];
      transport.failSigning = (paths) => paths.contains('b/missing.jpg');

      final result = await ZyraJourneyService.fetchJourneyMatches(
        statuses: ['active'],
      );

      expect(result, hasLength(2));
      expect(result![0].profile.photos, [
        for (var i = 0; i < 39; i++) _signed('a/$i.jpg'),
      ]);
      expect(result[1].profile.photos, [_signed('b/visible.jpg')]);
      expect(transport.signingBatches.map((batch) => batch.length), [40, 1, 1]);
    },
  );

  for (final path in [
    '/rest/v1/matches',
    '/rest/v1/rpc/zyra_my_pause_states',
    '/rest/v1/rpc/zyra_journey_busy_flags',
    '/rest/v1/profiles',
  ]) {
    test(
      '$path read failure stays unavailable and logs no backend payload',
      () async {
        transport.failPath = path;
        final logs = <String?>[];
        final previousPrint = debugPrint;
        debugPrint = (message, {wrapWidth}) => logs.add(message);
        addTearDown(() => debugPrint = previousPrint);

        final result = await ZyraJourneyService.fetchJourneyMatches(
          statuses: ['active'],
        );

        expect(result, isNull);
        expect(
          logs.join(),
          contains('fetchJourneyMatches failed (PostgrestException)'),
        );
        expect(logs.join(), isNot(contains('synthetic-private-backend')));
        expect(transport.signingBatches, isEmpty);
      },
    );
  }

  test('age failure retains the existing best-effort age fallback', () async {
    transport.failPath = '/rest/v1/rpc/ages_for';

    final result = await ZyraJourneyService.fetchJourneyMatches(
      statuses: ['active'],
    );

    expect(result, hasLength(1));
    expect(result!.single.profile.age, 0);
  });

  test(
    'empty matches is an authoritative empty result with no hydration',
    () async {
      transport.matches = [];

      final result = await ZyraJourneyService.fetchJourneyMatches(
        statuses: ['active'],
      );

      expect(result, isEmpty);
      expect(transport.calls, hasLength(1));
      expect(transport.calls.single.url.path, '/rest/v1/matches');
    },
  );

  test(
    'signed-out callers get an empty result without a backend read',
    () async {
      await supabase.auth.signOut(scope: SignOutScope.local);
      transport.calls.clear();

      final result = await ZyraJourneyService.fetchJourneyMatches(
        statuses: ['active'],
      );

      expect(result, isEmpty);
      expect(transport.calls, isEmpty);
    },
  );
}
