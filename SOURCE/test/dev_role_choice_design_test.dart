import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/screens/auth/role_selection_screen.dart';
import 'package:zyra/widgets/zyra_onboarding_continue_action.dart';
import 'support/queue44_role_choice_fixture.dart';

Future<void> _rolePage(
  WidgetTester tester,
  GlobalKey<NavigatorState> navigator,
) async {
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: const RoleSelectionScreen(devPreview: true),
    ),
  );
  await tester.pumpAndSettle();
}

VoidCallback _seekerChoice(WidgetTester tester) => tester
    .widget<InkWell>(find.byKey(const ValueKey('role-select-seeker')))
    .onTap!;

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevRoleChoiceDesign.resetForTesting();
  });

  tearDown(() {
    ZyraDevRoleChoiceDesign.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
  });

  test('chosen Guided Paths is protected across account generations', () {
    expect(ZyraDevRoleChoiceDesign.current, ZyraRoleChoiceDesign.guidedPaths);
    expect(
      ZyraDevRoleChoiceDesign.select(ZyraRoleChoiceDesign.guidedPaths),
      isTrue,
    );
    expect(ZyraDevRoleChoiceDesign.current, ZyraRoleChoiceDesign.guidedPaths);

    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    expect(
      ZyraDevRoleChoiceDesign.select(ZyraRoleChoiceDesign.guidedPaths),
      isFalse,
    );
    expect(ZyraDevRoleChoiceDesign.current, ZyraRoleChoiceDesign.guidedPaths);

    ZyraAccountState.resetForTesting();
    expect(ZyraDevRoleChoiceDesign.current, ZyraRoleChoiceDesign.guidedPaths);
  });

  testWidgets('member role choice rejects covered and revoked callbacks', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await _rolePage(tester, navigator);
    final choose = _seekerChoice(tester);
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Covered')),
      ),
    );
    await tester.pumpAndSettle();
    choose();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('role-choice-no-continue')),
      findsOneWidget,
    );
    choose();
    await tester.pumpAndSettle();
    final advance = tester
        .widget<ZyraOnboardingArrowAction>(
          find.byKey(const ValueKey('role-choice-continue')),
        )
        .onPressed!;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpAndSettle();
    choose();
    advance();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('role_preview_denied')), findsOneWidget);
    expect(navigator.currentState!.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chosen Guided Paths member role page has no design picker', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await _rolePage(tester, navigator);
    expect(
      find.byKey(const ValueKey('dev_page_options_group_Role choice design')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('role-select-seeker')), findsOneWidget);
    expect(find.byKey(const ValueKey('role-select-guardian')), findsOneWidget);
    _seekerChoice(tester)();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ZyraOnboardingArrowAction>(
            find.byKey(const ValueKey('role-choice-continue')),
          )
          .active,
      isTrue,
    );
    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
