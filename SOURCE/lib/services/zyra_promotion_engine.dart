// Notification education and compatibility entry points for retired promotions.
// Paid-only product direction, 2026-09-13: commercial campaigns are removed.
// Legacy product/argument identifiers remain callable while their screen owners
// migrate; they never create an offer, retain campaign state, or grant access.
// Only notification education preferences persist. Developer evidence remains
// local and allowlisted; there is no analytics SDK or production collection.

import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'zyra_developer_access.dart';
import 'zyra_local_prefs.dart';

enum ZyraPromotionRole { seeker, guardian }

enum ZyraPromotionProduct { notifications, zyraOne, guardianPlus }

enum ZyraPromotionFeature {
  deviceNotifications,
  generalMembership,
  guardianNetwork,
  planLimit,
  adFreeBrowsing,
  zyraIntelligence,
}

enum ZyraPromotionPlacement { home, profile, guardianNetwork, lockedFeature }

enum ZyraPromotionTrigger {
  firstActiveJourney,
  firstSeekerLink,
  saveSucceeded,
  considerSucceeded,
  mutualMatch,
  journeyStageCompleted,
  familyReviewSaved,
  guardianActionCompleted,
  manualPlanEntry,
  lockedFeatureTap,
  developerPreview,
}

enum ZyraPromotionIntent { proactive, lockedFeatureTap, manualPlanEntry }

enum ZyraPromotionDependency { ready, missing, serviceUnavailable, notBuilt }

/// Fixed, non-sensitive reason codes only. No safety cause, score, answer or
/// relationship identifier can enter the evaluator.
enum ZyraPromotionExclusion {
  none,
  launch,
  onboarding,
  authentication,
  recovery,
  verification,
  osPermission,
  anotherModal,
  keyboardCritical,
  safetyOrModeration,
  guardianChange,
  journeyDecision,
  familyDecision,
  compatibilityReveal,
  paymentFailure,
  safetyCooldown,
  journeyCooldown,
}

enum ZyraPromotionDecisionKind {
  hidden,
  inlineInvitation,
  lockedExplanation,
  notificationEducation,
  openPlanOnUserTap,
  openDeviceSettingsOnUserTap,
}

enum ZyraNotificationPermissionState {
  unavailable,
  notDetermined,
  enabled,
  denied,
  restricted,
}

enum ZyraPromotionDismissal { close, notNow, notInterested, dontShow }

/// Developer-only Guardian Network access matrix. Production access is always
/// resolved from live link and entitlement services; this value is never
/// persisted and cannot change either source of truth.
enum ZyraDeveloperGuardianNetworkState {
  d14Preview,
  unlinkedBasic,
  linkedBasic,
  unlinkedEntitled,
  linkedEntitledUnavailable,
}

@immutable
class ZyraPromotionOffer {
  final ZyraPromotionProduct product;
  final ZyraPromotionRole role;
  final ZyraPromotionPlacement placement;
  final ZyraPromotionFeature feature;
  final ZyraPromotionTrigger trigger;
  final ZyraPromotionDependency dependency;
  final bool developerPreview;

  const ZyraPromotionOffer({
    required this.product,
    required this.role,
    required this.placement,
    required this.feature,
    required this.trigger,
    this.dependency = ZyraPromotionDependency.ready,
    this.developerPreview = false,
  });

  String get targetProduct => switch (product) {
    ZyraPromotionProduct.notifications => 'notifications',
    ZyraPromotionProduct.zyraOne => 'zyra_one',
    ZyraPromotionProduct.guardianPlus => 'guardian_plus',
  };

  String get title => switch (product) {
    ZyraPromotionProduct.notifications =>
      role == ZyraPromotionRole.seeker
          ? 'Stay close to your Journey'
          : 'Stay close to the people you support',
    ZyraPromotionProduct.zyraOne || ZyraPromotionProduct.guardianPlus => '',
  };

  String get message => switch (product) {
    ZyraPromotionProduct.notifications =>
      dependency != ZyraPromotionDependency.ready
          ? 'Device alerts are not connected in this build yet. Updates in My ZYRA still work.'
          : role == ZyraPromotionRole.seeker
          ? 'Turn on notifications for replies and decisions that need you. You can change this any time.'
          : 'Turn on notifications for requests and Journey decisions that need you. You can change this any time.',
    ZyraPromotionProduct.zyraOne || ZyraPromotionProduct.guardianPlus => '',
  };

