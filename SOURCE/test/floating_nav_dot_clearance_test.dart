// Paint-geometry regressions for the real five-destination navigation bar.
// Activity is caller-owned; these fixtures never load accounts or notifications.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';
import 'package:zyra/widgets/zyra_journey_icon.dart';

const _captureDirectory = String.fromEnvironment('ZYRA_NAV_DOT_CAPTURE_DIR');
const _captureKey = ValueKey('nav-dot-clearance-capture');
const _font = 'PoppinsNavDotClearance';
const _icons = [
  Icons.search,
  Icons.route_outlined,
  Icons.dashboard_outlined,
  Icons.gpp_good_outlined,
  Icons.person_outline,
];
const _labels = ['Browse', 'Journey', 'My ZYRA', 'Guardian', 'Profile'];
final _platformCalls = <MethodCall>[];

Finder _cell(int index) => find.byKey(ValueKey('floating-nav-item-$index'));
Finder _glyph(int index) => find.descendant(
  of: _cell(index),
  matching: index == 1
      ? find.byType(ZyraJourneyIcon)
      : find.byIcon(_icons[index]),
);
Finder _paintedGoldCircle(int index) => find.descendant(
  of: _cell(index),
  matching: find.byWidgetPredicate((widget) {
    if (widget is! DecoratedBox) return false;
    final decoration = widget.decoration;
    return decoration is BoxDecoration &&
        decoration.shape == BoxShape.circle &&
        decoration.color == ZyraColors.unlockDot;
  }),
);
Finder get _barClip => find.descendant(
  of: find.byType(FloatingNavBar),
  matching: find.byType(ClipRRect),
);

class _NoNetwork extends HttpOverrides {
  int calls = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    calls++;
    throw StateError('Navigation dot paint fixtures must stay offline.');
  }
}

class _Fixture {
  _Fixture({
    this.selected = 0,
    this.showLabels = false,
    int activityIndex = 2,
    int badge = 0,
  }) : activity = ValueNotifier((
         index: activityIndex,
         dot: true,
         badge: badge,
       ));

  final int selected;
  final bool showLabels;
  final ValueNotifier<({int index, bool dot, int badge})> activity;
  final selections = <int>[];
}

