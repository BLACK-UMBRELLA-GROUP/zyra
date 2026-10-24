import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_onboarding_directions.dart';
import 'package:zyra/dev/dev_onboarding_interaction.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';

const _continue = ValueKey('dev_onboarding_advance_continueButton');
const _arrow = ValueKey('dev_onboarding_advance_animatedDownArrow');

Widget _picker({bool enabled = true}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: DevOnboardingDirectionPicker(enabled: enabled),
    ),
  ),
);

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraDevOnboardingInteraction.resetForTesting();
  });

  tearDown(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraText.useTestFontStubs = false;
    ZyraDevOnboardingInteraction.resetForTesting();
  });

  testWidgets('two-mode control is independent of all eleven directions', (
    tester,
  ) async {
    await tester.pumpWidget(_picker());
    expect(
      ZyraDevOnboardingInteraction.current,
      ZyraOnboardingAdvanceMode.animatedDownArrow,
    );
    expect(find.byKey(_continue), findsOneWidget);
    expect(find.byKey(_arrow), findsOneWidget);
    for (final direction in ZyraOnboardingDirection.values) {
      expect(
        find.byKey(ValueKey('dev_onboarding_${direction.name}')),
        findsOneWidget,
      );
    }

    await tester.ensureVisible(find.byKey(_continue));
    await tester.tap(find.byKey(_continue));
    await tester.pumpAndSettle();
    expect(
      ZyraDevOnboardingInteraction.current,
      ZyraOnboardingAdvanceMode.continueButton,
    );
    expect(
      find.byKey(const ValueKey('dev_onboarding_current')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('dev_onboarding_atoms')), findsOneWidget);

    await tester.tap(find.byKey(_arrow));
    await tester.pumpAndSettle();
    expect(
      ZyraDevOnboardingInteraction.current,
      ZyraOnboardingAdvanceMode.animatedDownArrow,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled control and revoked access cannot change selection', (
    tester,
  ) async {
    await tester.pumpWidget(_picker(enabled: false));
    expect(tester.widget<InkWell>(find.byKey(_continue)).onTap, isNull);
    expect(
      ZyraDevOnboardingInteraction.select(
        ZyraOnboardingAdvanceMode.continueButton,
      ),
      isTrue,
    );
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    expect(
      ZyraDevOnboardingInteraction.select(
        ZyraOnboardingAdvanceMode.animatedDownArrow,
      ),
      isFalse,
    );
    expect(
      ZyraDevOnboardingInteraction.current,
      ZyraOnboardingAdvanceMode.continueButton,
    );
  });

  testWidgets(
    'a new account generation restores the down arrow without persistence',
    (tester) async {
      await tester.pumpWidget(_picker());
      await tester.ensureVisible(find.byKey(_continue));
      await tester.tap(find.byKey(_continue));
      await tester.pumpAndSettle();
      expect(
        ZyraDevOnboardingInteraction.current,
        ZyraOnboardingAdvanceMode.continueButton,
      );

      ZyraAccountState.resetForTesting();
      expect(
        ZyraDevOnboardingInteraction.current,
        ZyraOnboardingAdvanceMode.animatedDownArrow,
      );
      await tester.pumpWidget(_picker());
      await tester.ensureVisible(find.byKey(_continue));
      await tester.tap(find.byKey(_continue));
      await tester.pumpAndSettle();
      expect(
        ZyraDevOnboardingInteraction.current,
        ZyraOnboardingAdvanceMode.continueButton,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
