import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_promotion_engine.dart';
import 'package:zyra/theme/zyra_text.dart';
import 'package:zyra/widgets/zyra_bottom_promotion.dart';

void main() {
  late ZyraPromotionEngine engine;

  setUp(() async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    ZyraText.useTestFontStubs = true;
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    engine = ZyraPromotionEngine();
    await engine.initialize();
  });

  tearDown(() {
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    ZyraText.useTestFontStubs = false;
  });

  Future<void> pumpBanner(
    WidgetTester tester, {
    required ZyraPromotionProduct product,
    required ValueChanged<ZyraPromotionProduct> onOpenPlan,
  }) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    engine.showDeveloperPreview(
      product: product,
      role: ZyraPromotionRole.seeker,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              ZyraBottomPromotion(
                role: ZyraPromotionRole.seeker,
                placement: ZyraPromotionPlacement.home,
                isCalmLanding: true,
                isEntitled: false,
                upgradeOfferAvailable: true,
                onOpenPlan: onOpenPlan,
                engine: engine,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final product in [
    ZyraPromotionProduct.zyraOne,
    ZyraPromotionProduct.guardianPlus,
  ]) {
    testWidgets('retired commercial preview stays hidden: ${product.name}', (
      tester,
    ) async {
      var opens = 0;
      await pumpBanner(tester, product: product, onOpenPlan: (_) => opens++);
      expect(
        find.byKey(const ValueKey('promotion_primary_action')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('promotion_countdown')), findsNothing);
      await tester.pump(const Duration(seconds: 5));
      expect(opens, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('notification explainer provides not-now and permanent decline', (
    tester,
  ) async {
    await pumpBanner(
      tester,
      product: ZyraPromotionProduct.notifications,
      onOpenPlan: (_) => fail('notification education is not a plan route'),
    );
    expect(
      find.byKey(const ValueKey('notification_promotion_not_now')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('notification_promotion_never')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(
      find.byKey(const ValueKey('notification_promotion_not_now')),
    );
    await tester.pump();
    expect(find.text('Stay close to your Journey'), findsNothing);
  });

  testWidgets('developer reset clears event evidence', (tester) async {
    await pumpBanner(
      tester,
      product: ZyraPromotionProduct.notifications,
      onOpenPlan: (_) {},
    );
    expect(engine.developerEvents, isNotEmpty);
    await engine.resetDeveloperPolicy();
    expect(engine.developerEvents, isEmpty);
  });

  testWidgets('enabled notification preview updates without a success notice', (
    tester,
  ) async {
    await pumpBanner(
      tester,
      product: ZyraPromotionProduct.notifications,
      onOpenPlan: (_) => fail('notification education is not a plan route'),
    );
    await tester.tap(find.byKey(const ValueKey('promotion_primary_action')));
    await tester.pumpAndSettle();
    expect(engine.permissionState, ZyraNotificationPermissionState.enabled);
    expect(find.text('Stay close to your Journey'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    expect(
      find.text('Device notifications enabled for this preview.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('unavailable notification permission keeps its truthful notice', (
    tester,
  ) async {
    await pumpBanner(
      tester,
      product: ZyraPromotionProduct.notifications,
      onOpenPlan: (_) => fail('notification education is not a plan route'),
    );
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
    await tester.tap(find.byKey(const ValueKey('promotion_primary_action')));
    await tester.pumpAndSettle();
    expect(
      engine.permissionState,
      ZyraNotificationPermissionState.notDetermined,
    );
    expect(
      find.text('Device notifications are not connected in this build yet.'),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
