import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/auth/role_selection_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'support/queue44_removed_controls_fixture.dart';
import 'support/queue44_signup_flow_fixture.dart';
import 'support/queue44_gold_fixture.dart';

class _Audit extends NavigatorObserver {
  int pushes = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
  }
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
    'member entry keeps providers while developer Onboarding categories are absent',
    (tester) async {
      await tester.pumpWidget(const Queue44MemberFrame(child: WelcomeScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('welcome_google')), findsOneWidget);
      expect(find.byKey(const ValueKey('welcome_apple')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dev_home_section_onboarding')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('dev_entry_section_onboarding')),
        findsNothing,
      );
      await holdQueue44MemberPage(tester);
    },
  );
  testWidgets(
    'code-selected entry state restarts its nested Navigator without a root route',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      final audit = _Audit();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          navigatorObservers: [audit],
          home: const WelcomeScreen(),
        ),
      );
      await tester.pumpAndSettle();
      OnboardingFixtureLauncher.start(
        tester.element(find.byType(WelcomeScreen)),
      );
      await tester.pumpAndSettle();
      final rootPushes = audit.pushes;
      final before = Navigator.of(tester.element(find.byType(WelcomeScreen)));
      expect(
        OnboardingFixtureController.instance.restartOnboarding(
          ZyraOnboardingDirection.luma,
        ),
        isTrue,
      );
      await tester.pumpAndSettle();
      final after = Navigator.of(tester.element(find.byType(WelcomeScreen)));
      expect(after, isNot(same(before)));
      expect(audit.pushes, rootPushes);
      expect(
        find.byType(SignupFlowFixture, skipOffstage: false),
        findsOneWidget,
      );
      OnboardingFixtureController.instance.closeOnboarding();
      await tester.pumpAndSettle();
      expect(navigator.currentState!.canPop(), isFalse);
    },
  );
  for (final role in const ['Seeker', 'Guardian', 'Onboarding']) {
    testWidgets(
      '$role signup preserves its member action without developer style options',
      (tester) async {
        final Widget page = switch (role) {
          'Seeker' => const OnboardingFlow(devPreview: true),
          'Guardian' => const WaliOnboardingFlow(devPreview: true),
          _ => const WelcomeScreen(),
        };
        await tester.pumpWidget(Queue44MemberFrame(child: page));
        await tester.pumpAndSettle();
        if (role == 'Seeker') {
          expect(
            find.byKey(const ValueKey('onboarding_stage_continue')),
            findsOneWidget,
          );
          await tester.tap(
            find.byKey(const ValueKey('onboarding_stage_continue')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('onboarding_first_name')),
            findsOneWidget,
          );
        } else if (role == 'Guardian') {
          expect(
            find.byKey(const ValueKey('onboarding_first_name')),
            findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('wali_onboarding_continue')),
            findsOneWidget,
          );
        } else {
          expect(find.byKey(const ValueKey('welcome_google')), findsOneWidget);
        }
        for (final key in const [
          'dev_page_options_dropdown_Onboarding',
          'dev_entry_signup',
          'dev_entry_seeker_signup',
          'dev_entry_guardian_signup',
        ]) {
          expect(find.byKey(ValueKey(key)), findsNothing);
        }
        expectQueue44ControlsAbsent();
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'revoked retained provider preview callback cannot navigate or call OAuth',
    (tester) async {
      var oauthCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(
            devPreview: true,
            googleSignIn: () async {
              oauthCalls++;
              throw StateError('OAuth must remain uncalled.');
            },
          ),
        ),
      );
      await tester.pump();
      final dynamic provider = tester.widget<Widget>(
        find.byKey(const ValueKey('welcome_google')),
      );
      final VoidCallback stale = provider.onTap;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pump();
      stale();
      await tester.pump();
      expect(oauthCalls, 0);
      expect(find.byType(RoleSelectionScreen), findsNothing);
      expect(find.byKey(const ValueKey('welcome_dev_skip')), findsNothing);
    },
  );
  testWidgets(
    'member role choices remain reachable at320px and2xtext without Actions menu',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const Queue44MemberFrame(
          scale: 2,
          child: RoleSelectionScreen(devPreview: true),
        ),
      );
      await tester.pumpAndSettle();
      for (final key in const ['role-select-seeker', 'role-select-guardian']) {
        final action = find.byKey(ValueKey(key));
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        expect(action.hitTestable(), findsOneWidget);
      }
      expectQueue44ControlsAbsent();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'unauthorized entry retains member recovery without developer choices',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpWidget(const Queue44MemberFrame(child: WelcomeScreen()));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('welcome_recovery_email')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('welcome_google')), findsOneWidget);
      expectQueue44ControlsAbsent();
    },
  );
}
