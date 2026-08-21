// Test sign-up — ONE implementation, reachable from two places.
//
// NEW 2026-08-07, correcting a mistake made earlier the same day.
//
// ── WHAT WENT WRONG. The Founder asked for the Test Sign Up tiles to move
// from Developer Access into the toggle panel. I moved them and deleted the
// originals, reasoning that "two copies of a dev entry point is how one of
// them quietly stops matching the flow it launches."
//
// That reasoning was right and the move was still wrong, because the panel
// is mounted in exactly one place:
//
//     home_shell.dart       if (!kReleaseMode) DevScenarioPanelV2(...),
//
// Not WaliHomeShell. Not Welcome. Not Developer Access. So the action
// "test signing up as a brand new user" ended up reachable only from
// inside the signed-in Seeker home — the one state you cannot be in when
// you want to test signing up.
//
// ── THE FIX IS BOTH PLACES, NOT ONE. They are two different moments:
//
//   Developer Access, signed out   "start the sign-up flow from scratch"
//   Toggle panel, signed in        "jump into onboarding from where I am"
//
// The original worry about drift is answered by this file rather than by
// picking one location: Developer Access and the toggle panel both call
// start(), so there is one behaviour and nowhere for a second copy to rot.

import 'package:flutter/material.dart';

import '../screens/onboarding/onboarding_flow.dart';
import '../screens/wali/wali_onboarding_flow.dart';
import '../services/zyra_auth.dart';
import '../state/app_state.dart';

class ZyraDevSignUp {
  ZyraDevSignUp._();

  /// Resets AppState to a blank slate and pushes the REAL onboarding flow.
  ///
  /// Deliberately NOT applyDevPreset's usual pre-filled-persona use: the
  /// questions and validation stay identical to production. The explicit
  /// DEV skip control is the only shortcut: it advances without persisting
  /// placeholder answers. No tier picker either — every account starts on
  /// Basic and upgrades afterwards from Profile or Network, same as
  /// production.
  ///
  /// A plain push, not pushAndRemoveUntil: backing out returns you where
  /// you were, so an abandoned trial costs nothing. Developer Access used
  /// to wipe the stack, which is fine on a screen you signed out to reach
  /// and wrong from inside a live session.
  static void start(BuildContext context, {required bool isWali}) {
    AppState.instance.applyDevPreset();
    final previewName = ZyraAuth.onboardingFirstName ?? 'Shakeel';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => isWali
            ? const WaliOnboardingFlow(devPreview: true)
            : OnboardingFlow(welcomeName: previewName, devPreview: true),
      ),
    );
  }
}
