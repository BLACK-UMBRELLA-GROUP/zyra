import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/auth/role_selection_screen.dart';
import 'package:zyra/services/zyra_auth.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'support/queue44_removed_controls_fixture.dart';
import 'support/queue44_signup_flow_fixture.dart';
import 'support/queue44_gold_fixture.dart';

Future<BuildContext> _member(
  WidgetTester tester,
  String role, {
  double scale = 1,
}) async {
  final Widget page = switch (role) {
    'Seeker' => const OnboardingFlow(devPreview: true),
    'Guardian' => const WaliOnboardingFlow(devPreview: true),
    _ => const WelcomeScreen(),
  };
  await tester.pumpWidget(Queue44MemberFrame(scale: scale, child: page));
  await tester.pumpAndSettle();
  if (role == 'Seeker') {
    tester
        .widget<OnboardingStageIntroScreen>(
          find.byType(OnboardingStageIntroScreen),
        )
        .onContinue();
    await tester.pumpAndSettle();
  }
  final finder = switch (role) {
    'Seeker' => find.byType(OnboardingFlow),
    'Guardian' => find.byType(WaliOnboardingFlow),
    _ => find.byType(WelcomeScreen),
  };
  if (role != 'entry') {
    await tester.enterText(
      find.byKey(const ValueKey('onboarding_first_name')),
      'Existing $role',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }
  expectQueue44ControlsAbsent();
  return tester.element(finder);
}

Future<void> _start(WidgetTester tester, BuildContext context) async {
  OnboardingFixtureLauncher.start(context);
  await tester.pumpAndSettle();
  expect(find.byType(SignupFlowFixture), findsOneWidget);
  expect(find.byType(WelcomeScreen), findsOneWidget);
  expect(OnboardingFixtureController.instance.canCloseOnboarding, isTrue);
}

Future<void> _close(WidgetTester tester) async {
  expect(OnboardingFixtureController.instance.closeOnboarding(), isTrue);
  await tester.pumpAndSettle();
  expect(find.byType(SignupFlowFixture), findsNothing);
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    OnboardingFixtureController.instance.resetForTesting();
  });
  tearDown(() {
    OnboardingFixtureController.instance.resetForTesting();
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
  });
  testWidgets(
    'member entry retains provider defaults without developer comparisons',
    (tester) async {
      await _member(tester, 'entry');
      expect(find.byKey(const ValueKey('welcome_google')), findsOneWidget);
      expect(find.byKey(const ValueKey('welcome_apple')), findsOneWidget);
      for (final key in const [
        'dev_home_section_onboarding',
        'dev_home_section_onboarding_transitions',
        'dev_home_section_icons',
      ]) {
        expect(find.byKey(ValueKey(key)), findsNothing);
      }
      await holdQueue44MemberPage(tester);
    },
  );
  testWidgets(
    'code-selected signup starts at Welcome and preserves invoking route identity',
    (tester) async {
      final context = await _member(tester, 'entry');
      final route = ModalRoute.of(context);
      await _start(tester, context);
      expect(context.mounted, isTrue);
      expect(route!.isCurrent, isFalse);
      await _close(tester);
      expect(ModalRoute.of(context), same(route));
      expect(route.isCurrent, isTrue);
      expectQueue44ControlsAbsent();
    },
  );
  for (final role in const ['entry', 'Seeker', 'Guardian']) {
    testWidgets('$role member screen survives a code-only onboarding route', (
      tester,
    ) async {
      final context = await _member(tester, role);
      await _start(tester, context);
      expect(context.mounted, isTrue);
      await _close(tester);
      expect(ModalRoute.of(context)!.isCurrent, isTrue);
      if (role != 'entry') {
        final input = find.byKey(const ValueKey('onboarding_first_name'));
        final editable = tester.widget<EditableText>(
          find.descendant(of: input, matching: find.byType(EditableText)),
        );
        expect(editable.controller.text, 'Existing $role');
      }
      expectQueue44ControlsAbsent();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'busy member provider rejects duplicate entry while its request is pending',
    (tester) async {
      final result = Completer<ZyraAuthResult>();
      var requests = 0;
      await tester.pumpWidget(
        Queue44MemberFrame(
          child: WelcomeScreen(
            googleSignIn: () {
              requests++;
              return result.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final dynamic provider = tester.widget<Widget>(
        find.byKey(const ValueKey('welcome_google')),
      );
      final VoidCallback enter = provider.onTap;
      enter();
      await tester.pump();
      enter();
      await tester.pump();
      expect(requests, 1);
      expect(find.byType(RoleSelectionScreen), findsNothing);
      result.complete(const ZyraAuthResult.cancelled());
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('welcome_google')), findsOneWidget);
      expectQueue44ControlsAbsent();
    },
  );
  testWidgets('revoked Welcome provider callback cannot open onboarding', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      Queue44MemberFrame(
        child: Queue44WelcomeFixture(
          devPreview: true,
          googleSignIn: () async {
            requests++;
            return const ZyraAuthResult.cancelled();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final dynamic provider = tester.widget<Widget>(
      find.byKey(const ValueKey('welcome_google')),
    );
    final VoidCallback enter = provider.onTap;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpAndSettle();
    enter();
    await tester.pumpAndSettle();
    expect(requests, 0);
    expect(find.byType(RoleSelectionScreen), findsNothing);
    expect(
      find.byKey(const ValueKey('welcome_preview_denied')),
      findsOneWidget,
    );
    expectQueue44ControlsAbsent();
  });
  testWidgets(
    'member question Continue stays reachable at320px and2xtext without pickers',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _member(tester, 'Seeker', scale: 2);
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_last_name')),
        'Member',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final action = find.byKey(const ValueKey('onboarding_continue'));
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(action.hitTestable(), findsOneWidget);
      expectQueue44ControlsAbsent();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'unauthorized member entry exposes no developer comparisons or signup shortcut',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      final context = await _member(tester, 'entry');
      await OnboardingFixtureLauncher.start(context);
      await tester.pumpAndSettle();
      expect(find.byType(SignupFlowFixture), findsNothing);
      expect(
        find.byKey(const ValueKey('welcome_recovery_email')),
        findsOneWidget,
      );
      expectQueue44ControlsAbsent();
    },
  );
}
