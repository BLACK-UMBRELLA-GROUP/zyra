import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/main.dart' show ZyraApp;
import 'package:zyra/screens/subscription/zyra_one_upgrade_page.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

const _seeker = [
  ('Journey places', '1', '3'),
  ('Browse profiles', '25 every 4 hours', 'Unlimited'),
  ('Requests waiting at once', '5', '20'),
  ('Compatibility score', 'Overall score', 'Every topic'),
  ('Filters', 'Age and location', 'All filters'),
  ('Guardians', '1 on Guardian Basic', 'Any 10'),
  ('Look again at declined profiles', '—', 'Up to 10'),
  ('Chaperoned video calls', '—', 'Coming later'),
];
const _guardian = [
  ('See the Journeys your Seeker allows', '✓', '✓'),
  ('Family Review (Main Guardian)', '✓', '✓'),
  ('Chat in a Journey, when your Seeker allows it', '—', '✓'),
  ('Compatibility score', 'Overall score', 'Every topic'),
  ('Join chaperoned video calls', '—', 'Coming later'),
];

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('Comparison fit tests use bundled fonts only.');
  }
}

Future<void> _mount(
  WidgetTester tester, {
  required bool guardian,
  required double width,
  required double scale,
  double? height,
  bool bold = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height ?? (width == 430 ? 932 : 667));
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        final source = const ZyraApp().build(context) as ListenableBuilder;
        final app = source.builder(context, null) as MaterialApp;
        return MaterialApp(
          theme: app.theme,
          scrollBehavior: app.scrollBehavior,
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
            backgroundColor: ZyraColors.ivoryTop,
            body: DecoratedBox(
              decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
              child: ZyraOneUpgradePage(
                guardian: guardian,
                includesPreviewComparisons: true,
                canContinue: () => true,
                onBack: () {},
              ),
            ),
          ),
        );
      },
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Finder get _comparison => find.byKey(const ValueKey('one-upgrade-comparison'));
Finder get _rows => find.descendant(
  of: _comparison,
  matching: find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString() == '_ComparisonRow',
  ),
);
Finder _cells(Finder row) =>
    find.descendant(of: row, matching: find.byType(Text));
RenderParagraph _paragraph(WidgetTester tester, Finder text) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: text, matching: find.byType(RichText)),
    );

