// OA-ZYRA-371: reuse LOCK10's existing vertical segments when a real word
// cannot fit its original equal-width cell. Fonts and tap guards stay real.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_browse_filter.dart';
import 'package:zyra/dev/zyra_one_journey_filters_presentation.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

const _font = 'ZYRAFilterFitPoppins';
const _labels = ['Near me', 'Country', 'Worldwide'];
final _observations = <Map<String, Object?>>[];
Finder _key(String value) => find.byKey(ValueKey(value));

class _Harness {
  var filter = const ZyraBrowseFilter();
  var allowed = true;
  late StateSetter update;
}

Future<_Harness> _mount(
  WidgetTester tester,
  Size size,
  double scale, {
  bool bold = false,
  double? letterSpacing,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final h = _Harness();
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(fontFamily: _font),
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, set) {
            h.update = set;
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale), boldText: bold),
              child: DefaultTextStyle.merge(
                style: TextStyle(letterSpacing: letterSpacing),
                child: ZyraOneJourneyFiltersPresentation(
                  initialIndex: 1,
                  filter: h.filter,
                  canAct: () => h.allowed,
                  onChanged: (value) => set(() => h.filter = value),
                  onApply: () {},
                  onCountry: () {},
                  onOrigin: () {},
                  onPreferences: () {},
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return h;
}

RenderParagraph _paragraph(WidgetTester tester, int index) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(
        of: _key('concept_where_$index'),
        matching: find.byType(RichText),
      ),
    );

Map<String, Object?> _checkWords(WidgetTester tester) {
  final words = <Map<String, Object?>>[];
  for (var i = 0; i < _labels.length; i++) {
    final paragraph = _paragraph(tester, i);
    expect(paragraph.text.style!.fontFamily, _font);
    expect(paragraph.text.style!.fontSize, 12.5);
    for (final word in RegExp(r'\S+').allMatches(_labels[i])) {
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: word.start, extentOffset: word.end),
      );
      expect(boxes, hasLength(1), reason: '${word.group(0)} must stay whole');
      expect(
        boxes.single.toRect().width,
        lessThanOrEqualTo(paragraph.constraints.maxWidth + .0001),
      );
      words.add({
        'word': word.group(0),
        'advance_width': boxes.single.toRect().width,
        'available_width': paragraph.constraints.maxWidth,
        'font_weight': paragraph.text.style!.fontWeight!.value,
        'letter_spacing': paragraph.text.style!.letterSpacing,
      });
    }
  }
  return {'words': words};
}

Future<void> _tap(WidgetTester tester, int index) async {
  await tester.ensureVisible(_key('concept_where_$index'));
  await tester.tap(_key('concept_where_$index'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final oldStubs = ZyraText.useTestFontStubs;
  final oldFont = ZyraText.testReadingFontFamily;
  setUpAll(() async {
    final loader = FontLoader(_font);
    for (final weight in ['Light', 'Regular', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await loader.load();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = _font;
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = oldStubs;
    ZyraText.testReadingFontFamily = oldFont;
    File('build/line126-filter-segments-fit.json').writeAsStringSync(
      const JsonEncoder.withIndent(
        '  ',
      ).convert({'observations': _observations}),
    );
  });

  for (final size in [const Size(430, 932), const Size(375, 667)]) {
    for (final scale in [1.0, 1.3]) {
      for (final bold in [false, true]) {
        testWidgets(
          'LOCK10 whole segments ${size.width.toInt()}@$scale bold=$bold',
          (tester) async {
            final h = await _mount(tester, size, scale, bold: bold);
            final rects = [
              for (var i = 0; i < 3; i++)
                tester.getRect(_key('concept_where_$i')),
            ];
            final vertical = rects[1].top > rects[0].bottom - .01;
            if (size.width == 430 && scale == 1 && !bold) {
              expect(vertical, isFalse);
              expect(rects.map((r) => r.top).toSet(), hasLength(1));
              expect(rects[0].width, closeTo(rects[1].width, .0001));
              expect(rects[1].width, closeTo(rects[2].width, .0001));
              expect(tester.getSize(_key('concept_where_segments')).height, 48);
            }
            if (size.width == 375 && scale == 1.3) expect(vertical, isTrue);
            _observations.add({
              'size': [size.width, size.height],
              'scale': scale,
              'bold': bold,
              'vertical': vertical,
              ..._checkWords(tester),
            });
            expect(
              _paragraph(tester, 2).text.style!.fontWeight,
              bold ? FontWeight.bold : FontWeight.w400,
            );
            final footer = tester.widget<Text>(
              find.text('Your preferences also shape who you see ›'),
            );
            expect(footer.style!.color, ZyraColors.goldTextStrong);
            await _tap(tester, 2);
            expect(h.filter.where, ZyraBrowseWhere.worldwide);
            _checkWords(tester);
            await _tap(tester, 0);
            expect(h.filter.where, ZyraBrowseWhere.nearMe);
            await _tap(tester, 1);
            expect(h.filter.where, ZyraBrowseWhere.country);
            final oldTap = tester
                .widget<InkWell>(_key('concept_where_2'))
                .onTap!;
            h.update(() => h.allowed = false);
            await tester.pumpAndSettle();
            oldTap();
            expect(h.filter.where, ZyraBrowseWhere.country);
          },
          variant: TargetPlatformVariant.only(TargetPlatform.iOS),
        );
      }
    }
  }

  testWidgets('LOCK10 segment fit includes inherited letter spacing', (
    tester,
  ) async {
    await _mount(tester, const Size(430, 932), 1, letterSpacing: 8);
    final rects = [
      for (var i = 0; i < 3; i++) tester.getRect(_key('concept_where_$i')),
    ];
    expect(rects[1].top, greaterThanOrEqualTo(rects[0].bottom));
    expect(_paragraph(tester, 2).text.style!.letterSpacing, 8);
    _observations.add({
      'case': 'inherited letter spacing',
      ..._checkWords(tester),
    });
  });

  testWidgets('LOCK10 keeps its existing greater-than1.3 vertical branch', (
    tester,
  ) async {
    await _mount(tester, const Size(600, 932), 1.31);
    final rects = [
      for (var i = 0; i < 3; i++) tester.getRect(_key('concept_where_$i')),
    ];
    expect(rects[1].top, greaterThanOrEqualTo(rects[0].bottom));
    _checkWords(tester);
  });
}
