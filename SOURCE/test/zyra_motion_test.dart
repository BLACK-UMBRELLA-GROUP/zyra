import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_motion.dart';
import 'package:zyra/widgets/zyra_pull_down_back_scope.dart';
import 'package:zyra/widgets/zyra_swipe_track.dart';

const _trackKey = ValueKey('track');
const _listKey = ValueKey('list');

class _TestScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      ZyraMotion.scrollPhysics;
}

Future<void> _mountTrack(
  WidgetTester tester,
  List<int> settled, {
  bool reduceMotion = false,
  ZyraSwipeController? controller,
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: Center(
            child: SizedBox(
              width: 300,
              height: 160,
              child: ZyraSwipeTrack(
                key: _trackKey,
                controller: controller,
                index: 0,
                itemCount: 3,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: onTap,
                  child: ColoredBox(
                    color: Colors.white,
                    child: Center(child: Text('Card $index')),
                  ),
                ),
                onSettled: settled.add,
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

double _offset(WidgetTester tester) {
  final viewport = tester.widget<ClipRect>(
    find
        .descendant(of: find.byKey(_trackKey), matching: find.byType(ClipRect))
        .first,
  );
  final track = viewport.child! as Stack;
  final page = (track.children.first as KeyedSubtree).child as Transform;
  return page.transform.getTranslation().x;
}

Future<TestGesture> _move(
  WidgetTester tester,
  double distance, {
  required int sampleMilliseconds,
}) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(_trackKey)),
  );
  for (var step = 1; step <= 4; step++) {
    await gesture.moveBy(
      Offset(distance / 4, 0),
      timeStamp: Duration(milliseconds: step * sampleMilliseconds),
    );
  }
  await tester.pump();
  return gesture;
}

void main() {
  test('LOCK 26 V3 motion tokens and settle limits', () {
    expect(ZyraMotion.duration, const Duration(milliseconds: 420));
    expect(ZyraMotion.curve, const Cubic(.22, 1, .36, 1));
    expect(ZyraMotion.minimumSettleFraction, .60);
    expect(ZyraMotion.pageThreshold, .22);
    expect(ZyraMotion.flickDistance, 12);
    expect(ZyraMotion.flickSpeed, .45);
    expect(ZyraMotion.settleDuration(100, 0).inMilliseconds, 420);
    expect(ZyraMotion.settleDuration(100, 500).inMilliseconds, 320);
    expect(ZyraMotion.settleDuration(100, 2000).inMilliseconds, 252);
  });

  test('production code declares clamping only for locked fixed cards', () {
    final sites = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.endsWith('.dart') &&
              file.readAsStringSync().contains('ClampingScrollPhysics'),
        )
        .map((file) => file.path);
    expect(sites, unorderedEquals(['lib/theme/zyra_motion.dart']));
    expect(
      File('lib/theme/zyra_motion.dart').readAsStringSync(),
      contains('extends ClampingScrollPhysics'),
    );
  });

  testWidgets('slow swipe past 22% follows the finger and settles at 420 ms', (
    tester,
  ) async {
    final settled = <int>[];
    await _mountTrack(tester, settled);
    final drag = await _move(tester, -67, sampleMilliseconds: 30);
    expect(_offset(tester), closeTo(-67, .01));
    await drag.up(timeStamp: const Duration(milliseconds: 121));
    await tester.pump();
    expect(_offset(tester), closeTo(-67, .01));
    expect(settled, isEmpty);
    await tester.pump(const Duration(milliseconds: 419));
    expect(settled, isEmpty);
    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();
    expect(settled, [1]);
  });

  testWidgets('16 pt flick advances with a velocity-scaled settle', (
    tester,
  ) async {
    final settled = <int>[];
    await _mountTrack(tester, settled);
    final drag = await _move(tester, -16, sampleMilliseconds: 2);
    await drag.up(timeStamp: const Duration(milliseconds: 9));
    await tester.pump();
    expect(_offset(tester), closeTo(-16, .01));
    await tester.pump(const Duration(milliseconds: 251));
    expect(settled, isEmpty);
    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();
    expect(settled, [1]);
  });

  testWidgets('short slow swipe springs back and does not activate its tile', (
    tester,
  ) async {
    final settled = <int>[];
    var taps = 0;
    await _mountTrack(tester, settled, onTap: () => taps++);
    final drag = await _move(tester, -48, sampleMilliseconds: 30);
    await drag.up(timeStamp: const Duration(milliseconds: 121));
    await tester.pump();
    expect(_offset(tester), closeTo(-48, .01));
    await tester.pump(const Duration(milliseconds: 1));
    expect(_offset(tester), lessThan(-48)); // Finger was still moving outward.
    await tester.pumpAndSettle();
    expect(_offset(tester), 0);
    expect(settled, isEmpty);
    expect(taps, 0);
  });

  testWidgets('ends resist by 30% and never wrap', (tester) async {
    final settled = <int>[];
    await _mountTrack(tester, settled);
    final drag = await _move(tester, 100, sampleMilliseconds: 20);
    expect(_offset(tester), closeTo(30, .01));
    await drag.up(timeStamp: const Duration(milliseconds: 81));
    await tester.pumpAndSettle();
    expect(_offset(tester), 0);
    expect(settled, isEmpty);
  });

  testWidgets(
    'page controls use shared easing and Reduce Motion switches instantly',
    (tester) async {
      final settled = <int>[];
      final controller = ZyraSwipeController();
      await _mountTrack(tester, settled, controller: controller);
      controller.animateTo(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 210));
      expect(
        _offset(tester),
        closeTo(-324 * ZyraMotion.curve.transform(.5), .01),
      );
      expect(settled, isEmpty);
      await tester.pump(const Duration(milliseconds: 211));
      await tester.pump();
      expect(settled, [1]);

      await _mountTrack(
        tester,
        settled,
        controller: controller,
        reduceMotion: true,
      );
      controller.animateTo(1);
      expect(settled, [1, 1]);
      final drag = await _move(tester, -100, sampleMilliseconds: 30);
      expect(_offset(tester), 0);
      await drag.up(timeStamp: const Duration(milliseconds: 121));
      expect(settled, [1, 1, 1]);
    },
  );

  testWidgets('short lists stay still while edge Back still works', (
    tester,
  ) async {
    var backs = 0;
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: _TestScrollBehavior(),
        home: Scaffold(
          body: ZyraPullDownBackScope(
            routeIdentity: 'test',
            onBack: () => backs++,
            child: ListView(
              key: _listKey,
              physics: const ScrollPhysics(),
              children: const [SizedBox(height: 30)],
            ),
          ),
        ),
      ),
    );
    final position = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(_listKey),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    expect(position.maxScrollExtent, 0);
    for (final step in [40.0, -40.0]) {
      final drag = await tester.startGesture(
        tester.getCenter(find.byKey(_listKey)),
      );
      await drag.moveBy(Offset(0, step));
      await drag.moveBy(Offset(0, step));
      await tester.pump();
      expect(position.pixels, 0);
      await drag.up();
      await tester.pumpAndSettle();
      expect(position.pixels, 0);
    }
    expect(backs, 0);
    await tester.dragFrom(const Offset(2, 260), const Offset(290, 0));
    await tester.pumpAndSettle();
    expect(backs, 1);
  });
}
