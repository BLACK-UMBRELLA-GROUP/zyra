// LOCK 8 V7: actual admitted offline Founder shell, unchanged action leases.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/theme/zyra_colors.dart';
import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

const root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const output = '$root/PRODUCT/APPROVED/GUARDIAN_TABS/BUILT/V7';
const evidence =
    '/Users/shakeelahmad/Documents/Codex/2026-11-01/zyra-queue60-guardian-action-pages-v7/work/raw';
const capture = bool.fromEnvironment('ZYRA_LOCK8_V7_CAPTURE');
Finder key(String id) => find.byKey(ValueKey(id));
ZyraGuardianTabsPresentation view(WidgetTester t) =>
    t.widget(find.byType(ZyraGuardianTabsPresentation));
Future<BaselineHarness> mount(
  WidgetTester t, {
  double scale = 1,
  int family = 0,
  int seeker = 0,
}) async {
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  final h = BaselineHarness(
    t,
    group: 'lock8_v7',
    outputRoot: output,
    evidenceRoot: evidence,
    flatOutput: true,
    textScale: scale,
  );
  await h.mount(
    guardian: true,
    checkpoint: ZyraPreviewNavigationCheckpoint(
      guardian: true,
      tab: 0,
      pages: const [],
      model: ViewRequestDraftModel(capacity: 3).snapshot(),
      guardianTabs: ZyraGuardianTabsSnapshot(
        networkIndex: family,
        seeker: seeker,
      ),
    ),
  );
  return h;
}

Future<void> cap(BaselineHarness h, String name, double scale) async {
  if (!capture) return;
  await h.flush();
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
          'logical_width': h.tester.view.physicalSize.width / 3,
          'logical_height': h.tester.view.physicalSize.height / 3,
          'text_scale': scale,
          'route': h.latest.pages,
          'tab': h.latest.tab,
          'reached':
              'Actual admitted offline Founder Guardian shell via Network; selected sample family; no backend.',
        }),
      );
    } finally {
      image.dispose();
    }
  });
}

Future<void> shadows(Future<void> Function() body) async {
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  try {
    await body();
  } finally {
    debugDisableShadows = previous;
  }
}

void main() {
  setUpAll(() async {
    await baselineSetUp(evidenceRoot: evidence);
  });
  tearDownAll(() async {
    debugDisableShadows = true;
    await baselineTearDown();
  });
  setUp(() {
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
  });
  for (final introduction in [true, false]) {
    final page = introduction ? 'g07' : 'g08';
    final action = introduction ? 'introduce' : 'connect';
    testWidgets(
      'V7 $page normal locked geometry, rows, privacy and existing action',
      (t) => shadows(() async {
        final h = await mount(t);
        await h.tap('guardian_${action}_confirm');
        expect(t.getSize(key('guardian_action_monogram')), const Size(96, 96));
        expect(find.text('A'), findsOneWidget);
        expect(
          find.text(introduction ? 'INTRODUCTION' : 'CONNECT WITH GUARDIAN'),
          findsOneWidget,
        );
        expect(
          find.text(
            introduction
                ? 'Nothing is sent to them.'
                : 'A private chat opens between the two of you.',
          ),
          findsOneWidget,
        );
        expect(find.byType(Image), findsNothing);
        final button = key('guardian_${action}_send');
        expect(button.hitTestable(), findsOneWidget);
        final label = t.widget<Text>(
          find.descendant(of: button, matching: find.byType(Text)),
        );
        expect(label.style!.color, ZyraColors.foreground);
        expect(
          t.widget<TextButton>(button).style!.backgroundColor!.resolve({}),
          ZyraColors.primaryAction,
        );
        await cap(h, '${page}_normal', 1);
        await h.tap('guardian_${action}_send');
        expect(h.latest.pages, isEmpty);
        expect(
          introduction ? view(t).state.introduced : view(t).state.sent,
          introduction ? {'adam:aisha'} : {'aisha'},
        );
      }),
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets(
      'V7 $page selected Noor/Yusuf, back unchanged and stale route/View callbacks rejected',
      (t) => shadows(() async {
        final h = await mount(t, family: 1, seeker: 1);
        await h.tap('guardian_${action}_confirm');
        expect(find.text('N'), findsOneWidget);
        expect(
          find.text(
            introduction
                ? 'Put Noor forward to Yusuf?'
                : 'Noor’s Main Guardian',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Aisha'), findsNothing);
        final stale = view(t).onAction;
        await openZyraDevControls(t);
        stale('${action}_send');
        await closeZyraDevControls(t);
        await h.flush();
        stale('${action}_send');
        expect(view(t).state.sent, isEmpty);
        expect(view(t).state.introduced, isEmpty);
        final oldRoute = view(t).onAction;
        await h.tap('guardian_action_back');
        oldRoute('${action}_send');
        await h.flush();
        expect(h.latest.pages, isEmpty);
        expect(view(t).state.sent, isEmpty);
        expect(view(t).state.introduced, isEmpty);
        await h.tap('guardian_${action}_confirm');
        await h.tap('guardian_${action}_send');
        expect(
          introduction ? view(t).state.introduced : view(t).state.sent,
          introduction ? {'yusuf:noor'} : {'noor'},
        );
      }),
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    for (final width in [430.0, 390.0]) {
      testWidgets(
        'V7 $page at ${width.toInt()}pt with 200 percent text keeps all rows/actions reachable',
        (t) => shadows(() async {
          final h = await mount(t, scale: 2);
          t.view.physicalSize = Size(width * 3, 2532);
          await h.flush();
          await h.tap('guardian_${action}_confirm');
          expect(t.takeException(), isNull);
          await cap(h, '${page}_large_${width.toInt()}_top', 2);
          await t.ensureVisible(key('guardian_action_back'));
          await h.flush();
          expect(key('guardian_${action}_send').hitTestable(), findsOneWidget);
          expect(key('guardian_action_back').hitTestable(), findsOneWidget);
          await cap(h, '${page}_large_${width.toInt()}_actions', 2);
          await h.tap('guardian_action_back');
          expect(view(t).state.sent, isEmpty);
          expect(view(t).state.introduced, isEmpty);
        }),
        variant: TargetPlatformVariant.only(TargetPlatform.iOS),
      );
    }
  }
}
