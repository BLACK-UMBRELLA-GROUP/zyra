import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_scrollable_seeker_selector.dart';

class _SelectorFixture {
  _SelectorFixture(int count, {this.position = 0, bool longNames = false})
    : labels = List.generate(
        count,
        (index) => longNames
            ? 'Aaliyah Sumayyah Maryam Long Family Name $index'
            : 'Seeker $index',
      ),
      keys = List.generate(
        count,
        (index) => ValueKey('selector-person-$index'),
      );

  List<String> labels;
  List<Key> keys;
  double position;
  final changes = <int>[];
  late StateSetter rebuild;

  void select(int index) {
    rebuild(() {
      changes.add(index);
      position = index.toDouble();
    });
  }

  void moveOwnerTo(int index) {
    rebuild(() => position = index.toDouble());
  }
}

Future<void> _mount(
  WidgetTester tester,
  _SelectorFixture fixture, {
  TextDirection direction = TextDirection.ltr,
  bool reducedMotion = false,
  double textScale = 1,
  double width = 360,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reducedMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: width,
              child: StatefulBuilder(
                builder: (context, setState) {
                  fixture.rebuild = setState;
                  return Directionality(
                    textDirection: direction,
                    child: ZyraScrollableSeekerSelector(
                      labels: fixture.labels,
                      segmentKeys: fixture.keys,
                      position: fixture.position,
                      onChanged: fixture.select,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder get _selector => find.byType(ZyraScrollableSeekerSelector);
Finder get _highlight =>
    find.byKey(const ValueKey('seeker-selector-highlight'));
Finder get _strip => find
    .descendant(of: _selector, matching: find.byType(GestureDetector))
    .first;

double _slotWidth(WidgetTester tester, _SelectorFixture fixture) =>
    (tester.getSize(_selector).width - 6) / math.min(3, fixture.labels.length);

Future<TestGesture> _beginDrag(
  WidgetTester tester, {
  TextDirection direction = TextDirection.ltr,
}) async {
  final gesture = await tester.startGesture(tester.getCenter(_strip));
  await gesture.moveBy(
    Offset(direction == TextDirection.ltr ? -24 : 24, 0),
    timeStamp: const Duration(milliseconds: 100),
  );
  await tester.pump(const Duration(milliseconds: 100));
  return gesture;
}

Future<void> _step(
  WidgetTester tester,
  _SelectorFixture fixture, {
  int delta = 1,
  TextDirection direction = TextDirection.ltr,
  bool cancel = false,
}) async {
  final original = fixture.position;
  final changes = fixture.changes.length;
  final physicalSign = (direction == TextDirection.rtl ? 1 : -1) * delta.sign;
  final gesture = await _beginDrag(
    tester,
    direction: physicalSign < 0 ? TextDirection.ltr : TextDirection.rtl,
  );
  await gesture.moveBy(
    Offset(physicalSign * _slotWidth(tester, fixture) * .65, 0),
    timeStamp: const Duration(milliseconds: 400),
  );
  await tester.pump();
  expect(fixture.position, original);
  expect(fixture.changes, hasLength(changes));
  if (cancel) {
    await gesture.cancel();
  } else {
    await gesture.up(timeStamp: const Duration(milliseconds: 1000));
  }
  await tester.pumpAndSettle();
}

void _expectWholeNames(
  WidgetTester tester,
  _SelectorFixture fixture,
  List<int> indexes,
) {
  final capsule = tester.getRect(_selector).deflate(3);
  for (var index = 0; index < fixture.labels.length; index++) {
    final name = find.byKey(fixture.keys[index]);
    if (!indexes.contains(index)) {
      expect(name, findsNothing, reason: 'Name $index must not peek at rest');
      continue;
    }
    expect(name, findsOneWidget);
    final rect = tester.getRect(name);
    expect(rect.left, greaterThanOrEqualTo(capsule.left - .01));
    expect(rect.right, lessThanOrEqualTo(capsule.right + .01));
    expect(rect.width, closeTo(_slotWidth(tester, fixture), .01));
  }
}

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  for (final count in [1, 2, 3, 4, 10]) {
    testWidgets('$count Seekers show whole first and last name windows', (
      tester,
    ) async {
      final fixture = _SelectorFixture(count);
      await _mount(tester, fixture);
      final visible = math.min(3, count);
      _expectWholeNames(
        tester,
        fixture,
        count > 3
            ? [count - 1, 0, 1]
            : List.generate(visible, (index) => index),
      );
      expect(
        tester.getRect(_highlight).left,
        closeTo(tester.getRect(find.byKey(fixture.keys.first)).left, .01),
      );

      fixture.moveOwnerTo(count - 1);
      await tester.pump();
      _expectWholeNames(
        tester,
        fixture,
        count > 3
            ? [count - 2, count - 1, 0]
            : List.generate(visible, (index) => count - visible + index),
      );
      expect(
        tester.getRect(_highlight).left,
        closeTo(tester.getRect(find.byKey(fixture.keys.last)).left, .01),
      );
      expect(fixture.changes, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('highlight follows fractional dragging before owner changes', (
    tester,
  ) async {
    final fixture = _SelectorFixture(3);
    await _mount(tester, fixture);
    final gesture = await _beginDrag(tester);
    final before = tester.getRect(_highlight);
    final width = _slotWidth(tester, fixture);
    await gesture.moveBy(
      Offset(-width * .25, 0),
      timeStamp: const Duration(milliseconds: 300),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final after = tester.getRect(_highlight);
    expect(after.left - before.left, closeTo(width * .25, .01));
    expect(after.width, closeTo(before.width, .01));
    expect(fixture.position, 0);
    expect(fixture.changes, isEmpty);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('ten-name strip moves continuously through the middle', (
    tester,
  ) async {
    final fixture = _SelectorFixture(10, position: 5);
    await _mount(tester, fixture);
    _expectWholeNames(tester, fixture, [4, 5, 6]);
    final gesture = await _beginDrag(tester);
    final nameBefore = tester.getRect(find.byKey(fixture.keys[5]));
    final highlightBefore = tester.getRect(_highlight);
    final width = _slotWidth(tester, fixture);
    await gesture.moveBy(
      Offset(-width * .25, 0),
      timeStamp: const Duration(milliseconds: 300),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final nameAfter = tester.getRect(find.byKey(fixture.keys[5]));
    expect(nameAfter.left - nameBefore.left, closeTo(-width * .25, .01));
    expect(tester.getRect(_highlight).left, closeTo(highlightBefore.left, .01));
    expect(fixture.position, 5);
    expect(fixture.changes, isEmpty);
    await gesture.cancel();
    await tester.pumpAndSettle();
    _expectWholeNames(tester, fixture, [4, 5, 6]);
  });

  testWidgets('release commits once without a same-frame highlight jump', (
    tester,
  ) async {
    final fixture = _SelectorFixture(3);
    await _mount(tester, fixture);
    final gesture = await _beginDrag(tester);
    final width = _slotWidth(tester, fixture);
    await gesture.moveBy(
      Offset(-width * .65, 0),
      timeStamp: const Duration(milliseconds: 400),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(fixture.changes, isEmpty);
    final beforeRelease = tester.getRect(_highlight);
    await gesture.up(timeStamp: const Duration(milliseconds: 1000));
    await tester.pump();
    expect(fixture.changes, [1]);
    expect(fixture.position, 1);
    final onRelease = tester.getRect(_highlight);
    expect(onRelease.left, closeTo(beforeRelease.left, .01));
    expect(onRelease.width, closeTo(beforeRelease.width, .01));
    await tester.pumpAndSettle();
    expect(
      tester.getRect(_highlight).left,
      closeTo(tester.getRect(find.byKey(fixture.keys[1])).left, .01),
    );
    expect(fixture.changes, [1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reverse dragging moves highlight back before release', (
    tester,
  ) async {
    final fixture = _SelectorFixture(3);
    await _mount(tester, fixture);
    final gesture = await _beginDrag(tester);
    final width = _slotWidth(tester, fixture);
    await gesture.moveBy(
      Offset(-width * .65, 0),
      timeStamp: const Duration(milliseconds: 300),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final forward = tester.getRect(_highlight);
    await gesture.moveBy(
      Offset(width * .35, 0),
      timeStamp: const Duration(milliseconds: 600),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.getRect(_highlight).left - forward.left,
      closeTo(-width * .35, .01),
    );
    expect(fixture.position, 0);
    expect(fixture.changes, isEmpty);
    await gesture.moveBy(
      Offset(width * .3, 0),
      timeStamp: const Duration(milliseconds: 850),
    );
    await tester.pump();
    await gesture.up(timeStamp: const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();
    expect(fixture.changes, [0]);
    expect(fixture.position, 0);
  });

  testWidgets('middle-window names do not jump when release changes owner', (
    tester,
  ) async {
    final fixture = _SelectorFixture(10, position: 4);
    await _mount(tester, fixture);
    final gesture = await _beginDrag(tester);
    await gesture.moveBy(
      Offset(-_slotWidth(tester, fixture) * .65, 0),
      timeStamp: const Duration(milliseconds: 400),
    );
    await tester.pump();
    final before = tester.getRect(find.byKey(fixture.keys[5]));
    expect(fixture.position, 4);
    expect(fixture.changes, isEmpty);
    await gesture.up(timeStamp: const Duration(milliseconds: 1000));
    await tester.pump();
    expect(fixture.changes, [5]);
    expect(fixture.position, 5);
    expect(
      tester.getRect(find.byKey(fixture.keys[5])).left,
      closeTo(before.left, .01),
    );
    await tester.pumpAndSettle();
    _expectWholeNames(tester, fixture, [4, 5, 6]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a visible name commits that person once', (
    tester,
  ) async {
    final fixture = _SelectorFixture(10);
    await _mount(tester, fixture);
    await tester.tap(find.byKey(fixture.keys[1]));
    await tester.pumpAndSettle();
    expect(fixture.changes, [1]);
    expect(fixture.position, 1);
    _expectWholeNames(tester, fixture, [0, 1, 2]);
    expect(
      tester.getRect(_highlight).left,
      closeTo(tester.getRect(find.byKey(fixture.keys[1])).left, .01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel returns to current owner without committing', (
    tester,
  ) async {
    final fixture = _SelectorFixture(4, position: 1);
    await _mount(tester, fixture);
    final original = tester.getRect(_highlight);
    final gesture = await _beginDrag(tester);
    await gesture.moveBy(
      Offset(-_slotWidth(tester, fixture) * .7, 0),
      timeStamp: const Duration(milliseconds: 400),
    );
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(fixture.position, 1);
    expect(fixture.changes, isEmpty);
    expect(tester.getRect(_highlight).left, closeTo(original.left, .01));
    _expectWholeNames(tester, fixture, [0, 1, 2]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changed roster keys invalidate a gesture selecting old people', (
    tester,
  ) async {
    final fixture = _SelectorFixture(10, position: 8);
    await _mount(tester, fixture);
    final gesture = await _beginDrag(tester);
    await gesture.moveBy(
      Offset(-_slotWidth(tester, fixture) * .6, 0),
      timeStamp: const Duration(milliseconds: 400),
    );
    await tester.pump();
    fixture.rebuild(() {
      fixture.labels = ['New Seeker A', 'New Seeker B'];
      fixture.keys = [
        const ValueKey('new-person-a'),
        const ValueKey('new-person-b'),
      ];
      fixture.position = 0;
    });
    await tester.pump();
    await gesture.up(timeStamp: const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    expect(fixture.changes, isEmpty);
    expect(fixture.position, 0);
    _expectWholeNames(tester, fixture, [0, 1]);
    expect(
      tester.getRect(_highlight).left,
      closeTo(tester.getRect(find.byKey(fixture.keys.first)).left, .01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL dragging mirrors movement and commits the intended person', (
    tester,
  ) async {
    final fixture = _SelectorFixture(4);
    await _mount(tester, fixture, direction: TextDirection.rtl);
    _expectWholeNames(tester, fixture, [3, 0, 1]);
    expect(
      tester.getRect(find.byKey(fixture.keys[0])).left,
      greaterThan(tester.getRect(find.byKey(fixture.keys[1])).left),
    );
    final gesture = await _beginDrag(tester, direction: TextDirection.rtl);
    final before = tester.getRect(find.byKey(fixture.keys[0]));
    final highlightBefore = tester.getRect(_highlight);
    final width = _slotWidth(tester, fixture);
    await gesture.moveBy(
      Offset(width * .65, 0),
      timeStamp: const Duration(milliseconds: 400),
    );
    await tester.pump();
    expect(
      tester.getRect(find.byKey(fixture.keys[0])).left - before.left,
      closeTo(width * .65, .01),
    );
    expect(tester.getRect(_highlight).left, closeTo(highlightBefore.left, .01));
    expect(fixture.changes, isEmpty);
    await gesture.up(timeStamp: const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();
    expect(fixture.changes, [1]);
    expect(
      tester.getRect(_highlight).left,
      closeTo(tester.getRect(find.byKey(fixture.keys[1])).left, .01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reduced motion settles on release without animated intermediate frames',
    (tester) async {
      final fixture = _SelectorFixture(4);
      await _mount(tester, fixture, reducedMotion: true);
      final gesture = await _beginDrag(tester);
      await gesture.moveBy(
        Offset(-_slotWidth(tester, fixture) * .65, 0),
        timeStamp: const Duration(milliseconds: 400),
      );
      await tester.pump();
      expect(fixture.changes, isEmpty);
      await gesture.up(timeStamp: const Duration(milliseconds: 1000));
      await tester.pump();
      expect(fixture.changes, [1]);
      expect(
        tester.getRect(_highlight).left,
        closeTo(tester.getRect(find.byKey(fixture.keys[1])).left, .01),
      );
      _expectWholeNames(tester, fixture, [0, 1, 2]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('320px screen with doubled text and long names has no overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = _SelectorFixture(10, longNames: true);
    await _mount(tester, fixture, width: 320, textScale: 2);
    _expectWholeNames(tester, fixture, [9, 0, 1]);
    expect(tester.takeException(), isNull);
    final texts = tester.widgetList<Text>(
      find.descendant(of: _selector, matching: find.byType(Text)),
    );
    expect(texts.every((text) => text.maxLines == 1), isTrue);
    expect(
      texts.every((text) => text.overflow == TextOverflow.ellipsis),
      isTrue,
    );
    fixture.moveOwnerTo(9);
    await tester.pump();
    _expectWholeNames(tester, fixture, [8, 9, 0]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('forward from last wraps to first using the next logical index', (
    tester,
  ) async {
    final fixture = _SelectorFixture(10, position: 9);
    await _mount(tester, fixture);
    _expectWholeNames(tester, fixture, [8, 9, 0]);
    await _step(tester, fixture);
    expect(fixture.changes, [10]);
    expect(fixture.position, 10);
    expect(fixture.position.toInt() % fixture.labels.length, 0);
    _expectWholeNames(tester, fixture, [9, 0, 1]);
    expect(
      tester.getRect(_highlight).left,
      closeTo(tester.getRect(find.byKey(fixture.keys[0])).left, .01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('backward from first wraps to last with negative logical index', (
    tester,
  ) async {
    final fixture = _SelectorFixture(10);
    await _mount(tester, fixture);
    _expectWholeNames(tester, fixture, [9, 0, 1]);
    await _step(tester, fixture, delta: -1);
    expect(fixture.changes, [-1]);
    expect(fixture.position, -1);
    expect(fixture.position.toInt() % fixture.labels.length, 9);
    _expectWholeNames(tester, fixture, [8, 9, 0]);
    expect(
      tester.getRect(_highlight).left,
      closeTo(tester.getRect(find.byKey(fixture.keys[9])).left, .01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'multiple forward and backward cycles retain unwrapped positions',
    (tester) async {
      final fixture = _SelectorFixture(4);
      await _mount(tester, fixture);
      for (var logical = 1; logical <= 12; logical++) {
        await _step(tester, fixture);
        expect(fixture.position, logical);
        expect(fixture.changes.last, logical);
        _expectWholeNames(tester, fixture, [
          (logical - 1) % 4,
          logical % 4,
          (logical + 1) % 4,
        ]);
        expect(tester.takeException(), isNull);
      }
      for (var logical = 11; logical >= -5; logical--) {
        await _step(tester, fixture, delta: -1);
        expect(fixture.position, logical);
        expect(fixture.changes.last, logical);
        _expectWholeNames(tester, fixture, [
          (logical - 1) % 4,
          logical % 4,
          (logical + 1) % 4,
        ]);
        expect(tester.takeException(), isNull);
      }
      expect(fixture.changes, hasLength(29));
    },
  );

  testWidgets('cancel across a wrapped edge preserves the original person', (
    tester,
  ) async {
    final fixture = _SelectorFixture(10);
    await _mount(tester, fixture);
    await _step(tester, fixture, delta: -1, cancel: true);
    expect(fixture.position, 0);
    expect(fixture.changes, isEmpty);
    _expectWholeNames(tester, fixture, [9, 0, 1]);
    fixture.moveOwnerTo(9);
    await tester.pump();
    await _step(tester, fixture, cancel: true);
    expect(fixture.position, 9);
    expect(fixture.changes, isEmpty);
    _expectWholeNames(tester, fixture, [8, 9, 0]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tapping wrapped neighbours uses their nearest logical position',
    (tester) async {
      final fixture = _SelectorFixture(10);
      await _mount(tester, fixture);
      await tester.tap(find.byKey(fixture.keys[9]));
      await tester.pumpAndSettle();
      expect(fixture.changes, [-1]);
      expect(fixture.position, -1);
      _expectWholeNames(tester, fixture, [8, 9, 0]);
      await tester.tap(find.byKey(fixture.keys[0]));
      await tester.pumpAndSettle();
      expect(fixture.changes, [-1, 0]);
      expect(fixture.position, 0);
      _expectWholeNames(tester, fixture, [9, 0, 1]);
      fixture.moveOwnerTo(9);
      await tester.pump();
      await tester.tap(find.byKey(fixture.keys[0]));
      await tester.pumpAndSettle();
      expect(fixture.changes, [-1, 0, 10]);
      expect(fixture.position, 10);
      _expectWholeNames(tester, fixture, [9, 0, 1]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('RTL wrapping preserves continuous logical order', (
    tester,
  ) async {
    final fixture = _SelectorFixture(10, position: 9);
    await _mount(tester, fixture, direction: TextDirection.rtl);
    await _step(tester, fixture, direction: TextDirection.rtl);
    expect(fixture.changes, [10]);
    _expectWholeNames(tester, fixture, [9, 0, 1]);
    expect(
      tester.getRect(find.byKey(fixture.keys[9])).left,
      greaterThan(tester.getRect(find.byKey(fixture.keys[0])).left),
    );
    expect(
      tester.getRect(find.byKey(fixture.keys[0])).left,
      greaterThan(tester.getRect(find.byKey(fixture.keys[1])).left),
    );
    await _step(tester, fixture, direction: TextDirection.rtl, delta: -1);
    expect(fixture.changes, [10, 9]);
    _expectWholeNames(tester, fixture, [8, 9, 0]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'four-person cyclic windows keep unique keys at large positions',
    (tester) async {
      final fixture = _SelectorFixture(4, position: 1000000);
      await _mount(tester, fixture);
      _expectWholeNames(tester, fixture, [3, 0, 1]);
      for (final position in [1000000.25, -1000000.25]) {
        fixture.rebuild(() => fixture.position = position);
        await tester.pump();
        for (final key in fixture.keys) {
          expect(find.byKey(key), findsOneWidget);
        }
        for (final label in fixture.labels) {
          expect(find.text(label), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
      fixture.moveOwnerTo(-1000001);
      await tester.pump();
      _expectWholeNames(tester, fixture, [2, 3, 0]);
      expect(fixture.changes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  for (final count in [1, 2, 3]) {
    testWidgets('$count-person selector remains bounded at both ends', (
      tester,
    ) async {
      final fixture = _SelectorFixture(count, position: (count - 1).toDouble());
      await _mount(tester, fixture);
      await _step(tester, fixture);
      expect(fixture.changes, [count - 1]);
      fixture.moveOwnerTo(0);
      await tester.pump();
      await _step(tester, fixture, delta: -1);
      expect(fixture.changes, [count - 1, 0]);
      expect(fixture.position, 0);
      _expectWholeNames(
        tester,
        fixture,
        List.generate(count, (index) => index),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('partially visible moving edge names stay out of semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      final fixture = _SelectorFixture(10, position: 1);
      await _mount(tester, fixture);
      expect(find.semantics.byLabel('Seeker 0'), findsOneWidget);
      expect(find.semantics.byLabel('Seeker 3'), findsNothing);
      final gesture = await _beginDrag(tester);
      await gesture.moveBy(
        Offset(-_slotWidth(tester, fixture) * .35, 0),
        timeStamp: const Duration(milliseconds: 400),
      );
      await tester.pump();
      expect(find.byKey(fixture.keys[0]), findsOneWidget);
      expect(find.byKey(fixture.keys[3]), findsOneWidget);
      expect(find.semantics.byLabel('Seeker 0'), findsNothing);
      expect(find.semantics.byLabel('Seeker 3'), findsNothing);
      expect(find.semantics.byLabel('Seeker 1'), findsOneWidget);
      expect(find.semantics.byLabel('Seeker 2'), findsOneWidget);
      expect(fixture.changes, isEmpty);
      await gesture.cancel();
      await tester.pumpAndSettle();
      expect(find.semantics.byLabel('Seeker 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
