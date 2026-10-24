import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_initial_signup_draft.dart';
import 'package:zyra/screens/auth/role_selection_screen.dart';
import 'package:zyra/screens/onboarding/transition_screen.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_direction_style.dart';

import 'initial_signup_draft_test.dart' show FakeSignupStore;

Widget _question({
  VoidCallback? onContinue,
  VoidCallback? onFinishLater,
  bool active = true,
}) => OnboardingScaffold(
  background: ZyraBackgroundVariant.neutral,
  chapterName: 'Account essentials',
  chapterProgress: 1 / 3,
  progressLabel: 'QUESTION 1 OF 3',
  question: 'What’s your first name?',
  content: const Text('Answer input'),
  fabActive: active,
  onContinue: onContinue,
  onFinishLater: onFinishLater,
  onSwipeBack: () {},
  onDevSkip: () {},
);

void main() {
  late ZyraSignupDraftRepository repository;

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    repository = ZyraSignupDraftRepository(
      store: FakeSignupStore(),
      backend: 'https://example.invalid',
      currentUserId: () => 'account-a',
      isPreview: () => false,
    );
    ZyraInitialSignupDraftService.setRepositoryForTesting(repository);
  });

  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
  });

  testWidgets(
    'ordinary questions use Luma and gold arrow without DEV controls',
    (tester) async {
      var advances = 0;
      await tester.pumpWidget(
        MaterialApp(home: _question(onContinue: () => advances++)),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('onboarding-preview-accent-luma')),
        findsOneWidget,
      );
      expect(find.byType(ZyraOnboardingArrowAction), findsOneWidget);
      expect(find.text('ACCOUNT ESSENTIALS'), findsOneWidget);
      expect(find.text('QUESTION 1 OF 3'), findsOneWidget);
      expect(find.text('Previous page'), findsNothing);
      expect(find.byKey(const ValueKey('onboarding_dev_skip')), findsNothing);
      expect(
        find.byKey(const ValueKey('onboarding_finish_later')),
        findsNothing,
      );
      final wordmark = tester.widget<Text>(find.text('ZYRA'));
      expect(wordmark.style?.fontFamily, 'Syne');
      expect(wordmark.style?.color, ZyraColors.splashWordmark);
      expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
      await tester.tap(find.byKey(const ValueKey('onboarding_continue')));
      expect(advances, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('explicit Current and Continue comparisons keep their layouts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPreviewStyle(
          directionName: 'current',
          child: ZyraOnboardingArrowScope(
            enabled: false,
            child: _question(onContinue: () {}),
          ),
        ),
      ),
    );
    expect(find.byType(OnboardingPreviewAccent), findsNothing);
    expect(find.byType(ZyraOnboardingArrowAction), findsNothing);
    expect(find.text('ZYRA'), findsNothing);
    expect(find.text('Previous page'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPreviewStyle(
          directionName: 'structured',
          child: ZyraOnboardingArrowScope(
            enabled: false,
            child: _question(onContinue: () {}),
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('onboarding-preview-accent-structured')),
      findsOneWidget,
    );
    expect(find.byType(ZyraOnboardingArrowAction), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary inactive question cannot advance', (tester) async {
    var advances = 0;
    await tester.pumpWidget(
      MaterialApp(home: _question(active: false, onContinue: () => advances++)),
    );
    await tester.tap(find.byKey(const ValueKey('onboarding_continue')));
    expect(advances, 0);
    expect(
      tester
          .widget<ZyraOnboardingArrowAction>(
            find.byType(ZyraOnboardingArrowAction),
          )
          .active,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('only an optional chapter can finish later with invalid answer', (
    tester,
  ) async {
    var advances = 0;
    var finishes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: _question(
          active: false,
          onContinue: () => advances++,
          onFinishLater: () => finishes++,
        ),
      ),
    );
    final finishLater = find.byKey(const ValueKey('onboarding_finish_later'));
    expect(finishLater, findsOneWidget);
    expect(find.text('Finish later'), findsOneWidget);
    await tester.tap(finishLater);
    expect(finishes, 1);
    expect(advances, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('question details contains no nonfunctional support menu', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: _question(onContinue: () {})));
    await tester.tap(find.text('···'));
    await tester.pumpAndSettle();
    expect(find.text('Question details'), findsOneWidget);
    expect(find.text('What’s your first name?'), findsNWidgets(2));
    expect(find.text('Contact Support'), findsNothing);
    expect(find.text('Report a billing issue'), findsNothing);
    expect(find.textContaining('Why do we ask for your'), findsNothing);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Question details'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'real Guardian essentials share UI and privately label birth date',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: WaliOnboardingFlow(
            signupUserId: 'account-a',
            initialDraft: ZyraInitialSignupDraft(role: ZyraSignupRole.guardian),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('ACCOUNT ESSENTIALS'), findsOneWidget);
      expect(find.text('QUESTION 1 OF 5'), findsOneWidget);
      expect(find.byType(OnboardingScaffold), findsOneWidget);
      expect(find.byKey(const ValueKey('onboarding_dev_skip')), findsNothing);
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_first_name')),
        'Amina',
      );
      await tester.enterText(
        find.byKey(const ValueKey('onboarding_last_name')),
        'Ahmed',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('wali_onboarding_continue')));
      await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.text('QUESTION 2 OF 5'), findsOneWidget);
      expect(find.text('Your date of birth stays private.'), findsOneWidget);
      expect(find.text('Shown on your profile.'), findsNothing);
      expect(
        (await tester.runAsync(() => repository.read('account-a')))?.step,
        1,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact enlarged question keeps gold continuation reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: _question(onContinue: () {}),
      ),
    );
    final action = tester.getRect(
      find.byKey(const ValueKey('onboarding_continue')),
    );
    expect(action.bottom, lessThanOrEqualTo(568));
    expect(action.left, greaterThanOrEqualTo(0));
    expect(action.right, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  for (var step = 0; step < 5; step++) {
    testWidgets('Guardian step ${step + 1} is safe on compact enlarged text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: WaliOnboardingFlow(
            signupUserId: 'account-a',
            initialDraft: ZyraInitialSignupDraft(
              role: ZyraSignupRole.guardian,
              step: step,
              firstName: step > 0 ? 'Amina' : null,
              lastName: step > 0 ? 'Ahmed' : null,
              dob: step > 1 ? DateTime(1980, 1, 1) : null,
              gender: step > 2 ? 'female' : null,
              relationship: step > 3 ? 'Mother' : null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('QUESTION ${step + 1} OF 5'), findsOneWidget);
      final continuation = tester.getRect(
        find.byKey(const ValueKey('wali_onboarding_continue')),
      );
      expect(continuation.bottom, lessThanOrEqualTo(568));
      expect(continuation.left, greaterThanOrEqualTo(0));
      expect(continuation.right, lessThanOrEqualTo(320));
      expect(find.byKey(const ValueKey('onboarding_dev_skip')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('ordinary role choice uses Luma without advancing on selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: RoleSelectionScreen(signupUserId: 'account-a')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('onboarding-preview-role-luma')),
      findsOneWidget,
    );
    expect(
      find.text('Start with the experience you need today.'),
      findsOneWidget,
    );
    expect(find.textContaining('add the other later'), findsNothing);
    expect(find.byKey(const ValueKey('role-choice-continue')), findsNothing);
    await tester.ensureVisible(
      find.byKey(const ValueKey('role-select-seeker')),
    );
    await tester.tap(find.byKey(const ValueKey('role-select-seeker')));
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('role-choice-continue')), findsOneWidget);
    expect(await tester.runAsync(() => repository.read('account-a')), isNull);
    await tester.tap(find.byKey(const ValueKey('role-select-seeker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('role-choice-continue')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ordinary Guardian handoff is readable with reachable gold arrow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var continues = 0;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: TransitionScreen(
            title: 'Support and guidance',
            body: 'A journey with trusted support. ' * 15,
            buttonLabel: 'Continue',
            onContinue: () => continues++,
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('onboarding-preview-accent-luma')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('onboarding_dev_skip')), findsNothing);
      final action = find.byKey(const ValueKey('transition_continue'));
      expect(action.hitTestable(), findsOneWidget);
      expect(tester.getRect(action).bottom, lessThanOrEqualTo(568));
      await tester.tap(action);
      expect(continues, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
