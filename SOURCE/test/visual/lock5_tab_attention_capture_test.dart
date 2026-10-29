// LOCK 5: real shell navigation clears tab attention without reading requests.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'baseline_capture_support.dart';
import '../support/zyra_hidden_dev_controls_driver.dart';

const _enabled = bool.fromEnvironment('ZYRA_LOCK5_CAPTURE');
const _output =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/PRODUCT/APPROVED/TAB_ATTENTION/BUILT';
const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/LOCK5_TAB_ATTENTION_2026-10-29';

ZyraShellNavigation _navigation(WidgetTester tester) =>
    tester.widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation));

Finder _icon(WidgetTester tester, String label) {
  final nav = _navigation(tester);
  final item = nav.items.singleWhere((item) => item.label == label);
  expect(item.useJourneyGlyph, isFalse);
  return find.descendant(
    of: find.byType(ZyraShellNavigation),
    matching: find.byIcon(item.icon),
  );
}

Future<void> _openTab(BaselineHarness h, String label) async {
  await expandZyraPreviewTabBarIfIdle(h.tester);
  final target = _icon(h.tester, label);
  expect(target, findsOneWidget);
  // The real floating bar's detector owns touch; its icons IgnorePointer.
  final touchBar = find
      .ancestor(
        of: target,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector && widget.onTapDown != null,
        ),
      )
      .first;
  expect(touchBar.hitTestable(), findsOneWidget);
  final point = h.tester.getCenter(target);
  expect(h.tester.getRect(touchBar).contains(point), isTrue);
  await h.tester.tapAt(point);
  await h.flush();
  final nav = _navigation(h.tester);
  expect(nav.items[nav.currentIndex].label, label);
}

Map<String, double> _rect(Rect rect) => {
  'left': rect.left,
  'top': rect.top,
  'right': rect.right,
  'bottom': rect.bottom,
  'width': rect.width,
  'height': rect.height,
};

void main() {
  setUpAll(baselineSetUp);
  tearDownAll(baselineTearDown);

  testWidgets(
    'LOCK 5 actual tab open clears gold while request remains unseen',
    (tester) async {
      final h = BaselineHarness(
        tester,
        group: 'lock5_tab_attention',
        outputRoot: _output,
        evidenceRoot: _evidence,
        flatOutput: true,
      );
      await h.mount();
      expect(h.latest.tab, 0);
      expect(h.latest.pages, isEmpty);
      expect(_navigation(tester).items[2].dot, isTrue);
      final states = Map.of(h.latest.model.states);
      final acknowledged = Set.of(
        h.latest.model.acknowledgedReceivedRequestIds,
      );
      final avatar = find.byKey(
        const ValueKey('concept_browse_details_avatar_draft-sara'),
      );
      final clip = find.byKey(
        const ValueKey('concept_browse_details_avatar_photo_draft-sara'),
      );
      expect(avatar, findsOneWidget);
      expect(clip, findsOneWidget);
      expect(tester.getSize(avatar), const Size(56, 56));
      expect(tester.getSize(clip), const Size(50, 50));
      final avatarRect = tester.getRect(avatar);
      final clipRect = tester.getRect(clip);
      final iconRect = tester.getRect(_icon(tester, 'My ZYRA'));
      await h.capture(
        'browse_and_requests',
        'tab_bar',
        'my_zyra_new_activity_gold',
        'Actual initial Profiles tab with an unseen received request; My ZYRA attention gold',
      );

      await _openTab(h, 'My ZYRA');
      expect(_navigation(tester).items[2].dot, isFalse);
      expect(h.latest.model.states, states);
      expect(h.latest.model.acknowledgedReceivedRequestIds, acknowledged);
      expect(
        find.byKey(const ValueKey('my-zyra-new-activity-heading')),
        findsOneWidget,
      );
      await _openTab(h, 'Profiles');
      expect(h.latest.tab, 0);
      expect(h.latest.pages, isEmpty);
      expect(_navigation(tester).items[2].dot, isFalse);
      expect(h.latest.model.states, states);
      expect(h.latest.model.acknowledgedReceivedRequestIds, acknowledged);
      expect(tester.getRect(avatar), avatarRect);
      expect(tester.getRect(clip), clipRect);
      await h.capture(
        'browse_and_requests',
        'tab_bar',
        'my_zyra_seen_plain',
        'Actual My ZYRA icon tap then actual Profiles icon tap; no request opened or acknowledged; My ZYRA attention plain',
      );
      await tester.runAsync(() async {
        final file = File('$_evidence/capture_invariants.json');
        await file.parent.create(recursive: true);
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert({
            'logical_size': [430, 932],
            'device_pixel_ratio': 3,
            'png_size': [1290, 2796],
            'attention_icon_rect_logical': _rect(iconRect),
            'avatar_outer_rect_logical': _rect(avatarRect),
            'photo_clip_rect_logical': _rect(clipRect),
            'underlying_states_unchanged': true,
            'acknowledged_received_request_ids': acknowledged.toList(),
            'request_seen_state_unchanged': true,
            'inside_new_activity_heading_preserved': true,
            'navigation': 'Actual touch detector via visible icon centers',
          }),
          flush: true,
        );
      });
    },
    skip: !_enabled,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
