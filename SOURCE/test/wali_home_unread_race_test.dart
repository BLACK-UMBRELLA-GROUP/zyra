import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/screens/wali/wali_home_shell.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'synthetic-widget-test-key',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient(
        (_) async => http.Response(
          '{"message":"synthetic offline test"}',
          403,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
  });

  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    AppState.instance.setWaliRealLinkedSeekers(const []);
  });

  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    AppState.instance.setWaliRealLinkedSeekers(const []);
  });

  int badge(WidgetTester tester) => tester
      .widget<FloatingNavBar>(find.byType(FloatingNavBar))
      .items
      .first
      .badge;

  testWidgets('Guardian unread badge ignores an older poll', (tester) async {
    final older = Completer<int?>();
    final newer = Completer<int?>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: WaliHomeShell(
          loadUnreadCount: () => ++calls == 1 ? older.future : newer.future,
        ),
      ),
    );
    expect(calls, 1);

    tester.widget<FloatingNavBar>(find.byType(FloatingNavBar)).onTap(1);
    await tester.pump();
    expect(calls, 2);
    newer.complete(2);
    await tester.pump();
    expect(badge(tester), 2);
    older.complete(5);
    await tester.pump();
    expect(badge(tester), 2);
  });

  testWidgets('Guardian badge holds last confirmed count on failed refresh', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: WaliHomeShell(
          loadUnreadCount: () async => ++calls == 1 ? 3 : null,
        ),
      ),
    );
    await tester.pump();
    expect(badge(tester), 3);
    tester.widget<FloatingNavBar>(find.byType(FloatingNavBar)).onTap(1);
    await tester.pump();
    expect(calls, 2);
    expect(badge(tester), 3);
  });

  testWidgets('Guardian badge discards same-ID generation revocation', (
    tester,
  ) async {
    final pending = Completer<int?>();
    await tester.pumpWidget(
      MaterialApp(home: WaliHomeShell(loadUnreadCount: () => pending.future)),
    );
    ZyraAccountState.resetForTesting();
    pending.complete(9);
    await tester.pump();
    expect(badge(tester), 0);
  });
}
