import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/widgets/zyra_onboarding_edge_swipe.dart';

const _edge = ValueKey('edge_swipe_fixture');

Widget _fixture({
  required ScrollController controller,
  required VoidCallback onForward,
  VoidCallback? onBackward,
  bool enabled = true,
  double contentHeight = 260,
  ScrollPhysics physics = const ClampingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  ),
  Key key = _edge,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 280,
        height: 300,
        child: ZyraOnboardingEdgeSwipe(
          key: key,
          controller: controller,
          enabled: enabled,
          onForward: onForward,
          onBackward: onBackward,
          child: SingleChildScrollView(
            controller: controller,
            physics: physics,
            child: Container(
              height: contentHeight,
              color: Colors.purple,
              alignment: Alignment.center,
              child: const Text('Read-only introduction'),
            ),
          ),
        ),
      ),
    ),
  ),
);

Future<TestGesture> _heldDrag(
  WidgetTester tester,
  Offset delta, {
  int pointer = 1,
}) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byType(ZyraOnboardingEdgeSwipe)),
    pointer: pointer,
  );
  await gesture.moveBy(delta / 2);
  await tester.pump(const Duration(milliseconds: 16));
  await gesture.moveBy(delta / 2);
  await tester.pump(const Duration(milliseconds: 16));
  return gesture;
}

