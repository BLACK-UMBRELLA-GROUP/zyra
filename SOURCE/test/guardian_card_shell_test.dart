// Actual admitted Founder shell ownership, permission and confirm regression.
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_cards.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
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
    'actual shell saves one Past summary bit without flipping and opens unchanged code route',
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
      await h.tap('guardian-card-center');
      expect(find.text('JOURNEY ACCESS'), findsOneWidget);
      await h.tap('guardian-card-next');
      await h.tap('guardian-card-next');
      expect(find.text('Waiting for Omar'), findsOneWidget);
      await h.tap('guardian-card-center');
      h.assertPage('guardian_invite');
    },
  );
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
      await h.tap('guardian-card-next');
      await h.tap('guardian-card-center');
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
      await h.tap('guardian-card-next');
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
      await h.tap('guardian-card-next');
      await h.tap('guardian-card-center');
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
      await h.tap('guardian-card-center');
      await h.tap('guardian-clear-main');
      expect(h.latest.model.ownMainGuardianPresent, isTrue);
      await h.tapText('Cancel');
      expect(h.latest.model.ownMainGuardianPresent, isTrue);
      await h.tap('guardian-clear-main');
      await h.tapText('Confirm');
      expect(h.latest.model.ownMainGuardianPresent, isFalse);
      expect(h.latest.model.states, states);
      await h.tap('guardian-remove');
      await h.tapText('Confirm');
      expect(h.latest.removedGuardians, contains(_hassan));
      expect(h.latest.removedGuardians, isNot(contains(_additional)));
      expect(h.latest.model.states, states);
    },
  );
  testWidgets(
    'actual Basic displays one Guardian and routes locked Add to membership',
    (t) async {
      final h = harness(t);
      await h.mount(
        tab: 3,
        initialSeekerBasic: true,
        seekerMembership: 'Seeker Basic',
      );
      expect(_page(t).basic, isTrue);
      await h.tap('guardian-card-next');
      expect(find.text('Add more Guardians'), findsOneWidget);
      expect(find.text('Omar'), findsNothing);
      await h.tap('guardian-card-center');
      h.assertPage('membership');
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
      await h.tap('guardian-card-next');
      await h.tap('guardian-card-center');
      await h.tap('guardian-make-main');
      expect(h.latest.mainGuardianId, _hassan);
      await h.tapText('Confirm');
      h.assertPage('guardian_main_notice');
      expect(h.latest.mainGuardianId, _additional);
      expect(h.latest.model.states, states);
      expect(h.latest.removedGuardians, isEmpty);
    },
  );
}
