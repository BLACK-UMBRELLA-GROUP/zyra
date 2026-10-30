// Queue 23: actual local Profiles reveal, same production frame as its baseline.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/widgets/zyra_browse_options_button.dart';

import 'baseline_capture_support.dart';

const _enabled = bool.fromEnvironment('ZYRA_COMPATIBILITY_LOOP_CAPTURE');
const _before = bool.fromEnvironment('ZYRA_COMPATIBILITY_LOOP_BEFORE');
const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/COMPATIBILITY_LOOP_2026-10-30';
const _built =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/PRODUCT/APPROVED/COMPATIBILITY_LOOP/BUILT';

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  testWidgets('Compatibility actual reader pages after both wraps', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final h = BaselineHarness(
      tester,
      group: _before ? 'loop_before' : 'loop_built',
      outputRoot: _before ? '$_evidence/before' : _built,
      evidenceRoot: _evidence,
      flatOutput: true,
    );
    await h.mount();
    await h.controls();
    await h.tap('draft_compatibility_unlock_1');
    await h.closeControls();
    await h.tap('concept_browse_menu');
    final nav = h.key('concept_browse_options_navigation');
    final option = find.descendant(
      of: nav,
      matching: find.byIcon(ZyraBrowseAction.compatibility.icon),
    );
    expect(option, findsOneWidget);
    await tester.tapAt(tester.getCenter(option));
    await h.flush();
    h.assertPage('compatibility');
    await h.tap('draft_compatibility_reveal');
    expect(h.key('draft_compatibility_overall_score'), findsOneWidget);
    if (_before) {
      await h.capture(
        'compatibility',
        'compatibility',
        'page_1',
        'Before queue 23; actual one-unlock reveal',
      );
      for (var page = 1; page < 7; page++) {
        await h.tap('draft_compatibility_score_next');
      }
    } else {
      await h.tap('draft_compatibility_score_previous');
    }
    expect(find.text('7 / 7'), findsOneWidget);
    expect(find.text('Deen'), findsOneWidget);
    await h.capture(
      'compatibility',
      'compatibility',
      'page_7',
      _before
          ? 'Before queue 23; six adjacent next taps'
          : 'Actual previous arrow from page 1 wraps to page 7',
    );
    if (!_before) {
      await tester.drag(
        h.key('draft_compatibility_score_pages'),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 / 7'), findsOneWidget);
      expect(find.text('Overall'), findsOneWidget);
      await h.capture(
        'compatibility',
        'compatibility',
        'page_1',
        'Actual left swipe from page 7 wraps to page 1',
      );
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }, skip: !_enabled);
}
