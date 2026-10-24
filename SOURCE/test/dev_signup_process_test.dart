import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zyra/config/zyra_internal_founder_policy.dart';
import 'package:zyra/dev/dev_onboarding_directions.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/dev_onboarding_interaction.dart';
import 'package:zyra/dev/dev_onboarding_lab.dart';
import 'package:zyra/dev/dev_onboarding_transition.dart';
import 'package:zyra/dev/dev_signup_process.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_dev_signup.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/dev/zyra_global_dev_overlay.dart';
import 'package:zyra/models/zyra_identity_verification.dart';
import 'package:zyra/screens/auth/role_selection_screen.dart';
import 'package:zyra/screens/dev/developer_access_screen.dart';
import 'package:zyra/screens/home/home_shell.dart';
import 'package:zyra/screens/onboarding/account_path_overview_screen.dart';
import 'package:zyra/screens/onboarding/identity_verification_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/onboarding/signup_membership_choice_screen.dart';
import 'package:zyra/screens/onboarding/transition_screen.dart';
import 'package:zyra/screens/wali/wali_invite_seeker_screen.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/screens/wali/zyra_code_screen.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_auth.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';

import 'initial_signup_draft_test.dart' show FakeSignupStore;

const _account = 'dry-signup-existing-owner';
const _host = ValueKey('dry-signup-host');
const _open = ValueKey('dry-signup-open');
const _home = ValueKey('dev_home_navigation');
const _candidateRoot = ValueKey('dev-signup-candidate');
const _firstNameField = ValueKey('onboarding_first_name');
const _lastNameField = ValueKey('onboarding_last_name');
const _openingThemeCount = 3;
const _appLinksEvents = MethodChannel('com.llfbandit.app_links/events');
const _captureCandidates = bool.fromEnvironment(
  'ZYRA_SIGNUP_CAPTURE_CANDIDATES',
);
const _candidateDirectory =
    'visual/candidates/dev_onboarding_edge_to_edge_2026_09_29';
const _captureStyledCandidates = bool.fromEnvironment(
  'ZYRA_STYLED_ONBOARDING_CAPTURE_CANDIDATES',
);
const _styledCandidateDirectory =
    'visual/candidates/onboarding_full_journey_styles_2026_09_29';

Future<void> _candidate(WidgetTester tester, String name) async {
  if (!_captureCandidates) return;
  // Repaint the full frame before rasterising nested-route changes. These
  // optional future captures have their own namespace; old header evidence
  // remains historical and must not be overwritten.
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_candidateRoot),
  );
  boundary.markNeedsPaint();
  await tester.pump();
  final capture = await tester.runAsync(() => boundary.toImage());
  expect(capture, isNotNull);
  final rendered = capture!;
  try {
    await expectLater(
      rendered,
      matchesGoldenFile('$_candidateDirectory/$name.png'),
    );
  } finally {
    rendered.dispose();
  }
}

Future<void> _styledCandidate(WidgetTester tester, String name) async {
  if (!_captureStyledCandidates) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_candidateRoot),
  );
  boundary.markNeedsPaint();
  await tester.pump();
  final capture = await tester.runAsync(() => boundary.toImage());
  expect(capture, isNotNull);
  final rendered = capture!;
  try {
    await expectLater(
      rendered,
      matchesGoldenFile('$_styledCandidateDirectory/$name.png'),
    );
  } finally {
    rendered.dispose();
  }
}

int _httpCalls = 0;
int _ownerChecks = 0;
late FakeSignupStore _store;
late SharedPreferences _prefs;
late Map<String, Object?> _initialPrefs;

class _OnboardingRouteAudit extends NavigatorObserver {
  int pushes = 0;
  int replacements = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      replacements++;
}

Map<String, Object?> _preferenceSnapshot() => {
  for (final key in _prefs.getKeys()) key: _prefs.get(key),
};

