// LOCK 8 V5: actual admitted preview and explicitly labelled master fixtures.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_one_journey_tab.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/widgets/zyra_profiles_components.dart';
import 'baseline_capture_support.dart';

const root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const evidence = '$root/REPORTS/EVIDENCE/LOCK8_V5_GUARDIAN_JOURNEYS_2026-11-01';
const capture = bool.fromEnvironment('ZYRA_LOCK8_V5_CAPTURE');
const sara = 'draft-sara', aisha = 'draft-aisha';
const hassan = 'draft-guardian-hassan', yusuf = 'draft-guardian-yusuf';
Finder key(String id) => find.byKey(ValueKey(id));

ViewRequestDraftModel fixture([int count = 1]) {
  final m = ViewRequestDraftModel(
    capacity: 3,
    clock: () => DateTime.utc(2026, 11, 1, 12),
  );
  if (count > 0) expect(m.seedJourneys(count), isTrue);
  return m;
}

Future<BaselineHarness> mount(
  WidgetTester t, {
  ViewRequestDraftModel? model,
  ZyraGuardianReview review = ZyraGuardianReview.open,
  bool basic = false,
  bool additional = false,
  bool linked = true,
  int seeker = 0,
  int tab = 1,
  double scale = 1,
}) async {
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  final m = model ?? fixture();
  if (basic) {
    expect(
      m.setSampleGuardianMembership(hassan, DraftGuardianMembership.basic),
      isTrue,
    );
  }
  final h = BaselineHarness(
    t,
    group: 'lock8_v5',
    outputRoot: '$root/PRODUCT/APPROVED/GUARDIAN_TABS/BUILT/V5',
    evidenceRoot: evidence,
    flatOutput: true,
    textScale: scale,
  );
  await h.mount(
    guardian: true,
    checkpoint: ZyraPreviewNavigationCheckpoint(
      guardian: true,
      model: m.snapshot(),
      tab: tab,
      pages: const [],
      guardianTabs: ZyraGuardianTabsSnapshot(review: review, seeker: seeker),
      mainGuardianId: additional ? yusuf : hassan,
      removedGuardians: linked ? const [] : const [hassan],
      guardianMembership: basic ? 'Guardian Basic' : 'Guardian One',
    ),
  );
  return h;
}

ZyraGuardianTabsPresentation view(WidgetTester t) =>
    t.widget<ZyraGuardianTabsPresentation>(
      find.byType(ZyraGuardianTabsPresentation),
    );
ZyraProfilesDots dots(WidgetTester t) =>
    t.widget<ZyraProfilesDots>(find.byType(ZyraProfilesDots));
Future<void> cap(BaselineHarness h, String name, String reached) async {
  if (capture) {
    await h.capture('journeys', name, 'fixture', reached, fileName: name);
  }
}

