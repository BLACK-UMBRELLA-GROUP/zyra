import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_legal_preview_content.dart';
import 'package:zyra/dev/zyra_legal_reader_preview.dart';

import '../support/zyra_rendered_text_contrast.dart';
import 'baseline_capture_support.dart';

const _root = 'build/line149';
const _capture = bool.fromEnvironment('ZYRA_LINE149_CAPTURE');
Finder _key(String key) => find.byKey(ValueKey(key));

void _selected(WidgetTester t, int section) {
  final selected = find.ancestor(
    of: _key('legal_chip_$section'),
    matching: find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.selected == true,
    ),
  );
  expect(selected, findsOneWidget);
}

BaselineHarness _harness(WidgetTester t, Size size, double scale) {
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
  return BaselineHarness(
    t,
    group: 'line149_${size.width.toInt()}_$scale',
    logicalSize: size,
    textScale: scale,
    safePadding: size.width == 375
        ? const EdgeInsets.only(top: 20)
        : const EdgeInsets.only(top: 59, bottom: 34),
    outputRoot: '$_root/screens',
    evidenceRoot: '$_root/screens',
    flatOutput: true,
  );
}

Future<void> _readToEnd(WidgetTester t) async {
  final scroll = t.state<ScrollableState>(
    find.descendant(
      of: _key('legal_reading_scroll'),
      matching: find.byType(Scrollable),
    ),
  );
  scroll.position.jumpTo(scroll.position.maxScrollExtent);
  await t.pumpAndSettle();
}

