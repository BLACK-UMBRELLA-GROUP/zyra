import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/journey_bio.dart';
import 'package:zyra/models/seeker_setup_checkpoint.dart';
import 'package:zyra/screens/home/home_shell.dart';
import 'package:zyra/screens/onboarding/account_path_overview_screen.dart';
import 'package:zyra/screens/onboarding/identity_verification_screen.dart';
import 'package:zyra/screens/onboarding/bio_onboarding_flow.dart';
import 'package:zyra/screens/onboarding/chapter2_flow.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/screens/onboarding/profile_ready_screen.dart';
import 'package:zyra/screens/onboarding/values_preferences_flow.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/services/zyra_onboarding_answers_service.dart';
import 'package:zyra/services/zyra_profile_service.dart';
import 'package:zyra/services/zyra_seeker_details_service.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';

class _JourneyRouteAudit extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
  }
}

Future<void> _mountJourney(
  WidgetTester tester,
  Widget screen, {
  NavigatorObserver? observer,
  Size size = const Size(390, 844),
  double textScale = 1,
  bool reducedMotion = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      navigatorObservers: [?observer],
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reducedMotion,
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
        ),
        child: OnboardingPreviewStyle(
          directionName: 'luma',
          child: ZyraOnboardingArrowScope(enabled: true, child: child!),
        ),
      ),
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapAction(WidgetTester tester, String key) async {
  final action = find.byKey(ValueKey(key));
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

void _expectEssentialsQuestion(WidgetTester tester, int position) {
  final scaffold = tester.widget<OnboardingScaffold>(
    find.byType(OnboardingScaffold),
  );
  expect(scaffold.progressLabel, 'QUESTION $position OF 4');
  expect(scaffold.chapterComplete, isFalse);
  expect(scaffold.chapterProgress, closeTo(position / 4, .0001));
  expect(
    find.byKey(const ValueKey('onboarding_welcome_reveal_tap_area')),
    findsNothing,
  );
  expect(find.text('Together, we’ll build four things.'), findsNothing);
}

SeekerDetails _savedProfileDetails({
  bool sensitiveAnswers = true,
  Map<String, dynamic>? preferences,
}) => SeekerDetails(
  sect: sensitiveAnswers ? 'Sunni' : null,
  revertStatus: sensitiveAnswers ? false : null,
  countryOfBirth: sensitiveAnswers ? 'United Kingdom' : null,
  nationality: sensitiveAnswers ? 'British' : null,
  ethnicity: sensitiveAnswers ? 'Pakistani' : null,
  languages: const ['English'],
  preferences:
      preferences ??
      const {
        'location': {'preference': 'United Kingdom', 'flexibility': 'green'},
        'sect': {
          'matrix': {'sunni': 'green', 'shia': 'yellow', 'other': 'red'},
          'outside_flexibility': 'yellow',
        },
        'revert': {'flexibility': 'green'},
        'country_of_birth': {'skipped': true},
        'nationality': {'skipped': true},
        'ethnicity': {'skipped': true},
        'languages': {'skipped': true},
      },
);

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    AppState.instance.resetForAccountChange();
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    AppState.instance.resetForAccountChange();
    ZyraText.useTestFontStubs = false;
  });

  test(
    'the first unfinished checkpoint is selected without redoing essentials',
    () {
      const unfinishedProfile = ZyraOnboardingProgress(
        complete: false,
        due: 0,
        missing: 0,
        hasChapter2: false,
        basicProfile: false,
      );
      const profileDone = ZyraOnboardingProgress(
        complete: false,
        due: 175,
        missing: 175,
        hasChapter2: true,
        basicProfile: true,
      );
      const answersDone = ZyraOnboardingProgress(
        complete: false,
        due: 175,
        missing: 0,
        hasChapter2: true,
        basicProfile: true,
      );
      expect(
        SeekerSetupCheckpoint.select(
          progress: unfinishedProfile,
          bioReviewed: true,
        ),
        SeekerSetupCheckpoint.profile,
      );
      expect(
        SeekerSetupCheckpoint.select(progress: profileDone, bioReviewed: false),
        SeekerSetupCheckpoint.bio,
      );
      expect(
        SeekerSetupCheckpoint.select(progress: profileDone, bioReviewed: true),
        SeekerSetupCheckpoint.compatibility,
      );
      expect(
        SeekerSetupCheckpoint.select(progress: answersDone, bioReviewed: true),
        SeekerSetupCheckpoint.review,
      );
      expect(
        SeekerSetupCheckpoint.select(
          progress: profileDone,
          bioReviewed: false,
          compatibilityStarted: true,
        ),
        SeekerSetupCheckpoint.compatibility,
      );
      expect(
        SeekerSetupCheckpoint.select(
          progress: profileDone,
          bioReviewed: true,
          profileSectionComplete: false,
        ),
        SeekerSetupCheckpoint.profile,
        reason: 'A partial Chapter 2 row is not a finished profile.',
      );
      expect(
        SeekerSetupCheckpoint.select(
          progress: const ZyraOnboardingProgress(
            complete: false,
            due: 175,
            missing: 175,
            hasChapter2: true,
            basicProfile: false,
          ),
          bioReviewed: false,
          profileSectionComplete: true,
        ),
        SeekerSetupCheckpoint.bio,
        reason: 'The publication flag is not the profile-question checkpoint.',
      );
    },
  );

  test(
    'profile resume requires saved answers, preferences, location and photos',
    () {
      bool complete({
        SeekerDetails? details,
        int photos = 3,
        String? location = 'London',
        bool? consent = true,
      }) => seekerProfileSectionComplete(
        details: details,
        photoCount: photos,
        location: location,
        article9Consent: consent,
      );

      final saved = _savedProfileDetails();
      expect(complete(details: saved), isTrue);
      expect(complete(details: saved, photos: 2), isFalse);
      expect(complete(details: saved, location: '   '), isFalse);
      expect(complete(details: null), isFalse);
      expect(complete(details: const SeekerDetails()), isFalse);
      expect(complete(details: _savedProfileDetails(preferences: {})), isFalse);
      expect(
        complete(details: _savedProfileDetails(sensitiveAnswers: false)),
        isFalse,
      );
      expect(
        complete(
          details: _savedProfileDetails(sensitiveAnswers: false),
          consent: false,
        ),
        isTrue,
        reason: 'Declining optional sensitive answers must not trap the user.',
      );
      expect(
        complete(
          details: _savedProfileDetails(sensitiveAnswers: false),
          consent: null,
        ),
        isFalse,
        reason: 'An unknown consent state is not an explicit decline.',
      );
      expect(
        complete(
          details: _savedProfileDetails(
            preferences: {
              ...saved.preferences,
              'languages': {
                'preferred': ['English'],
                'flexibility': 'not-a-traffic-light',
              },
            },
          ),
        ),
        isFalse,
      );
    },
  );

  test(
    'an intentionally empty optional Bio retains its reviewed checkpoint',
    () {
      const reviewed = JourneyBio(reviewed: true);
      expect(reviewed.isEmpty, isTrue);
      expect(reviewed.sharedItemCount, 0);
      expect(
        JourneyBio.fromOnboardingAnswers(
          reviewed.toOnboardingAnswers(),
        ).reviewed,
        isTrue,
      );
      expect(JourneyBio.fromOnboardingAnswers({}).reviewed, isFalse);
    },
  );

  testWidgets('new Seeker completes essentials before the profile roadmap', (
    tester,
  ) async {
    await _mountJourney(
      tester,
      const OnboardingFlow(devPreview: true, welcomeName: 'Aaliyah Hassan'),
    );

    expect(find.text('First, your account.'), findsOneWidget);
    expect(find.byType(AccountEssentialsIntroScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('onboarding_welcome_reveal_tap_area')),
      findsNothing,
    );
    expect(find.text('Together, we’ll build four things.'), findsNothing);
    await _tapAction(tester, 'onboarding_stage_continue');

    _expectEssentialsQuestion(tester, 1);
    expect(find.text("What's your name?"), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('onboarding_first_name')),
      'Fatima',
    );
    await tester.enterText(
      find.byKey(const ValueKey('onboarding_last_name')),
      'Ahmed',
    );
    await tester.pump();
    await _tapAction(tester, 'onboarding_continue');

    _expectEssentialsQuestion(tester, 2);
    await tester.tap(find.text('Female'));
    await tester.pump();
    await _tapAction(tester, 'onboarding_continue');

    _expectEssentialsQuestion(tester, 3);
    await tester.tap(find.text('Select date of birth'));
    await tester.pumpAndSettle();
    // The picker starts at an adult date. Confirm through its real UI rather
    // than using the protected DEV question shortcut.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await _tapAction(tester, 'onboarding_continue');

    _expectEssentialsQuestion(tester, 4);
    expect(find.text('Add your first photo'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('signup_membership_choice')),
      findsNothing,
    );
    await _tapAction(tester, 'onboarding_dev_skip');

    expect(
      find.byKey(const ValueKey('signup_membership_choice')),
      findsOneWidget,
    );
    expect(find.byType(InitialIdentityCheckScreen), findsNothing);
    await tester.tap(find.byKey(const ValueKey('signup_membership_basic')));
    await tester.pump();
    await _tapAction(tester, 'signup_membership_continue');

    expect(find.byType(InitialIdentityCheckScreen), findsOneWidget);
    expect(find.byType(SeekerPostIdentityChoiceScreen), findsNothing);
    expect(find.byType(OnboardingStageIntroScreen), findsNothing);
    expect(AppState.instance.name, 'Fatima');
    expect(AppState.instance.gender, 'female');
    expect(tester.takeException(), isNull);

    // A local walkthrough may rehearse this checkpoint without claiming
    // production verification. The dedicated IDV suite covers server gates.
    await _tapAction(tester, 'identity_dev_skip');
    expect(find.byType(SeekerPostIdentityChoiceScreen), findsOneWidget);
    expect(find.text('Together, we’ll build four things.'), findsNothing);
    await _tapAction(tester, 'seeker_post_identity_continue_setup');
    expect(find.byType(SeekerOnboardingOverviewScreen), findsOneWidget);
    expect(find.text('Together, we’ll build four things.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('post-IDV offers two explicit choices even with arrow controls', (
    tester,
  ) async {
    AppState.instance.applyDevPreset(name: 'Aaliyah', gender: 'female');
    await _mountJourney(
      tester,
      const SeekerPostIdentityChoiceScreen(devPreview: true),
    );

    expect(find.text('Continue profile setup'), findsOneWidget);
    expect(find.text('Go to My ZYRA · finish later'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('seeker_post_identity_finish_later')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('seeker_post_identity_continue_setup')),
      findsOneWidget,
    );
    expect(find.text('Skip to My ZYRA · DEV'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final finishLater in [false, true]) {
    testWidgets(
      '${finishLater ? 'finish later' : 'continue setup'} ignores a duplicate navigation request',
      (tester) async {
        AppState.instance.applyDevPreset(name: 'Aaliyah', gender: 'female');
        final observer = _JourneyRouteAudit();
        await _mountJourney(
          tester,
          const SeekerPostIdentityChoiceScreen(devPreview: true),
          observer: observer,
        );
        final routeCount = observer.pushes;
        final action = find.byKey(
          ValueKey(
            finishLater
                ? 'seeker_post_identity_finish_later'
                : 'seeker_post_identity_continue_setup',
          ),
        );
        final button = tester.widget<ButtonStyleButton>(action);
        final callback = button.onPressed!;
        callback();
        callback();
        await tester.pumpAndSettle();

        expect(observer.pushes, routeCount + 1);
        expect(
          finishLater
              ? find.byType(HomeShell)
              : find.byType(SeekerOnboardingOverviewScreen),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'finish later enters My ZYRA and one resume opens the saved journey',
    (tester) async {
      AppState.instance.applyDevPreset(name: 'Aaliyah', gender: 'female');
      final observer = _JourneyRouteAudit();
      await _mountJourney(
        tester,
        const SeekerPostIdentityChoiceScreen(devPreview: true),
        observer: observer,
      );
      await _tapAction(tester, 'seeker_post_identity_finish_later');
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.text('Continue your profile'), findsOneWidget);
      expect(find.textContaining('profile stays hidden'), findsOneWidget);
      final action = find.byKey(
        const ValueKey('my-zyra-route-onboarding-profile-gate'),
      );
      await tester.ensureVisible(action);
      final callback = tester.widget<TextButton>(action).onPressed!;
      final routesBeforeResume = observer.pushes;
      callback();
      callback();
      await tester.pumpAndSettle();

      expect(observer.pushes, routesBeforeResume + 1);
      expect(find.byType(SeekerOnboardingOverviewScreen), findsOneWidget);
      expect(find.text('Together, we’ll build four things.'), findsOneWidget);
      expect(find.text('First, your account.'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact reduced-motion setup retains choices and direct entry', (
    tester,
  ) async {
    await _mountJourney(
      tester,
      const OnboardingFlow(devPreview: true),
      size: const Size(320, 568),
      textScale: 1.4,
      reducedMotion: true,
    );
    expect(find.text('First, your account.'), findsOneWidget);
    await _tapAction(tester, 'onboarding_stage_continue');
    _expectEssentialsQuestion(tester, 1);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    AppState.instance.applyDevPreset(name: 'Aaliyah', gender: 'female');
    await _mountJourney(
      tester,
      const SeekerPostIdentityChoiceScreen(devPreview: true),
      size: const Size(320, 568),
      textScale: 1.4,
      reducedMotion: true,
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

  for (final checkpoint in SeekerSetupCheckpoint.values) {
    testWidgets(
      'saved ${checkpoint.name} checkpoint opens its matching handoff',
      (tester) async {
        AppState.instance.applyDevPreset(name: 'Aaliyah', gender: 'female');
        AppState.instance.saveJourneyBio(
          JourneyBio(
            reviewed:
                checkpoint.index >= SeekerSetupCheckpoint.compatibility.index,
          ),
        );
        final profileDone = checkpoint != SeekerSetupCheckpoint.profile;
        await _mountJourney(
          tester,
          SeekerOnboardingOverviewScreen(
            gender: 'female',
            devPreview: true,
            progress: ZyraOnboardingProgress(
              complete: false,
              due: profileDone ? 175 : 0,
              missing: checkpoint == SeekerSetupCheckpoint.review ? 0 : 175,
              hasChapter2: profileDone,
              basicProfile: false,
            ),
          ),
          reducedMotion: true,
        );
        final handoff = tester.widget<OnboardingStageIntroScreen>(
          find.byType(OnboardingStageIntroScreen),
        );
        expect(handoff.stage.index, checkpoint.index);
        expect(find.text('First, your account.'), findsNothing);
        if (checkpoint == SeekerSetupCheckpoint.profile) {
          final reveal = find.byKey(
            const ValueKey('onboarding_welcome_reveal_tap_area'),
          );
          for (var index = 0; index < 4; index++) {
            await tester.tap(reveal);
            await tester.pumpAndSettle();
          }
          await _tapAction(tester, 'onboarding_welcome_continue');
        } else {
          expect(find.text('Together, we’ll build four things.'), findsNothing);
        }
        await _tapAction(tester, 'onboarding_stage_continue');
        final questions = switch (checkpoint) {
          SeekerSetupCheckpoint.profile => find.byType(Chapter2Flow),
          SeekerSetupCheckpoint.bio => find.byType(BioOnboardingFlow),
          SeekerSetupCheckpoint.compatibility => find.byType(
            ValuesPreferencesFlow,
          ),
          SeekerSetupCheckpoint.review => find.byType(ProfileReadyScreen),
        };
        expect(questions, findsOneWidget);
        expect(find.byType(OnboardingFlow), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final actualProfileComplete in [false, true]) {
    testWidgets(
      'saved partial row resumes ${actualProfileComplete ? 'Bio when actual profile is complete' : 'profile when actual questions are unfinished'}',
      (tester) async {
        await _mountJourney(
          tester,
          SeekerOnboardingOverviewScreen(
            gender: 'female',
            progressLoader: () async => const ZyraOnboardingProgress(
              complete: false,
              due: 175,
              missing: 175,
              hasChapter2: true,
              basicProfile: false,
            ),
            answersLoader: () async => const ZyraOnboardingAnswersSnapshot(
              ch3Answers: {},
              ch4Preferences: {},
              ch4HardRequirements: {},
              journeyBio: JourneyBio(),
            ),
            profileCompleteLoader: () async => actualProfileComplete,
          ),
        );
        final intro = tester.widget<OnboardingStageIntroScreen>(
          find.byType(OnboardingStageIntroScreen),
        );
        expect(
          intro.stage,
          actualProfileComplete
              ? SeekerOnboardingStage.journeyBio
              : SeekerOnboardingStage.buildProfile,
        );
        expect(find.text('First, your account.'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('an unreadable saved setup cannot start a replacement chapter', (
    tester,
  ) async {
    await _mountJourney(
      tester,
      SeekerOnboardingOverviewScreen(
        gender: 'female',
        progressLoader: () async => const ZyraOnboardingProgress(
          complete: false,
          due: 175,
          missing: 100,
          hasChapter2: true,
          basicProfile: true,
        ),
        answersLoader: () async => throw StateError('local read failure'),
        profileCompleteLoader: () async => true,
      ),
    );
    expect(
      find.textContaining('saved setup could not be loaded'),
      findsOneWidget,
    );
    expect(find.byType(OnboardingStageIntroScreen), findsNothing);
    expect(find.byType(Chapter2Flow), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
