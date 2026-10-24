// F21 / OA-ZYRA-302/303, with OA-ZYRA-305 dependency.
// CURRENT-SOURCE CHARACTERISATION, NOT REPAIR ACCEPTANCE.
// The unchanged service violates the preservation rule. Its unsoftened red
// contract and exact failed output are preserved as P1_RED_CONTRACT_test.dart
// and P1_RED_CONTRACT_RUN.log in the dated F21 local candidate review folder.
// All users, rows and HTTP responses below are synthetic. The public production
// service is invoked unchanged. No request can leave the injected MockClient.
// This is a transport test, not proof of PostgreSQL transaction rollback.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_photo_service.dart';

const _actorA = '00000000-0000-4000-8000-000000000861';
const _actorB = '00000000-0000-4000-8000-000000000862';
const _origin = 'https://f21.invalid';

Future<void> _session(String id) async {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  await supabase.auth.setInitialSession(
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
        'created_at': '2026-10-08T00:00:00Z',
      },
    }),
  );
  await ZyraAccountState.synchronize(id);
}

String _signed(String path, {bool encodePath = false}) =>
    '$_origin/storage/v1/object/sign/profile-photos/'
    '${encodePath ? Uri.encodeComponent(path) : path}?token=synthetic';

Map<String, Object?> _row(String owner, String file, int order) => {
  'user_id': owner,
  'storage_path': '$owner/$file',
  'is_primary': order == 0,
  'display_order': order,
};

class _Call {
  _Call(this.method, this.actor, this.rows);

  final String method;
  final String actor;
  final List<Map<String, Object?>> rows;
}

/// Minimal fake persistence transport: each DELETE and POST commits separately.
/// It deliberately does not emulate PostgreSQL constraints or RPC transactions.
class _PhotoTransport {
  final rows = <String, List<Map<String, Object?>>>{
    _actorA: [_row(_actorA, 'first.jpg', 0), _row(_actorA, 'second.jpg', 1)],
    _actorB: [_row(_actorB, 'unrelated.jpg', 0)],
  };
  final calls = <_Call>[];
  final unexpected = <String>[];
  bool failDelete = false;
  bool failInsert = false;
  bool loseInsertAcknowledgement = false;
  Future<void> Function()? afterDelete;

  List<Map<String, Object?>> rowsFor(String owner) => [
    for (final row in rows[owner] ?? <Map<String, Object?>>[]) Map.of(row),
  ];

  String _actor(http.Request request) {
    final authorization = request.headers['authorization'];
    if (authorization == null || !authorization.startsWith('Bearer ')) {
      throw StateError('Synthetic authorization required.');
    }
    final parts = authorization.substring(7).split('.');
    if (parts.length != 3) throw StateError('Invalid synthetic session.');
    final claims =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
            as Map<String, dynamic>;
    final actor = claims['sub'];
    if (actor != _actorA && actor != _actorB) {
      throw StateError('Unexpected synthetic principal.');
    }
    return actor as String;
  }

  http.Response _reply(http.Request request, Object? body, int status) =>
      http.Response(
        status == 204 ? '' : jsonEncode(body),
        status,
        request: request,
        headers: {'content-type': 'application/json'},
      );

  Future<http.Response> send(http.Request request) async {
    if (request.url.origin != _origin ||
        request.url.path != '/rest/v1/profile_photos' ||
        (request.method != 'DELETE' && request.method != 'POST')) {
      unexpected.add('${request.method} ${request.url.path}');
      throw StateError('All unrelated traffic is rejected by this fake.');
    }
    final actor = _actor(request);
    if (request.method == 'DELETE') {
      if (request.url.queryParameters['user_id'] != 'eq.$actor') {
        unexpected.add('DELETE owner predicate mismatch');
        throw StateError('Synthetic DELETE must bind its owner.');
      }
      calls.add(_Call('DELETE', actor, const []));
      if (failDelete) {
        return _reply(request, {'message': 'Synthetic delete rejected'}, 503);
      }
      rows[actor] = [];
      await afterDelete?.call();
      return _reply(request, null, 204);
    }
    final payload = jsonDecode(request.body) as List;
    final inserted = <Map<String, Object?>>[
      for (final item in payload) Map<String, Object?>.from(item as Map),
    ];
    if (inserted.any((row) => row['user_id'] != actor)) {
      unexpected.add('INSERT owner mismatch');
      throw StateError('Synthetic INSERT must bind its owner.');
    }
    calls.add(_Call('POST', actor, inserted));
    if (failInsert) {
      return _reply(request, {'message': 'Synthetic insert rejected'}, 503);
    }
    rows[actor]!.addAll(inserted);
    if (loseInsertAcknowledgement) {
      throw http.ClientException('Synthetic acknowledgement lost');
    }
    return _reply(request, null, 201);
  }

