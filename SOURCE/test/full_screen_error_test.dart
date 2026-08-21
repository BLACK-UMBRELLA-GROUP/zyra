import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_error_state.dart';
import 'package:zyra/widgets/zyra_full_screen_error.dart';

void main() {
  test('classifies the four failure families without exposing exceptions', () {
    expect(
      zyraErrorKindFor(TimeoutException('hidden timeout detail')),
      ZyraErrorKind.offline,
    );
    expect(
      zyraErrorKindFor(Exception('refresh token has expired')),
      ZyraErrorKind.sessionExpired,
    );
    expect(
      zyraErrorKindFor(Exception('503 service unavailable')),
      ZyraErrorKind.serviceUnavailable,
    );
    expect(
      zyraErrorKindFor(Exception('unexpected render failure')),
      ZyraErrorKind.page,
    );

    final reference = zyraErrorReference(Exception('private backend detail'));
    expect(reference, matches(RegExp(r'^ZY-[0-9A-Z]{4}$')));
    expect(reference, isNot(contains('private')));
  });

  for (final kind in ZyraErrorKind.values) {
    testWidgets('${kind.name} is a complete branded recovery screen', (
      tester,
    ) async {
      var primaryTaps = 0;
      var secondaryTaps = 0;
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: ZyraFullScreenError(
            kind: kind,
            referenceCode: 'ZY-TEST',
            onPrimary: () => primaryTaps++,
            onSecondary: () => secondaryTaps++,
          ),
        ),
      );

      expect(
        find.byKey(ValueKey('zyra_error_screen_${kind.name}')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('zyra_error_connection_mark')),
        findsOneWidget,
      );
      expect(find.text(kind.content.title), findsOneWidget);
      expect(find.text(kind.content.message), findsOneWidget);
      expect(find.text('REFERENCE: ZY-TEST'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('zyra_error_primary')));
      await tester.tap(find.byKey(const ValueKey('zyra_error_secondary')));
      expect(primaryTaps, 1);
      expect(secondaryTaps, 1);
    });
  }
}
