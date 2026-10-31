import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_draft_browse_utility_presentation.dart';
import 'package:zyra/dev/zyra_draft_journey_block_hide_sheet.dart';
import 'package:zyra/dev/zyra_one_journey_account_presentation.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/widgets/zyra_browse_options_button.dart';
import 'package:zyra/widgets/zyra_shell_navigation.dart';
import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

const _root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const _out = '$_root/PRODUCT/APPROVED/JOURNEY_BLOCK_HIDE/BUILT/V2';
const _evidence = '$_root/REPORTS/EVIDENCE/LOCK16_BLOCK_HIDE_V2_2026-10-31';
const _render = bool.fromEnvironment('ZYRA_LOCK16_RENDER');
const _sara = 'draft-sara';
const _aisha = 'draft-aisha';
Finder _k(String id) => find.byKey(ValueKey(id));

ViewRequestDraftModel _fixture({bool basic = false, bool preparing = false}) {
  final model = ViewRequestDraftModel(capacity: basic ? 1 : 3);
  if (preparing) {
    expect(model.request(_sara), isTrue);
    expect(model.simulateRecipientAccept(_sara), isTrue);
  } else {
    expect(model.seedJourneys(basic ? 1 : 2), isTrue);
  }
  return model;
}

BaselineHarness _h(WidgetTester t, {double scale = 1}) {
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  return BaselineHarness(
    t,
    group: 'lock16_v2',
    outputRoot: _out,
    evidenceRoot: _evidence,
    flatOutput: true,
    textScale: scale,
  );
}

ViewRequestDraftModel _model(BaselineHarness h) =>
    ViewRequestDraftModel.fromSnapshot(h.latest.model);
Future<void> _cap(BaselineHarness h, String name) async {
  if (_render) {
    await h.capture(
      'safety',
      name,
      'locked_v2',
      'Actual shell and local fixture; report Submit stays disabled; no transport.',
      fileName: '$name.png',
    );
  }
}

Future<void> _open(BaselineHarness h, {required bool hide}) async {
  if (find.byType(ZyraDraftReportPresentation).evaluate().isEmpty) {
    if (_k('draft_safety').evaluate().isNotEmpty) {
      await h.tap('draft_safety');
    } else {
      final button = h.tester.widget<ZyraBrowseOptionsButton>(
        find.byType(ZyraBrowseOptionsButton).first,
      );
      button.onOpen(button.profile);
      await h.flush();
      await _nav(h, 'Report');
    }
  }
  await h.tap(hide ? 'draft_safety_hide' : 'draft_safety_block');
}

