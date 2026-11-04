// Candidate renders only: this suite never reads or replaces approved pixels.
// Capture using --update-goldens and ZYRA_DEV_ACCESS_CAPTURE_CANDIDATES=true.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/widgets/zyra_account_session_host.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_internal_preview_client.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

const _capture = bool.fromEnvironment('ZYRA_DEV_ACCESS_CAPTURE_CANDIDATES');
const _root = ValueKey('developer-access-visual-root');
const _candidateName = 'developer_access_three_actions_restored_2026_09_28';
const _directory = 'test/visual/candidates/$_candidateName';
const _variants = <({String name, Size size, double scale})>[
  (name: 'small', size: Size(320, 568), scale: 1),
  (name: 'standard', size: Size(390, 844), scale: 1),
  (name: 'large', size: Size(430, 932), scale: 1),
  (name: 'standard__text-130', size: Size(390, 844), scale: 1.3),
];

Future<ByteData> _font(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());

void main() {
  final captured = <Map<String, Object>>[];

  setUpAll(() async {
    final reading = FontLoader('PoppinsAudit')
      ..addFont(_font('assets/fonts/Poppins-ExtraLight.ttf'))
      ..addFont(_font('assets/fonts/Poppins-Light.ttf'))
      ..addFont(_font('assets/fonts/Poppins-Regular.ttf'))
      ..addFont(_font('assets/fonts/Poppins-Medium.ttf'))
      ..addFont(_font('assets/fonts/Poppins-SemiBold.ttf'))
      ..addFont(_font('assets/fonts/Poppins-Bold.ttf'));
    final wordmark = FontLoader('SyneAudit')
      ..addFont(_font('assets/fonts/Syne-SemiBold.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), wordmark.load(), icons.load()]);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsAudit';
    ZyraText.testWordmarkFontFamily = 'SyneAudit';
  });

  setUp(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDeveloperAccess.setMainAppFounderPreviewForTesting(true);
    ZyraInternalPreviewClient.beginPreview();
    ZyraColors.restoreAppPalette(null);
    ZyraColors.restoreAppSurfaceStyle(null);
  });

  tearDown(() {
    ZyraInternalPreviewClient.finishSignOut();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });

  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
    if (_capture && captured.isNotEmpty) {
      final sourcePaths = [
        'lib/screens/dev/developer_access_screen.dart',
        'lib/dev/zyra_dev_signup.dart',
        'lib/dev/dev_signup_process.dart',
        'lib/dev/zyra_global_dev_overlay.dart',
        'test/visual/zyra_developer_access_visual_test.dart',
      ];
      final manifest = <String, Object>{
        'status': 'REVIEW_CANDIDATE_NOT_FOUNDER_ACCEPTED',
        'approved': false,
        'approved_baselines_changed': false,
        'capture_command':
            'flutter test --no-pub --update-goldens '
            '--dart-define=ZYRA_DEV_ACCESS_CAPTURE_CANDIDATES=true '
            'test/visual/zyra_developer_access_visual_test.dart',
        'captured_at_utc': DateTime.now().toUtc().toIso8601String(),
        'palette': 'midnightPlum',
        'surface': 'glassSignals',
        'reading_font': 'PoppinsAudit (bundled Poppins)',
        'device_pixel_ratio': 1,
        'fixture_data_only': true,
        'active_preview_latch': true,
        'includes_global_developer_controls': true,
        'landing_actions': ['Seeker', 'Guardian', 'Sign up'],
        'neutral_signup_actions': 1,
        'restored_landing_role_preview_doors': true,
        'source_sha256': {
          for (final path in sourcePaths)
            path: sha256.convert(File(path).readAsBytesSync()).toString(),
        },
        'captures': captured,
      };
      File('$_directory/manifest.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
      );
    }
  });

  for (final variant in _variants) {
    testWidgets('${variant.name} landing renders without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = variant.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
            colorScheme: ColorScheme.fromSeed(
              seedColor: ZyraColors.actionFill,
              brightness: Brightness.dark,
            ),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(variant.scale),
              disableAnimations: true,
            ),
            child: RepaintBoundary(
              key: _root,
              child: ZyraAccountSessionHost(
                navigatorKey: navigatorKey,
                authStateChangesOverride: const Stream.empty(),
                child: child!,
              ),
            ),
          ),
          home: const WelcomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == 'DeveloperAccessScreen',
          ),
          matching: find.text('Developer Access'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('main_app_founder_preview_safety_banner')),
        findsNothing,
      );
      for (final action in const [
        ('dev_access_seeker', 'Seeker'),
        ('dev_access_guardian', 'Guardian'),
        ('dev_access_signup', 'Sign up'),
      ]) {
        final pill = find.byKey(ValueKey(action.$1));
        expect(pill, findsOneWidget);
        expect(
          find.descendant(of: pill, matching: find.text(action.$2)),
          findsOneWidget,
        );
        await tester.ensureVisible(pill);
        await tester.pumpAndSettle();
        expect(pill.hitTestable(), findsOneWidget);
        expect(tester.getSize(pill).height, greaterThanOrEqualTo(80));
        expect(tester.getCenter(pill).dx, closeTo(variant.size.width / 2, 1));
      }
      expect(tester.takeException(), isNull);

      if (_capture) {
        expect(
          autoUpdateGoldenFiles,
          isTrue,
          reason: 'Candidate capture requires --update-goldens.',
        );
        await expectLater(
          find.byKey(_root),
          matchesGoldenFile('candidates/$_candidateName/${variant.name}.png'),
        );
        final bytes = File('$_directory/${variant.name}.png').readAsBytesSync();
        captured.add({
          'id': variant.name,
          'approved': false,
          'path': '${variant.name}.png',
          'width': variant.size.width.toInt(),
          'height': variant.size.height.toInt(),
          'text_scale': variant.scale,
          'sha256': sha256.convert(bytes).toString(),
          'bytes': bytes.length,
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
