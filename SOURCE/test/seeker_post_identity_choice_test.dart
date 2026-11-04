import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/browse/browse_screen.dart';
import 'package:zyra/screens/home/home_shell.dart';
import 'package:zyra/screens/onboarding/account_path_overview_screen.dart';
import 'package:zyra/screens/onboarding/chapter2_flow.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';

import 'initial_signup_draft_test.dart' show FakeSignupStore;

class _RouteObserver extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
  }
}

void main() {
  setUpAll(() => ZyraText.useTestFontStubs = true);
  tearDownAll(() => ZyraText.useTestFontStubs = false);
  setUp(() {
    ZyraAccountState.resetForTesting();
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
  });
  tearDown(() {
    ZyraAccountState.resetForTesting();
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
  });

  for (final action in ['continue_setup', 'finish_later']) {
    testWidgets('live $action refuses a replaced same-ID account epoch', (
      tester,
    ) async {
      ZyraInitialSignupDraftService.setRepositoryForTesting(
        ZyraSignupDraftRepository(
          store: FakeSignupStore(),
          backend: 'https://example.invalid',
          currentUserId: () => 'first-user',
          isPreview: () => false,
        ),
      );
      final observer = _RouteObserver();
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: const SeekerPostIdentityChoiceScreen(
            expectedUserId: 'first-user',
          ),
        ),
      );
      final callback = tester
          .widget<ButtonStyleButton>(
            find.byKey(ValueKey('seeker_post_identity_$action')),
          )
          .onPressed!;
      final initialPushes = observer.pushes;
      ZyraAccountState.resetForTesting();
      callback();
      final finalPushes = observer.pushes;
      // Remove any unexpected destination before asserting so a failing
      // regression cannot start its live account readers.
      await tester.pumpWidget(const SizedBox.shrink());
      expect(finalPushes, initialPushes);
      expect(tester.takeException(), isNull);
    });

    testWidgets('live $action retained callback is harmless after disposal', (
      tester,
    ) async {
      ZyraInitialSignupDraftService.setRepositoryForTesting(
        ZyraSignupDraftRepository(
          store: FakeSignupStore(),
          backend: 'https://example.invalid',
          currentUserId: () => 'first-user',
          isPreview: () => false,
        ),
      );
      final observer = _RouteObserver();
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: const SeekerPostIdentityChoiceScreen(
            expectedUserId: 'first-user',
          ),
        ),
      );
      final callback = tester
          .widget<ButtonStyleButton>(
            find.byKey(ValueKey('seeker_post_identity_$action')),
          )
          .onPressed!;
      final initialPushes = observer.pushes;
      await tester.pumpWidget(const SizedBox.shrink());
      expect(callback, returnsNormally);
      expect(observer.pushes, initialPushes);
      expect(tester.takeException(), isNull);
    });

    testWidgets('live $action cannot navigate from a covered choice route', (
      tester,
    ) async {
      ZyraInitialSignupDraftService.setRepositoryForTesting(
        ZyraSignupDraftRepository(
          store: FakeSignupStore(),
          backend: 'https://example.invalid',
          currentUserId: () => 'first-user',
          isPreview: () => false,
        ),
      );
      final observer = _RouteObserver();
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: [observer],
          home: const SeekerPostIdentityChoiceScreen(
            expectedUserId: 'first-user',
          ),
        ),
      );
      final callback = tester
          .widget<ButtonStyleButton>(
            find.byKey(ValueKey('seeker_post_identity_$action')),
          )
          .onPressed!;
      navigatorKey.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Current route')),
        ),
      );
      await tester.pumpAndSettle();
      final initialPushes = observer.pushes;
      callback();
      final finalPushes = observer.pushes;
      await tester.pumpWidget(const SizedBox.shrink());
      expect(finalPushes, initialPushes);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('live handoff refuses both actions after account switch', (
    tester,
  ) async {
    var currentOwner = 'first-user';
    ZyraInitialSignupDraftService.setRepositoryForTesting(
      ZyraSignupDraftRepository(
        store: FakeSignupStore(),
        backend: 'https://example.invalid',
        currentUserId: () => currentOwner,
        isPreview: () => false,
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: SeekerPostIdentityChoiceScreen(expectedUserId: 'first-user'),
      ),
    );
    currentOwner = 'second-user';

    await tester.tap(
      find.byKey(const ValueKey('seeker_post_identity_continue_setup')),
    );
    await tester.pump();
    expect(find.byType(SeekerOnboardingOverviewScreen), findsNothing);
    expect(find.textContaining('Your account changed.'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('seeker_post_identity_finish_later')),
    );
    await tester.pump();
    expect(find.byType(HomeShell), findsNothing);
    expect(find.byType(SeekerPostIdentityChoiceScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Seeker handoff explains finish-later consequence before app', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SeekerPostIdentityChoiceScreen()),
    );

    expect(find.text('Your account is ready.'), findsOneWidget);
    expect(find.text('IF YOU FINISH LATER'), findsOneWidget);
    expect(
      find.textContaining('profile stays hidden and Discovery and Journeys'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('seeker_post_identity_continue_setup')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('seeker_post_identity_finish_later')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('onboarding_dev_skip')), findsNothing);
  });

  testWidgets('account-ready choices use quiet plum and readable accents', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SeekerPostIdentityChoiceScreen()),
    );
    final primary = tester.widget<FilledButton>(
      find.byKey(const ValueKey('seeker_post_identity_continue_setup')),
    );
    final style = primary.style!;
    expect(
      style.backgroundColor!.resolve({}),
      Color.alphaBlend(
        ZyraColors.splashWordmark.withValues(alpha: .06),
        ZyraColors.modalSheetSurface,
      ),
    );
    expect(style.backgroundColor!.resolve({}), isNot(ZyraColors.journeyGold));
    expect(style.foregroundColor!.resolve({}), ZyraColors.foreground);
    expect(style.side!.resolve({})!.color.a, closeTo(.55, .01));
    expect(
      tester.widget(
        find.byKey(const ValueKey('seeker_post_identity_finish_later')),
      ),
      isA<TextButton>(),
    );
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account-ready copy and idle time do not choose for the user', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    final observer = _RouteObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: const SeekerPostIdentityChoiceScreen(devPreview: true),
      ),
    );
    final initialPushes = observer.pushes;
    await tester.tap(find.text('Your account is ready.'));
    await tester.tap(find.text('IF YOU FINISH LATER'));
    await tester.pump(const Duration(seconds: 4));
    expect(observer.pushes, initialPushes);
    expect(find.byType(SeekerPostIdentityChoiceScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final firstChoice in ['continue_setup', 'finish_later']) {
    testWidgets('opposite choice after $firstChoice cannot push twice', (
      tester,
    ) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraInternalPreviewClient.beginPreview();
      final observer = _RouteObserver();
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: const SeekerPostIdentityChoiceScreen(devPreview: true),
        ),
      );
      final first = tester
          .widget<ButtonStyleButton>(
            find.byKey(ValueKey('seeker_post_identity_$firstChoice')),
          )
          .onPressed!;
      final secondChoice = firstChoice == 'continue_setup'
          ? 'finish_later'
          : 'continue_setup';
      final second = tester
          .widget<ButtonStyleButton>(
            find.byKey(ValueKey('seeker_post_identity_$secondChoice')),
          )
          .onPressed!;
      final initialPushes = observer.pushes;
      first();
      second();
      expect(observer.pushes, initialPushes + 1);
      await tester.pumpAndSettle();
      expect(
        find.byType(
          firstChoice == 'continue_setup'
              ? SeekerOnboardingOverviewScreen
              : HomeShell,
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('local option carries identity to real next overview', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.applyDevPreset(
      name: 'Aaliyah',
      gender: 'female',
      dob: DateTime(1998, 1, 1),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingPreviewStyle(
          directionName: 'luma',
          child: SeekerPostIdentityChoiceScreen(devPreview: true),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('seeker_post_identity_finish_later')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('seeker_post_identity_continue_setup')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SeekerOnboardingOverviewScreen), findsOneWidget);
    expect(AppState.instance.name, 'Aaliyah');
    expect(AppState.instance.gender, 'female');
    expect(
      find.byKey(const ValueKey('onboarding_stage_dev_skip')),
      findsNothing,
    );
    tester
        .widget<OnboardingStageIntroScreen>(
          find.byType(OnboardingStageIntroScreen),
        )
        .onContinue();
    await tester.pumpAndSettle();
    final profile = tester.widget<Chapter2Flow>(find.byType(Chapter2Flow));
    expect(profile.gender, 'female');
    expect(profile.devPreview, isTrue);
    expect(AppState.instance.name, 'Aaliyah');
    expect(tester.takeException(), isNull);
  });

  testWidgets('revoked or unlatched local choice never becomes live', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pumpWidget(
      const MaterialApp(home: SeekerPostIdentityChoiceScreen(devPreview: true)),
    );
    expect(
      find.byKey(const ValueKey('seeker_post_identity_preview_denied')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    ZyraInternalPreviewClient.beginPreview();
    await tester.pumpWidget(
      const MaterialApp(home: SeekerPostIdentityChoiceScreen(devPreview: true)),
    );
    expect(
      find.byKey(const ValueKey('seeker_post_identity_choice')),
      findsOneWidget,
    );
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('seeker_post_identity_preview_denied')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('seeker_post_identity_finish_later')),
      findsNothing,
    );
  });

  testWidgets('compact large-text decision keeps both actions reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: const SeekerPostIdentityChoiceScreen(devPreview: true),
      ),
    );
    expect(
      find
          .byKey(const ValueKey('seeker_post_identity_continue_setup'))
          .hitTestable(),
      findsOneWidget,
    );
    expect(
      find
          .byKey(const ValueKey('seeker_post_identity_finish_later'))
          .hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'both role overviews use protected Continue without developer Skip',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      ZyraInternalPreviewClient.beginPreview();
      AppState.instance.applyDevPreset(gender: 'female');
      await tester.pumpWidget(
        const MaterialApp(
          home: SeekerOnboardingOverviewScreen(
            gender: 'female',
            devPreview: true,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('onboarding_stage_dev_skip')),
        findsNothing,
      );
      final seekerContinue = tester
          .widget<OnboardingStageIntroScreen>(
            find.byType(OnboardingStageIntroScreen),
          )
          .onContinue;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      seekerContinue();
      await tester.pumpAndSettle();
      expect(find.byType(Chapter2Flow), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await tester.pumpWidget(
        const MaterialApp(
          home: SeekerOnboardingOverviewScreen(
            gender: 'female',
            devPreview: true,
          ),
        ),
      );
      seekerContinue();
      await tester.pumpAndSettle();
      expect(find.byType(Chapter2Flow), findsNothing);
      tester
          .widget<OnboardingStageIntroScreen>(
            find.byType(OnboardingStageIntroScreen),
          )
          .onContinue();
      await tester.pumpAndSettle();
      expect(find.byType(Chapter2Flow), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        const MaterialApp(
          home: GuardianOnboardingOverviewScreen(devPreview: true),
        ),
      );
      expect(find.byKey(const ValueKey('onboarding_dev_skip')), findsNothing);
      final guardianContinue = tester
          .widget<ZyraOnboardingArrowAction>(
            find.byKey(const ValueKey('account_path_overview_continue')),
          )
          .onPressed!;
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      guardianContinue();
      await tester.pumpAndSettle();
      expect(find.byType(WaliOnboardingFlow), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await tester.pumpWidget(
        const MaterialApp(
          home: GuardianOnboardingOverviewScreen(devPreview: true),
        ),
      );
      guardianContinue();
      await tester.pumpAndSettle();
      expect(find.byType(WaliOnboardingFlow), findsNothing);
      tester
          .widget<ZyraOnboardingArrowAction>(
            find.byKey(const ValueKey('account_path_overview_continue')),
          )
          .onPressed!();
      await tester.pumpAndSettle();
      expect(find.byType(WaliOnboardingFlow), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('first-use My ZYRA mounts no inactive account readers', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.applyDevPreset(name: 'Aaliyah', gender: 'female');
    final messages = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };
    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeShell(
            initialTab: 2,
            deferredOnboardingDevPreview: true,
            initialOnboardingProgress:
                SeekerPostIdentityChoiceScreen.previewIncompleteProgress,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue your profile'), findsOneWidget);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.byType(BrowseScreen, skipOffstage: false), findsNothing);
      expect(
        tester.widget<FloatingNavBar>(find.byType(FloatingNavBar)).currentIndex,
        2,
      );
      expect(
        messages.where(
          (message) =>
              message.contains('fetchCandidates') ||
              message.contains('fetchOnboardingProgress'),
        ),
        isEmpty,
      );
      ZyraInternalPreviewClient.finishSignOut();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('seeker_home_preview_denied')),
        findsOneWidget,
      );
      expect(find.byType(BrowseScreen, skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
    } finally {
      debugPrint = originalDebugPrint;
    }
  });

  testWidgets('unlatched Home preview never mounts a live Browse tab', (
    tester,
  ) async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeShell(
          initialTab: 0,
          deferredOnboardingDevPreview: true,
          initialOnboardingProgress:
              SeekerPostIdentityChoiceScreen.previewIncompleteProgress,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('seeker_home_preview_denied')),
      findsOneWidget,
    );
    expect(find.byType(BrowseScreen, skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
