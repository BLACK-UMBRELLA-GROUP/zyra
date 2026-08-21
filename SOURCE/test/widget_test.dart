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
// They guard the Founder's 2026-08-20 direction that ZYRA has one purple
// background theme. Gender remains account data, but no longer selects a
// blue or pink presentation layer.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zyra/theme/zyra_colors.dart';

void main() {
  group('ZyraColors unified purple background', () {
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

    test('the unified gradient uses the approved purple endpoints', () {
      final gradient = ZyraColors.brandGradient;
      expect(gradient.colors.first, ZyraColors.royalPurple);
      expect(gradient.colors.last, ZyraColors.luxuryDarkPurple);
      expect(gradient.begin, Alignment.topCenter);
      expect(gradient.end, Alignment.bottomCenter);
    });
  });
}
