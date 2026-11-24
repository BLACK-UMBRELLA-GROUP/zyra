import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUp(() => ZyraText.useTestFontStubs = true);
  tearDown(() => ZyraText.useTestFontStubs = false);

  test('reading roles meet V9 on the darkest locked page background', () {
    for (final ink in [
      ZyraColors.goldText,
      ZyraColors.greenText,
      ZyraColors.secondaryText,
      ZyraColors.dangerText,
    ]) {
      final ratio =
          (ZyraColors.ivoryBottom.computeLuminance() + .05) /
          (ink.computeLuminance() + .05);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: '$ink');
    }
    expect(
      ZyraText.body(color: ZyraColors.journeyGold).color,
      ZyraColors.goldText,
    );
    expect(
      ZyraText.body(color: ZyraColors.positiveGreen).color,
      ZyraColors.greenText,
    );
    expect(
      ZyraText.subtext(color: ZyraColors.mutedText).color,
      ZyraColors.secondaryText,
    );
    expect(
      ZyraText.body(color: ZyraColors.espresso.withValues(alpha: .45)).color,
      ZyraColors.secondaryText,
    );
  });

  test('all small reading styles and Material slots have regular minimum', () {
    final theme = ZyraText.textTheme(ThemeData().textTheme);
    for (final style in [
      ZyraText.heading(size: 15),
      ZyraText.body(),
      ZyraText.subtext(),
      ZyraText.option(),
      ZyraText.button(),
      ZyraText.chapterLabel(),
      ZyraText.privacyText(),
      theme.bodySmall!,
      theme.bodyMedium!,
      theme.labelSmall!,
      theme.labelMedium!,
      theme.labelLarge!,
    ]) {
      if ((style.fontSize ?? 14) < 16) {
        expect(style.fontWeight!.value, greaterThanOrEqualTo(400));
      }
    }
    expect(ZyraText.body(size: 16).fontWeight, FontWeight.w300);
    expect(ZyraText.heading(size: 26).fontWeight, FontWeight.w200);
    expect(
      ZyraText.body(color: ZyraColors.espresso).color,
      ZyraColors.espresso,
    );
  });

  test('large accent and white photo ink preserve their roles', () {
    expect(
      ZyraText.heading(size: 24, color: ZyraColors.journeyGold).color,
      ZyraColors.journeyGold,
    );
    expect(ZyraText.wordmark(size: 24).color, ZyraColors.splashWordmark);
    expect(ZyraText.wordmark(size: 22).color, ZyraColors.goldText);
    expect(ZyraText.body(color: Colors.white).color, Colors.white);
    expect(ZyraText.button().color, isNull);
    expect(ZyraColors.journeyGold, const Color(0xFFA9792E));
    expect(ZyraColors.positiveGreen, const Color(0xFF4E9A72));
  });

  test('locked darker fallback inks work on the specified tinted surfaces', () {
    double ratio(Color ink, Color bg) =>
        (bg.computeLuminance() + .05) / (ink.computeLuminance() + .05);
    expect(
      ratio(ZyraColors.goldTextStrong, const Color(0xFFDCC8A8)),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      ratio(ZyraColors.secondaryStrong, const Color(0xFFE1D8CA)),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      ratio(ZyraColors.espresso, const Color(0xFFC09D66)),
      greaterThanOrEqualTo(3),
    );
  });
}
