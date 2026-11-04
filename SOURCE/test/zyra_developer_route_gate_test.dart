import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/widgets/zyra_account_session_host.dart';

void main() {
  tearDown(() => ZyraDeveloperAccess.setAuthorizedForTesting(false));

  testWidgets(
    'stale local proof cannot retain content after a fresh resume check fails',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      final navigator = GlobalKey<NavigatorState>();
      var allowed = true, refreshes = 0;
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          builder: (context, child) => ZyraAccountSessionHost(
            navigatorKey: navigator,
            authStateChangesOverride: const Stream.empty(),
            authorizationReaderOverride: () => allowed,
            resumeAuthorizationRefreshOverride: () async {
              refreshes++;
              allowed = false;
              return false;
            },
            authorityLossDestinationBuilder: (_) =>
                const Scaffold(body: Text('Denied safely')),
            child: child!,
          ),
          home: const Scaffold(body: Text('Protected content')),
        ),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(refreshes, 1);
      expect(find.text('Protected content'), findsNothing);
      expect(find.text('Denied safely'), findsOneWidget);
    },
  );

  testWidgets('fresh resume authorization preserves the protected content', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    final navigator = GlobalKey<NavigatorState>();
    var refreshes = 0;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        builder: (context, child) => ZyraAccountSessionHost(
          navigatorKey: navigator,
          authStateChangesOverride: const Stream.empty(),
          resumeAuthorizationRefreshOverride: () async {
            refreshes++;
            return true;
          },
          child: child!,
        ),
        home: const Scaffold(body: Text('Protected content')),
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(refreshes, 1);
    expect(find.text('Protected content'), findsOneWidget);
  });

  test('retired developer leaves are absent from production source', () {
    for (final path in const ['lib/dev/zyra_page_preview_screen.dart']) {
      expect(File(path).existsSync(), isFalse, reason: path);
    }
  });
}
