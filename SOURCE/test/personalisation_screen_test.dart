import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zyra/screens/settings/personalisation_screen.dart';
import 'package:zyra/dev/zyra_app_gold_preview.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_app_gold_style.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_personalisation_content.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ZyraAppGoldStyle.instance.restore(false);
    ZyraDevAppGold.instance.resetForTesting();
    ZyraDeveloperAccess.resetAuthorizationForTesting();
    ZyraText.useTestFontStubs = true;
    ZyraColors.restoreAppPalette(null);
    ZyraText.restoreAppFont(null);
    ZyraInteractionStyle.restoreHapticLevel(null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
  });

  tearDown(() {
    ZyraAppGoldStyle.instance.restore(false);
    ZyraDevAppGold.instance.resetForTesting();
    ZyraColors.restoreAppPalette(null);
    ZyraText.restoreAppFont(null);
    ZyraInteractionStyle.restoreHapticLevel(null);
    ZyraText.useTestFontStubs = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('Personalisation exposes ten dark backgrounds and no light studies', () {
    expect(PersonalisationScreen.availablePalettes, hasLength(10));
    expect(
      PersonalisationScreen.availablePalettes,
      contains(ZyraDevPalette.midnightBlue),
    );
    expect(
      PersonalisationScreen.availablePalettes.every(
        (palette) => !palette.isLight,
      ),
      isTrue,
    );
    expect(
      PersonalisationScreen.availablePalettes,
      isNot(contains(ZyraDevPalette.paperWhite)),
    );
    expect(
      PersonalisationScreen.availablePalettes,
      isNot(contains(ZyraDevPalette.crystalMist)),
    );
  });

  testWidgets('screen starts from Midnight Plum, Poppins and Subtle', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PersonalisationScreen()));
    await tester.pump();

    expect(find.text('Personalisation'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('personalisation_preview')),
      findsOneWidget,
    );
    expect(find.text('Choose how ZYRA looks and responds.'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('personalisation-scroll')),
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    expect(find.text('YOUR EXPERIENCE'), findsOneWidget);
    expect(find.text('Midnight Plum'), findsOneWidget);
    expect(find.text('Poppins'), findsOneWidget);
    expect(find.text('Subtle'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('background sheet omits light choices and applies a dark one', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PersonalisationScreen()));

    await tester.tap(find.byKey(const ValueKey('personalisation_background')));
    await tester.pumpAndSettle();
    expect(find.text('Paper White'), findsNothing);
    expect(find.text('Crystal Mist'), findsNothing);
    expect(find.text('Deep Emerald'), findsOneWidget);

    await tester.tap(find.text('Deep Emerald'));
    await tester.pumpAndSettle();
    expect(ZyraColors.devPalette, ZyraDevPalette.deepEmerald);
  });

  testWidgets('Midnight blue is selected through the Background sheet', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PersonalisationScreen()));
    expect(ZyraColors.devPalette, ZyraDevPalette.midnightPlum);
    await tester.tap(find.byKey(const ValueKey('personalisation_background')));
    await tester.pumpAndSettle();
    final choice = find.byKey(
      const ValueKey('personalisation_choice_ZyraDevPalette.midnightBlue'),
    );
    await tester.scrollUntilVisible(
      choice,
      160,
      scrollable: find.descendant(
        of: find.byType(ZyraPersonalisationChoiceSheet<ZyraDevPalette>),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(choice);
    await tester.pumpAndSettle();
    expect(ZyraColors.devPalette, ZyraDevPalette.midnightBlue);
    expect(ZyraLocalPrefs.cachedAppPaletteName, 'midnightBlue');
    expect(
      ZyraLocalPrefs.cachedAppPaletteRevision,
      ZyraColors.currentPaletteRevision,
    );
    expect(find.text('Midnight blue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final role in ['seeker', 'wali']) {
    testWidgets(
      '$role can turn gold accents On and Off without developer access',
      (tester) async {
        ZyraLocalPrefs.setCachedRole(role);
        expect(ZyraDeveloperAccess.canUseDeveloperTools, isFalse);
        await tester.pumpWidget(
          const MaterialApp(home: PersonalisationScreen()),
        );
        final toggle = find.byKey(
          const ValueKey('personalisation_gold_toggle'),
        );
        await tester.ensureVisible(toggle);
        await tester.pumpAndSettle();
        expect(tester.widget<Switch>(toggle).value, isFalse);
        final semantics = tester.ensureSemantics();
        expect(tester.getSemantics(toggle).label, contains('Gold accents'));
        semantics.dispose();

        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(tester.widget<Switch>(toggle).value, isTrue);
        expect(ZyraAppGoldStyle.instance.enabled, isTrue);
        expect(ZyraDevAppGold.instance.renderingEnabled, isTrue);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(tester.widget<Switch>(toggle).value, isFalse);
        expect(ZyraDevAppGold.instance.renderingEnabled, isFalse);
        expect(tester.takeException(), isNull);
        ZyraLocalPrefs.setCachedRole(null);
      },
    );
  }

  testWidgets(
    'gold control remains readable and reachable at compact 140% text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.4)),
            child: child!,
          ),
          home: const PersonalisationScreen(),
        ),
      );
      final toggle = find.byKey(const ValueKey('personalisation_gold_toggle'));
      await tester.scrollUntilVisible(toggle, 160);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(ZyraAppGoldStyle.instance.enabled, isTrue);
      expect(find.text('Gold accents'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Poppins is fixed for members while haptic choice still applies',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PersonalisationScreen()));

      await tester.ensureVisible(
        find.byKey(const ValueKey('personalisation_font')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('personalisation_font')));
      await tester.pumpAndSettle();
      expect(find.text('Poppins'), findsOneWidget);
      expect(find.text('Manrope'), findsNothing);
      expect(ZyraText.appFont, ZyraAppFont.poppins);
      expect(tester.widget<Text>(find.text('ZYRA')).style?.fontFamily, 'Syne');
      expect(
        tester
            .widget<Text>(find.text('Connecting Through Trust'))
            .style
            ?.fontFamily,
        'Poppins',
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('personalisation_haptic')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('personalisation_haptic')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Medium'));
      await tester.pumpAndSettle();
      expect(ZyraInteractionStyle.hapticLevel, ZyraHapticLevel.medium);
    },
  );
}