  String get actionLabel => switch (product) {
    ZyraPromotionProduct.notifications =>
      dependency == ZyraPromotionDependency.ready
          ? 'Enable notifications'
          : 'Not connected yet',
    ZyraPromotionProduct.zyraOne || ZyraPromotionProduct.guardianPlus => '',
  };
}

@immutable
class ZyraPromotionPromptHistory {
  final DateTime policyFirstSeen;
  final int notificationExplainers;
  final int rollingUpgradeImpressions;
  final bool proactiveShownThisSession;

  const ZyraPromotionPromptHistory({
    required this.policyFirstSeen,
    required this.notificationExplainers,
    required this.rollingUpgradeImpressions,
    required this.proactiveShownThisSession,
  });
}

@immutable
class ZyraPromotionRequest {
  final ZyraPromotionRole roleContext;
  final ZyraPromotionProduct targetProduct;
  final ZyraPromotionFeature feature;
  final ZyraPromotionPlacement placement;
  final ZyraPromotionTrigger trigger;
  final ZyraPromotionIntent presentationIntent;
  final bool isEntitled;
  final ZyraPromotionDependency dependency;
  final bool isOnboardingComplete;
  final bool hasSuccessfulValueMarker;
  final bool isCalmLanding;
  final bool offerAvailable;
  final ZyraPromotionExclusion exclusion;
  final ZyraPromotionPromptHistory history;

  const ZyraPromotionRequest({
    required this.roleContext,
    required this.targetProduct,
    required this.feature,
    required this.placement,
    required this.trigger,
    required this.presentationIntent,
    required this.isEntitled,
    required this.dependency,
    required this.isOnboardingComplete,
    required this.hasSuccessfulValueMarker,
    required this.isCalmLanding,
    required this.offerAvailable,
    required this.exclusion,
    required this.history,
  });
}

@immutable
class ZyraPromotionDecision {
  final ZyraPromotionDecisionKind kind;
  final String reason;
  final ZyraPromotionOffer? offer;

  const ZyraPromotionDecision._(this.kind, this.reason, [this.offer]);

  const ZyraPromotionDecision.hidden(String reason)
    : this._(ZyraPromotionDecisionKind.hidden, reason);

  const ZyraPromotionDecision.show(
    ZyraPromotionDecisionKind kind,
    ZyraPromotionOffer offer,
  ) : this._(kind, 'eligible', offer);
}

@immutable
class ZyraPromotionAnalyticsEvent {
  final String name;
  final DateTime occurredAt;
  final Map<String, String> attributes;

  const ZyraPromotionAnalyticsEvent({
    required this.name,
    required this.occurredAt,
    required this.attributes,
  });
}

class ZyraPromotionEngine extends ChangeNotifier {
  ZyraPromotionEngine({DateTime Function()? now}) : _now = now ?? DateTime.now;

  static final ZyraPromotionEngine instance = ZyraPromotionEngine();

  static const policyVersion = '2026-09-13-notifications-only';
  static const notificationCooldown = Duration(days: 30);
  static const notificationLifetimeLimit = 2;
  final DateTime Function() _now;
  bool _initialized = false;
  int _accountEpoch = 0;
  DateTime? _policyStartedAt;

  bool _notificationPending = false;
  ZyraPromotionRole? _notificationRole;
  ZyraPromotionTrigger _notificationTrigger =
      ZyraPromotionTrigger.firstActiveJourney;
  int _notificationImpressions = 0;
  DateTime? _notificationCooldownUntil;
  bool _notificationNeverAsk = false;

  ZyraPromotionOffer? _developerOffer;
  ZyraDeveloperGuardianNetworkState _developerGuardianNetworkState =
      ZyraDeveloperGuardianNetworkState.d14Preview;
  ZyraNotificationPermissionState _permissionState =
      ZyraNotificationPermissionState.unavailable;

