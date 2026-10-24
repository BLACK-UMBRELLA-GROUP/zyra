import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_initial_signup_draft.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';

import 'initial_signup_draft_test.dart' show FakeSignupStore;

void main() {
  late FakeSignupStore store;
  late ZyraSignupDraftRepository repository;
  setUp(() {
    store = FakeSignupStore();
    repository = ZyraSignupDraftRepository(
      store: store,
      backend: 'https://example.invalid',
      currentUserId: () => 'account-a',
      isPreview: () => false,
    );
    ZyraInitialSignupDraftService.setRepositoryForTesting(repository);
    ZyraText.useTestFontStubs = true;
  });
  tearDown(() {
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = false;
  });

  Future<void> show(WidgetTester tester, Widget child) async {
    // Ahem test glyphs are wider than the app font. These are persistence,
    // not golden/layout tests; retain space for the existing DOB placeholder.
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pumpAndSettle();
  }

  Future<void> flushPersistence(WidgetTester tester) async {
    // The repository serialization future is created in setUp's real async
    // zone. Flush it explicitly rather than mistaking fake-frame settling
    // for completed device I/O.
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Seeker completed name persists before gender and survives widget restart',
    (tester) async {
      await show(
        tester,
        const OnboardingFlow(
          signupUserId: 'account-a',
          initialDraft: ZyraInitialSignupDraft(role: ZyraSignupRole.seeker),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_first_name')),
        'Test',
      );
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_last_name')),
        'Ahmed',
      );
      tester
          .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
          .onContinue!();
      await flushPersistence(tester);
      expect(find.text("What's your gender?"), findsOneWidget);
      final restored = await tester.runAsync(
        () => repository.read('account-a'),
      );
      expect(restored?.step, 1);
      expect(restored?.firstName, 'Test');
      expect(restored?.lastName, 'Ahmed');
      await tester.pumpWidget(const SizedBox.shrink());
      await show(
        tester,
        OnboardingFlow(signupUserId: 'account-a', initialDraft: restored),
      );
      expect(find.text("What's your gender?"), findsOneWidget);
      expect(find.text("What's your name?"), findsNothing);
    },
  );

  testWidgets('Seeker cannot advance until secure save readback completes', (
    tester,
  ) async {
    store.writeWait = Completer<void>();
    await show(
      tester,
      const OnboardingFlow(
        signupUserId: 'account-a',
        initialDraft: ZyraInitialSignupDraft(
          role: ZyraSignupRole.seeker,
          step: 1,
          firstName: 'Test',
          lastName: 'Ahmed',
        ),
      ),
    );
    await tester.tap(find.text('Male'));
    tester
        .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
        .onContinue!();
    await tester.pump();
    expect(find.text("What's your gender?"), findsOneWidget);
    expect(
      tester
          .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
          .fabActive,
      isFalse,
    );
    store.writeWait!.complete();
    await flushPersistence(tester);
    expect(find.text('When were you born?'), findsOneWidget);
    expect(
      (await tester.runAsync(() => repository.read('account-a')))?.step,
      2,
    );
  });

  testWidgets(
    'failed save stays on current question with an honest retry message',
    (tester) async {
      store.rejectWrite = true;
      await show(
        tester,
        const OnboardingFlow(
          signupUserId: 'account-a',
          initialDraft: ZyraInitialSignupDraft(
            role: ZyraSignupRole.seeker,
            step: 1,
            firstName: 'Test',
            lastName: 'Ahmed',
          ),
        ),
      );
      await tester.tap(find.text('Male'));
      tester
          .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
          .onContinue!();
      await flushPersistence(tester);
      expect(find.text("What's your gender?"), findsOneWidget);
      expect(
        find.textContaining("couldn't save your progress securely"),
        findsOneWidget,
      );
      expect(await tester.runAsync(() => repository.read('account-a')), isNull);
    },
  );

  testWidgets('Guardian restores each saved question and first name', (
    tester,
  ) async {
    final questions = [
      "What's your name?",
      'When were you born?',
      'What’s your gender?',
      'What is your relationship to the Seeker you support?',
    ];
    for (var step = 0; step < 4; step++) {
      await tester.pumpWidget(const SizedBox.shrink());
      await show(
        tester,
        WaliOnboardingFlow(
          signupUserId: 'account-a',
          initialDraft: ZyraInitialSignupDraft(
            role: ZyraSignupRole.guardian,
            step: step,
            firstName: 'Guardian',
            lastName: 'Ahmed',
            dob: step > 1 ? DateTime(1980) : null,
            gender: step > 2 ? 'female' : null,
          ),
        ),
      );
      expect(find.text(questions[step]), findsOneWidget);
      if (step == 0) {
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('onboarding_first_name')),
              )
              .controller
              ?.text,
          'Guardian',
        );
      }
    }
  });

  testWidgets('Guardian first answer survives restart at date of birth', (
    tester,
  ) async {
    await show(tester, const WaliOnboardingFlow(signupUserId: 'account-a'));
    await tester.enterText(
      find.byKey(const ValueKey('onboarding_first_name')),
      'Guardian',
    );
    await tester.enterText(
      find.byKey(const ValueKey('onboarding_last_name')),
      'Ahmed',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('wali_onboarding_continue')));
    await flushPersistence(tester);
    final restored = await tester.runAsync(() => repository.read('account-a'));
    expect(restored?.role, ZyraSignupRole.guardian);
    expect(restored?.step, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await show(
      tester,
      WaliOnboardingFlow(signupUserId: 'account-a', initialDraft: restored),
    );
    expect(find.text('When were you born?'), findsOneWidget);
  });

  testWidgets(
    'Founder preview intro and first answer do not touch draft storage',
    (tester) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await show(tester, const OnboardingFlow(devPreview: true));
      tester
          .widget<OnboardingStageIntroScreen>(
            find.byType(OnboardingStageIntroScreen),
          )
          .onContinue();
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_first_name')),
        'Preview',
      );
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_last_name')),
        'Example',
      );
      tester
          .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
          .onContinue!();
      await tester.pumpAndSettle();
      expect(find.text("What's your gender?"), findsOneWidget);
      expect(store.operations, 0);
    },
  );
}
