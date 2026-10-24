import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/onboarding/account_path_overview_screen.dart';
import 'package:zyra/services/zyra_profile_service.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_loading.dart';

void main() {
  setUpAll(() => ZyraText.useTestFontStubs = true);
  tearDownAll(() => ZyraText.useTestFontStubs = false);

  testWidgets('pending overview uses shared accessible loading before Retry', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final progress = Completer<ZyraOnboardingProgress?>();
      var reads = 0;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: SeekerOnboardingOverviewScreen(
            gender: 'female',
            progressLoader: () {
              reads++;
              return progress.future;
            },
          ),
        ),
      );

      expect(reads, 1);
      expect(find.byType(ZyraLoading), findsOneWidget);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.widgetWithText(TextButton, 'Try again'), findsNothing);
      expect(tester.takeException(), isNull);

      progress.completeError(StateError('Synthetic unreadable progress'));
      await tester.pumpAndSettle();
      expect(find.byType(ZyraLoading), findsNothing);
      expect(find.textContaining('saved setup could not be loaded'), findsOne);
      expect(find.widgetWithText(TextButton, 'Try again'), findsOne);
      expect(find.widgetWithText(TextButton, 'Back'), findsNothing);
      expect(reads, 1);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('root overview error keeps Retry without a dead Back action', (
    tester,
  ) async {
    var reads = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SeekerOnboardingOverviewScreen(
          gender: 'female',
          progressLoader: () async {
            reads++;
            throw StateError('Synthetic unreadable progress');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('saved setup could not be loaded'), findsOne);
    expect(find.widgetWithText(TextButton, 'Back'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Try again'), findsOne);
    expect(reads, 1);

    await tester.tap(find.widgetWithText(TextButton, 'Try again'));
    await tester.pumpAndSettle();

    expect(reads, 2);
    expect(find.textContaining('saved setup could not be loaded'), findsOne);
    expect(find.widgetWithText(TextButton, 'Back'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pushed overview error has a working Back action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => SeekerOnboardingOverviewScreen(
                    gender: 'female',
                    progressLoader: () async =>
                        throw StateError('Synthetic unreadable progress'),
                  ),
                ),
              ),
              child: const Text('Open setup'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open setup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('saved setup could not be loaded'), findsOne);
    expect(find.widgetWithText(TextButton, 'Back'), findsOne);
    await tester.tap(find.widgetWithText(TextButton, 'Back'));
    await tester.pumpAndSettle();

    expect(find.byType(SeekerOnboardingOverviewScreen), findsNothing);
    expect(find.text('Open setup'), findsOne);
    expect(tester.takeException(), isNull);
  });
}
