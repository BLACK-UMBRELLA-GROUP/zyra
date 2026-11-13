import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'baseline_capture_support.dart';

const _evidenceDir = String.fromEnvironment('ZYRA_LOCK26_V4_EVIDENCE_DIR');
const _myZyraScrollKey = PageStorageKey('my-zyra-focus-scroll');
const _settingsScrollKey = ValueKey('concept-current-settings-scroll');
final _ios = TargetPlatformVariant.only(TargetPlatform.iOS);

BaselineHarness _harness(WidgetTester tester, String group) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return BaselineHarness(
    tester,
    group: group,
    outputRoot: _evidenceDir,
    evidenceRoot: _evidenceDir,
    flatOutput: true,
  );
}

ScrollPosition _position(WidgetTester tester, Finder owner) => tester
    .state<ScrollableState>(
      find.descendant(of: owner, matching: find.byType(Scrollable)),
    )
    .position;

Future<TestGesture> _drag(
  WidgetTester tester,
  Finder owner,
  double step,
) async {
  final gesture = await tester.startGesture(tester.getCenter(owner));
  await gesture.moveBy(Offset(0, step));
  await gesture.moveBy(Offset(0, step));
  await gesture.moveBy(Offset(0, step));
  await tester.pump();
  return gesture;
}

Future<void> _capture(
  BaselineHarness harness,
  String page,
  String state,
) async {
  if (_evidenceDir.isEmpty) return;
  await harness.capture(
    'app_swipe',
    page,
    state,
    'Offline Founder preview with the production scroll behavior.',
  );
}

void main() {
  setUpAll(
    () => baselineSetUp(
      evidenceRoot: _evidenceDir.isEmpty ? null : _evidenceDir,
      useSystemSymbolFont: Platform.isMacOS,
    ),
  );
  tearDownAll(baselineTearDown);

  for (final guardian in [false, true]) {
    final role = guardian ? 'guardian' : 'seeker';
    testWidgets('$role My ZYRA stays still during vertical drags', (
      tester,
    ) async {
      final harness = _harness(tester, role);
      await harness.mount(guardian: guardian, tab: 2, receivedRequest: false);
      expect(find.text('ALL CAUGHT UP'), findsOneWidget);
      final message = find.text('Nothing needs you right now.');
      expect(message, findsOneWidget);

      final owner = find.byKey(_myZyraScrollKey);
      final position = _position(tester, owner);
      expect(position.maxScrollExtent, position.minScrollExtent);
      final restingOffset = position.pixels;
      final restingMessage = tester.getTopLeft(message);
      await _capture(harness, '${role}_my_zyra', 'rest');

      for (final (step, direction) in [(40.0, 'down'), (-40.0, 'up')]) {
        final gesture = await _drag(tester, owner, step);
        expect(position.pixels, restingOffset);
        expect(tester.getTopLeft(message), restingMessage);
        await _capture(harness, '${role}_my_zyra', 'drag_$direction');
        await gesture.up();
        await tester.pumpAndSettle();
        expect(position.pixels, restingOffset);
      }
    }, variant: _ios);
  }

  testWidgets('long Settings scrolls and bounces at both ends', (tester) async {
    final harness = _harness(tester, 'settings');
    await harness.mount(tab: 4, pages: ['settings']);
    harness.assertPage('settings');
    final owner = find.byKey(_settingsScrollKey);
    final position = _position(tester, owner);
    final top = position.minScrollExtent;
    final bottom = position.maxScrollExtent;
    expect(bottom, greaterThan(top));
    expect(position.pixels, top);

    await _capture(harness, 'settings', 'top_rest');
    final topDrag = await _drag(tester, owner, 40);
    expect(position.pixels, lessThan(top));
    await _capture(harness, 'settings', 'top_drag');
    await topDrag.up();
    await tester.pumpAndSettle();
    expect(position.pixels, closeTo(top, .01));

    final scrollDrag = await _drag(tester, owner, -20);
    expect(position.pixels, greaterThan(top));
    await scrollDrag.up();
    await tester.pumpAndSettle();

    position.jumpTo(bottom);
    await tester.pump();
    await _capture(harness, 'settings', 'bottom_rest');
    final bottomDrag = await _drag(tester, owner, -40);
    expect(position.pixels, greaterThan(bottom));
    await _capture(harness, 'settings', 'bottom_drag');
    await bottomDrag.up();
    await tester.pumpAndSettle();
    expect(position.pixels, closeTo(bottom, .01));
  }, variant: _ios);
}
