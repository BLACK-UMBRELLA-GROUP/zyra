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

  test('design choice is protected and resets across account generations', () {
    expect(ZyraDevRoleChoiceDesign.current, ZyraRoleChoiceDesign.guidedPaths);
    expect(
      ZyraDevRoleChoiceDesign.select(ZyraRoleChoiceDesign.editorial),
      isTrue,
    );
    expect(ZyraDevRoleChoiceDesign.current, ZyraRoleChoiceDesign.editorial);

    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    expect(
      ZyraDevRoleChoiceDesign.select(ZyraRoleChoiceDesign.spotlight),
      isFalse,
    );
    expect(ZyraDevRoleChoiceDesign.current, ZyraRoleChoiceDesign.editorial);

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
      coordinator.selectRoleChoiceDesign(owner, ZyraRoleChoiceDesign.spotlight),
      isTrue,
    );
    expect(ZyraDevRoleChoiceDesign.current, ZyraRoleChoiceDesign.spotlight);

    current = false;
    expect(coordinator.activeRoleChoiceOwner, isNull);
    expect(
      coordinator.selectRoleChoiceDesign(owner, ZyraRoleChoiceDesign.editorial),
      isFalse,
    );
    coordinator.detachRoleChoice(owner);
    expect(coordinator.activeRoleChoiceOwner, isNull);
    expect(ZyraDevRoleChoiceDesign.current, ZyraRoleChoiceDesign.spotlight);
  });

  testWidgets('entry Actions exposes six choices only on role-choice route', (
    tester,
  ) async {
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
    expect(designs, hasLength(6));
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
        .singleWhere((option) => option.id == 'dev_role_choice_editorial')
        .onSelected!();
    expect(ZyraDevRoleChoiceDesign.current, ZyraRoleChoiceDesign.editorial);

    final staleSelection = designs
        .singleWhere((option) => option.id == 'dev_role_choice_spotlight')
        .onSelected!;
    current = false;
    expect(() => staleSelection(), throwsStateError);
    expect(ZyraDevRoleChoiceDesign.current, ZyraRoleChoiceDesign.editorial);
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
  });
}
