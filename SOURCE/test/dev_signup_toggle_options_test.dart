import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;
import 'package:zyra/dev/dev_onboarding_directions.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/dev_onboarding_lab.dart';
import 'package:zyra/dev/dev_onboarding_transition.dart';
import 'package:zyra/dev/dev_onboarding_welcome_motion.dart';
import 'package:zyra/dev/dev_signup_process.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_dev_page_options.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/dev/zyra_dev_tool_section.dart';
import 'package:zyra/dev/zyra_global_dev_overlay.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';

const _host = ValueKey('signup-toggle-host');
final _directRequests = ValueNotifier<int>(0);

Finder _choice(ZyraOnboardingDirection direction) =>
    find.byKey(ValueKey('dev_onboarding_${direction.name}'));

class _RouteAudit extends NavigatorObserver {
  int pushes = 0;
  int pops = 0;
  int replacements = 0;
  int removals = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => pops++;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      replacements++;

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      removals++;
}

Future<void> _openActions(WidgetTester tester) async {
  if (find.byType(ZyraGlobalDevOverlayHost).evaluate().isNotEmpty) {
    final hold = await tester.startGesture(tester.getCenter(find.byKey(_host)));
    await tester.pump(const Duration(seconds: 3));
    await hold.up();
  } else {
    _directRequests.value++;
  }
  await tester.pumpAndSettle();
}

Widget _entry(String label, {double textScale = 1}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    key: _host,
    body: Stack(
      fit: StackFit.expand,
      children: [
        const Text('Existing signup page'),
        ZyraEntryDevPanel(pageLabel: label, openRequests: _directRequests),
      ],
    ),
  ),
);