void clearance(WidgetTester t) {
  expect(
    t.getRect(key('guardian_ended')).bottom,
    lessThanOrEqualTo(t.getRect(key('compact-nav-surface')).top),
  );
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: evidence));
  tearDownAll(baselineTearDown);
  setUp(() {
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
  });

  for (final review in ZyraGuardianReview.values) {
    testWidgets(
      'V5 active Sara fixture uses ${review.name} review and shared photo card',
      (t) async {
        final h = await mount(t, review: review);
        final expected = switch (review) {
          ZyraGuardianReview.open => 'STAGE 4 OF 8 · FAMILY REVIEW',
          ZyraGuardianReview.paused => 'STAGE 4 OF 8 · PAUSED BY FAMILY',
          ZyraGuardianReview.continued => 'STAGE 5 OF 8 · BUILDING A LIFE',
        };
        expect(find.text(expected), findsOneWidget);
        expect(t.widget<Text>(find.text(expected)).style!.color, Colors.white);
        expect(find.text('Adam & Sara'), findsOneWidget);
        expect(
          find.textContaining(
            'Sara Ahmed · 27 · Birmingham · You: Main Guardian · View and Chat',
          ),
          findsOneWidget,
        );
        final photo = t.widget<ZyraJourneyPhotoCard>(
          find.byType(ZyraJourneyPhotoCard),
        );
        expect(photo.photo, isA<AssetImage>());
        expect(dots(t).count, 1);
        clearance(t);
        expect(find.text('S'), findsNothing);
        expect(h.latest.model.states[sara], DraftJourneyState.active);
        final name = review == ZyraGuardianReview.paused
            ? 'g09b_journeys__adam_paused.png'
            : review == ZyraGuardianReview.open
            ? 'g09_journeys__adam.png'
            : 'g09d_journeys__adam_continued.png';
        await cap(
          h,
          name,
          'Explicit active-Sara model fixture; ${review.name} local review; production card',
        );
        await h.tap('guardian_journey');
        expect(h.latest.pages.last, 'guardian');
        expect(h.latest.guardianJourneyId, sara);
        expect(find.text('Adam & Sara'), findsOneWidget);
      },
    );
  }

  testWidgets(
    'V5 Basic remains View only and uses the existing permitted Journey target',
    (t) async {
      final h = await mount(t, basic: true);
      expect(find.textContaining('Main Guardian · View only'), findsOneWidget);
      expect(find.textContaining('View and Chat'), findsNothing);
      final button = t.widget<FilledButton>(key('guardian_journey'));
      expect(
        button.style!.backgroundColor!.resolve({}),
        ZyraColors.goldTextFill,
      );
      expect(button.style!.foregroundColor!.resolve({}), ZyraColors.foreground);
      await cap(
        h,
        'g09c_journeys__adam_guardian_basic.png',
        'Explicit active-Sara Basic model and membership; production card, no Chat grant',
      );
      await h.tap('guardian_journey');
      expect(h.latest.guardianJourneyId, sara);
      expect(h.latest.pages.last, 'guardian');
      expect(find.byType(TextField), findsNothing);
      expect(
        h.latest.model.guardianMemberships[hassan],
        DraftGuardianMembership.basic,
      );
    },
  );

  testWidgets(
    'V5 default requests never become cards; Yusuf and removed link expose no Adam card',
    (t) async {
      final h = await mount(t, model: fixture(0));
      expect(find.text('No current Journey'), findsOneWidget);
      expect(find.byType(ZyraJourneyPhotoCard), findsNothing);
      expect(find.byType(ZyraProfilesDots), findsNothing);
      view(t).onAction('journey_open_draft-amira');
      await h.flush();
      expect(h.latest.pages, isEmpty);
      await cap(
        h,
        'g09_actual_default_empty.png',
        'Actual default model has received Amira only; no active card or synthetic Sara',
      );
      await mount(t, model: fixture(2), seeker: 1);
      expect(find.text('No current Journey'), findsOneWidget);
      expect(find.textContaining('for Yusuf'), findsOneWidget);
      expect(find.byType(ZyraJourneyPhotoCard), findsNothing);
      final unlinked = await mount(t, linked: false);
      expect(find.byType(ZyraJourneyPhotoCard), findsNothing);
      expect(find.text('Ended Journeys'), findsNothing);
      view(t).onAction('journey_open_$sara');
      await unlinked.flush();
      expect(unlinked.latest.pages, isEmpty);
    },
  );

  for (final chat in [false, true]) {
    testWidgets(
      'V5 Additional permitted View and Chat=$chat retain actual role and access',
      (t) async {
        final m = fixture(2);
        expect(
          m.setSampleGuardianJourneyAccess(
            hassan,
            sara,
            viewEnabled: true,
            chatEnabled: chat,
          ),
          isTrue,
        );
        expect(
          m.setSampleGuardianJourneyAccess(hassan, aisha, viewEnabled: false),
          isTrue,
        );
        final h = await mount(t, model: m, additional: true);
        expect(dots(t).count, 1);
        expect(
          find.textContaining(
            'Additional Guardian · ${chat ? 'View and Chat' : 'View only'}',
          ),
          findsOneWidget,
        );
        view(t).onAction('journey_open_$aisha');
        await h.flush();
        expect(h.latest.pages, isEmpty);
        await cap(
          h,
          'g09_additional_${chat ? 'chat' : 'view'}.png',
          'Existing Additional View grant only; denied Aisha excluded; Chat=$chat',
        );
        await h.tap('guardian_journey');
        expect(h.latest.guardianJourneyId, sara);
        expect(h.latest.pages.last, 'guardian');
      },
    );
  }

  testWidgets(
    'V5 activity order, dots/swipe and Open Journey follow each actual person',
    (t) async {
      var now = DateTime.utc(2026, 11, 1, 12);
      final m = ViewRequestDraftModel(capacity: 3, clock: () => now)
        ..seedJourneys(2);
      now = now.add(const Duration(minutes: 1));
      expect(m.sendSalam(aisha), isTrue);
      final h = await mount(t, model: m, review: ZyraGuardianReview.paused);
      expect(dots(t).count, 2);
      expect(find.text('Adam & Aisha'), findsOneWidget);
      expect(find.text('STAGE 1 OF 8 · SALAM EXCHANGE'), findsOneWidget);
      expect(find.textContaining('PAUSED BY FAMILY'), findsNothing);
      await cap(
        h,
        'g09_multiple_aisha.png',
        'Actual activity puts Aisha first; own model stage, no Sara review',
      );
      final old = t.widget<FilledButton>(key('guardian_journey')).onPressed!;
      await t.drag(key('guardian_journey_card'), const Offset(-250, 0));
      await h.flush();
      expect(find.text('Adam & Sara'), findsOneWidget);
      expect(find.text('STAGE 4 OF 8 · PAUSED BY FAMILY'), findsOneWidget);
      old();
      await h.flush();
      expect(h.latest.pages, isEmpty);
      await h.tap('guardian_journey_dot_target_0');
      expect(find.text('Adam & Aisha'), findsOneWidget);
      old();
      await h.flush();
      expect(
        h.latest.pages,
        isEmpty,
        reason: 'Pager ABA cannot revive the old card action.',
      );
      await h.tap('guardian_journey');
      expect(h.latest.guardianJourneyId, aisha);
      expect(find.text('Adam & Aisha'), findsOneWidget);
    },
  );

  testWidgets(
    'V5 retained card and dot actions expire across seeker, route and account changes',
    (t) async {
      final h = await mount(t, model: fixture(2));
      final oldOpen = t
          .widget<FilledButton>(key('guardian_journey'))
          .onPressed!;
      final oldDot = dots(t).onSelected!;
      await h.tap('guardian_seeker');
      oldOpen();
      oldDot(1);
      await h.flush();
      expect(h.latest.pages, isEmpty);
      expect(find.textContaining('for Yusuf'), findsOneWidget);
      await h.tap('guardian_seeker');
      oldOpen();
      oldDot(1);
      await h.flush();
      expect(h.latest.guardianJourneyId, isNull);
      final routeOpen = t
          .widget<FilledButton>(key('guardian_journey'))
          .onPressed!;
      final nav = Navigator.of(
        t.element(find.byType(ZyraGuardianTabsPresentation)),
      );
      nav.push<void>(
        MaterialPageRoute(builder: (_) => const Scaffold(body: Text('Cover'))),
      );
      await h.flush();
      nav.pop();
      await h.flush();
      routeOpen();
      await h.flush();
      expect(h.latest.pages, isEmpty);
      final accountOpen = t
          .widget<FilledButton>(key('guardian_journey'))
          .onPressed!;
      final owner = ZyraAccountState.userId;
      ZyraAccountState.synchronize('other-preview-owner');
      ZyraAccountState.synchronize(owner);
      accountOpen();
      await h.flush();
      expect(h.latest.pages, isEmpty);
    },
  );

  testWidgets('V5 Ended Journeys retains its existing held sharing target', (
    t,
  ) async {
    final h = await mount(t);
    await h.tap('guardian_ended');
    expect(
      find.textContaining('Past summaries are not shared.'),
      findsOneWidget,
    );
    expect(h.latest.pages, ['held_action']);
    expect(h.latest.guardianHistory, isEmpty);
  });

  for (final basic in [false, true]) {
    testWidgets(
      'V5 200 percent text wraps and keeps the ${basic ? 'Basic' : 'One'} Journey action reachable',
      (t) async {
        final h = await mount(
          t,
          basic: basic,
          scale: 2,
          review: ZyraGuardianReview.paused,
        );
        await t.ensureVisible(key('guardian_journey'));
        await h.flush();
        expect(t.takeException(), isNull);
        clearance(t);
        expect(
          find.textContaining(basic ? 'View only' : 'View and Chat'),
          findsOneWidget,
        );
        await cap(
          h,
          'g09_larger_200_${basic ? 'basic' : 'one'}.png',
          'Explicit active-Sara paused fixture at 200 percent; overlay scroll keeps action reachable',
        );
        await h.tap('guardian_journey');
        expect(h.latest.guardianJourneyId, sara);
        expect(h.latest.pages.last, 'guardian');
      },
    );
  }
}
