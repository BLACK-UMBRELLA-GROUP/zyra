import '../state/app_state.dart' show ZyraPlan;
import 'zyra_seeker_basic_policy.dart';

/// Founder-approved client membership policy. These are capacity/display
/// rules, not backend authorisation, purchase proof or data-retention rules.
/// Downgrading never deletes profiles, Journeys or accepted Guardian links.
class ZyraSeekerPlanLimits {
  final int savedProfiles;
  final int? activeConsiders;
  final int? dailyConsiders;
  final int recentDeclinedProfiles;
  final int linkedGuardians;

  const ZyraSeekerPlanLimits({
    required this.savedProfiles,
    required this.activeConsiders,
    required this.dailyConsiders,
    required this.recentDeclinedProfiles,
    required this.linkedGuardians,
  });

  static const oneSavedProfiles = 50;
  static const basic = ZyraSeekerPlanLimits(
    savedProfiles: ZyraSeekerBasicPolicy.totalSaveLimit,
    activeConsiders: ZyraSeekerBasicPolicy.totalConsiderLimit,
    dailyConsiders: ZyraSeekerBasicPolicy.dailyConsiderLimit,
    recentDeclinedProfiles: 0,
    linkedGuardians: 1,
  );
  static const one = ZyraSeekerPlanLimits(
    savedProfiles: oneSavedProfiles,
    activeConsiders: null,
    dailyConsiders: null,
    recentDeclinedProfiles: 10,
    linkedGuardians: 10,
  );

  static ZyraSeekerPlanLimits of(ZyraPlan plan) =>
      plan == ZyraPlan.one ? one : basic;

  bool canSave({required int currentCount, bool alreadySaved = false}) =>
      alreadySaved || (currentCount >= 0 && currentCount < savedProfiles);

  bool canConsider({
    required int currentCount,
    bool alreadyConsidered = false,
  }) =>
      alreadyConsidered ||
      (currentCount >= 0 &&
          (activeConsiders == null || currentCount < activeConsiders!));

  /// Main counts as one of the accepted links. Pending requests are not links.
  static bool canAddGuardian({
    required ZyraPlan plan,
    required int linkedGuardianCount,
  }) =>
      linkedGuardianCount >= 0 &&
      linkedGuardianCount < of(plan).linkedGuardians;

  /// AppState.declined is the profile decision/Passed list, not declined
  /// Journey requests. Hydration and local Pass both keep newest first.
  /// Return a display copy without mutating the source.
  List<T> recentDeclined<T>(List<T> profiles) =>
      List<T>.unmodifiable(profiles.take(recentDeclinedProfiles));
}
