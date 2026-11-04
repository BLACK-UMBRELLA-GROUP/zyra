// Fresh review candidates only. Does not update accepted visual baselines.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/zyra_preview_navigation_checkpoint.dart';
import 'package:zyra/dev/zyra_view_request_draft_model.dart';
import 'baseline_capture_support.dart';
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
    await baselineSetUp(
      evidenceRoot: '.buildlog/queue44_20261103/network-sections',
    );
  });
  setUp(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraColors.restoreAppPalette(null);
  });
  tearDown(() => ZyraDeveloperAccess.resetAuthorizationForTesting());
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    baselineTearDown();
  });

  for (final expanded in [false, true]) {
    testWidgets(
      'member Network ${expanded ? 'sent' : 'recommended'} has no developer categories',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final h = BaselineHarness(
          tester,
          group: 'network-categories',
          outputRoot: '.buildlog/queue44_20261103/network-sections',
          evidenceRoot: '.buildlog/queue44_20261103/network-sections',
        );
        await h.mount(
          guardian: true,
          tab: 0,
          checkpoint: ZyraPreviewNavigationCheckpoint(
            guardian: true,
            model: ViewRequestDraftModel().snapshot(),
            tab: 0,
            pages: const [],
            networkTab: expanded ? 1 : 0,
          ),
        );
        expect(h.latest.networkTab, expanded ? 1 : 0);
        expect(find.text('Network'), findsWidgets);
        for (final group in [
          'Network scene',
          'Network card design',
          'Profiles',
          'Sent requests',
          'Received requests',
        ]) {
          expect(
            find.byKey(ValueKey('dev_page_options_group_$group')),
            findsNothing,
          );
          expect(
            find.byKey(ValueKey('dev_page_options_dropdown_$group')),
            findsNothing,
          );
        }
        expect(tester.takeException(), isNull);
        if (capture) {
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              'candidates/toggle_sections_2026_09_27/network_${expanded ? 'expanded' : 'closed'}.png',
            ),
          );
        }
      },
    );
  }
}
