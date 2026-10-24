import 'package:flutter/material.dart';

import '../../models/zyra_initial_signup_draft.dart';
import 'zyra_code_screen.dart';

/// Guardian entry point for their permanent code and Seeker requests.
class WaliInviteSeekerScreen extends StatelessWidget {
  /// Requested rehearsal mode is never reinterpreted as live on revocation.
  final bool signupPreview;
  final ZyraInitialSignupDraft? signupPreviewIdentity;

  const WaliInviteSeekerScreen({
    super.key,
    this.signupPreview = false,
    this.signupPreviewIdentity,
  });

  @override
  Widget build(BuildContext context) => ZyraCodeScreen(
    asGuardian: true,
    signupPreview: signupPreview,
    signupPreviewIdentity: signupPreviewIdentity,
  );
}