double _wordWidth(RenderParagraph render, String word) {
  final painter = TextPainter(
    text: TextSpan(text: word, style: render.text.style),
    textDirection: render.textDirection,
    textScaler: render.textScaler,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}

String _readable(String value) => switch (value) {
  '✓' => 'Included',
  '—' => 'Unavailable',
  _ => value,
};

void _verify(
  WidgetTester tester, {
  required bool guardian,
  required double width,
  required double scale,
  bool bold = false,
}) {
  final expected = [('', 'BASIC', 'ONE'), ...guardian ? _guardian : _seeker];
  expect(_rows, findsNWidgets(expected.length));
  final stacked = _cells(_rows.first).evaluate().length == 2;
  final rowWidth = tester.getSize(_comparison).width - 24;
  final originalPlanWidth = rowWidth * .27 - 6;
  var anyOverwideWord = false;
  for (var index = 0; index < expected.length; index++) {
    final row = _rows.at(index);
    final values = [expected[index].$1, expected[index].$2, expected[index].$3];
    final cells = _cells(row);
    expect(cells, findsNWidgets(stacked && index == 0 ? 2 : 3));
    for (var column = 0; column < values.length; column++) {
      if (stacked && index == 0 && column == 0) continue;
      final cellIndex = stacked && index == 0 ? column - 1 : column;
      final finder = cells.at(cellIndex);
      final text = tester.widget<Text>(finder);
      final render = _paragraph(tester, finder);
      final display = render.text.toPlainText();
      expect(display.replaceAll(RegExp(r'\s+'), ' '), values[column]);
      expect(text.style!.fontSize, index == 0 && column > 0 ? 11 : 13);
      expect(
        text.style!.fontWeight,
        column == 2 ? FontWeight.w500 : FontWeight.w400,
      );
      expect(text.textScaler, isNull);
      expect(text.maxLines, isNull);
      expect(render.didExceedMaxLines, isFalse);
      if (values[column].isNotEmpty) {
        expect(render.text.style!.fontFamily, 'Poppins');
        expect(render.textScaler.scale(13), closeTo(13 * scale, .0001));
        expect(
          render.text.style!.fontWeight,
          bold ? FontWeight.bold : text.style!.fontWeight,
        );
      }
      for (final word in RegExp(r'\S+').allMatches(display)) {
        final boxes = render.getBoxesForSelection(
          TextSelection(baseOffset: word.start, extentOffset: word.end),
        );
        expect(boxes, isNotEmpty);
        expect(
          boxes.every((box) => (box.top - boxes.first.top).abs() < .01),
          isTrue,
          reason: '$width/$scale: split ${word.group(0)}',
        );
        expect(
          _wordWidth(render, word.group(0)!),
          lessThanOrEqualTo(render.size.width + .01),
        );
        if (column > 0) {
          anyOverwideWord |=
              _wordWidth(render, word.group(0)!) > originalPlanWidth;
        }
      }
    }
    if (index > 0) {
      final semantics = find
          .descendant(of: row, matching: find.byType(Semantics))
          .first;
      expect(
        tester.widget<Semantics>(semantics).properties.label,
        '${values[0]}. Basic, ${_readable(values[1])}. One, ${_readable(values[2])}.',
      );
      final label = tester.getRect(cells.at(0));
      final basic = tester.getRect(cells.at(1));
      final one = tester.getRect(cells.at(2));
      if (stacked) {
        expect(label.width, closeTo(rowWidth, .01));
        expect(basic.top, greaterThanOrEqualTo(label.bottom - .01));
        expect(one.top, greaterThanOrEqualTo(label.bottom - .01));
        expect(basic.width, closeTo(rowWidth / 2 - 6, .01));
        expect(one.width, closeTo(basic.width, .01));
      } else {
        expect(label.width, closeTo(rowWidth * .46, .01));
        expect(basic.width, closeTo(originalPlanWidth, .01));
        expect(one.width, closeTo(originalPlanWidth, .01));
      }
    } else if (stacked) {
      final basic = tester.getRect(cells.at(0));
      final one = tester.getRect(cells.at(1));
      expect(basic.width, closeTo(rowWidth / 2 - 6, .01));
      expect(one.width, closeTo(basic.width, .01));
    }
  }
  expect(
    stacked,
    anyOverwideWord,
    reason: 'One overwide plan word switches the entire table and its header.',
  );
  if (width == 430 && scale == 1) expect(stacked, isFalse);
  if (!guardian && width == 375 && scale == 1.3) expect(stacked, isTrue);
}

void main() {
  final network = _NoNetwork();
  final oldNetwork = HttpOverrides.current;
  final oldStubs = ZyraText.useTestFontStubs;
  final oldFamily = ZyraText.testReadingFontFamily;
  setUpAll(() async {
    HttpOverrides.global = network;
    final font = FontLoader('Poppins');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([font.load(), icons.load()]);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'Poppins';
  });
  tearDownAll(() {
    expect(network.attempts, 0);
    HttpOverrides.global = oldNetwork;
    ZyraText.useTestFontStubs = oldStubs;
    ZyraText.testReadingFontFamily = oldFamily;
  });
  for (final guardian in [false, true]) {
    for (final width in [430.0, 375.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets(
          'Q194 ${guardian ? 'Guardian' : 'Seeker'} Basic $width/$scale',
          (tester) async {
            await _mount(
              tester,
              guardian: guardian,
              width: width,
              scale: scale,
            );
            _verify(tester, guardian: guardian, width: width, scale: scale);
          },
        );
      }
    }
  }
  testWidgets(
    'Q194 measures inherited bold text before selecting one table mode',
    (tester) async {
      await _mount(tester, guardian: false, width: 375, scale: 1.3, bold: true);
      _verify(tester, guardian: false, width: 375, scale: 1.3, bold: true);
    },
  );
  testWidgets('Q194 Guardian wider plan words also switch together', (
    tester,
  ) async {
    await _mount(tester, guardian: true, width: 320, height: 932, scale: 2);
    _verify(tester, guardian: true, width: 320, scale: 2);
    expect(_cells(_rows.first), findsNWidgets(2));
  });
  testWidgets('Q194 responds at the measured original plan-word boundary', (
    tester,
  ) async {
    await _mount(tester, guardian: false, width: 375, scale: 1);
    final measuredWords =
        <({String word, TextStyle? style, TextDirection direction})>[];
    for (final row in _rows.evaluate()) {
      final texts = _cells(find.byWidget(row.widget));
      for (final column in [1, 2]) {
        final render = _paragraph(tester, texts.at(column));
        for (final word in RegExp(
          r'\S+',
        ).allMatches(render.text.toPlainText())) {
          measuredWords.add((
            word: word.group(0)!,
            style: render.text.style,
            direction: render.textDirection,
          ));
        }
      }
    }
    final originalWidth = (tester.getSize(_comparison).width - 24) * .27 - 6;
    double widest(double scale) {
      var result = 0.0;
      for (final word in measuredWords) {
        final painter = TextPainter(
          text: TextSpan(text: word.word, style: word.style),
          textDirection: word.direction,
          textScaler: TextScaler.linear(scale),
        )..layout();
        if (painter.width > result) result = painter.width;
        painter.dispose();
      }
      return result;
    }

    // Font advances and inherited tracking need not scale by the same factor.
    // Measure each proposed scaler rather than multiplying the 1.0 width.
    var below = 1.0, above = 2.0;
    expect(widest(below), lessThan(originalWidth));
    expect(widest(above), greaterThan(originalWidth));
    for (var iteration = 0; iteration < 20; iteration++) {
      final middle = (below + above) / 2;
      if (widest(middle) <= originalWidth) {
        below = middle;
      } else {
        above = middle;
      }
    }
    final boundary = (below + above) / 2;
    final retained = tester.renderObject(_comparison);
    await _mount(tester, guardian: false, width: 375, scale: boundary - .005);
    expect(_cells(_rows.first), findsNWidgets(3));
    await _mount(tester, guardian: false, width: 375, scale: boundary + .005);
    expect(_cells(_rows.first), findsNWidgets(2));
    expect(tester.renderObject(_comparison), same(retained));
    _verify(tester, guardian: false, width: 375, scale: boundary + .005);
  });
}
