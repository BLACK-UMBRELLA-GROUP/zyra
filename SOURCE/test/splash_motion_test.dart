// LOCK 14 V5: APP_COLOURS/RECORD/APP_COLOURS_SPEC_CURRENT_VERSION_V5.md;
// masters APP_COLOURS/MASTERS/c11_app_icon_1024.png and c12_splash.png.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/splash_screen.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_splash_artwork.dart';
import 'package:zyra/widgets/zyra_splash_motion.dart';

Future<void> _mountSplash(
  WidgetTester tester, {
  VoidCallback? onFinished,
  ZyraSplashMotion? motion,
  bool? reducedMotion,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: child!,
      ),
      home: SplashScreen(
        key: const ValueKey('real-splash'),
        motion: motion,
        onFinished: onFinished,
      ),
    ),
  );
}

ZyraSplashArtworkFrame _artwork(WidgetTester tester) =>
    tester.widget<ZyraSplashArtworkFrame>(find.byType(ZyraSplashArtworkFrame));

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  test('production and preview share 2.4s motion and 0.65s hold', () {
    expect(zyraSplashMotionMilliseconds, 2400);
    expect(zyraSplashFinishedHoldMilliseconds, 650);
    expect(zyraSplashTotalDuration, const Duration(milliseconds: 3050));
    expect(zyraSplashMotionFraction, 48 / 61);
  });

  test('Bloom + Draw stages bloom before the centred line', () {
    final early = ZyraSplashMotionFrame.at(
      motion: ZyraSplashMotion.bloomDraw,
      progress: 0.30,
    );
    expect(early.bloomOpacity, greaterThan(0));
    expect(early.lineProgress, 0);

    final connected = ZyraSplashMotionFrame.at(
      motion: ZyraSplashMotion.bloomDraw,
      progress: 0.72,
    );
    expect(connected.bloomOpacity, greaterThan(0));
    expect(connected.lineProgress, greaterThan(0));
    expect(connected.lineOpacity, greaterThan(0));

    final settled = ZyraSplashMotionFrame.at(
      motion: ZyraSplashMotion.bloomDraw,
      progress: 1,
    );
    expect(settled.bloomOpacity, 0);
    expect(settled.lineProgress, 1);
    expect(settled.lineOpacity, 1);
  });

  testWidgets('default production splash is Quiet Horizon with gold ZYRA', (
    tester,
  ) async {
    await _mountSplash(tester);
    expect(zyraPrimarySplashDirection, ZyraSplashDirection.dawnHorizon);
    expect(_artwork(tester).direction, zyraPrimarySplashDirection);
    expect(_artwork(tester).tagline, 'Connecting Through Trust');
    expect(
      find.byKey(const ValueKey('splash_study_dawnHorizon')),
      findsOneWidget,
    );
    expect(find.byType(ZyraSplashBloom), findsNothing);
    expect(find.byType(ZyraSplashDrawRule), findsNothing);
    expect(find.byKey(const ValueKey('splash_motion_bloomDraw')), findsNothing);
    expect(find.text('ZYRA'), findsOneWidget);
    expect(find.text('Connecting Through Trust'), findsOneWidget);
    expect(find.text('Connecting with trust'), findsNothing);
    final wordmark = tester.widget<Text>(
      find.byKey(const ValueKey('splash_study_wordmark')),
    );
    expect(wordmark.style!.color, const Color(0xFFA9792E));
    expect(find.text('Z'), findsNothing);
    expect(find.text('Y'), findsNothing);
    expect(find.text('R'), findsNothing);
    expect(find.text('A'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quiet Horizon arrives at 2.4s and finishes after 3.05s', (
    tester,
  ) async {
    var completions = 0;
    await _mountSplash(tester, onFinished: () => completions++);
    expect(_artwork(tester).progress, 0);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(_artwork(tester).progress, closeTo(.5, .001));
    expect(completions, 0);
    await tester.pump(const Duration(milliseconds: 1201));
    expect(_artwork(tester).progress, 1);
    expect(completions, 0);
    await tester.pump(const Duration(milliseconds: 648));
    expect(_artwork(tester).progress, 1);
    expect(completions, 0);
    // One millisecond beyond the lifecycle boundary avoids timer rounding.
    await tester.pump(const Duration(milliseconds: 2));
    expect(_artwork(tester).progress, 1);
    expect(completions, 1);
    await tester.pump(const Duration(seconds: 5));
    expect(completions, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rebuilding the splash never resets or repeats completion', (
    tester,
  ) async {
    var completions = 0;
    void finished() => completions++;
    await _mountSplash(tester, onFinished: finished);
    await tester.pump(const Duration(milliseconds: 1500));
    final before = _artwork(tester).progress;
    await _mountSplash(tester, onFinished: finished);
    expect(_artwork(tester).progress, closeTo(before, .001));
    await tester.pump(const Duration(milliseconds: 1551));
    expect(completions, 1);
    await _mountSplash(tester, onFinished: finished);
    expect(_artwork(tester).progress, 1);
    await tester.pump(const Duration(seconds: 6));
    expect(completions, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing before completion cancels the pending callback', (
    tester,
  ) async {
    var completions = 0;
    await _mountSplash(tester, onFinished: () => completions++);
    await tester.pump(const Duration(milliseconds: 3000));
    expect(_artwork(tester).progress, 1);
    expect(completions, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
    expect(completions, 0);
    expect(find.byType(ZyraSplashArtworkFrame), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reduced motion shows completed artwork but preserves 3.05s lifecycle',
    (tester) async {
      var completions = 0;
      await _mountSplash(
        tester,
        reducedMotion: true,
        onFinished: () => completions++,
      );
      expect(_artwork(tester).direction, ZyraSplashDirection.dawnHorizon);
      expect(_artwork(tester).progress, 1);
      expect(completions, 0);
      await tester.pump(const Duration(milliseconds: 2400));
      expect(_artwork(tester).progress, 1);
      expect(completions, 0);
      await tester.pump(const Duration(milliseconds: 651));
      expect(_artwork(tester).progress, 1);
      expect(completions, 1);
      await tester.pump(const Duration(seconds: 5));
      expect(completions, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'platform reduced motion never compresses the production lifecycle to 220ms',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      var completions = 0;
      // Leave the MediaQuery override unset so the platform accessibility
      // feature reaches both the artwork and Flutter's animation controller.
      await _mountSplash(tester, onFinished: () => completions++);
      expect(_artwork(tester).direction, ZyraSplashDirection.dawnHorizon);
      expect(_artwork(tester).progress, 1);
      expect(completions, 0);
      await tester.pump(const Duration(milliseconds: 220));
      expect(_artwork(tester).progress, 1);
      expect(completions, 0);
      await tester.pump(const Duration(milliseconds: 2179));
      expect(completions, 0);
      await tester.pump(const Duration(milliseconds: 650));
      expect(completions, 0);
      // Sample just beyond the deadline to avoid floating-point equality
      // at exactly 3.05s, as in the normal-motion lifecycle regression.
      await tester.pump(const Duration(milliseconds: 2));
      expect(_artwork(tester).progress, 1);
      expect(completions, 1);
      await tester.pump(const Duration(seconds: 5));
      expect(completions, 1);
      expect(tester.takeException(), isNull);
    },
  );

  for (final motion in ZyraSplashMotion.values) {
    testWidgets('explicit ${motion.name} keeps the shared 3.05s lifecycle', (
      tester,
    ) async {
      var completions = 0;
      await _mountSplash(
        tester,
        motion: motion,
        onFinished: () => completions++,
      );
      expect(find.byType(ZyraSplashArtworkFrame), findsNothing);
      expect(
        find.byKey(ValueKey('splash_motion_${motion.name}')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('splash_soft_bloom')), findsOneWidget);
      expect(find.byKey(const ValueKey('splash_centre_draw')), findsOneWidget);
      for (final letter in ['Z', 'Y', 'R', 'A']) {
        expect(find.text(letter), findsOneWidget);
      }
      expect(find.text('Connecting Through Trust'), findsOneWidget);
      expect(find.text('ZYRA'), findsNothing);
      await tester.pump(const Duration(milliseconds: 2401));
      final bloom = tester.widget<ZyraSplashBloom>(
        find.byType(ZyraSplashBloom),
      );
      final rule = tester.widget<ZyraSplashDrawRule>(
        find.byType(ZyraSplashDrawRule),
      );
      expect(bloom.motion, motion);
      expect(bloom.progress, 1);
      expect(rule.motion, motion);
      expect(rule.progress, 1);
      expect(completions, 0);
      if (motion == ZyraSplashMotion.bloomDraw) {
        final lineOpacity = find
            .ancestor(
              of: find.byKey(const ValueKey('splash_centre_draw')),
              matching: find.byType(Opacity),
            )
            .first;
        expect(tester.widget<Opacity>(lineOpacity).opacity, 1);
      }
      await tester.pump(const Duration(milliseconds: 648));
      expect(completions, 0);
      await tester.pump(const Duration(milliseconds: 2));
      expect(completions, 1);
      await tester.pump(const Duration(seconds: 5));
      expect(completions, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
