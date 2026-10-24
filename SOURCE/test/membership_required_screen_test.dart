import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/zyra_release_gates.dart';
import 'package:zyra/screens/subscription/membership_required_screen.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUpAll(() => ZyraText.useTestFontStubs = true);
  tearDownAll(() => ZyraText.useTestFontStubs = false);

  test('paid-only boundary remains held until receipt authority deploys', () {
    expect(ZyraReleaseGates.paidOnlyMembershipEnforced, isFalse);
  });

  for (final guardian in [false, true]) {
    testWidgets('locked ${guardian ? 'Guardian' : 'Seeker'} keeps essentials', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(home: MembershipRequiredScreen(guardian: guardian)),
      );
      await tester.pumpAndSettle();

      expect(tester.widget<Text>(find.text('ZYRA')).style?.fontFamily, 'Syne');
      expect(find.text('Your membership is not active'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('membership-required-restore')),
        findsOneWidget,
      );
      expect(find.text('Safety case status'), findsOneWidget);
      expect(find.text('Safety & support'), findsOneWidget);
      expect(find.text('Privacy & data'), findsOneWidget);
      expect(find.text('Download or delete account data'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('membership-required-sign-out')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
