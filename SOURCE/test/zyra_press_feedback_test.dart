import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/widgets/zyra_press_feedback.dart';

const _feedbackKey = ValueKey('press-feedback');
const _actionKey = ValueKey('original-action');
const _semanticsKey = ValueKey('original-action-semantics');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final platformCalls = <MethodCall>[];
  var presses = 0;

  Widget subject({
    bool enabled = true,
    bool disableAnimations = false,
    bool accessibleNavigation = false,
  }) => MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: disableAnimations,
        accessibleNavigation: accessibleNavigation,
      ),
      child: child!,
    ),
    home: Scaffold(
      body: Center(
        child: ZyraPressFeedback(
          key: _feedbackKey,
          enabled: enabled,
          child: Semantics(
            key: _semanticsKey,
            label: 'Request a Journey',
            button: true,
            child: GestureDetector(
              key: _actionKey,
              behavior: HitTestBehavior.opaque,
              onTap: () => presses++,
              child: const SizedBox(
                width: 180,
                height: 56,
                child: Center(child: Text('Journey')),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  AnimatedScale animation(WidgetTester tester) => tester.widget<AnimatedScale>(
    find.descendant(
      of: find.byKey(_feedbackKey),
      matching: find.byType(AnimatedScale),
    ),
  );

  double currentScale(WidgetTester tester) => tester
      .widget<ScaleTransition>(
        find.descendant(
          of: find.byKey(_feedbackKey),
          matching: find.byType(ScaleTransition),
        ),
      )
      .scale
      .value;

  setUp(() {
    presses = 0;
    platformCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
  });

  tearDown(() {
    expect(
      platformCalls.where((call) => call.method == 'HapticFeedback.vibrate'),
      isEmpty,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('pointer down and up animate feedback without action authority', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_actionKey)),
    );
    await tester.pump();
    expect(presses, 0);
    expect(animation(tester).scale, .985);
    expect(animation(tester).duration, const Duration(milliseconds: 90));
    expect(animation(tester).curve, Curves.easeOutCubic);
    await tester.pump(const Duration(milliseconds: 45));
    expect(currentScale(tester), inExclusiveRange(.985, 1));
    await tester.pumpAndSettle();
    expect(currentScale(tester), closeTo(.985, .0001));
    expect(presses, 0);
    await gesture.up();
    await tester.pump();
    expect(animation(tester).scale, 1);
    expect(animation(tester).duration, const Duration(milliseconds: 180));
    expect(presses, 1);
    await tester.pumpAndSettle();
    expect(currentScale(tester), 1);
    expect(presses, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pointer cancellation restores scale without invoking the child',
    (tester) async {
      await tester.pumpWidget(subject());
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_actionKey)),
      );
      await tester.pumpAndSettle();
      expect(currentScale(tester), closeTo(.985, .0001));
      await gesture.cancel();
      await tester.pump();
      expect(animation(tester).scale, 1);
      expect(animation(tester).duration, const Duration(milliseconds: 180));
      await tester.pumpAndSettle();
      expect(currentScale(tester), 1);
      expect(presses, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final quiet in const [
    (enabled: false, disable: false, accessible: false),
    (enabled: true, disable: true, accessible: false),
    (enabled: true, disable: false, accessible: true),
    (enabled: true, disable: true, accessible: true),
  ]) {
    testWidgets(
      'quiet ${quiet.enabled}/${quiet.disable}/${quiet.accessible} keeps the original action',
      (tester) async {
        await tester.pumpWidget(
          subject(
            enabled: quiet.enabled,
            disableAnimations: quiet.disable,
            accessibleNavigation: quiet.accessible,
          ),
        );
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(_actionKey)),
        );
        await tester.pumpAndSettle();
        expect(animation(tester).scale, 1);
        expect(animation(tester).duration, Duration.zero);
        expect(currentScale(tester), 1);
        expect(presses, 0);
        await gesture.up();
        await tester.pumpAndSettle();
        expect(currentScale(tester), 1);
        expect(presses, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('ordinary tap invokes the original child exactly once', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    await tester.tap(find.byKey(_actionKey));
    await tester.pumpAndSettle();
    expect(presses, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(presses, 1);
    expect(currentScale(tester), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('layout bounds and the original semantic target stay intact', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(subject());
      final frameBounds = tester.getRect(find.byKey(_feedbackKey));
      final childSize = tester.getSize(find.byKey(_actionKey));
      expect(childSize, const Size(180, 56));
      expect(frameBounds.size, childSize);
      final original = tester.getSemantics(find.byKey(_semanticsKey));
      expect(original.label, 'Request a Journey\nJourney');
      expect(
        original.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      expect(original.flagsCollection.isButton, isTrue);
      final gesture = await tester.startGesture(frameBounds.center);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(_feedbackKey)), frameBounds);
      expect(tester.getSize(find.byKey(_actionKey)), childSize);
      final during = tester.getSemantics(find.byKey(_semanticsKey));
      expect(during.label, original.label);
      expect(during.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      expect(during.flagsCollection.isButton, isTrue);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(_feedbackKey)), frameBounds);
      expect(tester.getSize(find.byKey(_actionKey)), childSize);
      expect(presses, 1);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('secondary mouse press cannot animate or invoke the child', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    final gesture = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryButton,
    );
    await gesture.down(tester.getCenter(find.byKey(_actionKey)));
    await tester.pumpAndSettle();
    expect(animation(tester).scale, 1);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(presses, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabling while pressed immediately clears pending feedback', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_actionKey)),
    );
    await tester.pumpAndSettle();
    expect(currentScale(tester), closeTo(.985, .0001));
    await tester.pumpWidget(subject(enabled: false));
    await tester.pumpAndSettle();
    expect(animation(tester).scale, 1);
    expect(currentScale(tester), 1);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(presses, 0);
    expect(tester.takeException(), isNull);
  });

  for (final quiet in const [
    (disable: true, accessible: false),
    (disable: false, accessible: true),
  ]) {
    for (final releasing in [false, true]) {
      testWidgets(
        'quiet ${quiet.disable}/${quiet.accessible} interrupts ${releasing ? "release" : "press"} without changing the child action',
        (tester) async {
          await tester.pumpWidget(subject());
          final bounds = tester.getRect(find.byKey(_feedbackKey));
          final gesture = await tester.startGesture(bounds.center);
          await tester.pumpAndSettle();
          expect(currentScale(tester), closeTo(.985, .0001));
          expect(presses, 0);
          if (releasing) {
            await gesture.up();
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 45));
            expect(currentScale(tester), inExclusiveRange(.985, 1));
            expect(presses, 1);
          }
          await tester.pumpWidget(
            subject(
              disableAnimations: quiet.disable,
              accessibleNavigation: quiet.accessible,
            ),
          );
          // Check the very first quiet paint, not merely the settled result.
          expect(animation(tester).scale, 1);
          expect(animation(tester).duration, Duration.zero);
          expect(currentScale(tester), 1);
          expect(tester.getRect(find.byKey(_feedbackKey)), bounds);
          expect(tester.getSize(find.byKey(_actionKey)), bounds.size);
          expect(presses, releasing ? 1 : 0);
          if (!releasing) await gesture.up();
          await tester.pumpAndSettle();
          expect(currentScale(tester), 1);
          expect(presses, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('disposal with a pending pointer leaves no delayed action', (
    tester,
  ) async {
    await tester.pumpWidget(subject());
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_actionKey)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpWidget(const SizedBox.shrink());
    await gesture.cancel();
    await tester.pump(const Duration(seconds: 1));
    expect(presses, 0);
    expect(tester.takeException(), isNull);
  });
}
