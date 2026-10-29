import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_developer_route_gate.dart';
import 'package:zyra/services/zyra_developer_access.dart';

void main() {
  tearDown(() => ZyraDeveloperAccess.setAuthorizedForTesting(false));

  testWidgets(
    'stale local proof cannot paint content after the fresh check fails',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);

      await tester.pumpWidget(
        MaterialApp(
          home: ZyraDeveloperRouteGate(
            refreshOverride: () async => false,
            deniedDestinationBuilder: (_) =>
                const Scaffold(body: Text('Denied safely')),
            child: const Scaffold(body: Text('Protected content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Protected content'), findsNothing);
      expect(find.text('Denied safely'), findsOneWidget);
    },
  );

  testWidgets('fresh authorization paints the protected content', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);

    await tester.pumpWidget(
      MaterialApp(
        home: ZyraDeveloperRouteGate(
          refreshOverride: () async => true,
          child: const Scaffold(body: Text('Protected content')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Protected content'), findsOneWidget);
  });

  test('every direct developer leaf uses the fresh route gate', () {
    for (final path in const ['lib/dev/zyra_page_preview_screen.dart']) {
      expect(
        File(path).readAsStringSync(),
        contains('ZyraDeveloperRouteGate'),
        reason: path,
      );
    }
  });
}
