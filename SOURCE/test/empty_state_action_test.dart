import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  testWidgets('empty-state action is a working 40pt gold outline control', (
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
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(tester.getSize(find.byType(OutlinedButton)).height, equals(40));
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
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Larger Text remains scrollable and revoked actions stay inert', (
    tester,
  ) async {
    var current = true;
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SizedBox(
              width: 320,
              height: 300,
              child: ZyraEmptyState(
                icon: Icons.forum_outlined,
                title: 'No requests sent yet.',
                message:
                    'Find a family in Network and choose Connect with Guardian.',
                ctaLabel: 'Open Network',
                onCta: () => taps++,
                canAct: () => current,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Open Network'));
    await tester.tap(find.text('Open Network'));
    expect(taps, 1);
    current = false;
    await tester.tap(find.text('Open Network'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'existing blank-page invitation reuses the shared layout and action',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZyraAddCircle(label: 'Invite a Seeker', onTap: () => taps++),
          ),
        ),
      );
      expect(find.byType(ZyraEmptyState), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      await tester.tap(find.byIcon(Icons.add_outlined));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