Widget _app(_Fixture fixture, {required bool reducedMotion}) {
  var selected = fixture.selected;
  final theme = ThemeData.dark();
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme.copyWith(
      textTheme: _captureDirectory.isEmpty
          ? theme.textTheme
          : theme.textTheme.apply(fontFamily: _font),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: const EdgeInsets.only(bottom: 34),
        viewPadding: const EdgeInsets.only(bottom: 34),
        textScaler: TextScaler.noScaling,
        disableAnimations: reducedMotion,
      ),
      child: child!,
    ),
    home: Scaffold(
      body: RepaintBoundary(
        key: _captureKey,
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ValueListenableBuilder<({int index, bool dot, int badge})>(
                valueListenable: fixture.activity,
                builder: (context, activity, _) => StatefulBuilder(
                  builder: (context, setState) => FloatingNavBar(
                    currentIndex: selected,
                    showLabels: fixture.showLabels,
                    hapticLevel: ZyraHapticLevel.subtle,
                    onTap: (index) {
                      fixture.selections.add(index);
                      setState(() => selected = index);
                    },
                    items: [
                      for (var index = 0; index < _labels.length; index++)
                        FloatingNavItem(
                          icon: _icons[index],
                          label: _labels[index],
                          useJourneyGlyph: index == 1,
                          dot: activity.index == index && activity.dot,
                          badge: activity.index == index ? activity.badge : 0,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _mount(
  WidgetTester tester,
  _Fixture fixture, {
  double width = 393,
  bool reducedMotion = true,
}) async {
  tester.view.physicalSize = Size(width, 200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // testWidgets owns the default enabled semantics handle and disposes it
  // before its end-of-test leak verification; do not add a second late handle.
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    fixture.activity.dispose();
  });
  await tester.pumpWidget(_app(fixture, reducedMotion: reducedMotion));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

int _selectionTicks() => _platformCalls
    .where(
      (call) =>
          call.method == 'HapticFeedback.vibrate' &&
          call.arguments == 'HapticFeedbackType.selectionClick',
    )
    .length;

Map<int, Rect> _glyphRects(WidgetTester tester) => {
  for (var index = 0; index < _labels.length; index++)
    index: tester.getRect(_glyph(index)),
};

void _expectGlyphsUnchanged(
  WidgetTester tester,
  Map<int, Rect> before, {
  bool showLabels = false,
}) {
  for (var index = 0; index < _labels.length; index++) {
    final rect = tester.getRect(_glyph(index));
    _expectSquare(rect, 22);
    expect(rect.left, closeTo(before[index]!.left, .001));
    expect(rect.top, closeTo(before[index]!.top, .001));
    expect(rect.center.dx, closeTo(tester.getCenter(_cell(index)).dx, .001));
    if (!showLabels) {
      expect(rect.center.dy, closeTo(tester.getCenter(_cell(index)).dy, .001));
    }
  }
}

void _expectContains(Rect outer, Rect inner) {
  expect(inner.left, greaterThanOrEqualTo(outer.left - .001));
  expect(inner.top, greaterThanOrEqualTo(outer.top - .001));
  expect(inner.right, lessThanOrEqualTo(outer.right + .001));
  expect(inner.bottom, lessThanOrEqualTo(outer.bottom + .001));
}

void _expectSquare(Rect rect, double side) {
  // Global rectangles subtract transformed coordinates; allow only numerical
  // rounding, not a change to the common logical icon or painted-circle size.
  expect(rect.width, closeTo(side, .001));
  expect(rect.height, closeTo(side, .001));
}

void _expectRectUnchanged(Rect before, Rect after) {
  expect(after.left, closeTo(before.left, .001));
  expect(after.top, closeTo(before.top, .001));
  expect(after.right, closeTo(before.right, .001));
  expect(after.bottom, closeTo(before.bottom, .001));
}

void _expectMinimumTargets(WidgetTester tester) {
  for (var index = 0; index < _labels.length; index++) {
    final rect = tester.getRect(_cell(index));
    expect(rect.width, greaterThanOrEqualTo(44));
    expect(rect.height, greaterThanOrEqualTo(44));
  }
}

void _expectClearance(WidgetTester tester, {int index = 2}) {
  expect(_paintedGoldCircle(index), findsNothing);
  final widget = tester.widget(_glyph(index));
  final color = widget is ZyraJourneyIcon
      ? widget.color
      : (widget as Icon).color;
  expect(color, ZyraColors.journeyGold);
  final icon = tester.getRect(_glyph(index));
  _expectSquare(icon, 22);
  _expectContains(tester.getRect(_cell(index)), icon);
  _expectContains(tester.getRect(_barClip), icon);
  expect(
    find.descendant(of: _cell(index), matching: find.text('9+')),
    findsNothing,
  );
  expect(tester.takeException(), isNull);
}

void _expectActivitySemantics(
  WidgetTester tester, {
  String? value,
  int index = 2,
}) {
  final data = tester.getSemantics(_cell(index)).getSemanticsData();
  expect(data.label, _labels[index]);
  expect(data.value, value ?? '');
  if (value == null) {
    final glyph = tester.widget(_glyph(index));
    final color = glyph is ZyraJourneyIcon
        ? glyph.color
        : (glyph as Icon).color;
    expect(color, isNot(ZyraColors.journeyGold));
  }
  expect(data.flagsCollection.isButton, isTrue);
  expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
  expect(find.bySemanticsLabel(_labels[index]), findsOneWidget);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (_captureDirectory.isEmpty) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final file = File('$_captureDirectory/$name.png');
    await file.create(exclusive: true);
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpOverrides? previousNetwork;
  late _NoNetwork network;

  setUpAll(() async {
    if (_captureDirectory.isEmpty) return;
    if (!_captureDirectory.startsWith('/') ||
        FileSystemEntity.typeSync(_captureDirectory, followLinks: false) !=
            FileSystemEntityType.directory ||
        Directory(_captureDirectory).resolveSymbolicLinksSync() !=
            Directory(_captureDirectory).path) {
      throw StateError(
        'Dot captures require an existing absolute nonlinked directory.',
      );
    }
    final reading = FontLoader(_font);
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
  });

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _captureDirectory.isEmpty ? null : _font;
    ZyraInteractionStyle.restoreDefaults();
    _platformCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          _platformCalls.add(call);
          return null;
        });
    previousNetwork = HttpOverrides.current;
    network = _NoNetwork();
    HttpOverrides.global = network;
    final fatal = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = fatal);
  });

  tearDown(() {
    expect(network.calls, 0);
    HttpOverrides.global = previousNetwork;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    ZyraInteractionStyle.restoreDefaults();
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  for (final width in [320, 393, 430]) {
    for (final selected in [0, 2]) {
      for (final reduced in [false, true]) {
        final destination = selected == 0 ? 'Browse' : 'MyZYRA';
        final motion = reduced ? 'reduced' : 'motion';
        final frame = '$width-${destination.toLowerCase()}-$motion';
        testWidgets('unread glyph geometry ${width}px $destination $motion', (
          tester,
        ) async {
          final fixture = _Fixture(selected: selected);
          await _mount(
            tester,
            fixture,
            width: width.toDouble(),
            reducedMotion: reduced,
          );
          // Capture the previous shoulder treatment before the new assertion fails.
          await _capture(tester, '$frame-rest');
          _expectClearance(tester);
          _expectActivitySemantics(tester, value: 'New activity');
          final original = _glyphRects(tester);
          fixture.activity.value = (index: 2, dot: false, badge: 0);
          await tester.pumpAndSettle();
          expect(_paintedGoldCircle(2), findsNothing);
          _expectGlyphsUnchanged(tester, original);
          _expectActivitySemantics(tester);
          fixture.activity.value = (index: 2, dot: true, badge: 0);
          await tester.pumpAndSettle();
          _expectGlyphsUnchanged(tester, original);
          _expectClearance(tester);
          expect(fixture.selections, isEmpty);
          expect(_selectionTicks(), 0);

          final finger = await tester.startGesture(
            tester.getCenter(_cell(selected)),
          );
          var released = false;
          try {
            // Let the real tap recognizer deliver tap-down; do not call its callback.
            await tester.pump(const Duration(milliseconds: 120));
            _expectClearance(tester);
            if (width == 393 && selected == 0 && !reduced) {
              await _capture(tester, '$frame-down');
            }
            await tester.pump(const Duration(milliseconds: 110));
            _expectClearance(tester);
            final height = tester.getSize(_barClip).height;
            if (reduced) {
              expect(height, closeTo(ZyraNavBarMetrics.height, .001));
            } else {
              expect(height, greaterThan(ZyraNavBarMetrics.restingHeight));
              expect(height, lessThan(ZyraNavBarMetrics.height));
            }
            if (width == 393 && selected == 0 && !reduced) {
              await _capture(tester, '$frame-mid-breath');
            }
            await tester.pump(const Duration(milliseconds: 200));
            if (selected == 2) {
              await finger.moveTo(tester.getCenter(_cell(3)));
              await tester.pump();
              _expectClearance(tester);
            }
            await finger.moveTo(tester.getCenter(_cell(2)));
            await tester.pump();
            _expectClearance(tester);
            if (width == 393 && selected == 0 && !reduced) {
              await _capture(tester, '$frame-scrub');
            }
            await finger.up();
            released = true;
            await tester.pumpAndSettle();
            _expectClearance(tester);
            if (width == 393 && selected == 0 && !reduced) {
              await _capture(tester, '$frame-released');
            }
          } finally {
            if (!released) await finger.cancel();
          }
          expect(fixture.selections, selected == 0 ? [2] : [3, 2]);
          // HAPTICS brief 30 Oct §2: scrub/swipe selection is silent.
          expect(_selectionTicks(), 0);
          expect(
            tester.widget<Semantics>(_cell(2)).properties.selected,
            isTrue,
          );
        });
      }
    }
  }

  testWidgets(
    'gold glyph centre still selects My ZYRA exactly once with one haptic',
    (tester) async {
      final fixture = _Fixture();
      await _mount(tester, fixture, width: 320);
      await _capture(tester, '320-dot-tap-rest');
      _expectClearance(tester);
      final point = tester.getCenter(_glyph(2));
      expect(tester.getRect(_cell(2)).contains(point), isTrue);
      await tester.tapAt(point);
      await tester.pumpAndSettle();
      expect(fixture.selections, [2]);
      expect(_selectionTicks(), 1);
      _expectClearance(tester);
      _expectActivitySemantics(tester, value: 'New activity');
      expect(tester.widget<Semantics>(_cell(2)).properties.selected, isTrue);
    },
  );

  testWidgets('count metadata keeps exact semantics without a painted badge', (
    tester,
  ) async {
    final fixture = _Fixture(badge: 12);
    await _mount(tester, fixture, width: 320);
    await _capture(tester, 'numeric-badge-12');
    _expectClearance(tester);
    expect(
      find.descendant(of: _cell(2), matching: find.text('9+')),
      findsNothing,
    );
    _expectActivitySemantics(tester, value: '12 unread');
    final original = _glyphRects(tester);
    fixture.activity.value = (index: 2, dot: false, badge: 12);
    await tester.pumpAndSettle();
    expect(_paintedGoldCircle(2), findsNothing);
    _expectActivitySemantics(tester, value: '12 unread');
    _expectGlyphsUnchanged(tester, original);
    fixture.activity.value = (index: 2, dot: false, badge: 0);
    await tester.pumpAndSettle();
    expect(_paintedGoldCircle(2), findsNothing);
    expect(
      find.descendant(of: _cell(2), matching: find.text('9+')),
      findsNothing,
    );
    _expectActivitySemantics(tester);
    _expectGlyphsUnchanged(tester, original);
    expect(fixture.selections, isEmpty);
    expect(_selectionTicks(), 0);
  });

  testWidgets('first and last unread glyphs fit the narrow rounded bar', (
    tester,
  ) async {
    final fixture = _Fixture(activityIndex: 0);
    await _mount(tester, fixture, width: 320);
    for (final index in [0, 4]) {
      fixture.activity.value = (index: index, dot: true, badge: 0);
      await tester.pumpAndSettle();
      await _capture(tester, '320-${index == 0 ? 'first' : 'last'}-under-icon');
      _expectClearance(tester, index: index);
      _expectActivitySemantics(tester, value: 'New activity', index: index);
      for (final other in [0, 1, 2, 3, 4].where((item) => item != index)) {
        expect(_paintedGoldCircle(other), findsNothing);
      }
    }
    expect(fixture.selections, isEmpty);
    expect(_selectionTicks(), 0);
  });

  for (final index in [0, 1, 2, 3, 4]) {
    for (final reduced in [false, true]) {
      final motion = reduced ? 'reduced' : 'motion';
      testWidgets('all five unread glyphs tab $index $motion at 320px', (
        tester,
      ) async {
        final fixture = _Fixture(
          selected: (index + 1) % _labels.length,
          activityIndex: index,
        );
        await _mount(tester, fixture, width: 320, reducedMotion: reduced);
        final original = _glyphRects(tester);
        final originalBar = tester.getRect(_barClip);
        final originalCells = {
          for (var cell = 0; cell < _labels.length; cell++)
            cell: tester.getRect(_cell(cell)),
        };
        if (!reduced) {
          await _capture(tester, '320-all-tabs-$index-motion-inactive');
        }
        _expectClearance(tester, index: index);
        _expectMinimumTargets(tester);
        _expectActivitySemantics(tester, value: 'New activity', index: index);
        expect(
          tester.widget<Semantics>(_cell(index)).properties.selected,
          isFalse,
        );
        expect(fixture.selections, isEmpty);
        expect(_selectionTicks(), 0);

        // A real touch on the painted under-icon dot must select its own cell.
        await tester.tapAt(tester.getCenter(_glyph(index)));
        await tester.pumpAndSettle();
        if (!reduced) {
          await _capture(tester, '320-all-tabs-$index-motion-selected');
        }
        _expectClearance(tester, index: index);
        _expectMinimumTargets(tester);
        _expectGlyphsUnchanged(tester, original);
        _expectRectUnchanged(originalBar, tester.getRect(_barClip));
        for (var cell = 0; cell < _labels.length; cell++) {
          _expectRectUnchanged(
            originalCells[cell]!,
            tester.getRect(_cell(cell)),
          );
        }
        _expectActivitySemantics(tester, value: 'New activity', index: index);
        expect(
          tester.widget<Semantics>(_cell(index)).properties.selected,
          isTrue,
        );
        expect(fixture.selections, [index]);
        expect(_selectionTicks(), 1);

        final neighbor = (index + 1) % _labels.length;
        final finger = await tester.startGesture(
          tester.getCenter(_cell(index)),
        );
        var released = false;
        try {
          await tester.pump(const Duration(milliseconds: 120));
          // Accept the real horizontal recognizer, then return to this actual
          // cell centre. Only the aligned samples claim ring-stroke clearance.
          await finger.moveTo(tester.getCenter(_cell(neighbor)));
          await tester.pump();
          await finger.moveTo(tester.getCenter(_cell(index)));
          await tester.pump();
          _expectClearance(tester, index: index);
          await tester.pump(const Duration(milliseconds: 110));
          await finger.moveTo(tester.getCenter(_cell(index)));
          await tester.pump();
          _expectClearance(tester, index: index);
          if (reduced) {
            expect(
              tester.getSize(_barClip).height,
              closeTo(ZyraNavBarMetrics.height, .001),
            );
          } else {
            expect(
              tester.getSize(_barClip).height,
              greaterThan(ZyraNavBarMetrics.restingHeight),
            );
            expect(
              tester.getSize(_barClip).height,
              lessThan(ZyraNavBarMetrics.height),
            );
          }
          await tester.pump(const Duration(milliseconds: 200));
          await finger.moveTo(tester.getCenter(_cell(index)));
          await tester.pump();
          _expectClearance(tester, index: index);
          _expectMinimumTargets(tester);
          expect(
            tester.getSize(_barClip).height,
            closeTo(ZyraNavBarMetrics.height, .001),
          );
          await finger.up();
          released = true;
          await tester.pumpAndSettle();
          _expectClearance(tester, index: index);
          _expectGlyphsUnchanged(tester, original);
          _expectRectUnchanged(originalBar, tester.getRect(_barClip));
        } finally {
          if (!released) await finger.cancel();
        }
        expect(fixture.selections, [index, neighbor, index]);
        // Only the earlier discrete tap ticks; swiping is silent (HAPTICS §2).
        expect(_selectionTicks(), 1);

        fixture.activity.value = (index: index, dot: false, badge: 0);
        await tester.pumpAndSettle();
        expect(_paintedGoldCircle(index), findsNothing);
        _expectActivitySemantics(tester, index: index);
        _expectGlyphsUnchanged(tester, original);
        _expectRectUnchanged(originalBar, tester.getRect(_barClip));
        _expectMinimumTargets(tester);
        expect(
          tester.widget<Semantics>(_cell(index)).properties.selected,
          isTrue,
        );
        expect(fixture.selections, [index, neighbor, index]);
        // Only the earlier discrete tap ticks; swiping is silent (HAPTICS §2).
        expect(_selectionTicks(), 1);
      });
    }
  }

  testWidgets('labelled nav gold glyph stays clear of its label', (
    tester,
  ) async {
    final fixture = _Fixture(selected: 2, showLabels: true);
    await _mount(tester, fixture);
    await _capture(tester, 'compat-show-labels-shoulder');
    _expectClearance(tester);
    final label = find.descendant(
      of: _cell(2),
      matching: find.text(_labels[2]),
    );
    expect(label, findsOneWidget);
    expect(tester.getRect(_glyph(2)).overlaps(tester.getRect(label)), isFalse);
    _expectActivitySemantics(tester, value: 'New activity');
    _expectMinimumTargets(tester);
    final original = _glyphRects(tester);
    final originalBar = tester.getRect(_barClip);
    fixture.activity.value = (index: 2, dot: false, badge: 0);
    await tester.pumpAndSettle();
    expect(_paintedGoldCircle(2), findsNothing);
    _expectActivitySemantics(tester);
    _expectGlyphsUnchanged(tester, original, showLabels: true);
    _expectRectUnchanged(originalBar, tester.getRect(_barClip));
    expect(fixture.selections, isEmpty);
    expect(_selectionTicks(), 0);
  });

  testWidgets('quiet-dot selection remains separate from unread gold glyph', (
    tester,
  ) async {
    ZyraInteractionStyle.selectNavStyle(ZyraNavStyle.quietDot);
    final fixture = _Fixture(selected: 2);
    await _mount(tester, fixture);
    await _capture(tester, 'compat-quiet-dot-shoulder');
    _expectClearance(tester);
    final marker = find.descendant(
      of: find.byType(ZyraNavHighlight),
      matching: find.byType(DecoratedBox),
    );
    expect(marker, findsOneWidget);
    final markerRect = tester.getRect(marker);
    _expectSquare(markerRect, 6);
    expect(tester.getRect(_glyph(2)).overlaps(markerRect), isFalse);
    _expectActivitySemantics(tester, value: 'New activity');
    _expectMinimumTargets(tester);
    final original = _glyphRects(tester);
    final originalBar = tester.getRect(_barClip);
    fixture.activity.value = (index: 2, dot: false, badge: 0);
    await tester.pumpAndSettle();
    expect(_paintedGoldCircle(2), findsNothing);
    _expectActivitySemantics(tester);
    _expectGlyphsUnchanged(tester, original);
    _expectRectUnchanged(originalBar, tester.getRect(_barClip));
    _expectRectUnchanged(markerRect, tester.getRect(marker));
    expect(fixture.selections, isEmpty);
    expect(_selectionTicks(), 0);
  });
}
