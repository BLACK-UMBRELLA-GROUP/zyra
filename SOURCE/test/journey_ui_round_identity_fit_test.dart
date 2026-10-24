import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_one_journey_card_content.dart';
import 'package:zyra/dev/zyra_one_journey_discovery_presentation.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

const _font = 'PoppinsJourneyUiRound';
const _capture = String.fromEnvironment('ZYRA_UI_ROUND_CAPTURE_DIR');
const _boundary = ValueKey('journey-ui-round-frame');

void main() {
  setUpAll(() async {
    final font = FontLoader(_font);
    for (final weight in ['Light', 'Regular', 'Medium', 'SemiBold', 'Bold']) {
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

  for (final width in [320.0, 393.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('public identity and Continue fit at ${width}x$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var continues = 0;
        final button = ZyraOneJourneyConnectionsActionButton(
          primary: true,
          action: ZyraOneJourneyConnectionsAction(
            key: const ValueKey('ui_round_continue'),
            label: 'Continue Journey',
            icon: null,
            fitLabel: true,
            onTap: () => continues++,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: true,
              ),
              child: RepaintBoundary(key: _boundary, child: child!),
            ),
            home: Scaffold(
              backgroundColor: ZyraColors.luxuryDarkPurple,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ZyraColors.surfaceFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ZyraOneJourneyCardContent(
                    design: ZyraOneJourneyCardDesign.portraitSplit,
                    profile: SeekerProfile(
                      id: 'draft-sara',
                      firstName: 'Sara',
                      surnameLine: 'Ahmed',
                      age: 27,
                      city: 'Birmingham',
                      gender: 'female',
                      photos: const [],
                      publicNationality: 'Pakistani',
                      publicEthnicity: 'Pakistani',
                    ),
                    photo: ColoredBox(color: ZyraColors.surfaceEmphasisFill),
                    action: Row(
                      children: [
                        Expanded(child: button),
                        const SizedBox(width: 6),
                        const SizedBox.square(dimension: 38),
                      ],
                    ),
                    primaryButton: button,
                    fillHeight: false,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Nationality: Pakistani'), findsOneWidget);
        expect(find.text('Ethnicity: Pakistani'), findsOneWidget);
        final label = find.text('Continue Journey');
        expect(label, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(label);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(paragraph.maxLines, 1);
        expect(paragraph.softWrap, isFalse);
        final actualScale = paragraph.getTransformTo(null).getMaxScaleOnAxis();
        final effectiveSize = 12.5 * scale * actualScale;
        expect(effectiveSize, greaterThanOrEqualTo(scale == 1 ? 11.5 : 19));
        await tester.tap(find.byKey(const ValueKey('ui_round_continue')));
        expect(continues, 1);
        expect(tester.takeException(), isNull);
        if (_capture.isNotEmpty) {
          final directory = Directory(_capture);
          if (!_capture.startsWith('/') || !directory.existsSync()) {
            throw StateError('Explicit existing capture directory required');
          }
          final render = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(_boundary),
          );
          await tester.runAsync(() async {
            final file = File(
              '$_capture/journey-continue-${width.toInt()}-${scale.toInt()}x.png',
            );
            await file.create(exclusive: true);
            final image = await render
                .toImage(pixelRatio: 1)
                .timeout(const Duration(seconds: 5));
            try {
              final bytes = await image
                  .toByteData(format: ui.ImageByteFormat.png)
                  .timeout(const Duration(seconds: 5));
              await file
                  .writeAsBytes(bytes!.buffer.asUint8List(), flush: true)
                  .timeout(const Duration(seconds: 5));
            } finally {
              image.dispose();
            }
          });
        }
      });
    }
  }
}
