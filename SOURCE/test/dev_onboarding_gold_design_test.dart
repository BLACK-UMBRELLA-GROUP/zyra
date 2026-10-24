import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/dev/dev_onboarding_directions.dart';
import 'package:zyra/dev/dev_onboarding_gold_design.dart';
import 'package:zyra/dev/dev_onboarding_lab.dart';
import 'package:zyra/dev/dev_onboarding_welcome_motion.dart';
import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

void _noOp() {}

Future<int> _signature(CustomPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final image = await recorder.endRecording().toImage(
    size.width.round(),
    size.height.round(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();
  var hash = 0;
  for (final byte in bytes) {
    hash = (hash * 31 + byte) & 0x7fffffff;
  }
  image.dispose();
  return hash;
}

Future<int> _visibleGoldPixels(CustomPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final image = await recorder.endRecording().toImage(
    size.width.round(),
    size.height.round(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();
  var count = 0;
  for (var index = 3; index < bytes.length; index += 4) {
    if (bytes[index] >= 32) count++;
  }
  image.dispose();
  return count;
}

Future<int> _goldPixelsInsideReadingInset(
  CustomPainter painter,
  Size size,
  int inset,
) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final image = await recorder.endRecording().toImage(
    size.width.round(),
    size.height.round(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();
  final width = size.width.round();
  final height = size.height.round();
  var count = 0;
  for (var y = 0; y < height; y++) {
    for (var x = inset; x < width - inset; x++) {
      if (bytes[(y * width + x) * 4 + 3] != 0) count++;
    }
  }
  image.dispose();
  return count;
}

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraAccountState.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraDevWelcomePulseIntensity.resetForTesting();
    ZyraDevWelcomePulseDesign.resetForTesting();
    ZyraDevOnboardingGoldDesign.resetForTesting();
    ZyraDevOnboardingGoldMotion.resetForTesting();
  });

  tearDown(() {
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraDevWelcomePulseDesign.resetForTesting();
    ZyraDevOnboardingGoldDesign.resetForTesting();
    ZyraDevOnboardingGoldMotion.resetForTesting();
    ZyraDevWelcomePulseIntensity.resetForTesting();
    ZyraText.useTestFontStubs = false;
  });

  test(
    'five pulse and eleven dust styles are distinct, guarded and session-local',
    () {
      expect(ZyraWelcomePulseDesign.values, hasLength(5));
      expect(ZyraOnboardingGoldDesign.values, hasLength(11));
      expect(
        ZyraOnboardingGoldDesign.values.map((value) => value.label),
        orderedEquals(const [
          'Gold dust',
          'Fine dust',
          'Sparse dust',
          'Bright dust',
          'High drift',
          'Low drift',
          'Edge dust',
          'Diagonal edge',
          'Twin clouds',
          'Dust halo',
          'Gentle sweep',
        ]),
      );
      expect(
        ZyraWelcomePulseDesign.values.map((value) => value.label).toSet(),
        hasLength(5),
      );
      expect(
        ZyraOnboardingGoldDesign.values.map((value) => value.label).toSet(),
        hasLength(11),
      );
      expect(ZyraDevWelcomePulseIntensity.level, 3);
      expect(
        ZyraDevWelcomePulseDesign.current,
        ZyraWelcomePulseDesign.softBloom,
      );
      expect(
        ZyraDevOnboardingGoldDesign.current,
        ZyraOnboardingGoldDesign.diagonalDust,
      );
      expect(ZyraOnboardingGoldMotion.values, hasLength(2));
      expect(
        ZyraDevOnboardingGoldMotion.current,
        ZyraOnboardingGoldMotion.liveDrift,
      );

      expect(
        ZyraDevWelcomePulseDesign.select(ZyraWelcomePulseDesign.orbitRing),
        isTrue,
      );
      expect(
        ZyraDevOnboardingGoldDesign.select(ZyraOnboardingGoldDesign.highDrift),
        isTrue,
      );
      expect(
        ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.liveDrift),
        isTrue,
      );
      ZyraAccountState.resetForTesting();
      expect(
        ZyraDevWelcomePulseDesign.current,
        ZyraWelcomePulseDesign.softBloom,
      );
      expect(
        ZyraDevOnboardingGoldDesign.current,
        ZyraOnboardingGoldDesign.diagonalDust,
      );
      expect(
        ZyraDevOnboardingGoldMotion.current,
        ZyraOnboardingGoldMotion.liveDrift,
      );
      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      expect(
        ZyraDevWelcomePulseDesign.select(ZyraWelcomePulseDesign.twinHalo),
        isFalse,
      );
      expect(
        ZyraDevOnboardingGoldDesign.select(ZyraOnboardingGoldDesign.dustHalo),
        isFalse,
      );
      expect(
        ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.liveDrift),
        isFalse,
      );
    },
  );

  test(
    'each pulse and backdrop painter has a different rendered signature',
    () async {
      final pulseSignatures = <int>{};
      for (final design in ZyraWelcomePulseDesign.values) {
        pulseSignatures.add(
          await _signature(
            ZyraWelcomePulsePainter(design, .55),
            const Size(56, 56),
          ),
        );
      }
      expect(pulseSignatures, hasLength(5));

      final backdropSignatures = <int>{};
      for (final design in ZyraOnboardingGoldDesign.values) {
        backdropSignatures.add(
          await _signature(
            ZyraOnboardingGoldPainter(design),
            const Size(160, 240),
          ),
        );
      }
      expect(backdropSignatures, hasLength(11));

      final previewSignatures = <int>{};
      for (final design in ZyraOnboardingGoldDesign.values) {
        previewSignatures.add(
          await _signature(
            ZyraOnboardingGoldPainter(design, preview: true),
            const Size(56, 36),
          ),
        );
      }
      expect(previewSignatures, hasLength(11));
      expect(
        await _visibleGoldPixels(
          const ZyraOnboardingGoldPainter(ZyraOnboardingGoldDesign.goldDust),
          const Size(390, 844),
        ),
        greaterThan(100),
      );
    },
  );

  test(
    'Diagonal edge retains its full diagonal spread at phone and tablet sizes',
    () async {
      expect(
        await _visibleGoldPixels(
          const ZyraOnboardingGoldPainter(
            ZyraOnboardingGoldDesign.diagonalDust,
          ),
          const Size(390, 844),
        ),
        greaterThan(100),
      );
      for (final size in const [
        Size(320, 568),
        Size(390, 844),
        Size(430, 932),
        Size(1024, 1366),
      ]) {
        expect(
          await _goldPixelsInsideReadingInset(
            const ZyraOnboardingGoldPainter(
              ZyraOnboardingGoldDesign.diagonalDust,
            ),
            size,
            24,
          ),
          greaterThan(100),
          reason: 'Gold must not be collapsed into the side gutters at $size',
        );
      }
      for (final motion in ZyraOnboardingGoldMotion.values) {
        for (final value in const [.1, .5, .9]) {
          expect(
            await _goldPixelsInsideReadingInset(
              ZyraOnboardingGoldPainter(
                ZyraOnboardingGoldDesign.diagonalDust,
                motion: motion,
                motionValue: value,
              ),
              const Size(390, 844),
              24,
            ),
            greaterThan(0),
            reason: '$motion must retain the diagonal spread while animating',
          );
        }
      }
    },
  );

  test('entry and live animation paint different moments', () async {
    final entryEarly = await _signature(
      const ZyraOnboardingGoldPainter(
        ZyraOnboardingGoldDesign.diagonalDust,
        motionValue: .2,
      ),
      const Size(390, 844),
    );
    final entryLate = await _signature(
      const ZyraOnboardingGoldPainter(
        ZyraOnboardingGoldDesign.diagonalDust,
        motionValue: .9,
      ),
      const Size(390, 844),
    );
    final liveStart = await _signature(
      const ZyraOnboardingGoldPainter(
        ZyraOnboardingGoldDesign.diagonalDust,
        motion: ZyraOnboardingGoldMotion.liveDrift,
        motionValue: 0,
      ),
      const Size(390, 844),
    );
    final liveLater = await _signature(
      const ZyraOnboardingGoldPainter(
        ZyraOnboardingGoldDesign.diagonalDust,
        motion: ZyraOnboardingGoldMotion.liveDrift,
        motionValue: .25,
      ),
      const Size(390, 844),
    );
    expect(entryEarly, isNot(entryLate));
    expect(liveStart, isNot(liveLater));
  });

  testWidgets('gold choice also updates the protected login preview live', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: WelcomeScreen(devPreview: true)),
    );
    ZyraOnboardingGoldPainter painter() =>
        tester
                .widget<CustomPaint>(
                  find.byKey(const ValueKey('dev_onboarding_gold_backdrop')),
                )
                .painter!
            as ZyraOnboardingGoldPainter;

    expect(painter().design, ZyraOnboardingGoldDesign.diagonalDust);
    expect(painter().motion, ZyraOnboardingGoldMotion.liveDrift);
    final initialMotion = painter().motionValue;
    await tester.pump(const Duration(milliseconds: 700));
    expect(painter().motionValue, isNot(initialMotion));
    ZyraDevOnboardingGoldDesign.select(ZyraOnboardingGoldDesign.twinClouds);
    await tester.pump();
    expect(painter().design, ZyraOnboardingGoldDesign.twinClouds);
    expect(find.text('Continue with Google'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    expect(
      find.byKey(const ValueKey('dev_onboarding_gold_backdrop')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('page entrance replays and live drift continues on login', (
    tester,
  ) async {
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    await tester.pumpWidget(
      const MaterialApp(home: WelcomeScreen(devPreview: true)),
    );
    ZyraOnboardingGoldPainter painter() =>
        tester
                .widget<CustomPaint>(
                  find.byKey(const ValueKey('dev_onboarding_gold_backdrop')),
                )
                .painter!
            as ZyraOnboardingGoldPainter;

    await tester.pumpAndSettle();
    expect(painter().motion, ZyraOnboardingGoldMotion.pageEntrance);
    expect(painter().motionValue, 1);

    ZyraDevOnboardingGoldMotion.pageEntered();
    await tester.pump();
    expect(painter().motionValue, lessThan(.1));
    await tester.pump(const Duration(milliseconds: 350));
    expect(painter().motionValue, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();

    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.liveDrift);
    await tester.pump();
    expect(painter().motion, ZyraOnboardingGoldMotion.liveDrift);
    final firstFrame = painter().motionValue;
    await tester.pump(const Duration(milliseconds: 700));
    expect(painter().motionValue, isNot(firstFrame));

    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
    await tester.pumpAndSettle();
    expect(painter().motionValue, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion holds the selected gold pattern still', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: WelcomeScreen(devPreview: true),
        ),
      ),
    );
    ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.liveDrift);
    await tester.pump(const Duration(milliseconds: 700));
    final painter =
        tester
                .widget<CustomPaint>(
                  find.byKey(const ValueKey('dev_onboarding_gold_backdrop')),
                )
                .painter!
            as ZyraOnboardingGoldPainter;
    expect(painter.reducedMotion, isTrue);
    expect(painter.motionValue, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening artwork stays anchored across welcome and every theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: DevOnboardingIntroduction(
            direction: ZyraOnboardingDirection.luma,
            onContinue: _noOp,
          ),
        ),
      ),
    );
    await tester.pump();
    final initialArt = tester.getRect(
      find.byKey(const ValueKey('dev_opening_art_0')),
    );
    final greeting = tester.getRect(
      find.byKey(const ValueKey('dev_opening_heading_0')),
    );
    expect(initialArt.bottom, lessThan(greeting.top));
    await tester.tap(
      find.byKey(const ValueKey('dev_onboarding_welcome_continue')),
    );
    await tester.pump();
    final trustArt = tester.getRect(
      find.byKey(const ValueKey('dev_onboarding_verification_art')),
    );
    expect(trustArt.top, closeTo(initialArt.top, 1));
    expect(trustArt.height, closeTo(initialArt.height, 1));
    await tester.tap(
      find.byKey(const ValueKey('dev_onboarding_verification_continue')),
    );
    await tester.pump();
    for (var page = 1; page <= 3; page++) {
      final art = tester.getRect(find.byKey(ValueKey('dev_opening_art_$page')));
      final heading = tester.getRect(
        find.byKey(ValueKey('dev_opening_heading_$page')),
      );
      expect(art.top, closeTo(initialArt.top, 1));
      expect(art.height, closeTo(initialArt.height, 1));
      expect(art.bottom, lessThan(heading.top));
      if (page < 3) {
        await tester.tap(find.byKey(ValueKey('dev_opening_page_$page')));
        await tester.pump();
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'the protected toggle offers eleven dust previews without an obsolete pulse control',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: DevOnboardingTransitionPicker()),
          ),
        ),
      );
      for (final design in ZyraWelcomePulseDesign.values) {
        expect(
          find.byKey(ValueKey('dev_welcome_pulse_design_${design.name}')),
          findsNothing,
        );
      }
      for (final design in ZyraOnboardingGoldDesign.values) {
        expect(
          find.byKey(ValueKey('dev_onboarding_gold_design_${design.name}')),
          findsOneWidget,
        );
      }
      for (final motion in ZyraOnboardingGoldMotion.values) {
        expect(
          find.byKey(ValueKey('dev_onboarding_gold_motion_${motion.name}')),
          findsOneWidget,
        );
      }

      final backdrop = find.byKey(
        const ValueKey('dev_onboarding_gold_design_highDrift'),
      );
      await tester.ensureVisible(backdrop);
      await tester.tap(backdrop);
      await tester.pump();
      expect(
        ZyraDevOnboardingGoldDesign.current,
        ZyraOnboardingGoldDesign.highDrift,
      );

      final live = find.byKey(
        const ValueKey('dev_onboarding_gold_motion_liveDrift'),
      );
      await tester.ensureVisible(live);
      await tester.tap(live);
      await tester.pump();
      expect(
        ZyraDevOnboardingGoldMotion.current,
        ZyraOnboardingGoldMotion.liveDrift,
      );

      ZyraDeveloperAccess.setAuthorizedForTesting(false);
      await tester.pump();
      expect(backdrop, findsNothing);
      expect(live, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'the complete opening reuses splash gold and live backdrop choice',
    (tester) async {
      ZyraDevOnboardingGoldMotion.select(ZyraOnboardingGoldMotion.pageEntrance);
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: DevOnboardingIntroduction(
              direction: ZyraOnboardingDirection.luma,
              onContinue: _noOp,
            ),
          ),
        ),
      );
      await tester.pump();
      void expectGoldWordmark() => expect(
        tester.widget<Text>(find.text('ZYRA')).style!.color,
        ZyraColors.splashWordmark,
      );
      ZyraOnboardingGoldPainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('dev_onboarding_gold_backdrop')),
                  )
                  .painter!
              as ZyraOnboardingGoldPainter;
      expectGoldWordmark();
      expect(painter().design, ZyraOnboardingGoldDesign.diagonalDust);
      ZyraDevOnboardingGoldDesign.select(ZyraOnboardingGoldDesign.dustHalo);
      await tester.pump();
      expect(painter().design, ZyraOnboardingGoldDesign.dustHalo);
      await tester.tap(
        find.byKey(const ValueKey('dev_onboarding_welcome_continue')),
      );
      await tester.pump();
      expectGoldWordmark();
      expect(painter().design, ZyraOnboardingGoldDesign.dustHalo);
      await tester.tap(
        find.byKey(const ValueKey('dev_onboarding_verification_continue')),
      );
      await tester.pump();
      expectGoldWordmark();
      expect(painter().design, ZyraOnboardingGoldDesign.dustHalo);
      expect(find.text('2 / 4'), findsOneWidget);
      Container dot(int page) => tester.widget<Container>(
        find.descendant(
          of: find.byKey(ValueKey('dev_onboarding_story_dot_$page')),
          matching: find.byType(Container),
        ),
      );
      Color dotColor(int page) =>
          (dot(page).decoration! as BoxDecoration).color!;
      expect(dotColor(0), ZyraColors.journeyGold);
      expect(dot(0).constraints!.maxWidth, 6);
      expect(dotColor(1), ZyraColors.journeyGold);
      expect(dot(1).constraints!.maxWidth, 20);
      expect(dotColor(2), isNot(ZyraColors.journeyGold));
      var pageEntries = 0;
      void onPageEntry() => pageEntries++;
      ZyraDevOnboardingGoldMotion.pageEntries.addListener(onPageEntry);
      await tester.tap(find.byKey(const ValueKey('dev_opening_page_1')));
      await tester.pump();
      ZyraDevOnboardingGoldMotion.pageEntries.removeListener(onPageEntry);
      expect(find.text('3 / 4'), findsOneWidget);
      expect(pageEntries, 1);
      expect(dotColor(0), ZyraColors.journeyGold);
      expect(dot(0).constraints!.maxWidth, 6);
      expect(dotColor(1), ZyraColors.journeyGold);
      expect(dot(1).constraints!.maxWidth, 6);
      expect(dotColor(2), ZyraColors.journeyGold);
      expect(dot(2).constraints!.maxWidth, 20);
      await tester.tap(find.byKey(const ValueKey('dev_opening_page_2')));
      await tester.pump();
      expect(find.text('4 / 4'), findsOneWidget);
      expect(find.byType(ZyraWelcomePulseMark), findsNothing);
      ZyraDevWelcomePulseDesign.select(ZyraWelcomePulseDesign.twinHalo);
      await tester.pump();
      expect(find.byType(ZyraWelcomePulseMark), findsNothing);
      expect(
        find.byKey(const ValueKey('dev_onboarding_story_dot_3')),
        findsOneWidget,
      );
      expect(dotColor(3), ZyraColors.journeyGold);
      expect(dot(3).constraints!.maxWidth, 20);
      expect(
        find.byKey(const ValueKey('dev_onboarding_story_dot_4')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
