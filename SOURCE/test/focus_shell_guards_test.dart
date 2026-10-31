// LOCK15 V2: retained Focus callbacks never become navigation or authority.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_one_journey_phone_access.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/widgets/zyra_focus_dashboard.dart';

import 'support/zyra_hidden_dev_controls_driver.dart';
import 'visual/baseline_capture_support.dart';

const _evidence =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/REPORTS/EVIDENCE/'
    'LOCK15_FOCUS_V2_2026-10-31';
const _ownerA = 'focus-guard-owner-a';
const _ownerB = 'focus-guard-owner-b';

ZyraFocusDashboard _dashboard(WidgetTester tester) =>
    tester.widget<ZyraFocusDashboard>(find.byType(ZyraFocusDashboard));

ZyraFocusItem _request(WidgetTester tester) => _dashboard(
  tester,
).items.firstWhere((item) => item.title == 'Journey request from Amira');

ZyraFocusItem _review(WidgetTester tester) => _dashboard(
  tester,
).items.firstWhere((item) => item.id.startsWith('review-'));

BaselineHarness _harness(WidgetTester tester) {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return BaselineHarness(
    tester,
    group: 'lock15_focus_guards',
    evidenceRoot: _evidence,
  );
}

Future<void> _back(BaselineHarness harness) async {
  await returnZyraPreviewPage(harness.tester);
  await harness.flush();
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: _evidence));
  tearDownAll(baselineTearDown);
  setUp(() async {
    ZyraAccountState.resetForTesting();
    ZyraAccountState.clearImagesForTesting = () async {};
    await ZyraAccountState.synchronize(_ownerA);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          zyraPhoneAccessChannel,
          (call) async => call.method == 'status'
              ? {
                  'notifications': 'allowed',
                  'location': 'allowed',
                  'photos': 'limited',
                  'camera': 'notDetermined',
                  'faceID': 'notDetermined',
                }
              : null,
        );
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(zyraPhoneAccessChannel, null),
  );

  testWidgets(
    'equal-time event kinds keep a stable order after restore',
    (tester) async {
      final harness = _harness(tester);
      final model = ViewRequestDraftModel(
        capacity: 3,
        clock: () => DateTime.utc(2026, 10, 31, 12),
      );
      expect(model.request('draft-sara'), isTrue);
      expect(model.simulateRecipientAccept('draft-sara'), isTrue);
      await harness.mount(tab: 2, model: model);
      final items = _dashboard(tester).items;
      expect(items.take(2).map((item) => item.title), [
        'Sara accepted your Journey request',
        'Journey request from Amira',
      ]);
      final order = items.map((item) => item.id).toList();
      await harness.mount(checkpoint: harness.latest);
      expect(_dashboard(tester).items.map((item) => item.id), order);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'a retained request action cannot navigate after another page and return',
    (tester) async {
      final h = _harness(tester);
      await h.mount(tab: 2);
      final retained = _request(tester).onAction;
      await h.tap('focus-notifications');
      h.assertPage('notifications');
      await _back(h);
      expect(h.latest.pages, isEmpty);
      expect(h.latest.tab, 2);
      final before = h.latest;

      retained();
      await h.flush();
      expect(h.latest.pages, isEmpty);
      expect(h.latest.tab, 2);
      expect(h.latest.model.states, before.model.states);
      expect(
        h.latest.model.acknowledgedReceivedRequestIds,
        before.model.acknowledgedReceivedRequestIds,
      );
      expect(
        h.latest.myZyraConsumedFocusTokens,
        before.myZyraConsumedFocusTokens,
      );

      // The current action still works; only the earlier callback expired.
      _request(tester).onAction();
      await h.flush();
      h.assertPage('requests');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Guardian Focus actions expire after developer controls open and close',
    (tester) async {
      final h = _harness(tester);
      await h.mount(guardian: true, tab: 2);
      final oldDashboard = _dashboard(tester);
      final oldReview = _review(tester);
      await h.controls();
      await h.closeControls();
      await h.flush();
      final before = h.latest.guardianTabs;

      oldReview.onAction();
      oldReview.onSecondaryAction!();
      oldDashboard.chips.first.onTap();
      oldDashboard.tiles.first.onTap();
      oldDashboard.onIndexChanged!(1);
      await h.flush();
      expect(h.latest.pages, isEmpty);
      expect(h.latest.tab, 2);
      expect(h.latest.guardianTabs.review, ZyraGuardianReview.open);
      expect(h.latest.guardianTabs.reviewRevision, before.reviewRevision);
      expect(h.latest.guardianTabs.consumedFocus, before.consumedFocus);
      expect(h.latest.guardianTabs.focusIndex, before.focusIndex);

      _review(tester).onAction();
      await h.flush();
      expect(h.latest.guardianTabs.review, ZyraGuardianReview.continued);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  for (final guardian in [false, true]) {
    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} retained Focus actions refuse account A-B-A',
      (tester) async {
        final h = _harness(tester);
        await h.mount(guardian: guardian, tab: 2);
        final dashboard = _dashboard(tester);
        final primary = guardian
            ? _review(tester).onAction
            : _request(tester).onAction;
        final chip = dashboard.chips.first.onTap;
        final tile = dashboard.tiles.last.onTap;
        final before = h.latest;
        final generation = ZyraAccountState.generation;

        await tester.runAsync(() async {
          await ZyraAccountState.synchronize(_ownerB);
          await ZyraAccountState.synchronize(_ownerA);
        });
        ZyraDeveloperAccess.setAuthorizedForTesting(true);
        expect(ZyraAccountState.userId, _ownerA);
        expect(ZyraAccountState.generation, greaterThan(generation));
        // Keep the same shell mounted: disposal must not be the guard here.
        expect(find.byType(ZyraFocusDashboard), findsOneWidget);
        primary();
        chip();
        tile();
        await h.flush();
        expect(h.latest.pages, before.pages);
        expect(h.latest.tab, before.tab);
        expect(h.latest.model.states, before.model.states);
        expect(
          h.latest.model.acknowledgedReceivedRequestIds,
          before.model.acknowledgedReceivedRequestIds,
        );
        expect(
          h.latest.myZyraConsumedFocusTokens,
          before.myZyraConsumedFocusTokens,
        );
        expect(h.latest.guardianTabs.review, before.guardianTabs.review);
        expect(
          h.latest.guardianTabs.reviewRevision,
          before.guardianTabs.reviewRevision,
        );
        expect(
          h.latest.guardianTabs.consumedFocus,
          before.guardianTabs.consumedFocus,
        );
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }

  testWidgets(
    'Guardian Journey opening consumes review through countdown but a new decision returns it',
    (tester) async {
      final h = _harness(tester);
      await h.mount(guardian: true, tab: 2);
      final originalReview = _review(tester).id;
      expect(originalReview, 'review-open-0');
      await h.tap('guardian_focus_adam');
      h.assertPage('guardian');
      expect(find.text('Adam & Sara'), findsOneWidget);
      expect(h.latest.guardianTabs.consumedFocus, contains(originalReview));
      await _back(h);
      expect(
        _dashboard(tester).items.any((i) => i.id == originalReview),
        isFalse,
      );

      final saved = h.latest;
      final countdown = ZyraGuardianTabsState(saved.guardianTabs)..hours = 40;
      await h.mount(
        guardian: true,
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: true,
          model: saved.model,
          tab: 2,
          pages: const [],
          guardianTabs: countdown.snapshot,
        ),
      );
      expect(h.latest.guardianTabs.hours, 40);
      expect(h.latest.guardianTabs.reviewRevision, 0);
      expect(h.latest.guardianTabs.consumedFocus, contains(originalReview));
      expect(
        _dashboard(tester).items.any((i) => i.id == originalReview),
        isFalse,
      );

      // A fresh bound domain action supplies a new review decision after the
      // read item has gone. Do not manufacture it by editing snapshot.review.
      tester
          .widget<ZyraGuardianTabsPresentation>(
            find.byType(ZyraGuardianTabsPresentation),
          )
          .onAction('pause');
      await h.flush();
      expect(h.latest.guardianTabs.review, ZyraGuardianReview.paused);
      expect(h.latest.guardianTabs.reviewRevision, 1);
      expect(_review(tester).id, 'review-paused-1');
      expect(h.latest.guardianTabs.consumedFocus, contains(originalReview));
      await h.tap('guardian_reopen');
      expect(h.latest.guardianTabs.review, ZyraGuardianReview.open);
      expect(h.latest.guardianTabs.reviewRevision, 2);
      expect(h.latest.guardianTabs.hours, 48);
      expect(_review(tester).id, 'review-open-2');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
