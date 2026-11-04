import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_initial_signup_draft.dart';
import 'package:zyra/screens/onboarding/onboarding_flow.dart';
import 'package:zyra/screens/wali/wali_onboarding_flow.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_initial_signup_draft_service.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/onboarding_scaffold.dart';

import 'initial_signup_draft_test.dart' show FakeSignupStore;
import 'support/queue44_signup_flow_driver.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';

const _ownerId = 'dob-test-owner';

void main() {
  late FakeSignupStore store;
  String? owner;

  setUp(() {
    store = FakeSignupStore();
    owner = _ownerId;
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraInitialSignupDraftService.setRepositoryForTesting(
      ZyraSignupDraftRepository(
        store: store,
        backend: 'https://example.invalid',
        currentUserId: () => owner,
        isPreview: () => false,
      ),
    );
    ZyraText.useTestFontStubs = true;
  });

  tearDown(() {
    ZyraInitialSignupDraftService.setRepositoryForTesting(null);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraAccountState.resetForTesting();
    ZyraText.useTestFontStubs = false;
  });

  String dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<ValueNotifier<bool>> showDob(
    WidgetTester tester,
    ZyraSignupRole role, {
    DateTime? selected,
    bool preview = false,
  }) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final showing = ValueNotifier(true);
    addTearDown(showing.dispose);
    final draft = ZyraInitialSignupDraft(
      role: role,
      step: role == ZyraSignupRole.seeker ? 2 : 1,
      firstName: 'Test',
      lastName: 'Ahmed',
      gender: role == ZyraSignupRole.seeker ? 'male' : null,
      dob: selected,
    );
    final flow = role == ZyraSignupRole.seeker
        ? OnboardingFlow(
            devPreview: preview,
            signupUserId: preview ? null : _ownerId,
            initialDraft: preview ? null : draft,
          )
        : WaliOnboardingFlow(
            devPreview: preview,
            signupUserId: preview ? null : _ownerId,
            initialDraft: preview ? null : draft,
          );
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: showing,
          builder: (_, present, _) => present
              ? flow
              : const Scaffold(body: Text('Replacement owner route')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (preview) {
      if (role == ZyraSignupRole.seeker) {
        tester
            .widget<OnboardingStageIntroScreen>(
              find.byType(OnboardingStageIntroScreen),
            )
            .onContinue();
        await tester.pumpAndSettle();
      }
      for (var step = 0; step < draft.step; step++) {
        await advanceSignupQuestionFromCode(tester, installPhotoFixture: false);
      }
    }
    expect(find.text('When were you born?'), findsOneWidget);
    expect(tester.takeException(), isNull);
    return showing;
  }

  Future<void> openDob(WidgetTester tester, {DateTime? selected}) async {
    final label = find.text(
      selected == null ? 'Select date of birth' : dateLabel(selected),
    );
    await tester.ensureVisible(label);
    await tester.tap(label);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
  }

  Future<void> acceptDob(WidgetTester tester) async {
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
  }

  for (final role in ZyraSignupRole.values) {
    testWidgets('${role.name} older recovery keeps picker bounds and answer', (
      tester,
    ) async {
      final selected = DateTime(1901, 5, 17);
      await showDob(tester, role, selected: selected);
      await openDob(tester, selected: selected);
      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.firstDate, DateTime(DateTime.now().year - 100));
      expect(picker.initialDate, picker.firstDate);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text(dateLabel(selected)), findsOneWidget);
      expect(store.operations, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${role.name} DOB dialog restores the saved selection', (
      tester,
    ) async {
      final selected = DateTime(1991, 5, 17);
      await showDob(tester, role, selected: selected);
      await openDob(tester, selected: selected);
      expect(
        tester
            .widget<DatePickerDialog>(find.byType(DatePickerDialog))
            .initialDate,
        selected,
      );
      await acceptDob(tester);
      expect(find.text(dateLabel(selected)), findsOneWidget);
      expect(store.operations, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${role.name} DOB result is ignored after its form disposal', (
      tester,
    ) async {
      final showing = await showDob(tester, role);
      await openDob(tester);
      showing.value = false;
      await tester.pump();
      expect(find.text('Replacement owner route'), findsOneWidget);
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await acceptDob(tester);
      expect(find.text('Replacement owner route'), findsOneWidget);
      expect(store.operations, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${role.name} DOB result cannot mutate a replacement account', (
      tester,
    ) async {
      await showDob(tester, role);
      await openDob(tester);
      owner = 'replacement-account';
      await acceptDob(tester);
      expect(find.text('Select date of birth'), findsOneWidget);
      expect(
        tester
            .widget<OnboardingScaffold>(find.byType(OnboardingScaffold))
            .fabActive,
        isFalse,
      );
      expect(store.operations, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '${role.name} DOB result cannot mutate a replaced same-ID epoch',
      (tester) async {
        await showDob(tester, role);
        await openDob(tester);
        ZyraAccountState.resetForTesting();
        await acceptDob(tester);
        expect(find.text('Select date of birth'), findsOneWidget);
        expect(store.operations, 0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('${role.name} DOB result is denied after preview revocation', (
      tester,
    ) async {
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await showDob(tester, role, preview: true);
      await openDob(tester);
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pump();
      await acceptDob(tester);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      await tester.pumpAndSettle();
      expect(find.text('Select date of birth'), findsOneWidget);
      expect(store.operations, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
