import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_profile_details_page.dart';
import 'package:zyra/widgets/zyra_profile_name_block.dart';

const _capture = bool.fromEnvironment('ZYRA_LOCK33_CAPTURE');
const _boundary = ValueKey('lock33_capture');
SeekerProfile _profile(String first, String surname) => SeekerProfile(
  id: 'lock33',
  firstName: first,
  surnameLine: surname,
  age: 28,
  city: 'London',
  gender: 'female',
  photos: const [],
);

Future<void> _mount(
  WidgetTester tester,
  Size size,
  Widget child, {
  double scale = 1,
  bool bold = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale), boldText: bold),
        child: child!,
      ),
      home: Scaffold(
        body: RepaintBoundary(key: _boundary, child: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Lock33Poppins');
    for (final weight in ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold']) {
      font.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
    }
    await font.load();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'Lock33Poppins';
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  for (final size in [const Size(375, 667), const Size(430, 932)]) {
    for (final (first, surname) in [
      ('Fatima-Zahra', 'Abdul-Rahman Al-Hashimi'),
      ('Zainab', 'Malik-Abdulkareem Bin Yusuf'),
      (
        'A very long existing compound first name',
        'An existing surname with many words that cannot fit into two lines at this width',
      ),
    ]) {
      for (final details in [false, true]) {
        testWidgets('LOCK33 ${details ? 'details' : 'photo'} $first at $size', (
          tester,
        ) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          var disposed = false;
          addTearDown(() {
            if (!disposed) semantics.dispose();
          });
          final profile = _profile(first, surname);
          await _mount(
            tester,
            size,
            details
                ? ZyraProfileDetailsPage(profile: profile)
                : Padding(
                    padding: const EdgeInsets.all(22),
                    child: ZyraProfileNameBlock(profile: profile),
                  ),
          );
          final text = tester.widget<Text>(find.text(first));
          final base = details ? 34.0 : 30.0;
          expect(text.maxLines, 1);
          expect(text.overflow, TextOverflow.ellipsis);
          expect(text.style!.fontSize, inInclusiveRange(base * .75, base));
          expect(text.semanticsLabel, '$first $surname');
          final sur = tester.widget<Text>(find.text(surname));
          expect(sur.maxLines, 2);
          expect(sur.overflow, TextOverflow.ellipsis);
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.text(surname),
              matching: find.byType(RichText),
            ),
          );
          expect(
            paragraph.size.height,
            lessThanOrEqualTo((sur.style!.fontSize! * 1.5) * 2 + 1),
          );
          expect(find.bySemanticsLabel('$first $surname'), findsOneWidget);
          if (_capture && first == 'Fatima-Zahra') {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(_boundary),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage();
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                'build/line99_captures/${details ? 'details' : 'photo'}_${size.width.toInt()}x${size.height.toInt()}.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(data!.buffer.asUint8List());
              image.dispose();
            });
          }
          semantics.dispose();
          disposed = true;
        });
      }
    }
  }
  testWidgets(
    'LOCK33 first name uses full size, intermediate fit, then75percent ellipsis',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final width in [350.0, 170.0, 50.0]) {
        await _mount(
          tester,
          const Size(375, 667),
          SizedBox(
            width: width,
            child: ZyraFittedProfileFirstName(
              'Fatima-Zahra',
              style: ZyraText.heading(size: 30),
            ),
          ),
        );
        final text = tester.widget<Text>(find.text('Fatima-Zahra'));
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text('Fatima-Zahra'),
        );
        if (width == 350) expect(text.style!.fontSize, 30);
        if (width == 170) {
          expect(text.style!.fontSize, greaterThan(22.5));
          expect(text.style!.fontSize, lessThan(30));
          expect(paragraph.didExceedMaxLines, isFalse);
        }
        if (width == 50) {
          expect(text.style!.fontSize, 22.5);
          expect(paragraph.didExceedMaxLines, isTrue);
        }
      }
    },
  );
  testWidgets('LOCK33 accessible scaling and bold preserve the fit floor', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mount(
      tester,
      const Size(375, 667),
      Padding(
        padding: const EdgeInsets.all(22),
        child: ZyraProfileNameBlock(
          profile: _profile('Fatima-Zahra', 'Abdul-Rahman Al-Hashimi'),
        ),
      ),
      scale: 1.4,
      bold: true,
    );
    final text = tester.widget<Text>(find.text('Fatima-Zahra'));
    expect(text.style!.fontSize, inInclusiveRange(22.5, 30));
    final painter = TextPainter(
      text: TextSpan(
        text: text.data,
        style: text.style!.copyWith(fontWeight: FontWeight.bold),
      ),
      textScaler: const TextScaler.linear(1.4),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: 331);
    expect(painter.didExceedMaxLines, isFalse);
    painter.dispose();
  });
  testWidgets(
    'LOCK33 unbroken existing first name reaches75percent then ellipsis',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final name = 'W' * 60;
      await _mount(
        tester,
        const Size(375, 667),
        SizedBox(
          width: 200,
          child: ZyraFittedProfileFirstName(
            name,
            style: ZyraText.heading(size: 30),
          ),
        ),
      );
      expect(tester.widget<Text>(find.text(name)).style!.fontSize, 22.5);
      expect(
        tester.renderObject<RenderParagraph>(find.text(name)).didExceedMaxLines,
        isTrue,
      );
    },
  );
}
