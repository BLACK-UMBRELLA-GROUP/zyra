import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  const message =
      'That change was not confirmed. Showing the last confirmed Journey access.';
  const bannerKey = ValueKey('error-banner-under-test');

  for (final scale in [1.0, 2.0]) {
    for (final controls in [
      (retry: true, dismiss: true),
      (retry: true, dismiss: false),
      (retry: false, dismiss: true),
      (retry: false, dismiss: false),
    ]) {
      testWidgets(
        '320px banner fits at ${scale}x with retry=${controls.retry}, '
        'dismiss=${controls.dismiss}',
        (tester) async {
          tester.view.physicalSize = const Size(320, 700);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var retries = 0;
          var dismissals = 0;
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 320,
                    child: ZyraErrorBanner(
                      key: bannerKey,
                      message: message,
                      onRetry: controls.retry ? () => retries++ : null,
                      onDismiss: controls.dismiss ? () => dismissals++ : null,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text(message), findsOneWidget);
          final bounds = tester.getRect(find.byKey(bannerKey));
          expect(bounds.width, 320);
          expect(
            tester.getRect(find.text(message)).right,
            lessThanOrEqualTo(bounds.right),
          );

          if (controls.retry) {
            final retry = find.widgetWithText(TextButton, 'Try again');
            expect(retry, findsOneWidget);
            expect(
              tester.getRect(retry).right,
              lessThanOrEqualTo(bounds.right),
            );
            await tester.tap(retry);
            await tester.pumpAndSettle();
            expect(retries, 1);
            expect(dismissals, 0);
          } else {
            expect(find.text('Try again'), findsNothing);
            expect(retries, 0);
          }

          if (controls.dismiss) {
            final dismiss = find.byIcon(Icons.close);
            expect(dismiss, findsOneWidget);
            expect(bounds.contains(tester.getCenter(dismiss)), isTrue);
            await tester.tap(dismiss);
            await tester.pumpAndSettle();
            expect(dismissals, 1);
            expect(retries, controls.retry ? 1 : 0);
          } else {
            expect(find.byIcon(Icons.close), findsNothing);
            expect(dismissals, 0);
          }
          expect(find.text(message), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
