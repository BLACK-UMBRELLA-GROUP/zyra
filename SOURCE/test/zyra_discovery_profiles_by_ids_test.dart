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
          return json(<Object>[]);
        }
        return json(<Object>[]);
      }),
    );
  });

  tearDownAll(() => Supabase.instance.dispose());
  setUp(() {
    requests.clear();
    photoRowMode = false;
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
}
