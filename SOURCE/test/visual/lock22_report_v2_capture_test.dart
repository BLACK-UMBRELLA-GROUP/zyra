// LOCK22 V2: the real report route, local reason ownership and LOCK16 flows.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_browse_utility_presentation.dart';
import 'package:zyra/dev/zyra_draft_journey_block_hide_sheet.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

const _root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const _out = '$_root/PRODUCT/APPROVED/UNITY_PASS/BUILT/V2';
const _evidence = '$_root/REPORTS/EVIDENCE/LOCK22_REPORT_V2_2026-10-31';
const _render = bool.fromEnvironment('ZYRA_LOCK22_REPORT_CAPTURE');
Finder _k(String id) => find.byKey(ValueKey(id));

BaselineHarness _h(WidgetTester t, {double scale = 1}) {
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  return BaselineHarness(
    t,
    group: 'report_v2_$scale',
    outputRoot: _out,
    evidenceRoot: _evidence,
    flatOutput: true,
    textScale: scale,
  );
}

Future<void> _cap(BaselineHarness h, String name, {bool narrow = false}) async {
  if (!_render) return;
  final old = debugDisableShadows;
  debugDisableShadows = false;
  void repaint(RenderObject node) {
    node.markNeedsPaint();
    node.visitChildren(repaint);
  }

  try {
    repaint(h.tester.renderObject(_k('zyra-founder-baseline-boundary')));
    await h.tester.pump();
    if (narrow) {
      final boundary = h.tester.renderObject<RenderRepaintBoundary>(
        _k('zyra-founder-baseline-boundary'),
      );
      await h.tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 3);
        try {
          expect((image.width, image.height), (960, 1704));
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            '$_out/$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
        } finally {
          image.dispose();
        }
      });
      return;
    }
    await h.capture(
      'report_v2',
      name,
      name,
      'Actual protected Report route; local sample and disabled Submit.',
      fileName: '$name.png',
    );
  } finally {
    debugDisableShadows = old;
  }
}

Future<void> _openReport(BaselineHarness h) async {
  if (_k('draft_safety').evaluate().isNotEmpty) {
    await h.tap('draft_safety');
    return;
  }
  await h.tap('concept_browse_menu');
  await expandZyraPreviewTabBarIfIdle(h.tester);
  final nav = find.byType(ZyraShellNavigation);
  final item = h.tester
      .widget<ZyraShellNavigation>(nav)
      .items
      .singleWhere((i) => i.label == 'Report');
  final icon = find.descendant(of: nav, matching: find.byIcon(item.icon));
  final owner = find
      .ancestor(
        of: icon,
        matching: find.byWidgetPredicate(
          (w) => w is GestureDetector && w.onTapDown != null,
        ),
      )
      .first;
  expect(owner.hitTestable(), findsOneWidget);
  await h.tester.tapAt(h.tester.getCenter(icon));
  await h.flush();
}

