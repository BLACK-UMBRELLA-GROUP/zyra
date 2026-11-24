import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';

import 'support/guardian_card_driver.dart';
import 'visual/baseline_capture_support.dart';

const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/SOURCE/build/line134/privacy_sensitive';

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);

  BaselineHarness harness(WidgetTester tester) {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return BaselineHarness(
      tester,
      group: 'line134_sensitive',
      evidenceRoot: _evidence,
    );
  }

  testWidgets('sign out other devices is held on failed phone check', (
    tester,
  ) async {
    var checks = 0;
    var allow = false;
    final h = harness(tester);
    await h.mount(
      tab: 4,
      pages: const ['settings'],
      confirmSensitiveAction: () async {
        checks++;
        return allow;
      },
    );
    await h.tap('concept_settings_signInSecurity');
    await h.tap('privacy_sign_out_other_devices');
    expect(checks, 1);
    expect(find.text('All other devices are signed out.'), findsNothing);
    allow = true;
    await h.tap('privacy_sign_out_other_devices');
    expect(checks, 2);
    expect(find.text('Only this phone is signed in.'), findsOneWidget);
  });

  testWidgets('download and final delete each stop when phone check fails', (
    tester,
  ) async {
    var checks = 0;
    var allow = false;
    final h = harness(tester);
    await h.mount(
      tab: 4,
      pages: const ['settings'],
      confirmSensitiveAction: () async {
        checks++;
        return allow;
      },
    );
    await h.tap('concept_settings_advanced');
    await h.tap('help_row_Download my data');
    await h.tap('help_action_Request my data');
    expect(checks, 1);
    expect(find.textContaining('Requested on'), findsNothing);
    allow = true;
    await h.tap('help_action_Request my data');
    expect(checks, 2);
    expect(find.textContaining('Requested on'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await h.flush();
    await h.tap('help_row_Delete my account');
    await h.tap('help_delete_open_confirm');
    allow = false;
    await h.tap('help_delete_confirm');
    expect(checks, 3);
    expect(find.text('Your account is closed'), findsNothing);
    await h.tap('help_delete_open_confirm');
    allow = true;
    await h.tap('help_delete_confirm');
    expect(checks, 4);
    expect(h.latest.pages.last, 'help_closed');
  });

  testWidgets('Make Main Guardian cannot change on cancelled phone check', (
    tester,
  ) async {
    var checks = 0;
    var allow = false;
    final h = harness(tester);
    await h.mount(
      tab: 3,
      confirmSensitiveAction: () async {
        checks++;
        return allow;
      },
    );
    await swipeGuardianCard(tester);
    await h.flush();
    final page = tester.widget<ZyraOneJourneyGuardianCards>(
      find.byType(ZyraOneJourneyGuardianCards),
    );
    expect(await page.makeMain('draft-guardian-yusuf'), isFalse);
    expect(checks, 1);
    expect(h.latest.mainGuardianId, 'draft-guardian-hassan');
    allow = true;
    expect(await page.makeMain('draft-guardian-yusuf'), isTrue);
    expect(checks, 2);
    expect(h.latest.mainGuardianId, 'draft-guardian-yusuf');
  });

  testWidgets('real Make Main menu stays quiet when phone check is cancelled', (
    tester,
  ) async {
    var checks = 0;
    final h = harness(tester);
    await h.mount(
      tab: 3,
      confirmSensitiveAction: () async {
        checks++;
        return false;
      },
    );
    await swipeGuardianCard(tester);
    await h.flush();
    await h.tap('guardian-card-menu');
    await h.tap('guardian-make-main');
    await h.tap('guardian-make-main-confirmation-approve');
    expect(checks, 1);
    expect(h.latest.mainGuardianId, 'draft-guardian-hassan');
    expect(
      find.text("That didn't go through. Please try again."),
      findsNothing,
    );
  });

  testWidgets('someone else blocking me never appears in my blocked list', (
    tester,
  ) async {
    final model = ViewRequestDraftModel(capacity: 3);
    expect(model.setPeerBlock('draft-sara', true), isTrue);
    final h = harness(tester);
    await h.mount(tab: 4, pages: const ['settings'], model: model);
    await h.tap('concept_settings_hiddenProfiles');
    expect(find.text('No one is blocked.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('privacy_unblock_draft-sara')),
      findsNothing,
    );
  });
}
