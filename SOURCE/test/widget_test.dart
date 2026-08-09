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
// They guard DR-ZYRA-094, which is worth guarding — genderGradient() was
// added precisely because Guardian screens had hardcoded the male
// gradient regardless of the signed-in Guardian's actual gender, and
// brandGradientFemale was defined but referenced nowhere. That was a
// silent bug for weeks. These fail loudly if it recurs.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zyra/theme/zyra_colors.dart';

void main() {
  group('ZyraColors.genderGradient (DR-ZYRA-094)', () {
    test('female Seekers get the Rose Pink gradient', () {
      expect(ZyraColors.genderGradient('female'), ZyraColors.brandGradientFemale);
    });

    test('male Seekers get the Royal Blue gradient', () {
      expect(ZyraColors.genderGradient('male'), ZyraColors.brandGradientMale);
    });

    test('unknown gender falls back to the neutral brand gradient', () {
      // Reachable in real use: an account part-way through onboarding has
      // no gender yet. Must not throw, and must not pick a side.
      expect(ZyraColors.genderGradient(null), ZyraColors.brandGradient);
      expect(ZyraColors.genderGradient(''), ZyraColors.brandGradient);
      expect(ZyraColors.genderGradient('Female'), ZyraColors.brandGradient);
    });

    test('every gradient ends in Luxury Dark Purple', () {
      // The whole point of DR-ZYRA-094: each theme fades from its own
      // accent into one shared colour. If a future edit breaks this,
      // sheets and the advert screen stop being continuous with the
      // screens behind them — the exact bug this decision prevents.
      for (final g in [
        ZyraColors.brandGradient,
        ZyraColors.brandGradientMale,
        ZyraColors.brandGradientFemale,
      ]) {
        expect(g.colors.last, ZyraColors.luxuryDarkPurple);
        expect(g.begin, Alignment.topCenter);
        expect(g.end, Alignment.bottomCenter);
      }
    });
  });
}
