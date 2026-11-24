// LOCK 35 / Q168: actual admitted Founder shell, offline sample data only.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_one_journey_monogram_presentation.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/models/zyra_error_state.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import 'package:zyra/widgets/zyra_full_screen_error.dart';
import 'package:zyra/widgets/zyra_profiles_components.dart';
import 'package:zyra/widgets/zyra_swipe_track.dart';

import '../support/received_request_fixture.dart';
import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

const _capture = bool.fromEnvironment('ZYRA_LOCK35_CAPTURE');
const _root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const _out = '$_root/PRODUCT/APPROVED/GUARDIAN_SEEKERS/BUILT/LINE122_BUILD';
const _evidence = '$_root/REPORTS/EVIDENCE/LINE122_GUARDIAN_SEEKERS_2026-11-19';
Finder _key(String value) => find.byKey(ValueKey(value));

BaselineHarness _h(
  WidgetTester tester, {
  double scale = 1,
  Size size = const Size(430, 932),
  bool reduce = false,
}) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return BaselineHarness(
    tester,
    group: 'lock35',
    outputRoot: _out,
    evidenceRoot: _evidence,
    flatOutput: true,
    textScale: scale,
    logicalSize: size,
    reduceMotion: reduce,
  );
}

Future<void> _mount(
  BaselineHarness h, {
  bool basic = false,
  bool linked = true,
  bool active = true,
  int seeker = 0,
}) async {
  final model = ReceivedRequestFixture(capacity: 3);
  if (active) expect(model.seedJourneys(1), isTrue);
  if (basic) {
    expect(
      model.setSampleGuardianMembership(
        'draft-guardian-hassan',
        DraftGuardianMembership.basic,
      ),
      isTrue,
    );
  }
  await h.mount(
    guardian: true,
    checkpoint: ZyraPreviewNavigationCheckpoint(
      guardian: true,
      model: model.snapshot(),
      tab: 3,
      pages: const [],
      guardianTabs: ZyraGuardianTabsSnapshot(seeker: seeker),
      removedGuardians: linked ? const [] : const ['draft-guardian-hassan'],
      guardianMembership: basic ? 'Guardian Basic' : 'Guardian One',
    ),
  );
}

Future<void> _swipe(BaselineHarness h, double dx) async {
  await h.tester.drag(_key('guardian_seekers_track'), Offset(dx, 0));
  await h.tester.pump(const Duration(milliseconds: 500));
  await h.flush();
}

