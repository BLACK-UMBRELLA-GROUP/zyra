import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_gold_action_pill.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
    ZyraText.selectAppFont(ZyraText.currentDefaultFont);
  });

  tearDown(() {
    ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
    ZyraText.selectAppFont(ZyraText.currentDefaultFont);
    ZyraText.useTestFontStubs = false;
  });

  Future<void> pumpPill(
    WidgetTester tester, {
    VoidCallback? onPressed,
    bool busy = false,
    double width = 320,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: ZyraColors.isLightPalette
              ? Brightness.light
              : Brightness.dark,
        ),
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Center(
              child: SizedBox(
                width: width,
                child: ZyraGoldActionPill(
                  label: 'Unlock Compatibility+',
                  icon: Icons.auto_awesome_rounded,
                  busy: busy,
                  onPressed: onPressed,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('uses the Founder-selected soft gold wash contract', (
    tester,
  ) async {
    await pumpPill(tester, onPressed: () {});

    final ink = tester.widget<Ink>(find.byType(Ink));
    final decoration = ink.decoration! as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;
    final border = decoration.border! as Border;

    expect(gradient.colors, [
      ZyraColors.journeyGold.withValues(alpha: 0.25),
      ZyraColors.journeyGold.withValues(alpha: 0.07),
    ]);
    expect(border.top.color, ZyraColors.journeyGold.withValues(alpha: 0.48));
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(find.text('Unlock Compatibility+'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('taps only while enabled and exposes a 48 point target', (
    tester,
  ) async {
    var taps = 0;
    await pumpPill(tester, onPressed: () => taps++);

    final inkWell = tester.widget<InkWell>(find.byType(InkWell));
    expect(inkWell.onTap, isNotNull);
    expect(
      tester.getSize(find.byType(ZyraGoldActionPill)).height,
      greaterThanOrEqualTo(48),
    );

    await tester.tap(find.byType(ZyraGoldActionPill));
    await tester.pump();
    expect(taps, 1);

    await pumpPill(tester);
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
    await tester.tap(find.byType(ZyraGoldActionPill));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('busy state is distinct and cannot submit twice', (tester) async {
    var taps = 0;
    await pumpPill(tester, busy: true, onPressed: () => taps++);

    expect(find.text('Unlocking…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);

    await tester.tap(find.byType(ZyraGoldActionPill));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('fits compact width and accessibility text on every palette', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final palette in ZyraDevPalette.values) {
      ZyraColors.selectDevPalette(palette);
      await pumpPill(tester, width: 260, textScale: 1.3, onPressed: () {});
      expect(tester.takeException(), isNull, reason: palette.label);
      expect(find.text('Unlock Compatibility+'), findsOneWidget);
    }
  });
}
