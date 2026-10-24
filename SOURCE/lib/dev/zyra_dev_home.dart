import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/dev/developer_access_screen.dart';
import '../services/zyra_account_state.dart';
import '../services/zyra_developer_access.dart';
import 'zyra_dev_surface_coordinator.dart';

/// Returns to the protected developer landing, not login or account reset.
abstract final class ZyraDevHome {
  static bool _opening = false;

  static Future<bool> open(
    BuildContext context, {
    bool Function()? isCurrent,
    bool replacePreviewRoot = false,
  }) async {
    if (_opening ||
        !context.mounted ||
        !ZyraDeveloperAccess.canUseDeveloperTools ||
        ZyraAccountState.isSigningOut ||
        (isCurrent == null &&
            ZyraDevSurfaceCoordinator.instance.hasOnboardingOwner)) {
      return false;
    }
    // A fresh proof can retract and dispose the toggle itself. Retain the
    // root navigator and account/route identity, not that transient context.
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = ModalRoute.of(context);
    final generation = ZyraAccountState.generation;
    _opening = true;
    try {
      final allowed = await ZyraDeveloperAccess.refreshCurrentAuthorization();
      if (!allowed ||
          !ZyraDeveloperAccess.canUseDeveloperTools ||
          !navigator.mounted ||
          ZyraAccountState.isSigningOut ||
          generation != ZyraAccountState.generation ||
          (route != null && !route.isCurrent) ||
          (isCurrent == null &&
              ZyraDevSurfaceCoordinator.instance.hasOnboardingOwner) ||
          (isCurrent != null && !isCurrent())) {
        return false;
      }
      if (!ZyraDevSurfaceCoordinator.instance.developerLandingVisible) {
        // The landing may have been an AuthGate child and persona entry can
        // replace its route. Do not guess it with popUntil. Retain only the
        // root below a fresh protected landing, discarding rehearsal routes.
        unawaited(
          navigator.pushAndRemoveUntil<void>(
            MaterialPageRoute<void>(
              builder: (_) => const DeveloperAccessScreen(),
            ),
            // A default concept occupies the first route. Retaining it under
            // Developer Home would retain its isolation lease over onboarding
            // and persona tools. Ordinary callers keep their previous stack.
            (route) => !replacePreviewRoot && route.isFirst,
          ),
        );
      }
      return true;
    } catch (error) {
      debugPrint('ZYRA developer Home authorization failed: $error');
      return false;
    } finally {
      _opening = false;
    }
  }
}
