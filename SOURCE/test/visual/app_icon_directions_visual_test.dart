// Candidate-only visual checks; no approved baseline is replaced.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_app_icon_directions.dart';
import 'package:zyra/services/zyra_dev_app_icon.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_text.dart';

const capture = bool.fromEnvironment('ZYRA_ICON_CAPTURE_CANDIDATES');
const root = ValueKey('icon-study-candidate');

Future<ByteData> font(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());

void main() {
  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader(
      'PoppinsAudit',
    )..addFont(font('assets/fonts/Poppins-Light.ttf'))).load();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsAudit';
  });
  setUp(() => ZyraDeveloperAccess.setAuthorizedForTesting(true));
  tearDown(() => ZyraDeveloperAccess.resetAuthorizationForTesting());
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  for (final icon in ZyraDevAppIcon.values) {
    testWidgets('${icon.name} real-font gallery candidate', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: RepaintBoundary(
            key: root,
            child: DevAppIconDirectionsScreen(
              initialIcon: icon,
              controller: ZyraDevAppIconController(isIOSOverride: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (capture) {
        await expectLater(
          find.byKey(root),
          matchesGoldenFile(
            'candidates/app_icons_2026_09_27/gallery_${icon.name}.png',
          ),
        );
      }
    });
  }
}
