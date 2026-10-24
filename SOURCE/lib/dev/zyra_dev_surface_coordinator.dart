// Page-context bridge for the app-wide developer overlay.
//
// Kept separate from the overlay widget so entry points such as test sign-up
// can temporarily identify themselves as entry/onboarding flows without
// importing the panel that launches them (and creating an import cycle).

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../services/zyra_developer_access.dart';
import '../widgets/zyra_onboarding_study.dart';
import 'dev_role_choice_design.dart';
import 'zyra_dev_scenario.dart';

enum ZyraDevSurface { entry, seeker, guardian }

/// Callbacks belong to the current sample route, never an account ledger.
@immutable
class ZyraCompatibilityDevControls {
  const ZyraCompatibilityDevControls({
    required this.profileId,
    required this.isCurrent,
    required this.balance,
    required this.setBalance,
  });

  final String profileId;
  final bool Function() isCurrent;
  final int Function(bool plus) balance;
  final void Function(bool plus, int count) setBalance;
}

class _SeekerSurfaceRegistration {
  const _SeekerSurfaceRegistration({
    required this.onOpen,
    this.onOpenConnectionsSection,
    this.onOpenIntroductions,
  });

  final ValueChanged<DevPage> onOpen;
  final ValueChanged<int>? onOpenConnectionsSection;
  final VoidCallback? onOpenIntroductions;
}

class _OnboardingRegistration {
  const _OnboardingRegistration({
    required this.restart,
    this.onClose,
    this.isCurrent,
  });

  final ValueChanged<ZyraOnboardingDirection> restart;
  final VoidCallback? onClose;
  final bool Function()? isCurrent;
}

/// Connects the single app-wide developer overlay to the live product shell.
/// This stores callbacks only; no user, entitlement, or product state lives
/// here.
class ZyraDevSurfaceCoordinator extends ChangeNotifier {
  ZyraDevSurfaceCoordinator._();

  static final ZyraDevSurfaceCoordinator instance =
      ZyraDevSurfaceCoordinator._();

  // A nested signup rehearsal can reach another HomeShell while the invoking
  // shell is still mounted underneath it. Register all mounted owners in
  // attachment order so disposing the nested shell restores its predecessor.
  // Identity keys also let an original shell detach while it is covered;
  // closing a preview must never resurrect a disposed owner's callbacks.
  final _seekerOwners =
      LinkedHashMap<Object, _SeekerSurfaceRegistration>.identity();
  final _guardianOwners =
      LinkedHashMap<Object, ValueChanged<WaliPage>>.identity();
  final _compatibilityOwners =
      LinkedHashMap<Object, ZyraCompatibilityDevControls>.identity();
  bool _compatibilityNotificationScheduled = false;
  int _compatibilityNotificationEpoch = 0;
  String? _entryOverride;
  final Set<Object> _developerLandingOwners = {};
  final _onboardingOwners =
      LinkedHashMap<Object, _OnboardingRegistration>.identity();
  final _roleChoiceOwners = LinkedHashMap<Object, bool Function()>.identity();
  int _roleChoiceRevision = 0;

  /// The role-design selector belongs only to the visible role-choice route.
  /// A covered route may stay mounted in the nested onboarding Navigator,
  /// but its old menu callback cannot change another page's selection.
  void attachRoleChoice(Object owner, {required bool Function() isCurrent}) {
    _roleChoiceOwners.remove(owner);
    _roleChoiceOwners[owner] = isCurrent;
    _roleChoiceRevision++;
    _notifyCompatibilityListeners();
  }

  void detachRoleChoice(Object owner) {
    if (_roleChoiceOwners.remove(owner) == null) return;
    _roleChoiceRevision++;
    _notifyCompatibilityListeners();
  }

  Object? get activeRoleChoiceOwner {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return null;
    for (final entry in _roleChoiceOwners.entries.toList().reversed) {
      if (entry.value()) return entry.key;
    }
    return null;
  }

  int get roleChoiceRevision => _roleChoiceRevision;

  bool selectRoleChoiceDesign(Object owner, ZyraRoleChoiceDesign design) {
    if (!identical(activeRoleChoiceOwner, owner) ||
        !ZyraDevRoleChoiceDesign.select(design)) {
      return false;
    }
    _notifyCompatibilityListeners();
    return true;
  }

  // The app-wide overlay is outside the nested onboarding Navigator. Keep an
  // owner-scoped callback so changing a style restarts that flow, not a second
  // outer route. No account data or durable design selection is stored here.
  void attachOnboarding(
    Object owner,
    ValueChanged<ZyraOnboardingDirection> restart, {
    VoidCallback? onClose,
    bool Function()? isCurrent,
  }) {
    _onboardingOwners.remove(owner);
    _onboardingOwners[owner] = _OnboardingRegistration(
      restart: restart,
      onClose: onClose,
      isCurrent: isCurrent,
    );
    _notifyCompatibilityListeners();
  }

  void detachOnboarding(Object owner) {
    if (_onboardingOwners.remove(owner) != null) {
      _notifyCompatibilityListeners();
    }
  }

  bool get hasOnboardingOwner => _onboardingOwners.isNotEmpty;

  bool get canCloseOnboarding {
    if (!ZyraDeveloperAccess.canUseDeveloperTools ||
        _onboardingOwners.isEmpty) {
      return false;
    }
    final active = _onboardingOwners.values.last;
    return active.onClose != null && (active.isCurrent?.call() ?? true);
  }

