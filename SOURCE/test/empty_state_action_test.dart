import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  testWidgets('empty-state action is a standard 48px working primary control', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZyraEmptyState(
            icon: Icons.refresh_outlined,
            title: 'Unavailable',
            message: 'Your information could not be confirmed.',
            ctaLabel: 'Try again',
            onCta: () => taps++,
          ),
        ),
      ),
    );
    expect(find.byType(FilledButton), findsOneWidget);
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.text('Try again'));
    expect(taps, 1);
    expect(
      tester.widget<Text>(find.text('Try again')).style!.fontFamily,
      'Poppins',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unavailable empty-state action is visibly disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ZyraEmptyState(
            icon: Icons.lock_outline,
            message: 'This action is not available.',
            ctaLabel: 'Continue',
          ),
        ),
      ),
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
