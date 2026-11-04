// OA-ZYRA-325: retired controls must be absent even with Founder authorization.
// Other role/plan states are reached only through code fixtures.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_concept_shell.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'visual/baseline_capture_support.dart';

void _expectNoRetiredControls() {
  final controls = find.byWidgetPredicate((widget) {
    final key = widget.key;
    final name = widget.runtimeType.toString();
    return (key is ValueKey<String> &&
            (key.value.startsWith('dev_') ||
                key.value.startsWith('identity-dev-'))) ||
        const {
          'ZyraDevControlRail',
          'ZyraDevHoldToOpen',
          'ZyraGlobalDevOverlay',
          'DevScenarioPanelV2',
          'WaliDevScenarioPanel',
          'DeveloperAccessScreen',
          'TesterAccessScreen',
        }.contains(name);
  });
  expect(controls, findsNothing);
}

void main() {
  const evidence =
      '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE/.buildlog/queue44_20261103/release_safety';
  const capture = bool.fromEnvironment('ZYRA_QUEUE44_CAPTURE');
  const captures =
      '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/PRODUCT/APPROVED/DEV_TOGGLES/BUILT/SCREENSHOTS';
  setUpAll(() => baselineSetUp(evidenceRoot: evidence));
  tearDownAll(baselineTearDown);
  testWidgets(
    'retired developer controls cannot be reached in any sample role or plan',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      ZyraDeveloperAccess.setAuthorizedForTesting(true);
      for (final guardian in [false, true]) {
        for (final basic in [false, true]) {
          final h = BaselineHarness(
            tester,
            group: 'release_safety',
            outputRoot: captures,
            flatOutput: true,
            evidenceRoot: evidence,
          );
          await h.mount(
            guardian: guardian,
            tab: 4,
            initialSeekerBasic: !guardian && basic,
            initialGuardianBasic: guardian && basic,
            seekerMembership: !guardian && basic
                ? 'Seeker Basic'
                : 'Seeker One',
            guardianMembership: guardian && basic
                ? 'Guardian Basic'
                : 'Guardian One',
          );
          expect(h.latest.guardian, guardian);
          expect(
            guardian ? h.latest.guardianMembership : h.latest.seekerMembership,
            '${guardian ? 'Guardian' : 'Seeker'} ${basic ? 'Basic' : 'One'}',
          );
          expect(find.byType(ZyraOneJourneyConceptShell), findsOneWidget);
          _expectNoRetiredControls();
          // A held touch formerly opened the rail. It now leaves the member page.
          final before = h.latest;
          final finger = await tester.startGesture(const Offset(215, 70));
          await tester.pump(const Duration(seconds: 4));
          await finger.up();
          await h.flush();
          _expectNoRetiredControls();
          expect(h.latest.guardian, before.guardian);
          expect(h.latest.tab, before.tab);
          if (capture) {
            final role = guardian ? 'guardian' : 'seeker';
            final plan = basic ? 'basic' : 'one';
            await h.capture(
              'profile',
              '${role}_$plan',
              '100',
              'code-only role/plan fixture; member Profile',
              fileName: '${role}_${plan}_profile__100.png',
            );
          }
        }
      }
      if (capture) {
        for (final guardian in [false, true]) {
          for (final scale in [1.0, 2.0]) {
            final role = guardian ? 'guardian' : 'seeker';
            final percent = (scale * 100).round();
            final h = BaselineHarness(
              tester,
              group: 'queue44_capture',
              outputRoot: captures,
              evidenceRoot: evidence,
              flatOutput: true,
              textScale: scale,
            );
            await h.mount(guardian: guardian, tab: 4);
            if (scale == 2) {
              await h.capture(
                'profile',
                '${role}_one',
                '$percent',
                'code-only fixture; actual member Profile',
                fileName: '${role}_one_profile__$percent.png',
              );
            }
            tester
                .widget<ZyraConceptProfilePresentation>(
                  find.byType(ZyraConceptProfilePresentation),
                )
                .onAction(ZyraConceptAccountAction.settings);
            await h.flush();
            _expectNoRetiredControls();
            await h.capture(
              'settings',
              role,
              '$percent',
              'actual Profile Settings callback',
              fileName: '${role}_settings__$percent.png',
            );
          }
        }
        final h = BaselineHarness(
          tester,
          group: 'queue44_capture',
          outputRoot: captures,
          evidenceRoot: evidence,
          flatOutput: true,
        );
        await h.mount();
        _expectNoRetiredControls();
        await h.capture(
          'browse',
          'seeker_one',
          '100',
          'default planned Seeker One',
          fileName: 'seeker_one_browse__100.png',
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
