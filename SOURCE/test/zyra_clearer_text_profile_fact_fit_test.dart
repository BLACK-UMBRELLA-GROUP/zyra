import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_browse_designs.dart';

const _report = String.fromEnvironment('ZYRA_LINE126_FACT_FIT_REPORT');
const _font = 'Q191Poppins';
const _boundary = ValueKey('fact-fit-boundary');
final _rows = <Map<String, Object?>>[];

Future<void> _mount(
  WidgetTester tester,
  SeekerProfile profile,
  double width,
  double scale, {
  bool bold = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, width == 430 ? 932 : 667);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          padding: const EdgeInsets.only(top: 59, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 59, bottom: 34),
          textScaler: TextScaler.linear(scale),
          boldText: bold,
          disableAnimations: true,
        ),
        child: child!,
      ),
      home: Scaffold(
        body: RepaintBoundary(
          key: _boundary,
          child: ZyraBrowseDesigns(
            profiles: [profile],
            selectedIndex: 0,
            design: ZyraOneJourneyBrowseDesign.portraitCard,
            photoBuilder:
                (
                  context,
                  photo, {
                  required width,
                  required height,
                  required alignment,
                }) => const ColoredBox(color: Colors.teal),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Map<String, double> _rect(Rect rect) => {
  'left': rect.left,
  'top': rect.top,
  'width': rect.width,
  'height': rect.height,
};

void main() {
  setUpAll(() async {
    final font = FontLoader(_font);
    for (final weight in ['ExtraLight', 'Light', 'Regular', 'Medium', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await font.load();
  });
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
  });
  tearDown(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });
  tearDownAll(() {
    if (_report.isNotEmpty) {
      final file = File(_report);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode({'rows': _rows}));
    }
  });

  for (final basic in [false, true]) {
    for (final width in [430.0, 375.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('Fact tiles basic=$basic at $width/$scale', (tester) async {
          final previousShadows = debugDisableShadows;
          try {
            debugDisableShadows = false;
            final profile = SeekerProfile(
              id: 'fact-fit',
              firstName: 'Sara',
              surnameLine: 'Ahmed',
              age: 27,
              city: 'Birmingham',
              publicNationality: 'British',
              publicEthnicity: 'South Asian',
              gender: 'female',
              photos: const ['admitted-photo'],
              seekerPlan: basic ? ZyraPlan.basic : ZyraPlan.one,
            );
            await _mount(tester, profile, width, scale);
            final facts = [
              ('AGE', '27'),
              ('LOCATION', profile.city),
              ('NATIONALITY', profile.publicNationality!),
              ('ETHNICITY', profile.publicEthnicity!),
            ];
            final rectangles = <String, Rect>{};
            final fullRows = <String>[];
            final page = tester.getRect(
              find.byKey(const ValueKey('concept_browse_details_fact-fit')),
            );
            final fullWidth = page.width - 44;
            final halfWidth = (fullWidth - 12) / 2;
            for (final fact in facts) {
              final tile = find.byKey(
                ValueKey('profile-detail-tile-${fact.$1}'),
              );
              final rect = tester.getRect(tile);
              rectangles[fact.$1] = rect;
              final texts = find.descendant(
                of: tile,
                matching: find.byType(Text),
              );
              expect(texts, findsNWidgets(2));
              var needsFullRow = false;
              for (var index = 0; index < 2; index++) {
                final finder = texts.at(index);
                final widget = tester.widget<Text>(finder);
                final render = tester.renderObject<RenderParagraph>(
                  find.descendant(of: finder, matching: find.byType(RichText)),
                );
                final original = index == 0 ? fact.$1 : fact.$2;
                final display = render.text.toPlainText();
                expect(display.replaceAll(RegExp(r'\s+'), ' '), original);
                expect(widget.style!.fontSize, index == 0 ? 11 : 18);
                expect(widget.style!.fontWeight, FontWeight.w400);
                expect(widget.style!.letterSpacing, index == 0 ? 1.1 : 0);
                expect(widget.textScaler, isNull);
                expect(widget.maxLines, isNull);
                expect(render.didExceedMaxLines, isFalse);
                for (final word in RegExp(r'\S+').allMatches(display)) {
                  final boxes = render.getBoxesForSelection(
                    TextSelection(
                      baseOffset: word.start,
                      extentOffset: word.end,
                    ),
                  );
                  expect(boxes, isNotEmpty);
                  expect(
                    boxes.every(
                      (box) => (box.top - boxes.first.top).abs() < .01,
                    ),
                    isTrue,
                    reason: '$width/$scale split ${word.group(0)}',
                  );
                  final painter = TextPainter(
                    text: TextSpan(
                      text: word.group(0),
                      style: render.text.style,
                    ),
                    textScaler: render.textScaler,
                    textDirection: render.textDirection,
                  )..layout();
                  needsFullRow |= painter.width > halfWidth - 34 + .01;
                  expect(
                    painter.width,
                    lessThanOrEqualTo(render.size.width + .01),
                  );
                  painter.dispose();
                }
              }
              expect(
                rect.width,
                closeTo(needsFullRow ? fullWidth : halfWidth, .01),
              );
              if (needsFullRow) fullRows.add(fact.$1);
            }
            if (width == 430 && scale == 1) {
              expect(fullRows, isEmpty);
              expect(rectangles['AGE']!.top, rectangles['LOCATION']!.top);
              expect(
                rectangles['NATIONALITY']!.top,
                rectangles['ETHNICITY']!.top,
              );
              expect(
                rectangles['LOCATION']!.left - rectangles['AGE']!.right,
                12,
              );
              expect(
                rectangles['NATIONALITY']!.top - rectangles['AGE']!.bottom,
                12,
              );
            } else {
              expect(fullRows, contains('LOCATION'));
              expect(
                rectangles['LOCATION']!.top,
                greaterThanOrEqualTo(rectangles['AGE']!.bottom + 12),
              );
              expect(
                rectangles['NATIONALITY']!.top,
                greaterThanOrEqualTo(rectangles['LOCATION']!.bottom + 12),
              );
            }
            String? raster;
            if (width == 430 && scale == 1) {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(_boundary),
              );
              raster = await tester.runAsync(() async {
                final image = await boundary.toImage(pixelRatio: 1);
                try {
                  final bytes = await image.toByteData(
                    format: ui.ImageByteFormat.rawRgba,
                  );
                  return sha256.convert(bytes!.buffer.asUint8List()).toString();
                } finally {
                  image.dispose();
                }
              });
            }
            _rows.add({
              'basic': basic,
              'width': width,
              'scale': scale,
              'full_rows': fullRows,
              'tiles': rectangles.map(
                (key, rect) => MapEntry(key, _rect(rect)),
              ),
              '430_normal_raster_sha256': raster,
            });
          } finally {
            debugDisableShadows = previousShadows;
          }
        });
      }
    }
  }

  for (final (city, bold) in [
    ('Northern Stratford-upon-Avon', false),
    ('Birmingham', true),
  ]) {
    testWidgets('Whole fact words retain stored hyphens and bold=$bold', (
      tester,
    ) async {
      final profile = SeekerProfile(
        id: 'fact-words',
        firstName: 'Sara',
        age: 27,
        city: city,
        gender: 'female',
        photos: const ['admitted-photo'],
      );
      await _mount(tester, profile, 375, 1.3, bold: bold);
      final tile = find.byKey(const ValueKey('profile-detail-tile-LOCATION'));
      final page = tester.getRect(
        find.byKey(const ValueKey('concept_browse_details_fact-words')),
      );
      expect(tester.getSize(tile).width, closeTo(page.width - 44, .01));
      final value = find
          .descendant(of: tile, matching: find.byType(Text))
          .at(1);
      final widget = tester.widget<Text>(value);
      final render = tester.renderObject<RenderParagraph>(
        find.descendant(of: value, matching: find.byType(RichText)),
      );
      final display = render.text.toPlainText();
      expect(display.replaceAll(RegExp(r'\s+'), ' '), city);
      expect(widget.style!.fontSize, 18);
      expect(
        render.text.style!.fontWeight,
        bold ? FontWeight.bold : FontWeight.w400,
      );
      if (!bold) {
        expect(display, 'Northern\nStratford-upon-Avon');
        expect(widget.semanticsLabel, city);
        expect(widget.softWrap, isFalse);
      }
      for (final word in RegExp(r'\S+').allMatches(display)) {
        final boxes = render.getBoxesForSelection(
          TextSelection(baseOffset: word.start, extentOffset: word.end),
        );
        expect(boxes, isNotEmpty);
        expect(
          boxes.every((box) => (box.top - boxes.first.top).abs() < .01),
          isTrue,
          reason: 'The whole word ${word.group(0)} remains on one line.',
        );
        expect(
          boxes.every(
            (box) => box.left >= -.01 && box.right <= render.size.width + .01,
          ),
          isTrue,
        );
      }
    });
  }
}
