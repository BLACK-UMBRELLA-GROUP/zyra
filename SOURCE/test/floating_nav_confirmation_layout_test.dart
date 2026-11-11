import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/confirm_sheet_test_entry.dart';

void main() {
  for (final width in [320.0, 393.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Hide confirmation fits ${width}px at ${scale}x text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final choices = <bool?>[];
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(top: 59, bottom: 34),
                viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: Scaffold(
              body: ConfirmSheetTestEntry(onDecision: choices.add),
            ),
          ),
        );
        for (final (key, label) in [
          ('browse-hide-cancel', 'Keep profile'),
          ('browse-hide-confirm', 'Hide profile'),
        ]) {
          await tester.tap(find.text('Open confirmation'));
          await tester.pumpAndSettle();
          final finder = find.byKey(ValueKey(key));
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          final bounds = tester.getRect(finder);
          final text = tester.getRect(find.text(label));
          expect(bounds.height, greaterThanOrEqualTo(52));
          expect(bounds.left, 20);
          expect(bounds.right, width - 20);
          expect(text.left, greaterThanOrEqualTo(bounds.left));
          expect(text.right, lessThanOrEqualTo(bounds.right));
          expect(text.top, greaterThanOrEqualTo(bounds.top));
          expect(text.bottom, lessThanOrEqualTo(bounds.bottom));
          expect(finder.hitTestable(), findsOneWidget);
          await tester.tap(finder);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(choices, [false, true]);
      });
    }
  }
}
