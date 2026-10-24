import 'package:flutter/material.dart';

import '../../services/zyra_account_state.dart';
import '../../services/zyra_auth.dart';
import '../../services/zyra_developer_access.dart';
import '../../services/zyra_identity_verification_service.dart';
import '../../services/zyra_internal_preview_client.dart';
import '../../services/zyra_profile_service.dart';
import '../home/home_shell.dart';
import 'account_path_overview_screen.dart';

/// Leaving an optional profile chapter is not a verification bypass.
Future<bool> returnToMyZyra(
  BuildContext context, {
  required bool devPreview,
  required String? expectedUserId,
  required int expectedGeneration,
}) async {
  ZyraOnboardingProgress? progress;
  if (devPreview) {
    if (!ZyraDeveloperAccess.canUseDeveloperTools ||
        !ZyraInternalPreviewClient.isActive) {
      return false;
    }
    progress = SeekerPostIdentityChoiceScreen.previewIncompleteProgress;
  } else {
    final owner = expectedUserId;
    if (owner == null ||
        ZyraAuth.currentUser?.id != owner ||
        ZyraAccountState.generation != expectedGeneration) {
      return false;
    }
    try {
      final identity = await ZyraIdentityVerificationService.fetchMyState(
        expectedUserId: owner,
      ).timeout(const Duration(seconds: 10));
      if (identity?.allowsApp != true) return false;
      progress = await ZyraProfileService.fetchOnboardingProgress().timeout(
        const Duration(seconds: 10),
      );
      if (progress == null ||
          ZyraAuth.currentUser?.id != owner ||
          ZyraAccountState.generation != expectedGeneration) {
        return false;
      }
    } catch (_) {
      return false;
    }
  }
  if (!context.mounted) return false;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      allowSnapshotting: !devPreview,
      builder: (_) => HomeShell(
        initialTab: 2,
        deferredOnboardingDevPreview: devPreview,
        initialOnboardingProgress: progress,
      ),
    ),
    (_) => false,
  );
  return true;
}
