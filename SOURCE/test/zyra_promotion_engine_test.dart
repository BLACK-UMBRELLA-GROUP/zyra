import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zyra/services/zyra_local_prefs.dart';
import 'package:zyra/services/zyra_developer_access.dart';
import 'package:zyra/services/zyra_promotion_engine.dart';

void main() {
  late DateTime now;
  late ZyraPromotionEngine engine;

  setUp(() async {
    ZyraDeveloperAccess.setAuthorizedForTesting(true);
    SharedPreferences.setMockInitialValues({});
    await ZyraLocalPrefs.init();
    now = DateTime.utc(2026, 8, 23, 12);
    engine = ZyraPromotionEngine(now: () => now);
    await engine.initialize();
  });

  tearDown(() => ZyraDeveloperAccess.setAuthorizedForTesting(false));

  ZyraPromotionRequest request({
    ZyraPromotionRole role = ZyraPromotionRole.seeker,
    ZyraPromotionProduct product = ZyraPromotionProduct.notifications,
    ZyraPromotionFeature feature = ZyraPromotionFeature.generalMembership,
    ZyraPromotionPlacement placement = ZyraPromotionPlacement.home,
    ZyraPromotionTrigger trigger = ZyraPromotionTrigger.saveSucceeded,
    ZyraPromotionIntent intent = ZyraPromotionIntent.proactive,
    bool entitled = false,
    ZyraPromotionDependency dependency = ZyraPromotionDependency.ready,
    bool onboarding = true,
    bool valueMarker = true,
    bool calm = true,
    bool available = true,
    ZyraPromotionExclusion exclusion = ZyraPromotionExclusion.none,
    DateTime? policyFirstSeen,
    int rollingImpressions = 0,
    bool shownThisSession = false,
  }) => ZyraPromotionRequest(
    roleContext: role,
    targetProduct: product,
    feature: feature,
    placement: placement,
    trigger: trigger,
    presentationIntent: intent,
    isEntitled: entitled,
    dependency: dependency,
    isOnboardingComplete: onboarding,
    hasSuccessfulValueMarker: valueMarker,
    isCalmLanding: calm,
    offerAvailable: available,
    exclusion: exclusion,
    history: ZyraPromotionPromptHistory(
      policyFirstSeen: policyFirstSeen ?? now.subtract(const Duration(days: 8)),
      notificationExplainers: 0,
      rollingUpgradeImpressions: rollingImpressions,
      proactiveShownThisSession: shownThisSession,
    ),
  );

  ZyraPromotionOffer offer({
    ZyraPromotionProduct product = ZyraPromotionProduct.notifications,
    ZyraPromotionRole role = ZyraPromotionRole.seeker,
    ZyraPromotionFeature feature = ZyraPromotionFeature.generalMembership,
    ZyraPromotionPlacement placement = ZyraPromotionPlacement.home,
  }) => ZyraPromotionOffer(
    product: product,
    role: role,
    feature: feature,
    placement: placement,
    trigger: ZyraPromotionTrigger.saveSucceeded,
  );

  test('launch, onboarding, auth and verification always suppress', () {
    for (final exclusion in const [
      ZyraPromotionExclusion.launch,
      ZyraPromotionExclusion.onboarding,
      ZyraPromotionExclusion.authentication,
      ZyraPromotionExclusion.verification,
    ]) {
      expect(
        engine.evaluate(request(exclusion: exclusion)).kind,
        ZyraPromotionDecisionKind.hidden,
      );
    }
    expect(
      engine.evaluate(request(onboarding: false)).reason,
      'onboarding_incomplete',
    );
  });

  test('every sensitive or interrupting state suppresses', () {
    for (final exclusion in ZyraPromotionExclusion.values.where(
      (value) => value != ZyraPromotionExclusion.none,
    )) {
      expect(
        engine.evaluate(request(exclusion: exclusion)).kind,
        ZyraPromotionDecisionKind.hidden,
        reason: exclusion.name,
      );
    }
  });

  test(
    'notification education stops after two explainers or OS denial',
    () async {
      engine.setDeveloperNotificationPermissionState(
        ZyraNotificationPermissionState.notDetermined,
      );
      await engine.markNotificationValueMoment(
        role: ZyraPromotionRole.seeker,
        trigger: ZyraPromotionTrigger.firstActiveJourney,
      );
      var decision = engine.decisionForSurface(
        role: ZyraPromotionRole.seeker,
        placement: ZyraPromotionPlacement.home,
        isCalmLanding: true,
        isEntitled: false,
        upgradeOfferAvailable: true,
      );
      expect(decision.kind, ZyraPromotionDecisionKind.notificationEducation);
      await engine.recordImpression(decision.offer!);
      await engine.dismiss(
        decision.offer!,
        dismissal: ZyraPromotionDismissal.notNow,
      );
      now = now.add(const Duration(days: 30));
      decision = engine.decisionForSurface(
        role: ZyraPromotionRole.seeker,
        placement: ZyraPromotionPlacement.home,
        isCalmLanding: true,
        isEntitled: false,
        upgradeOfferAvailable: true,
      );
      expect(decision.kind, ZyraPromotionDecisionKind.notificationEducation);
      await engine.recordImpression(decision.offer!);
      await engine.dismiss(
        decision.offer!,
        dismissal: ZyraPromotionDismissal.close,
      );
      expect(
        engine
            .decisionForSurface(
              role: ZyraPromotionRole.seeker,
              placement: ZyraPromotionPlacement.home,
              isCalmLanding: true,
              isEntitled: false,
              upgradeOfferAvailable: true,
            )
            .kind,
        ZyraPromotionDecisionKind.hidden,
      );

      SharedPreferences.setMockInitialValues({});
      await ZyraLocalPrefs.init();
      final denied = ZyraPromotionEngine(now: () => now);
      denied.setDeveloperNotificationPermissionState(
        ZyraNotificationPermissionState.denied,
      );
      expect(
        denied
            .evaluate(
              request(
                role: ZyraPromotionRole.guardian,
                product: ZyraPromotionProduct.notifications,
                feature: ZyraPromotionFeature.deviceNotifications,
                trigger: ZyraPromotionTrigger.firstSeekerLink,
                placement: ZyraPromotionPlacement.home,
              ),
            )
            .reason,
        'permission_final',
      );
    },
  );

  test(
    'unconnected native notifications render an honest disabled offer',
    () async {
      await engine.markNotificationValueMoment(
        role: ZyraPromotionRole.seeker,
        trigger: ZyraPromotionTrigger.firstActiveJourney,
      );
      final decision = engine.decisionForSurface(
        role: ZyraPromotionRole.seeker,
        placement: ZyraPromotionPlacement.home,
        isCalmLanding: true,
        isEntitled: false,
        upgradeOfferAvailable: true,
      );
      expect(decision.kind, ZyraPromotionDecisionKind.notificationEducation);
      expect(decision.offer!.dependency, ZyraPromotionDependency.notBuilt);
      expect(decision.offer!.actionLabel, 'Not connected yet');
    },
  );

  test('developer analytics accepts allowlist and rejects private fields', () {
    engine.recordDeveloperEventForTest('promotion_impression', const {
      'role_context': 'seeker',
      'target_product': 'zyra_one',
      'placement': 'home',
    });
    expect(engine.developerEvents, hasLength(1));
    expect(
      () => engine.recordDeveloperEventForTest('promotion_impression', const {
        'journey_id': 'private',
      }),
      throwsArgumentError,
    );
    expect(
      () => engine.recordDeveloperEventForTest('unknown_event', const {}),
      throwsArgumentError,
    );
  });

  test('sign-out clears persisted cadence and in-memory evidence', () async {
    engine.recordDeveloperEventForTest('promotion_impression', const {
      'role_context': 'seeker',
    });
    await engine.dismiss(offer(), dismissal: ZyraPromotionDismissal.dontShow);
    expect(ZyraLocalPrefs.promotionPolicy, isNotNull);
    await engine.clearForSignOut();
    expect(ZyraLocalPrefs.promotionPolicy, isNull);
    expect(engine.developerEvents, isEmpty);
  });
}
