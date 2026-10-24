import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

String _token(String sub) =>
    'test.${base64Url.encode(utf8.encode(jsonEncode({'sub': sub})))}.test';

void main() {
  const endpoint = ZyraInternalFounderPolicy.approvedSupabaseUrl;
  const founder = ZyraInternalFounderPolicy.approvedFounderUserId;
  const personal = '22222222-2222-4222-8222-222222222222';
  setUp(() => ZyraInternalPreviewClient.bindAccount(personal));
  tearDown(ZyraInternalPreviewClient.finishSignOut);

  test(
    'preview denial remains a typed PostgREST error, not a null crash',
    () async {
      var sent = 0;
      final client = ZyraInternalPreviewClient(
        MockClient((_) async {
          sent++;
          return http.Response('[]', 200);
        }),
        previewActive: () => true,
      );
      addTearDown(client.close);
      final database = PostgrestClient(
        '$endpoint/rest/v1',
        httpClient: client,
        headers: {'Authorization': 'Bearer ${_token(founder)}'},
      );
      await expectLater(
        database.from('profiles').select(),
        throwsA(
          isA<PostgrestException>().having(
            (error) => error.code,
            'code',
            'ZYRA_LOCAL_PREVIEW',
          ),
        ),
      );
      // The installed SDK's maybeSingle wrapper normalizes this error code
      // to HTTP403, but must still throw its typed denial, never _TypeError.
      await expectLater(
        database.from('profiles').select().maybeSingle(),
        throwsA(
          isA<PostgrestException>().having(
            (error) => error.code,
            'code',
            '403',
          ),
        ),
      );
      expect(sent, 0);
    },
  );

  test(
    'logout and account replacement deny newly dispatched old tokens',
    () async {
      var sent = 0;
      final client = ZyraInternalPreviewClient(
        MockClient((_) async {
          sent++;
          return http.Response('{}', 200);
        }),
        previewActive: () => false,
      );
      addTearDown(client.close);
      Future<http.Response> request() => client.get(
        Uri.parse('$endpoint/rest/v1/profiles'),
        headers: {'Authorization': 'Bearer ${_token(personal)}'},
      );
      ZyraInternalPreviewClient.bindAccount(null);
      expect((await request()).statusCode, 403);
      ZyraInternalPreviewClient.bindAccount('another-person');
      expect((await request()).statusCode, 403);
      expect(sent, 0);
      ZyraInternalPreviewClient.bindAccount(personal);
      expect((await request()).statusCode, 200);
      expect(sent, 1);
    },
  );

  test('late member response is discarded after an account boundary', () async {
    final response = Completer<http.Response>();
    final sent = Completer<void>();
    final client = ZyraInternalPreviewClient(
      MockClient((_) {
        sent.complete();
        return response.future;
      }),
      previewActive: () => false,
    );
    addTearDown(client.close);
    final pending = client.get(
      Uri.parse('$endpoint/rest/v1/profiles'),
      headers: {'Authorization': 'Bearer ${_token(personal)}'},
    );
    await sent.future;
    ZyraInternalPreviewClient.invalidateAccountRequests();
    response.complete(http.Response('{"name":"Previous person"}', 200));
    final result = await pending;
    expect(result.statusCode, 403);
    expect(jsonDecode(result.body)['code'], 'ZYRA_ACCOUNT_CHANGED');
    expect(result.body, isNot(contains('Previous person')));
  });

  test(
    'body arriving after preview begins never reaches the consumer',
    () async {
      final body = StreamController<List<int>>();
      final client = ZyraInternalPreviewClient(
        MockClient.streaming((request, _) async {
          return http.StreamedResponse(body.stream, 200, request: request);
        }),
      );
      addTearDown(client.close);
      final response = await client.send(
        http.Request('GET', Uri.parse('$endpoint/rest/v1/profiles'))
          ..headers['Authorization'] = 'Bearer ${_token(personal)}',
      );
      final expectation = expectLater(
        response.stream.toBytes(),
        throwsA(isA<http.ClientException>()),
      );
      ZyraInternalPreviewClient.beginPreview();
      body.add(utf8.encode('{"name":"Previous person"}'));
      await body.close();
      await expectation;
    },
  );

  test(
    'same-account response is not discarded by repeated preview exit',
    () async {
      final client = ZyraInternalPreviewClient(
        MockClient((_) async {
          ZyraInternalPreviewClient.finishSignOut();
          return http.Response('{"name":"Current person"}', 200);
        }),
      );
      addTearDown(client.close);
      final response = await client.get(
        Uri.parse('$endpoint/rest/v1/profiles'),
        headers: {'Authorization': 'Bearer ${_token(personal)}'},
      );
      expect(response.statusCode, 200);
      expect(jsonDecode(response.body)['name'], 'Current person');
    },
  );

  test(
    'Founder data operations never reach the underlying transport',
    () async {
      var sent = 0;
      final client = ZyraInternalPreviewClient(
        MockClient((_) async {
          sent++;
          return http.Response('{}', 200);
        }),
        previewActive: () => false,
      );
      addTearDown(client.close);
      for (final path in [
        '/rest/v1/profiles',
        '/rest/v1/rpc/zyra_dev_reset_account',
        '/storage/v1/object/profile-photos/test',
        '/functions/v1/anything',
      ]) {
        for (final method in ['GET', 'POST', 'PATCH', 'PUT', 'DELETE']) {
          final request = http.Request(method, Uri.parse('$endpoint$path'))
            ..headers['Authorization'] = 'Bearer ${_token(founder)}';
          expect((await client.send(request)).statusCode, 403);
        }
      }
      expect(sent, 0);
    },
  );

  test(
    'latch blocks a switched personal token; old Founder token stays denied',
    () async {
      var active = true;
      var sent = 0;
      final client = ZyraInternalPreviewClient(
        MockClient((_) async {
          sent++;
          return http.Response('{}', 200);
        }),
        previewActive: () => active,
      );
      addTearDown(client.close);
      Future<int> request(String sub) async => (await client.post(
        Uri.parse('$endpoint/rest/v1/profiles'),
        headers: {'Authorization': 'Bearer ${_token(sub)}'},
      )).statusCode;
      expect(await request(personal), 403);
      active = false;
      expect(await request(founder), 403);
      expect(await request(personal), 200);
      expect(sent, 1);
    },
  );

  test('unknown tokens and another host cannot forward data', () async {
    var sent = 0;
    final client = ZyraInternalPreviewClient(
      MockClient((_) async {
        sent++;
        return http.Response('{}', 200);
      }),
      previewActive: () => false,
    );
    addTearDown(client.close);
    for (final token in ['', 'Bearer broken', 'Bearer x.e30=.x']) {
      expect(
        (await client.get(
          Uri.parse('$endpoint/rest/v1/profiles'),
          headers: {'Authorization': token},
        )).statusCode,
        403,
      );
    }
    expect(
      (await client.get(
        Uri.parse('https://example.com/auth/v1/user'),
        headers: {'Authorization': 'Bearer ${_token(personal)}'},
      )).statusCode,
      403,
    );
    expect(sent, 0);
  });

  test(
    'Founder can refresh and sign out but cannot change Auth identity',
    () async {
      var sent = 0;
      final client = ZyraInternalPreviewClient(
        MockClient((_) async {
          sent++;
          return http.Response('{}', 200);
        }),
        previewActive: () => true,
      );
      addTearDown(client.close);
      for (final pair in [
        ('POST', '/token?grant_type=refresh_token'),
        ('POST', '/logout'),
        ('GET', '/user'),
      ]) {
        final request = http.Request(
          pair.$1,
          Uri.parse('$endpoint/auth/v1${pair.$2}'),
        );
        expect((await client.send(request)).statusCode, 200);
      }
      for (final pair in [
        ('PUT', '/user'),
        ('POST', '/otp'),
        ('POST', '/recover'),
        ('GET', '/user/identities/authorize'),
        ('DELETE', '/user'),
      ]) {
        final request = http.Request(
          pair.$1,
          Uri.parse('$endpoint/auth/v1${pair.$2}'),
        );
        expect((await client.send(request)).statusCode, 403);
      }
      expect(sent, 3);
    },
  );

  test('ordinary member auth passes through outside preview', () async {
    var sent = 0;
    final client = ZyraInternalPreviewClient(
      MockClient((_) async {
        sent++;
        return http.Response('{}', 200);
      }),
      previewActive: () => false,
    );
    addTearDown(client.close);
    expect(
      (await client.put(
        Uri.parse('$endpoint/auth/v1/user'),
        headers: {'Authorization': 'Bearer ${_token(personal)}'},
      )).statusCode,
      200,
    );
    expect(sent, 1);
  });

  test('preview profile values do not replace cached real identity', () async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    ZyraLocalPrefs.setCachedFirstName('Real');
    ZyraLocalPrefs.setCachedGender('female');
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.surnameLine = 'Private name';
    AppState.instance.age = 99;
    AppState.instance.hydrated = true;
    AppState.instance.guardianSuggestedBy = {'private-id': 'Private guardian'};
    AppState.instance.applyDevPreset(name: 'Adam', gender: 'male');
    expect(AppState.instance.fullName, 'Adam');
    expect(AppState.instance.age, isNull);
    expect(AppState.instance.hydrated, isFalse);
    expect(AppState.instance.guardianSuggestedBy, isEmpty);
    expect(ZyraLocalPrefs.cachedFirstName, 'Real');
    expect(ZyraLocalPrefs.cachedGender, 'female');
    AppState.instance.applyDevPreset();
    expect(AppState.instance.fullName, isNull);
    expect(AppState.instance.age, isNull);
    expect(AppState.instance.gender, isNull);
    expect(AppState.instance.guardianSuggestedBy, isEmpty);
    AppState.instance.saveChapter1(
      name: 'Another',
      gender: 'male',
      dob: DateTime(1995),
    );
    expect(ZyraLocalPrefs.cachedFirstName, 'Real');
    expect(ZyraLocalPrefs.cachedGender, 'female');
  });

  test(
    'both SDK initializers install the guard and only guarded chat uses Realtime',
    () {
      final main = File('lib/main.dart').readAsStringSync();
      expect(
        RegExp(r'await Supabase\.initialize\(').allMatches(main).length,
        2,
      );
      expect(
        'httpClient: ZyraInternalPreviewClient.create()'
            .allMatches(main)
            .length,
        2,
      );
      final channels = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.dart') &&
                f.readAsStringSync().contains('.channel('),
          )
          .map((f) => f.path)
          .toList();
      expect(channels, ['lib/screens/chat/chat_screen.dart']);
      final chat = File(channels.single).readAsStringSync();
      expect(
        chat.indexOf('if (ZyraInternalPreviewClient.isActive) return;'),
        lessThan(chat.indexOf('supabase.channel(')),
      );
    },
  );
}
