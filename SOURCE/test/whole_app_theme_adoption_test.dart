import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const owner = 'theme-test-member';

  Future<void> restore(Map<String, Object> stored) async {
    SharedPreferences.setMockInitialValues({
      'zyra.cached_account_owner': owner,
      ...stored,
    });
    await ZyraLocalPrefs.init();
    await ZyraLocalPrefs.bindAccount(owner);
  }

  tearDown(() => ZyraColors.restoreAppPalette(null));

  for (final oldPalette in [
    null,
    'zyraPurple',
    'royalBlue',
    'deepEmerald',
    'midnightPlum',
    'paperWhite',
    'unknown',
  ]) {
    test('startup adopts Hulu across the app from saved $oldPalette', () async {
      await restore({
        'zyra.app_palette': ?oldPalette,
        'zyra.cached_first_name': 'Returning member',
        'zyra.app_font': 'manrope',
        'zyra.haptic_level': 'medium',
        'zyra.app_lock_enabled': true,
      });
      ZyraColors.restoreCurrentAppPalette();
      expect(ZyraColors.brandGradient.colors, const [
        Color(0xFF30203F),
        Color(0xFF160E20),
      ]);
      for (final gender in ['male', 'female', null]) {
        expect(ZyraColors.genderGradient(gender), ZyraColors.brandGradient);
      }
      expect(ZyraLocalPrefs.cachedAppPaletteName, 'midnightPlum');
      expect(
        ZyraLocalPrefs.cachedAppPaletteRevision,
        ZyraColors.currentPaletteRevision,
      );
      expect(ZyraLocalPrefs.cachedFirstName, 'Returning member');
      expect(ZyraLocalPrefs.cachedAppFontName, 'manrope');
      expect(ZyraLocalPrefs.cachedHapticLevelName, 'medium');
      expect(ZyraLocalPrefs.appLockEnabled, isTrue);
      // Cold-start binding, not just an in-memory colour assertion.
      await ZyraLocalPrefs.init();
      await ZyraLocalPrefs.bindAccount(owner);
      ZyraColors.restoreCurrentAppPalette();
      expect(ZyraColors.devPalette, ZyraColors.currentDefaultPalette);
      expect(ZyraLocalPrefs.appLockEnabled, isTrue);
    });
  }

  test('later explicit personalisation is not reset on every launch', () async {
    await restore({});
    ZyraColors.restoreCurrentAppPalette();
    ZyraColors.selectAppPalette(ZyraDevPalette.deepEmerald);
    await ZyraLocalPrefs.init();
    await ZyraLocalPrefs.bindAccount(owner);
    ZyraColors.restoreCurrentAppPalette();
    expect(ZyraColors.devPalette, ZyraDevPalette.deepEmerald);
  });

  test(
    'Midnight blue is optional and leaves default and surfaces unchanged',
    () {
      expect(ZyraColors.currentDefaultPalette, ZyraDevPalette.midnightPlum);
      expect(ZyraColors.currentPaletteRevision, 'dark-hulu-app-2026-09-27-v1');
      expect(ZyraDevPalette.midnightBlue.isLight, isFalse);
      expect(ZyraDevPalette.midnightBlue.gradient.begin, Alignment.topRight);
      expect(ZyraDevPalette.midnightBlue.gradient.end, Alignment.bottomLeft);
      expect(ZyraDevPalette.midnightBlue.gradient.colors, const [
        Color(0xFF183F83),
        Color(0xFF07132B),
      ]);
      ZyraColors.restoreAppPalette('midnightBlue');
      expect(ZyraColors.brandGradient, ZyraDevPalette.midnightBlue.gradient);
      expect(ZyraColors.journeyGold, const Color(0xFFE8C98A));
      expect(ZyraColors.modalSheetSurface, ZyraColors.darkPlumSurface);
      expect(ZyraColors.toastSurface, ZyraColors.darkPlumSurface);
      expect(ZyraColors.currentDefaultPalette, ZyraDevPalette.midnightPlum);
    },
  );

  test(
    'explicit Midnight blue survives a same-owner cold restoration',
    () async {
      await restore({
        'zyra.app_palette': 'deepEmerald',
        'zyra.app_palette_revision': ZyraColors.currentPaletteRevision,
        'zyra.cached_first_name': 'Returning member',
        'zyra.app_font': 'manrope',
        'zyra.haptic_level': 'medium',
        'zyra.app_lock_enabled': true,
      });
      ZyraColors.selectAppPalette(ZyraDevPalette.midnightBlue);
      await ZyraLocalPrefs.bindAccount(owner);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('zyra.app_palette'), 'midnightBlue');
      await ZyraLocalPrefs.init();
      await ZyraLocalPrefs.bindAccount(owner);
      ZyraColors.restoreCurrentAppPalette();
      expect(ZyraColors.devPalette, ZyraDevPalette.midnightBlue);
      expect(
        ZyraLocalPrefs.cachedAppPaletteRevision,
        ZyraColors.currentPaletteRevision,
      );
      expect(ZyraLocalPrefs.cachedFirstName, 'Returning member');
      expect(ZyraLocalPrefs.cachedAppFontName, 'manrope');
      expect(ZyraLocalPrefs.cachedHapticLevelName, 'medium');
      expect(ZyraLocalPrefs.appLockEnabled, isTrue);
    },
  );

  test('Midnight blue preference cannot follow a different account', () async {
    await restore({});
    ZyraColors.selectAppPalette(ZyraDevPalette.midnightBlue);
    await ZyraLocalPrefs.bindAccount(owner);
    await ZyraLocalPrefs.bindAccount('another-theme-member');
    expect(ZyraLocalPrefs.cachedAppPaletteName, isNull);
    expect(ZyraLocalPrefs.cachedAppPaletteRevision, isNull);
    await ZyraLocalPrefs.init();
    await ZyraLocalPrefs.bindAccount('another-theme-member');
    ZyraColors.restoreCurrentAppPalette();
    expect(ZyraColors.devPalette, ZyraDevPalette.midnightPlum);
    expect(ZyraLocalPrefs.cachedAppPaletteName, 'midnightPlum');
    expect(ZyraLocalPrefs.cachedAppPaletteName, isNot('midnightBlue'));
  });

  test('palette revision cannot leak into another account', () async {
    await restore({'zyra.app_palette': 'zyraPurple'});
    ZyraColors.restoreCurrentAppPalette();
    await ZyraLocalPrefs.bindAccount('another-theme-member');
    expect(ZyraLocalPrefs.cachedAppPaletteRevision, isNull);
    expect(ZyraLocalPrefs.cachedAppPaletteName, isNull);
    await ZyraLocalPrefs.init();
    await ZyraLocalPrefs.bindAccount('another-theme-member');
    expect(ZyraLocalPrefs.cachedAppPaletteRevision, isNull);
  });

  test('real app startup uses revision-aware restoration', () {
    final main = File('lib/main.dart').readAsStringSync();
    expect(main, contains('ZyraColors.restoreCurrentAppPalette();'));
    expect(
      main,
      isNot(
        contains(
          'ZyraColors.restoreAppPalette(ZyraLocalPrefs.cachedAppPaletteName)',
        ),
      ),
    );
    expect(main, contains('gradient: ZyraColors.genderGradient'));
  });
}
