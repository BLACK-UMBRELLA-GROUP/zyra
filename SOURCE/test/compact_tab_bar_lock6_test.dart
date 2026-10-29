// LOCK 6: actual floating navigation geometry and owned pointer lifetimes.
// Fixtures have no account, service, subscription, or notification authority.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_journey_icon.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

const _seekerItems = [
  FloatingNavItem(icon: Icons.search, label: 'Profiles'),
  FloatingNavItem(
    icon: Icons.route_outlined,
    label: 'Journey',
    useJourneyGlyph: true,
  ),
  FloatingNavItem(icon: Icons.dashboard_outlined, label: 'My ZYRA'),
  FloatingNavItem(icon: Icons.gpp_good_outlined, label: 'Guardian'),
  FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
];
const _guardianItems = [
  FloatingNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
  FloatingNavItem(icon: Icons.diversity_3_outlined, label: 'Network'),
  FloatingNavItem(icon: Icons.people_outline, label: 'Seekers'),
  FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
];

Finder get _surface => find.byKey(const ValueKey('compact-nav-surface'));
Finder get _underline => find.byKey(const ValueKey('compact-nav-underline'));
Finder _cell(int index) => find.byKey(ValueKey('floating-nav-item-$index'));

class _Offline extends HttpOverrides {
  int attempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Tab-bar fixtures must stay offline.');
  }
}

class _Fixture extends ChangeNotifier {
  _Fixture({this.guardian = false, this.compact = true});

  bool guardian;
  bool compact;
  bool enabled = true;
  bool commitOnRelease = false;
  bool reducedMotion = true;
  bool? accessibleNavigation;
  double textScale = 1;
  int selected = 0;
  int collapseRevision = 0;
  bool newActivity = true;
  final selections = <int>[];

  List<FloatingNavItem> get items => [
    for (final (index, item)
        in (guardian ? _guardianItems : _seekerItems).indexed)
      FloatingNavItem(
        icon: item.icon,
        label: item.label,
        useJourneyGlyph: item.useJourneyGlyph,
        dot: !guardian && index == 2 && newActivity,
      ),
  ];

  void change(VoidCallback update) {
    update();
    notifyListeners();
  }

  void select(int index) => change(() {
    selections.add(index);
    selected = index;
    if (!guardian && index == 2) newActivity = false;
  });
}

Future<void> _mount(WidgetTester tester, _Fixture fixture) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    fixture.dispose();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: AnimatedBuilder(
        animation: fixture,
        builder: (context, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.only(top: 59, bottom: 34),
            viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
            accessibleNavigation: fixture.accessibleNavigation,
            disableAnimations: fixture.reducedMotion,
            textScaler: TextScaler.linear(fixture.textScale),
          ),
          child: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Colors.black),
                ZyraShellNavigation(
                  items: fixture.items,
                  currentIndex: fixture.selected,
                  onTap: fixture.select,
                  contentEdgeInset: 20,
                  hapticLevel: ZyraHapticLevel.off,
                  commitOnRelease: fixture.commitOnRelease,
                  compactWhenIdle: fixture.compact,
                  collapseRevision: fixture.collapseRevision,
                  interactionEnabled: fixture.enabled,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}

void _expectSize(WidgetTester tester, Size expected) {
  expect(_surface, findsOneWidget);
  final size = tester.getSize(_surface);
  expect(size.width, closeTo(expected.width, .001));
  expect(size.height, closeTo(expected.height, .001));
  expect(tester.getCenter(_surface).dx, closeTo(215, .001));
}

Future<void> _expand(WidgetTester tester) async {
  final finger = await tester.startGesture(tester.getCenter(_surface));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  _expectSize(tester, const Size(390, 58));
  await finger.up();
  await tester.pump();
}

Widget _icon(WidgetTester tester, int index) => tester.widget(
  find.descendant(
    of: _cell(index),
    matching: find.byWidgetPredicate(
      (widget) => widget is Icon || widget is ZyraJourneyIcon,
    ),
  ),
);

