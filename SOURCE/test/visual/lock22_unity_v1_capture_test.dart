// LOCK22 V1: actual protected shell routes, bundled fonts, offline sample data.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_compatibility_presentation.dart';
import 'package:zyra/dev/zyra_draft_compatibility_store_presentation.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'baseline_capture_support.dart';

const _root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const _evidence = '$_root/REPORTS/EVIDENCE/LOCK22_UNITY_V1_2026-10-31';
const _capture = bool.fromEnvironment('ZYRA_LOCK22_CAPTURE');

ZyraPreviewNavigationCheckpoint _checkpoint(
  String page,
  int balance, {
  bool one = true,
}) => ZyraPreviewNavigationCheckpoint(
  guardian: false,
  model: ViewRequestDraftModel(capacity: one ? 3 : 1).snapshot(),
  tab: 0,
  pages: [page],
  personId: page == 'safety' ? null : 'draft-sara',
  compatibilityBalance: balance,
  seekerMembership: one ? 'Seeker One' : 'Seeker Basic',
);

Future<void> _cap(BaselineHarness h, String name) async {
  if (!_capture) return;
  final old = debugDisableShadows;
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
      'unity_v1',
      name,
      name,
      'Actual protected shell route with fixed local data.',
      fileName: '$name.png',
    );
  } finally {
    debugDisableShadows = old;
  }
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'LOCK22 V1 actual x01-x04 at text $scale and real unlock navigation',
      (t) async {
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final h = BaselineHarness(
          t,
          group: 'lock22_$scale',
          outputRoot: '$_root/PRODUCT/APPROVED/UNITY_PASS/BUILT/V1',
          evidenceRoot: _evidence,
          flatOutput: true,
          textScale: scale,
        );
        final suffix = scale == 1 ? '' : '__text200';
        await h.mount(checkpoint: _checkpoint('compatibility', 1));
        h.assertPage('compatibility');
        expect(find.text('READY TO REVEAL'), findsOneWidget);
        expect(find.text('Uses 1 Unlock'), findsOneWidget);
        expect(
          t
              .widget<ZyraDraftCompatibilityPresentation>(
                find.byType(ZyraDraftCompatibilityPresentation),
              )
              .revealed,
          isFalse,
        );
        await _cap(h, 'x01_compatibility__locked$suffix');
        if (scale == 2) {
          await t.ensureVisible(h.key('draft_compatibility_buy_more'));
          await h.flush();
          expect(
            h.key('draft_compatibility_buy_more').hitTestable(),
            findsOneWidget,
          );
          await _cap(h, 'x01_compatibility__locked__text200__footer');
        }
        await h.tap('draft_compatibility_buy_more');
        h.assertPage('compatibility_store');
        expect(find.text('3 MORE EACH MONTH WITH SEEKER ONE'), findsOneWidget);
        expect(find.text('Unlock left'), findsOneWidget);
        await _cap(h, 'x02_unlocks__seeker_one$suffix');
        if (scale == 2) {
          await t.ensureVisible(h.key('draft_compatibility_store_terms'));
          await h.flush();
          expect(
            h.key('draft_compatibility_store_terms').hitTestable(),
            findsOneWidget,
          );
          await _cap(h, 'x02_unlocks__seeker_one__text200__footer');
        }
        await h.mount(
          checkpoint: _checkpoint('compatibility', 0, one: false),
          initialSeekerBasic: true,
        );
        await h.controls();
        await h.tap('draft_compatibility_unlock_0');
        await h.closeControls();
        await h.tap('draft_compatibility_buy_more');
        expect(find.text('SEEKER ONE INCLUDES 3 EACH MONTH'), findsOneWidget);
        expect(find.text('Unlocks left'), findsOneWidget);
        expect(find.text('Unlocks remaining'), findsNothing);
        await _cap(h, 'x03_unlocks__seeker_basic$suffix');
        if (scale == 2) {
          await t.ensureVisible(h.key('draft_compatibility_store_terms'));
          await h.flush();
          expect(
            h.key('draft_compatibility_store_terms').hitTestable(),
            findsOneWidget,
          );
          await _cap(h, 'x03_unlocks__seeker_basic__text200__footer');
        }
        await h.mount(tab: 4);
        await h.tap('concept_safety_advice');
        h.assertPage('safety');
        expect(find.text('Choose a profile to report'), findsOneWidget);
        expect(find.text('Submit report'), findsNothing);
        expect(
          find.byKey(const ValueKey('draft_safety_monogram')),
          findsOneWidget,
        );
        await _cap(h, 'x04_safety$suffix');
        // The existing caller owns the actual debit and permanent local reveal.
        await h.mount(checkpoint: _checkpoint('compatibility', 1));
        await h.tap('draft_compatibility_reveal');
        final revealed = t.widget<ZyraDraftCompatibilityPresentation>(
          find.byType(ZyraDraftCompatibilityPresentation),
        );
        expect(revealed.revealed, isTrue);
        expect(revealed.balance, 0);
        expect(
          find.byKey(const ValueKey('draft_compatibility_score_reader')),
          findsOneWidget,
        );
        expect(
          find.byType(ZyraDraftCompatibilityStorePresentation),
          findsNothing,
        );
        expect(t.takeException(), isNull);
      },
    );
  }
}
