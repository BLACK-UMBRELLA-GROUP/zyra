// Queue70 / LOCK8 V4: actual admitted shell, no live transport.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_guardian_tabs.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'package:zyra/screens/wali/family_messaging_screens.dart';
import '../support/zyra_hidden_dev_controls_driver.dart';
import 'baseline_capture_support.dart';

const _root = '/Users/shakeelahmad/Developer/DEVELOPMENT/ZYRA';
const _out = '$_root/PRODUCT/APPROVED/GUARDIAN_TABS/BUILT/V4';
const _evidence =
    '$_root/REPORTS/EVIDENCE/LOCK8_GUARDIAN_CHAT_V4_QUEUE70_2026-10-31';
const _capture = bool.fromEnvironment('ZYRA_GUARDIAN_CHAT_V4_CAPTURE');
const _message =
    'Assalaamu alaikum. Adam’s family would be glad to speak about Noor.';
Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _cap(WidgetTester t, String name) async {
  if (!_capture) return;
  final oldShadows = debugDisableShadows;
  debugDisableShadows = false;
  void repaint(RenderObject object) {
    object.markNeedsPaint();
    object.visitChildren(repaint);
  }

  repaint(t.renderObject(_key('zyra-founder-baseline-boundary')));
  try {
    await t.pump(const Duration(milliseconds: 500));
    expect(t.takeException(), isNull);
    final boundary = t.renderObject<RenderRepaintBoundary>(
      _key('zyra-founder-baseline-boundary'),
    );
    await t.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      try {
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('$_out/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
  } finally {
    debugDisableShadows = oldShadows;
    repaint(t.renderObject(_key('zyra-founder-baseline-boundary')));
    await t.pump();
  }
}

Future<void> _reveal(WidgetTester t, Finder target) async {
  final scroll = find
      .descendant(
        of: _key('guardian_chat_scroll'),
        matching: find.byType(Scrollable),
      )
      .first;
  if (target.evaluate().isEmpty) {
    await t.scrollUntilVisible(target, 120, scrollable: scroll, maxScrolls: 25);
  }
  await Scrollable.ensureVisible(t.element(target), alignment: .5);
  await t.pump(const Duration(milliseconds: 400));
  expect(t.takeException(), isNull);
}

void main() {
  setUpAll(() async {
    await baselineSetUp(evidenceRoot: _evidence);
  });
  tearDownAll(() async {
    await baselineTearDown();
  });
  for (final c in [
    (name: 'standard', scale: 1.0, width: 430.0, height: 932.0),
    (name: 'large200', scale: 2.0, width: 430.0, height: 932.0),
    (name: 'narrow200', scale: 2.0, width: 320.0, height: 640.0),
  ]) {
    testWidgets(
      'Guardian chat V4 ${c.name}: empty, sheet, draft, actual sent message',
      (t) async {
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final h = BaselineHarness(
          t,
          group: 'queue70_${c.name}',
          outputRoot: _out,
          evidenceRoot: _evidence,
          textScale: c.scale,
        );
        await h.mount(
          guardian: true,
          checkpoint: ZyraPreviewNavigationCheckpoint(
            guardian: true,
            tab: 2,
            pages: const ['guardian_connect', 'guardian_private_chat'],
            personId: 'draft-aisha',
            model: ViewRequestDraftModel(capacity: 3).snapshot(),
            guardianTabs: const ZyraGuardianTabsSnapshot(
              connection: ZyraGuardianConnection.accepted,
              connectReceived: true,
              seeker: 1,
              networkIndex: 0,
            ),
          ),
        );
        t.view.physicalSize = Size(c.width * 3, c.height * 3);
        await h.flush();
        expect(find.text('Guardian chat'), findsOneWidget);
        expect(find.text('Noor’s Main Guardian'), findsOneWidget);
        expect(find.text('ABOUT ADAM AND NOOR'), findsOneWidget);
        final monogram = t.getSize(
          find
              .ancestor(of: find.text('N'), matching: find.byType(Container))
              .first,
        );
        expect(monogram, const Size(44, 44));
        expect(find.byType(ZyraFamilyMessageComposer), findsOneWidget);
        if (c.name == 'narrow200') {
          await _cap(t, 'narrow200_header');
          await _reveal(t, find.text('A private chat'));
        }
        expect(find.text('A private chat'), findsOneWidget);
        await _cap(
          t,
          c.name == 'standard' ? 'g19_guardian_chat__new' : '${c.name}_empty',
        );
        await h.tap('guardian_chat_options');
        expect(find.byType(ZyraGuardianChatOptions), findsOneWidget);
        expect(find.text('Report a message'), findsOneWidget);
        expect(find.text('Block Noor’s Main Guardian'), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);
        expect(find.byType(ListTile), findsNWidgets(2));
        await _cap(
          t,
          c.name == 'standard'
              ? 'g22_guardian_chat__options'
              : '${c.name}_options',
        );
        await h.tap('guardian_chat_options_done');
        await t.enterText(find.byType(TextField), 'draft to preserve');
        await h.tap('guardian_chat_options');
        await h.tap('guardian_chat_options_done');
        expect(
          t.widget<TextField>(find.byType(TextField)).controller!.text,
          'draft to preserve',
        );
        await t.enterText(find.byType(TextField), _message);
        await t.tap(_key('circle_send_action'));
        await h.flush();
        FocusManager.instance.primaryFocus?.unfocus();
        await h.flush();
        if (c.name == 'narrow200') await _reveal(t, find.text(_message));
        expect(find.text(_message), findsOneWidget);
        expect(find.text('A private chat'), findsNothing);
        expect(
          t.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
        await _cap(
          t,
          c.name == 'standard' ? 'g21_guardian_chat__sent' : '${c.name}_sent',
        );
        await t.enterText(find.byType(TextField), 'discard on leaving');
        await returnZyraPreviewPage(t);
        await h.flush();
        await h.tap('guardian_chat');
        expect(
          t.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
        expect(find.text(_message), findsNothing);
        if (c.name == 'narrow200') {
          await _reveal(t, find.text('A private chat'));
        }
        expect(find.text('A private chat'), findsOneWidget);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );
  }
}
