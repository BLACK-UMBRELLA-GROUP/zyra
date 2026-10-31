// LOCK21: actual four Profile tab states, rendered locally with real tabs.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'baseline_capture_support.dart';

const _root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const _evidence = '$_root/REPORTS/EVIDENCE/LOCK21_PROFILE_TAB_2026-10-31';
const _capture = bool.fromEnvironment('ZYRA_LOCK21_CAPTURE');

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
      'profile',
      name,
      name,
      'Actual admitted Profile tab; current Guardian sample has Adam and Yusuf.',
      fileName: '$name.png',
    );
  } finally {
    debugDisableShadows = previous;
  }
}

Future<void> _scroll(BaselineHarness h, double offset) async {
  final scroll = find.descendant(
    of: find.byKey(const ValueKey('concept-current-profile-scroll')),
    matching: find.byType(Scrollable),
  );
  h.tester.state<ScrollableState>(scroll).position.jumpTo(offset);
  await h.flush();
  expect(
    h.tester.state<ScrollableState>(scroll).position.pixels,
    closeTo(offset, .01),
  );
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  testWidgets('LOCK21 renders p01-p06 actual Profile roots', (t) async {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final h = BaselineHarness(
      t,
      group: 'lock21',
      outputRoot: '$_root/PRODUCT/APPROVED/PROFILE_TAB/BUILT',
      evidenceRoot: _evidence,
      flatOutput: true,
    );
    await h.mount(tab: 4);
    await _cap(h, 'p01_seeker_one__top');
    await _scroll(h, 204);
    await _cap(h, 'p02_seeker_one__scrolled');
    await h.mount(
      tab: 4,
      initialSeekerBasic: true,
      seekerMembership: 'Seeker Basic',
    );
    await _cap(h, 'p03_seeker_basic__top');
    await h.mount(tab: 4, guardian: true);
    await _cap(h, 'p04_guardian_one__top');
    await _scroll(h, 105);
    await _cap(h, 'p05_guardian_one__scrolled');
    await h.mount(
      tab: 4,
      guardian: true,
      initialGuardianBasic: true,
      guardianMembership: 'Guardian Basic',
    );
    await _cap(h, 'p06_guardian_basic__top');
  });
  testWidgets('LOCK21 larger text retains wrapped pills and final Sign out', (
    t,
  ) async {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final h = BaselineHarness(
      t,
      group: 'lock21_large',
      outputRoot: '$_root/PRODUCT/APPROVED/PROFILE_TAB/BUILT',
      evidenceRoot: _evidence,
      flatOutput: true,
      textScale: 2,
    );
    for (final guardian in [false, true]) {
      await h.mount(tab: 4, guardian: guardian);
      await _cap(
        h,
        guardian ? 'guardian_large_text__top' : 'seeker_large_text__top',
      );
      final scroll = find.descendant(
        of: find.byKey(const ValueKey('concept-current-profile-scroll')),
        matching: find.byType(Scrollable),
      );
      final position = t.state<ScrollableState>(scroll).position;
      position.jumpTo(position.maxScrollExtent);
      await h.flush();
      expect(
        find.byKey(const ValueKey('concept_sign_out')).hitTestable(),
        findsOneWidget,
      );
      await _cap(
        h,
        guardian ? 'guardian_large_text__last' : 'seeker_large_text__last',
      );
    }
  });
}
