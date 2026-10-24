import '../state/app_state.dart';
import 'zyra_membership_catalog.dart';
import 'zyra_seeker_plan_limits.dart';

enum ZyraGuardianCapacityStatus { available, atLimit, unavailable }

/// Client presentation guard for a Seeker's active, accepted Guardian links.
/// It never revokes a link on downgrade and is not atomic server enforcement.
class ZyraGuardianCapacity {
  final ZyraPlan plan;
  final int? linkedGuardianCount;
  final ZyraGuardianCapacityStatus status;

  const ZyraGuardianCapacity._(
    this.plan,
    this.linkedGuardianCount,
    this.status,
  );

  factory ZyraGuardianCapacity.fromCount({
    required ZyraPlan plan,
    required int? linkedGuardianCount,
  }) => ZyraGuardianCapacity._(
    plan,
    linkedGuardianCount,
    linkedGuardianCount == null || linkedGuardianCount < 0
        ? ZyraGuardianCapacityStatus.unavailable
        : ZyraSeekerPlanLimits.canAddGuardian(
            plan: plan,
            linkedGuardianCount: linkedGuardianCount,
          )
        ? ZyraGuardianCapacityStatus.available
        : ZyraGuardianCapacityStatus.atLimit,
  );

  bool get canAdd => status == ZyraGuardianCapacityStatus.available;
  bool get canUpgrade =>
      status == ZyraGuardianCapacityStatus.atLimit && plan == ZyraPlan.basic;

  static String get basicLimitMessage =>
      'Your current access allows ${ZyraSeekerPlanLimits.basic.linkedGuardians} '
      'linked Guardian${ZyraSeekerPlanLimits.basic.linkedGuardians == 1 ? '' : 's'}. '
      'View ${ZyraMembershipCatalog.seekerOneTitle} for up to ${ZyraSeekerPlanLimits.one.linkedGuardians}. '
      'Your existing Guardians stay linked.';
  static String get oneLimitMessage =>
      '${ZyraMembershipCatalog.seekerOneTitle} includes up to ${ZyraSeekerPlanLimits.one.linkedGuardians} '
      'linked Guardians. Your existing Guardians '
      'stay linked. Remove a link before adding another.';
  static const unavailableMessage =
      'Your linked Guardians could not be checked. Please try again before '
      'adding another.';

  String? get message => switch (status) {
    ZyraGuardianCapacityStatus.available => null,
    ZyraGuardianCapacityStatus.unavailable => unavailableMessage,
    ZyraGuardianCapacityStatus.atLimit =>
      plan == ZyraPlan.basic ? basicLimitMessage : oneLimitMessage,
  };

  static bool isCapacityMessage(String? message) =>
      message == basicLimitMessage ||
      message == oneLimitMessage ||
      message == unavailableMessage;
}
