import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/models/zyra_error_state.dart';
import 'package:zyra/screens/subscription/membership_required_screen.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_full_screen_error.dart';

void main() {
  late bool originalFontStubs;
  late String? originalWordmarkFont;
  late ZyraDevPalette originalPalette;

  setUp(() {
    originalFontStubs = ZyraText.useTestFontStubs;
    originalWordmarkFont = ZyraText.testWordmarkFontFamily;
    originalPalette = ZyraColors.devPalette;
    ZyraText.useTestFontStubs = true;
    ZyraText.testWordmarkFontFamily = null;
    ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
  });

  tearDown(() {
    ZyraText.useTestFontStubs = originalFontStubs;
    ZyraText.testWordmarkFontFamily = originalWordmarkFont;
    ZyraColors.selectDevPalette(originalPalette);
  });

  for (final stubFonts in [false, true]) {
    final branch = stubFonts ? 'test-stub' : 'production';

    test('$branch wordmark defaults to the approved splash gold', () {
      ZyraText.useTestFontStubs = stubFonts;

      expect(ZyraColors.splashWordmark, const Color(0xFFE5CE8E));
      expect(ZyraColors.splashWordmark, isNot(ZyraColors.journeyGold));
      for (final size in [24.0, 26.0, 29.0, 30.0, 34.0]) {
        final style = ZyraText.wordmark(size: size);
        expect(style.color, ZyraColors.splashWordmark);
        expect(style.fontFamily, 'Syne');
        expect(style.fontSize, size);
        expect(style.fontWeight, FontWeight.w600);
        expect(style.letterSpacing, 4);
      }
    });

    test('$branch wordmark preserves deliberate colour overrides', () {
      ZyraText.useTestFontStubs = stubFonts;

      for (final override in [
        Colors.white,
        ZyraColors.journeyGold,
        ZyraColors.ink(0.24),
        const Color(0xFF527A68),
      ]) {
        expect(ZyraText.wordmark(color: override).color, override);
      }
    });
  }

  test('a bundled test font alias retains the canonical wordmark colour', () {
    ZyraText.testWordmarkFontFamily = 'BundledSyne';

    final style = ZyraText.wordmark();
    expect(style.fontFamily, 'BundledSyne');
    expect(style.color, ZyraColors.splashWordmark);
  });

  test('ordinary headings and reading text keep their existing colours', () {
    expect(ZyraText.heading(size: 26).color, ZyraColors.foreground);
    expect(ZyraText.body().color, ZyraColors.foregroundBody);
    expect(ZyraText.subtext().color, ZyraColors.foregroundSecondary);
    expect(ZyraText.chapterLabel().color, ZyraColors.foregroundSecondary);
    expect(ZyraText.heading(size: 26).color, isNot(ZyraColors.splashWordmark));
  });

  for (final kind in ZyraErrorKind.values) {
    testWidgets('${kind.name} recovery uses gold for the wordmark only', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: ZyraFullScreenError(
            kind: kind,
            onPrimary: () {},
            onSecondary: () {},
            referenceCode: 'ZY-TEST',
          ),
        ),
      );

      final wordmark = tester.widget<Text>(find.text('ZYRA'));
      expect(wordmark.style?.color, ZyraColors.splashWordmark);
      expect(wordmark.style?.fontFamily, 'Syne');
      expect(wordmark.style?.fontSize, 29);
      expect(wordmark.style?.fontWeight, FontWeight.w600);
      expect(
        tester.widget<Text>(find.text(kind.content.title)).style?.color,
        ZyraColors.foreground,
      );
      expect(
        tester.widget<Text>(find.text(kind.content.message)).style?.color,
        ZyraColors.foregroundSecondary,
      );
      expect(find.byKey(const ValueKey('zyra_error_primary')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('zyra_error_secondary')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final guardian in [false, true]) {
    testWidgets(
      '${guardian ? 'Guardian' : 'Seeker'} membership header is gold',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(home: MembershipRequiredScreen(guardian: guardian)),
        );
        await tester.pumpAndSettle();

        final wordmark = tester.widget<Text>(find.text('ZYRA'));
        expect(wordmark.style?.color, ZyraColors.splashWordmark);
        expect(wordmark.style?.fontFamily, 'Syne');
        expect(
          tester
              .widget<Text>(find.text('Your membership is not active'))
              .style
              ?.color,
          ZyraColors.foreground,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
