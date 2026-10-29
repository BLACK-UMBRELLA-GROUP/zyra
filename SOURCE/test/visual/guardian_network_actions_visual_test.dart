// Founder review candidates only. Never update an approved visual baseline.
// Capture with --update-goldens and
// --dart-define=ZYRA_GUARDIAN_NETWORK_ACTIONS_CAPTURE=true.
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

const _capture = bool.fromEnvironment('ZYRA_GUARDIAN_NETWORK_ACTIONS_CAPTURE');
const _captureRoot = ValueKey('guardian-network-actions-candidate');
const _candidateDirectory = 'candidates/guardian_network_actions_2026_09_27';

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsActionsAudit');
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
    ZyraText.testReadingFontFamily = 'PoppinsActionsAudit';
  });

  setUp(() {
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraText.restoreAppFont(null);
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevScenario.instance.reset();
    GNContext.instance.reset();
    ZyraDevScenario.instance.setWaliLinkedSeekers(1);
    GNContext.instance.setPreviewCount(GNNetworkPreviewArea.browser, 1);
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

  for (final viewport in const [
    (width: 390.0, height: 844.0, textScale: 1.0, label: 'standard'),
    (width: 320.0, height: 568.0, textScale: 1.4, label: 'compact_140'),
  ]) {
    testWidgets(
      'Portrait Focus and four action layouts remain reachable with real fonts: '
      '${viewport.label}',
      (tester) async {
        tester.view.physicalSize = Size(viewport.width, viewport.height);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(viewport.textScale)),
              child: child!,
            ),
            home: const Scaffold(
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
          for (final layout in GNNetworkActionLayout.values) {
            GNContext.instance.setNetworkActionLayout(layout);
            await tester.pumpAndSettle();
            expect(
              find.byKey(Key('gn-card-design-${design.name}')),
              findsOneWidget,
            );
            expect(
              find.byKey(Key('gn-browser-actions-${layout.name}')),
              findsOneWidget,
            );
            for (final actionKey in const [
              'gn-view-profile-action',
              'gn-speak-action',
              'gn-next-action',
            ]) {
              final action = find.byKey(Key(actionKey));
              expect(action, findsOneWidget);
              await tester.ensureVisible(action);
              await tester.pumpAndSettle();
              final page = tester.getRect(
                find.byKey(const Key('gn-mode-page-view')),
              );
              final rect = tester.getRect(action);
              expect(
                rect.center.dy,
                inInclusiveRange(page.top, page.bottom),
                reason:
                    '${design.label}, ${layout.label}: $actionKey is hidden',
              );
              expect(
                action.hitTestable(),
                findsOneWidget,
                reason:
                    '${design.label}, ${layout.label}: $actionKey is blocked',
              );
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(viewport.width));
              expect(
                rect.height,
                greaterThanOrEqualTo(44),
                reason: '${design.label}, ${layout.label}: $actionKey target',
              );
            }
            expect(
              tester.takeException(),
              isNull,
              reason: '${design.label}, ${layout.label}: overflow',
            );

            // Compact-screen candidates are scrolled to the actions, showing
            // all three arrangements rather than an off-screen button rail.
            if (_capture && design == GNNetworkCardDesign.portraitFocus) {
              await expectLater(
                find.byKey(_captureRoot),
                matchesGoldenFile(
                  '$_candidateDirectory/portraitFocus__${layout.name}__${viewport.label}.png',
                ),
              );
            }
          }
        }
      },
    );
  }
}
