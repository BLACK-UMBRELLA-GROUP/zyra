// LOCK 6: actual floating navigation geometry and owned pointer lifetimes.
// Fixtures have no account, service, subscription, or notification authority.
import 'dart:io';

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
  FloatingNavItem(icon: Icons.search, label: 'Network'),
  FloatingNavItem(
    icon: Icons.route_outlined,
    label: 'Journeys',
    useJourneyGlyph: true,
  ),
  FloatingNavItem(icon: Icons.dashboard_outlined, label: 'My ZYRA'),
  FloatingNavItem(icon: Icons.gpp_good_outlined, label: 'Seekers'),
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
  _Fixture({this.guardian = false, this.locked = true});

  ZyraHapticLevel haptic = ZyraHapticLevel.off;
  bool guardian;
  bool locked;
  bool enabled = true;
  bool commitOnRelease = false;
  bool reducedMotion = true;
  bool? accessibleNavigation;
  double textScale = 1;
  int selected = 0;
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
                  hapticLevel: fixture.haptic,
                  commitOnRelease: fixture.commitOnRelease,
                  lockedTabBar: fixture.locked,
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
  final pulses = <Object?>[];

  setUp(() {
    pulses.clear();
    ZyraText.useTestFontStubs = true;
    ZyraInteractionStyle.restoreDefaults();
    previousHttp = HttpOverrides.current;
    offline = _Offline();
    HttpOverrides.global = offline;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            pulses.add(call.arguments);
          }
          return null;
        });
  });

  tearDown(() {
    expect(offline.attempts, 0);
    HttpOverrides.global = previousHttp;
    ZyraInteractionStyle.restoreDefaults();
    ZyraText.useTestFontStubs = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  for (final level in [ZyraHapticLevel.subtle, ZyraHapticLevel.off]) {
    testWidgets('first and subsequent tab taps use ${level.label} once', (
      tester,
    ) async {
      final fixture = _Fixture()..haptic = level;
      await _mount(tester, fixture);
      final expected = level == ZyraHapticLevel.off
          ? <Object?>[]
          : <Object?>['HapticFeedbackType.selectionClick'];
      await tester.tapAt(tester.getCenter(_cell(1)));
      await tester.pump();
      expect(fixture.selections, [1]);
      expect(pulses, expected);
      pulses.clear();
      await tester.tapAt(tester.getCenter(_cell(3)));
      await tester.pump();
      expect(fixture.selections, [1, 3]);
      expect(pulses, expected);
      pulses.clear();
      await tester.drag(_surface, const Offset(90, 0));
      await tester.pump();
      expect(pulses, isEmpty);
      fixture.change(() => fixture.enabled = false);
      await tester.pump();
      await tester.tapAt(tester.getCenter(_cell(2)));
      await tester.pump();
      expect(pulses, isEmpty);
    });
  }

  for (final guardian in [false, true]) {
    testWidgets(
      guardian
          ? 'Guardian uses the fixed V4 geometry'
          : 'Seeker uses the fixed V4 geometry',
      (tester) async {
        final fixture = _Fixture(guardian: guardian)..reducedMotion = false;
        await _mount(tester, fixture);
        final frame = tester.getRect(_surface);
        final decoration = tester.widget<Container>(_surface).decoration;
        expect(frame, const Rect.fromLTWH(20, 840, 390, 58));
        expect(fixture.items.length, 5);
        expect(tester.getSize(_underline).width, 24);
        _expectSelection(tester, 0);
        for (var index = 0; index < fixture.items.length; index++) {
          expect(_iconSize(tester, index), 21);
          expect(tester.getSize(_cell(index)), const Size(44, 44));
        }
        expect(_iconColor(tester, 0), ZyraColors.foreground);
        final last = fixture.items.length - 1;
        final finger = await tester.startGesture(tester.getCenter(_cell(last)));
        await tester.pump(const Duration(milliseconds: 350));
        expect(fixture.selections, isEmpty);
        expect(tester.getRect(_surface), frame);
        expect(tester.widget<Container>(_surface).decoration, decoration);
        await finger.up();
        await tester.pump();
        expect(fixture.selections, [last]);
        _expectSelection(tester, last);
        expect(tester.getRect(_surface), frame);
        expect(tester.widget<Container>(_surface).decoration, decoration);
        await tester.pump(const Duration(seconds: 4));
        expect(tester.getRect(_surface), frame);
      },
    );
  }

  testWidgets(
    'larger text, accessible navigation and idle leave the same bar',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      final frame = tester.getRect(_surface);
      fixture.change(() {
        fixture.textScale = 2;
        fixture.accessibleNavigation = true;
      });
      await tester.pump(const Duration(seconds: 4));
      expect(tester.getRect(_surface), frame);
      expect(tester.getSize(_cell(2)), const Size(44, 44));
      await tester.tapAt(tester.getCenter(_cell(2)));
      await tester.pump();
      expect(fixture.selections, [2]);
      _expectSelection(tester, 2);
    },
  );

  testWidgets('cancelled or covered pointer cannot select a tab', (
    tester,
  ) async {
    final fixture = _Fixture();
    await _mount(tester, fixture);
    final finger = await tester.startGesture(tester.getCenter(_cell(1)));
    fixture.change(() => fixture.enabled = false);
    await tester.pump();
    fixture.change(() => fixture.enabled = true);
    await tester.pump();
    await finger.up();
    await tester.pump();
    expect(fixture.selections, isEmpty);
    final previousRole = await tester.startGesture(tester.getCenter(_cell(1)));
    fixture.change(() => fixture.guardian = true);
    await tester.pump();
    await previousRole.up();
    await tester.pump();
    expect(fixture.selections, isEmpty);
    final cancelled = await tester.startGesture(tester.getCenter(_cell(1)));
    await cancelled.cancel();
    await tester.pump();
    expect(fixture.selections, isEmpty);
    await tester.tapAt(tester.getCenter(_cell(1)));
    await tester.pump();
    expect(fixture.selections, [1]);
  });

  testWidgets(
    'gold activity survives other tab taps and clears only when opened',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture);
      expect(_iconColor(tester, 2), ZyraColors.journeyGold);
      await tester.tapAt(tester.getCenter(_cell(1)));
      await tester.pump();
      expect(fixture.selections, [1]);
      expect(fixture.newActivity, isTrue);
      expect(_iconColor(tester, 2), ZyraColors.journeyGold);
      expect(
        tester.widget<Semantics>(_cell(2)).properties.value,
        'New activity',
      );
      await tester.tapAt(tester.getCenter(_cell(2)));
      await tester.pump();
      expect(fixture.selections, [1, 2]);
      expect(fixture.newActivity, isFalse);
      expect(_iconColor(tester, 2), ZyraColors.foreground);
      _expectSelection(tester, 2);
      await tester.pump(const Duration(seconds: 3));
      _expectSize(tester, const Size(390, 58));
      expect(_iconColor(tester, 2), ZyraColors.foreground);
      fixture.change(() => fixture.newActivity = true);
      await tester.pump();
      expect(_iconColor(tester, 2), ZyraColors.journeyGold);
      _expectSize(tester, const Size(390, 58));
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
      expect(_cell(4), findsOneWidget);
      expect(tester.widget<Semantics>(_cell(1)).properties.label, 'Journeys');
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
      final fixture = _Fixture(locked: false);
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
      final fixture = _Fixture(locked: false);
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
