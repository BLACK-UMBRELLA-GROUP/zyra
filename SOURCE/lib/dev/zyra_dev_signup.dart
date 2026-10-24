// One protected, local-only signup entry for Developer Access and toggles.
// Founder correction 2026-09-28: no developer-only role sheet or direct-role
// shortcut. Rehearse Welcome and the app's actual first-use choice, then the
// existing setup screens. No real OAuth, account/draft writes or sign-out.

import 'package:flutter/material.dart';

import '../services/zyra_developer_access.dart';
import '../services/zyra_internal_preview_client.dart';
import '../state/app_state.dart';
import '../widgets/zyra_onboarding_study.dart';
import 'dev_signup_process.dart';
import 'zyra_dev_surface_coordinator.dart';

class ZyraDevSignUp {
  ZyraDevSignUp._();

  static bool _opening = false;

  /// One neutral entry: Welcome → actual first-use role choice → questions.
  /// Refresh proof before latching local-only data isolation and resetting
  /// sample state. Never sign out or create/change an authenticated account.
  static Future<void> start(
    BuildContext context, {
    ZyraOnboardingDirection direction = zyraDefaultDevOnboardingDirection,
  }) async {
    if (!ZyraDeveloperAccess.canUseDeveloperTools) return;
    final coordinator = ZyraDevSurfaceCoordinator.instance;
    if (coordinator.restartOnboarding(direction)) return;
    if (_opening) return;
    final navigator = Navigator.of(context);
    _opening = true;
    var started = false;
    try {
      final allowed = await ZyraDeveloperAccess.refreshCurrentAuthorization();
      if (!navigator.mounted ||
          !allowed ||
          !ZyraDeveloperAccess.canUseDeveloperTools) {
        return;
      }
      ZyraInternalPreviewClient.beginPreview();
      AppState.instance.applyDevPreset();
      coordinator.beginEntryFlow('Onboarding');
      started = true;
      await navigator.push<void>(
        MaterialPageRoute(
          allowSnapshotting: false,
          builder: (_) => DevSignUpProcessScreen(initialDirection: direction),
        ),
      );
    } finally {
      if (started) coordinator.endEntryFlow();
      _opening = false;
    }
  }
}