void _selected(WidgetTester t, ZyraDraftReportReason reason) {
  final icons = find.descendant(
    of: _k('draft_report_reason_${reason.name}'),
    matching: find.byIcon(Icons.radio_button_checked),
  );
  expect(icons, findsOneWidget);
  expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
  expect(t.widget<OutlinedButton>(_k('draft_report_submit')).onPressed, isNull);
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'Report x05/x06 actual route at text $scale selects all reasons, stays offline and draft',
      (t) async {
        final h = _h(t, scale: scale);
        await h.mount(tab: 0, pages: ['profile']);
        await _openReport(h);
        h.assertPage('safety');
        expect(find.text('Sara Ahmed'), findsOneWidget);
        final before = h.latest.model;
        _selected(t, ZyraDraftReportReason.fakeProfile);
        final suffix = scale == 1 ? '' : '__text200';
        await _cap(h, 'x05_report__sara$suffix');
        for (final reason in ZyraDraftReportReason.values) {
          await h.tap('draft_report_reason_${reason.name}');
          _selected(t, reason);
          expect(t.takeException(), isNull);
          if (scale == 2 && reason == ZyraDraftReportReason.underage) {
            await _cap(h, 'x05_report__sara__text200__middle');
          }
        }
        await h.tap('draft_report_reason_harassment');
        _selected(t, ZyraDraftReportReason.harassment);
        final scroll = t.state<ScrollableState>(
          find.descendant(
            of: _k('draft_report_viewport'),
            matching: find.byType(Scrollable),
          ),
        );
        if (scale == 1) {
          scroll.position.jumpTo(0);
        } else {
          scroll.position.jumpTo(scroll.position.maxScrollExtent);
        }
        await h.flush();
        await _cap(h, 'x06_report__reason_chosen$suffix');
        for (final id in [
          'draft_report_submit',
          'draft_safety_hide',
          'draft_safety_block',
        ]) {
          await t.ensureVisible(_k(id));
          await h.flush();
          expect(_k(id).hitTestable(), findsOneWidget);
          expect(t.getSize(_k(id)).height, greaterThanOrEqualTo(44));
        }
        if (scale == 2) {
          await _cap(h, 'x06_report__reason_chosen__text200__footer');
        }
        expect(h.latest.model.states, before.states);
        expect(h.latest.model.hiddenPeers, before.hiddenPeers);
        expect(h.latest.model.blockedPeers, before.blockedPeers);
        expect(h.latest.model.endedAttempts, before.endedAttempts);
        expect(find.textContaining('sent'), findsNothing);
      },
    );
  }

  testWidgets(
    'Report actual narrow 320x568 at 200 percent reaches every reason and disabled action without overflow',
    (t) async {
      final h = _h(t, scale: 2);
      await h.mount(tab: 0, pages: ['profile']);
      await _openReport(h);
      t.view.physicalSize = const Size(960, 1704);
      await h.flush();
      await _cap(h, 'x05_report__sara__narrow320_text200', narrow: true);
      for (final reason in ZyraDraftReportReason.values) {
        await h.tap('draft_report_reason_${reason.name}');
        _selected(t, reason);
      }
      await h.tap('draft_report_reason_harassment');
      for (final id in [
        'draft_report_submit',
        'draft_safety_hide',
        'draft_safety_block',
      ]) {
        await t.ensureVisible(_k(id));
        await h.flush();
        expect(_k(id).hitTestable(), findsOneWidget);
        final rect = t.getRect(_k(id));
        expect(rect.left, greaterThanOrEqualTo(20));
        expect(rect.right, lessThanOrEqualTo(300));
      }
      await _cap(
        h,
        'x06_report__reason_chosen__narrow320_text200__footer',
        narrow: true,
      );
      expect(t.takeException(), isNull);
    },
  );

  for (final basic in [false, true]) {
    for (final hide in [false, true]) {
      for (final phase in ['none', 'preparing', 'active']) {
        testWidgets(
          'Report ${basic ? "Basic" : "One"} $phase ${hide ? "Hide" : "Block"} retains reason through Keep/dismiss and confirms exact target',
          (t) async {
            final h = _h(t);
            final model = ViewRequestDraftModel(capacity: basic ? 1 : 3);
            if (phase == 'active') {
              expect(model.seedJourneys(1), isTrue);
            } else if (phase == 'preparing') {
              expect(model.request('draft-sara'), isTrue);
              expect(model.simulateRecipientAccept('draft-sara'), isTrue);
            }
            await h.mount(
              tab: phase == 'none' ? 0 : 1,
              pages: ['profile'],
              model: model,
              initialSeekerBasic: basic,
              seekerMembership: basic ? 'Seeker Basic' : 'Seeker One',
            );
            await _openReport(h);
            await h.tap('draft_report_reason_privacy');
            final before = h.latest.model;
            final action = hide ? 'draft_safety_hide' : 'draft_safety_block';
            await h.tap(action);
            if (phase != 'none') {
              expect(
                find.byType(ZyraDraftJourneyBlockHideSheet),
                findsOneWidget,
              );
              await h.tap('journey_person_safety_keep');
              _selected(t, ZyraDraftReportReason.privacy);
              expect(h.latest.model.states, before.states);
              await h.tap(action);
              await t.tapAt(const Offset(10, 120));
              await h.flush();
              expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
              _selected(t, ZyraDraftReportReason.privacy);
              await h.tap(action);
              await h.tap('journey_person_safety_confirm');
              expect(h.latest.tab, 1);
              expect(
                find.text(
                  hide
                      ? "Your Journey with Sara has ended. Sara won't appear again."
                      : 'Your Journey with Sara has ended and Sara is blocked.',
                ),
                findsOneWidget,
              );
            } else {
              expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
              expect(h.latest.model.endedAttempts, before.endedAttempts);
            }
            final after = ViewRequestDraftModel.fromSnapshot(h.latest.model);
            expect(after.isHidden('draft-sara'), hide);
            expect(after.isBlocked('draft-sara'), !hide);
            expect(find.byType(ZyraDraftReportPresentation), findsNothing);
            expect(t.takeException(), isNull);
          },
        );
      }
    }
  }
}
