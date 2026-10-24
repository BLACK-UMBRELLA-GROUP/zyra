// Synthetic accounts, opaque UUIDs and an intercepted HTTP client only.
// No live Supabase connection, native sign-in or real notification is used.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/screens/notifications/notifications_screen.dart';
import 'package:zyra/screens/wali/wali_home_shell.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_notification_service.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';

const _a = '00000000-0000-4000-8000-000000009101';
const _b = '00000000-0000-4000-8000-000000009102';
const _first = '00000000-0000-4000-8000-000000009111';
const _later = '00000000-0000-4000-8000-000000009112';
const _readAt = '2026-10-19T12:00:00Z';
const _bound = Duration(seconds: 3);

/// Every delayed transport has bounded admission and unconditional teardown.
/// A denied service operation reports its status instead of leaving a widget
/// test waiting forever for a request that correctly never went on the wire.
final class _HeldResponse {
  final _received = Completer<Request>();
  final _response = Completer<Response>();

  Future<Response> call(Request request) {
    if (_received.isCompleted) {
      return Future.error(
        StateError('Unexpected duplicate synthetic dispatch.'),
      );
    }
    _received.complete(request);
    return _response.future;
  }

  Future<Request> waitForDispatch(Future<Object?> pending) =>
      Future.any<Request>([
        _received.future,
        pending.then<Request>((result) {
          final status = result is ZyraNotificationAckResult
              ? result.status.name
              : 'read completed';
          throw StateError(
            'Synthetic operation ended before transport: $status.',
          );
        }),
      ]).timeout(_bound);

  void complete(Response response) {
    if (!_response.isCompleted) _response.complete(response);
  }

  Future<void> settle(Future<Object?> pending) async {
    complete(
      Response('[]', 200, headers: {'content-type': 'application/json'}),
    );
    await pending.timeout(_bound);
  }
}

Map<String, dynamic> _sessionJson(String id, {String lifetime = 'opening'}) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return {
    'access_token':
        '${part({'alg': 'none'})}.${part({'sub': id, 'exp': 4102444800, 'session_id': lifetime})}.synthetic',
    'token_type': 'bearer',
    'refresh_token': 'synthetic-refresh',
    'expires_at': 4102444800,
    'user': {
      'id': id,
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'aud': 'authenticated',
      'created_at': '2026-10-19T00:00:00Z',
    },
  };
}

Future<void> _session(
  String id, {
  String lifetime = 'opening',
  bool synchronize = true,
}) async {
  await supabase.auth.setInitialSession(
    jsonEncode(_sessionJson(id, lifetime: lifetime)),
  );
  if (synchronize) await ZyraAccountState.synchronize(id);
  await Future<void>.delayed(Duration.zero);
}

Response _confirmed(Iterable<String> ids) => Response(
  jsonEncode([
    for (final id in ids) {'id': id, 'read_at': _readAt},
  ]),
  200,
  headers: {'content-type': 'application/json'},
);

ZyraNotification _notification(String id, {bool read = false}) =>
    ZyraNotification(
      id: id,
      type: 'new_message',
      title: id == _first ? 'Previously displayed event' : 'New arrival',
      body: null,
      relatedMatchId: null,
      createdAt: DateTime.utc(2026, 10, 19),
      readAt: read ? DateTime.parse(_readAt) : null,
    );

VoidCallback _strip(WidgetTester tester, String label) => tester
    .widget<InkWell>(
      find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first,
    )
    .onTap!;

