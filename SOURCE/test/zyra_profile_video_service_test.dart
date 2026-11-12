import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/services/zyra_profile_video_service.dart';

const _viewer = '00000000-0000-4000-8000-000000000811';
const _owner = '00000000-0000-4000-8000-000000000812';
const _path = '$_owner/00000000-0000-4000-8000-000000000813.mp4';

http.Response _json(http.Request request, Object? value, [int status = 200]) =>
    http.Response(
      jsonEncode(value),
      status,
      headers: {'content-type': 'application/json'},
      request: request,
    );

String _encoded(Object value) =>
    base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

Future<String> _session(SupabaseClient client) async {
  final token =
      '${_encoded({'alg': 'none'})}.${_encoded({'sub': _viewer, 'exp': 4102444800})}.synthetic';
  await client.auth.setInitialSession(
    jsonEncode({
      'access_token': token,
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': _viewer,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'created_at': '2026-11-12T00:00:00Z',
      },
    }),
  );
  return token;
}

void main() {
  test(
    'viewer always resolves approved path before authenticated bytes',
    () async {
      final requested = <String>[];
      var approved = false;
      var permitted = true;
      late String token;
      final httpClient = MockClient((request) async {
        requested.add(request.url.path);
        expect(request.headers['authorization'], 'Bearer $token');
        if (request.url.path.endsWith('/zyra_profile_video_for')) {
          expect(jsonDecode(request.body), {'p_user': _owner});
          return _json(
            request,
            approved
                ? [
                    {'storage_path': _path, 'duration_ms': 9000},
                  ]
                : [],
          );
        }
        expect(
          request.url.path,
          '/storage/v1/object/authenticated/profile-videos/$_path',
        );
        expect(request.headers['cache-control'], 'no-store');
        permitted = false;
        return http.Response.bytes([1, 2, 3], 200);
      });
      final client = SupabaseClient(
        'https://example.invalid',
        'synthetic-test-only',
        httpClient: httpClient,
      );
      addTearDown(client.dispose);
      token = await _session(client);
      final store = ZyraSupabaseProfileVideoStore(
        client,
        accountId: _viewer,
        canAct: () => permitted,
        mediaClient: httpClient,
      );
      expect(await store.loadApproved(_owner), isNull);
      expect(requested, ['/rest/v1/rpc/zyra_profile_video_for']);
      approved = true;
      await expectLater(store.loadApproved(_owner), throwsStateError);
      expect(requested, [
        '/rest/v1/rpc/zyra_profile_video_for',
        '/rest/v1/rpc/zyra_profile_video_for',
        '/storage/v1/object/authenticated/profile-videos/$_path',
      ]);
    },
  );

  test(
    'upload and one explicit 503 retry reuse a fresh validated path',
    () async {
      var submits = 0;
      var uploads = 0;
      String? path;
      late String token;
      final httpClient = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer $token');
        final route = request.url.path;
        if (route.startsWith('/storage/v1/object/profile-videos/')) {
          uploads++;
          path = route.split('/profile-videos/').last;
          expect(
            path,
            matches(RegExp(r'^' + _viewer + r'/[a-f0-9-]{36}\.mp4$')),
          );
          expect(request.headers['x-upsert'], 'false');
          expect(request.body, contains('video/mp4'));
          return _json(request, {'Key': 'profile-videos/$path'});
        }
        if (route.endsWith('/zyra_my_profile_video')) return _json(request, []);
        expect(route, '/functions/v1/zyra-profile-video-submit');
        expect(jsonDecode(request.body), {'path': path});
        return ++submits == 1
            ? _json(request, {'error': 'temporarily_unavailable'}, 503)
            : _json(request, {'ok': true, 'status': 'pending'});
      });
      final client = SupabaseClient(
        'https://example.invalid',
        'synthetic-test-only',
        httpClient: httpClient,
      );
      addTearDown(client.dispose);
      token = await _session(client);
      final scratch = await Directory.systemTemp.createTemp(
        'profile-video-contract',
      );
      addTearDown(() => scratch.delete(recursive: true));
      final clip = await File(
        '${scratch.path}/short.mp4',
      ).writeAsBytes([1, 2, 3]);
      final store = ZyraSupabaseProfileVideoStore(
        client,
        accountId: _viewer,
        canAct: () => true,
        mediaClient: httpClient,
      );
      final saved = await store.submit(clip, const Duration(seconds: 4));
      expect(saved.status, ZyraProfileVideoStatus.pending);
      expect(saved.path, path);
      expect(uploads, 1);
      expect(submits, 2);
      await expectLater(
        store.submit(clip, const Duration(milliseconds: 10001)),
        throwsA(
          isA<ZyraProfileVideoRefusal>().having(
            (error) => error.reason,
            'reason',
            'too_long',
          ),
        ),
      );
      expect(uploads, 1);
    },
  );

  test(
    'removal withdraws the row before deleting the returned object',
    () async {
      const ownPath = '$_viewer/00000000-0000-4000-8000-000000000813.mp4';
      final calls = <String>[];
      late String token;
      final httpClient = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer $token');
        calls.add(request.url.path);
        if (calls.length == 1) return _json(request, ownPath);
        expect(request.method, 'DELETE');
        expect(jsonDecode(request.body), {
          'prefixes': [ownPath],
        });
        return _json(request, []);
      });
      final client = SupabaseClient(
        'https://example.invalid',
        'synthetic-test-only',
        httpClient: httpClient,
      );
      addTearDown(client.dispose);
      token = await _session(client);
      final store = ZyraSupabaseProfileVideoStore(
        client,
        accountId: _viewer,
        canAct: () => true,
        mediaClient: httpClient,
      );
      await store.remove();
      expect(calls, [
        '/rest/v1/rpc/zyra_remove_my_profile_video',
        '/storage/v1/object/profile-videos',
      ]);
    },
  );
}
