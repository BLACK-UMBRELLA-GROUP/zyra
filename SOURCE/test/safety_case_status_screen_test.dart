import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/settings/safety_case_status_screen.dart';
import 'package:zyra/services/zyra_report_service.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUpAll(() => ZyraText.useTestFontStubs = true);
  tearDownAll(() => ZyraText.useTestFontStubs = false);

  testWidgets('shows the caller safety statuses without member identities', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SafetyCaseStatusScreen(
          loadCases: () async => [
            ZyraSafetyCase(
              id: 'case-1',
              type: 'guardian_circle',
              status: 'reviewing',
              createdAt: DateTime(2026, 9, 24),
              updatedAt: null,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Guardian Circle report'), findsOneWidget);
    expect(find.text('Under review'), findsOneWidget);
    expect(find.text('Submitted 24 Sep 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('successful empty and failed reads remain distinct', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SafetyCaseStatusScreen(loadCases: () async => [])),
    );
    await tester.pumpAndSettle();
    expect(find.text('No reports submitted'), findsOneWidget);
    expect(find.text('Your safety reports'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: SafetyCaseStatusScreen(
          key: UniqueKey(),
          loadCases: () async => null,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No reports submitted'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets(
    'local preview shows a truthful empty state without a live read',
    (tester) async {
      ZyraInternalPreviewClient.beginPreview();
      addTearDown(ZyraInternalPreviewClient.finishSignOut);

      await tester.pumpWidget(
        const MaterialApp(home: SafetyCaseStatusScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('No reports submitted'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