Future<void> _audit(BaselineHarness h, String name) async {
  final previousShadows = debugDisableShadows;
  try {
    debugDisableShadows = false;
    await h.tester.pump(const Duration(milliseconds: 2600));
    final boundary = h.tester.renderObject<RenderRepaintBoundary>(
      _key('zyra-founder-baseline-boundary'),
    );
    final result = await auditZyraRenderedText(h.tester, boundary);
    await h.tester.runAsync(() async {
      final file = File('$_root/audit/$name.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(result.toJson()));
    });
    expect(result.failures, isEmpty, reason: '$name ${result.failures}');
    if (_capture) {
      void repaint(RenderObject object) {
        object.visitChildren(repaint);
        object.markNeedsPaint();
      }

      repaint(boundary);
      await h.tester.pump();
      await h.capture('legal', name, 'normal', name, fileName: '$name.png');
    }
  } finally {
    debugDisableShadows = previousShadows;
  }
}

void main() {
  setUpAll(() => baselineSetUp(evidenceRoot: null));
  tearDownAll(baselineTearDown);

  for (final (size, scale) in [
    (const Size(430, 932), 1.0),
    (const Size(375, 667), 1.3),
    (const Size(375, 667), 1.0),
    (const Size(430, 932), 1.3),
  ]) {
    testWidgets(
      'LOCK51 settings, pinned title, jump and Read next at $size/$scale',
      (t) async {
        final h = _harness(t, size, scale);
        final suffix = size.width == 430 && scale == 1.0
            ? ''
            : '_${size.width.toInt()}_${scale == 1.0 ? 'normal' : 'large'}';
        await h.mount(tab: 4, pages: ['settings']);
        await t.scrollUntilVisible(
          _key('concept_settings_privacyData'),
          160,
          scrollable: find
              .descendant(
                of: _key('concept-current-settings-scroll'),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await h.tap('concept_settings_privacyData');
        expect(_key('help_safety_privacy'), findsOneWidget);
        await _audit(h, 'lg00_privacy_data__rows$suffix');
        await h.tap('help_row_Privacy policy');
        await t.pumpAndSettle();
        final title = find.descendant(
          of: _key('legal_reader_privacy'),
          matching: find.text('Privacy policy'),
        );
        final header = t.getTopLeft(title);
        expect(find.byType(BackButton), findsNothing);
        expect(_key('floating-nav-item-0'), findsNothing);
        expect(find.text('Last updated 24 Nov 2026'), findsOneWidget);
        _selected(t, 0);
        await _audit(h, 'lg01_privacy__top$suffix');

        await h.tap('legal_chip_1');
        await t.pumpAndSettle();
        expect(t.getTopLeft(title), header);
        _selected(t, 1);
        expect(
          find.text('What this policy covers').hitTestable(),
          findsOneWidget,
        );
        // Reopen the fresh page so the sheet master starts on its first section.
        await t.binding.handlePopRoute();
        await t.pumpAndSettle();
        await h.tap('help_row_Privacy policy');
        await t.pumpAndSettle();
        await h.tap('legal_all_sections');
        await t.pumpAndSettle();
        expect(find.text('ON THIS PAGE · 18 SECTIONS'), findsOneWidget);
        final longSheetHeight = t.getSize(_key('legal_sections_sheet')).height;
        await _audit(h, 'lg02_privacy__all_sections$suffix');
        await t.tapAt(const Offset(56, 90));
        await t.pumpAndSettle();
        expect(_key('legal_sections_sheet'), findsNothing);
        await h.tap('legal_all_sections');
        await t.scrollUntilVisible(
          _key('legal_sheet_section_6'),
          100,
          scrollable: find.descendant(
            of: _key('legal_sections_sheet'),
            matching: find.byType(Scrollable),
          ),
        );
        await t.tap(_key('legal_sheet_section_6'));
        await t.pumpAndSettle();
        expect(_key('legal_sections_sheet'), findsNothing);
        expect(
          find.text('Your photos and video').hitTestable(),
          findsOneWidget,
        );
        _selected(t, 6);
        await _audit(h, 'lg03_privacy__jumped_to_section$suffix');

        await _readToEnd(t);
        _selected(t, 17);
        expect(
          find.text('zyraconnect.app/privacy').hitTestable(),
          findsOneWidget,
        );
        await _audit(h, 'lg04_privacy__end_read_next$suffix');
        await h.tap('legal_next_terms');
        _selected(t, 0);
        expect(_key('legal_reader_terms'), findsOneWidget);
        await _audit(h, 'lg05_terms__top$suffix');
        await h.tap('legal_all_sections');
        await t.pumpAndSettle();
        expect(find.text('ON THIS PAGE · 15 SECTIONS'), findsOneWidget);
        await t.tapAt(const Offset(56, 90));
        await t.pumpAndSettle();
        await _readToEnd(t);
        await h.tap('legal_next_photos');
        expect(_key('legal_reader_photos'), findsOneWidget);
        expect(find.text('IN SHORT'), findsNothing);
        await _audit(h, 'lg06_photos__top$suffix');
        await h.tap('legal_all_sections');
        await t.pumpAndSettle();
        expect(find.text('ON THIS PAGE · 6 SECTIONS'), findsOneWidget);
        expect(
          t.getSize(_key('legal_sections_sheet')).height,
          lessThan(longSheetHeight),
        );
        expect(_key('legal_sheet_section_5').hitTestable(), findsOneWidget);
        await t.tapAt(const Offset(56, 90));
        await t.pumpAndSettle();
        await t.binding.handlePopRoute();
        await t.pumpAndSettle();
        expect(_key('help_safety_privacy'), findsOneWidget);
        expect(find.byType(ZyraLegalReaderPreview), findsNothing);
      },
    );
  }

  testWidgets('one iOS edge swipe returns to origin after Read next', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => openZyraLegalReader(
                context,
                ZyraLegalPreviewDocument.privacy,
                canOpen: () => true,
                canRetain: () => true,
              ),
              child: const Text('Read privacy'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Read privacy'));
    await t.pumpAndSettle();
    await _readToEnd(t);
    await t.tap(_key('legal_next_terms'));
    await t.pumpAndSettle();
    expect(_key('legal_reader_terms'), findsOneWidget);
    await t.dragFrom(const Offset(3, 350), const Offset(650, 0));
    await t.pumpAndSettle();
    expect(find.byType(ZyraLegalReaderPreview), findsNothing);
    expect(find.text('Read privacy'), findsOneWidget);
  });
}
