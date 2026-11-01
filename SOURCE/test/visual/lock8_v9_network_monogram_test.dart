// LOCK8 V9: actual admitted offline Network card; public identity only.
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
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'baseline_capture_support.dart';

const output =
    '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA/PRODUCT/APPROVED/GUARDIAN_TABS/BUILT/V9';
const evidence =
    '/Users/shakeelahmad/Documents/Codex/2026-11-01/zyra-queue63-network-monogram-v9/work/raw';
const capture = bool.fromEnvironment('ZYRA_LOCK8_V9_CAPTURE');
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
    group: 'lock8_v9',
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

void publicIdentity(WidgetTester t, String initial, String label) {
  final avatar = key('guardian_network_monogram');
  final monogram = t.widget<ZyraGoldRingMonogram>(avatar);
  expect(monogram.name, initial);
  expect(t.getSize(avatar), const Size(110, 110));
  final initialText = t.widget<Text>(
    find.descendant(of: avatar, matching: find.text(initial)),
  );
  expect(initialText.style!.fontSize, 52);
  expect(initialText.style!.fontWeight, FontWeight.w200);
  expect(initialText.style!.color, ZyraColors.journeyGold);
  expect(initialText.textScaler!.scale(52), 52);
  final circle = t.widget<Container>(
    find.descendant(of: avatar, matching: find.byType(Container)).first,
  );
  final decoration = circle.decoration! as BoxDecoration;
  expect(decoration.color, isNull);
  expect(decoration.shape, BoxShape.circle);
  final ring = decoration.border! as Border;
  expect(ring.top.width, 1);
  expect(ring.top.color, const Color(0xFFA9792E).withValues(alpha: .7));
  final name = t.widget<Text>(find.text(label));
  expect(name.style!.fontSize, 34);
  expect(name.style!.fontWeight, FontWeight.w300);
  expect(find.byType(Image), findsNothing);
  expect(find.textContaining('Aisha'), findsNothing);
  expect(find.textContaining('Noor'), findsNothing);
  final trees = <String>[];
  void collect(PipelineOwner owner) {
    final node = owner.semanticsOwner?.rootSemanticsNode;
    if (node != null) trees.add(node.toStringDeep());
    owner.visitChildren(collect);
  }

  collect(t.binding.rootPipelineOwner);
  final tree = trees.join('\n');
  expect(tree, isNot(contains('Aisha')));
  expect(tree, isNot(contains('Noor')));
  expect(tree, contains(label));
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
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
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
          'reached': 'Actual admitted offline Founder Guardian Network shell.',
          'privacy': 'Public initial and age only; no photo or surname.',
        }),
      );
    } finally {
      image.dispose();
    }
  });
}

Future<void> shadows(WidgetTester t, Future<void> Function() body) async {
  final semantics = t.ensureSemantics();
  final previous = debugDisableShadows;
  debugDisableShadows = false;
  try {
    await body();
  } finally {
    debugDisableShadows = previous;
    semantics.dispose();
  }
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: evidence));
  tearDownAll(baselineTearDown);
  setUp(() {
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
  });
  for (final family in [0, 1]) {
    testWidgets(
      'V9 family $family public monogram and semantics preserve card details',
      (t) => shadows(t, () async {
        final h = await mount(t, family: family, seeker: family);
        publicIdentity(
          t,
          family == 0 ? 'A' : 'N',
          family == 0 ? 'A., 29' : 'N., 25',
        );
        expect(
          find.text(family == 0 ? 'London' : 'Nottingham'),
          findsOneWidget,
        );
        for (final text in [
          'Main Guardian',
          'Father · ✓ Verified',
          'Nationality',
          'British',
          'Ethnicity',
          'Mixed',
        ]) {
          expect(find.text(text), findsOneWidget);
        }
        expect(
          find.text('for ${family == 0 ? 'Adam' : 'Yusuf'} ▾'),
          findsOneWidget,
        );
        expect(
          ZyraGuardianTabsState.network.every((p) => p.guardianOne),
          isTrue,
        );
        final nav = t.getRect(key('compact-nav-surface'));
        for (final action in ['introduce_confirm', 'connect_confirm']) {
          final button = key('guardian_$action');
          expect(button.hitTestable(), findsOneWidget);
          expect(t.getRect(button).bottom + 8, lessThanOrEqualTo(nav.top));
        }
        expect(
          t
              .widget<IconButton>(
                key(family == 0 ? 'guardian_previous' : 'guardian_next'),
              )
              .onPressed,
          isNull,
        );
        if (family == 0) await cap(h, 'g06_network_normal', 1);
      }),
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }
  for (final width in [430.0, 390.0]) {
    testWidgets(
      'V9 ${width.toInt()}pt at 200 percent text keeps details and actions reachable',
      (t) => shadows(t, () async {
        final h = await mount(t, scale: 2);
        t.view.physicalSize = Size(width * 3, 2532);
        await h.flush();
        publicIdentity(t, 'A', 'A., 29');
        await cap(h, 'g06_network_large_${width.toInt()}_top', 2);
        await t.ensureVisible(key('guardian_connect_confirm'));
        await h.flush();
        for (final action in ['introduce_confirm', 'connect_confirm']) {
          expect(key('guardian_$action').hitTestable(), findsOneWidget);
        }
        await cap(h, 'g06_network_large_${width.toInt()}_actions', 2);
        await h.tap('guardian_connect_confirm');
        await t.ensureVisible(key('guardian_action_back'));
        await h.flush();
        expect(key('guardian_connect_send').hitTestable(), findsOneWidget);
        await h.tap('guardian_action_back');
        expect(view(t).state.sent, isEmpty);
        expect(view(t).state.introduced, isEmpty);
      }),
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }
  testWidgets(
    'V9 existing introduction, connect and family navigation still use selected identity',
    (t) => shadows(t, () async {
      final h = await mount(t);
      await h.tap('guardian_introduce_confirm');
      await h.tap('guardian_introduce_send');
      expect(view(t).state.introduced, {'adam:aisha'});
      expect(find.text('Introduced'), findsOneWidget);
      await h.tap('guardian_connect_confirm');
      await h.tap('guardian_connect_send');
      expect(view(t).state.sent, {'aisha'});
      expect(find.text('Request sent'), findsOneWidget);
      await h.tap('guardian_next');
      expect(find.text('N., 25'), findsOneWidget);
      expect(find.text('Introduced'), findsNothing);
      expect(find.text('Request sent'), findsNothing);
      await h.tap('guardian_previous');
      expect(find.text('A., 29'), findsOneWidget);
      expect(find.text('Introduced'), findsOneWidget);
      expect(find.text('Request sent'), findsOneWidget);
    }),
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
