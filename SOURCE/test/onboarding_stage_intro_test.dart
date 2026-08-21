import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/chapter3_categories.dart';
import 'package:zyra/screens/onboarding/compatibility_category_intro_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';

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

    expect(find.text('3 OF 4'), findsOneWidget);
    expect(find.text('COMPATIBILITY'), findsOneWidget);
    expect(find.text('YOU’LL ADD'), findsOneWidget);
    expect(find.text('WHO SEES IT'), findsOneWidget);
    expect(find.text('WHEN DONE'), findsOneWidget);
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

  testWidgets('personal welcome scrolls down and up before first question', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: OnboardingFlow(welcomeName: 'Shakeel Ahmad')),
    );

    expect(find.text('Welcome to ZYRA, Shakeel.'), findsOneWidget);
    expect(find.text("What's your first name?"), findsNothing);

    final pageView = tester.widget<PageView>(
      find.byKey(const ValueKey('onboarding_intro_page_view')),
    );
    expect(pageView.scrollDirection, Axis.vertical);

    await tester.tap(find.byKey(const ValueKey('onboarding_welcome_continue')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('onboarding_stage_build_profile')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('onboarding_stage_scroll_up')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('onboarding_stage_scroll_up')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to ZYRA, Shakeel.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('onboarding_welcome_continue')));
    await tester.pumpAndSettle();
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

    expect(find.text("What's your first name?"), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Shakeel',
    );
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
