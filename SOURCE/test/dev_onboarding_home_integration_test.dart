import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/config/zyra_app_variant.dart';
import 'package:zyra/dev/dev_onboarding_directions.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/dev_onboarding_lab.dart';
import 'package:zyra/dev/dev_onboarding_transition.dart';
import 'package:zyra/dev/dev_onboarding_welcome_motion.dart';
import 'package:zyra/dev/dev_signup_process.dart';
import 'package:zyra/dev/dev_scenario_panel_v2.dart';
import 'package:zyra/dev/wali_dev_scenario_panel.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/dev/zyra_dev_tool_section.dart';
import 'package:zyra/dev/zyra_global_dev_overlay.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/theme/zyra_text.dart';

Finder _choice(ZyraOnboardingDirection direction) =>
    find.byKey(ValueKey('dev_onboarding_${direction.name}'));

Widget _home({
  bool busy = false,
  VoidCallback? closePanel,
  VoidCallback? home,
  VoidCallback? restart,
  VoidCallback? reset,
  VoidCallback? accounts,
  VoidCallback? signup,
  GlobalKey<NavigatorState>? navigator,
}) => MaterialApp(
  navigatorKey: navigator,
  home: Scaffold(
    body: SingleChildScrollView(
      child: Column(
        children: [
          const Text('Existing page stays here'),
          ZyraDevHomeTools(
            busy: busy,
            onHome: home ?? () {},
            onOpenSplashPreview: closePanel,
            onRestart: restart ?? () {},
            onReset: reset ?? () {},
            onAccounts: accounts ?? () {},
            onSeekerSignUp: signup ?? () {},
            onGuardianSignUp: signup ?? () {},
          ),
        ],
      ),
    ),
  ),
);

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraInternalPreviewClient.finishSignOut();
  });

  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraInternalPreviewClient.finishSignOut();
  });

  testWidgets(
    'Home keeps the selected onboarding choice without motion or icon comparisons',
    (tester) async {
      await tester.pumpWidget(_home());
      expect(ZyraOnboardingDirection.values.map((e) => e.name), ['luma']);
      expect(find.text('Onboarding directions'), findsOneWidget);
      for (final direction in ZyraOnboardingDirection.values) {
        expect(ZyraDevSurfaceCoordinator.instance.canCloseOnboarding, isFalse);
        expect(_choice(direction), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('dev_home_section_onboarding')),
            matching: _choice(direction),
          ),
          findsOneWidget,
        );
      }
      final splash = find.byKey(const ValueKey('dev_home_section_splash'));
      final onboarding = find.byKey(
        const ValueKey('dev_home_section_onboarding'),
      );
      expect(
        find.byKey(const ValueKey('dev_home_section_onboarding_transitions')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('dev_home_section_icons')),
        findsNothing,
      );
      for (final transition in ZyraOnboardingPageTransition.values) {
        expect(
          find.byKey(ValueKey('dev_onboarding_transition_${transition.name}')),
          findsNothing,
        );
      }
      final descentMotions = ZyraWelcomeTextMotion.values.where(
        (motion) => motion.family == ZyraWelcomeTextMotionFamily.descent,
      );
      expect(descentMotions, hasLength(5));
      for (final motion in descentMotions) {
        expect(
          find.byKey(ValueKey('dev_welcome_text_motion_${motion.name}')),
          findsNothing,
        );
      }
      expect(
        find.byKey(const ValueKey('dev_welcome_text_motion_quietTypewriter')),
        findsNothing,
      );
      final settings = find.byKey(const ValueKey('dev_home_section_settings'));
      final account = find.byKey(const ValueKey('dev_home_section_account'));
      for (final section in [splash, onboarding, settings, account]) {
        expect(tester.widget(section), isA<ZyraDevToolSection>());
      }
      expect(
        tester.getTopLeft(onboarding).dy,
        greaterThan(tester.getBottomLeft(splash).dy),
      );
      expect(
        tester.getTopLeft(settings).dy,
        greaterThan(tester.getBottomLeft(onboarding).dy),
      );
      expect(
        tester.getTopLeft(account).dy,
        greaterThan(tester.getBottomLeft(settings).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'every Home choice starts full onboarding at Welcome without account callbacks',
    (tester) async {
      var closes = 0;
      var restarts = 0;
      var resets = 0;
      var switches = 0;
      var signups = 0;
      var refreshes = 0;
      ZyraDeveloperAccess.configureAuthorizationForTesting(
        variant: ZyraAppVariant.production,
        currentUser: () => null,
        refreshSession: () async {
          refreshes++;
          return null;
        },
        founderIdentityMatches: (_) => false,
      );
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        _home(
          navigator: navigator,
          closePanel: () => closes++,
          restart: () => restarts++,
          reset: () => resets++,
          accounts: () => switches++,
          signup: () => signups++,
        ),
      );
      for (final direction in ZyraOnboardingDirection.values) {
        await tester.ensureVisible(_choice(direction));
        await tester.pumpAndSettle();
        await tester.tap(_choice(direction));
        await tester.pumpAndSettle();
        final screen = tester.widget<DevSignUpProcessScreen>(
          find.byType(DevSignUpProcessScreen),
        );
        expect(screen.initialDirection, direction);
        expect(find.byType(WelcomeScreen), findsOneWidget);
        expect(find.byType(DevOnboardingIntroduction), findsNothing);
        expect(find.byType(DevOnboardingDirectionsScreen), findsNothing);
        expect(find.text('Sign-up preview · no account changes'), findsNothing);
        expect(find.byKey(const ValueKey('dev_signup_close')), findsNothing);
        expect(ZyraDevSurfaceCoordinator.instance.canCloseOnboarding, isTrue);
        expect(navigator.currentState!.canPop(), isTrue);
        navigator.currentState!.pop();
        await tester.pumpAndSettle();
        expect(find.text('Existing page stays here'), findsOneWidget);
        expect(ZyraDevSurfaceCoordinator.instance.canCloseOnboarding, isFalse);
        expect(tester.takeException(), isNull);
      }
      expect(closes, 1);
      expect([restarts, resets, switches, signups], [0, 0, 0, 0]);
      expect(
        refreshes,
        1,
        reason: 'Each outside launch refreshes guarded proof',
      );
    },
  );

  for (final (label, panel)
      in <(String, Widget Function(ValueListenable<int>))>[
        (
          'entry',
          (requests) => ZyraEntryDevPanel(
            pageLabel: 'Auth fixture',
            openRequests: requests,
          ),
        ),
        (
          'Seeker',
          (requests) =>
              DevScenarioPanelV2(onOpenPage: (_) {}, openRequests: requests),
        ),
        (
          'Guardian',
          (requests) =>
              WaliDevScenarioPanel(onOpenPage: (_) {}, openRequests: requests),
        ),
      ]) {
    testWidgets('$label Home opens onboarding above its existing page', (
      tester,
    ) async {
      final requests = ValueNotifier<int>(0);
      addTearDown(requests.dispose);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [const Text('Original host page'), panel(requests)],
            ),
          ),
        ),
      );
      requests.value++;
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('dev_controls_tab_home')).hitTestable(),
      );
      await tester.pumpAndSettle();
      expect(find.text('Onboarding directions'), findsOneWidget);
      final choice = _choice(ZyraOnboardingDirection.luma);
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      await tester.tap(choice);
      await tester.pumpAndSettle();
      expect(find.byType(DevSignUpProcessScreen), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(DevOnboardingDirectionsScreen), findsNothing);
      expect(navigator.currentState!.canPop(), isTrue);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(find.text('Original host page'), findsOneWidget);
      // The host page remains mounted; the full-screen controls have closed.
      expect(find.byType(ZyraDevControlRail), findsNothing);
      expect(find.byKey(const ValueKey('dev_controls_close')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('busy Home disables the selected onboarding preview choice', (
    tester,
  ) async {
    var closes = 0;
    await tester.pumpWidget(_home(busy: true, closePanel: () => closes++));
    for (final direction in ZyraOnboardingDirection.values) {
      final chip = tester.widget<ActionChip>(_choice(direction));
      expect(chip.onPressed, isNull);
    }
    expect(closes, 0);
    expect(find.byType(DevSignUpProcessScreen), findsNothing);
    expect(find.byType(DevOnboardingDirectionsScreen), findsNothing);
  });

  testWidgets('unauthorized picker exposes no comparisons', (tester) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: DevOnboardingDirectionPicker())),
    );
    expect(find.byType(ActionChip), findsNothing);
    expect(find.text('Onboarding directions'), findsNothing);
  });

  testWidgets('picker rechecks revoked access before opening a preview', (
    tester,
  ) async {
    var closes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DevOnboardingDirectionPicker(onBeforeOpen: () => closes++),
        ),
      ),
    );
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.tap(_choice(ZyraOnboardingDirection.luma));
    await tester.pumpAndSettle();
    expect(closes, 0);
    expect(find.byType(DevSignUpProcessScreen), findsNothing);
    expect(find.byType(DevOnboardingDirectionsScreen), findsNothing);
  });

  testWidgets('separate picker remains usable at narrow width and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(14),
            child: ZyraDevToolSection(child: DevOnboardingDirectionPicker()),
          ),
        ),
      ),
    );
    for (final direction in ZyraOnboardingDirection.values) {
      await tester.ensureVisible(_choice(direction));
      await tester.pumpAndSettle();
      expect(_choice(direction).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
