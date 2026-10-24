import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/models/zyra_initial_signup_draft.dart';
import 'package:zyra/screens/onboarding/generic_select_question_screen.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';
import 'package:zyra/widgets/zyra_onboarding_choice_card.dart';

import 'initial_signup_draft_test.dart' show FakeSignupStore;

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraInitialSignupDraftService.setRepositoryForTesting(
      ZyraSignupDraftRepository(
        store: FakeSignupStore(),
        backend: 'https://example.invalid',
        currentUserId: () => 'choice-account',
        isPreview: () => false,
      ),
    );
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
  });

  for (final guardian in [false, true]) {
    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} gender keeps both standalone cards and explicit next',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: guardian
                ? WaliOnboardingFlow(
                    signupUserId: 'choice-account',
                    initialDraft: ZyraInitialSignupDraft(
                      role: ZyraSignupRole.guardian,
                      step: 2,
                      firstName: 'Amina',
                      lastName: 'Ahmad',
                      dob: DateTime(1990, 1, 1),
                    ),
                  )
                : const OnboardingFlow(
                    signupUserId: 'choice-account',
                    initialDraft: ZyraInitialSignupDraft(
                      role: ZyraSignupRole.seeker,
                      step: 1,
                      firstName: 'Amina',
                      lastName: 'Ahmad',
                    ),
                  ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
              .frameContent,
          isFalse,
        );
        expect(find.byType(ZyraOnboardingChoiceCard), findsNWidgets(2));
        await tester.tap(find.text('Female'));
        await tester.pump(const Duration(milliseconds: 240));
        expect(find.byType(ZyraOnboardingChoiceCard), findsNWidgets(2));
        expect(find.text('Male'), findsOneWidget);
        expect(find.text('Female'), findsOneWidget);
        final selected = tester.widget<ZyraOnboardingChoiceCard>(
          find.byKey(
            ValueKey('${guardian ? 'guardian' : 'seeker'}_gender_female'),
          ),
        );
        expect(selected.selected, isTrue);
        expect(
          find.text(guardian ? 'What’s your gender?' : "What's your gender?"),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(
            ValueKey(
              guardian ? 'wali_onboarding_continue' : 'onboarding_continue',
            ),
          ),
        );
        await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
        await tester.pumpAndSettle();
        expect(
          find.text(
            guardian
                ? 'What is your relationship to the Seeker you support?'
                : 'When were you born?',
          ),
          findsOneWidget,
        );
        if (guardian) {
          expect(
            tester
                .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
                .frameContent,
            isFalse,
          );
          await tester.tap(find.text('Mother'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const ValueKey('onboarding_back')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<ZyraOnboardingChoiceCard>(
                find.byKey(
                  ValueKey('${guardian ? 'guardian' : 'seeker'}_gender_female'),
                ),
              )
              .selected,
          isTrue,
        );
        if (guardian) {
          await tester.tap(find.text('Male'));
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('wali_onboarding_continue')),
          );
          await tester.runAsync(
            () async => Future<void>.delayed(Duration.zero),
          );
          await tester.pumpAndSettle();
          expect(find.text('Mother'), findsNothing);
          expect(find.text('Father'), findsOneWidget);
          expect(
            tester
                .widget<ZyraOnboardingChoiceCard>(
                  find.byKey(const ValueKey('guardian_relationship_Father')),
                )
                .selected,
            isFalse,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final multiple in [false, true]) {
    testWidgets(
      'guided compatibility retains ${multiple ? 'multi' : 'single'} values',
      (tester) async {
        dynamic answer;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GenericSelectQuestionScreen(
                prompt: 'Choose an answer',
                options: const ['First', 'Second'],
                selectionType: multiple
                    ? QuestionSelectionType.multi
                    : QuestionSelectionType.single,
                guidedChoices: true,
                initialValue: multiple ? <String>['First'] : 'First',
                onChanged: (value) => answer = value,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Second'));
        await tester.pumpAndSettle();
        expect(answer, multiple ? ['First', 'Second'] : 'Second');
        await tester.tap(find.text('Second'));
        await tester.pumpAndSettle();
        expect(answer, multiple ? ['First'] : 'Second');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('profile editor default does not inherit onboarding cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenericSelectQuestionScreen(
            prompt: 'Choose an answer',
            options: const ['First', 'Second'],
            selectionType: QuestionSelectionType.single,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(ZyraOnboardingChoiceCard), findsNothing);
    expect(find.byType(ZyraOnboardingChoiceEntrance), findsNothing);
    expect(find.text('First'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
