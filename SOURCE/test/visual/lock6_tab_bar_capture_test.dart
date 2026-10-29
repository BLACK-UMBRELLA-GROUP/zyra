// LOCK6 captures actual Founder roots; prototype Guardian destinations stay
// separate from the existing four current destinations.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'baseline_capture_support.dart';

const _enabled = bool.fromEnvironment('ZYRA_LOCK6_CAPTURE');
const _output =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/PRODUCT/APPROVED/TAB_BAR/BUILT';
const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/LOCK6_TAB_BAR_2026-10-29';
Finder _key(String value) => find.byKey(ValueKey(value));
Finder _surface() => _key('compact-nav-surface');
ZyraShellNavigation _nav(WidgetTester tester) =>
    tester.widget(find.byType(ZyraShellNavigation));

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  for (final guardian in [false, true]) {
    final role = guardian ? 'guardian' : 'seeker';
    testWidgets(
      'LOCK6 actual $role idle and touched root',
      (tester) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final h = BaselineHarness(
          tester,
          group: 'lock6_$role',
          outputRoot: _output,
          evidenceRoot: _evidence,
          flatOutput: true,
        );
        final model = ViewRequestDraftModel(
          capacity: 3,
          clock: () => DateTime.utc(2026, 10, 29, 12),
        );
        if (!guardian) expect(model.request('draft-sara'), isTrue);
        await h.mount(guardian: guardian, model: model);
        expect(_nav(tester).items.length, guardian ? 4 : 5);
        expect(h.latest.tab, 0);
        expect(tester.getSize(_surface()), const Size(156, 46));
        if (!guardian) expect(_nav(tester).items[2].dot, isTrue);
        await h.capture(
          'navigation',
          '${role}_tab_bar',
          'idle_small',
          'Actual current Founder $role root; first idle state; existing destinations and current body retained',
        );
        final states = Map.of(h.latest.model.states);
        final acknowledged = Set.of(
          h.latest.model.acknowledgedReceivedRequestIds,
        );
        final gesture = await tester.startGesture(tester.getCenter(_surface()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.getSize(_surface()), const Size(390, 58));
        expect(h.latest.tab, 0);
        await h.capture(
          'navigation',
          '${role}_tab_bar',
          'touched_full',
          'Actual first touch on small bar expands only; held finger, unchanged destination; current Guardian has four tabs per LOCK6 spec',
        );
        await gesture.up();
        await h.flush();
        expect(h.latest.tab, 0);
        expect(h.latest.model.states, states);
        expect(h.latest.model.acknowledgedReceivedRequestIds, acknowledged);
        expect(tester.getSize(_surface()), const Size(390, 58));
        if (!guardian) {
          await tester.tapAt(tester.getCenter(_key('floating-nav-item-2')));
          await h.flush();
          expect(h.latest.tab, 2);
          expect(_nav(tester).items[2].dot, isFalse);
          expect(h.latest.model.acknowledgedReceivedRequestIds, acknowledged);
          expect(_key('my-zyra-new-activity-heading'), findsOneWidget);
          await tester.drag(
            _key('my-zyra-quiet-scroll-0'),
            const Offset(0, -100),
          );
          await tester.pumpAndSettle();
          expect(tester.getSize(_surface()), const Size(156, 46));
        }
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.getSize(_surface()), const Size(156, 46));
        await tester.runAsync(
          () => File('$_evidence/invariants_$role.json').writeAsString(
            jsonEncode({
              'role': role,
              'idle': [156, 46],
              'full': [390, 58],
              'destinations': _nav(tester).items.map((x) => x.label).toList(),
              'first_touch_does_not_switch': true,
              'model_unchanged_on_expansion': true,
              'LOCK5_gold_clear_keeps_item_attention': !guardian,
            }),
          ),
        );
      },
      skip: !_enabled,
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      timeout: const Timeout(Duration(minutes: 3)),
    );
  }
}