Future<void> _flush(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Future<Response> Function(Request) respond;
  final requests = <Request>[];

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    await Supabase.initialize(
      url: 'https://synthetic.invalid',
      publishableKey: 'synthetic-test-only',
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = await respond(request);
        // PostgREST parses the originating method/headers from response.request.
        // A real transport always supplies it; MockClient does not add it.
        return Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
          reasonPhrase: response.reasonPhrase,
          isRedirect: response.isRedirect,
          persistentConnection: response.persistentConnection,
        );
      }),
    );
  });
  setUp(() async {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    respond = (_) async => throw StateError('Unplanned synthetic transport.');
    await _session(_a);
    requests.clear();
  });
  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
  });
  tearDownAll(() => Supabase.instance.dispose());

  test('bulk ACK snapshots exact IDs and pins actor and bearer', () async {
    final held = _HeldResponse();
    respond = held.call;
    final ids = <String>[_first];
    final token = supabase.auth.currentSession!.accessToken;
    final pending = ZyraNotificationService.acknowledgeIds(ids);
    try {
      ids.add(_later);
      final request = await held.waitForDispatch(pending);
      expect(request.method, 'PATCH');
      expect(request.url.queryParameters['user_id'], 'eq.$_a');
      expect(request.url.queryParameters['id'], 'in.("$_first")');
      expect(request.url.queryParameters['select'], 'id,read_at');
      expect(request.headers['Authorization'], 'Bearer $token');
      held.complete(_confirmed([_first]));
      final result = await pending.timeout(_bound);
      expect(result.isConfirmed, isTrue);
      expect(result.confirmedIds, {_first});
      expect(() => result.confirmedIds.add(_later), throwsUnsupportedError);
      expect(requests, hasLength(1));
    } finally {
      await held.settle(pending);
    }
  });

  for (final rows in [
    <Map<String, Object?>>[],
    [
      {'id': _first, 'read_at': null},
    ],
    [
      {'id': _later, 'read_at': _readAt},
    ],
    [
      {'id': _first, 'read_at': _readAt},
      {'id': _first, 'read_at': _readAt},
    ],
  ]) {
    test(
      'missing, unconfirmed, unrelated or duplicated return is not ACK: $rows',
      () async {
        respond = (_) async => Response(
          jsonEncode(rows),
          200,
          headers: {'content-type': 'application/json'},
        );
        final result = await ZyraNotificationService.acknowledgeIds([_first]);
        expect(result.status, ZyraNotificationAckStatus.unavailable);
        expect(result.confirmedIds, isEmpty);
      },
    );
  }

  test('failed mutation never claims a confirmed read', () async {
    respond = (_) async => Response(
      '{"message":"synthetic unavailable"}',
      403,
      headers: {'content-type': 'application/json'},
    );
    final result = await ZyraNotificationService.acknowledgeIds([_first]);
    expect(result.status, ZyraNotificationAckStatus.unavailable);
    expect(result.confirmedIds, isEmpty);
  });

  test('account-generation ABA cannot publish an old confirmation', () async {
    final held = _HeldResponse();
    respond = held.call;
    final pending = ZyraNotificationService.acknowledgeIds([_first]);
    try {
      await held.waitForDispatch(pending);
      await _session(_b);
      await _session(_a);
      held.complete(_confirmed([_first]));
      expect(
        (await pending.timeout(_bound)).status,
        ZyraNotificationAckStatus.revoked,
      );
      expect(requests, hasLength(1));
    } finally {
      await held.settle(pending);
    }
  });

  test(
    'SDK-only A-B-A is terminal before shared generation catches up',
    () async {
      final held = _HeldResponse();
      respond = held.call;
      final generation = ZyraAccountState.generation;
      final pending = ZyraNotificationService.acknowledgeIds([_first]);
      try {
        await held.waitForDispatch(pending);
        await _session(_b, synchronize: false);
        await _session(_a, synchronize: false);
        expect(ZyraAccountState.generation, generation);
        held.complete(_confirmed([_first]));
        expect(
          (await pending.timeout(_bound)).status,
          ZyraNotificationAckStatus.revoked,
        );
        expect(requests, hasLength(1));
      } finally {
        await held.settle(pending);
      }
    },
  );

  test('same-actor replacement session cannot complete an old ACK', () async {
    final held = _HeldResponse();
    respond = held.call;
    final pending = ZyraNotificationService.acknowledgeIds([_first]);
    try {
      await held.waitForDispatch(pending);
      await _session(_a, lifetime: 'replacement', synchronize: false);
      held.complete(_confirmed([_first]));
      expect(
        (await pending.timeout(_bound)).status,
        ZyraNotificationAckStatus.revoked,
      );
    } finally {
      await held.settle(pending);
    }
  });

  test('read also pins actor and drops a late former-account count', () async {
    final held = _HeldResponse();
    respond = held.call;
    final pending = ZyraNotificationService.fetchUnreadCount();
    try {
      final request = await held.waitForDispatch(pending);
      expect(request.url.queryParameters['user_id'], 'eq.$_a');
      await _session(_b, synchronize: false);
      held.complete(
        Response('[]', 200, headers: {'content-type': 'application/json'}),
      );
      expect(await pending.timeout(_bound), isNull);
    } finally {
      await held.settle(pending);
    }
  });

  test('invalid IDs and a revoked actor issue no mutation', () async {
    final invalid = await ZyraNotificationService.acknowledgeIds(['not-an-id']);
    expect(invalid.status, ZyraNotificationAckStatus.unavailable);
    await ZyraAccountState.beginSignOut();
    final revoked = await ZyraNotificationService.acknowledgeIds([_first]);
    expect(revoked.status, ZyraNotificationAckStatus.revoked);
    expect(requests, isEmpty);
    ZyraAccountState.endSignOutAttempt();
  });

  test(
    'active preview denies notification reads and writes despite a retained real SDK actor',
    () async {
      final revision = ZyraNotificationService.confirmedAcknowledgements.value;
      final generation = ZyraAccountState.generation;
      ZyraInternalPreviewClient.beginPreview();
      expect(supabase.auth.currentUser?.id, _a);
      expect(ZyraAccountState.generation, generation);
      expect(ZyraNotificationOwnerLease.capture(), isNull);
      expect(
        (await ZyraNotificationService.acknowledgeIds([_first])).status,
        ZyraNotificationAckStatus.revoked,
      );
      expect(await ZyraNotificationService.fetchUnreadCount(), isNull);
      expect(await ZyraNotificationService.fetchSectionsWithUnread(), isNull);
      expect(await ZyraNotificationService.fetchRecent(), isNull);
      expect(requests, isEmpty);
      expect(ZyraNotificationService.confirmedAcknowledgements.value, revision);
    },
  );

  test(
    'preview active-inactive ABA permanently revokes the opening lease and ACK',
    () async {
      final lease = ZyraNotificationOwnerLease.capture()!;
      final held = _HeldResponse();
      final revision = ZyraNotificationService.confirmedAcknowledgements.value;
      respond = held.call;
      final pending = ZyraNotificationService.acknowledgeIds([_first]);
      try {
        await held.waitForDispatch(pending);
        ZyraInternalPreviewClient.beginPreview();
        ZyraInternalPreviewClient.finishSignOut();
        expect(lease.isCurrent, isFalse);
        held.complete(_confirmed([_first]));
        expect(
          (await pending.timeout(_bound)).status,
          ZyraNotificationAckStatus.revoked,
        );
        expect(
          ZyraNotificationService.confirmedAcknowledgements.value,
          revision,
        );
        expect(requests, hasLength(1));
      } finally {
        lease.dispose();
        await held.settle(pending);
      }
    },
  );

  test(
    'a read begun before preview ABA cannot hydrate former real rows',
    () async {
      final held = _HeldResponse();
      respond = held.call;
      final pending = ZyraNotificationService.fetchUnreadCount();
      try {
        await held.waitForDispatch(pending);
        ZyraInternalPreviewClient.beginPreview();
        ZyraInternalPreviewClient.finishSignOut();
        held.complete(
          Response('[]', 200, headers: {'content-type': 'application/json'}),
        );
        expect(await pending.timeout(_bound), isNull);
        expect(requests, hasLength(1));
      } finally {
        await held.settle(pending);
      }
    },
  );

  test(
    'identifier-free revision advances only after a confirmed nonempty ACK',
    () async {
      final revision = ZyraNotificationService.confirmedAcknowledgements.value;
      var notices = 0;
      void changed() => notices++;
      ZyraNotificationService.confirmedAcknowledgements.addListener(changed);
      try {
        respond = (_) async =>
            Response('[]', 200, headers: {'content-type': 'application/json'});
        expect(
          (await ZyraNotificationService.acknowledgeIds([_first])).isConfirmed,
          isFalse,
        );
        expect(notices, 0);
        expect(
          (await ZyraNotificationService.acknowledgeIds([])).isConfirmed,
          isTrue,
        );
        expect(notices, 0);
        respond = (_) async => _confirmed([_first]);
        expect(
          (await ZyraNotificationService.acknowledgeIds([_first])).isConfirmed,
          isTrue,
        );
        expect(notices, 1);
        expect(
          ZyraNotificationService.confirmedAcknowledgements.value,
          revision + 1,
        );
      } finally {
        ZyraNotificationService.confirmedAcknowledgements.removeListener(
          changed,
        );
      }
    },
  );

  testWidgets(
    'standalone confirmed ACK refreshes the current shell immediately, not optimistically',
    (tester) async {
      var reads = 0;
      // Both completers belong to the real-async zone that awaits transport.
      // Creating them in FakeAsync then awaiting dispatch inside runAsync would
      // wait for a fake microtask that cannot be pumped until runAsync returns.
      late final _HeldResponse held;
      await tester.runAsync(() async {
        held = _HeldResponse();
      });
      respond = (request) {
        if (request.method == 'PATCH' &&
            request.url.path == '/rest/v1/notifications') {
          return held.call(request);
        }
        return Future.value(
          Response(
            '{"message":"synthetic unavailable"}',
            403,
            headers: {'content-type': 'application/json'},
          ),
        );
      };
      Future<ZyraNotificationAckResult>? pending;
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: WaliHomeShell(
              loadUnreadCount: () async => ++reads == 1 ? 3 : 0,
            ),
          ),
        );
        await _flush(tester);
        int unread() => tester
            .widget<FloatingNavBar>(find.byType(FloatingNavBar))
            .items
            .first
            .badge;
        expect(reads, 1);
        expect(unread(), 3);
        await tester.runAsync(() async {
          pending = ZyraNotificationService.acknowledgeIds([_first]);
          await held.waitForDispatch(pending!);
        });
        await _flush(tester);
        expect(reads, 1);
        expect(unread(), 3);
        final result = await tester.runAsync(() async {
          held.complete(_confirmed([_first]));
          return pending!.timeout(_bound);
        });
        await _flush(tester);
        expect(result!.isConfirmed, isTrue);
        expect(reads, 2);
        expect(unread(), 0);
      } finally {
        if (pending != null) {
          await tester.runAsync(() => held.settle(pending!));
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    },
  );

  testWidgets('a confirmed B ACK cannot refresh an old mounted A shell', (
    tester,
  ) async {
    var reads = 0;
    respond = (request) async =>
        request.method == 'PATCH' &&
            request.url.path == '/rest/v1/notifications'
        ? _confirmed([_first])
        : Response(
            '{"message":"synthetic unavailable"}',
            403,
            headers: {'content-type': 'application/json'},
          );
    await tester.pumpWidget(
      MaterialApp(
        home: WaliHomeShell(
          loadUnreadCount: () async {
            reads++;
            return 3;
          },
        ),
      ),
    );
    await _flush(tester);
    expect(reads, 1);
    await tester.runAsync(() => _session(_b));
    final result = await tester.runAsync(
      () => ZyraNotificationService.acknowledgeIds([_first]),
    );
    await _flush(tester);
    expect(result!.isConfirmed, isTrue);
    expect(reads, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test(
    'Dashboard domain events and guessed IDs cannot become notification ACKs',
    () {
      String? resolve(String id, bool? unread) =>
          ZyraNotificationService.dashboardNotificationId(id, unread);
      expect(resolve('update:notification.new_message:$_first', true), _first);
      expect(resolve('update:notification.new_message:$_first', false), isNull);
      expect(resolve('update:notification.new_message:$_first', null), isNull);
      expect(resolve('update:journey.started:$_first', true), isNull);
      expect(resolve('update:notification.unknown:$_first', true), isNull);
      expect(resolve('notification:$_first', true), isNull);
      expect(resolve('update:notification.new_message:guessed', true), isNull);
    },
  );

  testWidgets(
    'a retained standalone read action cannot revive after preview ABA',
    (tester) async {
      respond = (_) async => _confirmed([_first]);
      Future<List<ZyraNotification>> loader() async => [_notification(_first)];
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(isTab: true, loadNotifications: loader),
        ),
      );
      await _flush(tester);
      final retained = _strip(tester, 'Mark all read');
      ZyraInternalPreviewClient.beginPreview();
      ZyraInternalPreviewClient.finishSignOut();
      retained();
      await _flush(tester);
      expect(requests, isEmpty);
      expect(find.text('Previously displayed event'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('confirmed displayed bulk leaves a later arrival unread', (
    tester,
  ) async {
    var loads = 0;
    respond = (_) async => _confirmed([_first]);
    Future<List<ZyraNotification>> loader() async => ++loads == 1
        ? [_notification(_first)]
        : [_notification(_first, read: true), _notification(_later)];
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(isTab: true, loadNotifications: loader),
      ),
    );
    await _flush(tester);
    _strip(tester, 'Mark all read')();
    await _flush(tester);
    expect(find.text('New arrival'), findsOneWidget);
    expect(requests, hasLength(1));
    expect(requests.single.url.queryParameters['id'], 'in.("$_first")');
    expect(loads, 2);
    expect(_strip(tester, 'Mark all read'), isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('failed selected ACK retains selected unread row for retry', (
    tester,
  ) async {
    respond = (_) async => Response(
      '{"message":"synthetic unavailable"}',
      403,
      headers: {'content-type': 'application/json'},
    );
    Future<List<ZyraNotification>> loader() async => [_notification(_first)];
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(isTab: true, loadNotifications: loader),
      ),
    );
    await _flush(tester);
    _strip(tester, 'Select')();
    await tester.pump();
    _strip(tester, 'Select all')();
    await tester.pump();
    _strip(tester, 'Mark read')();
    await _flush(tester);
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(
      find.text("Couldn't mark these notifications as read. Try again."),
      findsOneWidget,
    );
    expect(find.text('Previously displayed event'), findsOneWidget);
    expect(requests, hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
