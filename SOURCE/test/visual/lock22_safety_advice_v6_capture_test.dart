import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_safety_advice_presentation.dart';
import 'baseline_capture_support.dart';

const _root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const _evidence = '$_root/REPORTS/EVIDENCE/LOCK22_SAFETY_ADVICE_V6_2026-10-31';
const _capture = bool.fromEnvironment('ZYRA_LOCK22_V6_CAPTURE');

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
      'safety_v6',
      name,
      name,
      'Actual Guardian Profile → Safety & advice route; bundled fonts, offline samples.',
      fileName: '$name.png',
    );
  } finally {
    debugDisableShadows = previous;
  }
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  for (final one in [true, false]) {
    for (final sample in [
      (scale: 1.0, narrow: false),
      (scale: 2.0, narrow: false),
      (scale: 2.0, narrow: true),
    ]) {
      testWidgets(
        'V6 Guardian ${one ? "One" : "Basic"} actual advice: scale=${sample.scale}, narrow=${sample.narrow}',
        (t) async {
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          final h = BaselineHarness(
            t,
            group: 'safety_v6_${one}_${sample.scale}_${sample.narrow}',
            outputRoot: '$_root/PRODUCT/APPROVED/UNITY_PASS/BUILT/V6',
            evidenceRoot: _evidence,
            flatOutput: true,
            textScale: sample.scale,
          );
          await h.mount(
            tab: 4,
            guardian: true,
            initialGuardianBasic: !one,
            guardianMembership: one ? 'Guardian One' : 'Guardian Basic',
          );
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
          final inheritedInsets = MediaQuery.of(
            t.element(find.byType(ZyraDraftSafetyAdvicePresentation)),
          ).viewPadding;
          if (_capture) {
            final footer = h.key('draft_safety_advice_emergency');
            final rect = t.getRect(footer);
            final file = File(
              '$_root/PRODUCT/APPROVED/UNITY_PASS/BUILT/V6/'
              '${one ? "x08" : "x09"}$suffix.geometry.json',
            );
            file.writeAsStringSync(
              const JsonEncoder.withIndent('  ').convert({
                'guardian_plan': one ? 'One' : 'Basic',
                'logical_size': [
                  sample.narrow ? 320 : 430,
                  sample.narrow ? 568 : 932,
                ],
                'text_scale': sample.scale,
                'safe_bottom': inheritedInsets.bottom,
                'safe_content_bottom':
                    (sample.narrow ? 568 : 932) - inheritedInsets.bottom,
                'initial_scroll_offset': position.pixels,
                'max_scroll_extent': position.maxScrollExtent,
                'emergency_rect': [
                  rect.left,
                  rect.top,
                  rect.right,
                  rect.bottom,
                ],
                'standard_unscrolled_fit': sample.scale == 1
                    ? position.maxScrollExtent == 0 && rect.bottom <= 898
                    : null,
              }),
            );
          }
          if (!sample.narrow) {
            await _cap(
              h,
              '${one ? "x08_guardian" : "x09_guardian_basic"}_safety_advice$suffix',
            );
          }
          if (sample.scale == 1) {
            expect(inheritedInsets.bottom, 34);
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
          if (sample.scale == 2) {
            expect(position.maxScrollExtent, greaterThan(0));
          }
          for (final title in [
            "Support, don't decide",
            'Be there when they meet',
            'Never send money',
            'Protect family details',
            'Speak up early',
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
              '${one ? "x08_guardian" : "x09_guardian_basic"}_safety_advice$suffix'
              '__end',
            );
          }
          expect(t.takeException(), isNull);
        },
      );
    }
  }
}
