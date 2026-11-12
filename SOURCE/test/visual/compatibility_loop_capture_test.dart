// Actual local Profiles reveal and both directions of the pager loop.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/widgets/zyra_browse_options_button.dart';

import 'baseline_capture_support.dart';

const _evidence = String.fromEnvironment('ZYRA_COMPATIBILITY_LOOP_CAPTURE_DIR');

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);
  testWidgets('Compatibility actual reader pages after both wraps', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final h = BaselineHarness(
      tester,
      group: 'compatibility_loop',
      outputRoot: _evidence,
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
    await h.tap('draft_compatibility_score_previous');
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('Every area'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    await h.capture(
      'compatibility',
      'compatibility',
      'page_2',
      'Previous arrow from Overall wraps to Every area',
    );
    await tester.drag(
      h.key('draft_compatibility_score_pages'),
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('Overall'), findsOneWidget);
    await h.capture(
      'compatibility',
      'compatibility',
      'page_1',
      'Left swipe from Every area wraps to Overall',
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }, skip: _evidence.isEmpty);
}
