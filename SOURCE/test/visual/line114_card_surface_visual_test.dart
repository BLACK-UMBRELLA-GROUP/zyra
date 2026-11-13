import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/zyra_floating_surface.dart';

import '../support/guardian_card_driver.dart';
import 'baseline_capture_support.dart';

const _captures = String.fromEnvironment('ZYRA_LINE114_CAPTURE_DIR');
const _fill = Color(0xD9FAF5EC);
const _border = BorderSide(color: Color(0x0F3E2E1E));
const _shadows = [
  BoxShadow(color: Color(0x1F3E2E1E), blurRadius: 24, offset: Offset(0, 10)),
  BoxShadow(color: Color(0x123E2E1E), blurRadius: 6, offset: Offset(0, 2)),
];

BaselineHarness _harness(WidgetTester tester) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return BaselineHarness(
    tester,
    group: 'line114_card_surface',
    outputRoot: _captures,
    evidenceRoot: _captures,
    flatOutput: true,
    reduceMotion: true,
  );
}

void _expectCardSurface(WidgetTester tester, Finder content) {
  expect(content, findsOneWidget);
  final floating = find.ancestor(
    of: content,
    matching: find.byType(ZyraFloatingSurface),
  );
  expect(floating, findsOneWidget);
  final paintedChildren = <Widget>[];
  tester.element(floating).visitChildren((element) {
    paintedChildren.add(element.widget);
  });
  final shadow = (paintedChildren.single as DecoratedBox).decoration;
  expect((shadow as BoxDecoration).boxShadow, _shadows);

  final card = tester.widget<ZyraFloatingSurface>(floating).child;
  if (card is Material) {
    expect(card.color, _fill);
    expect((card.shape! as RoundedRectangleBorder).side, _border);
    return;
  }
  final decoration =
      switch (card) {
            Container() => card.decoration,
            DecoratedBox() => card.decoration,
            _ => throw StateError(
              'Unexpected card surface: ${card.runtimeType}',
            ),
          }
          as BoxDecoration;
  expect(decoration.color, _fill);
  expect(decoration.border, Border.fromBorderSide(_border));
}

Future<void> _capture(BaselineHarness harness, String name) async {
  if (_captures.isEmpty) return;
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  try {
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    repaint(
      harness.tester.renderObject(
        harness.key('zyra-founder-baseline-boundary'),
      ),
    );
    await harness.capture('card_surface', 'line114', name, name);
  } finally {
    debugDisableShadows = previous;
  }
}

void main() {
  setUpAll(
    () => baselineSetUp(evidenceRoot: _captures.isEmpty ? null : _captures),
  );
  tearDownAll(baselineTearDown);

  test('Line 114 keeps the original card fill, border and shadow', () {
    expect(ZyraColors.cardSurface, _fill);
    expect(ZyraColors.surfaceBorder, _border.color);
    expect(ZyraColors.cardShadows, _shadows);
  });

  for (final guardian in [false, true]) {
    final role = guardian ? 'guardian' : 'seeker';
    testWidgets(
      'Line 114 $role My ZYRA and Profile share a card style',
      (tester) async {
        final harness = _harness(tester);
        await harness.mount(tab: 2, guardian: guardian);
        _expectCardSurface(
          tester,
          harness.key(guardian ? 'guardian_requests' : 'concept-my-requests'),
        );
        await _capture(harness, '${role}_my_zyra');

        await harness.mount(tab: 4, guardian: guardian);
        _expectCardSurface(
          tester,
          harness.key(
            guardian ? 'concept_your_seekers' : 'concept_manage_photos',
          ),
        );
        _expectCardSurface(tester, harness.key('concept_membership'));
        await _capture(harness, '${role}_profile');
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }

  testWidgets(
    'Line 114 Guardian card and Add share the same card style',
    (tester) async {
      final harness = _harness(tester);
      await harness.mount(
        tab: 3,
        model: ViewRequestDraftModel(capacity: 3)..seedJourneys(1),
      );
      _expectCardSurface(
        tester,
        harness.key('guardian-card-content-draft-guardian-hassan'),
      );
      await _capture(harness, 'guardian_card');

      for (var card = 0; card < 3; card++) {
        await swipeGuardianCard(tester);
        await harness.flush();
      }
      expect(harness.key('guardian-card-add'), findsOneWidget);
      _expectCardSurface(tester, find.text('Add a Guardian'));
      await _capture(harness, 'guardian_add');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