void main() {
  late (String?, ZyraPlan, String?) originalProfile;

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraInternalPreviewClient.finishSignOut();
    final state = AppState.instance;
    originalProfile = (state.name, state.plan, state.location);
    state.name = 'Existing synthetic member';
    state.plan = ZyraPlan.one;
    state.location = 'Synthetic region';
  });

  tearDown(() {
    AppState.instance.name = originalProfile.$1;
    AppState.instance.plan = originalProfile.$2;
    AppState.instance.location = originalProfile.$3;
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(null);
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraInternalPreviewClient.finishSignOut();
  });

  for (final label in ['Onboarding', 'Seeker sign-up', 'Guardian sign-up']) {
    testWidgets('$label Actions separate styles and offer one Onboarding', (
      tester,
    ) async {
      await tester.pumpWidget(_entry(label));
      await _openActions(tester);
      final section = find.byKey(
        const ValueKey('dev_entry_section_onboarding'),
      );
      final transitions = find.byKey(
        const ValueKey('dev_entry_section_onboarding_transitions'),
      );
      expect(tester.widget(section), isA<ZyraDevToolSection>());
      expect(tester.widget(transitions), isA<ZyraDevToolSection>());
      expect(find.text('Onboarding directions'), findsOneWidget);
      for (final direction in ZyraOnboardingDirection.values) {
        expect(
          find.descendant(of: section, matching: _choice(direction)),
          findsOneWidget,
        );
      }
      for (final transition in ZyraOnboardingPageTransition.values) {
        expect(
          find.descendant(
            of: transitions,
            matching: find.byKey(
              ValueKey('dev_onboarding_transition_${transition.name}'),
            ),
          ),
          findsOneWidget,
        );
      }
      final descentMotions = ZyraWelcomeTextMotion.values.where(
        (motion) => motion.family == ZyraWelcomeTextMotionFamily.descent,
      );
      expect(descentMotions, hasLength(5));
      for (final motion in descentMotions) {
        expect(
          find.descendant(
            of: transitions,
            matching: find.byKey(
              ValueKey('dev_welcome_text_motion_${motion.name}'),
            ),
          ),
          findsOneWidget,
        );
      }
      expect(
        find.byKey(const ValueKey('dev_welcome_text_motion_quietTypewriter')),
        findsNothing,
      );
      final options = tester.widget<ZyraDevPageOptions>(
        find.byType(ZyraDevPageOptions),
      );
      final signup = options.options.where(
        (option) => option.group == 'Onboarding',
      );
      expect(signup, hasLength(1));
      expect(signup.single.id, 'dev_entry_signup');
      expect(signup.single.label, 'Onboarding');
      expect(signup.single.onSelected, isNotNull);
      expect(
        options.options.map((option) => option.id),
        isNot(contains('dev_entry_seeker_signup')),
      );
      expect(
        options.options.map((option) => option.id),
        isNot(contains('dev_entry_guardian_signup')),
      );
      expect(
        options.options.where((option) => option.group == 'Entry'),
        hasLength(1),
      );
      expect(
        tester.getTopLeft(transitions).dy,
        greaterThan(tester.getBottomLeft(section).dy),
      );
      expect(
        tester.getTopLeft(find.byType(ZyraDevPageOptions)).dy,
        greaterThan(tester.getBottomLeft(transitions).dy),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('entry Home retains the separate onboarding category', (
    tester,
  ) async {
    await tester.pumpWidget(_entry('Onboarding'));
    await _openActions(tester);
    await tester.tap(
      find.byKey(const ValueKey('dev_controls_tab_home')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dev_home_section_onboarding')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('dev_home_section_onboarding_transitions')),
      findsNothing,
    );
    for (final direction in ZyraOnboardingDirection.values) {
      expect(_choice(direction), findsOneWidget);
    }
    expect(
      find.byKey(const ValueKey('dev_entry_section_onboarding')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'all eleven entry styles restart the existing onboarding without a root route',
    (tester) async {
      final coordinator = ZyraDevSurfaceCoordinator.instance;
      coordinator.beginEntryFlow('Onboarding');
      final rootNavigator = GlobalKey<NavigatorState>();
      final rootRouteObserver = ZyraDevControlsRouteObserver();
      final nestedNavigator = GlobalKey<NavigatorState>();
      final rootAudit = _RouteAudit();
      final nestedAudit = _RouteAudit();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: rootNavigator,
          navigatorObservers: [rootAudit, rootRouteObserver],
          builder: (context, child) => ZyraGlobalDevOverlayHost(
            navigatorKey: rootNavigator,
            routeObserver: rootRouteObserver,
            authStateChangesOverride: const Stream<AuthState>.empty(),
            child: child!,
          ),
          home: Navigator(
            key: nestedNavigator,
            observers: [nestedAudit],
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) =>
                  const Scaffold(key: _host, body: DevSignUpProcessScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final direction in ZyraOnboardingDirection.values) {
        await _openActions(tester);
        await tester.ensureVisible(_choice(direction));
        await tester.pumpAndSettle();
        await tester.tap(_choice(direction));
        await tester.pumpAndSettle();
        expect(find.byType(WelcomeScreen), findsOneWidget);
        expect(find.byType(DevSignUpProcessScreen), findsOneWidget);
        expect(find.byType(DevOnboardingIntroduction), findsNothing);
        expect(find.byType(DevOnboardingDirectionsScreen), findsNothing);
        expect(find.text('Sign-up preview · no account changes'), findsNothing);
        expect(find.byKey(const ValueKey('dev_signup_close')), findsNothing);
        expect(coordinator.canCloseOnboarding, isTrue);
        expect(rootNavigator.currentState!.canPop(), isFalse);
        expect(nestedNavigator.currentState!.canPop(), isFalse);
        expect(find.byKey(_host), findsOneWidget);
        expect(coordinator.entryLabel, 'Onboarding');
        expect(coordinator.surface, ZyraDevSurface.entry);
        expect(find.byType(ZyraDevControlRail), findsNothing);
        expect(find.byKey(const ValueKey('dev_controls_close')), findsNothing);
        expect(ZyraInternalPreviewClient.isActive, isTrue);
        expect(tester.takeException(), isNull);
      }
      expect(rootAudit.pushes, 1);
      expect(rootAudit.pops, 0);
      expect([rootAudit.replacements, rootAudit.removals], [0, 0]);
      expect(
        [
          nestedAudit.pushes,
          nestedAudit.pops,
          nestedAudit.replacements,
          nestedAudit.removals,
        ],
        [1, 0, 0, 0],
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('revoked stale entry preview tap does not navigate', (
    tester,
  ) async {
    await tester.pumpWidget(_entry('Onboarding'));
    await _openActions(tester);
    final choice = _choice(ZyraOnboardingDirection.structured);
    await tester.ensureVisible(choice);
    await tester.pumpAndSettle();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.tap(choice);
    await tester.pumpAndSettle();
    expect(find.byType(DevOnboardingDirectionsScreen), findsNothing);
    expect(find.byType(DevSignUpProcessScreen), findsNothing);
    expect(find.byKey(_host), findsOneWidget);
    expect(AppState.instance.name, 'Existing synthetic member');
    expect(tester.takeException(), isNull);
  });

  testWidgets('unauthorized entry page exposes no developer choices', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpWidget(_entry('Onboarding'));
    expect(find.byType(DevOnboardingDirectionPicker), findsNothing);
    expect(find.byType(ZyraDevPageOptions), findsNothing);
    expect(find.byType(ZyraDevControlRail), findsNothing);
  });

  testWidgets('signup Actions category scrolls cleanly at320px and2xtext', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_entry('Onboarding', textScale: 2));
    await _openActions(tester);
    for (final direction in ZyraOnboardingDirection.values) {
      await tester.ensureVisible(_choice(direction));
      await tester.pumpAndSettle();
      expect(_choice(direction).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    final signup = find.byKey(
      const ValueKey('dev_page_options_dropdown_Onboarding'),
    );
    await tester.ensureVisible(signup);
    await tester.pumpAndSettle();
    expect(signup.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
