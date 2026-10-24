import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_consent_service.dart';

const _owner = '00000000-0000-0000-0000-000000000901';
const _other = '00000000-0000-0000-0000-000000000902';

// Unsigned synthetic sessions. Every HTTP request is handled in memory.
Future<void> _session(String id) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return supabase.auth.setInitialSession(
    jsonEncode({
      'access_token':
          '${part({'alg': 'none'})}.${part({'sub': id, 'exp': 4102444800})}.synthetic',
      'token_type': 'bearer',
      'refresh_token': 'synthetic-refresh',
      'user': {
        'id': id,
        'app_metadata': <String, Object?>{},
        'user_metadata': <String, Object?>{},
        'aud': 'authenticated',
        'email': 'synthetic@example.invalid',
        'created_at': '2026-10-13T00:00:00Z',
      },
    }),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Future<http.Response> Function(http.Request) responder;
  final requests = <http.Request>[];

  http.Response json(http.Request request, Object? value) => http.Response(
    jsonEncode(value),
    200,
    request: request,
    headers: {'content-type': 'application/json'},
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    responder = (request) async => json(request, false);
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) {
        requests.add(request);
        return responder(request);
      }),
    );
  });

  tearDownAll(() => Supabase.instance.dispose());

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await _session(_owner);
    await ZyraAccountState.synchronize(_owner);
    ZyraConsentService.clearForSignOut();
    requests.clear();
    responder = (request) async => json(request, false);
  });

  tearDown(() {
    ZyraConsentService.clearForSignOut();
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = null;
  });

  test('old granted read cannot resurrect a confirmed withdrawal', () async {
    final started = Completer<void>();
    final delayed = Completer<http.Response>();
    late http.Request read;
    responder = (request) {
      if (request.url.path.endsWith('/has_article9_consent')) {
        read = request;
        started.complete();
        return delayed.future;
      }
      expect(request.url.path, endsWith('/consents'));
      expect(jsonDecode(request.body)['granted'], isFalse);
      return Future.value(json(request, null));
    };
    final pending = ZyraConsentService.hasArticle9Consent();
    await started.future;
    expect(await ZyraConsentService.record(granted: false), isTrue);
    delayed.complete(json(read, true));
    expect(await pending, isFalse);
    final count = requests.length;
    expect(await ZyraConsentService.hasArticle9Consent(), isFalse);
    expect(requests.length, count);
  });

  test('old denied read cannot erase a newer confirmed grant', () async {
    final started = Completer<void>();
    final delayed = Completer<http.Response>();
    late http.Request read;
    responder = (request) {
      if (request.url.path.endsWith('/has_article9_consent')) {
        read = request;
        started.complete();
        return delayed.future;
      }
      return Future.value(json(request, null));
    };
    final pending = ZyraConsentService.hasArticle9Consent();
    await started.future;
    expect(await ZyraConsentService.record(granted: true), isTrue);
    delayed.complete(json(read, false));
    expect(await pending, isFalse);
    final count = requests.length;
    expect(await ZyraConsentService.hasArticle9Consent(), isTrue);
    expect(requests.length, count);
  });

  test('withdrawal immediately denies while its write is pending', () async {
    responder = (request) async => json(request, true);
    expect(await ZyraConsentService.hasArticle9Consent(), isTrue);
    final started = Completer<void>();
    final delayed = Completer<http.Response>();
    late http.Request write;
    responder = (request) {
      write = request;
      started.complete();
      return delayed.future;
    };
    final pending = ZyraConsentService.record(granted: false);
    await started.future;
    final count = requests.length;
    expect(await ZyraConsentService.hasArticle9Consent(), isFalse);
    expect(requests.length, count);
    delayed.complete(json(write, null));
    expect(await pending, isTrue);
    expect(await ZyraConsentService.hasArticle9Consent(), isFalse);
  });

  test('pending grant is not proof of consent and starts no read', () async {
    final started = Completer<void>();
    final delayed = Completer<http.Response>();
    late http.Request write;
    responder = (request) {
      write = request;
      started.complete();
      return delayed.future;
    };
    final pending = ZyraConsentService.record(granted: true);
    await started.future;
    final count = requests.length;
    expect(await ZyraConsentService.hasArticle9Consent(), isFalse);
    expect(requests.length, count);
    delayed.complete(json(write, null));
    expect(await pending, isTrue);
    expect(await ZyraConsentService.hasArticle9Consent(), isTrue);
  });

  for (final secondGrant in [true, false]) {
    test('pending write refuses concurrent granted=$secondGrant', () async {
      final started = Completer<void>();
      final delayed = Completer<http.Response>();
      late http.Request write;
      responder = (request) {
        write = request;
        if (!started.isCompleted) started.complete();
        return delayed.future;
      };
      final first = ZyraConsentService.record(granted: true);
      await started.future;
      // Settle both even on the old implementation, which dispatches two.
      final second = ZyraConsentService.record(granted: secondGrant);
      await Future<void>.delayed(Duration.zero);
      delayed.complete(json(write, null));
      expect(await first, isTrue);
      expect(await second, isFalse);
      expect(requests.length, 1);
    });
  }

  test('failed withdrawal invalidates previous cache and rechecks', () async {
    responder = (request) async => json(request, true);
    expect(await ZyraConsentService.hasArticle9Consent(), isTrue);
    responder = (request) async => http.Response(
      jsonEncode({'message': 'synthetic rejected write'}),
      403,
      request: request,
      headers: {'content-type': 'application/json'},
    );
    expect(await ZyraConsentService.record(granted: false), isFalse);
    final count = requests.length;
    responder = (request) async => json(request, false);
    expect(await ZyraConsentService.hasArticle9Consent(), isFalse);
    expect(requests.length, count + 1);
  });

  test('a newer read wins when same-owner reads finish in reverse', () async {
    final oldStarted = Completer<void>();
    final oldResponse = Completer<http.Response>();
    late http.Request oldRead;
    var reads = 0;
    responder = (request) {
      if (++reads == 1) {
        oldRead = request;
        oldStarted.complete();
        return oldResponse.future;
      }
      return Future.value(json(request, false));
    };
    final old = ZyraConsentService.hasArticle9Consent();
    await oldStarted.future;
    expect(await ZyraConsentService.hasArticle9Consent(), isFalse);
    oldResponse.complete(json(oldRead, true));
    expect(await old, isFalse);
    expect(await ZyraConsentService.hasArticle9Consent(), isFalse);
  });

  test('same-account generation change discards late granted read', () async {
    final started = Completer<void>();
    final delayed = Completer<http.Response>();
    late http.Request read;
    responder = (request) {
      read = request;
      started.complete();
      return delayed.future;
    };
    final pending = ZyraConsentService.hasArticle9Consent();
    await started.future;
    ZyraAccountState.resetForTesting();
    delayed.complete(json(read, true));
    expect(await pending, isFalse);
  });

  test('sign-out begins with no further consent read or write', () async {
    await ZyraAccountState.beginSignOut();
    requests.clear();
    expect(await ZyraConsentService.hasArticle9Consent(), isFalse);
    expect(await ZyraConsentService.record(granted: true), isFalse);
    expect(requests, isEmpty);
  });

  test('late grant completion cannot consent a replacement account', () async {
    final started = Completer<void>();
    final delayed = Completer<http.Response>();
    late http.Request write;
    responder = (request) {
      write = request;
      started.complete();
      return delayed.future;
    };
    final pending = ZyraConsentService.record(granted: true);
    await started.future;
    await _session(_other);
    await ZyraAccountState.synchronize(_other);
    delayed.complete(json(write, null));
    expect(await pending, isFalse);
    responder = (request) async => json(request, false);
    expect(await ZyraConsentService.hasArticle9Consent(), isFalse);
  });

  test(
    'confirmed sequential grant and withdrawal keep normal behavior',
    () async {
      responder = (request) async => json(request, null);
      expect(await ZyraConsentService.record(granted: true), isTrue);
      expect(await ZyraConsentService.hasArticle9Consent(), isTrue);
      expect(await ZyraConsentService.record(granted: false), isTrue);
      expect(await ZyraConsentService.hasArticle9Consent(), isFalse);
      expect(requests.length, 2);
      expect(jsonDecode(requests.last.body)['policy_version'], '2026-08-04');
    },
  );

  for (final expiry in <int?>[null, 1]) {
    for (final granted in [true, false]) {
      test(
        'expiry=$expiry refuses granted=$granted without dispatch',
        () async {
          // The SDK exposes nullable parsed expiry on its Session. Only this
          // in-memory synthetic session changes; no provider request is made.
          supabase.auth.currentSession!.expiresAt = expiry;
          requests.clear();
          expect(await ZyraConsentService.record(granted: granted), isFalse);
          expect(requests, isEmpty);
        },
      );
    }
  }

  test(
    'session expiry during a write cannot publish granted consent',
    () async {
      final started = Completer<void>();
      final delayed = Completer<http.Response>();
      late http.Request write;
      responder = (request) {
        write = request;
        started.complete();
        return delayed.future;
      };
      final pending = ZyraConsentService.record(granted: true);
      await started.future;
      supabase.auth.currentSession!.expiresAt = 1;
      delayed.complete(json(write, null));
      expect(await pending, isFalse);
      // A confirmed true was not cached from this invalidated acknowledgement.
      await _session(_owner);
      responder = (request) async => json(request, false);
      expect(await ZyraConsentService.hasArticle9Consent(), isFalse);
    },
  );
}
