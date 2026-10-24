// Synthetic SDK sessions and injected rows only. All transport is intercepted;
// an old notification callback must never dispatch a read mutation to it.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/main.dart' show supabase;
import 'package:zyra/screens/notifications/notifications_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_notification_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';

const _a = '00000000-0000-4000-8000-000000004811';
const _b = '00000000-0000-4000-8000-000000004812';

Map<String, dynamic> _sessionJson(
  String id, {
  String sessionMarker = 'opening',
  String tokenMarker = 'opening',
}) {
  String part(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return {
    'access_token':
        '${part({'alg': 'none'})}.${part({'sub': id, 'exp': 4102444800, 'session_id': sessionMarker, 'jti': tokenMarker})}.synthetic',
    'token_type': 'bearer',
    'refresh_token': 'synthetic-refresh',
    'user': {
      'id': id,
      'app_metadata': <String, Object?>{},
      'user_metadata': <String, Object?>{},
      'aud': 'authenticated',
      'created_at': '2026-10-18T00:00:00Z',
    },
  };
}

Future<void> _session(
  String id, {
  bool synchronize = true,
  String sessionMarker = 'opening',
}) async {
  await supabase.auth.setInitialSession(
    jsonEncode(_sessionJson(id, sessionMarker: sessionMarker)),
  );
  if (synchronize) await ZyraAccountState.synchronize(id);
}

void _emit(AuthChangeEvent event, Session session) {
  // Local event payload only; no server call or authorization publication.
  // ignore: invalid_use_of_internal_member
  supabase.auth.notifyAllSubscribers(event, session: session, broadcast: false);
}

Future<void> _flush(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

ZyraNotification _row() => ZyraNotification(
  id: 'synthetic-row-for-opening-owner',
  type: 'new_message',
  title: 'Opening account event',
  body: 'Opening account private body',
  relatedMatchId: null,
  createdAt: DateTime.utc(2026, 10, 18),
  readAt: null,
);

VoidCallback _strip(WidgetTester tester, String label) => tester
    .widget<InkWell>(
      find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first,
    )
    .onTap!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <String>[];
  var reads = 0;
  late ZyraNotificationsLoader loader;

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
        requests.add('${request.method} ${request.url.path}');
        throw StateError('Notification fixture transport must remain unused.');
      }),
    );
  });
  setUp(() async {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    AppState.instance.resetForAccountChange();
    requests.clear();
    reads = 0;
    loader = () async {
      reads++;
      return [_row()];
    };
    await _session(_a);
  });
  tearDown(() {
    expect(requests, isEmpty);
    ZyraAccountState.clearImagesForTesting = null;
    ZyraText.useTestFontStubs = false;
  });
  tearDownAll(() => Supabase.instance.dispose());

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationsScreen(isTab: true, loadNotifications: loader),
      ),
    );
    await _flush(tester);
    expect(find.text('Opening account event'), findsOneWidget);
    expect(reads, 1);
    expect(tester.takeException(), isNull);
  }

  void expectWithdrawn(WidgetTester tester) {
    expect(find.text('Opening account event'), findsNothing);
    expect(find.text('Opening account private body'), findsNothing);
    expect(find.text("Couldn't load notifications"), findsOneWidget);
    expect(reads, 1);
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'SDK-only owner replacement denies before shared state catches up',
    (tester) async {
      await mount(tester);
      final action = _strip(tester, 'Mark all read');
      final generation = ZyraAccountState.generation;
      final replacement = _session(_b, synchronize: false);
      expect(supabase.auth.currentUser?.id, _b);
      expect(ZyraAccountState.userId, _a);
      action();
      await tester.runAsync(() => replacement);
      await _flush(tester);
      expect(ZyraAccountState.generation, generation);
      expectWithdrawn(tester);
    },
  );

  testWidgets('queued SDK-only ABA cannot revive loaded A rows or callbacks', (
    tester,
  ) async {
    await mount(tester);
    final select = _strip(tester, 'Select');
    final markAll = _strip(tester, 'Mark all read');
    final generation = ZyraAccountState.generation;
    final toB = _session(_b, synchronize: false);
    final backToA = _session(_a, synchronize: false);
    expect(supabase.auth.currentUser?.id, _a);
    await tester.runAsync(() async => Future.wait([toB, backToA]));
    await _flush(tester);
    select();
    markAll();
    await _flush(tester);
    expect(ZyraAccountState.generation, generation);
    expect(ZyraAccountState.userId, _a);
    expectWithdrawn(tester);
  });

  testWidgets(
    'same-ID replacement session remains terminal without generation change',
    (tester) async {
      await mount(tester);
      final action = _strip(tester, 'Mark all read');
      final generation = ZyraAccountState.generation;
      await tester.runAsync(
        () => _session(_a, synchronize: false, sessionMarker: 'replacement'),
      );
      await _flush(tester);
      await tester.runAsync(() => _session(_a, synchronize: false));
      await _flush(tester);
      action();
      await _flush(tester);
      expect(ZyraAccountState.generation, generation);
      expectWithdrawn(tester);
    },
  );

  for (final event in [
    AuthChangeEvent.signedIn,
    AuthChangeEvent.signedOut,
    AuthChangeEvent.passwordRecovery,
  ]) {
    testWidgets('${event.name} terminates the notification opening lifetime', (
      tester,
    ) async {
      await mount(tester);
      final action = _strip(tester, 'Mark all read');
      _emit(event, supabase.auth.currentSession!);
      await _flush(tester);
      action();
      await _flush(tester);
      expectWithdrawn(tester);
    });
  }

  testWidgets(
    'Auth stream errors withdraw loaded rows without an unhandled error',
    (tester) async {
      await mount(tester);
      final action = _strip(tester, 'Mark all read');
      // Synthetic SDK stream error only, never a refresh/network operation.
      // ignore: invalid_use_of_internal_member
      supabase.auth.notifyException(
        StateError('Synthetic Auth stream failure.'),
      );
      await _flush(tester);
      action();
      await _flush(tester);
      expectWithdrawn(tester);
    },
  );

  testWidgets(
    'same-owner healthy refresh preserves current rows and local selection',
    (tester) async {
      await mount(tester);
      final generation = ZyraAccountState.generation;
      final opening = supabase.auth.currentSession!;
      final refreshed = Session.fromJson(
        _sessionJson(_a, tokenMarker: 'healthy-refresh'),
      )!;
      _emit(AuthChangeEvent.initialSession, opening);
      _emit(AuthChangeEvent.tokenRefreshed, refreshed);
      _emit(AuthChangeEvent.userUpdated, refreshed);
      await _flush(tester);
      expect(find.text('Opening account event'), findsOneWidget);
      _strip(tester, 'Select')();
      await tester.pump();
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Select all'), findsOneWidget);
      expect(ZyraAccountState.generation, generation);
      expect(requests, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'same-State delegate replacement withdraws rows without dispatching the new source',
    (tester) async {
      await mount(tester);
      final oldState = tester.state(find.byType(NotificationsScreen));
      final action = _strip(tester, 'Mark all read');
      var replacementReads = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationsScreen(
            isTab: true,
            loadNotifications: () async {
              replacementReads++;
              return [_row()];
            },
          ),
        ),
      );
      await _flush(tester);
      action();
      tester.widget<ZyraEmptyState>(find.byType(ZyraEmptyState)).onCta!();
      await _flush(tester);
      expect(tester.state(find.byType(NotificationsScreen)), same(oldState));
      expect(replacementReads, 0);
      expectWithdrawn(tester);
    },
  );
}