void main() {
  testWidgets('fitted clamped page stays still until a released swipe', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var forwards = 0;
    await tester.pumpWidget(
      _fixture(controller: controller, onForward: () => forwards++),
    );
    final gesture = await _heldDrag(tester, const Offset(0, -90));
    expect(controller.offset, 0);
    expect(forwards, 0);
    await gesture.up();
    expect(forwards, 0);
    await tester.pump();
    expect(forwards, 1);
    expect(controller.position.isScrollingNotifier.value, isFalse);
    expect(controller.position.outOfRange, isFalse);
  });

  testWidgets('handoff stops outgoing bounce before invoking navigation', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var forwards = 0;
    await tester.pumpWidget(
      _fixture(
        controller: controller,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        onForward: () {
          forwards++;
          expect(controller.position.outOfRange, isFalse);
          expect(controller.position.isScrollingNotifier.value, isFalse);
          expect(controller.offset, 0);
        },
      ),
    );
    final gesture = await _heldDrag(tester, const Offset(0, -90));
    expect(controller.position.outOfRange, isTrue);
    await gesture.up();
    expect(forwards, 0);
    await tester.pump();
    expect(forwards, 1);
    await tester.pumpAndSettle();
    expect(forwards, 1);
  });

  testWidgets('second release before dispatch cannot queue a second handoff', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var forwards = 0;
    await tester.pumpWidget(
      _fixture(controller: controller, onForward: () => forwards++),
    );
    final first = await _heldDrag(tester, const Offset(0, -90));
    await first.up();
    final second = await tester.startGesture(
      tester.getCenter(find.byKey(_edge)),
      pointer: 2,
    );
    await second.moveBy(const Offset(0, -90));
    await second.up();
    await tester.pumpAndSettle();
    expect(forwards, 1);
  });

  testWidgets('overflow must be read before a fresh edge swipe advances', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var forwards = 0;
    await tester.pumpWidget(
      _fixture(
        controller: controller,
        contentHeight: 1000,
        onForward: () => forwards++,
      ),
    );
    controller.jumpTo(500);
    final reading = await _heldDrag(tester, const Offset(0, -90));
    controller.jumpTo(controller.position.maxScrollExtent);
    await reading.up();
    await tester.pumpAndSettle();
    expect(forwards, 0);
    final advance = await _heldDrag(tester, const Offset(0, -90));
    await advance.up();
    await tester.pumpAndSettle();
    expect(forwards, 1);
  });

  testWidgets('backward swipe requires starting at the top edge', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var backwards = 0;
    await tester.pumpWidget(
      _fixture(
        controller: controller,
        contentHeight: 1000,
        onForward: () {},
        onBackward: () => backwards++,
      ),
    );
    controller.jumpTo(300);
    final reading = await _heldDrag(tester, const Offset(0, 90));
    await reading.up();
    await tester.pumpAndSettle();
    expect(backwards, 0);
    controller.jumpTo(0);
    final back = await _heldDrag(tester, const Offset(0, 90));
    await back.up();
    await tester.pumpAndSettle();
    expect(backwards, 1);
  });

  testWidgets(
    'short horizontal cancelled and multi-touch drags do not advance',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var forwards = 0;
      await tester.pumpWidget(
        _fixture(controller: controller, onForward: () => forwards++),
      );
      for (final delta in [const Offset(0, -40), const Offset(110, -90)]) {
        final gesture = await _heldDrag(tester, delta);
        await gesture.up();
        await tester.pumpAndSettle();
      }
      final cancelled = await _heldDrag(tester, const Offset(0, -90));
      await cancelled.cancel();
      await tester.pumpAndSettle();
      final first = await _heldDrag(tester, const Offset(0, -90));
      final second = await tester.startGesture(
        tester.getCenter(find.byKey(_edge)),
        pointer: 2,
      );
      await second.up();
      await first.up();
      await tester.pumpAndSettle();
      expect(forwards, 0);
    },
  );

  testWidgets('disabling cancels held and queued gestures before re-enabling', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var forwards = 0;
    void callback() => forwards++;
    await tester.pumpWidget(
      _fixture(controller: controller, onForward: callback),
    );
    final held = await _heldDrag(tester, const Offset(0, -90));
    await tester.pumpWidget(
      _fixture(controller: controller, onForward: callback, enabled: false),
    );
    await held.up();
    await tester.pump();
    expect(forwards, 0);
    await tester.pumpWidget(
      _fixture(controller: controller, onForward: callback),
    );
    final queued = await _heldDrag(tester, const Offset(0, -90));
    await queued.up();
    await tester.pumpWidget(
      _fixture(controller: controller, onForward: callback, enabled: false),
    );
    expect(forwards, 0);
    await tester.pumpWidget(
      _fixture(controller: controller, onForward: callback),
    );
    final fresh = await _heldDrag(tester, const Offset(0, -90));
    await fresh.up();
    await tester.pumpAndSettle();
    expect(forwards, 1);
  });

  testWidgets('controller replacement cancels queued navigation', (
    tester,
  ) async {
    final original = ScrollController();
    final replacement = ScrollController();
    addTearDown(original.dispose);
    addTearDown(replacement.dispose);
    var forwards = 0;
    void callback() => forwards++;
    await tester.pumpWidget(
      _fixture(controller: original, onForward: callback),
    );
    final queued = await _heldDrag(tester, const Offset(0, -90));
    await queued.up();
    await tester.pumpWidget(
      _fixture(controller: replacement, onForward: callback),
    );
    expect(forwards, 0);
    final fresh = await _heldDrag(tester, const Offset(0, -90));
    await fresh.up();
    await tester.pumpAndSettle();
    expect(forwards, 1);
  });

  testWidgets('page identity replacement cancels queued navigation', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var forwards = 0;
    void callback() => forwards++;
    await tester.pumpWidget(
      _fixture(controller: controller, onForward: callback),
    );
    final queued = await _heldDrag(tester, const Offset(0, -90));
    await queued.up();
    await tester.pumpWidget(
      _fixture(
        controller: controller,
        onForward: callback,
        key: const ValueKey('replacement_page'),
      ),
    );
    expect(forwards, 0);
    final fresh = await _heldDrag(tester, const Offset(0, -90));
    await fresh.up();
    await tester.pumpAndSettle();
    expect(forwards, 1);
  });

  testWidgets('disposal cancels a queued handoff without a callback or error', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var forwards = 0;
    await tester.pumpWidget(
      _fixture(controller: controller, onForward: () => forwards++),
    );
    final queued = await _heldDrag(tester, const Offset(0, -90));
    await queued.up();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(forwards, 0);
    expect(tester.takeException(), isNull);
  });
}