  bool closeOnboarding() {
    if (!canCloseOnboarding) return false;
    _onboardingOwners.values.last.onClose!();
    return true;
  }

  // Bind a rendered menu action to its registration, not whichever rehearsal
  // happens to be latest when a retained callback is invoked later.
  bool Function()? get onboardingExit {
    if (!canCloseOnboarding) return null;
    final registration = _onboardingOwners.values.last;
    return () {
      if (!canCloseOnboarding ||
          !identical(_onboardingOwners.values.last, registration)) {
        return false;
      }
      registration.onClose!();
      return true;
    };
  }

  bool restartOnboarding(ZyraOnboardingDirection direction) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools ||
        _onboardingOwners.isEmpty) {
      return false;
    }
    _onboardingOwners.values.last.restart(direction);
    return true;
  }

  /// Presentation-only: never releases the local-preview network-deny latch.
  bool get developerLandingVisible => _developerLandingOwners.isNotEmpty;

  void setDeveloperLandingVisible(Object owner, bool visible) {
    final changed = visible
        ? _developerLandingOwners.add(owner)
        : _developerLandingOwners.remove(owner);
    if (changed) notifyListeners();
  }

  ZyraDevSurface get surface {
    if (_entryOverride != null || developerLandingVisible) {
      return ZyraDevSurface.entry;
    }
    if (_guardianOwners.isNotEmpty) return ZyraDevSurface.guardian;
    if (_seekerOwners.isNotEmpty) return ZyraDevSurface.seeker;
    return ZyraDevSurface.entry;
  }

  String get entryLabel =>
      _entryOverride ??
      (developerLandingVisible ? 'Developer Access' : 'Entry & sign-up');

  ZyraCompatibilityDevControls? get activeCompatibilityControls {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return null;
    for (final controls in _compatibilityOwners.values.toList().reversed) {
      if (controls.isCurrent()) return controls;
    }
    return null;
  }

  void attachCompatibility(
    Object owner,
    ZyraCompatibilityDevControls controls,
  ) {
    _compatibilityOwners.remove(owner);
    _compatibilityOwners[owner] = controls;
    _notifyCompatibilityListeners();
  }

  void detachCompatibility(Object owner) {
    if (_compatibilityOwners.remove(owner) != null) {
      _notifyCompatibilityListeners();
    }
  }

  void compatibilityChanged(Object owner) {
    if (_compatibilityOwners.containsKey(owner)) {
      _notifyCompatibilityListeners();
    }
  }

  void _notifyCompatibilityListeners() {
    // A route unregisters synchronously from dispose, which can run while the
    // widget tree is locked. Remove its callbacks immediately, but let the
    // shared overlay rebuild only after the current frame has completed.
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      notifyListeners();
      return;
    }
    if (_compatibilityNotificationScheduled) return;
    _compatibilityNotificationScheduled = true;
    final epoch = _compatibilityNotificationEpoch;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (epoch != _compatibilityNotificationEpoch) return;
      _compatibilityNotificationScheduled = false;
      notifyListeners();
    });
  }

  void attachSeeker(
    Object owner,
    ValueChanged<DevPage> onOpen, {
    ValueChanged<int>? onOpenConnectionsSection,
    VoidCallback? onOpenIntroductions,
  }) {
    _seekerOwners.remove(owner);
    _seekerOwners[owner] = _SeekerSurfaceRegistration(
      onOpen: onOpen,
      onOpenConnectionsSection: onOpenConnectionsSection,
      onOpenIntroductions: onOpenIntroductions,
    );
    _notifyCompatibilityListeners();
  }

  void detachSeeker(Object owner) {
    if (!_seekerOwners.containsKey(owner)) return;
    _seekerOwners.remove(owner);
    _notifyCompatibilityListeners();
  }

  void attachGuardian(Object owner, ValueChanged<WaliPage> onOpen) {
    _guardianOwners.remove(owner);
    _guardianOwners[owner] = onOpen;
    _notifyCompatibilityListeners();
  }

  void detachGuardian(Object owner) {
    if (!_guardianOwners.containsKey(owner)) return;
    _guardianOwners.remove(owner);
    _notifyCompatibilityListeners();
  }

  void beginEntryFlow(String label) {
    _entryOverride = label;
    notifyListeners();
  }

  void endEntryFlow() {
    if (_entryOverride == null) return;
    _entryOverride = null;
    notifyListeners();
  }

  void openSeeker(DevPage page) {
    if (_seekerOwners.isEmpty) return;
    _seekerOwners.values.last.onOpen(page);
  }

  void openSeekerConnectionsSection(int section) {
    if (_seekerOwners.isEmpty) return;
    _seekerOwners.values.last.onOpenConnectionsSection?.call(section);
  }

  void openSeekerIntroductions() {
    if (_seekerOwners.isEmpty) return;
    _seekerOwners.values.last.onOpenIntroductions?.call();
  }

  void openGuardian(WaliPage page) {
    if (_guardianOwners.isEmpty) return;
    _guardianOwners.values.last(page);
  }

  @visibleForTesting
  void resetForTesting() {
    _seekerOwners.clear();
    _guardianOwners.clear();
    _compatibilityOwners.clear();
    _compatibilityNotificationScheduled = false;
    _compatibilityNotificationEpoch++;
    _entryOverride = null;
    _developerLandingOwners.clear();
    _onboardingOwners.clear();
    _roleChoiceOwners.clear();
    _roleChoiceRevision++;
  }
}
