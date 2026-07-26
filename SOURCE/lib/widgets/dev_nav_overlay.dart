// Temporary testing aid — floating Back/Home buttons so Shakeel can get
// unstuck while manually testing flows on a real device, without needing
// each individual screen to have wired-up navigation yet. Debug-only:
// gated on `!kReleaseMode`, so this never appears in a release build and
// needs no separate flag to remember to turn off later.
//
// Sits on top of the whole app via MaterialApp's `builder:` (see
// main.dart), using a global navigatorKey rather than a local
// BuildContext, so it works identically no matter how deep the current
// screen is in the navigation stack.
//
// 2026-07-19 fix: reported as "visible but not functional." Root cause —
// several ZYRA flows (onboarding chapters especially) don't push real
// Navigator routes per step; they track a step index inside one
// StatefulWidget's own State. A plain Navigator.pop() has nothing to do
// in those screens, so it looked "broken" when it was actually a no-op
// by design. Fixed by making Home a hard reset (pushAndRemoveUntil a
// fresh WelcomeScreen), which wipes the whole widget tree — including
// any internal step state — regardless of how the current screen was
// reached. Back remains a soft pop, which is a legitimate no-op on a
// screen with nothing above it in the route stack (e.g. right after
// opening the app) — not a bug, just nothing to go back to yet.

// 2026-07-19 fix 2 (Fable): gate changed kDebugMode -> !kReleaseMode so
// the overlay also appears in PROFILE builds. Reason: the recurring
// "crashes after unplugging the phone / won't relaunch from the icon"
// problem was not an app bug at all — `flutter run` installs a DEBUG
// build, and iOS kills JIT (debug) apps the moment no debugger is
// attached, and refuses to cold-launch them from the icon. Untethered
// device testing must therefore use `flutter run --profile` (or
// --release), which is AOT-compiled and runs standalone. Profile mode
// keeps this overlay available during that testing; release builds
// (the only thing real users ever get) still never show it.
//
// Back also now explains itself when there is genuinely nothing to go
// back to, instead of silently doing nothing — "silent no-op" and
// "broken" are indistinguishable to a person testing on a phone.

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';

class DevNavOverlay extends StatelessWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const DevNavOverlay({super.key, required this.child, required this.navigatorKey});

  void _goBack(BuildContext context) {
    final nav = navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return;
    }
    // Nothing above this screen in the route stack (screens reached via
    // pushReplacement/pushAndRemoveUntil, onboarding step-state flows,
    // or the very first screen). Say so rather than appearing broken.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nothing to go back to — use Home to reset.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goHome() {
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) return child;

    final topOffset = MediaQuery.of(context).padding.top + 90;

    return Stack(
      children: [
        child,
        Positioned(
          right: 12,
          top: topOffset,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DevButton(icon: Icons.arrow_back, label: 'Back', onTap: () => _goBack(context)),
              const SizedBox(height: 10),
              _DevButton(icon: Icons.home, label: 'Home', onTap: _goHome),
            ],
          ),
        ),
      ],
    );
  }
}

class _DevButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DevButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Colors.black.withValues(alpha: 0.6),
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Icon(icon, color: Colors.white, size: 22, semanticLabel: label),
          ),
        ),
      ),
    );
  }
}
