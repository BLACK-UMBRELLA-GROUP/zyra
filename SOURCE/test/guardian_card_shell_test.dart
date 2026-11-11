// Actual admitted Founder shell ownership, permission and confirm regression.
import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter/widgets.dart' show EdgeInsets, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/subscription/zyra_one_upgrade_page.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import 'support/guardian_card_driver.dart';
import 'support/zyra_hidden_dev_controls_driver.dart';
import 'visual/baseline_capture_support.dart';

const _hassan = 'draft-guardian-hassan',
    _additional = 'draft-guardian-yusuf',
    _sara = 'draft-sara';
const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/LOCK19_GUARDIAN_CARD_2026-10-31';
ZyraOneJourneyGuardianCards _page(WidgetTester t) =>
    t.widget(find.byType(ZyraOneJourneyGuardianCards));
void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  BaselineHarness harness(WidgetTester t) {
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    return BaselineHarness(t, group: 'lock19_shell', evidenceRoot: _evidence);
  }

  test('model defaults and view revocation retain entitlement boundary', () {
    final model = ViewRequestDraftModel(
      capacity: 3,
      clock: () => DateTime.utc(2026, 10, 29, 12),
    )..seedJourneys(2);
    expect(
      model.sampleGuardianAccessFor(_hassan, _sara, isMain: true).chat,
      isTrue,
    );
    expect(model.sampleGuardianAccessFor(_additional, _sara).chat, isFalse);
    expect(
      model.setSampleGuardianJourneyAccess(
        _additional,
        _sara,
        chatEnabled: true,
      ),
      isTrue,
    );
    expect(
      model.setSampleGuardianJourneyAccess(
        _additional,
        _sara,
        viewEnabled: false,
      ),
      isTrue,
    );
    expect(model.sampleGuardianAccessFor(_additional, _sara), (
      view: false,
      chat: false,
    ));
    expect(
      model.setSampleGuardianJourneyAccess(
        _additional,
        _sara,
        viewEnabled: true,
      ),
      isTrue,
    );
    expect(model.sampleGuardianAccessFor(_additional, _sara).chat, isFalse);
    model.setSampleGuardianMembership(
      _additional,
      DraftGuardianMembership.basic,
    );
    expect(
      model.setSampleGuardianJourneyAccess(
        _additional,
        _sara,
        chatEnabled: true,
      ),
      isFalse,
    );
  });
  testWidgets(
    'actual shell saves a Past summary bit and confirms cancellation without opening Add',
    (t) async {
      final h = harness(t);
      await h.mount(
        tab: 3,
        model: ViewRequestDraftModel(
          capacity: 3,
          clock: () => DateTime.utc(2026, 10, 29, 12),
        )..seedJourneys(2),
      );
      await h.tap('guardian-card-history-$_hassan');
      expect(h.latest.guardianHistory[_hassan], isTrue);
      expect(find.text('MAIN GUARDIAN'), findsOneWidget);
      expect(find.text('JOURNEY ACCESS'), findsOneWidget);
      await swipeGuardianCard(t);
      await h.flush();
      await swipeGuardianCard(t);
      await h.flush();
      expect(find.text('Waiting for Omar to accept'), findsOneWidget);
      expect(find.textContaining('Omar has until 9 Nov'), findsOneWidget);
      expect(find.text('Send invitation again'), findsNothing);
      expect(find.text('Send again'), findsNothing);
      await h.tap('guardian-card-cancel-invitation');
      expect(find.text('Cancel Omar’s invitation?'), findsOneWidget);
      await t.tap(find.text('Keep invitation'));
      await h.flush();
      expect(find.text('Waiting for Omar to accept'), findsOneWidget);
      await h.tap('guardian-card-cancel-invitation');
      await h.tap('guardian-card-confirm-cancel-invitation');
      expect(find.text('Omar'), findsNothing);
      expect(h.latest.pages, isEmpty);
      expect(find.byKey(const ValueKey('guardian-card-add')), findsOneWidget);
    },
  );
  testWidgets('the expired Omar invitation has no resend or Add route', (
    t,
  ) async {
    final h = harness(t);
    await h.mount(tab: 3, previewClock: () => DateTime.utc(2026, 11, 9));
    await swipeGuardianCard(t);
    await h.flush();
    await swipeGuardianCard(t);
    await h.flush();
    expect(find.text('INVITATION EXPIRED'), findsOneWidget);
    expect(find.text('Expired 9 Nov'), findsOneWidget);
    expect(find.text('The invitation has expired'), findsOneWidget);
    expect(find.text('Send again'), findsNothing);
    expect(find.text('Cancel invitation'), findsNothing);
    expect(find.byKey(const ValueKey('guardian-card-center')), findsNothing);
    expect(h.latest.pages, isEmpty);
  });
  testWidgets(
    'a restored invitation preserves its original preview clock start',
    (t) async {
      final h = harness(t);
      final started = DateTime.utc(2026, 11, 7);
      final initial = ZyraPreviewNavigationCheckpoint(
        guardian: false,
        model: ViewRequestDraftModel(capacity: 3).snapshot(),
        tab: 3,
        pages: const [],
        guardianPage: 2,
        guardianInvitationClockStart: started,
      );
      await h.mount(
        checkpoint: initial,
        previewClock: () => DateTime.utc(2026, 11, 11),
      );
      expect(find.text('Waiting for Omar to accept'), findsOneWidget);
      final saved = h.latest;
      expect(saved.guardianInvitationClockStart, started);
      await h.mount(
        checkpoint: saved,
        previewClock: () => DateTime.utc(2026, 11, 14),
      );
      expect(find.text('The invitation has expired'), findsOneWidget);
      expect(h.latest.guardianInvitationClockStart, started);
    },
  );
  testWidgets(
    'an invitation that expires during confirmation stays on the expired card',
    (t) async {
      final h = harness(t);
      var now = DateTime.utc(2026, 11, 8, 23, 59);
      await h.mount(tab: 3, previewClock: () => now);
      await swipeGuardianCard(t);
      await h.flush();
      await swipeGuardianCard(t);
      await h.flush();
      await h.tap('guardian-card-cancel-invitation');
      expect(find.text('Cancel Omar’s invitation?'), findsOneWidget);
      now = DateTime.utc(2026, 11, 9);
      await h.tap('guardian-card-confirm-cancel-invitation');
      expect(find.text('The invitation has expired'), findsOneWidget);
      expect(find.text('Cancel invitation'), findsNothing);
      expect(find.byKey(const ValueKey('guardian-card-add')), findsNothing);
    },
  );
  for (final (size, padding) in [
    (const Size(430, 932), const EdgeInsets.only(top: 59, bottom: 34)),
    (const Size(375, 667), const EdgeInsets.only(top: 20)),
  ]) {
    final dimensions = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('LOCK19 V11 free-place fixture route at $dimensions', (
      t,
    ) async {
      const captures = String.fromEnvironment(
        'ZYRA_LINE81_FREE_PLACE_CAPTURE_DIR',
      );
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final h = BaselineHarness(
        t,
        group: 'line81_guardian_free_place',
        evidenceRoot: _evidence,
        outputRoot: captures.isEmpty ? _evidence : captures,
        flatOutput: true,
        logicalSize: size,
        safePadding: padding,
      );
      final now = DateTime.utc(2026, 11, 11);
      final expiry = now.add(const Duration(days: 7));
      await h.mount(
        guardian: true,
        previewClock: () => now,
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: true,
          model: ViewRequestDraftModel(capacity: 1).snapshot(),
          tab: 2,
          pages: const [],
          seekerMembership: 'Seeker Basic',
          guardianMembership: 'Guardian Basic',
          removedGuardians: const [_hassan],
          guardianTabs: ZyraGuardianTabsSnapshot(
            freePlaceInviteExpiresAt: expiry,
          ),
        ),
      );
      expect(h.key('focus-item-free-place-invite'), findsOneWidget);
      if (captures.isNotEmpty) {
        await h.capture(
          'guardian_free_place',
          'guardian_free_place',
          'needs_you_$dimensions',
          'Guardian My ZYRA with the explicit Founder invitation fixture',
        );
      }
      await h.tap('guardian_free_place_view');
      h.assertPage('guardian_free_place_invite');
      expect(find.text('Adam’s free place is taken'), findsOneWidget);
      expect(find.text('GUARDIAN INVITATION'), findsOneWidget);
      expect(find.text('Adam is on Seeker Basic'), findsOneWidget);
      expect(find.text('Join on Guardian One'), findsOneWidget);
      expect(find.text('Or wait for Adam'), findsOneWidget);
      expect(find.textContaining('Hassan'), findsNothing);
      expect(find.textContaining('Main Guardian'), findsNothing);
      expect(h.key('guardian_free_place_join').hitTestable(), findsOneWidget);
      expect(
        h.key('guardian_free_place_dismiss').hitTestable(),
        findsOneWidget,
      );
      expect(
        t.getBottomLeft(h.key('guardian_free_place_dismiss')).dy,
        lessThanOrEqualTo(size.height - padding.bottom),
      );
      expect(
        t.getSize(h.key('guardian_free_place_monogram')),
        const Size.square(96),
      );
      if (captures.isNotEmpty) {
        await h.capture(
          'guardian_free_place',
          'guardian_free_place',
          'invitation_$dimensions',
          'Guardian free-place-taken page with three rows and two actions',
        );
      }
      await h.tap('guardian_free_place_join');
      expect(find.byType(ZyraOneUpgradePage), findsOneWidget);
      h.assertPage('one_upgrade');
      await returnZyraPreviewPage(t);
      h.assertPage('guardian_free_place_invite');
      await returnZyraPreviewPage(t);
      expect(h.latest.pages, isEmpty);
      expect(h.key('focus-item-free-place-invite'), findsOneWidget);
      await h.tap('guardian_free_place_view');
      await h.tap('guardian_free_place_dismiss');
      expect(h.latest.pages, isEmpty);
      expect(h.key('focus-item-free-place-invite'), findsNothing);
      expect(h.latest.guardianTabs.freePlaceInviteExpiresAt, expiry);
      expect(h.latest.guardianMembership, 'Guardian Basic');
      expect(h.latest.removedGuardians, contains(_hassan));
    });
  }

  testWidgets(
    'actual shell View/Chat target and retained mutation deny after page change',
    (t) async {
      final h = harness(t);
      await h.mount(
        tab: 3,
        model: ViewRequestDraftModel(
          capacity: 3,
          clock: () => DateTime.utc(2026, 10, 29, 12),
        )..seedJourneys(2),
      );
      await swipeGuardianCard(t);
      await h.flush();
      final old = _page(t);
      expect(find.text('JOURNEY ACCESS'), findsOneWidget);
      expect(old.journeysFor(_additional), isNotEmpty);
      await h.tap('guardian-card-chat-$_additional-$_sara');
      expect(
        h.latest.model.guardianAccess['$_additional|$_sara']?.chat,
        isTrue,
      );
      await h.tap('guardian-card-view-$_additional-$_sara');
      expect(h.latest.model.guardianAccess['$_additional|$_sara'], (
        view: false,
        chat: false,
      ));
      await swipeGuardianCard(t);
      await h.flush();
      old.onPermission(_additional, _sara, view: true, chat: true);
      old.onHistory(_additional, true);
      await h.flush();
      expect(h.latest.model.guardianAccess['$_additional|$_sara'], (
        view: false,
        chat: false,
      ));
      expect(h.latest.guardianHistory[_additional], isNot(true));
    },
  );
  testWidgets(
    'actual local Family invite never grants Chat and can be cancelled',
    (t) async {
      final model =
          ViewRequestDraftModel(
              capacity: 3,
              clock: () => DateTime.utc(2026, 10, 29, 12),
            )
            ..seedJourneys(2)
            ..setSampleGuardianMembership(
              _additional,
              DraftGuardianMembership.basic,
            );
      final h = harness(t);
      await h.mount(tab: 3, model: model);
      await swipeGuardianCard(t);
      await h.flush();
      final old = _page(t);
      await h.tap('guardian-card-chat-$_additional-$_sara');
      expect(find.text('Yusuf can view, but not chat'), findsOneWidget);
      old.onPermission(_additional, _sara, chat: true);
      old.onHistory(_additional, true);
      await h.tap('guardian-family-introduction-primary');
      await h.tap('guardian-family-price-primary');
      await h.tap('guardian-family-invited-primary');
      expect(find.text('Invited'), findsNWidgets(2));
      expect(
        h.latest.model.guardianMemberships[_additional],
        DraftGuardianMembership.basic,
      );
      expect(
        h.latest.model.guardianAccess['$_additional|$_sara']?.chat,
        isFalse,
      );
      expect(h.latest.guardianHistory[_additional], isNot(true));
      await h.tap('guardian-card-chat-$_additional-$_sara');
      await h.tap('guardian-family-invited-secondary');
      expect(find.text('Invited'), findsNothing);
      expect(find.text('Chat'), findsNWidgets(2));
    },
  );
  testWidgets(
    'actual Main/Remove confirm flows preserve other Guardian and Journey facts',
    (t) async {
      final h = harness(t);
      await h.mount(
        tab: 3,
        model: ViewRequestDraftModel(
          capacity: 3,
          clock: () => DateTime.utc(2026, 10, 29, 12),
        )..seedJourneys(2),
      );
      final states = h.latest.model.states;
      await h.tap('guardian-card-menu');
      expect(find.byType(ZyraShellNavigation).hitTestable(), findsNothing);
      await h.tap('guardian-clear-main');
      expect(h.latest.model.ownMainGuardianPresent, isTrue);
      await h.tapFinder(
        find.byKey(ValueKey('guardian-clear-main-confirmation-keep')),
      );
      expect(h.latest.model.ownMainGuardianPresent, isTrue);
      await h.tap('guardian-card-menu');
      await h.tap('guardian-clear-main');
      await h.tap('guardian-clear-main-confirmation-approve');
      expect(h.latest.model.ownMainGuardianPresent, isFalse);
      expect(h.latest.model.states, states);
      expect(
        find.byKey(const ValueKey('guardian-card-$_hassan')),
        findsOneWidget,
      );
      await h.tap('guardian-card-menu');
      await h.tap('guardian-remove');
      await h.tap('guardian-remove-confirmation-approve');
      expect(h.latest.removedGuardians, contains(_hassan));
      expect(h.latest.removedGuardians, isNot(contains(_additional)));
      expect(h.latest.model.states, states);
    },
  );
  testWidgets(
    'actual Basic keeps its roster and routes Add and upgrade separately',
    (t) async {
      final h = harness(t);
      await h.mount(
        tab: 3,
        initialSeekerBasic: true,
        seekerMembership: 'Seeker Basic',
      );
      expect(_page(t).basic, isTrue);
      await swipeGuardianCard(t);
      await h.flush();
      expect(
        find.byKey(const ValueKey('guardian-card-$_additional')),
        findsOneWidget,
      );
      await swipeGuardianCard(t);
      await h.flush();
      expect(find.text('Add a Guardian'), findsNWidgets(2));
      expect(find.text('Free'), findsOneWidget);
      expect(find.text('Omar'), findsNothing);
      await h.tapText('Seeker One: any 10 Guardians ›');
      h.assertPage('one_upgrade');
      expect(find.text('Journey places'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
      await t.binding.handlePopRoute();
      await h.flush();
      await h.tap('guardian-card-center');
      h.assertPage('guardian_invite');
    },
  );
  testWidgets(
    'actual tab switch invalidates retained confirm and permission delegates',
    (t) async {
      final h = harness(t);
      await h.mount(
        tab: 3,
        model: ViewRequestDraftModel(
          capacity: 3,
          clock: () => DateTime.utc(2026, 10, 29, 12),
        )..seedJourneys(2),
      );
      final old = _page(t);
      t.widget<ZyraShellNavigation>(find.byType(ZyraShellNavigation)).onTap(4);
      await h.flush();
      expect(await old.clearMain(_hassan), isFalse);
      expect(await old.remove(_hassan), isNotNull);
      old.onHistory(_hassan, true);
      old.onPermission(_hassan, _sara, view: false);
      expect(h.latest.model.ownMainGuardianPresent, isTrue);
      expect(h.latest.guardianHistory[_hassan], isNot(true));
    },
  );
  testWidgets(
    'actual Make Main confirms into existing notice without removing links or Journeys',
    (t) async {
      final h = harness(t);
      await h.mount(
        tab: 3,
        model: ViewRequestDraftModel(capacity: 3)..seedJourneys(2),
      );
      final states = h.latest.model.states;
      await swipeGuardianCard(t);
      await h.flush();
      await h.tap('guardian-card-menu');
      await h.tap('guardian-make-main');
      expect(h.latest.mainGuardianId, _hassan);
      await h.tap('guardian-make-main-confirmation-approve');
      h.assertPage('guardian_main_notice');
      expect(h.latest.mainGuardianId, _additional);
      expect(h.latest.model.states, states);
      expect(h.latest.removedGuardians, isEmpty);
    },
  );
}