Color? _iconColor(WidgetTester tester, int index) {
  final icon = _icon(tester, index);
  return icon is Icon ? icon.color : (icon as ZyraJourneyIcon).color;
}

double? _iconSize(WidgetTester tester, int index) {
  final icon = _icon(tester, index);
  return icon is Icon ? icon.size : (icon as ZyraJourneyIcon).size;
}

void _expectSelection(WidgetTester tester, int index) {
  expect(tester.widget<Semantics>(_cell(index)).properties.selected, isTrue);
  final rect = tester.getRect(_underline);
  final icon = find.descendant(
    of: _cell(index),
    matching: find.byWidgetPredicate(
      (widget) => widget is Icon || widget is ZyraJourneyIcon,
    ),
  );
  expect(rect.center.dx, closeTo(tester.getCenter(icon).dx, .001));
  expect(rect.top - tester.getRect(icon).bottom, closeTo(3, .001));
  expect(rect.height, closeTo(2.5, .001));
  expect(find.byType(ZyraNavHighlight), findsNothing);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousHttp;
  late _Offline offline;

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraInteractionStyle.restoreDefaults();
    previousHttp = HttpOverrides.current;
    offline = _Offline();
    HttpOverrides.global = offline;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    expect(offline.attempts, 0);
    HttpOverrides.global = previousHttp;
    ZyraInteractionStyle.restoreDefaults();
    ZyraText.useTestFontStubs = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final guardian in [false, true]) {
    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} has locked idle/full geometry',
      (tester) async {
        final fixture = _Fixture(guardian: guardian);
        await _mount(tester, fixture);
        _expectSize(tester, const Size(156, 46));
        expect(fixture.items.length, guardian ? 4 : 5);
        expect(tester.getSize(_underline).width, closeTo(16, .001));
        _expectSelection(tester, 0);
        for (var index = 0; index < fixture.items.length; index++) {
          expect(_iconSize(tester, index), 16);
        }
        await _expand(tester);
        expect(fixture.selections, isEmpty);
        expect(tester.getSize(_underline).width, closeTo(24, .001));
        _expectSelection(tester, 0);
        for (var index = 0; index < fixture.items.length; index++) {
          expect(_iconSize(tester, index), 21);
          expect(tester.getSize(_cell(index)).width, greaterThanOrEqualTo(44));
          expect(tester.getSize(_cell(index)).height, greaterThanOrEqualTo(44));
        }
        expect(_iconColor(tester, 0), ZyraColors.foreground);
        final last = fixture.items.length - 1;
        await tester.tapAt(tester.getCenter(_cell(last)));
        await tester.pump();
        expect(fixture.selections, [last]);
        _expectSelection(tester, last);
        await tester.pump(const Duration(seconds: 3));
        _expectSize(tester, const Size(156, 46));
        _expectSelection(tester, last);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'a narrow phone retains the 40 percent idle bar without overflow',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      tester.view.physicalSize = const Size(320, 568);
      await tester.pumpAndSettle();
      expect(tester.getSize(_surface), const Size(112, 46));
      expect(tester.getCenter(_surface).dx, 160);
      for (var i = 0; i < fixture.items.length; i++) {
        final cell = tester.getRect(_cell(i));
        expect(cell.left, greaterThanOrEqualTo(tester.getRect(_surface).left));
        expect(cell.right, lessThanOrEqualTo(tester.getRect(_surface).right));
      }
      await tester.tapAt(tester.getCenter(_surface));
      await tester.pumpAndSettle();
      expect(tester.getSize(_surface), const Size(280, 58));
      expect(fixture.selections, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the complete first idle gesture expands without choosing any tab',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      final idle = tester.getRect(_surface);
      final finger = await tester.startGesture(
        Offset(idle.right - 8, idle.center.dy),
      );
      await tester.pump(const Duration(milliseconds: 350));
      _expectSize(tester, const Size(390, 58));
      await finger.moveTo(tester.getCenter(_cell(1)));
      await tester.pump();
      await finger.moveTo(tester.getCenter(_cell(4)));
      await tester.pump();
      expect(fixture.selections, isEmpty);
      _expectSelection(tester, 0);
      await finger.up();
      await tester.pump();
      expect(fixture.selections, isEmpty);
      await tester.tapAt(tester.getCenter(_cell(3)));
      await tester.pump();
      expect(fixture.selections, [3]);
    },
  );

  testWidgets(
    'cancelling the expand-only gesture never selects a destination',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      final finger = await tester.startGesture(tester.getCenter(_surface));
      await tester.pump(const Duration(milliseconds: 350));
      await finger.moveTo(tester.getCenter(_cell(3)));
      await tester.pump();
      await finger.cancel();
      await tester.pump();
      expect(fixture.selections, isEmpty);
      _expectSelection(tester, 0);
      await tester.pump(const Duration(seconds: 3));
      _expectSize(tester, const Size(156, 46));
    },
  );

  testWidgets('a full-bar tap dispatches its exact destination once', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _mount(tester, fixture);
    await _expand(tester);
    await tester.tapAt(tester.getCenter(_cell(1)));
    await tester.pump();
    expect(fixture.selections, [1]);
    _expectSelection(tester, 1);
    await tester.tapAt(tester.getCenter(_cell(1)));
    await tester.pump();
    expect(fixture.selections, [1]);
    await tester.tapAt(tester.getCenter(_cell(4)));
    await tester.pump();
    expect(fixture.selections, [1, 4]);
  });

  testWidgets('idle deadline is exactly three seconds after release', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _mount(tester, fixture);
    await _expand(tester);
    await tester.pump(const Duration(milliseconds: 2999));
    _expectSize(tester, const Size(390, 58));
    await tester.pump(const Duration(milliseconds: 1));
    _expectSize(tester, const Size(156, 46));
    expect(fixture.selections, isEmpty);
  });

  testWidgets(
    'holding the bar suppresses idle and release starts a fresh deadline',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      final finger = await tester.startGesture(tester.getCenter(_surface));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(seconds: 5));
      _expectSize(tester, const Size(390, 58));
      expect(fixture.selections, isEmpty);
      await finger.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 2999));
      _expectSize(tester, const Size(390, 58));
      await tester.pump(const Duration(milliseconds: 1));
      _expectSize(tester, const Size(156, 46));
    },
  );

  testWidgets('a new touch cancels the previous idle deadline', (tester) async {
    final fixture = _Fixture();
    await _mount(tester, fixture);
    await _expand(tester);
    await tester.pump(const Duration(milliseconds: 2500));
    final finger = await tester.startGesture(tester.getCenter(_cell(0)));
    await tester.pump(const Duration(milliseconds: 600));
    _expectSize(tester, const Size(390, 58));
    await finger.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2999));
    _expectSize(tester, const Size(390, 58));
    await tester.pump(const Duration(milliseconds: 1));
    _expectSize(tester, const Size(156, 46));
    expect(fixture.selections, isEmpty);
  });

  testWidgets(
    'scroll-collapse revision collapses without consuming a destination',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _expand(tester);
      fixture.change(() => fixture.collapseRevision++);
      await tester.pump();
      _expectSize(tester, const Size(156, 46));
      expect(fixture.selections, isEmpty);
      await _expand(tester);
      // An ordinary owner rebuild does not impersonate another scroll event.
      fixture.change(() {});
      await tester.pump();
      _expectSize(tester, const Size(390, 58));
    },
  );

  testWidgets(
    'normal motion finishes in 250ms without overshooting full width',
    (tester) async {
      final fixture = _Fixture()..reducedMotion = false;
      await _mount(tester, fixture);
      _expectSize(tester, const Size(156, 46));
      final finger = await tester.startGesture(tester.getCenter(_surface));
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 125));
      expect(tester.getSize(_surface).width, greaterThan(156));
      expect(tester.getSize(_surface).width, lessThanOrEqualTo(390));
      await tester.pump(const Duration(milliseconds: 125));
      _expectSize(tester, const Size(390, 58));
      await finger.up();
      await tester.pump();
      fixture.change(() => fixture.collapseRevision++);
      await tester.pump();
      for (var frame = 0; frame < 16; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final width = tester.getSize(_surface).width;
        expect(width, inInclusiveRange(156, 390));
      }
      _expectSize(tester, const Size(156, 46));
      expect(fixture.selections, isEmpty);
    },
  );

  testWidgets('Reduce Motion changes size immediately in both directions', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _mount(tester, fixture);
    final finger = await tester.startGesture(tester.getCenter(_surface));
    await tester.pump(const Duration(milliseconds: 120));
    _expectSize(tester, const Size(390, 58));
    await finger.up();
    await tester.pump();
    fixture.change(() => fixture.collapseRevision++);
    await tester.pump();
    _expectSize(tester, const Size(156, 46));
    expect(fixture.selections, isEmpty);
  });

  testWidgets(
    'native Reduce Motion is honored even without MediaQuery disableAnimations',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(reduceMotion: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final fixture = _Fixture()..reducedMotion = false;
      await _mount(tester, fixture);
      final finger = await tester.startGesture(tester.getCenter(_surface));
      await tester.pump(const Duration(milliseconds: 120));
      _expectSize(tester, const Size(390, 58));
      await finger.up();
      await tester.pump();
      fixture.change(() => fixture.collapseRevision++);
      await tester.pump();
      _expectSize(tester, const Size(156, 46));
    },
  );

  for (final native in [false, true]) {
    final setting = native
        ? 'native Reduce Motion'
        : 'MediaQuery Reduce Motion';
    testWidgets('$setting settles mid-expansion and retains the held pointer', (
      tester,
    ) async {
      if (native) {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures();
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
      }
      final fixture = _Fixture()..reducedMotion = false;
      await _mount(tester, fixture);
      final finger = await tester.startGesture(tester.getCenter(_surface));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final movingWidth = tester.getSize(_surface).width;
      expect(movingWidth, greaterThan(156));
      expect(movingWidth, lessThan(390));
      if (native) {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
      } else {
        fixture.change(() => fixture.reducedMotion = true);
      }
      await tester.pump();
      _expectSize(tester, const Size(390, 58));
      await tester.pump(const Duration(seconds: 4));
      _expectSize(tester, const Size(390, 58));
      expect(fixture.selections, isEmpty);
      await finger.up();
      await tester.pump();
      expect(fixture.selections, isEmpty);
      await tester.pump(const Duration(milliseconds: 2999));
      _expectSize(tester, const Size(390, 58));
      await tester.pump(const Duration(milliseconds: 1));
      _expectSize(tester, const Size(156, 46));
      expect(tester.takeException(), isNull);
    });

    testWidgets('$setting settles mid-collapse and accepts the next touch', (
      tester,
    ) async {
      if (native) {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures();
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
      }
      final fixture = _Fixture()..reducedMotion = false;
      await _mount(tester, fixture);
      await _expand(tester);
      fixture.change(() => fixture.collapseRevision++);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final movingWidth = tester.getSize(_surface).width;
      expect(movingWidth, greaterThan(156));
      expect(movingWidth, lessThan(390));
      if (native) {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
      } else {
        fixture.change(() => fixture.reducedMotion = true);
      }
      await tester.pump();
      _expectSize(tester, const Size(156, 46));
      final finger = await tester.startGesture(tester.getCenter(_surface));
      await tester.pump();
      _expectSize(tester, const Size(390, 58));
      await finger.up();
      await tester.pump();
      expect(fixture.selections, isEmpty);
      await tester.pump(const Duration(seconds: 3));
      _expectSize(tester, const Size(156, 46));
      expect(tester.takeException(), isNull);
    });
  }

  for (final mode in ['VoiceOver or Switch Control', 'Larger Text']) {
    testWidgets('$mode keeps all named tab targets full size', (tester) async {
      final fixture = _Fixture();
      if (mode == 'Larger Text') {
        fixture.textScale = 1.1;
      } else {
        fixture.accessibleNavigation = true;
      }
      await _mount(tester, fixture);
      _expectSize(tester, const Size(390, 58));
      final semantics = tester.ensureSemantics();
      try {
        for (var index = 0; index < fixture.items.length; index++) {
          final data = tester.getSemantics(_cell(index)).getSemanticsData();
          expect(data.label, fixture.items[index].label);
          expect(data.flagsCollection.isButton, isTrue);
          expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
          expect(tester.getSize(_cell(index)).width, greaterThanOrEqualTo(44));
          expect(tester.getSize(_cell(index)).height, greaterThanOrEqualTo(44));
        }
        await tester.tapAt(tester.getCenter(_cell(3)));
        await tester.pump();
        expect(fixture.selections, [3]);
        await tester.pump(const Duration(seconds: 10));
        fixture.change(() => fixture.collapseRevision++);
        await tester.pump();
        _expectSize(tester, const Size(390, 58));
      } finally {
        semantics.dispose();
      }
    });
  }

  testWidgets(
    'enabling accessibility settles an already shrinking bar at full size',
    (tester) async {
      final fixture = _Fixture()..reducedMotion = false;
      await _mount(tester, fixture);
      await _expand(tester);
      fixture.change(() => fixture.collapseRevision++);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getSize(_surface).width, lessThan(390));
      fixture.change(() => fixture.accessibleNavigation = true);
      await tester.pump(const Duration(milliseconds: 300));
      _expectSize(tester, const Size(390, 58));
      await tester.pump(const Duration(seconds: 5));
      _expectSize(tester, const Size(390, 58));
    },
  );

  testWidgets(
    'changing Reduce Motion preserves the current expansion and idle deadline',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      await _expand(tester);
      await tester.pump(const Duration(seconds: 1));
      fixture.change(() => fixture.reducedMotion = false);
      await tester.pump();
      _expectSize(tester, const Size(390, 58));
      fixture.change(() => fixture.reducedMotion = true);
      await tester.pump();
      _expectSize(tester, const Size(390, 58));
      await tester.pump(const Duration(milliseconds: 1999));
      _expectSize(tester, const Size(390, 58));
      await tester.pump(const Duration(milliseconds: 1));
      _expectSize(tester, const Size(156, 46));
    },
  );

  testWidgets(
    'gold activity survives expansion and clears only after the owner opens its tab',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      expect(_iconColor(tester, 2), ZyraColors.journeyGold);
      await _expand(tester);
      expect(fixture.selections, isEmpty);
      expect(fixture.newActivity, isTrue);
      expect(_iconColor(tester, 2), ZyraColors.journeyGold);
      expect(
        tester.widget<Semantics>(_cell(2)).properties.value,
        'New activity',
      );
      await tester.tapAt(tester.getCenter(_cell(2)));
      await tester.pump();
      expect(fixture.selections, [2]);
      expect(fixture.newActivity, isFalse);
      expect(_iconColor(tester, 2), ZyraColors.foreground);
      _expectSelection(tester, 2);
      await tester.pump(const Duration(seconds: 3));
      _expectSize(tester, const Size(156, 46));
      expect(_iconColor(tester, 2), ZyraColors.foreground);
      fixture.change(() => fixture.newActivity = true);
      await tester.pump();
      expect(_iconColor(tester, 2), ZyraColors.journeyGold);
      _expectSize(tester, const Size(156, 46));
    },
  );

  testWidgets(
    'stale semantic callbacks refuse after selection, role change and disposal',
    (tester) async {
      final fixture = _Fixture()..accessibleNavigation = true;
      await _mount(tester, fixture);
      final beforeSelection = tester
          .widget<Semantics>(_cell(4))
          .properties
          .onTap!;
      tester.widget<Semantics>(_cell(1)).properties.onTap!();
      await tester.pump();
      beforeSelection();
      await tester.pump();
      expect(fixture.selections, [1]);
      final beforeRole = tester.widget<Semantics>(_cell(3)).properties.onTap!;
      fixture.change(() {
        fixture.guardian = true;
        fixture.selected = 0;
      });
      await tester.pump();
      beforeRole();
      await tester.pump();
      expect(fixture.selections, [1]);
      expect(_cell(4), findsNothing);
      expect(tester.widget<Semantics>(_cell(1)).properties.label, 'Network');
      tester.widget<Semantics>(_cell(1)).properties.onTap!();
      await tester.pump();
      expect(fixture.selections, [1, 1]);
      final detached = tester.widget<Semantics>(_cell(2)).properties.onTap!;
      await tester.pumpWidget(const SizedBox.shrink());
      detached();
      await tester.pump(const Duration(seconds: 5));
      expect(fixture.selections, [1, 1]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a covered bar revokes retained actions across a disable/enable round trip',
    (tester) async {
      final fixture = _Fixture()..accessibleNavigation = true;
      await _mount(tester, fixture);
      final retained = tester.widget<Semantics>(_cell(2)).properties.onTap!;
      fixture.change(() => fixture.enabled = false);
      await tester.pump();
      retained();
      await tester.pump();
      expect(fixture.selections, isEmpty);
      fixture.change(() => fixture.enabled = true);
      await tester.pump();
      retained();
      await tester.pump();
      expect(fixture.selections, isEmpty);
      tester.widget<Semantics>(_cell(2)).properties.onTap!();
      await tester.pump();
      expect(fixture.selections, [2]);
    },
  );

  testWidgets(
    'ordinary callers retain the existing Floating Glass navigation',
    (tester) async {
      final fixture = _Fixture(compact: false);
      await _mount(tester, fixture);
      expect(_surface, findsNothing);
      expect(_underline, findsNothing);
      expect(find.byType(ZyraNavHighlight), findsOneWidget);
      expect(_iconSize(tester, 0), ZyraNavBarMetrics.iconSize);
      await tester.tapAt(tester.getCenter(_cell(3)));
      await tester.pump();
      expect(fixture.selections, [3]);
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(ZyraNavHighlight), findsOneWidget);
      expect(_surface, findsNothing);
    },
  );

  testWidgets(
    'the Profiles action-bar mode keeps its full legacy release contract',
    (tester) async {
      final fixture = _Fixture()..commitOnRelease = true;
      await _mount(tester, fixture);
      expect(_surface, findsNothing);
      expect(find.byType(ZyraNavHighlight), findsOneWidget);
      final finger = await tester.startGesture(tester.getCenter(_cell(1)));
      await tester.pump(const Duration(milliseconds: 350));
      await finger.moveTo(tester.getCenter(_cell(4)));
      await tester.pump();
      expect(fixture.selections, isEmpty);
      await finger.up();
      await tester.pump();
      expect(fixture.selections, [4]);
      expect(_surface, findsNothing);
    },
  );

  testWidgets(
    'other developer navigation styles keep their existing renderer',
    (tester) async {
      ZyraInteractionStyle.selectNavStyle(ZyraNavStyle.goldUnderline);
      final fixture = _Fixture();
      await _mount(tester, fixture);
      expect(_surface, findsNothing);
      expect(_underline, findsNothing);
      expect(
        tester.widget<ZyraNavHighlight>(find.byType(ZyraNavHighlight)).style,
        ZyraNavStyle.goldUnderline,
      );
      await tester.tapAt(tester.getCenter(_cell(1)));
      await tester.pump();
      expect(fixture.selections, [1]);
    },
  );
}
