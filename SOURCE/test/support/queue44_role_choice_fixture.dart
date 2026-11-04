// Test-only code-selected fixture state and presentation; no application controls.
// Chosen presentation for the protected first-use role-choice page.
// This never changes account role, signup drafts, or ordinary onboarding.
import 'package:flutter/foundation.dart';

import 'package:zyra/services/zyra_account_state.dart';
import 'package:zyra/services/zyra_developer_access.dart';

enum ZyraRoleChoiceDesign {
  guidedPaths('2 · Guided paths');

  const ZyraRoleChoiceDesign(this.label);

  final String label;
}

abstract final class ZyraDevRoleChoiceDesign {
  static final ValueNotifier<ZyraRoleChoiceDesign> _selection = ValueNotifier(
    ZyraRoleChoiceDesign.guidedPaths,
  );
  static int _accountGeneration = ZyraAccountState.generation;

  static Listenable get changes => _selection;

  /// A change of authenticated account cannot inherit the previous account's
  /// design choice, even before the protected control is mounted again.
  static ZyraRoleChoiceDesign get current =>
      _accountGeneration == ZyraAccountState.generation
      ? _selection.value
      : ZyraRoleChoiceDesign.guidedPaths;

  static bool select(ZyraRoleChoiceDesign design) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return false;
    final generation = ZyraAccountState.generation;
    if (_accountGeneration != generation) {
      _accountGeneration = generation;
      _selection.value = ZyraRoleChoiceDesign.guidedPaths;
    }
    _selection.value = design;
    return true;
  }

  @visibleForTesting
  static void resetForTesting() {
    assert(() {
      _accountGeneration = ZyraAccountState.generation;
      _selection.value = ZyraRoleChoiceDesign.guidedPaths;
      return true;
    }());
  }
}
