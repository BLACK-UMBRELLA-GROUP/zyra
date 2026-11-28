import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/widgets/zyra_wordmark.dart';

const _font = 'ZYRAWordmarkRegressionSyne';
const _style = TextStyle(
  fontFamily: _font,
  fontSize: 54,
  fontWeight: FontWeight.w600,
  letterSpacing: 14,
  color: Color(0xFFA9792E),
);
const _mark = ValueKey('mark');
const _boundary = ValueKey('boundary');

Widget _host(
  Widget child, {
  double width = 335,
  TextScaler scaler = const TextScaler.linear(2),
  bool intrinsic = false,
  bool unbounded = false,
  MediaQueryData? media,
}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: (media ?? const MediaQueryData()).copyWith(textScaler: scaler),
    child: DefaultTextStyle(
      style: const TextStyle(fontSize: 16, color: Colors.black),
      child: Center(
        child: RepaintBoundary(
          key: _boundary,
          child: SizedBox(
            width: width,
            child: unbounded
                ? Row(mainAxisSize: MainAxisSize.min, children: [child])
                : intrinsic
                ? IntrinsicHeight(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [child],
                    ),
                  )
                : child,
          ),
        ),
      ),
    ),
  ),
);

RenderParagraph _paragraph(WidgetTester tester, Key key) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(of: find.byKey(key), matching: find.byType(RichText)),
    );

TextPainter _measure(RenderParagraph p, {TextScaler? scaler}) => TextPainter(
  text: p.text,
  textAlign: p.textAlign,
  textDirection: p.textDirection,
  textScaler: scaler ?? p.textScaler,
  maxLines: p.maxLines,
  locale: p.locale,
  strutStyle: p.strutStyle,
  textWidthBasis: p.textWidthBasis,
  textHeightBehavior: p.textHeightBehavior,
)..layout();

