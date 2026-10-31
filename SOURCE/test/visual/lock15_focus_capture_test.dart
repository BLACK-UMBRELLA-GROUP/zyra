// LOCK15 V2 actual offline Founder routes, sources and visual states.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_phone_access.dart';
import 'package:zyra/dev/zyra_my_zyra_activity_preview.dart';
import 'package:zyra/widgets/zyra_focus_dashboard.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_subscription_wallet_draft.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/data/chapter3_categories.dart';
import 'package:zyra/models/onboarding_question.dart';
import 'package:zyra/screens/profile/compatibility_editors.dart';
import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

const root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const evidence = '$root/REPORTS/EVIDENCE/LOCK15_FOCUS_V2_2026-10-31';
const capture = bool.fromEnvironment('ZYRA_LOCK15_CAPTURE');
Finder k(String value) => find.byKey(ValueKey(value));
const circleToken = 'circle:response:draft-guardian-hassan';
BaselineHarness harness(WidgetTester t, {double scale = 1}) {
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  return BaselineHarness(
    t,
    group: 'lock15_$scale',
    flatOutput: true,
    outputRoot: '$root/PRODUCT/APPROVED/MY_ZYRA/BUILT',
    evidenceRoot: evidence,
    textScale: scale,
  );
}

ViewRequestDraftModel one({int capacity = 3}) {
  final m = ViewRequestDraftModel(
    capacity: capacity,
    clock: () => DateTime.utc(2026, 10, 31, 12),
  );
  expect(m.seedJourneys(1), isTrue);
  return m;
}

Future<void> back(BaselineHarness h) async {
  await returnZyraPreviewPage(h.tester);
  await h.flush();
}

Future<void> cap(BaselineHarness h, String name) async {
  if (!capture) return;
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  try {
    void repaint(RenderObject object) {
      object.markNeedsPaint();
      object.visitChildren(repaint);
    }

    repaint(h.tester.renderObject(k('zyra-founder-baseline-boundary')));
    await h.tester.pump();
    await h.capture(
      'focus',
      name,
      name,
      'Actual admitted offline Founder shell, LOCK15 V2.',
      fileName: '$name.png',
    );
  } finally {
    debugDisableShadows = previous;
  }
}