Future<void> _cap(BaselineHarness h, String file) async {
  if (baselineTextAuditOnly) {
    await h.auditText(file);
    return;
  }
  if (!_capture) return;
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  try {
    void repaint(RenderObject node) {
      node.markNeedsPaint();
      node.visitChildren(repaint);
    }

    repaint(
      h.tester.renderObject(
        find.byKey(const ValueKey('zyra-founder-baseline-boundary')),
      ),
    );
    await h.tester.pump();
    await h.capture(
      'guardian_seekers',
      file,
      file,
      'Actual offline Founder Guardian shell, LOCK 35; no live server.',
      fileName: '$file.png',
    );
  } finally {
    debugDisableShadows = previous;
  }
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _capture ? _evidence : null));
  tearDownAll(baselineTearDown);

  testWidgets(
    'LOCK35 real swipes settle identity and dots, then reach Invite',
    (t) async {
      final h = _h(t);
      await _mount(h);
      expect(find.byType(ZyraSwipeTrack), findsOneWidget);
      expect(
        t.widget<ZyraProfilesDots>(find.byType(ZyraProfilesDots)).count,
        3,
      );
      final mono = t.widget<ZyraGoldRingMonogram>(
        find.byType(ZyraGoldRingMonogram),
      );
      expect(mono.name, 'Adam');
      expect(mono.size, 76);
      expect(find.text('YOU ARE HIS MAIN GUARDIAN'), findsOneWidget);
      expect(find.text('With Sara'), findsOneWidget);
      await _cap(h, 'gs01_guardian_one__adam_main_current_journey');
      final gesture = await t.startGesture(
        t.getCenter(_key('guardian_seekers_track')),
      );
      await gesture.moveBy(const Offset(-150, 0));
      await t.pump();
      expect(h.latest.guardianTabs.seeker, 0);
      expect(
        t.widget<ZyraProfilesDots>(find.byType(ZyraProfilesDots)).index,
        0,
      );
      await gesture.up();
      await t.pump(const Duration(milliseconds: 500));
      await h.flush();
      expect(h.latest.guardianTabs.seeker, 1);
      expect(find.text('ADDITIONAL GUARDIAN'), findsOneWidget);
      expect(find.text('With Sara'), findsNothing);
      expect(find.text('No current Journey'), findsOneWidget);
      await _cap(h, 'gs02_guardian_one__yusuf_additional_no_journey');
      await _swipe(h, -320);
      expect(
        t.widget<ZyraProfilesDots>(find.byType(ZyraProfilesDots)).index,
        2,
      );
      expect(h.latest.guardianTabs.seeker, 1);
      expect(find.text('Invite a Seeker'), findsOneWidget);
      expect(
        t.widget<ZyraGoldRingMonogram>(find.byType(ZyraGoldRingMonogram)).size,
        104,
      );
      await _cap(h, 'gs03_invite_card');
      await h.tap('guardian_seekers_invite_card');
      expect(find.text('Invite your Seeker'), findsOneWidget);
      await _mount(h, linked: false, active: false);
      expect(find.text('Adam'), findsNothing);
      expect(
        t.widget<ZyraProfilesDots>(find.byType(ZyraProfilesDots)).count,
        1,
      );
      await _cap(h, 'gs05_empty__no_seekers_invite_only');
      await h.tap('guardian_invite');
      expect(find.text('Invite your Seeker'), findsOneWidget);
    },
  );

  for (final basic in [false, true]) {
    testWidgets(
      'LOCK35 ${basic ? 'Basic' : 'One'} header and each Circle row use the selected Seeker',
      (t) async {
        final h = _h(t);
        await _mount(h, basic: basic);
        if (basic) {
          await _cap(h, 'gs04_guardian_basic__adam_main_current_journey');
        }
        await h.tap('guardian_seekers_chat');
        var circle = t.widget<ZyraGuardianCircleScreen>(
          find.byType(ZyraGuardianCircleScreen),
        );
        expect(circle.seekerFirstName, 'Adam');
        expect(circle.previewData!.canSend, !basic);
        await _cap(
          h,
          basic
              ? 'gs07_guardian_basic__guardian_circle_read_only'
              : 'gs06_guardian_one__guardian_circle',
        );
        await returnZyraPreviewPage(t);
        await h.flush();
        await h.tap('guardian_seekers_dot_target_1');
        await t.pump(const Duration(milliseconds: 500));
        await h.flush();
        await h.tap('guardian_seekers_circle_1');
        circle = t.widget<ZyraGuardianCircleScreen>(
          find.byType(ZyraGuardianCircleScreen),
        );
        expect(circle.seekerId, 'draft-linked-yusuf');
        expect(circle.previewData!.canSend, !basic);
        expect(circle.previewData!.contexts, isEmpty);
        expect(
          circle.previewData!.participants.any((p) => p.firstName == 'Adam'),
          isFalse,
        );
      },
    );
  }

  testWidgets(
    'LOCK35 Journey selects the existing tab; no-Journey and details rows use existing details',
    (t) async {
      final h = _h(t);
      await _mount(h);
      await h.tap('guardian_seekers_journey_0');
      expect(h.latest.tab, 1);
      expect(h.latest.pages, isEmpty);
      expect(find.text('Adam & Sara'), findsOneWidget);
      await _cap(h, 'gs08_current_journey_row_opens_journey');
      await _mount(h, seeker: 1);
      await h.tap('guardian_seekers_journey_1');
      h.assertPage('guardian_seeker');
      expect(find.text('Main Guardian only'), findsOneWidget);
      for (final label in ['Relationship', 'Membership', 'Linked']) {
        await _mount(h);
        await h.tapText(label);
        h.assertPage('guardian_seeker');
      }
    },
  );

  testWidgets('LOCK35 swipe revokes retained card and route callbacks', (
    t,
  ) async {
    final h = _h(t);
    await _mount(h);
    final oldAction = t
        .widget<ZyraGuardianTabsPresentation>(
          find.byType(ZyraGuardianTabsPresentation),
        )
        .onAction;
    final oldRow = t.widget<InkWell>(_key('guardian_seekers_circle_0')).onTap!;
    await _swipe(h, -320);
    oldRow();
    oldAction('seeker_0');
    oldAction('seekers_circle_0');
    await h.flush();
    expect(h.latest.pages, isEmpty);
    expect(h.latest.guardianTabs.seeker, 1);
    final beforeInvite = t
        .widget<ZyraGuardianTabsPresentation>(
          find.byType(ZyraGuardianTabsPresentation),
        )
        .onAction;
    await _swipe(h, -320);
    beforeInvite('seekers_circle_1');
    await h.flush();
    expect(h.latest.pages, isEmpty);
    final onInvite = t
        .widget<ZyraGuardianTabsPresentation>(
          find.byType(ZyraGuardianTabsPresentation),
        )
        .onAction;
    await _swipe(h, 320);
    onInvite('circle');
    onInvite('seeker_1');
    await h.flush();
    expect(h.latest.pages, isEmpty);
    expect(h.latest.guardianTabs.seeker, 1);
    final freshAction = t
        .widget<ZyraGuardianTabsPresentation>(
          find.byType(ZyraGuardianTabsPresentation),
        )
        .onAction;
    await h.tap('floating-nav-item-4');
    freshAction('seekers_circle_1');
    await h.flush();
    expect(h.latest.pages, isEmpty);
    expect(h.latest.tab, 4);
  });

  for (final size in [const Size(393, 852), const Size(430, 932)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'LOCK35 card fits or scrolls above navigation $size scale $scale',
        (t) async {
          final h = _h(t, size: size, scale: scale);
          await _mount(h);
          final card = t.getRect(_key('guardian_seekers_card_0'));
          expect(card.left, 22);
          expect(card.right, size.width - 22);
          expect(
            card.bottom,
            lessThanOrEqualTo(t.getTopLeft(_key('compact-nav-surface')).dy),
          );
          await t.ensureVisible(_key('guardian_seekers_circle_0'));
          await h.flush();
          await h.tap('guardian_seekers_circle_0');
          h.assertPage('guardian_circle');
        },
      );
    }
  }

  testWidgets('LOCK35 Reduce Motion uses the shared instant selection', (
    t,
  ) async {
    final h = _h(t, reduce: true);
    await _mount(h);
    await _swipe(h, -320);
    expect(h.latest.guardianTabs.seeker, 1);
  });

  for (final sample in [
    ('gs91_error__offline', ZyraErrorKind.offline),
    ('gs92_error__server', ZyraErrorKind.serviceUnavailable),
  ]) {
    testWidgets('LOCK35 unchanged shared error ${sample.$1}', (t) async {
      final h = _h(t);
      await h.mountPresentation(
        child: ZyraFullScreenError(
          kind: sample.$2,
          referenceCode: 'ZY-TEST',
          onPrimary: () async {},
        ),
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: true,
          model: ViewRequestDraftModel(capacity: 3).snapshot(),
          tab: 3,
          pages: const [],
        ),
      );
      await _cap(h, sample.$1);
      await t.pumpWidget(const SizedBox.shrink());
    });
  }
}