  final List<ZyraPromotionAnalyticsEvent> _events = [];
  final Set<String> _decisionEvidence = {};
  List<ZyraPromotionAnalyticsEvent> get developerEvents =>
      List.unmodifiable(_events);
  ZyraNotificationPermissionState get permissionState => _permissionState;
  ZyraDeveloperGuardianNetworkState get developerGuardianNetworkState =>
      _developerGuardianNetworkState;

  Future<void> initialize() async {
    if (_initialized) return;
    final epoch = _accountEpoch;
    _resetMemory(keepEvents: true);
    final raw = ZyraLocalPrefs.promotionPolicy;
    if (raw != null) {
      try {
        _hydrate(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (error) {
        debugPrint(
          'ZYRA promotion policy could not be read; starting clean.\n$error',
        );
      }
    }
    _policyStartedAt ??= _now().toUtc();
    _initialized = true;
    await _persist();
    if (epoch != _accountEpoch) return;
    notifyListeners();
  }

  /// Synchronous principal boundary: drop memory before any disk cleanup.
  /// This never persists old policy into the newly bound account.
  void resetForAccountChange() {
    _accountEpoch++;
    _resetMemory(keepEvents: false);
    _initialized = false;
    notifyListeners();
  }

  Future<void> clearForSignOut() async {
    resetForAccountChange();
    await ZyraLocalPrefs.clearPromotionPolicy();
  }

  Future<void> clearForAccountSwitch() => clearForSignOut();

  Future<void> markNotificationValueMoment({
    required ZyraPromotionRole role,
    required ZyraPromotionTrigger trigger,
  }) async {
    final epoch = _accountEpoch;
    if (_notificationNeverAsk ||
        _notificationImpressions >= notificationLifetimeLimit) {
      return;
    }
    _notificationPending = true;
    _notificationRole = role;
    _notificationTrigger = trigger;
    await _persist();
    if (epoch != _accountEpoch) return;
    notifyListeners();
  }

  /// Compatibility entry point; commercial value moments are retired.
  Future<void> markUpgradeValueMoment({
    required ZyraPromotionRole role,
    required ZyraPromotionProduct product,
    required ZyraPromotionPlacement placement,
    required ZyraPromotionFeature feature,
    required ZyraPromotionTrigger trigger,
  }) async {}

  ZyraPromotionPromptHistory get promptHistory => ZyraPromotionPromptHistory(
    policyFirstSeen: _policyStartedAt ?? _now().toUtc(),
    notificationExplainers: _notificationImpressions,
    rollingUpgradeImpressions: 0,
    proactiveShownThisSession: false,
  );

  /// The single screen-facing entry. It assembles the current prompt-history
  /// snapshot and routes notification education through [evaluate].
  ZyraPromotionDecision decisionForSurface({
    required ZyraPromotionRole role,
    required ZyraPromotionPlacement placement,
    required bool isCalmLanding,
    required bool isEntitled,
    required bool upgradeOfferAvailable,
    ZyraPromotionExclusion exclusion = ZyraPromotionExclusion.none,
  }) {
    final forced = _developerOffer;
    if (forced != null &&
        forced.product == ZyraPromotionProduct.notifications &&
        forced.role == role &&
        isCalmLanding &&
        exclusion == ZyraPromotionExclusion.none) {
      return ZyraPromotionDecision.show(
        ZyraPromotionDecisionKind.notificationEducation,
        forced,
      );
    }

    if (_notificationPending && _notificationRole == role) {
      final notificationRequest = ZyraPromotionRequest(
        roleContext: role,
        targetProduct: ZyraPromotionProduct.notifications,
        feature: ZyraPromotionFeature.deviceNotifications,
        placement: placement,
        trigger: _notificationTrigger,
        presentationIntent: ZyraPromotionIntent.proactive,
        isEntitled: _permissionState == ZyraNotificationPermissionState.enabled,
        dependency:
            _permissionState == ZyraNotificationPermissionState.unavailable
            ? ZyraPromotionDependency.notBuilt
            : ZyraPromotionDependency.ready,
        isOnboardingComplete: true,
        hasSuccessfulValueMarker: true,
        isCalmLanding: isCalmLanding,
        offerAvailable: true,
        exclusion: exclusion,
        history: promptHistory,
      );
      final notificationDecision = _recordDecision(
        notificationRequest,
        evaluate(notificationRequest),
      );
      if (notificationDecision.kind != ZyraPromotionDecisionKind.hidden) {
        return notificationDecision;
      }
    }

    return const ZyraPromotionDecision.hidden('no_notification_candidate');
  }

  /// Compatibility boundary for older locked-feature callers. Commercial
  /// requests are hidden; feature owners render their own availability state.
  ZyraPromotionDecision decisionForLockedFeature({
    required ZyraPromotionRole role,
    required ZyraPromotionProduct product,
    required ZyraPromotionFeature feature,
    required ZyraPromotionPlacement placement,
    required bool isEntitled,
    ZyraPromotionDependency dependency = ZyraPromotionDependency.ready,
  }) {
    final request = ZyraPromotionRequest(
      roleContext: role,
      targetProduct: product,
      feature: feature,
      placement: placement,
      trigger: ZyraPromotionTrigger.lockedFeatureTap,
      presentationIntent: ZyraPromotionIntent.lockedFeatureTap,
      isEntitled: isEntitled,
      dependency: dependency,
      isOnboardingComplete: true,
      hasSuccessfulValueMarker: true,
      isCalmLanding: true,
      offerAvailable: true,
      exclusion: ZyraPromotionExclusion.none,
      history: promptHistory,
    );
    return _recordDecision(request, evaluate(request));
  }

  /// Notification requests obey the stored permission/education preferences.
  /// Every commercial request is refused before a display intent is evaluated.
  ZyraPromotionDecision evaluate(ZyraPromotionRequest request) {
    if (request.targetProduct != ZyraPromotionProduct.notifications) {
      return const ZyraPromotionDecision.hidden(
        'commercial_promotions_retired',
      );
    }
    if (request.exclusion != ZyraPromotionExclusion.none) {
      return ZyraPromotionDecision.hidden('excluded_${request.exclusion.name}');
    }
    if (!request.isOnboardingComplete) {
      return const ZyraPromotionDecision.hidden('onboarding_incomplete');
    }
    if (!request.isCalmLanding) {
      return const ZyraPromotionDecision.hidden('not_calm_landing');
    }
    if (!request.hasSuccessfulValueMarker) {
      return const ZyraPromotionDecision.hidden('no_successful_value_marker');
    }
    if (request.isEntitled ||
        _permissionState == ZyraNotificationPermissionState.enabled) {
      _notificationPending = false;
      unawaited(_persist());
      return const ZyraPromotionDecision.hidden('permission_enabled');
    }
    if (_permissionState == ZyraNotificationPermissionState.denied ||
        _permissionState == ZyraNotificationPermissionState.restricted) {
      _notificationPending = false;
      _notificationNeverAsk = true;
      unawaited(_persist());
      return const ZyraPromotionDecision.hidden('permission_final');
    }
    final cooling =
        _notificationCooldownUntil?.isAfter(_now().toUtc()) ?? false;
    if (cooling ||
        _notificationNeverAsk ||
        _notificationImpressions >= notificationLifetimeLimit) {
      return const ZyraPromotionDecision.hidden('notification_cooldown');
    }
    return ZyraPromotionDecision.show(
      ZyraPromotionDecisionKind.notificationEducation,
      _offerFrom(request),
    );
  }

  ZyraPromotionOffer _offerFrom(ZyraPromotionRequest request) =>
      ZyraPromotionOffer(
        product: request.targetProduct,
        role: request.roleContext,
        placement: request.placement,
        feature: request.feature,
        trigger: request.trigger,
        dependency: request.dependency,
      );

  Future<void> recordImpression(ZyraPromotionOffer offer) async {
    if (offer.product != ZyraPromotionProduct.notifications) return;
    _track('notification_education_shown', offer);
    if (offer.developerPreview) return;
    _notificationImpressions++;
    await _persist();
  }

  Future<void> dismiss(
    ZyraPromotionOffer offer, {
    required ZyraPromotionDismissal dismissal,
  }) async {
    final epoch = _accountEpoch;
    if (offer.product != ZyraPromotionProduct.notifications) return;
    _track('notification_education_dismissed', offer, {
      'outcome': dismissal.name,
    });
    if (offer.developerPreview) {
      _developerOffer = null;
      notifyListeners();
      return;
    }
    if (dismissal == ZyraPromotionDismissal.dontShow ||
        _notificationImpressions >= notificationLifetimeLimit) {
      _notificationNeverAsk = true;
      _notificationPending = false;
    } else {
      _notificationCooldownUntil = _now().toUtc().add(notificationCooldown);
    }
    await _persist();
    if (epoch != _accountEpoch) return;
    notifyListeners();
  }

  Future<void> recordOpened(ZyraPromotionOffer offer) async {
    final epoch = _accountEpoch;
    if (offer.product != ZyraPromotionProduct.notifications) return;
    _track('notification_permission_requested', offer);
    await _persist();
    if (epoch != _accountEpoch) return;
    notifyListeners();
  }

  Future<ZyraNotificationPermissionState> requestNotificationPermission(
    ZyraPromotionOffer offer,
  ) async {
    final epoch = _accountEpoch;
    // The production gateway remains unavailable until APNs/FCM and token
    // registration are built. Developer preview simulates the real positive
    // transition so the complete UI can be rehearsed without lying in release.
    if (offer.product != ZyraPromotionProduct.notifications ||
        !offer.developerPreview ||
        !ZyraDeveloperAccess.canUseDeveloperTools) {
      return ZyraNotificationPermissionState.unavailable;
    }
    _permissionState = ZyraNotificationPermissionState.enabled;
    _notificationPending = false;
    _developerOffer = null;
    _track('notification_permission_result', offer, {'outcome': 'enabled'});
    await _persist();
    if (epoch != _accountEpoch) {
      return ZyraNotificationPermissionState.unavailable;
    }
    notifyListeners();
    return _permissionState;
  }

  /// Retained for older callers; commercial suggestions cannot be re-enabled.
  Future<void> setUpgradeSuggestionsEnabled(
    ZyraPromotionProduct product,
    bool enabled,
  ) async {}

  bool upgradeSuggestionsEnabled(ZyraPromotionProduct product) => false;

  Future<void> recordUpgradeScreenViewed({
    required ZyraPromotionRole role,
    required ZyraPromotionProduct product,
    required ZyraPromotionPlacement placement,
  }) async {
    _trackName('upgrade_screen_viewed', {
      'role_context': role.name,
      'target_product': product == ZyraPromotionProduct.zyraOne
          ? 'zyra_one'
          : 'guardian_plus',
      'placement': placement.name,
    });
  }

  void recordLockedFeature({
    required bool ctaTapped,
    required ZyraPromotionRole role,
    required ZyraPromotionProduct product,
    required ZyraPromotionFeature feature,
    required ZyraPromotionPlacement placement,
  }) {
    _trackName(
      ctaTapped ? 'locked_feature_cta_tapped' : 'locked_feature_viewed',
      {
        'role_context': role.name,
        'target_product': product == ZyraPromotionProduct.zyraOne
            ? 'zyra_one'
            : 'guardian_plus',
        'feature_key': feature.name,
        'placement': placement.name,
      },
    );
  }

  void recordPreferenceChanged({
    required ZyraPromotionRole role,
    required String categoryCode,
    required bool marketing,
    required bool enabled,
  }) {
    _trackName(
      marketing
          ? 'marketing_consent_changed'
          : 'notification_preference_changed',
      {
        'role_context': role.name,
        'feature_key': categoryCode,
        'outcome': enabled ? 'enabled' : 'disabled',
      },
    );
  }

  @visibleForTesting
  void recordDeveloperEventForTest(
    String name,
    Map<String, String> attributes,
  ) => _trackName(name, attributes);

  Future<void> recordPurchaseResult({
    required ZyraPromotionRole role,
    required ZyraPromotionProduct product,
    required bool success,
  }) async {
    _trackName(success ? 'purchase_succeeded' : 'purchase_failed', {
      'role_context': role.name,
      'target_product': product == ZyraPromotionProduct.zyraOne
          ? 'zyra_one'
          : 'guardian_plus',
      'outcome': success ? 'success' : 'failure',
    });
  }

  void recordCheckoutStarted({
    required ZyraPromotionRole role,
    required ZyraPromotionProduct product,
    required ZyraPromotionPlacement placement,
  }) {
    _trackName('checkout_started', {
      'role_context': role.name,
      'target_product': product == ZyraPromotionProduct.zyraOne
          ? 'zyra_one'
          : 'guardian_plus',
      'placement': placement.name,
    });
  }

  Future<void> notePlanLapse() async {}

  void showDeveloperPreview({
    required ZyraPromotionProduct product,
    required ZyraPromotionRole role,
    ZyraPromotionPlacement placement = ZyraPromotionPlacement.home,
  }) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return;
    if (product != ZyraPromotionProduct.notifications) return;
    _permissionState = ZyraNotificationPermissionState.notDetermined;
    _developerOffer = ZyraPromotionOffer(
      product: product,
      role: role,
      placement: placement,
      feature: ZyraPromotionFeature.deviceNotifications,
      trigger: ZyraPromotionTrigger.developerPreview,
      developerPreview: true,
    );
    notifyListeners();
  }

  void setDeveloperGuardianNetworkState(
    ZyraDeveloperGuardianNetworkState state,
  ) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return;
    _developerGuardianNetworkState = state;
    notifyListeners();
  }

