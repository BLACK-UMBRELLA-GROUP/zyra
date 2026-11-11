// LOCK 6 V4. Actual Founder roots, both roles and both memberships.
// Current private screen captures run through lock24_tab_spacing_test.dart.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';

import 'baseline_capture_support.dart';

Finder _key(String value) => find.byKey(ValueKey(value));
Finder _surface() => _key('compact-nav-surface');
ZyraShellNavigation _nav(WidgetTester tester) =>
    tester.widget(find.byType(ZyraShellNavigation));

void main() {
  setUpAll(
    () => baselineSetUp(
      evidenceRoot: null,
      useSystemSymbolFont: Platform.isMacOS,
    ),
  );
  tearDownAll(baselineTearDown);

  for (final guardian in [false, true]) {
    for (final basic in [false, true]) {
      final role = guardian ? 'Guardian' : 'Seeker';
      final plan = basic ? 'Basic' : 'One';
      testWidgets(
        'LOCK6 V4 first tap switches from every $role $plan root',
        (tester) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final h = BaselineHarness(tester, group: 'lock6_v4_roots');
          for (var tab = 0; tab < 5; tab++) {
            await h.mount(
              guardian: guardian,
              tab: tab,
              initialSeekerBasic: !guardian && basic,
              initialGuardianBasic: guardian && basic,
            );
            expect(_nav(tester).lockedTabBar, isTrue);
            expect(_nav(tester).currentIndex, tab);
            expect(_nav(tester).items.length, 5);
            const frame = Rect.fromLTWH(20, 840, 390, 58);
            expect(tester.getRect(_surface()), frame);
            for (var index = 0; index < 5; index++) {
              expect(
                tester.getSize(_key('floating-nav-item-$index')),
                const Size(44, 44),
              );
            }

            final next = (tab + 1) % 5;
            final finger = await tester.startGesture(
              tester.getCenter(_key('floating-nav-item-$next')),
            );
            await tester.pump(const Duration(milliseconds: 350));
            expect(h.latest.tab, tab);
            expect(tester.getRect(_surface()), frame);
            await finger.up();
            await h.flush();
            expect(h.latest.tab, next);
            expect(tester.getRect(_surface()), frame);
            await tester.pump(const Duration(seconds: 4));
            expect(tester.getRect(_surface()), frame);
            expect(tester.takeException(), isNull);
          }
        },
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );
    }
  }
}
