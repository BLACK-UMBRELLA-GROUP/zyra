import '../state/app_state.dart';
import 'zyra_seeker_plan_limits.dart';

enum ZyraGuardianCapacityStatus {
  available,
  atLimit,
  basicPlaceUsed,
  unavailable,
}

/// Client preflight for active, accepted Guardian links. Unknown plans are
/// kept unknown. Existing links remain in place on a membership change.
class ZyraGuardianCapacity {
  final ZyraPlan plan;
  final int? linkedGuardianCount;
  final bool? basicPlaceUsed;
  final ZyraGuardianCapacityStatus status;

  const ZyraGuardianCapacity._(
    this.plan,
    this.linkedGuardianCount,
    this.basicPlaceUsed,
    this.status,
  );

  factory ZyraGuardianCapacity.fromCount({
    required ZyraPlan plan,
    required int? linkedGuardianCount,
    int? linkedBasicGuardianCount,
    ZyraPlan? incomingGuardianPlan,
  }) {
    final total = linkedGuardianCount;
    final basic = linkedBasicGuardianCount ?? (total == 0 ? 0 : null);
    final basicUsed = basic == null
        ? null
        : basic >= ZyraSeekerPlanLimits.basicGuardianPlaces;
    final status = switch (total) {
      null || < 0 => ZyraGuardianCapacityStatus.unavailable,
      >= ZyraSeekerPlanLimits.maxLinkedGuardians =>
        ZyraGuardianCapacityStatus.atLimit,
      _ when basic != null && (basic < 0 || basic > total) =>
        ZyraGuardianCapacityStatus.unavailable,
      _
          when plan == ZyraPlan.one ||
              incomingGuardianPlan == ZyraPlan.one ||
              basicUsed == false =>
        ZyraGuardianCapacityStatus.available,
      _ when basicUsed == true && incomingGuardianPlan == ZyraPlan.basic =>
        ZyraGuardianCapacityStatus.basicPlaceUsed,
      _ => ZyraGuardianCapacityStatus.unavailable,
    };
    return ZyraGuardianCapacity._(plan, total, basicUsed, status);
  }

  int get guardianOnePlaces =>
      (ZyraSeekerPlanLimits.maxLinkedGuardians -
              (linkedGuardianCount ?? 0) -
              (plan == ZyraPlan.basic && basicPlaceUsed == false ? 1 : 0))
          .clamp(0, ZyraSeekerPlanLimits.maxLinkedGuardians);

  bool get canAdd => status == ZyraGuardianCapacityStatus.available;

  static const basicLimitMessage =
      'Your Guardian Basic place is used, so new Guardians need Guardian One.';
  static const totalLimitMessage =
      'You can link up to ${ZyraSeekerPlanLimits.maxLinkedGuardians} Guardians. '
      'Your existing Guardians stay linked. Remove a link before adding another.';
  static const unavailableMessage =
      'Your linked Guardians could not be checked. Please try again before '
      'adding another.';

  String? get message => switch (status) {
    ZyraGuardianCapacityStatus.available => null,
    ZyraGuardianCapacityStatus.unavailable => unavailableMessage,
    ZyraGuardianCapacityStatus.atLimit => totalLimitMessage,
    ZyraGuardianCapacityStatus.basicPlaceUsed => basicLimitMessage,
  };

  static bool isCapacityMessage(String? message) =>
      message == basicLimitMessage ||
      message == totalLimitMessage ||
      message == unavailableMessage;
}
