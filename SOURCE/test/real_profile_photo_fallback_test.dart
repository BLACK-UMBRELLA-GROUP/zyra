// OA-ZYRA-304/305: real readers must not invent a stranger's photo or put
// a member identifier into a third-party image URL. Synthetic SDK session
// and allowlisted in-memory HTTP only; no live account, backend or image I/O.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/services/zyra_journey_service.dart';
import 'package:zyra/services/zyra_match_service.dart';
import 'package:zyra/services/zyra_photo_service.dart';

const _actor = '00000000-0000-4000-8000-000000003401';
const _other = '00000000-0000-4000-8000-000000003402';
const _match = '00000000-0000-4000-8000-000000003403';
const _host = 'real-profile-photo-evidence.invalid';
const _photoPath = 'synthetic-member/visible-photo.jpg';
const _signedUrl =
    'https://$_host/storage/v1/object/sign/profile-photos/$_photoPath?token=synthetic';

Future<void> _session() async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': _actor, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-in-memory-only',
      'user': {
        'id': _actor,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-10-18T00:00:00Z',
      },
    }),
  );
}

class _Transport {
  bool single = false;
  List<Map<String, Object?>>? photos;
  bool signingUnavailable = false;
  final calls = <http.Request>[];
  final denied = <String>[];

  http.Response _json(http.Request request, Object? body, {int status = 200}) =>
      http.Response(
        jsonEncode(body),
        status,
        request: request,
        headers: {'content-type': 'application/json'},
      );

  Future<http.Response> respond(http.Request request) async {
    final path = request.url.path;
    final allowed =
        request.url.scheme == 'https' &&
        request.url.host == _host &&
        request.url.port == 443 &&
        request.url.userInfo.isEmpty &&
        request.url.fragment.isEmpty &&
        ((request.method == 'GET' &&
                const [
                  '/rest/v1/matches',
                  '/rest/v1/profiles',
                ].contains(path)) ||
            (request.method == 'POST' &&
                request.url.query.isEmpty &&
                const [
                  '/rest/v1/rpc/ages_for',
                  '/rest/v1/rpc/zyra_my_pause_states',
                  '/rest/v1/rpc/zyra_journey_busy_flags',
                  '/storage/v1/object/sign/profile-photos',
                ].contains(path)));
    if (!allowed) {
      denied.add('${request.method} ${request.url}');
      throw StateError('Unexpected synthetic photo-test transport');
    }
    calls.add(request);
    switch (path) {
      case '/rest/v1/matches':
        final matchRow = <String, Object?>{
          'id': _match,
          'seeker_a_id': _actor,
          'seeker_b_id': _other,
          'status': 'active',
          'journey_stage': 'salams',
          'suspended_by': null,
          'suspended_at': null,
          'ended_at': null,
        };
        return _json(request, single ? matchRow : [matchRow]);
      case '/rest/v1/profiles':
        final profileRow = <String, Object?>{
          'id': _other,
          'first_name': 'Synthetic member',
          'location_text': 'Synthetic city',
          'gender': 'female',
          'profile_photos': photos,
        };
        return _json(request, single ? profileRow : [profileRow]);
      case '/rest/v1/rpc/ages_for':
        return _json(request, [
          {'id': _other, 'age': 29},
        ]);
      case '/rest/v1/rpc/zyra_my_pause_states':
      case '/rest/v1/rpc/zyra_journey_busy_flags':
        return _json(request, <Object>[]);
      case '/storage/v1/object/sign/profile-photos':
        if (signingUnavailable) {
          return _json(request, {
            'statusCode': '403',
            'error': 'Synthetic signing unavailable',
            'message': 'Synthetic signing unavailable',
          }, status: 403);
        }
        return _json(request, [
          {
            'path': _photoPath,
            'signedURL':
                '/object/sign/profile-photos/$_photoPath?token=synthetic',
          },
        ]);
      default:
        throw StateError('Unreachable synthetic photo-test path');
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
      url: 'https://$_host',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
      httpClient: MockClient((request) => transport.respond(request)),
    );
  });
  tearDownAll(() => Supabase.instance.dispose());

  setUp(() async {
    transport = _Transport();
    await _session();
    ZyraPhotoService.clearUrlMemoForSignOut();
    transport.calls.clear();
  });

  tearDown(() {
    expect(transport.denied, isEmpty);
    expect(transport.calls, isNotEmpty);
    expect(transport.calls.every((r) => r.url.host == _host), isTrue);
    expect(
      transport.calls.any((r) => r.url.toString().contains('picsum')),
      isFalse,
    );
  });

  for (final single in [false, true]) {
    final reader = single ? 'Journey refetch' : 'real Matches';
    Future<SeekerProfile?> read() async {
      transport.single = single;
      if (single) {
        return (await ZyraJourneyService.refetchOne(_match, _other))?.profile;
      }
      final profiles = await ZyraMatchService.fetchRealMatches();
      expect(profiles, hasLength(1));
      return profiles.single;
    }

    for (final nullPhotos in [true, false]) {
      test(
        '$reader keeps ${nullPhotos ? 'null' : 'empty'} photos neutral',
        () async {
          transport.photos = nullPhotos ? null : [];

          final profile = await read();

          expect(profile, isNotNull);
          expect(profile!.id, _other);
          expect(profile.firstName, 'Synthetic member');
          expect(profile.age, 29);
          expect(profile.photos, isEmpty);
          expect(profile.photoUrl, isEmpty);
          expect(
            transport.calls.any((r) => r.url.path.startsWith('/storage/')),
            isFalse,
          );
        },
        timeout: const Timeout(Duration(seconds: 10)),
      );
    }

    test(
      '$reader does not replace an unavailable photo with a fake one',
      () async {
        transport.photos = [
          {'storage_path': _photoPath, 'display_order': 0},
        ];
        transport.signingUnavailable = true;

        final profile = await read();

        expect(profile, isNotNull);
        expect(profile!.id, _other);
        expect(profile.photos, isEmpty);
        expect(profile.photoUrl, isEmpty);
        expect(
          transport.calls.where((r) => r.url.path.startsWith('/storage/')),
          hasLength(2),
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    test(
      '$reader preserves a genuinely signed member photo',
      () async {
        transport.photos = [
          {'storage_path': _photoPath, 'display_order': 0},
        ];

        final profile = await read();

        expect(profile, isNotNull);
        expect(profile!.id, _other);
        expect(profile.photos, [_signedUrl]);
        expect(Uri.parse(profile.photoUrl).host, _host);
        final signing = transport.calls.singleWhere(
          (r) => r.url.path == '/storage/v1/object/sign/profile-photos',
        );
        expect(jsonDecode(signing.body)['paths'], [_photoPath]);
        expect(profile.photoUrl, isNot(contains(_other)));
        expect(profile.photoUrl, isNot(contains('picsum')));
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  }
}
