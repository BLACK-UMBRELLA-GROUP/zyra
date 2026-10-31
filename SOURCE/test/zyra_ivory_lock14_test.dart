import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/dev/zyra_request_account_session.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/theme/zyra_colors.dart';
import 'package:zyra/theme/zyra_interaction_style.dart';
import 'package:zyra/widgets/zyra_floating_surface.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('LOCK14 opaque reading roles and gold text fills meet 4.5:1', () {
    expect(
      contrast(ZyraColors.espresso, ZyraColors.goldTextFill),
      greaterThanOrEqualTo(4.5),
    );
    for (final bg in [
      ZyraColors.ivoryTop,
      ZyraColors.ivoryBottom,
      ZyraColors.cardSurface,
      ZyraColors.lowerSurface,
      ZyraColors.sheetIvory,
    ]) {
      expect(contrast(ZyraColors.espresso, bg), greaterThanOrEqualTo(4.5));
      expect(contrast(ZyraColors.goldText, bg), greaterThanOrEqualTo(4.65));
      expect(contrast(ZyraColors.secondaryText, bg), greaterThanOrEqualTo(4.5));
    }
    expect(
      contrast(ZyraColors.espresso, ZyraColors.journeyGold),
      lessThan(4.5),
      reason:
          'Accent gold cannot substitute for the distinct text-bearing fill.',
    );
  });
  test(
    'startup ignores old palette without changing any stored member preference',
    () async {
      SharedPreferences.setMockInitialValues({
        'zyra.cached_account_owner': 'lock14-test-member',
        'zyra.app_palette': 'deepEmerald',
        'zyra.app_palette_revision': 'older',
        'zyra.cached_first_name': 'Example',
        'zyra.haptic_level': 'strong',
        'zyra.app_gold_enabled': true,
        'zyra.app_lock_enabled': true,
      });
      await ZyraLocalPrefs.init();
      await ZyraLocalPrefs.bindAccount('lock14-test-member');
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      ZyraColors.restoreCurrentAppPalette();
      ZyraColors.restoreAppPalette('midnightPlum');
      ZyraColors.selectAppPalette(ZyraDevPalette.royalBlue);
      await Future<void>.delayed(Duration.zero);
      expect(ZyraColors.devPalette, ZyraDevPalette.ivory);
      expect(ZyraColors.isLightPalette, isTrue);
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
      expect(ZyraLocalPrefs.cachedAppPaletteName, 'deepEmerald');
      expect(ZyraLocalPrefs.cachedAppPaletteRevision, 'older');
    },
  );
  test('session adopts Ivory and retains admission and haptic lifetime', () {
    var live = true;
    final session = ZyraRequestAccountSession(
      canAct: () => live,
      palette: ZyraDevPalette.deepEmerald,
      hapticLevel: ZyraHapticLevel.subtle,
      goldEnabled: false,
    );
    expect(session.palette, ZyraDevPalette.ivory);
    expect(session.setPalette(ZyraDevPalette.deepEmerald), isFalse);
    expect(session.setHapticLevel(ZyraHapticLevel.strong), isTrue);
    expect(session.setGoldEnabled(true), isTrue);
    live = false;
    expect(session.setHapticLevel(ZyraHapticLevel.subtle), isFalse);
    live = true;
    expect(session.current, isFalse);
    session.dispose();
  });
  testWidgets(
    'floating owner suppresses nested shadow without moving content',
    (t) async {
      const marker = ValueKey('marker');
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(20),
              child: ZyraFloatingSurface(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: ZyraFloatingSurface(child: SizedBox(key: marker)),
                ),
              ),
            ),
          ),
        ),
      );
      final decor = t.widgetList<DecoratedBox>(find.byType(DecoratedBox));
      expect(
        decor.where(
          (d) =>
              d.decoration is BoxDecoration &&
              (d.decoration as BoxDecoration).boxShadow ==
                  ZyraFloatingSurface.standardShadows,
        ),
        hasLength(1),
      );
      expect(
        t.getRect(find.byKey(marker)),
        const Rect.fromLTWH(20, 20, 200, 200),
      );
    },
  );
  testWidgets(
    'scroll shadow clearance preserves viewport content positions and extent',
    (t) async {
      const marker = ValueKey('scroll-marker');
      final controller = ScrollController();
      Widget frame(bool floating) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 400,
            child: floating
                ? ZyraShadowScrollView(
                    controller: controller,
                    padding: const EdgeInsets.all(20),
                    child: const SizedBox(key: marker, height: 800),
                  )
                : SingleChildScrollView(
                    controller: controller,
                    padding: const EdgeInsets.all(20),
                    child: const SizedBox(key: marker, height: 800),
                  ),
          ),
        ),
      );
      await t.pumpWidget(frame(false));
      final before = t.getRect(find.byKey(marker));
      final extent = controller.position.maxScrollExtent;
      await t.pumpWidget(frame(true));
      await t.pump();
      expect(t.getRect(find.byKey(marker)), before);
      expect(controller.position.maxScrollExtent, extent);
      await t.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );
  testWidgets('unbounded nested scroll keeps natural height', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              ZyraShadowScrollView(child: SizedBox(height: 100, width: 100)),
            ],
          ),
        ),
      ),
    );
    expect(t.takeException(), isNull);
  });
}
