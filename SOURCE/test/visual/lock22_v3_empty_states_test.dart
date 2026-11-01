// LOCK22 V3 / LOCK8 V8: actual admitted offline shell routes, not stand-alone mocks.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_one_journey_monogram_presentation.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/widgets/zyra_state_widgets.dart';
import 'baseline_capture_support.dart';

const root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const raw =
    '/Users/shakeelahmad/Documents/Codex/2026-11-01/zyra-queue61-shared-empty-states-v3/work/raw';
const capture = bool.fromEnvironment('ZYRA_LOCK22_V3_CAPTURE');
Finder key(String id) => find.byKey(ValueKey(id));

Future<void> cap(
  BaselineHarness h,
  String name,
  String output,
  double scale,
) async {
  await h.flush();
  final ring = h.tester.getRect(
    find.descendant(
      of: find.byType(ZyraEmptyState),
      matching: find.byType(ZyraGoldRingMonogram),
    ),
  );
  final expectedCenters = {
    'e01': 360.8,
    'e02': 360.8,
    'g05': 329.8,
    'g16': 367.8,
    'g20': 398.8,
    'g23': 360.8,
  };
  if (scale == 1) {
    expect(ring.size, const Size(96, 96));
    expect(
      (ring.center.dy - expectedCenters[name.substring(0, 3)]!).abs(),
      lessThanOrEqualTo(8),
    );
  }
  if (!capture) return;
  await h.tester.runAsync(() async {
    final boundary = h.tester.renderObject<RenderRepaintBoundary>(
      key('zyra-founder-baseline-boundary'),
    );
    final image = await boundary.toImage(pixelRatio: 3);
    try {
      final file = File('$output/$name.png');
      await file.parent.create(recursive: true);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.writeAsBytes(data!.buffer.asUint8List());
      await File('$output/$name.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'file': '$name.png',
          'width': image.width,
          'height': image.height,
          'ring_bounds_pt': [ring.left, ring.top, ring.width, ring.height],
          'logical_width': 430,
          'logical_height': 932,
          'text_scale': scale,
          'route': h.latest.pages,
          'tab': h.latest.tab,
          'reached':
              'Actual admitted offline Founder shell; existing route and local sample data; no backend.',
        }),
      );
    } finally {
      image.dispose();
    }
  });
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: raw));
  tearDownAll(baselineTearDown);
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'LOCK22 V3 six real empty routes and guarded Network actions at $scale',
      (t) async {
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final suffix = scale == 1 ? '' : '__text200';
        Future<BaselineHarness> mount({
          bool guardian = false,
          int tab = 2,
          List<String> pages = const [],
          ZyraGuardianTabsSnapshot state = const ZyraGuardianTabsSnapshot(),
        }) async {
          final h = BaselineHarness(
            t,
            group: 'empty_v3',
            outputRoot: raw,
            evidenceRoot: raw,
            flatOutput: true,
            textScale: scale,
          );
          await h.mount(
            guardian: guardian,
            checkpoint: ZyraPreviewNavigationCheckpoint(
              guardian: guardian,
              tab: tab,
              pages: pages,
              model: ViewRequestDraftModel(capacity: 3).snapshot(),
              guardianTabs: state,
            ),
          );
          return h;
        }

        var h = await mount(pages: ['introductions']);
        expect(find.byType(ZyraEmptyState), findsOneWidget);
        expect(find.text('No introductions yet'), findsOneWidget);
        await cap(
          h,
          'e01_introductions__empty$suffix',
          '$root/PRODUCT/APPROVED/UNITY_PASS/BUILT/V3',
          scale,
        );
        h = await mount(pages: ['ended']);
        expect(find.text('No ended Journeys'), findsOneWidget);
        expect(
          find.text("When a Journey ends, it's kept here with its Timeline."),
          findsOneWidget,
        );
        await cap(
          h,
          'e02_ended_journeys__empty$suffix',
          '$root/PRODUCT/APPROVED/UNITY_PASS/BUILT/V3',
          scale,
        );
        for (final intro in [true, false]) {
          h = await mount(
            guardian: true,
            pages: [intro ? 'guardian_introductions' : 'guardian_connect'],
          );
          expect(find.byType(ZyraEmptyState), findsOneWidget);
          expect(find.text('Open Network'), findsOneWidget);
          final retired = t
              .widget<ZyraEmptyState>(find.byType(ZyraEmptyState))
              .onCta!;
          await cap(
            h,
            '${intro ? 'g05_introductions_made__empty' : 'g16_connect_with_guardian__sent_empty'}$suffix',
            '$root/PRODUCT/APPROVED/GUARDIAN_TABS/BUILT/V8',
            scale,
          );
          await h.tap('guardian_empty_network');
          expect(h.latest.tab, 0);
          expect(h.latest.pages, isEmpty);
          retired();
          await h.flush();
          expect(h.latest.tab, 0);
          expect(h.latest.pages, isEmpty);
        }
        h = await mount(
          guardian: true,
          pages: ['guardian_connect'],
          state: const ZyraGuardianTabsSnapshot(
            connectReceived: true,
            connection: ZyraGuardianConnection.dismissed,
          ),
        );
        expect(find.text('No requests received yet.'), findsOneWidget);
        expect(find.text('Open Network'), findsNothing);
        await cap(
          h,
          'g20_connect_with_guardian__received_empty$suffix',
          '$root/PRODUCT/APPROVED/GUARDIAN_TABS/BUILT/V8',
          scale,
        );
        h = await mount(guardian: true, tab: 1);
        await h.tap('guardian_ended');
        expect(h.latest.pages.last, 'held_action');
        expect(find.byType(ZyraEmptyState), findsOneWidget);
        expect(find.text('No ended Journeys to show.'), findsOneWidget);
        expect(find.text('Open Network'), findsNothing);
        await cap(
          h,
          'g23_ended_journeys__empty$suffix',
          '$root/PRODUCT/APPROVED/GUARDIAN_TABS/BUILT/V8',
          scale,
        );
        expect(t.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      'LOCK22 V3 existing request and Journey empty surfaces at $scale',
      (t) async {
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final h = BaselineHarness(
          t,
          group: 'empty_other',
          outputRoot: raw,
          evidenceRoot: raw,
          textScale: scale,
        );
        final emptyModel = ViewRequestDraftModel(capacity: 3);
        for (final profile in draftProfiles) {
          emptyModel.block(profile.id);
        }
        await h.mount(
          checkpoint: ZyraPreviewNavigationCheckpoint(
            guardian: false,
            tab: 2,
            pages: const ['requests'],
            model: emptyModel.snapshot(),
          ),
        );
        for (final index in [0, 1, 2]) {
          await h.tap('draft_requests_$index');
          expect(find.byType(ZyraEmptyState), findsOneWidget);
        }
        await h.mount(tab: 1);
        expect(find.text('No Journey yet'), findsOneWidget);
        expect(find.byType(ZyraEmptyState), findsOneWidget);
        expect(t.takeException(), isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }
}
