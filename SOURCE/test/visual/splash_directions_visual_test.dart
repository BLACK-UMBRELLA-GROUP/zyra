// Review candidates only. No accepted baseline is replaced or promoted.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_splash_directions.dart';
import 'package:zyra/screens/splash_screen.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_splash_artwork.dart'
    show ZyraSplashArtworkFrame, zyraPrimarySplashDirection;

const capture = bool.fromEnvironment('ZYRA_SPLASH_CAPTURE_CANDIDATES');
const root = ValueKey('splash-study-candidate');

Future<ByteData> font(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());

void main() {
  setUpAll(() async {
    await Future.wait([
      (FontLoader(
        'PoppinsAudit',
      )..addFont(font('assets/fonts/Poppins-Light.ttf'))).load(),
      (FontLoader(
        'SyneAudit',
      )..addFont(font('assets/fonts/Syne-SemiBold.ttf'))).load(),
    ]);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsAudit';
    ZyraText.testWordmarkFontFamily = 'SyneAudit';
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });

  for (final direction in ZyraSplashDirection.values) {
    testWidgets('${direction.name} settled candidate', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: root,
              child: ZyraSplashStudy(direction: direction),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 4401));
      expect(tester.takeException(), isNull);
      if (capture) {
        await expectLater(
          find.byKey(root),
          matchesGoldenFile(
            'candidates/dark_hulu_app_2026_09_27/${direction.name}.png',
          ),
        );
      }
    });
  }

  for (final size in [const Size(390, 844), const Size(320, 568)]) {
    testWidgets('main Quiet Horizon at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: RepaintBoundary(key: root, child: SplashScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 2401));
      expect(
        tester
            .widget<ZyraSplashArtworkFrame>(find.byType(ZyraSplashArtworkFrame))
            .direction,
        zyraPrimarySplashDirection,
      );
      expect(find.text('Connecting Through Trust'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (capture) {
        await expectLater(
          find.byKey(root),
          matchesGoldenFile(
            'candidates/quiet_horizon_main_2026_09_27/main_${size.width.toInt()}.png',
          ),
        );
      }
    });
  }
}