  /// Test/developer seam for the OS state. Production will replace this with
  /// the platform permission gateway under OA-ZYRA-254.
  void setDeveloperNotificationPermissionState(
    ZyraNotificationPermissionState state,
  ) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return;
    _permissionState = state;
    notifyListeners();
  }

  Future<void> resetDeveloperPolicy() async {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return;
    final epoch = _accountEpoch;
    await ZyraLocalPrefs.clearPromotionPolicy();
    if (epoch != _accountEpoch) return;
    _resetMemory(keepEvents: false);
    _policyStartedAt = _now().toUtc();
    _initialized = true;
    await _persist();
    if (epoch != _accountEpoch) return;
    notifyListeners();
  }

  void _hydrate(Map<String, dynamic> json) {
    _policyStartedAt = _date(json['policy_started_at']);
    _notificationPending = json['notification_pending'] == true;
    _notificationRole = _role(json['notification_role']);
    _notificationTrigger =
        _trigger(json['notification_trigger']) ??
        ZyraPromotionTrigger.firstActiveJourney;
    _notificationImpressions =
        (json['notification_impressions'] as num?)?.toInt() ?? 0;
    _notificationCooldownUntil = _date(json['notification_cooldown_until']);
    _notificationNeverAsk = json['notification_never_ask'] == true;
    _permissionState =
        _permission(json['notification_permission_state']) ??
        ZyraNotificationPermissionState.unavailable;
    // Legacy commercial campaign fields are intentionally ignored.
  }

  Future<void> _persist() async {
    if (!_initialized) return;
    final json = <String, dynamic>{
      'policy_version': policyVersion,
      'policy_started_at': _policyStartedAt?.toIso8601String(),
      'notification_pending': _notificationPending,
      'notification_role': _notificationRole?.name,
      'notification_trigger': _notificationTrigger.name,
      'notification_impressions': _notificationImpressions,
      'notification_cooldown_until': _notificationCooldownUntil
          ?.toIso8601String(),
      'notification_never_ask': _notificationNeverAsk,
      'notification_permission_state': _permissionState.name,
    };
    try {
      await ZyraLocalPrefs.setPromotionPolicy(jsonEncode(json));
    } catch (error) {
      debugPrint('ZYRA promotion policy could not be saved.\n$error');
    }
  }

  void _resetMemory({required bool keepEvents}) {
    _policyStartedAt = null;
    _notificationPending = false;
    _notificationRole = null;
    _notificationTrigger = ZyraPromotionTrigger.firstActiveJourney;
    _notificationImpressions = 0;
    _notificationCooldownUntil = null;
    _notificationNeverAsk = false;
    _developerOffer = null;
    _developerGuardianNetworkState =
        ZyraDeveloperGuardianNetworkState.d14Preview;
    _permissionState = ZyraNotificationPermissionState.unavailable;
    _decisionEvidence.clear();
    if (!keepEvents) _events.clear();
  }

  ZyraPromotionDecision _recordDecision(
    ZyraPromotionRequest request,
    ZyraPromotionDecision decision,
  ) {
    // A protection/safety hold is deliberately invisible to analytics.
    if (request.exclusion == ZyraPromotionExclusion.safetyOrModeration ||
        request.exclusion == ZyraPromotionExclusion.safetyCooldown) {
      return decision;
    }
    final key = <String>[
      request.roleContext.name,
      request.targetProduct.name,
      request.feature.name,
      request.placement.name,
      decision.kind.name,
      decision.reason,
    ].join('/');
    if (!_decisionEvidence.add(key)) return decision;
    final attributes = <String, String>{
      'role_context': request.roleContext.name,
      'target_product': request.targetProduct.name,
      'feature_key': request.feature.name,
      'placement': request.placement.name,
      'trigger': request.trigger.name,
      'presentation': request.presentationIntent.name,
      'outcome': decision.kind.name,
    };
    _trackName('promotion_evaluated', attributes);
    if (decision.kind == ZyraPromotionDecisionKind.hidden) {
      _trackName('promotion_suppressed', {
        ...attributes,
        'suppression_reason': decision.reason,
      });
    }
    return decision;
  }

  void _track(
    String name,
    ZyraPromotionOffer offer, [
    Map<String, String> extra = const {},
  ]) {
    _trackName(name, {
      'role_context': offer.role.name,
      'target_product': offer.targetProduct,
      'feature_key': offer.feature.name,
      'placement': offer.placement.name,
      'trigger': offer.trigger.name,
      'presentation': 'bottom_nav_pill',
      ...extra,
    });
  }

  void _trackName(String name, Map<String, String> attributes) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return;
    if (!_allowedEventNames.contains(name)) {
      throw ArgumentError.value(name, 'name', 'Not in the governed taxonomy');
    }
    final invalid = attributes.keys.where(
      (key) => !_allowedAttributes.contains(key),
    );
    if (invalid.isNotEmpty) {
      throw ArgumentError.value(
        invalid.join(', '),
        'attributes',
        'Attribute is outside the governed analytics allowlist',
      );
    }
    _events.add(
      ZyraPromotionAnalyticsEvent(
        name: name,
        occurredAt: _now().toUtc(),
        attributes: {'policy_version': policyVersion, ...attributes},
      ),
    );
    if (_events.length > 200) _events.removeAt(0);
  }

  static const Set<String> _allowedEventNames = {
    'promotion_evaluated',
    'promotion_suppressed',
    'promotion_impression',
    'promotion_opened',
    'promotion_dismissed',
    'promotion_declined',
    'locked_feature_viewed',
    'locked_feature_cta_tapped',
    'upgrade_screen_viewed',
    'checkout_started',
    'purchase_succeeded',
    'purchase_failed',
    'purchase_restored',
    'notification_education_shown',
    'notification_education_dismissed',
    'notification_permission_requested',
    'notification_permission_result',
    'notification_device_settings_opened',
    'notification_preference_changed',
    'marketing_consent_changed',
  };

  static const Set<String> _allowedAttributes = {
    'policy_version',
    'role_context',
    'target_product',
    'feature_key',
    'placement',
    'trigger',
    'presentation',
    'outcome',
    'suppression_reason',
    'permission_state',
    'platform',
    'app_version',
  };

  static DateTime? _date(dynamic value) =>
      value is String ? DateTime.tryParse(value)?.toUtc() : null;

  static ZyraPromotionRole? _role(dynamic value) {
    for (final role in ZyraPromotionRole.values) {
      if (role.name == value) return role;
    }
    return null;
  }

  static ZyraPromotionTrigger? _trigger(dynamic value) {
    for (final trigger in ZyraPromotionTrigger.values) {
      if (trigger.name == value) return trigger;
    }
    return null;
  }

  static ZyraNotificationPermissionState? _permission(dynamic value) {
    for (final state in ZyraNotificationPermissionState.values) {
      if (state.name == value) return state;
    }
    return null;
  }
}