Future<Uint8List> _pixels(WidgetTester tester) async {
  final image = await tester
      .renderObject<RenderRepaintBoundary>(find.byKey(_boundary))
      .toImage(pixelRatio: 1);
  try {
    return (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

class _NonlinearScaler extends TextScaler {
  const _NonlinearScaler();
  @override
  double scale(double fontSize) => fontSize * (1 + fontSize / 54);
  @override
  double get textScaleFactor => 2;
}

void main() {
  setUpAll(() async {
    final font = FontLoader(_font)
      ..addFont(rootBundle.load('assets/fonts/Syne-SemiBold.ttf'));
    await font.load();
  });

  testWidgets('fitting wordmark retains exact Text metrics and pixels', (
    tester,
  ) async {
    const scaler = TextScaler.linear(1.3);
    await tester.pumpWidget(
      _host(
        const Text('ZYRA', key: _mark, style: _style),
        scaler: scaler,
      ),
    );
    final originalSize = tester.getSize(find.byKey(_mark));
    final originalBaseline = _paragraph(tester, _mark).getDryBaseline(
      const BoxConstraints(maxWidth: 335),
      TextBaseline.alphabetic,
    );
    final original = await tester.runAsync(() => _pixels(tester));
    await tester.pumpWidget(
      _host(
        const ZyraWordmark(key: _mark, style: _style),
        scaler: scaler,
      ),
    );
    expect(tester.getSize(find.byKey(_mark)), originalSize);
    expect(_paragraph(tester, _mark).textScaler, same(scaler));
    expect(
      _paragraph(tester, _mark).getDryBaseline(
        const BoxConstraints(maxWidth: 335),
        TextBaseline.alphabetic,
      ),
      originalBaseline,
    );
    final actual = await tester.runAsync(() => _pixels(tester));
    expect(actual, orderedEquals(original!));
    expect(tester.takeException(), isNull);
  });

  for (final width in [335.0, 280.0, 120.0]) {
    testWidgets('wordmark cap measures real tracking at width $width', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const ZyraWordmark(key: _mark, style: _style),
          width: width,
        ),
      );
      final p = _paragraph(tester, _mark);
      final measured = _measure(p);
      final slightlyLarger = _measure(
        p,
        scaler: TextScaler.linear(p.textScaler.scale(54) / 54 + .001),
      );
      try {
        expect(p.textScaler.scale(54), lessThan(108));
        expect(measured.maxIntrinsicWidth, lessThanOrEqualTo(width));
        expect(slightlyLarger.maxIntrinsicWidth, greaterThan(width));
        expect(measured.computeLineMetrics(), hasLength(1));
        expect(p.text.toPlainText(), 'ZYRA');
        expect((p.text as TextSpan).style!.letterSpacing, 14);
        expect((p.text as TextSpan).style!.fontSize, 54);
        expect(p.debugHasOverflowShader, isFalse);
      } finally {
        measured.dispose();
        slightlyLarger.dispose();
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('nonlinear scaler cap leaves nearby reading text inherited', (
    tester,
  ) async {
    const scaler = _NonlinearScaler();
    const reading = ValueKey('reading');
    await tester.pumpWidget(
      _host(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ZyraWordmark(key: _mark, style: _style),
            Text(
              'Ordinary reading text',
              key: reading,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        scaler: scaler,
      ),
    );
    final p = _paragraph(tester, _mark);
    final measured = _measure(p);
    try {
      expect(p.textScaler.scale(54), lessThan(scaler.scale(54)));
      expect(measured.maxIntrinsicWidth, lessThanOrEqualTo(335));
      expect(_paragraph(tester, reading).textScaler, same(scaler));
      expect(_paragraph(tester, reading).textScaler.scale(18), 24);
      expect(
        MediaQuery.textScalerOf(tester.element(find.byKey(_mark))),
        same(scaler),
      );
    } finally {
      measured.dispose();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('actual Text spacing and bold overrides are measured', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const ZyraWordmark(
          key: _mark,
          style: _style,
          locale: Locale('ar'),
          textDirection: TextDirection.rtl,
        ),
        media: const MediaQueryData(
          boldText: true,
          letterSpacingOverride: 18,
          wordSpacingOverride: 5,
          lineHeightScaleFactorOverride: 1.4,
        ),
      ),
    );
    final p = _paragraph(tester, _mark);
    final measured = _measure(p);
    try {
      expect(measured.maxIntrinsicWidth, lessThanOrEqualTo(335));
      expect(measured.computeLineMetrics(), hasLength(1));
      expect(p.locale, const Locale('ar'));
      expect(p.textDirection, TextDirection.rtl);
      expect((p.text as TextSpan).style!.letterSpacing, 18);
      expect((p.text as TextSpan).style!.fontWeight, FontWeight.bold);
    } finally {
      measured.dispose();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('intrinsic and dry layouts agree with capped real layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const ZyraWordmark(key: _mark, style: _style), intrinsic: true),
    );
    final box = tester.renderObject<RenderBox>(find.byKey(_mark));
    final size = box.size;
    final scaler = _paragraph(tester, _mark).textScaler;
    expect(box.getMaxIntrinsicHeight(335), size.height);
    expect(box.getDryLayout(const BoxConstraints(maxWidth: 335)), size);
    expect(_paragraph(tester, _mark).textScaler, scaler);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unbounded parent keeps natural inherited wordmark size', (
    tester,
  ) async {
    const scaler = TextScaler.linear(2);
    await tester.pumpWidget(
      _host(
        const ZyraWordmark(key: _mark, style: _style),
        width: 600,
        scaler: scaler,
        unbounded: true,
      ),
    );
    final p = _paragraph(tester, _mark);
    final measured = _measure(p);
    try {
      expect(p.textScaler, same(scaler));
      expect(
        tester.getSize(find.byKey(_mark)).width,
        measured.maxIntrinsicWidth,
      );
    } finally {
      measured.dispose();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('composed mark keeps one accessible brand name', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const ZyraWordmark(
          text: 'Z Y R A',
          key: _mark,
          style: _style,
          semanticsLabel: 'ZYRA',
        ),
      ),
    );
    expect(find.bySemanticsLabel('ZYRA'), findsOneWidget);
    expect(find.bySemanticsLabel('Z Y R A'), findsNothing);
    final measured = _measure(_paragraph(tester, _mark));
    try {
      expect(measured.maxIntrinsicWidth, lessThanOrEqualTo(335));
      expect(measured.computeLineMetrics(), hasLength(1));
    } finally {
      measured.dispose();
    }
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('animated letter group preserves fitting pixels and whole cap', (
    tester,
  ) async {
    Widget letters() => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 4; i++)
          Opacity(
            opacity: .8,
            child: Transform.translate(
              offset: Offset(0, i.toDouble()),
              child: Text(
                'ZYRA'[i],
                style: _style.copyWith(letterSpacing: i == 3 ? 0 : 4),
              ),
            ),
          ),
      ],
    );
    await tester.pumpWidget(
      _host(letters(), width: 400, scaler: TextScaler.noScaling),
    );
    final before = await tester.runAsync(() => _pixels(tester));
    await tester.pumpWidget(
      _host(
        ZyraWordmarkGroup(child: letters()),
        width: 400,
        scaler: TextScaler.noScaling,
      ),
    );
    final after = await tester.runAsync(() => _pixels(tester));
    expect(after, orderedEquals(before!));
    await tester.pumpWidget(
      _host(ZyraWordmarkGroup(child: letters()), width: 150),
    );
    var width = 0.0;
    final paragraphs = tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .toList();
    expect(paragraphs, hasLength(4));
    for (final p in paragraphs) {
      final measured = _measure(p);
      try {
        width += measured.width;
        expect(p.textScaler.scale(54), lessThan(108));
        expect(measured.computeLineMetrics(), hasLength(1));
      } finally {
        measured.dispose();
      }
    }
    expect(width, lessThanOrEqualTo(150));
    expect(tester.takeException(), isNull);
  });
}
