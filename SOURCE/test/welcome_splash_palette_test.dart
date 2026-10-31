import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/splash_screen.dart';
import 'package:zyra/screens/welcome_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';

void main() {
  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraDeveloperAccess.resetAuthorizationForTesting();
  });

  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = false;
  });

  testWidgets('settled main splash uses the canonical brand text colours', (
    tester,
  ) async {
    expect(ZyraColors.splashWordmark, const Color(0xFFA9792E));
    expect(ZyraColors.splashTagline, ZyraColors.secondaryText);
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pump(const Duration(milliseconds: 2401));

    final wordmark = tester.widget<Text>(
      find.byKey(const ValueKey('splash_study_wordmark')),
    );
    final tagline = tester.widget<Text>(find.text('Connecting Through Trust'));
    expect(wordmark.style?.color, ZyraColors.splashWordmark);
    expect(tagline.style?.color, ZyraColors.splashTagline);
    final headerMark = ZyraText.wordmark(size: 18);
    expect(wordmark.style?.fontFamily, headerMark.fontFamily);
    expect(wordmark.style?.fontWeight, headerMark.fontWeight);
    expect(
      wordmark.style!.letterSpacing! / wordmark.style!.fontSize!,
      closeTo(headerMark.letterSpacing! / headerMark.fontSize!, .000001),
    );
    expect(tagline.style?.fontFamily, 'Poppins');

    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final preview in const [false, true]) {
    testWidgets(
      '${preview ? 'developer preview' : 'ordinary'} Welcome matches splash text colours',
      (tester) async {
        if (preview) ZyraDeveloperAccess.setAuthorizedForTesting(true);
        await tester.pumpWidget(
          MaterialApp(home: WelcomeScreen(devPreview: preview)),
        );

        final wordmark = tester.widget<Text>(find.text('ZYRA'));
        final tagline = tester.widget<Text>(
          find.text('Connecting Through Trust'),
        );
        expect(wordmark.style?.color, ZyraColors.splashWordmark);
        expect(tagline.style?.color, ZyraColors.splashTagline);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
