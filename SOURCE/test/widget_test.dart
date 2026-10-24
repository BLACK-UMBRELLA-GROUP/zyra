// REPLACED 2026-08-01.
//
// This file was still the stock `flutter create` counter template. It
// pumped `const MyApp()` — a class this project has never had, the root
// widget being `ZyraApp` — and asserted a counter incrementing from 0 to
// 1, a screen that has never existed either.
//
// It therefore did not compile, which made `flutter analyze` exit
// non-zero, which meant `flutter analyze && ./run.sh` silently never
// reached ./run.sh. A broken test file was presenting as "the app won't
// start". Scaffolding debris with a real cost.
//
// What replaces it is deliberately NOT a widget test. Pumping ZyraApp
// starts the session router, which reads Supabase — no test harness for
// that exists yet, and a test that needs the network is a test that gets
// deleted the first time it goes red. These are pure assertions over the
// colour system instead: no async, no IO, deterministic.
//
// They guard the Founder's 2026-08-20 direction that ZYRA has one shared
// background theme. Gender remains account data, but no longer selects a
// blue or pink presentation layer. Founder direction 2026-08-24 changed the
// current shared default from ZYRA Purple to Midnight Plum.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

import 'package:zyra/theme/zyra_colors.dart';

void main() {
  group('ZyraColors unified background', () {
    setUp(() => ZyraColors.restoreAppPalette(null));
    test('every gender resolves to the same ZYRA gradient', () {
      for (final gender in ['female', 'male', null, '', 'Female']) {
        expect(ZyraColors.genderGradient(gender), ZyraColors.brandGradient);
      }
    });

    test('every onboarding variant resolves to the same ZYRA gradient', () {
      for (final variant in ZyraBackgroundVariant.values) {
        expect(ZyraColors.backgroundFor(variant), ZyraColors.brandGradient);
      }
    });

    test('the unified gradient uses the current Midnight Plum endpoints', () {
      final gradient = ZyraColors.brandGradient;
      expect(ZyraColors.currentDefaultPalette, ZyraDevPalette.midnightPlum);
      expect(gradient.colors.first, const Color(0xFF30203F));
      expect(gradient.colors.last, const Color(0xFF160E20));
      expect(gradient.begin, Alignment.topLeft);
      expect(gradient.end, Alignment.bottomRight);
    });

    test('persisted Midnight Plum receives the darker theme without reset', () {
      ZyraColors.restoreAppPalette('midnightPlum');
      expect(ZyraColors.brandGradient.colors, [
        ZyraColors.royalPurple,
        ZyraColors.luxuryDarkPurple,
      ]);
      // Unrelated member choices remain opt-in, not silently erased.
      ZyraColors.restoreAppPalette('deepEmerald');
      expect(ZyraColors.devPalette, ZyraDevPalette.deepEmerald);
      ZyraColors.restoreAppPalette(null);
    });

    test('every bottom sheet and dark popup shares the new plum surface', () {
      expect(ZyraColors.modalSheetSurface, const Color(0xFF241A2F));
      expect(ZyraColors.sheetSurface, ZyraColors.modalSheetSurface);
      expect(ZyraColors.waliSheetBg, ZyraColors.modalSheetSurface);
      expect(ZyraColors.sheetGradient.colors, [
        ZyraColors.modalSheetSurface,
        ZyraColors.modalSheetSurface,
      ]);
      expect(ZyraColors.toastSurface, ZyraColors.modalSheetSurface);
      expect(ZyraColors.menuSurface.r, ZyraColors.modalSheetSurface.r);
      expect(ZyraColors.modalSheetSurface.a, 1);
    });

    test('foreground, gold and action text retain readable dark contrast', () {
      double contrast(Color a, Color b) {
        final x = a.computeLuminance();
        final y = b.computeLuminance();
        return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
      }

      for (final canvas in [
        ...ZyraColors.brandGradient.colors,
        ZyraColors.modalSheetSurface,
      ]) {
        for (final ink in [
          ZyraColors.foreground,
          ZyraColors.foregroundBody,
          ZyraColors.foregroundSecondary,
          ZyraColors.journeyGold,
          ZyraColors.destructive,
        ]) {
          expect(
            contrast(Color.alphaBlend(ink, canvas), canvas),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
      expect(
        contrast(ZyraColors.onAction, ZyraColors.actionFill),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('native launch and adaptive icon use the dark canvas endpoint', () {
      final config = File('pubspec.yaml').readAsStringSync();
      expect(config, contains('adaptive_icon_background: "#160E20"'));
      expect(config, contains('flutter_native_splash:\n  color: "#160E20"'));
      expect(config, contains('android_12:\n    color: "#160E20"'));
    });
  });
}
