// Rendering a protected settings shell without an Auth SDK is harmless.
// This file deliberately never initializes Supabase or invokes a service.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/settings/account_advanced_screen.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_auth.dart';
import 'package:zyra/services/zyra_profile_service.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  testWidgets(
    'Advanced without an Auth client renders disabled actions',
    (tester) async {
      ZyraText.useTestFontStubs = true;
      ZyraAccountState.resetForTesting();
      addTearDown(() {
        ZyraText.useTestFontStubs = false;
        ZyraAccountState.resetForTesting();
      });
      await tester.pumpWidget(const MaterialApp(home: AccountAdvancedScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Advanced'), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (final button in tester.widgetList<InkWell>(find.byType(InkWell))) {
        expect(button.onTap, isNull);
      }
      expect(await ZyraAuth.deleteAccount(), isFalse);
      expect(
        (await ZyraProfileService.resetProfile()).outcome,
        ZyraResetOutcome.refused,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );
}