  void report(String name, bool result, List<Map<String, Object?>> before) {
    // Only synthetic rows and tokenless references are output. No header or
    // signed URL is retained in these evidence records.
    // ignore: avoid_print
    print(
      'F21_SYNTHETIC ${jsonEncode({'case': name, 'serviceReturned': result, 'beforeRowsA': before, 'afterRowsA': rowsFor(_actorA), 'afterRowsB': rowsFor(_actorB), 'methods': calls.map((call) => call.method).toList()})}',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _PhotoTransport transport;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: _origin,
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) => transport.send(request)),
    );
  });

  setUp(() async {
    transport = _PhotoTransport();
    SharedPreferences.setMockInitialValues({});
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    ZyraPhotoService.clearUrlMemoForSignOut();
    await _session(_actorA);
  });

  tearDown(() {
    expect(transport.unexpected, isEmpty);
    ZyraAccountState.clearImagesForTesting = null;
    ZyraAccountState.endSignOutAttempt();
  });
  tearDownAll(() => Supabase.instance.dispose());

  Future<void> interruptedDelete(
    String name,
    Future<void> Function() interrupt,
  ) async {
    final before = transport.rowsFor(_actorA);
    final started = Completer<void>();
    final release = Completer<void>();
    transport.afterDelete = () async {
      started.complete();
      await release.future;
    };
    final pending = ZyraPhotoService.syncPhotosConfirmed([
      _signed('$_actorA/replacement.jpg'),
    ], expectedUserId: _actorA);
    try {
      await started.future.timeout(const Duration(seconds: 2));
      await interrupt();
    } finally {
      release.complete();
    }
    final result = await pending;
    transport.report(name, result, before);
    expect(result, isFalse);
    expect(transport.calls.map((call) => call.method), ['DELETE']);
    expect(transport.rowsFor(_actorA), isEmpty);
    expect(transport.rowsFor(_actorB), [_row(_actorB, 'unrelated.jpg', 0)]);
  }

  group('F21 CURRENT-SOURCE CHARACTERISATION (not repair acceptance)', () {
    test(
      'INSERT rejection loses previously saved rows despite false',
      () async {
        final beforeA = transport.rowsFor(_actorA);
        final beforeB = transport.rowsFor(_actorB);
        transport.failInsert = true;
        final result = await ZyraPhotoService.syncPhotosConfirmed([
          _signed('$_actorA/replacement.jpg'),
        ], expectedUserId: _actorA);
        transport.report('insert-rejected-observed-data-loss', result, beforeA);
        expect(result, isFalse);
        expect(transport.calls.map((call) => call.method), ['DELETE', 'POST']);
        expect(transport.rowsFor(_actorB), beforeB);
        // Observed defect, never the desired contract. The red snapshot retains
        // the original preservation assertion rather than weakening it.
        expect(beforeA, hasLength(2));
        expect(transport.rowsFor(_actorA), isEmpty);
      },
    );

    test('DELETE rejection preserves rows and never starts INSERT', () async {
      final before = transport.rowsFor(_actorA);
      transport.failDelete = true;
      final result = await ZyraPhotoService.syncPhotosConfirmed([
        _signed('$_actorA/replacement.jpg'),
      ], expectedUserId: _actorA);
      transport.report('delete-rejected', result, before);
      expect(result, isFalse);
      expect(transport.calls.map((call) => call.method), ['DELETE']);
      expect(transport.rowsFor(_actorA), before);
    });

    test(
      'successful reorder uses actual signed and legacy URL decoding',
      () async {
        final before = transport.rowsFor(_actorA);
        final beforeB = transport.rowsFor(_actorB);
        final result = await ZyraPhotoService.syncPhotosConfirmed([
          _signed('$_actorA/second.jpg', encodePath: true),
          '$_origin/storage/v1/object/public/profile-photos/$_actorA/first.jpg',
        ], expectedUserId: _actorA);
        transport.report('reorder-signed-and-legacy-decoder', result, before);
        expect(result, isTrue);
        expect(transport.calls.map((call) => call.method), ['DELETE', 'POST']);
        expect(transport.calls.every((call) => call.actor == _actorA), isTrue);
        expect(transport.rowsFor(_actorA), [
          _row(_actorA, 'second.jpg', 0),
          _row(_actorA, 'first.jpg', 1),
        ]);
        expect(transport.rowsFor(_actorB), beforeB);
      },
    );

    test(
      'empty list currently clears rows and returns true without INSERT',
      () async {
        final before = transport.rowsFor(_actorA);
        final result = await ZyraPhotoService.syncPhotosConfirmed(
          const [],
          expectedUserId: _actorA,
        );
        transport.report('empty-list-current-contract', result, before);
        expect(result, isTrue);
        expect(transport.calls.map((call) => call.method), ['DELETE']);
        expect(transport.rowsFor(_actorA), isEmpty);
      },
    );

    test('mismatched expected owner performs no HTTP request', () async {
      final before = transport.rowsFor(_actorA);
      final result = await ZyraPhotoService.syncPhotosConfirmed([
        _signed('$_actorA/replacement.jpg'),
      ], expectedUserId: _actorB);
      transport.report('expected-owner-mismatch', result, before);
      expect(result, isFalse);
      expect(transport.calls, isEmpty);
      expect(transport.rowsFor(_actorA), before);
    });

    test('A to B during DELETE prevents old operation INSERT', () async {
      await interruptedDelete(
        'actor-A-to-B-after-delete',
        () => _session(_actorB),
      );
      expect(ZyraAccountState.userId, _actorB);
    });

    test('A to B to A lifecycle invalidates the old DELETE epoch', () async {
      await interruptedDelete('actor-ABA-after-delete', () async {
        await _session(_actorB);
        await _session(_actorA);
      });
      expect(ZyraAccountState.userId, _actorA);
    });

    test('same-owner public reset invalidates pending DELETE intent', () async {
      await interruptedDelete('same-owner-clear-after-delete', () async {
        ZyraPhotoService.clearUrlMemoForSignOut();
      });
    });

    test(
      'lost INSERT acknowledgement returns false although rows committed',
      () async {
        final before = transport.rowsFor(_actorA);
        transport.loseInsertAcknowledgement = true;
        final result = await ZyraPhotoService.syncPhotosConfirmed([
          _signed('$_actorA/replacement.jpg'),
        ], expectedUserId: _actorA);
        transport.report(
          'insert-committed-acknowledgement-lost',
          result,
          before,
        );
        expect(result, isFalse);
        expect(transport.calls.map((call) => call.method), ['DELETE', 'POST']);
        expect(transport.rowsFor(_actorA), [
          _row(_actorA, 'replacement.jpg', 0),
        ]);
        // This public method does no readback or object cleanup. Its false cannot
        // distinguish confirmed rejection from an unknown committed result.
        expect(transport.unexpected, isEmpty);
      },
    );

    test(
      'concurrent saves can interleave independently committed requests',
      () async {
        final before = transport.rowsFor(_actorA);
        final firstDelete = Completer<void>();
        final releaseFirst = Completer<void>();
        var deleteOrdinal = 0;
        transport.afterDelete = () async {
          if (++deleteOrdinal == 1) {
            firstDelete.complete();
            await releaseFirst.future;
          }
        };
        final first = ZyraPhotoService.syncPhotosConfirmed([
          _signed('$_actorA/concurrent-first.jpg'),
        ], expectedUserId: _actorA);
        late bool secondResult;
        try {
          await firstDelete.future.timeout(const Duration(seconds: 2));
          secondResult = await ZyraPhotoService.syncPhotosConfirmed([
            _signed('$_actorA/concurrent-second.jpg'),
          ], expectedUserId: _actorA);
        } finally {
          releaseFirst.complete();
        }
        final firstResult = await first;
        transport.report(
          'concurrent-independent-request-interleaving',
          firstResult,
          before,
        );
        expect(firstResult, isTrue);
        expect(secondResult, isTrue);
        expect(transport.calls.map((call) => call.method), [
          'DELETE',
          'DELETE',
          'POST',
          'POST',
        ]);
        // The fake has no database unique constraints. Combined rows describe
        // only this synthetic transport fixture, not a live PostgreSQL outcome.
        expect(transport.rowsFor(_actorA), [
          _row(_actorA, 'concurrent-second.jpg', 0),
          _row(_actorA, 'concurrent-first.jpg', 0),
        ]);
      },
    );

    test(
      'sync currently submits seven rows without enforcing six-photo limit',
      () async {
        final before = transport.rowsFor(_actorA);
        final result = await ZyraPhotoService.syncPhotosConfirmed([
          for (var index = 0; index < 7; index++)
            _signed('$_actorA/limit-$index.jpg'),
        ], expectedUserId: _actorA);
        transport.report('seven-rows-no-client-service-cap', result, before);
        expect(result, isTrue);
        expect(transport.calls.last.rows, hasLength(7));
        expect(transport.rowsFor(_actorA), hasLength(7));
        expect(
          transport.rowsFor(_actorA).where((row) => row['is_primary'] == true),
          hasLength(1),
        );
      },
    );

    test(
      'malformed URL decoding fails only after saved rows were deleted',
      () async {
        final before = transport.rowsFor(_actorA);
        final result = await ZyraPhotoService.syncPhotosConfirmed([
          '$_origin/storage/v1/object/sign/profile-photos/$_actorA/%GG.jpg',
        ], expectedUserId: _actorA);
        transport.report('malformed-url-decode-after-delete', result, before);
        expect(result, isFalse);
        expect(transport.calls.map((call) => call.method), ['DELETE']);
        expect(
          transport.rowsFor(_actorA),
          isEmpty,
          reason: 'Observed pre-validation F21 loss, not a desired contract.',
        );
      },
    );
  });
}