Future<void> fillPreferences(BaselineHarness h) async {
  await h.tap('focus-preferences');
  await h.flush();
  final editor = h.tester.widget<CompatibilityEditorScreen>(
    find.byType(CompatibilityEditorScreen),
  );
  final draft = editor.initialDraft.copy();
  for (final category in chapter3Categories) {
    for (final question in draft.preferenceQuestions(category)) {
      draft.preferences[question.responseKey] = {
        for (final option in question.options) option: TrafficLight.green,
      };
    }
  }
  expect(await editor.onPersist(draft), isTrue);
  editor.onPreviewReturn!(draft);
  await h.flush();
  expect(k('focus-preferences'), findsNothing);
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: evidence));
  tearDownAll(baselineTearDown);
  var notificationStatus = 'allowed';
  setUp(() {
    notificationStatus = 'allowed';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          zyraPhoneAccessChannel,
          (call) async => call.method == 'status'
              ? {
                  'notifications': notificationStatus,
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
    'LOCK15 m01 m02: exact targets, paging and separate request attention',
    (t) async {
      final h = harness(t);
      await h.mount(tab: 2, model: one());
      expect(find.text('NEEDS YOU · 1 OF 2'), findsOneWidget);
      await cap(h, 'm01_needs_you_1_of_2');
      final semantics = t.ensureSemantics();
      expect(t.getSize(k('focus-next')), const Size(44, 44));
      try {
        expect(t.getSemantics(k('focus-next')).rect.size, const Size(44, 44));
      } finally {
        semantics.dispose();
      }
      expect(t.getSize(k('focus-previous')), const Size(44, 44));
      // Hit the lower part of the full target, outside the visible chevron.
      await t.tapAt(t.getCenter(k('focus-next')) + const Offset(0, 17));
      await h.flush();
      expect(find.text('New message in\nGuardian Circle'), findsOneWidget);
      await cap(h, 'm02_needs_you_2_of_2');
      await h.tap('focus-open-guardian_circle');
      h.assertPage('guardian_circle');
      expect(h.latest.myZyraConsumedFocusTokens, contains(circleToken));
      await back(h);
      await h.tap('concept-my-requests');
      h.assertPage('requests');
      final saved = h.latest;
      expect(
        saved.model.acknowledgedReceivedRequestIds,
        isNot(contains('draft-amira')),
      );
      expect(saved.model.states['draft-amira'], DraftJourneyState.received);
      expect(
        saved.myZyraConsumedFocusTokens.any(
          (x) => x.startsWith('received:draft-amira:'),
        ),
        isTrue,
      );
      await back(h);
      expect(find.text('Nothing needs you right now.'), findsOneWidget);
      await h.mount(checkpoint: h.latest);
      expect(find.text('Nothing needs you right now.'), findsOneWidget);
      final m = ViewRequestDraftModel.fromSnapshot(h.latest.model);
      expect(
        m.seedReceived(
          'draft-noor',
          requestedAt: DateTime.utc(2026, 10, 31, 13),
        ),
        isTrue,
      );
      await h.mount(
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: m.snapshot(),
          tab: 2,
          pages: [],
          myZyraConsumedFocusTokens: saved.myZyraConsumedFocusTokens,
        ),
      );
      expect(find.text('Journey request from Noor'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK15 m03: grouped requests newest event order, no private row acknowledgement',
    (t) async {
      final h = harness(t);
      final m = ViewRequestDraftModel(
        capacity: 3,
        clock: () => DateTime.utc(2026, 10, 31, 12, 0, 3),
      );
      expect(m.request('draft-maryam'), isTrue);
      expect(m.simulateRecipientAccept('draft-maryam'), isTrue);
      expect(
        m.seedReceived(
          'draft-sara',
          requestedAt: DateTime.utc(2026, 10, 31, 12, 0, 2),
        ),
        isTrue,
      );
      expect(
        m.seedReceived(
          'draft-noor',
          requestedAt: DateTime.utc(2026, 10, 31, 12, 0, 1),
        ),
        isTrue,
      );
      final accepted =
          'accepted:draft-maryam:${m.outgoingRequestAcceptedRevision('draft-maryam')}:${m.outgoingRequestAcceptedAt('draft-maryam')!.microsecondsSinceEpoch}';
      await h.mount(
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: m.snapshot(),
          tab: 2,
          pages: [],
          myZyraConsumedFocusTokens: [circleToken, accepted],
        ),
      );
      expect(find.text('3 Journey requests'), findsOneWidget);
      expect(
        find.text(
          'Amira, Sara and Noor would like to begin a Journey with you.',
        ),
        findsOneWidget,
      );
      await cap(h, 'm03_several_requests');
      await h.tap('focus-open-requests');
      h.assertPage('requests');
      expect(h.latest.model.acknowledgedReceivedRequestIds, isEmpty);
      expect(
        h.latest.model.states.values
            .where((s) => s == DraftJourneyState.received)
            .length,
        3,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK15 m04 m05: caught up, actual preference counts, setup and Phone access',
    (t) async {
      final h = harness(t);
      final m = one();
      m.acknowledgeReceivedRequests(['draft-amira']);
      expect(m.request('draft-noor'), isTrue);
      await h.mount(
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: m.snapshot(),
          tab: 2,
          pages: [],
          myZyraConsumedFocusTokens: [circleToken],
        ),
      );
      await fillPreferences(h);
      await cap(h, 'm04_all_caught_up');
      notificationStatus = 'denied';
      await h.mount(
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: false,
          model: m.snapshot(),
          tab: 2,
          pages: [],
          seekerReadiness: ZyraWalletReadiness.unfinished,
          removedGuardians: draftGuardians.map((g) => g.id),
          myZyraConsumedFocusTokens: [circleToken],
        ),
      );
      await fillPreferences(h);
      expect(find.text('Finish setup'), findsOneWidget);
      await cap(h, 'm05_new_member');
      await h.tap('focus-notifications-off');
      h.assertPage('phone_access');
      await back(h);
      await back(h);
      await h.tap('focus-setup');
      h.assertPage('switch_account_setup');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK15 m06: Basic occupied places derive from model capacity',
    (t) async {
      final h = harness(t);
      await h.mount(
        tab: 2,
        model: one(capacity: 1),
        seekerMembership: 'Seeker Basic',
      );
      expect(find.text('1 of 1 place in use'), findsOneWidget);
      await cap(h, 'm06_seeker_basic');
      await h.tap('focus-places');
      expect(h.latest.tab, 1);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK15 gm01-gm05: actual Guardian review, Connect, stable consumption and Basic',
    (t) async {
      final h = harness(t);
      await h.mount(guardian: true, tab: 2);
      await cap(h, 'gm01_family_review');
      await h.tap('focus-next');
      await cap(h, 'gm02_connect_request');
      await h.tap('guardian_received');
      h.assertPage('guardian_connect');
      expect(h.latest.guardianTabs.connection, ZyraGuardianConnection.pending);
      expect(h.latest.guardianTabs.consumedFocus, contains('connect-pending'));
      await back(h);
      await h.tap('guardian_pause');
      expect(h.latest.guardianTabs.review, ZyraGuardianReview.paused);
      // gm03 is its own locked state: Connect is still unopened. A prior gm02
      // navigation must not leak its consumed event or its transient toast.
      await h.mount(
        guardian: true,
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: true,
          model: one().snapshot(),
          tab: 2,
          pages: [],
          guardianTabs: const ZyraGuardianTabsSnapshot(
            review: ZyraGuardianReview.paused,
            reviewRevision: 1,
          ),
        ),
      );
      await cap(h, 'gm03_review_paused');
      expect(h.latest.guardianTabs.review, ZyraGuardianReview.paused);
      await h.tap('guardian_reopen');
      expect(h.latest.guardianTabs.hours, 48);
      await h.tap('guardian_continue');
      await h.mount(
        guardian: true,
        checkpoint: ZyraPreviewNavigationCheckpoint(
          guardian: true,
          model: one().snapshot(),
          tab: 2,
          pages: [],
          guardianTabs: const ZyraGuardianTabsSnapshot(
            review: ZyraGuardianReview.continued,
            connection: ZyraGuardianConnection.dismissed,
          ),
        ),
      );
      await cap(h, 'gm04_all_caught_up');
      await h.mount(
        guardian: true,
        tab: 2,
        guardianMembership: 'Guardian Basic',
      );
      await cap(h, 'gm05_guardian_basic');
      await h.tap('guardian_connect');
      h.assertPage('membership');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK15 every existing Seeker activity kind reaches its exact current destination',
    (t) async {
      final h = harness(t);
      for (final example in ZyraMyZyraActivityExample.values.where(
        (e) => e != ZyraMyZyraActivityExample.quiet,
      )) {
        final m = ViewRequestDraftModel(capacity: 3);
        m.seedJourneys(3);
        await h.mount(tab: 2, model: m);
        await h.controls();
        await h.tap('concept_activity_checklist');
        await h.tap('activity-checklist-${example.name}');
        if (example != ZyraMyZyraActivityExample.requestReceived &&
            example != ZyraMyZyraActivityExample.severalRequests) {
          await h.tap('focus-next');
        }
        final dashboard = t.widget<ZyraFocusDashboard>(
          find.byType(ZyraFocusDashboard),
        );
        final item = example == ZyraMyZyraActivityExample.severalRequests
            ? dashboard.items.single
            : dashboard.items.firstWhere(
                (x) => x.title == example.items.single.title,
              );
        await h.tap(item.actionKey!);
        switch (example) {
          case ZyraMyZyraActivityExample.requestReceived ||
              ZyraMyZyraActivityExample.severalRequests:
            h.assertPage('requests');
            expect(h.latest.requestsTab, 0);
          case ZyraMyZyraActivityExample.requestDeclined:
            h.assertPage('requests');
            expect(h.latest.requestsTab, 2);
          case ZyraMyZyraActivityExample.requestAccepted ||
              ZyraMyZyraActivityExample.journeyReady ||
              ZyraMyZyraActivityExample.familyReviewOpened:
            h.assertPage('journey');
            expect(h.latest.personId, example.items.single.personId);
          case ZyraMyZyraActivityExample.introductionReceived:
            h.assertPage('introductions');
          case ZyraMyZyraActivityExample.journeyEnded:
            h.assertPage('ended');
          case ZyraMyZyraActivityExample.guardianUpdate ||
              ZyraMyZyraActivityExample.guardianInvitationExpiring:
            expect(h.latest.tab, 3);
            expect(h.latest.pages, isEmpty);
          case ZyraMyZyraActivityExample.circleMessage:
            h.assertPage('guardian_circle');
          case ZyraMyZyraActivityExample.milestoneToConfirm:
            h.assertPage('timeline');
            expect(h.latest.personId, 'draft-sara');
          case ZyraMyZyraActivityExample.quiet:
            fail('quiet has no action');
        }
        expect(
          h.latest.model.states,
          m.states,
          reason: 'A fictional event must not mutate domain state.',
        );
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'LOCK15 Larger Text actual Seeker and Guardian scroll to all quick routes',
    (t) async {
      final h = harness(t, scale: 2);
      await h.mount(tab: 2, model: one());
      await cap(h, 'large_seeker');
      await h.tap('focus-notifications');
      h.assertPage('notifications');
      await h.mount(guardian: true, tab: 2);
      await cap(h, 'large_guardian');
      await h.tap('guardian_notifications');
      h.assertPage('notifications');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
  for (final guardian in [false, true]) {
    testWidgets(
      'LOCK15 320pt 200% ${guardian ? 'Guardian Basic' : 'Seeker'} last tiles scroll fully above navigation',
      (t) async {
        final h = harness(t, scale: 2);
        await h.mount(
          guardian: guardian,
          tab: 2,
          model: one(),
          guardianMembership: guardian ? 'Guardian Basic' : 'Guardian One',
        );
        t.view.physicalSize = const Size(960, 1704);
        await h.flush();
        final scroll = t.state<ScrollableState>(find.byType(Scrollable).first);
        scroll.position.jumpTo(scroll.position.maxScrollExtent);
        await h.flush();
        final nav = t.getRect(k('compact-nav-surface'));
        final tile = t.getRect(
          k(guardian ? 'guardian_notifications' : 'focus-notifications'),
        );
        expect(tile.top, greaterThanOrEqualTo(59));
        expect(tile.bottom, lessThanOrEqualTo(nav.top - 8));
        final labelRects = <Rect>[];
        if (guardian) {
          expect(find.text('Guardian One'), findsNWidgets(2));
          for (final label in find.text('Guardian One').evaluate()) {
            final rect = t.getRect(
              find.byElementPredicate((e) => identical(e, label)),
            );
            expect(rect.top, greaterThanOrEqualTo(59));
            expect(rect.bottom, lessThanOrEqualTo(nav.top - 8));
            labelRects.add(rect);
          }
        }
        if (capture) {
          final name = guardian
              ? 'compact_200_guardian_basic_end'
              : 'compact_200_seeker_end';
          final previous = debugDisableShadows;
          debugDisableShadows = false;
          try {
            void repaint(RenderObject object) {
              object.markNeedsPaint();
              object.visitChildren(repaint);
            }

            repaint(t.renderObject(k('zyra-founder-baseline-boundary')));
            await t.pump();
            final boundary = t.renderObject<RenderRepaintBoundary>(
              k('zyra-founder-baseline-boundary'),
            );
            await t.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 3);
              try {
                expect(image.width, 960);
                expect(image.height, 1704);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File(
                  '$root/PRODUCT/APPROVED/MY_ZYRA/BUILT/$name.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
                List<double> rect(Rect r) => [r.left, r.top, r.right, r.bottom];
                await File('$evidence/$name.json').writeAsString(
                  jsonEncode({
                    'logical_size': [320, 568],
                    'text_scale': 2,
                    'device_pixel_ratio': 3,
                    'role': guardian ? 'Guardian Basic' : 'Seeker One',
                    'scroll_offset': scroll.position.pixels,
                    'max_scroll_extent': scroll.position.maxScrollExtent,
                    'navigation_rect': rect(nav),
                    'last_tile_rect': rect(tile),
                    'locked_label_rects': labelRects.map(rect).toList(),
                    'clearance': nav.top - tile.bottom,
                    'all_geometry_assertions_passed': true,
                  }),
                );
              } finally {
                image.dispose();
              }
            });
          } finally {
            debugDisableShadows = previous;
          }
        }
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }
}
