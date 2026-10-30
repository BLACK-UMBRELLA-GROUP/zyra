// LOCK6 V2 captures actual Founder roots and verifies every root in both roles.
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
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/LOCK6_TAB_BAR_2026-10-30';
Finder _key(String value) => find.byKey(ValueKey(value));
Finder _surface() => _key('compact-nav-surface');
ZyraShellNavigation _nav(WidgetTester tester) =>
    tester.widget(find.byType(ZyraShellNavigation));

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  for (final guardian in [false, true]) {
    for (final basic in [false, true]) {
      testWidgets(
        'LOCK6 V2 every ${guardian ? 'Guardian' : 'Seeker'} root ${basic ? 'Basic' : 'One'}',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final h = BaselineHarness(
            tester,
            group: 'lock6_roots',
            evidenceRoot: _evidence,
          );
          for (var tab = 0; tab < 5; tab++) {
            await h.mount(
              guardian: guardian,
              tab: tab,
              initialSeekerBasic: !guardian && basic,
              initialGuardianBasic: guardian && basic,
            );
            expect(_nav(tester).compactV2, isTrue);
            expect(_nav(tester).currentIndex, tab);
            expect(_nav(tester).items.length, 5);
            expect(
              tester.getRect(_surface()),
              const Rect.fromLTWH(98, 848, 234, 50),
            );
            for (var index = 0; index < 5; index++) {
              expect(
                tester.getSize(_key('floating-nav-item-$index')).width,
                38,
              );
              expect(
                tester.getCenter(_key('floating-nav-item-$index')).dx,
                closeTo(127 + 44.0 * index, .001),
              );
            }
            final next = (tab + 1) % 5;
            await tester.tapAt(
              tester.getCenter(_key('floating-nav-item-$next')),
            );
            await h.flush();
            expect(
              h.latest.tab,
              tab,
              reason: 'First tap expands only at every root.',
            );
            expect(tester.getSize(_surface()), const Size(390, 58));
            await tester.tapAt(
              tester.getCenter(_key('floating-nav-item-$next')),
            );
            await h.flush();
            expect(h.latest.tab, next);
            await tester.pump(const Duration(seconds: 3));
            await tester.pump(const Duration(milliseconds: 300));
            expect(tester.getSize(_surface()), const Size(234, 50));
            expect(tester.takeException(), isNull);
          }
        },
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );
    }
  }
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
        await h.mount(guardian: guardian, model: model, tab: guardian ? 2 : 0);
        expect(_nav(tester).items.length, 5);
        expect(h.latest.tab, guardian ? 2 : 0);
        expect(tester.getSize(_surface()), const Size(234, 50));
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
        expect(h.latest.tab, guardian ? 2 : 0);
        await h.capture(
          'navigation',
          '${role}_tab_bar',
          'touched_full',
          'Actual first touch on small bar expands only; held finger, unchanged destination; Guardian retains LOCK8 V2 five-tab order',
        );
        await gesture.up();
        await h.flush();
        expect(h.latest.tab, guardian ? 2 : 0);
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
          expect(tester.getSize(_surface()), const Size(234, 50));
        }
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.getSize(_surface()), const Size(234, 50));
        await tester.runAsync(
          () => File('$_evidence/invariants_$role.json').writeAsString(
            jsonEncode({
              'role': role,
              'idle': [234, 50],
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
