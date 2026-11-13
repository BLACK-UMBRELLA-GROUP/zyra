import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/services/zyra_discovery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const firstId = '00000000-0000-0000-0000-000000000821';
  const secondId = '00000000-0000-0000-0000-000000000822';
  final requests = <http.Request>[];
  var photoRowMode = false;
  String? firstPath;
  var signFirst = false;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        http.Response json(Object body) => http.Response(
          jsonEncode(body),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
        if (request.url.path == '/rest/v1/profiles') {
          return json([
            {
              'id': firstId,
              'first_name': 'Aaliyah',
              'surname_line': null,
              'location_text': 'Leeds, UK',
              'gender': 'female',
              'profile_photos': photoRowMode
                  ? [
                      {
                        'storage_path': 'synthetic/unsigned-photo.jpg',
                        'display_order': 0,
                      },
                    ]
                  : firstPath != null
                  ? [
                      {'storage_path': firstPath, 'display_order': 0},
                      {
                        'storage_path': 'synthetic/later.jpg',
                        'display_order': 1,
                      },
                    ]
                  : <Object>[],
            },
            {
              'id': secondId,
              'first_name': 'Maryam',
              'surname_line': null,
              'location_text': 'Bristol, UK',
              'gender': 'female',
              'profile_photos': <Object>[],
            },
          ]);
        }
        if (request.url.path == '/rest/v1/rpc/ages_for') {
          return json([
            {'id': firstId, 'age': 29},
            {'id': secondId, 'age': 27},
          ]);
        }
        if (request.url.path.contains('/object/sign/')) {
          final paths = jsonDecode(request.body)['paths'] as List;
          return json([
            for (final path in paths)
              if ((path == firstPath && signFirst) ||
                  path == 'synthetic/later.jpg')
                {
                  'path': path,
                  'signedURL': '/object/sign/profile-photos/$path',
                },
          ]);
        }
        return json(<Object>[]);
      }),
    );
  });

  tearDownAll(() => Supabase.instance.dispose());
  setUp(() {
    requests.clear();
    photoRowMode = false;
    firstPath = null;
    signFirst = false;
  });

  test(
    'linked read retains photo-less profiles without changing deck default',
    () async {
      final linked = await ZyraDiscoveryService.profilesByIds([
        secondId,
        firstId,
      ], includeWithoutPhotos: true);
      expect(linked.map((profile) => profile.id), [secondId, firstId]);
      expect(linked.map((profile) => profile.photos), everyElement(isEmpty));
      expect(linked.map((profile) => profile.age), [27, 29]);
      expect(linked.map((profile) => profile.city), [
        'Bristol, UK',
        'Leeds, UK',
      ]);

      final deckDefault = await ZyraDiscoveryService.profilesByIds([
        secondId,
        firstId,
      ]);
      expect(deckDefault, isEmpty);

      final profileReads = requests
          .where((request) => request.url.path == '/rest/v1/profiles')
          .toList();
      expect(profileReads, hasLength(2));
      for (final request in profileReads) {
        final idFilter = request.url.queryParameters['id'];
        expect(idFilter, contains(firstId));
        expect(idFilter, contains(secondId));
      }
      expect(
        requests.any((request) => request.url.path.contains('/object/sign/')),
        isFalse,
      );
    },
  );

  test(
    'linked read retains profile fields when a photo row cannot be signed',
    () async {
      photoRowMode = true;
      final linked = await ZyraDiscoveryService.profilesByIds([
        firstId,
      ], includeWithoutPhotos: true);
      expect(linked, hasLength(1));
      expect(linked.single.id, firstId);
      expect(linked.single.firstName, 'Aaliyah');
      expect(linked.single.age, 29);
      expect(linked.single.city, 'Leeds, UK');
      expect(linked.single.photos, isEmpty);

      final deckDefault = await ZyraDiscoveryService.profilesByIds([firstId]);
      expect(deckDefault, isEmpty);
      expect(
        requests.any((request) => request.url.path.contains('/object/sign/')),
        isTrue,
      );
    },
  );

  test(
    'admitted photo one follows reorder and omits an unsignable first slot',
    () async {
      const owner = '00000000-0000-0000-0000-000000000824';
      String part(Object value) =>
          base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
      await Supabase.instance.client.auth.setInitialSession(
        jsonEncode({
          'access_token':
              '${part({'alg': 'none'})}.${part({'sub': owner, 'exp': 4102444800})}.synthetic',
          'token_type': 'bearer',
          'refresh_token': 'synthetic-refresh',
          'user': {
            'id': owner,
            'app_metadata': <String, Object?>{},
            'user_metadata': <String, Object?>{},
            'aud': 'authenticated',
            'created_at': '2026-09-13T00:00:00Z',
          },
        }),
      );
      firstPath = 'synthetic/first.jpg';
      signFirst = true;
      final first = await ZyraDiscoveryService.photoOnesByIds([
        firstId,
        secondId,
      ]);
      expect(first.keys, [firstId]);
      expect(first[firstId], contains(firstPath!));

      firstPath = 'synthetic/reordered.jpg';
      final changed = await ZyraDiscoveryService.photoOnesByIds([
        firstId,
        secondId,
      ]);
      expect(changed[firstId], contains(firstPath!));

      firstPath = 'synthetic/unavailable.jpg';
      signFirst = false;
      expect(
        await ZyraDiscoveryService.photoOnesByIds([firstId, secondId]),
        isEmpty,
      );
      final firstReads = requests.where(
        (r) => r.url.path == '/rest/v1/profiles',
      );
      for (final read in firstReads) {
        expect(read.url.queryParameters['role'], 'eq.seeker');
        expect(read.url.queryParameters['profile_photos.limit'], '1');
        expect(
          read.url.queryParameters['profile_photos.order'],
          'display_order.asc.nullslast,id.asc.nullslast',
        );
      }
      final signing = requests.where(
        (r) => r.url.path.contains('/object/sign/'),
      );
      expect(signing.map((r) => jsonDecode(r.body)['paths']), [
        ['synthetic/first.jpg'],
        ['synthetic/reordered.jpg'],
        ['synthetic/unavailable.jpg'],
        ['synthetic/unavailable.jpg'],
      ]);
    },
  );
}
