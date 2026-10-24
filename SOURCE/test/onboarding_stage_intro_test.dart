import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/chapter3_categories.dart';
import 'package:zyra/screens/onboarding/compatibility_category_intro_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';

import 'initial_signup_draft_test.dart' show FakeSignupStore;

void main() {
  group('Seeker onboarding journey stages', () {
    test('defines four ordered outcomes with clear visibility guidance', () {
      expect(SeekerOnboardingStage.values, hasLength(4));
      expect(seekerOnboardingStages, hasLength(4));
      expect(
        seekerOnboardingStages.map((stage) => stage.id),
        orderedEquals(const [
          'build_profile',
          'journey_bio',
          'compatibility',
          'review',
        ]),
      );

      for (final stage in seekerOnboardingStages) {
        expect(stage.heading, isNotEmpty);
        expect(stage.summary, isNotEmpty);
        expect(stage.includes, isNotEmpty);
        expect(stage.visibility, isNotEmpty);
        expect(stage.outcome, isNotEmpty);
      }
    });

    test('keeps Journey Bio out of Browse and answers private', () {
      final bio = seekerOnboardingStages[1];
      final compatibility = seekerOnboardingStages[2];

      expect(bio.visibility, contains('Never shown while browsing'));
      expect(compatibility.visibility, startsWith('Private.'));
      expect(compatibility.outcome, contains('raw answers'));
    });
  });

  testWidgets('later stage introduction fits an iPhone SE viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var continued = false;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingStageIntroScreen(
          stage: SeekerOnboardingStage.compatibility,
          onContinue: () => continued = true,
        ),
      ),
    );

    expect(find.text('STAGE 3 OF 4'), findsNothing);
    expect(find.text('COMPATIBILITY'), findsOneWidget);
    expect(find.text('Let’s explore compatibility.'), findsOneWidget);
    expect(find.text('YOU’LL ADD'), findsNothing);
    expect(find.text('WHO SEES IT'), findsNothing);
    expect(find.text('WHEN DONE'), findsNothing);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('onboarding_stage_continue')),
      180,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('onboarding_stage_scrollable')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('onboarding_stage_continue')));
    expect(continued, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all later categories use one concise handoff before questions', (
    tester,
  ) async {
    for (final (stage, heading) in const [
      (SeekerOnboardingStage.journeyBio, 'Let’s build your Journey Bio.'),
      (SeekerOnboardingStage.compatibility, 'Let’s explore compatibility.'),
      (SeekerOnboardingStage.review, 'Let’s review and go live.'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingStageIntroScreen(stage: stage, onContinue: () {}),
        ),
      );
      expect(find.text(heading), findsOneWidget);
      expect(find.text('YOU’LL ADD'), findsNothing);
      expect(find.text('WHO SEES IT'), findsNothing);
      expect(find.text('WHEN DONE'), findsNothing);
      expect(
        find.byKey(const ValueKey('onboarding_stage_continue')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Seeker overview does not repeat the opening ZYRA welcome', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingStageIntroScreen(
          stage: SeekerOnboardingStage.buildProfile,
          onContinue: () {},
        ),
      ),
    );
    expect(find.text('Your next steps.'), findsOneWidget);
    expect(find.text('Welcome to ZYRA.'), findsNothing);
  });

  testWidgets('account handoff precedes essentials without premature roadmap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // This is an ordinary signed-in setup, not a developer bypass. The intro
    // now saves a protected checkpoint before advancing, so supply its
    // account-bound device-store boundary in this isolated widget test.
    final repository = ZyraSignupDraftRepository(
      store: FakeSignupStore(),
      backend: 'https://example.invalid',
      currentUserId: () => 'intro-test-account',
      isPreview: () => false,
    );
    ZyraInitialSignupDraftService.setRepositoryForTesting(repository);
    addTearDown(
      () => ZyraInitialSignupDraftService.setRepositoryForTesting(null),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingFlow(
          welcomeName: 'Shakeel Ahmad',
          signupUserId: 'intro-test-account',
        ),
      ),
    );

    expect(find.text('First, your account.'), findsOneWidget);
    expect(find.text('ACCOUNT ESSENTIALS'), findsOneWidget);
    expect(find.text('Together, we’ll build four things.'), findsNothing);
    expect(find.text('SEEKER SETUP · OVERVIEW'), findsNothing);
    expect(
      find.byKey(const ValueKey('onboarding-stage-progress-segment-0')),
      findsNothing,
    );
    expect(find.text("What's your name?"), findsNothing);

    expect(
      find.byKey(const ValueKey('onboarding_stage_account_essentials')),
      findsOneWidget,
    );
    expect(find.text('STAGE 1 OF 4'), findsNothing);
    expect(find.text('Let’s begin with your profile.'), findsNothing);
    expect(
      find.byKey(const ValueKey('onboarding-stage-progress-segment-0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('onboarding_stage_scroll_up')),
      findsNothing,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('onboarding_stage_continue')),
      180,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('onboarding_stage_scrollable')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('onboarding_stage_continue')));
    await tester.pumpAndSettle();

    expect(find.text("What's your name?"), findsOneWidget);
    expect(
      find.text('Both names will appear on your public profile.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('onboarding_first_name')),
          )
          .controller
          ?.text,
      'Shakeel',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('onboarding_last_name')))
          .controller
          ?.text,
      isEmpty,
    );
    final checkpoint = await repository.read('intro-test-account');
    expect(checkpoint?.step, 0);
    expect(checkpoint?.showIntroduction, isFalse);
    expect(checkpoint?.firstName, 'Shakeel');
    expect(checkpoint?.lastName, isNull);
  });

  testWidgets('compatibility section transition is clear and navigable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var continued = false;
    var wentBack = false;
    await tester.pumpWidget(
      MaterialApp(
        home: CompatibilityCategoryIntroScreen(
          category: chapter3Categories[3],
          sectionIndex: 4,
          totalSections: chapter3Categories.length,
          questionCount: chapter3Categories[3].questions.length,
          onContinue: () => continued = true,
          onBack: () => wentBack = true,
        ),
      ),
    );

    expect(find.text('SECTION 4 OF 11'), findsOneWidget);
    expect(find.text('Family & In-Laws'), findsOneWidget);
    expect(find.text('PRIVATE'), findsOneWidget);
    expect(find.text('ZYRA SHOWS'), findsNothing);
    expect(
      find.text('Used to calculate your compatibility score.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('compatibility_section_back')));
    expect(wentBack, isTrue);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('compatibility_section_continue')),
      160,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('compatibility_section_scrollable')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey('compatibility_section_continue')),
    );
    expect(continued, isTrue);
    expect(tester.takeException(), isNull);
  });
}
