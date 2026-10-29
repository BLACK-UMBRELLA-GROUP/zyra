import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_role_choice_design.dart';
import 'package:zyra/dev/zyra_dev_page_options.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/dev/zyra_global_dev_overlay.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';

Widget _panel(ValueNotifier<int> openRequests) => MaterialApp(
  home: Scaffold(
    body: Stack(
      children: [
        ZyraEntryDevPanel(pageLabel: 'Onboarding', openRequests: openRequests),
      ],
    ),
  ),
);

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraDevRoleChoiceDesign.resetForTesting();
  });

  tearDown(() {
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
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

  test('mounted route must be current for any role-design selection', () {
    final coordinator = ZyraDevSurfaceCoordinator.instance;
    final owner = Object();
    var current = true;
    coordinator.attachRoleChoice(owner, isCurrent: () => current);
    expect(coordinator.activeRoleChoiceOwner, same(owner));
    expect(
      coordinator.selectRoleChoiceDesign(
        owner,
        ZyraRoleChoiceDesign.guidedPaths,
      ),
      isTrue,
    );
    expect(ZyraDevRoleChoiceDesign.current, ZyraRoleChoiceDesign.guidedPaths);

    current = false;
    expect(coordinator.activeRoleChoiceOwner, isNull);
    expect(
      coordinator.selectRoleChoiceDesign(
        owner,
        ZyraRoleChoiceDesign.guidedPaths,
      ),
      isFalse,
    );
    coordinator.detachRoleChoice(owner);
    expect(coordinator.activeRoleChoiceOwner, isNull);
    expect(ZyraDevRoleChoiceDesign.current, ZyraRoleChoiceDesign.guidedPaths);
  });

  testWidgets(
    'entry Actions exposes chosen Guided Paths only on role-choice route',
    (tester) async {
      final openRequests = ValueNotifier<int>(0);
      await tester.pumpWidget(_panel(openRequests));
      openRequests.value++;
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('dev_page_options_group_Role choice design')),
        findsNothing,
      );

      final coordinator = ZyraDevSurfaceCoordinator.instance;
      final owner = Object();
      var current = true;
      coordinator.attachRoleChoice(owner, isCurrent: () => current);
      await tester.pumpWidget(_panel(openRequests));
      await tester.pumpAndSettle();

      final pageOptions = tester.widget<ZyraDevPageOptions>(
        find.byType(ZyraDevPageOptions),
      );
      final designs = pageOptions.options
          .where((option) => option.group == 'Role choice design')
          .toList();
      expect(designs, hasLength(1));
      expect(
        designs.map((option) => option.id),
        ZyraRoleChoiceDesign.values.map(
          (design) => 'dev_role_choice_${design.name}',
        ),
      );
      expect(
        designs.singleWhere((option) => option.selected).label,
        '2 · Guided paths',
      );
      expect(
        find.byKey(const ValueKey('dev_page_options_group_Role choice design')),
        findsOneWidget,
      );

      designs
          .singleWhere((option) => option.id == 'dev_role_choice_guidedPaths')
          .onSelected!();
      expect(ZyraDevRoleChoiceDesign.current, ZyraRoleChoiceDesign.guidedPaths);

      final staleSelection = designs
          .singleWhere((option) => option.id == 'dev_role_choice_guidedPaths')
          .onSelected!;
      current = false;
      expect(() => staleSelection(), throwsStateError);
      expect(ZyraDevRoleChoiceDesign.current, ZyraRoleChoiceDesign.guidedPaths);
      coordinator.detachRoleChoice(owner);
      await tester.pumpWidget(_panel(openRequests));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('dev_page_options_group_Role choice design')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      openRequests.dispose();
    },
  );
}
