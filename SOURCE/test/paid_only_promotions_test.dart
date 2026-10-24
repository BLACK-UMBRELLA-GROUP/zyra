import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/screens/browse/browse_screen.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_promotion_engine.dart';
import 'package:zyra/state/app_state.dart';

void main() {
  final now = DateTime.utc(2026, 9, 13);
  late ZyraPromotionEngine engine;

  setUp(() async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    engine = ZyraPromotionEngine(now: () => now);
    await engine.initialize();
  });

  tearDown(() {
    engine.dispose();
    ZyraDeveloperAccess.setAuthorizedForTesting(false);
  });

  ZyraPromotionDecision surface() => engine.decisionForSurface(
    role: ZyraPromotionRole.seeker,
    placement: ZyraPromotionPlacement.home,
    isCalmLanding: true,
    isEntitled: false,
    upgradeOfferAvailable: true,
  );

  test('commercial products cannot be offered for any entry or role', () {
    for (final product in [
      ZyraPromotionProduct.zyraOne,
      ZyraPromotionProduct.guardianPlus,
    ]) {
      for (final role in ZyraPromotionRole.values) {
        for (final intent in ZyraPromotionIntent.values) {
          final decision = engine.evaluate(
            ZyraPromotionRequest(
              roleContext: role,
              targetProduct: product,
              feature: ZyraPromotionFeature.generalMembership,
              placement: ZyraPromotionPlacement.home,
              trigger: ZyraPromotionTrigger.developerPreview,
              presentationIntent: intent,
              isEntitled: false,
              dependency: ZyraPromotionDependency.ready,
              isOnboardingComplete: true,
              hasSuccessfulValueMarker: true,
              isCalmLanding: true,
              offerAvailable: true,
              exclusion: ZyraPromotionExclusion.none,
              history: ZyraPromotionPromptHistory(
                policyFirstSeen: now.subtract(const Duration(days: 365)),
                notificationExplainers: 0,
                rollingUpgradeImpressions: 0,
                proactiveShownThisSession: false,
              ),
            ),
          );
          expect(decision.kind, ZyraPromotionDecisionKind.hidden);
          expect(decision.offer, isNull);
        }
      }
    }
  });

  test(
    'retired value moments and developer requests cannot queue a sale',
    () async {
      for (final product in [
        ZyraPromotionProduct.zyraOne,
        ZyraPromotionProduct.guardianPlus,
      ]) {
        await engine.setUpgradeSuggestionsEnabled(product, true);
        await engine.markUpgradeValueMoment(
          role: ZyraPromotionRole.seeker,
          product: product,
          placement: ZyraPromotionPlacement.home,
          feature: ZyraPromotionFeature.generalMembership,
          trigger: ZyraPromotionTrigger.firstActiveJourney,
        );
        engine.showDeveloperPreview(
          product: product,
          role: ZyraPromotionRole.seeker,
        );
        expect(surface().kind, ZyraPromotionDecisionKind.hidden);
        expect(engine.upgradeSuggestionsEnabled(product), isFalse);
      }
    },
  );

  test(
    'old commercial history is discarded while notification opt-out survives',
    () async {
      await ZyraLocalPrefs.setPromotionPolicy(
        jsonEncode({
          'policy_started_at': now
              .subtract(const Duration(days: 365))
              .toIso8601String(),
          'upgrade_pending': 'zyraOne',
          'upgrade_role': 'seeker',
          'upgrade_placement': 'home',
          'hidden_targets': [],
          'notification_pending': true,
          'notification_role': 'seeker',
          'notification_never_ask': true,
          'notification_impressions': 1,
        }),
      );
      engine.dispose();
      engine = ZyraPromotionEngine(now: () => now);
      await engine.initialize();
      expect(surface().kind, ZyraPromotionDecisionKind.hidden);
      final stored = jsonDecode(ZyraLocalPrefs.promotionPolicy!) as Map;
      expect(stored.containsKey('upgrade_pending'), isFalse);
      expect(stored.containsKey('hidden_targets'), isFalse);
      expect(stored['notification_never_ask'], isTrue);
      expect(stored['notification_impressions'], 1);
    },
  );

  test(
    'notification education remains available without a commercial offer',
    () async {
      await engine.markNotificationValueMoment(
        role: ZyraPromotionRole.seeker,
        trigger: ZyraPromotionTrigger.firstActiveJourney,
      );
      expect(surface().kind, ZyraPromotionDecisionKind.notificationEducation);
      expect(surface().offer!.product, ZyraPromotionProduct.notifications);
      expect(surface().offer!.dependency, ZyraPromotionDependency.notBuilt);
    },
  );

  test('ZYRA One browsing is unlimited and Seeker Basic stops at 25', () {
    for (final viewed in [24, 25, 26, 500]) {
      expect(
        zyraBrowseLimitReached(plan: ZyraPlan.one, viewed: viewed),
        isFalse,
      );
      expect(
        zyraBrowseLimitReached(plan: ZyraPlan.basic, viewed: viewed),
        viewed >= 25,
      );
    }
  });
}
