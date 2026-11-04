// Real-font member signup entry regression retained from the retired Home tests.
// Fixture callbacks only: no account, backend, provider or native actions.
// Capture with --update-goldens and
// --dart-define=ZYRA_DEV_HOME_CAPTURE_CANDIDATES=true.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import '../support/queue44_signup_flow_fixture.dart';

const _capture = bool.fromEnvironment('ZYRA_DEV_HOME_CAPTURE_CANDIDATES');
const _root = ValueKey('dev-home-navigation-candidate');
const _directory = 'candidates/dev_home_navigation_2026_09_29';

Future<void> _mount(
  WidgetTester tester,
  Widget home, {
  required Size size,
  required double scale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: const EdgeInsets.only(top: 24, bottom: 24),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
          disableAnimations: true,
          accessibleNavigation: true,
        ),
        child: RepaintBoundary(key: _root, child: child!),
      ),
      home: home,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _candidate(WidgetTester tester, String name) async {
  if (!_capture) return;
  expect(autoUpdateGoldenFiles, isTrue);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_root),
  );
  boundary.markNeedsPaint();
  await tester.pump();
  final frame = await tester.runAsync(() => boundary.toImage());
  expect(frame, isNotNull);
  final image = frame!;
  try {
    final data = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.png),
    );
    await tester.runAsync(
      () => expectLater(
        data!.buffer.asUint8List(),
        matchesGoldenFile('$_directory/$name.png'),
      ),
    );
  } finally {
    image.dispose();
  }
}

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsDevHomeNavigationAudit');
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
    final wordmark = FontLoader('SyneDevHomeNavigationAudit')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Syne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsDevHomeNavigationAudit';
    ZyraText.testWordmarkFontFamily = 'SyneDevHomeNavigationAudit';
  });

  setUp(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraText.restoreAppFont(null);
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });

  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });

  for (final viewport in const [
    (size: Size(390, 844), scale: 1.0, name: 'standard'),
    (size: Size(320, 568), scale: 1.4, name: 'compact_140'),
  ]) {
    testWidgets('member signup entry real-font ${viewport.name}', (
      tester,
    ) async {
      // Queue 44 removed developer Home and its Developer Access destination.
      // DEV_TOGGLES_REMOVAL_BRIEF_2026-10-30.md steps 3–6 retire those
      // assertions; preserve the same case's real member-entry checks below.
      await _mount(
        tester,
        const SignupFlowFixture(),
        size: viewport.size,
        scale: viewport.scale,
      );
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('dev_signup_close')), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(
        tester.getRect(find.byType(WelcomeScreen)),
        Offset.zero & viewport.size,
      );
      expect(find.text('Sign-up preview · no account changes'), findsNothing);
      expect(tester.takeException(), isNull);
      await _candidate(tester, 'member_signup_entry__${viewport.name}');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
