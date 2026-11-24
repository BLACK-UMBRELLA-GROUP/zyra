import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/widgets/zyra_membership_choices.dart';

import 'baseline_capture_support.dart';

const _output = String.fromEnvironment('ZYRA_LINE119_OUTPUT');
final _ios = TargetPlatformVariant({TargetPlatform.iOS});

Finder _key(String id) => find.byKey(ValueKey(id));

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
      final role = guardian ? 'guardian' : 'seeker';
      final plan = basic ? 'basic' : 'one';
      testWidgets('line119 $role $plan Profile and paid Current routes', (
        t,
      ) async {
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final h = BaselineHarness(
          t,
          group: 'line119_${role}_$plan',
          outputRoot: _output,
          evidenceRoot: _output,
          flatOutput: true,
        );
        await h.mount(
          guardian: guardian,
          tab: 4,
          receivedRequest: false,
          seekerPhotos: const [],
          initialSeekerBasic: !guardian && basic,
          initialGuardianBasic: guardian && basic,
          seekerMembership: !guardian && basic ? 'Seeker Basic' : 'Seeker One',
          guardianMembership: guardian && basic
              ? 'Guardian Basic'
              : 'Guardian One',
        );
        expect(find.text('Membership'), findsOneWidget);
        expect(find.text('Your places'), findsOneWidget);
        expect(find.text('Profiles & Family places'), findsNothing);
        if (_output.isNotEmpty || baselineTextAuditOnly) {
          await h.capture(
            'profile',
            role,
            plan,
            'Actual Founder Profile tab',
            fileName: '${role}_${plan}_profile.png',
          );
        }
        if (!basic) {
          await h.tap('concept_membership');
          expect(_key('membership-section-unlocks'), findsNothing);
          final pills = [
            'current',
            'seeker',
            'guardian',
            'family',
          ].map((name) => t.getRect(_key('membership-section-$name'))).toList();
          expect(pills.every((rect) => rect.top == pills.first.top), isTrue);
          expect(pills.first.left, greaterThanOrEqualTo(20));
          expect(pills.last.right, lessThanOrEqualTo(410));
          expect(
            t
                .widget<ZyraMembershipChoices>(
                  find.byType(ZyraMembershipChoices),
                )
                .initialDraft!
                .section,
            ZyraMembershipSection.current,
          );
          final cancel = t.getRect(_key('concept_cancel_membership'));
          expect(cancel.left, 20);
          expect(cancel.right, 410);
          expect(cancel.bottom, closeTo(932 - 34 - 16, .1));
          if (_output.isNotEmpty || baselineTextAuditOnly) {
            await h.capture(
              'membership',
              role,
              'current',
              'Profile → Membership → Current',
              fileName: '${role}_current_membership.png',
            );
          }
        }
        if (guardian && basic) {
          await h.tap('floating-nav-item-0');
          expect(_key('guardian_network_lock_circle'), findsOneWidget);
          if (_output.isNotEmpty || baselineTextAuditOnly) {
            await h.capture(
              'network',
              role,
              'basic',
              'Guardian Basic → Network',
              fileName: 'guardian_basic_network.png',
            );
          }
          await h.tap('floating-nav-item-2');
          if (_output.isNotEmpty || baselineTextAuditOnly) {
            await h.capture(
              'my_zyra',
              role,
              'basic',
              'Guardian Basic → My ZYRA',
              fileName: 'guardian_basic_my_zyra.png',
            );
          }
        }
        expect(t.takeException(), isNull);
      }, variant: _ios);
    }
  }
}
