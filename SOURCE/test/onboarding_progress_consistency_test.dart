import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/auth/role_selection_screen.dart';
import 'package:zyra/screens/onboarding/account_path_overview_screen.dart';
import 'package:zyra/screens/onboarding/chapter2_flow.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/screens/onboarding/values_preferences_flow.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';
import 'package:zyra/widgets/onboarding_top_bar.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
  });

  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });

  testWidgets('question progress states its scope and position accessibly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OnboardingTopBar(
            chapterName: 'About You',
            chapterProgress: 1 / 3,
            progressLabel: 'QUESTION 1 OF 3',
            onHelpTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('ABOUT YOU'), findsOneWidget);
    expect(find.text('QUESTION 1 OF 3'), findsOneWidget);
    final progress = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(progress.value, closeTo(1 / 3, .0001));
    expect(progress.semanticsLabel, 'About You, QUESTION 1 OF 3');
    expect(progress.valueColor!.value, ZyraColors.progressFill);
  });

  testWidgets(
    'Atoms fractional progress uses a rail, exact stages use four segments',
    (tester) async {
      const style = OnboardingPreviewStyle(
        directionName: 'atoms',
        child: SizedBox.shrink(),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                OnboardingPreviewProgress(
                  style: style,
                  progress: 1 / 3,
                  semanticValue: 'QUESTION 1 OF 3',
                ),
                OnboardingStageProgress(currentStep: 1, totalSteps: 4),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        find.byKey(const ValueKey('onboarding-stage-progress-segment-3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('onboarding-stage-progress-segment-4')),
        findsNothing,
      );
      final stageSemantics = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Sign-up journey stage',
        ),
      );
      expect(stageSemantics.properties.value, 'Stage 1 of 4');
    },
  );

  testWidgets(
    'path choice is unnumbered; Seeker overview and stages have distinct scopes',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingPreviewStyle(
            directionName: 'atoms',
            child: RoleSelectionScreen(devPreview: true),
          ),
        ),
      );
      expect(find.text('CHOOSE YOUR PATH'), findsOneWidget);
      expect(find.textContaining('OF 2'), findsNothing);
      expect(find.byType(OnboardingPreviewProgress), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPreviewStyle(
            directionName: 'atoms',
            child: OnboardingStageIntroScreen(
              stage: SeekerOnboardingStage.buildProfile,
              devPreview: true,
              onContinue: () {},
            ),
          ),
        ),
      );
      expect(find.text('PROFILE SETUP · OVERVIEW'), findsOneWidget);
      expect(find.byType(OnboardingStageProgress), findsNothing);
      for (var item = 0; item < 4; item++) {
        await tester.tap(
          find.byKey(const ValueKey('onboarding_welcome_reveal_tap_area')),
        );
        await tester.pumpAndSettle();
      }
      await tester.tap(
        find.byKey(const ValueKey('onboarding_welcome_continue')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Let’s begin with your profile.'), findsOneWidget);
      expect(find.byType(OnboardingStageProgress), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPreviewStyle(
            directionName: 'atoms',
            child: OnboardingStageIntroScreen(
              stage: SeekerOnboardingStage.journeyBio,
              devPreview: true,
              onContinue: () {},
            ),
          ),
        ),
      );
      expect(find.text('YOUR JOURNEY BIO'), findsOneWidget);
      expect(find.text('Let’s build your Journey Bio.'), findsOneWidget);
      expect(find.text('STAGE 2 OF 4'), findsNothing);
      expect(
        find.byKey(const ValueKey('onboarding-stage-progress-segment-3')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Seeker essentials count four questions including the first photo',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OnboardingFlow(devPreview: true)),
      );
      await tester.tap(find.byKey(const ValueKey('onboarding_stage_dev_skip')));
      await tester.pumpAndSettle();

      for (var question = 1; question <= 4; question++) {
        final scaffold = tester.widget<OnboardingScaffold>(
          find.byType(OnboardingScaffold),
        );
        expect(scaffold.chapterName, 'Account essentials');
        expect(scaffold.progressLabel, 'QUESTION $question OF 4');
        expect(scaffold.chapterProgress, closeTo(question / 4, .0001));
        expect(scaffold.chapterComplete, isFalse);
        expect(find.text('QUESTION $question OF 4'), findsOneWidget);
        if (question < 4) {
          await tester.tap(find.byKey(const ValueKey('onboarding_dev_skip')));
          await tester.pumpAndSettle();
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Guardian setup counts five questions including its photo', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: WaliOnboardingFlow(devPreview: true)),
    );

    for (var question = 1; question <= 5; question++) {
      expect(find.text('ACCOUNT ESSENTIALS'), findsOneWidget);
      expect(find.text('QUESTION $question OF 5'), findsOneWidget);
      if (question < 5) {
        await tester.tap(find.byKey(const ValueKey('onboarding_dev_skip')));
        await tester.pumpAndSettle();
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Compatibility Part 1 rail advances across section boundaries', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ValuesPreferencesFlow(gender: 'male', devPreview: true),
      ),
    );

    double? lastQuestionProgress;
    var reachedSecondSection = false;
    // Walk only the first two synthetic sections through the existing DEV
    // controls. The production answer and preference paths are untouched.
    for (var page = 0; page < 40; page++) {
      final questionPage = find.byType(OnboardingScaffold);
      if (questionPage.evaluate().isNotEmpty) {
        final scaffold = tester.widget<OnboardingScaffold>(questionPage);
        final position = scaffold.chapterProgress;
        if (lastQuestionProgress != null) {
          expect(position, greaterThanOrEqualTo(lastQuestionProgress));
        }
        lastQuestionProgress = position;
        if (scaffold.progressLabel == 'SECTION 2 OF 11') {
          reachedSecondSection = true;
          break;
        }
        scaffold.onDevSkip!();
      } else {
        final skip = find.byKey(const ValueKey('deferred_onboarding_dev_skip'));
        expect(skip, findsOneWidget, reason: 'No DEV path on page $page');
        tester.widget<TextButton>(skip).onPressed!();
      }
      await tester.pumpAndSettle();
    }

    expect(reachedSecondSection, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Profile progress follows the consent-decline and no-preference path',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Chapter2Flow(gender: 'male', devPreview: true)),
      );

      for (var step = 1; step <= 3; step++) {
        final scaffold = tester.widget<OnboardingScaffold>(
          find.byType(OnboardingScaffold),
        );
        expect(scaffold.progressLabel, 'STEP $step OF 21');
        scaffold.onDevSkip!();
        await tester.pumpAndSettle();
      }

      var scaffold = tester.widget<OnboardingScaffold>(
        find.byType(OnboardingScaffold),
      );
      expect(scaffold.progressLabel, 'STEP 4 OF 21');
      await tester.tap(find.text("Yes, I'd be happy to consider them."));
      await tester.pump();
      scaffold = tester.widget<OnboardingScaffold>(
        find.byType(OnboardingScaffold),
      );
      expect(scaffold.fabActive, isTrue);
      scaffold.onContinue!();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip these questions'));
      await tester.pumpAndSettle();
      scaffold = tester.widget<OnboardingScaffold>(
        find.byType(OnboardingScaffold),
      );
      expect(scaffold.progressLabel, 'STEP 5 OF 7');
      expect(scaffold.chapterProgress, closeTo(5 / 7, .0001));

      scaffold.onDevSkip!();
      await tester.pumpAndSettle();
      scaffold = tester.widget<OnboardingScaffold>(
        find.byType(OnboardingScaffold),
      );
      expect(scaffold.progressLabel, 'STEP 6 OF 7');
      await tester.tap(find.text('Skip — no preference'));
      await tester.pump();
      scaffold = tester.widget<OnboardingScaffold>(
        find.byType(OnboardingScaffold),
      );
      expect(scaffold.progressLabel, 'STEP 6 OF 6');
      expect(scaffold.chapterProgress, 1);
      expect(scaffold.chapterComplete, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Seeker overview separates completed essentials from four stages',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SeekerOnboardingOverviewScreen(
            gender: 'male',
            progressLoader: () async =>
                SeekerPostIdentityChoiceScreen.previewIncompleteProgress,
            answersLoader: () async => null,
            profileCompleteLoader: () async => false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var item = 0; item < 4; item++) {
        await tester.tap(
          find.byKey(const ValueKey('onboarding_welcome_reveal_tap_area')),
        );
        await tester.pumpAndSettle();
      }
      expect(find.text('Account essentials'), findsNothing);
      expect(find.text('Your profile'), findsOneWidget);
      expect(find.text('Your Journey Bio'), findsOneWidget);
      expect(find.text('Compatibility'), findsOneWidget);
      expect(find.text('Review & go live'), findsOneWidget);
      for (final number in ['1', '2', '3', '4']) {
        expect(find.text(number), findsOneWidget);
      }
      expect(find.text('5'), findsNothing);
      expect(
        find.byKey(const ValueKey('onboarding_welcome_continue')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Guardian overview is a roadmap, not a numbered page count', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: GuardianOnboardingOverviewScreen()),
    );

    for (final title in [
      'Account essentials',
      'Verify your identity',
      'Responsibilities',
    ]) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Guardian Presentation'), findsNothing);
    expect(find.text('Guardian Membership'), findsNothing);
    for (final number in ['01', '02', '03', '04', '05']) {
      expect(find.text(number), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });
}