Future<void> _nav(BaselineHarness h, String label) async {
  await h.tester.pumpAndSettle();
  await expandZyraPreviewTabBarIfIdle(h.tester);
  final nav = find.byType(ZyraShellNavigation);
  final item = h.tester
      .widget<ZyraShellNavigation>(nav)
      .items
      .singleWhere((i) => i.label == label);
  final icon = find.descendant(of: nav, matching: find.byIcon(item.icon));
  final owner = find
      .ancestor(
        of: icon,
        matching: find.byWidgetPredicate(
          (w) => w is GestureDetector && w.onTapDown != null,
        ),
      )
      .first;
  expect(owner.hitTestable(), findsOneWidget);
  await h.tester.tapAt(h.tester.getCenter(icon));
  await h.flush();
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  setUp(() async {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await ZyraAccountState.synchronize('lock16-owner');
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
  });

  for (final hide in [false, true]) {
    for (final basic in [false, true]) {
      for (final preparing in [false, true]) {
        testWidgets(
          '${hide ? 'Hide' : 'Block'} ${basic ? 'Basic' : 'One'} ${preparing ? 'preparing' : 'active'} warns, keeps, confirms exact attempt and toast',
          (t) async {
            final h = _h(t);
            await h.mount(
              tab: 1,
              pages: ['profile'],
              model: _fixture(basic: basic, preparing: preparing),
              initialSeekerBasic: basic,
              seekerMembership: basic ? 'Seeker Basic' : 'Seeker One',
            );
            await h.tap('draft_safety');
            await h.tap('draft_report_reason_fakeProfile');
            final before = h.latest.model;
            await _open(h, hide: hide);
            expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsOneWidget);
            expect(
              find.text(
                "You're in a Journey with Sara. ${hide ? 'Hiding' : 'Blocking'} ends it first.",
              ),
              findsOneWidget,
            );
            if (!basic && !preparing) {
              await _cap(h, hide ? 'b02_hide_confirm' : 'b01_block_confirm');
            }
            await h.tap('journey_person_safety_keep');
            expect(h.latest.model.states, before.states);
            expect(h.latest.model.hiddenPeers, before.hiddenPeers);
            expect(h.latest.model.blockedPeers, before.blockedPeers);
            expect(h.latest.model.endedAttempts, before.endedAttempts);
            await _open(h, hide: hide);
            await h.tap('journey_person_safety_confirm');
            final after = _model(h);
            expect(after.stateFor(_sara), DraftJourneyState.ended);
            expect(after.occupiedCount, (preparing || basic ? 1 : 2) - 1);
            expect(after.endedAttemptsFor(_sara), hasLength(1));
            expect(after.isHidden(_sara), hide);
            expect(after.isBlocked(_sara), !hide);
            expect(after.stateFor(_aisha), before.states[_aisha]);
            expect(h.latest.tab, 1);
            expect(h.latest.pages, isEmpty);
            expect(
              find.text(
                hide
                    ? "Your Journey with Sara has ended. Sara won't appear again."
                    : 'Your Journey with Sara has ended and Sara is blocked.',
              ),
              findsOneWidget,
            );
            if (!basic && !preparing && !hide) {
              await _cap(h, 'b03_journey_tab_after');
            }
          },
        );
      }
    }

    testWidgets(
      '${hide ? 'Hide' : 'Block'} absent person stays immediate with no warning or report',
      (t) async {
        final h = _h(t);
        await h.mount(
          tab: 0,
          pages: ['profile'],
          model: ViewRequestDraftModel(capacity: 3),
        );
        final before = h.latest.model;
        await _open(h, hide: hide);
        expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
        expect(_model(h).isHidden(_sara), hide);
        expect(_model(h).isBlocked(_sara), !hide);
        expect(h.latest.model.states, before.states);
        expect(h.latest.model.endedAttempts, before.endedAttempts);
        expect(h.latest.tab, 0);
      },
    );

    testWidgets(
      '${hide ? 'Hide' : 'Block'} accepted waiting never ends its held other Journey',
      (t) async {
        final m = ViewRequestDraftModel(capacity: 1)..seedJourneys(1);
        expect(m.seedReceived('draft-hana'), isTrue);
        expect(m.setPeerOccupied('draft-hana', true), isTrue);
        expect(
          m.replaceJourneyForRequest('draft-hana', _sara, incoming: true),
          isTrue,
        );
        expect(m.isAcceptedWaiting('draft-hana'), isTrue);
        final h = _h(t);
        await h.mount(
          tab: 2,
          pages: ['profile'],
          personId: 'draft-hana',
          model: m,
        );
        await _open(h, hide: hide);
        expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
        expect(_model(h).stateFor(_sara), DraftJourneyState.active);
        expect(
          _model(h).stateFor('draft-hana'),
          DraftJourneyState.acceptedWaiting,
        );
        expect(_model(h).occupiedCount, 1);
        expect(h.latest.model.endedAttempts, isEmpty);
      },
    );
  }

  testWidgets(
    'barrier dismissal preserves report choice and all Journey state',
    (t) async {
      final h = _h(t);
      await h.mount(tab: 1, pages: ['profile'], model: _fixture());
      await h.tap('draft_safety');
      await h.tap('draft_report_reason_fakeProfile');
      final before = h.latest.model;
      await _open(h, hide: false);
      await t.tapAt(const Offset(12, 100));
      await h.flush();
      expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
      expect(h.latest.model.states, before.states);
      expect(h.latest.model.hiddenPeers, before.hiddenPeers);
      expect(h.latest.model.blockedPeers, before.blockedPeers);
      expect(h.latest.model.endedAttempts, before.endedAttempts);
      expect(_k('draft_report_submit'), findsOneWidget);
      expect(
        t.widget<OutlinedButton>(_k('draft_report_submit')).onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'Journey options and View profile warn; Profiles keeps occupied people excluded',
    (t) async {
      for (final route in ['journey_options', 'profile', 'browse']) {
        String? browseTarget;
        final h = _h(t);
        await h.mount(
          tab: route == 'browse' ? 0 : 1,
          pages: route == 'browse' ? [] : [route],
          model: _fixture(),
          checkpoint: route == 'browse'
              ? ZyraPreviewNavigationCheckpoint(
                  guardian: false,
                  model: _fixture().snapshot(),
                  tab: 0,
                  pages: [],
                  browseId: _sara,
                  browseHistory: [_sara],
                  browseCursor: 0,
                )
              : null,
        );
        if (route == 'journey_options') {
          await h.tap('draft_options_report_$_sara');
        } else if (route == 'profile') {
          await h.tap('draft_safety');
        } else {
          final button = t.widget<ZyraBrowseOptionsButton>(
            find.byType(ZyraBrowseOptionsButton).first,
          );
          browseTarget = button.profile!.id;
          expect(browseTarget, isNot(_sara));
          button.onOpen(button.profile);
          await h.flush();
          await _nav(h, 'Report');
        }
        expect(find.byType(ZyraDraftReportPresentation), findsOneWidget);
        await _open(h, hide: true);
        if (route == 'browse') {
          expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
          expect(_model(h).isHidden(browseTarget!), isTrue);
        } else {
          expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsOneWidget);
          await h.tap('journey_person_safety_keep');
        }
        expect(_model(h).stateFor(_sara), DraftJourneyState.active);
      }
    },
  );

  testWidgets(
    'Browse no-Journey Hide preserves current Journey; hidden inspection Block warns',
    (t) async {
      var h = _h(t);
      await h.mount(
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: _fixture().snapshot(),
          tab: 0,
          pages: [],
          browseId: _sara,
          browseHistory: [_sara],
          browseCursor: 0,
        ),
      );
      final button = t.widget<ZyraBrowseOptionsButton>(
        find.byType(ZyraBrowseOptionsButton).first,
      );
      button.onOpen(button.profile);
      await h.flush();
      expect(button.profile!.id, isNot(_sara));
      await _nav(h, 'Hide profile');
      expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsNothing);
      await h.tap('browse-hide-confirm');
      expect(_model(h).isHidden(button.profile!.id), isTrue);
      expect(_model(h).stateFor(_sara), DraftJourneyState.active);
      final m = _fixture()..hide(_sara);
      h = _h(t);
      await h.mount(
        tab: 4,
        pages: ['settings', 'account_action', 'profile'],
        model: m,
      );
      // The existing account destination is needed for hidden inspection.
      final c = ZyraPreviewNavigationCheckpoint(
        guardian: false,
        model: m.snapshot(),
        tab: 4,
        pages: ['settings', 'account_action', 'profile'],
        personId: _sara,
        accountDestination: ZyraConceptAccountAction.hiddenProfiles.name,
      );
      await h.mount(checkpoint: c);
      await h.tap('concept_hidden_inspection_block');
      expect(find.byType(ZyraDraftJourneyBlockHideSheet), findsOneWidget);
      await h.tap('journey_person_safety_confirm');
      expect(_model(h).stateFor(_sara), DraftJourneyState.ended);
      expect(_model(h).isBlocked(_sara), isTrue);
    },
  );

  for (final hide in [false, true]) {
    testWidgets(
      '${hide ? 'Hide' : 'Block'} sheet 200 percent narrow scroll reaches both actions',
      (t) async {
        final h = _h(t, scale: 2);
        await h.mount(tab: 1, pages: ['profile'], model: _fixture());
        await _open(h, hide: hide);
        await _cap(
          h,
          hide
              ? 'b02_hide_confirm__text200_top'
              : 'b01_block_confirm__text200_top',
        );
        await t.ensureVisible(_k('journey_person_safety_keep'));
        await h.flush();
        expect(_k('journey_person_safety_keep').hitTestable(), findsOneWidget);
        await t.ensureVisible(_k('journey_person_safety_confirm'));
        await h.flush();
        expect(
          _k('journey_person_safety_confirm').hitTestable(),
          findsOneWidget,
        );
        expect(
          t.getSize(_k('journey_person_safety_confirm')).height,
          greaterThanOrEqualTo(48),
        );
        await _cap(
          h,
          hide
              ? 'b02_hide_confirm__text200_actions'
              : 'b01_block_confirm__text200_actions',
        );
        t.view.physicalSize = const Size(960, 2136);
        await h.flush();
        await t.ensureVisible(_k('journey_person_safety_keep'));
        await h.flush();
        expect(_k('journey_person_safety_keep').hitTestable(), findsOneWidget);
        await t.ensureVisible(_k('journey_person_safety_confirm'));
        await h.flush();
        expect(
          _k('journey_person_safety_confirm').hitTestable(),
          findsOneWidget,
        );
        await h.tap('journey_person_safety_confirm');
        expect(_model(h).stateFor(_sara), DraftJourneyState.ended);
      },
    );
  }
}
