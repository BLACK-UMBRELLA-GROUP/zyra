import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'baseline_capture_support.dart';

const _root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const _evidence = '$_root/REPORTS/EVIDENCE/LOCK22_SAFETY_ADVICE_V5_2026-10-31';
const _capture = bool.fromEnvironment('ZYRA_LOCK22_V5_CAPTURE');

Future<void> _cap(BaselineHarness h, String name) async {
  if (!_capture) return;
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  void repaint(RenderObject node) {
    node.markNeedsPaint();
    node.visitChildren(repaint);
  }

  try {
    repaint(
      h.tester.renderObject(
        find.byKey(const ValueKey('zyra-founder-baseline-boundary')),
      ),
    );
    await h.tester.pump();
    await h.capture(
      'safety_v5',
      name,
      name,
      'Actual Seeker Profile → Safety & advice route; bundled fonts, offline samples.',
      fileName: '$name.png',
    );
  } finally {
    debugDisableShadows = previous;
  }
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  for (final sample in [
    (scale: 1.0, narrow: false),
    (scale: 2.0, narrow: false),
    (scale: 2.0, narrow: true),
  ]) {
    testWidgets(
      'V5 actual advice: scale=${sample.scale}, narrow=${sample.narrow}',
      (t) async {
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final h = BaselineHarness(
          t,
          group: 'safety_v5_${sample.scale}_${sample.narrow}',
          outputRoot: '$_root/PRODUCT/APPROVED/UNITY_PASS/BUILT/V5',
          evidenceRoot: _evidence,
          flatOutput: true,
          textScale: sample.scale,
        );
        await h.mount(tab: 4);
        if (sample.narrow) {
          t.view.physicalSize = const Size(960, 1704);
          await h.flush();
        }
        await h.tap('concept_safety_advice');
        h.assertPage('safety_advice');
        final suffix = sample.narrow
            ? '__320_text200'
            : sample.scale == 2
            ? '__text200'
            : '';
        final scroll = find.descendant(
          of: h.key('draft_safety_advice_scroll'),
          matching: find.byType(Scrollable),
        );
        final position = t.state<ScrollableState>(scroll).position;
        if (!sample.narrow) await _cap(h, 'x07_safety_advice$suffix');
        if (sample.scale == 1) {
          expect(position.maxScrollExtent, 0);
          expect(position.pixels, 0);
          for (final id in [
            'draft_safety_advice_report',
            'draft_safety_advice_help',
            'draft_safety_advice_emergency',
          ]) {
            expect(h.key(id).hitTestable(), findsOneWidget);
            expect(t.getBottomRight(h.key(id)).dy, lessThanOrEqualTo(898));
          }
        }
        if (sample.scale == 2) expect(position.maxScrollExtent, greaterThan(0));
        for (final title in [
          'Keep your family close',
          'Meet safely',
          'Never send money',
          'Protect your details',
          'Trust how you feel',
        ]) {
          await t.ensureVisible(find.text(title));
          await h.flush();
          expect(find.text(title).hitTestable(), findsOneWidget);
        }
        for (final id in [
          'draft_safety_advice_report',
          'draft_safety_advice_help',
          'draft_safety_advice_emergency',
        ]) {
          await t.ensureVisible(h.key(id));
          await h.flush();
          expect(h.key(id).hitTestable(), findsOneWidget);
        }
        position.jumpTo(position.maxScrollExtent);
        await h.flush();
        if (sample.scale == 2 && !sample.narrow) {
          await _cap(
            h,
            'x07_safety_advice$suffix'
            '__end',
          );
        }
        expect(t.takeException(), isNull);
      },
    );
  }
}
