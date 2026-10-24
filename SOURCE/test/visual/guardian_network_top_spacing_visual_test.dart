// New review candidates only. Never update the approved visual baselines.
// Capture with --update-goldens and
// --dart-define=ZYRA_GUARDIAN_NETWORK_SPACING_CAPTURE=true.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_dev_scenario.dart';
import 'package:zyra/screens/wali/wali_gn_shared.dart';
import 'package:zyra/screens/wali/wali_network_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_segmented_toggle.dart';

const _capture = bool.fromEnvironment('ZYRA_GUARDIAN_NETWORK_SPACING_CAPTURE');
const _captureRoot = ValueKey('guardian-network-spacing-candidate');
const _candidateDirectory =
    'candidates/guardian_network_top_spacing_2026_09_27';

const _modes = [
  (segment: 'gn-mode-browser', card: 'gn-served-fam-h'),
  (segment: 'gn-mode-sent', card: 'gn-sent-fam-h'),
  (segment: 'gn-mode-received', card: 'gn-incoming-fam-h'),
];

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsAudit');
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
    ZyraText.testReadingFontFamily = 'PoppinsAudit';
  });

  setUp(() {
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraText.restoreAppFont(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevScenario.instance.reset();
    GNContext.instance.reset();
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    for (final area in GNNetworkPreviewArea.values) {
      GNContext.instance.setPreviewCount(area, 1);
    }
  });

  tearDown(() {
    GNContext.instance.reset();
    ZyraDevScenario.instance.reset();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
  });

  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
  });

  for (final viewport in [
    (width: 390.0, height: 844.0),
    (width: 320.0, height: 700.0),
  ]) {
    testWidgets(
      'all five Network designs and three tabs clear the mode pill at '
      '${viewport.width}×${viewport.height}',
      (tester) async {
        tester.view.physicalSize = Size(viewport.width, viewport.height);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: RepaintBoundary(
                key: _captureRoot,
                child: WaliNetworkScreen(),
              ),
            ),
          ),
        );
        await tester.pump();

        for (final design in GNNetworkCardDesign.values) {
          GNContext.instance.setNetworkCardDesign(design);
          await tester.pump();

          for (final mode in _modes) {
            await tester.tap(find.byKey(Key(mode.segment)));
            await tester.pumpAndSettle();

            final cardFinder = find.byKey(Key(mode.card));
            expect(cardFinder, findsOneWidget);
            expect(
              find.byKey(Key('gn-card-design-${design.name}')),
              findsOneWidget,
            );
            final pillBottom = tester
                .getRect(find.byType(ZyraSegmentedToggle))
                .bottom;
            final cardTop = tester.getRect(cardFinder).top;
            expect(
              cardTop - pillBottom,
              greaterThanOrEqualTo(18),
              reason:
                  '${design.label}, ${mode.segment}, '
                  '${viewport.width}×${viewport.height}: card touches tab pill',
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '${design.label}, ${mode.segment}',
            );

            // The five designs remain undecided. These are review candidates,
            // never a selection or an approved visual baseline update.
            if (_capture && viewport.width == 390) {
              await expectLater(
                find.byKey(_captureRoot),
                matchesGoldenFile(
                  '$_candidateDirectory/${design.name}__${mode.segment}.png',
                ),
              );
            }
          }
        }
      },
    );
  }

  testWidgets('the mode-to-content gutter remains fixed while cards scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final area in GNNetworkPreviewArea.values) {
      GNContext.instance.setPreviewCount(area, 3);
    }

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: WaliNetworkScreen())),
    );
    await tester.pump();

    final pill = find.byType(ZyraSegmentedToggle);
    final page = find.byKey(const Key('gn-mode-page-view'));
    final initialGutter =
        tester.getRect(page).top - tester.getRect(pill).bottom;
    expect(initialGutter, greaterThanOrEqualTo(16));

    for (final mode in _modes) {
      await tester.tap(find.byKey(Key(mode.segment)));
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(Key(mode.card)), const Offset(0, -340));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(page).top - tester.getRect(pill).bottom,
        closeTo(initialGutter, 0.01),
        reason: '${mode.segment} must not scroll into the segmented control',
      );
      expect(tester.takeException(), isNull, reason: mode.segment);
    }
  });

  testWidgets(
    'all five designs keep their primary actions reachable at 320×568 and 1.4× text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.4)),
            child: child!,
          ),
          home: const Scaffold(body: WaliNetworkScreen()),
        ),
      );
      await tester.pump();

      for (final design in GNNetworkCardDesign.values) {
        GNContext.instance.setNetworkCardDesign(design);
        await tester.pump();

        for (final target in const [
          (segment: 'gn-mode-browser', action: 'gn-next-action'),
          (segment: 'gn-mode-sent', action: 'gn-withdraw-fam-h'),
          (segment: 'gn-mode-received', action: 'gn-connect-family-action'),
        ]) {
          await tester.tap(find.byKey(Key(target.segment)));
          await tester.pumpAndSettle();

          final action = find.byKey(Key(target.action));
          expect(action, findsOneWidget);
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();

          final page = tester.getRect(
            find.byKey(const Key('gn-mode-page-view')),
          );
          final actionRect = tester.getRect(action);
          expect(
            actionRect.center.dy,
            inInclusiveRange(page.top, page.bottom),
            reason: '${design.label}, ${target.segment}: action is off-screen',
          );
          expect(
            action.hitTestable(),
            findsOneWidget,
            reason: '${design.label}, ${target.segment}: action is blocked',
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${design.label}, ${target.segment}: layout overflow',
          );
        }
      }
    },
  );
}
