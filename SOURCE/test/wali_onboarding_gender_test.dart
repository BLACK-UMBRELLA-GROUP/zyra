import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/services/zyra_developer_access.dart';

void main() {
  setUp(() => ZyraDeveloperAccess.setAuthorizedForTesting(true));
  tearDown(() => ZyraDeveloperAccess.setAuthorizedForTesting(false));
  testWidgets('Guardian onboarding captures female identity before relation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: WaliOnboardingFlow(devPreview: true)),
    );
    expect(tester.takeException(), isNull, reason: 'name page');

    await tester.tap(find.byKey(const ValueKey('onboarding_dev_skip')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'date-of-birth page');
    await tester.tap(find.byKey(const ValueKey('onboarding_dev_skip')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'gender page');

    expect(find.text('What’s your gender?'), findsOneWidget);
    await tester.tap(find.text('Female'));
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'female selected');
    await tester.tap(find.byKey(const ValueKey('wali_onboarding_continue')));
    await tester.pumpAndSettle();

    expect(
      find.text('What is your relationship to the Seeker you support?'),
      findsOneWidget,
    );
    expect(find.text('Mother'), findsOneWidget);
    expect(find.text('Father'), findsNothing);
    expect(tester.takeException(), isNull, reason: 'relationship page');
  });
}
