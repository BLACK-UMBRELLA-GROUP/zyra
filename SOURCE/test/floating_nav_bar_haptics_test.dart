import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    ZyraInteractionStyle.restoreDefaults();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    ZyraInteractionStyle.restoreDefaults();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget subject({
    bool commitOnRelease = false,
    bool dimmed = false,
    bool showLabels = false,
    bool disableAnimations = false,
    bool accessibleNavigation = false,
    int badge = 0,
    bool dot = false,
    ZyraHapticLevel? hapticLevel,
    ValueChanged<int>? onSelection,
  }) {
    var selected = 0;
    return MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          accessibleNavigation: accessibleNavigation,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => Stack(
            children: [
              FloatingNavBar(
                currentIndex: selected,
                commitOnRelease: commitOnRelease,
                showLabels: showLabels,
                hapticLevel: hapticLevel,
                onTap: (index) {
                  onSelection?.call(index);
                  setState(() => selected = index);
                },
                items: [
                  const FloatingNavItem(icon: Icons.search, label: 'Search'),
                  FloatingNavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    badge: badge,
                    dot: dot,
                  ),
                  FloatingNavItem(
                    icon: Icons.gpp_good_outlined,
                    label: 'Guardian',
                    dimmed: dimmed,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int selectionTicks() => calls
      .where(
        (call) =>
            call.method == 'HapticFeedback.vibrate' &&
            call.arguments == 'HapticFeedbackType.selectionClick',
      )
      .length;

  Finder cell(int index) => find.byKey(ValueKey('floating-nav-item-$index'));

  void semanticTap(WidgetTester tester, int index) {
    final finder = cell(index);
    final node = tester.getSemantics(finder);
    tester
        .renderObject<RenderObject>(finder)
        .owner!
        .semanticsOwner!
        .performAction(node.id, ui.SemanticsAction.tap);
  }

  testWidgets('icon-only nav exposes one labelled action per destination', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(subject(dimmed: true, badge: 12, dot: true));
      const labels = ['Search', 'Dashboard', 'Guardian'];
      for (var index = 0; index < labels.length; index++) {
        final node = tester.getSemantics(cell(index));
        final data = node.getSemanticsData();
        expect(data.label, labels[index]);
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
        expect(
          data.flagsCollection.isSelected,
          index == 0 ? ui.Tristate.isTrue : ui.Tristate.isFalse,
        );
        expect(find.bySemanticsLabel(labels[index]), findsOneWidget);
      }
      expect(
        tester.getSemantics(cell(1)).getSemanticsData().value,
        '12 unread',
        reason: 'the spoken count stays exact even when the glyph shows 9+',
      );
      expect(
        tester
            .widget<GestureDetector>(
              find.descendant(
                of: find.byType(FloatingNavBar),
                matching: find.byType(GestureDetector),
              ),
            )
            .excludeFromSemantics,
        isTrue,
      );
      semanticTap(tester, 2);
      await tester.pump();
      expect(
        tester.getSemantics(cell(2)).flagsCollection.isSelected,
        ui.Tristate.isTrue,
        reason: 'a visually dimmed destination remains reachable',
      );
    } finally {
      handle.dispose();
    }
  });

  testWidgets('dot badges have one honest spoken activity cue', (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(subject(dot: true, showLabels: true));
      final data = tester.getSemantics(cell(1)).getSemanticsData();
      expect(data.label, 'Dashboard');
      expect(data.value, 'New activity');
      expect(find.bySemanticsLabel('Dashboard'), findsOneWidget);
    } finally {
      handle.dispose();
    }
  });

  for (final mode in ['icon-only', 'labelled', 'dimmed', 'actions']) {
    testWidgets('$mode exposes a full-height accessible navigation cell', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          subject(
            showLabels: mode == 'labelled',
            dimmed: mode == 'dimmed',
            commitOnRelease: mode == 'actions',
          ),
        );
        for (var index = 0; index < 3; index++) {
          final node = tester.getSemantics(cell(index));
          expect(node.rect.height, greaterThanOrEqualTo(44));
          expect(node.rect.width, greaterThanOrEqualTo(44));
        }
        if (mode != 'labelled') {
          expect(
            tester.getCenter(find.byIcon(Icons.dashboard_outlined)),
            tester.getCenter(cell(1)),
            reason: 'the larger semantic target leaves the glyph centered',
          );
        }
        expect(tester.takeException(), isNull);
      } finally {
        handle.dispose();
      }
    });
  }

  testWidgets('semantic activation selects one exact tab and haptic', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final selected = <int>[];
    try {
      await tester.pumpWidget(subject(onSelection: selected.add));
      semanticTap(tester, 1);
      await tester.pump();
      expect(selected, [1]);
      expect(selectionTicks(), 1);
      semanticTap(tester, 1);
      await tester.pump();
      expect(selected, [1]);
      expect(selectionTicks(), 2);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('semantic action mode executes once, including its active cell', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final selected = <int>[];
    try {
      await tester.pumpWidget(
        subject(commitOnRelease: true, onSelection: selected.add),
      );
      semanticTap(tester, 1);
      await tester.pump();
      expect(selected, [1]);
      expect(selectionTicks(), 1);
      semanticTap(tester, 1);
      await tester.pump();
      expect(selected, [1, 1]);
      expect(selectionTicks(), 2);
    } finally {
      handle.dispose();
    }
  });

  testWidgets('stale semantic callbacks cannot activate a replaced bar', (
    tester,
  ) async {
    final first = <int>[];
    final replacement = <int>[];
    await tester.pumpWidget(subject(onSelection: first.add));
    final staleTap = tester.widget<Semantics>(cell(1)).properties.onTap!;
    await tester.pumpWidget(
      subject(commitOnRelease: true, onSelection: replacement.add),
    );
    staleTap();
    await tester.pump();
    expect(first, isEmpty);
    expect(replacement, isEmpty);
    expect(selectionTicks(), 0);
    tester.widget<Semantics>(cell(2)).properties.onTap!();
    await tester.pump();
    expect(replacement, [2]);
    expect(selectionTicks(), 1);
    final detachedTap = tester.widget<Semantics>(cell(1)).properties.onTap!;
    await tester.pumpWidget(const SizedBox());
    detachedTap();
    expect(replacement, [2]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('semantic callbacks expire after a logical selection change', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(subject(onSelection: selected.add));
    final previousTap = tester.widget<Semantics>(cell(2)).properties.onTap!;
    tester.widget<Semantics>(cell(1)).properties.onTap!();
    await tester.pump();
    previousTap();
    await tester.pump();
    expect(selected, [1]);
    expect(selectionTicks(), 1);
  });

  testWidgets('pointer action scrubbing commits only its release cell', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(
      subject(commitOnRelease: true, onSelection: selected.add),
    );
    final bar = find.descendant(
      of: find.byType(FloatingNavBar),
      matching: find.byType(GestureDetector),
    );
    final initial = tester.getRect(bar);
    final gesture = await tester.startGesture(
      Offset(initial.left + 8, initial.center.dy),
    );
    await tester.pump();
    final touched = tester.getRect(bar);
    await gesture.moveTo(Offset(touched.right - 8, touched.center.dy));
    await tester.pump();
    expect(selected, isEmpty);
    await gesture.up();
    await tester.pump();
    expect(selected, [2]);

    final cancelled = await tester.startGesture(
      Offset(touched.left + 8, touched.center.dy),
    );
    await tester.pump();
    await cancelled.moveTo(touched.center);
    await tester.pump();
    await cancelled.cancel();
    await tester.pump();
    expect(selected, [2], reason: 'a cancelled gesture is not an action');
  });

  testWidgets('caller-owned Off suppresses pointer and semantic feedback', (
    tester,
  ) async {
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.strong);
    final selected = <int>[];
    await tester.pumpWidget(
      subject(hapticLevel: ZyraHapticLevel.off, onSelection: selected.add),
    );
    await tester.tapAt(tester.getCenter(cell(1)));
    await tester.pump();
    tester.widget<Semantics>(cell(2)).properties.onTap!();
    await tester.pump();
    expect(selected, [1, 2]);
    expect(
      calls.where((call) => call.method == 'HapticFeedback.vibrate'),
      isEmpty,
    );
    expect(ZyraInteractionStyle.hapticLevel, ZyraHapticLevel.strong);
  });

  testWidgets(
    'caller-owned Strong works without changing ordinary preference',
    (tester) async {
      ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.off);
      final selected = <int>[];
      await tester.pumpWidget(
        subject(hapticLevel: ZyraHapticLevel.strong, onSelection: selected.add),
      );
      await tester.tapAt(tester.getCenter(cell(1)));
      await tester.pump();
      expect(selected, [1]);
      expect(
        calls.where(
          (call) =>
              call.method == 'HapticFeedback.vibrate' &&
              call.arguments == 'HapticFeedbackType.heavyImpact',
        ),
        hasLength(1),
      );
      expect(ZyraInteractionStyle.hapticLevel, ZyraHapticLevel.off);
    },
  );

  testWidgets('confirmation pills respect caller-owned feedback', (
    tester,
  ) async {
    ZyraInteractionStyle.selectHapticLevel(ZyraHapticLevel.strong);
    final selected = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FloatingNavConfirmationBar(
                hapticLevel: ZyraHapticLevel.off,
                onCancel: () => selected.add('cancel'),
                onConfirm: () => selected.add('confirm'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('browse-hide-cancel')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('browse-hide-confirm')));
    await tester.pump();
    expect(selected, ['cancel', 'confirm']);
    expect(
      calls.where((call) => call.method == 'HapticFeedback.vibrate'),
      isEmpty,
    );
    expect(ZyraInteractionStyle.hapticLevel, ZyraHapticLevel.strong);
  });

  for (final quiet in ['reduced motion', 'accessible navigation']) {
    testWidgets('$quiet makes every navigation transition immediate', (
      tester,
    ) async {
      await tester.pumpWidget(
        subject(
          showLabels: true,
          disableAnimations: quiet == 'reduced motion',
          accessibleNavigation: quiet == 'accessible navigation',
        ),
      );
      await tester.tapAt(tester.getCenter(cell(1)));
      await tester.pump();
      expect(tester.widget<Semantics>(cell(1)).properties.selected, isTrue);
      final animations = tester.widgetList<ImplicitlyAnimatedWidget>(
        find.descendant(
          of: find.byType(FloatingNavBar),
          matching: find.byWidgetPredicate(
            (widget) => widget is ImplicitlyAnimatedWidget,
          ),
        ),
      );
      expect(animations.length, greaterThanOrEqualTo(6));
      for (final animation in animations) {
        expect(animation.duration, Duration.zero);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('$quiet settles a navigation transition already in flight', (
      tester,
    ) async {
      var selected = 0;
      var quietMode = false;
      late StateSetter configure;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              configure = setState;
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  disableAnimations: quietMode && quiet == 'reduced motion',
                  accessibleNavigation:
                      quietMode && quiet == 'accessible navigation',
                ),
                child: Scaffold(
                  body: Stack(
                    children: [
                      FloatingNavBar(
                        currentIndex: selected,
                        onTap: (index) => setState(() => selected = index),
                        items: const [
                          FloatingNavItem(icon: Icons.search, label: 'Search'),
                          FloatingNavItem(
                            icon: Icons.dashboard_outlined,
                            label: 'Dashboard',
                          ),
                          FloatingNavItem(
                            icon: Icons.gpp_good_outlined,
                            label: 'Guardian',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
      tester.widget<Semantics>(cell(2)).properties.onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(
        (tester.getCenter(find.byType(ZyraNavHighlight)).dx -
                tester.getCenter(cell(2)).dx)
            .abs(),
        greaterThan(0.01),
        reason: 'the ordinary transition was genuinely still moving',
      );
      configure(() => quietMode = true);
      await tester.pump();
      final settled = tester.getCenter(find.byType(ZyraNavHighlight));
      final destination = tester.getCenter(cell(2));
      expect(settled.dx, closeTo(destination.dx, 0.001));
      expect(settled.dy, closeTo(destination.dy, 0.001));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getCenter(find.byType(ZyraNavHighlight)), settled);
      expect(selected, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('dimmed destinations stay visible without a lock badge', (
    tester,
  ) async {
    await tester.pumpWidget(subject(dimmed: true));

    expect(find.byIcon(Icons.gpp_good_outlined), findsOneWidget);
    expect(find.byIcon(Icons.lock_rounded), findsNothing);
    final icon = tester.widget<Icon>(find.byIcon(Icons.gpp_good_outlined));
    expect(icon.color!.a, lessThan(0.6));
  });

  testWidgets('changing tab emits one subtle selection haptic', (tester) async {
    await tester.pumpWidget(subject());
    final bar = find.descendant(
      of: find.byType(FloatingNavBar),
      matching: find.byType(GestureDetector),
    );
    final rect = tester.getRect(bar);
    final dashboard = Offset(rect.left + rect.width / 2, rect.center.dy);

    await tester.tapAt(dashboard);
    await tester.pump();

    expect(selectionTicks(), 1);

    await tester.tapAt(dashboard);
    await tester.pump();

    expect(selectionTicks(), 2, reason: 'each enabled tap has one pulse');
  });

  testWidgets('holding inside one action cell does not repeat haptics', (
    tester,
  ) async {
    await tester.pumpWidget(subject(commitOnRelease: true));
    final bar = find.descendant(
      of: find.byType(FloatingNavBar),
      matching: find.byType(GestureDetector),
    );
    final rect = tester.getRect(bar);
    final centre = Offset(rect.left + rect.width / 2, rect.center.dy);
    final gesture = await tester.startGesture(centre);
    await tester.pump();
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-2, 0));
    await tester.pump();

    expect(selectionTicks(), 0);

    await gesture.up();
    await tester.pump();
    expect(selectionTicks(), 0);
  });

  test('each haptic level maps to one honest native semantic', () async {
    const expected = {
      ZyraHapticLevel.subtle: 'HapticFeedbackType.selectionClick',
      ZyraHapticLevel.light: 'HapticFeedbackType.lightImpact',
      ZyraHapticLevel.medium: 'HapticFeedbackType.mediumImpact',
      ZyraHapticLevel.strong: 'HapticFeedbackType.heavyImpact',
    };

    await ZyraInteractionStyle.emitSelectionHaptic(level: ZyraHapticLevel.off);
    expect(calls, isEmpty);

    for (final entry in expected.entries) {
      calls.clear();
      await ZyraInteractionStyle.emitSelectionHaptic(level: entry.key);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'HapticFeedback.vibrate');
      expect(calls.single.arguments, entry.value);
    }
  });

  testWidgets('the locked Floating Glass renders every destination', (
    tester,
  ) async {
    expect(ZyraNavStyle.values, hasLength(7));
    expect(ZyraInteractionStyle.navStyle, ZyraNavStyle.floatingGlass);
    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
    expect(find.byIcon(Icons.gpp_good_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
