// Fresh review candidates only. Does not update accepted visual baselines.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_page_options.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/services/zyra_developer_access.dart';

const capture = bool.fromEnvironment('ZYRA_TOGGLE_SECTIONS_CAPTURE');
const root = ValueKey('toggle-sections-candidate');

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsAudit')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Poppins-Light.ttf').readAsBytesSync(),
          ),
        ),
      );
    await reading.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsAudit';
  });
  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraColors.restoreAppPalette(null);
  });
  tearDown(() => ZyraDeveloperAccess.resetAuthorizationForTesting());
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  for (final expanded in [false, true]) {
    testWidgets('Network categories ${expanded ? 'expanded' : 'closed'}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final options = <ZyraDevPageOption>[
        for (final label in [
          'Standard recommendations',
          'Request limit reached',
          'No recommendations',
          'Recommendations loading',
          'Recommendations unavailable',
        ])
          ZyraDevPageOption(
            id: 'scene-$label',
            label: label,
            group: 'Network scene',
            selected: label == 'Standard recommendations',
            onSelected: () {},
          ),
        for (final label in [
          '1 · Open canvas',
          '2 · Cinematic overlay',
          '3 · Editorial profile',
          '4 · Portrait focus',
          '5 · Minimal action rail',
        ])
          ZyraDevPageOption(
            id: 'design-$label',
            label: label,
            group: 'Network card design',
            selected: label == '2 · Cinematic overlay',
            onSelected: () {},
          ),
        for (final group in ['Profiles', 'Sent requests', 'Received requests'])
          for (var count = 1; count <= 3; count++)
            ZyraDevPageOption(
              id: '$group-$count',
              label: '$count ${count == 1 ? 'profile' : 'profiles'}',
              group: group,
              selected: count == 1,
              onSelected: () {},
            ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: RepaintBoundary(
              key: root,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Network', style: ZyraText.heading(size: 24)),
                        const SizedBox(height: 20),
                        ZyraDevPageOptions(
                          options: options,
                          contextKey: 'network',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (expanded) {
        await tester.tap(
          find.byKey(
            const ValueKey('dev_page_options_dropdown_Network card design'),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('scene-No recommendations')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('design-1 · Open canvas')),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
      if (capture) {
        await expectLater(
          find.byKey(root),
          matchesGoldenFile(
            'candidates/toggle_sections_2026_09_27/network_${expanded ? 'expanded' : 'closed'}.png',
          ),
        );
      }
    });
  }
}
