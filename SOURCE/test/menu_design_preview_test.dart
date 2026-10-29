import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

const _seeker = [
  FloatingNavItem(icon: Icons.search, label: 'Browse'),
  FloatingNavItem(icon: Icons.bookmark_border, label: 'Connections', dot: true),
  FloatingNavItem(icon: Icons.dashboard_outlined, label: 'My ZYRA', badge: 12),
  FloatingNavItem(icon: Icons.gpp_good_outlined, label: 'Guardian'),
  FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
];
Widget _app() => MaterialApp(
  home: Scaffold(
    body: Stack(
      children: [
        ZyraShellNavigation(items: _seeker, currentIndex: 2, onTap: (_) {}),
      ],
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
  });
  tearDown(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('default and Browse safety actions retain canonical bar', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    expect(find.byType(FloatingNavBar), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-open')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home omits menu comparisons and keeps the canonical default', (
    tester,
  ) async {
    final home = ZyraDevHomeTools(
      busy: false,
      onHome: () {},
      onRestart: () {},
      onReset: () {},
      onAccounts: () {},
      onSeekerSignUp: () {},
      onGuardianSignUp: () {},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: home)),
      ),
    );
    expect(
      find.byKey(const ValueKey('dev_home_section_mobile_menu')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('dev_home_section_discovery_direction')),
      findsOneWidget,
    );
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dev_menu_design_fab')), findsNothing);
  });
}
