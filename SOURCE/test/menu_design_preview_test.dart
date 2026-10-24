import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_menu_directions.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/state/app_state.dart';
import 'package:zyra/theme/zyra_colors.dart';
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
const _guardian = [
  FloatingNavItem(
    icon: Icons.dashboard_outlined,
    label: 'Dashboard',
    badge: 12,
  ),
  FloatingNavItem(
    icon: Icons.diversity_3_outlined,
    label: 'Network',
    dimmed: true,
  ),
  FloatingNavItem(icon: Icons.people_outline, label: 'Seekers'),
  FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
];

bool _choose(ZyraMenuDesign value) => ZyraDevMenuDesign.instance.select(
  value,
  expectedGeneration: ZyraAccountState.generation,
  expectedRevision: ZyraDevMenuDesign.instance.revision,
);

Widget _app({
  List<FloatingNavItem> items = _seeker,
  ValueChanged<int>? onTap,
  double scale = 1,
  bool forceCurrent = false,
  bool reduce = false,
  EdgeInsets insets = EdgeInsets.zero,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(scale),
      padding: const EdgeInsets.only(top: 44, bottom: 34),
      viewInsets: insets,
      disableAnimations: reduce,
    ),
    child: child!,
  ),
  home: Scaffold(
    body: Stack(
      children: [
        ZyraMenuCanvas(
          child: const SizedBox.expand(key: ValueKey('menu-canvas')),
        ),
        ZyraShellNavigation(
          items: items,
          currentIndex: items.length == 5 ? 2 : 0,
          onTap: onTap ?? (_) {},
          forceCurrent: forceCurrent,
        ),
      ],
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevMenuDesign.instance.resetForTesting();
  });
  tearDown(() {
    ZyraDevMenuDesign.instance.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
  });

  test('current default and exactly eight requested comparisons', () {
    expect(ZyraDevMenuDesign.instance.effectiveDesign, ZyraMenuDesign.current);
    expect(ZyraMenuDesign.values.map((value) => value.label), [
      'Current · Floating menu',
      'Grid',
      'Side Menu',
      'Tab Bar',
      'FAB',
      'Sheet',
      'Three Dots',
      'Rectangular',
      'Rudder',
    ]);
  });

  test(
    'ordinary accounts cannot select; stale selection and revival denied',
    () {
      final state = ZyraDevMenuDesign.instance;
      final generation = ZyraAccountState.generation;
      final revision = state.revision;
      expect(_choose(ZyraMenuDesign.fab), isTrue);
      expect(
        state.select(
          ZyraMenuDesign.grid,
          expectedGeneration: generation,
          expectedRevision: revision,
        ),
        isFalse,
      );
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      expect(state.effectiveDesign, ZyraMenuDesign.current);
      expect(_choose(ZyraMenuDesign.grid), isFalse);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      expect(state.effectiveDesign, ZyraMenuDesign.current);
      ZyraAccountState.resetForTesting();
      expect(
        state.select(
          ZyraMenuDesign.grid,
          expectedGeneration: generation,
          expectedRevision: state.revision,
        ),
        isFalse,
      );
    },
  );

  test('same selection is silent; account reset clears preview', () {
    final state = ZyraDevMenuDesign.instance;
    var notifications = 0;
    void changed() => notifications++;
    state.addListener(changed);
    expect(_choose(ZyraMenuDesign.rectangular), isTrue);
    expect(_choose(ZyraMenuDesign.rectangular), isTrue);
    expect(notifications, 1);
    ZyraAccountState.resetForTesting();
    AppState.instance.resetForAccountChange();
    expect(state.effectiveDesign, ZyraMenuDesign.current);
    expect(notifications, 2);
    state.removeListener(changed);
  });

  testWidgets('default and Browse safety actions retain canonical bar', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    expect(find.byType(FloatingNavBar), findsOneWidget);
    _choose(ZyraMenuDesign.fab);
    await tester.pumpWidget(_app(forceCurrent: true));
    expect(find.byType(FloatingNavBar), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-open')), findsNothing);
  });

  for (final role in [_seeker, _guardian]) {
    for (final design in ZyraMenuDesign.values.skip(1)) {
      testWidgets(
        '${role == _seeker ? 'Seeker' : 'Guardian'} ${design.label} routes every destination',
        (tester) async {
          _choose(design);
          final calls = <int>[];
          await tester.pumpWidget(_app(items: role, onTap: calls.add));
          for (var i = 0; i < role.length; i++) {
            if (design.opensMenu) {
              await tester.tap(find.byKey(const ValueKey('menu-open')));
              await tester.pumpAndSettle();
            }
            if (i == 0 && role == _guardian) {
              expect(find.byKey(const ValueKey('menu-badge-0')), findsNothing);
              final glyph = find.descendant(
                of: find.byKey(const ValueKey('menu-destination-0')),
                matching: find.byIcon(role.first.icon),
              );
              expect(glyph, findsOneWidget);
              expect(
                tester.widget<Icon>(glyph).color,
                design == ZyraMenuDesign.rudder || design == ZyraMenuDesign.fab
                    ? const Color(0xFF62460E)
                    : ZyraColors.journeyGold,
              );
            }
            final destination = find.byKey(ValueKey('menu-destination-$i'));
            await tester.ensureVisible(destination);
            await tester.tap(destination);
            await tester.pumpAndSettle();
            expect(calls, List.generate(i + 1, (index) => index));
            if (design.opensMenu) expect(find.text('Go to'), findsNothing);
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  for (final design in ZyraMenuDesign.values.where(
    (value) => value.opensMenu,
  )) {
    testWidgets(
      '${design.label} outside/back and authority dismissal are safe',
      (tester) async {
        _choose(design);
        final calls = <int>[];
        await tester.pumpWidget(_app(onTap: calls.add));
        await tester.tap(find.byKey(const ValueKey('menu-open')));
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Go to'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('menu-open')));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(790, 50));
        await tester.pumpAndSettle();
        expect(find.text('Go to'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('menu-open')));
        await tester.pumpAndSettle();
        ZyraDeveloperAccess.setAuthorizedForTesting(false);
        await tester.pumpAndSettle();
        expect(find.text('Go to'), findsNothing);
        expect(find.byType(FloatingNavBar), findsOneWidget);
        expect(calls, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('style switch and account change close owned menu', (
    tester,
  ) async {
    _choose(ZyraMenuDesign.sheet);
    await tester.pumpWidget(_app());
    await tester.tap(find.byKey(const ValueKey('menu-open')));
    await tester.pumpAndSettle();
    _choose(ZyraMenuDesign.rectangular);
    await tester.pumpAndSettle();
    expect(find.text('Go to'), findsNothing);
    _choose(ZyraMenuDesign.grid);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-open')));
    await tester.pumpAndSettle();
    ZyraAccountState.resetForTesting();
    AppState.instance.resetForAccountChange();
    await tester.pumpAndSettle();
    expect(find.text('Go to'), findsNothing);
    expect(find.byType(FloatingNavBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Rectangular reserves canvas space without touching current default',
    (tester) async {
      await tester.pumpWidget(_app());
      final original = tester.getRect(
        find.byKey(const ValueKey('menu-canvas')),
      );
      _choose(ZyraMenuDesign.rectangular);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const ValueKey('menu-canvas'))).left,
        original.left + 76,
      );
      _choose(ZyraMenuDesign.current);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const ValueKey('menu-canvas'))),
        original,
      );
    },
  );

  for (final design in ZyraMenuDesign.values.skip(1)) {
    for (final scale in [1.0, 1.4, 2.0]) {
      testWidgets(
        '${design.label} compact phone at ${(scale * 100).round()}% text',
        (tester) async {
          tester.view.physicalSize = const Size(320, 568);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          _choose(design);
          await tester.pumpWidget(_app(scale: scale, reduce: true));
          if (design.opensMenu) {
            await tester.tap(find.byKey(const ValueKey('menu-open')));
            await tester.pumpAndSettle();
            await tester.ensureVisible(
              find.byKey(const ValueKey('menu-destination-4')),
            );
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

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
    expect(find.byType(DevMenuDirectionPicker), findsNothing);
    expect(
      find.byKey(const ValueKey('dev_home_section_discovery_direction')),
      findsOneWidget,
    );
    for (final design in ZyraMenuDesign.values) {
      expect(
        find.byKey(ValueKey('dev_menu_design_${design.name}')),
        findsNothing,
      );
    }
    expect(ZyraDevMenuDesign.instance.effectiveDesign, ZyraMenuDesign.current);
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    expect(ZyraDevMenuDesign.instance.effectiveDesign, ZyraMenuDesign.current);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dev_menu_design_fab')), findsNothing);
  });

  testWidgets('disabled picker refuses selection', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DevMenuDirectionPicker(enabled: false),
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<InkWell>(find.byKey(const ValueKey('dev_menu_design_fab')))
          .onTap,
      isNull,
    );
    expect(ZyraDevMenuDesign.instance.effectiveDesign, ZyraMenuDesign.current);
  });

  testWidgets('retained modal and rail callbacks cannot outlive authority', (
    tester,
  ) async {
    final calls = <int>[];
    _choose(ZyraMenuDesign.grid);
    await tester.pumpWidget(_app(onTap: calls.add));
    await tester.tap(find.byKey(const ValueKey('menu-open')));
    await tester.pumpAndSettle();
    final modalTap = tester
        .widget<InkWell>(find.byKey(const ValueKey('menu-destination-1')))
        .onTap!;
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    modalTap();
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    _choose(ZyraMenuDesign.rectangular);
    await tester.pumpAndSettle();
    final railTap = tester
        .widget<InkWell>(find.byKey(const ValueKey('menu-destination-1')))
        .onTap!;
    ZyraAccountState.resetForTesting();
    AppState.instance.resetForAccountChange();
    railTap();
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final design in ZyraMenuDesign.values.where(
    (value) => value.opensMenu,
  )) {
    testWidgets(
      '${design.label} keyboard insets and 200% text stay reachable',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        _choose(design);
        final calls = <int>[];
        await tester.pumpWidget(
          _app(
            scale: 2,
            onTap: calls.add,
            insets: const EdgeInsets.only(bottom: 250),
            reduce: true,
          ),
        );
        await tester.tap(find.byKey(const ValueKey('menu-open')));
        await tester.pumpAndSettle();
        final target = find.byKey(const ValueKey('menu-destination-4'));
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(calls, [4]);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
