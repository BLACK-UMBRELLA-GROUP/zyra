// Test-only code-selected fixture state and presentation; no application controls.
// A local comparison setting for the onboarding next-step control. It is
// independent of the eleven visual directions and never changes live signup.
import 'package:flutter/foundation.dart';

import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';

enum ZyraOnboardingAdvanceMode { continueButton, animatedDownArrow }

/// How the protected four-card opening story is read. Independent of later
/// form controls so comparison never changes the real member signup flow.
enum ZyraOnboardingStoryNavigation { tapThrough, scrollDown }

abstract final class ZyraDevOnboardingStoryNavigation {
  static const _defaultMode = ZyraOnboardingStoryNavigation.tapThrough;
  static final ValueNotifier<ZyraOnboardingStoryNavigation> _selection =
      ValueNotifier(_defaultMode);
  static int _accountGeneration = ZyraAccountState.generation;

  static Listenable get changes => _selection;
  static ZyraOnboardingStoryNavigation get current =>
      _accountGeneration == ZyraAccountState.generation
      ? _selection.value
      : _defaultMode;

  static bool select(ZyraOnboardingStoryNavigation mode) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return false;
    final generation = ZyraAccountState.generation;
    if (_accountGeneration != generation) {
      _accountGeneration = generation;
      _selection.value = _defaultMode;
    }
    _selection.value = mode;
    return true;
  }

  @visibleForTesting
  static void resetForTesting() {
    assert(() {
      _accountGeneration = ZyraAccountState.generation;
      _selection.value = _defaultMode;
      return true;
    }());
  }
}

abstract final class ZyraDevOnboardingInteraction {
  // Founder-selected default for protected onboarding comparisons. Continue
  // remains an explicit session-local alternative; ordinary signup is not
  // driven by this developer control.
  static const _defaultMode = ZyraOnboardingAdvanceMode.animatedDownArrow;
  static final ValueNotifier<ZyraOnboardingAdvanceMode> _selection =
      ValueNotifier(_defaultMode);
  static int _accountGeneration = ZyraAccountState.generation;

  /// The selector and the local rehearsal may listen without gaining a
  /// writable ValueNotifier or a route into production onboarding.
  static Listenable get changes => _selection;

  /// An account transition immediately restores the default, even before
  /// another developer control has been built for the new account.
  static ZyraOnboardingAdvanceMode get current =>
      _accountGeneration == ZyraAccountState.generation
      ? _selection.value
      : _defaultMode;

  static bool select(ZyraOnboardingAdvanceMode mode) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return false;
    final generation = ZyraAccountState.generation;
    if (_accountGeneration != generation) {
      _accountGeneration = generation;
      _selection.value = _defaultMode;
    }
    _selection.value = mode;
    return true;
  }

  @visibleForTesting
  static void resetForTesting() {
    assert(() {
      _accountGeneration = ZyraAccountState.generation;
      _selection.value = _defaultMode;
      return true;
    }());
  }
}
