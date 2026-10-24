// Fresh candidate captures only; no approved baseline is changed.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/onboarding/onboarding_stage_intro_screen.dart';
import 'package:zyra/theme/zyra_text.dart';

const _capture = bool.fromEnvironment('ZYRA_ACCOUNT_ICON_CAPTURE');
const _boundary = ValueKey('account-artwork-candidate');

void main() {
  setUpAll(() async {
    final reading = FontLoader('PoppinsAccountIconReview');
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
    final logo = FontLoader('SyneAccountIconReview')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            File('assets/fonts/Syne-SemiBold.ttf').readAsBytesSync(),
          ),
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await Future.wait([reading.load(), logo.load(), icons.load()]);
    ZyraText.useTestFontStubs = true;
    ZyraText.testReadingFontFamily = 'PoppinsAccountIconReview';
    ZyraText.testWordmarkFontFamily = 'SyneAccountIconReview';
  });
  tearDownAll(() {
    ZyraText.useTestFontStubs = false;
    ZyraText.testReadingFontFamily = null;
    ZyraText.testWordmarkFontFamily = null;
  });

  for (final compact in [false, true]) {
    testWidgets(
      'account artwork real fonts ${compact ? 'compact140' : 'phone'}',
      (tester) async {
        tester.view.physicalSize = compact
            ? const Size(320, 568)
            : const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: 24, bottom: 24),
                viewPadding: const EdgeInsets.only(top: 24, bottom: 24),
                textScaler: TextScaler.linear(compact ? 1.4 : 1),
                disableAnimations: true,
              ),
              child: RepaintBoundary(key: _boundary, child: child!),
            ),
            home: AccountEssentialsIntroScreen(onContinue: () {}),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final suffix = compact ? 'compact140' : 'phone';
        await _candidate(tester, suffix);
        await tester.ensureVisible(
          find.byKey(const ValueKey('onboarding_stage_continue')),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (compact) await _candidate(tester, '${suffix}_end');
      },
    );
  }
}

Future<void> _candidate(WidgetTester tester, String name) async {
  if (!_capture) return;
  expect(autoUpdateGoldenFiles, isTrue);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final image = await tester.runAsync(() => boundary.toImage());
  try {
    final data = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    await tester.runAsync(
      () => expectLater(
        data!.buffer.asUint8List(),
        matchesGoldenFile(
          'candidates/account_essentials_icon_2026_10_04/$name.png',
        ),
      ),
    );
  } finally {
    image?.dispose();
  }
}
