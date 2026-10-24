// Real-font review candidates for the shared developer Home action.
// Fixture callbacks only: no account, backend, provider or native actions.
// Capture with --update-goldens and
// --dart-define=ZYRA_DEV_HOME_CAPTURE_CANDIDATES=true.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_signup_process.dart';
import 'package:zyra/dev/zyra_dev_control_system.dart';
import 'package:zyra/dev/zyra_dev_surface_coordinator.dart';
import 'package:zyra/dev/zyra_dev_tool_section.dart';
import 'package:zyra/screens/dev/developer_access_screen.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

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

Widget _homeToolsFixture({
  required VoidCallback onHome,
  required VoidCallback otherAction,
}) => Scaffold(
  body: DecoratedBox(
    decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
    child: SafeArea(
      child: Center(
        child: SizedBox(
          width: 280,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Builder(
              builder: (context) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Developer Access', style: ZyraText.heading(size: 22)),
                  const SizedBox(height: 16),
                  ZyraDevHomeTools(
                    busy: false,
                    onHome: () {
                      onHome();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => const DeveloperAccessScreen(),
                        ),
                        (_) => false,
                      );
                    },
                    onRestart: otherAction,
                    onReset: otherAction,
                    onAccounts: otherAction,
                    onSeekerSignUp: otherAction,
                    onGuardianSignUp: otherAction,
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
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
    ZyraInternalPreviewClient.beginPreview();
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
    ZyraText.restoreAppFont(null);
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDevSurfaceCoordinator.instance.resetForTesting();
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
    testWidgets('shared Home and destination real-font ${viewport.name}', (
      tester,
    ) async {
      var homes = 0;
      var otherActions = 0;
      await _mount(
        tester,
        _homeToolsFixture(
          onHome: () => homes++,
          otherAction: () => otherActions++,
        ),
        size: viewport.size,
        scale: viewport.scale,
      );
      final label = find.text('Home');
      expect(label, findsOneWidget);
      final home = find
          .ancestor(of: label, matching: find.byType(InkWell))
          .first;
      expect(home.hitTestable(), findsOneWidget);
      final rect = tester.getRect(home);
      expect(rect.top, greaterThanOrEqualTo(24));
      expect(rect.bottom, lessThanOrEqualTo(viewport.size.height - 24));
      expect(rect.size.shortestSide, greaterThanOrEqualTo(48));
      final labelRect = tester.getRect(label);
      expect(labelRect.left, greaterThanOrEqualTo(rect.left));
      expect(labelRect.right, lessThanOrEqualTo(rect.right));
      expect(labelRect.bottom, lessThanOrEqualTo(rect.bottom));
      final section = find.ancestor(
        of: label,
        matching: find.byType(ZyraDevToolSection),
      );
      expect(section, findsOneWidget);
      expect(
        find.descendant(of: section, matching: find.text('Restart at login')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: section,
          matching: find.text('Onboarding directions'),
        ),
        findsNothing,
      );
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: section,
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.color, ZyraColors.surfaceFill);
      expect(find.text('Exit onboarding'), findsNothing);
      expect(tester.takeException(), isNull);
      await _candidate(tester, 'home_panel__${viewport.name}');
      await tester.tap(home);
      await tester.pumpAndSettle();
      expect([homes, otherActions], [1, 0]);
      expect(find.byType(DeveloperAccessScreen), findsOneWidget);
      for (final entry in const [
        ('dev_access_seeker', 'Seeker'),
        ('dev_access_guardian', 'Guardian'),
        ('dev_access_signup', 'Onboarding'),
      ]) {
        final action = find.byKey(ValueKey(entry.$1));
        expect(
          find.descendant(of: action, matching: find.text(entry.$2)),
          findsOneWidget,
        );
        expect(action.hitTestable(), findsOneWidget);
      }
      expect(find.text('Exit onboarding'), findsNothing);
      expect(tester.takeException(), isNull);
      await _candidate(tester, 'developer_access__${viewport.name}');
      // Shared Home navigation must not reintroduce normal onboarding chrome.
      // A different home argument alone does not replace a retained Navigator.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await _mount(
        tester,
        const DevSignUpProcessScreen(),
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
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
