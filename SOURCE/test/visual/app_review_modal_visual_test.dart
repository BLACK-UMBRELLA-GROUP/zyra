// Candidate-only proof of the shared modal with bundled Poppins/Syne metrics.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_glass_dialog.dart';

const _capture = bool.fromEnvironment('ZYRA_APP_REVIEW_MODAL_CAPTURE');
const _boundary = ValueKey('app-review-modal-candidate');

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsAppReview');
    for (final weight in [
      'ExtraLight',
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
    ]) {
      reading.addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-$weight.ttf').readAsBytesSync(),
          ),
        ),
      );
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsAppReview';
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });
  for (final (name, size, scale) in [
    ('phone', const Size(390, 844), 1.0),
    ('compact160', const Size(320, 568), 1.6),
    ('compact200', const Size(320, 568), 2.0),
  ]) {
    testWidgets('shared app modal real fonts $name', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 48),
                foregroundColor: ZyraColors.foreground,
                backgroundColor: ZyraColors.surfaceEmphasisFill,
                side: BorderSide(color: ZyraColors.surfaceEmphasisBorder),
                shape: const StadiumBorder(),
              ),
            ),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              textScaler: TextScaler.linear(scale),
            ),
            child: RepaintBoundary(key: _boundary, child: child!),
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Container(
                decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => showZyraGlassChoice(
                    context: context,
                    icon: Icons.visibility_outlined,
                    title: 'Unhide this profile?',
                    body:
                        'You may see each other in Browse again. Any report '
                        'stays with ZYRA, and any Journey ended by the hide '
                        'will not be restored.',
                    primaryLabel: 'Unhide',
                    secondaryLabel: 'Cancel',
                    primaryKey: const ValueKey('review_modal_primary'),
                  ),
                  child: Text('Review', style: ZyraText.body()),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _candidate(tester, name);
      await tester.ensureVisible(
        find.byKey(const ValueKey('review_modal_primary')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('review_modal_primary')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await _candidate(tester, '${name}_action');
      await tester.tap(find.byKey(const ValueKey('review_modal_primary')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('zyra_modal_surface')), findsNothing);
    });
  }
}

Future<void> _candidate(WidgetTester tester, String name) async {
  if (!_capture) return;
  expect(autoUpdateGoldenFiles, isTrue);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final image = await tester.runAsync(() => boundary.toImage());
  try {
    final data = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    await tester.runAsync(
      () => expectLater(
        data!.buffer.asUint8List(),
        matchesGoldenFile('candidates/app_review_2026_10_03/modal_$name.png'),
      ),
    );
  } finally {
    image?.dispose();
  }
}
