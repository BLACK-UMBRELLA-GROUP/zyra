// LOCK 14 V5: APP_COLOURS/RECORD/APP_COLOURS_SPEC_CURRENT_VERSION_V5.md;
// masters APP_COLOURS/MASTERS/c11_app_icon_1024.png and c12_splash.png.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/screens/home/home_shell.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    ZyraColors.restoreAppPalette(null);
    ZyraText.restoreAppFont(null);
    ZyraInteractionStyle.restoreHapticLevel(null);
    ZyraColors.restoreAppSurfaceStyle(null);
  });

  tearDown(() {
    ZyraColors.restoreAppPalette(null);
    ZyraText.restoreAppFont(null);
    ZyraInteractionStyle.restoreHapticLevel(null);
    ZyraColors.restoreAppSurfaceStyle(null);
  });

  test('normal Seeker and Guardian shells default to Dashboard', () {
    expect(const HomeShell().initialTab, 2);

    final router = File(
      'lib/services/zyra_session_router.dart',
    ).readAsStringSync();
    expect(
      router,
      contains("if (role == 'wali') return const WaliHomeShell();"),
    );
    expect(router, contains('initialTab: 2'));
    expect(router, isNot(contains('onboarding?.complete == true ? 0 : 2')));

    final waliShell = File(
      'lib/screens/wali/wali_home_shell.dart',
    ).readAsStringSync();
    expect(waliShell, contains('WaliPage _page = WaliPage.dashboard;'));
    expect(waliShell.indexOf('WaliDashboardScreen('), greaterThanOrEqualTo(0));
  });

  test('auth and missing-profile exceptions still bypass the home shell', () {
    final router = File(
      'lib/services/zyra_session_router.dart',
    ).readAsStringSync();
    expect(
      RegExp(r'return const RoleSelectionScreen\(\)').allMatches(router).length,
      greaterThanOrEqualTo(2),
    );
    expect(router, contains('return ZyraFounderLaunchScreen('));
  });

  test('Glass Signals ignores and clears a retired stored surface', () async {
    await ZyraLocalPrefs.setCachedAppSurfaceStyleName('classicGlass');
    expect(ZyraLocalPrefs.cachedAppSurfaceStyleName, 'classicGlass');

    ZyraColors.restoreAppSurfaceStyle(ZyraLocalPrefs.cachedAppSurfaceStyleName);
    await Future<void>.delayed(Duration.zero);

    expect(ZyraColors.appSurfaceStyle, ZyraAppSurfaceStyle.glassSignals);
    expect(ZyraLocalPrefs.cachedAppSurfaceStyleName, isNull);
  });

  test(
    'member Personalisation ignores retired colour choice and keeps haptics',
    () async {
      ZyraColors.selectAppPalette(ZyraDevPalette.deepEmerald);
      await ZyraLocalPrefs.setCachedAppFontName('manrope');
      ZyraInteractionStyle.selectPersonalisationHapticLevel(
        ZyraHapticLevel.medium,
      );
      await Future<void>.delayed(Duration.zero);

      expect(ZyraLocalPrefs.cachedAppPaletteName, isNull);
      expect(ZyraLocalPrefs.cachedAppFontName, 'manrope');
      expect(ZyraLocalPrefs.cachedHapticLevelName, 'medium');

      ZyraColors.restoreAppPalette(ZyraLocalPrefs.cachedAppPaletteName);
      ZyraText.restoreAppFont(ZyraLocalPrefs.cachedAppFontName);
      ZyraInteractionStyle.restoreHapticLevel(
        ZyraLocalPrefs.cachedHapticLevelName,
      );
      expect(ZyraColors.devPalette, ZyraDevPalette.ivory);
      expect(ZyraText.appFont, ZyraAppFont.poppins);
      expect(ZyraInteractionStyle.hapticLevel, ZyraHapticLevel.medium);

      ZyraColors.restoreAppPalette('paperWhite');
      ZyraText.restoreAppFont('future-font');
      ZyraInteractionStyle.restoreHapticLevel('future-haptic');
      expect(ZyraColors.devPalette, ZyraColors.currentDefaultPalette);
      expect(ZyraText.appFont, ZyraText.currentDefaultFont);
      expect(
        ZyraInteractionStyle.hapticLevel,
        ZyraInteractionStyle.currentDefaultHapticLevel,
      );

      await ZyraLocalPrefs.setCachedAppFontName(null);
      expect(ZyraLocalPrefs.cachedAppFontName, isNull);

      await ZyraLocalPrefs.clear();
      expect(ZyraLocalPrefs.cachedAppPaletteName, isNull);
      expect(ZyraLocalPrefs.cachedAppFontName, isNull);
      expect(ZyraLocalPrefs.cachedHapticLevelName, isNull);
    },
  );
}
