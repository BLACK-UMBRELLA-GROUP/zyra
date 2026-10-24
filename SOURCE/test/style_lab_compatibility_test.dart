import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/floating_nav_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ZyraText.useTestFontStubs = true;
    ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
    ZyraColors.selectDevLightAccent(ZyraDevLightAccent.purple);
    ZyraColors.selectAppSurfaceStyle(ZyraColors.currentDefaultSurfaceStyle);
    ZyraText.selectAppFont(ZyraText.currentDefaultFont);
    ZyraInteractionStyle.restoreDefaults();
  });

  tearDown(() {
    ZyraColors.selectDevPalette(ZyraColors.currentDefaultPalette);
    ZyraColors.selectDevLightAccent(ZyraDevLightAccent.purple);
    ZyraColors.selectAppSurfaceStyle(ZyraColors.currentDefaultSurfaceStyle);
    ZyraText.selectAppFont(ZyraText.currentDefaultFont);
    ZyraInteractionStyle.restoreDefaults();
    ZyraText.useTestFontStubs = false;
  });

  Widget subject() => MaterialApp(
    theme: ThemeData(
      brightness: ZyraColors.isLightPalette
          ? Brightness.light
          : Brightness.dark,
      textTheme: ZyraText.textTheme(
        ZyraColors.isLightPalette
            ? ThemeData.light().textTheme
            : ThemeData.dark().textTheme,
      ),
    ),
    home: Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: ZyraColors.brandGradient),
              child: Center(
                child: Container(
                  width: 250,
                  height: 200,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: ZyraColors.glassFill,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: ZyraColors.glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, Maryam.', style: ZyraText.heading()),
                      const SizedBox(height: 8),
                      Text(
                        'Background, accent, type and navigation remain independent.',
                        style: ZyraText.subtext(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          FloatingNavBar(
            currentIndex: 2,
            onTap: (_) {},
            items: const [
              FloatingNavItem(icon: Icons.search, label: 'Browse'),
              FloatingNavItem(
                icon: Icons.bookmark_border,
                label: 'Connections',
              ),
              FloatingNavItem(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                badge: 8,
              ),
              FloatingNavItem(
                icon: Icons.gpp_good_outlined,
                label: 'Guardian',
                dot: true,
              ),
              FloatingNavItem(icon: Icons.person_outline, label: 'Profile'),
            ],
          ),
        ],
      ),
    ),
  );

  testWidgets('every member dark background fits fixed Floating Glass', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final palette in ZyraDevPalette.values.where((p) => !p.isLight)) {
      ZyraColors.selectDevPalette(palette);
      await tester.pumpWidget(subject());
      await tester.pump();
      expect(tester.takeException(), isNull, reason: palette.label);
    }
    expect(ZyraInteractionStyle.navStyle, ZyraNavStyle.floatingGlass);
  });

  testWidgets('every member reading face fits Midnight Plum', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ZyraColors.selectDevPalette(ZyraDevPalette.midnightPlum);
    for (final font in ZyraAppFont.values) {
      ZyraText.selectAppFont(font);
      await tester.pumpWidget(subject());
      await tester.pump();
      expect(tester.takeException(), isNull, reason: font.label);
    }
  });
}
