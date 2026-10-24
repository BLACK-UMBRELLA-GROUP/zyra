import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_initial_signup_draft.dart';
import 'package:zyra/screens/auth/role_selection_screen.dart';
import 'package:zyra/screens/onboarding/account_path_overview_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/theme/zyra_text.dart';

import 'initial_signup_draft_test.dart' show FakeSignupStore;

void main() {
  const accountId = 'onboarding-account-exit-test';

  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraInitialSignupDraftService.setRepositoryForTesting(
      ZyraSignupDraftRepository(
        store: FakeSignupStore(),
        backend: 'https://example.invalid',
        currentUserId: () => accountId,
        isPreview: () => false,
      ),
    );
    ZyraText.useTestFontStubs = true;
  });

  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
    ZyraText.useTestFontStubs = false;
  });

  Future<void> show(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pumpAndSettle();
  }

  testWidgets('pre-profile Seeker introduction exposes the account exit', (
    tester,
  ) async {
    await show(tester, const OnboardingFlow(signupUserId: accountId));

    expect(find.byKey(const ValueKey('onboarding_account_exit')), findsWidgets);
    expect(
      find.byKey(const ValueKey('onboarding_account_exit')).hitTestable(),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey('onboarding_stage_account_essentials')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('onboarding_account_exit')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('role selection exposes the account exit', (tester) async {
    await show(tester, const RoleSelectionScreen(signupUserId: accountId));

    expect(
      find.byKey(const ValueKey('onboarding_account_exit')),
      findsOneWidget,
    );
  });

  testWidgets('pre-profile Seeker questions expose the account exit', (
    tester,
  ) async {
    await show(
      tester,
      const OnboardingFlow(
        signupUserId: accountId,
        initialDraft: ZyraInitialSignupDraft(
          role: ZyraSignupRole.seeker,
          showIntroduction: false,
        ),
      ),
    );

    expect(find.text("What's your name?"), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding_first_name')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding_last_name')), findsOneWidget);
    expect(
      find.text('Both names will appear on your public profile.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('onboarding_account_exit')),
      findsOneWidget,
    );
  });

  testWidgets('Seeker developer preview suppresses the account exit', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await show(tester, const OnboardingFlow(devPreview: true));

    expect(find.byKey(const ValueKey('onboarding_account_exit')), findsNothing);

    tester
        .widget<AccountEssentialsIntroScreen>(
          find.byType(AccountEssentialsIntroScreen),
        )
        .onContinue();
    await tester.pumpAndSettle();

    expect(find.text("What's your name?"), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding_first_name')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding_last_name')), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding_account_exit')), findsNothing);
  });

  testWidgets(
    'Guardian initial overview exposes the account exit but migration preview does not',
    (tester) async {
      await show(
        tester,
        const GuardianOnboardingOverviewScreen(signupUserId: accountId),
      );
      expect(
        find.byKey(const ValueKey('onboarding_account_exit')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: GuardianOnboardingOverviewScreen(migrationGatedPreview: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('onboarding_account_exit')),
        findsNothing,
      );
    },
  );

  testWidgets('Guardian questions expose the exit outside developer preview', (
    tester,
  ) async {
    await show(tester, const WaliOnboardingFlow(signupUserId: accountId));
    expect(
      find.byKey(const ValueKey('onboarding_account_exit')),
      findsOneWidget,
    );

    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pumpWidget(
      const MaterialApp(home: WaliOnboardingFlow(devPreview: true)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('onboarding_account_exit')), findsNothing);
  });
}
