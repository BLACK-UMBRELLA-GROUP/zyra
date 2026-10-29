import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
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

  testWidgets('Luma stage handoff stays concise', (tester) async {
    for (final direction in const ['luma']) {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPreviewStyle(
            directionName: direction,
            child: OnboardingStageIntroScreen(
              stage: SeekerOnboardingStage.journeyBio,
              devPreview: true,
              onContinue: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Let’s build your Journey Bio.'),
        findsOneWidget,
        reason: direction,
      );
      expect(find.text('STAGE 2 OF 4'), findsNothing, reason: direction);
      for (var index = 0; index < 4; index++) {
        expect(
          find.byKey(ValueKey('onboarding-stage-progress-segment-$index')),
          findsNothing,
          reason: direction,
        );
      }
      expect(
        find.byKey(const ValueKey('onboarding-stage-progress-segment-4')),
        findsNothing,
        reason: direction,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.value == 'Stage 2 of 4',
        ),
        findsNothing,
        reason: direction,
      );
      expect(tester.takeException(), isNull, reason: direction);
    }
  });

  testWidgets(
    'post-identity handoff names the profile without false progress',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingPreviewStyle(
            directionName: 'luma',
            child: OnboardingStageIntroScreen(
              stage: SeekerOnboardingStage.buildProfile,
              devPreview: true,
              onContinue: _noop,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PROFILE SETUP · OVERVIEW'), findsOneWidget);
      expect(find.textContaining('STAGE 1 OF 4'), findsNothing);
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
      expect(find.text('STAGE 1 OF 4'), findsNothing);
      expect(
        find.byKey(const ValueKey('onboarding-stage-progress-segment-0')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Luma fractional progress is a continuous local rail', (
    tester,
  ) async {
    const style = OnboardingPreviewStyle(
      directionName: 'luma',
      child: SizedBox.shrink(),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OnboardingPreviewProgress(
            style: style,
            progress: .5,
            semanticValue: 'Question 2 of 4',
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      .5,
    );
    expect(
      find.byKey(const ValueKey('onboarding-stage-progress-segment-0')),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Question 2 of 4' &&
            widget.properties.value == '50%',
      ),
      findsOneWidget,
    );
  });
}

void _noop() {}
