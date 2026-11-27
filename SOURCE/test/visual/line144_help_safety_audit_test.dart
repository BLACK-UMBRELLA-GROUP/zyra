import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_help_safety_preview.dart';

import 'baseline_capture_support.dart';

Future<void> _expectScreen(
  BaselineHarness harness,
  ZyraHelpSafetyScreen screen,
  String route,
) async {
  harness.assertPage(route);
  final presenter = harness.tester.widget<ZyraHelpSafetyPreview>(
    find.byType(ZyraHelpSafetyPreview),
  );
  expect(presenter.screen, screen);
  expect(presenter.guardian, harness.guardian);
  await harness.auditText(route);
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  for (final guardian in [false, true]) {
    for (final basic in [false, true]) {
      final plan =
          '${guardian ? 'guardian' : 'seeker'}_${basic ? 'basic' : 'one'}';

      Future<BaselineHarness> openSettings(
        WidgetTester tester,
        String scenario,
      ) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final harness = BaselineHarness(
          tester,
          group: 'line144_help_${plan}_$scenario',
          reduceMotion: true,
        );
        await harness.mount(
          tab: 4,
          pages: const ['settings'],
          guardian: guardian,
          initialSeekerBasic: !guardian && basic,
          initialGuardianBasic: guardian && basic,
          seekerMembership: !guardian && basic ? 'Seeker Basic' : 'Seeker One',
          guardianMembership: guardian && basic
              ? 'Guardian Basic'
              : 'Guardian One',
          confirmSensitiveAction: () async => true,
        );
        harness.assertPage('settings');
        return harness;
      }

      testWidgets(
        'LOCK 37 $plan Contact support and sent',
        (tester) async {
          final h = await openSettings(tester, 'contact');
          await h.tap('concept_settings_contactSupport');
          await _expectScreen(h, ZyraHelpSafetyScreen.contact, 'help_contact');
          await h.tap('help_topic_Journeys');
          await tester.enterText(
            h.key('help_contact_message'),
            'Sample support message.',
          );
          await h.flush();
          await h.tap('help_action_Send message');
          await _expectScreen(
            h,
            ZyraHelpSafetyScreen.contactSent,
            'help_contact_sent',
          );
        },
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );

      testWidgets(
        'LOCK 37 $plan Privacy & data and data request',
        (tester) async {
          final h = await openSettings(tester, 'privacy_data');
          final privacy = h.key('concept_settings_privacyData');
          if (privacy.evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              privacy,
              170,
              scrollable: find.descendant(
                of: h.key('concept-current-settings-scroll'),
                matching: find.byType(Scrollable),
              ),
            );
          }
          await h.tapFinder(privacy);
          await _expectScreen(h, ZyraHelpSafetyScreen.privacy, 'help_privacy');
          await h.tap('help_row_Download my data');
          await _expectScreen(h, ZyraHelpSafetyScreen.data, 'help_data');
          await h.tap('help_action_Request my data');
          expect(h.key('help_data_requested'), findsOneWidget);
          await h.auditText('help_data_requested');
        },
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );

      testWidgets(
        'LOCK 37 $plan Advanced, delete, confirm and closed',
        (tester) async {
          final h = await openSettings(tester, 'delete');
          await h.tap('concept_settings_advanced');
          await _expectScreen(
            h,
            ZyraHelpSafetyScreen.advanced,
            'help_advanced',
          );
          await h.tap('help_row_Delete my account');
          await _expectScreen(h, ZyraHelpSafetyScreen.delete, 'help_delete');
          await h.tap('help_delete_open_confirm');
          expect(h.key('help_delete_confirm'), findsOneWidget);
          await h.auditText('help_delete_confirm');
          await h.tap('help_delete_confirm');
          await _expectScreen(h, ZyraHelpSafetyScreen.closed, 'help_closed');
        },
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );

      if (!guardian) {
        testWidgets(
          'LOCK 37 $plan Report sent',
          (tester) async {
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final h = BaselineHarness(
              tester,
              group: 'line144_help_${plan}_report',
              reduceMotion: true,
            );
            await h.mount(
              tab: 0,
              pages: const ['profile'],
              personId: 'draft-sara',
              initialSeekerBasic: basic,
              seekerMembership: basic ? 'Seeker Basic' : 'Seeker One',
            );
            h.assertPage('profile');
            await h.tap('full_profile_options');
            await h.tap('full_profile_option_report');
            h.assertPage('safety');
            await h.tap('draft_report_submit');
            await _expectScreen(
              h,
              ZyraHelpSafetyScreen.reportSent,
              'help_report_sent',
            );
          },
          variant: TargetPlatformVariant.only(TargetPlatform.iOS),
        );
      }
    }
  }
}
