// Real-font review candidates; no approved baseline is replaced.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/seeker_profile.dart';
import 'package:zyra/screens/subscription/profile_unlock_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_unlock_service.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

const _capture = bool.fromEnvironment('ZYRA_COMPATIBILITY_CAPTURE_CANDIDATES');
const _root = ValueKey('compatibility-demo-visual-root');
const _directory = 'test/visual/candidates/compatibility_plus_demo_2026_09_28';
const _profile = SeekerProfile(
  id: 'dev-compatibility-demo-visual-amira',
  firstName: 'Amira',
  surnameLine: 'Example',
  age: 29,
  city: 'London',
  photos: [],
  gender: 'female',
);

Future<ByteData> _font(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());

void main() {
  final captures = <String>[];
  setUpAll(() async {
    final reading = FontLoader('PoppinsAudit')
      ..addFont(_font('assets/fonts/Poppins-ExtraLight.ttf'))
      ..addFont(_font('assets/fonts/Poppins-Light.ttf'))
      ..addFont(_font('assets/fonts/Poppins-Regular.ttf'))
      ..addFont(_font('assets/fonts/Poppins-Medium.ttf'))
      ..addFont(_font('assets/fonts/Poppins-SemiBold.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), icons.load()]);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsAudit';
  });
  setUp(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraUnlockService.clearForSignOut();
    ZyraColors.restoreAppPalette(null);
  });
  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraUnlockService.clearForSignOut();
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    if (_capture) {
      final sources = [
        'lib/screens/subscription/profile_unlock_screen.dart',
        'lib/dev/zyra_compatibility_demo.dart',
        'lib/services/zyra_unlock_service.dart',
        'test/visual/compatibility_plus_demo_visual_test.dart',
      ];
      File('$_directory/manifest.json').writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert({
          'status': 'REVIEW_CANDIDATE_NOT_FOUNDER_ACCEPTED',
          'approved_baselines_changed': false,
          'demo_only': true,
          'fonts': 'bundled Poppins and MaterialIcons',
          'captures': captures,
          'source_sha256': {for (final path in sources) path: sha256.convert(File(path).readAsBytesSync()).toString()},
          'png_sha256': {for (final path in captures) path: sha256.convert(File(path).readAsBytesSync()).toString()},
        })}\n',
      );
    }
  });

  for (final variant in const [
    (name: 'standard', size: Size(390, 844), scale: 1.0),
    (name: 'small-text-130', size: Size(320, 568), scale: 1.3),
  ]) {
    testWidgets('${variant.name} Plus control and result remain readable', (
      tester,
    ) async {
      tester.view.physicalSize = variant.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark().copyWith(
            textTheme: ZyraText.textTheme(ThemeData.dark().textTheme),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(variant.scale),
              disableAnimations: true,
            ),
            child: RepaintBoundary(key: _root, child: child!),
          ),
          home: const ProfileUnlockScreen(profile: _profile),
        ),
      );
      await tester.pumpAndSettle();
      final action = find.byKey(
        const ValueKey('compatibility-unlock-Unlock Compatibility'),
      );
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      expect(action.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (_capture) {
        expect(autoUpdateGoldenFiles, isTrue);
        final path = '$_directory/${variant.name}-button.png';
        await expectLater(
          find.byKey(_root),
          matchesGoldenFile(path.substring(12)),
        );
        captures.add(path);
      }
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('compatibility-demo-result')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('compatibility-demo-notice')),
        findsOneWidget,
      );
      expect(ZyraUnlockService.isTierAvailable(UnlockTier.plus), isFalse);
      for (final target in const [
        'compatibility-demo-notice',
        'compatibility-demo-guardian',
      ]) {
        await tester.ensureVisible(find.byKey(ValueKey(target)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (_capture) {
          final suffix = target.endsWith('notice') ? 'result' : 'guardian';
          final path = '$_directory/${variant.name}-$suffix.png';
          await expectLater(
            find.byKey(_root),
            matchesGoldenFile(path.substring(12)),
          );
          captures.add(path);
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
