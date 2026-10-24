// New review candidates only; never writes approved visual baselines.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_scrollable_seeker_selector.dart';

const _capture = bool.fromEnvironment('ZYRA_SEEKER_SELECTOR_CAPTURE');
const _root = ValueKey('seeker-selector-candidate');
const _names = [
  'Aaliyah',
  'Umar',
  'Sumayyah',
  'Maryam',
  'Yusuf',
  'Zaynab',
  'Hamza',
  'Safiya',
  'Ibrahim',
  'Fatima',
];

void main() {
  setUpAll(() async {
    await (FontLoader('PoppinsAudit')..addFont(
          Future.value(
            ByteData.sublistView(
              File('assets/fonts/Poppins-Light.ttf').readAsBytesSync(),
            ),
          ),
        ))
        .load();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsAudit';
    ZyraColors.restoreAppPalette(null);
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  for (final position in [-1.0, 0.0, 9.65, 10.0, 24.0]) {
    testWidgets('ten-person strip at $position', (tester) async {
      tester.view.physicalSize = const Size(390, 230);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: _root,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Guardian Dashboard',
                        style: ZyraText.heading(size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Assalamu alaikum, Ibrahim.',
                        style: ZyraText.body(size: 13),
                      ),
                      const SizedBox(height: 14),
                      ZyraScrollableSeekerSelector(
                        labels: _names,
                        segmentKeys: [
                          for (var index = 0; index < _names.length; index++)
                            ValueKey('person-$index'),
                        ],
                        position: position,
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      if (_capture) {
        await expectLater(
          find.byKey(_root),
          matchesGoldenFile(
            'candidates/seeker_carousel_2026_09_27/position_${position.toString().replaceAll('.', '_')}.png',
          ),
        );
      }
    });
  }
}
