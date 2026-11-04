import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/data/chapter3_categories.dart';
import 'package:zyra/screens/onboarding/values_preferences_flow.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';

void main() {
  setUp(() => ZyraDeveloperAccess.setAuthorizedForTesting(true));
  tearDown(() => ZyraDeveloperAccess.setAuthorizedForTesting(false));
  testWidgets(
    'compatibility flow completes About You before Partner Preferences',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ValuesPreferencesFlow(gender: 'male', devPreview: true),
        ),
      );

      final firstCategory = chapter3Categories.first;
      final firstQuestion = firstCategory.questions.first;
      expect(find.text('SECTION 1 OF 11'), findsOneWidget);
      expect(find.text(firstCategory.name), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('compatibility_section_continue')),
      );
      await tester.pumpAndSettle();

      expect(find.text(firstQuestion.prompt), findsWidgets);
      await tester.tap(find.text(firstQuestion.options.first));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('onboarding_continue')));
      await tester.pumpAndSettle();

      final secondQuestion = firstCategory.questions[1];
      expect(find.text(secondQuestion.prompt), findsWidgets);
      expect(find.text('Who would you be open to?'), findsNothing);
      expect(
        find.text('Private. Used to calculate your compatibility score.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'code-only preview advances an unanswered question without Skip',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: ValuesPreferencesFlow(gender: 'male', devPreview: true),
        ),
      );

      final firstCategory = chapter3Categories.first;
      await tester.tap(
        find.byKey(const ValueKey('compatibility_section_continue')),
      );
      await tester.pumpAndSettle();

      expect(find.text(firstCategory.questions.first.prompt), findsWidgets);
      expect(find.byKey(const ValueKey('onboarding_dev_skip')), findsNothing);
      final question = tester.widget<OnboardingScaffold>(
        find.byType(OnboardingScaffold),
      );
      expect(question.fabActive, isFalse);
      final advanceFromCode = question.onContinue!;

      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      advanceFromCode();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('values_preview_denied')),
        findsOneWidget,
      );
      expect(find.text(firstCategory.questions[1].prompt), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await tester.pumpWidget(
        const MaterialApp(
          home: ValuesPreferencesFlow(gender: 'male', devPreview: true),
        ),
      );
      advanceFromCode();
      await tester.pumpAndSettle();
      expect(find.text(firstCategory.name), findsOneWidget);
      expect(find.text(firstCategory.questions[1].prompt), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('compatibility_section_continue')),
      );
      await tester.pumpAndSettle();
      final freshQuestion = tester.widget<OnboardingScaffold>(
        find.byType(OnboardingScaffold),
      );
      expect(freshQuestion.fabActive, isFalse);
      freshQuestion.onContinue!();
      await tester.pumpAndSettle();

      expect(find.text(firstCategory.questions[1].prompt), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