Future<GlobalKey<NavigatorState>> _mountHost(
  WidgetTester tester, {
  bool overlay = true,
  ZyraOnboardingDirection direction = ZyraOnboardingDirection.current,
  bool implicitDirection = false,
  NavigatorObserver? routeAudit,
  Size viewport = const Size(430, 932),
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final navigator = GlobalKey<NavigatorState>();
  final controlsRouteObserver = ZyraDevControlsRouteObserver();
  // A failed assertion must still resolve the protected helper's route
  // future so its static opening guard cannot poison later cases.
  addTearDown(() async {
    final state = navigator.currentState;
    if (state != null && state.mounted) {
      while (state.canPop()) {
        state.pop();
      }
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      navigatorObservers: [controlsRouteObserver, ?routeAudit],
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
        child: RepaintBoundary(
          key: _candidateRoot,
          child: overlay
              ? ZyraGlobalDevOverlayHost(
                  navigatorKey: navigator,
                  routeObserver: controlsRouteObserver,
                  authStateChangesOverride: const Stream<AuthState>.empty(),
                  child: child!,
                )
              : child!,
        ),
      ),
      home: Scaffold(
        key: _host,
        body: Builder(
          builder: (context) => Column(
            children: [
              const Text('Invoking page stays here'),
              TextButton(
                key: _open,
                onPressed: () => implicitDirection
                    ? ZyraDevSignUp.start(context)
                    : ZyraDevSignUp.start(context, direction: direction),
                child: const Text('Open local sign up'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Decode the real local Google brand asset before the first capture; a
  // settled fake-async frame alone can precede engine image decoding.
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage('assets/auth/google_g_logo.png'),
      navigator.currentContext!,
    );
  });
  await tester.pumpAndSettle();
  return navigator;
}

Future<void> _launch(WidgetTester tester) async {
  final fromLanding = find.byKey(const ValueKey('dev_access_signup'));
  await tester.tap(
    fromLanding.hitTestable().evaluate().isNotEmpty
        ? fromLanding
        : find.byKey(_open),
  );
  await tester.pumpAndSettle();
  expect(find.byType(DevSignUpProcessScreen), findsOneWidget);
  expect(find.byType(WelcomeScreen), findsOneWidget);
  expect(ZyraInternalPreviewClient.isActive, isTrue);
  expect(ZyraDevSurfaceCoordinator.instance.entryLabel, 'Onboarding');
  expect(find.text('Sign-up preview · no account changes'), findsNothing);
  expect(find.byType(DevOnboardingDirectionsScreen), findsNothing);
}

Future<void> _completeIntroductionPage(
  WidgetTester tester,
  ZyraOnboardingDirection direction,
  int page,
) async {
  await _finishWelcomePrelude(tester);
  final story = find.byKey(ValueKey('dev_opening_page_${page + 1}'));
  expect(story.hitTestable(), findsOneWidget);
  if (page == _openingThemeCount - 1 ||
      ZyraDevOnboardingStoryNavigation.current ==
          ZyraOnboardingStoryNavigation.scrollDown) {
    await tester.tap(
      find.byKey(const ValueKey('dev_onboarding_story_continue')),
    );
  } else {
    await tester.tap(story);
  }
  await tester.pumpAndSettle();
}

void _expectOpeningProgress(WidgetTester tester, int page) {
  expect(find.text('$page / 4'), findsOneWidget);
  for (var index = 0; index < 4; index++) {
    final dot = find.byKey(ValueKey('dev_onboarding_story_dot_$index'));
    expect(dot, findsOneWidget);
    final semantics = tester.widget<Semantics>(dot).properties;
    expect(semantics.label, 'How ZYRA works, page ${index + 1} of 4');
    expect(semantics.selected, index == page - 1);
    expect(
      semantics.value,
      index < page - 1
          ? 'Completed'
          : index == page - 1
          ? 'Current'
          : 'Upcoming',
    );
    final decoration =
        tester
                .widget<Container>(
                  find.descendant(of: dot, matching: find.byType(Container)),
                )
                .decoration!
            as BoxDecoration;
    expect(
      decoration.color,
      index <= page - 1
          ? ZyraColors.journeyGold
          : ZyraColors.foreground.withValues(alpha: .25),
    );
  }
  expect(
    find.byKey(const ValueKey('dev_onboarding_story_dot_4')),
    findsNothing,
  );
}

Future<void> _finishWelcomePrelude(WidgetTester tester) async {
  final prelude = find.byKey(const ValueKey('dev_onboarding_welcome_prelude'));
  if (prelude.evaluate().isNotEmpty) {
    expect(find.text('Welcome to ZYRA, Shakeel.'), findsOneWidget);
    expect(
      find.text(
        'We praise Allah and send peace and blessings upon His Messenger ﷺ.',
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('dev_onboarding_welcome_continue')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('dev_onboarding_verification_intro')),
      findsOneWidget,
    );
  }
  final verification = find.byKey(
    const ValueKey('dev_onboarding_verification_intro'),
  );
  if (verification.evaluate().isEmpty) return;
  expect(find.text('Verified people.\nSerious intentions.'), findsOneWidget);
  expect(
    find.text(
      'Every Seeker and Guardian must complete identity verification before joining ZYRA.',
    ),
    findsOneWidget,
  );
  expect(find.byType(RoleSelectionScreen), findsNothing);
  _expectOpeningProgress(tester, 1);
  final next = find.byKey(
    const ValueKey('dev_onboarding_verification_continue'),
  );
  if (ZyraDevOnboardingStoryNavigation.current ==
      ZyraOnboardingStoryNavigation.scrollDown) {
    expect(tester.widget<ZyraOnboardingArrowAction>(next).onPressed, isNotNull);
  } else {
    expect(tester.widget<IconButton>(next).onPressed, isNotNull);
    expect(find.byType(ZyraOnboardingArrowAction), findsNothing);
  }
  await tester.tap(next);
  await tester.pumpAndSettle();
  _expectOpeningProgress(tester, 2);
}

Future<void> _reachFinalIntroductionCard(
  WidgetTester tester, {
  required ZyraOnboardingDirection direction,
}) async {
  await tester.tap(find.byKey(const ValueKey('welcome_google')));
  await tester.pumpAndSettle();
  await _finishWelcomePrelude(tester);
  for (var page = 0; page < _openingThemeCount - 1; page++) {
    await _completeIntroductionPage(tester, direction, page);
  }
  _expectOpeningProgress(tester, 4);
  expect(find.byType(RoleSelectionScreen), findsNothing);
}

Future<void> _revealFinalIntroductionCard(
  WidgetTester tester,
  ZyraOnboardingDirection direction,
) async {
  expect(find.byKey(const ValueKey('dev_opening_page_3')), findsOneWidget);
  _expectOpeningProgress(tester, 4);
}

double _verticalTranslation(WidgetTester tester, ValueKey<String> key) {
  final opacity = tester.widget<Opacity>(find.byKey(key));
  return (opacity.child! as Transform).transform.getTranslation().y;
}

Future<void> _chooseRole(
  WidgetTester tester, {
  required bool guardian,
  String provider = 'google',
  ZyraOnboardingDirection? introductionDirection,
}) async {
  await tester.tap(find.byKey(ValueKey('welcome_$provider')));
  await tester.pumpAndSettle();
  await _finishWelcomePrelude(tester);
  final direction =
      introductionDirection ??
      tester
          .widget<DevSignUpProcessScreen>(find.byType(DevSignUpProcessScreen))
          .initialDirection;
  if (direction != ZyraOnboardingDirection.current) {
    for (var page = 0; page < _openingThemeCount; page++) {
      expect(find.byType(DevOnboardingIntroduction), findsOneWidget);
      _expectDirectionStyle(
        tester,
        find.byType(DevOnboardingIntroduction),
        direction,
      );
      expect(
        find.byKey(ValueKey('dev_opening_page_${page + 1}')).hitTestable(),
        findsOneWidget,
      );
      expect(find.byType(RoleSelectionScreen), findsNothing);
      expect(find.text('Finish preview'), findsNothing);
      expect(find.byKey(const ValueKey('dev_onboarding_close')), findsNothing);
      await _completeIntroductionPage(tester, direction, page);
    }
  }
  final role = tester.widget<RoleSelectionScreen>(
    find.byType(RoleSelectionScreen),
  );
  _expectDirectionStyle(
    tester,
    find.byType(RoleSelectionScreen),
    direction,
    roleHeader: direction != ZyraOnboardingDirection.current,
  );
  expect(role.devPreview, isTrue);
  expect(role.signupUserId, isNull);
  expect(find.byKey(const ValueKey('onboarding_account_exit')), findsNothing);
  final action = find.byKey(
    ValueKey(guardian ? 'role-select-guardian' : 'role-select-seeker'),
  );
  await tester.ensureVisible(action);
  await tester.pumpAndSettle();
  await tester.tap(action);
  await tester.pumpAndSettle();
  expect(find.byType(RoleSelectionScreen), findsOneWidget);
  expect(find.byKey(const ValueKey('role-choice-continue')), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('role-choice-continue')));
  await tester.pumpAndSettle();
  if (guardian) {
    _expectDirectionStyle(
      tester,
      find.byType(GuardianOnboardingOverviewScreen),
      direction,
      accent: direction != ZyraOnboardingDirection.current,
    );
    final overview = tester.widget<GuardianOnboardingOverviewScreen>(
      find.byType(GuardianOnboardingOverviewScreen),
    );
    expect(overview.devPreview, isTrue);
    expect(overview.signupUserId, isNull);
    expect(find.byKey(const ValueKey('onboarding_account_exit')), findsNothing);
    await tester.tap(find.text('Begin Guardian Setup'));
    await tester.pumpAndSettle();
    final flow = tester.widget<WaliOnboardingFlow>(
      find.byType(WaliOnboardingFlow),
    );
    _expectDirectionStyle(
      tester,
      find.byType(WaliOnboardingFlow),
      direction,
      accent: direction != ZyraOnboardingDirection.current,
    );
    expect(flow.devPreview, isTrue);
    expect(flow.signupUserId, isNull);
  } else {
    final flow = tester.widget<OnboardingFlow>(find.byType(OnboardingFlow));
    _expectDirectionStyle(tester, find.byType(OnboardingFlow), direction);
    expect(flow.devPreview, isTrue);
    expect(flow.signupUserId, isNull);
    expect(find.text('First, your account.'), findsOneWidget);
    expect(find.text('Together, we’ll build four things.'), findsNothing);
    final stage = find.byKey(const ValueKey('onboarding_stage_continue'));
    expect(stage.hitTestable(), findsOneWidget);
    await tester.tap(stage);
    await tester.pumpAndSettle();
  }
  expect(find.text("What's your name?"), findsOneWidget);
  expect(find.byKey(_firstNameField), findsOneWidget);
  expect(find.byKey(_lastNameField), findsOneWidget);
  expect(
    find.text('Both names will appear on your public profile.'),
    findsOneWidget,
  );
  _expectDirectionStyle(
    tester,
    find.byType(guardian ? WaliOnboardingFlow : OnboardingFlow),
    direction,
    accent: direction != ZyraOnboardingDirection.current,
  );
  expect(find.byKey(const ValueKey('onboarding_account_exit')), findsNothing);
}

Future<void> _expectNoSideEffects(WidgetTester tester) async {
  await tester.runAsync(() => ZyraLocalPrefs.bindAccount(_account));
  expect(_httpCalls, 0, reason: 'No OAuth, recovery, profile, or data API I/O');
  expect(_store.operations, 0, reason: 'No protected signup draft I/O');
  expect(_ownerChecks, 0, reason: 'No live draft ownership checks in preview');
  expect(_preferenceSnapshot(), _initialPrefs);
  expect(ZyraLocalPrefs.cachedFirstName, 'Existing member');
  expect(ZyraLocalPrefs.cachedGender, 'female');
  expect(ZyraLocalPrefs.cachedRole, 'seeker');
}

VoidCallback _enabledQuestionContinue(
  WidgetTester tester, {
  required bool guardian,
}) {
  final action = find.byKey(
    ValueKey(guardian ? 'wali_onboarding_continue' : 'onboarding_continue'),
  );
  return _enabledActionCallback(tester, action);
}

VoidCallback _enabledActionCallback(WidgetTester tester, Finder action) {
  final widget = tester.widget<Widget>(action);
  if (widget is ZyraOnboardingArrowAction) return widget.onPressed!;
  if (widget is FilledButton) return widget.onPressed!;
  if (widget is InkWell) return widget.onTap!;
  if (widget is GestureDetector) return widget.onTap!;
  final arrow = find.descendant(
    of: action,
    matching: find.byType(ZyraOnboardingArrowAction),
  );
  if (arrow.evaluate().isNotEmpty) {
    return tester.widget<ZyraOnboardingArrowAction>(arrow).onPressed!;
  }
  final button = find.descendant(
    of: action,
    matching: find.byType(FilledButton),
  );
  if (button.evaluate().isNotEmpty) {
    return tester.widget<FilledButton>(button).onPressed!;
  }
  throw StateError('Unknown enabled onboarding action: ${widget.runtimeType}');
}

void _expectNoHeader(WidgetTester tester) {
  expect(find.text('Sign-up preview · no account changes'), findsNothing);
  expect(find.textContaining('Preview ·'), findsNothing);
  expect(find.byKey(const ValueKey('dev_signup_close')), findsNothing);
  expect(
    find.descendant(
      of: find.byType(DevSignUpProcessScreen),
      matching: find.byIcon(Icons.close_rounded),
    ),
    findsNothing,
  );
}

Future<void> _chooseSignupMembership(WidgetTester tester) async {
  expect(find.byType(SignupMembershipChoiceScreen), findsOneWidget);
  expect(find.byType(InitialIdentityCheckScreen), findsNothing);
  final basic = find.byKey(const ValueKey('signup_membership_basic'));
  await tester.ensureVisible(basic);
  await tester.pumpAndSettle();
  await tester.tap(basic);
  await tester.pumpAndSettle();
  await _expectNoSideEffects(tester);
  final continueChoice = find.byKey(
    const ValueKey('signup_membership_continue'),
  );
  await tester.ensureVisible(continueChoice);
  await tester.pumpAndSettle();
  expect(continueChoice.hitTestable(), findsOneWidget);
  await tester.tap(continueChoice);
  await tester.pumpAndSettle();
  expect(find.byType(InitialIdentityCheckScreen), findsOneWidget);
  await _expectNoSideEffects(tester);
}

Future<void> _expectDeveloperAccess(WidgetTester tester) async {
  expect(find.byType(DeveloperAccessScreen), findsOneWidget);
  for (final key in const [
    'dev_access_seeker',
    'dev_access_guardian',
    'dev_access_signup',
  ]) {
    final action = find.byKey(ValueKey(key));
    // The expanded landing is deliberately scrollable on compact screens.
    // Check each action's reachability rather than requiring all at once.
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    expect(action.hitTestable(), findsOneWidget);
  }
  expect(find.byKey(_host), findsNothing);
  expect(find.byKey(_host, skipOffstage: false), findsOneWidget);
  expect(ZyraDevSurfaceCoordinator.instance.entryLabel, 'Developer Access');
}

VoidCallback _homeCallback(WidgetTester tester) => tester
    .widget<InkWell>(
      find.descendant(of: find.byKey(_home), matching: find.byType(InkWell)),
    )
    .onTap!;

Future<void> _showControls(WidgetTester tester) async {
  if (find.byKey(const ValueKey('dev_controls_close')).evaluate().isNotEmpty) {
    return;
  }
  final hold = await tester.startGesture(
    Offset(
      tester.view.physicalSize.width - 8,
      tester.view.physicalSize.height / 2,
    ),
  );
  await tester.pump(const Duration(seconds: 3));
  await hold.up();
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('dev_controls_close')), findsOneWidget);
}

Future<void> _returnHome(WidgetTester tester) async {
  _expectNoHeader(tester);
  expect(ZyraDevSurfaceCoordinator.instance.canCloseOnboarding, isTrue);
  await _showControls(tester);
  await tester.tap(
    find.byKey(const ValueKey('dev_controls_tab_home')).hitTestable(),
  );
  await tester.pumpAndSettle();
  final home = find.byKey(_home);
  await tester.ensureVisible(home);
  await tester.pumpAndSettle();
  expect(home.hitTestable(), findsOneWidget);
  expect(find.text('Exit onboarding'), findsNothing);
  await tester.tap(home);
  await tester.pumpAndSettle();
  expect(find.byType(DevSignUpProcessScreen), findsNothing);
  expect(ZyraDevSurfaceCoordinator.instance.canCloseOnboarding, isFalse);
  await _expectDeveloperAccess(tester);
}

Future<void> _discardDeniedFlow(WidgetTester tester) async {
  _expectNoHeader(tester);
  expect(ZyraDevSurfaceCoordinator.instance.canCloseOnboarding, isFalse);
  expect(find.byKey(_home).hitTestable(), findsNothing);
  final navigator = Navigator.of(
    tester.element(find.byType(DevSignUpProcessScreen)),
    rootNavigator: true,
  );
  expect(navigator.canPop(), isTrue);
  navigator.pop();
  await tester.pumpAndSettle();
}

void _expectNestedRoute(WidgetTester tester, Finder routeScreen) {
  final context = tester.element(routeScreen);
  final navigator = Navigator.of(context);
  expect(
    navigator,
    isNot(same(Navigator.of(context, rootNavigator: true))),
    reason: 'First-use route replacements stay inside the bounded outer host',
  );
}

void _expectDirectionStyle(
  WidgetTester tester,
  Finder screen,
  ZyraOnboardingDirection direction, {
  bool accent = false,
  bool roleHeader = false,
}) {
  final style = OnboardingPreviewStyle.maybeOf(tester.element(screen));
  final styledMarkers = find.descendant(
    of: screen,
    matching: find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('onboarding-preview-');
    }),
  );
  if (direction == ZyraOnboardingDirection.current) {
    expect(style, isNull, reason: 'Current keeps its original visual language');
    expect(styledMarkers, findsNothing);
    return;
  }
  expect(style?.directionName, direction.name);
  if (accent) {
    final motif = find.descendant(
      of: screen,
      matching: find.byKey(
        ValueKey('onboarding-preview-accent-${direction.name}'),
      ),
    );
    expect(motif, findsOneWidget);
    expect(tester.getSize(motif).isEmpty, isFalse);
  }
  if (roleHeader) {
    expect(
      find.descendant(
        of: screen,
        matching: find.byKey(
          ValueKey('onboarding-preview-role-${direction.name}'),
        ),
      ),
      findsOneWidget,
    );
  }
}

Future<void> _openRoleSelectionForDirection(
  WidgetTester tester,
  ZyraOnboardingDirection direction,
) async {
  await _launch(tester);
  await tester.tap(find.byKey(const ValueKey('welcome_google')));
  await tester.pumpAndSettle();
  if (direction != ZyraOnboardingDirection.current) {
    await _finishWelcomePrelude(tester);
    for (var page = 0; page < _openingThemeCount; page++) {
      expect(
        find.byKey(ValueKey('dev_opening_page_${page + 1}')),
        findsOneWidget,
      );
      await _completeIntroductionPage(tester, direction, page);
    }
  }
  _expectDirectionStyle(
    tester,
    find.byType(RoleSelectionScreen),
    direction,
    roleHeader: direction != ZyraOnboardingDirection.current,
  );
}

void main() {
  setUpAll(() async {
    // Supabase Flutter subscribes to the app_links event stream during
    // initialization. Widget tests have no native plugin; acknowledge only
    // its EventChannel lifecycle so a queued listen failure cannot surface
    // in the first unrelated widget assertion of a multi-file run.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_appLinksEvents, (call) async {
          if (call.method == 'listen' || call.method == 'cancel') return null;
          throw MissingPluginException(
            'Unexpected app_links event method ${call.method}',
          );
        });
    final reading = FontLoader('PoppinsSignupAudit');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final wordmark = FontLoader('SyneSignupAudit')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Syne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
    ZyraText.testReadingFontFamily = 'PoppinsSignupAudit';
    ZyraText.testWordmarkFontFamily = 'SyneSignupAudit';
    SharedPreferences.setMockInitialValues({
      'zyra.cached_account_owner': _account,
      'zyra.cached_first_name': 'Existing member',
      'zyra.cached_gender': 'female',
      'zyra.cached_role': 'seeker',
    });
    await Supabase.initialize(
      // Use the guard's public pinned host so denial is not accidentally
      // proved only by a mismatched fixture URL. All transport remains mock.
      url: ZyraInternalFounderPolicy.approvedSupabaseUrl,
      publishableKey: 'local-widget-test',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      httpClient: ZyraInternalPreviewClient(
        MockClient((_) async {
          _httpCalls++;
          return http.Response(
            '{"message":"offline test rejects every API request"}',
            403,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );
    await ZyraLocalPrefs.init();
    await ZyraLocalPrefs.bindAccount(_account);
    _prefs = await SharedPreferences.getInstance();
    _initialPrefs = _preferenceSnapshot();
  });

  tearDownAll(() async {
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
    await Supabase.instance.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_appLinksEvents, null);
  });

  setUp(() {
    _httpCalls = 0;
    _ownerChecks = 0;
    _store = FakeSignupStore();
    ZyraInitialSignupDraftService.setRepositoryForTesting(
      ZyraSignupDraftRepository(
        store: _store,
        backend: 'https://example.invalid',
        currentUserId: () {
          _ownerChecks++;
          return _account;
        },
        isPreview: () => ZyraInternalPreviewClient.isActive,
      ),
    );
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraDevOnboardingInteraction.resetForTesting();
    ZyraDevOnboardingStoryNavigation.resetForTesting();
    ZyraDevOnboardingTransition.resetForTesting();
    // Existing journey assertions intentionally cover the retained Continue
    // alternative. The focused test below checks the new fresh-run default.
    ZyraDevOnboardingInteraction.select(
      ZyraOnboardingAdvanceMode.continueButton,
    );
    ZyraText.useTestFontStubs = true;
  });

  tearDown(() {
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraDevOnboardingInteraction.resetForTesting();
    ZyraDevOnboardingStoryNavigation.resetForTesting();
    ZyraDevOnboardingTransition.resetForTesting();
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('fresh protected onboarding defaults to animated down arrow', (
    tester,
  ) async {
    ZyraDevOnboardingInteraction.resetForTesting();
    expect(
      ZyraDevOnboardingInteraction.current,
      ZyraOnboardingAdvanceMode.animatedDownArrow,
    );
    await _mountHost(tester, direction: ZyraOnboardingDirection.structured);
    await _launch(tester);
    expect(
      tester
          .widget<ZyraOnboardingArrowScope>(
            find.byType(ZyraOnboardingArrowScope),
          )
          .enabled,
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('welcome_google')));
    await tester.pumpAndSettle();
    await _finishWelcomePrelude(tester);
    expect(find.byType(DevOnboardingIntroduction), findsOneWidget);
    expect(find.byType(ZyraOnboardingArrowAction), findsNothing);
    expect(
      find.byKey(const ValueKey('dev_onboarding_reading_hint')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await _returnHome(tester);
  });

  for (final navigation in ZyraOnboardingStoryNavigation.values) {
    testWidgets(
      '${navigation.name} Guardian checkpoint arrow lifts only intro foreground and brings role content up over fixed purple',
      (tester) async {
        const direction = ZyraOnboardingDirection.structured;
        ZyraDevOnboardingStoryNavigation.select(navigation);
        ZyraDevOnboardingInteraction.select(
          ZyraOnboardingAdvanceMode.animatedDownArrow,
        );
        await _mountHost(tester, direction: direction);
        await _launch(tester);
        await _reachFinalIntroductionCard(tester, direction: direction);
        await _revealFinalIntroductionCard(tester, direction);

        const canvasKey = ValueKey('dev_onboarding_static_canvas');
        const exitKey = ValueKey('dev_opening_foreground_opacity');
        final canvas = find.byKey(canvasKey);
        final originalCanvasRect = tester.getRect(canvas);
        final originalDecoration =
            tester.widget<DecoratedBox>(canvas).decoration as BoxDecoration;
        expect(
          tester.widget<DecoratedBox>(canvas).decoration,
          isA<BoxDecoration>(),
        );
        expect(tester.widget<Opacity>(find.byKey(exitKey)).opacity, 1);

        await tester.tap(
          find.byKey(const ValueKey('dev_onboarding_story_continue')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        final leaving = tester.widget<Opacity>(find.byKey(exitKey));
        expect(leaving.opacity, inExclusiveRange(0, 1));
        expect(_verticalTranslation(tester, exitKey), lessThan(0));
        expect(tester.getRect(canvas), originalCanvasRect);
        expect(find.byType(RoleSelectionScreen), findsNothing);

        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        expect(find.byType(RoleSelectionScreen), findsOneWidget);
        final role = tester.widget<RoleSelectionScreen>(
          find.byType(RoleSelectionScreen),
        );
        expect(role.animateDevEntrance, isTrue);
        final route = ModalRoute.of(
          tester.element(find.byType(RoleSelectionScreen)),
        )!;
        expect(route.transitionDuration, Duration.zero);
        expect(route.reverseTransitionDuration, Duration.zero);
        const entryKey = ValueKey('dev_onboarding_downward_entry');
        final roleCanvas = find.ancestor(
          of: find.byKey(entryKey),
          matching: find.byType(Container),
        );
        expect(roleCanvas, findsOneWidget);
        final stationaryRoleRect = tester.getRect(roleCanvas);
        expect(stationaryRoleRect, originalCanvasRect);
        expect(
          (tester.widget<Container>(roleCanvas).decoration! as BoxDecoration)
              .gradient,
          originalDecoration.gradient,
        );
        await tester.pump(const Duration(milliseconds: 260));
        final entering = tester.widget<Opacity>(find.byKey(entryKey));
        expect(entering.opacity, inExclusiveRange(0, 1));
        expect(_verticalTranslation(tester, entryKey), greaterThan(0));
        expect(tester.getRect(roleCanvas), stationaryRoleRect);

        await tester.pumpAndSettle();
        expect(tester.widget<Opacity>(find.byKey(entryKey)).opacity, 1);
        expect(_verticalTranslation(tester, entryKey), 0);
        expect(find.byType(DevOnboardingIntroduction), findsNothing);
        await _expectNoSideEffects(tester);
        expect(tester.takeException(), isNull);
        await _returnHome(tester);
      },
    );

    testWidgets(
      '${navigation.name} Guardian checkpoint upward edge swipe uses the same down handoff',
      (tester) async {
        const direction = ZyraOnboardingDirection.structured;
        ZyraDevOnboardingStoryNavigation.select(navigation);
        ZyraDevOnboardingInteraction.select(
          ZyraOnboardingAdvanceMode.animatedDownArrow,
        );
        await _mountHost(tester, direction: direction);
        await _launch(tester);
        await _reachFinalIntroductionCard(tester, direction: direction);
        await _revealFinalIntroductionCard(tester, direction);
        const canvasKey = ValueKey('dev_onboarding_static_canvas');
        const exitKey = ValueKey('dev_opening_foreground_opacity');
        final canvas = find.byKey(canvasKey);
        final originalCanvasRect = tester.getRect(canvas);
        final originalDecoration =
            tester.widget<DecoratedBox>(canvas).decoration as BoxDecoration;

        await tester.drag(
          find.byKey(const ValueKey('dev_opening_page_3')),
          const Offset(0, -135),
        );
        await tester.pump();
        // The edge handoff runs after the release frame, then the ticker
        // needs its first frame before sampling elapsed foreground motion.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 120));
        expect(
          tester.widget<Opacity>(find.byKey(exitKey)).opacity,
          inExclusiveRange(0, 1),
        );
        expect(_verticalTranslation(tester, exitKey), lessThan(0));
        expect(tester.getRect(canvas), originalCanvasRect);
        expect(find.byType(RoleSelectionScreen), findsNothing);
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        expect(find.byType(RoleSelectionScreen), findsOneWidget);
        final role = tester.widget<RoleSelectionScreen>(
          find.byType(RoleSelectionScreen),
        );
        expect(role.animateDevEntrance, isTrue);
        final route = ModalRoute.of(
          tester.element(find.byType(RoleSelectionScreen)),
        )!;
        expect(route.transitionDuration, Duration.zero);
        expect(route.reverseTransitionDuration, Duration.zero);
        const entryKey = ValueKey('dev_onboarding_downward_entry');
        final roleCanvas = find.ancestor(
          of: find.byKey(entryKey),
          matching: find.byType(Container),
        );
        expect(roleCanvas, findsOneWidget);
        expect(tester.getRect(roleCanvas), originalCanvasRect);
        expect(
          (tester.widget<Container>(roleCanvas).decoration! as BoxDecoration)
              .gradient,
          originalDecoration.gradient,
        );
        await tester.pump(const Duration(milliseconds: 260));
        expect(
          tester.widget<Opacity>(find.byKey(entryKey)).opacity,
          inExclusiveRange(0, 1),
        );
        expect(_verticalTranslation(tester, entryKey), greaterThan(0));
        expect(tester.getRect(roleCanvas), originalCanvasRect);
        await tester.pumpAndSettle();
        expect(tester.widget<Opacity>(find.byKey(entryKey)).opacity, 1);
        expect(_verticalTranslation(tester, entryKey), 0);
        expect(find.byType(DevOnboardingIntroduction), findsNothing);
        await _expectNoSideEffects(tester);
        expect(tester.takeException(), isNull);
        await _returnHome(tester);
      },
    );
  }

  testWidgets('rapid final arrow callbacks create only one role route', (
    tester,
  ) async {
    const direction = ZyraOnboardingDirection.structured;
    ZyraDevOnboardingStoryNavigation.select(
      ZyraOnboardingStoryNavigation.tapThrough,
    );
    ZyraDevOnboardingInteraction.select(
      ZyraOnboardingAdvanceMode.animatedDownArrow,
    );
    await _mountHost(tester, direction: direction);
    await _launch(tester);
    await _reachFinalIntroductionCard(tester, direction: direction);
    await _revealFinalIntroductionCard(tester, direction);

    final advance = tester
        .widget<ZyraOnboardingArrowAction>(
          find.byKey(const ValueKey('dev_onboarding_story_continue')),
        )
        .onPressed!;
    advance();
    advance();
    await tester.pumpAndSettle();
    expect(
      find.byType(RoleSelectionScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byType(DevOnboardingIntroduction, skipOffstage: false),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await _returnHome(tester);
  });

  testWidgets(
    'restart during the Guardian checkpoint exit cannot open a stale role route',
    (tester) async {
      const direction = ZyraOnboardingDirection.structured;
      ZyraDevOnboardingStoryNavigation.select(
        ZyraOnboardingStoryNavigation.scrollDown,
      );
      ZyraDevOnboardingInteraction.select(
        ZyraOnboardingAdvanceMode.animatedDownArrow,
      );
      await _mountHost(tester, direction: direction);
      await _launch(tester);
      await _reachFinalIntroductionCard(tester, direction: direction);
      await _revealFinalIntroductionCard(tester, direction);

      await tester.tap(
        find.byKey(const ValueKey('dev_onboarding_story_continue')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        tester
            .widget<Opacity>(
              find.byKey(const ValueKey('dev_opening_foreground_opacity')),
            )
            .opacity,
        inExclusiveRange(0, 1),
      );
      expect(
        find.byType(RoleSelectionScreen, skipOffstage: false),
        findsNothing,
      );

      // This is the protected restart entry used by the design toggle. It
      // replaces the nested Navigator while the old checkpoint exit is live.
      expect(
        ZyraDevSurfaceCoordinator.instance.restartOnboarding(
          ZyraOnboardingDirection.atoms,
        ),
        isTrue,
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(WelcomeScreen), findsOneWidget);
      _expectDirectionStyle(
        tester,
        find.byType(WelcomeScreen),
        ZyraOnboardingDirection.atoms,
      );
      expect(
        find.byType(RoleSelectionScreen, skipOffstage: false),
        findsNothing,
      );
      expect(
        find.byType(DevOnboardingIntroduction, skipOffstage: false),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await _expectNoSideEffects(tester);
      await _returnHome(tester);
    },
  );

  testWidgets('outgoing intro remains faintly present until route handoff', (
    tester,
  ) async {
    const direction = ZyraOnboardingDirection.structured;
    ZyraDevOnboardingStoryNavigation.select(
      ZyraOnboardingStoryNavigation.scrollDown,
    );
    ZyraDevOnboardingInteraction.select(
      ZyraOnboardingAdvanceMode.animatedDownArrow,
    );
    await _mountHost(tester, direction: direction);
    await _launch(tester);
    await _reachFinalIntroductionCard(tester, direction: direction);
    await _revealFinalIntroductionCard(tester, direction);
    final canvasRect = tester.getRect(
      find.byKey(const ValueKey('dev_onboarding_static_canvas')),
    );

    await tester.tap(
      find.byKey(const ValueKey('dev_onboarding_story_continue')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 460));
    final opacity = tester
        .widget<Opacity>(
          find.byKey(const ValueKey('dev_opening_foreground_opacity')),
        )
        .opacity;
    expect(opacity, greaterThan(0));
    expect(opacity, lessThan(.2));
    expect(
      tester.getRect(
        find.byKey(const ValueKey('dev_onboarding_static_canvas')),
      ),
      canvasRect,
    );
    expect(find.byType(RoleSelectionScreen), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _returnHome(tester);
  });

  testWidgets(
    'reduced motion skips travel and Tap-through keeps the downward checkpoint handoff',
    (tester) async {
      const direction = ZyraOnboardingDirection.structured;
      ZyraDevOnboardingStoryNavigation.select(
        ZyraOnboardingStoryNavigation.scrollDown,
      );
      ZyraDevOnboardingInteraction.select(
        ZyraOnboardingAdvanceMode.animatedDownArrow,
      );
      await _mountHost(tester, direction: direction, disableAnimations: true);
      await _launch(tester);
      await _reachFinalIntroductionCard(tester, direction: direction);
      await _revealFinalIntroductionCard(tester, direction);
      await tester.tap(
        find.byKey(const ValueKey('dev_onboarding_story_continue')),
      );
      await tester.pump();
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      // A reduced reader keeps a stationary foreground frame, with no
      // content travel. The parent still owns the immediate route handoff.
      const entryKey = ValueKey('dev_onboarding_downward_entry');
      expect(tester.widget<Opacity>(find.byKey(entryKey)).opacity, 1);
      expect(_verticalTranslation(tester, entryKey), 0);
      await tester.pumpAndSettle();
      await _returnHome(tester);

      ZyraDevOnboardingInteraction.select(
        ZyraOnboardingAdvanceMode.continueButton,
      );
      ZyraDevOnboardingStoryNavigation.select(
        ZyraOnboardingStoryNavigation.tapThrough,
      );
      await _mountHost(tester, direction: direction);
      await _launch(tester);
      await _reachFinalIntroductionCard(tester, direction: direction);
      await tester.tap(
        find.byKey(const ValueKey('dev_onboarding_story_continue')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 32));
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      expect(find.byKey(entryKey), findsOneWidget);
      expect(
        tester
            .widget<RoleSelectionScreen>(find.byType(RoleSelectionScreen))
            .animateDevEntrance,
        isTrue,
      );
      expect(
        ModalRoute.of(
          tester.element(find.byType(RoleSelectionScreen)),
        )!.transitionDuration,
        Duration.zero,
      );
      await tester.pump(const Duration(milliseconds: 260));
      expect(
        tester.widget<Opacity>(find.byKey(entryKey)).opacity,
        inExclusiveRange(0, 1),
      );
      expect(_verticalTranslation(tester, entryKey), greaterThan(0));
      await tester.pumpAndSettle();
      expect(tester.widget<Opacity>(find.byKey(entryKey)).opacity, 1);
      expect(_verticalTranslation(tester, entryKey), 0);
      expect(tester.takeException(), isNull);
      await _returnHome(tester);
    },
  );

  test(
    'ordinary Welcome, role selection, and Guardian overview default live',
    () {
      expect(const WelcomeScreen().devPreview, isFalse);
      expect(const RoleSelectionScreen().devPreview, isFalse);
      expect(const GuardianOnboardingOverviewScreen().devPreview, isFalse);
      expect(const OnboardingFlow().devPreview, isFalse);
      expect(const WaliOnboardingFlow().devPreview, isFalse);
    },
  );

  testWidgets('fresh protected Onboarding starts Luma, not Current', (
    tester,
  ) async {
    await _mountHost(tester, implicitDirection: true);
    await _launch(tester);
    expect(
      tester
          .widget<DevSignUpProcessScreen>(find.byType(DevSignUpProcessScreen))
          .initialDirection,
      ZyraOnboardingDirection.luma,
    );
    await tester.tap(find.byKey(const ValueKey('welcome_google')));
    await tester.pumpAndSettle();
    await _finishWelcomePrelude(tester);
    expect(find.byKey(const ValueKey('dev_opening_page_1')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _returnHome(tester);
    await _expectDeveloperAccess(tester);
  });

  testWidgets('selected intro transition begins at provider-to-welcome route', (
    tester,
  ) async {
    expect(
      ZyraDevOnboardingTransition.select(ZyraOnboardingPageTransition.softLift),
      isTrue,
    );
    await _mountHost(tester, implicitDirection: true);
    await _launch(tester);
    await tester.tap(find.byKey(const ValueKey('welcome_dev_skip')));
    await tester.pump();

    final entry = find.byType(ZyraOnboardingEntryTransition);
    expect(entry, findsOneWidget);
    expect(
      tester.widget<ZyraOnboardingEntryTransition>(entry).transition,
      ZyraOnboardingPageTransition.softLift,
    );
    expect(
      ModalRoute.of(
        tester.element(find.byType(DevOnboardingIntroduction)),
      )!.transitionDuration,
      ZyraOnboardingPageTransition.softLift.duration,
    );
    await tester.pump(const Duration(milliseconds: 160));
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('dev_onboarding_entry_opacity')),
          )
          .opacity,
      inExclusiveRange(0, 1),
    );
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('dev_opening_foreground_opacity')),
          )
          .opacity,
      0,
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome to ZYRA, Shakeel.'), findsOneWidget);
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('dev_opening_foreground_opacity')),
          )
          .opacity,
      1,
    );
    await _returnHome(tester);
  });

  testWidgets(
    'Welcome and four-slide introduction stay connected with DEV Back',
    (tester) async {
      await _mountHost(tester, implicitDirection: true);
      await _launch(tester);
      await tester.tap(find.byKey(const ValueKey('welcome_dev_skip')));
      await tester.pumpAndSettle();

      const back = ValueKey('dev_onboarding_welcome_back');
      const lines = [
        'Welcome to ZYRA, Shakeel.',
        'We praise Allah and send peace and blessings upon His Messenger ﷺ.',
        'May Allah make the path ahead easy for you and guide you towards what is best.',
      ];
      for (final line in lines) {
        expect(find.text(line), findsOneWidget);
      }
      expect(find.byKey(back), findsOneWidget);
      await _finishWelcomePrelude(tester);
      expect(find.byKey(const ValueKey('dev_opening_page_1')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dev_onboarding_story_back')),
        findsOneWidget,
      );

      for (var page = 0; page < _openingThemeCount - 1; page++) {
        await _completeIntroductionPage(
          tester,
          ZyraOnboardingDirection.luma,
          page,
        );
        expect(
          find.byKey(ValueKey('dev_opening_page_${page + 2}')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('dev_onboarding_story_back')),
          findsOneWidget,
        );
        _expectOpeningProgress(tester, page + 3);
      }
      for (var previousPage = 2; previousPage >= 0; previousPage--) {
        await tester.tap(
          find.byKey(const ValueKey('dev_onboarding_story_back')),
        );
        await tester.pumpAndSettle();
        if (previousPage == 0) {
          expect(
            find.byKey(const ValueKey('dev_onboarding_verification_intro')),
            findsOneWidget,
          );
          expect(
            find.text('Verified people.\nSerious intentions.'),
            findsOneWidget,
          );
        }
        _expectOpeningProgress(tester, previousPage + 1);
      }
      await tester.tap(
        find.byKey(const ValueKey('dev_onboarding_verification_back')),
      );
      await tester.pumpAndSettle();
      for (final line in lines) {
        expect(find.text(line), findsOneWidget);
      }
      expect(
        find.byKey(const ValueKey('dev_onboarding_story_dot_0')),
        findsNothing,
      );
      await _returnHome(tester);
    },
  );

  testWidgets(
    'Trust and Photos reject repeated Next and Back callbacks without skipping',
    (tester) async {
      await _mountHost(tester, implicitDirection: true);
      await _launch(tester);
      await tester.tap(find.byKey(const ValueKey('welcome_dev_skip')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('dev_onboarding_welcome_continue')),
      );
      await tester.pumpAndSettle();
      _expectOpeningProgress(tester, 1);
      final next = tester.widget<IconButton>(
        find.byKey(const ValueKey('dev_onboarding_verification_continue')),
      );
      expect(find.byType(ZyraOnboardingArrowAction), findsNothing);
      final repeatedNext = next.onPressed!;
      repeatedNext();
      repeatedNext();
      repeatedNext();
      await tester.pumpAndSettle();
      _expectOpeningProgress(tester, 2);
      expect(find.byKey(const ValueKey('dev_opening_page_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('dev_opening_page_2')), findsNothing);

      final repeatedBack = tester
          .widget<TextButton>(
            find.byKey(const ValueKey('dev_onboarding_story_back')),
          )
          .onPressed!;
      repeatedBack();
      repeatedBack();
      repeatedBack();
      await tester.pumpAndSettle();
      _expectOpeningProgress(tester, 1);
      expect(
        find.byKey(const ValueKey('dev_onboarding_verification_intro')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('dev_onboarding_welcome_prelude')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('dev_onboarding_verification_back')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('dev_onboarding_welcome_prelude')),
        findsOneWidget,
      );
      await _expectNoSideEffects(tester);
      expect(tester.takeException(), isNull);
      await _returnHome(tester);
    },
  );

  testWidgets('Back DEV on first welcome line returns to provider entry', (
    tester,
  ) async {
    await _mountHost(tester, implicitDirection: true);
    await _launch(tester);
    await tester.tap(find.byKey(const ValueKey('welcome_dev_skip')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to ZYRA, Shakeel.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dev_onboarding_welcome_back')));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('welcome_dev_skip')), findsOneWidget);
    await _returnHome(tester);
  });

  testWidgets('DEV skips traverse the Seeker entry to unfinished My ZYRA', (
    tester,
  ) async {
    await _mountHost(tester, direction: ZyraOnboardingDirection.structured);
    await _launch(tester);
    await tester.tap(find.byKey(const ValueKey('welcome_dev_skip')));
    await tester.pumpAndSettle();
    for (var page = 0; page < _openingThemeCount + 2; page++) {
      expect(find.byType(DevOnboardingIntroduction), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dev_onboarding_skip')));
      await tester.pumpAndSettle();
    }
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('role-select-seeker')));
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('role-choice-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboarding_stage_dev_skip')));
    await tester.pumpAndSettle();
    for (var question = 0; question < 4; question++) {
      await tester.tap(find.byKey(const ValueKey('onboarding_dev_skip')));
      await tester.pumpAndSettle();
    }
    await _chooseSignupMembership(tester);
    expect(find.byType(InitialIdentityCheckScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('identity_dev_skip')));
    await tester.pumpAndSettle();
    expect(find.byType(SeekerPostIdentityChoiceScreen), findsOneWidget);
    expect(find.textContaining('profile stays hidden'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('seeker_post_identity_finish_later')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
    await _expectNoSideEffects(tester);
    expect(tester.takeException(), isNull);
    await _returnHome(tester);
    await tester.pumpAndSettle();
    await _expectDeveloperAccess(tester);
  });

  for (final direction in ZyraOnboardingDirection.values) {
    testWidgets(
      '${direction.name} is edge-to-edge while each child owns safe insets',
      (tester) async {
        const viewport = Size(390, 844);
        await _mountHost(tester, direction: direction, viewport: viewport);
        await _launch(tester);
        _expectNoHeader(tester);
        final nested = find.descendant(
          of: find.byType(DevSignUpProcessScreen),
          matching: find.byType(Navigator),
        );
        expect(nested, findsOneWidget);
        expect(tester.getRect(nested), Offset.zero & viewport);
        final welcome = find.byType(WelcomeScreen);
        expect(tester.getRect(welcome), Offset.zero & viewport);
        expect(
          MediaQuery.of(tester.element(welcome)).padding,
          const EdgeInsets.only(top: 24, bottom: 24),
          reason: 'The process must not consume the child safe-area insets',
        );
        for (final provider in const ['google', 'apple']) {
          final rect = tester.getRect(
            find.byKey(ValueKey('welcome_$provider')),
          );
          expect(rect.top, greaterThanOrEqualTo(24));
          expect(rect.bottom, lessThanOrEqualTo(viewport.height - 24));
        }
        await tester.tap(find.byKey(const ValueKey('welcome_google')));
        await tester.pumpAndSettle();
        await _finishWelcomePrelude(tester);
        final next = direction == ZyraOnboardingDirection.current
            ? find.byType(RoleSelectionScreen)
            : find.byType(DevOnboardingIntroduction);
        expect(next, findsOneWidget);
        expect(tester.getRect(next), Offset.zero & viewport);
        expect(
          MediaQuery.of(tester.element(next)).padding,
          const EdgeInsets.only(top: 24, bottom: 24),
        );
        if (direction != ZyraOnboardingDirection.current) {
          expect(
            tester.getRect(find.text('ZYRA')).top,
            greaterThanOrEqualTo(24),
          );
          final controlsRect = tester.getRect(
            find.byKey(const ValueKey('dev_onboarding_story_dot_0')),
          );
          expect(controlsRect.bottom, lessThanOrEqualTo(viewport.height - 24));
        }
        await _expectNoSideEffects(tester);
        await _returnHome(tester);
        await _expectDeveloperAccess(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Home is available at Welcome without on-page close chrome', (
    tester,
  ) async {
    final navigator = await _mountHost(tester);
    expect(ZyraDevSurfaceCoordinator.instance.canCloseOnboarding, isFalse);
    await _launch(tester);
    _expectNoHeader(tester);
    expect(find.byKey(_home).hitTestable(), findsNothing);
    await _returnHome(tester);
    await _expectDeveloperAccess(tester);
    expect(navigator.currentState!.canPop(), isTrue);
    expect(ZyraInternalPreviewClient.isActive, isTrue);
    await _expectNoSideEffects(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('retained Home cannot close after revocation or owner disposal', (
    tester,
  ) async {
    final navigator = await _mountHost(tester);
    await _launch(tester);
    await _showControls(tester);
    await tester.tap(
      find.byKey(const ValueKey('dev_controls_tab_home')).hitTestable(),
    );
    await tester.pumpAndSettle();
    final exit = find.byKey(_home);
    await tester.ensureVisible(exit);
    await tester.pumpAndSettle();
    final stale = _homeCallback(tester);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dev_signup_denied')), findsOneWidget);
    expect(ZyraDevSurfaceCoordinator.instance.canCloseOnboarding, isFalse);
    stale();
    await tester.pumpAndSettle();
    expect(navigator.currentState!.canPop(), isTrue);
    expect(find.byType(DevSignUpProcessScreen), findsOneWidget);
    await _expectNoSideEffects(tester);
    await _discardDeniedFlow(tester);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pumpAndSettle();
    stale();
    await tester.pumpAndSettle();
    expect(find.byKey(_host), findsOneWidget);
    expect(navigator.currentState!.canPop(), isFalse);
    expect(ZyraDevSurfaceCoordinator.instance.canCloseOnboarding, isFalse);
    await _expectNoSideEffects(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an old rendered Home cannot close the next onboarding flow', (
    tester,
  ) async {
    final navigator = await _mountHost(tester);
    await _launch(tester);
    await _showControls(tester);
    await tester.tap(
      find.byKey(const ValueKey('dev_controls_tab_home')).hitTestable(),
    );
    await tester.pumpAndSettle();
    final exit = find.byKey(_home);
    await tester.ensureVisible(exit);
    await tester.pumpAndSettle();
    final stale = _homeCallback(tester);
    await _returnHome(tester);
    await _launch(tester);
    stale();
    stale();
    await tester.pumpAndSettle();
    expect(find.byType(DevSignUpProcessScreen), findsOneWidget);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(navigator.currentState!.canPop(), isTrue);
    expect(ZyraDevSurfaceCoordinator.instance.canCloseOnboarding, isTrue);
    await _expectNoSideEffects(tester);
    await _returnHome(tester);
    await _expectDeveloperAccess(tester);
    expect(navigator.currentState!.canPop(), isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final viewport in const [
    (size: Size(390, 844), textScale: 1.0, label: 'standard'),
    (size: Size(390, 844), textScale: 1.3, label: 'large text'),
    (size: Size(320, 568), textScale: 1.0, label: 'compact'),
    (size: Size(320, 568), textScale: 1.4, label: 'compact large text'),
  ]) {
    testWidgets(
      'Welcome, role, and Guardian overview are reachable with real fonts ${viewport.label}',
      (tester) async {
        await _mountHost(
          tester,
          viewport: viewport.size,
          textScale: viewport.textScale,
        );
        await _launch(tester);
        _expectNoHeader(tester);
        _expectNestedRoute(tester, find.byType(WelcomeScreen));
        for (final provider in const ['google', 'apple']) {
          final button = find.byKey(ValueKey('welcome_$provider'));
          expect(button.hitTestable(), findsOneWidget);
          expect(tester.getSize(button).height, greaterThanOrEqualTo(44));
        }
        expect(tester.takeException(), isNull);
        final capture =
            viewport.label == 'standard' ||
            viewport.label == 'compact large text';
        final candidateSize = viewport.label == 'standard'
            ? 'standard'
            : 'compact_140';
        if (capture) {
          await _candidate(tester, 'welcome__$candidateSize');
        }
        await tester.tap(find.byKey(const ValueKey('welcome_google')));
        await tester.pumpAndSettle();
        await _finishWelcomePrelude(tester);
        _expectNoHeader(tester);
        _expectNestedRoute(tester, find.byType(RoleSelectionScreen));
        if (capture) {
          await _candidate(tester, 'role_choice__$candidateSize');
        }
        for (final role in const ['seeker', 'guardian']) {
          final action = find.byKey(ValueKey('role-select-$role'));
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          expect(action.hitTestable(), findsOneWidget);
          expect(tester.getSize(action).height, greaterThanOrEqualTo(44));
        }
        _expectNoHeader(tester);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('role-select-guardian')));
        await tester.pumpAndSettle();
        _expectNestedRoute(tester, find.byType(RoleSelectionScreen));
        await tester.tap(find.byKey(const ValueKey('role-choice-continue')));
        await tester.pumpAndSettle();
        _expectNoHeader(tester);
        _expectNestedRoute(
          tester,
          find.byType(GuardianOnboardingOverviewScreen),
        );
        if (capture) {
          await _candidate(tester, 'guardian_overview__$candidateSize');
        }
        final lastCopy = find.text(
          'Once your account is ready, you can invite a Seeker or accept their invitation. You do not need to be a family member.',
        );
        await tester.ensureVisible(lastCopy);
        await tester.pumpAndSettle();
        expect(lastCopy.hitTestable(), findsOneWidget);
        final begin = find.ancestor(
          of: find.text('Begin Guardian Setup'),
          matching: find.byType(FilledButton),
        );
        expect(begin.hitTestable(), findsOneWidget);
        expect(tester.getSize(begin).height, greaterThanOrEqualTo(44));
        _expectNoHeader(tester);
        expect(tester.takeException(), isNull);
        await _expectNoSideEffects(tester);
        await _returnHome(tester);
        await tester.pumpAndSettle();
        await _expectDeveloperAccess(tester);
      },
    );
  }

  for (final provider in const ['google', 'apple']) {
    for (final guardian in [false, true]) {
      testWidgets(
        '$provider simulation runs real ${guardian ? 'Guardian' : 'Seeker'} first-use questions locally',
        (tester) async {
          final navigator = await _mountHost(tester);
          final existingSession = Supabase.instance.client.auth.currentSession;
          await _launch(tester);
          expect(
            find.byKey(const ValueKey('welcome_recovery_email')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('welcome_tester_access')),
            findsNothing,
          );
          await _expectNoSideEffects(tester);
          await _chooseRole(tester, guardian: guardian, provider: provider);
          await _expectNoSideEffects(tester);
          expect(
            tester
                .widget<TextField>(find.byKey(_firstNameField))
                .textInputAction,
            TextInputAction.next,
          );
          expect(
            tester
                .widget<TextField>(find.byKey(_lastNameField))
                .textInputAction,
            TextInputAction.done,
          );
          await tester.enterText(
            find.byKey(_firstNameField),
            'Local rehearsal',
          );
          await tester.pump();
          await tester.testTextInput.receiveAction(TextInputAction.next);
          await tester.pump();
          expect(
            tester
                .widget<EditableText>(
                  find.descendant(
                    of: find.byKey(_lastNameField),
                    matching: find.byType(EditableText),
                  ),
                )
                .focusNode
                .hasFocus,
            isTrue,
          );
          final nameContinue = find.byKey(
            ValueKey(
              guardian ? 'wali_onboarding_continue' : 'onboarding_continue',
            ),
          );
          await tester.ensureVisible(nameContinue);
          await tester.tap(nameContinue);
          await tester.pumpAndSettle();
          expect(find.text("What's your name?"), findsOneWidget);
          await tester.enterText(find.byKey(_lastNameField), '   ');
          await tester.pump();
          await tester.tap(nameContinue);
          await tester.pumpAndSettle();
          expect(find.text("What's your name?"), findsOneWidget);
          await tester.enterText(find.byKey(_lastNameField), 'Example');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          expect(find.text("What's your name?"), findsOneWidget);
          await tester.pump();
          await tester.tap(
            find.byKey(
              ValueKey(
                guardian ? 'wali_onboarding_continue' : 'onboarding_continue',
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(guardian ? 'When were you born?' : "What's your gender?"),
            findsOneWidget,
          );
          await _expectNoSideEffects(tester);
          expect(
            Supabase.instance.client.auth.currentSession,
            same(existingSession),
          );
          expect(navigator.currentState!.canPop(), isTrue);
          await _returnHome(tester);
          await tester.pumpAndSettle();
          await _expectDeveloperAccess(tester);
          expect(navigator.currentState!.canPop(), isTrue);
          expect(ZyraInternalPreviewClient.isActive, isTrue);
          expect(
            ZyraDevSurfaceCoordinator.instance.entryLabel,
            'Developer Access',
          );
          await _expectNoSideEffects(tester);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }

    testWidgets('preview $provider never calls an injected OAuth function', (
      tester,
    ) async {
      var calls = 0;
      Future<ZyraAuthResult> auth() async {
        calls++;
        return const ZyraAuthResult.cancelled();
      }

      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(
            devPreview: true,
            googleSignIn: auth,
            appleSignIn: auth,
          ),
        ),
      );
      await tester.tap(find.byKey(ValueKey('welcome_$provider')));
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.byType(RoleSelectionScreen), findsOneWidget);
      await _expectNoSideEffects(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ordinary $provider still calls its actual auth callback', (
      tester,
    ) async {
      var calls = 0;
      var introductionBuilds = 0;
      Future<ZyraAuthResult> auth() async {
        calls++;
        return const ZyraAuthResult.cancelled();
      }

      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(
            googleSignIn: auth,
            appleSignIn: auth,
            devIntroductionBuilder: (_) {
              introductionBuilds++;
              return DevOnboardingIntroduction(
                direction: ZyraOnboardingDirection.structured,
                onContinue: () {},
              );
            },
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('welcome_recovery_email')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(ValueKey('welcome_$provider')));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(introductionBuilds, 0);
      expect(find.byType(DevOnboardingIntroduction), findsNothing);
      expect(find.byType(RoleSelectionScreen), findsNothing);
      expect(ZyraInternalPreviewClient.isActive, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stale $provider preview callback cannot become real OAuth', (
      tester,
    ) async {
      var calls = 0;
      Future<ZyraAuthResult> auth() async {
        calls++;
        return const ZyraAuthResult.cancelled();
      }

      await tester.pumpWidget(
        MaterialApp(
          home: WelcomeScreen(
            devPreview: true,
            googleSignIn: auth,
            appleSignIn: auth,
          ),
        ),
      );
      final stale = tester
          .widget<InkWell>(
            find.descendant(
              of: find.byKey(ValueKey('welcome_$provider')),
              matching: find.byType(InkWell),
            ),
          )
          .onTap!;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpAndSettle();
      stale();
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(
        find.byKey(const ValueKey('welcome_preview_denied')),
        findsOneWidget,
      );
      expect(find.byType(RoleSelectionScreen), findsNothing);
      await _expectNoSideEffects(tester);
      expect(tester.takeException(), isNull);
    });
  }

  for (final direction in ZyraOnboardingDirection.values) {
    for (final guardian in [false, true]) {
      testWidgets(
        '${direction.name} begins at Welcome and completes the full ${guardian ? 'Guardian' : 'Seeker'} onboarding locally',
        (tester) async {
          final audit = _OnboardingRouteAudit();
          final navigator = await _mountHost(
            tester,
            direction: direction,
            routeAudit: audit,
          );
          await _launch(tester);
          expect(
            tester
                .widget<DevSignUpProcessScreen>(
                  find.byType(DevSignUpProcessScreen),
                )
                .initialDirection,
            direction,
          );
          for (final provider in const ['google', 'apple']) {
            expect(
              find.byKey(ValueKey('welcome_$provider')).hitTestable(),
              findsOneWidget,
            );
          }
          _expectDirectionStyle(tester, find.byType(WelcomeScreen), direction);
          expect(find.byType(DevOnboardingIntroduction), findsNothing);
          await _expectNoSideEffects(tester);
          await _chooseRole(
            tester,
            guardian: guardian,
            provider: direction.index.isEven ? 'apple' : 'google',
          );
          _expectNoHeader(tester);
          final questions = guardian ? 5 : 4;
          for (var question = 0; question < questions; question++) {
            await tester.tap(find.byKey(const ValueKey('onboarding_dev_skip')));
            await tester.pumpAndSettle();
            if (question < questions - 1) {
              _expectDirectionStyle(
                tester,
                find.byType(guardian ? WaliOnboardingFlow : OnboardingFlow),
                direction,
                accent: direction != ZyraOnboardingDirection.current,
              );
            }
            await _expectNoSideEffects(tester);
          }
          await _chooseSignupMembership(tester);
          expect(find.byType(InitialIdentityCheckScreen), findsOneWidget);
          _expectDirectionStyle(
            tester,
            find.byType(InitialIdentityCheckScreen),
            direction,
            accent: direction != ZyraOnboardingDirection.current,
          );
          await tester.tap(
            find.byKey(const ValueKey('identity-consent-agree')),
          );
          await tester.pumpAndSettle();
          final verified = find.byKey(const ValueKey('identity-dev-verified'));
          await tester.ensureVisible(verified);
          await tester.pumpAndSettle();
          await tester.tap(verified);
          await tester.pumpAndSettle();
          final continueAction = find.byKey(
            const ValueKey('identity-continue'),
          );
          await tester.ensureVisible(continueAction);
          await tester.pumpAndSettle();
          await tester.tap(continueAction);
          if (guardian) {
            // The existing Guardian transition animates continuously.
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 500));
            expect(find.byType(TransitionScreen), findsOneWidget);
            _expectDirectionStyle(
              tester,
              find.byType(TransitionScreen),
              direction,
              accent: direction != ZyraOnboardingDirection.current,
            );
            final transitionContinue = find.descendant(
              of: find.byType(TransitionScreen),
              matching: find.text('Continue'),
            );
            await tester.ensureVisible(transitionContinue);
            await tester.pump(const Duration(milliseconds: 300));
            await tester.tap(transitionContinue);
            await tester.pumpAndSettle();
            expect(find.byType(ZyraCodeScreen), findsOneWidget);
            _expectDirectionStyle(
              tester,
              find.byType(ZyraCodeScreen),
              direction,
              accent: direction != ZyraOnboardingDirection.current,
            );
            expect(
              tester
                  .widget<ZyraCodeScreen>(find.byType(ZyraCodeScreen))
                  .signupPreview,
              isTrue,
            );
          } else {
            await tester.pumpAndSettle();
            expect(find.byType(SeekerPostIdentityChoiceScreen), findsOneWidget);
            await tester.tap(
              find.byKey(const ValueKey('seeker_post_identity_finish_later')),
            );
            await tester.pumpAndSettle();
            expect(find.byType(HomeShell), findsOneWidget);
          }
          expect(
            audit.pushes,
            2,
            reason: 'All first-use screens stay inside one outer route',
          );
          expect(navigator.currentState!.canPop(), isTrue);
          expect(
            find.text('Sign-up preview · no account changes'),
            findsNothing,
          );
          expect(find.text('Finish preview'), findsNothing);
          await _expectNoSideEffects(tester);
          await _returnHome(tester);
          await tester.pumpAndSettle();
          await _expectDeveloperAccess(tester);
          expect(navigator.currentState!.canPop(), isTrue);
          await _expectNoSideEffects(tester);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  // Review images are generated only by an explicit candidate-capture run.
  // The older standalone studies and approved golden baselines remain intact.
  if (_captureStyledCandidates) {
    for (final viewport in const [
      (size: Size(390, 844), scale: 1.0, label: 'standard'),
      (size: Size(320, 568), scale: 1.4, label: 'compact_140'),
    ]) {
      for (final direction in ZyraOnboardingDirection.values) {
        testWidgets(
          '${direction.name} Seeker downstream style ${viewport.label}',
          (tester) async {
            await _mountHost(
              tester,
              direction: direction,
              viewport: viewport.size,
              textScale: viewport.scale,
            );
            await _openRoleSelectionForDirection(tester, direction);
            await _styledCandidate(
              tester,
              '${direction.name}__role__${viewport.label}',
            );
            final seeker = find.byKey(const ValueKey('role-select-seeker'));
            await tester.ensureVisible(seeker);
            await tester.pumpAndSettle();
            await tester.tap(seeker);
            await tester.pumpAndSettle();
            expect(find.byType(RoleSelectionScreen), findsOneWidget);
            await tester.tap(
              find.byKey(const ValueKey('role-choice-continue')),
            );
            await tester.pumpAndSettle();
            final flow = find.byType(OnboardingFlow);
            _expectDirectionStyle(tester, flow, direction);
            await _styledCandidate(
              tester,
              '${direction.name}__seeker_welcome__${viewport.label}',
            );
            expect(find.text('First, your account.'), findsOneWidget);
            expect(
              find.text('Together, we’ll build four things.'),
              findsNothing,
            );
            _expectDirectionStyle(
              tester,
              flow,
              direction,
              accent: direction != ZyraOnboardingDirection.current,
            );
            await _styledCandidate(
              tester,
              '${direction.name}__seeker_stage__${viewport.label}',
            );
            final stageContinue = find.byKey(
              const ValueKey('onboarding_stage_continue'),
            );
            await tester.ensureVisible(stageContinue);
            await tester.pumpAndSettle();
            expect(stageContinue.hitTestable(), findsOneWidget);
            await tester.tap(stageContinue);
            await tester.pumpAndSettle();
            expect(find.text("What's your name?"), findsOneWidget);
            _expectDirectionStyle(
              tester,
              flow,
              direction,
              accent: direction != ZyraOnboardingDirection.current,
            );
            await _styledCandidate(
              tester,
              '${direction.name}__seeker_question__${viewport.label}',
            );
            final firstNameField = find.byKey(_firstNameField);
            await tester.ensureVisible(firstNameField);
            await tester.pumpAndSettle();
            expect(firstNameField.hitTestable(), findsOneWidget);
            final lastNameField = find.byKey(_lastNameField);
            await tester.ensureVisible(lastNameField);
            await tester.pumpAndSettle();
            expect(lastNameField.hitTestable(), findsOneWidget);
            if (direction != ZyraOnboardingDirection.current) {
              final privacy = find.text('Shown on your profile.');
              final continueButton = find.byKey(
                const ValueKey('onboarding_continue'),
              );
              expect(privacy, findsOneWidget);
              expect(continueButton, findsOneWidget);
              expect(
                tester.getRect(privacy).bottom,
                lessThan(tester.getRect(continueButton).top),
                reason: 'The question privacy note must clear the preview CTA',
              );
            }
            await _expectNoSideEffects(tester);
            await _returnHome(tester);
            expect(tester.takeException(), isNull);
          },
        );

        testWidgets(
          '${direction.name} Guardian downstream style ${viewport.label}',
          (tester) async {
            await _mountHost(
              tester,
              direction: direction,
              viewport: viewport.size,
              textScale: viewport.scale,
            );
            await _openRoleSelectionForDirection(tester, direction);
            final guardian = find.byKey(const ValueKey('role-select-guardian'));
            await tester.ensureVisible(guardian);
            await tester.pumpAndSettle();
            await tester.tap(guardian);
            await tester.pumpAndSettle();
            expect(find.byType(RoleSelectionScreen), findsOneWidget);
            await tester.tap(
              find.byKey(const ValueKey('role-choice-continue')),
            );
            await tester.pumpAndSettle();
            final overview = find.byType(GuardianOnboardingOverviewScreen);
            _expectDirectionStyle(
              tester,
              overview,
              direction,
              accent: direction != ZyraOnboardingDirection.current,
            );
            await _styledCandidate(
              tester,
              '${direction.name}__guardian_overview__${viewport.label}',
            );
            final begin = find.text('Begin Guardian Setup');
            await tester.ensureVisible(begin);
            await tester.pumpAndSettle();
            final button = find.ancestor(
              of: begin,
              matching: find.byType(FilledButton),
            );
            expect(button.hitTestable(), findsOneWidget);
            final labelRect = tester.getRect(begin);
            final buttonRect = tester.getRect(button);
            expect(labelRect.left, greaterThanOrEqualTo(buttonRect.left));
            expect(labelRect.right, lessThanOrEqualTo(buttonRect.right));
            expect(labelRect.top, greaterThanOrEqualTo(buttonRect.top));
            expect(labelRect.bottom, lessThanOrEqualTo(buttonRect.bottom));
            await tester.tap(begin);
            await tester.pumpAndSettle();
            expect(find.text("What's your name?"), findsOneWidget);
            _expectDirectionStyle(
              tester,
              find.byType(WaliOnboardingFlow),
              direction,
              accent: direction != ZyraOnboardingDirection.current,
            );
            await _styledCandidate(
              tester,
              '${direction.name}__guardian_question__${viewport.label}',
            );
            final firstNameField = find.byKey(_firstNameField);
            await tester.ensureVisible(firstNameField);
            await tester.pumpAndSettle();
            expect(firstNameField.hitTestable(), findsOneWidget);
            final lastNameField = find.byKey(_lastNameField);
            await tester.ensureVisible(lastNameField);
            await tester.pumpAndSettle();
            expect(lastNameField.hitTestable(), findsOneWidget);
            if (viewport.label == 'standard' &&
                (direction == ZyraOnboardingDirection.current ||
                    direction == ZyraOnboardingDirection.headspace ||
                    direction == ZyraOnboardingDirection.revolut)) {
              for (var question = 0; question < 5; question++) {
                await tester.tap(
                  find.byKey(const ValueKey('onboarding_dev_skip')),
                );
                await tester.pumpAndSettle();
              }
              await _chooseSignupMembership(tester);
              expect(find.byType(InitialIdentityCheckScreen), findsOneWidget);
              _expectDirectionStyle(
                tester,
                find.byType(InitialIdentityCheckScreen),
                direction,
                accent: direction != ZyraOnboardingDirection.current,
              );
              await _styledCandidate(
                tester,
                '${direction.name}__guardian_identity__${viewport.label}',
              );
              await tester.tap(
                find.byKey(const ValueKey('identity-consent-agree')),
              );
              await tester.pumpAndSettle();
              final verified = find.byKey(
                const ValueKey('identity-dev-verified'),
              );
              await tester.ensureVisible(verified);
              await tester.pumpAndSettle();
              await tester.tap(verified);
              await tester.pumpAndSettle();
              final identityContinue = find.byKey(
                const ValueKey('identity-continue'),
              );
              await tester.ensureVisible(identityContinue);
              await tester.pumpAndSettle();
              await tester.tap(identityContinue);
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 500));
              _expectDirectionStyle(
                tester,
                find.byType(TransitionScreen),
                direction,
                accent: direction != ZyraOnboardingDirection.current,
              );
              await _styledCandidate(
                tester,
                '${direction.name}__guardian_transition__${viewport.label}',
              );
              final transitionContinue = find.descendant(
                of: find.byType(TransitionScreen),
                matching: find.text('Continue'),
              );
              await tester.ensureVisible(transitionContinue);
              await tester.pump(const Duration(milliseconds: 300));
              await tester.tap(transitionContinue);
              await tester.pumpAndSettle();
              _expectDirectionStyle(
                tester,
                find.byType(ZyraCodeScreen),
                direction,
                accent: direction != ZyraOnboardingDirection.current,
              );
              await _styledCandidate(
                tester,
                '${direction.name}__guardian_code__${viewport.label}',
              );
            }
            await _expectNoSideEffects(tester);
            await _returnHome(tester);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets(
    'changing direction halfway restarts at Welcome inside the same outer route',
    (tester) async {
      final audit = _OnboardingRouteAudit();
      await _mountHost(tester, overlay: true, routeAudit: audit);
      await _launch(tester);
      await _chooseRole(tester, guardian: false);
      _expectDirectionStyle(
        tester,
        find.byType(OnboardingFlow),
        ZyraOnboardingDirection.current,
      );
      await tester.enterText(
        find.byKey(_firstNameField),
        'Discarded rehearsal',
      );
      await tester.enterText(find.byKey(_lastNameField), 'Example');
      // The surname change enables the action on the next frame; tap the
      // rebuilt button rather than the preceding disabled widget.
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('onboarding_continue')));
      await tester.pumpAndSettle();
      expect(find.text("What's your gender?"), findsOneWidget);
      final oldFlow = Navigator.of(tester.element(find.byType(OnboardingFlow)));
      await _showControls(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final choice = find.byKey(const ValueKey('dev_onboarding_wise'));
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      await tester.tap(choice);
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      _expectDirectionStyle(
        tester,
        find.byType(WelcomeScreen),
        ZyraOnboardingDirection.wise,
      );
      expect(find.byType(DevOnboardingIntroduction), findsNothing);
      expect(find.byType(OnboardingFlow, skipOffstage: false), findsNothing);
      expect(find.byType(DevOnboardingDirectionsScreen), findsNothing);
      expect(
        find.byType(DevSignUpProcessScreen, skipOffstage: false),
        findsOneWidget,
      );
      expect(audit.pushes, 2);
      expect(
        Navigator.of(tester.element(find.byType(WelcomeScreen))),
        isNot(same(oldFlow)),
      );
      await _expectNoSideEffects(tester);
      await _chooseRole(
        tester,
        guardian: false,
        introductionDirection: ZyraOnboardingDirection.wise,
      );
      expect(find.text("What's your name?"), findsOneWidget);
      _expectDirectionStyle(
        tester,
        find.byType(OnboardingFlow),
        ZyraOnboardingDirection.wise,
        accent: true,
      );
      expect(
        tester.widget<TextField>(find.byKey(_firstNameField)).controller?.text,
        isNot('Discarded rehearsal'),
      );
      expect(
        tester.widget<TextField>(find.byKey(_lastNameField)).controller?.text,
        isNot('Example'),
      );
      expect(audit.pushes, 2);
      await _expectNoSideEffects(tester);
      await _returnHome(tester);
      await tester.pumpAndSettle();
      await _expectDeveloperAccess(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'stale final introduction action cannot advance a restarted flow',
    (tester) async {
      final audit = _OnboardingRouteAudit();
      await _mountHost(
        tester,
        overlay: true,
        routeAudit: audit,
        direction: ZyraOnboardingDirection.structured,
      );
      await _launch(tester);
      await tester.tap(find.byKey(const ValueKey('welcome_google')));
      await tester.pumpAndSettle();
      await _finishWelcomePrelude(tester);
      for (var page = 0; page < _openingThemeCount - 1; page++) {
        await _completeIntroductionPage(
          tester,
          ZyraOnboardingDirection.structured,
          page,
        );
      }
      _expectOpeningProgress(tester, 4);
      final stale = tester
          .widget<ZyraOnboardingArrowAction>(
            find.byKey(const ValueKey('dev_onboarding_story_continue')),
          )
          .onPressed!;
      await _showControls(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final currentChoice = find.byKey(
        const ValueKey('dev_onboarding_current'),
      );
      await tester.ensureVisible(currentChoice);
      await tester.pump();
      await tester.tap(currentChoice);
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      stale();
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(RoleSelectionScreen), findsNothing);
      expect(find.byType(DevOnboardingIntroduction), findsNothing);
      expect(audit.pushes, 2);
      await _expectNoSideEffects(tester);
      await _returnHome(tester);
      await tester.pumpAndSettle();
      await _expectDeveloperAccess(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('neutral Onboarding action restarts an already open flow', (
    tester,
  ) async {
    final audit = _OnboardingRouteAudit();
    await _mountHost(tester, overlay: true, routeAudit: audit);
    await _launch(tester);
    await _chooseRole(tester, guardian: false);
    expect(find.text("What's your name?"), findsOneWidget);
    await _showControls(tester);
    await tester.pumpAndSettle();
    final dropdown = find.byKey(
      const ValueKey('dev_page_options_dropdown_Onboarding'),
    );
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('dev_entry_signup'));
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(OnboardingFlow, skipOffstage: false), findsNothing);
    expect(
      find.byType(DevSignUpProcessScreen, skipOffstage: false),
      findsOneWidget,
    );
    expect(audit.pushes, 2);
    await _expectNoSideEffects(tester);
    await _returnHome(tester);
    await tester.pumpAndSettle();
    await _expectDeveloperAccess(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed introduction callback cannot reopen role selection', (
    tester,
  ) async {
    await _mountHost(tester, direction: ZyraOnboardingDirection.structured);
    await _launch(tester);
    await tester.tap(find.byKey(const ValueKey('welcome_google')));
    await tester.pumpAndSettle();
    final stale = tester
        .widget<DevOnboardingIntroduction>(
          find.byType(DevOnboardingIntroduction),
        )
        .onContinue;
    for (var page = 0; page < _openingThemeCount; page++) {
      await _completeIntroductionPage(
        tester,
        ZyraOnboardingDirection.structured,
        page,
      );
    }
    await tester.tap(find.byKey(const ValueKey('role-select-seeker')));
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('role-choice-continue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboarding_stage_continue')));
    await tester.pumpAndSettle();
    expect(find.text("What's your name?"), findsOneWidget);
    stale();
    await tester.pumpAndSettle();
    expect(find.text("What's your name?"), findsOneWidget);
    expect(find.byType(RoleSelectionScreen), findsNothing);
    expect(find.byType(DevOnboardingIntroduction), findsNothing);
    await _expectNoSideEffects(tester);
    await _returnHome(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('denial and regrant cannot revive an old introduction callback', (
    tester,
  ) async {
    await _mountHost(tester, direction: ZyraOnboardingDirection.structured);
    await _launch(tester);
    await tester.tap(find.byKey(const ValueKey('welcome_google')));
    await tester.pumpAndSettle();
    final stale = tester
        .widget<DevOnboardingIntroduction>(
          find.byType(DevOnboardingIntroduction),
        )
        .onContinue;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dev_signup_denied')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding-preview-accent-structured')),
      findsNothing,
    );
    stale();
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsNothing);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    stale();
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(RoleSelectionScreen), findsNothing);
    await _expectNoSideEffects(tester);
    await _returnHome(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'completed Seeker flow restarts cleanly through the global toggle',
    (tester) async {
      final audit = _OnboardingRouteAudit();
      await _mountHost(tester, overlay: true, routeAudit: audit);
      final originalOwner = Object();
      final originalOpenedPages = <DevPage>[];
      final coordinator = ZyraDevSurfaceCoordinator.instance;
      coordinator.attachSeeker(originalOwner, originalOpenedPages.add);
      addTearDown(() => coordinator.detachSeeker(originalOwner));
      await _launch(tester);
      await _chooseRole(tester, guardian: false);
      for (var question = 0; question < 4; question++) {
        await tester.tap(find.byKey(const ValueKey('onboarding_dev_skip')));
        await tester.pumpAndSettle();
      }
      await _chooseSignupMembership(tester);
      await tester.tap(find.byKey(const ValueKey('identity-consent-agree')));
      await tester.pumpAndSettle();
      final verified = find.byKey(const ValueKey('identity-dev-verified'));
      await tester.ensureVisible(verified);
      await tester.pumpAndSettle();
      await tester.tap(verified);
      await tester.pumpAndSettle();
      final continueAction = find.byKey(const ValueKey('identity-continue'));
      await tester.ensureVisible(continueAction);
      await tester.pumpAndSettle();
      await tester.tap(continueAction);
      await tester.pumpAndSettle();
      expect(find.byType(SeekerPostIdentityChoiceScreen), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('seeker_post_identity_finish_later')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _showControls(tester);
      await tester.pumpAndSettle();
      final choice = find.byKey(const ValueKey('dev_onboarding_headspace'));
      await tester.ensureVisible(choice);
      await tester.pumpAndSettle();
      await tester.tap(choice);
      await tester.pumpAndSettle();
      expect(find.byType(HomeShell, skipOffstage: false), findsNothing);
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(audit.pushes, 2);
      expect(coordinator.surface, ZyraDevSurface.entry);
      coordinator.openSeeker(DevPage.profile);
      expect(originalOpenedPages, [DevPage.profile]);
      await _expectNoSideEffects(tester);
      expect(tester.takeException(), isNull);
      await _returnHome(tester);
      await tester.pumpAndSettle();
      await _expectDeveloperAccess(tester);
      expect(tester.takeException(), isNull);
    },
  );

  for (final (screen, deniedKey) in const <(Widget, String)>[
    (WelcomeScreen(devPreview: true), 'welcome_preview_denied'),
    (
      RoleSelectionScreen(devPreview: true, signupUserId: _account),
      'role_preview_denied',
    ),
    (
      GuardianOnboardingOverviewScreen(
        devPreview: true,
        signupUserId: _account,
      ),
      'guardian_overview_preview_denied',
    ),
    (DevSignUpProcessScreen(), 'dev_signup_denied'),
  ]) {
    testWidgets('$deniedKey denies direct unauthorized construction', (
      tester,
    ) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpWidget(MaterialApp(home: screen));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey(deniedKey)), findsOneWidget);
      expect(find.byKey(const ValueKey('welcome_google')), findsNothing);
      expect(find.byKey(const ValueKey('role-select-seeker')), findsNothing);
      expect(find.byType(OnboardingFlow), findsNothing);
      expect(find.byType(WaliOnboardingFlow), findsNothing);
      await _expectNoSideEffects(tester);
      expect(tester.takeException(), isNull);
    });
  }

  for (final guardian in [false, true]) {
    testWidgets(
      'stale ${guardian ? 'Guardian' : 'Seeker'} role choice callbacks cannot save a live draft',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: RoleSelectionScreen(devPreview: true, signupUserId: _account),
          ),
        );
        final staleSelection = tester
            .widget<InkWell>(
              find.byKey(
                ValueKey(
                  guardian ? 'role-select-guardian' : 'role-select-seeker',
                ),
              ),
            )
            .onTap!;
        final selection = find.byKey(
          ValueKey(guardian ? 'role-select-guardian' : 'role-select-seeker'),
        );
        await tester.ensureVisible(selection);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            ValueKey(guardian ? 'role-select-guardian' : 'role-select-seeker'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(RoleSelectionScreen), findsOneWidget);
        expect(_store.operations, 0);
        final staleAdvance = tester
            .widget<ZyraOnboardingArrowAction>(
              find.byKey(const ValueKey('role-choice-continue')),
            )
            .onPressed!;
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        await tester.pumpAndSettle();
        staleSelection();
        staleAdvance();
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('role_preview_denied')),
          findsOneWidget,
        );
        expect(find.byType(OnboardingFlow), findsNothing);
        expect(find.byType(GuardianOnboardingOverviewScreen), findsNothing);
        await _expectNoSideEffects(tester);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ordinary ${guardian ? 'Guardian' : 'Seeker'} role selection persists its account-bound choice',
      (tester) async {
        await _mountHost(tester);
        await tester.pumpWidget(
          const MaterialApp(home: RoleSelectionScreen(signupUserId: _account)),
        );
        final action = find.byKey(
          ValueKey(guardian ? 'role-select-guardian' : 'role-select-seeker'),
        );
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.byType(RoleSelectionScreen), findsOneWidget);
        expect(_store.operations, 0);
        expect(
          find.byKey(const ValueKey('role-choice-continue')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('role-choice-continue')));
        await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
        await tester.pumpAndSettle();
        expect(_store.operations, 2);
        expect(_ownerChecks, greaterThan(0));
        expect(ZyraInternalPreviewClient.isActive, isFalse);
        if (guardian) {
          final target = tester.widget<GuardianOnboardingOverviewScreen>(
            find.byType(GuardianOnboardingOverviewScreen),
          );
          expect(target.devPreview, isFalse);
          expect(target.signupUserId, _account);
        } else {
          final target = tester.widget<OnboardingFlow>(
            find.byType(OnboardingFlow),
          );
          expect(target.devPreview, isFalse);
          expect(target.signupUserId, _account);
        }
        expect(
          find.byKey(const ValueKey('onboarding_account_exit')),
          findsWidgets,
        );
        expect(_httpCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'revoked ${guardian ? 'Guardian' : 'Seeker'} questions disappear without live fallback',
      (tester) async {
        final navigator = await _mountHost(tester);
        await _launch(tester);
        await _chooseRole(tester, guardian: guardian);
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('dev_signup_denied')), findsOneWidget);
        expect(find.byType(OnboardingFlow), findsNothing);
        expect(find.byType(WaliOnboardingFlow), findsNothing);
        _expectNoHeader(tester);
        expect(navigator.currentState!.canPop(), isTrue);
        await _discardDeniedFlow(tester);
        await tester.pumpAndSettle();
        expect(find.byKey(_host), findsOneWidget);
        expect(ZyraInternalPreviewClient.isActive, isTrue);
        await _expectNoSideEffects(tester);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'stale enabled ${guardian ? 'Guardian' : 'Seeker'} question action cannot write after revocation',
      (tester) async {
        await _mountHost(tester);
        await _launch(tester);
        await _chooseRole(tester, guardian: guardian);
        await tester.enterText(find.byKey(_firstNameField), 'Local rehearsal');
        await tester.enterText(find.byKey(_lastNameField), 'Example');
        await tester.pump();
        final stale = _enabledQuestionContinue(tester, guardian: guardian);
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        await tester.pumpAndSettle();
        stale();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('dev_signup_denied')), findsOneWidget);
        expect(find.byType(InitialIdentityCheckScreen), findsNothing);
        await _expectNoSideEffects(tester);
        expect(tester.takeException(), isNull);
        await _discardDeniedFlow(tester);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'direct requested ${guardian ? 'Guardian' : 'Seeker'} questions never read a live draft when denied',
      (tester) async {
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        await tester.pumpWidget(
          MaterialApp(
            home: guardian
                ? const WaliOnboardingFlow(
                    devPreview: true,
                    signupUserId: _account,
                  )
                : const OnboardingFlow(
                    devPreview: true,
                    signupUserId: _account,
                  ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            ValueKey(
              guardian
                  ? 'guardian_signup_preview_denied'
                  : 'seeker_signup_preview_denied',
            ),
          ),
          findsOneWidget,
        );
        expect(find.byType(TextField), findsNothing);
        expect(find.byKey(const ValueKey('onboarding_continue')), findsNothing);
        expect(
          find.byKey(const ValueKey('wali_onboarding_continue')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('onboarding_account_exit')),
          findsNothing,
        );
        expect(find.byType(InitialIdentityCheckScreen), findsNothing);
        await _expectNoSideEffects(tester);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'direct ${guardian ? 'Guardian' : 'Seeker'} stale enabled question stays isolated with a live draft owner',
      (tester) async {
        await _mountHost(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: guardian
                ? const WaliOnboardingFlow(
                    devPreview: true,
                    signupUserId: _account,
                  )
                : const OnboardingFlow(
                    devPreview: true,
                    signupUserId: _account,
                  ),
          ),
        );
        await tester.pumpAndSettle();
        if (!guardian) {
          final action = find.byKey(
            const ValueKey('onboarding_stage_continue'),
          );
          expect(action.hitTestable(), findsOneWidget);
          await tester.tap(action);
          await tester.pumpAndSettle();
        }
        await tester.enterText(find.byKey(_firstNameField), 'Local rehearsal');
        await tester.enterText(find.byKey(_lastNameField), 'Example');
        await tester.pump();
        final stale = _enabledQuestionContinue(tester, guardian: guardian);
        expect(ZyraInternalPreviewClient.isActive, isFalse);
        await _expectNoSideEffects(tester);
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        await tester.pumpAndSettle();
        stale();
        await tester.pumpAndSettle();
        expect(
          find.byKey(
            ValueKey(
              guardian
                  ? 'guardian_signup_preview_denied'
                  : 'seeker_signup_preview_denied',
            ),
          ),
          findsOneWidget,
        );
        expect(find.byType(InitialIdentityCheckScreen), findsNothing);
        await _expectNoSideEffects(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('rapid Seeker arrow actions save once and replace one route', (
    tester,
  ) async {
    final audit = _OnboardingRouteAudit();
    await _mountHost(tester);
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [audit],
        home: const RoleSelectionScreen(signupUserId: _account),
      ),
    );
    final seeker = find.byKey(const ValueKey('role-select-seeker'));
    await tester.ensureVisible(seeker);
    await tester.tap(seeker);
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(_store.operations, 0);

    final arrow = tester.widget<ZyraOnboardingArrowAction>(
      find.byKey(const ValueKey('role-choice-continue')),
    );
    arrow.onPressed!();
    arrow.onPressed!();
    await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(_store.operations, 2);
    expect(audit.replacements, 1);
    expect(find.byType(RoleSelectionScreen), findsNothing);
    expect(find.byType(OnboardingFlow), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'stale Guardian overview action cannot open non-preview questions',
    (tester) async {
      ZyraInternalPreviewClient.beginPreview();
      await tester.pumpWidget(
        const MaterialApp(
          home: GuardianOnboardingOverviewScreen(
            devPreview: true,
            signupUserId: _account,
          ),
        ),
      );
      final stale = _enabledActionCallback(
        tester,
        find.byKey(const ValueKey('account_path_overview_continue')),
      );
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      stale();
      await tester.pumpAndSettle();
      expect(find.byType(WaliOnboardingFlow), findsNothing);
      await _expectNoSideEffects(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rapid Guardian overview actions replace only one route', (
    tester,
  ) async {
    final audit = _OnboardingRouteAudit();
    ZyraInternalPreviewClient.beginPreview();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [audit],
        home: const GuardianOnboardingOverviewScreen(devPreview: true),
      ),
    );
    final advance = _enabledActionCallback(
      tester,
      find.byKey(const ValueKey('account_path_overview_continue')),
    );
    advance();
    advance();
    await tester.pumpAndSettle();
    expect(audit.replacements, 1);
    expect(find.byType(WaliOnboardingFlow), findsOneWidget);
    expect(
      tester
          .widget<WaliOnboardingFlow>(find.byType(WaliOnboardingFlow))
          .devPreview,
      isTrue,
    );
    advance();
    await tester.pumpAndSettle();
    expect(audit.replacements, 1);
    await _expectNoSideEffects(tester);
    expect(tester.takeException(), isNull);
  });

  for (final disposed in [false, true]) {
    testWidgets(
      '${disposed ? 'disposed' : 'covered'} Guardian overview rejects its retained action',
      (tester) async {
        final navigator = GlobalKey<NavigatorState>();
        final audit = _OnboardingRouteAudit();
        ZyraInternalPreviewClient.beginPreview();
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: navigator,
            navigatorObservers: [audit],
            home: const GuardianOnboardingOverviewScreen(devPreview: true),
          ),
        );
        final stale = _enabledActionCallback(
          tester,
          find.byKey(const ValueKey('account_path_overview_continue')),
        );
        if (disposed) {
          await tester.pumpWidget(const SizedBox.shrink());
        } else {
          navigator.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Cover overview')),
            ),
          );
          await tester.pumpAndSettle();
        }
        stale();
        await tester.pumpAndSettle();
        expect(audit.replacements, 0);
        expect(find.byType(WaliOnboardingFlow), findsNothing);
        if (!disposed) expect(find.text('Cover overview'), findsOneWidget);
        await _expectNoSideEffects(tester);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('requested identity preview denies direct unauthorized entry', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpWidget(
      const MaterialApp(home: InitialIdentityCheckScreen(devPreview: true)),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('identity_preview_denied')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('identity-consent-agree')), findsNothing);
    expect(
      find.byKey(const ValueKey('identity-use-different-account')),
      findsNothing,
    );
    await _expectNoSideEffects(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'direct authorized signup process latches before its first child',
    (tester) async {
      expect(ZyraInternalPreviewClient.isActive, isFalse);
      await tester.pumpWidget(
        const MaterialApp(home: DevSignUpProcessScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(ZyraInternalPreviewClient.isActive, isTrue);
      await _expectNoSideEffects(tester);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('dev_signup_denied')), findsOneWidget);
      expect(ZyraInternalPreviewClient.isActive, isTrue);
      await _expectNoSideEffects(tester);
      expect(tester.takeException(), isNull);
    },
  );

  for (final action in const [
    'agree',
    'decline',
    'dev-state',
    'leave',
    'finish',
  ]) {
    testWidgets('stale identity $action callback cannot become a live action', (
      tester,
    ) async {
      await _mountHost(tester);
      var finalizeCalls = 0;
      var continueCalls = 0;
      final now = DateTime.utc(2026, 9, 28);
      final initialState =
          action == 'leave' || action == 'finish' || action == 'dev-state'
          ? ZyraIdentityVerificationState(
              result: action == 'leave'
                  ? ZyraIdentityVerificationResult.cancelled
                  : action == 'finish'
                  ? ZyraIdentityVerificationResult.verified
                  : ZyraIdentityVerificationResult.pending,
              duplicateReview: ZyraDuplicateReviewState.clear,
              consentGranted: action != 'leave',
              consentVersion: 'test-consent',
              consentRecordedAt: now,
              updatedAt: now,
            )
          : null;
      await tester.pumpWidget(
        MaterialApp(
          home: InitialIdentityCheckScreen(
            devPreview: true,
            initialState: initialState,
            finalizeOnboarding: () async {
              finalizeCalls++;
              return null;
            },
            onContinue: (_) async => continueCalls++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      late VoidCallback stale;
      if (action == 'dev-state') {
        final chip = tester.widget<ChoiceChip>(
          find.byKey(const ValueKey('identity-dev-verified')),
        );
        stale = () => chip.onSelected!(true);
      } else if (action == 'decline' || action == 'leave') {
        stale = tester
            .widget<TextButton>(
              find.byKey(
                ValueKey(
                  action == 'decline'
                      ? 'identity-consent-decline'
                      : 'identity-delete-attempt',
                ),
              ),
            )
            .onPressed!;
      } else {
        final key = ValueKey(
          action == 'finish' ? 'identity-continue' : 'identity-consent-agree',
        );
        stale = _enabledActionCallback(tester, find.byKey(key));
      }
      expect(ZyraInternalPreviewClient.isActive, isFalse);
      expect(
        find.byKey(const ValueKey('identity-use-different-account')),
        findsNothing,
      );
      await _expectNoSideEffects(tester);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pumpAndSettle();
      stale();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('identity_preview_denied')),
        findsOneWidget,
      );
      expect(finalizeCalls, 0);
      expect(continueCalls, 0);
      expect(find.byType(WelcomeScreen), findsNothing);
      await _expectNoSideEffects(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Seeker completion can remove nested routes without erasing the outer host',
    (tester) async {
      final navigator = await _mountHost(tester);
      final originalOwner = Object();
      final originalOpenedPages = <DevPage>[];
      final coordinator = ZyraDevSurfaceCoordinator.instance;
      coordinator.attachSeeker(originalOwner, originalOpenedPages.add);
      addTearDown(() => coordinator.detachSeeker(originalOwner));
      await _launch(tester);
      await _chooseRole(tester, guardian: false);
      for (var question = 0; question < 4; question++) {
        await tester.tap(find.byKey(const ValueKey('onboarding_dev_skip')));
        await tester.pumpAndSettle();
        await _expectNoSideEffects(tester);
      }
      await _chooseSignupMembership(tester);
      expect(find.byType(InitialIdentityCheckScreen), findsOneWidget);
      final consent = find.byKey(const ValueKey('identity-consent-agree'));
      expect(consent.hitTestable(), findsOneWidget);
      await tester.tap(consent);
      await tester.pumpAndSettle();
      await _expectNoSideEffects(tester);
      final verified = find.byKey(const ValueKey('identity-dev-verified'));
      await tester.ensureVisible(verified);
      await tester.pumpAndSettle();
      await tester.tap(verified);
      await tester.pumpAndSettle();
      final continueAction = find.byKey(const ValueKey('identity-continue'));
      await tester.ensureVisible(continueAction);
      await tester.pumpAndSettle();
      await tester.tap(continueAction);
      await tester.pumpAndSettle();
      expect(find.byType(SeekerPostIdentityChoiceScreen), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('seeker_post_identity_finish_later')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeShell), findsOneWidget);
      expect(navigator.currentState!.canPop(), isTrue);
      expect(coordinator.surface, ZyraDevSurface.entry);
      expect(coordinator.entryLabel, 'Onboarding');
      expect(originalOpenedPages, isEmpty);
      await _expectNoSideEffects(tester);
      await _returnHome(tester);
      await tester.pumpAndSettle();
      await _expectDeveloperAccess(tester);
      expect(find.byType(HomeShell), findsNothing);
      expect(navigator.currentState!.canPop(), isTrue);
      expect(ZyraInternalPreviewClient.isActive, isTrue);
      expect(coordinator.surface, ZyraDevSurface.entry);
      coordinator.openSeeker(DevPage.profile);
      expect(originalOpenedPages, [DevPage.profile]);
      await _expectNoSideEffects(tester);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Guardian completion reaches pure local code orientation without native actions',
    (tester) async {
      final platformCalls = <String>[];
      final shareChannel = const MethodChannel(
        'dev.fluttercommunity.plus/share',
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          // TextField focus may query whether the clipboard has any text;
          // capture actual content reads/writes, not that benign status query.
          if (call.method == 'Clipboard.setData' ||
              call.method == 'Clipboard.getData') {
            platformCalls.add(call.method);
          }
          return null;
        },
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        shareChannel,
        (call) async {
          platformCalls.add('share:${call.method}');
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          shareChannel,
          null,
        );
      });
      final navigator = await _mountHost(
        tester,
        viewport: const Size(390, 844),
      );
      await _launch(tester);
      await _chooseRole(tester, guardian: true);
      for (var question = 0; question < 5; question++) {
        await tester.tap(find.byKey(const ValueKey('onboarding_dev_skip')));
        await tester.pumpAndSettle();
        await _expectNoSideEffects(tester);
      }
      await _chooseSignupMembership(tester);
      expect(find.byType(InitialIdentityCheckScreen), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('identity-consent-agree')));
      await tester.pumpAndSettle();
      final verified = find.byKey(const ValueKey('identity-dev-verified'));
      await tester.ensureVisible(verified);
      await tester.pumpAndSettle();
      await tester.tap(verified);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('identity-continue')));
      // TransitionScreen deliberately repeats its chevron animation, so
      // advance the route transition instead of waiting for it to settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TransitionScreen), findsOneWidget);
      expect(find.text('Support and guidance'), findsOneWidget);
      await _expectNoSideEffects(tester);
      final support = tester.widget<TransitionScreen>(
        find.byType(TransitionScreen),
      );
      final staleSupportContinue = support.onContinue;
      final staleSupportSkip = support.onDevSkip!;
      final supportNavigator = Navigator.of(
        tester.element(find.byType(TransitionScreen)),
      );
      supportNavigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Cover support')),
        ),
      );
      await tester.pumpAndSettle();
      staleSupportContinue();
      staleSupportSkip();
      await tester.pump();
      expect(find.text('Cover support'), findsOneWidget);
      expect(find.byType(WaliInviteSeekerScreen), findsNothing);
      supportNavigator.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final transitionContinue = find.descendant(
        of: find.byType(TransitionScreen),
        matching: find.text('Continue'),
      );
      await tester.ensureVisible(transitionContinue);
      await tester.pump(const Duration(milliseconds: 300));
      expect(transitionContinue.hitTestable(), findsOneWidget);
      await tester.tap(transitionContinue);
      staleSupportContinue();
      staleSupportSkip();
      await tester.pumpAndSettle();
      expect(find.byType(WaliInviteSeekerScreen), findsOneWidget);
      expect(find.byType(ZyraCodeScreen), findsOneWidget);
      staleSupportContinue();
      staleSupportSkip();
      await tester.pumpAndSettle();
      expect(find.byType(WaliInviteSeekerScreen), findsOneWidget);
      expect(find.byType(ZyraCodeScreen), findsOneWidget);
      final invite = tester.widget<WaliInviteSeekerScreen>(
        find.byType(WaliInviteSeekerScreen),
      );
      final code = tester.widget<ZyraCodeScreen>(find.byType(ZyraCodeScreen));
      expect(invite.signupPreview, isTrue);
      expect(code.signupPreview, isTrue);
      expect(code.asGuardian, isTrue);
      expect(find.byKey(const ValueKey('signup_code_preview')), findsOneWidget);
      expect(find.text('SIGN-UP PREVIEW').hitTestable(), findsOneWidget);
      final appBar = find.byType(AppBar);
      expect(
        tester.getRect(find.text('SIGN-UP PREVIEW')).top,
        greaterThanOrEqualTo(tester.getRect(appBar).bottom),
      );
      _expectNoHeader(tester);
      await _candidate(tester, 'guardian_code__standard');
      for (final action in const ['copy', 'share', 'scan', 'enter']) {
        final target = find.byKey(ValueKey('signup_code_$action'));
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('signup_code_action_info')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('inline-code-composer')),
          findsNothing,
        );
        expect(platformCalls, isEmpty);
        await _expectNoSideEffects(tester);
      }
      expect(navigator.currentState!.canPop(), isTrue);
      expect(ZyraDevSurfaceCoordinator.instance.entryLabel, 'Onboarding');
      await _returnHome(tester);
      await tester.pumpAndSettle();
      await _expectDeveloperAccess(tester);
      expect(navigator.currentState!.canPop(), isTrue);
      expect(ZyraInternalPreviewClient.isActive, isTrue);
      expect(platformCalls, isEmpty);
      await _expectNoSideEffects(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('global toggle options remain available within full signup', (
    tester,
  ) async {
    await _mountHost(tester, overlay: true);
    await _launch(tester);
    await _showControls(tester);
    await tester.pumpAndSettle();
    expect(find.text('Onboarding').hitTestable(), findsWidgets);
    await tester.tap(
      find.byKey(const ValueKey('dev_controls_tab_home')).hitTestable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('Onboarding directions'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dev_onboarding_structured')),
      findsOneWidget,
    );
    await _expectNoSideEffects(tester);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
