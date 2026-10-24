import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_initial_signup_draft.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'package:zyra/widgets/zyra_onboarding_name_field.dart';

import 'initial_signup_draft_test.dart' show FakeSignupStore;

const _fieldKey = ValueKey('onboarding_first_name');
const _lastNameFieldKey = ValueKey('onboarding_last_name');

Widget _question({
  required TextEditingController controller,
  ValueChanged<String>? onChanged,
  VoidCallback? onContinue,
  bool lastName = false,
}) => OnboardingScaffold(
  background: ZyraBackgroundVariant.neutral,
  chapterName: 'Account essentials',
  chapterProgress: 1 / 3,
  progressLabel: 'QUESTION 1 OF 3',
  question: 'What’s your first name?',
  subtext: 'This is how you’ll appear to other members.',
  frameContent: false,
  content: ZyraOnboardingNameField(
    controller: controller,
    onChanged: onChanged ?? (_) {},
    lastName: lastName,
  ),
  fabActive: true,
  onContinue: onContinue ?? () {},
);

void main() {
  late TextEditingController controller;
  late ZyraSignupDraftRepository repository;

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.selectAppFont(ZyraText.currentDefaultFont);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    controller = TextEditingController();
    repository = ZyraSignupDraftRepository(
      store: FakeSignupStore(),
      backend: 'https://example.invalid',
      currentUserId: () => 'account-a',
      isPreview: () => false,
    );
    ZyraInitialSignupDraftService.setRepositoryForTesting(repository);
  });

  tearDown(() {
    controller.dispose();
    ZyraText.useTestFontStubs = false;
    ZyraText.selectAppFont(ZyraText.currentDefaultFont);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
  });

  testWidgets('name input is centred Poppins with a gold unfilled underline', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: _question(controller: controller)),
    );
    final field = tester.widget<TextField>(find.byKey(_fieldKey));
    expect(field.controller, same(controller));
    expect(field.textAlign, TextAlign.center);
    expect(field.style?.fontFamily, 'Poppins');
    expect(field.style?.fontSize, 28);
    expect(field.cursorColor, ZyraColors.splashWordmark);
    expect(field.decoration?.filled, isNot(true));
    expect(field.decoration?.enabledBorder, isA<UnderlineInputBorder>());
    expect(field.decoration?.focusedBorder, isA<UnderlineInputBorder>());
    final focusBorder = field.decoration!.focusedBorder!;
    expect(focusBorder.borderSide.color, ZyraColors.splashWordmark);
    expect(field.autofillHints, contains(AutofillHints.givenName));
    expect(field.keyboardType, TextInputType.name);
    expect(field.textCapitalization, TextCapitalization.words);
    expect(field.textInputAction, TextInputAction.done);
    expect(
      tester
          .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
          .frameContent,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('last-name input has its own key and family-name autofill', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: _question(controller: controller, lastName: true)),
    );
    final field = tester.widget<TextField>(find.byKey(_lastNameFieldKey));
    expect(find.byKey(_fieldKey), findsNothing);
    expect(field.controller, same(controller));
    expect(field.decoration?.hintText, 'Last name');
    expect(field.autofillHints, contains(AutofillHints.familyName));
    expect(field.textAlign, TextAlign.center);
    expect(field.style?.fontFamily, 'Poppins');
    expect(field.decoration?.filled, isNot(true));
    await tester.enterText(find.byKey(_lastNameFieldKey), 'Al-Rahman');
    expect(controller.text, 'Al-Rahman');
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing reports the raw given name without changing the value', (
    tester,
  ) async {
    final changes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: _question(controller: controller, onChanged: changes.add),
      ),
    );
    const name = '  Āmina O’Neill  ';
    await tester.enterText(find.byKey(_fieldKey), name);
    expect(controller.text, name);
    expect(changes, [name]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty name remains empty and validation belongs to the flow', (
    tester,
  ) async {
    final changes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: _question(controller: controller, onChanged: changes.add),
      ),
    );
    expect(controller.text, isEmpty);
    await tester.enterText(find.byKey(_fieldKey), 'Amina');
    await tester.enterText(find.byKey(_fieldKey), '');
    expect(controller.text, isEmpty);
    expect(changes.last, isEmpty);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard Done dismisses focus without advancing the page', (
    tester,
  ) async {
    var advances = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: _question(controller: controller, onContinue: () => advances++),
      ),
    );
    await tester.tap(find.byKey(_fieldKey));
    await tester.enterText(find.byKey(_fieldKey), 'Shakeel');
    await tester.pump();
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(editable.focusNode.hasFocus, isFalse);
    expect(advances, 0);
    expect(controller.text, 'Shakeel');
    expect(find.byKey(_fieldKey), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding_continue')));
    expect(advances, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact enlarged name input stays usable with the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: _question(controller: controller),
      ),
    );
    await tester.ensureVisible(find.byKey(_fieldKey));
    await tester.tap(find.byKey(_fieldKey));
    await tester.enterText(find.byKey(_fieldKey), 'Amina');
    await tester.pump();
    expect(controller.text, 'Amina');
    expect(tester.takeException(), isNull);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    final action = tester.getRect(
      find.byKey(const ValueKey('onboarding_continue')),
    );
    expect(action.top, greaterThanOrEqualTo(0));
    expect(action.bottom, lessThanOrEqualTo(568 - 240));
    expect(action.left, greaterThanOrEqualTo(0));
    expect(action.right, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  for (final role in ZyraSignupRole.values) {
    testWidgets('${role.name} requires both public names before advancing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: role == ZyraSignupRole.seeker
              ? const OnboardingFlow(
                  signupUserId: 'account-a',
                  initialDraft: ZyraInitialSignupDraft(
                    role: ZyraSignupRole.seeker,
                  ),
                )
              : const WaliOnboardingFlow(
                  signupUserId: 'account-a',
                  initialDraft: ZyraInitialSignupDraft(
                    role: ZyraSignupRole.guardian,
                  ),
                ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ZyraOnboardingNameField), findsNWidgets(2));
      expect(find.byKey(_fieldKey), findsOneWidget);
      expect(find.byKey(_lastNameFieldKey), findsOneWidget);
      expect(find.text("What's your name?"), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data?.toLowerCase().contains('public') ?? false),
        ),
        findsWidgets,
      );
      expect(
        tester
            .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
            .frameContent,
        isFalse,
      );
      expect(
        tester
            .widget<ZyraOnboardingArrowAction>(
              find.byType(ZyraOnboardingArrowAction),
            )
            .active,
        isFalse,
      );
      await tester.enterText(find.byKey(_fieldKey), '   ');
      await tester.pump();
      expect(
        tester
            .widget<ZyraOnboardingArrowAction>(
              find.byType(ZyraOnboardingArrowAction),
            )
            .active,
        isFalse,
      );
      await tester.enterText(find.byKey(_fieldKey), 'Amina');
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byKey(_fieldKey)).textInputAction,
        TextInputAction.next,
      );
      expect(
        tester
            .widget<ZyraOnboardingArrowAction>(
              find.byType(ZyraOnboardingArrowAction),
            )
            .active,
        isFalse,
      );
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(_lastNameFieldKey),
                matching: find.byType(EditableText),
              ),
            )
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(find.byType(ZyraOnboardingNameField), findsNWidgets(2));
      await tester.enterText(find.byKey(_lastNameFieldKey), '   ');
      await tester.pump();
      expect(
        tester
            .widget<ZyraOnboardingArrowAction>(
              find.byType(ZyraOnboardingArrowAction),
            )
            .active,
        isFalse,
      );
      await tester.enterText(find.byKey(_lastNameFieldKey), 'Ahmed');
      await tester.pump();
      expect(
        tester
            .widget<ZyraOnboardingArrowAction>(
              find.byType(ZyraOnboardingArrowAction),
            )
            .active,
        isTrue,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.byType(ZyraOnboardingNameField), findsNWidgets(2));
      final totalQuestions = role == ZyraSignupRole.seeker ? 4 : 5;
      expect(find.text('QUESTION 1 OF $totalQuestions'), findsOneWidget);
      final actionKey = ValueKey(
        role == ZyraSignupRole.seeker
            ? 'onboarding_continue'
            : 'wali_onboarding_continue',
      );
      await tester.tap(find.byKey(actionKey));
      await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.byType(ZyraOnboardingNameField), findsNothing);
      expect(find.text('QUESTION 2 OF $totalQuestions'), findsOneWidget);
      if (role == ZyraSignupRole.seeker) {
        expect(find.text("What's your gender?"), findsOneWidget);
        expect(find.text('Male'), findsOneWidget);
        expect(find.text('Female'), findsOneWidget);
      }
      final saved = await tester.runAsync(() => repository.read('account-a'));
      expect(saved?.firstName, 'Amina');
      expect(saved?.lastName, 'Ahmed');
      expect(tester.takeException(), isNull);
    });
  }
}
